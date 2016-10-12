-- 5320.
USE LEGACY;
/*

Here, some control data are corrected with updates. These data indicate if an offer should be migrated or not.
Also, error/warning codes are also set as evidence to block offers from migratiing to MDM.
These updates cannot be run in earlier phase, thus these update steps are done here.

*/


SET SQL_SAFE_UPDATES=0;

DROP TABLE if exists M_OFFER_MIGR_RSN;

CREATE TABLE M_OFFER_MIGR_RSN
(
    Migr_Rsn_Cd     SMALLINT        NOT NULL
,   Migr_Ind        CHAR(1)         NOT NULL
,   Migr_Rsn_Name   VARCHAR(100)    NOT NULL
,   Migr_Rsn_Desc   VARCHAR(1000)   NOT NULL
)
;

INSERT INTO M_OFFER_MIGR_RSN VALUES ( 11, 'Y', 'Migrált Offer - DWH Sub_Id és DWH-ban kalkulált Main Offer eset'
                                                     , 'Migrált Offer DWH-ban szereplö Sub_Id és DWH-ban kalkulált Main Offer esetén');

INSERT INTO M_OFFER_MIGR_RSN VALUES ( 12, 'Y', 'Migrált Offer - DWH Sub_Id és SOC kombináció szerinti Main Offer eset'
                                                     , 'Migrált Offer DWH-ban szereplö Sub_Id és SOC kombináció szerinti Main Offer esetén');

INSERT INTO M_OFFER_MIGR_RSN VALUES ( 13, 'Y', 'Migrált Offer - pusztán PanDocs SOC mapping eset'
                                                     , 'Migrált Offer DWH-ban nem szereplö Sub_Id esetén');

INSERT INTO M_OFFER_MIGR_RSN VALUES ( 15, 'Y', 'Migrált Mandatory Addon - DWH kalkuláció szerinti Main Offer eset'
                                                     , 'Migrált Mandatory Addon Offer DWH-ban kalkulált Main Offer alapján');

INSERT INTO M_OFFER_MIGR_RSN VALUES ( 16, 'Y', 'Migrált Mandatory Addon - SOC kombináció szerinti Main Offer eset'
                                                     , 'Migrált Mandatory Addon Offer SOC kombináció szerinti Main Offer alapján');

INSERT INTO M_OFFER_MIGR_RSN VALUES (101, 'N', 'Hiányzó Offer Id2Id mapping'
                                                     , 'Hiányzik az Offer szintü mapping információ a {WORK_TB}M_IDID_OFFER_MOD" mapping táblából');

INSERT INTO M_OFFER_MIGR_RSN VALUES (102, 'N', 'Hiányzó Main Offer'
                                                     , 'Hiányzik a Sub_Id-hez tartozó Main Offer mind a DWH, mind a PanDocs SOC kombináció mappingböl.');

INSERT INTO M_OFFER_MIGR_RSN VALUES (103, 'N', 'Duplikált Offer - DWH / Addon mapping'
                                                     , 'Target Offer duplikáció: DWH kalkuláció és SOC kombináció is ugyanazt az Addon Offert eredményezi.');

INSERT INTO M_OFFER_MIGR_RSN VALUES (104, 'N', 'Duplikált Offer - Addon / Addon mapping'
                                                     , 'Target Offer duplikáció: különbözö SOC kombinációk ugyanazt az Addon Offert eredményezik.');

INSERT INTO M_OFFER_MIGR_RSN VALUES (105, 'N', 'Hivatkozott Main Offer kiszürve'
                                                     , 'A mandatory Addon által Hivatkozott Main Offer ki lett szürve, nem migráljuk.');
-- NGy 08.03
INSERT INTO M_OFFER_MIGR_RSN VALUES (106, 'S', 'Spec. Addon eldobása HYB'
                                                     , 'A3ONNET, ACUGFAMM, ACUGFAMMPI Addon eldobása HYBrid ügyfél esetén');
-- NGy 08.17
INSERT INTO M_OFFER_MIGR_RSN VALUES (107, 'S', 'Spec11 Addon eldobasa B2B'
                                                     , 'ha A5PU0% maszott fel B2B main offerre, azt toroljuk');
-- MT. 2016-08-29
INSERT INTO M_OFFER_MIGR_RSN VALUES (108, 'N', 'Duplikált Offer - DWH / eltero addon eldobas'
                                                     , 'Target Offer duplikáció: DWH kalkuláció és SOC kombináció eltero Addon Offert eredményez. Minden felsorolt addont el kell dobni DWH-s CTN eseten.');

-- Ez a 4 update csak akkor fusson, ha a szkript magaban fut (a korabbi lepesek mar kinullazzak a mezoket)
/*													 
UPDATE  M_OFFER_M00_DWH
SET     Migr_Offer_Ind = NULL
,       Migr_SOC_Ind   = NULL
,       Migr_Rsn_Cd    = NULL
;

UPDATE  M_OFFER_M01_TARIFF
SET     Migr_Offer_Ind = NULL
,       Migr_SOC_Ind   = NULL
,       Migr_Rsn_Cd    = NULL
;

UPDATE  M_OFFER_M02_ADDON
SET     Migr_Offer_Ind = NULL
,       Migr_SOC_Ind   = NULL
,       Migr_Rsn_Cd    = NULL
-- ---
,       Mand_Addon_Ind = 'N'
;

UPDATE  M_OFFER_M03_MAND_ADDON
SET     Migr_Offer_Ind = NULL
,       Migr_SOC_Ind   = NULL
,       Migr_Rsn_Cd    = NULL
;
*/
-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ------<###>--
-- <Type>  : UPDATE
-- <Table> : M_OFFER_M01_TARIFF
-- <Brief> : Munka tábla karbantartása
-- <Desc>  : Elöször megállapítjuk a Tariff mapping tábla rekordjai kezelési módját:
--             1. Hibaeset: Hiányzik az Id2Id mapping.
--             2. Map eset: DWH kalkulációban meglévõ Sub_Id-hez (B2B) tartozó Main Offer
--                azon esteben, ha a DWH-ban nincs Main Offer a Sub_Id-hez,
--                azonban a SOC lapú Tarifa mappingben szerepel (pl. 1:1 mapping által).
--             3. Map eset: DWH-ban nem létezõ Sub_Id-hez (B2C) tartozó Main Offer.
-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----</###>--


