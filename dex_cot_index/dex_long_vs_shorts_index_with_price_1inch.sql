with long_vs_shorts as (
select date(block_time), 
    sum(case when token_a_symbol in ('USDT','USDC','BUSD', 'DAI', 'UST', 'TUSD', 'USDP') then cast(token_a_amount as float) else 0 end) as long, -- buying crypto
    sum(case when token_b_symbol in ('USDT','USDC','BUSD', 'DAI', 'UST', 'TUSD', 'USDP') then cast(token_b_amount as float) else 0 end) as short, -- selling crypto
    avg(price) as price
from dex.trades as d
join (
        select avg(price) as price, 
        date(minute) as date 
        from prices.usd 
        where symbol = '1INCH' 
        group by date(minute)
     ) as p 
    on date(p.date) = date(d.block_time)
where 
    (token_a_symbol in ('USDT','USDC','BUSD', 'DAI', 'UST', 'TUSD', 'USDP') and token_b_symbol = '1INCH') or 
    (token_a_symbol = '1INCH' and token_b_symbol in ('USDT','USDC','BUSD', 'DAI', 'UST', 'TUSD', 'USDP'))
    and "block_time" >= now() - interval '36 months' 
group by date(block_time)
order by date desc
-- limit 30*12
),
normalised as (
select
date,
long-short as long_vs_short,
MIN(long-short) OVER (ORDER BY date ASC ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) AS min_long_vs_short,
MAX(long-short) OVER (ORDER BY date ASC ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) - MIN(long-short) OVER (ORDER BY date ASC ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) AS long_vs_short_range,
-- _7days,
-- MIN(_7days) OVER () AS min_7days,
-- MAX(_7days) OVER () - MIN(_7days) OVER () AS _7days_range,
price
from long_vs_shorts
)
select
date,
case 
    when long_vs_short_range = 0 then 0
    else price*(long_vs_short-min_long_vs_short)/long_vs_short_range
    end as long_vs_short_30_day_normalised,
-- 1.00*(_7days-min_7days)/_7days_range,
price
from normalised

