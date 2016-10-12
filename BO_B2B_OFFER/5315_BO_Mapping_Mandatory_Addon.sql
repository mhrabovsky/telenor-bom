-- USE LEGACY;

-- Futasido (3-as gep): 11 perc
/*

Here, mandatory addon offers are mapped with offer-map and IDID-map tables.
This code also eliminates multi-match (split type) multiplication with Use_Flag and Main_Product_Flag.
For Split_Type=4 these flags should be revised to allow offer multiplication.

*/


call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M01_TARIFF','Tgt_Offer_Type,Tgt_Offer_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M00_DWH','Tgt_Offer_Type,Tgt_Offer_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','EDSZ_LDR','BAN_BEN_CTN');

DROP TABLE if exists LEGACY.M_OFFER_M03_MAND_ADDON;

-- NAS 10.04 beégetések bõvítése
SET @i=CAST(LEGACY.CONFIG('Mand_Addon_Offer_Inst_Id','950000000') AS UNSIGNED);
SET @OFFER_CD_EDSZ=LEGACY.CONFIG('OFFER_CD_EDSZ',NULL);

CREATE TABLE LEGACY.M_OFFER_M03_MAND_ADDON
AS
  SELECT
  -- ---
          CA_Id
  ,       BAN
  ,       CTN
  ,       Sub_Id
  ,       Main_Offer_Cd
  ,       Main_Offer_Inst_Id
  ,       Mand_Addon_Offer_Cd
  -- ---
  ,       @i:=@i+1  AS  Mand_Addon_Offer_Inst_Id
  -- ---
  ,       Src_SOC_Cd
  ,       Src_SOC_Seq_No
  ,       Src_Svc_Class_Cd
  -- ---
  ,       Map_Type_Main
  -- ---
  ,       Map_Type
  ,       Map_Src
  ,       Id2Id_Rec_Id
  -- ---
  ,       Addon_Ind
  -- ---
  ,       cast(NULL as CHAR(1))      AS  Migr_Offer_Ind
  ,       cast(NULL as CHAR(1))      AS  Migr_SOC_Ind
  ,       cast(NULL as UNSIGNED)     AS  Migr_Rsn_Cd
  -- ---
  -- MT: A Split type 2 es 10 igenyli az alabbi adatokat: User.Sub_Type, map.VOICE_BILLING_INCREMENT
  ,       Sub_Type
  ,       SUBSCRIBER_REF
  ,       VOICE_BILLING_INCREMENT
  -- ---
    /*
    -- Ide mar be kellene dobni az alabbi adatokat, hogy kesobb ne join-oljunk IDID tablat:
    Tgt_Offer_Name varchar(1000),
    Tgt_Offer_Id   bigint,
    Split_Type     integer
    */
  FROM (
    SELECT
      -- 
         MAIN_OFFER.CA_Id                AS  CA_Id
      ,  MAIN_OFFER.BAN                  AS  BAN
      ,  MAIN_OFFER.CTN                  AS  CTN
      ,  MAIN_OFFER.Sub_Id               AS  Sub_Id
      ,  MAIN_OFFER.Tgt_Offer_Cd         AS  Main_Offer_Cd
      ,  MAIN_OFFER.Src_SOC_Seq_No       AS  Main_Offer_Inst_Id
      ,  MAND_ADDON_MAP.Addon_Offer_Cd   AS  Mand_Addon_Offer_Cd
      -- 
      ,  COALESCE(ADDON_OFFER_SOC.Src_SOC_Cd      , ADDON_OFFER_DWH.Src_SOC_Cd      )    AS  Src_SOC_Cd
      ,  COALESCE(ADDON_OFFER_SOC.Src_SOC_Seq_No  , ADDON_OFFER_DWH.Src_SOC_Seq_No  )    AS  Src_SOC_Seq_No
      ,  COALESCE(ADDON_OFFER_SOC.Src_Svc_Class_Cd, ADDON_OFFER_DWH.Src_Svc_Class_Cd)    AS  Src_Svc_Class_Cd
      -- 
      ,  MAIN_OFFER.Map_Type             AS  Map_Type_Main
      ,  MAND_ADDON_MAP.Map_Type         AS  Map_Type
      ,  'TAR'                  AS  Map_Src
      -- 
      ,  (CASE WHEN (COALESCE(ADDON_OFFER_SOC.Sub_Id, ADDON_OFFER_DWH.Sub_Id) IS NOT NULL) THEN 'Y' ELSE 'N' END)  AS  Addon_Ind
      -- 
      ,  ID2ID_MAP.Id2Id_Rec_Id          AS  Id2Id_Rec_Id
      -- 
      -- MT: A Split type 2 es 10 igenyli az alabbi adatokat: User.Sub_Type, map.VOICE_BILLING_INCREMENT
      ,  COALESCE(ADDON_OFFER_SOC.Sub_Type, ADDON_OFFER_DWH.Sub_Type) Sub_Type
      ,  COALESCE(ADDON_OFFER_SOC.SUBSCRIBER_REF, ADDON_OFFER_DWH.SUBSCRIBER_REF) SUBSCRIBER_REF
      ,  MAIN_OFFER.VOICE_BILLING_INCREMENT
      -- ---
    FROM
                LEGACY.M_OFFER_M01_TARIFF  AS  MAIN_OFFER
    INNER JOIN  LEGACY.M_OFFER_MANDADD_MAP AS  MAND_ADDON_MAP
            ON  (
                    MAIN_OFFER.Tgt_Offer_Cd = MAND_ADDON_MAP.Main_Offer_Cd
                )
    LEFT  JOIN  LEGACY.M_OFFER_M02_ADDON   AS  ADDON_OFFER_SOC
            ON  (
                        MAIN_OFFER.Sub_Id             = ADDON_OFFER_SOC.Sub_Id
                    AND MAND_ADDON_MAP.Addon_Offer_Cd = ADDON_OFFER_SOC.Tgt_Offer_Cd
                    -- ---
                    AND ADDON_OFFER_SOC.First_SOC_Seq_No  = ADDON_OFFER_SOC.Src_SOC_Seq_No
                )
    LEFT  JOIN  LEGACY.M_OFFER_M00_DWH     AS  ADDON_OFFER_DWH
            ON  (
                        MAIN_OFFER.Sub_Id              = ADDON_OFFER_DWH.Sub_Id
                    AND MAND_ADDON_MAP.Addon_Offer_Cd  = ADDON_OFFER_DWH.Tgt_Offer_Cd
                    -- ---
                    AND ADDON_OFFER_DWH.Tgt_Offer_Type = 'A'
                )
    LEFT  JOIN  LEGACY.M_IDID_OFFER_MOD  AS  ID2ID_MAP
            ON  (
                        ID2ID_MAP.Tgt_Offer_Cd      = MAND_ADDON_MAP.Addon_Offer_Cd
                    -- ---
                    AND ID2ID_MAP.Use_Flag          = 'Y'
                    AND ID2ID_MAP.Main_Product_Flag = 'Y'
                )
    WHERE
          MAIN_OFFER.Tgt_Offer_Type        = 'T'
      AND MAIN_OFFER.Src_Price_Plan_Seq_No = MAIN_OFFER.Src_SOC_Seq_No -- /Offer-egyediseg (PP-SOC --> "driver")
    -- ----- ---
    UNION
    -- ----- ---
    SELECT
      -- 
         MAIN_OFFER.CA_Id                AS  CA_Id
      ,  MAIN_OFFER.BAN                  AS  BAN
      ,  MAIN_OFFER.CTN                  AS  CTN
      ,  MAIN_OFFER.Sub_Id               AS  Sub_Id
      ,  MAIN_OFFER.Main_Offer_Cd        AS  Main_Offer_Cd
      ,  MAIN_OFFER.Main_Offer_Inst_Id   AS  Main_Offer_Inst_Id
      ,  MAND_ADDON_MAP.Addon_Offer_Cd   AS  Mand_Addon_Offer_Cd
      -- 
      ,  COALESCE(ADDON_OFFER_SOC.Src_SOC_Cd      , ADDON_OFFER_DWH.Src_SOC_Cd      )    AS  Src_SOC_Cd
      ,  COALESCE(ADDON_OFFER_SOC.Src_SOC_Seq_No  , ADDON_OFFER_DWH.Src_SOC_Seq_No  )    AS  Src_SOC_Seq_No
      ,  COALESCE(ADDON_OFFER_SOC.Src_Svc_Class_Cd, ADDON_OFFER_DWH.Src_Svc_Class_Cd)    AS  Src_Svc_Class_Cd
      -- 
      ,  MAIN_OFFER.Map_Type             AS  Map_Type_Main
      ,  MAND_ADDON_MAP.Map_Type         AS  Map_Type
      ,  'DWH'                  AS  Map_Src
      -- 
      ,  (CASE WHEN (COALESCE(ADDON_OFFER_SOC.Sub_Id, ADDON_OFFER_DWH.Sub_Id) IS NOT NULL) THEN 'Y' ELSE 'N' END)  AS  Addon_Ind
      -- 
      ,  ID2ID_MAP.Id2Id_Rec_Id          AS  Id2Id_Rec_Id
      -- 
      -- MT: A Split type 2 es 10 igenyli az alabbi adatokat: User.Sub_Type, map.VOICE_BILLING_INCREMENT
      ,  COALESCE(ADDON_OFFER_SOC.Sub_Type, ADDON_OFFER_DWH.Sub_Type) Sub_Type
      ,  COALESCE(ADDON_OFFER_SOC.SUBSCRIBER_REF, ADDON_OFFER_DWH.SUBSCRIBER_REF) SUBSCRIBER_REF
      ,  MAIN_OFFER.VOICE_BILLING_INCREMENT
      -- ---
    FROM
                LEGACY.M_OFFER_M00_DWH     AS  MAIN_OFFER
    INNER JOIN  LEGACY.M_OFFER_MANDADD_MAP AS  MAND_ADDON_MAP
            ON  (
                    MAIN_OFFER.Tgt_Offer_Cd = MAND_ADDON_MAP.Main_Offer_Cd
                )
    LEFT  JOIN  LEGACY.M_OFFER_M02_ADDON   AS  ADDON_OFFER_SOC
            ON  (
                        MAIN_OFFER.Sub_Id                = ADDON_OFFER_SOC.Sub_Id
                    AND MAND_ADDON_MAP.Addon_Offer_Cd    = ADDON_OFFER_SOC.Tgt_Offer_Cd
                    -- ---
                    AND ADDON_OFFER_SOC.First_SOC_Seq_No = ADDON_OFFER_SOC.Src_SOC_Seq_No
                )
    LEFT  JOIN  LEGACY.M_OFFER_M00_DWH     AS  ADDON_OFFER_DWH
            ON  (
                        MAIN_OFFER.Sub_Id              = ADDON_OFFER_DWH.Sub_Id
                    AND MAND_ADDON_MAP.Addon_Offer_Cd  = ADDON_OFFER_DWH.Tgt_Offer_Cd
                    -- ---
                    AND ADDON_OFFER_DWH.Tgt_Offer_Type = 'A'
                )
    LEFT  JOIN  LEGACY.M_IDID_OFFER_MOD  AS  ID2ID_MAP
            ON  (
                        MAND_ADDON_MAP.Addon_Offer_Cd = ID2ID_MAP.Tgt_Offer_Cd
                    -- ---
                    AND ID2ID_MAP.Use_Flag            = 'Y'
                    AND ID2ID_MAP.Main_Product_Flag   = 'Y'
                )
    WHERE
            MAIN_OFFER.Tgt_Offer_Type = 'T'
    ) AS  Q
