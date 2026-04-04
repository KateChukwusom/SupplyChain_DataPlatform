with source as (

    select
        _airbyte_extracted_at,
        transaction_id,
        store_id,
        product_id,
        quantity_sold,
        unit_price,
        discount_pct,
        sale_amount,
        transaction_timestamp,
        _source_table
    from {{ source('RAW_SUPPLYCHAIN', 'SALES') }}
),

renamed as (

    select
        transaction_id,
        store_id,
        product_id,
        quantity_sold,
        cast(unit_price as numeric(10, 2))          as unit_price,
        cast(discount_pct as numeric(5, 4))         as discount_pct,
        cast(sale_amount as numeric(10, 2))         as sale_amount,
        cast(transaction_timestamp as timestamp_ntz) as transaction_timestamp,
        cast(transaction_timestamp as date)         as transaction_date,
        _source_table                               as source_table,
        _airbyte_extracted_at                       as ingested_at

    from source
)

select * from renamed