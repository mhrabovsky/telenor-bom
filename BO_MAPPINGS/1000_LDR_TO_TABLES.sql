-- USE LEGACY;

/*
OFFER MAP es IDID MAP tablazatok betoltese, eloszurese, formazasa
A forras excel tablazatokat a B2B es a B2C csoport (Kata es Tomek) allitjak elo.
Nalunk Csaba formazza es TSV-ve alakitja az alabbi tablak alapjaul szolgalo Excel tablazatokat.
Az id2id_rec_id-t Csaba minden hetfon ujraszamolja a fenti feldolgozassal egyutt (elozo penteki allapot).
A betoltesuket a Mignon vegzi el minden kedden delben, aszinkron, kezzel inditott menetben. A Pandocs az utolso atado, amikor atado, utana van a betoltes.
*/
-- --
-- B2C Pandocs input (not used):
-- 	BO_ADDON_DESCRIPTION_LDR
-- --	BO_TARIFF_DESCRIPTION_LDR
-- --
-- --	BO_ID2ID_ADDON_OFFER_LDR
-- --	BO_ID2ID_ATTR2ATTR_LDR
-- --	BO_ID2ID_MAIN_OFFER_LDR
-- --
-- B2B Pandocs input:
-- --	M_B2B_ADDON_LDR		- M_B2B_ADDON
-- --	M_B2B_TARIFF_LDR	- M_B2B_TARIFF
-- --	M_B2C_ADDON_LDR		- M_B2C_ADDON
-- --	M_B2C_TARIFF_LDR	- M_B2C_TARIFF
-- --
-- --	M_IDID_ATTR_LDR		- M_IDID_ATTR_MOD
-- --	M_IDID_OFFER_LDR	- M_IDID_OFFER_MOD
-- --	M_IDID_OFFER_SPLIT_LDR	- M_IDID_OFFER_SPLIT
-- --
-- DWH input:
-- --	SOC_REF_LDR		- SOC_REF
-- --
-- worktables:
-- --	M_OFFER_MANDADD_WORK
-- --	M_OFFER_WORK
-- --
-- target tables:
-- --	M_OFFER_MANDADD_MAP
-- --	M_OFFER_MAP
-- --

-- NAS 10.11 beegetesek bovitese
SET @SERVICE_ATTR_ID = LEGACY.CONFIG('SERVICE_ATTR_ID', NULL);

TRUNCATE LEGACY.M_B2C_TARIFF;

INSERT INTO LEGACY.M_B2C_TARIFF
   SELECT *
     FROM LEGACY.M_B2C_TARIFF_LDR
    WHERE     SRC_COMBO_LIST IS NOT NULL
          AND TGT_OFFER_CD IS NOT NULL
          AND MAP_TYPE = 'B2C';

TRUNCATE LEGACY.M_B2C_ADDON;

INSERT INTO LEGACY.M_B2C_ADDON
   SELECT *
     FROM LEGACY.M_B2C_ADDON_LDR
    WHERE SRC_COMBO_LIST IS NOT NULL;

TRUNCATE LEGACY.M_B2B_TARIFF;

INSERT INTO LEGACY.M_B2B_TARIFF
   SELECT MAP_RULE_ID,
          MAP_TYPE,
          RTRIM(TGT_OFFER_TYPE),
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
          P_VOICE_BILLING_INCREMENT
     FROM LEGACY.M_B2B_TARIFF_LDR
    WHERE SRC_COMBO_LIST IS NOT NULL;

TRUNCATE LEGACY.M_B2B_ADDON;

INSERT INTO LEGACY.M_B2B_ADDON
   SELECT *
     FROM LEGACY.M_B2B_ADDON_LDR
    WHERE SRC_COMBO_LIST IS NOT NULL;

-- select max(length(SRC_COMBO_LIST)) from M_B2B_ADDON_LDR; -- 285!!!
TRUNCATE LEGACY.M_IDID_OFFER;

INSERT INTO LEGACY.M_IDID_OFFER
   SELECT *
     FROM LEGACY.M_IDID_OFFER_LDR
    WHERE TGT_OFFER_CD IS NOT NULL;

TRUNCATE LEGACY.M_IDID_ATTR;

INSERT INTO LEGACY.M_IDID_ATTR
   -- SELECT * FROM M_IDID_ATTR_LDR
   -- WHERE PRODUCT_ID IS NOT NULL
   SELECT ID2ID_REC_ID,
          MAP_TYPE,
          PRODUCT_ID,
          PRODUCT_NAME,
          SERVICE_ID,
          SERVICE_NAME,
          SERVICE_DESC,
          SERVICE_ATTR_ID,
          SERVICE_ATTR_NAME,
          SERVICE_ATTR_DESC,
          PRODUCT_MAPPING_TYPE,
          FEATURE_CD,
          SOURCE_NAME,
          LEGACY_PARAM_NAME,
          LEGACY_PARAM_DESC
     FROM (SELECT CASE
                     WHEN @p = concat(Product_Id, '-', Service_Id)
                     THEN
                        @i := @i + 1
                     ELSE
                        @i := 1
                  END
                     nr,
                  x.*,
                  @p := concat(Product_Id, '-', Service_Id) part
             FROM (SELECT l.*
                     FROM LEGACY.M_IDID_ATTR_LDR l -- 806 speciális attr_id, a product_id+service_id többi attr_id-je kimarad
                          JOIN
                          (SELECT product_id, service_id, service_attr_id
                             FROM LEGACY.M_IDID_ATTR_LDR
                            WHERE service_attr_id IN (810301,
                                                      810001,
                                                      820001,
                                                      10760)) x
                             ON     l.product_id = x.product_id
                                AND l.service_id = x.service_id
                                AND l.service_attr_id = x.service_attr_id
                   UNION ALL
                   --
                   SELECT l.*
                     FROM LEGACY.M_IDID_ATTR_LDR l -- 749 az olyan product_id+service_id attr_id-i, akiknek nincs kituntetett attr_id-je
                          LEFT OUTER JOIN
                          (SELECT DISTINCT product_id, service_id
                             FROM LEGACY.M_IDID_ATTR_LDR
                            WHERE service_attr_id IN (810301,
                                                      810001,
                                                      820001,
                                                      10760)) x
                             ON     l.product_id = x.product_id
                                AND l.service_id = x.service_id
                    WHERE x.product_id IS NULL
                   ORDER BY product_id,
                            service_id,
                            (CASE
                                WHEN (Feature_Cd IS NOT NULL) THEN 1
                                ELSE 2
                             END) ASC                       --  van Feature_Cd
                                     ,
                            (CASE Map_Type WHEN 'B2C' THEN 1 ELSE 2 END) --  B2C -> B2B
                                                                        ,
                            Service_Attr_Id) x
                  JOIN (SELECT @i := 1, @p := '-') xx ON 1 = 1) xxx
    WHERE xxx.nr = 1         -- product_id+service_id-re egyediseg biztositasa
;
TRUNCATE LEGACY.M_IDID_OFFER_SPLIT;

INSERT INTO LEGACY.M_IDID_OFFER_SPLIT
   SELECT * FROM LEGACY.M_IDID_OFFER_SPLIT_LDR;

TRUNCATE LEGACY.SOC_REF;

INSERT INTO LEGACY.SOC_REF(OFFER_ID, SVC_CLASS, OFFER_DESC)
   SELECT OFFER_ID, SVC_CLASS, OFFER_DESC FROM LEGACY.SOC_REF_LDR;