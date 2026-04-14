
--  Business facing model for warehouse efficiency analysis. Aggregates daily metrics to warehouse
--  level 
-- Grain: One row per warehouse


with daily_metrics as (

    select
        warehouse_id,
        warehouse_city,
        warehouse_state,
        warehouse_region,
        snapshot_date,
        total_quantity_available,
        total_reorder_threshold,
        products_stocked_out,
        total_products_tracked,
        daily_stockout_rate_pct,
        stock_utilisation_ratio,
        total_shipments,
        total_quantity_shipped,
        on_time_shipments,
        late_shipments,
        daily_on_time_rate_pct,
        avg_delay_days

    from {{ ref('int_warehouse_efficiency_metrics') }}

),

aggregated as (

    -- aggregate daily metrics to warehouse level
    select
        warehouse_id,
        warehouse_city,
        warehouse_state,
        warehouse_region,

        -- inventory health metrics
        round(avg(daily_stockout_rate_pct), 2)      as avg_stockout_rate_pct,
        round(avg(stock_utilisation_ratio), 2)      as avg_stock_utilisation_ratio,
        max(products_stocked_out)                   as max_products_stocked_out_in_a_day,
        round(avg(total_quantity_available), 0)     as avg_daily_stock_level,

        -- shipment throughput metrics
        sum(total_shipments)  as total_shipments_processed,
        sum(total_quantity_shipped)  as total_units_shipped,
        round(avg(
            case when total_shipments > 0
            then total_shipments end ), 2)  as avg_daily_shipments,

        -- delivery performance metrics
        round(avg(daily_on_time_rate_pct), 2)  as avg_on_time_delivery_rate_pct,
        round(avg(avg_delay_days), 2)  as avg_delay_days,
        sum(late_shipments)  as total_late_shipments,

        -- observation window
        min(snapshot_date)   as first_observed_date,
        max(snapshot_date)  as last_observed_date,
        count(distinct snapshot_date)   as total_days_observed

    from daily_metrics
    group by
        warehouse_id,
        warehouse_city,
        warehouse_state,
        warehouse_region

),

efficiency_classified as (

    select
        *,

        -- efficiency tier based on stockout rate and on time delivery
        -- excellent: low stockout rate and high on time delivery
        -- good:      moderate performance on both dimensions
        -- needs improvement: high stockout or poor delivery
        -- poor: consistently failing on both dimensions
        case
            when avg_stockout_rate_pct <= 5
                and avg_on_time_delivery_rate_pct >= 90  then 'Excellent'
            when avg_stockout_rate_pct <= 15
                and avg_on_time_delivery_rate_pct >= 75  then 'Good'
            when avg_stockout_rate_pct <= 30
                or  avg_on_time_delivery_rate_pct >= 60  then 'Needs Improvement'
            else                                              'Poor'
        end   as efficiency_tier,

        -- rank warehouses by combined performance
        -- lower stockout rate and higher on time rate = better rank
        rank() over (
            order by
                avg_stockout_rate_pct asc,
                avg_on_time_delivery_rate_pct desc
        )                                           as efficiency_rank

    from aggregated

)

select * from efficiency_classified
order by efficiency_rank