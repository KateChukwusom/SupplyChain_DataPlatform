{{ config(materialized='table') }}

with sales as (

    select
        store_id,
        store_name,
        store_city,
        store_state,
        store_region,
        product_id,
        product_name,
        product_category,
        supplier_id,
        supplier_name,
        transaction_date,
        day_of_week,
        transaction_month,
        transaction_year,
        is_discounted,
        quantity_sold,
        sale_amount,
        discount_amount,
        expected_sale_amount

    from {{ ref('facts_sales') }}

),

daily_demand as (

    select
        store_id,
        store_name,
        store_city,
        store_state,
        store_region,
        product_id,
        product_name,
        product_category,
        supplier_id,
        supplier_name,
        transaction_date,
        day_of_week,
        transaction_month,
        transaction_year,
        is_discounted,

        sum(quantity_sold)                                      as daily_units_sold,
        sum(sale_amount)                                        as daily_revenue,
        sum(discount_amount)                                    as daily_discount_amount,
        sum(expected_sale_amount)                               as daily_expected_revenue,
        count(*)                                                as daily_transaction_count

    from sales
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15

),

final as (

    select
        -- keys
        store_id,
        product_id,
        transaction_date,

        -- context
        store_name,
        store_city,
        store_region,
        product_name,
        product_category,
        supplier_name,
        day_of_week,
        transaction_month,
        transaction_year,
        is_discounted,

        -- demand measures
        daily_units_sold,
        daily_revenue,
        daily_discount_amount,
        daily_expected_revenue,
        daily_transaction_count,

        -- rolling 7 day demand per store per product
        sum(daily_units_sold) over (
            partition by store_id, product_id
            order by transaction_date
            rows between 6 preceding and current row
        )                                                       as rolling_7day_units_sold,

        -- average daily demand per store per product
        round(
            avg(daily_units_sold) over (
                partition by store_id, product_id
            ), 2
        )                                                       as avg_daily_demand,

        -- demand standard deviation per store per product
        round(
            stddev(daily_units_sold) over (
                partition by store_id, product_id
            ), 2
        )                                                       as demand_stddev,

        -- coefficient of variation — stores with highest demand variability
        round(
            nullif(
                stddev(daily_units_sold) over (
                    partition by store_id, product_id
                ), 0
            )
            /
            nullif(
                avg(daily_units_sold) over (
                    partition by store_id, product_id
                ), 0
            ), 4
        )                                                       as demand_coefficient_of_variation,

        -- cumulative revenue per store
        sum(daily_revenue) over (
            partition by store_id
            order by transaction_date
            rows between unbounded preceding and current row
        )                                                       as cumulative_store_revenue

    from daily_demand

)

select * from final