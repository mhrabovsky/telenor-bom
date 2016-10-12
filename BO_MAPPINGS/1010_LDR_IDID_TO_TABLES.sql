USE LEGACY;

/*
OFFER MAP es IDID MAP tablazatok betoltese, eloszurese, formazasa
A forras excel tablazatokat a B2B es a B2C csoport (Kata es Tomek) allitjak elo.
Nalunk Csaba formazza es TSV-ve alakitja az alabbi tablak alapjaul szolgalo Excel tablazatokat.
Az id2id_rec_id-t Csaba minden hetfon ujraszamolja a fenti feldolgozassal egyutt (elozo penteki allapot).
A betoltesuket a Mignon vegzi el minden kedden delben, aszinkron, kezzel inditott menetben. A Pandocs az utolso atado, amikor atado, utana van a betoltes.
*/
-- --
-- B2C Pandocs input (not used):
-- BO_ID2ID_ADDON_OFFER_LDR
-- BO_ID2ID_ATTR2ATTR_LDR
-- BO_ID2ID_MAIN_OFFER_LDR
--
-- B2B Pandocs input(a "gyari" strukturak bovitese):
-- M_IDID_ATTR_LDR		- M_IDID_ATTR_MOD
-- M_IDID_OFFER_LDR	- M_IDID_OFFER_MOD
-- M_IDID_OFFER_SPLIT_LDR	- M_IDID_OFFER_MOD
--
-- --


DROP TABLE IF EXISTS M_IDID_OFFER_MOD;
DROP TABLE IF EXISTS M_IDID_ATTR_MOD;


CREATE TABLE M_IDID_OFFER_MOD
(
--
    Id2Id_Rec_Id            INTEGER         NOT NULL
,   Map_Type                CHAR(3)         NOT NULL
,   Tgt_Offer_Type          CHAR(1)         NOT NULL
,   Tgt_Offer_Type_Desc     VARCHAR(30)     NOT NULL
,   Tgt_Offer_Cd            VARCHAR(100)    NOT NULL
,   Tgt_Offer_Name          VARCHAR(1000)   NOT NULL
,   Veris_Type_Cd           VARCHAR(10)     NOT NULL
,   MDM_Type_Cd             VARCHAR(30)     NOT NULL
,   Billing_Type            INTEGER         NOT NULL
,   Veris_Object_Id         BIGINT          NOT NULL
,   Veris_Object_Name       VARCHAR(1000)   NOT NULL
,   Relat_Offer_Id          BIGINT          NOT NULL
--
,   Service_Flag            VARCHAR(100)    	NULL
--
,   Deduct_Flag             INTEGER         	NULL
,   Split_Type              INTEGER         	NULL
,   Split_Desc              VARCHAR(1000)   	NULL
,   Price_Plan_Name         VARCHAR(1000)   NOT NULL
,   Relat_Main_Product      VARCHAR(30)         NULL
--
,   Role_Id                 BIGINT              NULL
,   Product_Line            VARCHAR(100)        NULL
,   Product_Comment         VARCHAR(1000)   	NULL
,   Id2Id_Date              DATE            	NULL
,   MDM_Type_Text           VARCHAR(30)     	NULL
--
,   Main_Product_Flag       CHAR(1)         NOT NULL
,   Split_Flag              CHAR(1)         NOT NULL
,   Use_Flag                CHAR(1)         NOT NULL
,   Use_Order_No            TINYINT         NOT NULL
--
,   Sub_Type                char(3)
)
;

CREATE TABLE M_IDID_ATTR_MOD
(
    Id2Id_Rec_Id            INTEGER         NOT NULL
,   Product_Id              BIGINT          NOT NULL
,   Product_Name            VARCHAR(1000)   NOT NULL
,   Service_Id              BIGINT          NOT NULL
,   Service_Name            VARCHAR(1000)       NULL
,   Service_Desc            VARCHAR(1000)       NULL
,   Service_Attr_Id         BIGINT              NULL
,   Service_Attr_Name       VARCHAR(1000)       NULL
,   Service_Attr_Desc       VARCHAR(1000)       NULL
,   Product_Mapping_Type    VARCHAR(30)         NULL
,   Feature_Cd              VARCHAR(100)        NULL
,   Source_Name             VARCHAR(100)        NULL
)
;


