-- 5340.
USE LEGACY;
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
 * -- 20161011_HL: FEAUTURE, M_IDID_ATTR_LDR helyett M_IDID_ATTR_MOD-ot hasznalunk
 *
 ****************************************************************************
*/








/*

MT 20160915:
  En irtam at Tgt_Offer_Id-sre ezt a reszt, mert elrontotta a split type-okat.
  Postpaid-bol prepaid-et csinalt.

*/











-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : DROP TABLE
-- <Table> : /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD
-- <Brief> : Mapping munka táblák eldobása
-- ------------------------------------------------------------------------------------------</###>--

-- .set errorlevel (3807) severity 0
DROP TABLE if exists /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD;
-- .set errorlevel (3807) severity 8



-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : CREATE TABLE AS ...
-- <Table> : /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD
-- <Brief> : Mapping munka tábla feltöltése
-- <Desc>  : Product mapping adatok ...
-- ------------------------------------------------------------------------------------------</###>--

CREATE TABLE /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD (
    `Sub_Id` VARCHAR(28) NOT NULL,
    `Tgt_Offer_Id` VARCHAR(30) NOT NULL,
    `Tgt_Offer_Cd` VARCHAR(30) NOT NULL,
    `Tgt_Offer_Type` CHAR(1) DEFAULT NULL,
    `Product_Id` BIGINT(20) NOT NULL,
    `MDM_Type_Cd` VARCHAR(30) NOT NULL,
    `Main_Prod_Ind` VARCHAR(1) NOT NULL,
    `Service_Flag` VARCHAR(100) DEFAULT NULL,
    `Feature_Cd` VARCHAR(100) DEFAULT NULL,
    `Feature_Switch_Ind` CHAR(1) DEFAULT NULL,
    `Feature_Order_No` SMALLINT(6) DEFAULT NULL,
    `SOC_Cd` CHAR(9) DEFAULT NULL,
    `SOC_Seq_No` INT(11) DEFAULT NULL,
    `Feature_Seq_No` DECIMAL(10 , 0 ) DEFAULT NULL,
    `Eff_Dt` DATE DEFAULT NULL,
    `Exp_Dt` DATE DEFAULT NULL -- ,
    -- PRIMARY KEY (`Sub_Id`),
    -- KEY `Sub_Id` (`Sub_Id` , `Tgt_Offer_Cd`)
);

INSERT INTO `LEGACY`.`M_OFFER_M12_MERGE_PRD`
(`Sub_Id`,
`Tgt_Offer_Id`,
`Tgt_Offer_Cd`,
`Tgt_Offer_Type`,
`Product_Id`,
`MDM_Type_Cd`,
`Main_Prod_Ind`,
`Service_Flag`,
`Feature_Cd` -- ,

)
 SELECT
           '1' AS Sub_Id
    ,      'DUMMY' AS Tgt_Offer_Id
    ,      'DUMMY' AS Tgt_Offer_Cd
    ,       'D' AS  Tgt_Offer_Type
    ,       '1' AS Product_Id
    ,       'DUMMY' AS  MDM_Type_Cd
    ,       '1' AS  Main_Prod_Ind
    ,       'DUMMY' AS  Service_Flag

    ,       'DUMMY' AS  Feature_CD
;

DROP TABLE IF EXISTS LEGACY.M_OFFER_M10_MERGE_PRD_W;
call LEGACY.createindex_ifnotexists('LEGACY','M_IDID_OFFER_MOD','Use_Flag,Split_Type,MDM_Type_Cd');

CREATE TABLE LEGACY.M_OFFER_M10_MERGE_PRD_W as
  SELECT
          OFR.Relat_Offer_Id Tgt_Offer_Id
  ,       OFR.Tgt_Offer_Cd
  ,       OFR.Veris_Object_Id AS Product_Id
  ,       OFR.MDM_Type_Cd
  ,       OFR.Service_Flag
  ,       PRD.Feature_Cd
  FROM
                      /*${WORK_TB}*/ M_IDID_OFFER_MOD   AS  OFR
          LEFT  JOIN  /*${WORK_TB}*/ (SELECT DISTINCT Product_Id, Feature_Cd FROM M_IDID_ATTR_MOD)    AS  PRD
                  ON  (
                          OFR.Veris_Object_Id = PRD.Product_Id
                      )
  WHERE
          (OFR.Use_Flag = 'Y' or OFR.Split_Type in (2,4,10) )
  AND     (
                  OFR.MDM_Type_Cd = 'PRICE_PROD'
              OR  (OFR.MDM_Type_Cd = 'SRVC_SINGLE' AND OFR.Service_Flag LIKE '%Mandatory%')
              OR  (OFR.MDM_Type_Cd = 'SRVC_SINGLE' AND PRD.Feature_Cd IS NOT NULL)
          );
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M10_MERGE_PRD_W','Tgt_Offer_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M10_MERGE_PRD_W','Tgt_Offer_Id');

