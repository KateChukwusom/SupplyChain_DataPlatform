
--  mart_regional_sales_demand
-- Business facing model for regional sales demand
--          analysis. Enables regional comparisons, trend
--          tracking, and product demand insights by region
-- Grain: One row per region per product per month


with demand as (

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
        total_transactions,
        total_quantity_sold,
        total_revenue,
        avg_transaction_value,
        avg_discount_pct,
        active_stores,
        prev_month_revenue,
        prev_month_quantity,
        mom_revenue_growth_pct,
        mom_quantity_growth_pct

    from {{ ref('int_sales_demand_metrics') }}

),

with_rankings as (

    select
        *,

        -- rank products by revenue within each region and month
        -- rank 1 = top selling product in that region that month
        rank() over (
            partition by store_region, first_day_of_month
            order by total_revenue desc)  as product_revenue_rank_in_region,

        -- rank regions by revenue within each month
        -- shows which region is performing best
        rank() over (
            partition by first_day_of_month
            order by total_revenue desc )  as region_revenue_rank_in_month,

        -- cumulative revenue per region per product over time
        sum(total_revenue) over (
            partition by store_region, product_id
            order by first_day_of_month
            rows between unbounded preceding and current row  )  as cumulative_revenue,

        -- cumulative quantity sold per region per product over time
        sum(total_quantity_sold) over (
            partition by store_region, product_id
            order by first_day_of_month
            rows between unbounded preceding and current row )  as cumulative_quantity_sold,

        -- demand trend label based on month over month growth
        case
            when mom_revenue_growth_pct is null      then 'Insufficient Data'
            when mom_revenue_growth_pct >= 10        then 'Growing'
            when mom_revenue_growth_pct >= -10       then 'Stable'
            else                                          'Declining'
        end   as demand_trend

    from demand

)

select * from with_rankings
order by
    store_region,
    first_day_of_month desc,
    product_revenue_rank_in_region