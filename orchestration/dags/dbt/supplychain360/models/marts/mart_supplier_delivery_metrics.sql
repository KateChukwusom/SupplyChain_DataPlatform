
--  mart_supplier_delivery_performance
--  Aggregates shipment delivery metrics at supplier
--          level for ranking and trend analysis
-- Grain: One row per supplier


with delivery as (

    select
        supplier_id,
        supplier_name,
        supplier_country,
        product_category,
        shipment_id,
        delivery_status,
        is_on_time,
        delay_in_days,
        quantity_shipped,
        shipment_date,
        warehouse_region
    from {{ ref('int_supplier_delivery_metrics') }}

),

aggregated as (

    select
        supplier_id,
        supplier_name,
        supplier_country,
        count(shipment_id) as total_shipments,
        sum(quantity_shipped)  as total_quantity_shipped,

        -- delivery status breakdown
        count(case when delivery_status = 'On Time'  then 1 end)  as on_time_shipments,
        count(case when delivery_status = 'Late'     then 1 end)  as late_shipments,
        count(case when delivery_status = 'Pending'  then 1 end) as pending_shipments,

        -- on time delivery rate excluding pending shipments
        round(
            count(case when is_on_time = true then 1 end) /
            nullif(count(
                case when delivery_status != 'Pending' then 1 end
            ), 0) * 100, 2
        )   as on_time_delivery_rate_pct,

        -- delay metrics for late shipments only
        round(avg(
            case when delay_in_days > 0 then delay_in_days end ), 2)  as avg_delay_days,
             max(delay_in_days)  as longest_delay_days,

        -- shipment date range
            min(shipment_date)                          as first_shipment_date,
            max(shipment_date)                          as most_recent_shipment_date,

        -- consistency measure
            count(distinct date_trunc('month', shipment_date)) as active_shipping_months

    from delivery
    group by
        supplier_id,
        supplier_name,
        supplier_country

),

performance_ranked as (

    select
        *,

        -- rank suppliers by on time delivery rate
        rank() over (
            order by on_time_delivery_rate_pct desc
        )                                           as performance_rank,

        -- classify performance tier
        case
            when on_time_delivery_rate_pct >= 90    then 'Excellent'
            when on_time_delivery_rate_pct >= 75    then 'Good'
            when on_time_delivery_rate_pct >= 60    then 'Needs Improvement'
            else                                         'Poor'
        end                                         as performance_tier

    from aggregated

)

select * from performance_ranked
order by performance_rank