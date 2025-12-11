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
--------------------------------------------------------------------------------------------------------------------------------
---Purchase Request to PO Generate Alert for MSPL Unit-I----
IF (:object_type = '22' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

select count(*) into Temp from OPOR T0
Inner Join POR1 T1 on T0."DocEntry"=T1."DocEntry"
Inner Join OITM T2 on T1."ItemCode"=T2."ItemCode"
where T0."CANCELED"='N' and T1."BaseType"='1470000113' and T2."ItmsGrpCod" in ('109','110','111','112','114','115','117','119') and T0."BPLId"='3' and T0."DocEntry"=:list_of_cols_val_tab_del;

If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM OPOR T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;
		MailID:= 'eni@minalspecialities.com,project1@minalspecialities.com';
		Mobile := '';
		EmailCC := 'devarsh@minalspecialities.com,unithead@minalspecialities.com,purchasemgr@minalspecialities.com';
		EmailBCC := '';
		ObjectType := 'R';
		Mobi_TYPE := 'Po Generated MSPL U1';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MSPL') Then
		CALL "MOBIALERT"."Add_Config_Proc" (122,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
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
		MailID:= 'devarsh@minalspecialities.com';
		Mobile := '';
		EmailCC := '';
		EmailBCC := '';
		ObjectType := 'A';
		Mobi_TYPE := 'Sales Order ';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MSPL') Then
		CALL "MOBIALERT"."Add_Config_Proc" (117,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

IF (:object_type = 'SHIPMASTER' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

	select count(*) into Temp from "@SHIPMASTER" where IFNULL("U_Scheme1",'')<>'' and IFNULL("U_BLDate",'')='' and "Code"=:list_of_cols_val_tab_del;

	If :Temp > 0 then

		SELECT T0."Code" INTO DocEntry FROM "@SHIPMASTER" T0 WHERE T0."Code"=:list_of_cols_val_tab_del;

		SELECT CASE WHEN SUM(CASE WHEN T1."Email" <> 'oglead@minalspecialities.com' THEN 1 ELSE 0 END) > 0 THEN CONCAT('oglead@minalspecialities.com,', STRING_AGG(T1."Email", ','))
		        	ELSE 'oglead@minalspecialities.com'
		       END AS "MailID" INTO MailID
		FROM "@SHIPMASTER" S0
		JOIN OCRD T0 ON S0."U_BPCode" = T0."CardCode"
		LEFT JOIN OSLP T1 ON T0."SlpCode" = T1."SlpCode"
		WHERE  T0."CardType" = 'C' AND S0."Code" = :list_of_cols_val_tab_del;
		Mobile := '';
		EmailCC := 'mgrppc@matangiindustries.com,amexport@matangiindustries.com,export.doc@matangiindustries.com,impex@matangiindustries.com,exports@matangiindustries.com,export.logistic@matangiindustries.com';
		EmailBCC := 'sap2@matangiindustries.com,sap@matangiindustries.com';
		ObjectType := 'Y';
		Mobi_TYPE := 'Vessel/Voyage Data';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MSPL') Then
			CALL "MOBIALERT"."Add_Config_Proc" (335,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

----------------------------- Customer Complain Generated --------------------------------------------
IF (:object_type = '191' AND (:transaction_type = 'A' /*or :transaction_type = 'U'*/)) THEN

	select count(T0."callID") INTO Temp from OSCL T0 WHERE T0."callID"=:list_of_cols_val_tab_del;

	If :Temp > 0 then

		SELECT T0."callID" INTO DocEntry FROM OSCL T0 WHERE T0."callID"=:list_of_cols_val_tab_del;

		MailID = 'qaqcmgr@matangiindustries.com,qa@matangiindustries.com';
		Mobile := '';
		EmailCC := 'oglead@minalspecialities.com';
		EmailBCC := '';
		ObjectType := 'C';
		Mobi_TYPE := 'Customer Complain';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MSPL') Then
			CALL "MOBIALERT"."Add_Config_Proc" (291,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

--- Direct Purchase Order Generated : PC,SC/DI,OF ----
IF (:object_type = '22' AND (:transaction_type = 'A')) THEN

select count(*) into Temp from OPOR T0
Inner Join POR1 T1 on T0."DocEntry"=T1."DocEntry"
Inner Join OITM T2 on T1."ItemCode"=T2."ItemCode"
where T0."CANCELED"='N' and (T1."ItemCode" like 'PC%' OR T1."ItemCode" like 'SC%' OR T1."ItemCode" like 'OF%') AND T1."BaseType"<>'1470000113'
and T0."DocEntry"=:list_of_cols_val_tab_del;


If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM OPOR T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;

		MailID:= 'purchasemgr1@minalspecialities.com,purchase5@minalspecialities.com,sanjay@minalspecialities.com,deepak@minalspecialities.com';
		Mobile := '';
		EmailCC := 'devarsh@minalspecialities.com,mgrppc@matangiindustries.com,ea1@matangiindustries.com,exppc@matangiindustries.com';
		EmailBCC := 'sap@matangiindustries.com,sap2@matangiindustries.com';
		ObjectType := 'D';
		Mobi_TYPE := 'Po Generated PC,SC/DI,OF';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MSPL') Then
		CALL "MOBIALERT"."Add_Config_Proc" (122,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

--- Purchase Request to Purchase Order Generated : PC,SC/DI,OF ----
IF (:object_type = '22' AND (:transaction_type IN ('A','U'))) THEN

select count(*) into Temp from OPOR T0
Inner Join POR1 T1 on T0."DocEntry"=T1."DocEntry"
Inner Join OITM T2 on T1."ItemCode"=T2."ItemCode"
where T0."CANCELED"='N' and (T1."ItemCode" like 'PC%' OR T1."ItemCode" like 'SC%' OR T1."ItemCode" like 'OF%') AND T1."BaseType"='1470000113'
and T0."DocEntry"=:list_of_cols_val_tab_del;


If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM OPOR T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;

		MailID:= 'purchasemgr1@minalspecialities.com,purchase5@minalspecialities.com,sanjay@minalspecialities.com,deepak@minalspecialities.com';
		Mobile := '';
		EmailCC := 'devarsh@minalspecialities.com,mgrppc@matangiindustries.com,ea1@matangiindustries.com,exppc@matangiindustries.com';
		EmailBCC := 'sap@matangiindustries.com,sap2@matangiindustries.com';
		ObjectType := 'C';
		Mobi_TYPE := 'Pr to Po Generated PC,SC/DI,OF';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MSPL') Then
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
		EmailCC := 'oglead@minalspecialities.com';
		EmailBCC := 'sap2@matangiindustries.com,sap@matangiindustries.com';
		ObjectType := 'S';
		Mobi_TYPE := 'Sample Request (QC & RND)';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MSPL') Then
			CALL "MOBIALERT"."Add_Config_Proc" (1000,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

----------------------------------------------- Debit Note --------------------------------------------------------
IF (:object_type = '19' AND (:transaction_type IN ('A'))) THEN

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
			        WHEN LEFT("CardCode",4) IN ('VSRD','VSRI','VPRD','VPRI','VPPD','VORD','VORI') THEN 'purchasemgr1@minalspecialities.com,accounts8@minalspecialities.com'
			        WHEN LEFT("CardCode",4) IN ('VEXP','VFAS','VGPR','VLAB') THEN 'purchasemgr@minalspecialities.com,accounts8@minalspecialities.com'
			    END
			INTO EmailCC FROM ORPC WHERE "DocEntry" = :list_of_cols_val_tab_del;

			SELECT
				CASE
					WHEN LEFT("CardCode",4) IN ('VSRD','VSRI','VPRD','VPRI','VPPD','VORD','VORI') THEN 'Y'
					WHEN LEFT("CardCode",4) IN ('VEXP','VFAS','VGPR','VLAB') THEN 'X'
				END
			INTO ObjectType FROM ORPC WHERE "DocEntry" = :list_of_cols_val_tab_del;

			Mobile := '';
			EmailBCC := 'sap@matangiindustries.com,sap2@matangiindustries.com';
			Mobi_TYPE := 'Debit Note';
			Select CURRENT_SCHEMA Into DBName from Dummy;
			If(:DBName = 'MSPL') Then
				CALL "MOBIALERT"."Add_Config_Proc" (119,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
			END IF;
	End If;
End If;
---Outgoing Payment Advice for RM/PM----
IF (:object_type = '46' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN

select count(*) into Temp from OVPM where Left("CardCode",4) in ('VSRD','VSRI','VPRD','VPRI','VPPD','VORD','VORI') and "DocEntry"=:list_of_cols_val_tab_del;

If :Temp > 0 then

		SELECT T0."DocEntry" INTO DocEntry FROM OVPM T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del;
		select STRING_AGG("E_MailL",',') INTO MailID from
		(
			select Distinct T1."E_MailL" FROM OCRD T0
			Inner Join OCPR T1 on T0."CardCode"=T1."CardCode"
			Inner Join OVPM T2 on T0."CardCode"=T2."CardCode"
			where  T0."CardType"='S' and T2."Canceled"='N' and Left(T0."CardCode",4) in ('VSRD','VSRI','VPRD','VPRI','VPPD','VORD','VORI') and T2."DocEntry"=:list_of_cols_val_tab_del
		) P;
		Mobile := '';
		EmailCC := 'purchasemgr1@minalspecialities.com';
		EmailBCC := 'accounts@minalspecialities.com,accounts8@minalspecialities.com';
		ObjectType := 'X';
		Mobi_TYPE := 'Outgoing Payment Advice RM MSPL';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MSPL') Then
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
		EmailCC := 'purchasemgr@minalspecialities.com';
		EmailBCC := 'accounts@minalspecialities.com,accounts8@minalspecialities.com';
		ObjectType := 'F';
		Mobi_TYPE := 'Outgoing Payment Advice Engg MSPL';
		Select CURRENT_SCHEMA Into DBName from Dummy;
		If(:DBName = 'MSPL') Then
		CALL "MOBIALERT"."Add_Config_Proc" (146,:DocEntry,:transaction_type,:MailID,:Mobile,:EmailCC,:EmailBCC,:ObjectType,:Mobi_TYPE);
		END IF;
	End If;
End If;

--------------------------------------------------------------------------------------------------------------------------------
-- Select the return values
select :error, :error_message FROM dummy;

end;