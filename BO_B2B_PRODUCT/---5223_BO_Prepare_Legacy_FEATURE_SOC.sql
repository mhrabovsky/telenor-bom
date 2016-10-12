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

CREATE TABLE /*${XTR_TB}*/ M_FEATURE
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
/*
, KEY `SOC_Seq_No` (`SOC_Seq_No`),
  KEY `CTN` (`CTN`),
  KEY `Feature_Cd` (`Feature_Cd`),
  KEY `Feature_Seq_No` (`Feature_Seq_No`)
*/
) ENGINE=MyISAM 
COMMENT 'TOM -- BO work table'
;

INSERT
INTO    /*${XTR_TB}*/ M_FEATURE
(
-- ---
        Sub_Id
-- ---
,       BAN
,       BEN
,       CTN
,       SOC_Cd
,       SOC_Seq_No
,       Feature_Cd
,       Feature_Seq_No
-- ---
,       Eff_Dt
,       Exp_Dt
-- ---
,   ADDITIONAL_INFO
,   SWITCH_PARAM   
)
select
        G.Sub_Id                
-- ---
,       G.BAN                   
,       G.BEN                   
,       G.CTN                   
,       G.SOC_Cd                   
,       G.SOC_Seq_No            
,       G.Feature_Cd          
,       G.Feature_Seq_No    
-- ---
,       COALESCE(CAST(G.FTR_EFFECTIVE_DATE  AS DATE), CAST('2099-12-31' AS DATE))   AS  FTR_EFFECTIVE_DATE
,       COALESCE(CAST(G.FTR_EXPIRATION_DATE AS DATE), CAST('2099-12-31' AS DATE))   AS  FTR_EXPIRATION_DATE
-- ---
,		G.ADDITIONAL_INFO       
-- ---
,		G.SWITCH_PARAM          
 
from
-- (select 
-- --case when @n=M.SOC_SEQ_NO and @c=M.Feature_Cd then @i:=@i+1 else @i:=1 end nr,
-- M.*
-- -- ,@n:=M.SOC_SEQ_NO
-- -- ,@c:=M.Feature_Cd
-- from
(SELECT
-- Kivenni S.Sub_Id és tenni jobb indexet az M_SOC-ra
--        S.Sub_Id                AS  Sub_Id
        W.CTN                AS  Sub_Id        
-- ---
,       W.BAN                   AS  BAN
,       W.BEN                   AS  BEN
,       W.CTN                   AS  CTN
,       S.SOC_Cd                AS  SOC_Cd
,       W.SOC_Seq_No            AS  SOC_Seq_No
,       W.FEATURE_CODE            AS  Feature_Cd
,       W.SERVICE_FTR_SEQ_NO        AS  Feature_Seq_No
-- ---
,		NULL                    AS  ADDITIONAL_INFO
-- ---
,       W.FTR_EFFECTIVE_DATE
,       W.FTR_EXPIRATION_DATE
-- ---
,		NULL                    AS  SWITCH_PARAM
FROM
		/*${LOAD_TB}PD_*/ LEGACY.M_FEATURE_WORK  AS  W
        INNER JOIN  /*${XTR_TB}*/ LEGACY.M_SOC          AS  S
                ON  (
                            S.CTN        = W.CTN
                        AND /*cast(*/S.SOC_Seq_No /*as char(11))*/ = W.SOC_SEQ_NO
                    )
-- where st.intCnt = 1        
-- ORDER BY F.SOC_SEQ_NO, F.FEATURE_CODE
-- 		, F.FTR_EFFECTIVE_DATE DESC
-- the previous line simplifies the next two        
-- 		, COALESCE(CAST(F.FTR_EXPIRATION_DATE AS DATE), CAST('2099-12-31' AS DATE)) DESC
--      , COALESCE(CAST(F.FTR_EFFECTIVE_DATE  AS DATE), CAST('2099-12-31' AS DATE)) DESC
--        ) M
-- ,(select @i:=0,@n:='-',@c:='-') x
) G
-- where nr = 1
;

-- .if errorcode<>0 then .quit errorcode

-- COLLECT STATISTICS ON /*${XTR_TB}*/ USR_ABO.M_FEATURE INDEX (Sub_Id);
-- .if errorcode<>0 then .quit errorcode

-- COLLECT STATISTICS ON /*${XTR_TB}*/ USR_ABO.M_FEATURE INDEX (Sub_Id, SOC_Cd);
-- .if errorcode<>0 then .quit errorcode
/*
call LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE','SOC_Seq_No');
call LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE','CTN');
call LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE','Feature_Cd');
call LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE','Feature_Seq_No');

call LEGACY.createindex_ifnotexists('LEGACY','M_FEATURE','Sub_Id,Feature_Cd,Feature_Seq_No');
*/
alter table LEGACY.M_FEATURE
add INDEX IDX_M_FEATURE_SOC_Seq_No(SOC_Seq_No),
add INDEX IDX_M_FEATURE_CTN(CTN),
add INDEX IDX_M_FEATURE_Feature_Cd(Feature_Cd),
add INDEX IDX_M_FEATURE_Feature_Seq_No(Feature_Seq_No),
add INDEX IDX_M_FEATURE_Sub_Id_Feature_Cd_Feature_Seq_No(Sub_Id,Feature_Cd,Feature_Seq_No);

