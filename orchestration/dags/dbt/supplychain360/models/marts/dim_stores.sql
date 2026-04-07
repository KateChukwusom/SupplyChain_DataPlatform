-- 
-- Model: dim_store
-- Store dimension with location and region details
-- Grain: One row per store
 

with stores as (

    select
        store_id,
        store_name,
        store_city,
        store_state,
        store_region,
        store_open_date
    from {{ ref('stg_gsheets__stores') }}

)

select * from stores