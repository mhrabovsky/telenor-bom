DELIMITER $$
CREATE PROCEDURE CreateRejectTable(in MDMTableName varchar(60))
BEGIN
     DECLARE l_TableName varchar(60);

     IF LENGTH(MDMTableName)>=56
        THEN SET l_TableName = concat(substr(MDMTableName,1,56),'_REJ');
        ELSE SET l_TableName = concat(       MDMTableName      ,'_REJ');
     END IF;

     IF((SELECT COUNT(*) AS table_exists FROM information_schema.tables WHERE TABLE_SCHEMA = DATABASE() and table_name = l_TableName )  != 0) THEN
        SET @s = CONCAT('DROP TABLE  ' , l_TableName);
        PREPARE stmt FROM @s;
        EXECUTE stmt;
     END IF;

     SET @s = CONCAT('CREATE TABLE ' , l_TableName, ' AS SELECT cast(null as char(400)) REJECT_REASON ,t.* FROM ' , MDMTableName, ' t WHERE 0=1 ');
     PREPARE stmt FROM @s;
     EXECUTE stmt;

END $$

CALL WORK.LOGIT_ACC('INIT', '060_PROC_CREATE_REJECT_TABLE.sql', 'MDM', 'CREATED', 1) $$