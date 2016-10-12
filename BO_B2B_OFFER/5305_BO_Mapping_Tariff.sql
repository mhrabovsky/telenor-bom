-- USE LEGACY;

-- Futasido (.133-as gep): 16m
/*

Here, main offers are mapped with offer-map and IDID-map tables.
This code also eliminates multi-match (split type) multiplication with Use_Flag and Main_Product_Flag.

*/

-- NAS 10.04 beegetesek bovitese
SET @EFF_DT = CAST(LEGACY.CONFIG('DEF_EFF_DATE',NULL) AS DATETIME);
SET @EXP_DT = CAST(LEGACY.CONFIG('DEF_EXP_DATE',NULL) AS DATETIME);

call LEGACY.createindex_ifnotexists('LEGACY','M_IDID_OFFER_MOD','Tgt_Offer_Cd');

call LEGACY.createindex_ifnotexists('LEGACY','M_SOC','CTN,SOC_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M00_DWH_SUB_ID','Sub_Id,Main_Offer_Ind');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_MAP','Src_Price_Plan_Cd,Tgt_Offer_Type');

select concat('Finished indexing: ', now(), ', affected rows:', ROW_COUNT());


DROP TABLE if exists LEGACY.M_OFFER_M01_TARIFF;
DROP TABLE if exists LEGACY.M_OFFER_M01_DEL_COMBO;
DROP TABLE if exists LEGACY.M_OFFER_M01_DEL_TARIFF;

-- mgy 2016.09.14 bovites a tortenetiseghez

CREATE TABLE LEGACY.M_OFFER_M01_TARIFF AS
  SELECT
  -- ---
          PRICE_PLAN.CA_Id                AS  CA_Id
  ,       PRICE_PLAN.BAN                  AS  BAN
  ,       PRICE_PLAN.BEN                  AS  BEN
  ,       PRICE_PLAN.CTN                  AS  CTN
  -- ---
  ,       PRICE_PLAN.Sub_Id               AS  Sub_Id
  -- ---
  ,       PRICE_PLAN.CA_Type_Cd           AS  CA_Type_Cd
  -- ---
  , CASE
      WHEN PRICE_PLAN.Eff_Dt > @EXP_DT THEN @EFF_DT
      ELSE COALESCE(PRICE_PLAN.Eff_Dt,@EFF_DT)
      END            AS EFFECTIVE_DATE
  , CASE
      WHEN PRICE_PLAN.Exp_Dt > @EXP_DT THEN @EXP_DT
      ELSE COALESCE(PRICE_PLAN.Exp_Dt,@EXP_DT)
      END            AS EXPIRATION_DATE
  -- ---
  ,       OFFER_MAP.Tgt_Offer_Cd          AS  Tgt_Offer_Cd
  ,       OFFER_MAP.Tgt_Offer_Type        AS  Tgt_Offer_Type
  ,       OFFER_MAP.Src_Combo_Id          AS  Src_Combo_Id
  ,       OFFER_MAP.Src_Combo_Cnt         AS  Src_Combo_Cnt
  -- ---
  ,       PRICE_PLAN.SOC_Cd        AS  Src_Price_Plan_Cd
  ,       PRICE_PLAN.SOC_Seq_No    AS  Src_Price_Plan_Seq_No
  -- ---
  ,       OFFER_MAP.Src_SOC_Cd            AS  Src_SOC_Cd
  ,       SOC_XTR.SOC_Seq_No              AS  Src_SOC_Seq_No
  ,       OFFER_MAP.Src_Svc_Class_Cd      AS  Src_Svc_Class_Cd
  ,       OFFER_MAP.Src_SOC_Rank          AS  Src_SOC_Rank
  ,       OFFER_MAP.Src_SOC_Order_No      AS  Src_SOC_Order_No
  -- ---
  ,       OFFER_MAP.Map_Type              AS  Map_Type
  ,       ID2ID_MAP.Id2Id_Rec_Id          AS  Id2Id_Rec_Id
  -- ---
  ,       cast(NULL as CHAR(1))                  AS  Migr_Offer_Ind
  ,       cast(NULL as CHAR(1))                  AS  Migr_SOC_Ind
  ,       cast(NULL as unsigned)                 AS  Migr_Rsn_Cd
  -- ---
  -- MT: A Split type 2 es 10 igenyli az alabbi adatokat: User.Sub_Type, map.VOICE_BILLING_INCREMENT
  ,       PRICE_PLAN.Sub_Type
  ,       PRICE_PLAN.SUBSCRIBER_REF  -- NRPC migralasahoz
  ,       OFFER_MAP.VOICE_BILLING_INCREMENT
  -- ---
  /*
  -- Ide mar be kellene dobni az alabbi adatokat, hogy kesobb ne join-oljunk IDID tablat:
  Tgt_Offer_Name varchar(1000),
  Tgt_Offer_Id   bigint,
  Split_Type     integer
  */
  FROM
    -- ----- ---
    --  (1) Veszem az extract-bol az osszes PP-t. Ez elofizetore egyedi (1:1)
    -- ----- ---
        LEGACY.M_SOC PARTITION (pP) AS  PRICE_PLAN -- 'PP' sorok particioja. Elvileg a Svc_Class_Cd-ra nem kellene szurni.
    -- ----- ---
    --  (2) Az elokeszitett Mapping tablat hozzakapcsolom a "preparalt" forras PP alapjan
    --      es veszem a kombinacio altal eloirt osszes (elmeleti) forras SOC-ot.
    --      Beszorozzuk a kombinaciok szamaval a tarifakat.
    -- ----- ---

    INNER JOIN  LEGACY.M_OFFER_MAP AS  OFFER_MAP
            ON  LEGACY.OFFER_MAP.Src_Price_Plan_Cd = PRICE_PLAN.SOC_Cd
            AND LEGACY.OFFER_MAP.Tgt_Offer_Type    = 'T'
    -- ----- ---
    --  (3) LEFT JOIN-nal hozzakapcsolom a tenyleges (instancia) meglevo SOC-okat.
    -- ----- ---
    LEFT  JOIN  LEGACY.M_SOC PARTITION (pM,pP)      AS  SOC_XTR
            ON  SOC_XTR.Sub_Id    = PRICE_PLAN.Sub_Id
            AND SOC_XTR.CTN       = PRICE_PLAN.CTN
            AND SOC_XTR.SOC_Cd    = OFFER_MAP.Src_SOC_Cd
            and PRICE_PLAN.Exp_Dt > SOC_XTR.Eff_Dt
            and PRICE_PLAN.Eff_Dt < SOC_XTR.Exp_Dt -- mgy 2016.09.14 main offer tortenetiseg
    -- ----- ---
    --  (4) Veszem az Id2Id Offer szintu mapping-et (Main_Product).
    --  Ha left join, akkor itt megjelolhetjuk, melyikhez nincs IDID. Az 5320 (Update) szakasz felesleges.
    -- ----- ---
    /*LEFT*/
    JOIN  LEGACY.M_IDID_OFFER_MOD  AS  ID2ID_MAP
            ON  OFFER_MAP.Tgt_Offer_Cd      = ID2ID_MAP.Tgt_Offer_Cd
            AND ID2ID_MAP.Use_Flag          = 'Y'
            AND ID2ID_MAP.Main_Product_Flag = 'Y'
            AND ID2ID_MAP.Tgt_Offer_Type_Desc<>'SHARPLAN' -- mgy 2016.09.08 hogy az optimalizalas ne valaszthasson SP offert
    -- ----- ---
    LEFT OUTER JOIN LEGACY.M_OFFER_M00_DWH_SUB_ID x
      on  PRICE_PLAN.Sub_Id=x.Sub_Id
      and 'Y'=x.Main_Offer_Ind
  WHERE
  -- ----- ---
  --  Azon elofizetesekre, akikhez nem volt DWH alapu tarifa azonositas.
  -- ----- ---
          x.Sub_Id is null
  -- ----- ---
