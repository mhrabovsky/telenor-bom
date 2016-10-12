-- 6011_BO_Mapping_Special_Offers.sql

/*

Ebben a fajlban tobb specialis offert allitunk elo. Jelenlegi tartalom:
1. Kiralysag (3 barati 20-as)
2. Special mapping of features to offers

*/

-- NAS 10.04 beégetések bõvítése
SET @EFF_DT = CAST(LEGACY.CONFIG('DEF_EFF_DATE',NULL) AS DATETIME);
SET @EXP_DT = CAST(LEGACY.CONFIG('DEF_EXP_DATE',NULL) AS DATETIME);
-- NAS 10.07 beégetések bõvítése
SET @CUST_TYPE_B2B = LEGACY.CONFIG('CUST_TYPE_B2B',NULL);
SET @OFFER_ID_A3ONNET = LEGACY.CONFIG('OFFER_ID_A3ONNET',NULL);

-- USE LEGACY;



/*

1. Kiralysag (3 barati 20-as)

MT: A3ONNET offer specialitasainak felpakolasa
A normal folyamat az A3ONNET offert felrakja, es megallapitja, mi hozza a PROD.
A PROD ala SRV est ATTR is felteendo, ami feature-bol jon, tartalma 3 db telefonszam.
Ez utobbit a PRODUCT szakaszban tesszuk.

ITT: Felrakando az A3ONNET50MB addon is, ami egy leforgalmazhato 50MB-os internet.

*/


drop table if exists LEGACY.M_A3ONNET_SRV;
set @i=0;
-- A tablank offer-prod-srv granularitasu es ezen kivul feature-param szerkezetu.
-- Tehat az attr sorokat tobbszorozve kell beszurni, a tobbi egy-egy alapon.
create table LEGACY.M_A3ONNET_SRV
(
  EFFECTIVE_DATE         datetime,
  EXPIRATION_DATE        datetime,
  TEL                    varchar(50),
  SERVICE_ID             varchar(30),
  SERVICE_ATTR_ID        varchar(30),
  PROD_SRV_RELAT_ID      varchar(30),
  OFFER_INST_ID          varchar(30),
  OFFER_USER_RELAT_ID    varchar(50),
  PROD_INST_ID           varchar(30),
  USER_ID                varchar(30),
  OFFER_ID               varchar(30),
  CUST_ID                varchar(30),
  CUST_TYPE              char(1)
);


insert into LEGACY.M_A3ONNET_SRV
select
  CASE
    WHEN TBL24.SDATE > @EXP_DT THEN @EFF_DT
    ELSE COALESCE(TBL24.SDATE,@EFF_DT)
    END            AS EFFECTIVE_DATE,
  CASE 
    WHEN TBL24.EDATE > @EXP_DT THEN @EXP_DT
    ELSE COALESCE(TBL24.EDATE,@EXP_DT)
    END            AS EXPIRATION_DATE,
  '' TEL,
  null SERVICE_ID,
  null SERVICE_ATTR_ID,
  null PROD_SRV_RELAT_ID,
  concat('A3ONNET_',(@i=@i+1)) OFFER_INST_ID,
  concat('A3ONNET_',(@i)) OFFER_USER_RELAT_ID,
  null PROD_INST_ID,
--  TBL24.A USER_ID,
  U.USER_ID,
  @OFFER_ID_A3ONNET OFFER_ID,
  U.CUST_ID,
  U.CUST_TYPE
from LEGACY.TBL41
join LEGACY.TBL24 on TBL24.A=TBL41.A
-- join MDM.INS_USER U on U.USER_ID=TBL24.A
join MDM.INS_USER U on U.BILL_ID=TBL24.A -- hianyzik a BAN,BEN; masreszt 6020_INSER_INS_USER elott fut
where TBL41.SPS like '%A01%'
  and COUNTID = 'CA3'
;

insert into MDM.INS_OFFER (
  TENANT_ID,
  OFFER_INST_ID,
  CUST_ID,
  CUST_TYPE,
  USER_ID,
  OFFER_ID,
  OFFER_TYPE,
  BRAND_ID,
  ORDER_NAME,
  STATE,
  EFFECTIVE_DATE,
  EXPIRE_DATE,
  SALE_TYPE,
  DONE_CODE,
  EXPIRE_PROCESS_TYPE,
  CHANNEL_TYPE,
  OS_STATE
)
select distinct
  '22',
  OFFER_INST_ID,
  CUST_ID,
  CUST_TYPE,
  USER_ID,
  OFFER_ID,
  'OFFER_VAS_CBOSS' OFFER_TYPE,
  '0'               BRAND_ID,
  'A3ONNET50MB'     ORDER_NAME,
  CASE
    WHEN EXPIRATION_DATE < SYSDATE() THEN '7'
    WHEN EFFECTIVE_DATE  > SYSDATE() THEN '7'
    ELSE '1'
    END STATE,
  EFFECTIVE_DATE,
  EXPIRATION_DATE,
  '0'       SALE_TYPE,
  null      DONE_CODE,
  '0'       EXPIRE_PROCESS_TYPE,
  '99999'   CHANNEL_TYPE,
  '1'       OS_STATE
FROM  LEGACY.M_A3ONNET_SRV
WHERE OFFER_ID>0
;


