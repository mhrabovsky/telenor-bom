-- ------------------- 5221_BO_Prepare_Legacy_FEATURE.sql -----------------------
cat >5221_BO_Prepare_Legacy_FEATURE.sql <<'-- EOF'
-- 5221.
USE LEGACY;
/* # ident "%W%    %E%    @@" */
/****************************************************************************
 *
 *  Filename    : %M%
 *  Part of     : ...
 *  Type        : Bteq
 *  Job         : ...
 *
 *  -------------------------------------------------------------------------
 *  Purpose     : ...
 *
 *  Comments    :
 *
 *  Datasource  :
 *  -------------------------------------------------------------------------
 *  DB-Version  : TERADATA V13
 *  UNIX-Version: Red Hat Enterprise Linux Server release 5.7 (Tikanga)
 *
 *  -------------------------------------------------------------------------
 *  Project     : OPP
 *  Subproject  : BO Migration
 *
 *  Author      : Berkó Tamás
 *  Department  : TD
 *  Version     : %I%
 *  Date        : %E%
 *
 *  (c) 2016 by UniCon
 *  -------------------------------------------------------------------------
 *  History:
 *
 *  1.1   2016/05/18    Berkó Tamás
 *        Initial Version
 *        OPP project - BO Migration
 *        - DR4 preparation
 *
 ****************************************************************************
*/



-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : DROP TABLE
-- <Table> : /*${XTR_TB}*/ M_FEATURE
-- <Brief> : Extract táblák eldobása
-- ------------------------------------------------------------------------------------------</###>--

-- .set errorlevel (3807) severity 0
DROP TABLE if exists /*${XTR_TB}*/ M_FEATURE;
-- .set errorlevel (3807) severity 8



-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : CREATE TABLE
-- <Table> : /*${XTR_TB}*/ M_FEATURE
-- <Brief> : Extract táblák létrehozása
-- <Desc>  : FEATURE tábla elöállítása a betöltött PanDocs extract-ból, kiegészítve ...
-- ------------------------------------------------------------------------------------------</###>--
/*
CREATE TABLE M_FEATURE
(
-- ---
    Sub_Id          INTEGER                   NOT NULL

-- ---
,   BAN             varchar(10)               NOT NULL    --  BAN
,   BEN             varchar(5)                NOT NULL    --  BEN
,   CTN             varchar(11)               NOT NULL    --  CTN



,   SOC_Cd          CHAR(9)                   NOT NULL
,   SOC_Seq_No      varchar(9)                NOT NULL    --  SOC_SEQ_NO
,   Feature_Cd      VARCHAR(6)                NOT NULL    --  FEATURE_CODE
,   Feature_Seq_No  varchar(10)               NOT NULL    --  SERVICE_FTR_SEQ_NO




-- ---
,   Eff_Dt          DATETIME                  NOT NULL    --  FTR_EFFECTIVE_DATE
,   Exp_Dt          DATETIME                  NOT NULL    --  FTR_EXPIRATION_DATE
-- ---
                                                          --  ADDITIONAL_INFO
                                                          --  SWITCH_PARAM

,   ADDITIONAL_INFO varchar(200)              DEFAULT NULL
,   SWITCH_PARAM    varchar(400)              DEFAULT NULL

-- ---
) ENGINE=MyISAM 
-- COMMENT 'TOM -- BO work table' nk_0906:kikommenteztem ezt a sort
;
-- .if errorcode<>0 then .quit errorcode

-- COMMENT ON TABLE /*${XTR_TB}*/ -- M_FEATURE AS 'TOM -- BO work table';
-- .if errorcode<>0 then .quit errorcode

*/

-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : INSERT
-- <Table> : /*${XTR_TB}*/ M_FEATURE
-- <Brief> : Extract tábla feltöltése
-- <Desc>  : FEATURE tábla elöállítása a betöltött PanDocs extract-ból, kiegészítve ...
-- ------------------------------------------------------------------------------------------</###>--
/*

-- MT20160901: Kivettem innen, atraktam az offer elokeszito szakaszaba.


call LEGACY.createindex_ifnotexists('LEGACY','FEATURE_LDR','CTN,SOC_SEQ_NO');
-- call LEGACY.createindex_ifnotexists('LEGACY','M_SOC','CTN,SOC_Seq_No,Sub_Id,SOC_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_SOC','CTN,SOC_Seq_No,SOC_Cd');


-- NGy 08.05
INSERT
INTO    M_FEATURE
(
        Sub_Id
,       BAN
,       BEN
,       CTN
,       SOC_Cd
,       SOC_Seq_No
,       Feature_Cd
,       Feature_Seq_No
,       Eff_Dt
,       Exp_Dt
,   ADDITIONAL_INFO
,   SWITCH_PARAM   
)
SELECT
        F.CTN                AS  Sub_Id        
-- ---
,       F.BAN                   AS  BAN
,       F.BEN                   AS  BEN
,       F.CTN                   AS  CTN
,       S.SOC_Cd                AS  SOC_Cd
,       F.SOC_Seq_No            AS  SOC_Seq_No
,       F.FEATURE_CODE            AS  Feature_Cd
,       F.SERVICE_FTR_SEQ_NO        AS  Feature_Seq_No
,       COALESCE(CAST(F.FTR_EFFECTIVE_DATE  AS DATE), CAST('1900-12-31' AS DATE))   AS  FTR_EFFECTIVE_DATE
,       COALESCE(CAST(F.FTR_EXPIRATION_DATE AS DATE), CAST('2099-12-31' AS DATE))   AS  FTR_EXPIRATION_DATE
,		ADDITIONAL_INFO
,		SWITCH_PARAM
FROM	LEGACY.FEATURE_LDR  AS  F
        INNER JOIN  LEGACY.M_USER         AS  U
                ON  (
							U.CTN        = F.CTN
					)
        INNER JOIN  LEGACY.M_SOC          AS  S
                ON  (
                            S.CTN        = F.CTN
                        AND S.SOC_Seq_No  = F.SOC_SEQ_NO
                    )
where F.FTR_EXPIRATION_DATE is null or F.FTR_EXPIRATION_DATE >= '2016-08-01'
;


*/



-- NGy 08.05
-- * INSERT
-- * INTO    /*${XTR_TB}*/ M_FEATURE
-- * (
-- * -- ---
-- *         Sub_Id
-- * -- ---
-- * ,       BAN
-- * ,       BEN
-- * ,       CTN
-- * ,       SOC_Cd
-- * ,       SOC_Seq_No
-- * ,       Feature_Cd
-- * ,       Feature_Seq_No
-- * -- ---
-- * ,       Eff_Dt
-- * ,       Exp_Dt
-- * -- ---
-- * ,   ADDITIONAL_INFO
-- * ,   SWITCH_PARAM   
-- * )
-- * select
-- *         G.Sub_Id                
-- * -- ---
-- * ,       G.BAN                   
-- * ,       G.BEN                   
-- * ,       G.CTN                   
-- * ,       G.SOC_Cd                   
-- * ,       G.SOC_Seq_No            
-- * ,       G.Feature_Cd          
-- * ,       G.Feature_Seq_No    
-- * -- ---
-- * ,       COALESCE(CAST(G.FTR_EFFECTIVE_DATE  AS DATE), CAST('2099-12-31' AS DATE))   AS  FTR_EFFECTIVE_DATE
-- * ,       COALESCE(CAST(G.FTR_EXPIRATION_DATE AS DATE), CAST('2099-12-31' AS DATE))   AS  FTR_EXPIRATION_DATE
-- * -- ---
-- * ,		G.ADDITIONAL_INFO       
-- * -- ---
-- * ,		G.SWITCH_PARAM          
-- *  
-- * from
-- * -- (select 
-- * -- --case when @n=M.SOC_SEQ_NO and @c=M.Feature_Cd then @i:=@i+1 else @i:=1 end nr,
-- * -- M.*
-- * -- -- ,@n:=M.SOC_SEQ_NO
-- * -- -- ,@c:=M.Feature_Cd
-- * -- from
-- * (SELECT
-- * -- Kivenni S.Sub_Id és tenni jobb indexet az M_SOC-ra
-- * --        S.Sub_Id                AS  Sub_Id
-- *         F.CTN                AS  Sub_Id        
-- * -- ---
-- * ,       F.BAN                   AS  BAN
-- * ,       F.BEN                   AS  BEN
-- * ,       F.CTN                   AS  CTN
-- * ,       S.SOC_Cd                AS  SOC_Cd
-- * ,       F.SOC_Seq_No            AS  SOC_Seq_No
-- * ,       F.FEATURE_CODE            AS  Feature_Cd
-- * ,       F.SERVICE_FTR_SEQ_NO        AS  Feature_Seq_No
-- * -- ---
-- * ,		NULL                    AS  ADDITIONAL_INFO
-- * -- ---
-- * ,       F.FTR_EFFECTIVE_DATE
-- * ,       F.FTR_EXPIRATION_DATE
-- * -- ---
-- * ,		NULL                    AS  SWITCH_PARAM
-- * FROM
-- *                     /*${LOAD_TB}PD_*/ LEGACY.FEATURE_LDR  AS  F
-- * -- 		inner join USR_ABO.SOC_LDR_CTN_STAT st 
-- * --      on S.CTN >= st.FromCTN and S.CTN < st.ToCTN
-- *         INNER JOIN  /*${XTR_TB}*/ LEGACY.M_USER         AS  U
-- *                 ON  (
-- * 							U.CTN        = F.CTN
-- * 					)
-- *         INNER JOIN  /*${XTR_TB}*/ LEGACY.M_SOC          AS  S
-- *                 ON  (
-- *                             S.CTN        = F.CTN
-- *                         AND /*cast(*/S.SOC_Seq_No /*as char(11))*/ = F.SOC_SEQ_NO
-- *                     )
-- * -- where st.intCnt = 1        
-- * -- ORDER BY F.SOC_SEQ_NO, F.FEATURE_CODE
-- * -- 		, F.FTR_EFFECTIVE_DATE DESC
-- * -- the previous line simplifies the next two        
-- * -- 		, COALESCE(CAST(F.FTR_EXPIRATION_DATE AS DATE), CAST('2099-12-31' AS DATE)) DESC
-- * --      , COALESCE(CAST(F.FTR_EFFECTIVE_DATE  AS DATE), CAST('2099-12-31' AS DATE)) DESC
-- * --        ) M
-- * -- ,(select @i:=0,@n:='-',@c:='-') x
-- * ) G
-- * -- where nr = 1
-- * ;
-- * 
-- * -- .if errorcode<>0 then .quit errorcode
-- * 
-- * -- COLLECT STATISTICS ON /*${XTR_TB}*/ USR_ABO.M_FEATURE INDEX (Sub_Id);
-- * -- .if errorcode<>0 then .quit errorcode
-- * 
-- * -- COLLECT STATISTICS ON /*${XTR_TB}*/ USR_ABO.M_FEATURE INDEX (Sub_Id, SOC_Cd);
-- * -- .if errorcode<>0 then .quit errorcode
-- * /*
-- * call LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE','SOC_Seq_No');
-- * call LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE','CTN');
-- * call LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE','Feature_Cd');
-- * call LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE','Feature_Seq_No');
-- * 
-- * call LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE','Sub_Id,Feature_Cd,Feature_Seq_No');
-- * */
-- * /*
-- * alter table LEGACY.M_FEATURE
-- * add INDEX IDX_M_FEATURE_SOC_Seq_No(SOC_Seq_No),
-- * add INDEX IDX_M_FEATURE_CTN(CTN),
-- * add INDEX IDX_M_FEATURE_Feature_Cd(Feature_Cd),
-- * add INDEX IDX_M_FEATURE_Feature_Seq_No(Feature_Seq_No),
-- * add INDEX IDX_M_FEATURE_Sub_Id_Feature_Cd_Feature_Seq_No(Sub_Id,Feature_Cd,Feature_Seq_No);
-- * */
-- EOF
-- ------------------- 5250_FEAT_EXTR.sql -----------------------
cat >5250_FEAT_EXTR.sql <<'-- EOF'

