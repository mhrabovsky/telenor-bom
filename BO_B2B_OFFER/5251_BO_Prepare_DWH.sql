-- 5251.
-- USE LEGACY;

-- Futasido (.133 gep, 8789242 sor): 2m:30s

-- NAS 10.10 beégetések bõvítése
SET @OFFER_CD_EDSZ=LEGACY.CONFIG('OFFER_CD_EDSZ',NULL);

DROP TABLE IF EXISTS LEGACY.M_DWH_B2B;

CREATE TABLE LEGACY.M_DWH_B2B(
  Sub_Id          VARCHAR(28) NOT NULL
 ,CA_Id           VARCHAR(30) NOT NULL
 ,BAN             VARCHAR(10) NOT NULL
 ,BEN             VARCHAR(5)  NOT NULL
 ,CTN             VARCHAR(11) NOT NULL
 ,Tgt_Offer_Cd    VARCHAR(30) NOT NULL
 ,Tgt_Offer_Val   DECIMAL(15,2) NULL
 ,One2One_Ind     CHAR(1) NOT NULL
 ,Sub_Type        char(3) not null    --  subsription type PRE,HYB,POS
 ,SUBSCRIBER_REF  VARCHAR(30)         -- NRPC migraciojahoz kell
);


INSERT INTO LEGACY.M_DWH_B2B (
    Sub_Id
   ,CA_Id
   ,BAN
   ,BEN
   ,CTN
   ,Tgt_Offer_Cd
   ,Tgt_Offer_Val
   ,One2One_Ind
   ,Sub_Type
   ,SUBSCRIBER_REF
  )
  SELECT
    U.Sub_Id AS Sub_Id --  !!! FONTOS !!! -- BAN,BEN,CTN <-> Sub_Id
   ,DWH.CA_Id AS CA_Id
   ,DWH.BAN AS BAN
   ,DWH.BEN AS BEN
   ,DWH.CTN AS CTN
   ,DWH.to_soc AS Tgt_Offer_Cd
   ,cast(
      ifnull(DWH.val,'0.00') AS decimal(15, 2)) -- * 100 mgy 2016.06.21
      AS Tgt_Offer_Val
   -- ---
   ,(CASE WHEN (DWH.one2one IS NOT NULL) THEN 'Y' ELSE 'N' END) AS One2One_Ind
   ,U.Sub_Type
   ,U.SUBSCRIBER_REF
  -- ---
  FROM LEGACY.B2B_ROS_TOSOC_LDR DWH
  JOIN LEGACY.M_USER U ON U.Sub_Id=concat(DWH.BAN,'_',DWH.BEN,'_',DWH.CTN)
--  JOIN M_USER U ON U.CTN=DWH.CTN and U.BAN=DWH.BAN and U.SUB_STATUS_CD='A' -- like concat(DWH.BAN,'%',DWH.CTN) -- addigis
  WHERE 1=1
-- NGy 08.12	hitelkeret spec eset. BT: DWH-bol nem hinnem, hogy jon ilyen.
	and to_soc <> @OFFER_CD_EDSZ
-- --------
;
