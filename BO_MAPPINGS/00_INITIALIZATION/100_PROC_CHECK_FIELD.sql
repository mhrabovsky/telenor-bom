DELIMITER $$
CREATE PROCEDURE CHECK_FIELD(in LegacyTableName varchar(60), in ColumnName varchar(60), in CheckMethod varchar(10))
BEGIN
     DECLARE l_FieldType    varchar(60);
     DECLARE l_ParamValue   varchar(6);
     DECLARE l_count        INT DEFAULT 0;
     DECLARE l_exists       INT DEFAULT 0;

     DECLARE l_ParamName    varchar(60);

     -- létezik-e a runtime paramétertábla
     IF((SELECT COUNT(*) AS table_exists FROM information_schema.tables WHERE TABLE_SCHEMA = 'WORK' and table_name = 'RUNTIME_PARAMS' )  = 1) THEN

        -- megkeressük a paramétertáblában a megfelelő kulcsot, hogy fel van-e véve
        SET @s = CONCAT('SELECT COUNT(*) INTO @l_exists FROM WORK.RUNTIME_PARAMS WHERE PARAM_NAME = ''CHECK_',CheckMethod,''' ');

        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        IF (@l_exists = 1 ) THEN
            CASE CheckMethod
                WHEN 'NOT_NULL' THEN
                    SET @s = CONCAT('SELECT PARAM_VALUE INTO @l_ParamValue FROM WORK.RUNTIME_PARAMS WHERE PARAM_NAME = ''CHECK_NOT_NULL'' limit 1 ');
                WHEN 'UNIQENESS' THEN
                    SET @s = CONCAT('SELECT PARAM_VALUE INTO @l_ParamValue FROM WORK.RUNTIME_PARAMS WHERE PARAM_NAME = ''CHECK_UNIQENESS'' limit 1 ');
            END CASE;

            PREPARE stmt FROM @s;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;

            -- megnézzük, hogy TRUE-e a paraméter értéke
            IF @l_ParamValue='TRUE' THEN


                -- ha létezik a mező, elvégezzük az ellenőrzést
                IF ((
                         SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
                         WHERE  TABLE_SCHEMA = DATABASE()
                             AND  TABLE_NAME = LegacyTableName
                             AND COLUMN_NAME = ColumnName
                    ) = 1) THEN

                    -- metódus ellenőrzése
                    CASE CheckMethod
                        WHEN 'NOT_NULL' THEN
                            SET @s = CONCAT('SELECT COUNT(*) AS CNT INTO @myResult FROM ', LegacyTableName, ' WHERE ', ColumnName, ' IS NULL OR LENGTH(', ColumnName, ') = 0 ');
                        WHEN 'UNIQENESS' THEN
                            SET @s = CONCAT('SELECT COUNT(*) AS CNT INTO @myResult FROM (SELECT ', ColumnName, ' , COUNT(1) AS CNT  FROM ', LegacyTableName, ' WHERE ', ColumnName, ' IS NOT NULL GROUP BY ', ColumnName, ' HAVING COUNT(1) >1 )X ');
                    END CASE;

                    PREPARE stmt FROM @s;
                    EXECUTE stmt;
                    DEALLOCATE PREPARE stmt;

                    SET l_count = @myResult;
					
					INSERT INTO WORK.LEGACY_VALIDATION_RESULT VALUES(LegacyTableName, ColumnName, CheckMethod, l_count);

                    PREPARE stmt FROM @res;
                    EXECUTE stmt;
                    DEALLOCATE PREPARE stmt;

                END IF;

            END IF;

        END IF;
     END IF;

END $$

CALL WORK.LOGIT_ACC('INIT', '100_PROC_CHECK_FIELD.sql', 'LEGACY', 'CREATED', 1) $$