import json
import os
import uuid
import logging

from google.api_core.exceptions import NotFound
from google.cloud import bigquery
from google.cloud import storage

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

bq = bigquery.Client()
gcs = storage.Client()


def resp(data, status=200):
    return json.dumps(data, ensure_ascii=False, indent=2), status, {"Content-Type": "application/json; charset=utf-8"}


def b(v, default=False):
    if v is None:
        return default
    if isinstance(v, bool):
        return v
    if isinstance(v, str):
        return v.strip().lower() in {"1", "true", "t", "yes", "y"}
    return bool(v)


def sql_str(v):
    return "'" + str(v).replace("\\", "\\\\").replace("'", "\\'") + "'"


def load_json_gcs(uri):
    if not uri.startswith("gs://"):
        raise ValueError(f"configUri inválido: {uri}")
    x = uri[5:]
    bucket, blob = x.split("/", 1)
    return json.loads(gcs.bucket(bucket).blob(blob).download_as_text())


def normalize_ref(ref):
    if ref is None:
        raise ValueError("Referencia vacía")
    ref = str(ref).strip()
    if not ref:
        raise ValueError("Referencia vacía")
    return ref


def parse_dataset_default(ref, fallback_project):
    ref = normalize_ref(ref)
    parts = [p.strip() for p in ref.split(".") if p.strip()]
    if len(parts) == 1:
        return fallback_project, parts[0]
    if len(parts) == 2:
        return parts[0], parts[1]
    raise ValueError(f"Dataset default inválido: {ref}. Usa dataset o project.dataset")


def resolve_table_ref(ref, default_project, default_dataset):
    ref = normalize_ref(ref)
    parts = [p.strip() for p in ref.split(".") if p.strip()]
    if len(parts) == 1:
        return default_project, default_dataset, parts[0]
    if len(parts) == 2:
        return default_project, parts[0], parts[1]
    if len(parts) == 3:
        return parts[0], parts[1], parts[2]
    raise ValueError(f"Tabla inválida: {ref}. Usa table, dataset.table o project.dataset.table")


def get_dataset_location(project, dataset):
    return bq.get_dataset(f"{project}.{dataset}").location


def ensure_dataset(project, dataset, location):
    ds_id = f"{project}.{dataset}"
    try:
        bq.get_dataset(ds_id)
    except NotFound:
        ds = bigquery.Dataset(ds_id)
        ds.location = location
        bq.create_dataset(ds)
        logger.info("Dataset creado: %s", ds_id)


def ensure_rejects_table(table_id, location):
    project, dataset, _ = table_id.split(".", 2)
    ensure_dataset(project, dataset, location)

    try:
        bq.get_table(table_id)
        return
    except NotFound:
        pass

    schema = [
        bigquery.SchemaField("run_id", "STRING"),
        bigquery.SchemaField("config_uri", "STRING"),
        bigquery.SchemaField("table_alias", "STRING"),
        bigquery.SchemaField("source_table", "STRING"),
        bigquery.SchemaField("target_table", "STRING"),
        bigquery.SchemaField("rule_name", "STRING"),
        bigquery.SchemaField("error_message", "STRING"),
        bigquery.SchemaField("rejected_at", "TIMESTAMP"),
        bigquery.SchemaField("row_id", "STRING"),
        bigquery.SchemaField("row_hash", "STRING"),
        bigquery.SchemaField("row_payload", "JSON"),
    ]
    table = bigquery.Table(table_id, schema=schema)
    table.time_partitioning = bigquery.TimePartitioning(type_=bigquery.TimePartitioningType.DAY, field="rejected_at")
    bq.create_table(table)
    logger.info("Tabla de errores creada: %s", table_id)


def run_query_to_table(sql, destination, location, write_disposition):
    job_config = bigquery.QueryJobConfig(
        destination=destination,
        create_disposition=bigquery.CreateDisposition.CREATE_IF_NEEDED,
        write_disposition=write_disposition,
    )
    job = bq.query(sql, job_config=job_config, location=location)
    job.result()
    return job


def path_sql(alias, parts):
    if not parts:
        return alias
    return alias + "." + ".".join("`" + p + "`" for p in parts)


