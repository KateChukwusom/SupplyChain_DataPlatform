
-- int_inventory_enriched
-- Purpose: Joins inventory snapshots to product and warehouse
--          dimensions to produce a fully enriched dataset
--          that intermediate metrics models build on top of
-- grain:  One row per product per warehouse per snapshot date
{{ config(
    materialized='incremental',
    unique_key=['product_id', 'warehouse_id', 'snapshot_date']
) }}

with inventory as (

    -- daily stock level snapshots per product per warehouse
    select
        product_id,
        warehouse_id,
        snapshot_date,
        quantity_available,
        reorder_threshold
    from {{ ref('stg_s3__inventory') }}

),

products as (

    -- product and supplier context
    select
        product_id,
        product_name,
        product_brand,
        product_category,
        supplier_id,
        supplier_name
    from {{ ref('dim_products') }}

),

warehouses as (

    -- warehouse location and region context
    select
        warehouse_id,
        warehouse_city,
        warehouse_state,
        warehouse_region
    from {{ ref('dim_warehouses') }}

),

enriched as (

    -- combine inventory with product and warehouse details
    select
        -- inventory 
        i.product_id,
        i.warehouse_id,
        i.snapshot_date,
        i.quantity_available,
        i.reorder_threshold,

        -- product 
        p.product_name,
        p.product_brand,
        p.product_category,
        p.supplier_id,
        p.supplier_name,

        -- warehouse t
        w.warehouse_city,
        w.warehouse_state,
        w.warehouse_region

    from inventory i
    left join products p
        on i.product_id = p.product_id
    left join warehouses w
        on i.warehouse_id = w.warehouse_id

)

select * from enriched