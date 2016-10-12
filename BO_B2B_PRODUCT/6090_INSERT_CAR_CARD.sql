-- NAS 10.04 beégetések bővítése
SET @BASE = LEGACY.CONFIG('ATTR_INST_ID', null);

call LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE_EXTR','Sub_Id');


-- Insert service to prod 800012

INSERT INTO MDM.INS_PROD_INS_SRV
(
     TENANT_ID
    ,PROD_SRV_RELAT_ID
    ,OFFER_INST_ID
    ,PROD_INST_ID
    ,USER_ID
    ,SERVICE_ID
    ,STATE
)
SELECT
        '22'
        ,CONCAT (X.SOC_SEQ_NO, X.FEATURE_SEQ_NO, '880012')		     AS PROD_SRV_RELAT_ID
        ,CONCAT(X.MAIN_SOC_SEQ_NO,X.VERIS_OFFER_ID)							AS OFFER_INST_ID
        ,CASE WHEN FEATURE_SEQ_NO IS NOT NULL
            THEN concat(VERIS_PRODUCT_ID,CTN,MAIN_SOC_SEQ_NO, RIGHT(X.VERIS_OFFER_ID, 4))
          ELSE CONCAT(SOC_SEQ_NO,CTN)
		 END                                                                AS PROD_INST_ID
        ,X.USER_ID
        ,'880012'  AS SERVICE_ID
        ,'1'

    FROM LEGACY.SOC_FEATURE_OFFER_MAPPING X
    WHERE   X.VERIS_PRODUCT_ID = '800012'
;	


-- INSERT attribs TO INS_SRV_ATTR table

-- MAX ID lekérdezés
SET @rownum := (SELECT max(cast(SUBSTR(ATTR_INST_ID, 10) as UNSIGNED)) FROM MDM.INS_SRV_ATTR);

-- másodlagos kártya telefonszáma
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
	'22'															-- TENANT_ID
	, CONCAT(@BASE, @rownum := @rownum + 1)                         -- ATTR_INST_ID
	, S.PROD_SRV_RELAT_ID											-- PROD_SRV_RELAT_ID
	, S.OFFER_INST_ID												-- OFFER_INST_ID
	, S.USER_ID 								  					-- USER_ID
	, S.SERVICE_ID 								  					-- SERVICE_ID
	, '2300000' 								  					-- ATTR_ID
	, TRIM(SUBSTRING(TXT_TO_SPLIT, INSTR(TXT_TO_SPLIT,'=') + 1))	-- ATTR_VALUE
	, TRIM(SUBSTRING(TXT_TO_SPLIT, INSTR(TXT_TO_SPLIT,'=') + 1))	-- ATTR_TEXT
	, S.STATE 									  					-- STATE
	, '99' 							    		  					-- SORT_ID
	, 'null' 									  					-- ATTR_BATCH
	, FTR_EFFECTIVE_DATE						  					-- EFFECTIVE_DATE	
	, FTR_EXPIRATION_DATE						  					-- EXPIRATION_DATE

FROM 
				MDM.INS_PROD_INS_SRV S
    INNER JOIN  LEGACY.M_FEATURE_EXTR F ON S.USER_ID = F.Sub_Id

WHERE F.FEATURE_CODE = 'CARPAR'
  AND F.TXT_TO_SPLIT LIKE 'SECCTN%'
  AND S.SERVICE_ID = '880012'
;


-- másodlagos kártya IMSI-je
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
	'22'															-- TENANT_ID
	, CONCAT(@BASE, @rownum := @rownum + 1)                         -- ATTR_INST_ID
	, A.PROD_SRV_RELAT_ID											-- PROD_SRV_RELAT_ID
	, A.OFFER_INST_ID												-- OFFER_INST_ID
	, A.USER_ID 								  					-- USER_ID
	, A.SERVICE_ID 								  					-- SERVICE_ID
	, '2300001' 								  					-- ATTR_ID
    , U.IMSI	 													-- ATTR_VALUE
	, U.IMSI														-- ATTR_TEXT
	, A.STATE 									  					-- STATE
	, '99' 							    		  					-- SORT_ID
	, 'null' 									  					-- ATTR_BATCH
	, EFFECTIVE_DATE						  			  			-- EFFECTIVE_DATE	
	, EXPIRE_DATE						  							-- EXPIRATION_DATE
FROM 
				MDM.INS_SRV_ATTR A
	 INNER JOIN LEGACY.M_USER U ON A.ATTR_VALUE = U.CTN -- !!! BAN-BEN?

WHERE ATTR_ID = '2300000'
  AND SERVICE_ID = '880012'
;


-- Restriction level paraméter
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
	'22'															-- TENANT_ID
	, CONCAT(@BASE, @rownum := @rownum + 1)                         -- ATTR_INST_ID
	, S.PROD_SRV_RELAT_ID											-- PROD_SRV_RELAT_ID
	, S.OFFER_INST_ID												-- OFFER_INST_ID
	, S.USER_ID 								  					-- USER_ID
	, S.SERVICE_ID 								  					-- SERVICE_ID
	, '2300013' 								  					-- ATTR_ID
	, TRIM(SUBSTRING(TXT_TO_SPLIT, INSTR(TXT_TO_SPLIT,'=') + 1))	-- ATTR_VALUE
	, TRIM(SUBSTRING(TXT_TO_SPLIT, INSTR(TXT_TO_SPLIT,'=') + 1))	-- ATTR_TEXT
	, S.STATE 									  					-- STATE
	, '99' 							    		  					-- SORT_ID
	, 'null' 									  					-- ATTR_BATCH
	, FTR_EFFECTIVE_DATE						  					-- EFFECTIVE_DATE	
	, FTR_EXPIRATION_DATE						  					-- EXPIRATION_DATE

FROM 
				MDM.INS_PROD_INS_SRV S
	INNER JOIN  LEGACY.M_FEATURE_EXTR F ON S.USER_ID = F.Sub_Id

WHERE F.FEATURE_CODE = 'CARPAR'
  AND F.TXT_TO_SPLIT LIKE 'RESLEV%'
  AND S.SERVICE_ID = '880012'
;

