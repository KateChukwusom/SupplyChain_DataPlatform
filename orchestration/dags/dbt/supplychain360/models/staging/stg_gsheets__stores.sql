-- 
-- Model: stg_stores
-- Grain: One row per store
-- 

with source as (

    select
        store_id,
        store_name,
        city,
        state,
        region,
        store_open_date
    from {{ source('RAW_SUPPLYCHAIN', 'STORES') }}

),

deduplicated as (


    select distinct
        store_id,
        store_name,
        city,
        state,
        region,
        store_open_date
    from source

),

renamed as (

    select
        store_id,
        store_name,
        city   as store_city,
        state    as store_state,
        region    as store_region,
        try_to_date(store_open_date, 'DD/MM/YYYY') as store_open_date
    from deduplicated

)

select * from renamed