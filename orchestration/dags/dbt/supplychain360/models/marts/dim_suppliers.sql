-- This is a dimension table that supports one row per supplier
-- It stands aS a source of truth for supplier attributes
-- It supports -  supplier performance monitoring, delivery delay analysis

{{ config(materialized='table') }}

with final as (

    select
        supplier_id,
        supplier_name,
        supplier_category,
        supplier_country,
        ingested_at

    from {{ ref('stg_s3__suppliers') }}

)

select * from final