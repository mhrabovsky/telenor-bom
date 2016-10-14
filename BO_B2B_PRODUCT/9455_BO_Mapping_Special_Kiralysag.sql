USE LEGACY;

/*

MT: A3ONNET offer specialitasainak felpakolasa
A normal folyamat ezt az offert felrakja, es megallapitja, mi hozza a PROD.
A PROD ala SRV est ATTR is felteendo, ami feature-bol jon, tartalma 3 db telefonszam.
Felrakando az A3ONNET50MB addon is, ami egy leforgalmazhato 50MB-os internet.

*/

-- NAS 10.11 beegetesek bovitese
SET @EFF_DT = CAST(LEGACY.CONFIG('DEF_EFF_DATE',NULL) AS DATETIME);
SET @EXP_DT = CAST(LEGACY.CONFIG('DEF_EXP_DATE',NULL) AS DATETIME);
SET @SYS_DATE = CAST(LEGACY.CONFIG('SYS_DATE',NULL) AS DATETIME);

set @i=0;


-- Ujrafelhasznaljuk a 6011-ben letrejott tablankat:
insert into LEGACY.M_A3ONNET_SRV
select
  CASE
    WHEN F.FTR_EFFECTIVE_DATE > @EXP_DT THEN @EFF_DT
    ELSE COALESCE(F.FTR_EFFECTIVE_DATE, @EFF_DT)
    END            AS EFFECTIVE_DATE,
  CASE 
    WHEN F.FTR_EXPIRATION_DATE > @EXP_DT THEN @EXP_DT
    ELSE COALESCE(F.FTR_EXPIRATION_DATE, @EXP_DT)
    END            AS EXPIRATION_DATE,
  replace(replace(replace(replace(F.txt_to_split,'@',','),'NR1=',''),'NR2=',''),'NR3=','') TEL,
  '31000281'  SERVICE_ID,
  '10201'     SERVICE_ATTR_ID,
  concat('A3ON50_',(@i=@i+1)) PROD_SRV_RELAT_ID,
  P.OFFER_INST_ID,
  null OFFER_USER_RELAT_ID,
  P.PROD_INST_ID,
  P.USER_ID,
  null OFFER_ID,
  null CUST_ID,
  null CUST_TYPE
from M_FEATURE_USED PARTITION (pSA) F
join MDM.INS_PROD   P
  on P.PROD_ID='1000281'
  and P.USER_ID=F.Sub_Id
where F.add_or_swi = 'A'
  and F.SOC_CD='FNFNR'
  -- and F.txt_to_split!='NR1=000000000@NR2=000000000@NR3=000000000' -- ureset is migralunk, '' ertekkel.
;





INSERT INTO MDM.INS_PROD_INS_SRV (
  TENANT_ID,
  PROD_SRV_RELAT_ID,
  OFFER_INST_ID,
  PROD_INST_ID,
  USER_ID,
  SERVICE_ID,
  STATE
)
SELECT DISTINCT
  22,
  PROD_SRV_RELAT_ID,
  OFFER_INST_ID,
  PROD_INST_ID,
  USER_ID,
  SERVICE_ID,
  1 DEFAULT_STATE
FROM M_A3ONNET_SRV
where SERVICE_ID is not null
;

INSERT INTO MDM.INS_SRV_ATTR (
  TENANT_ID            ,
  ATTR_INST_ID         ,
  PROD_SRV_RELAT_ID    ,
  OFFER_INST_ID        ,
  USER_ID              ,
  SERVICE_ID           ,
  ATTR_ID              ,
  ATTR_VALUE           ,
  ATTR_TEXT            ,
  STATE                ,
  SORT_ID              ,
  ATTR_BATCH           ,
  EFFECTIVE_DATE       ,
  EXPIRE_DATE
)
SELECT
  22       TENANT_ID ,
  concat(PROD_SRV_RELAT_ID,'_',N.N) ATTR_INST_ID,
  PROD_SRV_RELAT_ID  ,
  OFFER_INST_ID      ,
  USER_ID            ,
  SERVICE_ID         ,
  SERVICE_ATTR_ID    ,
  substring_index(substring_index(TEL,',',N.N),',',-1) ATTR_VALUE,
  substring_index(substring_index(TEL,',',N.N),',',-1) ATTR_TEXT,
  CASE
    WHEN EXPIRATION_DATE < @SYS_DATE THEN '7'
    WHEN EFFECTIVE_DATE  > @SYS_DATE THEN '7'
    ELSE '1'
    END STATE,
  null               , -- legacy.sort_id
  null               ,
  EFFECTIVE_DATE,
  EXPIRATION_DATE
FROM  M_A3ONNET_SRV
CROSS JOIN  (select 1 N UNION ALL select 2 N UNION ALL select 3 N) N
WHERE substring_index(substring_index(TEL,',',N.N),',',-1)+0 > 0
   OR N.N=1
  and SERVICE_ID is not null
  and SERVICE_ATTR_ID is not null
;


