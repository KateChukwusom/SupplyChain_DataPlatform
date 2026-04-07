-- 
-- Grain: One row per product per warehouse per snapshot date
-- 

with source as (

    select
        "product_id",
        "warehouse_id",
        "snapshot_date",
        "quantity_available",
        "reorder_threshold"
    from {{ source('RAW_SUPPLYCHAIN', 'INVENTORY') }}

),

deduplicated as (

    
    select distinct
        "product_id",
        "warehouse_id",
        "snapshot_date",
        "quantity_available",
        "reorder_threshold"
    from source

),

renamed as (

    select
        "product_id"                            as product_id,
        "warehouse_id"                          as warehouse_id,
        cast("snapshot_date" as date)           as snapshot_date,
        "quantity_available"                    as quantity_available,
        "reorder_threshold"                     as reorder_threshold
    from deduplicated

)

select * from renamed