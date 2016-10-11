DELIMITER $$
CREATE PROCEDURE DropIndex(in theIndexName varchar(128), in theTable varchar(128) )
BEGIN
 IF((SELECT COUNT(*) AS index_exists FROM information_schema.statistics WHERE TABLE_SCHEMA = DATABASE() and table_name = theTable AND index_name = theIndexName)  = 1) THEN
   SET @s = CONCAT('ALTER TABLE  ' , theTable , ' DROP INDEX ' , theIndexName);
   PREPARE stmt FROM @s;
   EXECUTE stmt;
 END IF;
END $$