select concat('begin update M00,M01,M02: ', now());

-- MT: Gyorsitas
drop table if exists M_OFFER_M01_TARIFF_SUB_ID;
create table M_OFFER_M01_TARIFF_SUB_ID as
SELECT DISTINCT Sub_Id FROM M_OFFER_M01_TARIFF WHERE Migr_Offer_Ind = 'Y'; -- Src_SOC_Seq_No
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M01_TARIFF_SUB_ID','Sub_Id');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M00_DWH_SUB_ID','Sub_Id');





-- ----- ---
--  1. Hibaeset: Hiányzik az Id2Id mapping.
-- ----- ---

/*
UPDATE  M_OFFER_M01_TARIFF
SET     Migr_Offer_Ind = 'N'
,       Migr_SOC_Ind   = 'N'
,       Migr_Rsn_Cd    = 101
WHERE   Migr_Rsn_Cd IS NULL
AND     Id2Id_Rec_Id IS NULL
;

-- ----- ---
--  2. Map eset: DWH-ban meglévõ Sub_Id-hez (B2B) tartozó Main Offer, hiányzó DWH main Offer esetén.
-- ----- ---
UPDATE  M_OFFER_M01_TARIFF
SET     Migr_Offer_Ind = (CASE WHEN (Src_Price_Plan_Seq_No =  Src_SOC_Seq_No) THEN 'Y' ELSE 'N' END)
,       Migr_SOC_Ind   = (CASE WHEN (Src_SOC_Seq_No        IS NOT NULL      ) THEN 'Y' ELSE 'N' END)
,       Migr_Rsn_Cd    = 12
WHERE   Migr_Rsn_Cd IS NULL
AND     Sub_Id IN (SELECT Sub_Id FROM M_OFFER_M00_DWH_SUB_ID WHERE Main_Offer_Ind = 'N')
;

-- ----- ---
--  3. Map eset: DWH-ban nem létezõ Sub_Id-hez (B2C) tartozó Main Offer.
-- ----- ---
UPDATE  M_OFFER_M01_TARIFF
SET     Migr_Offer_Ind = (CASE WHEN (Src_Price_Plan_Seq_No =  Src_SOC_Seq_No) THEN 'Y' ELSE 'N' END)
,       Migr_SOC_Ind   = (CASE WHEN (Src_SOC_Seq_No        IS NOT NULL      ) THEN 'Y' ELSE 'N' END)
,       Migr_Rsn_Cd    = 13
WHERE   Migr_Rsn_Cd IS NULL
AND     Sub_Id NOT IN (SELECT Sub_Id FROM M_OFFER_M00_DWH_SUB_ID)
;
*/


-- ----- ---
--  MT: A fenti map esetek egyetlen futasba atirva, jobban indexelve (hogy gyorsabb legyen)
-- ----- ---

UPDATE  M_OFFER_M01_TARIFF  O
left outer join M_OFFER_M00_DWH_SUB_ID S on O.Sub_Id=S.Sub_Id
SET
  O.Migr_Offer_Ind =
    case
    when O.Id2Id_Rec_Id IS NULL then 'N'
    when S.Main_Offer_Ind = 'N'
      or S.Main_Offer_Ind is null then
      (CASE WHEN (O.Src_SOC_Seq_No = O.Src_Price_Plan_Seq_No) THEN 'Y' ELSE 'N' END)
    end
, O.Migr_SOC_Ind =
    case
    when O.Id2Id_Rec_Id IS NULL then 'N'
    when S.Main_Offer_Ind = 'N'
      or S.Main_Offer_Ind is null then
      (CASE WHEN (O.Src_SOC_Seq_No is null) THEN 'Y' ELSE 'N' END)
    end
, O.Migr_Rsn_Cd =
    case
    when O.Id2Id_Rec_Id IS NULL then 101
    when S.Main_Offer_Ind = 'N' then 12
    when S.Main_Offer_Ind is null then 13
    end
WHERE O.Migr_Rsn_Cd IS NULL
  and (
      -- 1. Hibaeset: Hiányzik az Id2Id mapping:
         O.Id2Id_Rec_Id IS NULL
      -- 2. Map eset: DWH-ban meglévõ Sub_Id-hez (B2B) tartozó Main Offer, hiányzó DWH main Offer esetén:
      or S.Main_Offer_Ind = 'N'
      -- 3. Map eset: DWH-ban nem létezõ Sub_Id-hez (B2C) tartozó Main Offer:
      or S.Main_Offer_Ind is null
      )
;
select concat('End UPDATE M_OFFER_M01_TARIFF: ', now(), ', affected rows:', ROW_COUNT());