/* -------------------------------------------------------------------------------------------------
*  leszedjük az érintett rekordokat
*/


use LEGACY;
/*
-- MT20160901: Kivettem innen, atraktam az offer elokeszito szakaszaba.


drop table if exists M_FEATURE_EXTR;
create TABLE M_FEATURE_EXTR (
	KEY `IDX_M_FEATURE_EXTR_CTN` (`CTN`)
) engine=MyIsam
	SELECT   ban
		   , ben
		   , ctn
           -- , soc_seq_no
			-- NGy 0609 egy sor
		   , Feature_Cd  			as FEATURE_CODE
           , Eff_Dt 				as ftr_effective_date
           , Exp_Dt					as ftr_expiration_date
           , Feature_Seq_No 		as service_ftr_seq_no
           , cast('S' as char(1)) 	as add_or_swi
           , TRIM(both '@' FROM trim(switch_param)) as txt_to_split
	from M_FEATURE
	where switch_param is not null
;

insert M_FEATURE_EXTR
	SELECT   ban
		   , ben
		   , ctn
           -- , soc_seq_no
			-- NGy 0609 egy sor
		   , Feature_Cd  			as FEATURE_CODE
           , Eff_Dt 				as ftr_effective_date
           , Exp_Dt					as ftr_expiration_date
           , Feature_Seq_No 		as service_ftr_seq_no
           , cast('A' as char(1)) 	as add_or_swi
           , TRIM(both '@' FROM trim(additional_info)) as txt_to_split
	from M_FEATURE
	where additional_info is not null
;
*/
-- EOF
-- ------------------- 5260_Feat_Attributes.sql -----------------------
cat >5260_Feat_Attributes.sql <<'-- EOF'
﻿
/* ---------------------------------------------------------------------------
 *	tárolt eljaras a @-ot tartamazo oszlopok felosztasara
*/

use LEGACY;
drop procedure if exists bo_split_attrs;
delimiter $$
create procedure bo_split_attrs ( )
begin
	declare l_ctn VARCHAR(30);

    
    kukac_loop: LOOP
		drop table if exists M_FEATURE_EXTR_WORK;
		create table M_FEATURE_EXTR_WORK like M_FEATURE_EXTR;

		insert M_FEATURE_EXTR_WORK
		select  
				add_or_swi
		,		ban
		,		ben
		,		ctn
		,		SOC_Cd         
		,		SOC_Seq_No 
           -- , soc_seq_no
		-- NGy 0609 egy sor
			, FEATURE_CODE
           , ftr_effective_date
           , ftr_expiration_date
		,		service_ftr_seq_no
		,		substring( txt_to_split, 1, INSTR(txt_to_split,'@') - 1 ) as txt_to_split
        from M_FEATURE_EXTR
		where INSTR(txt_to_split,'@') > 1
        
		union
        
		select  
				add_or_swi
		,		ban
		,		ben
		,		ctn
		,		SOC_Cd         
		,		SOC_Seq_No 
           -- , soc_seq_no
		-- NGy 0609 egy sor
			, FEATURE_CODE
           , ftr_effective_date
           , ftr_expiration_date
		,		service_ftr_seq_no
		,		substring( txt_to_split, INSTR(txt_to_split,'@') + 1 ) as txt_to_split
        from M_FEATURE_EXTR
		;
    
		drop table if exists M_FEATURE_EXTR;
        rename table M_FEATURE_EXTR_WORK TO M_FEATURE_EXTR;
        
        set l_ctn := null;
        select ctn
          into l_ctn
		from M_FEATURE_EXTR
        where INSTR(txt_to_split,'@') > 1
        limit 1;
        
        if l_ctn is null then leave kukac_loop; end if;
        
	end loop;
    
    drop table if exists M_FEATURE_ATTRS;
    CREATE TABLE M_FEATURE_ATTRS (
		BAN varchar(30) DEFAULT NULL,
		BEN varchar(30) DEFAULT NULL,
		CTN varchar(30) DEFAULT NULL,
		-- SOC_SEQ_NO varchar(30) DEFAULT NULL,
		-- NGy 0609 egy sor
			FEATURE_CODE  varchar(6) default null,
        ftr_effective_date varchar(30) DEFAULT NULL,
        ftr_expiration_date varchar(30) DEFAULT NULL,
		SERVICE_FTR_SEQ_NO varchar(30) DEFAULT NULL,
		add_or_swi char(1) DEFAULT NULL,
		attr_code varchar(200) DEFAULT NULL,
		attr_val varchar(200) DEFAULT NULL
	) engine MyISAM;

    insert M_FEATURE_ATTRS
		select  ban
		,		ben
		,		ctn
           -- , soc_seq_no
		-- NGy 0609 egy sor
			, FEATURE_CODE
           , ftr_effective_date
           , ftr_expiration_date
		,		service_ftr_seq_no
		, 		add_or_swi
		,		trim( substring( txt_to_split, 1, INSTR(txt_to_split,'=') - 1 )) as attr_code
        ,		trim( substring( txt_to_split, INSTR(txt_to_split,'=') + 1 )) as attr_val
        from M_FEATURE_EXTR
		where 
           substring( txt_to_split, 1, INSTR(txt_to_split,'=') - 1 ) in (
				SELECT distinct LEGACY_PARAM_name 
				  from LEGACY.M_IDID_ATTR_MOD
           		 WHERE LEGACY_PARAM_name IS NOT null )
         and length( trim( substring( txt_to_split, 1, INSTR(txt_to_split,'=') - 1 ))) > 0
         and length( trim( substring( txt_to_split, INSTR(txt_to_split,'=') + 1 ))) > 0
	;
 
end$$
delimiter ;









/*	-----------------------------------------------------------------------------------------
* 	igy lehet meghivni
*/
 use LEGACY;
 CALL bo_split_attrs;
-- EOF
-- ------------------- 5340_BO_Mapping_Merge_Offer_Products.sql -----------------------
cat >5340_BO_Mapping_Merge_Offer_Products.sql <<'-- EOF'
-- 5340.
USE LEGACY;
/* # ident "%W%    %E%    @@" */
/****************************************************************************
 *
 *  Filename    : %M%
 *  Part of     : ...
 *  Type        : Bteq
 *  Job         : ...
 *
 *  -------------------------------------------------------------------------
 *  Purpose     : ...
 *
 *  Comments    :
 *
 *  Datasource  :
 *  -------------------------------------------------------------------------
 *  DB-Version  : TERADATA V13
 *  UNIX-Version: Red Hat Enterprise Linux Server release 5.7 (Tikanga)
 *
 *  -------------------------------------------------------------------------
 *  Project     : OPP
 *  Subproject  : BO Migration
 *
 *  Author      : Berkó Tamás
 *  Department  : TD
 *  Version     : %I%
 *  Date        : %E%
 *
 *  (c) 2016 by UniCon
 *  -------------------------------------------------------------------------
 *  History:
 *
 *  1.1   2016/05/03    Berkó Tamás
 *        OPP project - BO Migration
 *        - DR2 preparation
 *
 ****************************************************************************
*/








/*

MT 20160915:
  En irtam at Tgt_Offer_Id-sre ezt a reszt, mert elrontotta a split type-okat.
  Postpaid-bol prepaid-et csinalt.

*/











-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : DROP TABLE
-- <Table> : /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD
-- <Brief> : Mapping munka táblák eldobása
-- ------------------------------------------------------------------------------------------</###>--

-- .set errorlevel (3807) severity 0
DROP TABLE if exists /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD;
-- .set errorlevel (3807) severity 8



-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : CREATE TABLE AS ...
-- <Table> : /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD
-- <Brief> : Mapping munka tábla feltöltése
-- <Desc>  : Product mapping adatok ...
-- ------------------------------------------------------------------------------------------</###>--

CREATE TABLE /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD (
    `Sub_Id` INT(11) NOT NULL,
    `Tgt_Offer_Id` VARCHAR(30) NOT NULL,
    `Tgt_Offer_Cd` VARCHAR(30) NOT NULL,
    `Tgt_Offer_Type` CHAR(1) DEFAULT NULL,
    `Product_Id` BIGINT(20) NOT NULL,
    `MDM_Type_Cd` VARCHAR(30) NOT NULL,
    `Main_Prod_Ind` VARCHAR(1) NOT NULL,
    `Service_Flag` VARCHAR(100) DEFAULT NULL,
    `Feature_Cd` VARCHAR(100) DEFAULT NULL,
    `Feature_Switch_Ind` CHAR(1) DEFAULT NULL,
    `Feature_Order_No` SMALLINT(6) DEFAULT NULL,
    `SOC_Cd` CHAR(9) DEFAULT NULL,
    `SOC_Seq_No` INT(11) DEFAULT NULL,
    `Feature_Seq_No` DECIMAL(10 , 0 ) DEFAULT NULL,
    `Eff_Dt` DATE DEFAULT NULL,
    `Exp_Dt` DATE DEFAULT NULL -- ,
    -- PRIMARY KEY (`Sub_Id`),
    -- KEY `Sub_Id` (`Sub_Id` , `Tgt_Offer_Cd`)
);

INSERT INTO `LEGACY`.`M_OFFER_M12_MERGE_PRD`
(`Sub_Id`,
`Tgt_Offer_Id`,
`Tgt_Offer_Cd`,
`Tgt_Offer_Type`,
`Product_Id`,
`MDM_Type_Cd`,
`Main_Prod_Ind`,
`Service_Flag`,
`Feature_Cd` -- ,

)
 SELECT
           '1' AS Sub_Id
    ,      'DUMMY' AS Tgt_Offer_Id
    ,      'DUMMY' AS Tgt_Offer_Cd
    ,       'D' AS  Tgt_Offer_Type
    ,       '1' AS Product_Id
    ,       'DUMMY' AS  MDM_Type_Cd
    ,       '1' AS  Main_Prod_Ind
    ,       'DUMMY' AS  Service_Flag

    ,       'DUMMY' AS  Feature_CD
;

