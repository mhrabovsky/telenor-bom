-- 9430.

-- B2B
-- -------------------------------------------------------------------------------------------<###>--
-- <Subdomain>    : Billing
-- <MDM Table>    : MDM.CA_RC_BILL
-- <MDM Version>  : 1.4 v1.0
-- <Legacy Table> : LEGACY.CA_RC_BILL_LDR, LEGACY.M_OFFER_M02_ADDON,
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

-- call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M02_ADDON','Tgt_Offer_Cd,Src_SOC_Seq_No');
-- call LEGACY.createindex_ifnotexists('MDM','INS_PROD','PROD_ID,USER_ID');
call LEGACY.createindex_ifnotexists('LEGACY','CA_RC_BILL_LDR','OWNER_ID,SOC_SEQ_NO');
-- 
-- call LEGACY.createindex_ifnotexists('LEGACY','BO_ID2ID_ADDON_OFFER_LDR','OBJECT_ID');
call LEGACY.createindex_ifnotexists('LEGACY','BO_ID2ID_ADDON_OFFER_LDR','OFFER_CD,MDM_TYPE,OBJECT_ID');
call LEGACY.createindex_ifnotexists('LEGACY','SOC_LDR','CTN,SOC_SEQ_NO,service_class');
 
    -- -------------------------------------------------------------------------------------------<###>--
    -- <Type>  : ALTER TABLE
    -- <Table> : MDM.CA_RC_BILL
    -- <Brief> : Create PK on MDM table


    -- <Desc>  : Mignon doesnt create PK.
    -- ------------------------------------------------------------------------------------------</###>--

--  CALL LEGACY.createindex_ifnotexists('MDM','CA_RC_BILL','ACCT_ID,OWNER_ID,PRODUCT_ID,OWNER_TYPE,BILLING_TYPE');
CREATE UNIQUE INDEX IDX_CA_RC_BILL_2_4_7_5_16 ON MDM.CA_RC_BILL(ACCT_ID,OWNER_ID,PRODUCT_ID,OWNER_TYPE,BILLING_TYPE);

    -- -------------------------------------------------------------------------------------------<###>--
    -- <Type>  : INSERT
    -- <Table> : MDM.CA_BM_PRODUCT_RECORD
    -- <Brief> : Insert MDM table
    -- <Desc>  : Used for record recurring charge pre-dedution of product instance.
    -- <Filter>: Only prepaids, BILLING_TYPE = 0
    -- ------------------------------------------------------------------------------------------</###>--

    INSERT IGNORE INTO MDM.CA_RC_BILL
    SELECT DISTINCT
          '22'                                  as TENANT_ID
        , RCB.ACCT_ID                           as ACCT_ID
    , COALESCE(INS.PROD_INST_ID, -1)    as PROD_INST_ID
        , RCB.OWNER_ID                          as OWNER_ID
        , RCB.OWNER_TYPE                        as OWNER_TYPE
        , RCB.MEASURE_ID                        as MEASURE_ID
    , COALESCE(INS.PROD_ID, -1)        as PRODUCT_ID
        , RCB.LAST_CYCLE_BEGIN_DATE             as LAST_CYCLE_CHARGE_BEGIN_DATE
        , RCB.LAST_CYCLE_END_DATE               as LAST_CYCLE_CHARGE_END_DATE
        , RCB.LAST_CYCLE_BEGIN_DATE             as LAST_CYCLE_BEGIN_DATE
        , RCB.LAST_CYCLE_END_DATE               as LAST_CYCLE_END_DATE
        , '2001-01-01 00:00:00'                 as PROD_VALID_DATE
        , '2001-01-01 00:00:00'                 as PROD_FIRST_BILL_DATE
        , RCB.RC_CHARGE_FEE                     as RC_CHARGE_FEE
        , RCB.TAX_INCLUDE                       as TAX_INCLUDE
        , RCB.BILLING_TYPE                      as BILLING_TYPE
        , RCB.VAT_FEE                           as VAT_FEE
--   RCB.SOC_SEQ_NO
--   RCB.SOC
    FROM     LEGACY.CA_RC_BILL_LDR RCB
  inner join LEGACY.SOC_LDR                         SOC
    on SOC.SOC_SEQ_NO  = RCB.SOC_SEQ_NO
    and SOC.CTN             = RCB.OWNER_ID
    and SOC.service_class   ='SOC' 
  inner join LEGACY.M_OFFER_MAP                     OMAP 
    on OMAP.Src_SOC_Cd      = SOC.SOC
    and OMAP.Tgt_Offer_Type ='A'
  -- MT: Az alabbi egy bug. Split type eseten csak offer_id-vel lehet prod-ra keresni, vagy kulon kezelni kell a split type mappinget.
  inner join LEGACY.BO_ID2ID_ADDON_OFFER_LDR        IDID
    on IDID.OFFER_CD        = OMAP.Tgt_Offer_Cd
    and IDID.MDM_TYPE       ='PRICE_PROD'
  inner join MDM.INS_PROD                           INS
    on INS.PROD_ID          = IDID.OBJECT_ID
--    and INS.USER_ID         = RCB.OWNER_ID 
    and right(INS.USER_ID,9) = RCB.OWNER_ID -- addigis
  WHERE 1 
--  and PROD_REC.BILLING_TYPE = 1
    ;
    -- SET SQL_SAFE_UPDATES=0;
  CALL LEGACY.createindex_ifnotexists('MDM','CA_RC_BILL','BILLING_TYPE');
    delete from MDM.CA_RC_BILL where BILLING_TYPE<>1;

  
