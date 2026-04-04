-- fact: one row per shipment and this supports: shipment tracking, supplier performance monitoring,
--           suppliers with consistent delivery delays


with shipments as (

                select
                    -- unique keys that supports one row per shipment
                    shipment_id,
                    warehouse_id,
                    store_id,
                    product_id,
                    supplier_id,
                    supplier_name,
                    -- about products
                    product_name,
                    product_category,
                    -- about warehouse
                    warehouse_city,
                    warehouse_state,
                    warehouse_region,
                    -- about store
                    store_name,
                    store_city,
                    store_state,
                    store_region,
                    -- measures about shipments
                    quantity_shipped,
                    shipment_date,
                    expected_delivery_date,
                    actual_delivery_date,
                    carrier,
                    -- delivery performance metrics
                    delivery_delay_days,
                    is_late,
                    is_on_time,
                    shipment_status,
                    ingested_at

    from {{ ref('int_shipments_enriched') }}

    {% if is_incremental() %}
        where shipment_date > (select max(shipment_date) from {{ this }})
    {% endif %}

)

select * from shipments