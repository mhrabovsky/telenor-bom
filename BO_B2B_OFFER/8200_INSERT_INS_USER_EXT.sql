-- 8200.
USE LEGACY;

-- DEFAULT FLAG 113060 - regretUserFlag

INSERT INTO MDM.INS_USER_EXT(
   TENANT_ID
  ,USER_ID
  ,ATTR_CODE
  ,ATTR_VALUE
  ,STATE
  ,EFFECTIVE_DATE
  ,EXPIRE_DATE
  ,OP_ID
  ,ORG_ID
)
SELECT
   '22'  AS TENANT_ID -- IN varchar(30)
  ,U.USER_ID  AS USER_ID -- IN varchar(30)
  ,113060   AS ATTR_CODE -- IN int(11)
  ,'False'  AS ATTR_VALUE -- IN varchar(500)
  ,U.STATE   AS STATE -- IN bigint(2)
  ,U.EFFECTIVE_DATE  AS EFFECTIVE_DATE -- IN datetime
  ,U.EXPIRE_DATE  AS EXPIRE_DATE -- IN datetime
  ,0   AS OP_ID -- IN bigint(12)
  ,0   AS ORG_ID -- IN bigint(12)
FROM MDM.INS_USER U
;

-- DEFAULT FLAG 301723 - PhoneBookState
CALL LEGACY.createindex_ifnotexists("LEGACY"
                                  , "CA_CPNI_LDR"
                                  , "SERIAL_NUM");

INSERT INTO
  MDM.INS_USER_EXT(TENANT_ID
                 , USER_ID
                 , ATTR_CODE
                 , ATTR_VALUE
                 , STATE
                 , EFFECTIVE_DATE
                 , EXPIRE_DATE
                 , OP_ID
                 , ORG_ID)
  SELECT
    '22' AS TENANT_ID -- IN varchar(30)
  , U.USER_ID AS USER_ID -- IN varchar(30)
  , 301723 AS ATTR_CODE -- IN int(11) -- PhoneBookState
  , CASE
      WHEN C.X_CPNI_SECRET = 'Y' THEN '3' -- :Secret
      WHEN C.X_CPNI_NO_SECRET = 'Y' THEN '1' -- :Fullypublic
      ELSE '2' -- :Partiallypublic
    END
      AS ATTR_VALUE -- IN varchar(500)
  , U.STATE AS STATE -- IN bigint(2)
  , U.EFFECTIVE_DATE AS EFFECTIVE_DATE -- IN datetime
  , U.EXPIRE_DATE AS EXPIRE_DATE -- IN datetime
  , 0 AS OP_ID -- IN bigint(12)
  , 0 AS ORG_ID -- IN bigint(12)
  FROM
    MDM.INS_USER U INNER JOIN LEGACY.CA_CPNI_LDR C ON U.USER_ID = C.SERIAL_NUM;
	