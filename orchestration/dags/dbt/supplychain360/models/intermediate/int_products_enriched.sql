-- -- This intermediate model enriches products with supplier information
-- -- Grain: one row per product

-- {{ config(materialized='view', schema='intermediate') }}

-- with products as (

--             select
--                 product_id,
--                 supplier_id,
--                 product_name,
--                 product_brand,
--                 product_category,
--                 unit_price,
--                 ingested_at
--             from {{ ref('stg_s3__products') }}

--         ),

-- suppliers as (

--             select
--                 supplier_id,
--                 supplier_name,
--                 supplier_category,
--                 supplier_country
--             from {{ ref('stg_s3__suppliers') }}

--         ),

-- final as (

--             select
--                 p.product_id,
--                 p.supplier_id,
--                 p.product_name,
--                 p.product_category,
--                 p.unit_price,
--                 s.supplier_name,
--                 s.supplier_category,
--                 s.supplier_country,
--                 p.ingested_at

--             from products p
--             left join suppliers s
--                 on p.supplier_id = s.supplier_id

--         )

--         select * from final