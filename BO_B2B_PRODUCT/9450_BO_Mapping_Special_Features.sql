
USE LEGACY;

/*


-------------------------------------------------------------------------------
PRODUCT, SERVICE, ATTRIBUTUM letrehozasa az MDM semaba tarifabol
-------------------------------------------------------------------------------


*/

-- MT: Ismet ide rakom azt, ami mar elkeszult 6011-ben:
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M01_TARIFF','CTN,BAN,BEN');



INSERT INTO MDM.INS_PROD (
  TENANT_ID,
  PROD_INST_ID,
  OFFER_USER_RELAT_ID,
  OFFER_INST_ID,
  USER_ID,
  PROD_ID,
  PROD_TYPE,
  EXPIRE_PROCESS_TYPE,
  STATE,
  EFFECTIVE_DATE,
  EXPIRE_DATE
  )
select distinct
  '22'         TENANT_ID          ,
  A.SER_NR     PROD_INST_ID       ,
  A.SER_NR     OFFER_USER_RELAT_ID,
  A.SER_NR     OFFER_INST_ID      ,
  T.Sub_Id     USER_ID            ,
  A.PROD_ID    PROD_ID            ,
  'PRICE_PROD' PROD_TYPE          ,
  '0'          EXPIRE_PROCESS_TYPE,
  CASE
    WHEN A.EXPIRATION_DATE < SYSDATE() THEN '7'
    WHEN A.EFFECTIVE_DATE  > SYSDATE() THEN '7'
    ELSE '1'
    END STATE,
  CASE
    WHEN A.EFFECTIVE_DATE > '2099-12-31 23:59:59' THEN '1900-01-01 00:00:00'
    ELSE COALESCE(A.EFFECTIVE_DATE,'1900-01-01 00:00:00')
    END            AS EFFECTIVE_DATE,
  CASE 
    WHEN A.EXPIRATION_DATE > '2099-12-31 23:59:59' THEN '2099-12-31 23:59:59'
    ELSE COALESCE(A.EXPIRATION_DATE,'2099-12-31 23:59:59')
    END            AS EXPIRE_DATE
FROM  M_OFFER_M01_TARIFF T
JOIN  M_SPECIAL_ADDONS   A
  ON  A.CTN=T.CTN
  AND A.BAN=T.BAN
  AND A.BEN=T.BEN
WHERE A.USE_FLAG = 'Y'
  AND A.TGT_OFFER_ID > 0
  AND A.PROD_ID > 0
group by  -- Olyan a logika, hogy lehet tobbszorozes A-ban, amit itt egyelunk ki.
  T.CA_ID,
  T.CTN,
  A.TGT_OFFER_ID
;


INSERT INTO MDM.INS_PROD_INS_SRV (
  TENANT_ID,
  PROD_SRV_RELAT_ID,
  OFFER_INST_ID,
  PROD_INST_ID,
  USER_ID,
  SERVICE_ID,
  STATE
)
SELECT DISTINCT
  22,
  A.SER_NR PROD_SRV_RELAT_ID,
  A.SER_NR ADDON_OFFER_INST_ID,
  A.SER_NR PROD_INST_ID,
  T.Sub_Id,
  A.SRV_ID SERVICE_ID,
  1 DEFAULT_STATE
FROM  M_OFFER_M01_TARIFF T
JOIN  M_SPECIAL_ADDONS   A
  ON  A.CTN=T.CTN
  AND A.BAN=T.BAN
  AND A.BEN=T.BEN
WHERE A.USE_FLAG = 'Y'
  AND A.TGT_OFFER_ID > 0
  AND A.PROD_ID > 0
  AND A.SRV_ID > 0
group by  -- Olyan a logika, hogy lehet tobbszorozes A-ban, amit itt egyelunk ki.
  T.CA_ID,
  T.CTN,
  A.TGT_OFFER_ID
;


INSERT INTO MDM.INS_SRV_ATTR (
  TENANT_ID            ,
  ATTR_INST_ID         ,
  PROD_SRV_RELAT_ID    ,
  OFFER_INST_ID        ,
  USER_ID              ,
  SERVICE_ID           ,
  ATTR_ID              ,
  ATTR_VALUE           ,
  ATTR_TEXT            ,
  STATE                ,
  SORT_ID              ,
  ATTR_BATCH           ,
  EFFECTIVE_DATE       ,
  EXPIRE_DATE
)
SELECT DISTINCT
  22                   ,
  A.SER_NR             ,
  A.SER_NR             ,
  A.SER_NR             ,
  T.Sub_Id      USER_ID,
  A.SRV_ID   SERVICE_ID,
  A.ATTR_ID            ,
  A.ATTR_VALUE         ,
  A.ATTR_VALUE         ,
  1                    ,
  null                 , -- legacy.sort_id
  null                 , -- family phone number
  CASE
    WHEN A.EFFECTIVE_DATE > '2099-12-31 23:59:59' THEN '1900-01-01 00:00:00'
    ELSE COALESCE(A.EFFECTIVE_DATE,'1900-01-01 00:00:00')
    END            AS EFFECTIVE_DATE,
  CASE 
    WHEN A.EXPIRATION_DATE > '2099-12-31 23:59:59' THEN '2099-12-31 23:59:59'
    ELSE COALESCE(A.EXPIRATION_DATE,'2099-12-31 23:59:59')
    END            AS EXPIRE_DATE
FROM  M_OFFER_M01_TARIFF T
JOIN  M_SPECIAL_ADDONS   A
  ON  A.CTN=T.CTN
  AND A.BAN=T.BAN
  AND A.BEN=T.BEN
WHERE A.USE_FLAG = 'Y'
  AND A.TGT_OFFER_ID > 0
  AND A.PROD_ID > 0
  AND A.SRV_ID > 0
  AND A.ATTR_ID > 0
group by  -- Olyan a logika, hogy lehet tobbszorozes A-ban, amit itt egyelunk ki.
  T.CA_ID,
  T.CTN,
  A.TGT_OFFER_ID
;

