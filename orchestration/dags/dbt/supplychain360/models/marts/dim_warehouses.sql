
-- Model: dim_warehouse
-- Warehouse dimension enriched with region
--          Region is derived by joining to stores on
--          city and state since warehouses share locations
--          with stores and stores already carry region
-- Grain: One row per warehouse
 

with warehouses as (

    select
        warehouse_id,
        warehouse_city,
        warehouse_state
    from {{ ref('stg_s3__warehouses') }}

),

store_regions as (

    -- get one distinct region per city and state from stores
    select distinct
        store_city,
        store_state,
        store_region
    from {{ ref('stg_gsheets__stores') }}

),

joined as (

    -- join warehouse to store region on city and state
 --    warehouses and stores in the same city
    -- and state share the same region
    select
        w.warehouse_id,
        w.warehouse_city,
        w.warehouse_state,
        sr.store_region  as warehouse_region

    from warehouses w
    left join store_regions sr
        on  w.warehouse_city  = sr.store_city
        and w.warehouse_state = sr.store_state

)

select * from joined