INSERT INTO MDM.INS_OFF_INS_USER
(
  TENANT_ID            ,
  OFFER_USER_RELAT_ID  ,
  OFFER_INST_ID        ,
  USER_ID              ,
  OFFER_ID             ,
  ROLE_ID              ,
  IS_MAIN_OFFER        ,
  IS_GRP_MAIN_USER     ,
  DONE_CODE            ,
  STATE                ,
  CREATE_DATE          ,
  DONE_DATE            ,
  EFFECTIVE_DATE       ,
  EXPIRE_DATE
)
SELECT DISTINCT
  '22'                        ,
  OFFER_USER_RELAT_ID         ,
  OFFER_INST_ID               ,
  USER_ID                     ,
  OFFER_ID                    ,
  '181000000001'              ,
  1                           ,
  0                           ,
  NULL              DONE_CODE ,
  CASE
    WHEN EXPIRATION_DATE < SYSDATE() THEN '7'
    WHEN EFFECTIVE_DATE  > SYSDATE() THEN '7'
    ELSE '1'
    END STATE,
  EFFECTIVE_DATE CREATE_DATE,
  EXPIRATION_DATE DONE_DATE,
  EFFECTIVE_DATE,
  EXPIRATION_DATE
FROM  LEGACY.M_A3ONNET_SRV
WHERE OFFER_ID>0
;


/*

2. Special mapping of features to offers

Special FEATURES mapping: Offer szakasz
Itt rakjuk fel a "special mapping rules" tema 7 db "capability" SOC-jabol jovo offereit, aminek logikajahoz a FEATURE tablabol is veszunk ertekeket.

*/



-- USE LEGACY;


/*

MT.2016-09-06

Here, special mappig rules for some SOC-s and features are handled. The below tasks are carried out:
  1. Preparation of feature data.
  2. Load special mapping table.
  3. Create offers.
  (4. Collect info for creatig product-service-attribute records in a later part of the code.)
  Point 4 is possibly not essential, because the normal operation of product creation is already using the FEATURE_EXT table.

*/

call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M01_TARIFF','CTN,BAN,BEN');


-- Very special case: A USER field must be added as a feature param in case of NRPC SOC.
SET SQL_SAFE_UPDATES = 0;
update LEGACY.M_FEATURE_EXTR_SL f
-- join M_USER u ON f.CTN=u.CTN
join LEGACY.M_USER u ON f.Sub_Id=u.Sub_Id
set f.txt_to_split=concat(f.txt_to_split,'@MGEN_NRPC_VALIDITY=',coalesce(u.SUBSCRIBER_REF,''))
where f.add_or_swi='A' and f.SOC_Cd='NRPC' and f.Feature_CODE='NRPC' and f.txt_to_split not like '%MGEN_NRPC_VALIDITY%'
;
update LEGACY.M_FEATURE_EXTR_SL f
-- join M_USER u ON f.CTN=u.CTN
join LEGACY.M_USER u ON f.Sub_Id=u.Sub_Id
join LEGACY.M_USER ua ON trim(substring( txt_to_split, INSTR(txt_to_split,'SECCTN=') + 7 ,9))  = ua.CTN
set f.txt_to_split=concat(f.txt_to_split,'@MGEN_IMSI=',coalesce(ua.IMSI,''))
where f.add_or_swi='A' and f.SOC_Cd='AUTPARN01' and f.Feature_CODE='CARPAR' and f.txt_to_split like '%SECCTN%'
;

-- SET SQL_SAFE_UPDATES = 1;



