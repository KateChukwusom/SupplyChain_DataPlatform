
-- Model: facts_sales
-- Record of every sales transaction —
--          
-- Grain: One row per transaction
                {{config(materialized='incremental', unique_key= 'transaction_id')}}

with sales as (

    select
        transaction_id,
        store_id,
        product_id,
        supplier_id,
        quantity_sold,
        unit_price,
        discount_pct,
        sale_amount,
        transaction_timestamp,
        transaction_date,
        store_region,
        year,
        month_number,
        quarter_number,
        first_day_of_month,
        first_day_of_quarter
    from {{ ref('int_sales_enriched') }}

)

select * from sales