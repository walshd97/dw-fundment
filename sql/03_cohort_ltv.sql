CREATE OR REPLACE TABLE `fundment-takehome-dw.fees.cohort_ltv` AS

select
  first_fee_month as cohort,
  count(distinct client_id) as number_of_clients,
  sum(ltv_6_month) as total_six_month_ltv,
  round(avg(ltv_6_month), 2) as average_six_month_ltv
from `fundment-takehome-dw.fees.client_ltv`
where first_fee_month in (date '2025-01-01', date '2025-02-01') and ltv_6_month is not null
group by first_fee_month
order by cohort

