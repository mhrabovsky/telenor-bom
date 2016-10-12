USE LEGACY;
-- 5310.
-- Futasido (3-as gep): 1h.
/*

Here, addon offers are mapped with offer-map and IDID-map tables.
This code also eliminates multi-match (split type) multiplication with Use_Flag and Main_Product_Flag.
For Split_Type=4 these flags should be revised to allow offer multiplication.

*/

call LEGACY.createindex_ifnotexists('LEGACY','M_SOC','SOC_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_SOC','Sub_Id');

call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_MAP','Tgt_Offer_Type,Src_SOC_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_MAP','Tgt_Offer_Cd');

select concat('Finished indexing: ', now(), ', affected rows:', ROW_COUNT());




/*
key                                  | key_len | ref                              | rows | Extra                              |
-------------------------------------+---------+----------------------------------+------+------------------------------------+
IDX_M_OFFER_MAP_3_6                  | 3       | const                            | 3504 | Using index condition              |
IDX_M_IDID_OFFER_MOD_5_12_25_15_9_14 | 302     | LEGACY_MT.OFFER_MAP.Tgt_Offer_Cd |    5 | Using where                        |
IDX_M_SOC_5                          | 27      | LEGACY_MT.OFFER_MAP.Src_SOC_Cd   | 3563 | Using index condition; Using where |
IDX_M_OFFER_M01_TARIFF_14_20         | 9       | LEGACY_MT.ADDON_SOC.SOC_Seq_No   |    1 | Using where; Using index           |
i_M_OFFER_M00_MAIN_SUB_ID            | 4       | LEGACY_MT.ADDON_SOC.Sub_Id       |    1 | Using index                        |
*/

DROP TABLE if exists M_OFFER_M02_ADDON;
DROP TABLE if exists M_OFFER_M02_DEL_COMBO;
DROP TABLE if exists M_OFFER_M02_DEL_ADDON;

call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M01_TARIFF','Src_SOC_Seq_No');


