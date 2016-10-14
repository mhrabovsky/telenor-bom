

use LEGACY;


/*
  MT: Teljesen ujragondolt FEATURE tablank van, ami a hasznalando sorokat tartalmazza csak.
  Ez az M_FEATURE_USED.
*/

drop table if exists M_FEATURE_EXTR;
create or replace view M_FEATURE_EXTR as
select
  add_or_swi           ,
  Sub_Id               ,
  ban                  ,
  ben                  ,
  ctn                  ,
  SOC_Cd               ,
  SOC_Seq_No           ,
  FEATURE_CODE         ,
  ftr_effective_date   ,
  ftr_expiration_date  ,
  service_ftr_seq_no   ,
  substring( txt_to_split, 1, INSTR(txt_to_split,'@') - 1 ) as txt_to_split
  from M_FEATURE_USED
;

/* ---------------------------------------------------------------------------
 *  tárolt eljaras a @-ot tartamazo oszlopok felosztasara
*/

drop procedure if exists bo_split_attrs;
delimiter $$
create procedure bo_split_attrs ( )
begin
  declare l_ctn VARCHAR(30);

    
    kukac_loop: LOOP
    drop table if exists M_FEATURE_EXTR_WORK;
    create table M_FEATURE_EXTR_WORK (
      add_or_swi           char(1)    ,
      Sub_Id               varchar(28),
      ban                  varchar(10),
      ben                  varchar(5) ,
      ctn                  varchar(11),
      SOC_Cd               char(9)    ,
      SOC_Seq_No           varchar(9) ,
      FEATURE_CODE         varchar(6) ,
      ftr_effective_date   date       ,
      ftr_expiration_date  date       ,
      service_ftr_seq_no   varchar(10),
      txt_to_split         text
    );

    insert M_FEATURE_EXTR_WORK
    select  
        add_or_swi
    ,    Sub_Id
    ,    ban
    ,    ben
    ,    ctn
    ,    SOC_Cd         
    ,    SOC_Seq_No 
    , FEATURE_CODE
    , ftr_effective_date
    , ftr_expiration_date
    ,    service_ftr_seq_no
    ,    substring( txt_to_split, 1, INSTR(txt_to_split,'@') - 1 ) as txt_to_split
        from M_FEATURE_EXTR
    where INSTR(txt_to_split,'@') > 1
        
    union
        
    select  
        add_or_swi
    ,    Sub_Id
    ,    ban
    ,    ben
    ,    ctn
    ,    SOC_Cd         
    ,    SOC_Seq_No 
           -- , soc_seq_no
    -- NGy 0609 egy sor
      , FEATURE_CODE
           , ftr_effective_date
           , ftr_expiration_date
    ,    service_ftr_seq_no
    ,    substring( txt_to_split, INSTR(txt_to_split,'@') + 1 ) as txt_to_split
        from M_FEATURE_EXTR
    ;
    
    drop table if exists M_FEATURE_EXTR;
    drop view if exists M_FEATURE_EXTR;
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
    Sub_Id varchar(28) default null,
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
    select  Sub_Id,ban
    ,    ben
    ,    ctn
           -- , soc_seq_no
    -- NGy 0609 egy sor
      , FEATURE_CODE
           , ftr_effective_date
           , ftr_expiration_date
    ,    service_ftr_seq_no
    ,     add_or_swi
    ,    trim( substring( txt_to_split, 1, INSTR(txt_to_split,'=') - 1 )) as attr_code
        ,    trim( substring( txt_to_split, INSTR(txt_to_split,'=') + 1 )) as attr_val
        from M_FEATURE_EXTR
    where 
           substring( txt_to_split, 1, INSTR(txt_to_split,'=') - 1 ) in (
        SELECT distinct LEGACY_PARAM_name 
          from LEGACY.M_IDID_ATTR_LDR
                WHERE LEGACY_PARAM_name IS NOT null )
         and length( trim( substring( txt_to_split, 1, INSTR(txt_to_split,'=') - 1 ))) > 0
         and length( trim( substring( txt_to_split, INSTR(txt_to_split,'=') + 1 ))) > 0
  ;
 
end$$
delimiter ;









/*  -----------------------------------------------------------------------------------------
*   igy lehet meghivni
*/
 use LEGACY;
 CALL bo_split_attrs;
