DELIMITER $$
CREATE PROCEDURE `headMake`(IN my_table_name varchar(255))
BEGIN

     DECLARE done INT DEFAULT 0;

     DECLARE v_field_name VARCHAR(100);
     DECLARE field_names VARCHAR(2000);


     DECLARE field_cursor CURSOR FOR
         SELECT COLUMN_NAME
         FROM INFORMATION_SCHEMA.COLUMNS
         WHERE (TABLE_NAME = my_table_name AND table_schema = 'MDM');


     DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

     set field_names = '';

     OPEN field_cursor;
     REPEAT
        FETCH field_cursor
             INTO v_field_name;

         IF not done then

             IF ISNULL(NULLIF(field_names,'')) THEN
                  set field_names = v_field_name;
              ELSE
                 set field_names = concat(field_names,'\t',v_field_name);
             END IF;

         END IF;
     UNTIL done END REPEAT;

    CLOSE field_cursor;

    INSERT INTO MDM.COLFILE (fieldnames)VALUES (field_names);

END $$