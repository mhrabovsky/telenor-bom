-- 0900.

DELIMITER $$
DROP PROCEDURE IF EXISTS LEGACY.`createindex_ifnotexists`
$$
CREATE PROCEDURE LEGACY.`createindex_ifnotexists`(db VARCHAR(128), tableName VARCHAR(128), IN indexColumns VARCHAR(256))
BEGIN
   DECLARE indexName VARCHAR(256);
   DECLARE cols VARCHAR(256);
   SET cols=concat(",",indexColumns);
   SET indexName = cols; -- CONCAT("IDX_" , tableName ,  cols);
   SET cols=concat(cols,",");

   IF EXISTS (
   SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA=db AND TABLE_NAME=tableName) THEN
    set @iname=indexName;
    select count(*) from (SELECT @iname:=replace(@iname,UPPER(column_name),cast(ORDINAL_POSITION as char(50))) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=db AND TABLE_NAME=tableName
    AND LOCATE(concat(",",UPPER(column_name),","), cols ) > 0) f into @foo;
   END IF;
    SET indexName = CONCAT("IDX_" , tableName , replace(@iname,',','_'));
   -- SELECT indexName,indexColumns; -- check the result
   
   IF((SELECT COUNT(*) AS index_exists FROM information_schema.statistics
     WHERE TABLE_SCHEMA = db AND table_name = tableName AND LOCATE(indexName, index_name)>0)  = 0) THEN
      SET @sqlCommand = CONCAT('CREATE INDEX ' , indexName , ' ON ' , db, '.', tableName, '(', indexColumns, ')');
      PREPARE _preparedStatement FROM @sqlCommand;
      EXECUTE _preparedStatement;
	  SELECT @sqlCommand as INFO;
   END IF;
END
$$
DELIMITER ;

DROP TABLE IF EXISTS LEGACY._CONFIG;

CREATE TABLE LEGACY._CONFIG
(
   KEY_FIELD   VARCHAR(30) NOT NULL,
   VALUE       VARCHAR(100)  CHARSET latin1 NULL,
   PRIMARY KEY(KEY_FIELD)
)
ENGINE = MyIsam;

DELIMITER $$
DROP FUNCTION IF EXISTS LEGACY.CONFIG
$$
CREATE FUNCTION LEGACY.`CONFIG`(NAME VARCHAR(30), DEFVAL VARCHAR(100))
RETURNS varchar(100) CHARSET latin1
DETERMINISTIC
BEGIN
 DECLARE RETVAL VARCHAR(100);
 SET RETVAL = (SELECT VALUE FROM LEGACY._CONFIG WHERE KEY_FIELD = NAME LIMIT 1);
 IF RETVAL IS NULL THEN
   SET RETVAL = DEFVAL;
   INSERT INTO LEGACY._CONFIG SELECT NAME, DEFVAL;
 END IF;
 RETURN RETVAL;
END
$$
DELIMITER ;

-- ABO 10/12 13:54