/*

-- Locating the features in scope:
SELECT
  count(*)            ,
  add_or_swi          ,
  SOC_Cd              ,
  FEATURE_CODE        ,
  txt_to_split
FROM LEGACY.M_FEATURE_EXTR_SL F
WHERE F.SOC_CD in (
'EDSZ', 'I10-MF20', 'I10-MF30', 'I10-MF40', 'I20-MF50', 'I20-MF60', 'I20-MF70', 'I30-MF80', 'I30-MF90', 'I5-MFCONS', 'I50-MF100', 'I50-MF200', 'I50-MF300', 'I50-MF400', 'I50-MF500', 'I50-MF600', 'I50-MF700', 'I50-MF800', 'MF100', 'MF20', 'MF200', 'MF30', 'MF300', 'MF40', 'MF400', 'MF50', 'MF500', 'MF60', 'MF600', 'MF70', 'MF700', 'MF80', 'MF800', 'MF90', 'MFCONS', 'MTSMSALL', 'MVTILTAS', 'NETROFLE', 'NETROFLEK', 'NETROFNO', 'NRPC', 'POSTVM'
)
group by 2,3,4,5;


+----------+------------+----------+--------------+----------------------------------------------+
| count(*) | add_or_swi | SOC_Cd   | FEATURE_CODE | txt_to_split                                 |
+----------+------------+----------+--------------+----------------------------------------------+
|       30 | A          | EDSZ     | EDSZ         | ADCONS=N@ADWEBS=N                            |
|     3529 | A          | EDSZ     | EDSZ         | ADCONS=N@ADWEBS=N@ESMSPL=N@EVOICE=N          |
|        1 | A          | EDSZ     | EDSZ         | ADCONS=N@ADWEBS=N@ESMSPL=N@EVOICE=N@ESMSPS=Y |
|     1109 | A          | EDSZ     | EDSZ         | ADCONS=N@ADWEBS=N@ESMSPL=N@EVOICE=Y          |
|        1 | A          | EDSZ     | EDSZ         | ADCONS=N@ADWEBS=N@ESMSPL=N@EVOICE=Y@EVOICE=Y |
|     1521 | A          | EDSZ     | EDSZ         | ADCONS=N@ADWEBS=N@ESMSPL=Y@EVOICE=N          |
|        1 | A          | EDSZ     | EDSZ         | ADCONS=N@ADWEBS=N@ESMSPL=Y@EVOICE=N@EVOICE=Y |
|   228553 | A          | EDSZ     | EDSZ         | ADCONS=N@ADWEBS=N@ESMSPL=Y@EVOICE=Y          |
|       30 | A          | EDSZ     | EDSZ         | ADCONS=N@ADWEBS=Y@ESMSPL=N@EVOICE=N          |
|       39 | A          | EDSZ     | EDSZ         | ADCONS=N@ADWEBS=Y@ESMSPL=N@EVOICE=Y          |
|        2 | A          | EDSZ     | EDSZ         | ADCONS=N@ADWEBS=Y@ESMSPL=Y@EVOICE=N          |
|     1124 | A          | EDSZ     | EDSZ         | ADCONS=N@ADWEBS=Y@ESMSPL=Y@EVOICE=Y          |
|      658 | A          | EDSZ     | EDSZ         | ADCONS=Y@ADWEBS=N@ESMSPL=N@EVOICE=N          |
|      426 | A          | EDSZ     | EDSZ         | ADCONS=Y@ADWEBS=N@ESMSPL=N@EVOICE=Y          |
|        1 | A          | EDSZ     | EDSZ         | ADCONS=Y@ADWEBS=N@ESMSPL=N@EVOICE=Y@ESMSPS=N |
|      566 | A          | EDSZ     | EDSZ         | ADCONS=Y@ADWEBS=N@ESMSPL=Y@EVOICE=N          |
|    13560 | A          | EDSZ     | EDSZ         | ADCONS=Y@ADWEBS=N@ESMSPL=Y@EVOICE=Y          |
|      713 | A          | EDSZ     | EDSZ         | ADCONS=Y@ADWEBS=Y@ESMSPL=N@EVOICE=N          |
|      175 | A          | EDSZ     | EDSZ         | ADCONS=Y@ADWEBS=Y@ESMSPL=N@EVOICE=Y          |
|       46 | A          | EDSZ     | EDSZ         | ADCONS=Y@ADWEBS=Y@ESMSPL=Y@EVOICE=N          |
|    38633 | A          | EDSZ     | EDSZ         | ADCONS=Y@ADWEBS=Y@ESMSPL=Y@EVOICE=Y          |
|        1 | A          | EDSZ     | EDSZ         | ADCONS=Y@ADWEBS=Y@ESMSPL=Y@EVOICE=Y@EVOICE=Y |
|     1587 | A          | EDSZ     | EDSZ         | ESMSPL=N@EVOICE=N@ADCONS=N@ADWEBS=N          |
|        1 | A          | EDSZ     | EDSZ         | ESMSPL=N@EVOICE=N@ADCONS=N@ADWEBS=Y          |
|      158 | A          | EDSZ     | EDSZ         | ESMSPL=N@EVOICE=N@ADCONS=Y@ADWEBS=N          |
|        7 | A          | EDSZ     | EDSZ         | ESMSPL=N@EVOICE=N@ADCONS=Y@ADWEBS=Y          |
|      204 | A          | EDSZ     | EDSZ         | ESMSPL=N@EVOICE=Y@ADCONS=N@ADWEBS=N          |
|        4 | A          | EDSZ     | EDSZ         | ESMSPL=N@EVOICE=Y@ADCONS=N@ADWEBS=Y          |
|      230 | A          | EDSZ     | EDSZ         | ESMSPL=N@EVOICE=Y@ADCONS=Y@ADWEBS=N          |
|        3 | A          | EDSZ     | EDSZ         | ESMSPL=N@EVOICE=Y@ADCONS=Y@ADWEBS=Y          |
|      341 | A          | EDSZ     | EDSZ         | ESMSPL=Y@EVOICE=N@ADCONS=N@ADWEBS=N          |
|        1 | A          | EDSZ     | EDSZ         | ESMSPL=Y@EVOICE=N@ADCONS=N@ADWEBS=Y          |
|        7 | A          | EDSZ     | EDSZ         | ESMSPL=Y@EVOICE=N@ADCONS=Y@ADWEBS=N          |
|        1 | A          | EDSZ     | EDSZ         | ESMSPL=Y@EVOICE=N@ADCONS=Y@ADWEBS=Y          |
|    35109 | A          | EDSZ     | EDSZ         | ESMSPL=Y@EVOICE=Y@ADCONS=N@ADWEBS=N          |
|       69 | A          | EDSZ     | EDSZ         | ESMSPL=Y@EVOICE=Y@ADCONS=N@ADWEBS=Y          |
|     2615 | A          | EDSZ     | EDSZ         | ESMSPL=Y@EVOICE=Y@ADCONS=Y@ADWEBS=N          |
|     8070 | A          | EDSZ     | EDSZ         | ESMSPL=Y@EVOICE=Y@ADCONS=Y@ADWEBS=Y          |
|        7 | A          | EDSZ     | EDSZ         | EVOICE=Y                                     |
|       73 | A          | NRPC     | NRPC         | NRPC_TYPE=T01@NRPC_FUNC=F1@NRPC_COST=C2      |
|      634 | A          | NRPC     | NRPC         | NRPC_TYPE=T01@NRPC_FUNC=F2@NRPC_COST=C2      |
|       44 | A          | NRPC     | NRPC         | NRPC_TYPE=T01@NRPC_FUNC=F6@NRPC_COST=C2      |
|      950 | A          | NRPC     | NRPC         | NRPC_TYPE=T01@NRPC_FUNC=F7@NRPC_COST=C2      |
|        1 | A          | NRPC     | NRPC         | NRPC_TYPE=T02@NRPC_FUNC=F2@NRPC_COST=C2      |
|        2 | A          | NRPC     | NRPC         | NRPC_TYPE=T02@NRPC_FUNC=F6@NRPC_COST=C2      |
|        2 | A          | NRPC     | NRPC         | NRPC_TYPE=T02@NRPC_FUNC=F7@NRPC_COST=C2      |
|     1278 | A          | NRPC     | NRPC         | NRPC_TYPE=T04@NRPC_FUNC=F6@NRPC_COST=C2      |
|     1374 | A          | NRPC     | NRPC         | NRPC_TYPE=T05@NRPC_FUNC=F6@NRPC_COST=C2      |
|       56 | A          | NRPC     | NRPC         | NRPC_TYPE=T06@NRPC_FUNC=F1@NRPC_COST=C2      |
|      662 | A          | NRPC     | NRPC         | NRPC_TYPE=T06@NRPC_FUNC=F2@NRPC_COST=C2      |
|        2 | A          | NRPC     | NRPC         | NRPC_TYPE=T06@NRPC_FUNC=F6@NRPC_COST=C2      |
|     5163 | A          | NRPC     | NRPC         | NRPC_TYPE=T06@NRPC_FUNC=F7@NRPC_COST=C2      |
|        4 | A          | NRPC     | NRPC         | NRPC_TYPE=T07@NRPC_FUNC=F7@NRPC_COST=C2      |
|     3080 | A          | NRPC     | NRPC         | NRPC_TYPE=T09@NRPC_FUNC=F3@NRPC_COST=C2      |
|       12 | A          | NRPC     | NRPC         | NRPC_TYPE=T10@NRPC_FUNC=F7@NRPC_COST=C2      |
|       32 | A          | NRPC     | NRPC         | NRPC_TYPE=T12@NRPC_FUNC=F5@NRPC_COST=C2      |
|       81 | A          | NRPC     | NRPC         | NRPC_TYPE=T12@NRPC_FUNC=F7@NRPC_COST=C2      |
|        6 | A          | NRPC     | NRPC         | NRPC_TYPE=T14@NRPC_FUNC=F7@NRPC_COST=C2      |
|        7 | A          | NRPC     | NRPC         | NRPC_TYPE=T15@NRPC_FUNC=F2@NRPC_COST=C2      |
|      448 | A          | NRPC     | NRPC         | NRPC_TYPE=T15@NRPC_FUNC=F7@NRPC_COST=C2      |
|        3 | A          | NRPC     | NRPC         | NRPC_TYPE=T16@NRPC_FUNC=F1@NRPC_COST=C1      |
|        4 | A          | NRPC     | NRPC         | NRPC_TYPE=T16@NRPC_FUNC=F1@NRPC_COST=C2      |
|       23 | A          | NRPC     | NRPC         | NRPC_TYPE=T16@NRPC_FUNC=F2@NRPC_COST=C1      |
|      140 | A          | NRPC     | NRPC         | NRPC_TYPE=T16@NRPC_FUNC=F2@NRPC_COST=C2      |
|       22 | A          | NRPC     | NRPC         | NRPC_TYPE=T16@NRPC_FUNC=F6@NRPC_COST=C2      |
|       30 | A          | NRPC     | NRPC         | NRPC_TYPE=T16@NRPC_FUNC=F7@NRPC_COST=C2      |
|        2 | A          | NRPC     | NRPC         | NRPC_TYPE=T17@NRPC_FUNC=F7@NRPC_COST=C2      |
|        9 | A          | NRPC     | NRPC         | NRPC_TYPE=T18@NRPC_FUNC=F1@NRPC_COST=C1      |
|        1 | A          | POSTVM   | VMPBSC       | LANG=E                                       |
|     3091 | A          | POSTVM   | VMPBSC       | LANG=H                                       |
|        7 | S          | I10-MF20 | I10M20       | ELOLEG=38100                                 |
|        1 | S          | I20-MF50 | I20M50       | ELOLEG=88900                                 |
|       83 | S          | MF100    | MF100        | ELOLEG=127000                                |
|    98582 | S          | MF20     | MF20         | ELOLEG=25400                                 |
|       60 | S          | MF200    | MF200        | ELOLEG=254000                                |
|    58962 | S          | MF30     | MF30         | ELOLEG=38100                                 |
|        8 | S          | MF300    | MF300        | ELOLEG=381000                                |
|     2500 | S          | MF40     | MF40         | ELOLEG=50800                                 |
|        2 | S          | MF400    | MF400        | ELOLEG=508000                                |
|      581 | S          | MF50     | MF50         | ELOLEG=63500                                 |
|        3 | S          | MF500    | MF500        | ELOLEG=635000                                |
|      331 | S          | MF60     | MF60         | ELOLEG=76200                                 |
|      159 | S          | MF70     | MF70         | ELOLEG=88900                                 |
|      111 | S          | MF80     | MF80         | ELOLEG=101600                                |
|        4 | S          | MF800    | MF800        | ELOLEG=1016000                               |
|       56 | S          | MF90     | MF90         | ELOLEG=114300                                |
|     1572 | S          | MVTILTAS | MVTIL1       | SERVICECATEGORY=TRANS                        |
|     1929 | S          | MVTILTAS | MVTIL2       | SERVICECATEGORY=GOODS                        |
|     1931 | S          | MVTILTAS | MVTIL3       | SERVICECATEGORY=NEWS                         |
|     2431 | S          | MVTILTAS | MVTIL4       | SERVICECATEGORY=BOOKS                        |
|     2526 | S          | MVTILTAS | MVTIL5       | SERVICECATEGORY=ENTER                        |
|     3110 | S          | POSTVM   | VMPBSC       | COS=BASIC@TK=M@OCCF=Y                        |
+----------+------------+----------+--------------+----------------------------------------------+
92 rows in set (8,36 sec)


*/



