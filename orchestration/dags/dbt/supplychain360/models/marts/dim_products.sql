
-- Model: dim_product
-- Purpose: Product dimension combining product attributes
--          and supplier details in one place
-- Grain: One row per product

with products as (

    select
        product_id,
        product_name,
        product_brand,
        product_category,
        unit_price,
        supplier_id
    from {{ ref('stg_s3__products') }}

),

suppliers as (

    select
        supplier_id,
        supplier_name,
        supplier_category,
        supplier_country
    from {{ ref('stg_s3__suppliers') }}

),

joined as (

            -- To enable downstream users query only dim_products, hence joining the suppliers table
    select
        p.product_id,
        p.product_name,
        p.product_brand,
        p.product_category,
        p.unit_price,
        p.supplier_id,
        s.supplier_name,
        s.supplier_category,
        s.supplier_country

    from products p
    left join suppliers s
        on p.supplier_id = s.supplier_id

)

select * from joined