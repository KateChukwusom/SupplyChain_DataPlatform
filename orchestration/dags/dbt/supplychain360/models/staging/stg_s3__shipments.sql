-- 
-- Model: stg_shipments
-- Grain: One row per shipment
-- 

with source as (

    select
        shipment_id,
        warehouse_id,
        store_id,
        product_id,
        quantity_shipped,
        shipment_date,
        expected_delivery_date,
        actual_delivery_date,
        carrier
    from {{ source('RAW_SUPPLYCHAIN', 'SHIPMENTS') }}

),

deduplicated as (

    
    select distinct
        shipment_id,
        warehouse_id,
        store_id,
        product_id,
        quantity_shipped,
        shipment_date,
        expected_delivery_date,
        actual_delivery_date,
        carrier
    from source

),

renamed as (

    select
        shipment_id,
        warehouse_id,
        store_id,
        product_id,
        quantity_shipped,
        cast(shipment_date as date) as shipment_date,
        cast(expected_delivery_date as date)  as expected_delivery_date,
        cast(actual_delivery_date as date)   as actual_delivery_date,
        carrier
    from deduplicated

)

select * from renamed