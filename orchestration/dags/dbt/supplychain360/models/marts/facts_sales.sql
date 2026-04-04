-- fact: one row per sales transaction and this supports: demand forecasting, store demand variability,
--           inventory optimization, and to analyze top products



with sales as (

            select

                transaction_id,
                store_id,
                product_id,
                supplier_id,
                supplier_name,
        -- To identify more about store
                store_name,
                store_city,
                store_state,
                store_region,
        -- from products about sales
                product_name,
                product_category,
        -- transaction measures
                quantity_sold,
                unit_price,
                discount_pct,
                sale_amount,
                expected_sale_amount,
                discount_amount,
                has_sale_amount_discrepancy,
        -- demand pattern attributes
                transaction_date,
                transaction_timestamp,
                day_of_week,
                transaction_month,
                transaction_year,
        -- promotional demand flag
                is_discounted,
        -- audit
                source_table,
                ingested_at

    from {{ ref('int_sales_enriched') }}

    {% if is_incremental() %}
        where transaction_date > (select max(transaction_date) from {{ this }})
    {% endif %}

)

select * from sales


