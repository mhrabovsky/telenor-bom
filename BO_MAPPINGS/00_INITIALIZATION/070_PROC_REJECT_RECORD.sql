DELIMITER $$
CREATE PROCEDURE RejectRecord(in MDMTableName varchar(60), in RejectRuleID varchar(30), in CheckMethod varchar(10), in LogParam varchar(80) )
BEGIN
     DECLARE l_TableName varchar(60);
     DECLARE l_Condition varchar(400);

     -- reject tábla neve
     IF LENGTH(MDMTableName)>=56
        THEN SET l_TableName = concat(substr(MDMTableName,1,56),'_REJ');
        ELSE SET l_TableName = concat(       MDMTableName      ,'_REJ');
     END IF;

     -- ha létezik a reject paramétertábla
     IF((SELECT COUNT(*) AS table_exists FROM information_schema.tables WHERE TABLE_SCHEMA = 'WORK' and table_name = 'REJECT_PARAM' )  = 1) THEN

        -- megkeressük a reject feltételt a paramétertáblában
        IF ((SELECT COUNT(*) FROM WORK.REJECT_PARAM WHERE REJECT_RULE_ID = RejectRuleID) = 1 ) THEN
            SELECT REJECT_CONDITION INTO l_Condition FROM WORK.REJECT_PARAM WHERE REJECT_RULE_ID = RejectRuleID limit 1;
        END IF;
     END IF;

     -- ha nem találtuk meg a szabályt ID alapján, akkor olyan dummy feltételt adunk meg, ami soha nem teljesül, nehogy véletlenül töröljünk valamit, amit nem kellene
     IF COALESCE(l_Condition,'###') = '###' THEN
        SET l_Condition = '0 = 1 /*dummy*/';
     END IF;


     -- ha megvan  a reject tábla és nem a dummy feltétel van beállítva
     IF(    (SELECT COUNT(*) AS table_exists FROM information_schema.tables WHERE TABLE_SCHEMA = DATABASE() and table_name = l_TableName )  = 1
        AND l_Condition != '0 = 1 /*dummy*/'
       )
     THEN

         -- itt lehet még finomítani a szabályon, ha kell, pl. replace, trim, stb. (a macskaköröt kicserélem dupla-aposztrófra)
         SET l_Condition = REPLACE(TRIM(l_Condition),'"','''');

         SET SQL_SAFE_UPDATES = 0;

         -- ha a feltételt sértő rekordokat meg kellene jelölni a már elrejectált rekordoknál is ("COMPLETE"-vizsgálat), akkor a reject táblát is átnézzük
         IF COALESCE(CheckMethod,'###') = 'COMPLETE' THEN
             SET @s = CONCAT('UPDATE ' , l_TableName, ' SET REJECT_REASON = CONCAT(REJECT_REASON,''<',RejectRuleID,'>'') WHERE ',l_Condition);
             PREPARE stmt FROM @s;
             EXECUTE stmt;

         END IF;

         -- beszúrjuk a feltételt kielégítő rekordokat az eredeti MDM táblából a reject táblába
         SET @s = CONCAT('INSERT INTO ' , l_TableName, ' SELECT ''<',RejectRuleID,'>'' ,t.* FROM ' , MDMTableName, ' t WHERE ', l_Condition);
         PREPARE stmt FROM @s;
         EXECUTE stmt;

         -- töröljük az eredeti MDM táblából azokat a rekordokat, amelyekre igaz a megfogalmazott feltétel
         SET @s = CONCAT('DELETE FROM ' , MDMTableName, ' WHERE ', l_Condition);
         PREPARE stmt FROM @s;
         EXECUTE stmt;

         SET @rec_num = ROW_COUNT();

         SET SQL_SAFE_UPDATES = 1;

         -- csak akkor logoljuk a törlés eredményét, ha van logtáblánk
         IF((SELECT COUNT(*) AS table_exists FROM information_schema.tables WHERE TABLE_SCHEMA = 'WORK' and table_name = 'ACC_LOG' )  = 1) THEN

            CALL WORK.LOGIT_ACC(MDMTableName, LogParam, 'MDM', 'DELETE', @rec_num);

         END IF;

         COMMIT;

     END IF;

END $$

CALL WORK.LOGIT_ACC('INIT', '070_PROC_REJECT_RECORD.sql', 'MDM', 'CREATED', 1) $$