/*

Mukodes:
A: Felhozom az osszes tarifat, osszes erintett feature-t, es megszurom a special mapping tabla szabalyai szerint, es megjelolom minden sorban, hogy kell-e az az offer. Ezzel pozitiv logikaju tablat kapok, es ez lesz az addon offer, a product/service/attribute sorok generalasanak vezerloje. Az ide sorolt FEATURE sorokat ki kell venni az altalanos logikabol (torolni az M_FEATURE_EXTR_SL tablabol).

*Ezt a tablat lehet azonos alakura hozni az M_FEATURE_EXTR_SL tablaval, es ujabb particiokent be is cserelhetem, beillesztve az altalanos logikaba.

*/

/*
-- Az M_SOC tablaban elvileg minden SOC peldanynak benne kell lennie, ami az M_FEATURE_EXTR_SL tablaban van.
-- Ha leszukitem erintett SOC-okra M_SPECIAL_MAP szerint, akkor:
-- M_SOC:          22M sorbol marad 580530 sor.
-- M_FEATURE_EXTR_SL: 11M sorbol marad 531771 sor.
-- Ezeket outer joinnal egyetlen temptablaba egyesitem, kozben formazom az adatokat. Ezt indexelem.
-- A temptablanak lesz 587982 sora (56211 tobbszorozes), de csak 531771-ben van feature.
*/

