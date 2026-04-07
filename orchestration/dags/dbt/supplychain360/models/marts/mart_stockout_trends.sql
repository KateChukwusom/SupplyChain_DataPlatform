-- 
-- mart_stockout_trends
--  Business facing model for product stockout trend
--          analysis. Enables month over month trend tracking,
--          regional comparisons, and product level insights
-- Grain: One row per stockout event per product per warehouse


with stockout_events as (

    select
        product_id,
        warehouse_id,
        product_name,
        product_brand,
        product_category,
        supplier_name,
        warehouse_city,
        warehouse_state,
        warehouse_region,
        stockout_start_date,
        stockout_end_date,
        stockout_duration_days,
        min_quantity_during_stockout,
        reorder_threshold
    from {{ ref('int_stockout_events') }}

),

final as (

    select
        *,

        -- month and year for trend slicing
        date_trunc('month', stockout_start_date)    as stockout_month,
        year(stockout_start_date)   as stockout_year,
        month(stockout_start_date)   as stockout_month_number,

        -- number of stockout events for this product
        -- at this warehouse in this month
        count(*) over (
            partition by product_id, warehouse_id,
                date_trunc('month', stockout_start_date)
        ) as stockouts_in_month,

        -- total days stocked out in the month
        sum(stockout_duration_days) over (
            partition by product_id, warehouse_id,
                date_trunc('month', stockout_start_date)
        )  as total_stockout_days_in_month,

        -- running total of stockout events over time
        -- increasing numbers indicate worsening performance
        count(*) over (
            partition by product_id, warehouse_id
            order by stockout_start_date
            rows between unbounded preceding and current row
        ) as cumulative_stockout_events

    from stockout_events

)

select * from final