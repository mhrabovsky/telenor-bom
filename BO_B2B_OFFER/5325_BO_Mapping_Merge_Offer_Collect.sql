-- 5325.
USE LEGACY;

-- Futasido (3-as gep): 20 perc
/*

Here, preprocessed sources of offers are concatenated into a single set.

*/

DROP TABLE if exists /*${WORK_TB}*/ M_OFFER_M10_MERGE;
DROP TABLE if exists /*${WORK_TB}*/ M_OFFER_M11_MERGE_SOC;

call LEGACY.createindex_ifnotexists('LEGACY','M_IDID_OFFER_MOD','Id2Id_Rec_Id');


CREATE TABLE M_OFFER_M10_MERGE
(
  `Sub_Id` varchar(28) NOT NULL,
  `Tgt_Offer_Cd` varchar(30) NOT NULL,
  `Tgt_Offer_Name` varchar(1000),
  `Tgt_Offer_Type` char(1),
  `Tgt_Offer_Id` bigint(20),
  `Tgt_Offer_Inst_Id` bigint(21) DEFAULT NULL,
  `Service_Attr_Value` decimal(15,2) DEFAULT NULL,
  `Src_SOC_Cd` char(9),
  `Src_SOC_Seq_No` int(11),
  `Map_Type` char(3),
   Map_Level varchar(10) null,
  `Id2Id_Rec_Id` int(11),
  Sub_Type char(3),
  SUBSCRIBER_REF varchar(30),
  VOICE_BILLING_INCREMENT varchar(30),
  Split_Type              INTEGER      -- adatellenorzeshez (debug) kell, nem itt toltjuk.
)
;