CREATE TABLE M_OFFER_M02_ADDON
AS
(
  SELECT
  -- ---
          ADDON_SOC.CA_Id             AS  CA_Id
  ,       ADDON_SOC.BAN               AS  BAN
  ,       ADDON_SOC.BEN               AS  BEN
  ,       ADDON_SOC.CTN               AS  CTN
  -- ---
  ,       ADDON_SOC.Sub_Id            AS  Sub_Id
  -- ---
  ,       ADDON_SOC.CA_Type_Cd        AS  CA_Type_Cd
  -- ---
  ,       OFFER_MAP.Tgt_Offer_Cd      AS  Tgt_Offer_Cd
  ,       OFFER_MAP.Tgt_Offer_Type    AS  Tgt_Offer_Type
  ,       OFFER_MAP.Src_Combo_Id      AS  Src_Combo_Id
  ,       OFFER_MAP.Src_Combo_Cnt     AS  Src_Combo_Cnt
  -- ---
  ,       cast(NULL as CHAR(9))       AS  First_SOC_Cd
  ,       cast(NULL as UNSIGNED)      AS  First_SOC_Seq_No
  -- ---
  ,       OFFER_MAP.Src_SOC_Cd        AS  Src_SOC_Cd
  ,       ADDON_SOC.SOC_Seq_No        AS  Src_SOC_Seq_No
  ,       OFFER_MAP.Src_Svc_Class_Cd  AS  Src_Svc_Class_Cd
  ,       OFFER_MAP.Src_SOC_Rank      AS  Src_SOC_Rank
  ,       OFFER_MAP.Src_SOC_Order_No  AS  Src_SOC_Order_No
  -- ---
  ,       OFFER_MAP.Map_Type          AS  Map_Type
  ,       ID2ID_MAP.Id2Id_Rec_Id      AS  Id2Id_Rec_Id
  -- ---
  ,       'N'                         AS  Mand_Addon_Ind
  -- ---
  ,       cast(NULL as CHAR(1))       AS  Migr_Offer_Ind
  ,       cast(NULL as CHAR(1))       AS  Migr_SOC_Ind
  ,       cast(NULL as unsigned)      AS  Migr_Rsn_Cd
  -- ---
  -- MT: A Split type 2 es 10 igenyli az alabbi adatokat: User.Sub_Type, map.VOICE_BILLING_INCREMENT
  ,       ADDON_SOC.Sub_Type
  ,       ADDON_SOC.SUBSCRIBER_REF
  ,       coalesce ( -- main offer vbi adatat vesszuk, esetleg az addonet
            M_OFFER_M00_MAIN_SUB_ID.VOICE_BILLING_INCREMENT,
            OFFER_MAP.VOICE_BILLING_INCREMENT
            )                         AS VOICE_BILLING_INCREMENT
  -- ---
  /*
  -- Ide mar be kellene dobni az alabbi adatokat, hogy kesobb ne join-oljunk IDID tablat:
  Tgt_Offer_Name varchar(1000),
  Tgt_Offer_Id   bigint,
  Split_Type     integer
  */
  FROM
              M_OFFER_M00_MAIN_SUB_ID         -- DWH vagy SOC tarifaval biro userek
  INNER JOIN  M_SOC             AS  ADDON_SOC
          ON  ADDON_SOC.Sub_Id            = M_OFFER_M00_MAIN_SUB_ID.Sub_Id
  INNER JOIN  M_OFFER_MAP       AS  OFFER_MAP
          ON  OFFER_MAP.Tgt_Offer_Type    = 'A'
          AND OFFER_MAP.Src_SOC_Cd        = ADDON_SOC.SOC_Cd
  LEFT  JOIN  M_IDID_OFFER_MOD  AS  ID2ID_MAP
          ON  OFFER_MAP.Tgt_Offer_Cd      = ID2ID_MAP.Tgt_Offer_Cd
          AND ID2ID_MAP.Use_Flag          = 'Y'
          AND ID2ID_MAP.Main_Product_Flag = 'Y'
  -- ---
  --  Azon SOC-ok kizarasa (lasd where), amiket még nem mappeltünk Main offer-hez:
  LEFT OUTER JOIN M_OFFER_M01_TARIFF          AS NOT_MAPPED_SOC
          ON  ADDON_SOC.SOC_Seq_No = NOT_MAPPED_SOC.Src_SOC_Seq_No
--          AND NOT_MAPPED_SOC.Src_SOC_Seq_No IS NOT NULL
  -- ----- ---
WHERE  ADDON_SOC.Svc_Class_Cd <> 'PP' -- PanDocs Price Plan-eket kizárjuk.
  and  ADDON_SOC.SOC_PART='M'         -- M_OFFER_MAP-ben lekepezett addonok particioja
-- ---
--  Azon SOC-ok kizarasa, amiket még nem mappeltünk Main offer-hez:
  AND   NOT_MAPPED_SOC.Src_SOC_Seq_No IS NULL  --  ez egy NOT IN
-- Az "Account Level" offerek kizarasa: mgy 2016.08.31 
and coalesce(ID2ID_MAP.TGT_OFFER_TYPE_DESC,'Account Level')<>'Account Level'
)
;

select concat('Finished addon mapping: ', now(), ', affected rows:', ROW_COUNT());



CREATE TABLE M_OFFER_M02_DEL_ADDON AS select * from M_OFFER_M02_ADDON where 1=2;

INSERT
INTO    M_OFFER_M02_DEL_ADDON
SELECT  *
FROM    M_OFFER_M02_ADDON
GROUP BY
        Sub_Id
,       Src_Combo_Id
HAVING
        COUNT(DISTINCT Src_SOC_Cd) <> MIN(Src_Combo_Cnt)
;

select concat('Finished del addon table: ', now(), ', affected rows:', ROW_COUNT());


call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M02_ADDON','Sub_Id,Src_Combo_Id');

DELETE M_OFFER_M02_ADDON
FROM    M_OFFER_M02_ADDON
join M_OFFER_M02_DEL_ADDON
  on M_OFFER_M02_ADDON.Sub_Id=M_OFFER_M02_DEL_ADDON.Sub_Id
  and M_OFFER_M02_ADDON.Src_Combo_Id=M_OFFER_M02_DEL_ADDON.Src_Combo_Id
;

select concat('Finished delete from del addon table: ', now(), ', affected rows:', ROW_COUNT());


INSERT
INTO    M_OFFER_M02_DEL_ADDON
SELECT  *
FROM    M_OFFER_M02_ADDON
GROUP BY
        Src_SOC_Seq_No
