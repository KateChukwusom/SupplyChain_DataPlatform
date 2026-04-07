-- Cleans and standardises the raw products table
-- Deduplication,renaming and casting
-- Grain: One row per product


with source as (

    select
        "product_id",
        "product_name",
        "brand",
        "category",
        "unit_price",
        "supplier_id"
    from {{ source ('RAW_SUPPLYCHAIN', 'PRODUCTS') }}

),

deduplicated as (

   
    select distinct
        "product_id",
        "product_name",
        "brand",
        "category",
        "unit_price",
        "supplier_id"
    from source

),

renamed as (

    select
        "product_id"                                    as product_id,
        "product_name"                                  as product_name,
        "brand"                                         as product_brand,
        "category"                                      as product_category,
        cast("unit_price" as numeric(10, 2))            as unit_price,
        "supplier_id"                                   as supplier_id
    from deduplicated

)

select * from renamed