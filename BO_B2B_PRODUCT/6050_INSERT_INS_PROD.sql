-- 6050.

-- NAS 10.04 beegetesek bovitese
SET @PROD_INST_ID = LEGACY.CONFIG('PROD_INST_ID',null);
SET @EFF_DT = CAST(LEGACY.CONFIG('DEF_EFF_DATE',NULL) AS DATETIME);
SET @EXP_DT = CAST(LEGACY.CONFIG('DEF_EXP_DATE',NULL) AS DATETIME);
SET @SYS_DATE = CAST(LEGACY.CONFIG('SYS_DATE',NULL) AS DATETIME);

call LEGACY.createindex_ifnotexists('LEGACY','BO_ID2ID_MAIN_OFFER_LDR','OFFER_ID');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M20_MERGE_ALL','Tgt_Offer_Id');
call LEGACY.createindex_ifnotexists('LEGACY','SOC_FEATURE_OFFER_MAPPING','CTN,VERIS_PRODUCT_ID');
call LEGACY.createindex_ifnotexists('MDM','INS_USER','USER_ID');

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
     '22'
     ,CASE WHEN M.FEATURE_SEQ_NO IS NOT NULL
            THEN concat(M.VERIS_PRODUCT_ID,M.CTN,M.MAIN_SOC_SEQ_NO, RIGHT(M.VERIS_OFFER_ID, 4))
          ELSE CONCAT(M.SOC_SEQ_NO,M.CTN)
     END                                                        AS PROD_INST_ID
    ,CONCAT(M.CTN, M.MAIN_SOC_SEQ_NO, M.VERIS_OFFER_ID)         AS OFFER_USER_RELAT_ID
    ,CONCAT(M.MAIN_SOC_SEQ_NO, M.VERIS_OFFER_ID)           AS OFFER_INST_ID
    ,M.USER_ID
    ,M.VERIS_PRODUCT_ID
    ,M.MDM_TYPE
    ,'0'
    ,CASE WHEN M.FEATURE_EXPIRATION_DATE < @SYS_DATE
            THEN '7'
          ELSE '1'
     END
    ,CASE WHEN M.FEATURE_EFFECTIVE_DATE IS NULL
            THEN @EFF_DT
          WHEN M.FEATURE_EFFECTIVE_DATE > M.FEATURE_EXPIRATION_DATE
            THEN M.FEATURE_EXPIRATION_DATE
          ELSE M.FEATURE_EFFECTIVE_DATE
     END                                                        AS EFFECTIVE_DATE
    ,CASE WHEN M.FEATURE_EXPIRATION_DATE IS NULL
            THEN @EXP_DT
          WHEN M.FEATURE_EXPIRATION_DATE > @EXP_DT
            THEN @EXP_DT
          ELSE M.FEATURE_EXPIRATION_DATE
     END                                                        AS EXPIRE_DATE

FROM LEGACY.SOC_FEATURE_OFFER_MAPPING M
join MDM.INS_USER U on U.USER_ID=M.USER_ID
WHERE  M.VERIS_PRODUCT_ID IS NOT NULL
;

CALL LEGACY.createindex_ifnotexists('LEGACY','SOC_FEATURE_OFFER_MAPPING','CTN');
CALL LEGACY.createindex_ifnotexists('LEGACY','SOC_FEATURE_OFFER_MAPPING','VERIS_OFFER_ID');
CALL LEGACY.createindex_ifnotexists('LEGACY','BO_ID2ID_MAIN_OFFER_LDR','OFFER_ID,MDM_TYPE');
CALL LEGACY.createindex_ifnotexists('LEGACY','BO_ID2ID_MAIN_OFFER_LDR','OBJECT_ID');
CALL LEGACY.createindex_ifnotexists('MDM','INS_PROD','PROD_INST_ID');
CALL LEGACY.createindex_ifnotexists('MDM','INS_PROD','USER_ID,PROD_ID');