DROP TABLE IF EXISTS LEGACY.M_OFFER_M10_MERGE_PRD_W;
call LEGACY.createindex_ifnotexists('LEGACY','M_IDID_OFFER_MOD','Use_Flag,Split_Type,MDM_Type_Cd');

CREATE TABLE LEGACY.M_OFFER_M10_MERGE_PRD_W as
  SELECT
          OFR.Relat_Offer_Id Tgt_Offer_Id
  ,       OFR.Tgt_Offer_Cd
  ,       OFR.Veris_Object_Id AS Product_Id
  ,       OFR.MDM_Type_Cd
  ,       OFR.Service_Flag
  ,       PRD.Feature_Cd
  FROM
                      /*${WORK_TB}*/ M_IDID_OFFER_MOD   AS  OFR
          LEFT  JOIN  /*${WORK_TB}*/ (SELECT DISTINCT Product_Id, Feature_Cd FROM M_IDID_ATTR_MOD)    AS  PRD
                  ON  (
                          OFR.Veris_Object_Id = PRD.Product_Id
                      )
  WHERE
          (OFR.Use_Flag = 'Y' or OFR.Split_Type in (2,4,10) )
  AND     (
                  OFR.MDM_Type_Cd = 'PRICE_PROD'
              OR  (OFR.MDM_Type_Cd = 'SRVC_SINGLE' AND OFR.Service_Flag LIKE '%Mandatory%')
              OR  (OFR.MDM_Type_Cd = 'SRVC_SINGLE' AND PRD.Feature_Cd IS NOT NULL)
          );
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M10_MERGE_PRD_W','Tgt_Offer_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M10_MERGE_PRD_W','Tgt_Offer_Id');

INSERT INTO `LEGACY`.`M_OFFER_M12_MERGE_PRD`
(`Sub_Id`,
`Tgt_Offer_Id`,
`Tgt_Offer_Cd`,
`Tgt_Offer_Type`,
`Product_Id`,
`MDM_Type_Cd`,
`Main_Prod_Ind`,
`Service_Flag`,
`Feature_Cd` -- ,
-- `Feature_Switch_Ind`,
-- `Feature_Order_No`,
-- `SOC_Cd`,
-- `SOC_Seq_No`,
-- `Feature_Seq_No`,
-- `Eff_Dt`,
-- `Exp_Dt`
)
SELECT
        M.Sub_Id
,       M.Tgt_Offer_Id
,       M.Tgt_Offer_Cd
,       M.Tgt_Offer_Type
,       R.Product_Id
,       R.MDM_Type_Cd
,       (CASE WHEN (M.Product_Id = R.Product_Id) THEN 'Y' ELSE 'N' END) AS  Main_Prod_Ind
,       R.Service_Flag

,       (CASE WHEN (R.Feature_Cd IS NOT NULL)                       THEN R.Feature_Cd
              WHEN (M.Tgt_Offer_Type = 'T' AND (M.Product_Id = R.Product_Id)) THEN 'PPCPKG'
              WHEN (R.MDM_Type_Cd = 'PRICE_PROD')                   THEN 'CPKG'
                                                                    ELSE NULL
        END)  AS  Feature_Cd
FROM
            M_OFFER_M10_MERGE               AS  M
INNER JOIN  LEGACY.M_OFFER_M10_MERGE_PRD_W  AS  R
        ON  M.Tgt_Offer_Id = R.Tgt_Offer_Id
;


-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : UPDATE
-- <Table> : /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD
-- <Brief> : Munka tábla karbantartása
-- <Desc>  : ...
-- ------------------------------------------------------------------------------------------</###>--

-- ????
-- ??? UPDATE  PRD
-- ??? FROM    /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD   AS  PRD
-- ??? ,       (
-- ???             SELECT
-- ???                     F.Feature_Code  AS  Feature_Cd
-- ???             FROM
-- ???                                 /*${WORK_TB}*/ M_REF_Base_Feature  AS  B
-- ???                     INNER JOIN  /*${WORK_TB}*/ M_REF_Feature       AS  F
-- ???                             ON  (
-- ???                                         F.MPS_Feature_Code = B.Base_Feature_Code
-- ???                                     AND B.Billing_Switch_Ind = 'Y'
-- ???                                 )
-- ???         )
-- ???         AS  REF
-- ??? SET     Feature_Switch_Ind = 'Y'
-- ??? WHERE   PRD.Feature_Cd = REF.Feature_Cd
-- ??? ;
-- .if errorcode<>0 then .quit errorcode



-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : UPDATE
-- <Table> : /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD
-- <Brief> : Munka tábla karbantartása
-- <Desc>  : Megsorszámozzuk az azonos Feature_Cd-ket Sub_Id-n belül.
--           - Az update-hez biztosítottuk a (Sub_Id, Tgt_Offer_Cd, Product_Id) egyediségét.
-- ------------------------------------------------------------------------------------------</###>--
SET SQL_SAFE_UPDATES=0;

call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M12_MERGE_PRD','Feature_Cd,Feature_Order_No,Sub_Id');
-- call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M12_MERGE_PRD','Sub_Id,Feature_Cd,Feature_Order_No');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M12_MERGE_PRD','Sub_Id,Tgt_Offer_Cd,Product_Id');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M12_MERGE_PRD','Sub_Id,Tgt_Offer_Id,Product_Id');


UPDATE  /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD as PRD
JOIN (
            SELECT
                    Sub_Id
            ,       Tgt_Offer_Id
            ,       Tgt_Offer_Cd
            ,       Product_Id
            ,case when @n=Sub_Id and @c=Feature_Cd then @i:=@i+1 else @i:=1 end
                                      AS Feature_Order_No
            , @n:=Sub_Id  n
            , @c:=Feature_Cd c
            FROM
                    M_OFFER_M12_MERGE_PRD
            WHERE
                    Feature_Cd IS NOT NULL
            order by  Sub_Id
                    , Feature_Cd
                    , (CASE WHEN TGT_Offer_Type = 'T' THEN 1 ELSE 2 END)
                    , Tgt_Offer_Cd
                    , Tgt_Offer_Id
                    , Product_Id
        ) AS  SEQ
    ON      PRD.Sub_Id       = SEQ.Sub_Id
--    AND     PRD.Tgt_Offer_Cd = SEQ.Tgt_Offer_Cd
    AND     PRD.Tgt_Offer_Id = SEQ.Tgt_Offer_Id
    AND     PRD.Product_Id   = SEQ.Product_Id
SET     PRD.Feature_Order_No = SEQ.Feature_Order_No
;


SET SQL_SAFE_UPDATES=1;


-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : UPDATE
-- <Table> : /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD
-- <Brief> : Munka tábla karbantartása
-- <Desc>  : Megsorszámozzuk az azonos Feature_Cd-ket Sub_Id-n belül.
--           - Sub_Id / Feature_Cd szerinti párosítás ... itt még a SOC-ot figyelembe kellene
--             venni, ha van.
--           - PPCPKG ~~ Main Offer / Main Product (Sub_Id-re mindkettő egyedi kell hogy legyen.)
--           - CPKG   ~~ Egyéb PRICE_PROD
-- ------------------------------------------------------------------------------------------</###>--

SET SQL_SAFE_UPDATES=0;
-- call LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE','Sub_Id,Feature_Cd,Feature_Seq_No');


UPDATE  /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD   AS  PRD
JOIN    (
            SELECT
                    CTN Sub_Id
            ,       SOC_Cd
            ,       SOC_Seq_No
            ,       FEATURE_CODE Feature_Cd
            ,       SERVICE_FTR_SEQ_NO Feature_Seq_No
            ,       FTR_EFFECTIVE_DATE Eff_Dt
            ,       FTR_EXPIRATION_DATE Exp_Dt
            ,case when @n=CTN and @c=FEATURE_CODE then @i:=@i+1 else @i:=1 end
                                      AS Feature_Order_No
            , @n:=CTN  n
            , @c:=FEATURE_CODE c
            FROM
                    -- M_FEATURE
                    M_FEATURE_EXTR
            order by  Sub_Id
                    , FEATURE_CODE
                    , SERVICE_FTR_SEQ_NO
        )
        AS  FTR
ON      PRD.Sub_Id           = FTR.Sub_Id
AND     PRD.Feature_Cd       = FTR.Feature_Cd
AND     PRD.Feature_Order_No = FTR.Feature_Order_No
SET
        PRD.SOC_Cd         = FTR.SOC_Cd
,       PRD.SOC_Seq_No     = FTR.SOC_Seq_No
,       PRD.Feature_Seq_No = FTR.Feature_Seq_No
,       PRD.Eff_Dt         = FTR.Eff_Dt
,       PRD.Exp_Dt         = FTR.Exp_Dt
WHERE
-- --------
        PRD.Feature_Cd IS NOT NULL
-- --------
;
-- .if errorcode<>0 then .quit errorcode

SET SQL_SAFE_UPDATES=1;


-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : UPDATE
-- <Table> : /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD
-- <Brief> : Munka tábla karbantartása
-- <Desc>  : Feature_Seq_No "kiosztása"
--           - Akihez nincs Feature_Seq_No, de van hozzá Feature_Cd ( vagyis Feature_Cd alapon,
--             vagy Mandatory / PRICE_PROD alapon került ide: PPCPKG, CPKG) azokat migráljuk,
--             tehát jobb híján osztunk egy szekvencia sorszámot.
--             (Fejlesztéskor a MAX(Feature_Seq_No) értéke 1,298,193,866 volt.)
-- ------------------------------------------------------------------------------------------</###>--

SET SQL_SAFE_UPDATES=0;
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M12_MERGE_PRD','Feature_Seq_No,Feature_Cd');

set @i:=2000000000;
UPDATE  /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD   AS  PRD
JOIN    (
            SELECT
                    Sub_Id
            ,       Tgt_Offer_Id
            ,       Tgt_Offer_Cd
            ,       Product_Id
            ,       @i:=@i+1
                                          AS GEN_Feature_Seq_No
            FROM
                    /*${WORK_TB}*/ M_OFFER_M12_MERGE_PRD
            WHERE
                    Feature_Cd IS NOT NULL
            AND     Feature_Seq_No IS NULL
            ORDER BY Sub_Id
                   , (CASE WHEN TGT_Offer_Type = 'T' THEN 1 ELSE 2 END)
                   , Tgt_Offer_Cd
                   , Tgt_Offer_Id
                   , Product_Id
        )
        AS  SEQ
ON
        PRD.Sub_Id       = SEQ.Sub_Id
-- AND     PRD.Tgt_Offer_Cd = SEQ.Tgt_Offer_Cd
AND     PRD.Tgt_Offer_Id = SEQ.Tgt_Offer_Id
AND     PRD.Product_Id   = SEQ.Product_Id
SET     Feature_Seq_No = SEQ.GEN_Feature_Seq_No
-- WHERE
;
-- .if errorcode<>0 then .quit errorcode
SET SQL_SAFE_UPDATES=1;
-- EOF
-- ------------------- 5390_BO_Mapping_Merge_Offer_ALL_Levels.sql -----------------------
cat >5390_BO_Mapping_Merge_Offer_ALL_Levels.sql <<'-- EOF'
-- 5390.
USE LEGACY;

