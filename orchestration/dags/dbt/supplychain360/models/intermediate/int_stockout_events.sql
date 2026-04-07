
-- int_stockout_events
--  Detects stockout events from enriched inventory
--          data and calculates duration per event
--  One row per stockout event per product per warehouse


with inventory as (

    -- 
    select
        product_id,
        warehouse_id,
        snapshot_date,
        quantity_available,
        reorder_threshold,
        product_name,
        product_brand,
        product_category,
        supplier_id,
        supplier_name,
        warehouse_city,
        warehouse_state,
        warehouse_region
    from {{ ref('int_inventory_enriched') }}

),

stockout_flagged as (

    select
        product_id,
        warehouse_id,
        snapshot_date,
        quantity_available,
        reorder_threshold,
        product_name,
        product_brand,
        product_category,
        supplier_id,
        supplier_name,
        warehouse_city,
        warehouse_state,
        warehouse_region,

        -- flag each day as a stockout using boolean
        -- true when stock is at or below the reorder threshold
        case
            when quantity_available <= reorder_threshold then true
            else false
        end as is_stockout

    from inventory

),

stockout_groups as (

    select
        product_id,
        warehouse_id,
        snapshot_date,
        quantity_available,
        reorder_threshold,
        product_name,
        product_brand,
        product_category,
        supplier_id,
        supplier_name,
        warehouse_city,
        warehouse_state,
        warehouse_region,
        is_stockout,

        -- group consecutive stockout days into a single event
        -- this works by counting how many healthy days have
        -- passed so far — consecutive stockout days share
        -- the same count and are therefore one event
        sum(case when is_stockout = false then 1 else 0 end)
            over (
                partition by product_id, warehouse_id
                order by snapshot_date
                rows between unbounded preceding and current row
            )  as stockout_event_group

    from stockout_flagged

),

stockout_events as (

    select
        product_id,
        warehouse_id,
        product_name,
        product_brand,
        product_category,
        supplier_id,
        supplier_name,
        warehouse_city,
        warehouse_state,
        warehouse_region,
        stockout_event_group,
        min(snapshot_date)   as stockout_start_date,
        max(snapshot_date)   as stockout_end_date,
        datediff('day',
            min(snapshot_date),
            max(snapshot_date)) + 1   as stockout_duration_days,
        min(quantity_available)  as min_quantity_during_stockout,
        max(reorder_threshold)   as reorder_threshold

    from stockout_groups
    where is_stockout = true
    group by
        product_id,
        warehouse_id,
        product_name,
        product_brand,
        product_category,
        supplier_id,
        supplier_name,
        warehouse_city,
        warehouse_state,
        warehouse_region,
        stockout_event_group

)

select
    product_id,
    warehouse_id,
    product_name,
    product_brand,
    product_category,
    supplier_id,
    supplier_name,
    warehouse_city,
    warehouse_state,
    warehouse_region,
    stockout_start_date,
    stockout_end_date,
    stockout_duration_days,
    min_quantity_during_stockout,
    reorder_threshold

from stockout_events