
--  facts_inventory
-- daily record of stock levels per product per warehouse 
-- Grain: One row per product per warehouse per snapshot date

 

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