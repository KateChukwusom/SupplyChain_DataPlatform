-- This dimension focuses one row per product
-- supports: stockout analysis, inventory planning, demand forecasting

{{ config(materialized='table') }}

with final as (

    select
        product_id,
        supplier_id,
        product_name,
        product_category,
        unit_price,
        supplier_name,
        supplier_category,
        supplier_country,
        ingested_at

    from {{ ref('int_products_enriched') }}

)

select * from final