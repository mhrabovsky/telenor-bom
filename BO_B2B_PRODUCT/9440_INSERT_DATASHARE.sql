-- Adatmegoszto special mapping rule - VR 2016.09.06

-- Attributum ertek kiolvasasa az additional_info-bol

-- 20161004_NS: beegetesek bovitese
-- 20161011_HL: FEAUTURE, M_IDID_ATTR_LDR helyett M_IDID_ATTR_MOD-ot használunk

SET @BASE = LEGACY.CONFIG('ATTR_INST_ID', null);
SET @EFF_DT = CAST(LEGACY.CONFIG('DEF_EFF_DATE',NULL) AS DATETIME);
SET @EXP_DT = CAST(LEGACY.CONFIG('DEF_EXP_DATE',NULL) AS DATETIME);
SET @SYS_DATE = CAST(LEGACY.CONFIG('SYS_DATE',NULL) AS DATETIME);

-- USE LEGACY;
DROP FUNCTION IF EXISTS LEGACY.read_attrib;
delimiter $$
CREATE FUNCTION LEGACY.read_attrib (additional_info VARCHAR(200), attr_name VARCHAR(30)) RETURNS VARCHAR(30)
BEGIN
  DECLARE attr_val VARCHAR(30) CHARACTER SET utf8;
  SET additional_info = CONCAT('@', TRIM(additional_info));
    IF INSTR(additional_info, CONCAT('@', attr_name, '=')) > 0 THEN
    SET attr_val = SUBSTRING( additional_info, INSTR(additional_info, CONCAT('@', attr_name, '=')) + LENGTH(attr_name) + 2 );
    IF INSTR(attr_val, '@') THEN 
      SET attr_val = LEFT( attr_val, INSTR(attr_val, '@') - 1); 
    END IF;
    END IF;
    RETURN attr_val;
END$$
delimiter ;


-- DATASHARE work tabla letrehozasa

DROP TABLE if exists LEGACY.WRK_DATASHARE_ALL;
CREATE TABLE LEGACY.WRK_DATASHARE_ALL
AS (
select distinct
-- ----------------- Fokartya SOC adatai ---------------------
                              trim(p.Sub_Id)                           HOST_SOC_CTN 
                ,              p.SOC_Seq_No                          HOST_SOC_SOC_Seq_No 
                ,              p.CA_Id                               HOST_SOC_CA_Id 
-- ---------------- Fo USER adatai -----------------------------
                ,              fo.IMSI,
-- ---------------- Tarskartya adatai --------------------------
                               b.* 
                from 
                (
                select 
                               LEGACY.read_attrib(f.txt_to_split,'HOST#') p_CTN
                ,              a.Tgt_Offer_Cd
-- ----------- M_SOC fields --------------------------
                ,              trim(m.CTN)                          TARS_SOC_CTN 
                ,              m.SOC_Seq_No                         TARS_SOC_SOC_Seq_No 
                ,              m.Eff_Dt                             TARS_SOC_Eff_Dt 
                ,              m.Exp_Dt                             TARS_SOC_Exp_Dt 
-- ------------M_USER fields ------------------------------------
                ,              u.IMSI                               TARS_USER_IMSI
-- -------------------------------------------------------------
                ,        f.service_ftr_seq_no         FEATURE_SEQ_NO
                ,        f.ftr_effective_date        FEATURE_EFFECTIVE_DATE
                ,        f.ftr_expiration_date        FEATURE_EXPIRATION_DATE
                               from LEGACY.M_SOC m
                               join LEGACY.M_USER u on m.Sub_Id=u.Sub_Id -- and m.BAN=u.BAN and m.CTN=u.CTN
                               join ( -- kivalasztjuk az adatmegosztoban erintett rekordokat a SOC rekordok kozul
                                               select Sub_Id
                                               ,              group_concat(distinct SOC_Cd order by 1) socs
                                               ,              case       group_concat(distinct trim(SOC_Cd) order by 1)
                                                                              when    'WISESHARE'                          then 'ADSPLIT02'
                                                                              when    'WISESHARE,WISESHDSC'                then 'ADSPLIT04'
                                                                              when    'PIDSC100,WISESHARE'                 then 'ADSPLIT03'
                                                                              when    'PIDSC100,WISESHARE,WISESHDSC'       then 'ADSPLIT03'
                                                                              when    'MYPPSHARE'                          then 'ADSPLIT01'
                                                               end Tgt_Offer_Cd
                                               FROM LEGACY.M_SOC 
                                               where 
                                                               SOC_Cd in ('MYPPSHARE','WISESHARE','PIDSC100','WISESHDSC')
                                               group by Sub_Id
                                               ) a
                                               on m.Sub_Id=a.Sub_Id
                               join LEGACY.M_FEATURE_EXTR f
                               on f.Sub_Id=a.Sub_Id  and f.SOC_Cd=m.SOC_Cd and f.FEATURE_CODE='QSHRPR' and f.add_or_swi = 'A' 
                               where m.SOC_Cd in ('MYPPSHARE','WISESHARE','PIDSC100','WISESHDSC')
                               order by 2
                ) b
                join LEGACY.M_SOC p
                               on b.p_CTN=p.CTN and (p.SOC_Cd='HOSTDATA' or p.Svc_Class_Cd='PP')
                join LEGACY.M_USER fo
                               on b.p_CTN=fo.CTN
                where p.SOC_cd='HOSTDATA'
)
;

