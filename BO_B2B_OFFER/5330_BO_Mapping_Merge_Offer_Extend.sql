-- USE LEGACY;
/* # ident "%W%    %E%    @@" */
/****************************************************************************
 *
 *  Filename    : %M%
 *  Part of     : ...
 *  Type        : Bteq
 *  Job         : ...
 *
 *  -------------------------------------------------------------------------
 *  Purpose     : ...
 *
 *  Comments    :
 *
 *  Datasource  :
 *  -------------------------------------------------------------------------
 *  DB-Version  : TERADATA V13
 *  UNIX-Version: Red Hat Enterprise Linux Server release 5.7 (Tikanga)
 *
 *  -------------------------------------------------------------------------
 *  Project     : OPP
 *  Subproject  : BO Migration
 *
 *  Author      : Berkó Tamás
 *  Department  : TD
 *  Version     : %I%
 *  Date        : %E%
 *
 *  (c) 2016 by UniCon
 *  -------------------------------------------------------------------------
 *  History:
 *
 *  1.1   2016/05/03    Berkó Tamás
 *        OPP project - BO Migration
 *        - DR2 preparation
 *
 ****************************************************************************
*/

-- NAS 10.07 beégetések bővítése
SET @MDM_TYPE_PRICE_PROD = LEGACY.CONFIG('MDM_TYPE_PRICE_PROD',NULL);

-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : DROP TABLE
-- <Table> : /*${WORK_TB}*/ M_OFFER_M10_MERGE_EXT
-- <Brief> : Mapping munka táblák eldobása
-- ------------------------------------------------------------------------------------------</###>--
-- 
-- .set errorlevel (3807) severity 0
DROP TABLE if exists /*${WORK_TB}*/ LEGACY.M_OFFER_M10_MERGE_EXT;
DROP TABLE if exists /*${WORK_TB}*/ LEGACY.M_OFFER_M10_MERGE_OLD;
-- .set errorlevel (3807) severity 8

call LEGACY.createindex_ifnotexists('LEGACY','M_IDID_OFFER_MOD','Use_Flag,MDM_Type_Cd,Relat_Offer_Id');
call LEGACY.createindex_ifnotexists('LEGACY','M_IDID_OFFER_MOD','Use_Flag,MDM_Type_Cd,Tgt_Offer_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_IDID_ATTR_MOD','Product_Id');

call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M10_MERGE','Sub_Id,Tgt_Offer_Id');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M10_MERGE','Sub_Id,Tgt_Offer_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M10_MERGE','Tgt_Offer_Id');

-- MT: Ez az index nagyon bevalt, mert a sort-ban is hasznalja:
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M10_MERGE','Tgt_Offer_Id,Split_Type,Sub_Id,Tgt_Offer_Cd');


-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : CREATE TABLE AS ...
-- <Table> : /*${WORK_TB}*/ M_OFFER_M10_MERGE_EXT
-- <Brief> : Mapping munka tábla feltöltése
-- <Desc>  : Offer mapping adatok kiegészítése Product / Service adatokkal
-- ------------------------------------------------------------------------------------------</###>--

CREATE TABLE /*${WORK_TB}*/ LEGACY.M_OFFER_M10_MERGE_EXT
(
  `Sub_Id` varchar(28) NOT NULL,
  `Tgt_Offer_Cd` varchar(30) NOT NULL,
  `Tgt_Offer_Name` varchar(1000) DEFAULT NULL,
  `Tgt_Offer_Type` char(1) DEFAULT NULL,
  `Tgt_Offer_Id` bigint(20) DEFAULT NULL,
  `Tgt_Offer_Inst_Id` bigint(21) DEFAULT NULL,
  `Src_SOC_Cd` char(9) DEFAULT NULL,
  `Src_SOC_Seq_No` int(11) DEFAULT NULL,
  `MDM_Type_Cd` varchar(30) DEFAULT NULL,
  `Product_Id` bigint(20) DEFAULT NULL,
  `Product_Name` varchar(1000) DEFAULT NULL,
  `Feature_Cd` varchar(100) DEFAULT NULL,
  `Service_Id` bigint(20) DEFAULT NULL,
  `Service_Name` varchar(1000) DEFAULT NULL,
  `Service_Attr_Id` bigint(20) DEFAULT NULL,
  `Service_Attr_Name` varchar(1000) DEFAULT NULL,
  `Service_Attr_Value` decimal(15,2) DEFAULT NULL,
  `Map_Type` char(3) DEFAULT NULL,
  `Map_Level` varchar(10) DEFAULT NULL,
  `Id2Id_Rec_Id` int(11) DEFAULT NULL,
  `Id2Id_Rec_Id_Price_Prod` int(11) DEFAULT NULL,
  `Id2Id_Rec_Id_Prod_Svc_Attr` int(11) DEFAULT NULL,
  Sub_Type char(3),
  SUBSCRIBER_REF varchar(30),
  VOICE_BILLING_INCREMENT varchar(30),
  Split_Type              INTEGER      -- adatellenorzeshez (debug) kell, nem itt toltjuk.

--  PRIMARY KEY (`Sub_Id`),
--  UNIQUE KEY `Sub_Id` (`Sub_Id`,`Tgt_Offer_Cd`)
--  UNIQUE KEY `Tgt_Offer_Inst_Id` (`Tgt_Offer_Inst_Id`)
)
;