def build_schema_index(fields, parent_parts=None, repeated_ancestors=None, path_map=None, leaf_paths=None):
    if parent_parts is None:
        parent_parts = []
    if repeated_ancestors is None:
        repeated_ancestors = []
    if path_map is None:
        path_map = {}
    if leaf_paths is None:
        leaf_paths = []

    for field in fields:
        parts = parent_parts + [field.name]
        path = ".".join(parts)
        reps = list(repeated_ancestors)
        if field.mode == "REPEATED":
            reps = reps + [parts]

        path_map[path] = {
            "path": path,
            "parts": parts,
            "field_type": field.field_type,
            "mode": field.mode,
            "is_record": field.field_type == "RECORD",
            "repeated_ancestors": reps,
            "field": field,
        }

        if field.field_type == "RECORD":
            build_schema_index(field.fields, parts, reps, path_map, leaf_paths)
        else:
            leaf_paths.append(path)

    return path_map, leaf_paths


def has_value_sql(field, expr, treat_blank_as_null=True):
    if field.field_type == "RECORD" and field.mode == "REPEATED":
        alias = f"x_{field.name.lower()}"
        child_checks = []
        for child in field.fields:
            child_expr = f"{alias}.`{child.name}`"
            child_sql = has_value_sql(child, child_expr, treat_blank_as_null)
            if child_sql:
                child_checks.append(child_sql)
        if not child_checks:
            return None
        return f"EXISTS (SELECT 1 FROM UNNEST(IFNULL({expr}, [])) AS {alias} WHERE " + " OR ".join(f"({c})" for c in child_checks) + ")"

    if field.field_type == "RECORD":
        child_checks = []
        for child in field.fields:
            child_expr = f"{expr}.`{child.name}`"
            child_sql = has_value_sql(child, child_expr, treat_blank_as_null)
            if child_sql:
                child_checks.append(child_sql)
        if not child_checks:
            return None
        return "(" + " OR ".join(f"({c})" for c in child_checks) + ")"

    if field.mode == "REPEATED":
        alias = f"x_{field.name.lower()}"
        if field.field_type == "STRING":
            if treat_blank_as_null:
                return f"EXISTS (SELECT 1 FROM UNNEST(IFNULL({expr}, [])) AS {alias} WHERE {alias} IS NOT NULL AND TRIM(CAST({alias} AS STRING)) <> '')"
            return f"EXISTS (SELECT 1 FROM UNNEST(IFNULL({expr}, [])) AS {alias} WHERE {alias} IS NOT NULL)"
        return f"EXISTS (SELECT 1 FROM UNNEST(IFNULL({expr}, [])) AS {alias} WHERE {alias} IS NOT NULL)"

    if field.field_type == "STRING":
        if treat_blank_as_null:
            return f"{expr} IS NOT NULL AND TRIM(CAST({expr} AS STRING)) <> ''"
        return f"{expr} IS NOT NULL"

    return f"{expr} IS NOT NULL"


def build_full_null_condition(schema_fields, alias="b", treat_blank_as_null=True):
    checks = []
    for field in schema_fields:
        expr = f"{alias}.`{field.name}`"
        x = has_value_sql(field, expr, treat_blank_as_null)
        if x:
            checks.append(x)
    if not checks:
        return "FALSE"
    return "NOT (" + " OR ".join(f"({c})" for c in checks) + ")"


def build_exists_over_repeated(base_alias, repeated_ancestors, leaf_parts, leaf_builder):
    def rec(level, current_alias, previous_parts):
        repeated_parts = repeated_ancestors[level]
        rel_parts = repeated_parts[len(previous_parts):]
        array_expr = path_sql(current_alias, rel_parts)
        elem_alias = f"rep_{level + 1}"

        if level == len(repeated_ancestors) - 1:
            leaf_rel = leaf_parts[len(repeated_parts):]
            leaf_expr = path_sql(elem_alias, leaf_rel) if leaf_rel else elem_alias
            inner = leaf_builder(leaf_expr)
        else:
            inner = rec(level + 1, elem_alias, repeated_parts)

        return f"EXISTS (SELECT 1 FROM UNNEST(IFNULL({array_expr}, [])) AS {elem_alias} WHERE {inner})"

    return rec(0, base_alias, [])


