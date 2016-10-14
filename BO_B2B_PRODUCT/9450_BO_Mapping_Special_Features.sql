-- USE LEGACY;

/*


-------------------------------------------------------------------------------
PRODUCT, SERVICE, ATTRIBUTUM letrehozasa az MDM semaba tarifabol
-------------------------------------------------------------------------------


*/

-- MT: Ismet ide rakom azt, ami mar elkeszult 6011-ben:
-- NAS 10.11 beegetesek bovitese

SET @EFF_DT = CAST(LEGACY.CONFIG('DEF_EFF_DATE',NULL) AS DATETIME);
SET @EXP_DT = CAST(LEGACY.CONFIG('DEF_EXP_DATE',NULL) AS DATETIME);
SET @SYS_DATE = CAST(LEGACY.CONFIG('SYS_DATE',NULL) AS DATETIME);

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
select -- distinct -- mgy mt biztatasara: a group by eleget szur
  '22'         TENANT_ID          ,
  A.SER_NR     PROD_INST_ID       ,
  A.SER_NR     OFFER_USER_RELAT_ID,
  A.SER_NR     OFFER_INST_ID      ,
  T.Sub_Id     USER_ID            ,
  A.PROD_ID    PROD_ID            ,
  'PRICE_PROD' PROD_TYPE          ,
  '0'          EXPIRE_PROCESS_TYPE,
  CASE
    WHEN A.EXPIRATION_DATE < @SYS_DATE THEN '7'
    WHEN A.EFFECTIVE_DATE  > @SYS_DATE THEN '7'
    ELSE '1'
    END STATE,
  CASE
    WHEN A.EFFECTIVE_DATE > @EXP_DT THEN @EFF_DT
    ELSE COALESCE(A.EFFECTIVE_DATE, @EFF_DT)
    END            AS EFFECTIVE_DATE,
  CASE 
    WHEN A.EXPIRATION_DATE > @EXP_DT THEN @EXP_DT
    ELSE COALESCE(A.EXPIRATION_DATE, @EXP_DT)
    END            AS EXPIRE_DATE
FROM  LEGACY.M_OFFER_M01_TARIFF T
JOIN  LEGACY.M_SPECIAL_ADDONS   A
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
SELECT -- DISTINCT -- lmf
  22,
  A.SER_NR PROD_SRV_RELAT_ID,
  A.SER_NR ADDON_OFFER_INST_ID,
  A.SER_NR PROD_INST_ID,
  T.Sub_Id,
  A.SRV_ID SERVICE_ID,
  1 DEFAULT_STATE
FROM  LEGACY.M_OFFER_M01_TARIFF T
JOIN  LEGACY.M_SPECIAL_ADDONS   A
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
SELECT -- DISTINCT -- lmf
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
    WHEN A.EFFECTIVE_DATE > @EXP_DT THEN @EFF_DT
    ELSE COALESCE(A.EFFECTIVE_DATE, @EFF_DT)
    END            AS EFFECTIVE_DATE,
  CASE 
    WHEN A.EXPIRATION_DATE > @EXP_DT THEN @EXP_DT
    ELSE COALESCE(A.EXPIRATION_DATE, @EXP_DT)
    END            AS EXPIRE_DATE
FROM  LEGACY.M_OFFER_M01_TARIFF T
JOIN  LEGACY.M_SPECIAL_ADDONS   A
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