-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ------<###>--
-- <Type>  : UPDATE
-- <Table> : M_OFFER_M00_DWH
-- <Brief> : Munka tábla karbantartása
-- <Desc>  : Másodszor megállapítjuk a DWH mapping tábla rekordjai kezelési módját:
--             1. Hibaeset: Hiányzik az Id2Id mapping.
--             2. Map eset: DWH Offer (B2B), ahol a Sub_Id-n megvan a DWH-ban a Main_Offer is.
--             3. Map eset: DWH Offer (B2B), ahol a Sub_Id-n nincs meg a DWH-ban a Main_Offer,
--                          de a PanDocs alapján megvan.
--             4. Hibaeset: Hiányzik a Main Offer mind a DWH, mind a PanDocs mappingböl.
-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----</###>--


/*
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M00_DWH','Migr_Rsn_Cd,Main_Offer_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M00_DWH','Migr_Rsn_Cd,Sub_Id');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M00_DWH','Migr_Rsn_Cd,Tgt_Offer_Id');

-- ----- ---
--  1. Hibaeset: Hiányzik az Id2Id mapping.
-- ----- ---

UPDATE  M_OFFER_M00_DWH
SET     Migr_Offer_Ind = 'N'
,       Migr_SOC_Ind   = 'N'
,       Migr_Rsn_Cd    = 101
WHERE   Migr_Rsn_Cd IS NULL
AND     Tgt_Offer_Id IS NULL
;

-- ----- ---
--  2. Map eset: DWH Offer (B2B), ahol a Sub_Id-n megvan a DWH-ban a Main_Offer is.
-- ----- ---
UPDATE  M_OFFER_M00_DWH
SET     Migr_Offer_Ind = 'Y'
,       Migr_SOC_Ind   = (CASE WHEN (Src_SOC_Seq_No IS NOT NULL) THEN 'Y' ELSE 'N' END)
,       Migr_Rsn_Cd    = 11
WHERE   Migr_Rsn_Cd IS NULL
AND     Main_Offer_Cd IS NOT NULL
;

-- ----- ---
--  3. Map eset: DWH Offer (B2B), ahol a Sub_Id-n nincs meg a DWH-ban a Main_Offer, de a PanDocs alapján megvan.
-- ----- ---
UPDATE  M_OFFER_M00_DWH
SET     Migr_Offer_Ind = 'Y'
,       Migr_SOC_Ind   = 'N'    --  Src_SOC_Seq_No csak 'PP' azaz Main Offer esetében van JOIN-olva a DWH-s konverzióban
,       Migr_Rsn_Cd    = 12
WHERE   Migr_Rsn_Cd IS NULL
AND     Sub_Id IN (SELECT DISTINCT Sub_Id FROM M_OFFER_M01_TARIFF WHERE Migr_Offer_Ind = 'Y')
;

-- ----- ---
--  4. Hibaeset: Hiányzik a Main Offer mind a DWH, mind a PanDocs mappingböl.
-- ----- ---
UPDATE  M_OFFER_M00_DWH
SET     Migr_Offer_Ind = 'N'
,       Migr_SOC_Ind   = 'N'
,       Migr_Rsn_Cd    = 102
WHERE   Migr_Rsn_Cd IS NULL
AND     Sub_Id NOT IN (SELECT          Sub_Id FROM M_OFFER_M00_DWH_SUB_ID WHERE Main_Offer_Ind = 'Y')
AND     Sub_Id NOT IN (SELECT DISTINCT Sub_Id FROM M_OFFER_M01_TARIFF     WHERE Migr_Offer_Ind = 'Y')
;


*/



-- ----- ---
--  MT: A fenti map esetek egyetlen futasba atirva, jobban indexelve (hogy gyorsabb legyen)
-- ----- ---

UPDATE  M_OFFER_M00_DWH  O
left outer join M_OFFER_M00_DWH_SUB_ID S on O.Sub_Id=S.Sub_Id and Main_Offer_Ind = 'Y'
left outer join M_OFFER_M01_TARIFF_SUB_ID TS on O.Sub_Id=TS.Sub_Id
SET
  O.Migr_Offer_Ind =
    case
    when Tgt_Offer_Id IS NULL then 'N'
    when Main_Offer_Cd IS NOT NULL then 'Y'
    when TS.Sub_Id is not null then 'Y'
    when (S.Sub_Id is null and TS.Sub_Id is null) then 'N'
    end
, O.Migr_SOC_Ind =
    case
    when Tgt_Offer_Id IS NULL then 'N'
    when Main_Offer_Cd IS NOT NULL then
        CASE WHEN (Src_SOC_Seq_No IS NOT NULL) THEN 'Y' ELSE 'N' END
    when TS.Sub_Id is not null then 'N'
    when (S.Sub_Id is null and TS.Sub_Id is null) then 'N'
    end
, Migr_Rsn_Cd =
    case
    when Tgt_Offer_Id IS NULL then 101
    when Main_Offer_Cd IS NOT NULL then 11
    when TS.Sub_Id is not null then 12
    when (S.Sub_Id is null and TS.Sub_Id is null) then 102
    end
WHERE Migr_Rsn_Cd IS NULL
  and (
-- 1. Hibaeset: Hiányzik az Id2Id mapping:
         Tgt_Offer_Id IS NULL
--  2. Map eset: DWH Offer (B2B), ahol a Sub_Id-n megvan a DWH-ban a Main_Offer is.
      or Main_Offer_Cd IS NOT NULL
--  3. Map eset: DWH Offer (B2B), ahol a Sub_Id-n nincs meg a DWH-ban a Main_Offer, de a PanDocs alapján megvan.
      or TS.Sub_Id is not null
--  4. Hibaeset: Hiányzik a Main Offer mind a DWH, mind a PanDocs mappingböl.
      or (S.Sub_Id is null and TS.Sub_Id is null)
      )
