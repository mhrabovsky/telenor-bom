INSERT INTO M_B2B_TARIFF(MAP_RULE_ID,
                         MAP_TYPE,
                         TGT_OFFER_TYPE,
                         SRC_COMBO_LIST,
                         TGT_OFFER_CD,
                         TGT_OFFER_NAME,
                         TGT_OFFER_CUST_DESC,
                         TGT_OFFER_INT_DESC,
                         P_TARIFF_TYPE,
                         P_SUBSCRIBER_TYPE,
                         P_SEGMENT_ELIGIBILITY,
                         P_OFF_THE_SHELF_PRODUCT,
                         P_EXACT_TARIFF_CATEGORY,
                         P_3RD_PARTY_SERVICE,
                         P_3RD_PARTY_SERVICE_VENDOR,
                         P_TARIFF_FEATURES,
                         P_MANDATORY_ADDON_TYPE,
                         P_MANDATORY_ADDON_LIST,
                         P_VOICE_BILLING_INCREMENT)
	SELECT
		CAST(TRIM(MAP_RULE_ID) AS SIGNED INTEGER)	AS MAP_RULE_ID,
		TRIM(MAP_TYPE)								AS MAP_TYPE,
		TRIM(TGT_OFFER_TYPE)						AS TGT_OFFER_TYPE,
		TRIM(SRC_COMBO_LIST)						AS SRC_COMBO_LIST,
		TRIM(TGT_OFFER_CD)							AS TGT_OFFER_CD,
		TRIM(TGT_OFFER_NAME)						AS TGT_OFFER_NAME,
		TRIM(TGT_OFFER_CUST_DESC)					AS TGT_OFFER_CUST_DESC,
		TRIM(TGT_OFFER_INT_DESC)					AS TGT_OFFER_INT_DESC,
		TRIM(P_TARIFF_TYPE)							AS P_TARIFF_TYPE,
		TRIM(P_SUBSCRIBER_TYPE)						AS P_SUBSCRIBER_TYPE,
		TRIM(P_SEGMENT_ELIGIBILITY)					AS P_SEGMENT_ELIGIBILITY,
		TRIM(P_OFF_THE_SHELF_PRODUCT)				AS P_OFF_THE_SHELF_PRODUCT,
		TRIM(P_EXACT_TARIFF_CATEGORY)				AS P_EXACT_TARIFF_CATEGORY,
		TRIM(P_3RD_PARTY_SERVICE)					AS P_3RD_PARTY_SERVICE,
		TRIM(P_3RD_PARTY_SERVICE_VENDOR)			AS P_3RD_PARTY_SERVICE_VENDOR,
		TRIM(P_TARIFF_FEATURES)						AS P_TARIFF_FEATURES,
		TRIM(P_MANDATORY_ADDON_TYPE)				AS P_MANDATORY_ADDON_TYPE,
		TRIM(P_MANDATORY_ADDON_LIST)				AS P_MANDATORY_ADDON_LIST,
		TRIM(P_VOICE_BILLING_INCREMENT)				AS P_VOICE_BILLING_INCREMENT
	  FROM
	    M_B2B_TARIFF_LDR;
		
CALL WORK.LOGIT_BO_MAPPINGS('030_LOAD_M_B2B_TARIFF.sql', 'LEGACY', 'INSERT', ROW_COUNT());