INSERT INTO `LEGACY`.`M_OFFER_M10_MERGE_EXT`
(`Sub_Id`,
`Tgt_Offer_Cd`,
`Tgt_Offer_Name`,
`Tgt_Offer_Type`,
`Tgt_Offer_Id`,
`Tgt_Offer_Inst_Id`,
`Src_SOC_Cd`,
`Src_SOC_Seq_No`,
`MDM_Type_Cd`,
`Product_Id`,
`Product_Name`,
`Feature_Cd`,
`Service_Id`,
`Service_Name`,
`Service_Attr_Id`,
`Service_Attr_Name`,
`Service_Attr_Value`,
`Map_Type`,
`Map_Level`,
`Id2Id_Rec_Id`,
`Id2Id_Rec_Id_Price_Prod`,
`Id2Id_Rec_Id_Prod_Svc_Attr`,
Sub_Type,
SUBSCRIBER_REF,
VOICE_BILLING_INCREMENT,
Split_Type
)
select
	-- ---
	 M.Sub_Id
	-- ---
	,M.Tgt_Offer_Cd
	,M.Tgt_Offer_Name
	,M.Tgt_Offer_Type
	,M.Tgt_Offer_Id
	,M.Tgt_Offer_Inst_Id
	--
	,M.Src_SOC_Cd
	,M.Src_SOC_Seq_No
	--
	,M.MDM_Type_Cd
	,M.Product_Id
	,M.Product_Name
	,M.Feature_Cd
	,M.Service_Id
	,M.Service_Name
	,M.Service_Attr_Id
	,M.Service_Attr_Name
	--
	,M.Service_Attr_Value
	--
	,M.Map_Type
	,M.Map_Level
	--
	,M.Id2Id_Rec_Id
	,M.Id2Id_Rec_Id_Price_Prod
	,M.Id2Id_Rec_Id_Prod_Svc_Attr
	-- ---
,  M.Sub_Type
,  M.SUBSCRIBER_REF
,  M.VOICE_BILLING_INCREMENT
,  M.Split_Type
-- ---
from
(select 
case
  when @n=G.Sub_Id
--    and @c=G.Tgt_Offer_Cd
    and @c=G.Tgt_Offer_Id
  then @i:=@i+1
  else @i:=1
  end NR
,G.*
,@n:=G.Sub_Id
,@c:=G.Tgt_Offer_Id
-- ,@c:=G.Tgt_Offer_Cd  -- Split Type 4 beengedese
from
(
    SELECT
    -- ---
            MRG.Sub_Id
    -- ---
    ,       MRG.Tgt_Offer_Cd
    ,       MRG.Tgt_Offer_Name
    ,       MRG.Tgt_Offer_Type
    ,       MRG.Tgt_Offer_Id
    ,       MRG.Tgt_Offer_Inst_Id
    -- ---
    ,       MRG.Src_SOC_Cd
    ,       MRG.Src_SOC_Seq_No
    -- ---
    ,       OFR.MDM_Type_Cd
    ,       OFR.Veris_Object_Id     AS  Product_Id
    ,       PRD.Product_Name
    ,       PRD.Feature_Cd
    ,       PRD.Service_Id
    ,       PRD.Service_Name
    ,       PRD.Service_Attr_Id
    ,       PRD.Service_Attr_Name
    -- ---
    ,       MRG.Service_Attr_Value
    -- ---
    ,       MRG.Map_Type
    ,       MRG.Map_Level
    -- ---
    ,       MRG.Id2Id_Rec_Id        AS  Id2Id_Rec_Id
    ,       OFR.Id2Id_Rec_Id        AS  Id2Id_Rec_Id_Price_Prod
    ,       PRD.Id2Id_Rec_Id        AS  Id2Id_Rec_Id_Prod_Svc_Attr
    -- ---
    ,       MRG.Sub_Type
    ,       MRG.SUBSCRIBER_REF
    ,       MRG.VOICE_BILLING_INCREMENT
    ,       MRG.Split_Type
    FROM
            LEGACY.M_OFFER_M10_MERGE      AS  MRG
    JOIN    LEGACY.M_IDID_OFFER_MOD       AS  OFR
        ON  OFR.Relat_Offer_Id = MRG.Tgt_Offer_Id
--        AND OFR.Use_Flag     = 'Y' -- MT: Split type-okat be kellett engedni, amit ez kizart.
          AND ( OFR.Use_Flag='Y' or MRG.Split_Type in (2,4,10) )
        AND OFR.MDM_Type_Cd  = @MDM_TYPE_PRICE_PROD
    LEFT JOIN LEGACY.M_IDID_ATTR_MOD      AS  PRD
        ON  PRD.Product_Id = OFR.Veris_Object_Id
  order by  MRG.Sub_Id
          , MRG.Tgt_Offer_Cd
          , MRG.Tgt_Offer_Id -- MT: Ez biztositja a Split Type 4 beengedeset.
          , (CASE WHEN (OFR.Id2Id_Rec_Id IS NOT NULL) THEN 1 ELSE 2 END) ASC
          , OFR.Use_Order_No ASC
) G
,(SELECT @i:=0,@n:='-',@c:='-') x
) M
where NR = 1
;





-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : RENAME
-- <Table> : /*${WORK_TB}*/ M_OFFER_M10_MERGE
-- <Brief> : Munkatábla átnevezése
-- <Desc>  : A kiegészített munkatáblát átnevezzük az eredeti névre.
-- ------------------------------------------------------------------------------------------</###>--

-- DROP TABLE M_OFFER_M10_MERGE;
RENAME TABLE LEGACY.M_OFFER_M10_MERGE TO LEGACY.M_OFFER_M10_MERGE_OLD; -- MT: itt van egy bug. Elallitodnak split-es sorok.

RENAME TABLE LEGACY.M_OFFER_M10_MERGE_EXT TO LEGACY.M_OFFER_M10_MERGE;

