-- int_sales_enriched
--  Joins sales transactions to product, store,
--          to produce a fully enriched
--          sales dataset for metrics models to build on
-- Grain: One row per transaction

        {{ config(materialized='incremental', unique_key='transaction_id') }}
with sales as (

    -- sales transactions
    select
        transaction_id,
        store_id,
        product_id,
        quantity_sold,
        unit_price,
        discount_pct,
        sale_amount,
        transaction_timestamp,
        transaction_date
    from {{ ref('stg_postgres__sales') }}

),

products as (

    -- product context 
    select
        product_id,
        product_name,
        product_brand,
        product_category,
        supplier_id,
        supplier_name
    from {{ ref('dim_products') }}

),

stores as (

    -- store context 
    select
        store_id,
        store_name,
        store_city,
        store_state,
        store_region
    from {{ ref('dim_stores') }}

),

dates as (

    -- date context for time based analysis
    select
        date_day,
        year,
        month_number,
        month_name,
        quarter_number,
        quarter_name,
        first_day_of_month,
        first_day_of_quarter
    from {{ ref('dim_date') }}

),

enriched as (

    select
        -- transaction 
        s.transaction_id,
        s.store_id,
        s.product_id,
        s.quantity_sold,
        s.unit_price,
        s.discount_pct,
        s.sale_amount,
        s.transaction_timestamp,
        s.transaction_date,
        

        -- product
        p.product_name,
        p.product_brand,
        p.product_category,
        p.supplier_id,
        p.supplier_name,

        -- store and region 
        st.store_name,
        st.store_city,
        st.store_state,
        st.store_region,

        -- date context
        d.year,
        d.month_number,
        d.month_name,
        d.quarter_number,
        d.quarter_name,
        d.first_day_of_month,
        d.first_day_of_quarter

    from sales s
    left join products p
        on s.product_id = p.product_id
    left join stores st
        on s.store_id = st.store_id
    left join dates d
        on s.transaction_date = d.date_day

)

select * from enriched