ORDER BY Sub_Id, Main_Offer_Cd, Main_Offer_Inst_Id, Mand_Addon_Offer_Cd
;

select concat('End create M03: ', now(), ', affected rows:', ROW_COUNT());


-- NGy 08.08
-- Repeta extract(EDSZ_LDR) - ABCONPRS Addon - Hitelkeret
insert into LEGACY.M_OFFER_M03_MAND_ADDON
SELECT
  -- 
     MAIN_OFFER.CA_Id                AS  CA_Id
  ,  MAIN_OFFER.BAN                  AS  BAN
  ,  MAIN_OFFER.CTN                  AS  CTN
  ,  MAIN_OFFER.Sub_Id               AS  Sub_Id
  ,  MAIN_OFFER.Tgt_Offer_Cd         AS  Main_Offer_Cd
  ,  MAIN_OFFER.Src_SOC_Seq_No       AS  Main_Offer_Inst_Id
  ,  @OFFER_CD_EDSZ                  AS  Mand_Addon_Offer_Cd
  -- 
  ,  @i:=@i+1  AS  Mand_Addon_Offer_Inst_Id
  -- 
  ,  Null    AS  Src_SOC_Cd
  ,  Null    AS  Src_SOC_Seq_No
  ,  Null    AS  Src_Svc_Class_Cd
  -- 
  ,  MAIN_OFFER.Map_Type             AS  Map_Type_Main
  ,  ID2ID_MAP.Map_Type         AS  Map_Type
  ,  'TAR'                        AS  Map_Src
  -- 
  ,  ID2ID_MAP.Id2Id_Rec_Id          AS  Id2Id_Rec_Id
  ,  'N'  AS  Addon_Ind
  -- 
  ,  Null      AS  Migr_Offer_Ind
  ,  Null      AS  Migr_SOC_Ind
  ,  Null      AS  Migr_Rsn_Cd
  -- MT: A Split type 2 es 10 igenyli az alabbi adatokat: User.Sub_Type, map.VOICE_BILLING_INCREMENT
  ,  MAIN_OFFER.Sub_Type
  ,  MAIN_OFFER.SUBSCRIBER_REF
  ,  MAIN_OFFER.VOICE_BILLING_INCREMENT
  -- ---