drop table if exists LEGACY.SPEC_FEA;

create table LEGACY.SPEC_FEA as
select distinct S.*,
  coalesce(trim(F.FEATURE_CODE),'') FEATURE_CODE,
  coalesce(trim(F.SERVICE_FTR_SEQ_NO),'') SERVICE_FTR_SEQ_NO,
  coalesce(trim(F.add_or_swi),'') add_or_swi,
  coalesce(trim(F.txt_to_split),'') txt_to_split
from (select distinct SOC from LEGACY.M_SPECIAL_MAP) M
straight_join LEGACY.M_SOC S on M.SOC=S.SOC_CD
-- left outer join SPEC_FEA_TMP F
left outer join LEGACY.M_FEATURE_EXTR_SL F
on F.SOC_Seq_No = concat(S.SOC_Seq_No,'') -- kulonbozik az adattipusuk.
;



/*
Query OK, 587982 rows affected (19.09 sec)
Records: 587982  Duplicates: 0  Warnings: 0

mysql> select count(*), count(soc_cd), count(distinct soc_cd), count(distinct soc_seq_no), count(FEATURE_CODE) from SPEC_FEA;
+----------+---------------+------------------------+----------------------------+---------------------+
| count(*) | count(soc_cd) | count(distinct soc_cd) | count(distinct soc_seq_no) | count(FEATURE_CODE) |
+----------+---------------+------------------------+----------------------------+---------------------+
|   587982 |        587982 |                     27 |                     580530 |              531771 |
+----------+---------------+------------------------+----------------------------+---------------------+
1 row in set (1.69 sec)

*/



/*

Ez a fuggveny adja vissza a parameter erteket:

*/

drop function if exists LEGACY.F_FEA_PAR_VAL_GET;
delimiter $$
create function LEGACY.F_FEA_PAR_VAL_GET
(
  txt_to_split varchar(400),
  FTR_PAR_NM   varchar(30)
)
RETURNS VARCHAR(400)
DETERMINISTIC
BEGIN
  declare szakasz varchar(1000);
  declare tol int;
  declare ig int;
  set tol=instr(concat('@',txt_to_split),concat('@',FTR_PAR_NM))+length(FTR_PAR_NM)+2;
  set szakasz=substr(concat('@',txt_to_split),tol);
  set ig=instr(szakasz,'@');
  if (ig=0) then
    return szakasz;
  end if;
  set szakasz=substr(szakasz,1,ig-1);
  return szakasz;
END;
$$
delimiter ;

-- create index SPEC_FEA_CTN_SOC_FEA on SPEC_FEA (CTN,SOC_CD,FEATURE_CODE);
-- call LEGACY.createindex_ifnotexists('LEGACY','SPEC_FEA','CTN,SOC_CD,FEATURE_CODE');
call LEGACY.createindex_ifnotexists('LEGACY','SPEC_FEA','SUB_ID,SOC_CD,FEATURE_CODE');