def build_required_invalid(info, alias="b", treat_blank_as_null=True):
    if info["is_record"]:
        raise ValueError(f"required solo soporta campos hoja, no RECORD: {info['path']}")

    def leaf_invalid(expr):
        if info["field_type"] == "STRING":
            if treat_blank_as_null:
                return f"{expr} IS NULL OR TRIM(CAST({expr} AS STRING)) = ''"
            return f"{expr} IS NULL"
        return f"{expr} IS NULL"

    if info["repeated_ancestors"]:
        return build_exists_over_repeated(alias, info["repeated_ancestors"], info["parts"], leaf_invalid)

    expr = path_sql(alias, info["parts"])
    return leaf_invalid(expr)


def build_min_items_invalid(info, min_items, alias="b"):
    if info["mode"] != "REPEATED":
        raise ValueError(f"minItems solo aplica a arrays: {info['path']}")

    def array_invalid(expr):
        return f"ARRAY_LENGTH(IFNULL({expr}, [])) < {int(min_items)}"

    if len(info["repeated_ancestors"]) <= 1:
        expr = path_sql(alias, info["parts"])
        return array_invalid(expr)

    parent_repeated = info["repeated_ancestors"][:-1]
    return build_exists_over_repeated(alias, parent_repeated, info["parts"], array_invalid)


def build_priority_case(quality):
    rule_when = []
    msg_when = []

    if b(quality.get("fullNull"), False):
        rule_when.append("WHEN _dq_full_null THEN 'dropFullyNullRows'")
        msg_when.append("WHEN _dq_full_null THEN 'Row rejected because all fields are NULL or blank.'")

    for path in (quality.get("minItems", {}) or {}).keys():
        col = "_dq_min_items_" + path.replace(".", "_")
        rule_when.append(f"WHEN {col} THEN {sql_str('minItems:' + path)}")
        msg_when.append(f"WHEN {col} THEN 'Row rejected because array size is below minItems.'")

    for path in quality.get("required", []):
        col = "_dq_req_" + path.replace(".", "_")
        rule_when.append(f"WHEN {col} THEN {sql_str('required:' + path)}")
        msg_when.append(f"WHEN {col} THEN 'Row rejected because required path is NULL or blank.'")

    if b(quality.get("fullDuplicate"), False):
        rule_when.append("WHEN _dq_dup_rn > 1 THEN 'dropExactDuplicates'")
        msg_when.append("WHEN _dq_dup_rn > 1 THEN 'Row rejected because it is an exact duplicate.'")

    rule_case = "CASE " + " ".join(rule_when) + " ELSE NULL END"
    msg_case = "CASE " + " ".join(msg_when) + " ELSE NULL END"
    return rule_case, msg_case