FROM
            LEGACY.M_OFFER_M01_TARIFF  AS  MAIN_OFFER
INNER JOIN  LEGACY.EDSZ_LDR      AS  EDSZ
    ON   MAIN_OFFER.sub_id = EDSZ.BAN_BEN_CTN
--    ON  MAIN_OFFER.ctn = EDSZ.ctn -- addigis
    and EDSZ.amount <> '0'
LEFT  JOIN  LEGACY.M_IDID_OFFER_MOD  AS  ID2ID_MAP
    ON  ID2ID_MAP.Tgt_Offer_Cd      = @OFFER_CD_EDSZ
    AND ID2ID_MAP.Use_Flag          = 'Y'
    AND ID2ID_MAP.Main_Product_Flag = 'Y'
WHERE
        MAIN_OFFER.Tgt_Offer_Type        = 'T'
AND     MAIN_OFFER.Src_Price_Plan_Seq_No = MAIN_OFFER.Src_SOC_Seq_No -- /Offer-egyediseg (PP-SOC --> "driver")
;

select concat('End ins1 M03: ', now(), ', affected rows:', ROW_COUNT());


insert into LEGACY.M_OFFER_M03_MAND_ADDON
SELECT
-- ---
        MAIN_OFFER.CA_Id                AS  CA_Id
