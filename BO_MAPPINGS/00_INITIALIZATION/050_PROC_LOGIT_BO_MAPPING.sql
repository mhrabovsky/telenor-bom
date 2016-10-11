DELIMITER $$
CREATE PROCEDURE LOGIT_BO_MAPPING(IN p_ScriptName	VARCHAR(80),
								  IN p_ScriptPart	VARCHAR(50),
								  IN p_Note			VARCHAR(100),
								  IN p_RowNumber	INT)
BEGIN
	
	PREPARE stmt FROM "INSERT INTO ACC_BO_MAPPING(DOMAIN, MDM_NAME, SCRIPT_NAME, SCRIPT_PART, ROW_NUM, NOTE, EVENT_DATE) VALUES('BO', 'NULL', ?, ?, ?, ?, ?)";

	SET @ScriptName := p_ScriptName;
	SET @ScriptPart := p_ScriptPart;
	SET @RowNumber := p_RowNumber;
	SET @Note := p_Note;
	SET @SysDate := SYSDATE();
	
	EXECUTE stmt USING @ScriptName, @ScriptPart, @RowNumber, @Note, @SysDate;
	
	DEALLOCATE PREPARE stmt;

END $$

CALL LOGIT_BO_MAPPING('INIT', '050_PROC_LOGIT_BO_MAPPING.sql', 'WORK', 'CREATED', 1) $$