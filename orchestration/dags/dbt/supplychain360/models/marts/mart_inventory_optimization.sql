
-- Model: mart_inventory_optimization

-- Grain: One row per product per warehouse

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
        stockout_duration_days
    from {{ ref('int_stockout_events') }}

),

aggregated as (

    -- aggregate stockout information to product-warehouse level
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

        count(*)   as total_stockout_events,
        sum(stockout_duration_days)  as total_days_stocked_out,
        round(avg(stockout_duration_days), 2)  as avg_stockout_duration_days,
        max(stockout_duration_days)  as longest_stockout_days,
        min(stockout_start_date)  as first_stockout_date,
        max(stockout_end_date)  as most_recent_stockout_date,

        -- count of distinct months with at least one stockout
        count(distinct date_trunc('month', stockout_start_date))  as months_with_stockout

    from stockout_events
    group by
        product_id,
        warehouse_id,
        product_name,
        product_brand,
        product_category,
        supplier_name,
        warehouse_city,
        warehouse_state,
        warehouse_region

),

risk_classified as (

    select
        *,

        -- risk tier classification:
        -- high:   5+ events or average duration above 7 days
        -- medium: 2-4 events or average duration 3-7 days
        -- low:    1 event and average duration under 3 days
        case
            when total_stockout_events >= 5
                or avg_stockout_duration_days > 7    then 'High'
            when total_stockout_events between 2 and 4
                or avg_stockout_duration_days between 3 and 7 then 'Medium'
            else  'Low'
        end  as stockout_risk_tier,

        -- plain english recommendation per risk tier
        case
            when total_stockout_events >= 5
                or avg_stockout_duration_days > 7  then 'Urgent'
            when total_stockout_events between 2 and 4
                or avg_stockout_duration_days between 3 and 7 then 'Monitor'
                else 'Stable: No immediate action required'
        end  as optimization_recommendation

    from aggregated

)

select * from risk_classified
order by
    case stockout_risk_tier
        when 'High'   then 1
        when 'Medium' then 2
        when 'Low'    then 3
    end,
    total_stockout_events desc