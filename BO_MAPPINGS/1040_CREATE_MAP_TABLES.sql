USE LEGACY;

DROP FUNCTION IF EXISTS SPLIT_STR;
CREATE FUNCTION SPLIT_STR(
xx VARCHAR(500),
delim VARCHAR(12),
pos INT
)
RETURNS VARCHAR(500)
RETURN REPLACE(SUBSTRING(SUBSTRING_INDEX(xx, delim, pos),
LENGTH(SUBSTRING_INDEX(xx, delim, pos -1)) + 1),
delim, '')
;

DROP TABLE if exists M_OFFER_MAP;
DROP TABLE if exists M_OFFER_MANDADD_MAP;

CREATE TABLE M_OFFER_MAP
(   Offer_Map_Id        VARCHAR(30)     NOT NULL
,   Tgt_Offer_Cd        VARCHAR(100)    NOT NULL
,   Tgt_Offer_Type      CHAR(1)         NOT NULL
,   Tgt_Offer_Name      VARCHAR(200)    NOT NULL
,   Src_Combo_Id        INTEGER         NOT NULL
,   Src_SOC_Cd          VARCHAR(250)    NOT NULL
,   Src_SOC_Name        VARCHAR(100)        NULL
,   Src_Svc_Class_Cd    CHAR(3)             NULL
,   Src_SOC_Rank        TINYINT             NULL
,   Src_SOC_Order_No    TINYINT         NOT NULL
,   Src_Price_Plan_Cd   VARCHAR(9)          NULL
,   Src_Combo_Cnt       TINYINT             NULL
,   Map_Type            CHAR(3)         NOT NULL    --  B2B / B2C
,   VOICE_BILLING_INCREMENT varchar(30)
)
;
/*
Map_Id:  1  B2C/B2B flag 0/1
    2  T/A flag 0/1
    3-6  Order_Work sor (Tgt_Offer_Cd?) egyedi azonositoja
    7-8  Combo sorszam offeren belul; 3-8 Combo_id
    9-10  SOC sorszam combo-n belul; 3-10 Offer_Map_id  
*/
CREATE TABLE M_OFFER_MANDADD_MAP
(
    Main_Offer_Cd       VARCHAR(200)     NOT NULL
,   Main_Offer_Type     CHAR(1)         NOT NULL
,   Main_Offer_Name     VARCHAR(200)    NOT NULL
,   Addon_Offer_Cd      VARCHAR(200)     NOT NULL
,   Addon_Group_Cnt     TINYINT             NULL
,   Map_Type            CHAR(3)         NOT NULL    --  B2B / B2C
,   VOICE_BILLING_INCREMENT varchar(30)
)
;



INSERT
INTO    M_OFFER_MAP
( Offer_Map_Id
, Tgt_Offer_Cd
, Tgt_Offer_Type
, Tgt_Offer_Name
, Src_Combo_Id
, Src_SOC_Cd
, Src_SOC_Name
, Src_Svc_Class_Cd
, Src_SOC_Rank
, Src_SOC_Order_No
, Src_Price_Plan_Cd
, Src_Combo_Cnt
, Map_Type
, VOICE_BILLING_INCREMENT
)
select
  concat(
    case x.Map_Type when 'B2C' then '0' when 'B2B' then '1' else '2' end,
    case x.Tgt_Offer_Type when 'T' then '0' when 'A' then '1' else '2' end,
    lpad(x.Tgt_Offer_Id,4,'0'),
    lpad(x.Combo_Seq,2,'0'),
    lpad(x.SOC_Seq,2,'0')
    ) Offer_Map_Id,
  x.Tgt_Offer_Cd Tgt_Offer_Cd,
  x.Tgt_Offer_Type Tgt_Offer_Type,
  x.Tgt_Offer_Name Tgt_Offer_Name,
  concat(
    case x.Map_Type when 'B2C' then '0' when 'B2B' then '1' else '2' end,
    case x.Tgt_Offer_Type when 'T' then '0' when 'A' then '1' else '2' end,
    lpad(x.Tgt_Offer_Id,4,'0'),
    lpad(x.Combo_Seq,2,'0')
    ) Src_Combo_Id,
  x.SOC Src_SOC_Cd,
  r.OFFER_DESC Src_SOC_Name,
  r.Svc_Class Src_Svc_Class_Cd,
  CASE r.Svc_Class
           WHEN 'PP'  THEN 1
           WHEN 'SOC' THEN 2
           WHEN 'DSC' THEN 3
           WHEN 'EQP' THEN 4
           WHEN 'AIS' THEN 5
           WHEN 'NON' THEN 6
           ELSE 99
    END Src_SOC_Rank,
  x.SOC_Seq Src_SOC_Order_No,
  null Src_Price_Plan_Cd,
  null Src_Combo_Cnt,
  x.Map_Type,
  x.VOICE_BILLING_INCREMENT