-- duplikaciok megszuntetese, megfelelo datumok beallitasa
-- amikhez nincs main_offer azok kiszurese
DROP TABLE if exists LEGACY.WRK_DATASHARE;
CREATE TABLE LEGACY.WRK_DATASHARE
AS (
SELECT     HOST_SOC_CTN
    ,   HOST_SOC_SOC_Seq_No
        ,   IMSI
        ,   HOST_SOC_CA_Id
        ,   Tgt_Offer_Cd
        ,   TARS_SOC_CTN
    ,  TARS_SOC_SOC_Seq_No
        ,   TARS_USER_IMSI
    ,  FEATURE_SEQ_NO
        ,  MIN(TARS_SOC_Eff_Dt)      AS TARS_SOC_Eff_Dt
        ,  MAX(TARS_SOC_Exp_Dt)      AS TARS_SOC_Exp_Dt
        ,  MIN(FEATURE_EFFECTIVE_DATE)   AS FEATURE_EFFECTIVE_DATE
        ,  MAX(FEATURE_EXPIRATION_DATE)  AS FEATURE_EXPIRATION_DATE
FROM LEGACY.WRK_DATASHARE_ALL
WHERE HOST_SOC_CTN IN (SELECT DISTINCT USER_ID FROM MDM.INS_OFFER WHERE OFFER_TYPE ='OFFER_PLAN_BBOSS')
 GROUP BY  HOST_SOC_CTN, 
      HOST_SOC_SOC_Seq_No, 
      IMSI, 
      HOST_SOC_CA_Id, 
      Tgt_Offer_Cd, 
      TARS_SOC_CTN, 
      TARS_SOC_SOC_Seq_No,
      TARS_USER_IMSI,
      FEATURE_SEQ_NO
)
;
-- DROP TABLE if exists LEGACY.WRK_DATASHARE_ALL;


