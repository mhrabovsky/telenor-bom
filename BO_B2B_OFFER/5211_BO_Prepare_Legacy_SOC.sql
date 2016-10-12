-- USE LEGACY;

-- Futasido (): 14 perc insert + 3 perc index

/*

A soc tablankat elparticionaljuk PP, OFFER_MAP, SPECIAL_MAP es nem hasznalt reszekre.

*/

-- NAS 10.04 be?get?sek b?v?t?se
SET @EXP_DATE = CAST(LEGACY.CONFIG('DEF_EXP_DATE',NULL) AS DATE);
SET @EXP_DT = CAST(LEGACY.CONFIG('DEF_EXP_DATE',NULL) AS DATETIME);

call LEGACY.createindex_ifnotexists('LEGACY','M_USER','Sub_Id');
-- call LEGACY.createindex_ifnotexists('LEGACY','SOC_LDR','BAN,BEN,CTN');



drop table if exists LEGACY.M_SOC;
CREATE TABLE LEGACY.M_SOC (
  SOC_PART         CHAR(1)      NOT NULL, -- 'P','M','S','-'
  SUB_ID           VARCHAR(30)  NOT NULL,
  BAN              VARCHAR(10)  NOT NULL,
  BEN              VARCHAR(5)   NOT NULL,
  CTN              VARCHAR(11)  NOT NULL,
  SOC_CD           VARCHAR(20)  NOT NULL,
  SOC_SEQ_NO       BIGINT(20)   NOT NULL,
  SVC_TYPE_CD      CHAR(1)      NOT NULL,
  SVC_CLASS_CD     CHAR(3)      NOT NULL,
  SOC_STATUS_CD    CHAR(1)      NULL,
  EFF_DT           DATETIME     NOT NULL,
  EXP_DT           DATETIME     NOT NULL,
  COMM_START_DT    DATETIME     NULL,
  COMM_END_DT      DATETIME     NULL,
  COMM_NO_MONTHS   SMALLINT(6)  NULL,
  SOC_RANK         TINYINT(4)   NOT NULL,
  CA_ID            VARCHAR(30)  NOT NULL,
  CA_TYPE_CD       TINYINT(4)   NULL,
  SUB_TYPE         CHAR(3)      NOT NULL,
  SUBSCRIBER_REF   VARCHAR(30)  NULL
)
engine=MyIsam
  PARTITION BY LIST COLUMNS(SOC_PART)          -- Termeszetes reszhalmazok
  SUBPARTITION BY KEY (SUB_ID) SUBPARTITIONS 4 -- Tobb CPU. A KEY olyan HASH, ami lehet tobboszlopos es nem csak integer
  (
    PARTITION pP VALUES IN('P'), -- PP
    PARTITION pM VALUES IN('M'), -- OFFER_MAP
    PARTITION pS VALUES IN('S'), -- SPECIAL_MAP
    PARTITION pU VALUES IN('-')  -- UNUSED
    )
;


-- --- Hasznalt soc-ok:

drop table if exists LEGACY.M_MAP_SOCS;
create temporary table LEGACY.M_MAP_SOCS (SOC varchar(20), PART char(1)) engine=memory;

truncate table LEGACY.M_MAP_SOCS;
insert into LEGACY.M_MAP_SOCS
  select distinct trim(SOC), 'S' PART from LEGACY.M_SPECIAL_MAP
  union
  select distinct substr(trim(Src_SOC_Cd),1,20) SOC, 'M' PART from LEGACY.M_OFFER_MAP
   where not exists (select 1 from LEGACY.M_SPECIAL_MAP where trim(SOC)=substr(trim(Src_SOC_Cd),1,20))
;

create unique index I_M_MAP_SOCS on LEGACY.M_MAP_SOCS(SOC); -- , PART);
desc LEGACY.M_MAP_SOCS;

insert into LEGACY.M_SOC (
  SOC_PART      ,
  SUB_ID        ,
  BAN           ,
  BEN           ,
  CTN           ,
  SOC_CD        ,
  SOC_SEQ_NO    ,
  SVC_TYPE_CD   ,
  SVC_CLASS_CD  ,
  SOC_STATUS_CD ,
  EFF_DT        ,
  EXP_DT        ,
  COMM_START_DT ,
  COMM_END_DT   ,
  COMM_NO_MONTHS,
  SOC_RANK      ,
  CA_ID         ,
  CA_TYPE_CD    ,
  SUB_TYPE      ,
  SUBSCRIBER_REF
)
select
  case
    when S.SERVICE_CLASS  ='PP'  then 'PP'
    when S.SERVICE_CLASS != 'PP' then coalesce(M.PART,'-')
    end SOC_PART,
  U.SUB_ID      ,
  S.BAN         ,
  S.BEN         ,
  S.CTN         ,
  S.SOC                                               AS  SOC_CD,
  S.SOC_SEQ_NO                                        AS  SOC_SEQ_NO,
  S.SERVICE_TYPE                                      AS  SVC_TYPE_CD,
  S.SERVICE_CLASS                                     AS  SVC_CLASS_CD,
  S.OFFER_STATUS                                      AS  SOC_STATUS_CD,
  CASE WHEN U.Sub_Status_Cd = 'C' THEN U.Init_Act_Dt ELSE COALESCE(S.EFFECTIVE_DATE , @EXP_DATE ) END AS  EFF_DT,
  COALESCE( CAST(S.EXPIRATION_DATE AS DATETIME), @EXP_DT ) AS  Exp_Dt,
  CAST(S.COMMITMENT_START_DATE AS DATE)               AS  COMM_START_DT,
  CAST(S.COMMITMENT_END_DATE   AS DATE)               AS  COMM_END_DT,
  COALESCE(S.NUMBER_OF_MONTHS,TIMESTAMPDIFF(MONTH, S.COMMITMENT_START_DATE, S.COMMITMENT_END_DATE))  COMM_NO_MONTHS,
  CASE S.SERVICE_CLASS
    WHEN 'PP'  THEN 1
    WHEN 'SOC' THEN 2
    WHEN 'DSC' THEN 3
    WHEN 'EQP' THEN 4
    WHEN 'AIS' THEN 5
    WHEN 'NON' THEN 6
  END   SOC_RANK,
  U.CA_ID       ,
  U.CA_Type_Cd  ,
  U.Sub_Type    ,
  U.SUBSCRIBER_REF
from      LEGACY.SOC_LDR    S
join      LEGACY.M_USER     U on U.Sub_Id=concat(S.BAN,'_',S.BEN,'_',rtrim(S.CTN))
left join LEGACY.M_MAP_SOCS M on M.SOC=S.SOC and M.PART in ('S','M')
;

call LEGACY.createindex_ifnotexists('LEGACY','M_SOC','Sub_Id');
