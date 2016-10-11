INSERT INTO M_IDID_OFFER(ID2ID_REC_ID,
                         MAP_TYPE,
                         TGT_OFFER_TYPE,
                         TGT_OFFER_TYPE_DESC,
                         TGT_OFFER_CD,
                         TGT_OFFER_NAME,
                         VERIS_TYPE_CD,
                         MDM_TYPE_CD,
                         BILLING_TYPE,
                         VERIS_OBJECT_ID,
                         VERIS_OBJECT_NAME,
                         RELAT_OFFER_ID,
                         SERVICE_FLAG,
                         PRODUCT_LINE,
                         ROLE_ID,
                         PRODUCT_COMMENT,
                         ID2ID_DATE,
                         MDM_TYPE_TEXT)
	SELECT
		AS ID2ID_REC_ID,
		AS MAP_TYPE,
		AS TGT_OFFER_TYPE,
		AS TGT_OFFER_TYPE_DESC,
		AS TGT_OFFER_CD,
		AS TGT_OFFER_NAME,
		AS VERIS_TYPE_CD,
		AS MDM_TYPE_CD,
		AS BILLING_TYPE,
		AS VERIS_OBJECT_ID,
		AS VERIS_OBJECT_NAME,
		AS RELAT_OFFER_ID,
		AS SERVICE_FLAG,
		AS PRODUCT_LINE,
		AS ROLE_ID,
		AS PRODUCT_COMMENT,
		AS ID2ID_DATE,
		AS MDM_TYPE_TEXT,
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	  FROM
	    M_IDID_OFFER_LDR;
		
CALL WORK.LOGIT_BO_MAPPINGS('050_LOAD_M_IDID_OFFER.sql', 'LEGACY', 'INSERT', ROW_COUNT());


TRUNCATE M_IDID_OFFER;

INSERT INTO M_IDID_OFFER
SELECT * FROM M_IDID_OFFER_LDR
WHERE TGT_OFFER_CD IS NOT NULL
;