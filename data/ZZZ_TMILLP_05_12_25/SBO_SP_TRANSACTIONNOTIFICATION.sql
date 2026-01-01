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
            error_message := N'Please Add Item in INACTIVE Mode.';
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
    /*
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
    */
    IF ItemType = 'I' AND UsrCod NOT IN ('account1','account2','prof01', 'dipurchase', 'purchase01', 'purchase02', 'manager', 'sap01','sap02', 'engg01', 'engg02', 'engg04', 'engg05', 'engg06', 'engg07') THEN
    	error := -10008;
        error_message := N'You are not allowed to add/update Item Master';
    END IF;
END IF;


IF Object_type = '2' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
    DECLARE CardType nvarchar(50);
    DECLARE Organisation nvarchar(50);
    DECLARE Industry nvarchar(50);
    DECLARE ValidFor nvarchar(50);
    DECLARE Series nvarchar(50);
    DECLARE SlpCode int;
    DECLARE LeadSource nvarchar(50);
    DECLARE Territory int;
    DECLARE UsrCod nvarchar(50);
    DECLARE UsrCod2 nvarchar(50);
    DECLARE MSMEtype nvarchar(50);
    DECLARE MSME nvarchar(35);
    DECLARE PaymentTermsCount int;
    DECLARE BDPerson nvarchar(100);
    DECLARE BDPCount int;
    DECLARE SLPCount int;
    DECLARE LeadSourceI int;
    DECLARE LeadSourceO int;
    DECLARE BDP1Count int;
    DECLARE MobiAlert nvarchar(10);
    DECLARE LabelType nvarchar(100);
    DECLARE DebAcct nvarchar(50);
    DECLARE GroupTypee nvarchar(10);

    SELECT
        OCRD."CardType", OCRD."U_Organisation_Id", OCRD."IndustryC", OCRD."validFor",
        OCRD."SlpCode", OCRD."U_Lead_Source", OCRD."Territory", OCRD."U_MSME_Type",
        OCRD."U_Udyam_certi", OCRD."U_BDPerson", OCRD."U_Mobi_Alert", NNM1."SeriesName",
        OUSR."USER_CODE", OCRD."U_LabelType", cast(OCRD."DebPayAcct" as nvarchar), cast(OCRD."GroupCode" as nvarchar)
    INTO
        CardType, Organisation, Industry, ValidFor,
        SlpCode, LeadSource, Territory, MSMEtype,
        MSME, BDPerson, MobiAlert, Series,
        UsrCod, LabelType, DebAcct, GroupTypee
    FROM OCRD
    INNER JOIN NNM1 ON NNM1."Series" = OCRD."Series"
    INNER JOIN OUSR ON OUSR."USERID" = ( CASE WHEN :transaction_type = 'A' THEN OCRD."UserSign" ELSE OCRD."UserSign2" END )
    WHERE OCRD."CardCode" = :list_of_cols_val_tab_del;

    IF (GroupTypee = '105' AND DebAcct not in ('21000320')) OR (GroupTypee = '103' AND DebAcct not in ('21000315')) OR (GroupTypee = '106' AND DebAcct not in ('21003211'))
       OR (GroupTypee = '102' AND DebAcct not in ('11200510')) OR (GroupTypee = '104' AND DebAcct not in ('11200520')) THEN

       error := -20018;
       error_message := N'Please select proper Accounts Payable in Business Partner.';

    END IF;

    /*IF (
     -- Group → Account
     (GroupTypee = '105' AND IFNULL(DebAcct,'') <> '21000320')
  OR (GroupTypee = '103' AND IFNULL(DebAcct,'') <> '21000315')
  OR (GroupTypee = '106' AND IFNULL(DebAcct,'') <> '21003211')
  OR (GroupTypee = '102' AND IFNULL(DebAcct,'') <> '11200510')
  OR (GroupTypee = '104' AND IFNULL(DebAcct,'') <> '11200520')

     -- Account → Group
  OR (IFNULL(DebAcct,'') = '21000320' AND GroupTypee <> '105')
  OR (IFNULL(DebAcct,'') = '21000315' AND GroupTypee <> '103')
  OR (IFNULL(DebAcct,'') = '21003211' AND GroupTypee <> '106')
  OR (IFNULL(DebAcct,'') = '11200510' AND GroupTypee <> '102')
  OR (IFNULL(DebAcct,'') = '11200520' AND GroupTypee <> '104')
)
THEN
   error := -20018;
   error_message := N'Please select proper Accounts Payable in Business Partner.';
END IF;*/




    IF ValidFor = 'Y' THEN
        IF :transaction_type = 'A' THEN
            error := -20001;
            error_message := N'Please ADD Business partner in INACTIVE Mode';
        ELSE
            IF UsrCod NOT IN ('manager', 'prof01', 'sap01','sap02') THEN
                error := -20002;
                error_message := N'Please UPDATE Business partner in INACTIVE Mode';
            END IF;
        END IF;
    END IF;

    IF CardType = 'C' THEN
        IF Series LIKE 'C%' THEN

            IF IFNULL(Organisation,'') = '' THEN
                error := -20003;
                error_message := N'Please enter Organisation ID';
            END IF;
            IF IFNULL(Industry,'') = '' THEN
                error := -20004;
                error_message := N'Please select Industry';
            END IF;
            IF SlpCode = -1 THEN
                error := -20005;
                error_message := N'Please select Sales employee';
            END IF;
            IF IFNULL(LeadSource,'') = '' THEN
                error := -20006;
                error_message := N'Please select Lead Source';
            END IF;
            IF Territory IS NULL THEN
                error := -20007;
                error_message := N'Please select Territory';
            END IF;
            IF IFNULL(MobiAlert,'') = '' THEN
                error := -20008;
                error_message := N'Please select Mobi Alert Yes/No for Customer Payment reminder mail.';
            END IF;
        END IF;
        IF UsrCod IN ('crm01', 'crm04') THEN
            IF Series NOT LIKE 'C%' THEN
                error := -20009;
                error_message := N'Please select proper Type and proper Series ' || Series;
            END IF;
        END IF;

        SELECT COUNT(OCRD."DocEntry") INTO PaymentTermsCount
        FROM OCRD
        INNER JOIN OCTG ON OCRD."GroupNum" = OCTG."GroupNum"
        WHERE OCRD."CardCode" = :list_of_cols_val_tab_del
        AND OCRD."CardType" = 'C'
        AND OCTG."ExtraDays" > 102;

        IF PaymentTermsCount > 0 THEN
            error := -20010;
            error_message := 'Payment Terms not allowed more than 90 days for new Customer';
        END IF;

        IF IFNULL(BDPerson,'') = '' THEN
            error := -20011;
            error_message := N'Please Enter BD Person Name.';
        END IF;

        SELECT COUNT(T0."SlpCode") INTO SLPCount
        FROM OCRD T0
        INNER JOIN OSLP T1 ON T0."SlpCode" = T1."SlpCode"
        WHERE T0."CardType" = 'C'
        AND T1."GroupCode" NOT IN (1,3)
        AND T0."CardCode" = :list_of_cols_val_tab_del;

        IF SLPCount > 0 THEN
            error := -20012;
            error_message := N'You cannot select the Sales Employee as their Commission Group is not Sales Person.';
        END IF;

        SELECT COUNT(T0."U_BDPerson") INTO LeadSourceI FROM OCRD T0
        WHERE T0."CardType" = 'C' AND T0."U_Lead_Source" = 'Inbound' AND T0."U_BDPerson" <> 'Digital Marketing'
        AND T0."CardCode" = :list_of_cols_val_tab_del;

        IF LeadSourceI > 0 THEN
            error := -20013;
            error_message := N'This customer''s lead source is inbound, You can only select digital marketing in the BD Person';
        END IF;

        SELECT COUNT(T0."U_BDPerson") INTO LeadSourceO
        FROM OCRD T0
        WHERE T0."CardType" = 'C' AND T0."U_Lead_Source" = 'Outbound' AND T0."U_BDPerson" = 'Digital Marketing'
        AND T0."CardCode" = :list_of_cols_val_tab_del;

        IF LeadSourceO > 0 THEN
            error := -20014;
            error_message := N'This customer''s lead source is Outbound, You can not select digital marketing in the BD Person';
        END IF;

        SELECT COUNT(T0."U_BDPerson") INTO BDP1Count
        FROM OCRD T0
        WHERE T0."U_BDPerson" NOT IN ( SELECT "SlpName" FROM OSLP WHERE "GroupCode" IN (2,3,4))
        AND T0."CardType" = 'C' AND T0."CardCode" = :list_of_cols_val_tab_del;

        IF BDP1Count > 0 THEN
            error := -20015;
            error_message := N'The selected BD person does not match the standard BD person list.';
        END IF;

        IF :transaction_type = 'A' AND LabelType IN ('Without Matangi Logo & Address') THEN
        	error := -20018;
            error_message := N'You are not allowed to select this label type.';
        END IF;
    END IF;

    IF CardType = 'S' THEN
        IF UsrCod IN ('purchase', 'dipurchase') THEN

            IF Series NOT LIKE 'V%' THEN
                error := -20016;
                error_message := N'Please select proper Type and Proper Series ' || Series;
            END IF;

        END IF;

        IF :transaction_type = 'A' AND Series LIKE 'V%' THEN
            IF UPPER(IFNULL(MSMEtype,'')) <> 'NA' THEN
                IF IFNULL(MSME,'') = '' THEN
                    error := -20017;
                    error_message := N'Please Enter MSME details for vendor';
                END IF;
            END IF;
        END IF;
    END IF;

