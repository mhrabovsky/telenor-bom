-- 5300.
USE LEGACY;

-- Futasido (.133-as gep): 17 perc
/*

Here, offers coming from DWH are mapped with IDID-map tables.
This code also eliminates multi-match (split type) multiplication with Use_Flag and Main_Product_Flag.
For Split_Type=4 these flags should be revised to allow offer multiplication.

*/

-- NAS 10.07 beégetések bővítése
SET @MDM_TYPE_SHARPLAN = LEGACY.CONFIG('MDM_TYPE_SHARPLAN',NULL);
SET @TGT_OFFER_INST_ID = CAST(LEGACY.CONFIG('TGT_OFFER_INST_ID','900000000') AS UNSIGNED);

DROP TABLE if exists M_OFFER_M00_DWH;
DROP TABLE if exists M_OFFER_M00_DWH_SUB_ID;

call LEGACY.createindex_ifnotexists('LEGACY','M_SOC','Sub_Id,Svc_Class_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_IDID_OFFER_MOD','Tgt_Offer_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_MAP','Tgt_Offer_Cd');


CREATE TABLE M_OFFER_M00_DWH
AS
  SELECT
    Sub_Id,
    CA_Id,
    BAN,
    CTN,
    Main_Offer_Cd,
    Main_Offer_Id,
    Main_Offer_Inst_Id,
    Tgt_Offer_Cd,
    Tgt_Offer_Name,
    Tgt_Offer_Type,
    Tgt_Offer_Id,
    @i:=@i+1 Tgt_Offer_Inst_Id,
    Service_Attr_Value,
    Map_Type,
    Id2Id_Rec_Id,
    Src_SOC_Cd,
    Src_SOC_Seq_No,
    Src_Svc_Class_Cd,
    Migr_Offer_Ind,
    Migr_SOC_Ind,
    Migr_Rsn_Cd,
    Sub_Type, 
    SUBSCRIBER_REF, 
    VOICE_BILLING_INCREMENT,
    Split_Type
from (
    SELECT
    -- ---
            DWH_XTR.Sub_Id              AS  Sub_Id
    ,       DWH_XTR.CA_Id               AS  CA_Id
    ,       DWH_XTR.BAN                 AS  BAN
    ,       DWH_XTR.CTN                 AS  CTN
    -- ---
    ,       cast(NULL as CHAR(30))      AS  Main_Offer_Cd
    ,       cast(NULL as UNSIGNED)      AS  Main_Offer_Id
    ,       cast(NULL as UNSIGNED)      AS  Main_Offer_Inst_Id
    -- ---
    ,       DWH_XTR.Tgt_Offer_Cd        AS  Tgt_Offer_Cd
    ,       ID2ID_MAP.Tgt_Offer_Name    AS  Tgt_Offer_Name
    ,       ID2ID_MAP.Tgt_Offer_Type    AS  Tgt_Offer_Type
    -- ---
    ,       ID2ID_MAP.Relat_Offer_Id    AS  Tgt_Offer_Id
    -- ---
    ,       case when ID2ID_MAP.Split_Type =4    -- Split type 4 ertek. Felezni kell.
              then cast(DWH_XTR.Tgt_Offer_Val/2 as decimal(15,2))
              else cast(DWH_XTR.Tgt_Offer_Val   as decimal(15,2))
              end                       AS Service_Attr_Value
    -- ---
    ,       ID2ID_MAP.Map_Type          AS  Map_Type
    ,       ID2ID_MAP.Id2Id_Rec_Id      AS  Id2Id_Rec_Id
    -- ---
    ,       SOC_XTR.SOC_Cd              AS  Src_SOC_Cd
    ,       SOC_XTR.SOC_Seq_No          AS  Src_SOC_Seq_No
    ,       SOC_XTR.Svc_Class_Cd        AS  Src_Svc_Class_Cd
    -- ---
    ,       cast(NULL as CHAR(1))       AS  Migr_Offer_Ind
    ,       cast(NULL as CHAR(1))       AS  Migr_SOC_Ind
    ,       cast(NULL as UNSIGNED)      AS  Migr_Rsn_Cd
    -- ---
    --      MT: Split type 2 es 10 igenyli az alabbi adatokat: user.Sub_Type, mappig.VOICE_BILLING_INCREMENT
    ,       DWH_XTR.Sub_Type
    ,       DWH_XTR.SUBSCRIBER_REF
    ,       M.VOICE_BILLING_INCREMENT
    ,       ID2ID_MAP.Split_Type
    FROM        M_DWH_B2B            AS  DWH_XTR
    -- ---
    LEFT  JOIN  M_IDID_OFFER_MOD     AS  ID2ID_MAP
            ON    DWH_XTR.Tgt_Offer_Cd        = ID2ID_MAP.Tgt_Offer_Cd
              AND ID2ID_MAP.Use_Flag          = 'Y'
              AND ID2ID_MAP.Main_Product_Flag = 'Y'
            -- AND ID2ID_MAP.MDM_Type_Cd NOT IN ('SHARPLAN') -- ABO: Krisz 07-05
              AND ID2ID_MAP.TGT_OFFER_TYPE_DESC in ('GSM MAIN OFFER','ADDON Offer') -- mgy: Krisz 07-20
    -- --- PP egyedisegehez DWH es SOC forrasbol jovo tarifak esetere (nem letfontossagu, de lassit)
    LEFT  JOIN  M_SOC                AS  SOC_XTR
            ON    SOC_XTR.Sub_Id           = DWH_XTR.Sub_Id
              AND SOC_XTR.Svc_Class_Cd     = 'PP'   --  PP duplikáció nem lehet !!!
              AND ID2ID_MAP.Tgt_Offer_Type = 'T'
    -- ---
    -- MT: Split 2-hoz kell a VOICE_BILLING_INCREMENT adat. Kb. 2 percet lassit a fenti indexszel.
    LEFT OUTER JOIN M_OFFER_MAP M
            ON M.Tgt_Offer_Cd=DWH_XTR.Tgt_Offer_Cd
              AND ID2ID_MAP.Tgt_Offer_Type = 'T'
    -- ---
-- mgy 2016.07.07 megtartva az 'A' és null (az offer_cd nincs az idid mappingben) Tgt_Offer_Type-okat, 'T'-ből kiszűri a 'SHARPLAN' MDM_Type_Cd-ket
    WHERE coalesce(ID2ID_MAP.MDM_Type_Cd,'X') NOT IN (@MDM_TYPE_SHARPLAN) 
    ORDER BY
      DWH_XTR.Sub_Id,
      (CASE ID2ID_MAP.Tgt_Offer_Type WHEN 'T' THEN 1 WHEN 'A' THEN 2 ELSE 3 END),
      DWH_XTR.Tgt_Offer_Cd
  ) x,
  (select @i:=@TGT_OFFER_INST_ID) i