INSERT
INTO    M_IDID_OFFER_MOD
(
--
        Id2Id_Rec_Id
,       Map_Type
,       Tgt_Offer_Type
,       Tgt_Offer_Type_Desc
,       Tgt_Offer_Cd
,       Tgt_Offer_Name
,       Veris_Type_Cd
,       MDM_Type_Cd
,       Billing_Type
,       Veris_Object_Id
,       Veris_Object_Name
,       Relat_Offer_Id
--
,       Service_Flag
--
,       Deduct_Flag
,       Split_Type
,       Split_Desc
,       Price_Plan_Name
,       Relat_Main_Product
--
,       Role_Id
,       Product_Line
,       Product_Comment
,       Id2Id_Date
,       MDM_Type_Text
--
,       Main_Product_Flag
,       Split_Flag
,       Use_Flag
,       Use_Order_No
--
,       Sub_Type
)
--
--
SELECT
--
        o.Id2Id_Rec_Id
,       o.Map_Type
--
,       o.Tgt_Offer_Type
--
,       o.Tgt_Offer_Type_Desc
,       o.Tgt_Offer_Cd
,       o.Tgt_Offer_Name
,       o.Veris_Type_Cd
,       o.MDM_Type_Cd
,       o.Billing_Type
,       o.Veris_Object_Id
,       o.Veris_Object_Name
,       o.Relat_Offer_Id
--
,       o.Service_Flag
--
,       -1     AS  Deduct_Flag
,       -1     AS  Split_Type
,       '#'    AS  Split_Desc
,       '#'    AS  Price_Plan_Name
,       NULL   AS  Relat_Main_Product
--
,       o.Role_Id
,       o.Product_Line
,       o.Product_Comment
,       o.Id2Id_Date
,       o.MDM_Type_Text
--
,       (CASE WHEN (o.Veris_Object_Id = o.Relat_Offer_Id AND o.Veris_type_Cd = 'VOF') THEN 'Y' ELSE 'N' END) AS Main_Product_Flag
--
,       'N' AS  Split_Flag
,       ''  AS  Use_Flag
,       0   AS  Use_Order_No
--
,       '#' AS Sub_Type
FROM
        M_IDID_OFFER_LDR o
/*      ----------
        --  Unknown tipusok kizarasa: ezek kesobb prblemat okoztak es nem tudjuk ugysem kezelni oket (pl. BMBIX)
        ----------
*/
where   Tgt_Offer_Cd NOT IN
          (
          SELECT  Tgt_Offer_Cd
          FROM    M_IDID_OFFER_SPLIT_LDR
          WHERE
            CASE
              WHEN (Tgt_Offer_Type_Desc LIKE '%Main%Offer%' ) THEN 'T'
              WHEN (Tgt_Offer_Type_Desc LIKE '%ADDON%Offer%') THEN 'A'
              WHEN (Tgt_Offer_Type_Desc LIKE '%OTTVAS%')      THEN 'A'
              ELSE 'U'
            END = 'U'
          )
UNION
SELECT
--
        Id2Id_Rec_Id
,       Map_Type
--
,       CASE WHEN (Tgt_Offer_Type_Desc LIKE '%Main%Offer%' ) THEN 'T'
             WHEN (Tgt_Offer_Type_Desc LIKE '%ADDON%Offer%') THEN 'A'
	      WHEN (Tgt_Offer_Type_Desc LIKE '%OTTVAS%') THEN 'A'
                                                             ELSE 'U' END  AS  Tgt_Offer_Type
