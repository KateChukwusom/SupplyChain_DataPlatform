-- 
--  dim_date
-- Date dimension covering all dates needed across
--          the project — sales, shipments, inventory snapshots
-- Grain: One row per calendar date
-- Note: Date spine runs from 2015-01-01 to 2026-12-31



with date_spine as (

    -- generate one row per day between the start and end dates
    select
        dateadd('day', seq4(), '2015-01-01'::date)  as date_day
    from table(generator(rowcount => 4383))         -- 12 years of dates

),

dates as (

    select
        date_day,

        -- calendar attributes
        year(date_day)                              as year,
        month(date_day)                             as month_number,
        monthname(date_day)                         as month_name,
        quarter(date_day)                           as quarter_number,
        'Q' || quarter(date_day)                    as quarter_name,
        dayofweek(date_day)                         as day_of_week,
        dayname(date_day)                           as day_name,
        dayofyear(date_day)                         as day_of_year,

        -- period helpers for trend analysis
        date_trunc('month', date_day)               as first_day_of_month,
        date_trunc('quarter', date_day)             as first_day_of_quarter,
        date_trunc('year', date_day)                as first_day_of_year,

        -- weekend flag
        case
            when dayofweek(date_day) in (0, 6)      then true
            else                                         false
        end                                         as is_weekend

    from date_spine

)

select * from dates