END IF;

IF :object_type = '2' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
    IF EXISTS
    (SELECT 1 FROM OCRD WHERE "CardCode" like 'VEXP%' and "CardCode" = :list_of_cols_val_tab_del AND (IFNULL("WTLiable",'')='N' or "WTLiable"='N')) THEN
        error := 1001;
        error_message := 'WT Liable flag is mandatory. Please select Yes or No before saving the Business Partner.';
    END IF;
END IF;

IF :object_type = '2' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
    /* Supplier only */
    IF EXISTS
    (SELECT 1 FROM OCRD T0 WHERE T0."CardCode" like 'VEXP%' and T0."CardCode" = :list_of_cols_val_tab_del AND (IFNULL(T0."WTLiable",'')='N' or T0."WTLiable"='N')) THEN
        error := 1001;
        error_message := 'Subject to Withholding Tax is mandatory for Supplier, please select in Account Tab.';
    END IF;

    /* WT Code must be assigned */
    IF EXISTS
    (SELECT 1 FROM OCRD T0 WHERE T0."CardCode" = :list_of_cols_val_tab_del AND T0."CardType" = 'S' AND T0."WTLiable" = 'Y' AND NOT EXISTS
          (SELECT 1 FROM CRD4 T1 WHERE T1."CardCode" = T0."CardCode")) THEN
        error := 1002;
        error_message := 'At least one Withholding Tax Code must be assigned for Supplier.';
    END IF;

END IF;
------------------------------------------------------------------------------------------------
-- Select the return values-
select :error, :error_message FROM dummy;
End