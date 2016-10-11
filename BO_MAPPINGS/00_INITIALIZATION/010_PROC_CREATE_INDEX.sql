DELIMITER $$
CREATE PROCEDURE CreateIndex(in theIndexName varchar(128), in theTable varchar(128), in theIndexColumns varchar(128)  )
BEGIN
 IF((SELECT COUNT(*) AS index_exists FROM information_schema.statistics WHERE TABLE_SCHEMA = DATABASE() and table_name = theTable AND index_name = theIndexName)  = 0) THEN
   SET @s = CONCAT('CREATE INDEX ' , theIndexName , ' ON ' , theTable, '(', theIndexColumns, ')');
   PREPARE stmt FROM @s;
   EXECUTE stmt;
 END IF;
END $$
