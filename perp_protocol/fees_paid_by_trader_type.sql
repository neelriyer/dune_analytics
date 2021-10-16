-- Professional market makers: these are usually a small group of individuals and 
-- teams that do a significant amount of volume and usually trade in very high 
-- frequencies 

-- Retail Pro: these users are also a relatively small group of traders however 
-- we suspect that their characteristics are higher average volume per trade but 
-- less in frequency compared to group (1) 

-- Retail: these traders amount for the largest group of traders that we currently
-- have however we expect them to trade at a low frequency and low amounts. They 
-- are the least sophisticated out of our users 



-- More than 1000 trades in the past 30 days
-- sum of positions larger than 1,000,000 (or maybe individual trades are larger than 10K?)
WITH ProMarketMakers AS (
    SELECT  
        "trader", 
        COUNT(DISTINCT "evt_block_time") AS "number_of_trades",
        SUM("positionNotional")/10^18 AS "sum_of_position_notional",
        'Pro' AS "type"
    FROM perp."ClearingHouse_evt_PositionChanged"
    WHERE "evt_block_time" >= now() - interval '30 days' 
    GROUP BY "trader"
    HAVING COUNT(DISTINCT "evt_block_time") >= 1000 AND SUM("positionNotional")/10^18 >= 1000000 
    ORDER BY "number_of_trades" DESC
),
-- sum of positions less than 1,000,000 and greater than 10,000
-- between 100 and 1000 trades in the past 30 days
RetailPro AS (
    SELECT  
        "trader", 
        COUNT(DISTINCT "evt_block_time") AS "number_of_trades",
        SUM("positionNotional")/10^18 AS "sum_of_position_notional",
        'RetailPro' AS "type"
    FROM perp."ClearingHouse_evt_PositionChanged"
    WHERE "evt_block_time" >= now() - interval '30 days'
    GROUP BY "trader"
    HAVING COUNT(DISTINCT "evt_block_time") >= 100 AND COUNT(DISTINCT "evt_block_time") < 1000 
    AND SUM("positionNotional")/10^18 < 1000000 AND SUM("positionNotional")/10^18 >= 10000
    ORDER BY "number_of_trades" DESC
)
-- everyone else:
-- Retail

SELECT 
    date(perp."evt_block_time"), 
    sum("fee"/10^18),
    Coalesce(retp."type",pro."type",'Retail') as "trader_type"
FROM perp."ClearingHouse_evt_PositionChanged" AS perp
LEFT JOIN RetailPro AS retp ON perp."trader" = retp."trader"
LEFT JOIN ProMarketMakers AS pro ON perp."trader" = pro."trader"
-- WHERE perp."evt_block_time" >= now() - interval '30 days' 
GROUP BY date(perp."evt_block_time"), "trader_type"
ORDER BY date(perp."evt_block_time") DESC

