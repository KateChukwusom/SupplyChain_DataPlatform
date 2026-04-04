-- with inventory as (

--     select 
--             product_id,
--             warehouse_id,
--             snapshot_date,
--             quantity_available,
--             reorder_threshold,
--             ingested_at
    
--      from {{ ref('stg_s3__inventory') }}
-- ),

-- warehouses as (

--     select 
--                 warehouse_id,
--                 warehouse_city,
--                 warehouse_state
    
--     from {{ ref('stg_s3__warehouses') }}
-- ),


-- products as (

--     select 
--     *
--          from {{ ref('int_products_enriched') }}
-- ),
-- state_region as (

--     select * from {{ ref('state_region_mapping') }}
-- ),

-- joined as (

--     select

--         i.product_id,
--         i.warehouse_id,
--         i.snapshot_date,
--         i.quantity_available,
--         i.reorder_threshold,

--         -- stockout flag, a flag to measure reorder threshold against quantity available
--         {{ is_below_reorder_threshold('i.quantity_available', 'i.reorder_threshold') }}
--             as is_below_reorder_threshold,

--         p.product_name,
--         p.product_category,
--         p.unit_price,
--         p.supplier_id,
--         p.supplier_name,
--         w.warehouse_city,
--         w.warehouse_state,
--         sr.region          as warehouse_region,
--         i.ingested_at,
--         -- stock status for severity classification
--         case
--             when i.quantity_available = 0 then 'out_of_stock'
--             when i.quantity_available <= i.reorder_threshold * 0.5  then 'critical'
--             when i.quantity_available <= i.reorder_threshold then 'low'
--             else 'healthy'
--         end as stock_status,

--         -- monetary value of stock in this warehouse
--         i.quantity_available * p.unit_price  as inventory_value

--     from inventory i
--     left join products p
--         on i.product_id = p.product_id
--     left join warehouses w
--         on i.warehouse_id = w.warehouse_id
--     left join state_region sr
--         on w.warehouse_state = sr.state
-- )

-- select * from joined