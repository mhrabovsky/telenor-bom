-- 5390.
-- USE LEGACY;

-- NAS 10.04 beegetesek bovitese
SET @EFF_DATE = CAST(LEGACY.CONFIG('DEF_EFF_DATE',NULL) AS DATE);
SET @EXP_DATE = CAST(LEGACY.CONFIG('DEF_EXP_DATE',NULL) AS DATE);

-- -------------------------------------------------------------------------------------------------------
-- MT: Valamiert le van az egesz attributumos tema allitva. Csak a Split_Type=4-re megprobalom beinditani:
update LEGACY.M_OFFER_M20_MERGE_ALL
set
--   Main_Prod_Ind='Y',
  Service_Attr_Id='810301'
where Split_Type=4
;


-- call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M12_MERGE_PRD','Sub_Id,Tgt_Offer_Cd,Feature_Seq_No');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M20_MERGE_ALL','Sub_Id,Tgt_Offer_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M20_MERGE_ALL','Sub_Id,Tgt_Offer_Id');

DROP TABLE IF EXISTS LEGACY.M_OFFER_M20_MERGE_ALL_WORK;


CREATE TABLE  LEGACY.M_OFFER_M20_MERGE_ALL_WORK AS
    SELECT
            M.CA_Id
    ,       M.Sub_Id
    ,       M.BAN
    ,       M.BEN
    ,       M.CTN
    ,       M.IMSI
    ,       M.Init_Act_Dt
    ,       M.User_Eff_Dt
    ,       M.User_Exp_Dt
    ,       M.Sub_Status_Cd
    ,       M.Sub_Status_Last_Act
    ,       M.Sub_Status_Rsn_Cd
    ,       M.Tgt_Offer_Inst_Id
    ,       M.Tgt_Offer_Cd
    ,       M.Tgt_Offer_Id
    ,       M.Tgt_Offer_Name
    ,       M.Tgt_Offer_Type
    ,       M.Svc_Class_Cd
    ,       M.Offer_Eff_Dt
    ,       M.Offer_Exp_Dt
    ,       P.Feature_Seq_No                                                     AS  Feature_Seq_No
    ,       P.Feature_Cd                                                         AS  Feature_Cd
    ,       COALESCE(P.Eff_Dt, M.Feature_Eff_Dt)                                 AS  Feature_Eff_Dt
    ,       COALESCE(P.Exp_Dt, M.Feature_Exp_Dt)                                 AS  Feature_Exp_Dt
    ,       P.Main_Prod_Ind
    ,       P.Product_Id
    ,       P.MDM_Type_Cd
    ,       CASE WHEN (P.Main_Prod_Ind = 'Y' or M.Split_Type=4 )
                 THEN M.Service_Id
                 ELSE NULL
            END                                                                  AS  Service_Id
    ,       CASE WHEN (P.Main_Prod_Ind = 'Y' or M.Split_Type=4 )
                 THEN M.Service_Attr_Id
                 ELSE NULL
            END                                                                  AS  Service_Attr_Id
    ,       CASE WHEN ((P.Main_Prod_Ind = 'Y' or M.Split_Type=4) AND M.Service_Attr_Id IS NOT NULL)
                 THEN M.Service_Attr_Value
                 ELSE NULL
            END                                                                  AS  Service_Attr_Value
--    ,       M.Service_Attr_Value                                               AS  Service_Attr_Value

    FROM        LEGACY.M_OFFER_M20_MERGE_ALL   AS  M
    INNER JOIN  LEGACY.M_OFFER_M12_MERGE_PRD   AS  P
                    ON  (
                                M.Sub_Id       = P.Sub_Id
                            AND M.Tgt_Offer_Cd = P.Tgt_Offer_Cd
                            AND P.Feature_Seq_No IS NOT NULL
                        )

;


DROP TABLE IF EXISTS LEGACY.SOC_FEATURE_OFFER_MAPPING;

CREATE TABLE LEGACY.SOC_FEATURE_OFFER_MAPPING AS

SELECT DISTINCT
      CA_Id                                                   AS CA
    , Sub_Id						      AS USER_ID
    , BAN                                                     AS BAN
    , BEN                                                     AS BEN
    , CTN                                                     AS CTN
    , IMSI                                                    AS IMSI    
    , COALESCE(CAST(Init_Act_Dt AS DATE), @EXP_DATE)          AS INIT_ACTIVATION_DATE
    , COALESCE(CAST(User_Eff_Dt AS DATE), @EFF_DATE)          AS USER_EFFECTIVE_DATE
    , COALESCE(CAST(User_Exp_Dt AS DATE), @EXP_DATE)          AS USER_EXPIRATION_DATE
    , ''                                                      AS SUBSCRIBER_REF
    , Sub_Status_Cd                                           AS SUB_STATUS
    , Sub_Status_Last_Act                                     AS SUB_STATUS_LAST_ACT
    , Sub_Status_Rsn_Cd                                       AS SUB_STATUS_RSN_CODE
    , Tgt_Offer_Inst_Id                                       AS MAIN_SOC_SEQ_NO
    , Tgt_Offer_Cd                                            AS MAIN_SOC_CODE
    , Tgt_Offer_Inst_Id                                       AS SOC_SEQ_NO
    , Tgt_Offer_Cd                                            AS SOC_CODE
    , '0'                                                     AS MAP_COMBO_ID
    , Tgt_Offer_Cd                                            AS TEMP_OFFER_CODE
    , Tgt_Offer_Id                                            AS VERIS_OFFER_ID
    , Tgt_Offer_Name                                          AS OFFER_NAME
    , Tgt_Offer_Type                                          AS OFFER_TYPE
    , Svc_Class_Cd                                            AS SERVICE_CLASS_CD
		, COALESCE(CAST(Offer_Eff_Dt AS DATE), @EFF_DATE)         AS SOC_EFFECTIVE_DATE
		, COALESCE(CAST(Offer_Exp_Dt AS DATE), @EXP_DATE)         AS SOC_EXPIRATION_DATE
    , Feature_Seq_No                                          AS FEATURE_SEQ_NO
		, COALESCE(CAST(Feature_Eff_Dt AS DATE), @EFF_DATE)       AS FEATURE_EFFECTIVE_DATE
		, COALESCE(CAST(Feature_Exp_Dt AS DATE), @EXP_DATE)       AS FEATURE_EXPIRATION_DATE
    , Feature_Cd                                              AS LEGACY_FEATURE_CODE
    , CAST(COALESCE(Main_Prod_Ind,'N') AS CHAR(1))            AS MAIN_FEATURE_FLAG
    , Product_Id                                              AS VERIS_PRODUCT_ID
    , MDM_Type_Cd                                             AS MDM_TYPE
    , Service_Id                                              AS VERIS_SERVICE_ID
    , Service_Attr_Id                                         AS VERIS_SERVICE_ATTR_ID
    , Service_Attr_Value                                      AS SERVICE_ATTR_VALUE

FROM LEGACY.M_OFFER_M20_MERGE_ALL_WORK
;