INSERT INTO `M_OFFER_M10_MERGE`
(`Sub_Id`,
`Tgt_Offer_Cd`,
`Tgt_Offer_Name`,
`Tgt_Offer_Type`,
`Tgt_Offer_Id`,
`Tgt_Offer_Inst_Id`,
`Service_Attr_Value`,
`Src_SOC_Cd`,
`Src_SOC_Seq_No`,
`Map_Type`,
`Map_Level`,
`Id2Id_Rec_Id`,
 Sub_Type,
 SUBSCRIBER_REF,
 VOICE_BILLING_INCREMENT,
 Split_Type
)
-- (
    -- ----
    --  DWH Offer Mapping adatok (B2B)
    -- ----
        SELECT
                Sub_Id                  AS  Sub_Id
        ,       Tgt_Offer_Cd            AS  Tgt_Offer_Cd
        ,       Tgt_Offer_Name          AS  Tgt_Offer_Name
        ,       Tgt_Offer_Type          AS  Tgt_Offer_Type
        ,       Tgt_Offer_Id            AS  Tgt_Offer_Id
        ,       Tgt_Offer_Inst_Id       AS  Tgt_Offer_Inst_Id
        ,       Service_Attr_Value      AS  Service_Attr_Value
        ,       Src_SOC_Cd              AS  Src_SOC_Cd
        ,       Src_SOC_Seq_No          AS  Src_SOC_Seq_No
        ,       Map_Type                AS  Map_Type
        ,       'DWH' /*(VARCHAR(10))*/     AS  Map_Level
        ,       Id2Id_Rec_Id            AS  Id2Id_Rec_Id
        ,       Sub_Type
        ,       SUBSCRIBER_REF
        ,       VOICE_BILLING_INCREMENT
        ,       case when Split_Type='4' then '4' else '-2' end Split_Type -- ST4 a dwh-bol jon.
        FROM
                M_OFFER_M00_DWH
        WHERE
                Migr_Offer_Ind = 'Y'
    -- ----
    UNION
    -- ----
    --  Tariff Offer Mapping adatok (B2B + B2C)
    -- ----
        SELECT
                T.Sub_Id                AS  Sub_Id
        ,       T.Tgt_Offer_Cd          AS  Tgt_Offer_Cd
        ,       I.Tgt_Offer_Name        AS  Tgt_Offer_Name
        ,       T.Tgt_Offer_Type        AS  Tgt_Offer_Type
        ,       I.Relat_Offer_Id        AS  Tgt_Offer_Id
        ,       T.Src_SOC_Seq_No        AS  Tgt_Offer_Inst_Id
        ,       NULL /*(DECIMAL(15,0))*/    AS  Service_Attr_Value
        ,       T.Src_SOC_Cd            AS  Src_SOC_Cd
        ,       T.Src_SOC_Seq_No        AS  Src_SOC_Seq_No
        ,       T.Map_Type              AS  Map_Type
        ,       'TAR' /*(VARCHAR(10))*/     AS  Map_Level
        ,       T.Id2Id_Rec_Id          AS  Id2Id_Rec_Id
        ,       T.Sub_Type
        ,       T.SUBSCRIBER_REF
        ,       T.VOICE_BILLING_INCREMENT
        ,       I.Split_Type
        FROM
                             M_OFFER_M01_TARIFF AS T
                INNER JOIN   M_IDID_OFFER_MOD AS I ON (T.Id2Id_Rec_Id = I.Id2Id_Rec_Id)
        WHERE
                T.Migr_Offer_Ind = 'Y'
-- and I.Tgt_Offer_Type_Desc<>'SHARPLAN' -- mgy 2016.08.24 mgy 2016.09.08 M01 szuri

    -- ----
    UNION
    -- ----
    --  Addon Offer Mapping adatok (B2B + B2C)
    -- ----
        SELECT
                A.Sub_Id                AS  Sub_Id
        ,       A.Tgt_Offer_Cd          AS  Tgt_Offer_Cd
        ,       I.Tgt_Offer_Name        AS  Tgt_Offer_Name
        ,       A.Tgt_Offer_Type        AS  Tgt_Offer_Type
        ,       I.Relat_Offer_Id        AS  Tgt_Offer_Id
        ,       A.Src_SOC_Seq_No        AS  Tgt_Offer_Inst_Id
        ,       NULL /*(DECIMAL(15,0))*/    AS  Service_Attr_Value
        ,       A.Src_SOC_Cd            AS  Src_SOC_Cd
        ,       A.Src_SOC_Seq_No        AS  Src_SOC_Seq_No
        ,       A.Map_Type              AS  Map_Type
        -- ---
        ,       CONCAT('ADD' , (CASE WHEN (A.Mand_Addon_Ind = 'Y') THEN '+MAN' ELSE '' END)) /*(VARCHAR(10))*/   AS  Map_Level
        -- ---
        ,       A.Id2Id_Rec_Id          AS  Id2Id_Rec_Id
        ,       A.Sub_Type
        ,       A.SUBSCRIBER_REF
        ,       A.VOICE_BILLING_INCREMENT
        ,       I.Split_Type
        FROM
                             M_OFFER_M02_ADDON  AS A
                INNER JOIN   M_IDID_OFFER_MOD AS I ON (A.Id2Id_Rec_Id = I.Id2Id_Rec_Id)
        WHERE
                A.Migr_Offer_Ind = 'Y'
    -- ----
    UNION
    -- ----
    --  Mandatory Addon Offer Mapping adatok (B2B + B2C)
    -- ----
        SELECT
                M.Sub_Id                            AS  Sub_Id
        ,       M.Mand_Addon_Offer_Cd               AS  Tgt_Offer_Cd
        ,       I.Tgt_Offer_Name                    AS  Tgt_Offer_Name
        ,       'A'                                 AS  Tgt_Offer_Type
        ,       I.Relat_Offer_Id                    AS  Tgt_Offer_Id
        ,       M.Mand_Addon_Offer_Inst_Id          AS  Tgt_Offer_Inst_Id
        ,       NULL /*(DECIMAL(15,0))*/                AS  Service_Attr_Value
        ,       M.Src_SOC_Cd                        AS  Src_SOC_Cd
        ,       M.Src_SOC_Seq_No                    AS  Src_SOC_Seq_No
        ,       M.Map_Type                          AS  Map_Type
        ,       CONCAT('MAN-' , M.Map_Src) /*(VARCHAR(10))*/ AS  Map_Level
        ,       M.Id2Id_Rec_Id                      AS  Id2Id_Rec_Id
        ,       M.Sub_Type
        ,       M.SUBSCRIBER_REF
        ,       M.VOICE_BILLING_INCREMENT
        ,       I.Split_Type
        FROM
                             M_OFFER_M03_MAND_ADDON AS M
                INNER JOIN   M_IDID_OFFER_MOD     AS I ON (M.Id2Id_Rec_Id = I.Id2Id_Rec_Id)
        WHERE
                M.Migr_Offer_Ind = 'Y'
    -- ----
-- )

;

