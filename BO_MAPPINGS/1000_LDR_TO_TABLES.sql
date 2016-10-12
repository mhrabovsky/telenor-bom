USE LEGACY;

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
--	BO_TARIFF_DESCRIPTION_LDR
--
--	BO_ID2ID_ADDON_OFFER_LDR
--	BO_ID2ID_ATTR2ATTR_LDR
--	BO_ID2ID_MAIN_OFFER_LDR
--
-- B2B Pandocs input:
--	M_B2B_ADDON_LDR		- M_B2B_ADDON
--	M_B2B_TARIFF_LDR	- M_B2B_TARIFF
--	M_B2C_ADDON_LDR		- M_B2C_ADDON
--	M_B2C_TARIFF_LDR	- M_B2C_TARIFF
--
--	M_IDID_ATTR_LDR		- M_IDID_ATTR_MOD
--	M_IDID_OFFER_LDR	- M_IDID_OFFER_MOD
--	M_IDID_OFFER_SPLIT_LDR	- M_IDID_OFFER_SPLIT
--
-- DWH input:
--	SOC_REF_LDR		- SOC_REF
--
-- worktables:
--	M_OFFER_MANDADD_WORK
--	M_OFFER_WORK
--
-- target tables:
--	M_OFFER_MANDADD_MAP
--	M_OFFER_MAP
-- --

TRUNCATE M_B2C_TARIFF;

INSERT INTO M_B2C_TARIFF
SELECT * FROM M_B2C_TARIFF_LDR
WHERE SRC_COMBO_LIST IS NOT NULL
AND   TGT_OFFER_CD IS NOT NULL
AND   MAP_TYPE ='B2C'
;

TRUNCATE M_B2C_ADDON;

INSERT INTO M_B2C_ADDON
SELECT * FROM M_B2C_ADDON_LDR
WHERE SRC_COMBO_LIST IS NOT NULL
;

TRUNCATE M_B2B_TARIFF;

INSERT INTO M_B2B_TARIFF
SELECT 
	 MAP_RULE_ID 
	,MAP_TYPE 
	,RTRIM(TGT_OFFER_TYPE)
	,SRC_COMBO_LIST 
        ,TGT_OFFER_CD
	,TGT_OFFER_NAME 
	,TGT_OFFER_CUST_DESC 
	,TGT_OFFER_INT_DESC 
	,P_TARIFF_TYPE 
	,P_SUBSCRIBER_TYPE  
	,P_SEGMENT_ELIGIBILITY
	,P_OFF_THE_SHELF_PRODUCT
	,P_EXACT_TARIFF_CATEGORY
	,P_3RD_PARTY_SERVICE 
	,P_3RD_PARTY_SERVICE_VENDOR 
	,P_TARIFF_FEATURES
	,P_MANDATORY_ADDON_TYPE
	,P_MANDATORY_ADDON_LIST
	,P_VOICE_BILLING_INCREMENT
FROM M_B2B_TARIFF_LDR
WHERE SRC_COMBO_LIST IS NOT NULL
;

TRUNCATE M_B2B_ADDON;

INSERT INTO M_B2B_ADDON
SELECT * FROM M_B2B_ADDON_LDR
WHERE SRC_COMBO_LIST IS NOT NULL
;
-- select max(length(SRC_COMBO_LIST)) from M_B2B_ADDON_LDR; -- 285!!!
TRUNCATE M_IDID_OFFER;

INSERT INTO M_IDID_OFFER
SELECT * FROM M_IDID_OFFER_LDR
WHERE TGT_OFFER_CD IS NOT NULL
;

TRUNCATE M_IDID_ATTR;

INSERT INTO M_IDID_ATTR
-- SELECT * FROM M_IDID_ATTR_LDR
-- WHERE PRODUCT_ID IS NOT NULL
select l.* from M_IDID_ATTR_LDR l -- 806
join (
select product_id,service_id,service_attr_id from M_IDID_ATTR_LDR
where service_attr_id in (810301,810001,820001,10760)
) x
on l.product_id=x.product_id
and l.service_id=x.service_id
and l.service_attr_id=x.service_attr_id

union all

select l.* from M_IDID_ATTR_LDR l -- 749
left outer join (
select distinct product_id,service_id from M_IDID_ATTR_LDR
where service_attr_id in (810301,810001,820001,10760)
) x
on l.product_id=x.product_id
and l.service_id=x.service_id
where x.product_id is null

;

TRUNCATE M_IDID_OFFER_SPLIT;

INSERT INTO M_IDID_OFFER_SPLIT
SELECT * FROM M_IDID_OFFER_SPLIT_LDR
;

truncate SOC_REF;

insert into SOC_REF(OFFER_ID,SVC_CLASS,OFFER_DESC) 
select OFFER_ID,SVC_CLASS,OFFER_DESC from SOC_REF_LDR
;


