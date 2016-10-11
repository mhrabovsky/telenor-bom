USE LEGACY;
-- --
-- 
--	M_B2B_ADDON		- M_OFFER_WORK
--	M_B2B_TARIFF		- M_OFFER_WORK
--	M_B2C_ADDON		- M_OFFER_WORK
--	M_B2C_TARIFF		- M_OFFER_WORK
--	M_IDID_OFFER_MOD	- M_OFFER_WORK
--
--	M_B2B_TARIFF		- M_OFFER_MANDADD_WORK
--	M_B2C_TARIFF		- M_OFFER_MANDADD_WORK
--
-- a WORK fajlok a fenti, lista oszlopot tartalmazo tablak gyujtoi
-- --

DROP TABLE IF EXISTS M_OFFER_WORK;
DROP TABLE IF EXISTS M_OFFER_MANDADD_WORK;

CREATE TABLE M_OFFER_WORK
(
    Tgt_Offer_Cd    VARCHAR(100)     NOT NULL
,   Tgt_Offer_Type  CHAR(1)         NOT NULL
,   Tgt_Offer_Name  VARCHAR(1000)   NOT NULL
,   Src_Combo_List  VARCHAR(1000)   NOT NULL
,   Map_Type        CHAR(3)         NOT NULL    --  B2B / B2C
,   VOICE_BILLING_INCREMENT varchar(30)
)
;

CREATE TABLE M_OFFER_MANDADD_WORK
(
    Tgt_Offer_Cd    VARCHAR(200)     NOT NULL
,   Tgt_Offer_Type  CHAR(1)         NOT NULL
,   Tgt_Offer_Name  VARCHAR(1000)   NOT NULL
,   Mand_Addon_List VARCHAR(1000)   NOT NULL
,   Map_Type        CHAR(3)         NOT NULL    --  B2B / B2C
,   VOICE_BILLING_INCREMENT varchar(30)
)
;

INSERT
INTO    M_OFFER_WORK
(
        Tgt_Offer_Cd
,       Tgt_Offer_Type
,       Tgt_Offer_Name
,       Src_Combo_List
,       Map_Type
,       VOICE_BILLING_INCREMENT
)
-- ----
--     --  'B2C' Tariff
-- ----
SELECT
        Tgt_Offer_Cd
,       Tgt_Offer_Type
,       Tgt_Offer_Name
,       Src_Combo_List
,       Map_Type
,       P_VOICE_BILLING_INCREMENT
FROM
        M_B2C_TARIFF
WHERE
        Src_Combo_List IS NOT NULL
-- ----
UNION   --  'B2C' Addon
-- ----
SELECT
        Tgt_Offer_Cd
,       Tgt_Offer_Type
,       Tgt_Offer_Name
,       Src_Combo_List
,       Map_Type
,       P_VOICE_BILLING_INCREMENT
FROM
        M_B2C_ADDON
WHERE
        Tgt_Offer_Cd    IS NOT NULL
AND     Src_Combo_List  IS NOT NULL
/*
-- ----
UNION   --  'B2B'
-- ----
SELECT  DISTINCT
        Tgt_Offer_Cd
,       Tgt_Offer_Type
,       Tgt_Offer_Name
,       Tgt_Offer_Cd    AS  Src_Combo_List
,       Map_Type
,       null P_VOICE_BILLING_INCREMENT
FROM
        M_IDID_OFFER_MOD
WHERE
        Map_Type = 'B2B'
AND     length(TRIM(Tgt_Offer_Cd)) <= 9
*/
-- ----
UNION --  'B2B' Tariff
-- ----
SELECT
        Tgt_Offer_Cd
,       Tgt_Offer_Type
,       Tgt_Offer_Name
,       Src_Combo_List
,       Map_Type
,       P_VOICE_BILLING_INCREMENT
FROM
        M_B2B_TARIFF
WHERE
        Src_Combo_List IS NOT NULL
-- ----
UNION   --  'B2B' Addon
-- ----
SELECT
        Tgt_Offer_Cd
,       Tgt_Offer_Type
,       Tgt_Offer_Name
,       Src_Combo_List
,       Map_Type
,       P_VOICE_BILLING_INCREMENT
FROM
        M_B2B_ADDON
WHERE
        Tgt_Offer_Cd    IS NOT NULL
AND     Src_Combo_List  IS NOT NULL
;

insert into M_OFFER_WORK
SELECT  DISTINCT
        Tgt_Offer_Cd
,       Tgt_Offer_Type
,       Tgt_Offer_Name
,       Tgt_Offer_Cd    AS  Src_Combo_List
,       Map_Type
,       null VOICE_BILLING_INCREMENT
FROM
        M_IDID_OFFER_MOD
WHERE
        Map_Type = 'B2B'
AND     length(TRIM(Tgt_Offer_Cd)) <= 9
and MDM_TYPE_CD='GSM_MAIN'
and Tgt_Offer_Cd not in (select Tgt_Offer_Cd from M_OFFER_WORK)
;


INSERT
INTO    M_OFFER_MANDADD_WORK
(
        Tgt_Offer_Cd
,       Tgt_Offer_Type
,       Tgt_Offer_Name
,       Mand_Addon_List
,       Map_Type
,       VOICE_BILLING_INCREMENT
)
--     --  'B2C' Tariff
SELECT
        Tgt_Offer_Cd
,       Tgt_Offer_Type
,       Tgt_Offer_Name
,       P_Mandatory_Addon_List
,       Map_Type
,       P_VOICE_BILLING_INCREMENT
FROM
        M_B2C_TARIFF
WHERE
        P_Mandatory_Addon_List IS NOT NULL
	AND Tgt_Offer_Cd IS NOT NULL
	
-- ----
UNION  --  'B2B' Tariff
SELECT
-- ----
        Tgt_Offer_Cd
,       Tgt_Offer_Type
,       coalesce(Tgt_Offer_Cust_Desc,'MIGR_DUMMY')
,       P_Mandatory_Addon_List
,       Map_Type
,       P_VOICE_BILLING_INCREMENT
FROM
        M_B2B_TARIFF
WHERE
        P_Mandatory_Addon_List IS NOT NULL
and Tgt_Offer_Name is not null
and Src_Combo_List is not null
AND     Src_Combo_List NOT IN ( SELECT Tgt_Offer_Cd
                              FROM   M_B2C_TARIFF
                              WHERE  P_Mandatory_Addon_List IS NOT NULL )
-- ----
;