-- -------------------------------------------------------------------------------------------------------
-- MT: Valamiert le van az egesz attributumos tema allitva. Csak a Split_Type=4-re megprobalom beinditani:
update M_OFFER_M20_MERGE_ALL
set
--   Main_Prod_Ind='Y',
  Service_Attr_Id='810301'
where Split_Type=4
;


-- call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M12_MERGE_PRD','Sub_Id,Tgt_Offer_Cd,Feature_Seq_No');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M20_MERGE_ALL','Sub_Id,Tgt_Offer_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M20_MERGE_ALL','Sub_Id,Tgt_Offer_Id');

DROP TABLE IF EXISTS M_OFFER_M20_MERGE_ALL_WORK;


CREATE TABLE  M_OFFER_M20_MERGE_ALL_WORK AS
    SELECT
            M.CA_Id
    ,       M.BAN
    ,       M.BEN
    ,       M.CTN
    ,       M.IMSI
    ,       M.Init_Act_Dt
    ,       M.User_Eff_Dt
    ,       M.User_Exp_Dt
    ,       M.Sub_Status_Cd
    ,       M.Sub_Status_Last_Act
    ,       M.Sub_Status_Rsn_Cd
    ,       M.Tgt_Offer_Inst_Id
    ,       M.Tgt_Offer_Cd
    ,       M.Tgt_Offer_Id
    ,       M.Tgt_Offer_Name
    ,       M.Tgt_Offer_Type
    ,       M.Svc_Class_Cd
    ,       M.Offer_Eff_Dt
    ,       M.Offer_Exp_Dt
    ,       P.Feature_Seq_No                                                     AS  Feature_Seq_No
    ,       P.Feature_Cd                                                         AS  Feature_Cd
    ,       COALESCE(P.Eff_Dt, M.Feature_Eff_Dt)                                 AS  Feature_Eff_Dt
    ,       COALESCE(P.Exp_Dt, M.Feature_Exp_Dt)                                 AS  Feature_Exp_Dt
    ,       P.Main_Prod_Ind
    ,       P.Product_Id
    ,       P.MDM_Type_Cd
    ,       CASE WHEN (P.Main_Prod_Ind = 'Y' or M.Split_Type=4 )
                 THEN M.Service_Id
                 ELSE NULL
            END                                                                  AS  Service_Id
    ,       CASE WHEN (P.Main_Prod_Ind = 'Y' or M.Split_Type=4 )
                 THEN M.Service_Attr_Id
                 ELSE NULL
            END                                                                  AS  Service_Attr_Id
    ,       CASE WHEN ((P.Main_Prod_Ind = 'Y' or M.Split_Type=4) AND M.Service_Attr_Id IS NOT NULL)
                 THEN M.Service_Attr_Value
                 ELSE NULL
            END                                                                  AS  Service_Attr_Value
--    ,       M.Service_Attr_Value                                               AS  Service_Attr_Value

    FROM        M_OFFER_M20_MERGE_ALL   AS  M
    INNER JOIN  M_OFFER_M12_MERGE_PRD   AS  P
                    ON  (
                                M.Sub_Id       = P.Sub_Id
                            AND M.Tgt_Offer_Cd = P.Tgt_Offer_Cd
                            AND P.Feature_Seq_No IS NOT NULL
                        )

;


DROP TABLE IF EXISTS SOC_FEATURE_OFFER_MAPPING;

CREATE TABLE SOC_FEATURE_OFFER_MAPPING AS

SELECT DISTINCT
      CA_Id                                                   AS CA
    , BAN                                                     AS BAN
    , BEN                                                     AS BEN
    , CTN                                                     AS CTN
    , IMSI                                                    AS IMSI
    , CAST(COALESCE(Init_Act_Dt,'2099-12-31') AS DATE)        AS INIT_ACTIVATION_DATE
    , CAST(COALESCE(User_Eff_Dt,'1900-01-01') AS DATE)        AS USER_EFFECTIVE_DATE
    , CAST(COALESCE(User_Exp_Dt,'2099-12-31') AS DATE)        AS USER_EXPIRATION_DATE
    , ''                                                      AS SUBSCRIBER_REF
    , Sub_Status_Cd                                           AS SUB_STATUS
    , Sub_Status_Last_Act                                     AS SUB_STATUS_LAST_ACT
    , Sub_Status_Rsn_Cd                                       AS SUB_STATUS_RSN_CODE
    , Tgt_Offer_Inst_Id                                       AS MAIN_SOC_SEQ_NO
    , Tgt_Offer_Cd                                            AS MAIN_SOC_CODE
    , Tgt_Offer_Inst_Id                                       AS SOC_SEQ_NO
    , Tgt_Offer_Cd                                            AS SOC_CODE
    , '0'                                                     AS MAP_COMBO_ID
    , Tgt_Offer_Cd                                            AS TEMP_OFFER_CODE
    , Tgt_Offer_Id                                            AS VERIS_OFFER_ID
    , Tgt_Offer_Name                                          AS OFFER_NAME
    , Tgt_Offer_Type                                          AS OFFER_TYPE
    , Svc_Class_Cd                                            AS SERVICE_CLASS_CD
    , CAST(COALESCE(Offer_Eff_Dt,'1900-01-01') AS DATE)       AS SOC_EFFECTIVE_DATE
    , CAST(COALESCE(Offer_Exp_Dt,'2099-12-31') AS DATE)       AS SOC_EXPIRATION_DATE
    , Feature_Seq_No                                          AS FEATURE_SEQ_NO
    , CAST(COALESCE(Feature_Eff_Dt,'1900-01-01') AS DATE)     AS FEATURE_EFFECTIVE_DATE
    , CAST(COALESCE(Feature_Exp_Dt,'2099-12-31') AS DATE)     AS FEATURE_EXPIRATION_DATE
    , Feature_Cd                                              AS LEGACY_FEATURE_CODE
    , CAST(COALESCE(Main_Prod_Ind,'N') AS CHAR(1))            AS MAIN_FEATURE_FLAG
    , Product_Id                                              AS VERIS_PRODUCT_ID
    , MDM_Type_Cd                                             AS MDM_TYPE
    , Service_Id                                              AS VERIS_SERVICE_ID
    , Service_Attr_Id                                         AS VERIS_SERVICE_ATTR_ID
    , Service_Attr_Value                                      AS SERVICE_ATTR_VALUE

FROM LEGACY.M_OFFER_M20_MERGE_ALL_WORK
;

-- EOF
-- ------------------- 6050_INSERT_INS_PROD.sql -----------------------
cat >6050_INSERT_INS_PROD.sql <<'-- EOF'
-- 6050.
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
            THEN concat(M.VERIS_PRODUCT_ID,M.CTN,M.MAIN_SOC_SEQ_NO)
          ELSE CONCAT(M.SOC_SEQ_NO,M.CTN)
     END                                                        AS PROD_INST_ID
    ,CONCAT(M.CTN, M.MAIN_SOC_SEQ_NO, M.VERIS_OFFER_ID)         AS OFFER_USER_RELAT_ID
    ,CONCAT(M.MAIN_SOC_SEQ_NO, M.VERIS_OFFER_ID)           AS OFFER_INST_ID
    ,M.CTN
    ,M.VERIS_PRODUCT_ID
    ,M.MDM_TYPE
    ,'0'
    ,CASE WHEN M.FEATURE_EXPIRATION_DATE < SYSDATE()
            THEN '7'
          ELSE '1'
     END
    ,CASE WHEN M.FEATURE_EFFECTIVE_DATE IS NULL
            THEN '1900-01-01 00:00:00'
          WHEN M.FEATURE_EFFECTIVE_DATE > M.FEATURE_EXPIRATION_DATE
            THEN M.FEATURE_EXPIRATION_DATE
          ELSE M.FEATURE_EFFECTIVE_DATE
     END                                                        AS EFFECTIVE_DATE
    ,CASE WHEN M.FEATURE_EXPIRATION_DATE IS NULL
            THEN '2099-12-31 23:59:59'
          WHEN M.FEATURE_EXPIRATION_DATE > '2099-12-31 23:59:59'
            THEN '2099-12-31 23:59:59'
          ELSE M.FEATURE_EXPIRATION_DATE
     END                                                        AS EXPIRE_DATE

FROM LEGACY.SOC_FEATURE_OFFER_MAPPING M
join MDM.INS_USER U on U.USER_ID=M.CTN
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
    ,concat('4000000000',lpad(@id:=@id+1,10,'0'))   AS PROD_INST_ID
    ,CONCAT(F.CTN, F.MAIN_SOC_SEQ_NO)               AS OFFER_USER_RELAT_ID
    ,CONCAT(F.MAIN_SOC_SEQ_NO,F.VERIS_OFFER_ID)     AS OFFER_INST_ID
    ,F.CTN                                          AS USER_ID
    ,ia.OBJECT_ID                                   AS PROD_ID
    ,'PRICE_PROD'                                   AS PROD_TYPE
    ,'0'                                            AS EXPIRE_PROCESS_TYPE
    ,'1'                                            AS STATE
    ,'1900-01-01 00:00:00'                          AS EFFECTIVE_DATE
    ,'2099-12-31 23:59:59'                          AS EXPIRE_DATE

FROM    LEGACY.SOC_FEATURE_OFFER_MAPPING            AS F
--    FORCE INDEX (IDX_SOC_FEATURE_OFFER_MAPPING_VERIS_OFFER_ID)

 join   LEGACY.BO_ID2ID_MAIN_OFFER_LDR              AS ia
