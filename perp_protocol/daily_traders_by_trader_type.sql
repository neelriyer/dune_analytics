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

SELECT COUNT(DISTINCT perp."trader") AS _traders,
       date(evt_block_time) AS _date,
       Coalesce(retp."type",pro."type",'Retail') as "trader_type"
    --   CASE
    --       WHEN amm = '\x0f346e19f01471c02485df1758cfd3d624e399b4' THEN 'BTC-USDC'
    --       WHEN amm = '\x8d22f1a9dce724d8c1b4c688d75f17a2fe2d32df' THEN 'ETH-USDC'
    --       WHEN amm = '\xd41025350582674144102b74b8248550580bb869' THEN 'YFI-USDC'
    --       WHEN amm = '\x6de775aabeeede8efdb1a257198d56a3ac18c2fd' THEN 'DOT-USDC'
    --       WHEN amm = '\xb397389b61cbf3920d297b4ea1847996eb2ac8e8' THEN 'SNX-USDC'
    --       WHEN amm = '\x80daf8abd5a6ba182033b6464e3e39a0155dcc10' THEN 'LINK-USDC'
    --       WHEN amm = '\x16a7ecf2c27cb367df36d39e389e66b42000e0df' THEN 'AAVE-USDC'
    --       WHEN amm = '\xf559668108ff57745d5e3077b0a7dd92ffc6300c' THEN 'SUSHI-USDC'
    --       WHEN amm = '\x33fbaefb2dcc3b7e0b80afbb4377c2eb64af0a3a' THEN 'COMP-USDC'
    --       WHEN amm = '\x922f28072babe6ea0c0c25ccd367fda0748a5ec7' THEN 'REN-USDC'
    --       WHEN amm = '\xfcae57db10356fcf76b6476b21ac14c504a45128' THEN 'PERP-USDC'
    --       WHEN amm = '\xeac6cee594edd353351babc145c624849bb70b11' THEN 'UNI-USDC'
    --       WHEN amm = '\xab08ff2c726f2f333802630ee19f4146385cc343' THEN 'CRV-USDC'
    --       WHEN amm = '\xb48f7accc03a3c64114170291f352b37eea26c0b' THEN 'MKR-USDC'
    --       WHEN amm = '\x7b479a0a816ca33f8eb5a3312d1705a34d2d4c82' THEN 'CREAM-USDC'
    --       WHEN amm = '\x187c938543f2bde09fe39034fe3ff797a3d35ca0' THEN 'GRT-USDC'
    --       WHEN amm = '\x26789518695b56e16f14008c35dc1b281bd5fc0e' THEN 'ALPHA-USDC'
    --       WHEN amm = '\x838b322610bd99a449091d3bf3fba60d794909a9' THEN 'FTT-USDC'
    --   END AS _market
FROM perp."ClearingHouse_evt_PositionChanged" as perp
LEFT JOIN RetailPro AS retp ON perp."trader" = retp."trader"
LEFT JOIN ProMarketMakers AS pro ON perp."trader" = pro."trader"
WHERE evt_block_time > now() - interval '30 days'
GROUP BY date(evt_block_time), "trader_type"
ORDER BY date(evt_block_time) DESC