def build_valid_sql(source_table_id, schema_fields, quality, path_map):
    treat_blank_as_null = b(quality.get("treatBlankAsNull"), True)
    flag_exprs = []

    if b(quality.get("fullNull"), False):
        flag_exprs.append(f"({build_full_null_condition(schema_fields, 'b', treat_blank_as_null)}) AS _dq_full_null")
    else:
        flag_exprs.append("FALSE AS _dq_full_null")

    if b(quality.get("fullDuplicate"), False):
        flag_exprs.append("ROW_NUMBER() OVER (PARTITION BY _row_hash ORDER BY _row_id) AS _dq_dup_rn")
    else:
        flag_exprs.append("1 AS _dq_dup_rn")

    for path in quality.get("required", []):
        if path not in path_map:
            raise ValueError(f"required path no existe: {path}")
        cond = build_required_invalid(path_map[path], "b", treat_blank_as_null)
        col = "_dq_req_" + path.replace(".", "_")
        flag_exprs.append(f"({cond}) AS {col}")

    for path, min_items in (quality.get("minItems", {}) or {}).items():
        if path not in path_map:
            raise ValueError(f"minItems path no existe: {path}")
        cond = build_min_items_invalid(path_map[path], min_items, "b")
        col = "_dq_min_items_" + path.replace(".", "_")
        flag_exprs.append(f"({cond}) AS {col}")

    flag_exprs_sql = ",\n    ".join(flag_exprs)
    rule_case, msg_case = build_priority_case(quality)

    helper_cols = ["_row_id", "_row_json", "_row_hash", "_dq_full_null", "_dq_dup_rn", "_dq_first_rule", "_dq_first_msg"]
    for path in quality.get("required", []):
        helper_cols.append("_dq_req_" + path.replace(".", "_"))
    for path in (quality.get("minItems", {}) or {}).keys():
        helper_cols.append("_dq_min_items_" + path.replace(".", "_"))

    return f"""
WITH base AS (
  SELECT t.*, GENERATE_UUID() AS _row_id, TO_JSON_STRING((SELECT AS STRUCT t.*)) AS _row_json, TO_HEX(SHA256(TO_JSON_STRING((SELECT AS STRUCT t.*)))) AS _row_hash
  FROM `{source_table_id}` AS t
),
flagged AS (
  SELECT b.*, {flag_exprs_sql}
  FROM base AS b
),
marked AS (
  SELECT f.*, {rule_case} AS _dq_first_rule, {msg_case} AS _dq_first_msg
  FROM flagged AS f
)
SELECT * EXCEPT({", ".join(helper_cols)})
FROM marked
WHERE _dq_first_rule IS NULL
""".strip()


def build_rejects_sql(source_table_id, target_table_id, schema_fields, quality, path_map, run_id, config_uri, table_alias):
    treat_blank_as_null = b(quality.get("treatBlankAsNull"), True)
    flag_exprs = []

    if b(quality.get("fullNull"), False):
        flag_exprs.append(f"({build_full_null_condition(schema_fields, 'b', treat_blank_as_null)}) AS _dq_full_null")
    else:
        flag_exprs.append("FALSE AS _dq_full_null")

    if b(quality.get("fullDuplicate"), False):
        flag_exprs.append("ROW_NUMBER() OVER (PARTITION BY _row_hash ORDER BY _row_id) AS _dq_dup_rn")
    else:
        flag_exprs.append("1 AS _dq_dup_rn")

    for path in quality.get("required", []):
        if path not in path_map:
            raise ValueError(f"required path no existe: {path}")
        cond = build_required_invalid(path_map[path], "b", treat_blank_as_null)
        col = "_dq_req_" + path.replace(".", "_")
        flag_exprs.append(f"({cond}) AS {col}")

    for path, min_items in (quality.get("minItems", {}) or {}).items():
        if path not in path_map:
            raise ValueError(f"minItems path no existe: {path}")
        cond = build_min_items_invalid(path_map[path], min_items, "b")
        col = "_dq_min_items_" + path.replace(".", "_")
        flag_exprs.append(f"({cond}) AS {col}")

    flag_exprs_sql = ",\n    ".join(flag_exprs)
    rule_case, msg_case = build_priority_case(quality)

    return f"""
WITH base AS (
  SELECT t.*, GENERATE_UUID() AS _row_id, TO_JSON_STRING((SELECT AS STRUCT t.*)) AS _row_json, TO_HEX(SHA256(TO_JSON_STRING((SELECT AS STRUCT t.*)))) AS _row_hash
  FROM `{source_table_id}` AS t
),
flagged AS (
  SELECT b.*, {flag_exprs_sql}
  FROM base AS b
),
marked AS (
  SELECT f.*, {rule_case} AS _dq_first_rule, {msg_case} AS _dq_first_msg
  FROM flagged AS f
)
SELECT {sql_str(run_id)} AS run_id, {sql_str(config_uri)} AS config_uri, {sql_str(table_alias)} AS table_alias, {sql_str(source_table_id)} AS source_table, {sql_str(target_table_id)} AS target_table, _dq_first_rule AS rule_name, _dq_first_msg AS error_message, CURRENT_TIMESTAMP() AS rejected_at, _row_id AS row_id, _row_hash AS row_hash, SAFE.PARSE_JSON(_row_json) AS row_payload
FROM marked
WHERE _dq_first_rule IS NOT NULL
""".strip()


