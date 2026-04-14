
--  facts_shipments
--  Record of every shipment with delivery
--          performance metrics 
-- Grain: One row per shipment
            {{config(materialized='incremental', unique_key= 'shipment_id')}}

with shipments as (

    select
        shipment_id,
        product_id,
        warehouse_id,
        store_id,
        supplier_id,
        quantity_shipped,
        shipment_date,
        expected_delivery_date,
        actual_delivery_date,
        carrier,
        delivery_status,
        is_on_time,
        delay_in_days,
        warehouse_region,
        store_region
    from {{ ref('int_supplier_delivery_metrics') }}

)

select * from shipments