drop table if exists LEGACY.M_SPECIAL_ADDONS;
create table LEGACY.M_SPECIAL_ADDONS (
  add_or_swi          char(1)     ,
  BAN                 varchar(10) ,
  BEN                 varchar(5)  ,
  CTN                 varchar(11) ,
  SUB_ID              varchar(30) ,
  SOC_Cd              char(9)     ,
  FEATURE_CODE        varchar(6)  ,
  txt_to_split        varchar(400),
  -- pozitiv logika szerint, ahol van ertek, ott letrehozni:
  FTR_PAR_NM          varchar(30) ,
  FTR_PAR_VAL         varchar(30) ,
  SUB_TYPE            char(3)     ,
  VBI                 varchar(30) ,
  MAIN_OFFER_CD       varchar(30) ,
  TGT_OFFER_CD        varchar(30) ,
  TGT_OFFER_ID        varchar(30) ,
  PROD_ID             varchar(30) ,
  SRV_ID              varchar(30) ,
  ATTR_ID             varchar(30) ,
  ATTR_VALUE          varchar(30) ,
  EFFECTIVE_DATE      datetime    ,
  EXPIRATION_DATE     datetime    ,
  SER_NR              varchar(30) default '0',
  USE_FLAG            char(1)     default 'Y'
) engine=MyIsam
;



-- CTN-re van mar index, ezert ez felesleges idohuzas:
-- create index I_FEATURE_EXTR_CTN_SOC on M_FEATURE_EXTR_SL (CTN,SOC_CD,FEATURE_CODE);


SET @SER_NR = (select coalesce(max(cast(right(OFFER_INST_ID,10) as UNSIGNED)),0)+1 from MDM.INS_OFFER );


/*

Osszegyujtom a felrakando es a torlendo addonokat. Ezeket a legvegen distinct-alni kell, mert duplazodhat.

*/

truncate table LEGACY.M_SPECIAL_ADDONS;


-- 1. Pozitiv logikaju insert-ek:

insert into LEGACY.M_SPECIAL_ADDONS (
  add_or_swi         ,
  BAN                ,
  BEN                ,
  CTN                ,
  SUB_ID             ,
  SOC_Cd             ,
  FEATURE_CODE       ,
  txt_to_split       ,
  FTR_PAR_NM         ,
  FTR_PAR_VAL        ,
  SUB_TYPE           ,
  VBI                ,
  MAIN_OFFER_CD      ,
  TGT_OFFER_CD       ,
  TGT_OFFER_ID       ,
  PROD_ID            ,
  SRV_ID             ,
  ATTR_ID            ,
  ATTR_VALUE         ,
  EFFECTIVE_DATE     ,
  EXPIRATION_DATE    ,
  SER_NR             ,
  USE_FLAG
)
SELECT
  F.add_or_swi         ,
  F.BAN                ,
  F.BEN                ,
  F.CTN                ,
  F.SUB_ID             ,
  coalesce(trim(F.SOC_Cd),'')             ,
  coalesce(trim(F.FEATURE_CODE),'')       ,
  F.txt_to_split       ,
  -- Itt a negativ vagy specialis logikat pozitiv logikava tesszuk:
  M.FTR_PAR_NM         ,
  M.FTR_PAR_VAL        ,
  coalesce(trim(T.SUB_TYPE),'')           ,
  coalesce(trim(T.VOICE_BILLING_INCREMENT),''),
  coalesce(trim(T.TGT_OFFER_CD),'')       ,
  M.OFFER_CD           ,
  M.OFFER_ID           ,
  M.PRODUCT_ID         ,
  M.SERVICE_ID         ,
  M.ATTR_ID            ,
  case
    when M.ATTR_VALUE='=' then LEGACY.F_FEA_PAR_VAL_GET(F.txt_to_split,M.FTR_PAR_NM)
    else M.ATTR_VALUE
  end ATTR_VALUE       ,
  F.EFF_DT             ,
  F.EXP_DT             ,
  concat('SPC',lpad(@SER_NR:=@SER_NR+1,10,'0')) SER_NR,
  'Y' USE_FLAG
  -- ---
FROM LEGACY.M_OFFER_M01_TARIFF    T  -- tarifahoz valasztjuk az addont
left outer join LEGACY.SPEC_FEA   F  -- innen jon az addonhoz a SOC+FEATURE adat.
  on  F.SUB_ID=T.SUB_ID
LEFT JOIN LEGACY.M_SPECIAL_MAP    M  -- innen jon az addon (addon offerkod, OFFER_ID, PROD_ID, SRV_ID, ATTR_ID) es a logika is
  ON  M.OPERATION='insert'
  AND M.SOC_LOGIC='+' -- LOGIC: egyenes (+) logika: a SOC/FEATURE/PARAM megletekor igaz.
  AND T.SUB_TYPE                             like M.SUB_TYPE
  AND coalesce(T.VOICE_BILLING_INCREMENT,'') like M.VBI       -- null is szamit!
  AND T.TGT_OFFER_CD                         like M.MAIN_OFFER
  AND F.SOC_CD                               like M.SOC
  AND F.FEATURE_CODE                         like M.FEATURE
  -- Az alabbi a konvertalando felsorolt ertekeket kezeli:
  AND (M.FTR_PAR_NM='%' 
       or  concat('@',F.TXT_TO_SPLIT) LIKE concat('%@',trim(M.FTR_PAR_NM),'=',coalesce(M.FTR_PAR_VAL,''),'%')
       or (concat('@',F.TXT_TO_SPLIT) LIKE concat('%@',trim(M.FTR_PAR_NM),'=%') and M.FTR_PAR_VAL='=' )
       )
-- Nem vonom be az IDID fajlt, mert az abbol vett adatokat betettuk az M_SPECIAL_MAP tablaba sajat map Excelbol.
     -- Tarifa PP soc elokeritese VBI/SUB_TYPE/MAIN OFFER vegett:
WHERE T.TGT_OFFER_TYPE        = 'T'
  AND T.SRC_PRICE_PLAN_SEQ_NO = T.SRC_SOC_SEQ_NO
;

