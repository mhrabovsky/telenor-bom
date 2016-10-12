-- USE MDM;

-- Futasido: 43 perc, ami tul sok. Muszaj javitani 10 perc ala. Talan masik SOC tablabol kellene dolgoznia. Na meg pont offerhez kotni SOC-ot...
-- Legjobb lenne nem LEGACY.SOC_LDR+MDM.INS_OFFER O alapokra tenni, hanem offeres kkoztes tablakbol generalni...
call LEGACY.createindex_ifnotexists('MDM','INS_OFFER','USER_ID,OFFER_TYPE,OFFER_ID');

/*
2016-08-03 Mezo Tamas: Ez a szkript B2B tarifa husegidot tolt.
*/

-- NAS 10.04 beégetések bõvítése
SET @EFF_DT = CAST(LEGACY.CONFIG('DEF_EFF_DATE',NULL) AS DATETIME);
SET @EXP_DT = CAST(LEGACY.CONFIG('DEF_EXP_DATE',NULL) AS DATETIME);
SET @EXP_DATE = CAST(LEGACY.CONFIG('DEF_EXP_DATE',NULL) AS DATE);
SET @INST_COMMITMENT_ID = LEGACY.CONFIG('INST_COMMITMENT_ID','74000000');
SET @OFFER_TYPE_MAIN = LEGACY.CONFIG('OFFER_TYPE_MAIN',NULL);


 INSERT INTO MDM.INS_COMMITMENT
 SELECT DISTINCT
  '22',                                              -- TENANT_ID
  CONCAT(@INST_COMMITMENT_ID,@rownum := @rownum + 1),         -- INST_COMMITMENT_ID
  NULL, -- O.OFFER_INST_ID, MT: kijartam, hogy NULL legyen.
  S.Sub_Id,                                             -- USER_ID 
  O.OFFER_ID,                                        -- OFFER_ID 
  '2',                                               -- COMM_TYPE: Mindig 2
  -- Az alabbit egy 0.9%-os hibaaranyu hibajelentes valtotta ki (COMM_VALUE cannot be null):
  -- coalesce(S.NUMBER_OF_MONTHS, TIMESTAMPDIFF(MONTH, COMM_START_DATE, COMM_END_DATE)) COMM_VALUE,
