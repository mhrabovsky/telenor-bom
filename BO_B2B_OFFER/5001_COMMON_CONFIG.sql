-- 5001.

-- NAS 10.04 be�get�sek b�v�t�se
-- NAS 10.07 be�get�sek b�v�t�se

TRUNCATE TABLE LEGACY._CONFIG;

INSERT INTO LEGACY._CONFIG(KEY_FIELD, VALUE)
VALUES ('BAN_THRESHOLD', '27721824'),
       ('DEF_EFF_DATE', '1900-01-01 00:00:00'),
       ('DEF_EXP_DATE', '2099-12-31 23:59:59'),       
       ('CUST_TYPE_B2B', '3'),
       ('Id2Id_Rec_Id', '700000'),
       ('OFFER_CD_EDSZ', 'ABCONPRS'),
       ('MDM_TYPE_SHARPLAN', 'SHARPLAN'),
       ('MDM_TYPE_GSM_VAS', 'GSM_VAS'),
       ('MDM_TYPE_PRICE_PROD', 'PRICE_PROD'),
--     ('MDM_TYPE_GSM_MAIN', 'GSM_MAIN'),
       ('OFFER_ID_A3ONNET', '20009716'),
       ('OFFER_TYPE_MAIN', 'OFFER_PLAN_BBOSS'),
       ('OFFER_TYPE_ADDON', 'OFFER_VAS_CBOSS');
