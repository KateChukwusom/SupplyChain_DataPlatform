-- This dimension focuses on one row per warehouse, the warehouse region is derived via state_region_mapping seed using state as join foreign key
-- This supports: inventory planning, stockout analysis, inventory optimization

{{ config(materialized='table') }}

with warehouses as (

    select
        warehouse_id,
        warehouse_city,
        warehouse_state,
        ingested_at
    from {{ ref('stg_s3__warehouses') }}

),

state_region as (

    select
        state,
        region
    from {{ ref('state_region_mapping') }}

),

final as (

    select
        w.warehouse_id,
        w.warehouse_city,
        w.warehouse_state,
        sr.region as warehouse_region,
        w.ingested_at

    from warehouses w
    left join state_region sr
        on w.warehouse_state = sr.state

)

select * from final