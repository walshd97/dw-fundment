CREATE OR REPLACE TABLE `fundment-dw.fees.adviser_six_month_ltv` AS

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

eligible_clients as (
    select 
      f.client_id,
      f.first_fee_month
    from first_fees f
    cross join data_end as d
    where date_diff(d.data_end_month, f.first_fee_month, month) + 1 >= 6
),

fees_with_month_number as (
  select 
    cf.client_id,
    cf.adviser_id,
    cf.fee_amount,
    ec.first_fee_month,
    cf.fee_date,
    date_diff(cf.fee_date, ec.first_fee_month, month) + 1 as month_number
  from `fundment-dw.fees.clean_fees` cf
  join eligible_clients ec
  on cf.client_id = ec.client_id
),

adviser_totals as (
  select 
    adviser_id,
    count(distinct client_id) as number_of_clients,
    round(sum(fee_amount), 2) as total_six_month_ltv,
  from fees_with_month_number
  where month_number <= 6
  group by adviser_id
)

select
  row_number() over(order by total_six_month_ltv desc) as adviser_rank,
  adviser_id, 
  number_of_clients,
  total_six_month_ltv
from adviser_totals
order by total_six_month_ltv desc;