HAVING
       COUNT(*) > 1
   AND MIN(Src_Combo_Cnt) = 1
   AND MAX(Src_Combo_Cnt) > 1
;


select concat('Finished insert into del addon table: ', now(), ', affected rows:', ROW_COUNT());


DELETE M_OFFER_M02_ADDON
from M_OFFER_M02_ADDON
join M_OFFER_M02_DEL_ADDON
  on M_OFFER_M02_ADDON.Sub_Id=M_OFFER_M02_DEL_ADDON.Sub_Id
  and M_OFFER_M02_ADDON.Src_Combo_Id=M_OFFER_M02_DEL_ADDON.Src_Combo_Id
;

select concat('Finished delete 2 from del addon table: ', now(), ', affected rows:', ROW_COUNT());


CREATE TABLE M_OFFER_M02_DEL_COMBO
AS
(
select Sub_Id
    ,  Src_SOC_Seq_No
    ,  Src_Combo_Id
from (
  select 
    case when @p=m02.Src_SOC_Seq_No then @i:=@i+1 else @i:=1 end nr,
    m02.*
    ,@p:=m02.Src_SOC_Seq_No
  from M_OFFER_M02_ADDON m02
  join (SELECT  Src_SOC_Seq_No FROM M_OFFER_M02_ADDON GROUP BY Src_SOC_Seq_No HAVING  COUNT(*) > 1) x
  on m02.Src_SOC_Seq_No=x.Src_SOC_Seq_No
  join (select @i:=0,@p:=0) i on 1=1
  order by
    m02.Src_SOC_Seq_No,
    CASE m02.Map_Type
      WHEN 'B2B' THEN 1 -- B2B ügyfél esetében elsösorban B2B tarifát választunk
      WHEN 'SOH' THEN 2 --
      WHEN 'B2C' THEN 3 -- 
      ELSE 4
    END,
    m02.Src_Combo_Cnt DESC,
    m02.Src_Combo_Id  DESC
  ) x
where nr>1
)
;

select concat('Finished del combo table: ', now(), ', affected rows:', ROW_COUNT());


INSERT
INTO    M_OFFER_M02_DEL_ADDON
SELECT  *
FROM    M_OFFER_M02_ADDON
WHERE    (Sub_Id, Src_Combo_Id) IN (
  SELECT  Sub_Id, Src_Combo_Id
    FROM    M_OFFER_M02_DEL_COMBO
  )
;

select concat('Finished insert3 del addon table: ', now(), ', affected rows:', ROW_COUNT());


DELETE M_OFFER_M02_ADDON
FROM    M_OFFER_M02_ADDON
join M_OFFER_M02_DEL_COMBO
on M_OFFER_M02_ADDON.Sub_Id=M_OFFER_M02_DEL_COMBO.Sub_Id
and M_OFFER_M02_ADDON.Src_Combo_Id=M_OFFER_M02_DEL_COMBO.Src_Combo_Id
;

select concat('Finished delete M02 addon table: ', now(), ', affected rows:', ROW_COUNT());


UPDATE M_OFFER_M02_ADDON   AS  A
join (
  SELECT  Sub_Id
  ,       Src_Combo_Id
  ,       MIN(Src_SOC_Seq_No) AS  First_SOC_Seq_No
  FROM    M_OFFER_M02_ADDON
  GROUP BY
          Sub_Id
  ,       Src_Combo_Id
  )  F
ON  A.Sub_Id       = F.Sub_Id
AND A.Src_Combo_Id = F.Src_Combo_Id
SET
  A.First_SOC_Seq_No = F.First_SOC_Seq_No
;

select concat('Finished update addon table: ', now(), ', affected rows:', ROW_COUNT());


call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M02_ADDON','Sub_Id,Src_SOC_Seq_No');

UPDATE  M_OFFER_M02_ADDON   AS  A
join    M_OFFER_M02_ADDON   AS  F
  on   A.Sub_Id           = F.Sub_Id
  AND  A.First_SOC_Seq_No = F.Src_SOC_Seq_No
SET
       A.First_SOC_Cd = F.Src_SOC_Cd
;


select concat('Finished update2 addon table: ', now(), ', affected rows:', ROW_COUNT());