INSERT INTO `LEGACY`.`M_OFFER_M12_MERGE_PRD` -- 61 012 926 / 309
(`Sub_Id`,
`Tgt_Offer_Id`,
`Tgt_Offer_Cd`,
`Tgt_Offer_Type`,
`Product_Id`,
`MDM_Type_Cd`,
`Main_Prod_Ind`,
`Service_Flag`,
`Feature_Cd` -- ,
-- `Feature_Switch_Ind`,
-- `Feature_Order_No`,
-- `SOC_Cd`,
-- `SOC_Seq_No`,
-- `Feature_Seq_No`,
-- `Eff_Dt`,
-- `Exp_Dt`
)
SELECT
        M.Sub_Id
,       M.Tgt_Offer_Id
,       M.Tgt_Offer_Cd
,       M.Tgt_Offer_Type
,       R.Product_Id
,       R.MDM_Type_Cd
,       (CASE WHEN (M.Product_Id = R.Product_Id) THEN 'Y' ELSE 'N' END) AS  Main_Prod_Ind
,       R.Service_Flag

,       (CASE WHEN (R.Feature_Cd IS NOT NULL)                       THEN R.Feature_Cd
              WHEN (M.Tgt_Offer_Type = 'T' AND (M.Product_Id = R.Product_Id)) THEN 'PPCPKG'
              WHEN (R.MDM_Type_Cd = 'PRICE_PROD')                   THEN 'CPKG'
                                                                    ELSE NULL
        END)  AS  Feature_Cd
FROM
            M_OFFER_M10_MERGE               AS  M
INNER JOIN  LEGACY.M_OFFER_M10_MERGE_PRD_W  AS  R
        ON  M.Tgt_Offer_Id = R.Tgt_Offer_Id
;


-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : UPDATE
-- <Table> : /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD
-- <Brief> : Munka tábla karbantartása
-- <Desc>  : ...
-- ------------------------------------------------------------------------------------------</###>--

-- ????
-- ??? UPDATE  PRD
-- ??? FROM    /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD   AS  PRD
-- ??? ,       (
-- ???             SELECT
-- ???                     F.Feature_Code  AS  Feature_Cd
-- ???             FROM
-- ???                                 /*${WORK_TB}*/ M_REF_Base_Feature  AS  B
-- ???                     INNER JOIN  /*${WORK_TB}*/ M_REF_Feature       AS  F
-- ???                             ON  (
-- ???                                         F.MPS_Feature_Code = B.Base_Feature_Code
-- ???                                     AND B.Billing_Switch_Ind = 'Y'
-- ???                                 )
-- ???         )
-- ???         AS  REF
-- ??? SET     Feature_Switch_Ind = 'Y'
-- ??? WHERE   PRD.Feature_Cd = REF.Feature_Cd
-- ??? ;
-- .if errorcode<>0 then .quit errorcode



-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : UPDATE
-- <Table> : /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD
-- <Brief> : Munka tábla karbantartása
-- <Desc>  : Megsorszámozzuk az azonos Feature_Cd-ket Sub_Id-n belül.
--           - Az update-hez biztosítottuk a (Sub_Id, Tgt_Offer_Cd, Product_Id) egyediségét.
-- ------------------------------------------------------------------------------------------</###>--
SET SQL_SAFE_UPDATES=0;

-- call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M12_MERGE_PRD','Feature_Cd,Feature_Order_No,Sub_Id');
-- call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M12_MERGE_PRD','Sub_Id,Feature_Cd,Feature_Order_No');
-- call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M12_MERGE_PRD','Sub_Id,Tgt_Offer_Cd,Product_Id');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M12_MERGE_PRD','Sub_Id,Tgt_Offer_Id,Product_Id'); -- 388


UPDATE  M_OFFER_M12_MERGE_PRD as PRD  -- 900+ (3000)
JOIN (
            SELECT
                    Sub_Id
            ,       Tgt_Offer_Id
            ,       Tgt_Offer_Cd
            ,       Product_Id
            ,case when @n=Sub_Id and @c=Feature_Cd then @i:=@i+1 else @i:=1 end
                                      AS Feature_Order_No
            , @n:=Sub_Id  n
            , @c:=Feature_Cd c
            FROM
                    M_OFFER_M12_MERGE_PRD
            WHERE
                    Feature_Cd IS NOT NULL
            order by  Sub_Id
                    , Feature_Cd
                    , (CASE WHEN TGT_Offer_Type = 'T' THEN 1 ELSE 2 END)
                    , Tgt_Offer_Cd
                    , Tgt_Offer_Id
                    , Product_Id
        ) AS  SEQ
    ON      PRD.Sub_Id       = SEQ.Sub_Id
--    AND     PRD.Tgt_Offer_Cd = SEQ.Tgt_Offer_Cd
    AND     PRD.Tgt_Offer_Id = SEQ.Tgt_Offer_Id
    AND     PRD.Product_Id   = SEQ.Product_Id
