with source as (
        select 
            _airbyte_extracted_at,
            product_id,
            product_name,
            brand,
            category,
            unit_price,
            supplier_id

        from {{ source('RAW_SUPPLYCHAIN', 'PRODUCTS')}}

),
renamed as (
             select 
                _airbyte_extracted_at as ingested_at,
                product_id,
                product_name,
                brand as product_brand,
                category as product_category,
                cast(unit_price as numeric(10,2)) as unit_price , 
                supplier_id

            from source
)

select * from renamed


