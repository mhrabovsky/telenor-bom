INSERT INTO REJECT_PARAM(REJECT_RULE_ID,
						 REJECT_CONDITION,
						 DESCRIPTION,
						 NOTE)
	VALUES('R10000',
		   'ACCT_ID IN ("200067215_1")',
		   'Az adott számla törlése',
		   '2016.08.04. BEN-nel nem rendelkező, LEGACY-ban nem tisztítható adat eldobása az üzleti döntés értelmében (Papp Zoltán)');

CALL LOGIT_ACC('INIT', '090_WORK_REJECT_PARAM_INSERTION.sql', 'WORK', 'INSERT', ROW_COUNT());