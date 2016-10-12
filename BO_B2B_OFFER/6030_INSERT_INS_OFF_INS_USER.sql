
insert into
MDM.INS_OFF_INS_USER 
(TENANT_ID,
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
ORG_ID)

select
DISTINCT
'22'TENANT_ID,
CONCAT(USER_ID,OFFER_INST_ID) OFFER_USER_RELAT_ID,
OFFER_INST_ID,
USER_ID,
OFFER_ID,
-- null ROLE_ID,
'181000000001' ROLE_ID,	-- NAS 0718
'1', -- IS_MAIN_OFFER
'0' IS_GRP_MAIN_USER,
STATE,
'0' DONE_CODE,
EFFECTIVE_DATE, -- CREATE_DATE,
EFFECTIVE_DATE, -- DONE_DATE,
EFFECTIVE_DATE,
EXPIRE_DATE,
null OP_ID,
null ORG_ID
FROM 
MDM.INS_OFFER;




