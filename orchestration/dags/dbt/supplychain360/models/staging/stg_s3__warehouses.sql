with source as (

            select 
                warehouse_id,
                city,
                state,
                _airbyte_extracted_at
                from {{ source('RAW_SUPPLYCHAIN', 'WAREHOUSES')}}

),

renamed as (

            select 
                warehouse_id,
                city as warehouse_city,
                state as warehouse_state,
                _airbyte_extracted_at as ingested_at
            from source
)

select * from renamed
