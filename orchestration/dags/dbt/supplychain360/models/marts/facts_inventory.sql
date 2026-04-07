-- ============================================================
-- Model: fct_inventory_snapshots
--  Immutable daily record of stock levels per
--          product per warehouse — the raw material for
--          any inventory analysis
-- Grain: One row per product per warehouse per snapshot date
-- Depends on: int_inventory_enriched
-- 

        {{ config(materialized='incremental', unique_key =['product_id', 'warehouse_id', 'snapshot_date'])}}

with inventory as (

    select
        product_id,
        warehouse_id,
        snapshot_date,
        quantity_available,
        reorder_threshold,
        warehouse_region,

        -- stockout flag for quick filtering
        case
            when quantity_available <= reorder_threshold then true
            else                                              false
        end                                         as is_stockout

    from {{ ref('int_inventory_enriched') }}

)

select * from inventory