-- WORK INS_OFFER tabla, csak a DATASHARE adatokkal 
DROP TABLE if exists LEGACY.WRK_DATASHARE_INS_OFFER;
create table LEGACY.WRK_DATASHARE_INS_OFFER AS (
select 
 distinct
'22'                                              AS TENANT_ID,
CONCAT(TARS_SOC_SOC_SEQ_NO, M.Relat_Offer_Id)     AS OFFER_INST_ID,
HOST_SOC_CA_Id                                    AS CUST_ID,
'3'                                               AS CUST_TYPE,
HOST_SOC_CTN                                      AS USER_ID,
M.Relat_Offer_Id                                  AS OFFER_ID,
'OFFER_VAS_CBOSS'                                 AS OFFER_TYPE,
'0'                                               AS BRAND_ID,
TGT_OFFER_NAME                                    AS ORDER_NAME,
CASE WHEN 
  TARS_SOC_Exp_Dt < @SYS_DATE THEN '7' 
     WHEN
  TARS_SOC_Eff_Dt > @SYS_DATE THEN '7' 
  ELSE '1'
END                                               AS STATE,
CASE WHEN TARS_SOC_Eff_Dt IS NULL THEN @EFF_DT
   WHEN  TARS_SOC_Eff_Dt > @EXP_DT THEN @EFF_DT
     ELSE TARS_SOC_Eff_Dt
     END                                          AS EFFECTIVE_DATE,

CASE WHEN TARS_SOC_Exp_Dt IS NULL THEN @EXP_DT
     WHEN TARS_SOC_Exp_Dt > @EXP_DT THEN @EXP_DT
     ELSE TARS_SOC_Exp_Dt END                     AS EXPIRE_DATE,
'0'                                               AS SALE_TYPE,
null                                              AS DONE_CODE,
'0'                                               AS EXPIRE_PROCESS_TYPE,
'99999'                                           AS CHANNEL_TYPE,
'0'                                               AS OS_STATE
FROM 
LEGACY.WRK_DATASHARE D
INNER JOIN LEGACY.M_IDID_OFFER_MOD M
ON D.Tgt_Offer_Cd = M.Tgt_Offer_Cd
WHERE
MDM_TYPE_CD = 'SRVC_SINGLE'
)
;


-- INS_OFF_INS_USER tabla feltoltese
insert into
MDM.INS_OFF_INS_USER (
  TENANT_ID,
  OFFER_USER_RELAT_ID,
  OFFER_INST_ID,
  USER_ID,
  OFFER_ID,
  ROLE_ID,
  IS_MAIN_OFFER,
  IS_GRP_MAIN_USER,
  STATE,
  DONE_CODE,
  CREATE_DATE,
  DONE_DATE,
  EFFECTIVE_DATE, 
  EXPIRE_DATE, 
  OP_ID,
  ORG_ID
)
select
DISTINCT
  '22' TENANT_ID,
  CONCAT(RIGHT(USER_ID,7),OFFER_INST_ID) OFFER_USER_RELAT_ID,
  OFFER_INST_ID,
  USER_ID,
  OFFER_ID,
  -- null ROLE_ID,
  '181000000001' ROLE_ID,  -- NAS 0718
  '1' IS_MAIN_OFFER, 
  '0' IS_GRP_MAIN_USER,
  STATE,
  '0' DONE_CODE,
  EFFECTIVE_DATE CREATE_DATE,
  EFFECTIVE_DATE DONE_DATE,
  EFFECTIVE_DATE,
  EXPIRE_DATE,
  null OP_ID,
  null ORG_ID
FROM 
LEGACY.WRK_DATASHARE_INS_OFFER
;


-- INS_OFFER tabla toltese DATASHARE adatokkal
insert into MDM.INS_OFFER 
select * FROM LEGACY.WRK_DATASHARE_INS_OFFER
;

-- -----------------------------------------------------------------------------------------

-- INS_PROD tabla toltese DATASHARE adatokkal
INSERT INTO MDM.INS_PROD
(
    TENANT_ID,
    PROD_INST_ID,
    OFFER_USER_RELAT_ID,
    OFFER_INST_ID,
    USER_ID,
    PROD_ID,
    PROD_TYPE,
    EXPIRE_PROCESS_TYPE,
    STATE,
    EFFECTIVE_DATE,
    EXPIRE_DATE
)
SELECT DISTINCT
     '22'                                                             AS TENANT_ID
    ,CONCAT(VERIS_OBJECT_ID,TARS_SOC_CTN, TARS_SOC_SOC_SEQ_NO)        AS PROD_INST_ID
    ,CONCAT(RIGHT(HOST_SOC_CTN, 7), TARS_SOC_SOC_SEQ_NO,Relat_Offer_Id)         AS OFFER_USER_RELAT_ID
    ,CONCAT(TARS_SOC_SOC_SEQ_NO,Relat_Offer_Id)                       AS OFFER_INST_ID
    ,HOST_SOC_CTN                                                     AS USER_ID
    ,VERIS_OBJECT_ID                                                  AS PROD_ID
    ,MDM_TYPE_CD                                                      AS EXPIRE_PROCESS_TYPE
    ,'0'                                                              AS STATE

    ,CASE WHEN FEATURE_EXPIRATION_DATE < @SYS_DATE
            THEN '7'
          ELSE '1'
     END
    ,CASE WHEN FEATURE_EFFECTIVE_DATE IS NULL
            THEN @EFF_DT
          WHEN FEATURE_EFFECTIVE_DATE > FEATURE_EXPIRATION_DATE
            THEN FEATURE_EXPIRATION_DATE
          ELSE FEATURE_EFFECTIVE_DATE
     END                                                              AS EFFECTIVE_DATE
    ,CASE WHEN FEATURE_EXPIRATION_DATE IS NULL
            THEN @EXP_DT
          WHEN FEATURE_EXPIRATION_DATE > @EXP_DT
            THEN @EXP_DT
          ELSE FEATURE_EXPIRATION_DATE
     END                                                              AS EXPIRE_DATE