--   FORCE INDEX (IDX_BO_ID2ID_MAIN_OFFER_LDR_OFFER_ID)

        on  ia.OFFER_ID  = CAST(F.VERIS_OFFER_ID AS CHAR)
       and  ia.MDM_TYPE                   = 'PRICE_PROD'

 left outer join MDM.INS_PROD                       AS P
        on P.USER_ID = F.CTN
       and P.PROD_ID = ia.OBJECT_ID

 join
    (select
        @id:=coalesce(max(cast(right(PROD_INST_ID,10) as UNSIGNED)),0)
     from MDM.INS_PROD
     where PROD_INST_ID like '4000000000__________'
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
    ,concat('4000000000',lpad(@id:=@id+1,10,'0'))   AS PROD_INST_ID
    ,CONCAT(F.CTN, F.MAIN_SOC_SEQ_NO)               AS OFFER_USER_RELAT_ID
    ,CONCAT(F.MAIN_SOC_SEQ_NO,F.VERIS_OFFER_ID)     AS OFFER_INST_ID
    ,F.CTN                                          AS USER_ID
    ,ia.OBJECT_ID                                   AS PROD_ID
    ,'SRVC_SINGLE'                                  AS PROD_TYPE
    ,'0'                                            AS EXPIRE_PROCESS_TYPE
    ,'1'                                            AS STATE
    ,'1900-01-01 00:00:00'                          AS EFFECTIVE_DATE
    ,'2099-12-31 23:59:59'                          AS EXPIRE_DATE
FROM
LEGACY.SOC_FEATURE_OFFER_MAPPING F
 join LEGACY.BO_ID2ID_ADDON_OFFER_LDR ia
    on cast(F.VERIS_OFFER_ID as char)=ia.OFFER_ID
    and 'SRVC_SINGLE'=ia.MDM_TYPE
 left outer join MDM.INS_PROD P
    on F.CTN=P.USER_ID
    and ia.OBJECT_ID=P.PROD_ID
 join
    (select
        @id:=coalesce(max(cast(right(PROD_INST_ID,10) as UNSIGNED)),0)
     from MDM.INS_PROD
     where PROD_INST_ID like '4000000000__________'
    ) x
    on 1=1
where 1=1
 and P.USER_ID is null
;




-- EOF
-- ------------------- 6070_INSERT_INS_PROD_SRV.sql -----------------------
cat >6070_INSERT_INS_PROD_SRV.sql <<'-- EOF'

INSERT INTO MDM.INS_PROD_INS_SRV
(
     TENANT_ID
    ,PROD_SRV_RELAT_ID
    ,OFFER_INST_ID
    ,PROD_INST_ID
    ,USER_ID
    ,SERVICE_ID
    ,STATE
)

SELECT * FROM
(
    SELECT
        '22'
        ,CONCAT (X.SOC_SEQ_NO, X.FEATURE_SEQ_NO, X.VERIS_SERVICE_ID)
        ,CONCAT(X.MAIN_SOC_SEQ_NO,X.VERIS_OFFER_ID)							AS OFFER_INST_ID
        ,CASE WHEN FEATURE_SEQ_NO IS NOT NULL
            THEN concat(VERIS_PRODUCT_ID,CTN,MAIN_SOC_SEQ_NO)
          ELSE CONCAT(SOC_SEQ_NO,CTN)
		 END                                                                AS PROD_INST_ID
        ,X.CTN
        ,X.VERIS_SERVICE_ID
        ,'1'

    FROM LEGACY.SOC_FEATURE_OFFER_MAPPING X
    JOIN (select @rownum :=0) r
        on 1 = 1
    WHERE   X.VERIS_PRODUCT_ID IS NOT NULL
        AND X.VERIS_SERVICE_ID IS NOT NULL
    -- AND X.CTN IN (SELECT DISTINCT CTN FROM LEGACY.SOC_FEATURE_OFFER_MAPPING WHERE OFFER_TYPE = 'T')
    ) Y
;


--
-- A Pandocs agon bekerult elofizetok "B2C-like" utanakuldese
-- mgy 2016.08.24
--

call LEGACY.createindex_ifnotexists('MDM','INS_PROD_INS_SRV','OFFER_INST_ID');

INSERT INTO MDM.INS_PROD_INS_SRV
(
     TENANT_ID
    ,PROD_SRV_RELAT_ID
    ,OFFER_INST_ID
    ,PROD_INST_ID
    ,USER_ID
    ,SERVICE_ID
    ,STATE
)
SELECT 
'22' TENANT_ID, 
CONCAT('6000000',@rownum := @rownum + 1) ,
P.OFFER_INST_ID,
P.PROD_INST_ID,
P.USER_ID,
I.SERV_ID,
P.STATE
FROM MDM.INS_PROD P
join (select distinct PRODUCT_ID PROD_ID, SERVICE_ID SERV_ID from LEGACY.M_IDID_ATTR_MOD) I
on P.PROD_ID = I.PROD_ID
join (select @rownum:=0) r on 1=1
left outer join MDM.INS_PROD_INS_SRV PS
on P.OFFER_INST_ID=PS.OFFER_INST_ID
WHERE PS.OFFER_INST_ID is null
-- and P.OFFER_INST_ID = '35078052320010022'
;    

-- EOF
-- ------------------- 6080_INSERT_INS_SRV_ATTR.sql -----------------------
cat >6080_INSERT_INS_SRV_ATTR.sql <<'-- EOF'


INSERT INTO MDM.INS_SRV_ATTR
(
     TENANT_ID
    ,ATTR_INST_ID
    ,PROD_SRV_RELAT_ID
    ,OFFER_INST_ID
    ,USER_ID
    ,SERVICE_ID
    ,ATTR_ID
    ,ATTR_VALUE
    ,ATTR_TEXT
    ,STATE
    ,SORT_ID
    ,ATTR_BATCH
    ,EFFECTIVE_DATE
    ,EXPIRE_DATE
)

SELECT
     '22'                                                           -- TENANT_ID
    ,CONCAT('100000000',@rownum := @rownum + 1)                     -- ATTR_INST_ID
    ,CONCAT(X.SOC_SEQ_NO, X.FEATURE_SEQ_NO, X.VERIS_SERVICE_ID)     -- PROD_SRV_RELAT_ID,
    ,CONCAT(X.MAIN_SOC_SEQ_NO,X.VERIS_OFFER_ID)                     -- OFFER_INST_ID
    ,X.CTN                                                          -- USER_ID
    ,X.VERIS_SERVICE_ID                                             -- SERVICE_ID
    ,X.VERIS_SERVICE_ATTR_ID                                        -- ATTR_ID
    ,X.SERVICE_ATTR_VALUE                                           -- ATTR_VALUE
    ,X.SERVICE_ATTR_VALUE                                           -- ATTR_TEXT
    ,CASE WHEN FEATURE_EXPIRATION_DATE < SYSDATE()
            THEN '7'
          ELSE '1'
     END                                                            -- STATE
    ,'99'                                                           -- SORT_ID
    ,'null'                                                         -- ATTR_BATCH
    ,CASE WHEN FEATURE_EFFECTIVE_DATE IS NULL
            THEN '1900-01-01 00:00:00'
          WHEN FEATURE_EFFECTIVE_DATE > FEATURE_EXPIRATION_DATE
            THEN FEATURE_EXPIRATION_DATE
          ELSE FEATURE_EFFECTIVE_DATE
     END                                                            AS EFFECTIVE_DATE
    ,CASE WHEN FEATURE_EXPIRATION_DATE IS NULL
            THEN '2099-12-31 23:59:59'
          WHEN FEATURE_EXPIRATION_DATE > '2099-12-31 23:59:59'
            THEN '2099-12-31 23:59:59'
          ELSE FEATURE_EXPIRATION_DATE
     END                                                            AS EXPIRE_DATE

    FROM  LEGACY.SOC_FEATURE_OFFER_MAPPING X

    JOIN (select @rownum :=0) r
        ON 1 = 1
    WHERE
            X.VERIS_SERVICE_ATTR_ID IS NOT NULL
        AND X.SERVICE_ATTR_VALUE IS NOT NULL
--      AND X.CTN IN (SELECT DISTINCT CTN FROM LEGACY.SOC_FEATURE_OFFER_MAPPING WHERE OFFER_TYPE = 'T')

;



-- NGy 08.08
/*
select @rownum := max(cast(trim(substring(ATTR_INST_ID, 10 )) as unsigned))
from MDM.INS_SRV_ATTR
where ATTR_INST_ID like '100000000%';
*/

-- Repeta extract(EDSZ_LDR) - ABCONPRS Addon - Hitelkeret
-- 
-- select MDM_TYPE_CD, VERIS_OBJECT_ID
-- from LEGACY.M_IDID_OFFER_MOD
-- where TGT_OFFER_CD = 'ABCONPRS';
-- GSM_VAS	20008717
-- PRICE_PROD	1003455
-- SRVC_SINGLE	20008718
-- 
-- select product_id, service_id, service_attr_id 
-- from LEGACY.M_IDID_ATTR_MOD
-- where product_id = '1003455';
-- 1003455	31003455	10760

call LEGACY.createindex_ifnotexists('MDM','INS_PROD_INS_SRV','SERVICE_ID');
call LEGACY.createindex_ifnotexists('LEGACY','EDSZ_LDR','CTN');

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
  
  SELECT
	'22', 										-- TENANT_ID
    CONCAT('100000000',@rownum := @rownum + 1), -- ATTR_INST_ID,
    S.PROD_SRV_RELAT_ID, 						-- PROD_SRV_RELAT_ID
    S.OFFER_INST_ID, 							-- OFFER_INST_ID
    S.USER_ID, 									-- USER_ID
    S.SERVICE_ID, 								-- SERVICE_ID
    '10760', 									-- ATTR_ID
    E.amount, 									-- ATTR_VALUE
    E.amount, 									-- ATTR_TEXT
    S.STATE, 									-- STATE
    '99999', 									-- SORT_ID
    'null', 									-- ATTR_BATCH
	IU.effective_date,							-- EFFECTIVE_DATE !!! offer-bol inkabb ???
	IU.expire_date								-- EXPIREE_DATE
  FROM MDM.INS_PROD_INS_SRV S, LEGACY.EDSZ_LDR E, MDM.INS_USER IU 
 WHERE S.USER_ID = E.ctn
   and S.USER_ID = IU.USER_ID
   and S.service_id = '31003455' 
;    
-- EOF
-- ------------------- 6090_INSERT_CAR_CARD.sql -----------------------
cat >6090_INSERT_CAR_CARD.sql <<'-- EOF'
-- Insert service to prod 800012

INSERT INTO MDM.INS_PROD_INS_SRV
(
     TENANT_ID
    ,PROD_SRV_RELAT_ID
    ,OFFER_INST_ID
    ,PROD_INST_ID
    ,USER_ID
    ,SERVICE_ID
    ,STATE
)
SELECT
        '22'
        ,CONCAT (X.SOC_SEQ_NO, X.FEATURE_SEQ_NO, '880012')		     AS PROD_SRV_RELAT_ID
        ,CONCAT(X.MAIN_SOC_SEQ_NO,X.VERIS_OFFER_ID)							AS OFFER_INST_ID
        ,CASE WHEN FEATURE_SEQ_NO IS NOT NULL
            THEN concat(VERIS_PRODUCT_ID,CTN,MAIN_SOC_SEQ_NO)
          ELSE CONCAT(SOC_SEQ_NO,CTN)
		 END                                                                AS PROD_INST_ID
        ,X.CTN
        ,'880012'  AS SERVICE_ID
        ,'1'

    FROM LEGACY.SOC_FEATURE_OFFER_MAPPING X
    WHERE   X.VERIS_PRODUCT_ID = '800012'
;	


-- INSERT attribs TO INS_SRV_ATTR table

-- MAX ID lekérdezés
SET @rownum := (SELECT max(cast(SUBSTR(ATTR_INST_ID, 10) as UNSIGNED)) FROM MDM.INS_SRV_ATTR);

-- másodlagos kártya telefonszáma
INSERT INTO MDM.INS_SRV_ATTR
(
     TENANT_ID
    ,ATTR_INST_ID
    ,PROD_SRV_RELAT_ID
    ,OFFER_INST_ID
    ,USER_ID
    ,SERVICE_ID
    ,ATTR_ID
    ,ATTR_VALUE
    ,ATTR_TEXT
    ,STATE
    ,SORT_ID
    ,ATTR_BATCH
    ,EFFECTIVE_DATE
    ,EXPIRE_DATE
)
SELECT
	'22'															-- TENANT_ID
	, CONCAT('100000000',@rownum := @rownum + 1)					-- ATTR_INST_ID
	, S.PROD_SRV_RELAT_ID											-- PROD_SRV_RELAT_ID
	, S.OFFER_INST_ID												-- OFFER_INST_ID
	, S.USER_ID 								  					-- USER_ID
	, S.SERVICE_ID 								  					-- SERVICE_ID
	, '2300000' 								  					-- ATTR_ID
	, TRIM(SUBSTRING(TXT_TO_SPLIT, INSTR(TXT_TO_SPLIT,'=') + 1))	-- ATTR_VALUE
	, TRIM(SUBSTRING(TXT_TO_SPLIT, INSTR(TXT_TO_SPLIT,'=') + 1))	-- ATTR_TEXT
	, S.STATE 									  					-- STATE
	, '99' 							    		  					-- SORT_ID
	, 'null' 									  					-- ATTR_BATCH
	, FTR_EFFECTIVE_DATE						  					-- EFFECTIVE_DATE	
	, FTR_EXPIRATION_DATE						  					-- EXPIRATION_DATE

FROM 
				MDM.INS_PROD_INS_SRV S
    INNER JOIN  LEGACY.M_FEATURE_EXTR F ON S.USER_ID = F.CTN

WHERE F.FEATURE_CODE = 'CARPAR'
  AND F.TXT_TO_SPLIT LIKE 'SECCTN%'
  AND S.SERVICE_ID = '880012'
;


-- másodlagos kártya IMSI-je
INSERT INTO MDM.INS_SRV_ATTR
(
     TENANT_ID
    ,ATTR_INST_ID
    ,PROD_SRV_RELAT_ID
    ,OFFER_INST_ID
    ,USER_ID
    ,SERVICE_ID
    ,ATTR_ID
    ,ATTR_VALUE
    ,ATTR_TEXT
    ,STATE
    ,SORT_ID
    ,ATTR_BATCH
    ,EFFECTIVE_DATE
    ,EXPIRE_DATE
)
SELECT
	'22'															-- TENANT_ID
	, CONCAT('100000000',@rownum := @rownum + 1)					-- ATTR_INST_ID
	, A.PROD_SRV_RELAT_ID											-- PROD_SRV_RELAT_ID
	, A.OFFER_INST_ID												-- OFFER_INST_ID
	, A.USER_ID 								  					-- USER_ID
	, A.SERVICE_ID 								  					-- SERVICE_ID
	, '2300001' 								  					-- ATTR_ID
    , U.IMSI	 													-- ATTR_VALUE
	, U.IMSI														-- ATTR_TEXT
	, A.STATE 									  					-- STATE
	, '99' 							    		  					-- SORT_ID
	, 'null' 									  					-- ATTR_BATCH
	, EFFECTIVE_DATE						  			  			-- EFFECTIVE_DATE	
	, EXPIRE_DATE						  							-- EXPIRATION_DATE
FROM 
				MDM.INS_SRV_ATTR A
	 INNER JOIN LEGACY.M_USER U ON A.ATTR_VALUE = U.CTN

WHERE ATTR_ID = '2300000'
  AND SERVICE_ID = '880012'
;


-- Restriction level paraméter
INSERT INTO MDM.INS_SRV_ATTR
(
     TENANT_ID
    ,ATTR_INST_ID
    ,PROD_SRV_RELAT_ID
    ,OFFER_INST_ID
    ,USER_ID
    ,SERVICE_ID
    ,ATTR_ID
    ,ATTR_VALUE
    ,ATTR_TEXT
    ,STATE
    ,SORT_ID
    ,ATTR_BATCH
    ,EFFECTIVE_DATE
    ,EXPIRE_DATE
)
SELECT
	'22'															-- TENANT_ID
	, CONCAT('100000000',@rownum := @rownum + 1)					-- ATTR_INST_ID
	, S.PROD_SRV_RELAT_ID											-- PROD_SRV_RELAT_ID
	, S.OFFER_INST_ID												-- OFFER_INST_ID
	, S.USER_ID 								  					-- USER_ID
	, S.SERVICE_ID 								  					-- SERVICE_ID
	, '2300013' 								  					-- ATTR_ID
	, TRIM(SUBSTRING(TXT_TO_SPLIT, INSTR(TXT_TO_SPLIT,'=') + 1))	-- ATTR_VALUE
	, TRIM(SUBSTRING(TXT_TO_SPLIT, INSTR(TXT_TO_SPLIT,'=') + 1))	-- ATTR_TEXT
	, S.STATE 									  					-- STATE
	, '99' 							    		  					-- SORT_ID
	, 'null' 									  					-- ATTR_BATCH
	, FTR_EFFECTIVE_DATE						  					-- EFFECTIVE_DATE	
	, FTR_EXPIRATION_DATE						  					-- EXPIRATION_DATE

FROM 
				MDM.INS_PROD_INS_SRV S
	INNER JOIN  LEGACY.M_FEATURE_EXTR F ON S.USER_ID = F.CTN

WHERE F.FEATURE_CODE = 'CARPAR'
  AND F.TXT_TO_SPLIT LIKE 'RESLEV%'
  AND S.SERVICE_ID = '880012'
;
-- EOF
-- ------------------- 9420_INSERT_CA_BM_PRODUCT_RECORD.sql -----------------------
cat >9420_INSERT_CA_BM_PRODUCT_RECORD.sql <<'-- EOF'
-- 9420.
-- B2B
-- -------------------------------------------------------------------------------------------<###>--
-- <Subdomain>    : Billing
-- <MDM Table>    : MDM.CA_BM_PRODUCT_RECORD
-- <MDM Version>  : 1.4 v1.0
-- <Legacy Table> : LEGACY.CA_BM_PRODUCT_RECORD_LDR, LEGACY.M_OFFER_M02_ADDON,
--                  LEGACY.BO_ID2ID_ADDON_OFFER
-- <Purpose>      : Load MDM table with PRODUCT instance mapping.
-- ------------------------------------------------------------------------------------------</###>--

SET @SourceDateTimeFormat = '%Y%m%d %H:%i:%s';
SET @DeductDateFormat = '%Y%m%d';
SET @DEFAULT_DATETIME = CAST(DATE('1900-01-01') AS DATETIME);

-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : CREATE INDEX
-- <Table> : MDM.INS_PROD
-- <Brief> : Create index on MDM and LEGACY tables
-- <Desc>  : 
-- ------------------------------------------------------------------------------------------</###>--

-- call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_MAP','Src_SOC_Cd,Tgt_Offer_Cd');
call LEGACY.createindex_ifnotexists('MDM','INS_PROD','PROD_ID,USER_ID');
call LEGACY.createindex_ifnotexists('LEGACY','CA_BM_PRODUCT_RECORD_LDR','OWNER_ID');
-- 
-- call LEGACY.createindex_ifnotexists('LEGACY','BO_ID2ID_ADDON_OFFER_LDR','OBJECT_ID');
call LEGACY.createindex_ifnotexists('LEGACY','BO_ID2ID_ADDON_OFFER_LDR','OFFER_CD,MDM_TYPE');

-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : CREATE TABLE
-- <Table> : MDM.CA_BM_PRODUCT_RECORD
-- <Brief> : Create another CA_BM_PRODUCT_RECORD table with different logic
-- <Desc>  : Mignon doesn't create this table at this moment.
-- ------------------------------------------------------------------------------------------</###>--

  -- -------------------------------------------------------------------------------------------<###>--
  -- <Type>  : ALTER TABLE
  -- <Table> : MDM.CA_BM_PRODUCT_RECORD
  -- <Brief> : Create PK on MDM table
  -- <Desc>  : Mignon doesn't create PK.
  -- ------------------------------------------------------------------------------------------</###>--

  CALL LEGACY.createindex_ifnotexists('MDM','CA_BM_PRODUCT_RECORD','ACCT_ID,OWNER_ID,PRODUCT_ID,OWNER_TYPE,BILLING_TYPE');
  
  -- -------------------------------------------------------------------------------------------<###>--
  -- <Type>  : INSERT
  -- <Table> : MDM.CA_BM_PRODUCT_RECORD
  -- <Brief> : Insert MDM table
  -- <Desc>  : Used for record recurring charge pre-dedution of product instance.
  -- <Filter>: Only prepaids, BILLING_TYPE = 0
  -- <Maps>  : PRODUCT_ID       - coming from INS_PROD.PROD_ID
  --           LAST_DEDUCT_TIME - 0 when is null
  --           NEXT_DEDUCT_TIME - CURRENT DATE + 2 when is null
  -- ------------------------------------------------------------------------------------------</###>--

  INSERT IGNORE INTO MDM.CA_BM_PRODUCT_RECORD
  SELECT DISTINCT
      PREC.TENANT_ID
    , PREC.ACCT_ID
    , PREC.OWNER_ID
     , COALESCE(INS.PROD_INST_ID, -1) AS PRODUCT_ID
    , COALESCE(CONCAT(SUBSTR(PREC.NEXT_DEDUCT_TIME, 1, 4)
             ,SUBSTR(PREC.NEXT_DEDUCT_TIME, 6, 2)
             ,SUBSTR(PREC.NEXT_DEDUCT_TIME, 9, 2))
           , DATE_FORMAT(DATE_ADD(CURRENT_DATE(), INTERVAL 2 DAY), @DeductDateFormat)) AS NEXT_DEDUCT_TIME
    , COALESCE(CONCAT(SUBSTR(PREC.LAST_DEDUCT_TIME, 1, 4)
             ,SUBSTR(PREC.LAST_DEDUCT_TIME, 6, 2)
             ,SUBSTR(PREC.LAST_DEDUCT_TIME, 9, 2)), 0) AS LAST_DEDUCT_TIME
    , PREC.SUCC_FLAG
    , PREC.RETRY_TIMES
    , PREC.OWNER_TYPE
    , PREC.BILLING_TYPE
--     , PREC.FEATURE_CODE
--     , PREC.SOC_SEQ_NO
--     , PREC.SOC
    FROM       LEGACY.CA_BM_PRODUCT_RECORD_LDR  PREC
  inner join LEGACY.SOC_LDR                     SOC
    on SOC.SOC_SEQ_NO  = PREC.SOC_SEQ_NO
    and SOC.CTN        = PREC.OWNER_ID
    and SOC.service_class   ='SOC' 
  inner join LEGACY.M_OFFER_MAP                 OMAP
    on OMAP.Src_SOC_Cd = SOC.SOC
    and OMAP.Tgt_Offer_Type ='A'
  -- MT: Az alabbi egy bug. Split type eseten csak offer_id-vel lehet prod-ra keresni, vagy kulon kezelni kell a split type mappinget.
  inner join LEGACY.BO_ID2ID_ADDON_OFFER_LDR    IDID
    on IDID.OFFER_CD   = OMAP.Tgt_Offer_Cd
    and IDID.MDM_TYPE       ='PRICE_PROD'
  inner join MDM.INS_PROD                       INS
    on INS.PROD_ID     = IDID.OBJECT_ID
    and INS.USER_ID         = PREC.OWNER_ID
  where 1
--  and PROD_REC.BILLING_TYPE = 0
  ;

  delete from MDM.CA_BM_PRODUCT_RECORD where BILLING_TYPE<>0;
  
-- EOF
-- ------------------- 9430_INSERT_CA_RC_BILL.sql -----------------------
cat >9430_INSERT_CA_RC_BILL.sql <<'-- EOF'
-- 9430.

-- B2B
-- -------------------------------------------------------------------------------------------<###>--
-- <Subdomain>    : Billing
-- <MDM Table>    : MDM.CA_RC_BILL
-- <MDM Version>  : 1.4 v1.0
-- <Legacy Table> : LEGACY.CA_RC_BILL_LDR, LEGACY.M_OFFER_M02_ADDON,
--                  LEGACY.BO_ID2ID_ADDON_OFFER
-- <Purpose>      : Load MDM table with PRODUCT instance mapping.
-- ------------------------------------------------------------------------------------------</###>--

SET @SourceDateTimeFormat = '%Y%m%d %H:%i:%s';
SET @DeductDateFormat = '%Y%m%d';
SET @DEFAULT_DATETIME = CAST(DATE('1900-01-01') AS DATETIME);

-- -------------------------------------------------------------------------------------------<###>--
-- <Type>  : CREATE INDEX
-- <Table> : MDM.INS_PROD
-- <Brief> : Create index on MDM and LEGACY tables
-- <Desc>  : 
-- ------------------------------------------------------------------------------------------</###>--

-- call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M02_ADDON','Tgt_Offer_Cd,Src_SOC_Seq_No');
-- call LEGACY.createindex_ifnotexists('MDM','INS_PROD','PROD_ID,USER_ID');
call LEGACY.createindex_ifnotexists('LEGACY','CA_RC_BILL_LDR','OWNER_ID,SOC_SEQ_NO');
-- 
-- call LEGACY.createindex_ifnotexists('LEGACY','BO_ID2ID_ADDON_OFFER_LDR','OBJECT_ID');
call LEGACY.createindex_ifnotexists('LEGACY','BO_ID2ID_ADDON_OFFER_LDR','OFFER_CD,MDM_TYPE,OBJECT_ID');
call LEGACY.createindex_ifnotexists('LEGACY','SOC_LDR','CTN,SOC_SEQ_NO,service_class');
 
    -- -------------------------------------------------------------------------------------------<###>--
    -- <Type>  : ALTER TABLE
    -- <Table> : MDM.CA_RC_BILL
    -- <Brief> : Create PK on MDM table


    -- <Desc>  : Mignon doesnt create PK.
    -- ------------------------------------------------------------------------------------------</###>--

--  CALL LEGACY.createindex_ifnotexists('MDM','CA_RC_BILL','ACCT_ID,OWNER_ID,PRODUCT_ID,OWNER_TYPE,BILLING_TYPE');
CREATE UNIQUE INDEX IDX_CA_RC_BILL_2_4_7_5_16 ON MDM.CA_RC_BILL(ACCT_ID,OWNER_ID,PRODUCT_ID,OWNER_TYPE,BILLING_TYPE);

    -- -------------------------------------------------------------------------------------------<###>--
    -- <Type>  : INSERT
    -- <Table> : MDM.CA_BM_PRODUCT_RECORD
    -- <Brief> : Insert MDM table
    -- <Desc>  : Used for record recurring charge pre-dedution of product instance.
    -- <Filter>: Only prepaids, BILLING_TYPE = 0
    -- ------------------------------------------------------------------------------------------</###>--

    INSERT IGNORE INTO MDM.CA_RC_BILL
    SELECT DISTINCT
          '22'                                  as TENANT_ID
        , RCB.ACCT_ID                           as ACCT_ID
    , COALESCE(INS.PROD_INST_ID, -1)    as PROD_INST_ID
        , RCB.OWNER_ID                          as OWNER_ID
        , RCB.OWNER_TYPE                        as OWNER_TYPE
        , RCB.MEASURE_ID                        as MEASURE_ID
    , COALESCE(INS.PROD_ID, -1)        as PRODUCT_ID
        , RCB.LAST_CYCLE_BEGIN_DATE             as LAST_CYCLE_CHARGE_BEGIN_DATE
        , RCB.LAST_CYCLE_END_DATE               as LAST_CYCLE_CHARGE_END_DATE
        , RCB.LAST_CYCLE_BEGIN_DATE             as LAST_CYCLE_BEGIN_DATE
        , RCB.LAST_CYCLE_END_DATE               as LAST_CYCLE_END_DATE
        , '2001-01-01 00:00:00'                 as PROD_VALID_DATE
        , '2001-01-01 00:00:00'                 as PROD_FIRST_BILL_DATE
        , RCB.RC_CHARGE_FEE                     as RC_CHARGE_FEE
        , RCB.TAX_INCLUDE                       as TAX_INCLUDE
        , RCB.BILLING_TYPE                      as BILLING_TYPE
        , RCB.VAT_FEE                           as VAT_FEE
--   RCB.SOC_SEQ_NO
--   RCB.SOC
    FROM     LEGACY.CA_RC_BILL_LDR RCB
  inner join LEGACY.SOC_LDR                         SOC
    on SOC.SOC_SEQ_NO  = RCB.SOC_SEQ_NO
    and SOC.CTN             = RCB.OWNER_ID
    and SOC.service_class   ='SOC' 
  inner join LEGACY.M_OFFER_MAP                     OMAP 
    on OMAP.Src_SOC_Cd      = SOC.SOC
    and OMAP.Tgt_Offer_Type ='A'
  -- MT: Az alabbi egy bug. Split type eseten csak offer_id-vel lehet prod-ra keresni, vagy kulon kezelni kell a split type mappinget.
  inner join LEGACY.BO_ID2ID_ADDON_OFFER_LDR        IDID
    on IDID.OFFER_CD        = OMAP.Tgt_Offer_Cd
    and IDID.MDM_TYPE       ='PRICE_PROD'
  inner join MDM.INS_PROD                           INS
    on INS.PROD_ID          = IDID.OBJECT_ID
    and INS.USER_ID         = RCB.OWNER_ID
  WHERE 1 
--  and PROD_REC.BILLING_TYPE = 1
    ;
    -- SET SQL_SAFE_UPDATES=0;
  CALL LEGACY.createindex_ifnotexists('MDM','CA_RC_BILL','BILLING_TYPE');
    delete from MDM.CA_RC_BILL where BILLING_TYPE<>1;

  
-- EOF
-- ------------------- 9440_INSERT_DATASHARE.sql -----------------------
cat >9440_INSERT_DATASHARE.sql <<'-- EOF'
-- Adatmegoszto special mapping rule - VR 2016.09.06

-- INS_PROD tabla toltese DATASHARE adatokkal
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
     '22'                                  AS TENANT_ID
    ,CONCAT(VERIS_OBJECT_ID,HOST_SOC_CTN, TARS_SOC_SOC_SEQ_NO)        AS PROD_INST_ID
    ,CONCAT(HOST_SOC_CTN, TARS_SOC_SOC_SEQ_NO,Relat_Offer_Id)         AS OFFER_USER_RELAT_ID
    ,CONCAT(TARS_SOC_SOC_SEQ_NO,Relat_Offer_Id)               AS OFFER_INST_ID
    ,HOST_SOC_CTN                              AS USER_ID
    ,VERIS_OBJECT_ID                            AS PROD_ID
    ,MDM_TYPE_CD                              AS EXPIRE_PROCESS_TYPE
    ,'0'                                  AS STATE

    ,CASE WHEN FEATURE_EXPIRATION_DATE < SYSDATE()
            THEN '7'
          ELSE '1'
     END
    ,CASE WHEN FEATURE_EFFECTIVE_DATE IS NULL
            THEN '1900-01-01 00:00:00'
          WHEN FEATURE_EFFECTIVE_DATE > FEATURE_EXPIRATION_DATE
            THEN FEATURE_EXPIRATION_DATE
          ELSE FEATURE_EFFECTIVE_DATE
     END                                                        AS EFFECTIVE_DATE
    ,CASE WHEN FEATURE_EXPIRATION_DATE IS NULL
            THEN '2099-12-31 23:59:59'
          WHEN FEATURE_EXPIRATION_DATE > '2099-12-31 23:59:59'
            THEN '2099-12-31 23:59:59'
          ELSE FEATURE_EXPIRATION_DATE
     END                                                        AS EXPIRE_DATE
FROM LEGACY.WRK_DATASHARE D
INNER JOIN LEGACY.M_IDID_OFFER_MOD M
ON D.Tgt_Offer_Cd = M.Tgt_Offer_Cd AND M.Tgt_Offer_CD LIKE 'ADSPLIT%' AND MDM_TYPE_CD IN ('SRVC_SINGLE', 'PRICE_PROD')
WHERE  VERIS_OBJECT_ID IS NOT NULL
;


-- INS_PROD_INS_SERV tabla toltese
INSERT INTO MDM.INS_PROD_INS_SRV
(
     TENANT_ID
    ,PROD_SRV_RELAT_ID
    ,OFFER_INST_ID
    ,PROD_INST_ID
    ,USER_ID
    ,SERVICE_ID
    ,STATE
)
SELECT DISTINCT
   '22'                                                                AS TENANT_ID
   ,CONCAT (HOST_SOC_SOC_SEQ_NO, FEATURE_SEQ_NO, A.SERVICE_ID)         AS PROD_SRV_RELAT_ID
   ,CONCAT(HOST_SOC_SOC_SEQ_NO,M.RELAT_OFFER_ID)                       AS OFFER_INST_ID
   ,concat(VERIS_OBJECT_ID,HOST_SOC_CTN,TARS_SOC_SOC_SEQ_NO)           AS PROD_INST_ID
   ,HOST_SOC_CTN                                                       AS USER_ID
   ,A.SERVICE_ID                                                       AS SERVICE_ID
   ,'1'                                                                AS STATE

FROM LEGACY.WRK_DATASHARE D
INNER JOIN LEGACY.M_IDID_OFFER_MOD M
   ON D.Tgt_Offer_Cd = M.Tgt_Offer_Cd AND M.Tgt_Offer_CD LIKE 'ADSPLIT%'
INNER JOIN (SELECT DISTINCT Product_Id, SERVICE_ID FROM LEGACY.M_IDID_ATTR_MOD) A
   ON M.VERIS_OBJECT_ID = A.Product_Id
WHERE   M.VERIS_OBJECT_ID IN ('800039', '20010005')
    AND A.SERVICE_ID IS NOT NULL
;

    
    
--    INS_SRV_ATTR tabla toltese 
-- MAX ID lekerdezes
SET @rownum := (SELECT max(cast(SUBSTR(ATTR_INST_ID, 10) as UNSIGNED)) FROM MDM.INS_SRV_ATTR);

-- masodlagos kartya telefonszáma
INSERT INTO MDM.INS_SRV_ATTR
(
     TENANT_ID
    ,ATTR_INST_ID
    ,PROD_SRV_RELAT_ID
    ,OFFER_INST_ID
    ,USER_ID
    ,SERVICE_ID
    ,ATTR_ID
    ,ATTR_VALUE
    ,ATTR_TEXT
    ,STATE
    ,SORT_ID
    ,ATTR_BATCH
    ,EFFECTIVE_DATE
    ,EXPIRE_DATE
)
SELECT DISTINCT
   '22'                                                    AS TENANT_ID
   , CONCAT('100000000',@rownum := @rownum + 1)            AS ATTR_INST_ID
   , S.PROD_SRV_RELAT_ID                                   AS PROD_SRV_RELAT_ID
   , S.OFFER_INST_ID                                       AS OFFER_INST_ID
   , S.USER_ID                                             AS USER_ID
   , S.SERVICE_ID                                          AS SERVICE_ID
   , '2300010'                                             AS ATTR_ID
   , D.TARS_SOC_CTN                                        AS ATTR_VALUE
   , D.TARS_SOC_CTN                                        AS ATTR_TEXT
   , S.STATE                                               AS STATE
   , '99'                                                  AS SORT_ID
   , 'null'                                                AS ATTR_BATCH
    , CASE WHEN D.FEATURE_EFFECTIVE_DATE IS NULL THEN '1900-01-01 00:00:00'
        WHEN D.FEATURE_EFFECTIVE_DATE > D.FEATURE_EFFECTIVE_DATE THEN D.FEATURE_EFFECTIVE_DATE
      ELSE D.FEATURE_EFFECTIVE_DATE END                    AS EFFECTIVE_DATE
    , CASE WHEN D.FEATURE_EXPIRATION_DATE IS NULL THEN '2099-12-31 23:59:59'
         WHEN D.FEATURE_EXPIRATION_DATE > '2099-12-31 23:59:59' THEN '2099-12-31 23:59:59'
          ELSE D.FEATURE_EXPIRATION_DATE END               AS EXPIRE_DATE
FROM 
            LEGACY.WRK_DATASHARE D
                INNER JOIN MDM.INS_PROD_INS_SRV S
            ON S.USER_ID = D.HOST_SOC_CTN

WHERE S.SERVICE_ID IN ('880039', '20010005')
;


-- masodlagos kartya IMSI-je
INSERT INTO MDM.INS_SRV_ATTR
(
     TENANT_ID
    ,ATTR_INST_ID
    ,PROD_SRV_RELAT_ID
    ,OFFER_INST_ID
    ,USER_ID
    ,SERVICE_ID
    ,ATTR_ID
    ,ATTR_VALUE
    ,ATTR_TEXT
    ,STATE
    ,SORT_ID
    ,ATTR_BATCH
    ,EFFECTIVE_DATE
    ,EXPIRE_DATE
)
SELECT DISTINCT
   '22'                                                  AS TENANT_ID
   , CONCAT('100000000',@rownum := @rownum + 1)          AS ATTR_INST_ID
   , S.PROD_SRV_RELAT_ID                                 AS PROD_SRV_RELAT_ID
   , S.OFFER_INST_ID                                     AS OFFER_INST_ID
   , S.USER_ID                                           AS USER_ID
   , S.SERVICE_ID                                        AS SERVICE_ID
   , '2300011'                                           AS ATTR_ID
   , D.TARS_USER_IMSI                                    AS ATTR_VALUE
   , D.TARS_USER_IMSI                                    AS ATTR_TEXT
   , S.STATE                                             AS STATE
   , '99'                                                AS SORT_ID
   , 'null'                                              AS ATTR_BATCH
    , CASE WHEN D.FEATURE_EFFECTIVE_DATE IS NULL THEN '1900-01-01 00:00:00'
        WHEN D.FEATURE_EFFECTIVE_DATE > D.FEATURE_EFFECTIVE_DATE THEN D.FEATURE_EFFECTIVE_DATE
      ELSE D.FEATURE_EFFECTIVE_DATE END                  AS EFFECTIVE_DATE
    , CASE WHEN D.FEATURE_EXPIRATION_DATE IS NULL THEN '2099-12-31 23:59:59'
         WHEN D.FEATURE_EXPIRATION_DATE > '2099-12-31 23:59:59' THEN '2099-12-31 23:59:59'
          ELSE D.FEATURE_EXPIRATION_DATE END             AS EXPIRE_DATE
FROM 
            LEGACY.WRK_DATASHARE D
                INNER JOIN MDM.INS_PROD_INS_SRV S
            ON S.USER_ID = D.HOST_SOC_CTN
WHERE S.SERVICE_ID IN ('880039', '20010005')
;-- EOF
-- ------------------- 9450_BO_Mapping_Special_Features.sql -----------------------
cat >9450_BO_Mapping_Special_Features.sql <<'-- EOF'

USE LEGACY;

/*


-------------------------------------------------------------------------------
PRODUCT, SERVICE, ATTRIBUTUM letrehozasa az MDM semaba tarifabol
-------------------------------------------------------------------------------


*/

-- MT: Ismet ide rakom azt, ami mar elkeszult 6011-ben:
call LEGACY.createindex_ifnotexists('LEGACY','M_OFFER_M01_TARIFF','CTN,BAN,BEN');



INSERT INTO MDM.INS_PROD (
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
select distinct
  '22'         TENANT_ID          ,
  A.SER_NR     PROD_INST_ID       ,
  A.SER_NR     OFFER_USER_RELAT_ID,
  A.SER_NR     OFFER_INST_ID      ,
  T.CTN        USER_ID            ,
  A.PROD_ID    PROD_ID            ,
  'PRICE_PROD' PROD_TYPE          ,
  '0'          EXPIRE_PROCESS_TYPE,
  CASE
    WHEN A.EXPIRATION_DATE < SYSDATE() THEN '7'
    WHEN A.EFFECTIVE_DATE  > SYSDATE() THEN '7'
    ELSE '1'
    END STATE,
  CASE
    WHEN A.EFFECTIVE_DATE > '2099-12-31 23:59:59' THEN '1900-01-01 00:00:00'
    ELSE COALESCE(A.EFFECTIVE_DATE,'1900-01-01 00:00:00')
    END            AS EFFECTIVE_DATE,
  CASE 
    WHEN A.EXPIRATION_DATE > '2099-12-31 23:59:59' THEN '2099-12-31 23:59:59'
    ELSE COALESCE(A.EXPIRATION_DATE,'2099-12-31 23:59:59')
    END            AS EXPIRE_DATE
FROM  M_OFFER_M01_TARIFF T
JOIN  M_SPECIAL_ADDONS   A
  ON  A.CTN=T.CTN
  AND A.BAN=T.BAN
  AND A.BEN=T.BEN
WHERE A.USE_FLAG = 'Y'
  AND A.TGT_OFFER_ID > 0
  AND A.PROD_ID > 0
group by  -- Olyan a logika, hogy lehet tobbszorozes A-ban, amit itt egyelunk ki.
  T.CA_ID,
  T.CTN,
  A.TGT_OFFER_ID
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
  A.SER_NR PROD_SRV_RELAT_ID,
  A.SER_NR ADDON_OFFER_INST_ID,
  A.SER_NR PROD_INST_ID,
  T.CTN,
  A.SRV_ID SERVICE_ID,
  1 DEFAULT_STATE
FROM  M_OFFER_M01_TARIFF T
JOIN  M_SPECIAL_ADDONS   A
  ON  A.CTN=T.CTN
  AND A.BAN=T.BAN
  AND A.BEN=T.BEN
WHERE A.USE_FLAG = 'Y'
  AND A.TGT_OFFER_ID > 0
  AND A.PROD_ID > 0
  AND A.SRV_ID > 0
group by  -- Olyan a logika, hogy lehet tobbszorozes A-ban, amit itt egyelunk ki.
  T.CA_ID,
  T.CTN,
  A.TGT_OFFER_ID
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
SELECT DISTINCT
  22                   ,
  A.SER_NR             ,
  A.SER_NR             ,
  A.SER_NR             ,
  T.CTN         USER_ID,
  A.SRV_ID   SERVICE_ID,
  A.ATTR_ID            ,
  A.ATTR_VALUE         ,
  A.ATTR_VALUE         ,
  1                    ,
  null                 , -- legacy.sort_id
  null                 , -- family phone number
  CASE
    WHEN A.EFFECTIVE_DATE > '2099-12-31 23:59:59' THEN '1900-01-01 00:00:00'
    ELSE COALESCE(A.EFFECTIVE_DATE,'1900-01-01 00:00:00')
    END            AS EFFECTIVE_DATE,
  CASE 
    WHEN A.EXPIRATION_DATE > '2099-12-31 23:59:59' THEN '2099-12-31 23:59:59'
    ELSE COALESCE(A.EXPIRATION_DATE,'2099-12-31 23:59:59')
    END            AS EXPIRE_DATE
FROM  M_OFFER_M01_TARIFF T
JOIN  M_SPECIAL_ADDONS   A
  ON  A.CTN=T.CTN
  AND A.BAN=T.BAN
  AND A.BEN=T.BEN
WHERE A.USE_FLAG = 'Y'
  AND A.TGT_OFFER_ID > 0
  AND A.PROD_ID > 0
  AND A.SRV_ID > 0
  AND A.ATTR_ID > 0
group by  -- Olyan a logika, hogy lehet tobbszorozes A-ban, amit itt egyelunk ki.
  T.CA_ID,
  T.CTN,
  A.TGT_OFFER_ID
;

-- EOF
-- ------------------- 9455_BO_Mapping_Special_Kiralysag.sql -----------------------
cat >9455_BO_Mapping_Special_Kiralysag.sql <<'-- EOF'
USE LEGACY;

/*

MT: A3ONNET offer specialitasainak felpakolasa
A normal folyamat ezt az offert felrakja, es megallapitja, mi hozza a PROD.
A PROD ala SRV est ATTR is felteendo, ami feature-bol jon, tartalma 3 db telefonszam.
Felrakando az A3ONNET50MB addon is, ami egy leforgalmazhato 50MB-os internet.

*/


set @i=0;


-- Ujrafelhasznaljuk a 6011-ben letrejott tablankat:
insert into LEGACY.M_A3ONNET_SRV
select
  CASE
    WHEN F.FTR_EFFECTIVE_DATE > '2099-12-31 23:59:59' THEN '1900-01-01 00:00:00'
    ELSE COALESCE(F.FTR_EFFECTIVE_DATE,'1900-01-01 00:00:00')
    END            AS EFFECTIVE_DATE,
  CASE 
    WHEN F.FTR_EXPIRATION_DATE > '2099-12-31 23:59:59' THEN '2099-12-31 23:59:59'
    ELSE COALESCE(F.FTR_EXPIRATION_DATE,'2099-12-31 23:59:59')
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
from M_FEATURE_EXTR_SL F
join MDM.INS_PROD   P
  on P.PROD_ID='1000281'
  and P.USER_ID=F.CTN
  -- and BAN/BEN/CA_ID vagy valami...
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
    WHEN EXPIRATION_DATE < SYSDATE() THEN '7'
    WHEN EFFECTIVE_DATE  > SYSDATE() THEN '7'
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


-- EOF