;

select concat('End UPDATE M_OFFER_M00_DWH: ', now(), ', affected rows:', ROW_COUNT());



-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ------<###>--
-- <Type>  : UPDATE
-- <Table> : M_OFFER_M02_ADDON
-- <Brief> : Munka tábla karbantartása
-- <Desc>  : Végül megállapítjuk az Addon mapping tábla rekordjai kezelési módját:
--             1. Hibaeset: Hiányzik az Id2Id mapping.
--             2. Map eset: PanDocs Addon (B2B), ahol a Sub_Id megvan a DWH-ban a Main_Offer is.
--             3. Map eset: PanDocs Addon (B2B), ahol a Sub_Id-n nincs meg a DWH-ban a Main_Offer
--                          (de a PanDocs alapján megvan).
--             4. Map eset: PanDocs Addon (B2C).
--             5. Hibaeset: Target Offer duplikéció
--                          (különbözö SOC kombinációk ugyanazt az Offert eredményezik).
--                          ( Elsödlegesen azt az Offer Mapping-et tartjuk meg, amelyik több
--                            elemü SOC kombinációból származik. )
-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----</###>--

/*
-- ----- ---
--  1. Hibaeset: Hiányzik az Id2Id mapping.
-- ----- ---
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M02_ADDON','Migr_Rsn_Cd,Sub_Id');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M02_ADDON','Migr_Rsn_Cd,Id2Id_Rec_Id');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M02_ADDON','Migr_Offer_Ind');

UPDATE  M_OFFER_M02_ADDON
SET     Migr_Offer_Ind = 'N'
,       Migr_SOC_Ind   = 'N'
,       Migr_Rsn_Cd    = 101
WHERE   Migr_Rsn_Cd IS NULL
AND     Id2Id_Rec_Id IS NULL
;

-- ----- ---
--  2. Map eset: PanDocs Addon (B2B), ahol a Sub_Id-n megvan a DWH-ban a Main_Offer is.
-- ----- ---
UPDATE  M_OFFER_M02_ADDON
SET     Migr_Offer_Ind = (CASE WHEN (First_SOC_Seq_No =  Src_SOC_Seq_No) THEN 'Y' ELSE 'N' END)
,       Migr_SOC_Ind   = (CASE WHEN (Src_SOC_Seq_No   IS NOT NULL      ) THEN 'Y' ELSE 'N' END)
,       Migr_Rsn_Cd    = 11
WHERE   Migr_Rsn_Cd IS NULL
AND     Sub_Id IN (SELECT Sub_Id FROM M_OFFER_M00_DWH_SUB_ID WHERE Main_Offer_Ind = 'Y')
;

-- ----- ---
--  3. Map eset: PanDocs Addon (B2B), ahol a Sub_Id-n nincs meg a DWH-ban a Main_Offer (de a PanDocs alapján megvan).
-- ----- ---
UPDATE  M_OFFER_M02_ADDON
SET     Migr_Offer_Ind = (CASE WHEN (First_SOC_Seq_No =  Src_SOC_Seq_No) THEN 'Y' ELSE 'N' END)
,       Migr_SOC_Ind   = (CASE WHEN (Src_SOC_Seq_No   IS NOT NULL      ) THEN 'Y' ELSE 'N' END)
,       Migr_Rsn_Cd    = 12
WHERE   Migr_Rsn_Cd IS NULL
AND     Sub_Id IN (SELECT          Sub_Id FROM M_OFFER_M00_DWH_SUB_ID WHERE Main_Offer_Ind = 'N')
AND     Sub_Id IN (SELECT DISTINCT Sub_Id FROM M_OFFER_M01_TARIFF     WHERE Migr_Offer_Ind = 'Y')
;

-- ----- ---
--  4. Map eset: PanDocs Addon (B2C).
--               (Addon-t csak olyan esetben mappelünk, amikor valamilyen módon megvan a Main Offer is.)
-- ----- ---
UPDATE  M_OFFER_M02_ADDON
SET     Migr_Offer_Ind = (CASE WHEN (First_SOC_Seq_No =  Src_SOC_Seq_No) THEN 'Y' ELSE 'N' END)
,       Migr_SOC_Ind   = (CASE WHEN (Src_SOC_Seq_No   IS NOT NULL      ) THEN 'Y' ELSE 'N' END)
,       Migr_Rsn_Cd    = 13
WHERE   Migr_Rsn_Cd IS NULL
AND     Sub_Id NOT IN (SELECT Sub_Id FROM M_OFFER_M00_DWH_SUB_ID)
;

*/


-- ----- ---
--  MT: A fenti esetek egyetlen futasba atirva, jobban indexelve (hogy gyorsabb legyen)
-- ----- ---

UPDATE  M_OFFER_M02_ADDON  O
left outer join M_OFFER_M00_DWH_SUB_ID S on O.Sub_Id=S.Sub_Id
left outer join M_OFFER_M01_TARIFF_SUB_ID TS on O.Sub_Id=TS.Sub_Id
SET
  O.Migr_Offer_Ind =
    case
    when Id2Id_Rec_Id IS NULL then 'N'
    when S.Main_Offer_Ind = 'Y' then (CASE WHEN (First_SOC_Seq_No =  Src_SOC_Seq_No) THEN 'Y' ELSE 'N' END)
    when (Main_Offer_Ind = 'N' and TS.Sub_Id is not null) then
      (CASE WHEN (First_SOC_Seq_No =  Src_SOC_Seq_No) THEN 'Y' ELSE 'N' END)
    when S.Sub_Id is null then (CASE WHEN (First_SOC_Seq_No =  Src_SOC_Seq_No) THEN 'Y' ELSE 'N' END)
    end