--    and   PRICE_PLAN.Svc_Class_Cd = 'PP' -- M_SOC particionalas miatt szuksegtelenne valt.
;

select concat('Finished tariff mapping: ', now(), ', affected rows:', ROW_COUNT());






/*




+------------+------+---------------------------+---------+---------------------------------------------------+---------+--------------------------------------+
| table      | type | key                       | key_len | ref                                               | rows    | Extra                                |
+------------+------+---------------------------+---------+---------------------------------------------------+---------+--------------------------------------+
| PRICE_PLAN | ALL  | NULL                      | NULL    | NULL                                              | 1248512 | Using where                          |
| x          | ref  | IDX_M_OFFER_M00_DWH_1_1_2 | 10      | LEGACY.PRICE_PLAN.SUB_ID,const                    |       1 | Using where; Not exists; Using index |
| OFFER_MAP  | ref  | IDX_M_OFFER_MAP_11_3      | 33      | LEGACY.PRICE_PLAN.SOC_CD,const                    |       3 | Using index condition                |
| SOC_XTR    | ref  | IDX_M_SOC_5_6             | 97      | LEGACY.PRICE_PLAN.CTN,LEGACY.OFFER_MAP.Src_SOC_Cd |       1 | Using where                          |
| ID2ID_MAP  | ref  | IDX_M_IDID_OFFER_MOD_5    | 302     | LEGACY.OFFER_MAP.Tgt_Offer_Cd                     |       5 | Using where                          |
+------------+------+---------------------------+---------+---------------------------------------------------+---------+--------------------------------------+
5 rows in set (0,00 sec)






*/