/*
Query OK, 470770 rows affected (37.04 sec)
Records: 470770  Duplicates: 0  Warnings: 0

MT: ez elegge jonak tunik az eddigi tesztek alapjan.

*/





-- 2. Negativ logikaju insert-ek:
insert into LEGACY.M_SPECIAL_ADDONS (
  add_or_swi         ,
  BAN                ,
  BEN                ,
  CTN                ,
  SUB_ID             ,
  SOC_Cd             ,
  FEATURE_CODE       ,
  txt_to_split       ,
  FTR_PAR_NM         ,
  FTR_PAR_VAL        ,
  SUB_TYPE           ,
  VBI                ,
  MAIN_OFFER_CD      ,
  TGT_OFFER_CD       ,
  TGT_OFFER_ID       ,
  PROD_ID            ,
  SRV_ID             ,
  ATTR_ID            ,
  ATTR_VALUE         ,
  EFFECTIVE_DATE     ,
  EXPIRATION_DATE    ,
  SER_NR             ,
  USE_FLAG
)
SELECT distinct
  F.add_or_swi         ,
  F.BAN                ,
  F.BEN                ,
  F.CTN                ,
  F.SUB_ID             ,
  coalesce(trim(F.SOC_Cd),'')             ,
  coalesce(trim(F.FEATURE_CODE),'')       ,
  F.txt_to_split       ,
  -- Itt a negativ vagy specialis logikat pozitiv logikava tesszuk:
  M.FTR_PAR_NM         ,
  M.FTR_PAR_VAL        ,
  coalesce(trim(T.SUB_TYPE),'')           ,
  coalesce(trim(T.VOICE_BILLING_INCREMENT),''),
  coalesce(trim(T.TGT_OFFER_CD),'')       ,
  M.OFFER_CD           ,
  M.OFFER_ID           ,
  M.PRODUCT_ID         ,
  M.SERVICE_ID         ,
  M.ATTR_ID            ,
  case
    when M.ATTR_VALUE='=' then LEGACY.F_FEA_PAR_VAL_GET(F.txt_to_split,M.FTR_PAR_NM)
    else M.ATTR_VALUE
  end ATTR_VALUE       ,
  F.EFF_DT             ,
  F.EXP_DT             ,
  concat('SPC',lpad(@SER_NR:=@SER_NR+1,10,'0')) SER_NR,
  'Y' USE_FLAG
  -- ---
FROM LEGACY.M_OFFER_M01_TARIFF    T  -- tarifahoz valasztjuk az addont
LEFT JOIN LEGACY.M_SPECIAL_MAP    M  -- innen jon az addon (addon offerkod, OFFER_ID, PROD_ID, SRV_ID, ATTR_ID) es a logika is
  ON  T.SUB_TYPE                                   like M.SUB_TYPE
  AND coalesce(T.VOICE_BILLING_INCREMENT,'')       like M.VBI       -- null is szamit!
  AND T.TGT_OFFER_CD                               like M.MAIN_OFFER
left outer join LEGACY.SPEC_FEA   F  -- innen jon az addonhoz a SOC+FEATURE adat.
  ON  F.Sub_Id=T.Sub_Id
  AND F.SOC_CD                                     like M.SOC
-- Nem vonom be az IDID fajlt, mert az abbol vett adatokat betettuk az M_SPECIAL_MAP tablaba sajat map Excelbol.
     -- Tarifa PP soc elokeritese VBI/SUB_TYPE/MAIN OFFER vegett:
WHERE T.TGT_OFFER_TYPE        = 'T'
  AND T.SRC_PRICE_PLAN_SEQ_NO = T.SRC_SOC_SEQ_NO
  AND M.OPERATION='insert'
  AND M.SOC_LOGIC='-'     -- LOGIC: inverz (-) logika: a SOC/FEATURE/PARAM nemletekor igaz.
  AND F.SOC_Cd is null    -- LOGIC: inverz (-) logika: a SOC/FEATURE/PARAM nemletekor igaz.
;


/*
Query OK, 6178 rows affected (1 min 11.27 sec)
Records: 6178  Duplicates: 0  Warnings: 0

MT: Ezt kell meg tesztelgetni. Gabornak passzolom.
*/

call LEGACY.createindex_ifnotexists('LEGACY','M_SPECIAL_ADDONS','MAIN_OFFER_CD,SOC_CD,FEATURE_CODE'); 


-- 3. delete csak pozitiv logikaval fordul elo:
update LEGACY.M_SPECIAL_ADDONS T
JOIN LEGACY.M_SPECIAL_MAP      M     -- innen jon az addon (addon offerkod, OFFER_ID, PROD_ID, SRV_ID, ATTR_ID) es a logika is
  ON  M.OPERATION='delete'
  AND M.SOC_LOGIC='+' -- LOGIC: egyenes (+) vagy inverz (-) lehet. Ha +, akkor a SOC/FEATURE/PARAM megletekor igaz, kulonben a nemletekor igaz.
-- MT: Szabolcs javallatara kihuztam a most epp nem erintett oszlopokat, hatha gyorsul:
--  AND T.SUB_TYPE                      like M.SUB_TYPE
--  AND T.VBI                           like M.VBI
  AND T.MAIN_OFFER_CD                 like M.MAIN_OFFER
  AND T.SOC_CD                        like M.SOC
  AND T.FEATURE_CODE                  like M.FEATURE
SET USE_FLAG='N'
;

/*
Query OK, 8535 rows affected (1.43 sec)
Rows matched: 8535  Changed: 8535  Warnings: 0

MT: Realisnak tunik. Gabornak tesztelni adni.
*/