, O.Migr_SOC_Ind =
    case
    when Id2Id_Rec_Id IS NULL then 'N'
    when S.Main_Offer_Ind = 'Y' then (CASE WHEN (Src_SOC_Seq_No   IS NOT NULL      ) THEN 'Y' ELSE 'N' END)
    when (Main_Offer_Ind = 'N' and TS.Sub_Id is not null) then
      (CASE WHEN (Src_SOC_Seq_No   IS NOT NULL      ) THEN 'Y' ELSE 'N' END)
    when S.Sub_Id is null then (CASE WHEN (Src_SOC_Seq_No   IS NOT NULL      ) THEN 'Y' ELSE 'N' END)
    end
, Migr_Rsn_Cd =
    case
    when Id2Id_Rec_Id IS NULL then 101
    when S.Main_Offer_Ind = 'Y' then 11
    when (Main_Offer_Ind = 'N' and TS.Sub_Id is not null) then 12
    when S.Sub_Id is null then 13
    end
WHERE Migr_Rsn_Cd IS NULL
  and (
-- 1. Hibaeset: Hiányzik az Id2Id mapping:
         Id2Id_Rec_Id IS NULL
--  2. Map eset: PanDocs Addon (B2B), ahol a Sub_Id-n megvan a DWH-ban a Main_Offer is.
      or S.Main_Offer_Ind = 'Y'
--  3. Map eset: PanDocs Addon (B2B), ahol a Sub_Id-n nincs meg a DWH-ban a Main_Offer (de a PanDocs alapján megvan).
      or (Main_Offer_Ind = 'N' and TS.Sub_Id is not null)
--  4. Map eset: PanDocs Addon (B2C).
--               (Addon-t csak olyan esetben mappelünk, amikor valamilyen módon megvan a Main Offer is.)
      or S.Sub_Id is null
      )
;

select concat('End UPDATE M_OFFER_M02_ADDON: ', now(), ', affected rows:', ROW_COUNT());


-- ----- ---
--  5. Hibaeset: Target Offer duplikáció (különbözö SOC kombinációk ugyanazt az Offert eredményezik).
-- ----- ---
UPDATE  M_OFFER_M02_ADDON   AS  ADDON_BASE
join (
  select Sub_Id,Tgt_Offer_Cd,Src_Combo_Id,Src_Combo_Rank
  from (
    select x.*
      ,case when @p=concat(lpad(Sub_Id,28,'0'),Tgt_Offer_Cd) then @i:=@i+1 else @i:=1 end Src_Combo_Rank
      ,@p:=concat(lpad(Sub_Id,28,'0'),Tgt_Offer_Cd) part
    from (
      SELECT  Sub_Id, Tgt_Offer_Cd, Src_Combo_Id
      FROM    M_OFFER_M02_ADDON
      WHERE   Migr_Offer_Ind = 'Y'
      OR      (Migr_Rsn_Cd = 104 AND First_SOC_Seq_No = Src_SOC_Seq_No)
      order by Sub_Id, Tgt_Offer_Cd,Src_Combo_Cnt DESC, Src_Combo_Id  ASC
      ) x,
      (select @i:=0,@p:='-') i
    ) x
    where Src_Combo_Rank>1
  ) AS  ADDON_RANK
  on ADDON_BASE.Sub_Id       = ADDON_RANK.Sub_Id
  AND     ADDON_BASE.Tgt_Offer_Cd = ADDON_RANK.Tgt_Offer_Cd
  AND     ADDON_BASE.Src_Combo_Id = ADDON_RANK.Src_Combo_Id
SET
    Migr_Offer_Ind = 'N'
,   Migr_SOC_Ind   = 'N'
,   Migr_Rsn_Cd    = 104
;

select concat('End UPDATE M_OFFER_M02_ADDON 2: ', now(), ', affected rows:', ROW_COUNT());


-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ------<###>--
-- <Type>  : UPDATE
-- <Table> : M_OFFER_M00_DWH
-- <Brief> : Munka tábla karbantartása
-- <Desc>  : Cross-check ...
--             5. Map eset/
--                Hibaeset: Target Offer duplikéció
--                          (DWH-ból és Addon-ból is képzödik ugyanazt az Offer).
--                          Ebben az esetben a DWH-s rekordot kell megtartani a
--                          'Service_Attr_Value' érték megörzése miatt, viszont a mapping
--                          információk megõrzése érdekében a 'Src_SOC_Cd' és 'Src_SOC_Seq_No'
--                          információkat átmásoljuk a DWH-s mapping adaok mellé.
-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----</###>--

-- ----- ---
--  5. Map eset: Target Offer duplikáció (DWH-ból és Addon-ból is képzödik ugyanazt az Offer).
-- ----- ---
UPDATE  M_OFFER_M00_DWH     AS  DWH
,       M_OFFER_M02_ADDON   AS  ADN
SET     DWH.Src_SOC_Cd       = ADN.Src_SOC_Cd
,       DWH.Src_SOC_Seq_No   = ADN.Src_SOC_Seq_No
,       DWH.Src_Svc_Class_Cd = ADN.Src_Svc_Class_Cd
,       DWH.Migr_SOC_Ind   = (CASE WHEN (ADN.Src_SOC_Seq_No IS NOT NULL) THEN 'Y' ELSE 'N' END)
WHERE   DWH.Migr_Offer_Ind = 'Y'
AND     ADN.Migr_Offer_Ind = 'Y'
AND     ADN.Src_Combo_Cnt  = 1
AND     DWH.Sub_Id         = ADN.Sub_Id
AND     DWH.Tgt_Offer_Cd   = ADN.Tgt_Offer_Cd
;

