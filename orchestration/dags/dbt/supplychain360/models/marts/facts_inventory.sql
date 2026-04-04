-- fact table focuses on daily inventory snapshot per product per warehouse
-- grain: one row per product per warehouse per snapshot date
-- composite unique key: product_id + warehouse_id + snapshot_date
-- incremental on snapshot_date — one new partition per day
-- supports: inventory planning, stockout analysis,
--           top products causing stockouts, inventory optimization



with inventory as (

    select
        -- keys
        product_id,
        warehouse_id,
        snapshot_date,

        -- product context
        product_name,
        product_category,
        supplier_id,
        supplier_name,
        unit_price,

        -- warehouse context
        warehouse_city,
        warehouse_state,
        warehouse_region,

        -- inventory measures
        quantity_available,
        reorder_threshold,

        -- derived business metrics
        is_below_reorder_threshold,
        --stock_vs_threshold,
        stock_status,
        inventory_value,

        -- audit
        ingested_at

    from {{ ref('int_inventory_enriched') }}

    {% if is_incremental() %}
        where snapshot_date > (select max(snapshot_date) from {{ this }})
    {% endif %}

)

select * from inventory