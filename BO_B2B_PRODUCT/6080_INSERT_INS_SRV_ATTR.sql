-- 6080

-- NAS 10.04 beegetesek bovitese
-- 20161011_HL INS_SRV_ATTR ATTR_TEXT oszlopaba SERVICE_ATTR_VALUE/100 kerul, ha a VERIS_SERVICE_ATTR_ID 820001

SET @BASE = LEGACY.CONFIG('ATTR_INST_ID', null);
SET @EFF_DT = CAST(LEGACY.CONFIG('DEF_EFF_DATE',NULL) AS DATETIME);
SET @EXP_DT = CAST(LEGACY.CONFIG('DEF_EXP_DATE',NULL) AS DATETIME);
SET @SYS_DATE = CAST(LEGACY.CONFIG('SYS_DATE',NULL) AS DATETIME);

INSERT INTO MDM.INS_SRV_ATTR
(
     TENANT_ID
    ,ATTR_INST_ID
    ,PROD_SRV_RELAT_ID
    ,OFFER_INST_ID
    ,USER_ID
    ,SERVICE_ID
    ,ATTR_ID
    ,ATTR_VALUE
    ,ATTR_TEXT
    ,STATE
    ,SORT_ID
    ,ATTR_BATCH
    ,EFFECTIVE_DATE
    ,EXPIRE_DATE
)

SELECT
     '22'                                                           -- TENANT_ID
    ,CONCAT(@BASE, @rownum := @rownum + 1)                          -- ATTR_INST_ID
    ,CONCAT(X.SOC_SEQ_NO, X.FEATURE_SEQ_NO, X.VERIS_SERVICE_ID)     -- PROD_SRV_RELAT_ID,
    ,CONCAT(X.MAIN_SOC_SEQ_NO,X.VERIS_OFFER_ID)                     -- OFFER_INST_ID
    ,X.USER_ID			                                    -- USER_ID
    ,X.VERIS_SERVICE_ID                                             -- SERVICE_ID
    ,X.VERIS_SERVICE_ATTR_ID                                        -- ATTR_ID
    ,X.SERVICE_ATTR_VALUE                                           -- ATTR_VALUE
    ,CASE WHEN X.VERIS_SERVICE_ATTR_ID = 820001 THEN X.SERVICE_ATTR_VALUE/100 ELSE X.SERVICE_ATTR_VALUE END  -- ATTR_TEXT
    ,CASE WHEN FEATURE_EXPIRATION_DATE < @SYS_DATE
            THEN '7'
          ELSE '1'
     END                                                            -- STATE
    ,'99'                                                           -- SORT_ID
    ,'null'                                                         -- ATTR_BATCH
    ,CASE WHEN FEATURE_EFFECTIVE_DATE IS NULL
            THEN @EFF_DT
          WHEN FEATURE_EFFECTIVE_DATE > FEATURE_EXPIRATION_DATE
            THEN FEATURE_EXPIRATION_DATE
          ELSE FEATURE_EFFECTIVE_DATE
     END                                                            AS EFFECTIVE_DATE
    ,CASE WHEN FEATURE_EXPIRATION_DATE IS NULL
            THEN @EXP_DT
          WHEN FEATURE_EXPIRATION_DATE > @EXP_DT
            THEN @EXP_DT
          ELSE FEATURE_EXPIRATION_DATE
     END                                                            AS EXPIRE_DATE

    FROM  LEGACY.SOC_FEATURE_OFFER_MAPPING X

    JOIN (select @rownum :=0) r
        ON 1 = 1
    WHERE
            X.VERIS_SERVICE_ATTR_ID IS NOT NULL
        AND X.SERVICE_ATTR_VALUE IS NOT NULL
--      AND X.CTN IN (SELECT DISTINCT CTN FROM LEGACY.SOC_FEATURE_OFFER_MAPPING WHERE OFFER_TYPE = 'T')

;



-- NGy 08.08
/*
select @rownum := max(cast(trim(substring(ATTR_INST_ID, 10 )) as unsigned))
from MDM.INS_SRV_ATTR
where ATTR_INST_ID like '100000000%';
*/

-- Repeta extract(EDSZ_LDR) - ABCONPRS Addon - Hitelkeret
-- 
-- select MDM_TYPE_CD, VERIS_OBJECT_ID
-- from LEGACY.M_IDID_OFFER_MOD
-- where TGT_OFFER_CD = 'ABCONPRS';
-- GSM_VAS	20008717
-- PRICE_PROD	1003455
-- SRVC_SINGLE	20008718
-- 
-- select product_id, service_id, service_attr_id 
-- from LEGACY.M_IDID_ATTR_MOD
-- where product_id = '1003455';
-- 1003455	31003455	10760

call LEGACY.createindex_ifnotexists('MDM','INS_PROD_INS_SRV','SERVICE_ID');
-- call LEGACY.createindex_ifnotexists('LEGACY','EDSZ_LDR','CTN');
call LEGACY.createindex_ifnotexists('LEGACY','EDSZ_LDR','BAN_BEN_CTN');


INSERT INTO MDM.INS_SRV_ATTR
(TENANT_ID,
ATTR_INST_ID,
PROD_SRV_RELAT_ID,
OFFER_INST_ID,
USER_ID,
SERVICE_ID,
ATTR_ID,
ATTR_VALUE,
ATTR_TEXT,
STATE,
SORT_ID,
ATTR_BATCH,
EFFECTIVE_DATE,
EXPIRE_DATE)
  
  SELECT
	'22', 										-- TENANT_ID
    CONCAT(@BASE, @rownum := @rownum + 1),  -- ATTR_INST_ID
    S.PROD_SRV_RELAT_ID, 						-- PROD_SRV_RELAT_ID
    S.OFFER_INST_ID, 							-- OFFER_INST_ID
    S.USER_ID, 									-- USER_ID
    S.SERVICE_ID, 								-- SERVICE_ID
    '10760', 									-- ATTR_ID
    E.amount, 									-- ATTR_VALUE
    E.amount, 									-- ATTR_TEXT
    S.STATE, 									-- STATE
    '99999', 									-- SORT_ID
    'null', 									-- ATTR_BATCH
	IU.effective_date,							-- EFFECTIVE_DATE !!! offer-bol inkabb ???
	IU.expire_date								-- EXPIREE_DATE
  FROM MDM.INS_PROD_INS_SRV S, LEGACY.EDSZ_LDR E, MDM.INS_USER IU 
-- WHERE right(S.USER_ID,9) = E.ctn -- addigis
  WHERE S.USER_ID = E.BAN_BEN_CTN
   and S.USER_ID = IU.USER_ID
   and S.service_id = '31003455' 
;    