--  coalesce(S.NUMBER_OF_MONTHS, 0) COMM_VALUE,
  coalesce(S.Comm_No_Months, 0) COMM_VALUE,
  S.Comm_Start_Dt,                           -- COMM_START_DATE
  coalesce(S.Comm_End_Dt,S.Exp_Dt), -- COMM_END_DATE  
  '1'   STATE,                                       -- STATE ABO 07/07
  null, -- CREATE_OP_ID
  null, -- CREATE_ORG_ID
  null, -- OP_ID
  null, -- ORG_ID
  null, -- DONE_CODE
  coalesce(S.Eff_Dt,S.Comm_Start_Dt,@EFF_DT) CREATE_DATE,
  coalesce(S.Eff_Dt,S.Comm_Start_Dt,@EFF_DT) DONE_DATE,
  greatest(least( S.Comm_Start_Dt, S.Eff_Dt, @EXP_DT), @EFF_DT) Eff_Dt,
  least(coalesce(S.Comm_End_Dt,S.Exp_Dt), @EXP_DT) EXPIRE_DATE,
  null, -- REGION_ID
  concat('SOC:', S.SOC_CD) REMARKS,
  case S.SOC_CD -- SOC tipusu SOC eseten konnyen valtunk at kategoriara az alabbi tablazattal (Dobos Petitol)
    when '2XSTH1'   then 20025258 -- MDUMMY_2XS
    when '2XSTH2'   then 20025258 -- MDUMMY_2XS
    when '3XSTH2'   then 20025257 -- MDUMMY_3XS
    when 'LTH2'     then 20025262 -- MDUMMY_L
    when 'MTH2'     then 20025261 -- MDUMMY_M
    when 'MYPPSTH2' then 20025259 -- MDUMMY_XS
    when 'OPENLTH2' then 20025262 -- MDUMMY_L
    when 'OPENMTH2' then 20025260 -- MDUMMY_S
    when 'OPENSTH2' then 20025259 -- MDUMMY_XS
    when 'STH2'     then 20025260 -- MDUMMY_S
    when 'XLTH2'    then 20025262 -- MDUMMY_L
    when 'XSTH'     then 20025259 -- MDUMMY_XS
    when 'XSTH2'    then 20025259 -- MDUMMY_XS
    when 'XXLTH2'   then 20025263 -- MDUMMY_XXL
    when 'LKH2ED'   then 20025262 -- MDUMMY_L
    when 'XSKH2ED'  then 20025259 -- MDUMMY_XS
    when 'XXLKH2ED' then 20025263 -- MDUMMY_XXL
    when 'SKH2ED'   then 20025260 -- MDUMMY_S
    -- BLOFF, nev alapjan:
    when 'BUA2XSTH1' then 20025258 -- MDUMMY_2XS
    when 'BUA2XSTH2' then 20025258 -- MDUMMY_2XS
    when 'BUA2XSSO2' then 20025258 -- MDUMMY_2XS
    when 'BUA3XSTH1' then 20025257 -- MDUMMY_3XS
    when 'BUA3XSTH2' then 20025257 -- MDUMMY_3XS
    when 'BUAXSTH1'  then 20025259 -- MDUMMY_XS
    when 'BUAXSTH2'  then 20025259 -- MDUMMY_XS
    when 'BUAXSSO2'  then 20025259 -- MDUMMY_XS
    when 'BUAIXSTH2' then 20025259 -- MDUMMY_XS
    when 'BUASTH1'   then 20025260 -- MDUMMY_S
    when 'BUASTH2'   then 20025260 -- MDUMMY_S
    when 'BUASSO2'   then 20025260 -- MDUMMY_S
    when 'BUAISTH2'  then 20025260 -- MDUMMY_S
    when 'BUAIMTH2'  then 20025261 -- MDUMMY_M
    when 'BUALTH1'   then 20025262 -- MDUMMY_L
    when 'BUALTH2'   then 20025262 -- MDUMMY_L
    when 'BUALSO2'   then 20025262 -- MDUMMY_L
    when 'BUAILTH2'  then 20025262 -- MDUMMY_L
    when 'BUAXXLTH1' then 20025263 -- MDUMMY_XXL
    when 'BUAXXLTH2' then 20025263 -- MDUMMY_XXL
    when 'BUAXXLSO2' then 20025263 -- MDUMMY_XXL
    when 'CEXXLPEN2' then 20025263 -- MDUMMY_XXL
    when 'BUAIXLTH2' then 20025263 -- MDUMMY_XXL -- (XL dummy main offer nincs.)
    -- Otletem sincs:
    -- 'ATRPN2Y15','BUTETH2','BUTITH2','CHIPRETH2','CORTH2', 'FLOTTH2',
    -- 'INDPEN3Y', 'INTPEN1Y','INTPEN2Y',
    -- 'VITAPEN', 'VITAPEN2', 'VITAPEN3','VITAPEN4', 'VITAPEN5', 'INTPUN2Y', 'INTPUN1Y',
    else O.OFFER_ID
  end, -- SRC_OFFER_ID     :   -- MT: eredeti main offer kategoria
  null,       -- SRC_OFFER_INS_ID : Marad NULL.
  '1'         -- COMM_BUSI_TYPE   : 1:tarifahuseg tarifa-kotberrel, 2:tarifahuseg keszulek-kotberrel
 FROM LEGACY.M_SOC S, MDM.INS_OFFER O,  (select @rownum :=0) r
