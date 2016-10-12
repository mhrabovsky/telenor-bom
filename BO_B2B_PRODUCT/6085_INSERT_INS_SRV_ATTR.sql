/******************************************************************************
*  File: 6085_INSERT_INS_SRV_ATTR.sql
*  Created: 2016.09.27 - HL
*  Desc: Olyan attrib�tumok l�trehoz�sa, melyeket kor�bban kiz�rtak, mert t�bb soruk felelt meg egy productid-serviceid-nak.
*  Modifications:
*
********************************************************************************/

-- NAS 10.04 be�get�sek b�v�t�se
SET @BASE = LEGACY.CONFIG('ATTR_INST_ID', null);

CALL LEGACY.createindex_ifnotexists('MDM','INS_PROD_INS_SRV','USER_ID');
CALL LEGACY.createindex_ifnotexists('MDM','INS_SRV_ATTR','USER_ID');
CALL LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE_ATTRS','Sub_Id');
CALL LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE_ATTRS','ATTR_CODE');
CALL LEGACY.createindex_ifnotexists('LEGACY','M_IDID_ATTR_LDR','LEGACY_PARAM_NAME');

SET @rownum := (SELECT max(cast(SUBSTR(ATTR_INST_ID, 10) as UNSIGNED)) FROM MDM.INS_SRV_ATTR);

INSERT INTO MDM.INS_SRV_ATTR
(TENANT_ID,
ATTR_INST_ID,
PROD_SRV_RELAT_ID,
OFFER_INST_ID,
USER_ID,
SERVICE_ID,
ATTR_ID,
ATTR_VALUE,
ATTR_TEXT,
STATE,
SORT_ID,
ATTR_BATCH,
EFFECTIVE_DATE,
EXPIRE_DATE)
SELECT * FROM (	  
SELECT 
    '22' TENANT_ID,
    CONCAT(@BASE, @rownum := @rownum + 1),                        -- ATTR_INST_ID
    S.PROD_SRV_RELAT_ID, 
    S.OFFER_INST_ID, 
    S.USER_ID,                                                         
    S.SERVICE_ID,                                             
    A.SERVICE_ATTR_ID ATTR_ID,
    F.ATTR_VAL ATTR_VALUE,
    F.ATTR_VAL ATTR_TEXT,
    CASE
        WHEN F.ftr_expiration_date < SYSDATE() THEN '7'
        ELSE '1'
    END STATE,
    '99' SORT_ID,
    'null' ATTR_BATCH,
    CASE
        WHEN ftr_effective_date IS NULL THEN '1900-01-01 00:00:00'
        WHEN ftr_effective_date > ftr_expiration_date THEN ftr_expiration_date
        ELSE ftr_effective_date
    END AS EFFECTIVE_DATE,
    CASE
        WHEN ftr_expiration_date IS NULL THEN '2099-12-31 23:59:59'
        WHEN ftr_expiration_date > '2099-12-31 23:59:59' THEN '2099-12-31 23:59:59'
        ELSE ftr_expiration_date
    END AS EXPIRE_DATE
FROM
    LEGACY.M_FEATURE_ATTRS F,
    LEGACY.M_IDID_ATTR_LDR A,
    MDM.INS_PROD_INS_SRV S -- FORCE INDEX (IDX_INS_PROD_INS_SRV_10)
WHERE
    A.LEGACY_PARAM_NAME = F.ATTR_CODE
        AND S.SERVICE_ID = A.SERVICE_ID
        AND A.SERVICE_ATTR_ID IS NOT NULL
        AND F.Sub_Id = S.USER_ID) qry where NOT
        EXISTS( SELECT 
            1
        FROM
            MDM.INS_SRV_ATTR T
        WHERE
            T.USER_ID = qry.USER_ID
                AND T.SERVICE_ID = qry.SERVICE_ID
                AND T.ATTR_ID = qry.ATTR_ID);
     

