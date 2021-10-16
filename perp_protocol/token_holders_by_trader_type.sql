-- not working!

WITH transfers AS (
    SELECT
    evt_tx_hash AS tx_hash,
    tr."from" AS address,
    -tr.value AS amount,
    contract_address
     FROM erc20."ERC20_evt_Transfer" tr
     WHERE contract_address =  '\xbc396689893d065f41bc2c6ecbee5e0085233447'
UNION ALL
    SELECT
    evt_tx_hash AS tx_hash,
    tr."to" AS address,
    tr.value AS amount,
      contract_address
     FROM erc20."ERC20_evt_Transfer" tr 
     where contract_address = '\xbc396689893d065f41bc2c6ecbee5e0085233447'
),
transferAmounts AS (
    SELECT address,
    
    sum(amount)/1e18 as poolholdings FROM transfers 
    
    GROUP BY 1
    ORDER BY 2 DESC
)

SELECT 
COUNT(DISTINCT(address)) as holders

FROM transferAmounts
WHERE poolholdings > 0.01