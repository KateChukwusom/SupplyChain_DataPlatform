with source as (

    select
        loaded_at,
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

renamed as (

    select
        shipment_id,
        warehouse_id,
        store_id,
        product_id,
        quantity_shipped,
        cast(shipment_date as date)             as shipment_date,
        cast(expected_delivery_date as date)    as expected_delivery_date,
        cast(actual_delivery_date as date)      as actual_delivery_date,
        carrier,
        cast(loaded_at as timestamp_ntz)        as ingested_at

    from source
)

select * from renamed