select concat('End UPDATE Target Offer duplikáció: ', now(), ', affected rows:', ROW_COUNT());

-- ----- ---
--  5. Hibaeset: Target Offer duplikáció (DWH-ból és Addon-ból is képzödik ugyanazt az Offer).
-- ----- ---
UPDATE  M_OFFER_M00_DWH     AS  DWH
,       M_OFFER_M02_ADDON   AS  ADN
SET     DWH.Migr_Offer_Ind = 'N'
,       DWH.Migr_SOC_Ind   = 'N'
,       DWH.Migr_Rsn_Cd    = 103
WHERE   DWH.Migr_Offer_Ind = 'Y'
AND     ADN.Migr_Offer_Ind = 'Y'
AND     ADN.Src_Combo_Cnt  = 1
AND     DWH.Sub_Id         = ADN.Sub_Id
AND     DWH.Tgt_Offer_Cd   = ADN.Tgt_Offer_Cd
;
select concat('End UPDATE Target Offer duplikáció 2: ', now(), ', affected rows:', ROW_COUNT());



/*

MT. 2016-08-29: Duplazo offerek, eltero addon lekepezes eldobasa
Masik neve: Negotiated Price
A DWH-bol jon egy sor elokeszitett offer. Maskepp kepezodnek le, mint a SOC-bol eloallo offerek. Az az uzlet kerese, hogy adott SOC offereket toroljunk le minden olyan CTN-rol, akik DWH-bol barmilyen offert kapnak.

1. Megjeloljuk a USER sorokon, hogy kap-e DWH-bol offert.
2. Ha igen akkor egy listaban levo offer sorokat letiltjuk az addon tablabol, [kiveve, ha mandatory] <- ez nem biztos.

*/


create temporary table DWH_USERS as
select distinct CTN from M_OFFER_M00_DWH;

create index i_DWH_USERS on DWH_USERS (CTN);

update M_OFFER_M02_ADDON A
  join DWH_USERS U on U.CTN = A.CTN
set
  A.Migr_Offer_Ind = 'N',
  A.Migr_SOC_Ind   = 'N',
  A.Migr_Rsn_Cd    = 108
where 1=1 -- itt kene kizarni a mandatory addonokat
  and A.tgt_offer_cd in (
  'HKEDV400', 'HKEDV1000', 'HKEDV1900', 'HKEDV600', 'HKEDV3000', 'HKEDV100',
  'HKEDV900', 'HKEDV1100', 'HKEDV800', 'HKEDV1700', 'HKEDV3300', 'HKEDV700',
  'HKEDV1200', 'HKEDV2100', 'HKEDV2700', 'HKEDV200', 'HKEDV300', 'HKEDV1500',
  'HKEDV1800', 'HKEDV1600', 'HKEDV2200', 'HKEDV500', 'HKEDV2000', 'HKEDV2500',
  'HKEDV1300', 'SMS21', 'SMS22', 'SMS18', 'SMS20', 'SMS25', 'SMS29', 'SMS19',
  'SMS27', 'SMS14', 'SMS125', 'UCON30DSC', 'VEZ18', 'INT1310', 'INT1320',
  'INT1330', 'INT1615', 'INT4610', 'INT4620', 'INT1610-ROHD500_1',
  'INT1610-ROHD500_2', 'INT1610-ROHD500_3', 'RK10ZON1-ROHD500_1',
  'RK10ZON1-ROHD500_2', 'RK10ZON1-ROHD500_3', 'RK10ZON23-ROHD500_1',
  'RK10ZON23-ROHD500_2', 'RK10ZON23-ROHD500_3', 'MID100', 'TAXHD300',
  'TAXHD400', 'TAXHD600', 'TAXHD800', 'TAXHD800+HKEDV800', 'TAXHD100',
  'TAXHD1100', 'TAXHD1200', 'TAXHD1300', 'TAXHD1400', 'TAXHD1800', 'TAXHD200',
  'TAXHD2300', 'TAXHD2600', 'TAXHD700', 'TAXHD800', 'TAXHD900', 'TAXHD300',
  'TAXHD400', 'TAXHD600', 'TAXHD800', 'TAXHD800+HKEDV800', 'TAXHD100', 'TAXHD1000',
  'TAXHD1100', 'TAXHD1200', 'TAXHD1400', 'TAXHD200', 'TAXHD228', 'TAXHD290',
  'TAXHD300', 'TAXHD400', 'TAXHD450', 'TAXHD500', 'TAXHD600', 'TAXHD700',
  'TAXHD800', 'TAXHD900', 'TAXHD990', 'MEXHD300', 'MEXHD400', 'MEXHD500',
  'MEXHD1000', 'MEXHD200', 'MEXHD600', 'MEXHD700', 'MEXHD800', 'MEXHD900',
  'MEXHD1200', 'MEXHD1700', '40FREESMS', 'KVK300'
);

drop table DWH_USERS;





-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ------<###>--
-- <Type>  : UPDATE
-- <Table> : M_OFFER_M03_MAND_ADDON
-- <Brief> : Munka tábla karbantartása
-- <Desc>  : mandatory Addon rekordok kezelési módja:
--             1. Hibaeset: Hiányzik az Id2Id mapping.
--             2. Hibaeset: Hivatkozott Main Offer kiszürve.
--             3. Map eset: A többi Mandatory Addon mind migrálandó.
--                            - Az Addon Offer CSAK akkor képzödik, ha a PanDocs SOC létezett.
--                            - A Mandatory Addon képzésnél átvesszük az Addon SOC információt.
--                          Ezért a Mandatory Addont csak akkor kell migrálni külön, ha nem
--                          találunk hivatkozott PanDocs SOC-ot, hiszen ebben az esetben már az
--                          Addon mapping alapján migráltuk ezen rekordokat.
-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----</###>--

