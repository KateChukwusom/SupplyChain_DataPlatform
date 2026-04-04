{{ config(materialized='table') }}

with inventory as (

    select
        product_id,
        warehouse_id,
        snapshot_date,
        product_name,
        product_category,
        supplier_id,
        supplier_name,
        warehouse_city,
        warehouse_state,
        warehouse_region,
        quantity_available,
        reorder_threshold,
        inventory_value,
        is_below_reorder_threshold,
        stock_status,
        ingested_at

    from {{ ref('facts_inventory') }}

),

sales as (

    select
        product_id,
        transaction_date,
        sum(quantity_sold)                                      as daily_units_sold

    from {{ ref('facts_sales') }}
    group by 1, 2

),

avg_velocity as (

    select
        product_id,
        round(avg(daily_units_sold), 2)                        as avg_daily_units_sold

    from sales
    group by 1

),

final as (

    select
        -- keys
        inventory.product_id,
        inventory.warehouse_id,
        inventory.snapshot_date,

        -- context
        inventory.product_name,
        inventory.product_category,
        inventory.supplier_id,
        inventory.supplier_name,
        inventory.warehouse_city,
        inventory.warehouse_region,

        -- inventory measures
        inventory.quantity_available,
        inventory.reorder_threshold,
        inventory.inventory_value,
        inventory.stock_status,
        inventory.is_below_reorder_threshold,

        -- sales velocity
        coalesce(avg_velocity.avg_daily_units_sold, 0)         as avg_daily_units_sold,

        -- days of stock remaining
        case
            when coalesce(
                avg_velocity.avg_daily_units_sold, 0
            ) = 0 then null
            else round(
                inventory.quantity_available /
                avg_velocity.avg_daily_units_sold, 1
            )
        end                                                     as days_of_stock_remaining,

        -- overstock flag
        case
            when coalesce(
                avg_velocity.avg_daily_units_sold, 0
            ) = 0 then null
            when round(
                inventory.quantity_available /
                avg_velocity.avg_daily_units_sold, 1
            ) > 90 then true
            else false
        end                                                     as is_overstocked,

        -- cumulative stockout days per product per warehouse
        sum(
            case when inventory.is_below_reorder_threshold
                then 1 else 0
            end
        ) over (
            partition by inventory.product_id, inventory.warehouse_id
            order by inventory.snapshot_date
            rows between unbounded preceding and current row
        )                                                       as cumulative_stockout_days,

        -- audit
        inventory.ingested_at

    from inventory
    left join avg_velocity
        on inventory.product_id = avg_velocity.product_id

)

select * from final