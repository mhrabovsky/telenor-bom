-- USE LEGACY;

-- Futasido (3-as gep, 910196 sor): 8 perc

-- NAS 10.07 beégetések bővítése
SET @MDM_TYPE_GSM_VAS = LEGACY.CONFIG('MDM_TYPE_GSM_VAS',NULL);


/*
  MT:
  Mar korabban behuztam ket uj oszlopot az M_OFFER_M10_MERGE tablaba:
    1. sub_type,
    2. VOICE_BILLING_INCREMENT.(vbi)

  Az M_OFFER_MAP-be (M_OFFER_WORK) modositottam a VOICE_BILLING_INCREMENT ertekeit az alabbi szerint:
    when '#01' then '1Sec'
    when '#02' then '1Min'
    when '#03' then '1Sec after 1Min'

  Az OFFER tablakon vegigvezettem az M_USER.Sub_Type es az M_OFFER_MAP.VOICE_BILLING_INCREMENT oszlopokat.
  Az IDID tablaba Sub_Type oszlopot tettem az alabbi szerint:
    CASE
      WHEN (Billing_Type = 2 AND Deduct_Flag = 1) THEN 'POS'
      WHEN (Billing_Type = 1 AND Deduct_Flag = 0) THEN 'PRE'
      WHEN (Billing_Type = 2 AND Deduct_Flag = 0) THEN 'HYB'
    END AS  Sub_Type
  
  Igy a split 2 es 10 kozvetlenul kapcsolodik az IDID tablahoz. Ha 10, akkor sub_type, ha 2, akkor sub_type+vbi kapcsolodik IDID.Sub_Type IDID.split_desc oszloppal.
  
  Split 4 esetben valojaban csak meg kell engednunk a tobbszorozest, de az eset azonos az alapesettel (kapcsolo: offer_cd)
  
  Split 9 esetben pedig sajat feloldo fajlunk van, az offer_cd-t ad vissza. Ahhoz hozzacsapjuk az offer_id/product_id/service/attr feloldast az IDID fajlokbol.
  
  Tehat csak Split 9 szamit sajatosnak; 4 nem uj eset; 10 es 2 pedig itt kezelendo.
*/

-- Split_Type=10 (valszeg jo)
UPDATE  LEGACY.M_OFFER_M10_MERGE      AS  MRG
,       LEGACY.M_IDID_OFFER_MOD       AS  IDM
SET
        MRG.Tgt_Offer_Id   = IDM.Relat_Offer_Id
,       MRG.Tgt_Offer_Name = IDM.Tgt_Offer_Name
,       MRG.Id2Id_Rec_Id   = IDM.Id2Id_Rec_Id
,       MRG.Split_Type     = IDM.Split_Type
WHERE   MRG.Tgt_Offer_Cd   = IDM.Tgt_Offer_Cd
AND     MRG.Tgt_Offer_Type = IDM.Tgt_Offer_Type
AND     @MDM_TYPE_GSM_VAS  = IDM.MDM_Type_Cd
AND     IDM.Split_Type     = 10
AND     MRG.Sub_Type       = IDM.Sub_Type
AND     MRG.Id2Id_Rec_Id  != IDM.Id2Id_Rec_Id
;

-- Ebbol hianyzik, hogy a Split_Type=2 eseten a vbi-t a main offerrol kell venni!!!
UPDATE  LEGACY.M_OFFER_M10_MERGE      AS  MRG
,       LEGACY.M_IDID_OFFER_MOD       AS  IDM
SET
        MRG.Tgt_Offer_Id   = IDM.Relat_Offer_Id
,       MRG.Tgt_Offer_Name = IDM.Tgt_Offer_Name
,       MRG.Id2Id_Rec_Id   = IDM.Id2Id_Rec_Id
,       MRG.Split_Type     = IDM.Split_Type
WHERE   MRG.Tgt_Offer_Cd   = IDM.Tgt_Offer_Cd
AND     MRG.Tgt_Offer_Type = IDM.Tgt_Offer_Type
AND     MRG.Sub_Type       = IDM.Sub_Type
AND     @MDM_TYPE_GSM_VAS  = IDM.MDM_Type_Cd
AND     IDM.Split_Type     =  2
AND     MRG.VOICE_BILLING_INCREMENT=IDM.Split_Desc
AND     MRG.Id2Id_Rec_Id  != IDM.Id2Id_Rec_Id
;
