-- 9420.
-- B2B
-- -------------------------------------------------------------------------------------------<###>--
-- <Subdomain>    : Billing
-- <MDM Table>    : MDM.CA_BM_PRODUCT_RECORD
-- <MDM Version>  : 1.4 v1.0
-- <Legacy Table> : LEGACY.CA_BM_PRODUCT_RECORD_LDR, LEGACY.M_OFFER_M02_ADDON,
--                  LEGACY.BO_ID2ID_ADDON_OFFER
-- <Purpose>      : Load MDM table with PRODUCT instance mapping.
-- ------------------------------------------------------------------------------------------</###>--

SET @SourceDateTimeFormat = '%Y%m%d %H:%i:%s';
SET @DeductDateFormat = '%Y%m%d';
SET @DEFAULT_DATETIME = CAST(DATE('1900-01-01') AS DATETIME);

-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : CREATE INDEX
-- <Table> : MDM.INS_PROD
-- <Brief> : Create index on MDM and LEGACY tables
-- <Desc>  : 
-- ------------------------------------------------------------------------------------------</###>--

-- call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_MAP','Src_SOC_Cd,Tgt_Offer_Cd');
call LEGACY.createindex_ifnotexists('MDM','INS_PROD','PROD_ID,USER_ID');
call LEGACY.createindex_ifnotexists('LEGACY','CA_BM_PRODUCT_RECORD_LDR','OWNER_ID');
-- 
-- call LEGACY.createindex_ifnotexists('LEGACY','BO_ID2ID_ADDON_OFFER_LDR','OBJECT_ID');
call LEGACY.createindex_ifnotexists('LEGACY','BO_ID2ID_ADDON_OFFER_LDR','OFFER_CD,MDM_TYPE');

-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : CREATE TABLE
-- <Table> : MDM.CA_BM_PRODUCT_RECORD
-- <Brief> : Create another CA_BM_PRODUCT_RECORD table with different logic
-- <Desc>  : Mignon doesn't create this table at this moment.
-- ------------------------------------------------------------------------------------------</###>--

  -- -------------------------------------------------------------------------------------------<###>--
  -- <Type>  : ALTER TABLE
  -- <Table> : MDM.CA_BM_PRODUCT_RECORD
  -- <Brief> : Create PK on MDM table
  -- <Desc>  : Mignon doesn't create PK.
  -- ------------------------------------------------------------------------------------------</###>--

  CALL LEGACY.createindex_ifnotexists('MDM','CA_BM_PRODUCT_RECORD','ACCT_ID,OWNER_ID,PRODUCT_ID,OWNER_TYPE,BILLING_TYPE');
  
  -- -------------------------------------------------------------------------------------------<###>--
  -- <Type>  : INSERT
  -- <Table> : MDM.CA_BM_PRODUCT_RECORD
  -- <Brief> : Insert MDM table
  -- <Desc>  : Used for record recurring charge pre-dedution of product instance.
  -- <Filter>: Only prepaids, BILLING_TYPE = 0
  -- <Maps>  : PRODUCT_ID       - coming from INS_PROD.PROD_ID
  --           LAST_DEDUCT_TIME - 0 when is null
  --           NEXT_DEDUCT_TIME - CURRENT DATE + 2 when is null
  -- ------------------------------------------------------------------------------------------</###>--

  INSERT IGNORE INTO MDM.CA_BM_PRODUCT_RECORD
  SELECT DISTINCT
      PREC.TENANT_ID
    , PREC.ACCT_ID
    , PREC.OWNER_ID
     , COALESCE(INS.PROD_INST_ID, -1) AS PRODUCT_ID
    , COALESCE(CONCAT(SUBSTR(PREC.NEXT_DEDUCT_TIME, 1, 4)
             ,SUBSTR(PREC.NEXT_DEDUCT_TIME, 6, 2)
             ,SUBSTR(PREC.NEXT_DEDUCT_TIME, 9, 2))
           , DATE_FORMAT(DATE_ADD(CURRENT_DATE(), INTERVAL 2 DAY), @DeductDateFormat)) AS NEXT_DEDUCT_TIME
    , COALESCE(CONCAT(SUBSTR(PREC.LAST_DEDUCT_TIME, 1, 4)
             ,SUBSTR(PREC.LAST_DEDUCT_TIME, 6, 2)
             ,SUBSTR(PREC.LAST_DEDUCT_TIME, 9, 2)), 0) AS LAST_DEDUCT_TIME
    , PREC.SUCC_FLAG
    , PREC.RETRY_TIMES
    , PREC.OWNER_TYPE
    , PREC.BILLING_TYPE
--     , PREC.FEATURE_CODE
--     , PREC.SOC_SEQ_NO
--     , PREC.SOC
    FROM       LEGACY.CA_BM_PRODUCT_RECORD_LDR  PREC
  inner join LEGACY.SOC_LDR                     SOC
    on SOC.SOC_SEQ_NO  = PREC.SOC_SEQ_NO
    and SOC.CTN        = PREC.OWNER_ID		-- változik!!!
    and SOC.service_class   ='SOC' 	
  inner join LEGACY.M_OFFER_MAP                 OMAP
    on OMAP.Src_SOC_Cd = SOC.SOC
    and OMAP.Tgt_Offer_Type ='A'
  -- MT: Az alabbi egy bug. Split type eseten csak offer_id-vel lehet prod-ra keresni, vagy kulon kezelni kell a split type mappinget.
  inner join LEGACY.BO_ID2ID_ADDON_OFFER_LDR    IDID
    on IDID.OFFER_CD   = OMAP.Tgt_Offer_Cd
    and IDID.MDM_TYPE       ='PRICE_PROD'
  inner join MDM.INS_PROD                       INS
    on INS.PROD_ID     = IDID.OBJECT_ID
    and left(INS.USER_ID,9)         = PREC.OWNER_ID -- addigis
  where 1
--  and PROD_REC.BILLING_TYPE = 0
  ;

  delete from MDM.CA_BM_PRODUCT_RECORD where BILLING_TYPE<>0;
  