-- order by Sub_Id, (CASE Tgt_Offer_Type WHEN 'T' THEN 1 WHEN 'A' THEN 2 ELSE 3 END), Tgt_Offer_Cd
;


call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M00_DWH','Tgt_Offer_Type,Sub_Id,Tgt_Offer_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M00_DWH','Sub_Id,Tgt_Offer_Type,Tgt_Offer_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M00_DWH','Tgt_Offer_Type,Sub_Id,Tgt_Offer_Id');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M00_DWH','Sub_Id,Tgt_Offer_Type,Tgt_Offer_Id');
-- call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M00_DWH','Sub_Id,Tgt_Offer_Type,Tgt_Offer_Cd,Tgt_Offer_Id,Tgt_Offer_Inst_Id,VOICE_BILLING_INCREMENT');

UPDATE  M_OFFER_M00_DWH  AS  O
join M_OFFER_M00_DWH AS T
  on O.Sub_Id = T.Sub_Id
  and 'T' = T.Tgt_Offer_Type
SET     O.Main_Offer_Cd      = T.Tgt_Offer_Cd
,       O.Main_Offer_Id      = T.Tgt_Offer_Id
,       O.Main_Offer_Inst_Id = T.Tgt_Offer_Inst_Id
,       O.VOICE_BILLING_INCREMENT = T.VOICE_BILLING_INCREMENT
;


CREATE TABLE M_OFFER_M00_DWH_SUB_ID
AS
(
    SELECT  Sub_Id
    ,       MAX(CASE WHEN (Main_Offer_Cd IS NOT NULL) THEN 'Y' ELSE 'N' END)    AS  Main_Offer_Ind
    ,       MAX(CASE WHEN (Src_SOC_Cd    IS NOT NULL) THEN 'Y' ELSE 'N' END)    AS  Price_Plan_Ind
    ,       COUNT(*)                                                            AS  Tgt_Offer_Cnt
    FROM    M_OFFER_M00_DWH
    GROUP BY
            Sub_Id
)
;


