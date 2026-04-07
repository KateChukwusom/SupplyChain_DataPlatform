--  int_shipments_enriched
--  Joins shipments to product, supplier, warehouse,
--          and store dimensions to produce a fully enriched
--          shipments dataset for metrics models to build on
-- Grain: One row per shipment
        {{ config(materialized= 'incremental', unique_key= 'shipment_id')}}
with shipments as (

    --
    select
        shipment_id,
        warehouse_id,
        store_id,
        product_id,
        quantity_shipped,
        shipment_date,
        expected_delivery_date,
        actual_delivery_date,
        carrier
    from {{ ref('stg_s3__shipments') }}

),

products as (

    -- product and supplier info
    select
        product_id,
        product_name,
        product_category,
        supplier_id,
        supplier_name,
        supplier_country
    from {{ ref('dim_products') }}

),

warehouses as (

    -- warehouse location 
    select
        warehouse_id,
        warehouse_city,
        warehouse_state,
        warehouse_region
    from {{ ref('dim_warehouses') }}

),

stores as (

    -- store info for the destination of the shipment
    select
        store_id,
        store_name,
        store_city,
        store_state,
        store_region
    from {{ ref('dim_stores') }}

),

enriched as (

    select
        -- shipment 
        s.shipment_id,
        s.product_id,
        s.warehouse_id,
        s.store_id,
        s.quantity_shipped,
        s.shipment_date,
        s.expected_delivery_date,
        s.actual_delivery_date,
        s.carrier,

        -- product and supplier 
        p.product_name,
        p.product_category,
        p.supplier_id,
        p.supplier_name,
        p.supplier_country,

        -- warehouse 
        w.warehouse_city,
        w.warehouse_state,
        w.warehouse_region,

        -- store destination 
        st.store_name,
        st.store_city,
        st.store_state,
        st.store_region

    from shipments s
    left join products p
        on s.product_id = p.product_id
    left join warehouses w
        on s.warehouse_id = w.warehouse_id
    left join stores st
        on s.store_id = st.store_id

)

select * from enriched