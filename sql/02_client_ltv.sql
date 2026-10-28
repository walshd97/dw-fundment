create or replace table `fundment-dw.fees.client_ltv` as

with first_fees as (
    select
        client_id,
        min(date_trunc(fee_date, month)) as first_fee_month
    from `fundment-dw.fees.clean_fees`
    group by
        client_id
),

data_end as (
    select
        max(date_trunc(fee_date, month)) as data_end_month
    from `fundment-dw.fees.clean_fees`
    -- In production, current_date() could be used to calculate
    -- complete and incomplete observation periods.
),

fees_with_month as (
    select
        cf.client_id,
        cf.fee_date,
        cf.fee_amount,
        ff.first_fee_month,
        date_diff(date_trunc(cf.fee_date, month), ff.first_fee_month, month) + 1 as month_number
    from `fundment-dw.fees.clean_fees` as cf
    inner join first_fees as ff
        on cf.client_id = ff.client_id
),

ltv as (
    select
        f.client_id,
        f.first_fee_month,
        sum(if(f.month_number <= 1, f.fee_amount, 0)) as ltv_1_month,
        case
            when date_diff(d.data_end_month, f.first_fee_month, month) + 1 >= 3
            then sum(if(f.month_number <= 3, f.fee_amount, 0))
        end as ltv_3_month,
        case
            when date_diff(d.data_end_month, f.first_fee_month, month) + 1 >= 6
            then sum(if(f.month_number <= 6, f.fee_amount, 0))
        end as ltv_6_month
    from fees_with_month as f
    cross join data_end as d
    group by
        f.client_id,
        f.first_fee_month,
        d.data_end_month
)

select *
from ltv;