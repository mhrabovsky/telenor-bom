-- USE LEGACY;

-- NAS 10.04 beégetések bõvítése
SET @EXP_DATE = CAST(LEGACY.CONFIG('DEF_EXP_DATE',NULL) AS DATE);

call LEGACY.createindex_ifnotexists('LEGACY','USER_LDR','CA');
call LEGACY.createindex_ifnotexists('LEGACY','CA_ID_FILTER_B2C_LDR','CA_ID');
call LEGACY.createindex_ifnotexists('LEGACY','CA_ID_FILTER_B2B_LDR','CA_ID');

DROP TABLE if exists LEGACY.M_USER;

CREATE TABLE LEGACY.M_USER
(
-- ---
    Sub_Id                  VARCHAR(28)                     NOT NULL                                --  ~~ BAN_BEN_CTN ideiglenesen
-- ---
,   CA_Id                   VARCHAR(30)                 NOT NULL    --  CA                      --  mindig NOT NULL ???
,   BAN                     VARCHAR(10)      NOT NULL    --  BAN
,   BEN                     VARCHAR(5)      NOT NULL    --  BEN
,   CTN                     VARCHAR(11)                 NOT NULL    --  CTN
,   IMSI                    VARCHAR(15)                     NULL    --  IMSI
-- ---
,   CA_Type_Cd              TINYINT                         NULL                                --  !!!
-- ---
,   Acct_Type               CHAR(3)                     NOT NULL    --  ACCOUNT_TYPE
,   Acct_Cat                CHAR(1)                     NOT NULL    --  ACCOUNT_CATEGORY
,   Init_Act_Dt             datetime            NOT NULL    --  INIT_ACTIVATION_DATE
                                                                    --  PRE_DESTROY_TIME        --  ???
,   Eff_Dt                  datetime            NOT NULL    --  EFFECTIVE_DATE
,   Exp_Dt                  datetime            NOT NULL    --  EXPIRATION_DATE
,   Sub_Status_Cd           CHAR(1)                     NOT NULL    --  SUB_STATUS
,   Sub_Status_Dt           datetime            NOT NULL    --  SUB_STATUS_DATE
,   Sub_Status_Last_Act     VARCHAR(3)                  NOT NULL    --  SUB_STATUS_LAST_ACT
,   Sub_Status_Rsn_Cd       VARCHAR(4)                  NOT NULL    --  SUB_STATUS_RSN_CODE
-- NGy 08.03
,   Sub_Type                  char(3)             not null  --  subsription type PRE,HYB,POS
-- NAS 08.11
,   LIFECYCLE_EXP_DATE        datetime            NULL
,   SUBSCRIBER_REF            varchar(30)     -- MT: NRPC migralasahoz kell.
)
;

SET @BAN_THRESHOLD = CAST(LEGACY.CONFIG('BAN_THRESHOLD',NULL) AS UNSIGNED);

INSERT
INTO    LEGACY.M_USER
(
-- ---
        Sub_Id
-- ---
,       CA_Id
,       BAN
,       BEN
,       CTN
,       IMSI
-- ---
,       CA_Type_Cd
-- ---
,       Acct_Type
,       Acct_Cat
,       Init_Act_Dt

,       Eff_Dt
,       Exp_Dt

,       Sub_Status_Cd
,       Sub_Status_Dt
,       Sub_Status_Last_Act
,       Sub_Status_Rsn_Cd
-- ---
-- NGy 08.03
,       Sub_Type
,       LIFECYCLE_EXP_DATE 
,       SUBSCRIBER_REF -- MT 0823
)
SELECT
-- ---
        concat(U.BAN,'_',U.BEN,'_',rtrim(U.CTN))                   AS  Sub_Id
-- ---
,       U.CA                                                AS  CA_Id
,       U.BAN                                               AS  BAN
,       U.BEN                                               AS  BEN
,       rtrim(U.CTN)                                        AS  CTN
,       U.IMSI                                              AS  IMSI            --  !!!
-- ---
,       /*CASE WHEN C.CA_Id IS NULL and B.CA_Id is null THEN 0
               WHEN C.CA_Id IS not NULL and B.CA_Id is null THEN 1
               WHEN C.CA_Id IS NULL and B.CA_Id is not null THEN 2
               ELSE 3
          END*/
          2   AS  CA_Type_Cd
-- ---
,       U.ACCOUNT_TYPE                                      AS  Acct_Type
,       U.ACCOUNT_CATEGORY                                  AS  Acct_Cat
,       COALESCE( CAST(U.INIT_ACTIVATION_DATE AS DATE), @EXP_DATE )    AS  Init_Act_Dt
,       COALESCE( CAST(U.EFFECTIVE_DATE       AS DATE), @EXP_DATE )    AS  Eff_Dt
-- ,       COALESCE(CAST(replace(replace(U.EXPIRATION_DATE,'2106','2016'),'3013','2013') AS DATE), CAST('2099-12-31' AS DATE)) Exp_Dt -- AI:2000219 adattisztitas
,       COALESCE(CAST(replace(replace(U.EXPIRATION_DATE,'2106','2016'),'3013','2013') AS DATE), @EXP_DATE ) Exp_Dt -- AI:2000219 adattisztitas
,       U.SUB_STATUS                                        AS  Sub_Status_Cd
,       COALESCE( CAST(U.SUB_STATUS_DATE      AS DATE), @EXP_DATE )    AS  Sub_Status_Dt
,       U.SUB_STATUS_LAST_ACT                               AS  Sub_Status_Last_Act
,       U.SUB_STATUS_RSN_CODE                               AS  Sub_Status_Rsn_Cd
-- ---
-- NGy 08.03
,       CASE U.ACCOUNT_CATEGORY
             WHEN 'P' THEN 'PRE'
             WHEN 'H' THEN 'HYB'
             WHEN 'M' THEN 'HYB'
             ELSE 'POS'
             END
        AS    Sub_Type
,       U.LIFECYCLE_EXP_DATE
,       U.SUBSCRIBER_REF
FROM LEGACY.USER_LDR U
/*LEFT outer*/INNER JOIN  LEGACY.CA_ID_FILTER_B2B_LDR B ON U.CA = B.CA_ID
LEFT outer JOIN  LEGACY.CA_ID_FILTER_B2C_LDR C ON U.CA = C.CA_ID
WHERE C.CA_ID is NULL
-- AND U.SUB_STATUS = 'C' -- NK0907:CANCELLED USEREKET BESZÛRJÜK
AND CAST(U.BAN AS UNSIGNED) >= @BAN_THRESHOLD -- ABO 10/03 BAN ALAPÚ SZELETELÉS
;

-- configuration 'cancelled'
select LEGACY.CONFIG('Mand_Addon_Offer_Inst_Id','950100000'); -- ABO 10/06 éjjel: 'LEGACY' hiányzott
select LEGACY.CONFIG('INST_COMMITMENT_ID','74100000');
select LEGACY.CONFIG('CMREL_ID_A','110000000');
select LEGACY.CONFIG('CMREL_ID_B','210000000');
select LEGACY.CONFIG('ACCT_RELA_ID','110000000');
select LEGACY.CONFIG('PROD_INST_ID','4100000000');
select LEGACY.CONFIG('PROD_SRV_RELAT_ID','6100000');
select LEGACY.CONFIG('ATTR_INST_ID','110000000');
select LEGACY.CONFIG('GEN_Feature_Seq_No','2100000000');
select LEGACY.CONFIG('TGT_OFFER_INST_ID', '901000000');


