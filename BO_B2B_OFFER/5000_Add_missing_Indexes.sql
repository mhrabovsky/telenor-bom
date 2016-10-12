USE LEGACY;

DELIMITER $$
DROP PROCEDURE IF EXISTS `createindex_ifnotexists`
$$
CREATE PROCEDURE `createindex_ifnotexists`(db VARCHAR(128), tableName VARCHAR(128), IN indexColumns VARCHAR(256))
BEGIN
   DECLARE indexName VARCHAR(256);
   DECLARE cols VARCHAR(256);
   SET cols=concat(",",UPPER(indexColumns));
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
END$$
DELIMITER ;

/*
CALL LEGACY.createindex_ifnotexists(
       'LEGACY'
      ,'FEATURE_LDR'
      ,'CTN,SOC_SEQ_NO');
*/

USE LEGACY;

-- CREATE TABLE LEGACY._DROP_INDEXES AS SELECT 1;

DROP PROCEDURE IF EXISTS index_handling;

DELIMITER $$

CREATE PROCEDURE index_handling()
BEGIN
 DECLARE v_finished INTEGER DEFAULT 0;
 DECLARE sqlCommand varchar(1000) DEFAULT "";

 -- declare cursor for employee email
 DECLARE index_cursor CURSOR FOR
 SELECT   DISTINCT CONCAT('DROP INDEX ', S.INDEX_NAME,' ON ',S.TABLE_SCHEMA, '.', S.TABLE_NAME) AS COMMAND
 FROM     information_schema.TABLES T
         INNER JOIN information_schema.STATISTICS S ON T.TABLE_CATALOG = S.TABLE_CATALOG AND T.TABLE_SCHEMA = S.TABLE_SCHEMA
 WHERE    T.TABLE_NAME = '_DROP_INDEXES' AND S.NON_UNIQUE = 1
 ORDER BY 1;

 -- declare NOT FOUND handler
 DECLARE CONTINUE HANDLER
        FOR NOT FOUND SET v_finished = 1;

  OPEN index_cursor;

 get_index:
  LOOP
    FETCH index_cursor INTO sqlCommand;

    IF v_finished = 1
    THEN
      LEAVE get_index;
    END IF;

    SET @CMD = sqlCommand;
    PREPARE _preparedStatement FROM @CMD;
    EXECUTE _preparedStatement;
    SELECT sqlCommand as INFO;
  END LOOP get_index;

  CLOSE index_cursor;
END
$$

DELIMITER ;

-- CALL LEGACY.index_handling();

USE LEGACY;

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