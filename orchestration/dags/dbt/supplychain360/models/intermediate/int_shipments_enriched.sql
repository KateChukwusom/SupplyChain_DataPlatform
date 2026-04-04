-- -- intermediate model: enriches shipments with warehouse, store and product context
-- -- delivery delay and is_late business logic applied here
-- -- one row per shipment

-- {{ config(materialized='view') }}

-- with shipments as (

--     select
--         shipment_id,
--         warehouse_id,
--         store_id,
--         product_id,
--         quantity_shipped,
--         shipment_date,
--         expected_delivery_date,
--         actual_delivery_date,
--         carrier,
--         ingested_at
--     from {{ ref('stg_s3__shipments') }}

-- ),

-- warehouses as (

--     select
--         warehouse_id,
--         warehouse_city,
--         warehouse_state
--     from {{ ref('stg_s3__warehouses') }}

-- ),

-- stores as (

--     select
--         store_id,
--         store_name,
--         store_city,
--         store_state,
--         store_region,
--         store_open_date
--     from {{ ref('stg_gsheets__stores') }}

-- ),

-- products as (

--     select
--         product_id,
--         product_name,
--         product_category,
--         supplier_id,
--         supplier_name
--     from {{ ref('int_products_enriched') }}

-- ),

-- state_region as (

--     select
--         state,
--         region
--     from {{ ref('state_region_mapping') }}

-- ),

-- joined as (

--     select
--         -- business keys
--         sp.shipment_id,
--         sp.warehouse_id,
--         sp.store_id,
--         sp.product_id,

--         -- warehouse context
--         w.warehouse_city,
--         w.warehouse_state,
--         sr.region               as warehouse_region,

--         -- store context
--         -- store_region already exists in staging, no join needed
--         st.store_name,
--         st.store_city,
--         st.store_state,
--         st.store_region,

--         -- product context
--         p.product_name,
--         p.product_category,
--         p.supplier_id,
--         p.supplier_name,

--         -- shipment measures
--         sp.quantity_shipped,
--         sp.shipment_date,
--         sp.expected_delivery_date,
--         sp.actual_delivery_date,
--         sp.carrier,

--         -- delivery performance business logic
--         -- positive = late, zero = on time, negative = early
--         {{ delivery_delay_days('sp.expected_delivery_date', 'sp.actual_delivery_date') }}
--                                 as delivery_delay_days,

--         -- late flag derived from delay
--         case
--             when {{ delivery_delay_days('sp.expected_delivery_date', 'sp.actual_delivery_date') }} > 0
--             then true
--             else false
--         end                     as is_late,

--         -- audit
--         sp.ingested_at,
--         -- cleaner boolean for supplier performance aggregation
--         case
--             when sp.actual_delivery_date <= sp.expected_delivery_date then true
--             else false
--         end                                         as is_on_time,

--         -- shipment lifecycle status
--         case
--             when sp.actual_delivery_date is null
--                 then 'in_transit'
--             when sp.actual_delivery_date <= sp.expected_delivery_date
--                 then 'delivered_on_time'
--             when sp.actual_delivery_date > sp.expected_delivery_date
--                 then 'delivered_late'
--         end                                         as shipment_status

--     from shipments sp
--     left join warehouses w
--         on sp.warehouse_id = w.warehouse_id
--     left join stores st
--         on sp.store_id = st.store_id
--     left join products p
--         on sp.product_id = p.product_id
--     left join state_region sr
--         on w.warehouse_state = sr.state

-- )

-- -- select * from joined