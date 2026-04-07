--  int_warehouse_efficiency_metrics
--  Calculates per-day warehouse efficiency metrics
--          by combining inventory snapshots and shipment data
-- Grain: One row per warehouse per snapshot date

with inventory as (

    -- daily inventory snapshots per warehouse
    -- aggregated to warehouse level since a warehouse

    select
        warehouse_id,
        warehouse_city,
        warehouse_state,
        warehouse_region,
        snapshot_date,

        -- total stock available across all products
        sum(quantity_available) as total_quantity_available,

        -- total reorder threshold across all products
        sum(reorder_threshold)  as total_reorder_threshold,

        -- count of products currently stocked out
        count(
            case when quantity_available <= reorder_threshold
            then 1 end
        )  as products_stocked_out,

        -- total products tracked at this warehouse
        count(*)  as total_products_tracked,

        -- stockout rate for this warehouse on this day
        -- percentage of products stocked out
        round(
            count(
                case when quantity_available <= reorder_threshold
                then 1 end
            ) / nullif(count(*), 0) * 100, 2
        )   as daily_stockout_rate_pct

    from {{ ref('int_inventory_enriched') }}
    group by
        warehouse_id,
        warehouse_city,
        warehouse_state,
        warehouse_region,
        snapshot_date

),

shipments as (

    -- shipment volume and delivery performance per warehouse per day
    select
        warehouse_id,
        shipment_date,

        -- volume of shipments processed
        count(shipment_id)                          as total_shipments,
        sum(quantity_shipped)                       as total_quantity_shipped,

        -- delivery performance
        count(
            case when is_on_time = true then 1 end ) as on_time_shipments,
        count(
            case when delivery_status = 'Late' then 1 end ) as late_shipments,
        count(
            case when delivery_status = 'Pending' then 1 end )  as pending_shipments,

        -- on time rate for this warehouse on this day
        round(
            count(case when is_on_time = true then 1 end) /
            nullif(count(
                case when delivery_status != 'Pending' then 1 end
            ), 0) * 100, 2 ) as daily_on_time_rate_pct,

        -- average delay for late shipments
        round(avg(
            case when delay_in_days > 0 then delay_in_days end ), 2)    as avg_delay_days

    from {{ ref('int_supplier_delivery_metrics') }}
    group by
        warehouse_id,
        shipment_date

),

joined as (

    -- join inventory metrics to shipment metrics on warehouse and date
    -- The essence is to retain all inventory days
    -- even when no shipments occurred
    select
        i.warehouse_id,
        i.warehouse_city,
        i.warehouse_state,
        i.warehouse_region,
        i.snapshot_date,
        i.total_quantity_available,
        i.total_reorder_threshold,
        i.products_stocked_out,
        i.total_products_tracked,
        i.daily_stockout_rate_pct,

        -- stock utilisation ratio
        -- how much stock is held relative to the reorder threshold
        -- values above 1 indicate healthy buffer above threshold
        round(
            i.total_quantity_available /
            nullif(i.total_reorder_threshold, 0), 2 )  as stock_utilisation_ratio,

        -- shipment metrics defaulting to zero when no shipments
        coalesce(s.total_shipments, 0)  as total_shipments,
        coalesce(s.total_quantity_shipped, 0) as total_quantity_shipped,
        coalesce(s.on_time_shipments, 0)  as on_time_shipments,
        coalesce(s.late_shipments, 0)  as late_shipments,
        coalesce(s.pending_shipments, 0) as pending_shipments,
        s.daily_on_time_rate_pct,
        s.avg_delay_days

    from inventory i
    left join shipments s
        on  i.warehouse_id   = s.warehouse_id
        and i.snapshot_date  = s.shipment_date

)

select * from joined