USE LEGACY;

--             A ';' jelet leszedjuk a kombinaciok vegerol, hogy tisztan szeparator legyen.

UPDATE  M_OFFER_WORK
SET     Tgt_Offer_Cd   = TRIM(Tgt_Offer_Cd)
,       Tgt_Offer_Name = TRIM(Tgt_Offer_Name)
,       Src_Combo_List = TRIM(TRAILING ';' FROM TRIM(LEADING ';' FROM TRIM(Src_Combo_List)))
,       VOICE_BILLING_INCREMENT=
          case TRIM(VOICE_BILLING_INCREMENT)
            when '#01' then '1Sec'
            when '#02' then '1Min'
            when '#03' then '1Sec after 1Min'
            else TRIM(VOICE_BILLING_INCREMENT)
          end
;


UPDATE  M_OFFER_MANDADD_WORK
SET     Tgt_Offer_Cd    = TRIM(Tgt_Offer_Cd)
,       Tgt_Offer_Name  = TRIM(Tgt_Offer_Name)
,       Mand_Addon_List = TRIM(TRAILING ';' FROM TRIM(LEADING ';' FROM TRIM(Mand_Addon_List)))
,       VOICE_BILLING_INCREMENT=
          case TRIM(VOICE_BILLING_INCREMENT)
            when '#01' then '1Sec'
            when '#02' then '1Min'
            when '#03' then '1Sec after 1Min'
            else TRIM(VOICE_BILLING_INCREMENT)
          end
;