SET     PRD.Feature_Order_No = SEQ.Feature_Order_No
;


SET SQL_SAFE_UPDATES=1;


-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : UPDATE
-- <Table> : /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD
-- <Brief> : Munka tábla karbantartása
-- <Desc>  : Megsorszámozzuk az azonos Feature_Cd-ket Sub_Id-n belül.
--           - Sub_Id / Feature_Cd szerinti párosítás ... itt még a SOC-ot figyelembe kellene
--             venni, ha van.
--           - PPCPKG ~~ Main Offer / Main Product (Sub_Id-re mindkettő egyedi kell hogy legyen.)
--           - CPKG   ~~ Egyéb PRICE_PROD
-- ------------------------------------------------------------------------------------------</###>--

SET SQL_SAFE_UPDATES=0;
-- call LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE','Sub_Id,Feature_Cd,Feature_Seq_No');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M12_MERGE_PRD','Sub_Id,Feature_Cd,Feature_Order_No'); -- 708

UPDATE  M_OFFER_M12_MERGE_PRD   AS  PRD -- 839
JOIN    (
            SELECT
                    Sub_Id
            ,       SOC_Cd
            ,       SOC_Seq_No
            ,       FEATURE_CODE Feature_Cd
            ,       SERVICE_FTR_SEQ_NO Feature_Seq_No
            ,       FTR_EFFECTIVE_DATE Eff_Dt
            ,       FTR_EXPIRATION_DATE Exp_Dt
            ,case when @n=Sub_Id and @c=FEATURE_CODE then @i:=@i+1 else @i:=1 end
                                      AS Feature_Order_No
            , @n:=Sub_Id  n
            , @c:=FEATURE_CODE c
            FROM
                    -- M_FEATURE
                    M_FEATURE_EXTR
            order by  Sub_Id
                    , FEATURE_CODE
                    , SERVICE_FTR_SEQ_NO
        )
        AS  FTR
ON      PRD.Sub_Id           = FTR.Sub_Id
AND     PRD.Feature_Cd       = FTR.Feature_Cd
AND     PRD.Feature_Order_No = FTR.Feature_Order_No
SET
        PRD.SOC_Cd         = FTR.SOC_Cd
,       PRD.SOC_Seq_No     = FTR.SOC_Seq_No
,       PRD.Feature_Seq_No = FTR.Feature_Seq_No
,       PRD.Eff_Dt         = FTR.Eff_Dt
,       PRD.Exp_Dt         = FTR.Exp_Dt
WHERE
-- --------
        PRD.Feature_Cd IS NOT NULL
-- --------
;
-- .if errorcode<>0 then .quit errorcode

SET SQL_SAFE_UPDATES=1;


-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : UPDATE
-- <Table> : /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD
-- <Brief> : Munka tábla karbantartása
-- <Desc>  : Feature_Seq_No "kiosztása"
--           - Akihez nincs Feature_Seq_No, de van hozzá Feature_Cd ( vagyis Feature_Cd alapon,
--             vagy Mandatory / PRICE_PROD alapon került ide: PPCPKG, CPKG) azokat migráljuk,
--             tehát jobb híján osztunk egy szekvencia sorszámot.
--             (Fejlesztéskor a MAX(Feature_Seq_No) értéke 1,298,193,866 volt.)
-- ------------------------------------------------------------------------------------------</###>--

SET SQL_SAFE_UPDATES=0;
-- call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M12_MERGE_PRD','Feature_Seq_No,Feature_Cd');

-- set @i:=2000000000;
set @i:=LEGACY.CONFIG('GEN_Feature_Seq_No', NULL);

UPDATE  M_OFFER_M12_MERGE_PRD   AS  PRD
JOIN    (
            SELECT
                    Sub_Id
            ,       Tgt_Offer_Id
            ,       Tgt_Offer_Cd
            ,       Product_Id
            ,       @i:=@i+1
                                          AS GEN_Feature_Seq_No
            FROM
                    M_OFFER_M12_MERGE_PRD
            WHERE
                    Feature_Cd IS NOT NULL
            AND     Feature_Seq_No IS NULL
            ORDER BY Sub_Id
                   , (CASE WHEN TGT_Offer_Type = 'T' THEN 1 ELSE 2 END)
                   , Tgt_Offer_Cd
                   , Tgt_Offer_Id
                   , Product_Id
        )
        AS  SEQ
ON
        PRD.Sub_Id       = SEQ.Sub_Id
-- AND     PRD.Tgt_Offer_Cd = SEQ.Tgt_Offer_Cd
AND     PRD.Tgt_Offer_Id = SEQ.Tgt_Offer_Id
AND     PRD.Product_Id   = SEQ.Product_Id
SET     Feature_Seq_No = SEQ.GEN_Feature_Seq_No
-- WHERE
;
-- .if errorcode<>0 then .quit errorcode
SET SQL_SAFE_UPDATES=1;
