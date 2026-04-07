#this file is for schema enforcement and normalisation.
# Its job is to make sure no matter how messy or inconsistent the source JSON is, 
# what lands in the data lake is always clean, consistently structured, and auditable.

import json
import pyarrow as pa
from datetime import datetime, timezone


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

# The 'KNOWN FIELDS' builds a set of all field names from the schema excluding the three columns
KNOWN_FIELDS = {f.name for f in SCHEMA} - {"SOURCE_FILE", "LOADED_AT", "_extra_fields"}


def normalise_record(record: dict, source_file: str) -> dict:
    """This function, uppercases all keys, splits fields into known vs extra, and adds pipeline metadata """
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
    """Takes a list of normalised record dicts and converts them into a PyArrow table enforcing the schema"""
    return pa.Table.from_pylist(records, schema=SCHEMA)