-- Az INS_PROD-bol hianyzik, de az Id2Id mapping-ben az offer-hez fellelheto PRICE_PROD-ok beirasa INS_PROD-ba
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
select
     '22'                                           AS TENANT_ID
    ,concat(@PROD_INST_ID, lpad(@id:=@id+1, 10, '0'))   AS PROD_INST_ID
    ,CONCAT(F.CTN, F.MAIN_SOC_SEQ_NO)               AS OFFER_USER_RELAT_ID
    ,CONCAT(F.MAIN_SOC_SEQ_NO,F.VERIS_OFFER_ID)     AS OFFER_INST_ID
    ,F.USER_ID			                    AS USER_ID
    ,ia.OBJECT_ID                                   AS PROD_ID
    ,'PRICE_PROD'                                   AS PROD_TYPE
    ,'0'                                            AS EXPIRE_PROCESS_TYPE
    ,'1'                                            AS STATE
    ,@EFF_DT                                        AS EFFECTIVE_DATE
    ,@EXP_DT                                        AS EXPIRE_DATE

FROM    LEGACY.SOC_FEATURE_OFFER_MAPPING            AS F
--    FORCE INDEX (IDX_SOC_FEATURE_OFFER_MAPPING_VERIS_OFFER_ID)

 join   LEGACY.BO_ID2ID_MAIN_OFFER_LDR              AS ia
--   FORCE INDEX (IDX_BO_ID2ID_MAIN_OFFER_LDR_OFFER_ID)

        on  ia.OFFER_ID  = CAST(F.VERIS_OFFER_ID AS CHAR)
       and  ia.MDM_TYPE                   = 'PRICE_PROD'

 left outer join MDM.INS_PROD                       AS P
        on P.USER_ID = F.USER_ID
       and P.PROD_ID = ia.OBJECT_ID

 join
     (   select @id:=coalesce(max(cast(right(PROD_INST_ID,10) as UNSIGNED)),0)
     from MDM.INS_PROD
     where PROD_INST_ID like concat(@PROD_INST_ID, '__________')
    )                                               AS x
        on 1=1

where 1=1
 and P.USER_ID is null
;

CALL LEGACY.createindex_ifnotexists('LEGACY','BO_ID2ID_ADDON_OFFER_LDR','OFFER_ID,MDM_TYPE');

--
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
select
     '22'                                           AS TENANT_ID
    ,concat(@PROD_INST_ID, lpad(@id:=@id+1, 10, '0'))   AS PROD_INST_ID
    ,CONCAT(F.CTN, F.MAIN_SOC_SEQ_NO)               AS OFFER_USER_RELAT_ID
    ,CONCAT(F.MAIN_SOC_SEQ_NO,F.VERIS_OFFER_ID)     AS OFFER_INST_ID
    ,F.USER_ID				            AS USER_ID
    ,ia.OBJECT_ID                                   AS PROD_ID
    ,'SRVC_SINGLE'                                  AS PROD_TYPE
    ,'0'                                            AS EXPIRE_PROCESS_TYPE
    ,'1'                                            AS STATE
    ,@EFF_DT                                        AS EFFECTIVE_DATE
    ,@EXP_DT                                        AS EXPIRE_DATE
FROM
LEGACY.SOC_FEATURE_OFFER_MAPPING F
 join LEGACY.BO_ID2ID_ADDON_OFFER_LDR ia
    on cast(F.VERIS_OFFER_ID as char)=ia.OFFER_ID
    and 'SRVC_SINGLE'=ia.MDM_TYPE
 left outer join MDM.INS_PROD P
    on F.USER_ID=P.USER_ID
    and ia.OBJECT_ID=P.PROD_ID
 join
    (select
        @id:=coalesce(max(cast(right(PROD_INST_ID,10) as UNSIGNED)),0)
     from MDM.INS_PROD
     where PROD_INST_ID like concat(@PROD_INST_ID, '__________')
    ) x
    on 1=1
where 1=1
 and P.USER_ID is null
;




