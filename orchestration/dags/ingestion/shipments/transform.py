import json
import pyarrow as pa
from datetime import datetime, timezone

# ─────────────────────────────────────────────────────────────
# SCHEMA
# Any field not in KNOWN_FIELDS is captured in _extra_fields
# as JSON string instead of breaking the pipeline
# ─────────────────────────────────────────────────────────────
SCHEMA = pa.schema([
    pa.field("SHIPMENT_ID",             pa.string()),
    pa.field("WAREHOUSE_ID",            pa.string()),
    pa.field("STORE_ID",                pa.string()),
    pa.field("PRODUCT_ID",              pa.string()),
    pa.field("QUANTITY_SHIPPED",        pa.string()),
    pa.field("SHIPMENT_DATE",           pa.string()),
    pa.field("EXPECTED_DELIVERY_DATE",  pa.string()),
    pa.field("ACTUAL_DELIVERY_DATE",    pa.string()),
    pa.field("CARRIER",                 pa.string()),
    pa.field("SOURCE_FILE",             pa.string()),
    pa.field("LOADED_AT",               pa.timestamp("us", tz="UTC")),
    pa.field("_extra_fields",           pa.string()),
])

KNOWN_FIELDS = {f.name for f in SCHEMA} - {"SOURCE_FILE", "LOADED_AT", "_extra_fields"}


def normalise_record(record: dict, source_file: str) -> dict:
    record = {k.upper(): v for k, v in record.items()}

    known = {k: str(v) if v is not None else None for k, v in record.items() if k in KNOWN_FIELDS}
    extra = {k: v for k, v in record.items() if k not in KNOWN_FIELDS}

    known["SOURCE_FILE"]   = source_file
    known["LOADED_AT"]     = datetime.now(timezone.utc)
    known["_extra_fields"] = json.dumps(extra) if extra else None

    # fill missing known fields with None
    for field in KNOWN_FIELDS:
        known.setdefault(field, None)

    return known


def build_table(records: list) -> pa.Table:
    return pa.Table.from_pylist(records, schema=SCHEMA)