from (
  select x.Tgt_Offer_Id,x.Tgt_Offer_Cd,x.Tgt_Offer_Type,x.Tgt_Offer_Name,x.Map_Type,x.Src_Combo_List,x.nr Combo_Seq,x.Combo,
    nn.nr SOC_Seq,
    trim(SPLIT_STR(x.Combo,' + ',nn.nr)) SOC,
    x.VOICE_BILLING_INCREMENT
  from (
    select x.*,nn.nr,
      trim(SPLIT_STR(x.Src_Combo_List,';',nn.nr)) Combo
    from (select @p:=@p+1 Tgt_Offer_Id,x.* from M_OFFER_WORK x,(select @p:=0) p) x
    join (select @r := @r+1 nr from M_OFFER_WORK, (select @r:=0) y limit 100) nn on 1=1
    having Combo<>''
    ) x 
  join (select @s := @s+1 nr from M_OFFER_WORK, (select @s:=0) y limit 100) nn on 1=1
  having SOC<>''
  ) x
left outer join SOC_REF_LDR r on x.SOC=r.Offer_Id
;

update M_OFFER_MAP o
join (select Tgt_Offer_Cd,Src_Combo_Id, max(Src_SOC_Cd) Src_SOC_Cd from M_OFFER_MAP where Src_Svc_Class_Cd = 'PP' group by Tgt_Offer_Cd,Src_Combo_Id) oo
  on o.Tgt_Offer_Cd = oo.Tgt_Offer_Cd 
  and o.Src_Combo_Id = oo.Src_Combo_Id
set o.Src_Price_Plan_Cd = oo.Src_SOC_Cd
;
update M_OFFER_MAP o
join (select Tgt_Offer_Cd,Src_Combo_Id, count(1) Src_Combo_Cnt from M_OFFER_MAP group by Tgt_Offer_Cd,Src_Combo_Id) oo
  on o.Tgt_Offer_Cd = oo.Tgt_Offer_Cd 
  and o.Src_Combo_Id = oo.Src_Combo_Id
set o.Src_Combo_Cnt = oo.Src_Combo_Cnt
;

-- A SOC combo-beli sorszamaval inicializaltuk, de itt felulirjuk az order by miatt
UPDATE  M_OFFER_MAP M
join (
  select M.Offer_Map_Id
    ,case when @p=Src_Combo_Id then @i:=@i+1 else @i:=1 end Src_SOC_Order_No
    ,@p:=Src_Combo_Id
  from M_OFFER_MAP M,(select @i:=0,@p:=0) i
  order by Src_Combo_Id,Src_SOC_Rank,Src_SOC_Cd 
  ) C
  ON   C.Offer_Map_Id = M.Offer_Map_Id
SET     M.Src_SOC_Order_No = C.Src_SOC_Order_No
;


INSERT
INTO    M_OFFER_MANDADD_MAP (
  Main_Offer_Cd
, Main_Offer_Type
, Main_Offer_Name
, Addon_Offer_Cd
, Addon_Group_Cnt
, Map_Type
, VOICE_BILLING_INCREMENT
)
select
  x.Tgt_Offer_Cd Main_Offer_Cd,
  x.Tgt_Offer_Type Main_Offer_Type,
  x.Tgt_Offer_Name Main_Offer_Name,
  x.SOC Addon_Offer_Cd,
  cast(null as unsigned) Addon_Group_Cnt,
  x.Map_Type,
  x.VOICE_BILLING_INCREMENT
from (
  select x.Tgt_Offer_Id,x.Tgt_Offer_Cd,x.Tgt_Offer_Type,x.Tgt_Offer_Name,x.Map_Type,x.Mand_Addon_List,x.nr Combo_Seq,x.Combo
    ,nn.nr SOC_Seq,
    trim(SPLIT_STR(x.Combo,'+',nn.nr)) SOC,
    x.VOICE_BILLING_INCREMENT
  from (
    select x.*,nn.nr,
      trim(SPLIT_STR(x.Mand_Addon_List,';',nn.nr)) Combo
    from (select @p:=@p+1 Tgt_Offer_Id,x.* from M_OFFER_MANDADD_WORK x,(select @p:=0) p) x
    join (select @r := @r+1 nr from M_OFFER_MANDADD_WORK, (select @r:=0) y limit 100) nn on 1=1
    having Combo<>''
    ) x 
  join (select @s := @s+1 nr from M_OFFER_MANDADD_WORK, (select @s:=0) y limit 100) nn on 1=1
  having SOC<>''
  ) x
-- left outer join SOC_REF_LDR r on x.SOC=r.Offer_Id
;

UPDATE  M_OFFER_MANDADD_MAP M
  JOIN (SELECT Main_Offer_Cd,count(1) Addon_Group_Cnt FROM M_OFFER_MANDADD_MAP GROUP BY Main_Offer_Cd) C ON M.Main_Offer_Cd = C.Main_Offer_Cd
SET M.Addon_Group_Cnt = C.Addon_Group_Cnt
;

-- NGy 08.08

SET SQL_SAFE_UPDATES=0;
-- Repeta extract(EDSZ_LDR) - ABCONPRS Addon - Hitelkeret
delete from M_OFFER_MAP
where Tgt_Offer_Cd = 'ABCONPRS';

delete from M_OFFER_MANDADD_MAP
where Addon_Offer_Cd = 'ABCONPRS';

