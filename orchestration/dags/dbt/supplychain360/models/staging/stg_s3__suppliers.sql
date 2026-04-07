
-- Grain: One row per supplier


with source as (

    select
        "supplier_id",
        "supplier_name",
        "category",
        "country"
    from {{ source('RAW_SUPPLYCHAIN', 'SUPPLIERS') }}

),

deduplicated as (

    -- 
               select distinct
                    "supplier_id",
                    "supplier_name",
                    "category",
                    "country"
               from source

),

renamed as (

               select
                                   "supplier_id"       as supplier_id,
                                   "supplier_name"     as supplier_name,
                                   "category"          as supplier_category,
                                   "country"           as supplier_country
               from deduplicated

)

select * from renamed