USE LEGACY;

-- Futasido (3-as gep): 18 perc insert + 5 perc index

/*

Here, our reduced FEATURE tables are prepared.
The legacy FEATURE table has 170M records, so it is worth not indexing but first create reduced sets.
M_FEATURE is reduced to B2B or B2C CTN-s in order to fork into parallel execution.
M_FEATURE is never used but still highly populated, so we jump over this step.

M_FEATURE_EXTR contains only those records that also bring us SWITCH_PARAM or ADDITIONAL_INFO.

*/


call LEGACY.createindex_ifnotexists('LEGACY','M_SOCX','SOC_Seq_No,SOC_Cd');
-- ido: 

/*

FEATURE-bol amikre szuksegunk van:

* Attr2Attr excelben felsorolt feature kodok
* Special mapping-ben hasznalt kodok
* Offer_map-ben felsoroltak (ez remeljuk, nem ter el az Attr2Attr tartalmatol)

*/


-- --- Hasznalt kodok:

drop table if exists M_MAP_FEA;
create temporary table M_MAP_FEA (FEA varchar(20), PART char(1)) engine=memory;

truncate table M_MAP_FEA;
insert into M_MAP_FEA
  select distinct trim(FEATURE) FEA, 'S' PART from M_SPECIAL_MAP
  union
  select distinct substr(trim(FEATURE_CD),1,20) FEA, 'M' PART from M_IDID_ATTR_MOD
   where substr(trim(FEATURE_CD),1,20) not in (select distinct trim(FEATURE) FEA from M_SPECIAL_MAP)
;

create index I_M_MAP_FEA on M_MAP_FEA(FEA);



drop TABLE IF EXISTS M_FEATURE_USED;

CREATE TABLE M_FEATURE_USED (
  FEA_PART             char(1)     ,
  add_or_swi           char(1)     ,
  Sub_Id               varchar(28) ,
  BAN                  varchar(10) ,
  BEN                  varchar(5)  ,
  CTN                  varchar(11) ,
  SOC_Cd               char(9)     ,
  SOC_Seq_No           varchar(9)  ,
  FEATURE_CODE         varchar(6)  ,
  FTR_EFFECTIVE_DATE   date        ,
  FTR_EXPIRATION_DATE  date        ,
  SERVICE_FTR_SEQ_NO   varchar(10) ,
  txt_to_split         varchar(400)
)
engine=MyIsam
PARTITION BY LIST COLUMNS(FEA_PART,add_or_swi)
  (
  PARTITION pSA VALUES IN(('S','A')), -- M_SPECIAL_MAP , additional_info
  PARTITION pSS VALUES IN(('S','S')), -- M_SPECIAL_MAP , switch_param
  PARTITION pSN VALUES IN(('S','-')), -- M_SPECIAL_MAP , none
  PARTITION pMA VALUES IN(('M','A')), -- M_IDID_ATTR_MOD , additional_info
  PARTITION pMS VALUES IN(('M','S')), -- M_IDID_ATTR_MOD , switch_param
  PARTITION pMN VALUES IN(('M','-'))  -- M_IDID_ATTR_MOD , none
  )
;

-- MT: Kette particionaltam aszerint, hogy additional_info vagy switch_param tartalmu-e a sor. Igy hatekonyan lehet egyikre lekerdezni.
-- A eredeti FEATURE_LDR tablaban kb. 20% olyan van, ami mind a kettot hordozza.



insert into M_FEATURE_USED
SELECT
  case when S.SOC_PART='S' then 'S' else M.PART end   FEA_PART,
  coalesce(SA.SA,'-')               AS  add_or_swi,
  concat(F.BAN,'_',F.BEN,'_',F.CTN) AS Sub_Id,
  F.BAN,
  F.BEN,
  F.CTN,
  S.SOC_Cd, -- Egyetlen adatunk az M_SOC tablabol
  F.SOC_Seq_No,
  F.FEATURE_CODE                              ,
  COALESCE(CAST(F.FTR_EFFECTIVE_DATE  AS DATE), CAST('1900-12-31' AS DATE)) FTR_EFFECTIVE_DATE ,
  COALESCE(CAST(F.FTR_EXPIRATION_DATE AS DATE), CAST('2099-12-31' AS DATE)) FTR_EXPIRATION_DATE,
  F.SERVICE_FTR_SEQ_NO,
  case
  when SA.SA='S' then TRIM(both '@' FROM trim(switch_param))
  when SA.SA='A' then TRIM(both '@' FROM trim(additional_info))
  else ''
  end                  as txt_to_split
FROM        FEATURE_LDR  AS  F     -- Tobb ido az indexeles mint a FTS egyszer.
INNER JOIN  M_SOCX       AS  S     -- M_SOC mar csak B2B vagy B2C CTN-ekre relevans sorokat tartalmaz.
        ON S.SOC_Seq_No = F.SOC_SEQ_NO -- Ez egyedi
