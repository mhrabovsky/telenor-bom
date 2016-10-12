-- USE LEGACY;

-- Futasido (3-as gep): index:10 perc + insert: 8 perc

-- NAS 10.04 beégetések bõvítése
SET @EFF_DATE = CAST(LEGACY.CONFIG('DEF_EFF_DATE',NULL) AS DATE);
SET @EXP_DATE = CAST(LEGACY.CONFIG('DEF_EXP_DATE',NULL) AS DATE);

/*

Here, our reduced FEATURE tables are prepared.
The legacy FEATURE table has 140M records, so it is worth not indexing but first create reduced sets.
M_FEATURE is reduced to B2B or B2C CTN-s in order to fork into parallel execution.
M_FEATURE is never used but still highly populated, so we jump over this step.

M_FEATURE_EXTR contains only those records that also bring us SWITCH_PARAM or ADDITIONAL_INFO.

*/


call LEGACY.createindex_ifnotexists('LEGACY','M_SOC','SOC_Seq_No,SOC_Cd');
-- create index i_M_SOC_SSN_SCD on M_SOC (SOC_Seq_No,SOC_Cd);
-- .136-os gepen 6 perc alatt keszul ez az index.


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


drop TABLE IF EXISTS LEGACY.M_FEATURE_EXTR;

CREATE TABLE LEGACY.M_FEATURE_EXTR (
  add_or_swi           char(1)     ,
  Sub_Id	       varchar(28) ,
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
  PARTITION BY LIST COLUMNS(add_or_swi) (
    PARTITION pA VALUES IN('A'),
    PARTITION pS VALUES IN('S')
    )
;
-- MT: Kette particionaltam aszerint, hogy additional_info vagy switch_param tartalmu-e a sor. Igy hatekonyan lehet egyikre lekerdezni.
-- A eredeti FEATURE_LDR tablaban kb. 20% olyan van, ami mind a kettot hordozza.



insert into LEGACY.M_FEATURE_EXTR
SELECT
  SA.SA                   as add_or_swi
,concat(F.BAN,'_',F.BEN,'_',F.CTN) AS Sub_Id
, F.BAN                   AS  BAN
, F.BEN                   AS  BEN
, F.CTN                   AS  CTN
, S.SOC_Cd                AS  SOC_Cd   -- Egyetlen adatunk az M_SOC tablabol
, F.SOC_Seq_No            AS  SOC_Seq_No
, F.FEATURE_CODE
, COALESCE(CAST(F.FTR_EFFECTIVE_DATE  AS DATE), @EFF_DATE ) FTR_EFFECTIVE_DATE
, COALESCE(CAST(F.FTR_EXPIRATION_DATE AS DATE), @EXP_DATE ) FTR_EXPIRATION_DATE
, F.SERVICE_FTR_SEQ_NO
, case
  when SA.SA='S' then TRIM(both '@' FROM trim(switch_param))
  when SA.SA='A' then TRIM(both '@' FROM trim(additional_info))
  else ''
  end                  as txt_to_split
FROM        LEGACY.FEATURE_LDR  AS  F     -- Tobb ido az indexeles mint a FTS egyszer.
INNER JOIN  LEGACY.M_SOC        AS  S     -- M_SOC mar csak B2B vagy B2C CTN-ekre relevans sorokat tartalmaz.
        ON S.SOC_Seq_No = F.SOC_SEQ_NO -- Ez egyedi
JOIN (select 'S' AS SA union all select 'A' AS SA) as SA
  ON ( (SA.SA='S' and switch_param is not null)
     or (SA.SA='A' and additional_info is not null)
     )
where (F.FTR_EXPIRATION_DATE is null
   or F.FTR_EXPIRATION_DATE >= '2016-08-01')
  AND (switch_param is not null
     or additional_info is not null)
;

-- 10737958 rows affected (8 min 7.95 sec)  -- .133-as gep
-- 11962832 rows affected (4 min 41,36 sec) -- .136-os gep

/*

A tablanak ezt a formajat megorizzuk _SL nevvegzodessel (ugyanis a product szakaszon valtozik a tabla):

*/

drop TABLE if exists LEGACY.M_FEATURE_EXTR_SL;
CREATE TABLE LEGACY.M_FEATURE_EXTR_SL
as select * from LEGACY.M_FEATURE_EXTR;

call LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE_EXTR_SL','SOC_Seq_No');

