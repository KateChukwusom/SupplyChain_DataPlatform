with source as (

    select
        _airbyte_extracted_at,
        store_id,
        store_name,
        city,
        state,
        region,
        store_open_date
    from {{ source('RAW_SUPPLYCHAIN', 'STORES') }}
),

renamed as (

    select
        
        store_id,
        store_name,
        city                                            as store_city,
        state                                           as store_state,
        region                                          as store_region,
        try_to_date(store_open_date, 'DD/MM/YYYY')      as store_open_date,
        _airbyte_extracted_at                           as ingested_at

    from source
)

select * from renamed