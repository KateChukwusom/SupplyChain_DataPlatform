{{ config(materialized='table') }}

with shipments as (

    select
        supplier_id,
        supplier_name,
        shipment_id,
        shipment_date,
        carrier,
        delivery_delay_days,
        is_late,
        shipment_status,
        warehouse_region,
        ingested_at

    from {{ ref('facts_shipments') }}

),

final as (

    select
        supplier_id,
        supplier_name,
        shipment_date,
        carrier,
        warehouse_region,
        shipment_status,
        delivery_delay_days,

        -- total shipments per supplier
        count(shipment_id) over (
            partition by supplier_id
        )                                                       as total_shipments,

        -- total late shipments per supplier
        sum(
            case when is_late then 1 else 0 end
        ) over (
            partition by supplier_id
        )                                                       as total_late_shipments,

        -- on time delivery rate per supplier
        round(
            100.0 * sum(
                case when not is_late then 1 else 0 end
            ) over (partition by supplier_id)
            /
            nullif(
                count(shipment_id) over (
                    partition by supplier_id
                ), 0
            ), 2
        )                                                       as on_time_rate_pct,

        -- average delay days per supplier
        round(
            avg(delivery_delay_days) over (
                partition by supplier_id
            ), 2
        )                                                       as avg_delay_days,

        -- rolling 7 day late shipments per supplier
        sum(
            case when is_late then 1 else 0 end
        ) over (
            partition by supplier_id
            order by shipment_date
            rows between 6 preceding and current row
        )                                                       as rolling_7day_late_shipments,

        -- audit
        ingested_at

    from shipments

)

select * from final