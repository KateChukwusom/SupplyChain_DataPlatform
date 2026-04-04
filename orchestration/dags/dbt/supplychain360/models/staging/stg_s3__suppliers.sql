with sources as (

            select 
                 _airbyte_extracted_at,
                 supplier_name,
                 supplier_id,
                 category,
                 country
            from {{ source('RAW_SUPPLYCHAIN', 'SUPPLIERS') }}
), 
renamed as (

            select 
                _airbyte_extracted_at as ingested_at,
                 supplier_name,
                 supplier_id,
                 category as supplier_category,
                 country as supplier_country
            from sources
)

select * from renamed