{{ config(materialized='table') }}

with shipments as (

    select
        shipment_id,
        product_id,
        product_name,
        product_category,
        supplier_id,
        supplier_name,
        warehouse_id,
        warehouse_city,
        warehouse_region,
        store_id,
        store_name,
        store_city,
        store_region,
        quantity_shipped,
        shipment_date,
        expected_delivery_date,
        actual_delivery_date,
        carrier,
        delivery_delay_days,
        is_late,
        shipment_status,
        ingested_at

    from {{ ref('facts_shipments') }}

),

final as (

    select
        -- keys
        shipment_id,
        product_id,
        warehouse_id,
        store_id,

        -- context
        product_name,
        product_category,
        supplier_name,
        warehouse_city,
        warehouse_region,
        store_name,
        store_city,
        store_region,
        carrier,

        -- shipment measures
        quantity_shipped,
        shipment_date,
        expected_delivery_date,
        actual_delivery_date,
        shipment_status,
        delivery_delay_days,

        -- days in transit
        datediff(
            day,
            shipment_date,
            actual_delivery_date
        )                                                       as days_in_transit,

        -- average transit days per carrier
        round(
            avg(datediff(day, shipment_date, actual_delivery_date))
            over (partition by carrier), 2
        )                                                       as avg_transit_days_by_carrier,

        -- late shipment rate per carrier
        round(
            100.0 * sum(case when is_late then 1 else 0 end)
            over (partition by carrier)
            /
            nullif(
                count(shipment_id) over (partition by carrier), 0
            ), 2
        )                                                       as carrier_late_rate_pct,

        -- average transit days per warehouse to store region route
        round(
            avg(datediff(day, shipment_date, actual_delivery_date))
            over (partition by warehouse_id, store_region), 2
        )                                                       as avg_transit_days_by_route,

        -- audit
        ingested_at

    from shipments

)

select * from final