--
,       Tgt_Offer_Type_Desc
,       Tgt_Offer_Cd
,       Tgt_Offer_Name
,       Veris_Type_Cd
,       MDM_Type_Cd
,       Billing_Type
,       Veris_Object_Id
,       Veris_Object_Name
,       Relat_Offer_Id
--
,       Service_Flag
--
,       Deduct_Flag
,       Split_Type
,       Split_Desc
,       Price_Plan_Name
,       Relat_Main_Product
--
,       NULL AS Role_Id -- ABO 07/21
,       Product_Line
,       Product_Comment
,       Id2Id_Date
,       MDM_Type_Text
--
,       CASE
          WHEN (Veris_Object_Id = Relat_Offer_Id AND Veris_type_Cd = 'VOF') THEN 'Y'
          ELSE 'N'
        END AS Main_Product_Flag
--
,       'Y' AS  Split_Flag
,       ''  AS  Use_Flag
,       0   AS  Use_Order_No
--
,       CASE
          WHEN (Billing_Type = 2 AND Deduct_Flag = 1) THEN 'POS'
          WHEN (Billing_Type = 1 AND Deduct_Flag = 0) THEN 'PRE'
          WHEN (Billing_Type = 2 AND Deduct_Flag = 0) THEN 'HYB'
        END AS  Sub_Type
FROM
        M_IDID_OFFER_SPLIT_LDR
WHERE
--  Unknown tipusok kizarasa: ezek kesobb prblemat okoztak es nem tudjuk ugysem kezelni oket (pl. BMBIX)
  Tgt_Offer_Cd NOT IN
    (
    SELECT  Tgt_Offer_Cd
    FROM    M_IDID_OFFER_SPLIT_LDR
    WHERE
      CASE
        WHEN (Tgt_Offer_Type_Desc LIKE '%Main%Offer%' ) THEN 'T'
        WHEN (Tgt_Offer_Type_Desc LIKE '%ADDON%Offer%') THEN 'A'
        ELSE 'U'
      END = 'U'
    )
;


--  Nem kezelt duplikaciok kizarasa ...

DELETE    M_IDID_OFFER_MOD
from M_IDID_OFFER_MOD
join         (
            SELECT
                    Tgt_Offer_Cd
            ,       Relat_Offer_Id
            ,       Split_Flag
            ,   Split_Type
            ,   Billing_Type
            ,   Deduct_Flag
            ,   Price_Plan_Name
            ,   Split_Desc
  
            FROM
                    M_IDID_OFFER_MOD
            WHERE
                    Main_Product_Flag = 'Y'
            GROUP BY
                    Tgt_Offer_Cd
            ,       Relat_Offer_Id
            ,       Split_Flag
            ,       Split_Type
            ,       Billing_Type
            ,       Deduct_Flag
            ,       Price_Plan_Name
            ,       Split_Desc
            HAVING
                    COUNT(*) > 1
        ) x
on M_IDID_OFFER_MOD.Tgt_Offer_Cd=x.Tgt_Offer_Cd
and M_IDID_OFFER_MOD.Relat_Offer_Id=x.Relat_Offer_Id
and M_IDID_OFFER_MOD.Split_Flag=x.Split_Flag
;


UPDATE  M_IDID_OFFER_MOD M
join (
  select x.*,case WHEN @part = Tgt_Offer_Cd THEN @i:=@i + 1 ELSE @i:=1 END AS Use_Order_No,@part:=Tgt_Offer_Cd
  from (
    SELECT 
        Relat_Offer_Id
      , Tgt_Offer_Cd
      , Split_Flag
      , Split_Type
      , Billing_Type
      , Deduct_Flag
      , Price_Plan_Name
      , Split_Desc
    FROM M_IDID_OFFER_MOD
    WHERE Main_Product_Flag = 'Y'
    ORDER BY Tgt_Offer_Cd,
        (CASE Split_Flag     WHEN 'Y'   THEN 1                 ELSE 3 END) ASC
      , (CASE Map_Type       WHEN 'B2C' THEN 1                 ELSE 3 END) ASC
      , (CASE Tgt_Offer_Type WHEN 'T'   THEN 1 WHEN 'A' THEN 2 ELSE 3 END) ASC
      --
      , Billing_Type     ASC
      --
      , Deduct_Flag      ASC
      , Price_Plan_Name  ASC
      , Split_Desc       ASC
      --
      , Product_Line     ASC
      --
      , Relat_Offer_Id   ASC
      --
      , Id2Id_Date       DESC
    ) x,(select @i:=0,@part:='-') i
  ) U
  on  M.Tgt_Offer_Cd    = U.Tgt_Offer_Cd
  AND M.Relat_Offer_Id  = U.Relat_Offer_Id
  AND M.Split_Flag      = U.Split_Flag
  AND M.Split_Type      = U.Split_Type
  AND M.Billing_Type    = U.Billing_Type
  AND M.Deduct_Flag     = U.Deduct_Flag
  AND M.Price_Plan_Name = U.Price_Plan_Name
  AND M.Split_Desc      = U.Split_Desc
