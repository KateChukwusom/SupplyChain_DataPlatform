with source as (

    select
        _airbyte_extracted_at,
        product_id,
        warehouse_id,
        snapshot_date,
        quantity_available,
        reorder_threshold
    from {{ source('RAW_SUPPLYCHAIN', 'INVENTORY') }}
),

renamed as (

    select
        product_id,
        warehouse_id,
        cast(snapshot_date as date)     as snapshot_date,
        quantity_available,
        reorder_threshold,
        _airbyte_extracted_at           as ingested_at

    from source
)

select * from renamed