-- ----- ---
--  1. Hibaeset: Hiányzik az Id2Id mapping.
-- ----- ---
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M03_MAND_ADDON','Migr_Rsn_Cd');

UPDATE  M_OFFER_M03_MAND_ADDON
SET     Migr_Offer_Ind = 'N'
,       Migr_SOC_Ind   = 'N'
,       Migr_Rsn_Cd    = 101
WHERE   Migr_Rsn_Cd IS NULL
AND     Id2Id_Rec_Id IS NULL
;
select concat('End UPDATE M_OFFER_M03_MAND_ADDON: ', now(), ', affected rows:', ROW_COUNT());


-- ----- ---
--  2. Hibaeset: Hivatkozott Main Offer kiszürve.
-- ----- ---
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M01_TARIFF','Src_SOC_Seq_No,Migr_Offer_Ind');
-- Ez mar igy letezo index. Ha bele tennem a Migr_Offer_Ind oslopot, akkor 3 percet is elvesz az eletunkbol:
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M00_DWH','Main_Offer_Inst_Id');

UPDATE  M_OFFER_M03_MAND_ADDON  O
left outer join M_OFFER_M01_TARIFF T on T.Src_SOC_Seq_No=O.Main_Offer_Inst_Id and T.Migr_Offer_Ind = 'Y'
left outer join M_OFFER_M00_DWH    D on D.Main_Offer_Inst_Id=O.Main_Offer_Inst_Id and D.Migr_Offer_Ind = 'Y'
SET     O.Migr_Offer_Ind = 'N'
,       O.Migr_SOC_Ind   = 'N'
,       O.Migr_Rsn_Cd    = 105
WHERE O.Migr_Rsn_Cd IS NULL
  and T.Src_SOC_Seq_No is null
  and D.Main_Offer_Inst_Id is null
  and not (O.Migr_Offer_Ind, O.Migr_SOC_Ind, O.Migr_Rsn_Cd) = ('N','N',105)
;
select concat('End UPDATE M_OFFER_M03_MAND_ADDON 2: ', now(), ', affected rows:', ROW_COUNT());


-- ----- ---
--  3. Map eset: A többi Mandatory Addon mind migrálandó.
--               Migr_Offer_Ind -> Ha már migráltuk ezt normál Addon-ként, akkor nem kell mégegyszer innen migrálni.
--               Migr_SOC_Ind   -> Ha már migráltuk ezt normál Addon-ként, akkor ott a SOC-ot is bejelöltük már.
--                                 Ha nem migráltuk normál addonként, akkor nem volt SOC alapú azonosítás sem, azaz a 'Src_SOC_Seq_No' biztos üres.
--               Migr_Rsn_Cd    -> Megjelöljük, hogy DWH-ból vagy Tariff migrációból triggereltük a Mandatory Addon-t.
-- ----- ---
UPDATE  M_OFFER_M03_MAND_ADDON
SET     Migr_Offer_Ind = (CASE WHEN (Addon_Ind = 'Y') THEN 'N' ELSE 'Y' END)
,       Migr_SOC_Ind   = 'N'
,       Migr_Rsn_Cd    = (CASE Map_Src WHEN 'DWH' THEN 15 WHEN 'TAR' THEN 16 END)
WHERE   Migr_Rsn_Cd IS NULL
;
select concat('End UPDATE M_OFFER_M03_MAND_ADDON 3: ', now(), ', affected rows:', ROW_COUNT());



-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ------<###>--
-- <Type>  : UPDATE
-- <Table> : M_OFFER_M02_ADDON
-- <Brief> : Munka tábla karbantartása
-- <Desc>  : Cross-check ...
--             6. Map eset: Mandatory Addon Flag beállítása.
-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----</###>--

-- ----- ---
--  6. Map eset: Mandatory Addon Flag beállítása.
-- ----- ---
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M02_ADDON','Src_SOC_Seq_No');

/*
UPDATE  M_OFFER_M02_ADDON M02
inner join (
select A.Src_SOC_Seq_No from M_OFFER_M03_MAND_ADDON A where A.Migr_Rsn_Cd = 15
union all
select B.Src_SOC_Seq_No from M_OFFER_M03_MAND_ADDON B where B.Migr_Rsn_Cd = 16 ) M
on M.Src_SOC_Seq_No = M02.Src_SOC_Seq_No
SET  Mand_Addon_Ind = 'Y'
;*/

UPDATE  M_OFFER_M02_ADDON M02
inner join M_OFFER_M03_MAND_ADDON M03
on M02.Src_SOC_Seq_No = M03.Src_SOC_Seq_No
AND   M03.Migr_Rsn_Cd IN (15,16)
SET  Mand_Addon_Ind = 'Y'
;
select concat('End UPDATE MAND_ADDON FLAG: ', now(), ', affected rows:', ROW_COUNT());