INNER JOIN  M_MAP_FEA    AS  M     -- A hasznalatban levo feature kodok
      USE INDEX (I_M_MAP_FEA)
        ON M.FEA=F.FEATURE_CODE
LEFT JOIN (select 'S' AS SA union all select 'A' AS SA) as SA
  ON ( (SA.SA='S' and switch_param is not null)
     or (SA.SA='A' and additional_info is not null)
     )
where S.SOC_PART in ('P','S','M')
  and (F.FTR_EXPIRATION_DATE is null  or F.FTR_EXPIRATION_DATE >= '2016-08-01')
--  AND (switch_param is not null or additional_info is not null)
;


/*
Query OK, 13453269 rows affected (18 min 14,40 sec)
Records: 13453269  Duplicates: 0  Warnings: 0

mysql> select count(*), FEA_PART, add_or_swi from M_FEATURE_USED group by FEA_PART, add_or_swi;
+----------+----------+------------+
| count(*) | FEA_PART | add_or_swi |
+----------+----------+------------+
|  7707789 | M        | -          |
|   854398 | M        | A          |
|  4454411 | M        | S          |
|     6109 | S        | -          |
|   394514 | S        | A          |
|    36048 | S        | S          |
+----------+----------+------------+
6 rows in set (9,39 sec)

*/



call LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE_EXTR_SL','SOC_Seq_No');

/*

Special feature tabla: Igazabol csak a pSA/pSS/pSN particiokat kell hasznalnunk.

*/








/*
desc FEATURE_LDR;
+---------------------+--------------+------+-----+---------+-------+
| Field               | Type         | Null | Key | Default | Extra |
+---------------------+--------------+------+-----+---------+-------+
| BAN                 | varchar(10)  | YES  |     | NULL    |       |
| BEN                 | varchar(5)   | YES  |     | NULL    |       |
| CTN                 | varchar(11)  | YES  |     | NULL    |       |
| SOC_SEQ_NO          | varchar(9)   | YES  |     | NULL    |       |
| SERVICE_FTR_SEQ_NO  | varchar(10)  | YES  |     | NULL    |       |
| FEATURE_CODE        | varchar(6)   | YES  |     | NULL    |       |
| ADDITIONAL_INFO     | varchar(200) | YES  |     | NULL    |       |
| FTR_EFFECTIVE_DATE  | datetime     | YES  |     | NULL    |       |
| FTR_EXPIRATION_DATE | datetime     | YES  |     | NULL    |       |
| SWITCH_PARAM        | varchar(400) | YES  |     | NULL    |       |
+---------------------+--------------+------+-----+---------+-------+


regi M_FEATURE_EXTR:
+---------------------+--------------+------+-----+---------+-------+
| Field               | Type         | Null | Key | Default | Extra |
+---------------------+--------------+------+-----+---------+-------+
| ban                 | varchar(10)  | NO   |     | NULL    |       |
| ben                 | varchar(5)   | NO   |     | NULL    |       |
| ctn                 | varchar(11)  | NO   | MUL | NULL    |       |
| FEATURE_CODE        | varchar(6)   | NO   |     | NULL    |       |
| ftr_effective_date  | datetime     | NO   |     | NULL    |       |
| ftr_expiration_date | datetime     | NO   |     | NULL    |       |
| service_ftr_seq_no  | varchar(10)  | NO   |     | NULL    |       |
| add_or_swi          | varchar(1)   | NO   |     |         |       |
| txt_to_split        | varchar(400) | YES  |     | NULL    |       |
+---------------------+--------------+------+-----+---------+-------+

uj M_FEATURE_EXTR:
+---------------------+--------------+------+-----+---------+-------+
| Field               | Type         | Null | Key | Default | Extra |
+---------------------+--------------+------+-----+---------+-------+
| add_or_swi          | char(1)      | NO   |     |         |       |
| BAN                 | varchar(10)  | YES  |     | NULL    |       |
| BEN                 | varchar(5)   | YES  |     | NULL    |       |
| CTN                 | varchar(11)  | YES  |     | NULL    |       |
| SOC_Cd              | char(9)      | NO   |     | NULL    |       |
| SOC_Seq_No          | varchar(9)   | YES  |     | NULL    |       |
| FEATURE_CODE        | varchar(6)   | YES  |     | NULL    |       |
| FTR_EFFECTIVE_DATE  | date         | YES  |     | NULL    |       |
| FTR_EXPIRATION_DATE | date         | YES  |     | NULL    |       |
| SERVICE_FTR_SEQ_NO  | varchar(10)  | YES  |     | NULL    |       |
| txt_to_split        | varchar(400) | YES  |     | NULL    |       |
+---------------------+--------------+------+-----+---------+-------+



*/
