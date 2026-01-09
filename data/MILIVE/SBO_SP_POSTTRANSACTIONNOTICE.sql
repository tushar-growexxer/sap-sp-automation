CREATE PROCEDURE SBO_SP_PostTransactionNotice
(
	in object_type nvarchar(30), 				-- SBO Object Type
	in transaction_type nchar(1),			-- [A]dd, [U]pdate, [D]elete, [C]ancel, C[L]ose
	in num_of_cols_in_key int,
	in list_of_key_cols_tab_del nvarchar(255),
	in list_of_cols_val_tab_del nvarchar(255)
)
LANGUAGE SQLSCRIPT
AS
-- Return values
error  int;				-- Result (0 for no error)
error_message nvarchar (200); 		-- Error string to be displayed
------For MobiAlert
DocEntry int;
MailID nvarchar(200);
Mobile nvarchar(200);
EmailCC nvarchar(200);
EmailBCC nvarchar(200);
ObjectType nvarchar(200);
Mobi_TYPE nvarchar(200);
DBName nvarchar(200);
TEMP int;

begin

error := 0;
error_message := N'Ok';

---------------------Delivery--Mobi Alert---------09-12-2024----------By VC Team--------------------------------------------
IF (:object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

	select Count(*) into TEMP from
	(select T1."CardCode",min(T0."DueDate") as "DueDateOld",T1."Balance",T1."CreditLine" from JDT1 T0
		INNER JOIN OCRD T1 ON T0."ShortName" = T1."CardCode" and T1."CardType"='C' and T1."CardCode" LIKE 'CPE%'
		where T0."BalDueDeb" != T0."BalDueCred" and T1."CardCode" =
		(SELECT T0."CardCode" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
		group by T1."CardCode",T1."Balance",T1."CreditLine" ) as A where DAYS_BETWEEN(A."DueDateOld",Current_Date)<=0 and
			(SELECT T1."Balance" FROM ODRF T0
			left outer join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
			>=
			(SELECT T1."CreditLine" FROM ODRF T0
			Left Join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
			and (SELECT T0."GroupNum" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
			NOT IN (5,70,34,23,73);

	IF :TEMP > 0 THEN

		SELECT T0."DocEntry" INTO DocEntry FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15;

		MailID := 'cfo@matangiindustries.com';
		Mobile := '';
		EmailCC := 'saleshead@matangiindustries.com,Salesmgr@matangiindustries.com,Ramesh@matangiindustries.com';
		EmailBCC := '';
		ObjectType := 'A';
		Mobi_TYPE := 'Delivery Credit Limit Passed';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (115,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	END IF;
END IF;

---------------------Delivery--Mobi Alert---------16-12-2024------02 SalesDel Crd Lmt 0 and OD Days 0 to 15>>SM---------------------------------------------
IF (:object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

	select Count(*) into TEMP from
	(select T1."CardCode",min(T0."DueDate") as "DueDateOld",T1."Balance",T1."CreditLine" from JDT1 T0
		INNER JOIN OCRD T1 ON T0."ShortName" = T1."CardCode" and T1."CardType"='C' and T1."CardCode" LIKE 'CPE%'
		where T0."BalDueDeb" != T0."BalDueCred" and T1."Balance">0 and T1."CardCode" =
		(SELECT T0."CardCode" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
		group by T1."CardCode",T1."Balance",T1."CreditLine" ) as A where DAYS_BETWEEN(A."DueDateOld",Current_Date)>0 and DAYS_BETWEEN(A."DueDateOld",Current_Date)<=15 and
			(SELECT T1."Balance" FROM ODRF T0
			Left Join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
			<=
			(SELECT T1."CreditLine" FROM ODRF T0
			Left Join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
			and (SELECT T0."GroupNum" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15) NOT IN (5,70,34,23,73);

	IF :TEMP > 0 THEN

		SELECT T0."DocEntry" INTO DocEntry FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15;

		MailID := 'saleshead@matangiindustries.com,Salesmgr@matangiindustries.com';
		Mobile := '';
		EmailCC := 'Ramesh@matangiindustries.com';
		EmailBCC := '';
		ObjectType := 'B';
		Mobi_TYPE := 'Delivery - Credit Limit Passed2';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (115,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	END IF;
END IF;
---------------------Delivery--Mobi Alert---------16-12-2024------03 SalesDel Crd Lmt Cross and OD Days 0 to 15 -->CFO-----------------------------
IF (:object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

	select Count(*) into TEMP from
	(select T1."CardCode",min(T0."DueDate") as "DueDateOld",T1."Balance",T1."CreditLine" from JDT1 T0
		INNER JOIN OCRD T1 ON T0."ShortName" = T1."CardCode" and T1."CardType"='C' and T1."CardCode" LIKE 'CPE%'
		where T0."BalDueDeb" != T0."BalDueCred" and T1."Balance">0 and T1."CardCode" =
	(SELECT T0."CardCode" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
		group by T1."CardCode",T1."Balance",T1."CreditLine" ) as A where DAYS_BETWEEN(A."DueDateOld",Current_Date)>0 and DAYS_BETWEEN(A."DueDateOld",Current_Date)<=15 and
		(SELECT T1."Balance" FROM ODRF T0
		Left Join OCRD T1 on T0."CardCode" = T1."CardCode"
		WHERE T1."Balance">0 and T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
		>=
		(SELECT T1."CreditLine" FROM ODRF T0
		Left Join OCRD T1 on T0."CardCode" = T1."CardCode"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
		and (SELECT T0."GroupNum" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15) NOT IN (5,70,34,23,73);

	IF :TEMP > 0 THEN

		SELECT T0."DocEntry" INTO DocEntry FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15;

		MailID := 'cfo@matangiindustries.com';
		Mobile := '';
		EmailCC := 'Ramesh@matangiindustries.com,saleshead@matangiindustries.com,Salesmgr@matangiindustries.com';
		EmailBCC := '';
		ObjectType := 'D';
		Mobi_TYPE := 'Delivery - Credit Limit Passed3';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (115,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	END IF;
END IF;
---------------------Delivery--Mobi Alert---------16-12-2024------04 SalesDel Crd Lmt 0 and OD Days > 15 -->SM+CFO--------------------
IF (:object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

	select Count(*) into TEMP from
	(select T1."CardCode",min(T0."DueDate") as "DueDateOld",T1."Balance",T1."CreditLine" from JDT1 T0
		INNER JOIN OCRD T1 ON T0."ShortName" = T1."CardCode" and T1."CardType"='C' and T1."CardCode" LIKE 'CPE%'
		where T0."BalDueDeb" != T0."BalDueCred" and T1."CardCode" =
		(SELECT T0."CardCode" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
		group by T1."CardCode",T1."Balance",T1."CreditLine" ) as A where DAYS_BETWEEN(A."DueDateOld",Current_Date)>15 and
			(SELECT T1."Balance" FROM ODRF T0
			left outer join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T1."Balance">0 and T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
			<=
			(SELECT T1."CreditLine" FROM ODRF T0
			Left Join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
			and (SELECT T0."GroupNum" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15) NOT IN (5,70,34,23,73);

	IF :TEMP > 0 THEN

		SELECT T0."DocEntry" INTO DocEntry FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15;

		MailID := 'cfo@matangiindustries.com';
		Mobile := '';
		EmailCC := 'Ramesh@matangiindustries.com,saleshead@matangiindustries.com,Salesmgr@matangiindustries.com';
		EmailBCC := '';
		ObjectType := 'E';
		Mobi_TYPE := 'Delivery - Credit Limit Passed4';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (115,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	END IF;
END IF;
---------------------Delivery--Mobi Alert---------16-12-2024------05 SalesDel Crd Lmt > 0 and OD Days > 15 -->SM+CFO---------------
IF (:object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

	select Count(*) into TEMP from
	(select T1."CardCode",min(T0."DueDate") as "DueDateOld",T1."Balance",T1."CreditLine" from JDT1 T0
		INNER JOIN OCRD T1 ON T0."ShortName" = T1."CardCode" and T1."CardType"='C' and T1."CardCode" LIKE 'CPE%'
		where T0."BalDueDeb" != T0."BalDueCred" and T1."CardCode" =
		(SELECT T0."CardCode" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
		group by T1."CardCode",T1."Balance",T1."CreditLine" ) as A where DAYS_BETWEEN(A."DueDateOld",Current_Date)>15 and
			(SELECT T1."Balance" FROM ODRF T0
			left outer join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T1."Balance">0 and T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
			>=
			(SELECT T1."CreditLine" FROM ODRF T0
			Left Join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15)
			and (SELECT T0."GroupNum" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15) NOT IN (5,70,34,23,73);

	IF :TEMP > 0 THEN

		SELECT T0."DocEntry" INTO DocEntry FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 15;

		MailID := 'cfo@matangiindustries.com';
		Mobile := '';
		EmailCC := 'Ramesh@matangiindustries.com,saleshead@matangiindustries.com,Salesmgr@matangiindustries.com';
		EmailBCC := '';
		ObjectType := 'F';
		Mobi_TYPE := 'Delivery - Credit Limit Passed5';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (115,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	END IF;
END IF;

---------------------AR Invoice--Mobi Alert---------16-12-2024------06 SalesInv Crd Lmt < 0 and OD Days > 10 -->CFO---------------
IF (:object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

	select Count(*) into TEMP from
	(select T1."CardCode",min(T0."DueDate") as "DueDateOld",T1."Balance",T1."CreditLine" from JDT1 T0
		INNER JOIN OCRD T1 ON T0."ShortName" = T1."CardCode" and T1."CardType"='C' and T1."CardCode" LIKE 'CPD%'
		where T0."BalDueDeb" != T0."BalDueCred" and T1."Balance">0 and T1."CardCode" =
		(SELECT T0."CardCode" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13)
		group by T1."CardCode",T1."Balance",T1."CreditLine" ) as A where DAYS_BETWEEN(A."DueDateOld",Current_Date)<0 and
			(SELECT T1."Balance" FROM ODRF T0
			left outer join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T1."Balance">0 and T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13)
			>=
			(SELECT T1."CreditLine" FROM ODRF T0
			Left Join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13)
			and (SELECT T0."GroupNum" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13) NOT IN (5,70,34,23,73);

	IF :TEMP > 0 THEN

		SELECT T0."DocEntry" INTO DocEntry FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13;
		MailID := 'cfo@matangiindustries.com';
		Mobile := '';
		EmailCC := 'ramesh@matangiindustries.com,amsales1@matangiindustries.com';
		EmailBCC := '';
		ObjectType := 'K';
		Mobi_TYPE := 'Invoice - Credit Limit Passed06';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (113,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	END IF;
END IF;

---------------------AR Invoice--Mobi Alert---------16-12-2024------07 SalesInv Crd Lmt 0 and OD Days 0 to 10>>SM---------------------------------------------
IF (:object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

	select Count(*) into TEMP from
	(select T1."CardCode",min(T0."DueDate") as "DueDateOld",T1."Balance",T1."CreditLine" from JDT1 T0
		INNER JOIN OCRD T1 ON T0."ShortName" = T1."CardCode" and T1."CardType"='C' and T1."CardCode" LIKE 'CPD%'
		where T0."BalDueDeb" != T0."BalDueCred" and T1."Balance">0 and T1."CardCode" =
		(SELECT T0."CardCode" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13)
		group by T1."CardCode",T1."Balance",T1."CreditLine" ) as A where DAYS_BETWEEN(A."DueDateOld",Current_Date)>0 and DAYS_BETWEEN(A."DueDateOld",Current_Date)<=10 and
			(SELECT T1."Balance" FROM ODRF T0
			left outer join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13)
			<=
			(SELECT T1."CreditLine" FROM ODRF T0
			Left Join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13)
			and (SELECT T0."GroupNum" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13) NOT IN (5,70,34,23,73);

	IF :TEMP > 0 THEN

		SELECT T0."DocEntry" INTO DocEntry FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13;

		MailID := 'amsales1@matangiindustries.com';
		Mobile := '';
		EmailCC := 'ramesh@matangiindustries.com';
		EmailBCC := '';
		ObjectType := 'H';
		Mobi_TYPE := 'Invoice - Credit Limit Passed07';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (113,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	END IF;
END IF;
---------------------AR Invoice--Mobi Alert---------16-12-2024------08 SalesInv Crd Lmt Cross and OD Days 0 to 10 -->CFO-----------------------------
IF (:object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

	select Count(*) into TEMP from
	(select T1."CardCode",min(T0."DueDate") as "DueDateOld",T1."Balance",T1."CreditLine" from JDT1 T0
		INNER JOIN OCRD T1 ON T0."ShortName" = T1."CardCode" and T1."CardType"='C' and T1."CardCode" LIKE 'CPD%'
		where T0."BalDueDeb" != T0."BalDueCred" and T1."Balance">0 and T1."CardCode" =
		(SELECT T0."CardCode" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13)
		group by T1."CardCode",T1."Balance",T1."CreditLine" ) as A where DAYS_BETWEEN(A."DueDateOld",Current_Date)>0 and DAYS_BETWEEN(A."DueDateOld",Current_Date)<=10 and
			(SELECT T1."Balance" FROM ODRF T0
			left outer join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T1."Balance">0 and T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13)
			>=
			(SELECT T1."CreditLine" FROM ODRF T0
			Left Join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13)
			and (SELECT T0."GroupNum" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13) NOT IN (5,70,34,23,73);

	IF :TEMP > 0 THEN

		SELECT T0."DocEntry" INTO DocEntry FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13;

		MailID := 'cfo@matangiindustries.com';
		Mobile := '';
		EmailCC := 'ramesh@matangiindustries.com,amsales1@matangiindustries.com';
		EmailBCC := '';
		ObjectType := 'I';
		Mobi_TYPE := 'Invoice - Credit Limit Passed08';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (113,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	END IF;
END IF;

---------------By VC Team------Invoice--Mobi Alert---------12-12-2024-------09 SalesInv Crd Lmt 0 and OD Days > 10 -->SM+CFO--------------------------

IF (:object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN


	select Count(*) into TEMP  from
(select T0."ShortName",T1."Balance", T1."CreditLine",Min(T0."DueDate") as "MinDueDate" from JDT1 T0
INNER JOIN OCRD T1 ON T0."ShortName" = T1."CardCode" and T1."CardType"='C' and  T1."CardCode" LIKE 'CPD%'
where  T0."BalDueDeb" != T0."BalDueCred" and T1."Balance">0 and T0."TransType" <> 30
group by T0."ShortName",T1."Balance", T1."CreditLine") as A
where  Days_Between(A."MinDueDate",Current_Date)>10
	and
	(SELECT T0."GroupNum" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 13) NOT IN (5,70,34,23,73)
	and
	(SELECT T1."Balance" FROM ODRF T0
	Left Join OCRD T1 on T0."CardCode" = T1."CardCode"
	WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 13)
	<=
	(SELECT T1."CreditLine" FROM ODRF T0
	Left Join OCRD T1 on T0."CardCode" = T1."CardCode"
	WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 13)
	and
	A."ShortName" = (SELECT T0."CardCode" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 13);

	IF :TEMP > 0 THEN

		SELECT T0."DocEntry" INTO DocEntry FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" = 13;

		MailID := 'cfo@matangiindustries.com,amsales1@matangiindustries.com';
		Mobile := '';
		EmailCC := 'Ramesh@matangiindustries.com';
		EmailBCC := '';
		ObjectType := 'C';
		Mobi_TYPE := 'Invoice Credit Limit Passed';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (113,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	END IF;
END IF;
---------------------AR Invoice--Mobi Alert---------16-12-2024------10 SalesInv Crd Lmt > 0 and OD Days > 10 -->SM+CFO--------------------
IF (:object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

	select Count(*) into TEMP from
	(select T1."CardCode",min(T0."DueDate") as "DueDateOld",T1."Balance",T1."CreditLine" from JDT1 T0
		INNER JOIN OCRD T1 ON T0."ShortName" = T1."CardCode" and T1."CardType"='C' and T1."CardCode" LIKE 'CPD%'
		where T0."BalDueDeb" != T0."BalDueCred" and T1."Balance">0 and T1."CardCode" =
		(SELECT T0."CardCode" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13)
		group by T1."CardCode",T1."Balance",T1."CreditLine" ) as A where DAYS_BETWEEN(A."DueDateOld",Current_Date)>10 and
			(SELECT T1."Balance" FROM ODRF T0
			Left Join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T1."Balance">0 and T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13)
			>=
			(SELECT T1."CreditLine" FROM ODRF T0
			Left Join OCRD T1 on T0."CardCode" = T1."CardCode"
			WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13)
			and (SELECT T0."GroupNum" FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13) 	NOT IN (5,70,34,23,73);

	IF :TEMP > 0 THEN

		SELECT T0."DocEntry" INTO DocEntry FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType" =13;

		MailID := 'cfo@matangiindustries.com';
		Mobile := '';
		EmailCC := 'ramesh@matangiindustries.com,amsales1@matangiindustries.com';
		EmailBCC := '';
		ObjectType := 'J';
		Mobi_TYPE := 'Invoice - Credit Limit Passed10';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (113,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	END IF;
END IF;

---Purchase Request to PO Generate Alert for Unit-I----
IF (:object_type = '22' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

select count(*) into Temp from OPOR T0
Inner Join POR1 T1 on T0."DocEntry"=T1."DocEntry"
Inner Join OITM T2 on T1."ItemCode"=T2."ItemCode"
where T0."CANCELED"='N' and T1."BaseType"='1470000113' and T2."ItmsGrpCod" in ('109','110','111','112','114','115','117','119') and T0."BPLId"='3' and T0."DocEntry"=:list_of_cols_val_tab_del;

If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM OPOR T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;
		MailID:= 'eni@matangiindustries.com,project1@matangiindustries.com';
		Mobile := '';
		EmailCC := 'devarsh@matangiindustries.com,unithead1@matangiindustries.com,purchasemgr@matangiindustries.com';
		EmailBCC := '';
		ObjectType := 'P';
		Mobi_TYPE := 'Po Generated U1';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (122,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

---Purchase Request to PO Generate Alert for Unit-II----
IF (:object_type = '22' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

select count(*) into Temp from OPOR T0
Inner Join POR1 T1 on T0."DocEntry"=T1."DocEntry"
Inner Join OITM T2 on T1."ItemCode"=T2."ItemCode"
where T0."CANCELED"='N' and T1."BaseType"='1470000113' and T2."ItmsGrpCod" in ('109','110','111','112','114','115','117','119') and T0."BPLId"='4' and T0."DocEntry"=:list_of_cols_val_tab_del;

If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM OPOR T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;
		MailID:= 'eni@matangiindustries.com,project1@matangiindustries.com';
		Mobile := '';
		EmailCC := 'ramesh@matangiindustries.com,unithead2@matangiindustries.com,purchasemgr@matangiindustries.com';
		EmailBCC := '';
		ObjectType := 'O';
		Mobi_TYPE := 'Po Generated U2';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (122,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;
---Sales Order Export remarks alert to Export team----
IF (:object_type = '17' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

select count(*) into Temp from ORDR T0
where T0."CANCELED"='N'  and (T0."CardCode" like 'CPE%' or T0."CardCode" like 'COE%' or T0."CardCode" like 'CIE%')
and CAST(T0."U_ExportRemarks" as Nvarchar)='Yes' and T0."DocEntry"=:list_of_cols_val_tab_del;

If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM ORDR T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;
		MailID:= 'exports@matangiindustries.com,impex@matangiindustries.com,export.doc@matangiindustries.com';
		Mobile := '';
		EmailCC := 'mgrppc@matangiindustries.com,amexport@matangiindustries.com,saleshead@matangiindustries.com,salesmgr@matangiindustries.com';
		EmailBCC := '';
		ObjectType := 'S';
		Mobi_TYPE := 'Sales Order Export Remarks Alert';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (117,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

---Sales Order Export remarks alert to Export team----
/*IF (:object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

select count(*) into Temp from ODRF T0
where T0."CANCELED"='N'  and (T0."CardCode" like 'CPE%' or T0."CardCode" like 'COE%' or T0."CardCode" like 'CIE%')
and CAST(T0."U_ExportRemarks" as Nvarchar)='Yes' and T0."DocEntry"=:list_of_cols_val_tab_del;

If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM ORDR T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;
		MailID:= 'exports@matangiindustries.com,impex@matangiindustries.com,export.doc@matangiindustries.com';
		Mobile := '';
		EmailCC := 'amexport@matangiindustries.com,salesmgr@matangiindustries.com';
		EmailBCC := '';
		ObjectType := 'S';
		Mobi_TYPE := 'Sales Order Export Remarks Alert';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (117,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;*/

---Outgoing Payment Advice for RM/PM----
IF (:object_type = '46' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

select count(*) into Temp from OVPM where Left("CardCode",4) in ('VIRD','VIRI','VPRD','VPRI','VPPD') and "DocEntry"=:list_of_cols_val_tab_del;

If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM OVPM T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;
		select STRING_AGG("E_MailL",',') INTO MailID from
		(
			select Distinct T1."E_MailL" FROM OCRD T0
			Inner Join OCPR T1 on T0."CardCode"=T1."CardCode"
			Inner Join OVPM T2 on T0."CardCode"=T2."CardCode"
			where  T0."CardType"='S' and T2."Canceled"='N' and Left(T0."CardCode",4) in ('VIRD','VIRI','VPRD','VPRI','VPPD') and T2."DocEntry"=:list_of_cols_val_tab_del
		) P;
		Mobile := '';
		EmailCC := 'purchasemgr1@matangiindustries.com';
		EmailBCC := 'accounts2@matangiindustries.com,accounts8@matangiindustries.com';
		ObjectType := 'R';
		Mobi_TYPE := 'Outgoing Payment Advice';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (146,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

---Outgoing Payment Advice for Engineering----
IF (:object_type = '46' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

select count(*) into Temp from OVPM where Left("CardCode",4) in ('VEXP','VFAS','VGPR','VLAB') and "DocEntry"=:list_of_cols_val_tab_del;

If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM OVPM T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;
		select STRING_AGG("E_MailL",',') INTO MailID from
		(
			select Distinct T1."E_MailL" FROM OCRD T0
			Inner Join OCPR T1 on T0."CardCode"=T1."CardCode"
			Inner Join OVPM T2 on T0."CardCode"=T2."CardCode"
			where  T0."CardType"='S' and T2."Canceled"='N' and Left(T0."CardCode",4) in ('VEXP','VFAS','VGPR','VLAB') and T2."DocEntry"=:list_of_cols_val_tab_del
		) P;
		Mobile := '';
		EmailCC := 'purchasemgr@matangiindustries.com';
		EmailBCC := 'accounts2@matangiindustries.com,accounts8@matangiindustries.com';
		ObjectType := 'E';
		Mobi_TYPE := 'Outgoing Payment Advice Engg MLLP';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (146,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

IF (:object_type = 'SHIPMASTER' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

	select count(*) into Temp from "@SHIPMASTER" where IFNULL("U_Scheme1",'')<>'' and IFNULL("U_BLDate",'')='' and "Code"=:list_of_cols_val_tab_del;

	If :Temp > 0 then

		SELECT T0."Code" INTO DocEntry FROM "@SHIPMASTER" T0 WHERE T0."Code"=:list_of_cols_val_tab_del;

		SELECT CASE WHEN SUM(CASE WHEN T1."Email" IN ('sales4@matangiindustries.com','bde4@matangiindustries.com') THEN 1 ELSE 0 END) > 0 THEN CONCAT('saleshead@matangiindustries.com,', STRING_AGG(T1."Email", ','))
			   		WHEN COUNT(T1."Email") > 0 THEN CONCAT('saleshead@matangiindustries.com,salesmgr@matangiindustries.com,', STRING_AGG(T1."Email", ','))
		        	ELSE 'saleshead@matangiindustries.com,salesmgr@matangiindustries.com'
		       END AS "MailID" INTO MailID
		FROM "@SHIPMASTER" S0
		JOIN OCRD T0 ON S0."U_BPCode" = T0."CardCode"
		LEFT JOIN OSLP T1 ON T0."SlpCode" = T1."SlpCode"
		WHERE  T0."CardType" = 'C' AND S0."Code" = :list_of_cols_val_tab_del;
		Mobile := '';
		EmailCC := 'mgrppc@matangiindustries.com,amexport@matangiindustries.com,export.doc@matangiindustries.com,impex@matangiindustries.com,exports@matangiindustries.com,export.logistic@matangiindustries.com';
		EmailBCC := 'sap2@matangiindustries.com,sap@matangiindustries.com';
		ObjectType := 'X';
		Mobi_TYPE := 'Vessel/Voyage Data';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
			CALL "MOBIALERT"."Add_Config_Proc" (333,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

---Sales Order Generate alert to Business Head(SC,DI,OF)----
IF (:object_type = '17' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

select count(*) into Temp from ORDR T0
where T0."CANCELED"='N'
and (T0."CardCode" like 'CSE%' or T0."CardCode" like 'COE%' or T0."CardCode" like 'CIE%'  or T0."CardCode" like 'CID%' or T0."CardCode" like 'COD%' or T0."CardCode" like 'CSD%')
and T0."DocEntry"=:list_of_cols_val_tab_del;

If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM ORDR T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;
		MailID:= 'devarsh@matangiindustries.com';
		Mobile := '';
		EmailCC := '';
		EmailBCC := '';
		ObjectType := 'R';
		Mobi_TYPE := 'Sales Order ';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (117,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

----------------------------- PR of RM is generated --------------------------------------------
IF (:object_type = '1470000113' AND (:transaction_type = 'A')) THEN

	select count(T0."DocEntry") INTO Temp from OPRQ T0 JOIN PRQ1 T1 ON T0."DocEntry" = T1."DocEntry" JOIN OUSR T3 ON T3."USERID" = T0."UserSign"
	WHERE (T1."ItemCode" LIKE 'PC%') AND T3."USER_CODE" IN ('prod07') and T0."DocEntry"=:list_of_cols_val_tab_del;

	If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM OPRQ T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;

		MailID = 'purchasemgr1@matangiindustries.com,purchase@matangiindustries.com,sanjay@matangiindustries.com,deepak@matangiindustries.com';
		Mobile := '';
		EmailCC := 'mgrppc@matangiindustries.com,ea1@matangiindustries.com,exppc@matangiindustries.com';
		EmailBCC := 'sap@matangiindustries.com,sap2@matangiindustries.com';
		ObjectType := 'P';
		Mobi_TYPE := 'RM PR Generated - MILIVE';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
			CALL "MOBIALERT"."Add_Config_Proc" (334,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;
----------------------------- Customer Complain Generated --------------------------------------------
IF (:object_type = '191' AND (:transaction_type = 'A' /*or :transaction_type = 'U'*/)) THEN

	select count(T0."callID") INTO Temp from OSCL T0 WHERE T0."callID"=:list_of_cols_val_tab_del;

	SELECT STRING_AGG("Email", ',') INTO EmailCC FROM

		(SELECT T2."Email" AS "Email" FROM OSCL T0
		JOIN OCRD T1 ON T0."customer" = T1."CardCode"
	    JOIN OSLP T2 ON T2."SlpCode" = T1."SlpCode"
	    WHERE T0."callID"=:list_of_cols_val_tab_del

	    UNION ALL

	    SELECT 'saleshead@matangiindustries.com,salesmgr@matangiindustries.com' from dummy) E;


	If :Temp > 0 then

		SELECT T0."callID" INTO DocEntry FROM OSCL T0 WHERE T0."callID"=:list_of_cols_val_tab_del;

		MailID = 'qaqcmgr@matangiindustries.com,qa@matangiindustries.com';
		Mobile := '';
		EmailCC := 'unithead1@matangiindustries.com,unithead2@matangiindustries.com,productionmgr2@matangiindustries.com,mgrproductionpc2@matangiindustries.com';
		EmailBCC := '';
		ObjectType := 'C';
		Mobi_TYPE := 'Customer Complain';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
			CALL "MOBIALERT"."Add_Config_Proc" (191,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;
--------------------------------------------------------------------------------------------------------------------------------
--- Direct Purchase Order Generated : PC,SC/DI,OF ----
IF (:object_type = '22' AND (:transaction_type = 'A')) THEN

select count(*) into Temp from OPOR T0
Inner Join POR1 T1 on T0."DocEntry"=T1."DocEntry"
Inner Join OITM T2 on T1."ItemCode"=T2."ItemCode"
where T0."CANCELED"='N' and (T1."ItemCode" like 'PC%' OR T1."ItemCode" like 'DI%' OR T1."ItemCode" like 'OF%') AND T1."BaseType"<>'1470000113'
and T0."DocEntry"=:list_of_cols_val_tab_del;

Select DISTINCT CONCAT(CASE WHEN T1."ItemCode" like 'PC%' then 'ramesh@matangiindustries.com,'
				   			WHEN (T1."ItemCode" like 'DI%' OR T1."ItemCode" like 'OF%') then 'devarsh@matangiindustries.com,'
			  		   END
					  ,'mgrppc@matangiindustries.com,ea1@matangiindustries.com,exppc@matangiindustries.com') INTO EmailCC
FROM POR1 T1 WHERE T1."DocEntry"=:list_of_cols_val_tab_del;

If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM OPOR T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;

		MailID:= 'purchasemgr1@matangiindustries.com,purchase@matangiindustries.com,sanjay@matangiindustries.com,deepak@matangiindustries.com';
		Mobile := '';
		EmailBCC := 'sap@matangiindustries.com,sap2@matangiindustries.com';
		ObjectType := 'A';
		Mobi_TYPE := 'Po Generated PC,SC/DI,OF';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (122,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

--------------------------------------- Sample Ready ---------------------------------

IF (:object_type = 'SPLREQ' AND (:transaction_type = 'A' or :transaction_type = 'U')) THEN

	select count(T0."DocEntry") INTO Temp from "@SAMPLEREQH" T0 JOIN "@SAMPLEREQD" T1 ON T0."DocEntry" = T1."DocEntry" WHERE T1."U_SampleReady" = 'Yes' AND T0."DocEntry" = :list_of_cols_val_tab_del;

	If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM "@SAMPLEREQH" T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

		select oslp."Email" into MailID from oqut
		join oslp on oqut."SlpCode" = oslp."SlpCode"
		join "@SAMPLEREQH" on "@SAMPLEREQH"."U_ReqDocEntry" = oqut."DocEntry"
		where "@SAMPLEREQH"."DocEntry" = :list_of_cols_val_tab_del ;
		Mobile := '';
		EmailCC := 'salesmgr@matangiindustries.com';
		EmailBCC := 'sap2@matangiindustries.com,sap@matangiindustries.com';
		ObjectType := 'S';
		Mobi_TYPE := 'Sample Request (QC & RND)';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
			CALL "MOBIALERT"."Add_Config_Proc" (1000,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

--- Purchase Request to Purchase Order Generated : PC,SC/DI,OF ----
IF (:object_type = '22' AND (:transaction_type IN ('A','U'))) THEN

select count(*) into Temp from OPOR T0
Inner Join POR1 T1 on T0."DocEntry"=T1."DocEntry"
Inner Join OITM T2 on T1."ItemCode"=T2."ItemCode"
where T0."CANCELED"='N' and (T1."ItemCode" like 'PC%' OR T1."ItemCode" like 'DI%' OR T1."ItemCode" like 'OF%') AND T1."BaseType"='1470000113'
and T0."DocEntry"=:list_of_cols_val_tab_del;

If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM OPOR T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;

		Select DISTINCT CONCAT(CASE WHEN T1."ItemCode" like 'PC%' then 'ramesh@matangiindustries.com,'
						   			WHEN (T1."ItemCode" like 'DI%' OR T1."ItemCode" like 'OF%') then 'devarsh@matangiindustries.com,'
					  		   END
							  ,'mgrppc@matangiindustries.com,ea1@matangiindustries.com,exppc@matangiindustries.com') INTO EmailCC
		FROM POR1 T1 WHERE T1."DocEntry"=DocEntry;

		MailID:= 'purchasemgr1@matangiindustries.com,purchase@matangiindustries.com,sanjay@matangiindustries.com,deepak@matangiindustries.com';
		Mobile := '';
		EmailBCC := 'sap@matangiindustries.com,sap2@matangiindustries.com';
		ObjectType := 'B';
		Mobi_TYPE := 'Pr to Po Generated PC,SC/DI,OF';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (122,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

----------------------------------------------- Debit Note --------------------------------------------------------
IF (:object_type = '19' AND (:transaction_type IN ('A','U'))) THEN

	select count(*) into Temp from ORPC where "DocEntry"=:list_of_cols_val_tab_del;

	If :Temp > 0 then

			SELECT T0."DocEntry" INTO DocEntry FROM ORPC T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;

			select STRING_AGG("E_MailL",',') INTO MailID from
			(
				select distinct T1."E_MailL" from OCRD T0
				Inner Join OCPR T1 on T0."CardCode"=T1."CardCode"
				Inner Join ORPC T2 on T0."CardCode"=T2."CardCode"
				where T2."CANCELED"='N' and T2."DocEntry"=:list_of_cols_val_tab_del
			) P;

			SELECT
			    CASE
			        WHEN LEFT("CardCode",4) IN ('VIRD','VIRI','VPRD','VPRI','VPPD','VORD','VORI') THEN 'purchasemgr1@matangiindustries.com,accounts8@matangiindustries.com'
			        WHEN LEFT("CardCode",4) IN ('VEXP','VFAS','VGPR','VLAB') THEN 'purchasemgr@matangiindustries.com,accounts8@matangiindustries.com'
			    END
			INTO EmailCC FROM ORPC WHERE "DocEntry" = :list_of_cols_val_tab_del;

			SELECT
				CASE
					WHEN LEFT("CardCode",4) IN ('VIRD','VIRI','VPRD','VPRI','VPPD','VORD','VORI') THEN 'E'
					WHEN LEFT("CardCode",4) IN ('VEXP','VFAS','VGPR','VLAB') THEN 'D'
				END
			INTO ObjectType FROM ORPC WHERE "DocEntry" = :list_of_cols_val_tab_del;

			Mobile := '';
			EmailBCC := 'sap@matangiindustries.com,sap2@matangiindustries.com';
			Mobi_TYPE := 'Debit Note';
			Select CURRENT_SCHEMA Into DBName from Dummy;
			If(:DBName = 'MILIVE') Then
				CALL "MOBIALERT"."Add_Config_Proc" (119,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
			END IF;
	End If;
End If;
-----------------------------------AR Invoice Generated---------------------------------------------
---Sales Invoice Generate alert to Business Head(SC,DI,OF)----
IF (:object_type = '13' AND (:transaction_type = 'A')) THEN

select count(*) into Temp from OINV T0
Where T0."CANCELED"='N' and Left(T0."CardCode",3) in ('COE','COD','CID','CIE') and T0."DocEntry"=:list_of_cols_val_tab_del;

If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM OINV T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;
		MailID:= 'devarsh@matangiindustries.com';
		Mobile := '';
		EmailCC := '';
		EmailBCC := 'sap@matangiindustries.com,sap2@matangiindustries.com';
		ObjectType := 'A';
		Mobi_TYPE := 'A/R Invoice Generated ';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (1113,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;
-----------------------------------AR Invoice Generated---------------------------------------------
---Sales Invoice Generate alert to Business Head(PC)----
IF (:object_type = '13' AND (:transaction_type = 'A')) THEN

select count(*) into Temp from OINV T0
Where T0."CANCELED"='N' and Left(T0."CardCode",3) in ('CPE','CPD') and T0."DocEntry"=:list_of_cols_val_tab_del;

If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM OINV T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;
		MailID:= 'ramesh@matangiindustries.com';
		Mobile := '';
		EmailCC := '';
		EmailBCC := 'sap@matangiindustries.com,sap2@matangiindustries.com';
		ObjectType := 'I';
		Mobi_TYPE := 'A/R Invoice Generated ';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (1113,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

-------------------------------------------- Sample Request ----------------------------------------------------------

IF (:object_type = '23' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

select count(*) into Temp from OQUT T0 JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry"
Where T0."CANCELED"='N' AND T1."U_Department" = 'QC' and T0."DocEntry"=:list_of_cols_val_tab_del;

If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM OQUT T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;
		MailID := 'qc@matangiindustries.com,qclab@matangiindustries.com';
		Mobile := '';
		EmailCC := '';
		EmailBCC := 'sap@matangiindustries.com,sap2@matangiindustries.com';
		ObjectType := 'K';
		Mobi_TYPE := 'Sample Request';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MILIVE') Then
		CALL "MOBIALERT"."Add_Config_Proc" (459,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

--SELECT * FROM View_Objdet

-- Select the return values
select :error, :error_message FROM dummy;

end;