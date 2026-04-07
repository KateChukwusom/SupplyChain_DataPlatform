-- Grain: One row per transaction


with source as (

    select
        "transaction_id",
        "store_id",
        "product_id",
        "quantity_sold",
        "unit_price",
        "discount_pct",
        "sale_amount",
        "transaction_timestamp"
    from {{ source('RAW_SUPPLYCHAIN', 'SALES') }}

),

deduplicated as (

    -- 
    select distinct
        "transaction_id",
        "store_id",
        "product_id",
        "quantity_sold",
        "unit_price",
        "discount_pct",
        "sale_amount",
        "transaction_timestamp"
    from source

),

renamed as (

    select
        "transaction_id"                                    as transaction_id,
        "store_id"                                          as store_id,
        "product_id"                                        as product_id,
        "quantity_sold"                                     as quantity_sold,
        cast("unit_price" as numeric(10, 2))                as unit_price,
        cast("discount_pct" as numeric(5, 4))               as discount_pct,
        cast("sale_amount" as numeric(10, 2))               as sale_amount,
        cast("transaction_timestamp" as timestamp_ntz)      as transaction_timestamp,
        cast("transaction_timestamp" as date)               as transaction_date
    from deduplicated

)

select * from renamed