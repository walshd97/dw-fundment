CREATE OR REPLACE TABLE `fundment-dw.fees.clean_fees` AS

with deduplicated as (
  select distinct 
    client_id, 
    client_nino, 
    adviser_id, 
    fee_date, 
    fee_amount
  from `fundment-dw.fees.raw_fees`
)
select
  client_id, 
  client_nino,
  adviser_id,
  fee_date,
  round(fee_amount, 2) as fee_amount
from deduplicated
