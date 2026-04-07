-- 
-- Model: stg_warehouses
-- Grain: One row per warehouse
-- 

with source as (

    select
        "warehouse_id",
        "city",
        "state"
    from {{ source('RAW_SUPPLYCHAIN', 'WAREHOUSES') }}

),

deduplicated as (

   
                select distinct
                    "warehouse_id",
                    "city",
                    "state"
                from source

),

renamed as (

    select
        "warehouse_id"      as warehouse_id,
        "city"              as warehouse_city,
        "state"             as warehouse_state
    from deduplicated

)

select * from renamed