FROM LEGACY.WRK_DATASHARE D
INNER JOIN LEGACY.M_IDID_OFFER_MOD M
ON D.Tgt_Offer_Cd = M.Tgt_Offer_Cd AND M.Tgt_Offer_CD LIKE 'ADSPLIT%' AND MDM_TYPE_CD IN ('SRVC_SINGLE', 'PRICE_PROD')
WHERE  VERIS_OBJECT_ID IS NOT NULL
;


-- INS_PROD_INS_SERV tabla toltese
INSERT INTO MDM.INS_PROD_INS_SRV
(
     TENANT_ID
    ,PROD_SRV_RELAT_ID
    ,OFFER_INST_ID
    ,PROD_INST_ID
    ,USER_ID
    ,SERVICE_ID
    ,STATE
)
SELECT DISTINCT
   '22'                                                                AS TENANT_ID
   ,CONCAT (HOST_SOC_SOC_SEQ_NO, FEATURE_SEQ_NO, A.SERVICE_ID)         AS PROD_SRV_RELAT_ID
   ,CONCAT(TARS_SOC_SOC_SEQ_NO,M.RELAT_OFFER_ID)                       AS OFFER_INST_ID
   ,concat(VERIS_OBJECT_ID,TARS_SOC_CTN,TARS_SOC_SOC_SEQ_NO)           AS PROD_INST_ID
   ,HOST_SOC_CTN                                                       AS USER_ID
   ,A.SERVICE_ID                                                       AS SERVICE_ID
   ,'1'                                                                AS STATE

FROM LEGACY.WRK_DATASHARE D
INNER JOIN LEGACY.M_IDID_OFFER_MOD M
   ON D.Tgt_Offer_Cd = M.Tgt_Offer_Cd AND M.Tgt_Offer_CD LIKE 'ADSPLIT%'
INNER JOIN (SELECT DISTINCT Product_Id, SERVICE_ID FROM LEGACY.M_IDID_ATTR_MOD) A
   ON M.VERIS_OBJECT_ID = A.Product_Id
WHERE   M.VERIS_OBJECT_ID IN ('800039', '20010005')
    AND A.SERVICE_ID IS NOT NULL
;

    
    
--    INS_SRV_ATTR tabla toltese 
-- MAX ID lekerdezes
SET @rownum := (SELECT max(cast(SUBSTR(ATTR_INST_ID, 10) as UNSIGNED)) FROM MDM.INS_SRV_ATTR);

