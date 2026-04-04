-- dimension: one row per store and it supports: demand forecasting, store demand variability analysis

{{ config(materialized='table') }}

with final as (

    select
        store_id,
        store_name,
        store_city,
        store_state,
        store_region,
        store_open_date,
        ingested_at

    from {{ ref('stg_gsheets__stores') }}

)

select * from final