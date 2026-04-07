-- int_supplier_delivery_metrics
--  Applies delivery performance macros to enriched
--          shipments to calculate per-shipment metrics
--          including delivery status, delay, and on time flag
-- One row per shipment


with shipments as (

    select
        shipment_id,
        product_id,
        warehouse_id,
        store_id,
        quantity_shipped,
        shipment_date,
        expected_delivery_date,
        actual_delivery_date,
        carrier,
        product_name,
        product_category,
        supplier_id,
        supplier_name,
        supplier_country,
        warehouse_city,
        warehouse_state,
        warehouse_region,
        store_name,
        store_city,
        store_state,
        store_region
    from {{ ref('int_shipments_enriched') }}

),

metrics as (

    select
        shipment_id,
        product_id,
        warehouse_id,
        store_id,
        quantity_shipped,
        shipment_date,
        expected_delivery_date,
        actual_delivery_date,
        carrier,
        product_name,
        product_category,
        supplier_id,
        supplier_name,
        supplier_country,
        warehouse_city,
        warehouse_state,
        warehouse_region,
        store_name,
        store_city,
        store_state,
        store_region,

        --  macro
        {{ delivery_status('actual_delivery_date', 'expected_delivery_date') }}
         as delivery_status,

        -- macro: boolean flag for on time delivery
        {{ is_on_time('actual_delivery_date', 'expected_delivery_date') }}
          as is_on_time,

        -- macro: days late (positive) or early (negative)
        {{ delay_in_days('actual_delivery_date', 'expected_delivery_date') }}
         as delay_in_days

    from shipments

)

select * from metrics