def process_table(config_uri, table_alias, table_cfg, defaults, dry_run):
    project_default = os.getenv("GOOGLE_CLOUD_PROJECT") or bq.project

    src_proj_def, src_ds_def = parse_dataset_default(defaults["source"], project_default)
    tgt_proj_def, tgt_ds_def = parse_dataset_default(defaults["target"], project_default)
    rej_proj_def, rej_ds_def, rej_tbl_def = resolve_table_ref(defaults["rejects"], project_default, "dummy_dataset")

    s_project, s_dataset, s_table = resolve_table_ref(table_cfg["source"], src_proj_def, src_ds_def)
    t_project, t_dataset, t_table = resolve_table_ref(table_cfg["target"], tgt_proj_def, tgt_ds_def)

    rejects_ref = table_cfg.get("rejects", defaults["rejects"])
    r_project, r_dataset, r_table = resolve_table_ref(rejects_ref, rej_proj_def, rej_ds_def)

    source_table_id = f"{s_project}.{s_dataset}.{s_table}"
    target_table_id = f"{t_project}.{t_dataset}.{t_table}"
    rejects_table_id = f"{r_project}.{r_dataset}.{r_table}"

    location = table_cfg.get("location") or defaults.get("location") or get_dataset_location(s_project, s_dataset)
    write_mode = (table_cfg.get("writeMode") or defaults.get("writeMode") or "truncate").strip().lower()
    write_disposition = bigquery.WriteDisposition.WRITE_TRUNCATE if write_mode == "truncate" else bigquery.WriteDisposition.WRITE_APPEND

    quality = {}
    quality.update(defaults.get("quality", {}))
    quality.update(table_cfg.get("quality", {}))

    source_table = bq.get_table(source_table_id)
    path_map, _ = build_schema_index(source_table.schema)

    ensure_dataset(t_project, t_dataset, location)
    ensure_rejects_table(rejects_table_id, location)

    run_id = str(uuid.uuid4())
    valid_sql = build_valid_sql(source_table_id, source_table.schema, quality, path_map)
    rejects_sql = build_rejects_sql(source_table_id, target_table_id, source_table.schema, quality, path_map, run_id, config_uri, table_alias)

    if dry_run:
        return {
            "table": table_alias,
            "source": source_table_id,
            "target": target_table_id,
            "rejects": rejects_table_id,
            "location": location,
            "validSql": valid_sql,
            "rejectsSql": rejects_sql,
        }

    valid_job = run_query_to_table(valid_sql, target_table_id, location, write_disposition)
    rejects_job = run_query_to_table(rejects_sql, rejects_table_id, location, bigquery.WriteDisposition.WRITE_APPEND)
    target_table = bq.get_table(target_table_id)

    return {
        "table": table_alias,
        "source": source_table_id,
        "target": target_table_id,
        "rejects": rejects_table_id,
        "location": location,
        "runId": run_id,
        "targetQueryJobId": valid_job.job_id,
        "rejectsQueryJobId": rejects_job.job_id,
        "targetRows": target_table.num_rows,
    }


def main(request):
    try:
        payload = request.get_json(silent=True) or {}
        config_uri = payload.get("configUri") or request.args.get("configUri") or f"gs://{os.getenv('BUCKET_CONFIG')}/reglas_calidad.json"
        dry_run = b(payload.get("dryRun") or request.args.get("dryRun"), False)
        only_table = payload.get("table") or request.args.get("table")

        if not config_uri:
            raise ValueError("Debes enviar configUri o definir BUCKET_CONFIG")

        config = load_json_gcs(config_uri)
        defaults = config["defaults"]
        tables = config["tables"]

        results = []
        for table_alias, table_cfg in tables.items():
            if only_table and table_alias != only_table:
                continue
            results.append(process_table(config_uri, table_alias, table_cfg, defaults, dry_run))

        return resp({"ok": True, "dryRun": dry_run, "configUri": config_uri, "results": results})
    except Exception as e:
        logger.exception("Error")
        return resp({"ok": False, "errorType": type(e).__name__, "message": str(e)}, 500)
    