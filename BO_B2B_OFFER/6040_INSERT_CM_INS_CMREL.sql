-- use MDM;

-- NAS 10.04 beégetések bõvítése
SET @CMREL_ID_A = LEGACY.CONFIG('CMREL_ID_A','100000000');
SET @CMREL_ID_B = LEGACY.CONFIG('CMREL_ID_B','200000000');
SET @OFFER_TYPE_MAIN = LEGACY.CONFIG('OFFER_TYPE_MAIN',NULL);

call LEGACY.createindex_ifnotexists('MDM','INS_USER','USER_ID');
call LEGACY.createindex_ifnotexists('MDM','INS_OFFER','USER_ID');

insert into MDM.CM_INS_CMREL 
select
'22' TENANT_ID,
CONCAT(@CMREL_ID_A,@rownum := @rownum + 1),
'1' RELA_TYPE,
u.USER_ID,
u.CUST_ID,
null USER_REGION_CODE,
o.STATE, -- ABO 
u.USER_TYPE,
u.PROD_CATALOG_ID,
o.OFFER_ID,
null CREATE_OP_ID,
null CREATE_ORG_ID,
null OP_ID,
null ORG_ID,
null DONE_CODE,
null CREATE_DATE,
null DONE_DATE,
o.EFFECTIVE_DATE,
o.EXPIRE_DATE,
NULL EXT1
from MDM.INS_USER u, MDM.INS_OFFER o, (select @rownum :=0) r
where o.user_id = u.user_id
and o.OFFER_TYPE = @OFFER_TYPE_MAIN;

insert into MDM.CM_INS_CMREL 
select
'22' TENANT_ID,
CONCAT(@CMREL_ID_B,@rownum := @rownum + 1),
'2' RELA_TYPE,
u.USER_ID,
u.CUST_ID,
null USER_REGION_CODE,
o.STATE, -- ABO 07/07
u.USER_TYPE,
u.PROD_CATALOG_ID,
o.OFFER_ID,
null CREATE_OP_ID,
null CREATE_ORG_ID,
null OP_ID,
null ORG_ID,
null DONE_CODE,
null CREATE_DATE,
null DONE_DATE,
o.EFFECTIVE_DATE,
o.EXPIRE_DATE,
NULL EXT1
from MDM.INS_USER u, MDM.INS_OFFER o, (select @rownum :=0) r
where o.user_id = u.user_id
and o.OFFER_TYPE = @OFFER_TYPE_MAIN;


