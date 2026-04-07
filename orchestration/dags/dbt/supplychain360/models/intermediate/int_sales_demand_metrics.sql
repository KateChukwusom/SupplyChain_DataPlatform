
-- int_sales_demand_metrics
--  Calculates sales demand metrics at the region-product-month level for trend analysis
-- Grain: One row per region per product per month


with sales as (

    select
        transaction_id,
        store_id,
        product_id,
        product_name,
        product_brand,
        product_category,
        supplier_id,
        supplier_name,
        store_city,
        store_state,
        store_region,
        transaction_date,
        quantity_sold,
        unit_price,
        discount_pct,
        sale_amount,
        year,
        month_number,
        month_name,
        quarter_number,
        quarter_name,
        first_day_of_month,
        first_day_of_quarter
    from {{ ref('int_sales_enriched') }}

),

monthly_aggregated as (

    -- aggregate sales to region-product-month grain
    select
        store_region,
        product_id,
        product_name,
        product_brand,
        product_category,
        supplier_id,
        supplier_name,
        year,
        month_number,
        month_name,
        quarter_number,
        quarter_name,
        first_day_of_month,
        first_day_of_quarter,

        -- volume and revenue metrics
        count(transaction_id)   as total_transactions,
        sum(quantity_sold)   as total_quantity_sold,
        round(sum(sale_amount), 2)   as total_revenue,
        round(avg(sale_amount), 2)   as avg_transaction_value,
        round(avg(discount_pct) * 100, 2)  as avg_discount_pct,

        -- number of stores contributing sales in this region
        count(distinct store_id)  as active_stores

    from sales
    group by
        store_region,
        product_id,
        product_name,
        product_brand,
        product_category,
        supplier_id,
        supplier_name,
        year,
        month_number,
        month_name,
        quarter_number,
        quarter_name,
        first_day_of_month,
        first_day_of_quarter

),

with_trends as (

    select
        *,

        -- previous month revenue for the same product in the same region
        -- used to calculate month over month growth
        lag(total_revenue) over (
            partition by store_region, product_id
            order by first_day_of_month )  as prev_month_revenue,

        -- previous month quantity for growth calculation
        lag(total_quantity_sold) over (
            partition by store_region, product_id
            order by first_day_of_month ) as prev_month_quantity,

        -- previous quarter revenue for the same product in the same region
        lag(total_revenue) over (
            partition by store_region, product_id,
                quarter_number, year
            order by first_day_of_quarter )  as prev_quarter_revenue

    from monthly_aggregated

),

final as (

    select
        *,

        -- month over month revenue growth percentage
        case
            when prev_month_revenue is null
                or prev_month_revenue = 0 then null
            else round(
                (total_revenue - prev_month_revenue)
                / prev_month_revenue * 100, 2
            )
        end as mom_revenue_growth_pct,

        -- month over month quantity growth percentage
        case
            when prev_month_quantity is null
                or prev_month_quantity = 0  then null
            else round(
                (total_quantity_sold - prev_month_quantity)
                / prev_month_quantity * 100, 2
            )
        end   as mom_quantity_growth_pct

    from with_trends

)

select * from final