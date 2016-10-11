delimiter //
create procedure WAIT_FOR_READY (
in board_name varchar(64),
in domain_name varchar(64),
in table_name varchar(64),
in remote_name varchar(64),
in locale_name varchar(64))
begin
declare buf VARCHAR(512);
set @col_ret = null;
set buf = CONCAT('select READY from MDM.',board_name ,
    ' where DOMAIN=',"'", domain_name,"'",
    ' and TABLE_NAME=',"'", table_name,"'",
    ' limit 1 into @col_ret ;' );
SET @sqlCommand = buf;
PREPARE _preparedStatement FROM @sqlCommand;
--
-- Wait for ready to be 1
--
    wait_loop: loop
EXECUTE _preparedStatement;
if @col_ret = 1
then
leave wait_loop;
else
set @junk = sleep(5);
end if;
end loop wait_loop;
--
    -- drop local copy table
--
    set buf = CONCAT('DROP TABLE IF EXISTS MDM.',locale_name ,' ;' );
SET @sqlCommand = buf;
PREPARE _preparedStatement FROM @sqlCommand;
EXECUTE _preparedStatement;
--
    -- Remote table copy to local
--
    set buf = CONCAT('create table MDM.',locale_name,
    ' as select * from MDM.',remote_name ,
    ';' );
SET @sqlCommand = buf;
PREPARE _preparedStatement FROM @sqlCommand;
EXECUTE _preparedStatement;
deallocate prepare _preparedStatement;
end//
delimiter ;

CALL WORK.LOGIT_ACC('INIT', '140_PROC_WAIT_FOR_READY.sql', 'MDM', 'CREATED', 1);