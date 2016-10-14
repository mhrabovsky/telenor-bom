-- 5390.
-- USE LEGACY;

-- NAS 10.04 beegetesek bovitese
SET @EFF_DATE = CAST(LEGACY.CONFIG('DEF_EFF_DATE',NULL) AS DATE);
SET @EXP_DATE = CAST(LEGACY.CONFIG('DEF_EXP_DATE',NULL) AS DATE);

DROP TABLE if exists LEGACY.M_OFFER_M20_MERGE_ALL;

call LEGACY.createindex_ifnotexists('LEGACY','M_USER','Sub_id');
call LEGACY.createindex_ifnotexists('LEGACY','M_SOC','SOC_Seq_No');

CREATE TABLE LEGACY.M_OFFER_M20_MERGE_ALL AS
    SELECT /*STRAIGHT_JOIN*/
            U.CA_Id
    ,       U.BAN
    ,       U.BEN
    ,       U.CTN
    ,       U.IMSI
    ,       U.Init_Act_Dt
    ,       U.Eff_Dt                                    AS  User_Eff_Dt
    ,       U.Exp_Dt                                    AS  User_Exp_Dt
    ,       U.Sub_Status_Cd
    ,       U.Sub_Status_Last_Act
    ,       U.Sub_Status_Rsn_Cd
    ,       O.Tgt_Offer_Inst_Id
    ,       O.Tgt_Offer_Cd
    ,       O.Tgt_Offer_Id
    ,       O.Tgt_Offer_Name
    ,       O.Tgt_Offer_Type
    ,       COALESCE(S.Svc_Class_Cd, O.Tgt_Offer_Type)  AS  Svc_Class_Cd
    ,       COALESCE(S.Eff_Dt, U.Eff_Dt)                AS  Offer_Eff_Dt
    ,       COALESCE(S.Exp_Dt, U.Exp_Dt)                AS  Offer_Exp_Dt
    ,       cast(NULL as char(9))                       AS  Feature_Seq_No
    ,       cast(NULL as char(9))                       AS  Feature_Cd
    ,       cast(NULL as datetime)                      AS  Feature_Eff_Dt
    ,       cast(NULL as datetime)                      AS  Feature_Exp_Dt
    ,       cast(NULL as CHAR(1))                       AS Main_Prod_Ind
--    ,       cast(NULL as bigint(20))                    AS Product_Id
    ,       O.Product_Id
    ,       cast(NULL as char(30))                      AS MDM_Type_Cd
    ,       O.Service_Id                                AS  Service_Id
    ,       O.Service_Attr_Id                           AS  Service_Attr_Id
    ,       O.Service_Attr_Value                        AS  Service_Attr_Value  
    ,       O.Sub_id
    -- ---
    ,       O.Sub_Type
    ,       O.SUBSCRIBER_REF
    ,       O.VOICE_BILLING_INCREMENT
    ,       O.Split_Type
    -- ---
    FROM        LEGACY.M_OFFER_M10_MERGE        AS  O
    INNER JOIN  LEGACY.M_USER                   AS  U
            ON  U.Sub_Id = O.Sub_Id
    LEFT  JOIN  LEGACY.M_SOC                    AS  S
            ON  O.Src_SOC_Seq_No = S.SOC_Seq_No
;


 

DROP VIEW IF EXISTS LEGACY.SOC_FEATURE_OFFER_MAPPING;
DROP TABLE IF EXISTS LEGACY.SOC_FEATURE_OFFER_MAPPING;



create TABLE LEGACY.SOC_FEATURE_OFFER_MAPPING as
SELECT DISTINCT
  CA_Id                                                 CA,
  BAN                                                   BAN,
  BEN                                                   BEN,
  CTN                                                   CTN,
  IMSI                                                  IMSI,
  COALESCE(CAST(Init_Act_Dt AS DATE),@EXP_DATE)         INIT_ACTIVATION_DATE,
  COALESCE(CAST(User_Eff_Dt AS DATE),@EFF_DATE)         USER_EFFECTIVE_DATE,
  COALESCE(CAST(User_Exp_Dt AS DATE),@EXP_DATE)         USER_EXPIRATION_DATE,
  ''                                                    SUBSCRIBER_REF,
  Sub_Status_Cd                                         SUB_STATUS,
  Sub_Status_Last_Act                                   SUB_STATUS_LAST_ACT,
  Sub_Status_Rsn_Cd                                     SUB_STATUS_RSN_CODE,
  Tgt_Offer_Inst_Id                                     MAIN_SOC_SEQ_NO,
  Tgt_Offer_Cd                                          MAIN_SOC_CODE,
  Tgt_Offer_Inst_Id                                     SOC_SEQ_NO,
  Tgt_Offer_Cd                                          SOC_CODE,
  '0'                                                   MAP_COMBO_ID,
  Tgt_Offer_Cd                                          TEMP_OFFER_CODE,
  Tgt_Offer_Id                                          VERIS_OFFER_ID,
  Tgt_Offer_Name                                        OFFER_NAME,
  Tgt_Offer_Type                                        OFFER_TYPE,
  Svc_Class_Cd                                          SERVICE_CLASS_CD,
  COALESCE(CAST(Offer_Eff_Dt AS DATE),@EFF_DATE)         SOC_EFFECTIVE_DATE,
  COALESCE(CAST(Offer_Exp_Dt AS DATE),@EXP_DATE)         SOC_EXPIRATION_DATE,
  Feature_Seq_No                                        FEATURE_SEQ_NO,
  COALESCE(CAST(Feature_Eff_Dt AS DATE),@EFF_DATE)      FEATURE_EFFECTIVE_DATE,
  COALESCE(CAST(Feature_Exp_Dt AS DATE),@EXP_DATE)      FEATURE_EXPIRATION_DATE,
  Feature_Cd                                            LEGACY_FEATURE_CODE,
  COALESCE(Main_Prod_Ind,'N')                           MAIN_FEATURE_FLAG,
  Product_Id                                            VERIS_PRODUCT_ID,
  MDM_Type_Cd                                           MDM_TYPE,
  Service_Id                                            VERIS_SERVICE_ID,
  Service_Attr_Id                                       VERIS_SERVICE_ATTR_ID,
  Service_Attr_Value                                    SERVICE_ATTR_VALUE
FROM LEGACY.M_OFFER_M20_MERGE_ALL
;