CREATE TABLE LEGACY.M_OFFER_M01_DEL_COMBO
AS
(
select Sub_Id,ptol,Src_Combo_Id from (
select
case
        WHEN @p = Sub_Id and @d = ptol THEN @i:=@i + 1
        ELSE @i:=1
    END AS num
, @p:=Sub_Id part1
, @d:=ptol part2
, o.Sub_Id,o.ptol,o.Src_Combo_Id
from (
                SELECT  Sub_Id                                                      AS  Sub_Id
    ,  EFFECTIVE_DATE                as  ptol
                ,       Src_Combo_Id                                                AS  Src_Combo_Id
                ,       MIN(Src_Combo_Cnt)                                          AS  Src_Combo_Cnt
                ,       SUM(CASE WHEN (Src_SOC_Seq_No IS NULL) THEN 1 ELSE 0 END)   AS  Src_Missing_Cnt
                ,       MIN(CA_Type_Cd)                                             AS  CA_Type_Cd
                ,       MIN(Map_Type)                                               AS  Map_Type
                FROM    LEGACY.M_OFFER_M01_TARIFF
                WHERE   Tgt_Offer_Type = 'T'
                GROUP BY
                        Sub_Id,EFFECTIVE_DATE
                ,       Src_Combo_Id
) o
,(SELECT @p:='-',@d:='-',@i:=0) as t
order by Sub_Id,ptol,
CASE
WHEN (CA_Type_Cd = 2 AND Map_Type = 'B2B') THEN 1   --  B2B ugyfel eseteben elsosorban B2B tarifat valasztunk -- javitani B2B+SOH-ra mgy
WHEN (CA_Type_Cd = 1 AND Map_Type = 'B2C') THEN 2   --  B2C ugyfel eseteben elsosorban B2C tarifat valasztunk
WHEN (CA_Type_Cd = 1)                      THEN 3
WHEN (CA_Type_Cd = 2)                      THEN 4
                                           ELSE 5
END
, Src_Missing_Cnt ASC
, Src_Combo_Cnt   DESC
, Src_Combo_Id    DESC   --  igy lesz determinisztikus !!!
) x

where num>1

)
;

select concat('Finished del combo: ', now(), ', affected rows:', ROW_COUNT());


call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M01_TARIFF','Sub_Id,Src_Combo_Id');

CREATE TABLE LEGACY.M_OFFER_M01_DEL_TARIFF like LEGACY.M_OFFER_M01_TARIFF;

INSERT
INTO    LEGACY.M_OFFER_M01_DEL_TARIFF
SELECT  distinct M_OFFER_M01_TARIFF.*
FROM    LEGACY.M_OFFER_M01_TARIFF
join LEGACY.M_OFFER_M01_DEL_COMBO
on M_OFFER_M01_TARIFF.Sub_Id=M_OFFER_M01_DEL_COMBO.Sub_Id
and M_OFFER_M01_TARIFF.EFFECTIVE_DATE=M_OFFER_M01_DEL_COMBO.ptol
and M_OFFER_M01_TARIFF.Src_Combo_Id=M_OFFER_M01_DEL_COMBO.Src_Combo_Id
;

select concat('Finished insert del tariff: ', now(), ', affected rows:', ROW_COUNT());


DELETE LEGACY.M_OFFER_M01_TARIFF
FROM   LEGACY.M_OFFER_M01_TARIFF
join (SELECT distinct Sub_Id, ptol, Src_Combo_Id FROM LEGACY.M_OFFER_M01_DEL_COMBO) x
on   M_OFFER_M01_TARIFF.Sub_Id=x.Sub_Id
and  M_OFFER_M01_TARIFF.EFFECTIVE_DATE=x.ptol
and  M_OFFER_M01_TARIFF.Src_Combo_Id=x.Src_Combo_Id
;

select concat('Finished combo delete: ', now(), ', affected rows:', ROW_COUNT());


-- Kigyujtok minden CTN-t, akinek van tarifaja akar DWH-bol akar SOC-bol:
drop TABLE if exists LEGACY.M_OFFER_M00_MAIN_SUB_ID;
CREATE TABLE LEGACY.M_OFFER_M00_MAIN_SUB_ID
AS
(
  SELECT  Sub_Id,
          min(VOICE_BILLING_INCREMENT) VOICE_BILLING_INCREMENT,
          COUNT(*) Tgt_Offer_Cnt
  FROM (
    select Sub_Id, VOICE_BILLING_INCREMENT from LEGACY.M_OFFER_M00_DWH where Tgt_Offer_Type = 'T'
    union all
    select Sub_Id, VOICE_BILLING_INCREMENT from LEGACY.M_OFFER_M01_TARIFF
  ) x
  GROUP BY Sub_Id
)
;


call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M00_MAIN_SUB_ID','Sub_Id,VOICE_BILLING_INCREMENT');

select concat('Finished sub_id collection: ', now(), ', affected rows:', ROW_COUNT());


-- select count(*), count(distinct Sub_Id) from M_OFFER_M00_MAIN_SUB_ID;
-- select count(*), count(distinct Sub_Id), VOICE_BILLING_INCREMENT from M_OFFER_M00_MAIN_SUB_ID group by  VOICE_BILLING_INCREMENT;