,       MAIN_OFFER.BAN                  AS  BAN
,       MAIN_OFFER.CTN                  AS  CTN
,       MAIN_OFFER.Sub_Id               AS  Sub_Id
,       MAIN_OFFER.Main_Offer_Cd        AS  Main_Offer_Cd
,       MAIN_OFFER.Main_Offer_Inst_Id   AS  Main_Offer_Inst_Id
,       @OFFER_CD_EDSZ                  AS  Mand_Addon_Offer_Cd
-- ---
,       @i:=@i+1  AS  Mand_Addon_Offer_Inst_Id
-- ---
,       Null    AS  Src_SOC_Cd
,       Null    AS  Src_SOC_Seq_No
,       Null    AS  Src_Svc_Class_Cd
-- ---
,       MAIN_OFFER.Map_Type             AS  Map_Type_Main
,       ID2ID_MAP.Map_Type             AS  Map_Type
,       'DWH'                        AS  Map_Src
-- ---
,       ID2ID_MAP.Id2Id_Rec_Id          AS  Id2Id_Rec_Id
,       'N'  AS  Addon_Ind
-- ---
,       Null      AS  Migr_Offer_Ind
,       Null      AS  Migr_SOC_Ind
,       Null      AS  Migr_Rsn_Cd
  -- MT: A Split type 2 es 10 igenyli az alabbi adatokat: User.Sub_Type, map.VOICE_BILLING_INCREMENT
  ,  MAIN_OFFER.Sub_Type
  ,  MAIN_OFFER.SUBSCRIBER_REF
  ,  MAIN_OFFER.VOICE_BILLING_INCREMENT
  -- ---
FROM
                LEGACY.M_OFFER_M00_DWH     AS  MAIN_OFFER
    INNER JOIN  LEGACY.EDSZ_LDR      AS  EDSZ
    ON  MAIN_OFFER.sub_id = EDSZ.BAN_BEN_CTN
--    ON  MAIN_OFFER.ctn = EDSZ.ctn -- addigis 
            and EDSZ.amount <> '0'
    LEFT  JOIN  LEGACY.M_IDID_OFFER_MOD  AS  ID2ID_MAP
            ON  ID2ID_MAP.Tgt_Offer_Cd      = @OFFER_CD_EDSZ
            AND ID2ID_MAP.Use_Flag          = 'Y'
            AND ID2ID_MAP.Main_Product_Flag = 'Y'
WHERE
        MAIN_OFFER.Tgt_Offer_Type = 'T'
;
select concat('End ins2 M03: ', now(), ', affected rows:', ROW_COUNT());