-- masodlagos kartya telefonszáma
INSERT INTO MDM.INS_SRV_ATTR
(
     TENANT_ID
    ,ATTR_INST_ID
    ,PROD_SRV_RELAT_ID
    ,OFFER_INST_ID
    ,USER_ID
    ,SERVICE_ID
    ,ATTR_ID
    ,ATTR_VALUE
    ,ATTR_TEXT
    ,STATE
    ,SORT_ID
    ,ATTR_BATCH
    ,EFFECTIVE_DATE
    ,EXPIRE_DATE
)
SELECT DISTINCT
   '22'                                                    AS TENANT_ID
   , CONCAT(@BASE, @rownum := @rownum + 1)                 AS ATTR_INST_ID
   , S.PROD_SRV_RELAT_ID                                   AS PROD_SRV_RELAT_ID
   , S.OFFER_INST_ID                                       AS OFFER_INST_ID
   , S.USER_ID                                             AS USER_ID
   , S.SERVICE_ID                                          AS SERVICE_ID
   , '2300010'                                             AS ATTR_ID
   , D.TARS_SOC_CTN                                        AS ATTR_VALUE
   , D.TARS_SOC_CTN                                        AS ATTR_TEXT
   , S.STATE                                               AS STATE
   , '99'                                                  AS SORT_ID
   , 'null'                                                AS ATTR_BATCH
    , CASE WHEN D.FEATURE_EFFECTIVE_DATE IS NULL THEN @EFF_DT
        WHEN D.FEATURE_EFFECTIVE_DATE > D.FEATURE_EFFECTIVE_DATE THEN D.FEATURE_EFFECTIVE_DATE
      ELSE D.FEATURE_EFFECTIVE_DATE END                    AS EFFECTIVE_DATE
    , CASE WHEN D.FEATURE_EXPIRATION_DATE IS NULL THEN @EXP_DT
         WHEN D.FEATURE_EXPIRATION_DATE > @EXP_DT THEN @EXP_DT
          ELSE D.FEATURE_EXPIRATION_DATE END               AS EXPIRE_DATE
FROM 
            LEGACY.WRK_DATASHARE D
                INNER JOIN MDM.INS_PROD_INS_SRV S
            ON S.USER_ID = D.HOST_SOC_CTN

WHERE S.SERVICE_ID IN ('880039', '20010005')
;


-- masodlagos kartya IMSI-je
INSERT INTO MDM.INS_SRV_ATTR
(
     TENANT_ID
    ,ATTR_INST_ID
    ,PROD_SRV_RELAT_ID
    ,OFFER_INST_ID
    ,USER_ID
    ,SERVICE_ID
    ,ATTR_ID
    ,ATTR_VALUE
    ,ATTR_TEXT
    ,STATE
    ,SORT_ID
    ,ATTR_BATCH
    ,EFFECTIVE_DATE
    ,EXPIRE_DATE
)
SELECT DISTINCT
   '22'                                                  AS TENANT_ID
   , CONCAT(@BASE, @rownum := @rownum + 1)               AS ATTR_INST_ID
   , S.PROD_SRV_RELAT_ID                                 AS PROD_SRV_RELAT_ID
   , S.OFFER_INST_ID                                     AS OFFER_INST_ID
   , S.USER_ID                                           AS USER_ID
   , S.SERVICE_ID                                        AS SERVICE_ID
   , '2300011'                                           AS ATTR_ID
   , D.TARS_USER_IMSI                                    AS ATTR_VALUE
   , D.TARS_USER_IMSI                                    AS ATTR_TEXT
   , S.STATE                                             AS STATE
   , '99'                                                AS SORT_ID
   , 'null'                                              AS ATTR_BATCH
    , CASE WHEN D.FEATURE_EFFECTIVE_DATE IS NULL THEN @EFF_DT
        WHEN D.FEATURE_EFFECTIVE_DATE > D.FEATURE_EFFECTIVE_DATE THEN D.FEATURE_EFFECTIVE_DATE
      ELSE D.FEATURE_EFFECTIVE_DATE END                  AS EFFECTIVE_DATE
    , CASE WHEN D.FEATURE_EXPIRATION_DATE IS NULL THEN @EXP_DT
         WHEN D.FEATURE_EXPIRATION_DATE > @EXP_DT THEN @EXP_DT
          ELSE D.FEATURE_EXPIRATION_DATE END             AS EXPIRE_DATE
FROM 
            LEGACY.WRK_DATASHARE D
                INNER JOIN MDM.INS_PROD_INS_SRV S
            ON S.USER_ID = D.HOST_SOC_CTN
WHERE S.SERVICE_ID IN ('880039', '20010005')
;