SET
  M.Use_Flag     =
    CASE
      WHEN (
           U.Use_Order_No=1 -- Offer sosem tobbszorozodhet, ezert az elsot valasztjuk a sorban.
        or M.Split_Type=4   -- Kiveve 4-es Split_Type, aminek tobbszoroznie kell.
        ) THEN 'Y'          -- VIGYAZAT! 4-es split tipus tobbszor tobbszorozhet, ha nem idid_row_id-vel kapcsolunk!
      ELSE 'N'
    END,
  M.Use_Order_No = U.Use_Order_No
;

INSERT
INTO    M_IDID_ATTR_MOD
(
        Id2Id_Rec_Id
,       Product_Id
,       Product_Name
,       Service_Id
,       Service_Name
,       Service_Desc
,       Service_Attr_Id
,       Service_Attr_Name
,       Service_Attr_Desc
,       Product_Mapping_Type
,       Feature_Cd
,       Source_Name
)
SELECT
--
        New_Id2Id_Rec_Id    AS  Id2Id_Rec_Id
--
,       Product_Id
,       Product_Name
,       Service_Id
,       Service_Name
,       Service_Desc
--
,       (CASE Attr_OK WHEN 'Y' THEN Service_Attr_Id   ELSE NULL END)    AS  Service_Attr_Id
,       (CASE Attr_OK WHEN 'Y' THEN Service_Attr_Name ELSE NULL END)    AS  Service_Attr_Name
,       (CASE Attr_OK WHEN 'Y' THEN Service_Attr_Desc ELSE NULL END)    AS  Service_Attr_Desc
--
,       Product_Mapping_Type
,       Feature_Cd
,       Source_Name
--
FROM (
  select @ii:=@ii+1 New_Id2Id_Rec_Id,x.*
  from (
    select 
    x.*,@i := case WHEN @part = concat(x.Product_Id, x.Service_Id) THEN @i:=@i + 1 ELSE @i:=1 END AS grp_seq
    ,@part := concat(x.Product_Id, x.Service_Id) AS work
    from (
      SELECT
      --
              (CASE WHEN (COALESCE(D.Cnt_Dist_Attr,0) > 1) THEN 'N' ELSE 'Y' END) AS  Attr_OK
      ,       (CASE WHEN (D.Product_Id IS NOT NULL) THEN 'Y' ELSE 'N' END)        AS  Service_Multi
      --
      ,       A.Id2Id_Rec_Id                                                      AS  Old_Id2Id_Rec_Id
      --
      ,       A.Product_Id
      ,       A.Product_Name
      ,       A.Service_Id
      ,       A.Service_Name
      ,       A.Service_Desc
      --
      ,       A.Service_Attr_Id
      ,       A.Service_Attr_Name
      ,       A.Service_Attr_Desc
      --
      ,       A.Product_Mapping_Type
      ,       A.Feature_Cd
      ,       A.Source_Name
      --
      FROM M_IDID_ATTR   AS  A
      LEFT JOIN  (
        SELECT  Product_Id
        ,       Service_Id
        ,       COUNT(*)                        AS  Cnt_Service
        ,       COUNT(DISTINCT Service_Attr_Id) AS  Cnt_Dist_Attr
        FROM    M_IDID_ATTR
        GROUP BY
                Product_Id
        ,       Service_Id
        HAVING
                COUNT(*) > 1
        ) AS  D
        ON    A.Product_Id = D.Product_Id
        AND   A.Service_Id = D.Service_Id
        where A.Product_Id is not null
      ORDER BY A.Product_Id, A.Service_Id
             ,(CASE WHEN (A.Feature_Cd IS NOT NULL) THEN 1 ELSE 2 END) ASC   --  van Feature_Cd
             ,(CASE Map_Type WHEN 'B2C' THEN 1 ELSE 2 END)                   --  B2C -> B2B
             , Service_Attr_Id
      ) x,(select @part:='-',@i:=0) i
    ) x,(select@ii:=700000) i
  where x.grp_seq=1
  ) AS  Q