/*
-- ----------------------------------------------------------------------------------------------------------

  MT: Az M_SPECIAL_ADDONS tablaba ez a logika tobbszorozve visz be sorokat. Ezt vagy egyszeri kiegyelessel vagy a tovabbiakba DISTINCT lekerdezesekkel orvosolhatjuk. Egyelore DISTINCT a megoldas.
                                                                                                             -- ----------------------------------------------------------------------------------------------------------
*/



-- MT: Ez hianyzott.
call LEGACY.createindex_ifnotexists('LEGACY','M_SPECIAL_ADDONS','CTN,BAN,BEN'); 




insert into MDM.INS_OFFER (
  TENANT_ID,
  OFFER_INST_ID,
  CUST_ID,
  CUST_TYPE,
  USER_ID,
  OFFER_ID,
  OFFER_TYPE,
  BRAND_ID,
  ORDER_NAME,
  STATE,
  EFFECTIVE_DATE,
  EXPIRE_DATE,
  SALE_TYPE,
  DONE_CODE,
  EXPIRE_PROCESS_TYPE,
  CHANNEL_TYPE,
  OS_STATE
)
select distinct
  '22',
  A.SER_NR,
  T.CA_ID,
  @CUST_TYPE_B2B,
  T.Sub_Id,
  A.TGT_OFFER_ID,
  'OFFER_VAS_CBOSS',
  '0',
  A.TGT_OFFER_CD,
  CASE
    WHEN A.EXPIRATION_DATE < SYSDATE() THEN '7'
    WHEN A.EFFECTIVE_DATE  > SYSDATE() THEN '7'
    ELSE '1'
    END STATE,
  CASE
    WHEN A.EFFECTIVE_DATE > @EXP_DT THEN @EFF_DT
    ELSE COALESCE(A.EFFECTIVE_DATE,@EFF_DT)
    END            AS EFFECTIVE_DATE,
  CASE 
    WHEN A.EXPIRATION_DATE > @EXP_DT THEN @EXP_DT
    ELSE COALESCE(A.EXPIRATION_DATE,@EXP_DT)
    END            AS EXPIRE_DATE,
  '0',
  null,
  '0',
  '99999',
  '1' -- OS_STATE
FROM  LEGACY.M_OFFER_M01_TARIFF T
JOIN  LEGACY.M_SPECIAL_ADDONS   A
  ON  A.CTN=T.CTN
  AND A.BAN=T.BAN
  AND A.BEN=T.BEN
WHERE A.USE_FLAG = 'Y'
  AND A.TGT_OFFER_ID > 0
group by  -- Olyan a logika, hogy lehet tobbszorozes A-ban, amit itt egyelunk ki.
  T.CA_ID,
  T.CTN,
  A.TGT_OFFER_ID
;


INSERT INTO MDM.INS_OFF_INS_USER
(
  TENANT_ID            ,
  OFFER_USER_RELAT_ID  ,
  OFFER_INST_ID        ,
  USER_ID              ,
  OFFER_ID             ,
  ROLE_ID              ,
  IS_MAIN_OFFER        ,
  IS_GRP_MAIN_USER     ,
  DONE_CODE            ,
  STATE                ,
  CREATE_DATE          ,
  DONE_DATE            ,
  EFFECTIVE_DATE       ,
  EXPIRE_DATE
)
SELECT DISTINCT
  '22'                        ,
  A.SER_NR OFFER_USER_RELAT_ID,
  A.SER_NR ADDON_OFFER_INST_ID,
  T.Sub_Id    USER_ID            ,
  A.TGT_OFFER_ID OFFER_ID     ,
  '181000000001'              ,
  1                           ,
  0                           ,
  NULL              DONE_CODE ,
  CASE
    WHEN A.EXPIRATION_DATE < SYSDATE() THEN '7'
    WHEN A.EFFECTIVE_DATE  > SYSDATE() THEN '7'
    ELSE '1'
    END STATE,
  CASE
    WHEN A.EFFECTIVE_DATE > @EXP_DT THEN @EFF_DT
    ELSE COALESCE(A.EFFECTIVE_DATE,@EFF_DT)
    END            AS CREATE_DATE,
  CASE 
    WHEN A.EXPIRATION_DATE > @EXP_DT THEN @EXP_DT
    ELSE COALESCE(A.EXPIRATION_DATE,@EXP_DT)
    END            AS DONE_DATE,
  CASE
    WHEN A.EFFECTIVE_DATE > @EXP_DT THEN @EFF_DT
    ELSE COALESCE(A.EFFECTIVE_DATE,@EFF_DT)
    END            AS EFFECTIVE_DATE,
  CASE 
    WHEN A.EXPIRATION_DATE > @EXP_DT THEN @EXP_DT
    ELSE COALESCE(A.EXPIRATION_DATE,@EXP_DT)
    END            AS EXPIRE_DATE
FROM  LEGACY.M_OFFER_M01_TARIFF T
JOIN  LEGACY.M_SPECIAL_ADDONS   A
  ON  A.CTN=T.CTN
  AND A.BAN=T.BAN
  AND A.BEN=T.BEN
WHERE A.USE_FLAG = 'Y'
  AND A.TGT_OFFER_ID > 0
group by  -- Olyan a logika, hogy lehet tobbszorozes A-ban, amit itt egyelunk ki.
  T.CA_ID,
  T.CTN,
  A.TGT_OFFER_ID
;