WHERE S.Sub_Id = O.USER_ID
  AND S.Svc_Class_Cd in ('SOC') -- ,'DSC','PP'
  AND O.OFFER_TYPE in (@OFFER_TYPE_MAIN)
 -- nem fogadjuk el a null commitmentet commitment soc-kent, sem a hibasakat, sem a lejartakat:
  AND S.Comm_Start_Dt IS NOT NULL
  AND coalesce(S.Comm_End_Dt,S.Exp_Dt) IS NOT NULL
  AND coalesce(S.Comm_End_Dt,S.Exp_Dt) > S.Comm_Start_Dt
  AND least(coalesce(S.Comm_End_Dt,@EXP_DT),
            coalesce(S.Exp_Dt,@EXP_DT),
            @EXP_DT
            ) between sysdate() and '2099-12-31 00:00:00' -- Kisebb legyen a maxdatumnal, azaz null kizart.
  -- AND S.NUMBER_OF_MONTHS IS NOT NULL -- ennek utana kell jarni !!!
  --
  -- Az uzlet adta meg, mely SOC-ok voatkoznak B2B tarifahusegre. Szolgaltatashuseget nem toltunk, mert nincs a Veris-ben ilyen funkcio. Az osszes tobbit (keszulekhuseg, leasing nem itt toltjuk, hanem a 7-es agban.)
  AND S.SOC_CD in (
  -- B2C tarifahuseg: Ezek mind megjelenhetnek B2B-ben is (biztosan migralando):
  '2XSTH1', '2XSTH2', '3XSTH2', 'LTH2', 'MTH2', 'STH2', 'XLTH2', 'XSTH', 'XSTH2', 'XXLTH2', 'LKH2ED', 'XSKH2ED', 'XXLKH2ED', 'SKH2ED', 
  -- B2B Egyosszegben terhelendo kotber (biztosan migralando): !!!Be kell kerni, melyik kategoriat kell ezeknek adni!!!
  'ATRPN2Y15', 'BUA2XSTH1', 'BUA2XSTH2', 'BUAILTH2', 'BUAIMTH2', 'BUAISTH2', 'BUAIXLTH2', 'BUAIXSTH2', 'BUALTH1', 'BUALTH2', 'BUASTH1', 'BUASTH2', 'BUAXSTH1', 'BUAXSTH2', 'BUAXXLTH1', 'BUAXXLTH2', 'BUTETH2', 'BUTITH2', 'CEXXLPEN2', 'CHIPRETH2', 'CORTH2', 'FLOTTH2', 'INDPEN3Y', 'INTPEN1Y', 'INTPEN2Y', 'VITAPEN', 'VITAPEN2', 'VITAPEN3', 'VITAPEN4', 'VITAPEN5', 'INTPUN2Y', 'INTPUN1Y'
  -- B2B SIMO: egyosszegu terheles, tehat migralando:
  , 'BUA2XSSO2', 'BUALSO2', 'BUASSO2', 'BUAXSSO2', 'BUAXXLSO2'
  -- B2C SIMO: ezek valoszinuleg nem migralandoak:
  -- , 'MYPPSTH2', 'OPENLTH2', 'OPENMTH2', 'OPENSTH2'
  )
group by
  S.Sub_Id, O.OFFER_ID, S.Comm_No_Months, S.Comm_Start_Dt,
  S.Comm_End_Dt, S.Exp_Dt, S.Eff_Dt
;

INSERT INTO MDM.INS_USER_EXT(
  TENANT_ID      ,
  USER_ID        ,
  ATTR_CODE      ,
  ATTR_VALUE     ,
  STATE          ,
  EFFECTIVE_DATE ,
  EXPIRE_DATE    ,
  OP_ID          ,
  ORG_ID
)
SELECT
  '22'                 TENANT_ID     ,
  M.USER_ID            USER_ID       ,
  300200               ATTR_CODE     ,
  M.SRC_OFFER_ID       ATTR_VALUE    ,
  M.STATE,
  M.COMM_START_DATE,
  M.COMM_END_DATE,
  0                    OP_ID         ,
  0                    ORG_ID
FROM INS_COMMITMENT M
;