/* NGy 08.03	2 specialis eset
*	3bar⵩ 20-as + extra net					
*	Offer code:	A3ONNET				
*	Hybrid ctn-en nem maradhat fent a szolg⭴atⳬ a soc-jait migr⤩󫯲 elvesz, 고nem kaphatja meg a Veris-es add-on-t
*						
*	K⳴yⳠCsal⥩ Csomag Mini					
*	Offer code:	ACUGFAMM, ACUGFAMMPI				
*	Hybrid ctn-en nem maradhat fent a szolg⭴atⳬ a soc-jait migr⤩󫯲 elvesz, 고nem kaphatja meg a Veris-es add-on-t					
*/
-- ----- ---
--  speciális eset: HYB eseten kihagyni harom addon offert.
-- ----- ---
UPDATE  M_OFFER_M02_ADDON   AS  AO
SET  AO.Migr_Offer_Ind = 'N'
,    AO.Migr_SOC_Ind   = 'N'
,    AO.Migr_Rsn_Cd    = 106
where AO.tgt_offer_cd in ( 'A3ONNET', 'ACUGFAMM', 'ACUGFAMMPI')
  and AO.sub_type = 'HYB'
  and AO.Migr_Rsn_Cd < 100
  and AO.Migr_Offer_Ind = 'Y'
;
-- NGy 08.03 end


-- NGy 08.12
-- ----- ---
--  speciális eset: HYB eseten kihagyni haromfele addon offert.
-- ----- ---
UPDATE  M_OFFER_M00_DWH   AS  AO
SET AO.Migr_Offer_Ind = 'N'
,   AO.Migr_SOC_Ind   = 'N'
,   AO.Migr_Rsn_Cd    = 106
where AO.tgt_offer_cd in ( 'A3ONNET', 'ACUGFAMM', 'ACUGFAMMPI')
  and AO.sub_type = 'HYB'
  and AO.Migr_Rsn_Cd < 100
  and AO.Migr_Offer_Ind = 'Y'
;
-- ----- ---
--  speciális eset: HYB eseten kihagyni haromfele addon offert.
-- ----- ---
UPDATE  M_OFFER_M03_MAND_ADDON   AS  AO
SET AO.Migr_Offer_Ind = 'N'
,   AO.Migr_SOC_Ind   = 'N'
,   AO.Migr_Rsn_Cd    = 106
where AO.Mand_Addon_offer_cd in ( 'A3ONNET', 'ACUGFAMM', 'ACUGFAMMPI')
  and AO.sub_type = 'HYB'
  and AO.Migr_Rsn_Cd < 100
  and AO.Migr_Offer_Ind = 'Y'
;
-- NGy 08.12 end

select concat('End UPDATE HYB-deletion: ', now(), ', affected rows:', ROW_COUNT());


-- MT 08.29 spec eset 11	ha A5PU0% maszott fel B2B main offerre, azt toroljuk
UPDATE  M_OFFER_M02_ADDON   AS  AO
,       M_OFFER_M01_TARIFF  as T   
SET  AO.Migr_Offer_Ind = 'N'
,       AO.Migr_SOC_Ind   = 'N'
,       AO.Migr_Rsn_Cd    = 107
where AO.Tgt_Offer_Cd in ('A5PU0','A5PU0T','A5PU0PI','A5PU0P','A5PU0PT')
  and AO.sub_id = T.sub_id	
  and T.map_type = 'B2B'
  and T.Migr_Offer_Ind = 'Y'
  and AO.Migr_Rsn_Cd < 100
  and AO.Migr_Offer_Ind = 'Y'
;

UPDATE  M_OFFER_M02_ADDON   AS  AO
,       M_OFFER_M00_DWH  as T   
SET  AO.Migr_Offer_Ind = 'N'
,       AO.Migr_SOC_Ind   = 'N'
,       AO.Migr_Rsn_Cd    = 107
where AO.Tgt_Offer_Cd in ('A5PU0','A5PU0T','A5PU0PI','A5PU0P','A5PU0PT')
  and AO.sub_id = T.sub_id	
  -- and T.map_type = 'B2B'
  and T.tgt_offer_type = 'T'
  and T.Migr_Offer_Ind = 'Y'
  and AO.Migr_Rsn_Cd < 100
  and AO.Migr_Offer_Ind = 'Y'
;

-- NGy 08.17	spec eset 11	ha A5PU0% maszott fel B2B main offerre, azt toroljuk
UPDATE  M_OFFER_M03_MAND_ADDON   AS  AO
,       M_OFFER_M01_TARIFF  as T   
SET		AO.Migr_Offer_Ind = 'N'
,       AO.Migr_SOC_Ind   = 'N'
,       AO.Migr_Rsn_Cd    = 107
where AO.Mand_Addon_offer_cd in ('A5PU0','A5PU0T','A5PU0PI','A5PU0P','A5PU0PT')
  and AO.sub_id = T.sub_id	
  and T.map_type = 'B2B'
  and T.Migr_Offer_Ind = 'Y'
  and AO.Migr_Rsn_Cd < 100
  and AO.Migr_Offer_Ind = 'Y'
;

UPDATE  M_OFFER_M03_MAND_ADDON   AS  AO
,       M_OFFER_M00_DWH  as T   
SET		AO.Migr_Offer_Ind = 'N'
,       AO.Migr_SOC_Ind   = 'N'
,       AO.Migr_Rsn_Cd    = 107
where AO.Mand_Addon_offer_cd in ('A5PU0','A5PU0T','A5PU0PI','A5PU0P','A5PU0PT')
  and AO.sub_id = T.sub_id	
  -- and T.map_type = 'B2B'
  and T.tgt_offer_type = 'T'
  and T.Migr_Offer_Ind = 'Y'
  and AO.Migr_Rsn_Cd < 100
  and AO.Migr_Offer_Ind = 'Y'
;


select concat('End delete A5PU0%: ', now(), ', affected rows:', ROW_COUNT());


SET SQL_SAFE_UPDATES=1;