;

--
-- a legacy minden sorat tartalmazza, sot LEGACY_PARAM_NAME (;) combora duplikalja a sorokat (pk: ID2ID_REC_ID, ID2ID_REC_ID_SEQ)
-- product_id+service_id-n belul sorba rendezi az attributumokat (pk2: PRODUCT_ID,SERVICE_ID,SERVICE_ATTR_SEQ )
--

drop table if exists M_IDID_SRV_ATTR;
create table M_IDID_SRV_ATTR as
select ID2ID_REC_ID, ID2ID_REC_ID_SEQ,MAP_TYPE,PRODUCT_ID,PRODUCT_NAME,SERVICE_ID,SERVICE_NAME,SERVICE_DESC,
SERVICE_ATTR_SEQ,SERVICE_ATTR_ID,SERVICE_ATTR_NAME,SERVICE_ATTR_DESC,PRODUCT_MAPPING_TYPE,FEATURE_CD,SOURCE_NAME,LEGACY_PARAM_NAME,LEGACY_PARAM_DESC
from (
select ID2ID_REC_ID, ID2ID_REC_ID_SEQ,MAP_TYPE,PRODUCT_ID,PRODUCT_NAME,SERVICE_ID,SERVICE_NAME,SERVICE_DESC,
case when @p=concat(PRODUCT_ID,'-',SERVICE_ID)  then @i:=@i+1 else @i:=1 end SERVICE_ATTR_SEQ,
SERVICE_ATTR_ID,SERVICE_ATTR_NAME,SERVICE_ATTR_DESC,PRODUCT_MAPPING_TYPE,FEATURE_CD,SOURCE_NAME,LEGACY_PARAM_NAME,LEGACY_PARAM_DESC
,@p :=  concat(PRODUCT_ID,'-',SERVICE_ID) part
from (
select ID2ID_REC_ID,nn.nr ID2ID_REC_ID_SEQ,
MAP_TYPE,PRODUCT_ID,PRODUCT_NAME,SERVICE_ID,SERVICE_NAME,SERVICE_DESC,SERVICE_ATTR_ID,SERVICE_ATTR_NAME,SERVICE_ATTR_DESC,
PRODUCT_MAPPING_TYPE,FEATURE_CD,SOURCE_NAME,
SPLIT_STR(coalesce(l.LEGACY_PARAM_NAME,'-'),';',nn.nr) LEGACY_PARAM_NAME,LEGACY_PARAM_DESC 
from M_IDID_ATTR_LDR l 
join (select @s := @s+1 nr from M_IDID_ATTR_LDR, (select @s:=0) y limit 100) nn on 1=1
-- where l.LEGACY_PARAM_NAME like '%;%' or product_id=1005273
having LEGACY_PARAM_NAME<>''
order by PRODUCT_ID,SERVICE_ID, case when SERVICE_ATTR_ID in (810301,810001,820001,10760) then 0 else 1 end, SERVICE_ATTR_ID
) x
join (select @i := 0, @p := '-') xx on 1=1
) x;