/*




explain SELECT DISTINCT
  '22',                                              -- TENANT_ID
  CONCAT('74000000',@rownum := @rownum + 1),         -- INST_COMMITMENT_ID
  NULL, -- O.OFFER_INST_ID, MT: kijartam, hogy NULL legyen.
  S.CTN,                                             -- USER_ID 
  O.OFFER_ID,                                        -- OFFER_ID 
  '2',                                               -- COMM_TYPE: Mindig 2
  -- Az alabbit egy 0.9%-os hibaaranyu hibajelentes valtotta ki (COMM_VALUE cannot be null):
  -- coalesce(S.NUMBER_OF_MONTHS, TIMESTAMPDIFF(MONTH, COMM_START_DATE, COMM_END_DATE)) COMM_VALUE,
--  coalesce(S.NUMBER_OF_MONTHS, 0) COMM_VALUE,
  coalesce(S.Comm_No_Months, 0) COMM_VALUE,
  S.Comm_Start_Dt,                           -- COMM_START_DATE
  coalesce(S.Comm_End_Dt,S.Exp_Dt), -- COMM_END_DATE  
  '1'   STATE,                                       -- STATE ABO 07/07
  null, -- CREATE_OP_ID
  null, -- CREATE_ORG_ID
  null, -- OP_ID
  null, -- ORG_ID
  null, -- DONE_CODE
  coalesce(S.Eff_Dt,S.Comm_Start_Dt,'1900-01-01 00:00:00') CREATE_DATE,
  coalesce(S.Eff_Dt,S.Comm_Start_Dt,'1900-01-01 00:00:00') DONE_DATE,
  greatest(
    least( S.Comm_Start_Dt, S.Eff_Dt, '2099-12-31 23:59:59'),
      '1900-01-01 00:00:00') Eff_Dt,
  least(coalesce(S.Comm_End_Dt,S.Exp_Dt), '2099-12-31 23:59:59') EXPIRE_DATE,
  null, -- REGION_ID
  concat('SOC:', S.SOC_CD) REMARKS,
  case S.SOC_CD -- SOC tipusu SOC eseten konnyen valtunk at kategoriara az alabbi tablazattal (Dobos Petitol)
    when '2XSTH1'   then 20025258 -- MDUMMY_2XS
    when '2XSTH2'   then 20025258 -- MDUMMY_2XS
    when '3XSTH2'   then 20025257 -- MDUMMY_3XS
    when 'LTH2'     then 20025262 -- MDUMMY_L
    when 'MTH2'     then 20025261 -- MDUMMY_M
    when 'MYPPSTH2' then 20025259 -- MDUMMY_XS
    when 'OPENLTH2' then 20025262 -- MDUMMY_L
    when 'OPENMTH2' then 20025260 -- MDUMMY_S
    when 'OPENSTH2' then 20025259 -- MDUMMY_XS
    when 'STH2'     then 20025260 -- MDUMMY_S
    when 'XLTH2'    then 20025262 -- MDUMMY_L
    when 'XSTH'     then 20025259 -- MDUMMY_XS
    when 'XSTH2'    then 20025259 -- MDUMMY_XS
    when 'XXLTH2'   then 20025263 -- MDUMMY_XXL
    when 'LKH2ED'   then 20025262 -- MDUMMY_L
    when 'XSKH2ED'  then 20025259 -- MDUMMY_XS
    when 'XXLKH2ED' then 20025263 -- MDUMMY_XXL
    when 'SKH2ED'   then 20025260 -- MDUMMY_S
    -- BLOFF, nev alapjan:
    when 'BUA2XSTH1' then 20025258 -- MDUMMY_2XS
    when 'BUA2XSTH2' then 20025258 -- MDUMMY_2XS
    when 'BUA2XSSO2' then 20025258 -- MDUMMY_2XS
    when 'BUA3XSTH1' then 20025257 -- MDUMMY_3XS
    when 'BUA3XSTH2' then 20025257 -- MDUMMY_3XS
    when 'BUAXSTH1'  then 20025259 -- MDUMMY_XS
    when 'BUAXSTH2'  then 20025259 -- MDUMMY_XS
    when 'BUAXSSO2'  then 20025259 -- MDUMMY_XS
    when 'BUAIXSTH2' then 20025259 -- MDUMMY_XS
    when 'BUASTH1'   then 20025260 -- MDUMMY_S
    when 'BUASTH2'   then 20025260 -- MDUMMY_S
    when 'BUASSO2'   then 20025260 -- MDUMMY_S
    when 'BUAISTH2'  then 20025260 -- MDUMMY_S
    when 'BUAIMTH2'  then 20025261 -- MDUMMY_M
    when 'BUALTH1'   then 20025262 -- MDUMMY_L
    when 'BUALTH2'   then 20025262 -- MDUMMY_L
    when 'BUALSO2'   then 20025262 -- MDUMMY_L
    when 'BUAILTH2'  then 20025262 -- MDUMMY_L
    when 'BUAXXLTH1' then 20025263 -- MDUMMY_XXL
    when 'BUAXXLTH2' then 20025263 -- MDUMMY_XXL
    when 'BUAXXLSO2' then 20025263 -- MDUMMY_XXL
    when 'CEXXLPEN2' then 20025263 -- MDUMMY_XXL
    when 'BUAIXLTH2' then 20025263 -- MDUMMY_XXL -- (XL dummy main offer nincs.)
    -- Otletem sincs:
    -- 'ATRPN2Y15','BUTETH2','BUTITH2','CHIPRETH2','CORTH2', 'FLOTTH2',
    -- 'INDPEN3Y', 'INTPEN1Y','INTPEN2Y',
    -- 'VITAPEN', 'VITAPEN2', 'VITAPEN3','VITAPEN4', 'VITAPEN5', 'INTPUN2Y', 'INTPUN1Y',
    else O.OFFER_ID
  end, -- SRC_OFFER_ID     :   -- MT: eredeti main offer kategoria
  null,       -- SRC_OFFER_INS_ID : Marad NULL.
  '1'         -- COMM_BUSI_TYPE   : 1:tarifahuseg tarifa-kotberrel, 2:tarifahuseg keszulek-kotberrel
 FROM LEGACY.M_SOC S, MDM.INS_OFFER O,  (select @rownum :=0) r
WHERE S.CTN = O.USER_ID
  AND S.Svc_Class_Cd in ('SOC') -- ,'DSC','PP'
  AND O.OFFER_TYPE in ('OFFER_PLAN_BBOSS')
 -- nem fogadjuk el a null commitmentet commitment soc-kent, sem a hibasakat, sem a lejartakat:
  AND S.Comm_Start_Dt IS NOT NULL
  AND coalesce(S.Comm_End_Dt,S.Exp_Dt) IS NOT NULL
  AND coalesce(S.Comm_End_Dt,S.Exp_Dt) > S.Comm_Start_Dt
  AND least(coalesce(S.Comm_End_Dt,'2099-12-31 23:59:59'),
            coalesce(S.Exp_Dt,'2099-12-31 23:59:59'),
            '2099-12-31 23:59:59'
            ) between sysdate() and '2099-12-31 00:00:00' -- Kisebb legyen a maxdatumnal, azaz null kizart.
  -- AND S.NUMBER_OF_MONTHS IS NOT NULL -- ennek utana kell jarni !!!
  --
  -- Az uzlet adta meg, mely SOC-ok voatkoznak B2B tarifahusegre. Szolgaltatashuseget nem toltunk, mert nincs a Veris-ben ilyen funkcio. Az osszes tobbit (keszulekhuseg, leasing nem itt toltjuk, hanem a 7-es agban.)
  AND S.SOC_CD in (
  -- B2C tarifahuseg: Ezek mind megjelenhetnek B2B-ben is (biztosan migralando):
  '2XSTH1', '2XSTH2', '3XSTH2', 'LTH2', 'MTH2', 'STH2', 'XLTH2', 'XSTH', 'XSTH2', 'XXLTH2', 'LKH2ED', 'XSKH2ED', 'XXLKH2ED', 'SKH2ED', 
  -- B2B Egyosszegben terhelendo kotber (biztosan migralando): !!!Be kell kerni, melyik kategoriat kell ezeknek adni!!!
  'ATRPN2Y15', 'BUA2XSTH1', 'BUA2XSTH2', 'BUAILTH2', 'BUAIMTH2', 'BUAISTH2', 'BUAIXLTH2', 'BUAIXSTH2', 'BUALTH1', 'BUALTH2', 'BUASTH1', 'BUASTH2', 'BUAXSTH1', 'BUAXSTH2', 'BUAXXLTH1', 'BUAXXLTH2', 'BUTETH2', 'BUTITH2', 'CEXXLPEN2', 'CHIPRETH2', 'CORTH2', 'FLOTTH2', 'INDPEN3Y', 'INTPEN1Y', 'INTPEN2Y', 'VITAPEN', 'VITAPEN2', 'VITAPEN3', 'VITAPEN4', 'VITAPEN5', 'INTPUN2Y', 'INTPUN1Y'
  -- B2B SIMO: egyosszegu terheles, tehat migralando:
  , 'BUA2XSSO2', 'BUALSO2', 'BUASSO2', 'BUAXSSO2', 'BUAXXLSO2'
  -- B2C SIMO: ezek valoszinuleg nem migralandoak:
  -- , 'MYPPSTH2', 'OPENLTH2', 'OPENMTH2', 'OPENSTH2'
  )
group by
  S.CTN, O.OFFER_ID, S.Comm_No_Months, S.Comm_Start_Dt,
  S.Comm_End_Dt, S.Exp_Dt, S.Eff_Dt
;


*/
