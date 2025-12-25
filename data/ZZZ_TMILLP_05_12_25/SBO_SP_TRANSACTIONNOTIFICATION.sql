CREATE PROCEDURE SBO_SP_TransactionNotification
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
error_message nvarchar (200); -- Error string to be displayed
DraftObj int;
begin

error := 0;
error_message := N'Ok';

IF Object_type = '4' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
    DECLARE ValidFor1 nvarchar(50);
    DECLARE UsrCod nvarchar(50);
    DECLARE ItemCode nvarchar(50);
    DECLARE ItemGrpCode nvarchar(50);
    DECLARE BrandName nvarchar(500);
    DECLARE ChemicalName nvarchar(500);
    DECLARE ISFA nvarchar(2);
    DECLARE ItemType NVARCHAR(5);

    IF :transaction_type = 'A' THEN
        SELECT T0."ItemCode",T0."validFor",T0."ItmsGrpCod",T0."U_B_URl",T0."U_C_URL",T0."U_IsFA",T1."USER_CODE", T0."ItemType"
        INTO ItemCode, ValidFor1, ItemGrpCode, BrandName, ChemicalName, ISFA, UsrCod, ItemType
        FROM OITM T0
        INNER JOIN OUSR T1 ON T1."USERID" = T0."UserSign"
        WHERE T0."ItemCode" = :list_of_cols_val_tab_del;
    ELSE
        SELECT T0."ItemCode",T0."validFor",T0."ItmsGrpCod",T0."U_B_URl",T0."U_C_URL",T0."U_IsFA",T1."USER_CODE"
        INTO ItemCode, ValidFor1, ItemGrpCode, BrandName, ChemicalName, ISFA, UsrCod
        FROM OITM T0
        INNER JOIN OUSR T1 ON T1."USERID" = T0."UserSign2"
        WHERE T0."ItemCode" = :list_of_cols_val_tab_del;
    END IF;

    IF UsrCod IN ('engg01', 'engg02', 'engg04', 'engg05', 'engg06', 'engg07') THEN
        IF ValidFor1 = 'Y' THEN
            error := -10001;
            error_message := N'Please Add Item in INACTIVE Mode';
        END IF;

        IF ItemCode NOT LIKE 'E%' AND ItemCode NOT LIKE 'SAFE%' THEN
            error := -10002;
            error_message := N'You are not allowed to create other than engineering item';
        END IF;
    END IF;

    IF ItemGrpCode = '100' THEN
        error := -10003;
        error_message := N'Please Select Proper Item Group';
    END IF;
    /*
    -- item group 105 - Finish Goods--
    IF ItemGrpCode = '105' AND ValidFor1 = 'Y' THEN
        IF IFNULL(BrandName,'') = '' THEN
            error := -10004;
            error_message := N'Please fill Brand Name URL';
        END IF;

        IF IFNULL(ChemicalName,'') = '' THEN
            error := -10005;
            error_message := N'Please fill Chemical Name URL';
        END IF;
    END IF;
    */
    IF ItemCode LIKE 'NU%' THEN
        IF UsrCod NOT IN ('sap01', 'sap02', 'manager') THEN
            error := -10006;
            error_message := N'You are not allowed to create NU Items.';
        END IF;

        IF UsrCod IN ('sap01', 'sap02', 'manager') AND ISFA IS NULL THEN
            error := -10007;
            error_message := N'Please select Y/N in Is Fixed Asset.';
        END IF;
    END IF;

    IF ItemType = 'I' AND UsrCod NOT IN ('account1','account2','prof01', 'dipurchase', 'purchase01', 'purchase02', 'manager', 'sap01','sap02', 'engg01', 'engg02', 'engg04', 'engg05', 'engg06', 'engg07') THEN
    	error := -10008;
        error_message := N'You are not allowed to add/update Item Master';
    END IF;
END IF;

------------------------------------------------------------------------------------------------
-- Select the return values-
select :error, :error_message FROM dummy;
End