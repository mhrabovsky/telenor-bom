
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
