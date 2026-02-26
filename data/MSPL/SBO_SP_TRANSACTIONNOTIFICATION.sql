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

-- CONSOLIDATED ITEM MASTER VALIDATION
-- Object_type = '4' (Item Master)
------------------------------ ITEM MASTER --------------------------------------------
IF Object_type = '4' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
    DECLARE ValidFor1 nvarchar(50);
    DECLARE UsrCod nvarchar(50);
    DECLARE ItemCode nvarchar(50);
    DECLARE ItemGrpCode nvarchar(50);
    DECLARE BrandName nvarchar(500);
    DECLARE ChemicalName nvarchar(500);
    DECLARE ISFA nvarchar(2);
    DECLARE MILLP_ItemCode NVARCHAR(50);

    IF :transaction_type = 'A' THEN
        SELECT T0."ItemCode",T0."validFor",T0."ItmsGrpCod",T0."U_B_URl",T0."U_C_URL",T0."U_IsFA",T1."USER_CODE","U_MILLP_ItemCode"
        INTO ItemCode, ValidFor1, ItemGrpCode, BrandName, ChemicalName, ISFA, UsrCod, MILLP_ItemCode
        FROM OITM T0
        INNER JOIN OUSR T1 ON T1."USERID" = T0."UserSign"
        WHERE T0."ItemCode" = :list_of_cols_val_tab_del;
    ELSE
        SELECT T0."ItemCode",T0."validFor",T0."ItmsGrpCod",T0."U_B_URl",T0."U_C_URL",T0."U_IsFA",T1."USER_CODE","U_MILLP_ItemCode"
        INTO ItemCode, ValidFor1, ItemGrpCode, BrandName, ChemicalName, ISFA, UsrCod, MILLP_ItemCode
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

    IF UsrCod NOT IN ('prof01', 'dipurchase', 'purchase01','purchase02', 'manager', 'sap01', 'engg01', 'engg02', 'engg04', 'engg05', 'engg06', 'engg07') THEN
    	error := -10008;
        error_message := N'You are not allowed to add/update Item Master';
    END IF;

    If ItemGrpCode IN ('114','115','116','117') AND IFNULL(MILLP_ItemCode,'') = '' then
		error :=-10009;
	    error_message := N'Please enter MILLP (Matangi) Item Code.';
	END IF;
END IF;

----------------------Item Master Validation close----------------------------
--------------------------------------------------------------------
-- CONSOLIDATED BUSINESS PARTNER VALIDATION
-- Object_type = '2' (Business Partner)

------------------------------ BUSINESS PARTNER --------------------------------------------
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
    DECLARE MSME nvarchar(15);
    DECLARE PaymentTermsCount int;
    DECLARE BDPerson nvarchar(100);
    DECLARE BDPCount int;
    DECLARE SLPCount int;
    DECLARE LeadSourceI int;
    DECLARE LeadSourceO int;
    DECLARE BDP1Count int;
    DECLARE MobiAlert nvarchar(10);
    DECLARE LabelType NVARCHAR(100);
    DECLARE DebAcct nvarchar(50);
	DECLARE GroupTypee nvarchar(10);

    SELECT
        OCRD."CardType", OCRD."U_Organisation_Id", OCRD."IndustryC", OCRD."validFor",
        OCRD."SlpCode", OCRD."U_Lead_Source", OCRD."Territory", OCRD."U_MSME_Type",
        OCRD."U_Udyam_certi", OCRD."U_BDPerson", OCRD."U_Mobi_Alert", NNM1."SeriesName",
        OUSR."USER_CODE",OCRD."U_LabelType", cast(OCRD."DebPayAcct" as nvarchar), cast(OCRD."GroupCode" as nvarchar)
    INTO
        CardType, Organisation, Industry, ValidFor,
        SlpCode, LeadSource, Territory, MSMEtype,
        MSME, BDPerson, MobiAlert, Series,
        UsrCod, LabelType, DebAcct, GroupTypee
    FROM OCRD
    INNER JOIN NNM1 ON NNM1."Series" = OCRD."Series"
    INNER JOIN OUSR ON OUSR."USERID" = ( CASE WHEN :transaction_type = 'A' THEN OCRD."UserSign" ELSE OCRD."UserSign2" END )
    WHERE OCRD."CardCode" = :list_of_cols_val_tab_del;

-- 1) VENDOR GST VALIDATION (Active 'V%' excluding 'V__I%')
	IF CardType = 'S' AND :list_of_cols_val_tab_del LIKE 'V%' AND :list_of_cols_val_tab_del NOT LIKE 'V__I%' THEN
	    IF EXISTS (
	        SELECT 1 FROM CRD1 T0
	        INNER JOIN CRD1 T1 ON T0."GSTRegnNo" = T1."GSTRegnNo"
	        INNER JOIN OCRD T2 ON T1."CardCode" = T2."CardCode" -- Join to check Active status
	        WHERE T0."CardCode" = :list_of_cols_val_tab_del
	        AND T1."CardCode" <> T0."CardCode"
	        AND T0."AdresType" = 'B' AND T1."AdresType" = 'B'
	        AND IFNULL(T0."GSTRegnNo",'') <> ''
	        AND T2."validFor" = 'Y' -- Only check against Active Vendors
	        AND T2."CardCode" LIKE 'V%' AND T2."CardCode" NOT LIKE 'V__I%'
	        AND (
	            (T0."CardCode" LIKE 'VS%' AND T1."CardCode" LIKE 'VS%') OR
	            (T0."CardCode" LIKE 'VP%' AND T1."CardCode" LIKE 'VP%') OR
	            (T0."CardCode" LIKE 'VO%' AND T1."CardCode" LIKE 'VO%')
	        )
	    ) THEN
	        error := -20021;
	        error_message := N'Duplicate GST Number found in an Active Pay-to address of another Vendor.';
	    END IF;
	END IF;

-- 2) EMPLOYEE FOREIGN NAME VALIDATION (Active 'EMP%' only)
	IF :list_of_cols_val_tab_del LIKE 'EMP%' THEN
	    IF EXISTS (
	        SELECT 1 FROM OCRD T0
	        INNER JOIN OCRD T1 ON T0."CardFName" = T1."CardFName"
	        WHERE T0."CardCode" = :list_of_cols_val_tab_del
	        AND T1."CardCode" <> T0."CardCode"
	        AND IFNULL(T0."CardFName",'') <> ''
	        AND T1."validFor" = 'Y' -- Only check against Active Employees
	        AND T1."CardCode" LIKE 'EMP%'
	    ) THEN
	        error := -20022;
	        error_message := N'Duplicate Foreign Name found. This name is already assigned to another Active Employee.';
	    END IF;
	END IF;

-- 3) CUSTOMER DIVISION-WISE GST VALIDATION (Active CPD/CID/COD & Bill-to)
	IF CardType = 'C' THEN
	    IF EXISTS (
	        SELECT 1 FROM CRD1 T0
	        INNER JOIN CRD1 T1 ON T0."GSTRegnNo" = T1."GSTRegnNo"
	        INNER JOIN OCRD T2 ON T1."CardCode" = T2."CardCode" -- Join to check Active status
	        WHERE T0."CardCode" = :list_of_cols_val_tab_del
	        AND T1."CardCode" <> T0."CardCode"
	        AND T0."AdresType" = 'B' AND T1."AdresType" = 'B'
	        AND IFNULL(T0."GSTRegnNo",'') <> ''
	        AND T2."validFor" = 'Y' -- Only check against Active Customers
	        AND (
	            (T0."CardCode" LIKE 'CPD%' AND T1."CardCode" LIKE 'CPD%') OR
	            (T0."CardCode" LIKE 'CSD%' AND T1."CardCode" LIKE 'CSD%') OR
	            (T0."CardCode" LIKE 'COD%' AND T1."CardCode" LIKE 'COD%')
	        )
	    ) THEN
	        error := -20023;
	        error_message := N'Duplicate GST Number found within the same Active Customer Division (CPD/CSD/COD).';
	    END IF;
	END IF;

    IF (GroupTypee = '105' AND DebAcct not in ('20203121')) OR (GroupTypee = '101' AND DebAcct not in ('20203101')) OR (GroupTypee = '106' AND DebAcct not in ('20203120'))
       OR (GroupTypee = '102' AND DebAcct not in ('10502000')) OR (GroupTypee = '100' AND DebAcct not in ('10501000')) OR (GroupTypee = '110' AND DebAcct not in ('20203536'))
       OR (GroupTypee = '109' AND DebAcct not in ('20203102')) OR (GroupTypee = '113' AND DebAcct not in ('10700001')) THEN

       error := -20018;
       error_message := N'Please select proper Accounts Payable in Business Partner.';

    END IF;

    /*IF (((Series like 'COD%' or Series like 'CPD%' or Series like 'CSD%') AND GroupTypee <> '100')
    	or ((Series like 'VSRD%' or Series like 'VPRD%' or Series like 'VORD%') AND GroupTypee <> '101')
    	or ((Series like 'COE%' or Series like 'CPE%' or Series like 'CSE%') AND GroupTypee <> '102')
    	or ((Series like 'VSRI%' or Series like 'VPRI%' or Series like 'VORI%') AND GroupTypee <> '105')
    	or ((Series like 'VFAS%' or Series like 'VLAB%' or Series like 'VEXP%' or Series like 'VGPR%') AND GroupTypee <> '106')
    	or ((Series like 'VPPD%') AND GroupTypee <> '109')
    	or ((Series like 'EMP%') AND GroupTypee <> '110')
    	or ((Series like 'STLO%') AND GroupTypee <> '113')) THEN

       error := -20019;
       error_message := N'Series and Group not matching in Business Partner.';

    END IF;*/

    IF ValidFor = 'Y' THEN
        IF :transaction_type = 'A' THEN
            error := -20001;
            error_message := N'Please ADD Business partner in INACTIVE Mode';
        ELSE
            IF UsrCod NOT IN ('manager', 'prof01', 'sap01') THEN
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

            IF SlpCode = -1 AND GroupTypee <> 113 THEN
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

        IF IFNULL(BDPerson,'') = '' AND GroupTypee <> 113 THEN
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

        SELECT COUNT(T0."U_BDPerson") INTO LeadSourceI
        FROM OCRD T0
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

        IF IFNULL(LabelType,'')='' AND GroupTypee <> 113 THEN
        	error := -20016;
        	error_message := N'Please select Label Type.';
        END IF;
    END IF;

    IF CardType = 'S' THEN
        IF UsrCod IN ('purchase', 'dipurchase') THEN
            IF Series NOT LIKE 'V%' THEN
                error := -20017;
                error_message := N'Please select proper Type and Proper Series ' || Series;
            END IF;
        END IF;

        IF :transaction_type = 'A' AND Series LIKE 'V%' THEN
            IF UPPER(IFNULL(MSMEtype,'')) <> 'NA' THEN
                IF IFNULL(MSME,'') = '' THEN
                    error := -20018;
                    error_message := N'Please Enter MSME details for vendor';
                END IF;
            END IF;
                		/* Supplier only */
		    /*IF EXISTS (SELECT 1 FROM OCRD T0 WHERE Left(T0."CardCode",4) in ('VSRD','VPRD','VPPD','VEXP','VFAS','VGPR','VLAB','VORD') and T0."CardCode" = :list_of_cols_val_tab_del AND (IFNULL(T0."WTLiable",'')='N' or T0."WTLiable"='N')) THEN
        	error := -20019;
	        error_message := 'Subject to Withholding Tax is mandatory for Supplier, please select in Account Tab.';
    		END IF;*/

		    /* WT Code must be assigned */
		    /*IF EXISTS (SELECT 1 FROM OCRD T0 WHERE T0."CardCode" = :list_of_cols_val_tab_del AND T0."CardType" = 'S' AND T0."WTLiable" = 'Y' AND
    							NOT EXISTS (SELECT 1 FROM CRD4 T1 WHERE T1."CardCode" = T0."CardCode")) THEN
        	error := -20020;
	        error_message := 'At least one Withholding Tax Code must be assigned for Supplier.';
    		END IF;*/
        END IF;
    END IF;
END IF;

------------------------ END BUSINESS PARTNER MASTER VALIDATIONS -------------------------------

--------------------------------- SALES ORDER START ----------------------------------

IF Object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

    -- =====================================
    -- VARIABLE DECLARATIONS
    -- =====================================
    DECLARE DraftObj INT;
    DECLARE MinSO INT;
    DECLARE MaxSO INT;
    DECLARE Series NVARCHAR(50);
    DECLARE CardCodeSO NVARCHAR(50);
    DECLARE SOCurrency NVARCHAR(50);
    DECLARE CustRef NVARCHAR(200);
    DECLARE SESO INT;
    DECLARE BPSLP INT;
    DECLARE RMRKPRD NVARCHAR(500);
    DECLARE RMRKSTR NVARCHAR(500);
    DECLARE RMRKQC NVARCHAR(500);
    DECLARE PSS NVARCHAR(5);
    DECLARE SOCmnt NVARCHAR(500);
    DECLARE SOrate DECIMAL(18,2);
    DECLARE SOdate DATE;
    DECLARE DLDate DATE;
    DECLARE OcrCode INT;
    DECLARE SOExrate DECIMAL(18,2);
    DECLARE CNPJ NVARCHAR(50);
    DECLARE CEP NVARCHAR(50);
    DECLARE CUIT NVARCHAR(50);
    DECLARE TaxID NVARCHAR(50);
    DECLARE City NVARCHAR(50);
    DECLARE ExpRmk NVARCHAR(5000);
    DECLARE ExpRmkO NVARCHAR(5000);
    DECLARE BPName NVARCHAR(100);
    DECLARE BPSlpName VARCHAR(100);
    DECLARE SOSlpName VARCHAR(100);
    DECLARE PLoad NVARCHAR(50);
    DECLARE PDischrg NVARCHAR(50);
    DECLARE PrtCnt INT;
    DECLARE POPayment NVARCHAR(200);
    DECLARE BPPayment NVARCHAR(200);
    DECLARE CCodeType NVARCHAR(5);
    DECLARE ItemCodeType NVARCHAR(5);

    -- Line Level Variables
    DECLARE SOEntryType NVARCHAR(50);
    DECLARE SOItemCode NVARCHAR(50);
    DECLARE TaxCode NVARCHAR(50);
    DECLARE SOItemGrpCode NVARCHAR(50);
    DECLARE LicenseTypeSO NVARCHAR(50);
    DECLARE Qty INT;
    DECLARE LicenseNoSO NVARCHAR(50);
    DECLARE Freetext NVARCHAR(50);
    DECLARE SOName NVARCHAR(100);
    DECLARE SOPckCode NVARCHAR(50);
    DECLARE SOPackType NVARCHAR(50);
    DECLARE SOOtherPackng NVARCHAR(100);
    DECLARE HASCOM NVARCHAR(50);
    DECLARE Commission INT;
    DECLARE CommissionPer INT;
    DECLARE ItmHSN NVARCHAR(50);
    DECLARE InvHSN NVARCHAR(50);
    DECLARE BatchCount NVARCHAR(50);
    DECLARE SOItemCategory NVARCHAR(50);
    DECLARE SOItemSubCategory NVARCHAR(50);
    DECLARE LeadTime DOUBLE;
    DECLARE ExpeLT DOUBLE;
    DECLARE ExpectedDelDate DATE;
    DECLARE U_Agro_Chem NVARCHAR(50);
    DECLARE U_Per_HM_CR NVARCHAR(50);
    DECLARE U_Food NVARCHAR(50);
    DECLARE U_Paints_Pigm NVARCHAR(50);
    DECLARE U_Indus_Care NVARCHAR(50);
    DECLARE U_Lube_Additiv NVARCHAR(50);
    DECLARE U_Oil_Gas NVARCHAR(50);
    DECLARE U_Textile NVARCHAR(50);
    DECLARE U_CAS_No NVARCHAR(50);
    DECLARE U_Other1 NVARCHAR(50);
    DECLARE U_Other2 NVARCHAR(50);
    DECLARE U_Pharma NVARCHAR(50);
    DECLARE U_Mining NVARCHAR(50);
    DECLARE typpltibc int;
    DECLARE Capacity INT;
    DECLARE Pack1C INT;
    DECLARE Pack2C INT;
    DECLARE U_Pack3C INT;
    DECLARE U_Pack4C INT;
    DECLARE U_Pack5C INT;
    DECLARE U_Pack6C INT;
    DECLARE U_Pack7C INT;
    DECLARE U_Pack8C INT;
    DECLARE U_Pack9C INT;
    DECLARE U_Pack10C INT;
    DECLARE U_Pack11C INT;
    DECLARE U_Pack12C INT;
    DECLARE U_Pack13C INT;
    DECLARE U_Pack14C INT;
    DECLARE U_Pack15C INT;
    DECLARE Series1 NVARCHAR(50);
    --DECLARE SOPackType NVARCHAR(500);
    DECLARE SOPackng NVARCHAR(100);
    DECLARE Pack1 NVARCHAR(50);
    DECLARE Pack2 NVARCHAR(50);
    DECLARE U_Pack3 NVARCHAR(50);
    DECLARE U_Pack4 NVARCHAR(50);
    DECLARE U_Pack5 NVARCHAR(50);
    DECLARE U_Pack6 NVARCHAR(50);
    DECLARE U_Pack7 NVARCHAR(50);
    DECLARE U_Pack8 NVARCHAR(50);
    DECLARE U_Pack9 NVARCHAR(50);
    DECLARE U_Pack10 NVARCHAR(50);
    DECLARE U_Pack11 NVARCHAR(50);
    DECLARE U_Pack12 NVARCHAR(50);
    DECLARE U_Pack13 NVARCHAR(50);
    DECLARE U_Pack14 NVARCHAR(50);
    DECLARE U_Pack15 NVARCHAR(50);
    DECLARE COA_Appr NVARCHAR(5);

    -- =======================================================
    -- SECTION 1: EFFICIENTLY SELECT ALL HEADER DATA UPFRONT
    -- =======================================================

    SELECT T0."ObjType" INTO DraftObj FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

    -- Only proceed if this is a Sales Order Draft (ObjType = 17)
    IF DraftObj = 17 THEN

        -- Select all header data in one go
        SELECT
            T1."SeriesName", T0."CardCode", T0."DocCur", T0."NumAtCard", T0."SlpCode", T0."U_RMRKPRD", T0."U_RMRKSTR",
            T0."U_RMRKQC", T0."Comments", T0."DocRate", T0."DocDate", T0."DocDueDate", T0."U_CNPJ_Num", T0."U_CEP_Num",
            T0."U_CUIT_Num", T0."U_Tax_ID", T0."U_FinlDest", T0."U_Export_Remark", T0."U_ExportRemarks", T0."CardName",
            T0."U_PLoad", T0."U_PDischrg",
            T2."PymntGroup",
            T3."SlpCode", T2."PymntGroup"
        INTO
            Series, CardCodeSO, SOCurrency, CustRef, SESO, RMRKPRD, RMRKSTR,
            RMRKQC, SOCmnt, SOrate, SOdate, DLDate, CNPJ, CEP,
            CUIT, TaxID, City, ExpRmk, ExpRmkO, BPName,
            PLoad, PDischrg,
            POPayment,
            BPSLP, BPPayment
        FROM ODRF T0
        INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
        INNER JOIN OCTG T2 ON T0."GroupNum" = T2."GroupNum"
        INNER JOIN OCRD T3 ON T0."CardCode" = T3."CardCode"
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."ObjType" = 17;

        -- Get Min and Max line numbers for the loop
        SELECT MIN(T0."VisOrder"), MAX(T0."VisOrder") INTO MinSO, MaxSO FROM DRF1 T0 JOIN ODRF ON ODRF."DocEntry" = T0."DocEntry" WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND ODRF."ObjType" = 17;

        -- =====================================
        -- SECTION 2: HEADER LEVEL VALIDATIONS
        -- =====================================

        -- Validation 31001: Distribution Rule Check
        SELECT COUNT(T1."OcrCode") INTO OcrCode FROM DRF1 T1 JOIN ODRF ON ODRF."DocEntry" = T1."DocEntry" WHERE T1."DocEntry" = :list_of_cols_val_tab_del AND T1."OcrCode" IS NOT NULL AND ODRF."ObjType" = 17;
        IF (OcrCode = 0) THEN
            error := 31001;
            error_message := N'Please Select Distr. Rule in Document [DRAFT]';
        END IF;

        -- Validation 31002: Sales Person Check
        IF SESO = -1 THEN
            error := 31002;
            error_message := N'Please Enter Sales Person Name. [DRAFT]';
        END IF;

        -- Validation 31003-31005: Remarks Checks (For Export Series)
        IF Series LIKE 'EX%' THEN
            IF (RMRKPRD IS NULL OR RMRKPRD = '') THEN
            	error := 31003;
            	error_message := N'Please Enter Production Remark. [DRAFT]';
            END IF;
            IF (RMRKSTR IS NULL OR RMRKSTR = '') THEN
            	error := 31004;
            	error_message := N'Please Enter Store Remark. [DRAFT]';
            END IF;
            IF (RMRKQC IS NULL OR RMRKQC = '') THEN
            	error := 31005;
            	error_message := N'Please Enter QC Remark. [DRAFT]';
            END IF;
        END IF;

        -- Validation 31006: Delivery Date Check
        IF (DLDate < SOdate) THEN
            error := 31006;
            error_message := N'Delivery date cannot be earlier than Posting date. [DRAFT]';
        END IF;

        -- Validation 31007: ETD Check (For Domestic Series)
        IF Series LIKE 'DM%' AND (DLDate < CURRENT_DATE) THEN
            error := 31007;
            error_message := N'ETD cannot be earlier than the current date. [DRAFT]';
        END IF;

        -- Validation 31008: Export Document Fields Check
        IF CardCodeSO LIKE 'C_E%' THEN
            IF CNPJ IS NULL THEN
            	error := 31008;
            	error_message := N'Please Enter CNPJ No. [DRAFT]';
            END IF;
            IF CEP IS NULL THEN
            	error := 31009;
            	error_message := N'Please Enter CEP No. [DRAFT]';
            END IF;
            IF CUIT IS NULL THEN
            	error := 31010;
            	error_message := N'Please Enter CUIT No. [DRAFT]';
            END IF;
            IF TaxID IS NULL THEN
            	error := 31011;
            	error_message := N'Please Enter Tax ID. [DRAFT]';
            END IF;
        END IF;

        -- Validation 31009: Final Destination Check
        IF CardCodeSO LIKE 'C_E%' AND City IS NULL THEN
            error := 31012;
            error_message := N'Please select City in Logistics. [DRAFT]';
        END IF;

        -- Validation 31010: Export Remarks Check
        IF Series LIKE 'EX%' THEN
            IF (ExpRmkO = 'No' OR ExpRmkO IS NULL) AND (ExpRmk IS NOT NULL AND ExpRmk <> '') THEN
                error := 31013;
                error_message := N'Cannot enter Export Remarks when option is No/blank. [DRAFT]';
            END IF;
            IF ExpRmkO = 'Yes' AND (ExpRmk IS NULL OR ExpRmk = '') THEN
                error := 31014;
                error_message := N'Export Remarks field is mandatory when option is Yes. [DRAFT]';
            END IF;
        END IF;

        -- Validation 31011: Sales Employee Check
        IF BPSLP <> SESO THEN
            SELECT T0."SlpName" INTO BPSlpName FROM OSLP T0 WHERE T0."SlpCode" = BPSLP;
            SELECT T0."SlpName" INTO SOSlpName FROM OSLP T0 WHERE T0."SlpCode" = SESO;
            error := 31015;
            error_message := N'Sales Employee ('||BPSlpName||') is assigned to ('||BPName||'), you cannot change it to ('||SOSlpName||'). [DRAFT]';
        END IF;

        -- Validation 31012: Port of Loading/Discharge Check
        IF (Series LIKE 'EX%') THEN
            SELECT COUNT(*) INTO PrtCnt FROM "@PORTMASTER" WHERE "U_PortName" = :PLoad;
            IF (PrtCnt = 0) THEN
            	error := 31016;
            	error_message := N'Invalid [Port of Loading]. Select from list. [DRAFT]';
            END IF;
            SELECT COUNT(*) INTO PrtCnt FROM "@PORTMASTER" WHERE "U_PortName" = :PDischrg;
            IF (PrtCnt = 0) THEN
            	error := 31017;
            	error_message := N'Invalid [Port of Discharge]. Select from list. [DRAFT]';
            END IF;
        END IF;

        -- Validation 31013: Payment Terms Check
        IF POPayment <> BPPayment THEN
            error := 31018;
            error_message := N'Document payment terms do not match Business Partner master. [DRAFT]';
        END IF;

        -- 'ADD' Transaction Specific Header Validations
        IF (:transaction_type = 'A') THEN
            -- Validation 31014: Currency and Series Check
            IF (CardCodeSO LIKE 'CPE%' AND SOCurrency = 'INR') OR (CardCodeSO LIKE 'CSE%' AND SOCurrency = 'INR') THEN
                error := 31019;
                error_message := N'Please Select Proper Currency. [DRAFT]';
            END IF;
            IF (CardCodeSO LIKE 'CSE%' AND Series NOT LIKE 'EX%') OR (CardCodeSO LIKE 'CPE%' AND Series NOT LIKE 'EX%') THEN
                error := 31020;
                error_message := N'Please Select Proper Series. [DRAFT]';
            END IF;

            -- Validation 31015: Customer Reference Number Check
            IF CustRef IS NULL OR LENGTH(CustRef) = 0 THEN
                error := 31021;
                error_message := N'Enter Customer Ref No. [DRAFT]';
            END IF;
            IF CustRef LIKE '%ail%' THEN
                error := 31022;
                error_message := N'Invalid Customer Ref No. [DRAFT]';
            END IF;

            -- Validation 31016: Exchange Rate Check
            IF CardCodeSO LIKE 'C_E%' THEN
                SELECT COUNT(T0."Rate") INTO PrtCnt FROM ORTT T0 WHERE T0."Currency" = :SOCurrency AND T0."RateDate" = :SOdate;
                IF PrtCnt > 0 THEN
                    SELECT T0."Rate" INTO SOExrate FROM ORTT T0 WHERE T0."Currency" = :SOCurrency AND T0."RateDate" = :SOdate;
                    IF SOExrate <> SOrate THEN
                        error := 31023;
                        error_message := N'Not allowed to change exchange rate. [DRAFT]';
                    END IF;
                END IF;
            END IF;
        END IF;

        -- =====================================================
		-- Validation 30021: Consignee Manual Entry Not Allowed
		-- =====================================================

		IF Series LIKE 'EX%' THEN
		        IF EXISTS		(SELECT 1 FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType" = '17'
		        AND
		        NOT EXISTS			(SELECT 1 FROM "@CONSIGNEED" T1 WHERE T1."Code" = T0."CardCode" AND T1."U_Consignee" = T0."U_Consignee_Name"
				        			AND TO_NVARCHAR(T1."U_ConsigneeAdd") = TO_NVARCHAR(T0."U_Consignee_Add")
		        				    )
		        				) THEN
		        error := 30032;
		        error_message := 'Manual entry not allowed.. Please select Consignee from the master list. [DRAFT]';
		    	END IF;
		END IF;

        -- ===================================================
        -- SECTION 3: LINE LEVEL VALIDATIONS - COMBINED LOOP
        -- ===================================================
        SELECT CASE WHEN CardCodeSO LIKE 'CP%' THEN 'PC' WHEN CardCodeSO LIKE 'CS%' THEN 'SC' WHEN CardCodeSO LIKE 'CO%' THEN 'OF' END INTO CCodeType FROM dummy;

        WHILE MinSO <= MaxSO DO
            -- Get all line-level data in a single, efficient query
            SELECT
                T1."U_EntryType", T1."ItemCode", T1."U_LicenseType", T1."Quantity", T1."U_LicenseNum", T1."FreeTxt", T1."TaxCode",
                T1."Dscription", T1."U_Pcode", T1."U_PTYPE", T1."Factor1", T1."U_Opack", T1."U_UNE_APPR", T1."U_Commission_Q",
                T1."U_Q_CommissionPer", T1."U_NoOfBatchRequired",
                T2."ItmsGrpCod", IFNULL(T2."U_PCAT", ''), IFNULL(T2."U_PSCAT", ''), count(T1."U_TOPLT"),
                T2."U_Agro_Chem", T2."U_Per_HM_CR", T2."U_Food", T2."U_Paints_Pigm", T2."U_Indus_Care", T2."U_Lube_Additiv", T2."U_Textile", T2."U_Oil_Gas", T2."U_CAS_No",
                T2."U_Other1", T2."U_Other2", T2."U_Pharma", T2."U_Mining", T1."Dscription",T1."FreeTxt",T1."U_PSS", T1."U_ApprOnCOA"
            INTO
                SOEntryType, SOItemCode, LicenseTypeSO, Qty, LicenseNoSO, Freetext, TaxCode,
                SOName, SOPckCode, SOPackType, Capacity, SOOtherPackng, HASCOM, Commission,
                CommissionPer, BatchCount,
                SOItemGrpCode, SOItemCategory, SOItemSubCategory, typpltibc,
                U_Agro_Chem, U_Per_HM_CR, U_Food, U_Paints_Pigm, U_Indus_Care, U_Lube_Additiv, U_Textile, U_Oil_Gas, U_CAS_No, U_Other1, U_Other2, U_Pharma, U_Mining, SOName, Freetext, PSS, COA_Appr
            FROM DRF1 T1 JOIN ODRF ON ODRF."DocEntry" = T1."DocEntry"
            INNER JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
            WHERE T1."DocEntry" = :list_of_cols_val_tab_del AND T1."VisOrder" = MinSO AND ODRF."ObjType" = 17
            GROUP BY
                T1."U_EntryType", T1."ItemCode", T1."U_LicenseType", T1."Quantity", T1."U_LicenseNum", T1."FreeTxt", T1."TaxCode",
                T1."Dscription", T1."U_Pcode", T1."U_PTYPE", T1."Factor1", T1."U_Opack", T1."U_UNE_APPR", T1."U_Commission_Q",
                T1."U_Q_CommissionPer", T1."U_NoOfBatchRequired",
                T2."ItmsGrpCod", IFNULL(T2."U_PCAT", ''), IFNULL(T2."U_PSCAT", ''),
                T2."U_Agro_Chem", T2."U_Per_HM_CR", T2."U_Food", T2."U_Paints_Pigm", T2."U_Indus_Care", T2."U_Lube_Additiv", T2."U_Textile", T2."U_Oil_Gas", T2."U_CAS_No",
                T2."U_Other1", T2."U_Other2", T2."U_Pharma", T2."U_Mining", T1."Dscription",T1."FreeTxt",T1."U_PSS", T1."U_ApprOnCOA";

            -- Validation 31017: Entry Type Check
            IF (:transaction_type = 'A') AND (SOEntryType = 'Blank' AND (SOItemCode LIKE 'PCRM%' OR SOItemCode LIKE 'PCFG%')) THEN
                error := 31024;
                error_message := N'Please select Entry Type at row level. [DRAFT]';
            END IF;

            -- Validation 31018: License Type and Quantity Check
            IF (LicenseTypeSO IS NULL OR LicenseTypeSO = '') AND SOCmnt NOT LIKE '%sample%' THEN
                error := 31025;
                error_message := N'Please enter License Type. [DRAFT]';
            END IF;
            IF LicenseTypeSO <> '' AND LicenseTypeSO NOT IN ('ADVANCE','DBK','MEIS', 'No Required') AND SOCmnt NOT LIKE '%sample%' THEN
                error := 31026;
                error_message := N'Invalid License Type selected. [DRAFT]';
            END IF;
        	IF LicenseTypeSO <> 'No Required' and LicenseNoSO IS NULL THEN
        		error := 31026;
        		error_message := N'Please Enter License Number in Sales Contract. [DRAFT]';
        	END IF;
            IF (SOItemCode LIKE 'PC%' OR SOItemCode LIKE 'SC%') AND Qty > 150000 THEN
                error := 31027;
                error_message := N'Quantity cannot exceed 150 MT for this item. [DRAFT]';
            END IF;
            IF (SOItemCode LIKE 'OF%') AND Qty > 1000000 THEN
                error := 31028;
                error_message := N'Quantity cannot exceed 1000 MT for this item. [DRAFT]';
            END IF;

            -- Validation 31019: License Number Check
            IF (LicenseNoSO IS NULL OR LicenseNoSO = '') AND LicenseTypeSO LIKE 'A%' AND CardCodeSO LIKE 'C_E%' THEN
                error := 31029;
                error_message := N'Please enter License No. [DRAFT]';
            END IF;

        	IF IFNULL(UPPER(PSS),'') NOT IN ('YES','NO') AND CardCodeSO LIKE 'C%' AND SOItemCode LIKE '%FG%' THEN
            	error := 32027;
            	error_message := N'Please select PSS Yes/No at Line '||MinSO+1;
        	END IF;

            -- Validation 31020: Alias Name Check
			IF Series NOT LIKE 'CL%' then
					IF (SOItemCode NOT LIKE 'SC%' AND SOItemCode NOT LIKE 'PCPM%' AND SOItemCode NOT LIKE 'FA%' AND SOItemCode NOT LIKE 'WS%') THEN
						IF SOName = Freetext then
						else
							IF Freetext = U_Agro_Chem then
							else
								IF Freetext = U_Per_HM_CR then
								else
									IF Freetext = U_Food then
									else
										IF Freetext = U_Paints_Pigm then
										else
											IF Freetext = U_Indus_Care then
											else
												IF Freetext = U_Textile then
												else
													IF Freetext = U_Lube_Additiv then
													else
														IF Freetext = U_Oil_Gas then
														else
															IF Freetext = U_CAS_No then
															else
																IF Freetext = U_Other1 then
																else
																	IF Freetext = U_Other2 then
																	else
																		IF Freetext = U_Pharma then
																		else
																			IF Freetext = U_Mining then
																			else
																				error:=30086;
																				error_message:=N'Please Select Proper Alias Name in Sales order (Alias Name not in master)';
																			END IF;
																		END IF;
																	END IF;
																END IF;
															END IF;
														END IF;
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
					END IF;

            -- Validation 31021: SAP Packing Code Check
            /*IF SOItemCode NOT LIKE '%PM%' AND SOItemCode NOT LIKE '%RM%' AND SOItemCode NOT IN ('WSTG0001', 'WSTG0004') THEN
                IF SOPackType NOT LIKE '%Tanker%' AND SOPackType NOT LIKE '%ISO%' AND (SOPckCode IS NULL OR SOPckCode = '') THEN
                    error := 31031;
                    error_message := N'Please select SAP Packing Code. [DRAFT]';
                END IF;
            END IF;*/

            IF SOItemCode NOT LIKE '%PM%' and SOItemCode NOT LIKE '%RM%' and SOItemCode <> 'WSTG0001' and SOItemCode <> 'WSTG0004'then
			IF SOPackType NOT LIKE '%Tanker%' THEN
				IF SOPackType NOT LIKE '%ISO%' THEN
					IF (SOPckCode IS NULL OR SOPckCode = '') THEN
						error := 31031;
						error_message:=N'Please Select SAP Packing Code ';
					END IF;
				END IF;
			END IF;
			END IF;

            -- Validation 31022: Other Packing Check
            IF SOItemCode NOT LIKE 'SC%' AND SOItemCode NOT LIKE 'OFRM%' AND SOItemCode NOT LIKE 'WS%' AND (SOOtherPackng IS NULL OR SOOtherPackng = '') THEN
                error := 31032;
                error_message := N'Please select Other Packing for this item. [DRAFT]';
            END IF;
            IF (Series LIKE 'DM%' OR Series LIKE 'EM%') AND SOItemCode NOT IN ('SC%','OFRM%','WSTG%') AND (SOOtherPackng IS NULL OR SOOtherPackng = '') THEN
                 error := 31033;
                 error_message := N'Please select Other Packing for this item. [DRAFT]';
            END IF;

            -----------------------------------------


				 IF SOItemCode NOT LIKE 'DIBP%' AND SOItemCode NOT LIKE 'PCPM%' AND SOItemCode NOT LIKE 'WSTG%' AND SOItemCode NOT LIKE 'EECA%' AND UPPER(SOPackType) NOT LIKE '%TANK%' THEN
                 SELECT T0."U_Pack1C", T0."U_Pack2C", T0."U_Pack3C", T0."U_Pack4C", T0."U_Pack5C", T0."U_Pack6C", T0."U_Pack7C", T0."U_Pack8C", T0."U_Pack9C", T0."U_Pack10C", T0."U_Pack11C", T0."U_Pack12C", T0."U_Pack13C", T0."U_Pack14C", T0."U_Pack15C"
                 INTO Pack1C, Pack2C, U_Pack3C, U_Pack4C, U_Pack5C, U_Pack6C, U_Pack7C, U_Pack8C, U_Pack9C, U_Pack10C, U_Pack11C, U_Pack12C, U_Pack13C, U_Pack14C, U_Pack15C
                 FROM "@SOPACKING" T0 WHERE T0."Code" = SOItemCode;

                 SELECT T0."U_Pack1", T0."U_Pack2", T0."U_Pack3", T0."U_Pack4", T0."U_Pack5", T0."U_Pack6", T0."U_Pack7", T0."U_Pack8", T0."U_Pack9", T0."U_Pack10", T0."U_Pack11", T0."U_Pack12", T0."U_Pack13", T0."U_Pack14", T0."U_Pack15"
                 INTO Pack1, Pack2, U_Pack3, U_Pack4, U_Pack5, U_Pack6, U_Pack7, U_Pack8, U_Pack9, U_Pack10, U_Pack11, U_Pack12, U_Pack13, U_Pack14, U_Pack15
                 FROM "@SOPACKING" T0 WHERE T0."Code" = SOItemCode;

                IF SOCmnt NOT LIKE '%sample%' AND SOPackType NOT LIKE 'ISO%' THEN
		        IF Capacity = Pack1C then
					else
						IF Capacity = U_Pack15C then
						else
							IF Capacity = Pack2C then
							else
								IF Capacity = U_Pack3C then
								else
									IF Capacity = U_Pack4C then
									else
										IF Capacity = U_Pack5C then
										else
											IF Capacity = U_Pack6C then
											else
												IF Capacity = U_Pack7C then
												else
													IF Capacity = U_Pack8C then
													else
														IF Capacity = U_Pack9C then
														else
															IF Capacity = U_Pack10C then
															else
																IF Capacity = U_Pack11C then
																else
																	IF Capacity = U_Pack12C then
																	else
																		IF Capacity = U_Pack13C then
																		else
																			IF Capacity = U_Pack14C then
																			else
																				error:=30066;
																				error_message:=N'Please Select proper capacity from list';
																			END IF;
																		END IF;
																	END IF;
																END IF;
															END IF;
														END IF;
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;


		            IF SOPckCode = Pack1 then
					else
						IF SOPckCode = U_Pack15 then
						else
							IF SOPckCode = Pack2 then
							else
								IF SOPckCode = U_Pack3 then
								else
									IF SOPckCode = U_Pack4 then
									else
										IF SOPckCode = U_Pack5 then
										else
											IF SOPckCode = U_Pack6 then
											else
												IF SOPckCode = U_Pack7 then
												else
													IF SOPckCode = U_Pack8 then
													else
														IF SOPckCode = U_Pack9 then
														else
															IF SOPckCode = U_Pack10 then
															else
																IF SOPckCode = U_Pack11 then
																else
																	IF SOPckCode = U_Pack12 then
																	else
																		IF SOPckCode = U_Pack13 then
																		else
																			IF SOPckCode = U_Pack14 then
																			else
																				error:=30067;
																				error_message:=N'Please Select Packing code from list';
																			END IF;
																		END IF;
																	END IF;
																END IF;
															END IF;
														END IF;
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
		        END IF;

            END IF;

            -- Validation 31023: Commission Check
            IF Series LIKE 'E%' AND HASCOM = 'Y' AND (Commission = 0 OR Commission IS NULL OR CommissionPer = 0 OR CommissionPer IS NULL) THEN
                error := 31034;
                error_message := N'Please enter Commission Percentage and check Commission value. [DRAFT]';
            END IF;

            -- Validation 31024: HSN Code Check
            IF SOItemCode NOT IN ('SER0121', 'WSTG0001') THEN
                SELECT concat(concat(concat(concat("Chapter",'.'),"Heading"),'.'),"SubHeading") INTO ItmHSN FROM OCHP T0 INNER JOIN OITM T1 ON T0."AbsEntry" = T1."ChapterID" WHERE T1."ItemCode" = SOItemCode;
                SELECT concat(concat(concat(concat("Chapter",'.'),"Heading"),'.'),"SubHeading") INTO InvHSN FROM OCHP T0 INNER JOIN DRF1 T1 ON T1."HsnEntry" = T0."AbsEntry" JOIN ODRF ON ODRF."DocEntry" = T1."DocEntry" WHERE T1."DocEntry" = :list_of_cols_val_tab_del AND T1."VisOrder" = MinSO AND ODRF."ObjType" = 17;
                IF ItmHSN <> InvHSN THEN
                    error := 31035;
                    error_message := 'HSN Code mismatch for item ' || SOItemCode || '. [DRAFT]';
                END IF;
            END IF;

            -- Validation 31025: Customer and Item Type Matching
            SELECT CASE WHEN SOItemCode LIKE 'PC%' THEN 'PC' WHEN SOItemCode LIKE 'DI%' THEN 'SC' WHEN SOItemCode LIKE 'OF%' THEN 'OF' END INTO ItemCodeType FROM dummy;
            IF SOItemGrpCode NOT IN (104, 101) THEN
                IF (SOItemCode LIKE 'PC%' AND CardCodeSO NOT LIKE 'CP%') OR (SOItemCode LIKE 'SC%' AND CardCodeSO NOT LIKE 'CS%') OR (SOItemCode LIKE 'OF%' AND CardCodeSO NOT LIKE 'CO%') THEN
                    error := 31036;
                    error_message := 'Customer type ('||CCodeType||') and Item type ('||ItemCodeType||') mismatch at row '|| MinSO+1||'. [DRAFT]';
                END IF;
            END IF;

            -- Validation 31026: Batch Count Check
            IF (SOItemCode LIKE '%FG%' OR SOItemCode LIKE '%RM%' OR SOItemCode LIKE '%TR%') AND BatchCount IS NULL THEN
                error := 31037;
                error_message := N'Number of Batches is required for item ' || SOItemCode || ' at line ' || MinSO + 1 || '. [DRAFT]';
            END IF;

            -- Validation 31027: Lead Time Check
            IF SOItemCode LIKE 'PCFG%' THEN
                SELECT MAX(T0."U_LT_Per_10MT") INTO LeadTime FROM OITM T0 WHERE T0."ItemCode" = SOItemCode;
                IF Series LIKE 'DM%' THEN SELECT MAX(ROUND((((:Qty/10000)*LeadTime)+3),0)) INTO ExpeLT FROM DUMMY;
                END IF;
                IF Series LIKE 'EX%' THEN SELECT MAX(ROUND((((:Qty/10000)*LeadTime)+3),0)) INTO ExpeLT FROM DUMMY;
                END IF;
                SELECT ADD_DAYS(:SOdate, ExpeLT) INTO ExpectedDelDate FROM DUMMY;
                IF DLDate < ExpectedDelDate THEN
                    error := 31038;
                    error_message := N'Delivery date is not acceptable. Required date: ' || ExpectedDelDate || '. [DRAFT]';
                END IF;
            END IF;

            -- Validation 32037: Type of Pallets/IBC Check
	        IF typpltibc = 0 THEN
	            error := 32037;
	            error_message := N'Please enter Type of pallets/IBC.';
	        END IF;

            -- Validation 31028: Item Category/Sub-Category Check
            IF (SOItemCode LIKE '%FG%') AND (SOItemCategory = '' OR SOItemSubCategory = '') THEN
                error := 31039;
                error_message := 'Item ('||SOItemCode||') is missing Category/Sub-Category. Contact admin. [DRAFT]';
            END IF;

            IF IFNULL(TaxCode,'') = '' THEN
	        	error := 31040;
	        	error_message := N'Please select Tax Code at Line No - '||MinSO+1 || ' [DRAFT].';
	        END IF;

			IF IFNULL(COA_Appr,'') = '' THEN
        		error := 31041;
        		error_message := N'Please select Approval On COA Yes/No at Line No - '||MinSO+1 || ' [DRAFT].';
        	END IF;

            MinSO := MinSO + 1;
        END WHILE;
    END IF; -- End of DraftObj = 17 check
END IF;


IF Object_type = '17' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

    -- =====================================
    -- VARIABLE DECLARATIONS
    -- =====================================
    DECLARE MinSO INT;
    DECLARE MaxSO INT;
    DECLARE Series NVARCHAR(50);
    DECLARE CardCode NVARCHAR(50);
    DECLARE SOCurrency NVARCHAR(50);
    DECLARE SOCmnt NVARCHAR(500);
    DECLARE SOSLP INT;
    DECLARE BPSLP INT;
    DECLARE RMRKPRD NVARCHAR(5000);
    DECLARE RMRKSTR NVARCHAR(500);
    DECLARE RMRKQC NVARCHAR(500);
    DECLARE SODate DATE;
    DECLARE DueDate DATE;
    DECLARE PLoad NVARCHAR(50);
    DECLARE PDischrg NVARCHAR(50);
    DECLARE CNPJ NVARCHAR(50);
    DECLARE CEP NVARCHAR(50);
    DECLARE CUIT NVARCHAR(50);
    DECLARE TaxID NVARCHAR(50);
    DECLARE NotifyCNPJ NVARCHAR(50);
    DECLARE NotifyCEP NVARCHAR(50);
    DECLARE City NVARCHAR(50);
    DECLARE ExpRmk NVARCHAR(5000);
    DECLARE ExpRmkO NVARCHAR(5000);
    DECLARE SOrate DECIMAL(18,2);
    DECLARE BPName NVARCHAR(100);
    DECLARE REXClause NVARCHAR(500);
    DECLARE REXNo NVARCHAR(50);
    DECLARE Name NVARCHAR(50);
    DECLARE POPayment NVARCHAR(200);
    DECLARE BPPayment NVARCHAR(200);
    DECLARE CardType NVARCHAR(50);
    DECLARE CreditLimit INT;
    DECLARE DueBalance INT;
    DECLARE DueDays INT;
    DECLARE OcrCode INT;
    DECLARE PrtCnt INT;
    DECLARE BPSlpName VARCHAR(100);
    DECLARE SOSlpName VARCHAR(100);
    DECLARE CustRef NVARCHAR(200);
    DECLARE SOExrate DECIMAL(18,2);
    DECLARE CCodeType NVARCHAR(5);
    DECLARE ItemCodeType NVARCHAR(5);

    -- Line Level Variables
    DECLARE SOItemCode NVARCHAR(50);
    DECLARE SOEntryType NVARCHAR(50);
    DECLARE TaxCode NVARCHAR(50);
    DECLARE LicenseTypeSO NVARCHAR(50);
    DECLARE Qty DOUBLE;
    DECLARE LicenseNoSO NVARCHAR(50);
    DECLARE PSS NVARCHAR(5);
    DECLARE SOPackType NVARCHAR(500);
    DECLARE SOPckCode NVARCHAR(500);
    DECLARE Capacity INT;
    DECLARE HASCOM NVARCHAR(50);
    DECLARE Commission INT;
    DECLARE CommissionPer INT;
    DECLARE ItmHSN NVARCHAR(50);
    DECLARE InvHSN NVARCHAR(50);
    DECLARE SOItemGrpCode NVARCHAR(50);
    DECLARE SOItemCategory NVARCHAR(50);
    DECLARE SOItemSubCategory NVARCHAR(50);
    DECLARE BatchCount NVARCHAR(50);
    DECLARE ShowREX VARCHAR(10);
    DECLARE typpltibc INT;
    DECLARE Freetext NVARCHAR(50);
    DECLARE LeadTime DOUBLE;
    DECLARE ExpeLT DOUBLE;
    DECLARE ExpectedDelDate DATE;
    DECLARE Pack1C INT;
    DECLARE Pack1 NVARCHAR(50);
    DECLARE Pack2C INT;
    DECLARE Pack2 NVARCHAR(50);
    DECLARE U_Pack3C INT;
    DECLARE U_Pack3 NVARCHAR(50);
    DECLARE U_Pack4C INT;
    DECLARE U_Pack4 NVARCHAR(50);
    DECLARE U_Pack5C INT;
    DECLARE U_Pack5 NVARCHAR(50);
    DECLARE U_Pack6C INT;
    DECLARE U_Pack6 NVARCHAR(50);
    DECLARE U_Pack7C INT;
    DECLARE U_Pack7 NVARCHAR(50);
    DECLARE U_Pack8C INT;
    DECLARE U_Pack8 NVARCHAR(50);
    DECLARE U_Pack9C INT;
    DECLARE U_Pack9 NVARCHAR(50);
    DECLARE U_Pack10C INT;
    DECLARE U_Pack10 NVARCHAR(50);
    DECLARE U_Pack11C INT;
    DECLARE U_Pack11 NVARCHAR(50);
    DECLARE U_Pack12C INT;
    DECLARE U_Pack12 NVARCHAR(50);
    DECLARE U_Pack13C INT;
    DECLARE U_Pack13 NVARCHAR(50);
    DECLARE U_Pack14C INT;
    DECLARE U_Pack14 NVARCHAR(50);
    DECLARE U_Pack15C INT;
    DECLARE U_Pack15 NVARCHAR(50);
    DECLARE U_Agro_Chem NVARCHAR(50);
    DECLARE U_Per_HM_CR NVARCHAR(50);
    DECLARE U_Food NVARCHAR(50);
    DECLARE U_Paints_Pigm NVARCHAR(50);
    DECLARE U_Indus_Care NVARCHAR(50);
    DECLARE U_Lube_Additiv NVARCHAR(50);
    DECLARE U_Oil_Gas NVARCHAR(50);
    DECLARE U_Textile NVARCHAR(50);
    DECLARE U_CAS_No NVARCHAR(50);
    DECLARE U_Other1 NVARCHAR(50);
    DECLARE U_Other2 NVARCHAR(50);
    DECLARE U_Pharma NVARCHAR(50);
    DECLARE U_Mining NVARCHAR(50);
    DECLARE SOPackng NVARCHAR(100);
    DECLARE SOName nvarchar(100);
    DECLARE COA_Appr NVARCHAR(5);

    -- =======================================================
    -- SECTION 1: EFFICIENTLY SELECT ALL HEADER DATA UPFRONT
    -- =======================================================
    SELECT
        T0."CardCode", T0."DocCur", T0."Comments", T0."SlpCode", T0."U_RMRKPRD", T0."U_RMRKSTR", T0."U_RMRKQC",
        T0."DocDate", T0."DocDueDate", T0."U_PLoad", T0."U_PDischrg", T0."U_CNPJ_Num", T0."U_CEP_Num", T0."U_CUIT_Num",
        T0."U_Tax_ID", T0."U_FinlDest", T0."U_Export_Remark", T0."U_ExportRemarks",
        T0."DocRate", T0."CardName", T3."BPLName", T0."NumAtCard",
        T1."SeriesName",
        T2."PymntGroup",
        T4."SlpCode", T4."CardType", T4."CreditLine", T4."Balance", T2."PymntGroup"
    INTO
        CardCode, SOCurrency, SOCmnt, SOSLP, RMRKPRD, RMRKSTR, RMRKQC,
        SODate, DueDate, PLoad, PDischrg, CNPJ, CEP, CUIT,
        TaxID, City, ExpRmk, ExpRmkO,
        SOrate, BPName, Name, CustRef,
        Series,
        POPayment,
        BPSLP, CardType, CreditLimit, DueBalance, BPPayment
    FROM ORDR T0
    INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
    INNER JOIN OCTG T2 ON T0."GroupNum" = T2."GroupNum"
    LEFT JOIN OBPL T3 ON T0."BPLId" = T3."BPLId"
    INNER JOIN OCRD T4 ON T0."CardCode" = T4."CardCode"
    WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

    SELECT Days_Between(Min(T0."DueDate"), Current_Date) INTO DueDays FROM JDT1 T0
    WHERE T0."ShortName" = :CardCode AND T0."BalDueDeb" != T0."BalDueCred" AND T0."TransType" <> 30 AND T0."BalDueDeb" > 0;

    SELECT MIN(T0."VisOrder"), MAX(T0."VisOrder") INTO MinSO, MaxSO FROM RDR1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

    -- =====================================
    -- SECTION 2: HEADER LEVEL VALIDATIONS
    -- =====================================

    -- Validation 32001: Distribution Rule Check
    SELECT COUNT(T0."OcrCode") INTO OcrCode FROM RDR1 T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T0."OcrCode" IS NOT NULL;
    IF (OcrCode = 0) THEN
        error := 32001;
        error_message := N'Please Select Distr. Rule in Document.';
    END IF;

    -- Validation 32002: Sales Person Check
    IF SOSLP = -1 THEN
        error := 32002;
        error_message := N'Please Enter Sales Person Name.';
    END IF;

    -- Validation 32003-32005: Remarks Checks (For Export Series)
    IF Series LIKE 'EX%' THEN
        IF RMRKPRD IS NULL THEN
        	error := 32003;
        	error_message := N'Please Enter Production Remark.';
        END IF;
        IF RMRKSTR IS NULL THEN
        	error := 32004;
        	error_message := N'Please Enter Store Remark.';
        END IF;
        IF RMRKQC IS NULL THEN
        	error := 32005;
        	error_message := N'Please Enter QC Remark.';
        END IF;
    END IF;

    -- Validation 32006: Delivery Date Check
    IF (DueDate < SODate) THEN
        error := 32006;
        error_message := N'Delivery date cannot be earlier than SO Date.';
    END IF;

    -- Validation 32007-32008: Port Checks (For Export Series)
    IF (Series LIKE 'EX%') THEN
        SELECT COUNT(*) INTO PrtCnt FROM "@PORTMASTER" WHERE "U_PortName" = :PLoad;
        IF (PrtCnt = 0) THEN
        	error := 32007;
        	error_message := N'Invalid [Port of Loading]. Select from list.';
        END IF;
        SELECT COUNT(*) INTO PrtCnt FROM "@PORTMASTER" WHERE "U_PortName" = :PDischrg;
        IF (PrtCnt = 0) THEN
        	error := 32008;
        	error_message := N'Invalid [Port of Discharge]. Select from list.';
        END IF;
    END IF;

    -- Validation 32009: Payment Terms Check
    IF POPayment <> BPPayment THEN
        error := 32009;
        error_message := N'Document payment terms do not match Business Partner master.';
    END IF;

    -- Validation 32011: Sales Employee Check
    IF BPSLP <> SOSLP THEN
        SELECT T0."SlpName" INTO BPSlpName FROM OSLP T0 WHERE T0."SlpCode" = BPSLP;
        SELECT T0."SlpName" INTO SOSlpName FROM OSLP T0 WHERE T0."SlpCode" = SOSLP;
        error := 32011;
        error_message := N'Sales Employee ('||BPSlpName||') is assigned to ('||BPName||'), you cannot change it to ('||SOSlpName||').';
    END IF;

    -- Validation 32012-32017: Export Document Fields Check
    IF CardCode LIKE 'C_E%' THEN
        IF CNPJ IS NULL THEN
        	error := 32012;
        	error_message := N'Please Enter CNPJ No.';
        END IF;
        IF CEP IS NULL THEN
        	error := 32013;
        	error_message := N'Please Enter CEP No.';
        END IF;
        IF CUIT IS NULL THEN
        	error := 32014;
        	error_message := N'Please Enter CUIT No.';
        END IF;
        IF TaxID IS NULL THEN
        	error := 32015;
        	error_message := N'Please Enter Tax ID.';
        END IF;
    END IF;

    -- Validation 32018: Final Destination Check
    IF CardCode LIKE 'C_E%' AND City IS NULL THEN
        error := 32018;
        error_message := N'Please select City in Logistics.';
    END IF;

    -- Validation 32019-32020: Export Remarks Check
    IF Series LIKE 'EX%' THEN
        IF (ExpRmkO='No' OR ExpRmkO IS NULL) AND (ExpRmk IS NOT NULL AND ExpRmk<>'') THEN
            error := 32019;
            error_message := N'Cannot enter Export Remarks when option is No/blank.';
        END IF;
        IF ExpRmkO='Yes' AND (ExpRmk IS NULL OR ExpRmk='') THEN
            error := 32020;
            error_message := N'Export Remarks field is mandatory when option is Yes.';
        END IF;
    END IF;

    -- 'ADD' Transaction Specific Header Validations
    IF (:transaction_type = 'A') THEN
        -- Validation 32021: Currency and Series Check
        IF (CardCode LIKE 'CPE%' AND SOCurrency = 'INR') OR (CardCode LIKE 'CSE%' AND SOCurrency = 'INR') THEN
            error := 32021;
            error_message := N'Please Select Proper Currency.';
        END IF;
        IF (CardCode LIKE 'CSE%' AND Series NOT LIKE 'EX%') OR (CardCode LIKE 'CPE%' AND Series NOT LIKE 'EX%') THEN
            error := 32021;
            error_message := N'Please Select Proper Series.';
        END IF;

        -- Validation 32022: Customer Reference Number Check
        IF CustRef IS NULL OR LENGTH(CustRef) = 0 THEN
            error := 32022;
            error_message := N'Enter Customer Ref No ..';
        END IF;
        IF CustRef LIKE '%ail%' THEN
            error := 32022;
            error_message := N'Invalid Customer Ref No ..';
        END IF;

        -- Validation 32023: Exchange Rate Check
        IF CardCode LIKE 'C_E%' THEN
            SELECT T0."Rate" INTO SOExrate FROM ORTT T0 WHERE T0."Currency" = :SOCurrency AND T0."RateDate" = :SODate;
            IF SOExrate <> SOrate THEN
                error := 32023;
                error_message := N'Not allowed to change exchange rate.';
            END IF;
        END IF;
    END IF;

    -- =====================================================
	-- Validation 30021: Consignee Manual Entry Not Allowed
	-- =====================================================
	IF Series LIKE 'EX%' THEN
	        IF EXISTS		(SELECT 1 FROM ORDR T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del
	        AND
	        NOT EXISTS			(SELECT 1 FROM "@CONSIGNEED" T1 WHERE T1."Code" = T0."CardCode" AND T1."U_Consignee" = T0."U_Consignee_Name"
			        			AND TO_NVARCHAR(T1."U_ConsigneeAdd") = TO_NVARCHAR(T0."U_Consignee_Add")
	        				    )
	        				) THEN
	        error := 30032;
	        error_message := 'Manual entry not allowed.. Please select Consignee from the master list.';
	    	END IF;
	END IF;

    -- ===================================================
    -- SECTION 3: LINE LEVEL VALIDATIONS - COMBINED LOOP
    -- ===================================================
    SELECT CASE WHEN CardCode LIKE 'CP%' THEN 'PC' WHEN CardCode LIKE 'CS%' THEN 'SC' WHEN CardCode LIKE 'CO%' THEN 'OF' END INTO CCodeType FROM dummy;

    WHILE MinSO <= MaxSO DO
        -- Get all line-level data in a single, efficient query
        SELECT
            T1."U_EntryType", T1."ItemCode", T1."U_LicenseType", T1."U_LicenseNum", T1."U_PSS", T1."Quantity", T1."TaxCode",
            T1."U_Pcode", T1."U_PTYPE", T1."Factor1", T1."U_UNE_APPR", T1."U_Commission_Q", T1."U_Q_CommissionPer",
            COUNT(T1."U_TOPLT"), T1."FreeTxt",
            T2."ItmsGrpCod", IFNULL(T2."U_PCAT", ''), IFNULL(T2."U_PSCAT", ''), T1."U_NoOfBatchRequired",
            T2."U_Agro_Chem", T2."U_Per_HM_CR", T2."U_Food", T2."U_Paints_Pigm", T2."U_Indus_Care", T2."U_Lube_Additiv", T2."U_Textile", T2."U_Oil_Gas", T2."U_CAS_No",
            T2."U_Other1", T2."U_Other2", T2."U_Pharma", T2."U_Mining", T1."Dscription", T1."U_Pcode", T1."U_ApprOnCOA"
        INTO
            SOEntryType, SOItemCode, LicenseTypeSO, LicenseNoSO, PSS, Qty, TaxCode,
            SOPckCode, SOPackType, Capacity, HASCOM, Commission, CommissionPer,
            typpltibc, Freetext,
            SOItemGrpCode, SOItemCategory, SOItemSubCategory, BatchCount,
            U_Agro_Chem, U_Per_HM_CR, U_Food, U_Paints_Pigm, U_Indus_Care, U_Lube_Additiv, U_Textile, U_Oil_Gas, U_CAS_No, U_Other1, U_Other2, U_Pharma, U_Mining, SOName, SOPackng, COA_Appr
        FROM RDR1 T1
        INNER JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode"
        WHERE T1."DocEntry" = :list_of_cols_val_tab_del AND T1."VisOrder" = MinSO
        GROUP BY T1."U_EntryType", T1."ItemCode", T1."U_LicenseType", T1."U_LicenseNum", T1."U_PSS", T1."Quantity", T1."TaxCode",
            T1."U_Pcode", T1."U_PTYPE", T1."Factor1", T1."U_UNE_APPR", T1."U_Commission_Q", T1."U_Q_CommissionPer",
            T1."FreeTxt", T2."ItmsGrpCod", T2."U_PCAT", T2."U_PSCAT", T1."U_NoOfBatchRequired",
            T2."U_Agro_Chem", T2."U_Per_HM_CR", T2."U_Food", T2."U_Paints_Pigm", T2."U_Indus_Care", T2."U_Lube_Additiv", T2."U_Textile", T2."U_Oil_Gas", T2."U_CAS_No",
            T2."U_Other1", T2."U_Other2", T2."U_Pharma", T2."U_Mining",T1."Dscription", T1."U_Pcode", T1."U_ApprOnCOA";

        -- Validation 32024: Entry Type Check (Only for Add)
        IF (:transaction_type = 'A') AND (SOEntryType = 'Blank' AND (SOItemCode LIKE 'PCRM%' OR SOItemCode LIKE 'PCFG%')) THEN
            error := 32024;
            error_message := N'Please select Entry Type at row level.';
        END IF;

        -- Validation 32025: License and Quantity Checks
        IF (LicenseTypeSO IS NULL OR LicenseTypeSO = '') AND SOCmnt NOT LIKE '%sample%' THEN
            error := 32025;
            error_message := N'Please enter License Type.';
        END IF;
        IF LicenseTypeSO <> '' AND LicenseTypeSO NOT IN ('ADVANCE','DBK','MEIS', 'No Required') AND SOCmnt NOT LIKE '%sample%' THEN
            error := 32025;
            error_message := N'Invalid License Type selected.';
        END IF;
        IF LicenseTypeSO <> 'No Required' and LicenseNoSO IS NULL THEN
        	error := 32025;
        	error_message := N'Please Enter License Number in Sales Contract';
        END IF;
        IF (SOItemCode LIKE 'PC%' OR SOItemCode LIKE 'SC%') AND Qty > 150000 THEN
            error := 32025;
            error_message := N'Quantity cannot exceed 150 MT for this item.';
        END IF;
        IF (SOItemCode LIKE 'OF%') AND Qty > 1000000 THEN
            error := 32025;
            error_message := N'Quantity cannot exceed 1000 MT for this item.';
        END IF;

        -- Validation 32026-32027: License Number and PSS Checks
        IF (LicenseNoSO IS NULL OR LicenseNoSO = '') AND LicenseTypeSO LIKE 'A%' AND CardCode LIKE 'C_E%' THEN
            error := 32026;
            error_message := N'Please enter License No.';
        END IF;

        IF IFNULL(UPPER(PSS),'') NOT IN ('YES','NO') AND CardCode LIKE 'C%' AND SOItemCode LIKE '%FG%' THEN
            error := -32027;
            error_message := N'Please select PSS Yes/No at Line '||MinSO+1;
        END IF;

        -- Validation 32028: SAP Packing Code Check
        IF SOItemCode NOT LIKE '%PM%' AND SOItemCode NOT LIKE '%RM%' AND SOItemCode NOT IN ('WSTG0001', 'WSTG0004') THEN
            IF SOPackType NOT LIKE '%Tanker%' AND SOPackType NOT LIKE '%ISO%' AND (SOPckCode IS NULL OR SOPckCode = '') THEN
                error := 32028;
                error_message := N'Please select SAP Packing Code.';
            END IF;
        END IF;

        -- Validation 32029-32030: Capacity and Packing Code Checks
        /*IF SOItemCode NOT LIKE 'DIBP%' AND SOItemCode NOT LIKE 'PCPM%' AND SOItemCode NOT LIKE 'WSTG%' AND SOPackType NOT LIKE '%Tanker%' THEN
            SELECT T0."U_Pack1C", T0."U_Pack2C", T0."U_Pack3C", T0."U_Pack4C", T0."U_Pack5C", T0."U_Pack6C", T0."U_Pack7C", T0."U_Pack8C", T0."U_Pack9C", T0."U_Pack10C", T0."U_Pack11C", T0."U_Pack12C", T0."U_Pack13C", T0."U_Pack14C", T0."U_Pack15C"
            INTO Pack1C, Pack2C, U_Pack3C, U_Pack4C, U_Pack5C, U_Pack6C, U_Pack7C, U_Pack8C, U_Pack9C, U_Pack10C, U_Pack11C, U_Pack12C, U_Pack13C, U_Pack14C, U_Pack15C
            FROM "@SOPACKING" T0 WHERE T0."Code" = SOItemCode;
            SELECT T0."U_Pack1", T0."U_Pack2", T0."U_Pack3", T0."U_Pack4", T0."U_Pack5", T0."U_Pack6", T0."U_Pack7", T0."U_Pack8", T0."U_Pack9", T0."U_Pack10", T0."U_Pack11", T0."U_Pack12", T0."U_Pack13", T0."U_Pack14", T0."U_Pack15"
            INTO Pack1, Pack2, U_Pack3, U_Pack4, U_Pack5, U_Pack6, U_Pack7, U_Pack8, U_Pack9, U_Pack10, U_Pack11, U_Pack12, U_Pack13, U_Pack14, U_Pack15
            FROM "@SOPACKING" T0 WHERE T0."Code" = SOItemCode;

            IF SOCmnt NOT LIKE '%sample%' AND SOPackType NOT LIKE 'ISO%' THEN
                IF Capacity NOT IN (Pack1C, Pack2C, U_Pack3C, U_Pack4C, U_Pack5C, U_Pack6C, U_Pack7C, U_Pack8C, U_Pack9C, U_Pack10C, U_Pack11C, U_Pack12C, U_Pack13C, U_Pack14C, U_Pack15C) THEN
                    error := 32029;
                    error_message := N'Invalid capacity selected. Choose from the list.';
                END IF;
                IF SOPckCode NOT IN (Pack1, Pack2, U_Pack3, U_Pack4, U_Pack5, U_Pack6, U_Pack7, U_Pack8, U_Pack9, U_Pack10, U_Pack11, U_Pack12, U_Pack13, U_Pack14, U_Pack15) THEN
                    error := 32030;
                    error_message := N'Invalid packing code. Choose from the list.';
                END IF;
            END IF;
        END IF;*/

        IF SOItemCode NOT LIKE 'DIBP%' AND SOItemCode NOT LIKE 'PCPM%' AND SOItemCode NOT LIKE 'WSTG%' AND SOItemCode NOT LIKE 'EECA%' AND UPPER(SOPackType) NOT LIKE '%TANK%' THEN
                 SELECT T0."U_Pack1C", T0."U_Pack2C", T0."U_Pack3C", T0."U_Pack4C", T0."U_Pack5C", T0."U_Pack6C", T0."U_Pack7C", T0."U_Pack8C", T0."U_Pack9C", T0."U_Pack10C", T0."U_Pack11C", T0."U_Pack12C", T0."U_Pack13C", T0."U_Pack14C", T0."U_Pack15C"
                 INTO Pack1C, Pack2C, U_Pack3C, U_Pack4C, U_Pack5C, U_Pack6C, U_Pack7C, U_Pack8C, U_Pack9C, U_Pack10C, U_Pack11C, U_Pack12C, U_Pack13C, U_Pack14C, U_Pack15C
                 FROM "@SOPACKING" T0 WHERE T0."Code" = SOItemCode;

                 SELECT T0."U_Pack1", T0."U_Pack2", T0."U_Pack3", T0."U_Pack4", T0."U_Pack5", T0."U_Pack6", T0."U_Pack7", T0."U_Pack8", T0."U_Pack9", T0."U_Pack10", T0."U_Pack11", T0."U_Pack12", T0."U_Pack13", T0."U_Pack14", T0."U_Pack15"
                 INTO Pack1, Pack2, U_Pack3, U_Pack4, U_Pack5, U_Pack6, U_Pack7, U_Pack8, U_Pack9, U_Pack10, U_Pack11, U_Pack12, U_Pack13, U_Pack14, U_Pack15
                 FROM "@SOPACKING" T0 WHERE T0."Code" = SOItemCode;

                IF SOCmnt NOT LIKE '%sample%' AND SOPackType NOT LIKE 'ISO%' THEN
		        IF Capacity = Pack1C then
					else
						IF Capacity = U_Pack15C then
						else
							IF Capacity = Pack2C then
							else
								IF Capacity = U_Pack3C then
								else
									IF Capacity = U_Pack4C then
									else
										IF Capacity = U_Pack5C then
										else
											IF Capacity = U_Pack6C then
											else
												IF Capacity = U_Pack7C then
												else
													IF Capacity = U_Pack8C then
													else
														IF Capacity = U_Pack9C then
														else
															IF Capacity = U_Pack10C then
															else
																IF Capacity = U_Pack11C then
																else
																	IF Capacity = U_Pack12C then
																	else
																		IF Capacity = U_Pack13C then
																		else
																			IF Capacity = U_Pack14C then
																			else
																				error:=30066;
																				error_message:=N'Please Select proper capacity from list';
																			END IF;
																		END IF;
																	END IF;
																END IF;
															END IF;
														END IF;
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;


		            IF SOPckCode = Pack1 then
					else
						IF SOPckCode = U_Pack15 then
						else
							IF SOPckCode = Pack2 then
							else
								IF SOPckCode = U_Pack3 then
								else
									IF SOPckCode = U_Pack4 then
									else
										IF SOPckCode = U_Pack5 then
										else
											IF SOPckCode = U_Pack6 then
											else
												IF SOPckCode = U_Pack7 then
												else
													IF SOPckCode = U_Pack8 then
													else
														IF SOPckCode = U_Pack9 then
														else
															IF SOPckCode = U_Pack10 then
															else
																IF SOPckCode = U_Pack11 then
																else
																	IF SOPckCode = U_Pack12 then
																	else
																		IF SOPckCode = U_Pack13 then
																		else
																			IF SOPckCode = U_Pack14 then
																			else
																				error:=30067;
																				error_message:=N'Please Select Packing code from list';
																			END IF;
																		END IF;
																	END IF;
																END IF;
															END IF;
														END IF;
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
		        END IF;

            END IF;

        -- Validation 32031: Commission Check (For Export Series)
        IF Series LIKE 'E%' AND HASCOM = 'Y' AND (Commission = 0 OR Commission IS NULL OR CommissionPer = 0 OR CommissionPer IS NULL) THEN
            error := 32031;
            error_message := N'Please enter Commission Percentage and check Commission value.';
        END IF;

        -- Validation 32032: HSN Code Check
        IF SOItemCode NOT IN ('SER0123', 'WSTG0001') THEN
            SELECT concat(concat(concat(concat("Chapter",'.'),"Heading"),'.'),"SubHeading") INTO ItmHSN FROM OCHP T0 INNER JOIN OITM T1 ON T0."AbsEntry" = T1."ChapterID" WHERE T1."ItemCode" = SOItemCode;
            SELECT concat(concat(concat(concat("Chapter",'.'),"Heading"),'.'),"SubHeading") INTO InvHSN FROM OCHP T0 INNER JOIN RDR1 T1 ON T1."HsnEntry" = T0."AbsEntry" WHERE T1."DocEntry" = :list_of_cols_val_tab_del AND T1."VisOrder" = MinSO;
            IF ItmHSN <> InvHSN THEN
                error := 32032;
                error_message := 'HSN Code mismatch for item ' || SOItemCode;
            END IF;
        END IF;

        -- Validation 32033: Customer and Item Type Matching
        SELECT CASE WHEN SOItemCode LIKE 'PC%' THEN 'PC' WHEN SOItemCode LIKE 'DI%' THEN 'SC' WHEN SOItemCode LIKE 'OF%' THEN 'OF' END INTO ItemCodeType FROM dummy;
        IF SOItemGrpCode NOT IN (104, 101) THEN
            IF (SOItemCode LIKE 'PC%' AND CardCode NOT LIKE 'CP%') OR (SOItemCode LIKE 'SC%' AND CardCode NOT LIKE 'CS%') OR (SOItemCode LIKE 'OF%' AND CardCode NOT LIKE 'CO%') THEN
                error := 32033;
                error_message := 'Customer type ('||CCodeType||') and Item type ('||ItemCodeType||') mismatch at row '|| MinSO+1;
            END IF;
        END IF;

        -- Validation 32034: Item Category/Sub-Category Check
        IF (SOItemCode LIKE '%FG%') AND (SOItemCategory = '' OR SOItemSubCategory = '') THEN
            error := 32034;
            error_message := 'Item ('||SOItemCode||') is missing Category/Sub-Category. Contact admin.';
        END IF;

        -- Validation 32035: Batch Count Check
        IF (SOItemCode LIKE '%FG%' OR SOItemCode LIKE '%RM%' OR SOItemCode LIKE '%TR%') AND BatchCount IS NULL THEN
            error := 32035;
            error_message := N'Number of Batches is required for item ' || SOItemCode || ' at line ' || MinSO + 1;
        END IF;

        -- Validation 32037: Type of Pallets/IBC Check
        IF typpltibc = 0 THEN
            error := 32037;
            error_message := N'Please enter Type of pallets/IBC.';
        END IF;

        -- Validation 32038: Alias Name Check
        /*IF Series NOT LIKE 'CL%' AND (SOItemCode NOT LIKE 'DI%' AND SOItemCode NOT LIKE 'PCPM%' AND SOItemCode NOT LIKE 'FA%' AND SOItemCode NOT LIKE 'WS%' AND SOItemCode <> 'PCFG0424') THEN
            SELECT "U_Agro_Chem", "U_Per_HM_CR", "U_Food", "U_Paints_Pigm", "U_Indus_Care", "U_Lube_Additiv", "U_Textile", "U_Oil_Gas", "U_CAS_No", "U_Other1", "U_Other2", "U_Pharma", "U_Mining"
            INTO U_Agro_Chem, U_Per_HM_CR, U_Food, U_Paints_Pigm, U_Indus_Care, U_Lube_Additiv, U_Textile, U_Oil_Gas, U_CAS_No, U_Other1, U_Other2, U_Pharma, U_Mining
            FROM OITM WHERE "ItemCode" = SOItemCode;
            IF Freetext NOT IN (U_Agro_Chem, U_Per_HM_CR, U_Food, U_Paints_Pigm, U_Indus_Care, U_Textile, U_Lube_Additiv, U_Oil_Gas, U_CAS_No, U_Other1, U_Other2, U_Pharma, U_Mining) THEN
                error:=32038;
                error_message:=N'Invalid Alias Name. Not found in master.';
            END IF;
        END IF;*/

        -- Validation 30051: Alias Name Check (Simplified Logic)
		IF Series NOT LIKE 'CL%' then
			IF (SOItemCode NOT LIKE 'SC%' AND SOItemCode NOT LIKE 'PCPM%' AND SOItemCode NOT LIKE 'FA%' AND SOItemCode NOT LIKE 'WS%') THEN
				IF SOName = Freetext then
				else
					IF Freetext = U_Agro_Chem then
					else
						IF Freetext = U_Per_HM_CR then
						else
							IF Freetext = U_Food then
							else
								IF Freetext = U_Paints_Pigm then
								else
									IF Freetext = U_Indus_Care then
									else
										IF Freetext = U_Textile then
										else
											IF Freetext = U_Lube_Additiv then
											else
												IF Freetext = U_Oil_Gas then
												else
													IF Freetext = U_CAS_No then
													else
														IF Freetext = U_Other1 then
														else
															IF Freetext = U_Other2 then
															else
																IF Freetext = U_Pharma then
																else
																	IF Freetext = U_Mining then
																	else
																		error:=30051;
																		error_message:=N'Please Select Proper Alias Name in Sales order (Alias Name not in master)';
																	END IF;
																END IF;
															END IF;
														END IF;
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
			END IF;


        -- Validation 32039: Lead Time Check
        IF SOItemCode LIKE 'PCFG%' THEN
            SELECT MAX(T0."U_LT_Per_10MT") INTO LeadTime FROM OITM T0 WHERE T0."ItemCode" = SOItemCode;
            IF Series LIKE 'DM%' THEN SELECT MAX(ROUND((((:Qty/10000)*LeadTime)+3),0)) INTO ExpeLT FROM DUMMY;
            END IF;
            IF Series LIKE 'EX%' THEN SELECT MAX(ROUND((((:Qty/10000)*LeadTime)+13),0)) INTO ExpeLT FROM DUMMY;
            END IF;
            SELECT ADD_DAYS(:SODate, ExpeLT) INTO ExpectedDelDate FROM DUMMY;
            IF DueDate < ExpectedDelDate THEN
                error := 32039;
                error_message := N'Delivery date is not acceptable. Required date: ' || ExpectedDelDate;
            END IF;
        END IF;

        IF IFNULL(TaxCode,'') = '' THEN
        	error := 32040;
        	error_message := N'Please select Tax Code at Line No - '||MinSO+1;
        END IF;

		IF IFNULL(COA_Appr,'') = '' THEN
        	error := 32041;
        	error_message := N'Please select Approval On COA Yes/No at Line No - '||MinSO+1;
        END IF;

        MinSO := MinSO + 1;
    END WHILE;
END IF;

--------------------------- SALES ORDER END ----------------------------------------------
-- =========================================================================================================
--  Purchase Order Validations (Object Type: 22)
-- =========================================================================================================
IF :object_type = '22' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

    -- ========== Variable Declaration ==========
    DECLARE MIN_ROW INT;
    DECLARE MAX_ROW INT;
    DECLARE TempCounter INT;
    DECLARE DaysDifference INT;

    -- Header Level Variables
    DECLARE HeaderBranch INT;
    DECLARE DocCurrency NVARCHAR(10);
    DECLARE VendorCode NVARCHAR(50);
    DECLARE SeriesName NVARCHAR(20);
    DECLARE Suffix NVARCHAR(20);
    DECLARE FooterText NVARCHAR(250);
    DECLARE TagNumber NVARCHAR(5000);
    DECLARE DeliveryTerm NVARCHAR(100);
    DECLARE PaymentTerm NVARCHAR(100);
    DECLARE BpPaymentTerm NVARCHAR(100);
    DECLARE UserCode NVARCHAR(50);
    DECLARE BpBaseDocRequired NVARCHAR(5);
    DECLARE DocDate DATE;
    DECLARE DeliveryDate DATE;
    DECLARE PlaceOfSupply NVARCHAR(100);
    DECLARE ShipToState NVARCHAR(100);

    -- Row Level Variables
    DECLARE ItemCode NVARCHAR(50);
    DECLARE ItemDescription NVARCHAR(250);
    DECLARE MasterItemName NVARCHAR(250);
    DECLARE OcrCode NVARCHAR(50);
    DECLARE TaxCode NVARCHAR(50);
    DECLARE EntryType NVARCHAR(50);
    DECLARE Warehouse NVARCHAR(50);
    DECLARE Project NVARCHAR(50);
    DECLARE BaseDocEntry INT;
    DECLARE BaseDocType INT;
    DECLARE BaseDocBranch INT;
    DECLARE BaseTypeUDF NVARCHAR(50);
    DECLARE BaseDocNumUDF INT;
    DECLARE ItemBranch INT;
    DECLARE ItemClass CHAR(1); -- '1' for Service, '2' for Material
    DECLARE PackingType NVARCHAR(100);
    DECLARE PackingCode NVARCHAR(50);
    DECLARE PackingCapacity INT;
    DECLARE HsnEntry INT;
    DECLARE SacEntry INT;
    DECLARE ItemType NVARCHAR(5);


    -- ========== Data Retrieval (Header) ==========
    SELECT T0."BPLId", T0."DocCur", T0."CardCode", T0."Footer", T0."U_Tag_number", T0."U_Del_Terms",
           T2."PymntGroup", T3."USER_CODE", T4."U_Base_Doc", T0."DocDate", T0."DocDueDate", T5."SeriesName", T5."EndStr"
    INTO HeaderBranch, DocCurrency, VendorCode, FooterText, TagNumber, DeliveryTerm, PaymentTerm, UserCode,
         BpBaseDocRequired, DocDate, DeliveryDate, SeriesName, Suffix
    FROM OPOR T0
    INNER JOIN OCTG T2 ON T0."GroupNum" = T2."GroupNum"
    INNER JOIN OUSR T3 ON T0."UserSign" = T3."USERID"
    INNER JOIN OCRD T4 ON T0."CardCode" = T4."CardCode"
    INNER JOIN NNM1 T5 ON T0."Series" = T5."Series"
    WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

    SELECT T1."PymntGroup" INTO BpPaymentTerm
    FROM OCRD T0
    INNER JOIN OCTG T1 ON T0."GroupNum" = T1."GroupNum"
    WHERE T0."CardCode" = VendorCode;

    SELECT T2."Name" INTO PlaceOfSupply FROM POR12 T0 INNER JOIN OPOR T1 ON T0."DocEntry" = T1."DocEntry" LEFT JOIN OCST T2 ON T0."LocStatCod" = T2."Code" WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
    SELECT T2."Name" INTO ShipToState FROM POR12 T0 INNER JOIN OPOR T1 ON T0."DocEntry" = T1."DocEntry" LEFT JOIN OCST T2 ON T0."StateB" = T2."Code" AND T0."CountryB" = T2."Country" WHERE T1."DocEntry" = :list_of_cols_val_tab_del;

    -- ========== Row Level Validations (Single Loop) ==========
    SELECT MIN(T0."VisOrder"), MAX(T0."VisOrder") INTO MIN_ROW, MAX_ROW FROM POR1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

    WHILE MIN_ROW <= MAX_ROW DO

        SELECT T0."ItemCode", T0."Dscription", T1."ItemName", T0."OcrCode", T0."TaxCode", T0."U_EntryType", T0."WhsCode",
               T0."Project", T0."BaseEntry", T0."BaseType", T0."U_BASETYPE", T0."U_BASEDOCNO", T1."ItemClass",
               T0."U_PTYPE", T0."U_Pcode", T0."Factor1", T0."HsnEntry", T0."SacEntry", T1."ItemType"
        INTO ItemCode, ItemDescription, MasterItemName, OcrCode, TaxCode, EntryType, Warehouse,
             Project, BaseDocEntry, BaseDocType, BaseTypeUDF, BaseDocNumUDF, ItemClass,
             PackingType, PackingCode, PackingCapacity, HsnEntry, SacEntry, ItemType
        FROM POR1 T0
        INNER JOIN OITM T1 ON T0."ItemCode" = T1."ItemCode"
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."VisOrder" = MIN_ROW;

        IF IFNULL(OcrCode, '') = '' THEN
            error := -40001;
            error_message := N'Please Select Distribution Rule for item: ' || ItemCode;
        END IF;

        IF DocCurrency <> 'INR' AND TaxCode = 'RIGST18' THEN
            error := -40002;
            error_message := N'Select proper "RIGST18T" Taxcode for import party.';
        END IF;

        SELECT COUNT(*) INTO TempCounter FROM DUMMY
        WHERE ItemCode LIKE '%RM%' OR ItemCode LIKE '%FG%';
        IF IFNULL(EntryType, 'Blank') = 'Blank' AND TempCounter > 0 THEN
            error := -40003;
            error_message := N'Please Select Entry Type (Normal/Trading) at row ' || MIN_ROW + 1;
        END IF;

        IF EntryType = 'Trading' AND Warehouse NOT LIKE '%TR%' THEN
            error := -40004;
            error_message := N'Please select a TR warehouse for Trading items at row ' || MIN_ROW + 1;
        END IF;

        IF :transaction_type = 'A' AND ItemCode <> 'EMHA0383' THEN
            IF LENGTH(ItemDescription) <> LENGTH(MasterItemName) THEN
                error := -40005;
                error_message := N'You are not allowed to change the Item Name at row ' || MIN_ROW + 1;
            END IF;
        END IF;

        IF BaseDocType = 1470000113 THEN
            SELECT T1."BPLId" INTO BaseDocBranch FROM OPRQ T1 WHERE T1."DocEntry" = BaseDocEntry;
            IF HeaderBranch <> BaseDocBranch THEN
                error := -40006;
                error_message := N'PO and Purchase Request must be of the same Branch.';
            END IF;
        END IF;

        IF HeaderBranch = 3 AND IFNULL(Project, '') = '' THEN
            error := -40007;
            error_message := N'For unit 1 Please select project as corporate or NA at row ' || MIN_ROW + 1;
        END IF;

        IF HeaderBranch = 4 AND (Project = 'Corpo. House' OR Project = 'NA') THEN
            error := -40008;
            error_message := N'For unit 2 do not select project at row ' || MIN_ROW + 1;
        END IF;

        IF HeaderBranch = 5 AND (Project = 'Corpo. House' OR Project = 'NA') THEN
            error := -40009;
            error_message := N'For unit 3 do not select project at row ' || MIN_ROW + 1;
        END IF;

        IF UserCode LIKE '%dispatch%' AND IFNULL(BaseTypeUDF, '') <> 'NA' THEN
            error := -40010;
            error_message := N'select NA as base type at row ' || MIN_ROW + 1;
        END IF;

        IF (ItemCode LIKE 'FA%' AND ItemType = 'F') THEN
            SELECT T1."BPLId" INTO ItemBranch FROM OITM T0
            INNER JOIN OACS T1 ON T0."AssetClass" = T1."Code"
            WHERE T0."ItemCode" = ItemCode;
            IF HeaderBranch <> ItemBranch THEN
                error := -40011;
                error_message := N'Fixed Asset branch does not match PO branch for item ' || ItemCode || ' contact SAP team.';
            END IF;
        END IF;

        IF BaseDocNumUDF IS NOT NULL THEN
            SELECT COUNT(*) INTO TempCounter FROM POR1 T0
            WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."U_BASEDOCNO" = BaseDocNumUDF AND T0."ItemCode" = ItemCode;
            IF TempCounter > 1 THEN
                error := -40012;
                error_message := N'Not allowed to select the same item (' || ItemCode || ') from the same base document twice.';
            END IF;
        END IF;

        IF HeaderBranch = 4 THEN
            IF ItemCode LIKE 'PCPM%' AND Warehouse NOT IN ('2EX1PCPM', '2PC-PAC') THEN
                error := -40013;
                error_message := N'For packing material, select 2PC-PAC or Extended Packing warehouse at row ' || MIN_ROW + 1;
            END IF;
            IF ItemCode NOT LIKE 'PCPM%' AND Warehouse LIKE '2EX%' THEN
                error := -40014;
                error_message := N'Extended warehouse is not allowed for item ' || ItemCode || ' at row ' || MIN_ROW + 1;
            END IF;
        END IF;

        IF Suffix LIKE 'SPO%' AND ItemClass = '2' THEN
            error := -40015;
            error_message := N'You have selected a Service Series. Please select a Service item at row ' || MIN_ROW + 1;
        END IF;

        IF Suffix LIKE 'PO%' AND ItemClass = '1' THEN
            error := -40016;
            error_message := N'You have selected a Material Series. Please select a Material item at row ' || MIN_ROW + 1;
        END IF;

        SELECT COUNT(*) INTO TempCounter FROM DUMMY WHERE ItemCode LIKE '%RM%' OR ItemCode LIKE '%FG%' OR ItemCode LIKE '%TR%';
        IF TempCounter > 0 THEN
            IF IFNULL(PackingType, '') = '' THEN
                error := -40017;
                error_message := N'Please select Packing for ' || ItemCode || ' at row ' || MIN_ROW + 1;
            END IF;
            IF IFNULL(PackingCode, '') <> '' AND IFNULL(PackingCapacity, 0) <= 1 THEN
                error := -40018;
                error_message := N'Please enter valid Packing Capacity for ' || ItemCode || ' at row ' || MIN_ROW + 1;
            END IF;
        END IF;

        IF BaseDocEntry IS NOT NULL THEN
            SELECT DAYS_BETWEEN(T1."DocDate", DocDate) INTO DaysDifference FROM OPRQ T1
            INNER JOIN PRQ1 T2 ON T1."DocEntry" = T2."DocEntry"
            INNER JOIN POR1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T2."LineNum" = T3."BaseLine"
            WHERE T3."DocEntry" = :list_of_cols_val_tab_del AND T3."VisOrder" = MIN_ROW;

            IF DaysDifference > 7 AND IFNULL(FooterText, '') = '' THEN
                error := -40019;
                error_message := N'Please enter reason of delay PO (Closing remark).';
            END IF;
            IF DaysDifference < 0 THEN
                error := -40020;
                error_message := N'PO not allowed to enter less than PR date.';
            END IF;
        END IF;

        IF PlaceOfSupply <> ShipToState AND TaxCode NOT LIKE 'IGST%' THEN
            error := -40061;
            error_message := N'For interstate transactions, you must choose an IGST tax code.';
        END IF;

        IF PlaceOfSupply = ShipToState AND TaxCode NOT LIKE 'CS%' THEN
            error := -40062;
            error_message := N'For intrastate transactions, you must choose a CSGST tax code.';
        END IF;

        IF ItemClass = '1' AND IFNULL(SacEntry, 0) = 0 THEN
            error := -40063;
            error_message := 'SAC Code is mandatory for service items.';
        END IF;

        IF ItemClass = '2' AND IFNULL(HsnEntry, 0) = 0 THEN
            error := -40064;
            error_message := 'HSN Code is mandatory for material items.';
        END IF;

        SELECT T1."BPLid" INTO BaseDocBranch FROM OWHS T1 WHERE T1."WhsCode" = Warehouse;
        IF HeaderBranch <> BaseDocBranch THEN
            error := -40065;
            error_message := N'Please select proper Warehouse at row ' || MIN_ROW + 1;
        END IF;

        MIN_ROW := MIN_ROW + 1;
    END WHILE;


    -- ========== Header/Document Level Validations ==========

    IF :transaction_type = 'A' AND (VendorCode LIKE 'VPRI%' OR VendorCode LIKE 'VIRI%' OR VendorCode LIKE 'VSRI%') AND VendorCode NOT IN ('VPRI0014', 'VPRI0020') THEN
        IF DocCurrency = 'INR' THEN
            error := -40021;
            error_message := N'Please select a foreign currency for this import vendor.';
        END IF;
        IF SeriesName NOT LIKE 'IM%' THEN
            error := -40022;
            error_message := N'Please select an Import series for this vendor.';
        END IF;
    END IF;

    IF :transaction_type = 'A' THEN
        IF DAYS_BETWEEN(DocDate, NOW()) >= 3 THEN
            error := -40023;
            error_message := N'POs older than 3 days are not allowed.';
        END IF;
    END IF;

    IF :transaction_type = 'A' AND DeliveryDate < DocDate THEN
        error := -40024;
        error_message := N'Delivery date cannot be earlier than the document date.';
    END IF;

    SELECT MAX(T0."BaseType") INTO BaseDocType FROM POR1 T0
    WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."ItemCode" NOT LIKE 'SER%' AND T0."ItemCode" NOT LIKE 'EGSR%'
      AND T0."ItemCode" NOT LIKE 'SAFE%' AND T0."ItemCode" NOT LIKE '%RM%' AND T0."ItemCode" NOT LIKE '%TR%' AND T0."ItemCode" NOT LIKE '%FG%';
    IF BpBaseDocRequired = 'Y' AND UserCode <> 'dispatch' AND BaseDocType = -1 THEN
        error := -40025;
        error_message := N'Please select a Base Document.';
    END IF;

    SELECT COUNT(T1."Cellolar") INTO TempCounter FROM OCPR T1 WHERE T1."CardCode" = VendorCode;
    IF TempCounter = 0 THEN
        error := -40026;
        error_message := N'Please add a mobile number to the Business Partner Master Data.';
    END IF;

    IF (VendorCode = 'VPRD0016' AND PaymentTerm NOT IN ('60 Days', '45 Days PDC')) OR (VendorCode <> 'VPRD0016' AND PaymentTerm <> BpPaymentTerm) THEN
        error := -40027;
        error_message := N'Payment term does not match the Business Partner Master record.';
    END IF;

    IF IFNULL(DeliveryTerm,'') NOT IN ('CIF Hazira','CIF Mundra', 'CIF Nhava sheva', 'CIF Pipavav', 'CIP Mundra', 'CIP Nhava Sheva', 'Ex  work', 'CIF Nhavasheva/ Pipavav', 'CIF Nhavasheva/ Mundra', 'CIF Mundra / Pipavav', 'Delivered rate', 'CIP ICD Ahmedabad', 'CFR Nhava Sheva', 'DAP Mundra', 'DAP Vatva', 'DAP HO', 'DAP Saykha', 'CIP Mumbai airport') THEN
        error := -40028;
        error_message := N'Please select a valid Delivery Term.';
    END IF;

    SELECT COUNT(*) INTO TempCounter FROM POR1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND (T0."ItemCode" LIKE 'FA%' OR T0."ItemCode" LIKE 'FU%');
    IF TempCounter > 0 AND IFNULL(TagNumber, '') = '' THEN
        error := -40029;
        error_message := N'Please enter a Tag Number for Fixed Asset items.';
    END IF;

    IF :transaction_type = 'A' AND DocDate >= '2025-11-26' THEN
        SELECT COUNT(T0."ItemCode") INTO TempCounter FROM POR1 T0
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."ItemCode" LIKE '%RM%' AND T0."ItemCode" NOT IN ('PCRM0018', 'PCRM0017', 'SCRM0010', 'OFRM0020', 'OFRM0001' ,'SCRM0016');

        SELECT DISTINCT T0."BaseEntry" INTO BaseDocEntry FROM POR1 T0
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."VisOrder" = 0;

        IF TempCounter > 0 AND IFNULL(BaseDocEntry, -1) = -1 THEN
            error := -40030;
            error_message := 'PO cannot be created without a PR for raw materials.';
        END IF;
    END IF;

END IF;
-- =========================================================================================================
--  Draft Document Validations (Object Type: 112 for PO)
-- =========================================================================================================
IF :object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

    DECLARE DraftObj NVARCHAR(20);
    SELECT T0."ObjType" INTO DraftObj FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

    IF DraftObj = '22' THEN

        -- ========== Variable Declaration ==========
        DECLARE MIN_ROW INT;
        DECLARE MAX_ROW INT;
        DECLARE TempCounter INT;
        DECLARE DaysDifference INT;
        -- Header Level Variables
        DECLARE HeaderBranch INT;
        DECLARE DocCurrency NVARCHAR(10);
        DECLARE VendorCode NVARCHAR(50);
        DECLARE SeriesName NVARCHAR(20);
        DECLARE Suffix NVARCHAR(20);
        DECLARE FooterText NVARCHAR(250);
        DECLARE TagNumber NVARCHAR(5000);
        DECLARE DeliveryTerm NVARCHAR(100);
        DECLARE PaymentTerm NVARCHAR(100);
        DECLARE BpPaymentTerm NVARCHAR(100);
        DECLARE UserCode NVARCHAR(50);
        DECLARE BpBaseDocRequired NVARCHAR(5);
        DECLARE DocDate DATE;
        DECLARE DeliveryDate DATE;
        DECLARE PlaceOfSupply NVARCHAR(100);
        DECLARE ShipToState NVARCHAR(100);

        -- Row Level Variables
        DECLARE ItemCode NVARCHAR(50);
        DECLARE ItemDescription NVARCHAR(250);
        DECLARE MasterItemName NVARCHAR(250);
        DECLARE OcrCode NVARCHAR(50);
        DECLARE TaxCode NVARCHAR(50);
        DECLARE EntryType NVARCHAR(50);
        DECLARE Warehouse NVARCHAR(50);
        DECLARE Project NVARCHAR(50);
        DECLARE BaseDocEntry INT;
        DECLARE BaseDocType INT;
        DECLARE BaseDocBranch INT;
        DECLARE BaseTypeUDF NVARCHAR(50);
        DECLARE BaseDocNumUDF INT;
        DECLARE ItemClass CHAR(1);
        DECLARE PackingType NVARCHAR(100);
        DECLARE PackingCode NVARCHAR(50);
        DECLARE PackingCapacity INT;
        DECLARE HsnEntry INT;
        DECLARE SacEntry INT;
        DECLARE ItemBranch INT;
        DECLARE ItemType NVARCHAR(5);

        -- ========== Data Retrieval (Header) ==========
        SELECT T0."BPLId", T0."DocCur", T0."CardCode", T0."Footer", T0."U_Tag_number", T0."U_Del_Terms",
               T2."PymntGroup", T3."USER_CODE", T4."U_Base_Doc", T0."DocDate", T0."DocDueDate", T5."SeriesName", T5."EndStr"
        INTO HeaderBranch, DocCurrency, VendorCode, FooterText, TagNumber, DeliveryTerm, PaymentTerm, UserCode,
             BpBaseDocRequired, DocDate, DeliveryDate, SeriesName, Suffix
        FROM ODRF T0
        INNER JOIN OCTG T2 ON T0."GroupNum" = T2."GroupNum"
        INNER JOIN OUSR T3 ON T0."UserSign" = T3."USERID"
        INNER JOIN OCRD T4 ON T0."CardCode" = T4."CardCode"
        INNER JOIN NNM1 T5 ON T0."Series" = T5."Series"
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

        SELECT T1."PymntGroup" INTO BpPaymentTerm
        FROM OCRD T0
        INNER JOIN OCTG T1 ON T0."GroupNum" = T1."GroupNum"
        WHERE T0."CardCode" = VendorCode;

        SELECT T2."Name" INTO PlaceOfSupply FROM DRF12 T0 INNER JOIN ODRF T1 ON T0."DocEntry" = T1."DocEntry" LEFT JOIN OCST T2 ON T0."LocStatCod" = T2."Code" WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
        SELECT T2."Name" INTO ShipToState FROM DRF12 T0 INNER JOIN ODRF T1 ON T0."DocEntry" = T1."DocEntry" LEFT JOIN OCST T2 ON T0."StateB" = T2."Code" AND T0."CountryB" = T2."Country" WHERE T1."DocEntry" = :list_of_cols_val_tab_del;

        -- ========== Row Level Validations (Single Loop) ==========
        SELECT MIN(T0."VisOrder"), MAX(T0."VisOrder") INTO MIN_ROW, MAX_ROW FROM DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

        WHILE MIN_ROW <= MAX_ROW DO

            SELECT T0."ItemCode", T0."Dscription", T1."ItemName", T0."OcrCode", T0."TaxCode", T0."U_EntryType", T0."WhsCode",
                   T0."Project", T0."BaseEntry", T0."BaseType", T0."U_BASETYPE", T0."U_BASEDOCNO", T1."ItemClass",
                   T0."U_PTYPE", T0."U_Pcode", T0."Factor1", T0."HsnEntry", T0."SacEntry", T1."ItemType"
            INTO ItemCode, ItemDescription, MasterItemName, OcrCode, TaxCode, EntryType, Warehouse,
                 Project, BaseDocEntry, BaseDocType, BaseTypeUDF, BaseDocNumUDF, ItemClass,
                 PackingType, PackingCode, PackingCapacity, HsnEntry, SacEntry, ItemType
            FROM DRF1 T0
            INNER JOIN OITM T1 ON T0."ItemCode" = T1."ItemCode"
            WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."VisOrder" = MIN_ROW;

            IF IFNULL(OcrCode, '') = '' THEN
                error := -40031;
                error_message := N'Please Select Distribution Rule for item: ' || ItemCode;
            END IF;

            IF DocCurrency <> 'INR' AND TaxCode = 'RIGST18' THEN
                error := -40032;
                error_message := N'Select proper "RIGST18T" Taxcode for import party.';
            END IF;

            SELECT COUNT(*) INTO TempCounter FROM DUMMY
            WHERE ItemCode LIKE '%RM%' OR ItemCode LIKE '%FG%';
            IF IFNULL(EntryType, 'Blank') = 'Blank' AND TempCounter > 0 THEN
                error := -40033;
                error_message := N'Please Select Entry Type (Normal/Trading) at row ' || MIN_ROW + 1;
            END IF;

            IF :transaction_type = 'A' AND ItemCode <> 'EMHA0383' THEN
                IF LENGTH(ItemDescription) <> LENGTH(MasterItemName) THEN
                    error := -40034;
                    error_message := N'You are not allowed to change the Item Name at row ' || MIN_ROW + 1;
                END IF;
            END IF;

            IF EntryType = 'Trading' THEN
                SELECT COUNT(*) INTO TempCounter FROM DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."VisOrder" = MIN_ROW AND T0."WhsCode" NOT LIKE '%TR%';
                IF TempCounter > 0 THEN
                    error := -40035;
                    error_message := N'Please select a TR warehouse for Trading items at row ' || MIN_ROW + 1;
                END IF;
            END IF;

            IF BaseDocType = 1470000113 THEN
                SELECT T1."BPLId" INTO BaseDocBranch FROM OPRQ T1 WHERE T1."DocEntry" = BaseDocEntry;
                IF HeaderBranch <> BaseDocBranch THEN
                    error := -40036;
                    error_message := N'PO and Purchase Request must be of the same Branch.';
                END IF;
            END IF;

            IF HeaderBranch = 3 AND IFNULL(Project, '') = '' THEN
                error := -40037;
                error_message := N'For unit 1 Please select project as corporate or NA at row ' || MIN_ROW + 1;
            END IF;

            IF HeaderBranch = 4 AND (Project = 'Corpo. House' OR Project = 'NA') THEN
                error := -40038;
                error_message := N'For unit 2 do not select project at row ' || MIN_ROW + 1;
            END IF;

            IF HeaderBranch = 5 AND (Project = 'Corpo. House' OR Project = 'NA') THEN
                error := -40039;
                error_message := N'For unit 3 do not select project at row ' || MIN_ROW + 1;
            END IF;

            IF UserCode LIKE '%dispatch%' AND IFNULL(BaseTypeUDF, '') <> 'NA' THEN
                error := -40040;
                error_message := N'select NA as base type at row ' || MIN_ROW + 1;
            END IF;

            IF Suffix LIKE 'SPO%' AND ItemClass = '2' THEN
                error := -40041;
                error_message := N'You have selected a Service Series. Please select a Service item at row ' || MIN_ROW + 1;
            END IF;

            IF Suffix LIKE 'PO%' AND ItemClass = '1' THEN
                error := -40042;
                error_message := N'You have selected a Material Series. Please select a Material item at row ' || MIN_ROW + 1;
            END IF;

            SELECT COUNT(*) INTO TempCounter FROM DUMMY WHERE ItemCode LIKE '%RM%' OR ItemCode LIKE '%FG%' OR ItemCode LIKE '%TR%';
            IF TempCounter > 0 THEN
                IF IFNULL(PackingType, '') = '' THEN
                    error := -40043;
                    error_message := N'Please select Packing for ' || ItemCode || ' at row ' || MIN_ROW + 1;
                END IF;
                IF IFNULL(PackingCode, '') <> '' AND IFNULL(PackingCapacity, 0) <= 1 THEN
                    error := -40044;
                    error_message := N'Please enter valid Packing Capacity for ' || ItemCode || ' at row ' || MIN_ROW + 1;
                END IF;
            END IF;

            IF BaseDocEntry IS NOT NULL THEN
                SELECT DAYS_BETWEEN(T1."DocDate", DocDate) INTO DaysDifference FROM OPRQ T1
                INNER JOIN PRQ1 T2 ON T1."DocEntry" = T2."DocEntry"
                INNER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T2."LineNum" = T3."BaseLine"
                WHERE T3."DocEntry" = :list_of_cols_val_tab_del AND T3."VisOrder" = MIN_ROW;

                IF DaysDifference > 7 AND IFNULL(FooterText, '') = '' THEN
                    error := -40045;
                    error_message := N'Please enter reason of delay PO (Closing remark).';
                END IF;
                IF DaysDifference < 0 THEN
                    error := -40046;
                    error_message := N'PO not allowed to enter less than PR date.';
                END IF;
            END IF;

            IF ItemClass = '1' AND IFNULL(SacEntry, 0) = 0 THEN
                error := -40047;
                error_message := 'SAC Code is mandatory for service items.';
            END IF;

            IF ItemClass = '2' AND IFNULL(HsnEntry, 0) = 0 THEN
                error := -40048;
                error_message := 'HSN Code is mandatory for material items.';
            END IF;

            IF PlaceOfSupply <> ShipToState AND TaxCode NOT LIKE 'IGST%' THEN
                error := -40049;
                error_message := N'For interstate transactions, you must choose an IGST tax code.';
            END IF;

            IF PlaceOfSupply = ShipToState AND TaxCode NOT LIKE 'CS%' THEN
                error := -40050;
                error_message := N'For intrastate transactions, you must choose a CSGST tax code.';
            END IF;

            SELECT T1."BPLid" INTO BaseDocBranch FROM OWHS T1 WHERE T1."WhsCode" = Warehouse;
            IF HeaderBranch <> BaseDocBranch THEN
                error := -40051;
                error_message := N'Please select proper Warehouse at row ' || MIN_ROW + 1;
            END IF;

            IF (ItemCode LIKE 'FA%' AND ItemType = 'F') THEN
                SELECT T1."BPLId" INTO ItemBranch FROM OITM T0
                INNER JOIN OACS T1 ON T0."AssetClass" = T1."Code"
                WHERE T0."ItemCode" = ItemCode;
                IF HeaderBranch <> ItemBranch THEN
                    error := -40066;
                    error_message := N'Fixed Asset branch does not match PO branch for item ' || ItemCode || ' contact SAP team.';
                END IF;
            END IF;

            IF HeaderBranch = 4 THEN
                IF ItemCode LIKE 'PCPM%' AND Warehouse NOT IN ('2EX1PCPM', '2PC-PAC') THEN
                    error := -40067;
                    error_message := N'For packing material, select 2PC-PAC or Extended Packing warehouse at row ' || MIN_ROW + 1;
                END IF;
                IF ItemCode NOT LIKE 'PCPM%' AND Warehouse LIKE '2EX%' THEN
                    error := -40068;
                    error_message := N'Extended warehouse is not allowed for item ' || ItemCode || ' at row ' || MIN_ROW + 1;
                END IF;
            END IF;

            IF BaseDocNumUDF IS NOT NULL THEN
                SELECT COUNT(*) INTO TempCounter FROM POR1 T0
                WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."U_BASEDOCNO" = BaseDocNumUDF AND T0."ItemCode" = ItemCode;
                IF TempCounter > 1 THEN
                    error := -40069;
                    error_message := N'Not allowed to select the same item (' || ItemCode || ') from the same base document twice.';
                END IF;
            END IF;

            MIN_ROW := MIN_ROW + 1;
        END WHILE;

        -- ========== Header/Document Level Validations ==========

        IF :transaction_type = 'A' THEN
            IF (VendorCode LIKE 'VPRI%' OR VendorCode LIKE 'VIRI%' OR VendorCode LIKE 'VSRI%') AND VendorCode NOT IN ('VPRI0014', 'VPRI0020') THEN
                IF DocCurrency = 'INR' THEN
                    error := -40052;
                    error_message := N'Please select a foreign currency for this import vendor.';
                END IF;
                IF SeriesName NOT LIKE 'IM%' THEN
                    error := -40053;
                    error_message := N'Please select an Import series for this vendor.';
                END IF;
            END IF;

            IF DeliveryDate < DocDate THEN
                error := -40054;
                error_message := N'Delivery date cannot be earlier than the document date.';
            END IF;

            SELECT MAX(T0."BaseType") INTO BaseDocType FROM DRF1 T0
            WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."ItemCode" NOT LIKE 'SER%' AND T0."ItemCode" NOT LIKE 'EGSR%' AND T0."ItemCode" NOT LIKE 'SAFE%' AND T0."ItemCode" NOT LIKE '%RM%' AND T0."ItemCode" NOT LIKE '%TR%' AND T0."ItemCode" NOT LIKE '%FG%';
            IF BpBaseDocRequired = 'Y' AND UserCode <> 'dispatch' AND BaseDocType = -1 THEN
                error := -40055;
                error_message := N'Please select a Base Document.';
            END IF;
        END IF;

        SELECT COUNT(T1."Cellolar") INTO TempCounter FROM OCPR T1 WHERE T1."CardCode" = VendorCode;
        IF TempCounter = 0 THEN
            error := -40056;
            error_message := N'Please add a mobile number to the Business Partner Master Data.';
        END IF;

        IF((VendorCode = 'VPRD0016' AND PaymentTerm NOT IN ('60 Days', '45 Days PDC')) OR (VendorCode <> 'VPRD0016' AND PaymentTerm <> BpPaymentTerm)) THEN
            error := -40057;
            error_message := N'Payment term does not match the Business Partner Master record.';
        END IF;

        IF IFNULL(DeliveryTerm,'') NOT IN ('CIF Hazira','CIF Mundra', 'CIF Nhava sheva', 'CIF Pipavav', 'CIP Mundra', 'CIP Nhava Sheva', 'Ex  work', 'CIF Nhavasheva/ Pipavav', 'CIF Nhavasheva/ Mundra', 'CIF Mundra / Pipavav', 'Delivered rate', 'CIP ICD Ahmedabad', 'CFR Nhava Sheva', 'DAP Mundra', 'DAP Vatva', 'DAP HO', 'DAP Saykha', 'CIP Mumbai airport') THEN
            error := -40058;
            error_message := N'Please select a valid Delivery Term.';
        END IF;

        SELECT COUNT(*) INTO TempCounter FROM DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND (T0."ItemCode" LIKE 'FA%' OR T0."ItemCode" LIKE 'FU%');
        IF TempCounter > 0 AND IFNULL(TagNumber, '') = '' THEN
            error := -40059;
            error_message := N'Please enter a Tag Number for Fixed Asset items.';
        END IF;

        IF :transaction_type = 'A' AND DocDate >= '2025-11-26' THEN
            SELECT COUNT(T0."ItemCode") INTO TempCounter FROM DRF1 T0
            WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."ItemCode" LIKE '%RM%' AND T0."ItemCode" NOT IN ('PCRM0018', 'PCRM0017', 'SCRM0010', 'OFRM0020', 'OFRM0001' ,'SCRM0016');

            SELECT DISTINCT T0."BaseEntry" INTO BaseDocEntry FROM DRF1 T0
            WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."VisOrder" = 0;

            IF TempCounter > 0 AND IFNULL(BaseDocEntry, -1) = -1 THEN
                error := -40060;
                error_message := 'PO cannot be created without a PR for raw materials.';
            END IF;
        END IF;

    END IF;
END IF;

-------------------------------------------- END OF PURCHASE ORDER ---------------------------------------------------------

-- =================================================================================================================================
-- SAP B1 Transaction Notification: Purchase Request Validations
-- Refactored and Consolidated Script
-- =================================================================================================================================

-- =================================================================================================================================
-- >> Section 1: Purchase Request Validations (Object Type: 1470000113)
-- =================================================================================================================================
IF :object_type = '1470000113' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

	DECLARE MIN_ROW INT;
	DECLARE MAX_ROW INT;
	DECLARE TEMP_COUNTER INT;
	DECLARE DocBPLId INT;
	DECLARE ItemBPLId INT;
	DECLARE DocSeriesID INT;
	DECLARE ItemCode NVARCHAR(250);
	DECLARE ItemDescription NVARCHAR(250);
	DECLARE MasterItemName NVARCHAR(250);
	DECLARE SeriesName NVARCHAR(250);
	DECLARE TagNo NVARCHAR(250);
	DECLARE OcrCode NVARCHAR(250);
	DECLARE UDF_QC_RD NVARCHAR(250);
	DECLARE UDF_CAPEX_OPEX NVARCHAR(250);
	DECLARE Priority NVARCHAR(10);
	DECLARE DocDate DATE;
	DECLARE ReqDate DATE;
	DECLARE TaxDate DATE;
    DECLARE Typ NVARCHAR(250);
    DECLARE ItemType NVARCHAR(5);

	-- Header-Level Validations
	-----------------------------------------------------------------------------------
	SELECT T0."DocDate", T0."ReqDate", T0."TaxDate"
	INTO DocDate, ReqDate, TaxDate
	FROM OPRQ T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	IF :transaction_type = 'A' THEN
		SELECT DAYS_BETWEEN(:DocDate, NOW()) INTO TEMP_COUNTER FROM DUMMY;
		IF :TEMP_COUNTER > 3 THEN
			error := -41001;
			error_message := N'You are allowed to enter the Posting Date only up to 3 days before today.';
		END IF;
	END IF;

	IF :TaxDate <> :DocDate THEN
		error := -41002;
		error_message := N'Document Date & Posting Date must be the same.';
	END IF;

	IF :ReqDate < :DocDate THEN
		error := -41003;
		error_message := N'Required Date cannot be less than the Posting Date.';
	END IF;

	IF :transaction_type = 'U' THEN
		SELECT DAYS_BETWEEN(T0."DocDate", T0."UpdateDate") INTO TEMP_COUNTER
		FROM OPRQ T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		IF :TEMP_COUNTER > 3 THEN
			error := -41004;
			error_message := N'You are allowed to enter the Posting Date only up to 3 days before today.';
		END IF;
	END IF;

	/*IF :transaction_type = 'U' THEN
		SELECT COUNT(*) INTO TEMP_COUNTER FROM OPRQ T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		IF :TEMP_COUNTER > 0 THEN
			error := -41005;
			error_message := N'You are not allowed to update the Purchase Request as it is already approved.';
		END IF;
	END IF;*/

	SELECT T0."U_Priority" INTO Priority FROM OPRQ T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	IF IFNULL(:Priority, '') = '' THEN
		error := -41006;
		error_message := N'Please select PR Priority.';
	END IF;

	-- Row-Level Validations (Unified Loop)
	-----------------------------------------------------------------------------------
	SELECT T0."BPLId", T1."SeriesName"
	INTO DocBPLId, SeriesName
	FROM OPRQ T0
	INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT MIN(T0."VisOrder"), MAX(T0."VisOrder")
	INTO MIN_ROW, MAX_ROW
	FROM PRQ1 T0
	WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	WHILE :MIN_ROW <= :MAX_ROW DO

		SELECT T1."ItemCode", T1."Dscription", T1."U_TagNo", T1."OcrCode", T1."U_QCRD", T1."U_CapxOpex", T0."ItemName", T0."ItemType"
		INTO ItemCode, ItemDescription, TagNo, OcrCode, UDF_QC_RD, UDF_CAPEX_OPEX, MasterItemName, ItemType
		FROM PRQ1 T1
		LEFT JOIN OITM T0 ON T1."ItemCode" = T0."ItemCode"
		WHERE T1."DocEntry" = :list_of_cols_val_tab_del AND T1."VisOrder" = :MIN_ROW;


		IF LENGTH(:ItemDescription) <> LENGTH(:MasterItemName) THEN
			error := -41007;
			error_message := N'You are not allowed to change the Item Name.';
		END IF;

		IF :transaction_type = 'A' THEN
			IF :ItemCode LIKE 'E%' AND IFNULL(:TagNo, '') = '' THEN
				error := -41008;
				error_message := N'Please enter Tag No for engineering items.';
			END IF;
		END IF;

		IF :transaction_type = 'A' AND :ItemCode LIKE 'E%' THEN
			IF :DocBPLId = 3 AND :SeriesName NOT LIKE 'EG1%' THEN
				error := -41009;
				error_message := N'Please Select EG1 Series for Unit 1.';
			END IF;
			IF :DocBPLId = 4 AND :SeriesName NOT LIKE 'EG2%' THEN
				error := -41010;
				error_message := N'Please Select EG2 Series for Unit 2.';
			END IF;
			IF :DocBPLId = 5 AND :SeriesName NOT LIKE 'EG3%' THEN
				error := -41011;
				error_message := N'Please Select EG3 Series for Unit 3.';
			END IF;
		END IF;

		IF IFNULL(:OcrCode, '') = '' THEN
			error := -41012;
			error_message := N'Please select a Distribution Rule at row - ' || :MIN_ROW+1 ;
		END IF;

		IF (:ItemCode LIKE 'FA%' AND :ItemType = 'F') THEN
			SELECT T1."BPLId" INTO ItemBPLId
			FROM OITM T0
			INNER JOIN OACS T1 ON T0."AssetClass" = T1."Code"
			WHERE T0."ItemCode" = :ItemCode;

			IF (:DocBPLId = 3 AND :ItemBPLId = 4) OR (:DocBPLId = 4 AND :ItemBPLId = 3) THEN
				error := -41013;
				error_message := N'Fixed Asset item ' || :ItemCode || ' belongs to a different branch. Please contact the SAP team.';
			END IF;
		END IF;

		IF :ItemCode LIKE 'LB%' THEN
			IF IFNULL(:UDF_QC_RD, '') IN ('', '-') THEN
				error := -41014;
				error_message := N'For lab items ' || :ItemCode || ', please select whether the request is for the R&D or QC department.';
			END IF;
		END IF;

		IF :SeriesName LIKE 'EG%' THEN

			SELECT COUNT(T0."DocEntry") INTO TEMP_COUNTER FROM OPRQ T0 Inner Join PRQ1 T1 on T0."DocEntry"=T1."DocEntry"
			Inner Join NNM1 T2 on T0."Series"=T2."Series"
			Inner Join OWHS T3 on T1."WhsCode"=T3."WhsCode"
			WHERE ifnull(T1."U_CapxOpex",'')='' and T2."SeriesName" like 'EG%' and T1."VisOrder"=MIN_ROW and T0."DocEntry" = :list_of_cols_val_tab_del;

			(select (case when ifnull("U_CapxOpex",'')='capx' then 'Capex' when ifnull("U_CapxOpex",'')='opex' then 'Opex' end) into Typ from PRQ1 where "DocEntry" = :list_of_cols_val_tab_del and "VisOrder"=MIN_ROW);

			IF IFNULL(:UDF_CAPEX_OPEX, '') = '' THEN
				error := -41015;
				error_message := N'Capex/Opex must be selected for item ' || :ItemCode || ' on row ' || (:MIN_ROW + 1) || '.';
			ELSEIF :TEMP_COUNTER > 0 THEN
				error := -41016;
				error_message := N'Please select '||Typ||' Warehouse at RowNum '||MIN_ROW+1||' For this ItemCode '||ItemCode;
			END IF;
		END IF;

		MIN_ROW := MIN_ROW + 1;
	END WHILE;
END IF;

-- =================================================================================================================================
-- >> Section 2: Purchase Request DRAFT Validations (Object Type: 112)
-- =================================================================================================================================
IF :object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

	DECLARE DraftObjType NVARCHAR(20);
	SELECT T0."ObjType" INTO DraftObjType FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	IF :DraftObjType = '1470000113' THEN

		DECLARE MIN_ROW INT;
		DECLARE MAX_ROW INT;
		DECLARE TEMP_COUNTER INT;
		DECLARE DocBPLId INT;
		DECLARE ItemBPLId INT;
		DECLARE DocSeriesID INT;
		DECLARE ItemCode NVARCHAR(250);
		DECLARE ItemDescription NVARCHAR(250);
		DECLARE MasterItemName NVARCHAR(250);
		DECLARE SeriesName NVARCHAR(250);
		DECLARE TagNo NVARCHAR(250);
		DECLARE OcrCode NVARCHAR(250);
		DECLARE UDF_QC_RD NVARCHAR(250);
		DECLARE UDF_CAPEX_OPEX NVARCHAR(250);
		DECLARE Priority NVARCHAR(10);
		DECLARE DocDate DATE;
		DECLARE ReqDate DATE;
		DECLARE TaxDate DATE;
        DECLARE Typ NVARCHAR(250);
        DECLARE ItemType NVARCHAR(5);

		-- Header-Level Validations
		-----------------------------------------------------------------------------------
		SELECT T0."DocDate", T0."ReqDate", T0."TaxDate"
		INTO DocDate, ReqDate, TaxDate
		FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."ObjType"='1470000113';

		IF :TaxDate <> :DocDate THEN
			error := -41017;
			error_message := N'Document Date & Posting Date must be the same.';
		END IF;

		IF :ReqDate < :DocDate THEN
			error := -41018;
			error_message := N'Required Date cannot be less than the Posting Date.';
		END IF;

        SELECT T0."U_Priority" INTO Priority FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."ObjType"='1470000113';
        IF IFNULL(:Priority, '') = '' THEN
            error := -41029;
            error_message := N'Please select PR Priority.';
        END IF;

        IF :transaction_type = 'A' THEN
            SELECT DAYS_BETWEEN(:DocDate, NOW()) INTO TEMP_COUNTER FROM DUMMY;
            IF :TEMP_COUNTER > 3 THEN
                error := -41030;
                error_message := N'You are allowed to enter the Posting Date only up to 3 days before today.';
            END IF;
        END IF;

		IF :transaction_type = 'U' THEN
			SELECT DAYS_BETWEEN(T0."DocDate", T0."UpdateDate") INTO TEMP_COUNTER
			FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."ObjType"='1470000113';
			IF :TEMP_COUNTER > 3 THEN
				error := -41032;
				error_message := N'You are allowed to enter the Posting Date only up to 3 days before today.';
			END IF;
		END IF;

		-- Row-Level Validations (Unified Loop)
		-----------------------------------------------------------------------------------
		SELECT T0."BPLId", T0."Series"
		INTO DocBPLId, DocSeriesID
		FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."ObjType"='1470000113';

		SELECT T1."SeriesName" INTO SeriesName FROM NNM1 T1 WHERE T1."Series" = :DocSeriesID;

		SELECT MIN(T0."VisOrder"), MAX(T0."VisOrder")
		INTO MIN_ROW, MAX_ROW
		FROM DRF1 T0
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

		WHILE :MIN_ROW <= :MAX_ROW DO
			SELECT T1."ItemCode", T1."Dscription", T1."U_TagNo", T1."OcrCode", T1."U_QCRD", T1."U_CapxOpex", T0."ItemName", T0."ItemType"
			INTO ItemCode, ItemDescription, TagNo, OcrCode, UDF_QC_RD, UDF_CAPEX_OPEX, MasterItemName, ItemType
			FROM DRF1 T1
			LEFT JOIN OITM T0 ON T1."ItemCode" = T0."ItemCode"
			WHERE T1."DocEntry" = :list_of_cols_val_tab_del AND T1."VisOrder" = :MIN_ROW AND T1."ObjType"='1470000113';

			IF LENGTH(:ItemDescription) <> LENGTH(:MasterItemName) THEN
				error := -41019;
				error_message := N'You are not allowed to change the Item Name at row - ' || :MIN_ROW+1;
			END IF;

			IF :transaction_type = 'A' THEN
				IF :ItemCode LIKE 'E%' AND IFNULL(:TagNo, '') = '' THEN
					error := -41020;
					error_message := N'Please enter Tag No for engineering items at row - ' || :MIN_ROW+1;
				END IF;
			END IF;

			IF :transaction_type = 'A' AND :ItemCode LIKE 'E%' THEN
				IF :DocBPLId = 3 AND :SeriesName NOT LIKE 'EG1%' THEN
					error := -41021;
					error_message := N'Please Select EG1 Current Series for Unit 1.';
				END IF;
				IF :DocBPLId = 4 AND :SeriesName NOT LIKE 'EG2%' THEN
					error := -41022;
					error_message := N'Please Select EG2 Series for Unit 2.';
				END IF;
                IF :DocBPLId = 5 AND :SeriesName NOT LIKE 'EG3%' THEN
                    error := -41031;
                    error_message := N'Please Select EG3 Series for Unit 3.';
                END IF;
			END IF;

			IF IFNULL(:OcrCode, '') = '' THEN
				error := -41023;
				error_message := N'Please select a Distribution Rule at row - ' || :MIN_ROW+1;
			END IF;

			IF (:ItemCode LIKE 'FA%' AND :ItemType = 'F') THEN
				SELECT T1."BPLId" INTO ItemBPLId
				FROM OITM T0
				INNER JOIN OACS T1 ON T0."AssetClass" = T1."Code"
				WHERE T0."ItemCode" = :ItemCode;

				IF (:DocBPLId = 3 AND :ItemBPLId = 4) OR (:DocBPLId = 4 AND :ItemBPLId = 3) THEN
					error := -41024;
					error_message := N'Fixed Asset item ' || :ItemCode || ' belongs to a different branch. Please contact the SAP team.';
				END IF;
			END IF;

			IF :ItemCode LIKE 'LB%' THEN
				IF IFNULL(:UDF_QC_RD, '') IN ('', '-') THEN
					error := -41025;
					error_message := N'For lab items ' || :ItemCode || ', please select whether the request is for the R&D or QC department.';
				END IF;
			END IF;

			IF :SeriesName LIKE 'EG%' THEN

				SELECT COUNT(T0."DocEntry") INTO TEMP_COUNTER FROM ODRF T0 Inner Join DRF1 T1 on T0."DocEntry"=T1."DocEntry"
				Inner Join NNM1 T2 on T0."Series"=T2."Series"
				Inner Join OWHS T3 on T1."WhsCode"=T3."WhsCode"
				WHERE ifnull(T1."U_CapxOpex",'')='' and T2."SeriesName" like 'EG%' and T1."VisOrder"=MIN_ROW and T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"='1470000113';

				(select (case when ifnull("U_CapxOpex",'')='capx' then 'Capex' when ifnull("U_CapxOpex",'')='opex' then 'Opex' end) into Typ from DRF1 T0 JOIN ODRF T1 on T0."DocEntry"=T1."DocEntry" where T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder"=MIN_ROW and T1."ObjType"='1470000113');

				IF IFNULL(:UDF_CAPEX_OPEX, '') = '' THEN
					error := -41026;
					error_message := N'Capex/Opex must be selected for item ' || :ItemCode || ' on row ' || (:MIN_ROW + 1) || '.';
				ELSEIF :TEMP_COUNTER > 0 THEN
					error := -41027;
					error_message := N'Please select '||Typ||' Warehouse at RowNum '||MIN_ROW+1||' For this ItemCode '||ItemCode;
				END IF;
			END IF;

			MIN_ROW := MIN_ROW + 1;
		END WHILE;
	END IF;
END IF;

IF Object_type = '30' and (:transaction_type ='A' OR :transaction_type ='U') Then

DECLARE MinJV int;
DECLARE MaxJV int;
DECLARE Drule Nvarchar(250);
DECLARE Accnt Nvarchar(250);
DECLARE TransType int;

	(SELECT min(T0."Line_ID") Into MinJV FROM JDT1 T0 where T0."TransId" = :list_of_cols_val_tab_del);
	(SELECT max(T0."Line_ID") Into MaxJV FROM JDT1 T0 where T0."TransId" = :list_of_cols_val_tab_del);
	WHILE MinJV <= MaxJV
	DO
	(SELECT JDT1."ProfitCode" into Drule FROM JDT1 WHERE JDT1."TransId"=:list_of_cols_val_tab_del AND JDT1."Line_ID"=MinJV);
	(SELECT JDT1."Account" into Accnt FROM JDT1 WHERE JDT1."TransId"=:list_of_cols_val_tab_del AND JDT1."Line_ID"=MinJV);
	(SELECT JDT1."TransType" into TransType FROM JDT1 WHERE JDT1."TransId"=:list_of_cols_val_tab_del AND JDT1."Line_ID"=MinJV);

		IF TransType = 30 then
			IF  Accnt LIKE '4%' OR Accnt LIKE '5%' then
				IF Drule = '' OR Drule IS NULL THEN
					error:=9;
					error_message:=N'Please select distribution rule.';
				END IF;
			END IF;
		END IF;
	 MinJV=MinJV+1;
	END WHILE;
END IF;


IF Object_type = '202' and (:transaction_type ='A' OR :transaction_type = 'U') Then
Declare whse nvarchar(50);
Declare Series nvarchar(50);
DECLARE UsrCod Nvarchar(50);
select OWOR."Warehouse" into whse from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;
select NNM1."SeriesName" into Series from OWOR INNER JOIN NNM1 ON OWOR."Series" = NNM1."Series" where OWOR."DocEntry"= :list_of_cols_val_tab_del;
select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF UsrCod LIKE '%prod05%' THEN
		IF (Series LIKE '%JW%') then
			IF (whse NOT LIKE '%JW%') then
		         error :=14;
		         error_message := N'Please select job work qc wrehouse for job work series';
		     END IF;
		END IF;
	END IF;
END IF;

IF Object_type = '202' and (:transaction_type ='A' OR :transaction_type = 'U') Then
Declare whse nvarchar(50);
Declare Series nvarchar(50);
DECLARE UsrCod Nvarchar(50);
select OWOR."Warehouse" into whse from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;
select NNM1."SeriesName" into Series from OWOR INNER JOIN NNM1 ON OWOR."Series" = NNM1."Series" where OWOR."DocEntry"= :list_of_cols_val_tab_del;
select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF UsrCod IN ('prod04','prod06') THEN
		IF (Series LIKE '%PC%') then
			IF (whse NOT LIKE '%PC%') then
		         error :=14;
		         error_message := N'Please select QC wrehouse for PC series';
		     END IF;
		END IF;
	END IF;
END IF;

IF Object_type = '202' and (:transaction_type ='A' OR :transaction_type = 'U') Then
Declare whse nvarchar(50);
Declare Series nvarchar(50);
DECLARE UsrCod Nvarchar(50);
select OWOR."Warehouse" into whse from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;
select NNM1."SeriesName" into Series from OWOR INNER JOIN NNM1 ON OWOR."Series" = NNM1."Series" where OWOR."DocEntry"= :list_of_cols_val_tab_del;
select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF UsrCod IN ('prod04','prod06') THEN
		IF (whse LIKE '%PC%') then
			IF (Series NOT LIKE '%PC%') then
		         error :=15;
		         error_message := N'Please select pc-qc wrehouse for PC series';
		     END IF;
		END IF;
	END IF;
END IF;

IF Object_type = '202' and (:transaction_type ='A' OR :transaction_type = 'U') Then
Declare whse nvarchar(50);
Declare Series nvarchar(50);
DECLARE UsrCod Nvarchar(50);
select OWOR."Warehouse" into whse from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;
select NNM1."SeriesName" into Series from OWOR INNER JOIN NNM1 ON OWOR."Series" = NNM1."Series" where OWOR."DocEntry"= :list_of_cols_val_tab_del;
select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF UsrCod LIKE '%prod05%' THEN
		IF (whse LIKE '%JW%') then
			IF (Series NOT LIKE '%JW%') then
		         error :=15;
		         error_message := N'Please select job work qc wrehouse for job work series';
		     END IF;
		END IF;
	END IF;
END IF;

IF object_type = '202' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE Series Nvarchar(50);
DECLARE Whse Nvarchar(50);
DECLARE UsrCod Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select NNM1."SeriesName" into Series from OWOR INNER JOIN NNM1 ON OWOR."Series" = NNM1."Series"	where OWOR."DocEntry"= :list_of_cols_val_tab_del;
 	select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF UsrCod LIKE '%prod05%' THEN
		WHILE :MinPRO <= :MaxPRO DO
			SELECT T2."U_UNE_JAPP" into Whse FROM WOR1 T1 INNER JOIN OWHS T2 ON T2."WhsCode" = T1."wareHouse" WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinPRO;
			If (Series LIKE '%JW%') then
				If (whse = 'N') then
		         error :=16;
		         error_message := N'Please select job work warehouse for job work series';
		     	END IF;
			END IF;

			MinPRO := MinPRO + 1;
		END WHILE;
	END IF;
END IF;

IF Object_type = '202' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare OcrCode nvarchar(50);
(Select  count(WOR1."ItemCode") into OcrCode
	from WOR1 inner join OWOR on OWOR."DocEntry"=WOR1."DocEntry" where OWOR."DocEntry"=list_of_cols_val_tab_del and (WOR1."ItemCode" = 'PCPM0094'
		OR WOR1."ItemCode" = 'PCPM0095' OR WOR1."ItemCode" = 'PCPM0096' OR WOR1."ItemCode" = 'PCPM0097' OR WOR1."ItemCode" = 'PCPM0098'));
          IF (OcrCode > 0) then
                  error :=17;
                  error_message := N'Error';
         End If;
End If;

IF Object_type = '202' and (:transaction_type ='A' or :transaction_type ='U' ) Then
DECLARE MinAP Int;
DECLARE MaxAP Int;
Declare OcrCode nvarchar(50);
Declare ItmCode nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinAP from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinAP <= :MaxAP DO
		(Select WOR1 ."OcrCode" into OcrCode from WOR1  where WOR1."DocEntry"=list_of_cols_val_tab_del and WOR1."VisOrder"=MinAP);
		(Select WOR1 ."ItemCode" into ItmCode from WOR1  where WOR1."DocEntry"=list_of_cols_val_tab_del and WOR1."VisOrder"=MinAP);
	          IF (OcrCode = '' OR OcrCode IS NULL) then
	          	error :=20;
	          	error_message := N'Please Select Distr. Rule in Document'||ItmCode;
	         End If;
         MinAP := MinAP+1;
		END WHILE;
End If;

If Object_Type = '202' and (:transaction_type='A') then
Declare PrdSeries  Nvarchar(50);
Declare PrdUser  Nvarchar(50);
select "SeriesName" into PrdSeries From OWOR INNER JOIN NNM1 ON NNM1."Series" = OWOR."Series" where "DocEntry"= :list_of_cols_val_tab_del;
select OUSR."USER_CODE" into PrdUser from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"= :list_of_cols_val_tab_del;

		if PrdUser NOT LIKE '%prod01%' and PrdSeries LIKE 'SC%' then
        	error :=21;
        	error_message := N'You are not allowed to select SC Series1';
		end if;
end if;

If Object_Type = '59' and (:transaction_type='A' ) then
Declare PrdSeries  Nvarchar(50);
Declare PrdUser  Nvarchar(50);
select "SeriesName" into PrdSeries From OIGN INNER JOIN NNM1 ON NNM1."Series" = OIGN."Series" where OIGN."DocEntry"= :list_of_cols_val_tab_del;
select OUSR."USER_CODE" into PrdUser from OIGN INNER JOIN OUSR ON OUSR."USERID" = OIGN."UserSign" where OIGN."DocEntry"= :list_of_cols_val_tab_del;

		if PrdUser NOT LIKE '%prod01%' and PrdSeries LIKE 'SC%' then
        	error :=22;
        	error_message := N'You are not allowed to select SC Series1';
		end if;
end if;

IF object_type = '60' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE PMGI Nvarchar(50);
DECLARE PMQTY decimal;

	SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGI <= :MaxGI DO
		SELECT IGE1."ItemCode" into PMGI FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
		SELECT SUBSTR_AFTER(IGE1."Quantity",'.') into PMQTY FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
		IF PMGI LIKE '%PM%' then
			IF 	PMQTY > 0 then
				error :=23;
				error_message := N'Decimal not allowed for Packing';
			END IF;
		END IF;
		MinGI := MinGI+1;
	END WHILE;
END IF;

IF Object_type = '60' and (:transaction_type ='U' ) Then

DECLARE MinGI Int;
DECLARE MaxGI Int;
Declare ICGI nvarchar(50);
Declare ChallanNo1 nvarchar(50);
Declare ChallanNo2 nvarchar(50);
Declare ChallanNo3 nvarchar(50);
Declare ChallanQty1 nvarchar(50);
Declare ChallanQty2 nvarchar(50);
Declare ChallanQty3 nvarchar(50);
Declare OvrQty1 nvarchar(50);
Declare OvrQty11 nvarchar(50);
Declare OvrQty111 nvarchar(50);
Declare OvrQty2 nvarchar(50);
Declare OvrQty22 nvarchar(50);
Declare OvrQty222 nvarchar(50);
Declare OvrQty3 nvarchar(50);
Declare OvrQty33 nvarchar(50);
Declare OvrQty333 nvarchar(50);
Declare Qtty1 nvarchar(50);
Declare Qtty2 nvarchar(50);
Declare Qtty3 nvarchar(50);
Declare SName nvarchar(50);
Declare ICode nvarchar(50);
Declare DateJb nvarchar(50);
Declare JWDate1 date;
Declare JWDate2 date;
Declare JWDate3 date;

		SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		select NNM1."SeriesName" into SName from OIGE INNER JOIN NNM1 ON NNM1."Series" = OIGE."Series" WHERE OIGE."DocEntry" = list_of_cols_val_tab_del;
		select OIGE."DocDate" into DateJb from OIGE WHERE OIGE."DocEntry" = list_of_cols_val_tab_del;

		WHILE :MinGI <= :MaxGI
		DO
			select "ItemCode" into ICGI from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del
				and IGE1."VisOrder"=MinGI;

			select ifnull("U_JobChallan1",0) into ChallanNo1 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del
				and IGE1."VisOrder"=MinGI;
			select "U_JWDate" into JWDate1 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

			IF 	ChallanNo1 > 0 THEN
				IF JWDate1 >= '20210401' then
					select "U_JobChallan1" into ChallanNo1 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del
						and IGE1."VisOrder"=MinGI;
				else
					IF length(ChallanNo1) = 3 THEN
						select concat('30',IGE1."U_JobChallan1") into ChallanNo1 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del
						and IGE1."VisOrder"=MinGI;
					else
						select "U_JobChallan1" into ChallanNo1 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del
						and IGE1."VisOrder"=MinGI;
					END IF;
				end if;
			END IF;
			select ifnull("U_JWQty1",0) into ChallanQty1 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI and IGE1."ItemCode" = ICGI;

			select ifnull("U_JobChallan2",0) into ChallanNo2 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			select "U_JWDate2" into JWDate2 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

			IF 	ChallanNo2 > 0 THEN
				IF JWDate2 >= '20210401' then
					select "U_JobChallan2" into ChallanNo2 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del
						and IGE1."VisOrder"=MinGI;
				else
					IF length(ChallanNo2) = 3 THEN
						select concat('30',IGE1."U_JobChallan2") into ChallanNo2 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del
						and IGE1."VisOrder"=MinGI;
					else
						select "U_JobChallan2" into ChallanNo2 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del
						and IGE1."VisOrder"=MinGI;
					END IF;
				end if;


			END IF;
			select ifnull("U_JWQty2",0) into ChallanQty2 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI and IGE1."ItemCode" = ICGI;

			select ifnull("U_JobChallan3",0) into ChallanNo3 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			select "U_JWDate3" into JWDate3 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

			IF 	ChallanNo3 > 0 THEN
				IF JWDate3 >= '20210401' then
					select "U_JobChallan3" into ChallanNo3 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del
						and IGE1."VisOrder"=MinGI;
				elseIF length(ChallanNo3) = 3 THEN
					select concat('30',IGE1."U_JobChallan3") into ChallanNo3 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del
						and IGE1."VisOrder"=MinGI;
				else
					select "U_JobChallan3" into ChallanNo3 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del
						and IGE1."VisOrder"=MinGI;
				end if;
			END IF;
			select ifnull("U_JWQty3",0) into ChallanQty3 from IGE1 WHERE IGE1."DocEntry" = list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI and IGE1."ItemCode" = ICGI;

			IF 	ChallanNo1 <> 0 THEN
				IF JWDate1 >= '20220401' then
					IF ChallanNo1 LIKE '20%' then
						Select PDN1."Quantity" into Qtty1 from PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry"
						WHERE OPDN."DocNum" = ChallanNo1 and OPDN."DocDate" >= '20220401' and PDN1."VisOrder" = 0;
					ELSEIF ChallanNo1 LIKE '10%' then
						Select WTR1."Quantity" into Qtty1 from WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry"
						WHERE OWTR."DocNum" = ChallanNo1 and OWTR."DocDate" >= '20220401';
					END IF;
				ELSEIF JWDate1 >= '20210401' then
					IF ChallanNo1 LIKE '30%' then
						Select PDN1."Quantity" into Qtty1 from PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry"
						WHERE OPDN."DocNum" = ChallanNo1 and OPDN."DocDate" >= '20210401' and PDN1."VisOrder" = 0;
					ELSEIF ChallanNo1 LIKE '40%' then
						Select WTR1."Quantity" into Qtty1 from WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry"
						WHERE OWTR."DocNum" = ChallanNo1 and OWTR."DocDate" >= '20210401';
					END IF;
				else
					IF ChallanNo1 LIKE '40%'  then
						Select PDN1."Quantity" into Qtty1 from PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry"
						WHERE OPDN."DocNum" = ChallanNo1 and OPDN."DocDate" < '20210401' and PDN1."VisOrder" = 0;
					ELSEIF ChallanNo1 LIKE '30%'  then
						Select WTR1."Quantity" into Qtty1 from WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry"
						WHERE OWTR."DocNum" = ChallanNo1 and OWTR."DocDate" < '20210401';
					END IF;
				end if;
			END IF;
			IF 	ChallanNo2 <> 0 THEN
				IF JWDate2 >= '20220401' then
					IF ChallanNo2 LIKE '20%' then
						Select PDN1."Quantity" into Qtty2 from PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry"
						 WHERE OPDN."DocNum" = ChallanNo2 and OPDN."DocDate" >= '20220401' and PDN1."VisOrder" = 0;
					ELSEIF ChallanNo2 LIKE '10%' then
						Select WTR1."Quantity" into Qtty2 from WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry"
						WHERE OWTR."DocNum" = ChallanNo2 and OWTR."DocDate" >= '20220401';
					END IF;
				ELSEIF JWDate2 >= '20210401' then
					IF ChallanNo2 LIKE '30%' then
						Select PDN1."Quantity" into Qtty2 from PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry"
						 WHERE OPDN."DocNum" = ChallanNo2 and OPDN."DocDate" >= '20210401' and PDN1."VisOrder" = 0;
					ELSEIF ChallanNo2 LIKE '40%' then
						Select WTR1."Quantity" into Qtty2 from WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry"
						WHERE OWTR."DocNum" = ChallanNo2 and OWTR."DocDate" >= '20210401';
					END IF;
				else
					IF ChallanNo2 LIKE '40%' then
						Select PDN1."Quantity" into Qtty2 from PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry"
						 WHERE OPDN."DocNum" = ChallanNo2 and OPDN."DocDate" < '20210401';
					ELSEIF ChallanNo2 LIKE '30%' then
						Select WTR1."Quantity" into Qtty2 from WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry"
						WHERE OWTR."DocNum" = ChallanNo2 and OWTR."DocDate" < '20210401';
					END IF;
				end if;
			END IF;
			IF 	ChallanNo3 <> 0 THEN
				IF JWDate3 >= '20220401' then
					IF ChallanNo3 LIKE '20%' then
						Select PDN1."Quantity" into Qtty3 from PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry"
						 WHERE OPDN."DocNum" = ChallanNo3 and OPDN."DocDate" >= '20220401' and PDN1."VisOrder" = 0;
					ELSEIF ChallanNo3 LIKE '10%'  then
						Select WTR1."Quantity" into Qtty3 from WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry"
						WHERE OWTR."DocNum" = ChallanNo3 and OWTR."DocDate" >= '20220401' and WTR1."VisOrder" = 0;
					END IF;
				ELSEIF JWDate3 >= '20210401' then
					IF ChallanNo3 LIKE '30%' then
						Select PDN1."Quantity" into Qtty3 from PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry"
						 WHERE OPDN."DocNum" = ChallanNo3 and OPDN."DocDate" >= '20210401' and PDN1."VisOrder" = 0;
					ELSEIF ChallanNo3 LIKE '40%' then
						Select WTR1."Quantity" into Qtty3 from WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry"
						WHERE OWTR."DocNum" = ChallanNo3 and OWTR."DocDate" >= '20210401' and WTR1."VisOrder" = 0;
					END IF;
				else
					IF ChallanNo3 LIKE '40%' then
						Select PDN1."Quantity" into Qtty3 from PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry"
						 WHERE OPDN."DocNum" = ChallanNo3 and OPDN."DocDate" < '20210401';
					ELSEIF ChallanNo3 LIKE '30%' then
						Select WTR1."Quantity" into Qtty3 from WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry"
						WHERE OWTR."DocNum" = ChallanNo3 and OWTR."DocDate" < '20210401';
					END IF;
				end if;
			END IF;
			select ifnull(SUM("U_JWQty1"),0) into OvrQty1 from IGE1 WHERE (IGE1."U_JobChallan1" = ChallanNo1) and IGE1."ItemCode" = ICGI;
			select ifnull(SUM("U_JWQty2"),0) into OvrQty11 from IGE1 WHERE (IGE1."U_JobChallan2" = ChallanNo1) and IGE1."ItemCode" = ICGI;
			select ifnull(SUM("U_JWQty3"),0) into OvrQty111 from IGE1 WHERE (IGE1."U_JobChallan3" = ChallanNo1) and IGE1."ItemCode" = ICGI;

			select ifnull(SUM("U_JWQty1"),0) into OvrQty2 from IGE1 WHERE (IGE1."U_JobChallan1" = ChallanNo2) and IGE1."ItemCode" = ICGI;
			select ifnull(SUM("U_JWQty2"),0) into OvrQty22 from IGE1 WHERE (IGE1."U_JobChallan2" = ChallanNo2) and IGE1."ItemCode" = ICGI;
			select ifnull(SUM("U_JWQty3"),0) into OvrQty222 from IGE1 WHERE (IGE1."U_JobChallan3" = ChallanNo2) and IGE1."ItemCode" = ICGI;


			select ifnull(SUM("U_JWQty1"),0) into OvrQty3 from IGE1 WHERE (IGE1."U_JobChallan1" = ChallanNo3) and IGE1."ItemCode" = ICGI;
			select ifnull(SUM("U_JWQty2"),0) into OvrQty33 from IGE1 WHERE (IGE1."U_JobChallan2" = ChallanNo3) and IGE1."ItemCode" = ICGI;
			select ifnull(SUM("U_JWQty3"),0) into OvrQty333 from IGE1 WHERE (IGE1."U_JobChallan3" = ChallanNo3) and IGE1."ItemCode" = ICGI;


			IF Qtty1 IS NOT NULL THEN
				IF Qtty1 < (OvrQty1+OvrQty11+OvrQty111) THEN
					error :=24;
					error_message := N'Error1 : Code : '||ICGI||' , Used quantity : '||OvrQty1 || '2nd : ' || OvrQty11 || '3rd : ' ||OvrQty111 ||' , Entry Quantity :  '||ChallanQty1||' , Challan quantity : '||Qtty1;
				END IF;
			END IF;
			IF Qtty2 IS NOT NULL THEN
				IF Qtty2 < (OvrQty2+OvrQty22+OvrQty222) THEN
					error :=24;
					error_message := N'Error2 : Code : '||ICGI||' , Used quantity : '||(OvrQty2+OvrQty22+OvrQty222) ||' , Entry Quantity :  '||ChallanQty2||' , Challan quantity : '||Qtty2;
				END IF;
			END IF;
			IF Qtty3 IS NOT NULL THEN
				IF Qtty3 < (OvrQty3+OvrQty33+OvrQty333) THEN
					error :=24;
					error_message := N'Error3 : Code : '||ICGI||' , Used quantity : '||(OvrQty3+OvrQty33+OvrQty333) ||' , Entry Quantity :  '||ChallanQty3||' , Challan quantity : '||Qtty3;
				END IF;
			END IF;
	    MinGI := MinGI+1;
		END WHILE;
End If;

IF object_type = '60' AND (:transaction_type = 'A' ) THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE JWDate Nvarchar(50);
DECLARE JWDate2 Nvarchar(50);
DECLARE Code Nvarchar(50);
DECLARE JWDate3 Nvarchar(50);
DECLARE JWChallan1 Int;
DECLARE JWChallan2 Int;
DECLARE JWChallan3 Int;

	SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

		WHILE :MinGI<= :MaxGI DO
			SELECT IGE1."ItemCode" into Code FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

			SELECT sum(IGE1."U_JobChallan1") into JWChallan1 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT IGE1."U_JWDate" into JWDate FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

			SELECT sum(IGE1."U_JobChallan2") into JWChallan2 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT IGE1."U_JWDate2" into JWDate2 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

			SELECT sum(IGE1."U_JobChallan3") into JWChallan3 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT IGE1."U_JWDate3" into JWDate3 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

			IF Code <> 'PCRM0017' then
				IF JWChallan1 > 0  then
					IF JWDate = '' OR JWDate IS NULL THEN
						error :=25;
						error_message := N'Please enter our job work challan date1.'||MinGI;
					END IF;
				END IF;
				IF JWChallan2 > 0 then
					IF JWDate2 = '' OR JWDate2 IS NULL THEN
						error :=25;
						error_message := N'Please enter our job work challan date2.'||MinGI;
					END IF;
				END IF;
				IF JWChallan3 > 0 then
					IF JWDate3 = '' OR JWDate3 IS NULL THEN
						error :=25;
						error_message := N'Please enter our job work challan date3.'||MinGI;
					END IF;
				END IF;
			END IF;
			MinGI := MinGI+1;
		END WHILE;
END IF;

IF object_type = '60' AND (:transaction_type = 'A' ) THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE JWQty1 Nvarchar(50);
DECLARE JWQty2 Nvarchar(50);
DECLARE JWQty3 Nvarchar(50);
DECLARE JWChallan1 Int;
DECLARE JWChallan2 Int;
DECLARE JWChallan3 Int;

	SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

		WHILE :MinGI<= :MaxGI DO
			SELECT Count(IGE1."U_JobChallan1") into JWChallan1 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT IGE1."U_JWQty1" into JWQty1 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

			SELECT Count(IGE1."U_JobChallan2") into JWChallan2 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT IGE1."U_JWQty2" into JWQty2 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

			SELECT Count(IGE1."U_JobChallan3") into JWChallan3 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT IGE1."U_JWQty3" into JWQty3 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

			IF JWChallan1 > 0  then
				IF JWQty1 = '' OR JWQty1 IS NULL THEN
					error :=26;
					error_message := N'Please enter our job work challan qty1.'||MinGI;
				END IF;
			END IF;
			IF JWChallan2 > 0  then
				IF JWQty2 = '' OR JWQty2 IS NULL THEN
					error :=26;
					error_message := N'Please enter our job work challan qty2.'||MinGI;
				END IF;
			END IF;
			IF JWChallan3 > 0  then
				IF JWQty3 = '' OR JWQty3 IS NULL THEN
					error :=26;
					error_message := N'Please enter our job work challan qty3.'||MinGI;
				END IF;
			END IF;
			MinGI := MinGI+1;
		END WHILE;
END IF;
----------------------Goods issue-------------------
----------------UNIT-I
/*IF object_type = '60' AND (:transaction_type = 'A') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE WhsGI Nvarchar(50);
DECLARE ItemGI Nvarchar(50);
DECLARE SeriesGI Nvarchar(50);
DECLARE VNoGI Nvarchar(50);
DECLARE CNoGI Nvarchar(50);
DECLARE Branch Nvarchar(50);
DECLARE JrnlMemo Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT "BPLName" INTO Branch FROM OIGE where OIGE."DocEntry" =:list_of_cols_val_tab_del;
	SELECT "JrnlMemo" INTO JrnlMemo FROM OIGE where OIGE."DocEntry" =:list_of_cols_val_tab_del;

	IF Branch = 'UNIT - I' AND JrnlMemo = 'Goods Issue' THEN

	WHILE :MinGI<= :MaxGI DO
		SELECT IGE1."WhsCode" into WhsGI FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
		SELECT IGE1."ItemCode" into ItemGI FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
		SELECT T0."SeriesName" into SeriesGI FROM NNM1 T0 INNER JOIN OIGE T1 ON T0."Series" = T1."Series" WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
		SELECT OIGE."U_UNE_CHNO" into VNoGI FROM OIGE WHERE OIGE."DocEntry" = :list_of_cols_val_tab_del;
		SELECT OIGE."U_UNE_VehicleNo" into CNoGI FROM OIGE WHERE OIGE."DocEntry" = :list_of_cols_val_tab_del;

		IF ItemGI LIKE '%FG%' and ItemGI <> 'PCFG0247' and SeriesGI NOT LIKE 'BT%' THEN
			IF WhsGI NOT LIKE '%FG%' and WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%DE%' and WhsGI NOT LIKE '%TRD%' THEN
				error :=2701;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
		END IF;
		IF ItemGI LIKE '%RM%' and SeriesGI NOT LIKE 'BT%' and ItemGI <> 'SCRM0016' THEN
			IF WhsGI NOT LIKE '%RAW%' and WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%AP%' and WhsGI NOT LIKE '%DE%' THEN
				error :=2702;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
		END IF;
		IF ItemGI LIKE '%PM%' and SeriesGI NOT LIKE 'BT%' and ItemGI <> 'SCPM0018' THEN
			IF WhsGI NOT LIKE '%PAC%' and WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%AP%'  and WhsGI NOT LIKE '%DE%' and WhsGI NOT LIKE '%RSC%' THEN
				error :=2703;
				error_message := N'Please Enter Proper Warehouse..PM';
			END IF;
		END IF;
		IF SeriesGI LIKE  '%JW%' and  ItemGI <> 'PCRM0017' THEN
			IF WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%AP%' and WhsGI NOT LIKE '%DE%' and WhsGI NOT LIKE '%RSC%' THEN
				error :=2704;
				error_message := N'Please Enter Proper Warehouse..JW';
			END IF;
		END IF;
		MinGI := MinGI+1;
	END WHILE;
	END IF;
END IF;*/
------------------Issue for prodcution-------
----------Unit-I--------

/*IF object_type = '60' AND (:transaction_type = 'A') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE WhsGI Nvarchar(50);
DECLARE ItemGI Nvarchar(50);
DECLARE SeriesGI Nvarchar(50);
DECLARE VNoGI Nvarchar(50);
DECLARE CNoGI Nvarchar(50);
DECLARE Branch Nvarchar(50);
DECLARE JrnlMemo Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT "BPLName" INTO Branch FROM OIGE where OIGE."DocEntry" =:list_of_cols_val_tab_del;
	SELECT "JrnlMemo" INTO JrnlMemo FROM OIGE where OIGE."DocEntry" =:list_of_cols_val_tab_del;

	IF Branch = 'UNIT - I' AND JrnlMemo = 'Issue for Production' THEN

	WHILE :MinGI<= :MaxGI DO
		SELECT IGE1."WhsCode" into WhsGI FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
		SELECT IGE1."ItemCode" into ItemGI FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
		SELECT T0."SeriesName" into SeriesGI FROM NNM1 T0 INNER JOIN OIGE T1 ON T0."Series" = T1."Series" WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
		SELECT OIGE."U_UNE_CHNO" into VNoGI FROM OIGE WHERE OIGE."DocEntry" = :list_of_cols_val_tab_del;
		SELECT OIGE."U_UNE_VehicleNo" into CNoGI FROM OIGE WHERE OIGE."DocEntry" = :list_of_cols_val_tab_del;

		IF ItemGI LIKE '%FG%' and ItemGI <> 'PCFG0247' and SeriesGI NOT LIKE 'BT%' THEN
			IF WhsGI NOT LIKE '%FG%' and WhsGI NOT LIKE 'PC-QCR' and  WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%DE%' and WhsGI NOT LIKE '%TRD%' THEN
				error :=27011;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
		END IF;
		IF ItemGI LIKE '%RM%' and SeriesGI NOT LIKE 'BT%' and ItemGI <> 'SCRM0016' THEN
			IF WhsGI NOT LIKE '%RAW%' and WhsGI NOT LIKE 'PC-QCR' and WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%AP%' and WhsGI NOT LIKE '%DE%' THEN
				error :=27021;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
		END IF;
		IF ItemGI LIKE '%PM%' and SeriesGI NOT LIKE 'BT%' and ItemGI <> 'SCPM0018' THEN
			IF WhsGI NOT LIKE '%PAC%' and WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%AP%'  and WhsGI NOT LIKE '%DE%' and WhsGI NOT LIKE '%RSC%' THEN
				error :=27031;
				error_message := N'Please Enter Proper Warehouse..PM';
			END IF;
		END IF;
		IF SeriesGI LIKE  '%JW%' and  ItemGI <> 'PCRM0017' THEN
			IF WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%AP%' and WhsGI NOT LIKE '%DE%' and WhsGI NOT LIKE '%RSC%' THEN
				error :=27041;
				error_message := N'Please Enter Proper Warehouse..JW';
			END IF;
		END IF;
		MinGI := MinGI+1;
	END WHILE;
	END IF;
END IF;*/


-------------2PC-FLOR
----------------UNIT-II-----Goods issue------

IF object_type = '60' AND (:transaction_type = 'A') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE WhsGI Nvarchar(50);
DECLARE ItemGI Nvarchar(50);
DECLARE SeriesGI Nvarchar(50);
DECLARE VNoGI Nvarchar(50);
DECLARE CNoGI Nvarchar(50);
DECLARE Branch Nvarchar(50);
DECLARE JrnlMemo Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT "BPLName" INTO Branch FROM OIGE where OIGE."DocEntry" =:list_of_cols_val_tab_del;
	SELECT "JrnlMemo" INTO JrnlMemo FROM OIGE where OIGE."DocEntry" =:list_of_cols_val_tab_del;

	IF Branch = 'UNIT - II' AND JrnlMemo = 'Goods Issue' THEN

	WHILE :MinGI<= :MaxGI DO
		SELECT IGE1."WhsCode" into WhsGI FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
		SELECT IGE1."ItemCode" into ItemGI FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
		SELECT T0."SeriesName" into SeriesGI FROM NNM1 T0 INNER JOIN OIGE T1 ON T0."Series" = T1."Series" WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
		SELECT OIGE."U_UNE_CHNO" into VNoGI FROM OIGE WHERE OIGE."DocEntry" = :list_of_cols_val_tab_del;
		SELECT OIGE."U_UNE_VehicleNo" into CNoGI FROM OIGE WHERE OIGE."DocEntry" = :list_of_cols_val_tab_del;

		IF ItemGI LIKE '%FG%' and ItemGI <> 'PCFG0247' and SeriesGI NOT LIKE 'BT%' THEN
			IF WhsGI NOT LIKE '%FG%' and WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%DE%' and WhsGI NOT LIKE '%TRD%' THEN
				error :=27021;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
		END IF;
		IF ItemGI LIKE '%RM%' and SeriesGI NOT LIKE 'BT%' and ItemGI <> 'SCRM0016' THEN
			IF WhsGI NOT LIKE '%RAW%' and WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%AP%' and WhsGI NOT LIKE '%DE%' THEN
				error :=27022;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
		END IF;
		IF ItemGI LIKE '%PM%' and SeriesGI NOT LIKE 'BT%' and ItemGI <> 'SCPM0018' THEN
			IF WhsGI NOT LIKE '%PAC%' and WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%AP%'  and WhsGI NOT LIKE '%DE%' and WhsGI NOT LIKE '%RSC%' THEN
				error :=27023;
				error_message := N'Please Enter Proper Warehouse..PM';
			END IF;
		END IF;
		IF SeriesGI LIKE  '%JW%' and  ItemGI <> 'PCRM0017' THEN
			IF WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%AP%' and WhsGI NOT LIKE '%DE%' and WhsGI NOT LIKE '%RSC%' THEN
				error :=27024;
				error_message := N'Please Enter Proper Warehouse..JW';
			END IF;
		END IF;
		MinGI := MinGI+1;
	END WHILE;
	END IF;
END IF;

----------------UNIT-II -----issue for production------
IF object_type = '60' AND (:transaction_type = 'A') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE WhsGI Nvarchar(50);
DECLARE ItemGI Nvarchar(50);
DECLARE SeriesGI Nvarchar(50);
DECLARE VNoGI Nvarchar(50);
DECLARE CNoGI Nvarchar(50);
DECLARE Branch Nvarchar(50);
DECLARE JrnlMemo Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT "BPLName" INTO Branch FROM OIGE where OIGE."DocEntry" =:list_of_cols_val_tab_del;
	SELECT "JrnlMemo" INTO JrnlMemo FROM OIGE where OIGE."DocEntry" =:list_of_cols_val_tab_del;

	IF Branch = 'UNIT - II' AND JrnlMemo = 'Issue for Production' THEN

	WHILE :MinGI<= :MaxGI DO
		SELECT IGE1."WhsCode" into WhsGI FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
		SELECT IGE1."ItemCode" into ItemGI FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
		SELECT T0."SeriesName" into SeriesGI FROM NNM1 T0 INNER JOIN OIGE T1 ON T0."Series" = T1."Series" WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
		SELECT OIGE."U_UNE_CHNO" into VNoGI FROM OIGE WHERE OIGE."DocEntry" = :list_of_cols_val_tab_del;
		SELECT OIGE."U_UNE_VehicleNo" into CNoGI FROM OIGE WHERE OIGE."DocEntry" = :list_of_cols_val_tab_del;

		IF ItemGI LIKE '%FG%' and ItemGI <> 'PCFG0247' and SeriesGI NOT LIKE 'BT%' THEN
			IF WhsGI NOT LIKE '2PC-FLOR' and WhsGI NOT LIKE '2PC-QCR' and WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%DE%' and WhsGI NOT LIKE '%TRD%' THEN
				error :=27031;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
		END IF;
		IF ItemGI LIKE '%RM%' and SeriesGI NOT LIKE 'BT%' and ItemGI <> 'SCRM0016' THEN
			IF WhsGI NOT LIKE '2PC-FLOR' and WhsGI NOT LIKE '2PC-QCR' and WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%AP%' and WhsGI NOT LIKE '%DE%' THEN
				error :=27032;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
		END IF;
		IF ItemGI LIKE '%PM%' and SeriesGI NOT LIKE 'BT%' and ItemGI <> 'SCPM0018' THEN
			IF WhsGI NOT LIKE '%PAC%' and WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%AP%'  and WhsGI NOT LIKE '%DE%' and WhsGI NOT LIKE '%RSC%' THEN
				error :=27033;
				error_message := N'Please Enter Proper Warehouse..PM';
			END IF;
		END IF;
		IF SeriesGI LIKE  '%JW%' and  ItemGI <> 'PCRM0017' THEN
			IF WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%AP%' and WhsGI NOT LIKE '%DE%' and WhsGI NOT LIKE '%RSC%' THEN
				error :=27034;
				error_message := N'Please Enter Proper Warehouse..JW';
			END IF;
		END IF;
		MinGI := MinGI+1;
	END WHILE;
	END IF;
END IF;

--------------------------------------------------------------------

IF Object_type = '60' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare ItemCode nvarchar(50);
DECLARE MinGI Nvarchar(50);
DECLARE MaxGI Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE MinGI<=MaxGI DO
		(Select IGE1."ItemCode" into ItemCode from IGE1 WHERE IGE1."DocEntry"=list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI);
          IF (ItemCode LIKE 'E%' ) then
                  error :=28;
                  error_message := N'Not allowed..';
         End If;
    	MinGI := MinGI+1;
	END WHILE;
End If;

If Object_Type = '60' and (:transaction_type='A' ) then
Declare PrdSeries  Nvarchar(50);
Declare PrdUser  Nvarchar(50);
select "SeriesName" into PrdSeries From OIGE INNER JOIN NNM1 ON NNM1."Series" = OIGE."Series" where OIGE."DocEntry"= :list_of_cols_val_tab_del;
select OUSR."USER_CODE" into PrdUser from OIGE INNER JOIN OUSR ON OUSR."USERID" = OIGE."UserSign" where OIGE."DocEntry"= :list_of_cols_val_tab_del;

		if PrdUser NOT LIKE '%prod01%' and PrdSeries LIKE 'DI%' then
        	error :=29;
        	error_message := N'You are not allowed to select DI Series1';
		end if;
end if;

IF Object_type = '202' and (:transaction_type ='A' OR :transaction_type = 'U') Then

DECLARE CompleteQty Int;
DECLARE PlanndQty Int;
DECLARE ItemCodePR Nvarchar(50);
select OWOR."PlannedQty" into PlanndQty from OWOR where OWOR."DocEntry"= :list_of_cols_val_tab_del;
select OWOR."CmpltQty" into CompleteQty from OWOR where OWOR."DocEntry"= :list_of_cols_val_tab_del;
select OWOR."ItemCode" into ItemCodePR from OWOR where OWOR."DocEntry"= :list_of_cols_val_tab_del;

	IF ItemCodePR LIKE 'PC%' THEN
		If CompleteQty > PlanndQty then
	         error :=30;
	         error_message := N'Complete quantity may more than planned..';
	     END IF;
	END IF;
END IF;

IF Object_type = '202' and (:transaction_type ='A' OR :transaction_type = 'U') Then

DECLARE CompleteQty decimal;
DECLARE PlanndQty decimal;
DECLARE ItemCodePR Nvarchar(50);

select OWOR."PlannedQty" + 550 into PlanndQty from OWOR where OWOR."DocEntry"= :list_of_cols_val_tab_del;
select OWOR."CmpltQty" into CompleteQty from OWOR where OWOR."DocEntry"= :list_of_cols_val_tab_del;
select OWOR."ItemCode" into ItemCodePR from OWOR where OWOR."DocEntry"= :list_of_cols_val_tab_del;

	IF ItemCodePR LIKE 'SC%' THEN
		If CompleteQty > PlanndQty then
	         error :=31;
	         error_message := N'Something went wrong'||PlanndQty;
	     END IF;
	END IF;
END IF;

IF Object_type = '202' and (:transaction_type ='A' OR :transaction_type = 'U') Then

Declare Compltqty int;
Declare issueqty int;
Declare Itemcde nvarchar(50);

select OWOR."ItemCode" into Itemcde from OWOR where OWOR."DocEntry"= :list_of_cols_val_tab_del;
select OWOR."CmpltQty" into Compltqty from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"= :list_of_cols_val_tab_del;
select SUM(WOR1."IssuedQty") into issueqty from WOR1 where WOR1."DocEntry"= :list_of_cols_val_tab_del and WOR1."ItemCode" NOT LIKE 'PCPM%';

	IF Itemcde LIKE 'PC%' THEN
		If (Compltqty>issueqty) then
	         error :=320011;
	         error_message := N'Completed Qty not allowed more than issued Qty'|| Compltqty || '  ' || issueqty;
		END IF;
	END IF;
END IF;

/*IF object_type = '59' AND (:transaction_type = 'A') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE Series Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

		WHILE MinGR<= MaxGR DO

			SELECT T0."SeriesName" into Series FROM OIGN T1 INNER JOIN NNM1 T0 ON T0."Series" = T1."Series"
				 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
			SELECT TOP 1 T1."WhsCode" into WhsGR FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
			IF Series LIKE 'JW%' THEN
				IF WhsGR NOT LIKE '%JW%' THEN
					error :=34;
					error_message := N'Please Select JW-QC Warehouse for JW Series.';
				END IF;
			END IF;
			MinGR := MinGR+1;
		END WHILE;
END IF;*/

IF object_type = '59' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE Base Nvarchar(50);
DECLARE SeriesGR Nvarchar(50);
DECLARE SeriesPRO Nvarchar(50);
DECLARE UsrCod Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into UsrCod from OIGN INNER JOIN OUSR ON OUSR."USERID" = OIGN."UserSign" where OIGN."DocEntry"=list_of_cols_val_tab_del;

	IF UsrCod LIKE '%prod05%' THEN
		WHILE :MinGR<= :MaxGR DO
			SELECT TOP 1 "BaseRef" into Base FROM IGN1 WHERE IGN1."DocEntry" = :list_of_cols_val_tab_del and IGN1."VisOrder"=MinGR;
			SELECT TOP 1 NNM1."SeriesName" into SeriesPRO FROM OWOR INNER JOIN NNM1 ON NNM1."Series" = OWOR."Series" WHERE OWOR."DocNum" = Base;
			SELECT TOP 1 NNM1."SeriesName" into SeriesGR FROM OIGN INNER JOIN NNM1 ON NNM1."Series" = OIGN."Series" WHERE OIGN."DocEntry" = :list_of_cols_val_tab_del;

			IF SeriesPRO LIKE 'JW%'  THEN
				IF SeriesGR NOT LIKE 'JW%' THEN
					error :=35;
					error_message := N'Please select job work series for job work production order.';
				END IF;
			END IF;
			MinGR := MinGR+1;
		END WHILE;
	END IF;
END IF;

IF object_type = '59' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE ItemGR Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGR <= :MaxGR DO
		SELECT IGN1."WhsCode" into WhsGR FROM IGN1 WHERE IGN1."DocEntry" = :list_of_cols_val_tab_del and IGN1."VisOrder"=MinGR;
		IF WhsGR LIKE '%SCSP%' THEN
			error :=36;
			error_message := N'You are not allowed to select SCSP warehouse ';
		END IF;
		MinGR := MinGR+1;
	END WHILE;
END IF;

IF object_type = '59' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE Base Nvarchar(50);
DECLARE WhsGR Nvarchar(50);
DECLARE SeriesPRO Nvarchar(50);
DECLARE UsrCod Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into UsrCod from OIGN INNER JOIN OUSR ON OUSR."USERID" = OIGN."UserSign" where OIGN."DocEntry"=list_of_cols_val_tab_del;

	IF UsrCod LIKE '%prod05%' THEN
		WHILE :MinGR<= :MaxGR DO
			SELECT TOP 1 "BaseRef" into Base FROM IGN1 WHERE IGN1."DocEntry" = :list_of_cols_val_tab_del and IGN1."VisOrder"=MinGR;
			SELECT TOP 1 NNM1."SeriesName" into SeriesPRO FROM OWOR INNER JOIN NNM1 ON NNM1."Series" = OWOR."Series" WHERE OWOR."DocNum" = Base;
			SELECT "WhsCode" into WhsGR FROM IGN1 WHERE IGN1."DocEntry" = :list_of_cols_val_tab_del and IGN1."VisOrder"=MinGR;

			IF SeriesPRO LIKE 'JW%'  THEN
				IF WhsGR NOT LIKE 'JW%' THEN
					error :=37;
					error_message := N'Please select job work warehouse for job work production order.';
				END IF;
			END IF;
			MinGR := MinGR+1;
		END WHILE;
	END IF;
END IF;

IF object_type = '59' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE JCGR Nvarchar(50);
DECLARE JCGRDT Nvarchar(50);
DECLARE UsrCod Nvarchar(50);
DECLARE ItmGR Nvarchar(50);
	SELECT Min(T0."VisOrder") INTO MinGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Count(OIGN."U_UNE_CHNO") into JCGR FROM OIGN WHERE OIGN."DocEntry" = :list_of_cols_val_tab_del;
	SELECT Count(OIGN."U_UNE_CHDT") into JCGRDT FROM OIGN WHERE OIGN."DocEntry" = :list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into UsrCod from OIGN INNER JOIN OUSR ON OUSR."USERID" = OIGN."UserSign"
			where OIGN."DocEntry"=list_of_cols_val_tab_del;

	IF UsrCod LIKE '%prod05%' THEN
		WHILE :MinGR <= :MaxGR DO
			SELECT IGN1."WhsCode" into WhsGR FROM IGN1 WHERE IGN1."DocEntry" = :list_of_cols_val_tab_del and IGN1."VisOrder"=MinGR;
			SELECT IGN1."ItemCode" into ItmGR FROM IGN1 WHERE IGN1."DocEntry" = :list_of_cols_val_tab_del and IGN1."VisOrder"=MinGR;
			IF ItmGR <> 'PCFG0247' then
				IF WhsGR LIKE '%JW%' THEN
					IF JCGR = 0 THEN
						error :=38;
						error_message := N'Please enter subsidary challan no.';
					END IF;
					IF JCGRDT = 0 THEN
						error :=38;
						error_message := N'Please enter subsidary challan date.';
					END IF;
				END IF;
			END IF;
			MinGR := MinGR+1;
		END WHILE;
	END IF;
END IF;
IF Object_type = '59' and (:transaction_type ='A' or :transaction_type ='U' ) Then

DECLARE MinGR Int;
DECLARE MaxGR Int;
Declare ChallanNo nvarchar(50);
Declare ChallanDate nvarchar(50);
Declare SCDate nvarchar(50);
		SELECT Min(T0."VisOrder") INTO MinGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		WHILE :MinGR <= :MaxGR DO
			select "U_JobChallan1" into ChallanNo from IGN1 WHERE IGN1."DocEntry" = list_of_cols_val_tab_del and IGN1."VisOrder"=MinGR;

			IF (ChallanNo IS NOT NULL) then
				IF ChallanNo LIKE '40%' then
					Select OPDN."DocDate" into ChallanDate from OPDN WHERE OPDN."DocNum" = ChallanNo;
				else
					Select OWTR."DocDate" into ChallanDate from OWTR WHERE OWTR."DocNum" = ChallanNo;
				END IF;
				select "U_UNE_CHDT" into SCDate from OIGN WHERE OIGN."DocEntry" = list_of_cols_val_tab_del;
		         IF (SCDate < ChallanDate) then
		               error :=40;
		               error_message := N'SC Challan Date not greater than job work challan date';
		         End If;
		    END IF;
	    MinGR := MinGR+1;
		END WHILE;
End If;

IF object_type = '60' AND (:transaction_type = 'A') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE WhsGI Nvarchar(50);
DECLARE ItemGI Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGI<= :MaxGI DO
		SELECT IGE1."WhsCode" into WhsGI FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
		SELECT IGE1."ItemCode" into ItemGI FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

		IF ItemGI LIKE '%RM%' AND ItemGI LIKE '%PM%' THEN
			IF WhsGI NOT LIKE '%RAW%' AND WhsGI NOT LIKE '%PAC%' AND WhsGI NOT LIKE '%SSPL%' AND WhsGI NOT LIKE '%PDI%' AND WhsGI NOT LIKE '%ADVP%' AND WhsGI NOT LIKE '%GJCM%' AND WhsGI NOT LIKE '%AP%' AND WhsGI LIKE '%DE%' THEN
				error :=41;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
		END IF;
		MinGI := MinGI+1;
	END WHILE;
END IF;

IF Object_type = '60' and (:transaction_type ='A') Then
Declare OcrCode nvarchar(50);
Declare ItmCode nvarchar(50);
DECLARE MinGI Int;
DECLARE MaxGI Int;
	SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGI<= :MaxGI DO
		(Select  IGE1."OcrCode" into OcrCode from IGE1 where IGE1."DocEntry"=list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI);
		(Select  IGE1."ItemCode" into ItmCode from IGE1 where IGE1."DocEntry"=list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI);
          IF (OcrCode = '' OR OcrCode IS NULL) then
                  error :=42;
                  error_message := N'Please Select Distr. Rule in Document'||ItmCode;
         End If;
    MinGI := MinGI+1;
	END WHILE;
End If;

IF object_type = '60' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE Base Nvarchar(50);
DECLARE SeriesGI Nvarchar(50);
DECLARE ItemCod Nvarchar(50);
DECLARE SeriesPRO Nvarchar(50);
DECLARE UsrCod Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	select OUSR."USER_CODE" into UsrCod from OIGE INNER JOIN OUSR ON OUSR."USERID" = OIGE."UserSign"
			where OIGE."DocEntry"=list_of_cols_val_tab_del;

	IF UsrCod LIKE '%prod05%' THEN
		WHILE :MinGI<= :MaxGI DO
			SELECT "ItemCode" into ItemCod FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			IF ItemCod IS NOT NULL OR ItemCod <> ''  then
				SELECT TOP 1 "BaseRef" into Base FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
				IF Base IS NOT NULL THEN
					SELECT TOP 1 NNM1."SeriesName" into SeriesPRO FROM OWOR INNER JOIN NNM1 ON NNM1."Series" = OWOR."Series" WHERE OWOR."DocNum" = Base;
					SELECT TOP 1 NNM1."SeriesName" into SeriesGI FROM OIGE INNER JOIN NNM1 ON NNM1."Series" = OIGE."Series" WHERE OIGE."DocEntry" = :list_of_cols_val_tab_del;

					IF SeriesPRO LIKE 'JW%'  THEN
						IF SeriesGI NOT LIKE 'JW%' THEN
							error :=43;
							error_message := N'Please select job work series for job work production order.';
						END IF;
					END IF;
				END IF;
				MinGI := MinGI+1;
			END IF;
		END WHILE;
	END IF;
END IF;

IF object_type = '60' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE QtyGI decimal;
DECLARE JbQtyGI1 decimal;
DECLARE JbQtyGI2 decimal;
DECLARE JbQtyGI3 decimal;
DECLARE JbQtyGI4 decimal;
DECLARE JbQtyGI5 decimal;
DECLARE JbQtyGI6 decimal;
DECLARE JbQtyGI7 decimal;
DECLARE UsrCod Nvarchar(50);
DECLARE WhsGI Nvarchar(50);
DECLARE CdGI Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	select OUSR."USER_CODE" into UsrCod from OIGE INNER JOIN OUSR ON OUSR."USERID" = OIGE."UserSign" where OIGE."DocEntry"=list_of_cols_val_tab_del;

	IF UsrCod LIKE '%prod05%' THEN
		WHILE :MinGI<= :MaxGI DO
			SELECT "Quantity" into QtyGI FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT "ItemCode" into CdGI FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT OWHS."U_UNE_JAPP" into WhsGI FROM IGE1 INNER JOIN OWHS ON IGE1."WhsCode" = OWHS."WhsCode" WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT "U_JWQty1" into JbQtyGI1 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT "U_JWQty2" into JbQtyGI2 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT "U_JWQty3" into JbQtyGI3 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT "U_JWQty4" into JbQtyGI4 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT "U_JWQty5" into JbQtyGI5 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT "U_JWQty6" into JbQtyGI6 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT "U_JWQty7" into JbQtyGI7 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

			IF WhsGI = 'Y' and CdGI <> 'PCRM0017' and CdGI <> 'PCFG0345' and CdGI <> 'PCFG0344' and CdGI <> 'PCFG0347' and CdGI <> 'PCFG0346' THEN

				IF JbQtyGI4 IS NULL THEN
					IF JbQtyGI3 IS NOT NULL THEN
						IF JbQtyGI2 IS NOT NULL THEN
							IF JbQtyGI1 IS NOT NULL THEN
								IF QtyGI <> (JbQtyGI1 + JbQtyGI2 + JbQtyGI3) THEN
									error :=44;
									error_message := N'Job work challan quantity is not match with issue quantity.3. Line No '||MinGI;
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
				IF JbQtyGI3 IS NULL THEN
					IF JbQtyGI2 IS NOT NULL THEN
						IF JbQtyGI1 IS NOT NULL THEN
							IF QtyGI <> (JbQtyGI1 + JbQtyGI2) THEN
								error :=44;
								error_message := N'Job work challan quantity is not match with issue quantity.2. Line No '||MinGI;
							END IF;
						END IF;
					END IF;
				END IF;
				IF JbQtyGI3 IS NULL THEN
					IF JbQtyGI2 IS NULL THEN
						IF JbQtyGI1 IS NOT NULL THEN
							IF QtyGI <> JbQtyGI1 THEN
								error :=44;
								error_message := N'Job work challan quantity is not match with issue quantity.1. Line No '||MinGI;
							END IF;
						END IF;
					END IF;
				END IF;
				IF JbQtyGI5 IS NULL THEN
					IF JbQtyGI4 IS NOT NULL THEN
						IF JbQtyGI3 IS NOT NULL THEN
							IF JbQtyGI2 IS NOT NULL THEN
								IF JbQtyGI1 IS NOT NULL THEN
									IF QtyGI <> (JbQtyGI1 + JbQtyGI2 + JbQtyGI3 + JbQtyGI4) THEN
										error :=44;
										error_message := N'Job work challan quantity is not match with issue quantity.4.'||(JbQtyGI1 + JbQtyGI2 + JbQtyGI3 + JbQtyGI4);
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
			MinGI := MinGI+1;
		END WHILE;
	END IF;
END IF;

IF object_type = '60' AND (:transaction_type = 'A') THEN
DECLARE entry int;
Declare MinIT Int;
Declare MaxIT Int;
Declare Count1 int;
Declare IC varchar(50);
Declare Itm varchar(50);
entry:=0;

		SELECT Min(T0."VisOrder") INTO MinIT from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxIT from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		WHILE MinIT <= MaxIT DO

			select "VisOrder" into IC from IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinIT;

			select Count("DocEntry") into Count1  from (SELECT "DocEntry" FROM IGE1 T1
			INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
			WHERE T2."Warehouse" = T1."WhsCode" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
			AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
			Group By T1."DocEntry"
			HAVING Sum(T2."InQty"-T2."OutQty") < 0)a;

			SELECT "ItemCode" into IC FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinIT;

			if(Count1>0) then
				(SELECT Count(T1."DocEntry") into entry FROM IGE1 T1 INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
						WHERE T2."Warehouse" = T1."WhsCode" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
						AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
						Group By T1."DocEntry" HAVING Sum(T2."InQty"-T2."OutQty") < 0);

			END IF;
			 IF (entry > 0) THEN
				   error :=45;
				   error_message := N'Negative stock... '||MinIT || ' .. ' || IC || '  hi: ' || entry;
			   END IF;
			MinIT := MinIT+1;
		END WHILE;
END IF;

IF object_type = '60' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE WhsGI Nvarchar(50);
DECLARE JCNOGI Nvarchar(50);
DECLARE JCQTYGI Nvarchar(50);
DECLARE UsrCod Nvarchar(50);
DECLARE ItemCd Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into UsrCod from OIGE INNER JOIN OUSR ON OUSR."USERID" = OIGE."UserSign" where OIGE."DocEntry"=list_of_cols_val_tab_del;

	IF UsrCod LIKE '%prod05%' THEN
		WHILE :MinGI<= :MaxGI DO
			SELECT OWHS."U_UNE_JAPP" into WhsGI FROM IGE1 INNER JOIN OWHS ON IGE1."WhsCode" = OWHS."WhsCode" WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT IGE1."U_JobChallan1" into JCNOGI FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT IGE1."ItemCode" into ItemCd FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			SELECT IGE1."U_JWQty1" into JCQTYGI FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
			IF WhsGI = 'Y' and ItemCd <> 'PCRM0017' and ItemCd <> 'PCFG0345' and ItemCd <> 'PCFG0344' and ItemCd <> 'PCFG0346' and ItemCd <> 'PCFG0347' and ItemCd <> 'PCFG0361'  THEN
				IF JCNOGI IS NULL OR JCNOGI = '' THEN
					error :=45;
					error_message := N'Please enter our job work challan no at row level.'||MinGI;
				END IF;
				IF JCQTYGI IS NULL OR JCQTYGI = '' THEN
					error :=45;
					error_message := N'Please enter our job work challan quantity at row level.'||MinGI;
				END IF;
			END IF;
			MinGI := MinGI+1;
		END WHILE;
	END IF;
END IF;

IF object_type = '60' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE WhsGI Nvarchar(50);
DECLARE JCNOGI1 Nvarchar(50);
DECLARE JCQTYGI1 Nvarchar(50);
DECLARE JCNOGI2 Nvarchar(50);
DECLARE JCQTYGI2 Nvarchar(50);
DECLARE JCNOGI3 Nvarchar(50);
DECLARE JCQTYGI3 Nvarchar(50);
DECLARE JCNOGI4 Nvarchar(50);
DECLARE JCQTYGI4 Nvarchar(50);
DECLARE JCITEMGI1 Nvarchar(50);
DECLARE JCITEMGI2 Nvarchar(50);
DECLARE JCITEMGI3 Nvarchar(50);
DECLARE JCITEMGI4 Nvarchar(50);
DECLARE ITITEMGI1 Nvarchar(50);
DECLARE ITITEMGI2 Nvarchar(50);
DECLARE ITITEMGI3 Nvarchar(50);
DECLARE ITITEMGI4 Nvarchar(50);
DECLARE JobChallan1 Nvarchar(50);
DECLARE JobChallan2 Nvarchar(50);
DECLARE JobChallan3 Nvarchar(50);
DECLARE JobChallan4 Nvarchar(50);
DECLARE JobChallan6 Nvarchar(50);
DECLARE Datejb Nvarchar(50);
DECLARE UsrCod Nvarchar(50);
DECLARE JWDate1 date;
DECLARE JWDate2 date;
DECLARE JWDate3 date;
DECLARE JWDate4 date;

	SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into UsrCod from OIGE INNER JOIN OUSR ON OUSR."USERID" = OIGE."UserSign" where OIGE."DocEntry"=list_of_cols_val_tab_del;
	select OIGE."DocDate" into Datejb from OIGE where OIGE."DocEntry"=list_of_cols_val_tab_del;

		IF UsrCod LIKE '%prod05%' THEN
			WHILE :MinGI<= :MaxGI DO

				SELECT OWHS."U_UNE_JAPP" into WhsGI FROM IGE1 INNER JOIN OWHS ON IGE1."WhsCode" = OWHS."WhsCode" WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

				IF WhsGI = 'Y' THEN
					SELECT IGE1."ItemCode" into JCITEMGI1 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
					SELECT IGE1."U_JobChallan1" into JobChallan1 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
					SELECT IGE1."U_JWDate" into JWDate1 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

						IF JWDate1 >= '20230401' then
							IF JobChallan1 LIKE '10%'  then
								SELECT WTR1."ItemCode" into ITITEMGI1 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan1 and OWTR."DocDate" >= '20230401';
								IF ITITEMGI1 <> JCITEMGI1 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan1 LIKE '20%' then
								SELECT PDN1."ItemCode" into ITITEMGI1 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan1 and OPDN."DocDate" >= '20220401' and PDN1."VisOrder" = 0;
								IF ITITEMGI1 <> JCITEMGI1 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						ELSEIF JWDate1 >= '20210401' then
							IF JobChallan1 LIKE '40%' then
								SELECT WTR1."ItemCode" into ITITEMGI1 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan1 and OWTR."DocDate" >= '20210401';
								IF ITITEMGI1 <> JCITEMGI1 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan1 LIKE '30%' then
								SELECT PDN1."ItemCode" into ITITEMGI1 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan1 and OPDN."DocDate" >= '20210401' and PDN1."VisOrder" = 0 and PDN1."ItemCode" LIKE 'PC%';
								IF ITITEMGI1 <> JCITEMGI1 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						else
							IF length(JobChallan1) = 3 then
								SELECT concat('30',IGE1."U_JobChallan1") into JobChallan6 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
								SELECT WTR1."ItemCode" into ITITEMGI1 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan6 and OWTR."DocDate" < '20210401';
								IF ITITEMGI1 <> JCITEMGI1 THEN
									error :=189;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan1 LIKE '40%' then
								SELECT PDN1."ItemCode" into ITITEMGI1 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan1 and OPDN."DocDate" < '20210401' and PDN1."VisOrder" = 0;
								IF ITITEMGI1 <> JCITEMGI1 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan1 LIKE '30%' then
								SELECT WTR1."ItemCode" into ITITEMGI1 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan1 and OWTR."DocDate" < '20210401';
								IF ITITEMGI1 <> JCITEMGI1 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							End IF;
						End IF;


					SELECT IGE1."ItemCode" into JCITEMGI2 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
					SELECT IGE1."U_JobChallan2" into JobChallan2 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
					SELECT IGE1."U_JWDate2" into JWDate2 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;


						IF JWDate2 >= '20230401' then
							IF JobChallan2 LIKE '10%' then
								SELECT WTR1."ItemCode" into ITITEMGI2 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan2 and OWTR."DocDate" >= '20230401';
								IF ITITEMGI2 <> JCITEMGI2 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan2 LIKE '20%' then
								SELECT PDN1."ItemCode" into ITITEMGI2 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan2 and OPDN."DocDate" >= '20220401' and PDN1."VisOrder" = 0;
								IF ITITEMGI2 <> JCITEMGI2 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						ELSEIF JWDate2 >= '20210401' then
							IF JobChallan2 LIKE '40%' then
								SELECT WTR1."ItemCode" into ITITEMGI2 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan2 and OWTR."DocDate" >= '20210401';
								IF ITITEMGI2 <> JCITEMGI2 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan2 LIKE '30%' then
								SELECT PDN1."ItemCode" into ITITEMGI2 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan2 and OPDN."DocDate" >= '20210401' and PDN1."VisOrder" = 0;
								IF ITITEMGI2 <> JCITEMGI2 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						else
							IF length(JobChallan2) = 3 then
								SELECT concat('30',IGE1."U_JobChallan2") into JobChallan6 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
								SELECT WTR1."ItemCode" into ITITEMGI2 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan6 and OWTR."DocDate" < '20210401';
								IF ITITEMGI2 <> JCITEMGI2 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan2 LIKE '40%' then
								SELECT PDN1."ItemCode" into ITITEMGI2 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan2 and OPDN."DocDate" < '20210401';
								IF ITITEMGI2 <> JCITEMGI2 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan2 LIKE '30%' then
								SELECT WTR1."ItemCode" into ITITEMGI2 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan2 and OWTR."DocDate" < '20210401';
								IF ITITEMGI2 <> JCITEMGI2 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							End IF;
						End IF;


					SELECT IGE1."ItemCode" into JCITEMGI3 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
					SELECT IGE1."U_JobChallan3" into JobChallan3 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
					SELECT IGE1."U_JWDate3" into JWDate3 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;


						IF JWDate3 >= '20220401' then
							IF JobChallan3 LIKE '10%' then
								SELECT WTR1."ItemCode" into ITITEMGI3 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan3 and OWTR."DocDate" >= '20220401';
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan3 LIKE '20%' then
								SELECT PDN1."ItemCode" into ITITEMGI3 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan3 and OPDN."DocDate" >= '20220401' and PDN1."VisOrder" = 0;
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						ELSEIF JWDate3 >= '20210401' then
							IF JobChallan3 LIKE '40%' then
								SELECT WTR1."ItemCode" into ITITEMGI3 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan3 and OWTR."DocDate" >= '20210401';
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan3 LIKE '30%' then
								SELECT PDN1."ItemCode" into ITITEMGI3 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan3 and OPDN."DocDate" >= '20210401' and PDN1."VisOrder" = 0;
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						else
							IF length(JobChallan3) = 3 then
								SELECT concat('30',IGE1."U_JobChallan3") into JobChallan6 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
								SELECT WTR1."ItemCode" into ITITEMGI3 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan6 and OWTR."DocDate" < '20210401';
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan3 LIKE '40%' then
								SELECT PDN1."ItemCode" into ITITEMGI3 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan3 and OPDN."DocDate" < '20210401';
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan3 LIKE '30%' then
								SELECT WTR1."ItemCode" into ITITEMGI3 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan3 and OWTR."DocDate" < '20210401';
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							End IF;
						End IF;

					SELECT IGE1."ItemCode" into JCITEMGI4 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
					SELECT IGE1."U_JobChallan4" into JobChallan4 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
					SELECT IGE1."U_JWDate4" into JWDate4 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;


						IF JWDate4 >= '20220401' then
							IF JobChallan4 LIKE '10%' then
								SELECT WTR1."ItemCode" into ITITEMGI4 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan4 and OWTR."DocDate" >= '20220401';
								IF ITITEMGI4 <> JCITEMGI4 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan4 LIKE '20%' then
								SELECT PDN1."ItemCode" into ITITEMGI4 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan4 and OPDN."DocDate" >= '20220401' and PDN1."VisOrder" =0 ;
								IF ITITEMGI4 <> JCITEMGI4 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						ELSEIF JWDate4 >= '20210401' then
							IF JobChallan4 LIKE '40%' then
								SELECT WTR1."ItemCode" into ITITEMGI4 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan4 and OWTR."DocDate" >= '20210401';
								IF ITITEMGI4 <> JCITEMGI4 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan4 LIKE '30%' then
								SELECT PDN1."ItemCode" into ITITEMGI4 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan4 and OPDN."DocDate" >= '20210401';
								IF ITITEMGI4 <> JCITEMGI4 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						else
							IF length(JobChallan4) = 3 then
								SELECT concat('30',IGE1."U_JobChallan4") into JobChallan6 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
								SELECT WTR1."ItemCode" into ITITEMGI4 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan6 and OWTR."DocDate" < '20210401';
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan4 LIKE '40%' then
								SELECT PDN1."ItemCode" into ITITEMGI4 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan4 and OPDN."DocDate" < '20210401';
								IF ITITEMGI4 <> JCITEMGI4 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan4 LIKE '30%' then
								SELECT WTR1."ItemCode" into ITITEMGI4 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan4 and OWTR."DocDate" < '20210401';
								IF ITITEMGI4 <> JCITEMGI4 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							End IF;
						End IF;


					SELECT Count(IGE1."U_JobChallan1") into JCNOGI1 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
					SELECT IGE1."U_JWQty1" into JCQTYGI1 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

					SELECT Count(IGE1."U_JobChallan2") into JCNOGI2 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
					SELECT IGE1."U_JWQty2" into JCQTYGI2 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

					SELECT Count(IGE1."U_JobChallan3") into JCNOGI3 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
					SELECT IGE1."U_JWQty3" into JCQTYGI3 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

					SELECT Count(IGE1."U_JobChallan4") into JCNOGI4 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;
					SELECT IGE1."U_JWQty4" into JCQTYGI4 FROM IGE1 WHERE IGE1."DocEntry" = :list_of_cols_val_tab_del and IGE1."VisOrder"=MinGI;

					IF JCNOGI1 > 0 THEN
						IF JCQTYGI1 = '' OR JCQTYGI1 IS NULL THEN
							error :=47;
							error_message := N'Please enter our job work challan Quantity if job work challan no is there. Line '||MinGI;
						END IF;
					END IF;
					IF JCNOGI2 > 0 THEN
						IF JCQTYGI2 = '' OR JCQTYGI2 IS NULL THEN
							error :=47;
							error_message := N'Please enter our job work challan Quantity if job work challan no is there. Line '||MinGI;
						END IF;
					END IF;
					IF JCNOGI3 > 0 THEN
						IF JCQTYGI3 = '' OR JCQTYGI3 IS NULL THEN
							error :=47;
							error_message := N'Please enter our job work challan Quantity if job work challan no is there. Line '||MinGI;
						END IF;
					END IF;
					IF JCNOGI4 > 0 THEN
						IF JCQTYGI4 = '' OR JCQTYGI4 IS NULL THEN
							error :=47;
							error_message := N'Please enter our job work challan Quantity if job work challan no is there. Line '||MinGI;
						END IF;
					END IF;
				END IF;
				MinGI := MinGI+1;
			END WHILE;
		END IF;
END IF;

IF Object_type = '20' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare BaseType nvarchar(50);
Declare BaseYN nvarchar(50);
(Select OCRD."U_Base_Doc" into BaseYN
	from OPDN inner join OCRD on OPDN."CardCode"=OCRD."CardCode" where OPDN."DocEntry"=list_of_cols_val_tab_del);
(Select max(PDN1."BaseType") into BaseType
	from PDN1 inner join OPDN on OPDN."DocEntry"=PDN1."DocEntry" where OPDN."DocEntry"=list_of_cols_val_tab_del);
		IF(BaseYN='Y') Then
          IF (BaseType = '-1') then
                  error :=48;
                  error_message := N'Please Select Base Document';
         End If;
	End If;
End If;

IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE DRGRN Nvarchar(50);
DECLARE BRGRN Int;
	SELECT Min(T0."VisOrder") INTO MinGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OPDN."BPLId" into BRGRN FROM OPDN WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del;
	WHILE :MinGRN <= :MaxGRN DO
		SELECT PDN1."OcrCode" into DRGRN FROM PDN1 WHERE PDN1."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN;
		IF BRGRN = 3 THEN
			IF DRGRN LIKE '2%' THEN
				error :=49;
				error_message := N'Select proper Distribution rule';
			END IF;
		END IF;
		MinGRN := MinGRN+1;
	END WHILE;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE DRGRN Nvarchar(50);
DECLARE BRGRN Int;
	SELECT Min(T0."VisOrder") INTO MinGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OPDN."BPLId" into BRGRN FROM OPDN WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del;
	WHILE :MinGRN <= :MaxGRN DO
		SELECT PDN1."OcrCode" into DRGRN FROM PDN1 WHERE PDN1."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN;
		IF BRGRN = 4 THEN
			IF DRGRN NOT LIKE '2%' THEN
				error :=49;
				error_message := N'Select proper Distribution rule';
			END IF;
		END IF;
		MinGRN := MinGRN+1;
	END WHILE;
END IF;

IF object_type = '20' AND (:transaction_type = 'A') THEN
DECLARE GRPOIC Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE GRPOWC Nvarchar(50);
DECLARE Series Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	Select T1."SeriesName" into Series from OPDN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry"=list_of_cols_val_tab_del;

	WHILE :MinLinePDQ<=MaxLinePDQ DO
		SELECT PDN1."ItemCode" INTO GRPOIC FROM PDN1  where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;
		SELECT PDN1."WhsCode" INTO GRPOWC FROM PDN1  where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;

		IF GRPOWC LIKE '%QC%' then
			IF GRPOIC LIKE 'E%' and Series NOT LIKE 'CL%' THEN
			error :=50;
			error_message := N'Please Enter proper warehouse....';
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;

IF object_type = '20' AND (:transaction_type = 'A') THEN
DECLARE GRPOIC Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE GRPOWC Nvarchar(50);
DECLARE Series Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	Select T1."SeriesName" into Series from OPDN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry"=list_of_cols_val_tab_del;

	WHILE :MinLinePDQ<=MaxLinePDQ DO
		SELECT PDN1."ItemCode" INTO GRPOIC FROM PDN1  where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;
		SELECT PDN1."WhsCode" INTO GRPOWC FROM PDN1  where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;

		IF GRPOWC <> 'GJCM' then
			IF GRPOIC LIKE 'PCFG%' AND GRPOWC NOT IN ('PC-QC-TR','2PC-QCTR') and Series NOT LIKE 'CL%' THEN
			error :=51;
			error_message := N'Please Enter proper warehouse....';
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;

IF object_type = '20' AND (:transaction_type = 'A') THEN

DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE GRNCode Nvarchar(50);
DECLARE GRNSeries Nvarchar(50);
DECLARE GRNType Nvarchar(50);
DECLARE ITWhsCode Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT NNM1."SeriesName" into GRNSeries FROM OPDN INNER JOIN NNM1 ON NNM1."Series" = OPDN."Series" WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del;

	IF MinGRN = MaxGRN and MinGRN = 0 THEN
		SELECT PDN1."ItemCode" into GRNCode FROM PDN1 WHERE PDN1."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=0;
		SELECT PDN1."U_PTYPE" into GRNType FROM PDN1 WHERE PDN1."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=0;

		IF GRNSeries NOT LIKE 'CL%' and GRNSeries NOT LIKE 'JC%' THEN
			IF GRNCode LIKE '%PCRM%' and GRNType LIKE '%Drum%'  then
				error :=51;
				error_message := N'Please add packing code & its detail';
			END IF;
			IF GRNCode LIKE '%PCRM%' and GRNType LIKE '%Tank'  then
				error :=51;
				error_message := N'Please add packing code & its detail';
			END IF;
		END IF;
	END IF;
END IF;

IF Object_type = '20' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare OcrCode nvarchar(50);
(Select  count(PDN1."OcrCode") into OcrCode
	from PDN1 inner join OPDN on OPDN."DocEntry"=PDN1."DocEntry" where OPDN."DocEntry"=list_of_cols_val_tab_del and PDN1."OcrCode" is not null );
          IF (OcrCode = 0) then
                  error :=52;
                  error_message := N'Please Select Distr. Rule in Document';
         End If;
End If;

IF object_type = '20' AND (:transaction_type = 'A') THEN
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE ItemCDPQD Nvarchar(50);
Declare PackType Nvarchar(50);
Declare COUNT1 Int;

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinLinePDQ<=MaxLinePDQ DO
		SELECT PDN1."U_PTYPE" into PackType FROM PDN1 WHERE PDN1."DocEntry" = list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ;
		SELECT Distinct (PDN1."ItemCode") INTO ItemCDPQD FROM PDN1 where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;

		select Count(*) INTO COUNT1 from "@TANKERLOAD" WHERE "Code" IN(ItemCDPQD);
		IF COUNT1 > 0 THEN
			IF PackType IS NULL THEN
				error :=53;
				error_message := N'Please Enter Packing Type for : '||ItemCDPQD;
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE GRPOQTD Int;
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE POQTB Int;
DECLARE ItemCDPQD Nvarchar(50);
DECLARE DOCTPDQ Nvarchar (50);
Declare COUNT1 Int;

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinLinePDQ<=MaxLinePDQ DO
		SELECT Distinct (PDN1."Quantity") INTO GRPOQTD FROM PDN1  where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (PDN1."BaseOpnQty") INTO POQTB FROM PDN1  where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (PDN1."ItemCode") INTO ItemCDPQD FROM PDN1 where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (OPDN."DocType") INTO DOCTPDQ FROM OPDN Inner JOIN PDN1 ON OPDN."DocEntry"=PDN1."DocEntry" Where OPDN."DocEntry" =:list_of_cols_val_tab_del ;
		select Count(*) INTO COUNT1 from "@TANKERLOAD" WHERE "Code" IN(ItemCDPQD);

		IF COUNT1 = 0 THEN
			IF ItemCDPQD NOT LIKE 'E%' THEN
			IF  :DOCTPDQ = 'I' And (:GRPOQTD > POQTB) THEN
				error :=54;
				error_message := N'GRPO Qty. should not greater then P.O Qty...!'||ItemCDPQD;
			END IF;
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE GRPOQTD Int;
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE POQTB Int;
DECLARE ItemCDPQD Nvarchar(50);
DECLARE DOCTPDQ Nvarchar (50);
Declare PackType Nvarchar(50);
Declare COUNT1 Int;

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinLinePDQ<=MaxLinePDQ DO
		SELECT Distinct (PDN1."Quantity") INTO GRPOQTD FROM PDN1  where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (PDN1."BaseOpnQty") INTO POQTB FROM PDN1  where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (PDN1."ItemCode") INTO ItemCDPQD FROM PDN1 where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (OPDN."DocType") INTO DOCTPDQ FROM OPDN Inner JOIN PDN1 ON OPDN."DocEntry"=PDN1."DocEntry" Where OPDN."DocEntry" =:list_of_cols_val_tab_del ;
		SELECT PDN1."U_PTYPE" INTO PackType FROM PDN1 WHERE PDN1."DocEntry" = list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ;
		select Count(*) INTO COUNT1 from "@TANKERLOAD" WHERE "Code" IN(ItemCDPQD);
		IF PackType LIKE '%Tanker%' THEN
			IF COUNT1 > 0 THEN
				IF  :DOCTPDQ = 'I' And (:GRPOQTD > (POQTB + ((POQTB*3)/100))) THEN
					error :=55;
					error_message := N'GRPO Qty. should not greater then P.O Qty.3%.'||ItemCDPQD;
				END IF;
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE GRPOQTD Int;
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE POQTB Int;
DECLARE ItemCDPQD Nvarchar(50);
DECLARE DOCTPDQ Nvarchar (50);
Declare PackType Nvarchar(50);
Declare COUNT1 Int;

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinLinePDQ<=MaxLinePDQ DO
		SELECT Distinct (PDN1."Quantity") INTO GRPOQTD FROM PDN1  where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (PDN1."BaseOpnQty") INTO POQTB FROM PDN1  where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (PDN1."ItemCode") INTO ItemCDPQD FROM PDN1 where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (OPDN."DocType") INTO DOCTPDQ FROM OPDN Inner JOIN PDN1 ON OPDN."DocEntry"=PDN1."DocEntry" Where OPDN."DocEntry" =:list_of_cols_val_tab_del ;
		SELECT PDN1."U_PTYPE" INTO PackType FROM PDN1 WHERE PDN1."DocEntry" = list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ;
		select Count(*) INTO COUNT1 from "@TANKERLOAD" WHERE "Code" IN(ItemCDPQD);

		IF PackType NOT LIKE '%Tanker%' THEN
			IF COUNT1 > 0 THEN
				IF  :DOCTPDQ = 'I' And (:GRPOQTD > POQTB) THEN
					error :=56;
					error_message := N'GRPO Qty. should not greater then P.O Qty..!!'||ItemCDPQD;
				END IF;
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;

---------------A/P Invoice-----------------
IF Object_type = '18' and (:transaction_type ='A' or :transaction_type ='U' ) Then
DECLARE MinAP Int;
DECLARE MaxAP Int;
Declare OcrCode nvarchar(50);
Declare ItmCode nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinAP <= :MaxAP DO
		(Select PCH1."OcrCode" into OcrCode from PCH1 where PCH1."DocEntry"=list_of_cols_val_tab_del and PCH1."VisOrder"=MinAP);
		(Select PCH1."ItemCode" into ItmCode from PCH1 where PCH1."DocEntry"=list_of_cols_val_tab_del and PCH1."VisOrder"=MinAP);
	          IF (OcrCode = '' OR OcrCode IS NULL) then
	          	error :=59;
	          	error_message := N'Please Select Distr. Rule in Document'||ItmCode;
	         End If;
         MinAP := MinAP+1;
		END WHILE;
End If;

IF object_type = '18' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinAP Int;
DECLARE MaxAP Int;
DECLARE TCAP Nvarchar(50);
DECLARE CurrAP Nvarchar(50);
	SELECT Min(T0."VisOrder") INTO MinAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OPCH."DocCur" into CurrAP FROM OPCH WHERE OPCH."DocEntry" = :list_of_cols_val_tab_del;

IF CurrAP <> 'INR' THEN
		WHILE :MinAP <= :MaxAP DO
			SELECT PCH1."TaxCode" into TCAP FROM PCH1 WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder"=MinAP;
			IF TCAP = 'RIGST18' THEN
				error :=60;
				error_message := N'Select proper "RIGST18T" Taxcode for import party';
			END IF;
			MinAP := MinAP+1;
		END WHILE;
	END IF;
END IF;


IF object_type = '18' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinAP Int;
DECLARE MaxAP Int;
DECLARE TCAP Nvarchar(50);
DECLARE ICode Nvarchar(50);
DECLARE CurrAP Nvarchar(50);
DECLARE CCode Nvarchar(50);
DECLARE SCNO Nvarchar(50);
DECLARE SCDATE Nvarchar(50);
DECLARE Countt Int;
	SELECT Min(T0."VisOrder") INTO MinAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinAP <= :MaxAP DO
		SELECT OPCH."CardCode" into CCode FROM OPCH WHERE OPCH."DocEntry" = :list_of_cols_val_tab_del;
		SELECT PCH1."ItemCode" into ICode FROM PCH1 WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder"=MinAP;
		Select Count(T0."ItemCode") into Countt from PCH1 T0 INNER JOIN OPCH T1 ON T0."DocEntry" = T1."DocEntry" WHERE T0."U_BASEDOCNO" = SCNO
		and T0."ItemCode" = 'SER0038' and T1."CardCode" = CCode;
		SELECT PCH1."U_Schln1" into SCNO FROM PCH1 WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder"=MinAP;
		SELECT PCH1."U_Schld1" into SCDATE FROM PCH1 WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder"=MinAP;

		IF ICode = 'SER0038' and SCDATE IS NULL THEN
			error :=61;
			error_message := N'Please enter Subsidary challan date';
		END IF;
		IF ICode = 'SER0038' and SCNO IS NULL THEN
			error :=61;
			error_message := N'Please enter Subsidary challan no';
		END IF;
		IF Countt > 1 THEN
			error :=61;
			error_message := N'Duplicate subsidary challan no';
		END IF;
		MinAP := MinAP+1;
	END WHILE;
END IF;

-----------------

IF Object_type = '15' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare BaseType nvarchar(50);
(Select max(DLN1."BaseType") into BaseType
	from DLN1 inner join ODLN on ODLN."DocEntry"=DLN1."DocEntry" where ODLN."DocEntry"=list_of_cols_val_tab_del);
          IF (BaseType = '-1') then
                  error :=64;
                  error_message := N'Please Select Base Document';
         End If;
End If;

IF Object_type = '15' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare OcrCode nvarchar(50);
(Select  count(DLN1."OcrCode") into OcrCode
	from DLN1 inner join ODLN on ODLN."DocEntry"=DLN1."DocEntry" where ODLN."DocEntry"=list_of_cols_val_tab_del and DLN1."OcrCode" is not null );
          IF (OcrCode = 0) then
                  error :=65;
                  error_message := N'Please Select Distr. Rule in Document';
         End If;
End If;

----------------------------------------------
-- FORM Name   : Delivery
-- Added Date  :
-- Note        : This SP will restrict user to create Delivery after 6:15 PM.
IF object_type = '15' AND (:transaction_type ='A' ) THEN
DECLARE tim varchar(50);
DECLARE Series varchar(50);
	(select "CreateTS" into tim from ODLN WHERE "DocEntry" = list_of_cols_val_tab_del);
		IF tim > 181500  THEN
			error :=66;
			error_message := N'Not allowed to enter after 6:15 PM..';
		END IF;
END IF;

-------------------------------------------------


IF object_type = '15' AND (:transaction_type = 'A') THEN
DECLARE entry int;
Declare MinIT Int;
Declare MaxIT Int;
Declare Count1 int;
entry:=0;

		SELECT Min(T0."VisOrder") INTO MinIT from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxIT from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		WHILE MinIT <= MaxIT DO
			select Count("DocEntry") into Count1  from ( SELECT "DocEntry" FROM DLN1 T1
			INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
			WHERE T2."Warehouse" = T1."WhsCode" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
			AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
			Group By T1."DocEntry"
			HAVING Sum(T2."InQty"-T2."OutQty") < 0 )a;

			if(Count1>0) then
				(SELECT Count(T1."DocEntry") into entry FROM DLN1 T1 INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
						WHERE T2."Warehouse" = T1."WhsCode" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
						AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
						Group By T1."DocEntry"
					HAVING Sum(T2."InQty"-T2."OutQty") < 0);
			END IF;
			IF (entry > 0) THEN
				error :=67;
				error_message := N'Negative stock...';
			END IF;
			MinIT := MinIT+1;
		END WHILE;
END IF;

IF object_type = '13' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE DRIN Nvarchar(50);
DECLARE BRIN Int;
	SELECT Min(T0."VisOrder") INTO MinIN from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OINV."BPLId" into BRIN FROM OINV WHERE OINV."DocEntry" = :list_of_cols_val_tab_del;
	WHILE :MinIN <= :MaxIN DO
		SELECT INV1."OcrCode" into DRIN FROM INV1 WHERE INV1."DocEntry" = :list_of_cols_val_tab_del and INV1."VisOrder"=MinIN;

		IF BRIN = 3 THEN
			IF DRIN LIKE '2%' THEN
				error :=71;
				error_message := N'Select proper Distribution rule';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;

IF Object_type = '13' and (:transaction_type ='A') Then
DECLARE MinAR int;
DECLARE MaxAR int;
DECLARE AREntryType nvarchar(50);
DECLARE ARItemCode int;

	(SELECT min(T0."VisOrder") Into MinAR FROM INV1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxAR FROM INV1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	WHILE MinAR <= MaxAR
	DO
	(SELECT T1."U_EntryType" into AREntryType FROM INV1 T1 LEFT JOIN OINV T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinAR);
	(SELECT Count(T1."ItemCode") into ARItemCode FROM INV1 T1 LEFT JOIN OINV T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinAR and (ARItemCode LIKE 'PCRM%' OR ARItemCode LIKE 'PCFG%' OR ARItemCode LIKE 'SCRM%' OR ARItemCode LIKE 'SCFG%'));

		IF (AREntryType = 'Blank' and ARItemCode > 0) THEN
			error:=72;
			error_message:=N'Please Select Entry Type : Normal or Trading in "Entry Type" Column at Row level';
		END IF;
	 MinAR=MinAR+1;
	END WHILE;
END IF;
-----------------------
-- FORM Name   : A/R Invoice
-- Added Date  :
-- Note        : This SP will restrict user to create A/R Invoice after 6:15 PM.
IF object_type = '13' AND (:transaction_type ='A') THEN
DECLARE tim varchar(50);
DECLARE Series varchar(50);
	(select "CreateTS" into tim from OINV WHERE "DocEntry" = list_of_cols_val_tab_del);
	(select "SeriesName" into Series from OINV INNER JOIN NNM1 ON NNM1."Series" = OINV."Series" WHERE "DocEntry" = list_of_cols_val_tab_del);
		IF tim > 181500 and Series NOT LIKE 'CL%' THEN
			error :=73;
			error_message := N'Not allowed to enter after 6:15 PM..';
		END IF;
END IF;

IF object_type = '13' AND (:transaction_type = 'A') THEN
DECLARE entry int;
Declare MinIT Int;
Declare MaxIT Int;
Declare Count1 int;
entry:=0;

		SELECT Min(T0."VisOrder") INTO MinIT from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxIT from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		WHILE MinIT <= MaxIT DO
			select Count("DocEntry") into Count1  from ( SELECT "DocEntry" FROM INV1 T1
			INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
			WHERE T2."Warehouse" = T1."WhsCode" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
			AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
			Group By T1."DocEntry"
			HAVING Sum(T2."InQty"-T2."OutQty") < 0 )a;

			if(Count1>0) then
				(SELECT Count(T1."DocEntry") into entry FROM INV1 T1 INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
						WHERE T2."Warehouse" = T1."WhsCode" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
						AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
						Group By T1."DocEntry"
					HAVING Sum(T2."InQty"-T2."OutQty") < 0);
			END IF;
			IF (entry > 0) THEN
				error :=74;
				error_message := N'Negative stock...' || MinIT;
			END IF;
			MinIT := MinIT+1;
		END WHILE;
END IF;

IF Object_type = '13' and (:transaction_type ='A' OR :transaction_type = 'U') Then

DECLARE ItemCodeIN Nvarchar(50);
DECLARE MinIN Int;
DECLARE MaxIN Int;
SELECT Min(T0."VisOrder") INTO MinIN from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
SELECT Max(T0."VisOrder") INTO MaxIN from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinIN <= :MaxIN DO
	select INV1."ItemCode" into ItemCodeIN from OINV INNER JOIN INV1 ON OINV."DocEntry" = INV1."DocEntry"
		where OINV."DocEntry"= :list_of_cols_val_tab_del and INV1."VisOrder"=0;
		IF ItemCodeIN = 'PCFG0247' THEN
		    error :=75;
		    error_message := N'Something went wrong';
		END IF;
		IF ItemCodeIN = 'SCFG0016' THEN
		    error :=75;
		    error_message := N'Something went wrong';
		END IF;
	MinIN := MinIN+1;
	END WHILE;
END IF;

IF Object_type = '15' and (:transaction_type ='A') Then
DECLARE DLParty nvarchar(50);
DECLARE DLCurrency nvarchar(50);
DECLARE DLSeries nvarchar(50);
	(SELECT T0."CardCode" into DLParty FROM ODLN T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del);
	(SELECT T0."DocCur" into DLCurrency FROM ODLN T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del);
	(SELECT T1."SeriesName" into DLSeries FROM ODLN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"=:list_of_cols_val_tab_del);
		IF (DLParty LIKE 'CPE%' and DLCurrency = 'INR') THEN
			error:=79;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (DLParty LIKE 'CSE%' and DLCurrency = 'INR') THEN
			error:=79;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (DLSeries NOT LIKE 'CL%' and DLSeries NOT LIKE 'DM%') THEN
			IF (DLParty LIKE 'CSE%' and DLSeries NOT LIKE 'EX%' ) THEN
				error:=79;
				error_message:=N'Please Select Proper Series';
			END IF;
			IF (DLParty LIKE 'CPE%' and DLSeries NOT LIKE 'EX%') THEN
				error:=79;
				error_message:=N'Please Select Proper Series';
			END IF;
		END IF;
END IF;

IF Object_type = '203' and (:transaction_type ='A') Then

DECLARE ADParty nvarchar(50);
DECLARE ADCurrency nvarchar(50);
DECLARE ADSeries nvarchar(50);
	(SELECT T0."CardCode" into ADParty FROM ODPI T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del);
	(SELECT T0."DocCur" into ADCurrency FROM ODPI T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del);
	(SELECT T1."SeriesName" into ADSeries FROM ODPI T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"=:list_of_cols_val_tab_del );
		IF (ADParty LIKE 'CPE%' and ADCurrency = 'INR') THEN
			error:=80;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (ADParty LIKE 'CSE%' and ADCurrency = 'INR') THEN
			error:=80;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (ADParty LIKE 'CSE%' and ADSeries NOT LIKE 'EX%' ) THEN
			error:=80;
			error_message:=N'Please Select Proper Series';
		END IF;
		IF (ADParty LIKE 'CPE%' and ADSeries NOT LIKE 'EX%' ) THEN
			error:=80;
			error_message:=N'Please Select Proper Series';
		END IF;
END IF;

IF Object_type = '20' and (:transaction_type ='A') Then
DECLARE GRNParty nvarchar(50);
DECLARE GRNCurrency nvarchar(50);
DECLARE GRNSeries nvarchar(50);
	(SELECT T0."CardCode" into GRNParty FROM OPDN T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del);
	(SELECT T0."DocCur" into GRNCurrency FROM OPDN T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del);
	(SELECT T1."SeriesName" into GRNSeries FROM OPDN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del);
	  	IF GRNParty <> 'VPRI0017' then
			IF (GRNParty LIKE 'VPRI%' and GRNCurrency = 'INR' and GRNParty <> 'VPRI0011') THEN
				error:=82;
				error_message:=N'Please Select Proper Currency';
			END IF;
			IF (GRNParty LIKE 'VSRI%' and GRNCurrency = 'INR' and GRNParty <> 'VPRI0011') THEN
				error:=82;
				error_message:=N'Please Select Proper Currency';
			END IF;

			IF (GRNParty LIKE 'VPRI%' and GRNSeries NOT LIKE 'IM%' and GRNSeries NOT LIKE 'JC%' and GRNSeries <> 'CL1/2324' and GRNParty <> 'VPRI0011') THEN
				error:=82;
				error_message:=N'Please Select Proper Series';
			END IF;
			IF (GRNParty LIKE 'VSRI%' and GRNSeries NOT LIKE 'IM%' and GRNSeries NOT LIKE 'JC%' and GRNSeries <> 'CL1/2324' and GRNParty <> 'VPRI0011') THEN
				error:=82;
				error_message:=N'Please Select Proper Series';
			END IF;
		END IF;
END IF;

IF Object_type = '18' and (:transaction_type ='A') Then
DECLARE APParty nvarchar(50);
DECLARE APCurrency nvarchar(50);
DECLARE APSeries nvarchar(50);
	(SELECT T0."CardCode" into APParty FROM OPCH T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del);
	(SELECT T0."DocCur" into APCurrency FROM OPCH T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del);
	(SELECT T1."SeriesName" into APSeries FROM OPCH T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del);

		IF (APParty LIKE 'VPRI%' and APCurrency = 'INR' and APParty <> 'VPRI0011' and APParty <> 'VPRI0017') THEN
			error:=83;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (APParty LIKE 'VSRI%' and APCurrency = 'INR' and APParty <> 'VPRI0011' and APParty <> 'VPRI0017') THEN
			error:=83;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (APParty LIKE 'VPRI%' and APSeries NOT LIKE 'IM%' and APParty <> 'VPRI0011' and APParty <> 'VPRI0017') THEN
			error:=83;
			error_message:=N'Please Select Proper Series';
		END IF;
		IF (APParty LIKE 'VSRI%' and APSeries NOT LIKE 'IM%' and APParty <> 'VPRI0011' and APParty <> 'VPRI0017')  THEN
			error:=83;
			error_message:=N'Please Select Proper Series';
		END IF;
END IF;

------------------------GRN For 2PC-FLOR---------------------------
IF object_type = '20' AND (:transaction_type = 'A') THEN
DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE WhseGRN Nvarchar(50);
DECLARE ItemGRN Nvarchar(50);
DECLARE SrsGRN Nvarchar(50);
DECLARE Branch Int;

	SELECT T0."BPLId" INTO Branch FROM OPDN T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del;

	IF Branch = 3 THEN

		SELECT Min(T0."VisOrder") INTO MinGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT T1."SeriesName" INTO SrsGRN from OPDN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" =:list_of_cols_val_tab_del;

		IF SrsGRN NOT LIKE 'J%' and SrsGRN NOT LIKE 'CL%'THEN
			WHILE MinGRN<=MaxGRN DO
				SELECT PDN1."WhsCode" into WhseGRN FROM PDN1 WHERE PDN1."DocEntry" = list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN;
				SELECT PDN1."ItemCode" into ItemGRN FROM PDN1 WHERE PDN1."DocEntry" = list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN;

				IF ItemGRN LIKE '%FG%' and (WhseGRN NOT LIKE '%TR%' and WhseGRN NOT LIKE '%OF%') THEN
					error :=8511;
					error_message := N'Please Enter Proper Warehouse.FG.';
				END IF;
				IF ItemGRN LIKE 'PCRM0018' and WhseGRN NOT LIKE '%RAW%' THEN
					error :=8512;
					error_message := N'Please Enter Proper Warehouse..';
				END IF;
				MinGRN := MinGRN+1;
			END WHILE;
		END IF;
	END IF;
END IF;

IF object_type = '20' AND (:transaction_type = 'A') THEN
DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE WhseGRN Nvarchar(50);
DECLARE ItemGRN Nvarchar(50);
DECLARE SrsGRN Nvarchar(50);
DECLARE Branch Int;

	SELECT T0."BPLId" INTO Branch FROM OPDN T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del;

	IF Branch = 4 THEN

		SELECT Min(T0."VisOrder") INTO MinGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT T1."SeriesName" INTO SrsGRN from OPDN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" =:list_of_cols_val_tab_del;

		IF SrsGRN NOT LIKE 'J%' and SrsGRN NOT LIKE 'CL%'THEN
			WHILE MinGRN<=MaxGRN DO
				SELECT PDN1."WhsCode" into WhseGRN FROM PDN1 WHERE PDN1."DocEntry" = list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN;
				SELECT PDN1."ItemCode" into ItemGRN FROM PDN1 WHERE PDN1."DocEntry" = list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN;

				IF ItemGRN LIKE '%FG%' and WhseGRN NOT LIKE '%TR%' THEN
					error :=8521;
					error_message := N'Please Enter Proper Warehouse.FG.';
				END IF;
				IF ItemGRN LIKE 'PCRM0018' and WhseGRN NOT LIKE '2PC-FLOR' THEN
					error :=8522;
					error_message := N'Please select 2PC-FLOR Warehouse..';
				END IF;
				MinGRN := MinGRN+1;
			END WHILE;
		END IF;
	END IF;
END IF;
---------------------------------------------------
/*IF object_type = '18' AND (:transaction_type = 'A') THEN
DECLARE MinAP Int;
DECLARE MaxAP Int;
DECLARE WhseAP Nvarchar(50);
DECLARE ItemAP Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinAP<=MaxAP DO
		SELECT PCH1."WhsCode" into WhseAP FROM PCH1 WHERE PCH1."DocEntry" = list_of_cols_val_tab_del and PCH1."VisOrder"=MinAP;
		SELECT PCH1."ItemCode" into ItemAP FROM PCH1 WHERE PCH1."DocEntry" = list_of_cols_val_tab_del and PCH1."VisOrder"=MinAP;
		IF ItemAP LIKE '%FG%' and WhseAP NOT LIKE '%TR%' and WhseAP NOT LIKE '%GJCM%' and WhseAP <> 'JW-OF' THEN
			error :=86;
			error_message := N'Please Enter Proper Warehouse.FG.';
		END IF;
		MinAP := MinAP+1;
	END WHILE;
END IF;*/

IF Object_type = '20' and (:transaction_type ='A') Then
DECLARE MinGRN int;
DECLARE MaxGRN int;
DECLARE GRNEntryType nvarchar(50);
DECLARE GRNItemCode int;

	(SELECT min(T0."VisOrder") Into MinGRN FROM PDN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGRN FROM PDN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	WHILE MinGRN <= MaxGRN
	DO
	(SELECT T1."U_EntryType" into GRNEntryType FROM PDN1 T1 LEFT JOIN OPDN T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinGRN);
	(SELECT Count(T1."ItemCode") into GRNItemCode FROM PDN1 T1 LEFT JOIN OPDN T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinGRN and (T1."ItemCode"  LIKE 'PCRM%' OR T1."ItemCode"  LIKE 'SCRM%' OR T1."ItemCode"  LIKE 'SCFG%' OR T1."ItemCode"  LIKE 'PCFG%'));

		IF (GRNEntryType = 'Blank' and GRNItemCode>0) THEN
			error:=88;
			error_message:=N'Please Select Entry Type : Normal or Trading in "Entry Type" Column at Row level';
			select :error, :error_message FROM dummy;
			Return;
		END IF;
	 MinGRN=MinGRN+1;
	END WHILE;
END IF;

IF Object_type = '20' and (:transaction_type ='A') Then
DECLARE MinGRN int;
DECLARE MaxGRN int;
DECLARE GRNSeries nvarchar(50);
DECLARE GRNItemCode nvarchar(50);

	(SELECT min(T0."VisOrder") Into MinGRN FROM PDN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGRN FROM PDN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	WHILE MinGRN <= MaxGRN
	DO
	(SELECT T1."SeriesName" into GRNSeries FROM OPDN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  	WHERE T0."DocEntry"= :list_of_cols_val_tab_del);
	(SELECT T1."ItemCode" into GRNItemCode FROM PDN1 T1 LEFT JOIN OPDN T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinGRN);

		IF (GRNSeries NOT LIKE 'CL%') THEN
			IF (GRNSeries NOT LIKE 'EG%' and GRNItemCode LIKE 'E%') THEN
				error:=89;
				error_message:=N'Please Select Engineering Series';
				select :error, :error_message FROM dummy;
				Return;
			END IF;
		END IF;
	 	MinGRN=MinGRN+1;
	END WHILE;
END IF;

IF object_type = '59' AND (:transaction_type = 'A') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE ItemGR Nvarchar(50);
DECLARE Series Nvarchar(50);
	SELECT Min(T0."VisOrder") INTO MinGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	SELECT T2."SeriesName" into Series FROM OIGN T1 INNER JOIN NNM1 T2 ON T1."Series" = T2."Series"
		WHERE T1."DocEntry" = :list_of_cols_val_tab_del;

	IF Series NOT LIKE 'BT%' AND Series NOT LIKE 'BA%' then
		WHILE MinGR<= MaxGR DO
			SELECT T1."WhsCode" into WhsGR FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
			SELECT T1."ItemCode" into ItemGR FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;

			IF ItemGR LIKE  'PCFG%' and WhsGR NOT LIKE '%QC' and ItemGR <> 'PCFG0247'
				and ItemGR <> 'PCFG0299' and ItemGR <> 'PCFG0292' and ItemGR <> 'PCFG0291' and ItemGR <> 'PCFG0290' and ItemGR <> 'PCFG0289'
				and ItemGR <> 'PCFG0288' and ItemGR <> 'SCFG0016' THEN
				error :=90;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
			MinGR := MinGR+1;
		END WHILE;
	END IF;
END IF;

IF object_type = '59' AND (:transaction_type = 'A') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE ItemGR Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE MinGR<= MaxGR DO
		SELECT T1."WhsCode" into WhsGR FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
		SELECT T1."ItemCode" into ItemGR FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
		IF WhsGR LIKE '%QC%' and (ItemGR = 'PCFG0299' OR ItemGR = 'PCFG0292' OR ItemGR = 'PCFG0291' OR ItemGR = 'PCFG0290'
			OR ItemGR = 'PCFG0289' OR ItemGR = 'PCFG0288') THEN
			error :=91;
			error_message := N'Please Enter PC-FG Warehouse.';
		END IF;
		MinGR := MinGR+1;
	END WHILE;
END IF;

IF object_type = '59' AND (:transaction_type = 'A') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE ItemGR Nvarchar(50);
DECLARE Series Nvarchar(50);
	SELECT Min(T0."VisOrder") INTO MinGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T2."SeriesName" into Series FROM OIGN T1 INNER JOIN NNM1 T2 ON T1."Series" = T2."Series" WHERE T1."DocEntry" = :list_of_cols_val_tab_del;

	IF Series NOT LIKE 'BT%' AND Series NOT LIKE 'BA%' then
		WHILE MinGR<= MaxGR DO
			SELECT T1."WhsCode" into WhsGR FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
			SELECT T1."ItemCode" into ItemGR FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
			IF ItemGR LIKE 'PCRM%' and WhsGR NOT LIKE '%QC' and ItemGR <> 'PCRM0018' and ItemGR <> 'PCRM0017' THEN
				error :=92;
				error_message := N'Please Enter Proper Warehouse........';
			END IF;
			MinGR := MinGR+1;
		END WHILE;
	END IF;
END IF;

IF object_type = '59' AND (:transaction_type = 'A') THEN

DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE ItemGR Nvarchar(50);
	SELECT Min(T0."VisOrder") INTO MinGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE MinGR<= MaxGR DO
		SELECT T1."WhsCode" into WhsGR FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
		SELECT T1."ItemCode" into ItemGR FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;

		IF ItemGR LIKE 'SCFG%' and WhsGR NOT LIKE '%QC' and ItemGR <> 'SCFG0016' THEN
			error :=93;
			error_message := N'Please Enter Proper Warehouse....';
		END IF;
		MinGR := MinGR+1;
	END WHILE;
END IF;

IF object_type = '59' AND (:transaction_type = 'A') THEN

DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE ItemGR Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE MinGR<= MaxGR DO
		SELECT T1."WhsCode" into WhsGR FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
		SELECT T1."ItemCode" into ItemGR FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;

		IF WhsGR NOT LIKE '%BT%' THEN
			IF ItemGR LIKE 'SCRM%' and WhsGR NOT LIKE '%QC' THEN
				error :=94;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
		END IF;
		MinGR := MinGR+1;
	END WHILE;
END IF;

If object_type = '59' and (:transaction_type='A') then
Declare PODE  nvarchar(10);
Declare IssuedQty  Numeric(19,6);
	select distinct "BaseEntry" into PODE from IGN1 where "DocEntry"=:list_of_cols_val_tab_del;
	select sum("IssuedQty") into IssuedQty  from  WOR1 where "DocEntry"=PODE and "ItemCode" <> 'SCBP0009';
	if IssuedQty = 0 then
         error :=96;
         error_message := N'Issue for Production Entry not Done for this Production order so the Receipt from Production not Possible';
	end if;
end if;

IF Object_type = '20' and (:transaction_type ='A') Then
DECLARE MinGRN int;
DECLARE MaxGRN int;
DECLARE GRNWhse nvarchar(50);
DECLARE GRNItemCode nvarchar(50);
DECLARE GRNBranch nvarchar(50);
DECLARE Series nvarchar(50);

	(SELECT min(T0."VisOrder") Into MinGRN FROM PDN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGRN FROM PDN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT T0."BPLId" Into GRNBranch FROM OPDN T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT T0."Series" Into Series FROM OPDN T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	WHILE MinGRN <= MaxGRN
	DO
	(SELECT T1."WhsCode" into GRNWhse FROM PDN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del AND T1."VisOrder"=MinGRN);
	(SELECT T1."ItemCode" into GRNItemCode FROM PDN1 T1 WHERE T1."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinGRN);

		IF (GRNBranch = 4) and Series NOT LIKE 'CL%' THEN
			IF (GRNWhse NOT LIKE 'E%' and GRNItemCode LIKE 'E%' and GRNWhse <> 'FBU2' and GRNWhse <> 'OBU2' and GRNWhse <> '2PC-GEN') THEN
				error:=100;
				error_message:=N'Please Select Proper Warehouse';
				select :error, :error_message FROM dummy;
				Return;
			END IF;
		END IF;
	 MinGRN=MinGRN+1;
	END WHILE;

END IF;

IF Object_type = '67' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare ITCardCode nvarchar(50);
Declare ITSeries nvarchar(50);
		select OWTR."CardCode" into ITCardCode from OWTR where OWTR."DocEntry"=list_of_cols_val_tab_del;
		SELECT NNM1."SeriesName" INTO ITSeries FROM OWTR LEFT JOIN NNM1 ON NNM1."Series" = OWTR."Series" where OWTR."DocEntry"=list_of_cols_val_tab_del;

		IF  ITSeries NOT LIKE 'JC%' and ITCardCode = 'VPPD0015' and ITCardCode = 'VPRD0018' and ITCardCode = 'VPRD0041' and ITCardCode = 'VPPD0012' THEN
			error :=102;
			error_message := N'Please select jobwork Series ..';
		END IF;
End If;

--------------------------------------------------
---------UNIT-1
IF object_type = '67' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE ITCode Nvarchar(50);
DECLARE ITWhsCode Nvarchar(50);
DECLARE Branch Nvarchar(50);
DECLARE FromWhsCode Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OBPL."BPLName" INTO Branch FROM OWTR INNER JOIN OBPL ON OBPL."BPLId" = OWTR."BPLId" WHERE OWTR."DocEntry" =:list_of_cols_val_tab_del;

	IF Branch = 'UNIT - I' THEN

	WHILE :MinIT <= :MaxIT DO
		SELECT WTR1."ItemCode" into ITCode FROM WTR1 WHERE WTR1."DocEntry" = :list_of_cols_val_tab_del and WTR1."VisOrder"=MinIT;
		SELECT WTR1."WhsCode" into ITWhsCode FROM WTR1 WHERE WTR1."DocEntry" = :list_of_cols_val_tab_del and WTR1."VisOrder"=MinIT;
		SELECT WTR1."FromWhsCod" into FromWhsCode FROM WTR1 where WTR1."DocEntry" =:list_of_cols_val_tab_del and WTR1."VisOrder"=MinIT;
		IF  ITWhsCode NOT LIKE '%TRD%' and ITWhsCode NOT LIKE '%GJCM%' and ITWhsCode NOT LIKE '%PSC%' and ITWhsCode NOT LIKE '%SSPL%' and ITWhsCode NOT LIKE '%ADVP%' and ITWhsCode NOT LIKE '%DE%' and ITWhsCode NOT LIKE '%RSC%' THEN

			IF ITCode LIKE '%RM%' THEN
				IF FromWhsCode IN ('PC-QC','SC-QC') THEN
					IF (ITWhsCode NOT IN ('PC-RAW','PC-QCR','SC-RAW','SC-QCR') and ITWhsCode NOT LIKE '%BT%') THEN
						error :=10300;
						error_message := N'Wrong warehouseqq';
					END IF;
				END IF;
			END IF;

			IF ITCode LIKE '%FG%' THEN
				IF FromWhsCode = 'PC-QC' THEN
					IF (ITWhsCode NOT IN ('PC-FG','PC-QCR','SC-FG','SC-QCR') and ITWhsCode NOT LIKE '%BT%') THEN
						error :=103000;
						error_message := N'Wrong warehouse';
					END IF;
				END IF;
			END IF;

		END IF;
		MinIT := MinIT+1;
	END WHILE;
	END IF;
END IF;

------------UNIT-2 "2PC-Flor"---------------

IF object_type = '67' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE ITCode Nvarchar(50);
DECLARE ITWhsCode Nvarchar(50);
DECLARE FromWhsCode Nvarchar(50);
DECLARE Branch Nvarchar(50);
	SELECT Min(T0."VisOrder") INTO MinIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	SELECT OBPL."BPLName" INTO Branch FROM OWTR INNER JOIN OBPL ON OBPL."BPLId" = OWTR."BPLId" WHERE OWTR."DocEntry" =:list_of_cols_val_tab_del;

	IF Branch = 'UNIT - II' THEN

	WHILE :MinIT <= :MaxIT DO
		SELECT WTR1."ItemCode" into ITCode FROM WTR1 WHERE WTR1."DocEntry" = :list_of_cols_val_tab_del and WTR1."VisOrder"=MinIT;
		SELECT WTR1."WhsCode" into ITWhsCode FROM WTR1 WHERE WTR1."DocEntry" = :list_of_cols_val_tab_del and WTR1."VisOrder"=MinIT;
		SELECT WTR1."FromWhsCod" into FromWhsCode FROM WTR1 where WTR1."DocEntry" =:list_of_cols_val_tab_del and WTR1."VisOrder"=MinIT;
		IF ITWhsCode NOT LIKE '%TRD%' and ITWhsCode NOT LIKE '%GJCM%' and ITWhsCode NOT LIKE '%PSC%' and ITWhsCode NOT LIKE '%SSPL%' and ITWhsCode NOT LIKE '%ADVP%' and ITWhsCode NOT LIKE '%DE%' and ITWhsCode NOT LIKE '%RSC%' THEN

			IF ITCode LIKE '%RM%' THEN
				-----By pass some items for transfer to 2PC-flor--------
				IF ITCode NOT IN ('PCRM0005','PCRM0033','PCRM0045','PCRM0027','PCRM0050','PCRM0009') THEN
					IF FromWhsCode = '2PC-QC' THEN
						IF (ITWhsCode NOT IN ('2PC-RAW','2PC-QCR') and ITWhsCode NOT LIKE '%BT%') THEN
							error :=1031;
							error_message := N'Wrong warehouse';
						END IF;
					END IF;
				END IF;

				IF ITCode IN  ('PCRM0005','PCRM0033','PCRM0045','PCRM0027','PCRM0050','PCRM0009') THEN
					IF FromWhsCode = '2PC-QC' THEN
						IF (ITWhsCode NOT IN ('2PC-FLOR','2PC-QCR') and ITWhsCode NOT LIKE '%BT%') THEN
							error :=1032;
							error_message := N'Wrong warehouse';
						END IF;
					END IF;
				END IF;
				IF FromWhsCode = '2PC-RAW' THEN
					IF (ITWhsCode NOT LIKE '2PC-FLOR' and ITWhsCode NOT LIKE '%BT%') THEN
						error :=1032;
						error_message := N'Wrong warehouse';
					END IF;
				END IF;
				IF FromWhsCode = '2PC-FLOR' THEN
					IF (ITWhsCode NOT LIKE '2PC-RAW') THEN
						error :=1033;
						error_message := N'Wrong warehouse';
					END IF;
				END IF;

			END IF;

			IF ITCode LIKE '%FG%' THEN

				IF FromWhsCode = '2PC-QC' THEN
					IF (ITWhsCode NOT IN ('2PC-FLOR','2PC-QCR') and ITWhsCode NOT LIKE '%BT%') THEN
						error :=1034;
						error_message := N'Wrong warehouse';
					END IF;
				END IF;
				IF FromWhsCode = '2PC-FG' THEN
					IF (ITWhsCode NOT IN ('2PC-FLOR','2EX1PCFG') and ITWhsCode NOT LIKE '%BT%') THEN
						error :=1035;
						error_message := N'Wrong warehouse.' ;
					END IF;
				END IF;
				IF FromWhsCode = '2PC-FLOR' THEN
					IF (ITWhsCode NOT IN ('2PC-FG','2EX1PCFG') AND ITWhsCode NOT LIKE '%BT%') THEN
						error :=1036;
						error_message := N'Wrong warehouse';
					END IF;
				END IF;

			END IF;
		END IF;
		MinIT := MinIT+1;
	END WHILE;
	END IF;
END IF;

----------------------------------------------------------
-----------Inventory transfer 'FT2' Series

IF object_type = '67' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE SeriesName Varchar (50);
DECLARE Fromwhs Varchar(50);
DECLARE Whscode Varchar(50);

	SELECT Min(T0."VisOrder") INTO MinIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT NNM1."SeriesName" INTO SeriesName FROM OWTR INNER JOIN NNM1 ON NNM1."Series" = OWTR."Series" where OWTR."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinIT <= :MaxIT DO
		SELECT WTR1."FromWhsCod" into Fromwhs FROM WTR1 WHERE WTR1."DocEntry" = :list_of_cols_val_tab_del and WTR1."VisOrder"=MinIT;

		IF Fromwhs <> '2PC-QC' THEN
		SELECT WTR1."WhsCode" into Whscode FROM WTR1 WHERE WTR1."DocEntry" = :list_of_cols_val_tab_del and WTR1."VisOrder"=MinIT;

			IF (Fromwhs = '2PC-FLOR' OR Whscode = '2PC-FLOR') THEN
				IF SeriesName NOT LIKE 'FT2%' THEN
					error :=1037;
					error_message := N'Please select FT2 Series';
				END IF;
			END IF;
		END IF;
		MinIT := MinIT+1;
	END WHILE;
END IF;

--------------------------------------------------------
----------------inventory transfer Base document (Floor warehouse)
IF object_type = '67' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE BaseType Int;
	SELECT Min(T0."VisOrder") INTO MinIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinIT <= :MaxIT DO
		SELECT MAX(WTR1."BaseType") into BaseType FROM OWTR INNER JOIN WTR1 ON OWTR."DocEntry" = WTR1."DocEntry" INNER JOIN NNM1 ON NNM1."Series" = OWTR."Series"
		WHERE WTR1."DocEntry" = :list_of_cols_val_tab_del and WTR1."VisOrder"=MinIT AND NNM1."SeriesName" LIKE 'FT2%';
			IF (BaseType = '-1') THEN
				error :=1038;
				error_message := N'Please select base Document';
			END IF;
		MinIT := MinIT+1;
	END WHILE;
END IF;

-----------------Inventory transfer request 2PC-Flor------------------

IF object_type = '1250000001' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE SeriesName Varchar (50);
DECLARE Fromwhs Varchar(50);
DECLARE Whscode Varchar(50);

	SELECT Min(T0."VisOrder") INTO MinIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT NNM1."SeriesName" INTO SeriesName FROM OWTQ INNER JOIN NNM1 ON NNM1."Series" = OWTQ."Series" where OWTQ."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinIT <= :MaxIT DO
		SELECT WTQ1."FromWhsCod" into Fromwhs FROM WTQ1 WHERE WTQ1."DocEntry" = :list_of_cols_val_tab_del and WTQ1."VisOrder"=MinIT;

		IF Fromwhs <> '2PC-QC' THEN
		SELECT WTQ1."WhsCode" into Whscode FROM WTQ1 WHERE WTQ1."DocEntry" = :list_of_cols_val_tab_del and WTQ1."VisOrder"=MinIT;

			IF (Fromwhs = '2PC-FLOR' OR Whscode = '2PC-FLOR') THEN
				IF SeriesName NOT LIKE 'FT2%' THEN
					error :=10370;
					error_message := N'Please select FT2 Series';
				END IF;
			END IF;
		END IF;
		MinIT := MinIT+1;
	END WHILE;
END IF;
--------------------------------------------------------

IF object_type = '67' AND (:transaction_type = 'A' ) THEN
DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE ITCapacity Int;
	SELECT Min(T0."VisOrder") INTO MinIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinIT <= :MaxIT DO
		SELECT WTR1."Factor1" into ITCapacity FROM WTR1 WHERE WTR1."DocEntry" = :list_of_cols_val_tab_del and WTR1."VisOrder"=MinIT;
			IF ITCapacity <> 950 and ITCapacity <> 180 and ITCapacity <> 230 and ITCapacity <> 20 and ITCapacity <> 1 and ITCapacity <> 25
			and ITCapacity <> 50 and ITCapacity <> 200 and ITCapacity <> 170 and ITCapacity <> 190 and ITCapacity <> 220 and ITCapacity <> 850 and ITCapacity <> 900
			and ITCapacity <> 1000 and ITCapacity <> 160 and ITCapacity <> 165 and ITCapacity <> 800 and ITCapacity <> 197 and ITCapacity <> 30 and ITCapacity <> 35 and ITCapacity <> 250
			and ITCapacity <> 215 and ITCapacity <> 185 and ITCapacity <> 225 and ITCapacity <> 228 and ITCapacity <> 210 and ITCapacity <> 15 and ITCapacity <> 232 and ITCapacity <> 235
			and ITCapacity <> 300 and ITCapacity <> 270 and ITCapacity <> 245 and ITCapacity <> 231 and ITCapacity <> 140 and ITCapacity <> 240 THEN
				error :=104;
				error_message := N'Capacity may wrong';
			END IF;
		MinIT := MinIT+1;
	END WHILE;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE GRNCapacity Int;
	SELECT Min(T0."VisOrder") INTO MinGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGRN <= :MaxGRN DO
		SELECT PDN1."Factor1" into GRNCapacity FROM PDN1 WHERE PDN1."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN;
			IF GRNCapacity = 1 THEN
			else
				IF GRNCapacity = 25 THEN
				else
					IF GRNCapacity = 30 THEN
					else
						IF GRNCapacity = 50 THEN
						else
							IF GRNCapacity = 200 THEN
							else
								IF GRNCapacity = 170 THEN
								else
									IF GRNCapacity = 190 THEN
									else
										IF GRNCapacity = 220 THEN
										else
											IF GRNCapacity = 850 THEN
											else
												IF GRNCapacity = 900 THEN
												else
													IF GRNCapacity = 1000 THEN
													else
														IF GRNCapacity = 160 THEN
														else
															IF GRNCapacity = 20 THEN
															else
																IF GRNCapacity = 165 THEN
																else
																	IF GRNCapacity = 800 THEN
																	else
																		IF GRNCapacity = 230 THEN
																		else
																			IF GRNCapacity = 197 THEN
																			else
																				IF GRNCapacity = 30 THEN
																				else
																					IF GRNCapacity = 35 THEN
																					else
																						IF GRNCapacity = 180 THEN
																						else
																							IF GRNCapacity = 250 THEN
																							else
																								IF GRNCapacity = 45 THEN
																								else
																									IF GRNCapacity = 215 THEN
																									else
																										IF GRNCapacity = 185 THEN
																										else
																											IF GRNCapacity = 225 THEN
																											else
																												IF GRNCapacity = 228 THEN
																												else
																													IF GRNCapacity = 210 THEN
																													else
																														IF GRNCapacity = 15 THEN
																														else
																															IF GRNCapacity = 232 THEN
																															else
																																IF GRNCapacity = 950 THEN
																																else
																																	IF GRNCapacity = 235 THEN
																																	else
																																		IF GRNCapacity = 300 THEN
																																		else
																																			IF GRNCapacity = 270 THEN
																																			else
																																				IF GRNCapacity = 245 THEN
																																				else
																																					IF GRNCapacity = 231 THEN
																																					else
																																						IF GRNCapacity = 140 THEN
																																						else
																																							IF GRNCapacity = 240 THEN
																																							else
																																								IF GRNCapacity = 1250 THEN
																																							else
																																								error :=105;
																																								error_message := N'Capacity may wrong';
																																							END IF;
																																						END IF;
																																					END IF;
																																				END IF;
																																			END IF;
																																		END IF;
																																	END IF;
																																END IF;
																															END IF;
																														END IF;
																													END IF;
																												END IF;
																											END IF;
																										END IF;
																									END IF;
																								END IF;
																							END IF;
																						END IF;
																					END IF;
																				END IF;
																			END IF;
																		END IF;
																	END IF;
																END IF;
															END IF;
														END IF;
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
		MinGRN := MinGRN+1;
	END WHILE;
END IF;

IF Object_type = '67' and (:transaction_type ='A' or :transaction_type ='U' ) Then

Declare fROMWHS nvarchar(50);
Declare tOwHS nvarchar(50);
Declare Challan1 nvarchar(50);
Declare MinIT Int;
Declare MaxIT Int;
		SELECT Min(T0."VisOrder") INTO MinIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		WHILE :MinIT <= :MaxIT DO
			select WTR1."FromWhsCod" into fROMWHS from WTR1 where WTR1."DocEntry"=list_of_cols_val_tab_del and WTR1."VisOrder"=MinIT;
			select OWHS."U_UNE_JAPP" into tOwHS from WTR1 INNER JOIN OWHS ON OWHS."WhsCode" = WTR1."WhsCode" where WTR1."DocEntry"=list_of_cols_val_tab_del and WTR1."VisOrder"=MinIT;
			select WTR1."U_JobChallan1" into Challan1 from WTR1 where WTR1."DocEntry"=list_of_cols_val_tab_del and WTR1."VisOrder"=MinIT;

			IF  fROMWHS LIKE '%TR%' THEN
				IF tOwHS = 'Y' THEN
					IF Challan1 = '' then
						error :=106;
						error_message := N'Something went wrong ..';
					End If;
				END IF;
			END IF;
		MinIT := MinIT+1;
		END WHILE;
End If;

IF object_type = '67' AND (:transaction_type = 'A') THEN
DECLARE entry int;
Declare MinIT Int;
Declare MaxIT Int;
Declare Count1 int;
entry:=0;

		SELECT Min(T0."VisOrder") INTO MinIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		WHILE MinIT <= MaxIT DO
			select Count("DocEntry") into Count1  from ( SELECT "DocEntry" FROM WTR1 T1
			INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
			WHERE T2."Warehouse" = T1."FromWhsCod" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
			AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
			Group By T1."DocEntry"
			HAVING Sum(T2."InQty"-T2."OutQty") < 0 )a;

			if(Count1>0) then
				(SELECT Count(T1."DocEntry") into entry FROM WTR1 T1 INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
						WHERE T2."Warehouse" = T1."FromWhsCod" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
						AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
						Group By T1."DocEntry"
					HAVING Sum(T2."InQty"-T2."OutQty") < 0);
			END IF;
			IF (entry > 0) THEN
				error :=107;
				error_message := N'Negative stock...';
			END IF;
			MinIT := MinIT+1;
		END WHILE;
END IF;

/*IF object_type = '67' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE WhsGI Nvarchar(50);
DECLARE BaseGR Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

		WHILE MinGR<= MaxGR DO
			SELECT TOP 1 T1."BaseRef" into BaseGR FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
			SELECT TOP 1  T1."WhsCode" into WhsGI FROM IGE1 T1 WHERE T1."BaseRef" = BaseGR;
			SELECT TOP 1 T1."WhsCode" into WhsGR FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
			IF WhsGI LIKE 'GJCM%' OR WhsGI LIKE 'ADVP%' OR WhsGI LIKE 'PDI%' OR WhsGI LIKE 'AP%' OR WhsGI LIKE 'SSPL%' OR WhsGI LIKE 'SVC%' OR WhsGI LIKE 'DE%' THEN
				IF WhsGR NOT LIKE '%JW%' THEN
					error :=108;
					error_message := N'Please Enter Proper Warehouse.!';
				END IF;
			END IF;
			MinGR := MinGR+1;
		END WHILE;
END IF;*/

IF object_type = '67' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE PTYPE Nvarchar(50);
DECLARE UsrCod Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

		WHILE MinIT<= MaxIT DO

			SELECT T1."U_PTYPE" into PTYPE FROM WTR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinIT;
			select OUSR."USER_CODE" into UsrCod from OWTR INNER JOIN OUSR ON OUSR."USERID" = OWTR."UserSign"
			where OWTR."DocEntry"=list_of_cols_val_tab_del;

			IF UsrCod = 'dispatch01' THEN
				IF PTYPE IS NULL OR PTYPE = ''  THEN
					error :=109;
					error_message := N'Please Enter Packing Type.';
				END IF;
			END IF;
			MinIT := MinIT+1;
		END WHILE;
END IF;

------------------Gate pass------------------------------

If Object_Type = 'GPass' and (:transaction_type='U') then
Declare Status  Nvarchar(50);
SELECT "Status" Into Status  FROM "@GPHR" T0 WHERE T0."DocEntry" = list_of_cols_val_tab_del;
		if  Status = 'C' then
        	error :=110;
        	error_message := N'Gate pass is Closed';
		end if;
end if;

----------------------------------------------------
-- FORM Name   : GATE PASS
-- Added Date  :
-- Note        : This SP will not allow to cancel or close Gate Pass Entry.

IF object_type = 'GPass' AND (:transaction_type = 'C' OR :transaction_type = 'L')   THEN
DECLARE Creator nvarchar(50);
 	SELECT T0."Creator" Into Creator  FROM "@GPHR" T0 WHERE T0."DocEntry" = list_of_cols_val_tab_del;
		IF (Creator <> 'manager') THEN
			error := 110;
			error_message := 'You are not allowed to cancel/close the document';
		END IF;
END IF;

------------------------------------------------
If Object_Type = 'GPass' and (:transaction_type='A' OR :transaction_type='U') then
Declare Onhand  Int;
Declare Code  varchar(50);
Declare Srs  varchar(50);
Declare InvntItem varchar(50);
DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE Qty Int;

	SELECT Min(T0."LineId") INTO MinIT from "@GPDL" T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."LineId") INTO MaxIT from "@GPDL" T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	SELECT T0."U_Srs" Into Srs  FROM "@GPHR" T0
		WHERE T0."DocEntry" = list_of_cols_val_tab_del;

	WHILE MinIT<= MaxIT DO

	SELECT T1."InvntItem" Into InvntItem  FROM "@GPDL" T0 INNER JOIN OITM T1 ON T0."U_ItemCode" = T1."ItemCode"
		WHERE T0."DocEntry" = list_of_cols_val_tab_del and T0."LineId" = MinIT;

	SELECT "U_ItemCode" Into Code  FROM "@GPDL" T0 WHERE T0."DocEntry" = list_of_cols_val_tab_del and T0."LineId" = MinIT;
	SELECT "OnHand" Into Onhand  FROM "@GPDL" T0 INNER JOIN OITM T1 ON T0."U_ItemCode" = T1."ItemCode"
		WHERE T0."DocEntry" = list_of_cols_val_tab_del and T0."LineId" = MinIT;
	SELECT "U_Quantity" Into Qty  FROM "@GPDL" T0 WHERE T0."DocEntry" = list_of_cols_val_tab_del and T0."LineId" = MinIT;

		IF InvntItem = 'Y' and Srs NOT LIKE 'R%' then
			IF  Onhand > 0 then
				IF Onhand < Qty THEN
					error :=111;
	        		error_message := N'Stock not allow more than available '||Code;
	        	END IF;
			ELSE
	        	error :=111;
	        	error_message := N'Stock not available '||Code;
			END IF;
		END IF;
		MinIT := MinIT+1;
		END WHILE;
end if;


If Object_Type = 'GPass' and (:transaction_type='A') then
Declare date1 Date;

	SELECT T0."U_Date" Into date1  FROM "@GPHR" T0 WHERE T0."DocEntry" = list_of_cols_val_tab_del;

	IF date1 <> CURRENT_DATE then
		error :=112;
	   	error_message := N'Gate pass Not allowed in back date ';
	END IF;
end if;



If Object_Type = 'GPass' and (:transaction_type='A') then
Declare date1 Date;
Declare Srss Nvarchar(50);

	SELECT T0."U_Date" Into date1  FROM "@GPHR" T0 WHERE T0."DocEntry" = list_of_cols_val_tab_del;
	SELECT T0."U_Srs" Into Srss  FROM "@GPHR" T0 WHERE T0."DocEntry" = list_of_cols_val_tab_del;

	IF (date1 >= '20220401' and date1 <= '20230331') and Srss NOT LIKE '%2223%' then
		error :=112;
	   	error_message := N'Gate pass series may wrong please contact to SAP';
	END IF;

	IF (date1 >= '20230401' and date1 <= '20240331') and Srss NOT LIKE '%2324%' then
		error :=112;
	   	error_message := N'Gate pass series may wrong please contact to SAP';
	END IF;
end if;


If Object_Type = 'GPass' and (:transaction_type='U')  then
	error :=112;
	error_message := N'Gate pass Not allowed to update ';
end if;

--------------------------------
-- FORM Name   : Non Returnatble GatePass entry
-- Added Date  :
-- Note        :


If Object_Type = 'GPass' and (:transaction_type='A' OR :transaction_type='U') then
Declare Srss Nvarchar(50);
	SELECT T0."U_Srs" Into Srss  FROM "@GPHR" T0 WHERE T0."DocEntry" = list_of_cols_val_tab_del;
	IF Srss LIKE 'NG%' then
		error :=112;
	   	error_message := N'NRGP gate pass is stopped';
	END IF;
end if;

-----------------------------------
IF object_type = '202' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE MainItemPRO Nvarchar(50);
DECLARE ItemPRO Nvarchar(50);
DECLARE TypePRO Nvarchar(50);
DECLARE CountPRO Int;

	SELECT Min(T0."VisOrder") INTO MinPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."ItemCode" into MainItemPRO FROM OWOR T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."Type" into TypePRO FROM OWOR T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	WHILE :MinPRO <= :MaxPRO DO

		SELECT T1."ItemCode" into ItemPRO FROM WOR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinPRO;
		select count(*) into CountPRO from OWOR INNER JOIN OITT ON OITT."Code" = OWOR."ItemCode" INNER JOIN ITT1 ON ITT1."Father" = OITT."Code"
			WHERE OWOR."ItemCode" = MainItemPRO	and ITT1."Code" = ItemPRO and OWOR."DocEntry" = :list_of_cols_val_tab_del;

		IF CountPRO = 0 and ItemPRO NOT LIKE '%PM%' and TypePRO = 'S' and ItemPRO <> 'SCRM0016' and ItemPRO <> 'PCFG0247' THEN
			error :=113;
			error_message := N'Not allowed to enter item other than BOM in Standard production order.';
		END IF;
		MinPRO := MinPRO + 1;
	END WHILE;
END IF;

IF object_type = '202' AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE PlanQtyPROH Int;
DECLARE PlanQtyPROL Int;
DECLARE ItemPRO Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T0."PlannedQty" into PlanQtyPROH FROM OWOR T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	WHILE :MinPRO <= :MaxPRO DO

		SELECT T1."ItemCode" into ItemPRO FROM WOR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinPRO;
		SELECT T1."PlannedQty" into PlanQtyPROL FROM WOR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinPRO and T1."ItemCode" = ItemPRO;
		IF ItemPRO LIKE '%PM%' and PlanQtyPROH = PlanQtyPROL THEN
			error :=114;
			error_message := N'Header planned quatity & footer planned quantity of packing material not same.';
		END IF;
		MinPRO := MinPRO + 1;
	END WHILE;
END IF;

IF Object_type = '15' and (:transaction_type ='A' or :transaction_type ='U' ) Then
DECLARE LRNo Nvarchar(50);
		SELECT T0."U_UNE_LRNo" into LRNo FROM ODLN T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		IF LRNo IS NULL THEN
			error :=123;
			error_message := N'Please Enter LR No.';
		END IF;
End If;

IF object_type = '15' AND (:transaction_type = 'A' or :transaction_type='U') THEN
DECLARE MinDL Int;
DECLARE MaxDL Int;
DECLARE FOBDL Nvarchar(50);
DECLARE CardCodeDL Nvarchar(50);
	SELECT Min(T0."VisOrder") INTO MinDL from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxDL from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."CardCode" into CardCodeDL FROM ODLN T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	WHILE :MinDL <= :MaxDL DO
		SELECT T1."U_fob_value" into FOBDL FROM DLN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;

		IF FOBDL IS NULL and CardCodeDL LIKE 'C_E%'  THEN
			error :=124;
			error_message := N'Please Enter FOB.';
		END IF;
		MinDL := MinDL + 1;
	END WHILE;
END IF;

IF Object_type = '15' and (:transaction_type ='A' or :transaction_type ='U' ) Then

DECLARE DLrate decimal(18,2);
DECLARE DLExrate decimal(18,2);
DECLARE DLDocCur Nvarchar(50);
DECLARE DLdate date;
DECLARE DLCardCode Nvarchar(50);
DECLARE DLSeries Nvarchar(50);
		SELECT T0."DocRate" into DLrate FROM ODLN T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		SELECT T0."DocDate" into DLdate FROM ODLN T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		SELECT T0."CardCode" into DLCardCode FROM ODLN T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		SELECT T0."DocCur" into DLDocCur FROM ODLN T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		(SELECT T1."SeriesName" into DLSeries FROM ODLN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del);

		IF DLCardCode LIKE 'C_E%' and DLSeries <> 'CL1/2223' THEN
			SELECT T0."Rate" into DLExrate FROM ORTT T0 WHERE T0."Currency" = DLDocCur and T0."RateDate" = DLdate;

			IF DLExrate <> DLrate THEN
				error :=126;
				error_message := N'Not allowd to change exchange rate.';
			END IF;
		END IF;
End If;

--------------------------------A/R Invoice------------------
IF Object_type = '13' and (:transaction_type ='A' ) Then
Declare BaseType nvarchar(50);
Declare GSTTranTyp nvarchar(50);
(Select max(INV1."BaseType") into BaseType
	from INV1 inner join OINV on OINV."DocEntry"=INV1."DocEntry" where OINV."DocEntry"= :list_of_cols_val_tab_del);
(Select OINV."GSTTranTyp" into GSTTranTyp from OINV where OINV."DocEntry"= :list_of_cols_val_tab_del);
          IF (BaseType = '-1' and GSTTranTyp != 'GD') then
                  error :=127;
                  error_message := N'Please Select Base Document';
         End If;
End If;
------------------

IF object_type = '13' AND (:transaction_type = 'A') THEN

DECLARE MinAR Int;
DECLARE MaxAR Int;
DECLARE WhseAR Nvarchar(50);
DECLARE SeriesAR Nvarchar(50);
DECLARE ItmAR Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinAR from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAR from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinAR<=MaxAR DO
		SELECT INV1."WhsCode" into WhseAR FROM INV1 WHERE INV1."DocEntry" = list_of_cols_val_tab_del and INV1."VisOrder"=MinAR;
		SELECT INV1."ItemCode" into ItmAR FROM INV1 WHERE INV1."DocEntry" = list_of_cols_val_tab_del and INV1."VisOrder"=MinAR;
		(SELECT T1."SeriesName" into SeriesAR FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del);

		IF SeriesAR NOT LIKE 'CL%' THEN
			IF ItmAR LIKE '%BY%' then
				IF WhseAR NOT LIKE '%BYP%' and WhseAR NOT LIKE '%TRD%' THEN
					error :=129;
					error_message := N'Please Enter Proper Warehouse';
				END IF;
			END IF;
			IF ItmAR LIKE '%FG%' then
				IF WhseAR NOT LIKE '%FG%' and WhseAR NOT LIKE '%TRD%' and WhseAR NOT LIKE '%GJCM%' and WhseAR NOT LIKE '%ADVP%' and WhseAR NOT LIKE '%GJCM%' and WhseAR NOT LIKE '%PSC%' and WhseAR NOT LIKE '%SSPL%' and WhseAR NOT LIKE '%DE%' and WhseAR NOT LIKE '%RSC%' and WhseAR NOT LIKE '%OF%' THEN
					error :=129;
					error_message := N'Please Enter Proper Warehouse';
				END IF;
			END IF;
		END IF;

		MinAR := MinAR+1;
	END WHILE;
END IF;


IF Object_type = '13' and (:transaction_type ='A' ) Then

DECLARE INParty nvarchar(50);
DECLARE INCurrency nvarchar(50);
DECLARE INSeries nvarchar(50);

	(SELECT T0."CardCode" into INParty FROM OINV T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del);
	(SELECT T0."DocCur" into INCurrency FROM OINV T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del);
	(SELECT T1."SeriesName" into INSeries FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"=:list_of_cols_val_tab_del );
		IF (INParty LIKE 'CPE%' and INCurrency = 'INR') THEN
			error:=130;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (INParty LIKE 'CSE%' and INCurrency = 'INR') THEN
			error:=130;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (INSeries NOT LIKE 'CL%') THEN
			IF (INParty LIKE 'CSE%' and INSeries NOT LIKE 'EX%' and INSeries NOT LIKE 'EM%') THEN
				error:=130;
				error_message:=N'Please Select Proper Series';
			END IF;
			IF (INParty LIKE 'CPE%' and INSeries NOT LIKE 'EX%' and INSeries NOT LIKE 'EM%') THEN
				error:=130;
				error_message:=N'Please Select Proper Series';
			END IF;
		END IF;
END IF;

IF Object_type = '13' and (:transaction_type ='A' ) Then

DECLARE ARrate decimal;
DECLARE ARExrate decimal;
DECLARE ARDocCur Nvarchar(50);
DECLARE ARdate date;
DECLARE ARCardCode Nvarchar(50);
DECLARE ARSeries Nvarchar(50);
		SELECT T0."DocRate" into ARrate FROM OINV T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		SELECT T0."DocDate" into ARdate FROM OINV T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		SELECT T0."DocCur" into ARDocCur FROM OINV T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		SELECT T0."CardCode" into ARCardCode FROM OINV T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		(SELECT T1."SeriesName" into ARSeries FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del);

		IF ARCardCode LIKE 'C_E%' and ARSeries <> 'CL1/2223' THEN

			SELECT T0."Rate" into ARExrate FROM ORTT T0 WHERE T0."Currency" = ARDocCur and T0."RateDate" = ARdate;
			IF ARExrate <> ARrate THEN
				error :=131;
				error_message := N'Not allowed to change exchange rate.' || ARrate;
			END IF;
		END IF;
End If;

IF object_type = '203' AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE MinARD Int;
DECLARE MaxARD Int;
DECLARE PerUntQty Nvarchar(50);
DECLARE Ttlunt Nvarchar(50);
DECLARE Wghtpckng Nvarchar(50);
DECLARE pckngtype Nvarchar(50);
DECLARE typpltibc Nvarchar(50);
DECLARE lictype Nvarchar(50);
DECLARE licno Nvarchar(50);
DECLARE pltibc Nvarchar(50);
DECLARE Nopltibc Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinARD from DPI1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxARD from DPI1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinARD <= :MaxARD DO
		SELECT T1."Factor1" into PerUntQty FROM DPI1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."Factor3" into Ttlunt FROM DPI1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."U_WOPT" into Wghtpckng FROM DPI1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."U_PTYPE" into pckngtype FROM DPI1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."U_TOPLT" into typpltibc FROM DPI1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."U_LicenseType" into lictype FROM DPI1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."U_LicenseNum" into licno FROM DPI1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."U_NoPalates" into pltibc FROM DPI1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."U_TAmount" into Nopltibc FROM DPI1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;

		IF PerUntQty IS NULL  then
			error :=132;
			error_message := N'Please enter Per unit quantity';
		END IF;
		IF Ttlunt IS NULL  then
			error :=132;
			error_message := N'Please enter Total unit';
		END IF;
		IF Wghtpckng IS NULL  then
			error :=132;
			error_message := N'Please enter weight of packing type';
		END IF;
		IF pckngtype IS NULL  then
			error :=132;
			error_message := N'Please enter packing type';
		END IF;
		IF pckngtype <> 'Bags' AND pckngtype <> 'Carboys' AND pckngtype <> 'Carboys' AND pckngtype <> 'IBC Tank' AND pckngtype <> 'HDPE Drums' AND
		 pckngtype <> 'MS Drum' AND pckngtype <> 'Jumbo bag' AND pckngtype <> 'Loose' AND pckngtype <> 'Tanker Load' AND pckngtype <> 'ISO Tank' AND pckngtype <> 'Box' then
			error :=132;
			error_message := N'Please select proper packing type';
		END IF;
		IF typpltibc IS NULL
		  then
			error :=132;
			error_message := N'Please enter Type of pallets/IBC';
		END IF;
		IF typpltibc <> 'COUNTRY WOOD PALLETS' and typpltibc <> 'IBC TANK' and typpltibc <> 'ISO TANK' and
		typpltibc <> 'PINE WOOD PALLETS' and typpltibc <> 'PLASTIC PALLETS' and typpltibc <> 'BAGS' and typpltibc <> 'BOX' then
			error :=132;
			error_message := N'Please enter proper word Type of pallets/IBC';
		END IF;
		IF lictype IS NULL  then
			error :=132;
			error_message := N'Please enter License Type';
		END IF;
		IF pltibc IS NULL  then
			error :=132;
			error_message := N'Please enter Pallates/IBC';
		END IF;
		IF pltibc <> 'PALLETS' AND  pltibc <> 'IBC Tank' AND  pltibc <> 'ISO Tank' AND  pltibc <> 'BAGS' AND  pltibc <> 'BOX' then
			error :=132;
			error_message := N'Please enter proper word PALLETS/IBC Tank/ISO Tank';
		END IF;
		IF Nopltibc IS NULL  then
			error :=132;
			error_message := N'Please enter No of Pallates/IBC';
		END IF;
		MinARD := MinARD + 1;
	END WHILE;
END IF;

IF object_type = '13' AND (:transaction_type = 'A') THEN

DECLARE MinAR Int;
DECLARE MaxAR Int;
DECLARE PerUntQty Nvarchar(50);
DECLARE Ttlunt Nvarchar(50);
DECLARE Wghtpckng Nvarchar(50);
DECLARE pckngtype Nvarchar(50);
DECLARE typpltibc Nvarchar(50);
DECLARE lictype Nvarchar(50);
DECLARE licno Nvarchar(50);
DECLARE pltibc Nvarchar(50);
DECLARE Nopltibc Nvarchar(50);
DECLARE SeriesAR Nvarchar(50);
DECLARE QCBatchNo Nvarchar(25);
DECLARE ItemCd Nvarchar(10);
DECLARE ExportAR Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinAR from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAR from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	(SELECT T1."SeriesName" into SeriesAR FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  	WHERE T0."DocEntry"= :list_of_cols_val_tab_del);
	(SELECT T0."ImpORExp" into ExportAR FROM INV12 T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del);

	WHILE :MinAR <= :MaxAR DO

		SELECT T1."Factor1" into PerUntQty FROM INV1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."Factor3" into Ttlunt FROM INV1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_WOPT" into Wghtpckng FROM INV1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_PTYPE" into pckngtype FROM INV1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_TOPLT" into typpltibc FROM INV1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_LicenseType" into lictype FROM INV1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_LicenseNum" into licno FROM INV1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_NoPalates" into pltibc FROM INV1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_TAmount" into Nopltibc FROM INV1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."ItemCode" into ItemCd FROM INV1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_QCBatchNo" into QCBatchNo FROM INV1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;

		IF SeriesAR LIKE 'E%' then
			IF PerUntQty IS NULL  then
				error :=133;
				error_message := N'Please enter Per unit quantity';
			END IF;
			IF Ttlunt IS NULL  then
				error :=133;
				error_message := N'Please enter Total unit';
			END IF;
			IF Wghtpckng IS NULL  then
				error :=133;
				error_message := N'Please enter weight of packing type';
			END IF;
			IF pckngtype IS NULL  then
				error :=133;
				error_message := N'Please enter packing type';
			END IF;
			IF pckngtype <> 'Bags' AND pckngtype <> 'Carboys' AND pckngtype <> 'Carboys' AND pckngtype <> 'IBC Tank' AND pckngtype <> 'HDPE Drums' AND
		 	pckngtype <> 'MS Drum' AND pckngtype <> 'Jumbo bag' AND pckngtype <> 'Loose' AND pckngtype <> 'Tanker Load' AND pckngtype <> 'ISO Tank' AND pckngtype <> 'Box' then
				error :=133;
				error_message := N'Please select proper packing type';
			END IF;
			IF typpltibc IS NULL  then
				error :=133;
				error_message := N'Please enter Type of pallets/IBC';
			END IF;
			IF typpltibc <> 'COUNTRY WOOD PALLETS' and typpltibc <> 'IBC TANK' and typpltibc <> 'ISO TANK' and
			typpltibc <> 'PINE WOOD PALLETS' and typpltibc <> 'PLASTIC PALLETS' and typpltibc <> 'BAGS' and typpltibc <> 'BOX' then
				error :=133;
				error_message := N'Please enter Type of pallets/IBC/ISO';
			END IF;
			IF lictype IS NULL  then
				error :=133;
				error_message := N'Please enter License Type';
			END IF;
			IF lictype <> 'No Required' then
				IF licno IS NULL THEN
					error :=133;
					error_message := N'Please enter License No';
				END IF;
			END IF;
			IF pltibc IS NULL  then
				error :=189;
				error_message := N'Please enter Pallates/IBC';
			END IF;
			IF pltibc <> 'PALLETS' AND  pltibc <> 'IBC Tank' AND  pltibc <> 'ISO Tank' AND  pltibc <> 'BAGS' AND  pltibc <> 'BOX' then
				error :=133;
				error_message := N'Please enter proper word PALLETS/IBC Tank/ISO Tank';
			END IF;
			IF Nopltibc IS NULL  then
				error :=133;
				error_message := N'Please enter No of Pallates/IBC';
			END IF;
		END IF;
	    --IF ItemCd in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013') and (QCBatchNo IS NULL or QCBatchNo = '') then
			--error := 133;
			--error_message := N'Please enter QC Batch No.';
		--END IF;

		IF ExportAR='Y' THEN
			IF lictype IS NULL  then
				error :=133;
				error_message := N'Please enter License Type';
			END IF;
			IF lictype <> 'No Required' then
				IF licno IS NULL THEN
					error :=1355;
					error_message := N'Please enter License No';
				END IF;
			END IF;
		END IF;
		MinAR := MinAR + 1;
	END WHILE;
END IF;

IF object_type = '13' AND (:transaction_type = 'A') THEN

DECLARE MinAR Int;
DECLARE MaxAR Int;
DECLARE typpltibc Nvarchar(50);
DECLARE Nopltibc Nvarchar(50);
DECLARE SeriesAR Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinAR from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAR from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	(SELECT T1."SeriesName" into SeriesAR FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del);

	WHILE :MinAR <= :MaxAR DO
		SELECT T1."U_TOPLT" into typpltibc FROM INV1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_TAmount" into Nopltibc FROM INV1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		IF SeriesAR LIKE 'E%' then
			IF typpltibc IS NULL  then
				error :=134;
				error_message := N'Please enter Type of pallets/IBC';
			END IF;
			IF typpltibc <> 'COUNTRY WOOD PALLETS' and typpltibc <> 'IBC TANK' and typpltibc <> 'ISO TANK' and
			typpltibc <> 'PINE WOOD PALLETS' and typpltibc <> 'PLASTIC PALLETS' and typpltibc <> 'BAGS'  and typpltibc <> 'BOX' then
				error :=134;
				error_message := N'Please enter proper Type of pallets/IBC';
			END IF;
			IF Nopltibc IS NULL  then
				error :=134;
				error_message := N'Please enter No of Pallates/IBC';
			END IF;
		END IF;
		MinAR := MinAR + 1;
	END WHILE;
END IF;


IF object_type = '15' AND (:transaction_type = 'A' or :transaction_type = 'U') THEN

DECLARE MinDL Int;
DECLARE MaxDL Int;
DECLARE PerUntQty Nvarchar(50);
DECLARE Ttlunt Nvarchar(50);
DECLARE Wghtpckng Nvarchar(50);
DECLARE pckngtype Nvarchar(50);
DECLARE typpltibc Nvarchar(50);
DECLARE lictype Nvarchar(50);
DECLARE licno Nvarchar(50);
DECLARE pltibc Nvarchar(50);
DECLARE Nopltibc Nvarchar(50);
DECLARE SeriesDL Nvarchar(50);
DECLARE QCBatchNo Nvarchar(25);
DECLARE ItemCd Nvarchar(10);

	SELECT Min(T0."VisOrder") INTO MinDL from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxDL from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	(SELECT T1."SeriesName" into SeriesDL FROM ODLN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"	WHERE T0."DocEntry"= :list_of_cols_val_tab_del);

	WHILE :MinDL <= :MaxDL DO
		SELECT T1."Factor1" into PerUntQty FROM DLN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT T1."Factor3" into Ttlunt FROM DLN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT T1."U_WOPT" into Wghtpckng FROM DLN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT T1."U_PTYPE" into pckngtype FROM DLN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT T1."U_TOPLT" into typpltibc FROM DLN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT T1."U_LicenseType" into lictype FROM DLN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT T1."U_LicenseNum" into licno FROM DLN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT T1."U_NoPalates" into pltibc FROM DLN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT T1."U_TAmount" into Nopltibc FROM DLN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT T1."ItemCode" into ItemCd FROM DLN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT T1."U_QCBatchNo" into QCBatchNo FROM DLN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;

		IF SeriesDL LIKE 'E%' then
			IF PerUntQty IS NULL  then
				error :=135;
				error_message := N'Please enter Per unit quantity';
			END IF;
			IF Ttlunt IS NULL  then
				error :=135;
				error_message := N'Please enter Total unit';
			END IF;
			IF Wghtpckng IS NULL  then
				error :=135;
				error_message := N'Please enter weight of packing type';
			END IF;
			IF pckngtype IS NULL  then
				error :=135;
				error_message := N'Please enter packing type';
			END IF;
			IF pckngtype <> 'Bags' AND pckngtype <> 'Carboys' AND pckngtype <> 'Carboys' AND pckngtype <> 'IBC Tank' AND pckngtype <> 'HDPE Drums' AND
		 		pckngtype <> 'MS Drum' AND pckngtype <> 'Jumbo bag' AND pckngtype <> 'Loose' AND pckngtype <> 'Tanker Load' AND pckngtype <> 'ISO Tank' AND pckngtype <> 'Box' then
				error :=135;
				error_message := N'Please select proper packing type';
			END IF;
			IF typpltibc IS NULL  then
				error :=135;
				error_message := N'Please enter Type of pallets/IBC';
			END IF;
			IF typpltibc <> 'COUNTRY WOOD PALLETS' and typpltibc <> 'IBC TANK' and typpltibc <> 'ISO TANK' and
				typpltibc <> 'PINE WOOD PALLETS' and typpltibc <> 'PLASTIC PALLETS' and typpltibc <> 'BAGS' and typpltibc <> 'BOX' then
				error :=135;
				error_message := N'Please enter proper Type of pallets/IBC/ISO';
			END IF;
			IF lictype IS NULL  then
				error :=135;
				error_message := N'Please enter License Type';
			END IF;
			IF licno IS NULL and lictype <> 'DBK' then
				error :=135;
				error_message := N'Please enter License No';
			END IF;
			IF pltibc IS NULL  then
				error :=135;
				error_message := N'Please enter Pallates/IBC';
			END IF;
			IF pltibc <> 'PALLETS' AND  pltibc <> 'IBC Tank' AND  pltibc <> 'ISO Tank' AND  pltibc <> 'BAGS' AND  pltibc <> 'BOX' then
				error :=135;
				error_message := N'Please enter proper word PALLETS/IBC Tank/ISO Tank';
			END IF;
			IF Nopltibc IS NULL  then
				error :=135;
				error_message := N'Please enter No of Pallates/IBC';
			END IF;
			IF ItemCd in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013') and (QCBatchNo IS NULL or QCBatchNo = '') then
				error := 135;
				error_message := N'Please enter QC Batch No.';
			END IF;
		END IF;
		MinDL := MinDL + 1;
	END WHILE;
END IF;

IF Object_type = '18' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare BaseType nvarchar(50);
(Select max(PCH1."BaseType") into BaseType
	from PCH1 inner join OPCH on OPCH."DocEntry"=PCH1."DocEntry"
	inner join OITM on PCH1."ItemCode" = OITM."ItemCode" and OITM."InvntItem" = 'Y'
	where OPCH."DocEntry"=list_of_cols_val_tab_del);

          IF (BaseType = '22') then
                  error :=137;
                  error_message := N'Please Select proper Base Document';
         End If;
End If;

IF object_type = '18' and (:transaction_type = 'A' or :transaction_type = 'U') THEN

	Declare BASEDOCNO int;
	Declare ITEMCODE  varchar(50);
	Declare BSITEMCODE  varchar(50);
	Declare BASETYPE  varchar(50);
	Declare Countt int;
	DECLARE MINN int;
	DECLARE MAXX int;
	Declare APSeries  varchar(50);
	Declare APCC  varchar(50);

	Select MIN(T0."VisOrder") into MINN from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXX from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into APSeries FROM OPCH T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del;
	SELECT T0."CardCode" into APCC FROM OPCH T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	IF APSeries NOT LIKE 'CL%' then
			WHILE MINN<=MAXX DO
					Select T0."U_BASEDOCNO" into BASEDOCNO from PCH1 T0 INNER JOIN OPCH T1 ON T0."DocEntry" = T1."DocEntry" WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINN ;
					Select T0."U_BASETYPE" into BASETYPE from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINN;
					Select T0."U_UNE_ITCD" into BSITEMCODE from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINN;
					Select T0."ItemCode" into ITEMCODE from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINN;
					Select Count(T0."ItemCode") into Countt from PCH1 T0 INNER JOIN OPCH T1 ON T0."DocEntry" = T1."DocEntry" WHERE T0."U_BASEDOCNO" = BASEDOCNO
					and T0."ItemCode" = ITEMCODE and T1."CardCode" = APCC and T0."U_BASETYPE" =BASETYPE and T1."CANCELED" = 'N' and T1."DocDate">='20250401';
					IF BASEDOCNO IS NOT NULL THEN
						IF (Countt > 1) THEN
							 error:=138;
							 error_message :='Not Allowed to select same base doc no of same item. ' || ITEMCODE;
						END IF;
					END IF;
				 MINN = MINN + 1;
			END WHILE;
	END IF;
END IF;

IF object_type = '18' and (:transaction_type = 'A' ) THEN
	Declare BASEDOCTYPE  varchar(50);
	DECLARE MINNAP int;
	DECLARE MAXXAP int;
	DECLARE APSeries varchar(50);
	DECLARE BaseCode varchar(50);
	DECLARE BaseMainItem varchar(50);
	  Select MIN(T0."VisOrder") into MINNAP from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	  Select MAX(T0."VisOrder") into MAXXAP from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	  (SELECT T1."SeriesName" into APSeries FROM OPCH T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del);

	WHILE MINNAP<=MAXXAP
	DO
		Select T0."U_BASETYPE" into BASEDOCTYPE from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = :MINNAP;
		Select T0."ItemCode" into BaseMainItem from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = :MINNAP;

		Select T0."U_UNE_ITCD" into BaseCode from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = :MINNAP;

		IF BaseMainItem <> 'SCRM0016' then
			IF (BASEDOCTYPE IS NULL OR BASEDOCTYPE = '') and APSeries NOT LIKE 'CL%'THEN
				 error:='140';
				 error_message :='Please select Base Doc Type. ' ;
			END IF;
			IF (BASEDOCTYPE <> 'NA' and BaseMainItem = 'SER0038')  then
				IF (BaseCode IS NULL OR BaseCode = '') and APSeries NOT LIKE 'CL%' THEN
					error:='140';
					 error_message :='Please select Base Doc item code ' ;
				END IF;
			END IF;
		END IF;
		 MINNAP = MINNAP + 1;
	END WHILE;
END IF;

If object_type = '20' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE POUNITPRICE varchar(50);
	DECLARE GRPOUNITPRICE varchar(50);
	DECLARE MINNGRPO int;
	DECLARE MAXXGRPO int;
	DECLARE GRPOSeries varchar(50);
	DECLARE GRPOCode varchar(50);
	Select MIN(T0."VisOrder") into MINNGRPO from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXGRPO from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into GRPOSeries FROM OPDN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del;
	IF GRPOSeries NOT LIKE 'CL%' then
		WHILE MINNGRPO<=MAXXGRPO
		DO
			select T0."ItemCode" into GRPOCode from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINNGRPO;

			IF GRPOCode NOT LIKE 'PCPM%' THEN
				select T1."Price" into POUNITPRICE FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN PDN1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OPDN T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO;

				select T3."Price" into GRPOUNITPRICE FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN PDN1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OPDN T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO;

				IF POUNITPRICE IS NOT NULL THEN
					IF POUNITPRICE != GRPOUNITPRICE THEN
						error:='141';
						error_message :='Price difference. Line No'||MINNGRPO;
					END IF;
				END IF;
			END IF;
			MINNGRPO = MINNGRPO + 1;
		END WHILE;
	END IF;
END IF;

If object_type = '18' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE GRPOUNITPRICE varchar(50);
	DECLARE APUNITPRICE varchar(50);
	DECLARE MINNAP int;
	DECLARE MAXXAP int;
	DECLARE Itms varchar(50);
	DECLARE APSeries varchar(50);
	DECLARE APbstype varchar(50);

	Select MIN(T0."VisOrder") into MINNAP from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAP from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into APSeries FROM OPCH T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	WHILE MINNAP<=MAXXAP
	DO
		Select PCH1."BaseType" into APbstype from PCH1 WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder" =  MINNAP;
		IF APSeries NOT LIKE 'CL%' and APbstype = '20' then
			select T1."Price" into GRPOUNITPRICE FROM PDN1 T1 LEFT OUTER JOIN OPDN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN PCH1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OPCH T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAP;

			select T3."Price" into APUNITPRICE FROM PDN1 T1 LEFT OUTER JOIN OPDN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN PCH1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OPCH T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAP;

			IF GRPOUNITPRICE IS NOT NULL THEN
				IF GRPOUNITPRICE != APUNITPRICE THEN
					error:='142';
					error_message :='Price difference. Line No';
				END IF;
			END IF;
		END IF;
		MINNAP = MINNAP + 1;
	END WHILE;
END IF;

If object_type = '18' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE POUNITPRICE varchar(50);
	DECLARE APUNITPRICE varchar(50);
	DECLARE MINNAP int;
	DECLARE MAXXAP int;
	DECLARE Itm varchar(50);
	DECLARE ItemCode varchar(50);
	DECLARE APSeries varchar(50);
	DECLARE APbstype varchar(50);

	Select MIN(T0."VisOrder") into MINNAP from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAP from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into APSeries FROM OPCH T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	WHILE MINNAP<=MAXXAP
	DO
		Select PCH1."ItemCode" into ItemCode from PCH1 WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder" =  MINNAP;
		Select PCH1."BaseType" into APbstype from PCH1 WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder" =  MINNAP;
		IF APSeries NOT LIKE 'CL%' and APbstype = '22' and ItemCode IS NOT NULL then

			select T1."Price" into POUNITPRICE FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN PCH1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OPCH T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAP;

			select T3."Price" into APUNITPRICE FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN PCH1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OPCH T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAP;

			Select OITM."InvntItem" into Itm from PCH1 INNER JOIN OITM ON PCH1."ItemCode" = OITM."ItemCode"
			WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder" =  MINNAP;
			IF Itm = 'Y' THEN
				IF POUNITPRICE IS NOT NULL THEN
					IF POUNITPRICE != APUNITPRICE THEN
						error:='142';
						error_message :='Price difference. Line No :';
					END IF;
				END IF;
			END IF;
		END IF;
		MINNAP = MINNAP + 1;
	END WHILE;
END IF;

IF object_type = '18' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE APQTD Int;
DECLARE MinLineAPQ Int;
DECLARE MaxLineAPQ Int;
DECLARE POQTB Int;
DECLARE Itm varchar(50);
DECLARE APSeries varchar(50);
DECLARE DocTyp varchar(50);

	SELECT Min(T0."VisOrder") INTO MinLineAPQ from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineAPQ from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into APSeries FROM OPCH T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	  Select OPCH."DocType" into DocTyp from OPCH WHERE OPCH."DocEntry" = :list_of_cols_val_tab_del;

	IF DocTyp = 'I' then
		WHILE :MinLineAPQ<=MaxLineAPQ DO

			SELECT Distinct (PCH1."Quantity") INTO APQTD FROM PCH1  where PCH1."DocEntry" =:list_of_cols_val_tab_del and PCH1."VisOrder"=MinLineAPQ ;
			SELECT Distinct (PCH1."BaseOpnQty") INTO POQTB FROM PCH1  where PCH1."DocEntry" =:list_of_cols_val_tab_del and PCH1."VisOrder"=MinLineAPQ ;
			Select OITM."InvntItem" into Itm from PCH1 INNER JOIN OITM ON PCH1."ItemCode" = OITM."ItemCode" WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder" =  MinLineAPQ;

			IF Itm = 'N' and APSeries NOT LIKE 'CL%' then
				IF POQTB > 0 THEN
					IF  (APQTD > POQTB) THEN
						error :=1440;
						error_message := 'AP Qty. should not greater then P.O Qty.... Line No'|| MinLineAPQ || -POQTB;
					END IF;
				END IF;
			END IF;
			MinLineAPQ := MinLineAPQ+1;
		END WHILE;
	END IF;
END IF;
------------------------------------------------------
---------Only QC dept can transfer material from QC warehouse------------
IF Object_type = '67' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare Usr nvarchar(50);
Declare Frmwhs nvarchar(50);
DECLARE MinLineITQ Int;
DECLARE MaxLineITQ Int;

	SELECT Min(T0."VisOrder") INTO MinLineITQ from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineITQ from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into Usr from OWTR INNER JOIN OUSR ON OUSR."USERID" = OWTR."UserSign" where OWTR."DocEntry"= :list_of_cols_val_tab_del;

	WHILE :MinLineITQ<=MaxLineITQ DO
		select WTR1."FromWhsCod" into Frmwhs from WTR1 where WTR1."DocEntry"= :list_of_cols_val_tab_del and WTR1."VisOrder"=MinLineITQ;

			IF Frmwhs IN ('2PC-QCTR','SC-QC-TR','SC-QC','2SC-QC','JW-QC','PC-QC-TR','PC-QC','2PC-QC','3PC-QC') THEN
				If (Usr <> 'qc02' AND Usr <> 'qc03' AND Usr <> 'sap01' AND Usr <> 'engg03' AND Usr <> 'manager' AND Usr <> 'unithead1' AND Usr <> 'prod08' AND Usr <> 'dispatch') then
				    error :=14501;
				    error_message := N'You are not allowed to do inventory transfer from QC Warehouse'||MinLineITQ;
				END IF;
			END IF;

		MinLineITQ := MinLineITQ+1;
	END WHILE;
END IF;
----------------Qc dept can transfer rejected material only to QC related warehouse---------
IF Object_type = '67' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare Usr nvarchar(50);
Declare Frmwhs nvarchar(50);
Declare Towhs nvarchar(50);
DECLARE MinLineITQ Int;
DECLARE MaxLineITQ Int;

	SELECT Min(T0."VisOrder") INTO MinLineITQ from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineITQ from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into Usr from OWTR INNER JOIN OUSR ON OUSR."USERID" = OWTR."UserSign" where OWTR."DocEntry"= :list_of_cols_val_tab_del;

	WHILE :MinLineITQ<=MaxLineITQ DO
		select WTR1."FromWhsCod" into Frmwhs from WTR1 where WTR1."DocEntry"= :list_of_cols_val_tab_del
		and WTR1."VisOrder"=MinLineITQ;
		select WTR1."WhsCode" into Towhs from WTR1 where WTR1."DocEntry"= :list_of_cols_val_tab_del
		and WTR1."VisOrder"=MinLineITQ;

			IF Frmwhs LIKE '%QCR' THEN
				IF Towhs LIKE '%BT' AND Usr <> 'engg02' AND Usr <> 'engg07' THEN
					If (Usr <> 'qc02' AND Usr <> 'qc03' AND Towhs NOT IN ('2PC-QCTR','SC-QC-TR','SC-QC','2SC-QC','JW-QC','PC-QC-TR','PC-QC','2PC-QC','3PC-QC')) then
					    error :=14502;
					    error_message := N'You are not allowed to do inventory transfer by using QC Warehouse'||MinLineITQ;
					END IF;
				END IF;
			END IF;

		MinLineITQ := MinLineITQ+1;
	END WHILE;
END IF;

----------------------------Branch Transfer is allowed to store dept only-------------

IF Object_type = '67' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare Usr nvarchar(50);
Declare Frmwhs nvarchar(50);
Declare ToWhs nvarchar(50);
DECLARE MinLineITQ Int;
DECLARE MaxLineITQ Int;

	SELECT Min(T0."VisOrder") INTO MinLineITQ from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineITQ from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into Usr from OWTR INNER JOIN OUSR ON OUSR."USERID" = OWTR."UserSign" where OWTR."DocEntry"= :list_of_cols_val_tab_del;

	WHILE :MinLineITQ<=MaxLineITQ DO
		select WTR1."FromWhsCod" into Frmwhs from WTR1 where WTR1."DocEntry"= :list_of_cols_val_tab_del
		and WTR1."VisOrder"=MinLineITQ;

		select WTR1."WhsCode" into ToWhs from WTR1 where WTR1."DocEntry"= :list_of_cols_val_tab_del
		and WTR1."VisOrder"=MinLineITQ;

			IF Frmwhs LIKE '%BT' THEN
				If (Usr <> 'engg02' AND Usr <> 'engg07') then
				    error :=14503;
				    error_message := N'You are not allowed to do inventory transfer from BT Warehouse'||MinLineITQ;
				END IF;
			END IF;

			IF ToWhs LIKE '%BT' THEN
				If (Usr <> 'engg02' AND Usr <> 'engg07') then
				    error :=14504;
				    error_message := N'You are not allowed to do inventory transfer by using BT Warehouse'||MinLineITQ;
				END IF;
			END IF;

		MinLineITQ := MinLineITQ+1;
	END WHILE;
END IF;

---------------- Only Store dept can transfer rejected matrial to only BT warehouse and vice-varsa----------------
IF Object_type = '67' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare Usr nvarchar(50);
Declare Frmwhs nvarchar(50);
Declare Towhs nvarchar(50);
DECLARE MinLineITQ Int;
DECLARE MaxLineITQ Int;

	SELECT Min(T0."VisOrder") INTO MinLineITQ from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineITQ from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into Usr from OWTR INNER JOIN OUSR ON OUSR."USERID" = OWTR."UserSign" where OWTR."DocEntry"= :list_of_cols_val_tab_del;

	WHILE :MinLineITQ<=MaxLineITQ DO
		select WTR1."FromWhsCod" into Frmwhs from WTR1 where WTR1."DocEntry"= :list_of_cols_val_tab_del
		and WTR1."VisOrder"=MinLineITQ;
		select WTR1."WhsCode" into Towhs from WTR1 where WTR1."DocEntry"= :list_of_cols_val_tab_del
		and WTR1."VisOrder"=MinLineITQ;

			IF Frmwhs LIKE '%QCR' THEN
				If (Usr = 'engg02' AND Usr = 'engg07' AND Towhs NOT LIKE '%BT' ) then
				    error :=14505;
				    error_message := N'You are only allowed to transfer rejected material to BT Warehouse'||MinLineITQ;
				END IF;
			END IF;

			IF Frmwhs LIKE '%BT' THEN
				If (Usr = 'engg02' AND Usr = 'engg07' AND Towhs NOT LIKE '%QCR' ) then
				    error :=14506;
				    error_message := N'You are only allowed to transfer rejected material to Rejected Warehouse'||MinLineITQ;
				END IF;
			END IF;

		MinLineITQ := MinLineITQ+1;
	END WHILE;
END IF;
------------------------------------------------------
------------------------------------------------------
/*IF object_type = '18' AND (:transaction_type = 'A') THEN

DECLARE MinAP Int;
DECLARE MaxAP Int;
DECLARE LicenseAP Nvarchar(50);
DECLARE LicneseMainAP Nvarchar(50);
DECLARE LicTypeMainAP Nvarchar(50);
DECLARE APSeries varchar(50);

	SELECT Min(T0."VisOrder") INTO MinAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into APSeries FROM OPCH T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	IF APSeries NOT LIKE 'CL%' then
		WHILE :MinAP<=MaxAP DO
			SELECT PCH1."U_LicenseType" into LicTypeMainAP FROM PCH1 WHERE PCH1."DocEntry" = list_of_cols_val_tab_del and PCH1."VisOrder"=MinAP;
			SELECT PCH1."U_LicenseNum" into LicenseAP FROM PCH1 WHERE PCH1."DocEntry" = list_of_cols_val_tab_del and PCH1."VisOrder"=MinAP;
			SELECT count("U_LCNumber") into LicneseMainAP FROM "@LICENSEMANAGER" WHERE "U_LCNumber" = LicenseAP;
			IF LicTypeMainAP NOT LIKE 'D%' then
				IF LicenseAP IS NOT NULL THEN
					IF LicneseMainAP = 0 THEN
						error :=146;
						error_message := N'This License No not available in License Master.'||LicenseAP;
					END IF;
				END IF;
			END IF;
			MinAP := MinAP+1;
		END WHILE;
	END IF;
END IF;*/

IF object_type = '13' AND (:transaction_type = 'A') THEN

DECLARE MinAR Int;
DECLARE MaxAR Int;
DECLARE LicenseAR Nvarchar(50);
DECLARE LicenseTypeAR Nvarchar(50);
DECLARE LicneseMainAR Nvarchar(50);
DECLARE ARSeries varchar(50);

	SELECT Min(T0."VisOrder") INTO MinAR from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAR from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into ARSeries FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	IF ARSeries NOT LIKE 'CL%' then
		WHILE :MinAR<=MaxAR DO
			SELECT INV1."U_LicenseNum" into LicenseAR FROM INV1 WHERE INV1."DocEntry" = list_of_cols_val_tab_del and INV1."VisOrder"=MinAR;
			SELECT INV1."U_LicenseType" into LicenseTypeAR FROM INV1 WHERE INV1."DocEntry" = list_of_cols_val_tab_del and INV1."VisOrder"=MinAR;
			SELECT count("U_LCNumber") into LicneseMainAR FROM "@LICENSEMANAGER" WHERE "U_LCNumber" = LicenseAR;
			IF LicenseAR IS NOT NULL and LicneseMainAR = 'ADVANCE' THEN
				IF LicneseMainAR = 0 THEN
					error :=147;
					error_message := N'This License No. not available in License Master.'||LicenseAR;
				END IF;
			END IF;
			MinAR := MinAR+1;
		END WHILE;
	END IF;
END IF;

IF object_type = '203' AND (:transaction_type = 'A') THEN

DECLARE MinARD Int;
DECLARE MaxARD Int;
DECLARE LicenseARD Nvarchar(50);
DECLARE LicneseMainARD Nvarchar(50);
DECLARE ARDSeries varchar(50);

	SELECT Min(T0."VisOrder") INTO MinARD from DPI1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxARD from DPI1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into ARDSeries FROM ODPI T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	IF ARDSeries NOT LIKE 'CL%' then
		WHILE :MinARD<=MaxARD DO
			SELECT DPI1."U_LicenseNum" into LicenseARD FROM DPI1 WHERE DPI1."DocEntry" = list_of_cols_val_tab_del and DPI1."VisOrder"=MinARD;
			SELECT count("U_LCNumber") into LicneseMainARD FROM "@LICENSEMANAGER" WHERE "U_LCNumber" = LicenseARD;

			IF LicenseARD IS NOT NULL THEN
				IF LicneseMainARD = 0 THEN
					error :=148;
					error_message := N'This License No. not available in License Master.'||LicenseARD;
				END IF;
			END IF;
			MinARD := MinARD+1;
		END WHILE;
	END IF;
END IF;

IF object_type = '15' AND (:transaction_type = 'A') THEN

DECLARE MinDL Int;
DECLARE MaxDL Int;
DECLARE LicenseDL Nvarchar(50);
DECLARE LicenseTypeDL Nvarchar(50);
DECLARE LicneseMainDL Nvarchar(50);
DECLARE DLSeries varchar(50);
DECLARE ItemDL varchar(50);

	SELECT Min(T0."VisOrder") INTO MinDL from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxDL from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into DLSeries FROM ODLN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	IF DLSeries NOT LIKE 'CL%' then
		WHILE :MinDL<=MaxDL DO
			SELECT DLN1."U_LicenseNum" into LicenseDL FROM DLN1 WHERE DLN1."DocEntry" = list_of_cols_val_tab_del and DLN1."VisOrder"=MinDL;
			SELECT DLN1."U_LicenseType" into LicenseTypeDL FROM DLN1 WHERE DLN1."DocEntry" = list_of_cols_val_tab_del and DLN1."VisOrder"=MinDL;
			SELECT count("U_LCNumber") into LicneseMainDL FROM "@LICENSEMANAGER" WHERE "U_LCNumber" = LicenseDL;
			SELECT DLN1."ItemCode" into ItemDL FROM DLN1 WHERE DLN1."DocEntry" = list_of_cols_val_tab_del and DLN1."VisOrder"=MinDL;

			IF LicenseDL IS NOT NULL and LicenseTypeDL = 'ADVANCE' THEN
				IF LicneseMainDL = 0 THEN
					error :=149;
					error_message := N'This License No. not available in License Master.' ||ItemDL;
				END IF;
			END IF;
			MinDL := MinDL+1;
		END WHILE;
	END IF;
END IF;

IF object_type = '18' AND (:transaction_type = 'A') THEN

DECLARE MinAP Int;
DECLARE MaxAP Int;
DECLARE LicImportQty Nvarchar(50);
DECLARE LicUtilizeQty Nvarchar(50);
DECLARE QtyAP Nvarchar(50);
DECLARE LicenseNoAP Nvarchar(50);
DECLARE ItemCodeAP Nvarchar(50);
DECLARE LICAP Nvarchar(50);
DECLARE APSeries varchar(50);

	SELECT Min(T0."VisOrder") INTO MinAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into APSeries FROM OPCH T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	IF APSeries NOT LIKE 'CL%' then
		WHILE :MinAP<=MaxAP DO
			SELECT PCH1."U_LicenseNum" into LicenseNoAP FROM PCH1 WHERE PCH1."DocEntry" = list_of_cols_val_tab_del
				and PCH1."VisOrder"=MinAP;

			IF LicenseNoAP IS NOT NULL and LICAP IS NOT NULL THEN
				SELECT PCH1."ItemCode" into ItemCodeAP FROM PCH1 WHERE PCH1."DocEntry" = list_of_cols_val_tab_del and PCH1."VisOrder"=MinAP;

				SELECT OITM."U_Sname" into LICAP FROM PCH1 INNER JOIN OITM ON OITM."ItemCode" = PCH1."ItemCode"
					WHERE PCH1."DocEntry" = list_of_cols_val_tab_del and PCH1."VisOrder"=MinAP;

				SELECT "U_Qty" into LicImportQty FROM "@IMPORTCHILD"
					INNER JOIN "@LICENSEMANAGER" ON "@LICENSEMANAGER"."Code" = "@IMPORTCHILD"."Code"
					  WHERE "U_ItemCode" = LICAP and "U_LCNumber" = LicenseNoAP;

				SELECT SUM("U_Qty") into LicUtilizeQty FROM "@UTICHILD"
					INNER JOIN "@LICENSEMANAGER" ON "@LICENSEMANAGER"."Code" = "@UTICHILD"."Code"
				 		WHERE "U_ItemCode" = ItemCodeAP and "U_LCNumber" = LicenseNoAP;

				SELECT SUM(PCH1."Quantity") into QtyAP FROM PCH1 WHERE PCH1."DocEntry" = list_of_cols_val_tab_del
					and "ItemCode" = ItemCodeAP and "U_LicenseNum" = LicenseNoAP;

				IF LicUtilizeQty + QtyAP > LicImportQty THEN
					error :=150;
					error_message := N'Quantity of License exceed.';
				END IF;
			END IF;
			MinAP := MinAP+1;
		END WHILE;
	END IF;
END IF;

IF object_type = '202' AND (:transaction_type = 'A' or :transaction_type='U') THEN
DECLARE TankerPRO Nvarchar(50);
DECLARE ItemCodePRO Nvarchar(50);
	select T1."U_UNE_LINE" into TankerPRO from OWOR T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	select T1."ItemCode" into ItemCodePRO from OWOR T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
		IF TankerPRO IS NULL and ItemCodePRO LIKE 'PC%' then
			error :=153;
			error_message := N'Please enter Tanker load or not...';
		END IF;
END IF;

IF object_type = '202' AND (:transaction_type = 'A' or :transaction_type='U') THEN
DECLARE TankerPRO Nvarchar(50);
DECLARE ItemCodePRO Nvarchar(50);
DECLARE ItemCode1PRO Nvarchar(50);
DECLARE MinPRO Nvarchar(50);
DECLARE MaxPRO Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select T1."U_UNE_LINE" into TankerPRO from OWOR T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	select T1."ItemCode" into ItemCodePRO from OWOR T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	WHILE MinPRO<=MaxPRO DO
		select T1."ItemCode" into ItemCode1PRO from WOR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinPRO;
		IF TankerPRO = 'Y' and ItemCodePRO LIKE 'PC%' and ItemCode1PRO LIKE '%PM%' then
			error :=154;
			error_message := N'Not allowed to add packing material...';
		END IF;
		MinPRO := MinPRO+1;
	END WHILE;
END IF;

IF object_type = '202' AND (:transaction_type = 'A' or :transaction_type='U') THEN
DECLARE TankerPRO Nvarchar(50);
DECLARE ItemCodePRO Nvarchar(50);
DECLARE PMCOUNTPRO int;

	select T1."U_UNE_LINE" into TankerPRO from OWOR T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	select T1."ItemCode" into ItemCodePRO from OWOR T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	(Select  count("ItemCode") into PMCOUNTPRO from WOR1 where WOR1."DocEntry"=list_of_cols_val_tab_del and WOR1."ItemCode" LIKE '%PM%' );
		IF ItemCodePRO <> 'PCFG0247' THEN
			IF TankerPRO = 'N' and ItemCodePRO LIKE 'PC%' and PMCOUNTPRO = 0  then
			error :=155;
			error_message := N'Please add packing material...';
			END IF;
		END IF;
END IF;

IF Object_type = '13' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare CardCode nvarchar(50);
(Select OINV."CardCode" into CardCode from OINV WHERE OINV."DocEntry"=list_of_cols_val_tab_del);
          IF (CardCode = 'CPD0125') then
                  error :=157;
                  error_message := N'Something went wrong..';
         End If;
End If;

/*IF Object_type = '20' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare ItCode nvarchar(50);
Declare whssss nvarchar(50);
Declare WhsType nvarchar(50);
DECLARE MinGRN int;
DECLARE MaxGRN int;
DECLARE BPLId int;

	SELECT Min(T0."VisOrder") INTO MinGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	SELECT "BPLId" INTO BPLId FROM OPDN T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del;

	IF BPLId = 3 THEN

	WHILE MinGRN<=MaxGRN DO
		(Select PDN1."WhsCode" into whssss from PDN1 WHERE PDN1."DocEntry"=list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN);
		(Select PDN1."ItemCode" into ItCode from PDN1 WHERE PDN1."DocEntry"=list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN);
		(Select OWHS."U_UNE_JAPP" into WhsType from PDN1 INNER JOIN OWHS ON OWHS."WhsCode" = PDN1."WhsCode"
			WHERE PDN1."DocEntry"=list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN);

		IF WhsType = 'N' THEN
	         IF (ItCode LIKE '%PM%') then
	         	IF  whssss NOT LIKE '%PAC%'  then
	              error :=159;
	              error_message := N'please select packing material warehouse..';
	            END IF;
	         END IF;
        END IF;
   	MinGRN := MinGRN+1;
	END WHILE;
	End If;

	IF BPLId = 4 THEN

	WHILE MinGRN<=MaxGRN DO
		(Select PDN1."WhsCode" into whssss from PDN1 WHERE PDN1."DocEntry"=list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN);
		(Select PDN1."ItemCode" into ItCode from PDN1 WHERE PDN1."DocEntry"=list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN);
		(Select OWHS."U_UNE_JAPP" into WhsType from PDN1 INNER JOIN OWHS ON OWHS."WhsCode" = PDN1."WhsCode"
			WHERE PDN1."DocEntry"=list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN);

		IF WhsType = 'N' THEN
	         IF (ItCode LIKE 'PM%') then
	         	IF (whssss NOT LIKE '%PAC%' OR whssss NOT LIKE '2EX1PCPM') then
	              error :=159;
	              error_message := N'please select packing material warehouse..';
	            END IF;
	         END IF;
        END IF;
   	MinGRN := MinGRN+1;
	END WHILE;
	End If;

End If;*/

IF Object_type = '202' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare CmpltQty Int;
Declare IssueQty Int;
Declare Prdstatus nvarchar(50);

		(Select SUM(WOR1."IssuedQty") into IssueQty from WOR1 WHERE WOR1."DocEntry"=list_of_cols_val_tab_del);
		(Select OWOR."CmpltQty" into CmpltQty from OWOR WHERE OWOR."DocEntry"=list_of_cols_val_tab_del);
		(Select OWOR."Status" into Prdstatus from OWOR WHERE OWOR."DocEntry"=list_of_cols_val_tab_del);
		 IF Prdstatus = 'L' then
	         IF (IssueQty <> 0 and CmpltQty = 0) then
	               error :=160;
	               error_message := N'Not allowed to close production order..Contact to SAP.';
	         End If;
	         IF (IssueQty = 0 and CmpltQty <> 0) then
	               error :=160;
	               error_message := N'Not allowed to close production order..Contact to SAP.';
	         End If;
         End If;
End If;

IF Object_type = '13' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare Unit nvarchar(50);
Declare Series nvarchar(50);
Declare UsrCod nvarchar(50);
		Select NNM1."SeriesName" into Series from OINV INNER JOIN NNM1 ON OINV."Series" = NNM1."Series" WHERE OINV."DocEntry"=list_of_cols_val_tab_del;

		IF Series NOT LIKE 'CL%' THEN
			Select OINV."BPLName" into Unit from OINV WHERE OINV."DocEntry" = list_of_cols_val_tab_del;
			select OUSR."USER_CODE" into UsrCod from OINV INNER JOIN OUSR ON OUSR."USERID" = OINV."UserSign" where OINV."DocEntry"=list_of_cols_val_tab_del;

	         IF (Unit = 'UNIT - I' and Series NOT LIKE '%M%'  and UsrCod = 'dispatch01') then
	               error :=161;
	               error_message := N'Please Select DM1/2021 Series';
	         End If;
         End If;
End If;

IF Object_type = '13' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare Unit nvarchar(50);
Declare Series nvarchar(50);
Declare UsrCod nvarchar(50);

		Select NNM1."SeriesName" into Series from OINV INNER JOIN NNM1 ON OINV."Series" = NNM1."Series"	WHERE OINV."DocEntry"=list_of_cols_val_tab_del;
		Select OINV."BPLName" into Unit from OINV WHERE OINV."DocEntry" = list_of_cols_val_tab_del;
		select OUSR."USER_CODE" into UsrCod from OINV INNER JOIN OUSR ON OUSR."USERID" = OINV."UserSign" where OINV."DocEntry"=list_of_cols_val_tab_del;

		IF Series NOT LIKE 'CL2%' THEN
         IF (Unit = 'UNIT - II' and Series NOT LIKE 'DM2%' and UsrCod = 'dispatch01') then
               error :=161;
               error_message := N'Please Select DM2/2021 Series';
         End If;
        END IF;

End If;

IF Object_type = '59' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare IssueDate nvarchar(50);
Declare ReceiptDate nvarchar(50);
Declare Baserefno nvarchar(50);

		select distinct "BaseEntry" into Baserefno from IGN1 WHERE IGN1."DocEntry" = list_of_cols_val_tab_del;
		IF (Baserefno IS NOT NULL) then
			Select MAX(OIGE."DocDate") into IssueDate from IGE1 INNER JOIN OIGE ON OIGE."DocEntry" = IGE1."DocEntry" WHERE IGE1."BaseEntry" = Baserefno;

			select "DocDate" into ReceiptDate from OIGN WHERE OIGN."DocEntry" = list_of_cols_val_tab_del;

	         IF (ReceiptDate < IssueDate) then
	               error :=162;
	               error_message := N'Receipt date must be after or equal to Issue date';
	         End If;
	    END IF;
End If;

If object_type = '20' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	DECLARE POUNIT varchar(50);
	DECLARE GRPOUNIT varchar(50);
	DECLARE MINNGRPO int;
	DECLARE MAXXGRPO int;
	DECLARE GRPOSeries varchar(50);
	DECLARE Code varchar(50);
	Select MIN(T0."VisOrder") into MINNGRPO from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXGRPO from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into GRPOSeries FROM OPDN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	IF GRPOSeries NOT LIKE 'CL%' then
		WHILE MINNGRPO<=MAXXGRPO
		DO
			select T1."ItemCode" into Code FROM PDN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder" = MINNGRPO;
			IF Code <> 'PCPM0094' and Code <> 'PCPM0095' and Code <> 'PCPM0096' and Code <> 'PCPM0097' and Code <> 'PCPM0098' then
				select T2."BPLId" into POUNIT FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN PDN1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OPDN T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO;

				select T4."BPLId" into GRPOUNIT FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN PDN1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OPDN T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO;

				IF POUNIT IS NOT NULL THEN
					IF POUNIT != GRPOUNIT THEN
						error:='164';
						error_message :='Something went wrong.UNIT.'||MINNGRPO;
					END IF;
				END IF;
			End IF;
			MINNGRPO = MINNGRPO + 1;
		END WHILE;
	END IF;
END IF;


IF object_type = '20' AND (:transaction_type = 'A' ) THEN
DECLARE DateGRN1 date;
Declare Seris varchar(100);
Declare ItemC varchar(100);
DECLARE MINNIT int;
DECLARE MAXXIT int;
		Select MIN(T0."VisOrder") into MINNIT from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		Select MAX(T0."VisOrder") into MAXXIT from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		WHILE MINNIT<=MAXXIT
		DO
		select T0."DocDate" INTO DateGRN1 from OPDN T0 where T0."DocEntry" = :list_of_cols_val_tab_del;
		select T0."ItemCode" INTO ItemC from PDN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINNIT;
		Select NNM1."SeriesName" into Seris from OPDN INNER JOIN NNM1 ON OPDN."Series" = NNM1."Series"
			 WHERE OPDN."DocEntry"=list_of_cols_val_tab_del;
			IF Seris NOT LIKE 'CL%' THEN
				IF ItemC <> 'SCRM0016' THEN
					IF  DateGRN1 <> CURRENT_DATE THEN
						error :=166;
						error_message := N'GRN Not allowed in back date..';
					END IF;
				END IF;
			END IF;
		MINNIT = MINNIT + 1;
		END WHILE;
END IF;


IF object_type = '59' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE DateGR Int;
DECLARE DateCHDT Int;
		select  DAYS_BETWEEN(T0."U_UNE_CHDT",T0."DocDate") INTO DateGR from OIGN T0 where T0."DocEntry" = :list_of_cols_val_tab_del;
		select  Count(T0."U_UNE_CHDT") INTO DateCHDT from OIGN T0 where T0."DocEntry" = :list_of_cols_val_tab_del;
		IF DateCHDT > 0 THEN
			IF  DateGR > 2 THEN
				error :=167;
				error_message := N'Challan Date not allowed in back days than Receipt date..';
			END IF;
		END IF;
END IF;

------------------------GRN in 2PC-FLOR-----------------------
IF object_type = '20' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE GRPWHS Nvarchar(50);
DECLARE Branch Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;

	SELECT T0."BPLId" INTO Branch FROM OPDN T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del;

	IF Branch = 3 THEN

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinLinePDQ<=MaxLinePDQ DO
		select T0."WhsCode" INTO GRPWHS from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		IF  GRPWHS LIKE '%FLOR%' THEN
			error :=1701;
			error_message := N'Not allowed to select FLOR warehouse...!';
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;

	END IF;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE GRPWHS Nvarchar(50);
DECLARE ItemCode Nvarchar(50);
DECLARE Branch Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;

	SELECT T0."BPLId" INTO Branch FROM OPDN T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del;

	IF Branch = 4 THEN

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinLinePDQ<=MaxLinePDQ DO
		select T0."WhsCode" INTO GRPWHS from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
		select T0."ItemCode" INTO ItemCode from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

			IF ItemCode <> 'PCRM0018' THEN
				IF  (GRPWHS LIKE '%FLOR%' ) THEN
					error :=1702;
					error_message := N'Not allowed to select FLOR warehouse...!';
				END IF;
			END IF;

			IF  ( GRPWHS = '2EX1PCFG') THEN
				error :=1702;
				error_message := N'Not allowed to select 2EX1PCFG warehouse...!';
			END IF;

			IF ItemCode NOT LIKE 'PCPM%' THEN
				IF  (GRPWHS = '2EX1PCPM' OR GRPWHS = '2PC-PAC') THEN
					error :=1702;
					error_message := N'Not allowed to select Packing warehouse...!';
				END IF;
			END IF;

	MinLinePDQ := MinLinePDQ+1;
	END WHILE;

	END IF;
END IF;


-----------------------------------------------

IF object_type = 'Q_QCCH' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE RFP Nvarchar(50);
DECLARE RFPPRO int;
DECLARE PRO Nvarchar(50);
		select T0."U_RecEntry" INTO RFP from "@Q_QCCH" T0 WHERE T0."Code" = :list_of_cols_val_tab_del;
		IF RFP IS NOT NULL then
		select distinct T1."BaseRef" INTO RFPPRO from OIGN T0 INNER JOIN IGN1 T1 ON T0."DocEntry" = T1."DocEntry" WHERE T0."DocEntry" = RFP;
		select distinct T0."Status" INTO PRO from OWOR T0 WHERE T0."DocNum" = RFPPRO and T0."PostDate">='20230401';
			IF  PRO <> 'L' THEN
				error :=171;
				error_message := N'Not allowed. as Production team not closed production order yet...!';
			END IF;
		END IF;
END IF;

IF object_type = 'Q_QCCH' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE Appwhs Nvarchar(50);
DECLARE Remrk Nvarchar(500);

		select T0."U_AppWhs" INTO Appwhs from "@Q_QCCH" T0 WHERE T0."Code" = :list_of_cols_val_tab_del;
		select T0."U_Remark" INTO Remrk from "@Q_QCCH" T0 WHERE T0."Code" = :list_of_cols_val_tab_del;
		IF Appwhs LIKE '%QCR' then
			IF  Remrk IS NULL OR Remrk = '' THEN
				error :=172;
				error_message := N'Please enter QC reject comment in remark field...!';
			END IF;
		END IF;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE Seris Nvarchar(50);
DECLARE GRPWHS Nvarchar(50);
DECLARE UsrCod Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into UsrCod from OPDN INNER JOIN OUSR ON OUSR."USERID" = OPDN."UserSign" where OPDN."DocEntry"=list_of_cols_val_tab_del;
	Select NNM1."SeriesName" into Seris from OPDN INNER JOIN NNM1 ON OPDN."Series" = NNM1."Series" WHERE OPDN."DocEntry"=list_of_cols_val_tab_del;

	WHILE :MinLinePDQ<=MaxLinePDQ DO
		select T0."WhsCode" INTO GRPWHS from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		IF UsrCod = 'dispatch01' and Seris NOT LIKE 'CL%' THEN
			IF GRPWHS NOT LIKE '%SSPL%' AND GRPWHS NOT LIKE '%PDI%' AND GRPWHS NOT LIKE '%ADVP%' AND GRPWHS NOT LIKE '%GJCM%' AND GRPWHS NOT LIKE '%AP%' AND GRPWHS NOT LIKE '%DE%' THEN
				error :=173;
				error_message := N'Wrong warehouse selection...!';
			END IF;
			IF Seris NOT LIKE 'JC%' THEN
				error :=173;
				error_message := N'Please select job work series...!';
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;

END IF;

IF object_type = '20' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE Seris Nvarchar(50);
DECLARE GRPWHS Nvarchar(50);
DECLARE UsrCod Nvarchar(50);
DECLARE Address Int;
DECLARE Address2 Int;
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into UsrCod from OPDN INNER JOIN OUSR ON OUSR."USERID" = OPDN."UserSign" where OPDN."DocEntry"=list_of_cols_val_tab_del;
	Select NNM1."SeriesName" into Seris from OPDN INNER JOIN NNM1 ON OPDN."Series" = NNM1."Series" WHERE OPDN."DocEntry"=list_of_cols_val_tab_del;
	Select LENGTH(OPDN."Address2") into Address2 from OPDN WHERE OPDN."DocEntry"=list_of_cols_val_tab_del;
	WHILE :MinLinePDQ<=MaxLinePDQ DO
		select T0."WhsCode" INTO GRPWHS from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		select LENGTH(T0."U_UNE_CUCD") INTO Address from OWHS T0 WHERE T0."WhsCode" = GRPWHS;

		IF UsrCod = 'dispatch01' and Seris NOT LIKE '%CL%' THEN
			IF Address <> Address2 THEN
				error :=174;
				error_message := N'Please check ship to address...!';
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE Factor1 decimal;
DECLARE Seris Nvarchar(50);
DECLARE Factor3 decimal;
DECLARE Factor2 decimal;
DECLARE Code Nvarchar(50);
DECLARE Packing Nvarchar(50);
DECLARE Qty Int;
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	Select NNM1."SeriesName" into Seris from OPDN INNER JOIN NNM1 ON OPDN."Series" = NNM1."Series"
			 WHERE OPDN."DocEntry"=list_of_cols_val_tab_del;

	WHILE :MinLinePDQ<=MaxLinePDQ DO

		select T0."U_PTYPE" INTO Packing from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		select T0."ItemCode" INTO Code from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		select T0."Factor1" INTO Factor1 from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		select T0."Factor2" INTO Factor2 from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		select T0."Factor3" INTO Factor3 from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		select T0."Quantity" INTO Qty from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		IF Code <> 'SCRM0016' and Code <> 'DIRM0026' THEN
			IF Packing NOT LIKE '%anker%' and Code LIKE '%RM%' and Seris NOT LIKE '%CL%' and Packing NOT LIKE '%oose%' and Factor2 = 1 THEN
				IF (Factor1 * Factor3) <> Qty THEN
					error :=175;
					error_message := N'per Unit Quantity or Total unit may worng...!';
				END IF;
			END IF;
			IF Factor2 <> 1 then
				IF (Factor1 * Factor3 * Factor2) <> Qty THEN
					error :=175;
					error_message := N'per Unit Quantity or Total unit may worng...!';
				END IF;
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;

END IF;

IF object_type = '20' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE Seris Nvarchar(50);
DECLARE Code Nvarchar(50);
DECLARE Packing Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	Select NNM1."SeriesName" into Seris from OPDN INNER JOIN NNM1 ON OPDN."Series" = NNM1."Series"
			 WHERE OPDN."DocEntry"=list_of_cols_val_tab_del;

	WHILE :MinLinePDQ<=MaxLinePDQ DO

		select T0."U_PTYPE" INTO Packing from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
		select T0."ItemCode" INTO Code from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
		IF Code <> 'SCRM0016' THEN
			IF Seris NOT LIKE '%CL%' and Code LIKE '%RM%' THEN
				IF Packing <> 'Bags' and Packing <> 'Carboys' and Packing <> 'HDPE Drums' and Packing <> 'IBC Tank'
					and Packing <> 'MS Drum' and Packing <> 'Jumbo bag' and Packing <> 'Loose' and Packing <> 'Tanker Load' THEN
					error :=176;
					error_message := N'Please select Proper packing type...!';
				END IF;
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;

END IF;

If object_type = '20' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	DECLARE PODATE varchar(50);
	DECLARE GRPODATE varchar(50);
	DECLARE MINNGRPO int;
	DECLARE MAXXGRPO int;
	DECLARE GRPOSeries varchar(50);

	Select MIN(T0."VisOrder") into MINNGRPO from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXGRPO from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into GRPOSeries FROM OPDN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	IF GRPOSeries NOT LIKE 'CL%' then
		WHILE MINNGRPO<=MAXXGRPO
		DO

			select MAX(T2."DocDate") into PODATE FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN PDN1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OPDN T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO;

			select MAX(T4."DocDate") into GRPODATE FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN PDN1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OPDN T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO;

			IF PODATE IS NOT NULL THEN
				IF PODATE > GRPODATE THEN
					error:='177';
					error_message :='Date issue...';
				END IF;
			END IF;

			MINNGRPO = MINNGRPO + 1;
		END WHILE;
	END IF;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinLinePD Int;
DECLARE MaxLinePD Int;
DECLARE ItemCDPD Nvarchar(50);
DECLARE ItemCount Int;
Declare Whse Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinLinePD from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePD from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinLinePD<=MaxLinePD DO
		SELECT PDN1."ItemCode" into ItemCDPD FROM PDN1 WHERE PDN1."DocEntry" = list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePD;
		SELECT PDN1."WhsCode" INTO Whse FROM PDN1 where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePD;

		select Count("Code") into ItemCount From "@UNE_STAGE" WHERE "Code" =  ItemCDPD;
		IF ItemCount > 0 THEN
			IF Whse LIKE '%QC%'  THEN
				error:='178';
				error_message :='For this Item QC not required.. please select SC-RAW warehouse';
			END IF;
		END IF;
		MinLinePD := MinLinePD+1;
	END WHILE;

END IF;

IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinLinePD Int;
DECLARE MaxLinePD Int;
DECLARE ItemCDPD Nvarchar(50);
Declare Whse Nvarchar(50);
Declare Series Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinLinePD from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePD from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	SELECT T0."SeriesName" into Series FROM OPDN T1 INNER JOIN NNM1 T0 ON T0."Series" = T1."Series"
				 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;

	IF Series NOT LIKE 'CL%' THEN
		WHILE :MinLinePD<=MaxLinePD DO
			SELECT PDN1."ItemCode" into ItemCDPD FROM PDN1 WHERE PDN1."DocEntry" = list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePD;
			SELECT PDN1."WhsCode" INTO Whse FROM PDN1 where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePD;

			IF ItemCDPD LIKE 'E%' THEN
				IF Whse LIKE '%QC%'  THEN
					error:='179';
					error_message :='Wrong warehouse';
				END IF;
			END IF;
			MinLinePD := MinLinePD+1;
		END WHILE;
	END IF;
END IF;

If object_type = '13' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	DECLARE SODATE varchar(50);
	DECLARE ARDATE varchar(50);
	DECLARE MINNAR int;
	DECLARE MAXXAR int;
	DECLARE Itm varchar(50);
	DECLARE ARSeries varchar(50);
	DECLARE ARbstype varchar(50);

	Select MIN(T0."VisOrder") into MINNAR from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAR from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into ARSeries FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	WHILE MINNAR<=MAXXAR
	DO
		Select INV1."BaseType" into ARbstype from INV1
		WHERE INV1."DocEntry" = :list_of_cols_val_tab_del and INV1."VisOrder" =  MINNAR;

		IF ARSeries NOT LIKE 'CL%' and ARbstype = '17' then

			select MAX(T2."DocDate") into SODATE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN INV1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OINV T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR;

			select Top 1 T4."DocDate" into ARDATE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN INV1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OINV T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR;

			IF SODATE IS NOT NULL THEN
				IF SODATE > ARDATE THEN
					error:='180';
					error_message :='Date issue.';
				END IF;
			END IF;

		END IF;
		MINNAR = MINNAR + 1;
	END WHILE;
END IF;

If object_type = '18' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	DECLARE PODATE varchar(50);
	DECLARE APDATE varchar(50);
	DECLARE MINNAP int;
	DECLARE MAXXAP int;
	DECLARE Itm varchar(50);
	DECLARE APSeries varchar(50);
	DECLARE APbstype varchar(50);

	Select MIN(T0."VisOrder") into MINNAP from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAP from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into APSeries FROM OPCH T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	WHILE MINNAP<=MAXXAP
	DO
		Select PCH1."BaseType" into APbstype from PCH1
		WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder" =  MINNAP;

		IF APSeries NOT LIKE 'CL%' and APbstype = '17' then

			select MAX(T2."DocDate") into PODATE FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN PCH1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OPCH T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAP;

			select MAX(T4."DocDate") into APDATE FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN PCH1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OPCH T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAP;

			IF PODATE IS NOT NULL THEN
				IF PODATE > APDATE THEN
					error:='181';
					error_message :='Date issue..';
				END IF;
			END IF;

		END IF;
		MINNAP = MINNAP + 1;
	END WHILE;
END IF;

If object_type = '15' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	DECLARE SODATE varchar(50);
	DECLARE DLDATE varchar(50);
	DECLARE MINNDL int;
	DECLARE MAXXDL int;
	DECLARE DLSeries varchar(50);

	Select MIN(T0."VisOrder") into MINNDL from DLN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXDL from DLN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into DLSeries FROM ODLN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	IF DLSeries NOT LIKE 'CL%' then
		WHILE MINNDL<=MAXXDL
		DO

			select MAX(T2."DocDate") into SODATE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DLN1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODLN T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNDL;

			select MAX(T4."DocDate") into DLDATE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DLN1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODLN T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNDL;

			IF SODATE IS NOT NULL THEN
				IF SODATE > DLDATE THEN
					error:='182';
					error_message :='Date issue....';
				END IF;
			END IF;

			MINNDL = MINNDL + 1;
		END WHILE;
	END IF;
END IF;

If object_type = '13' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	DECLARE DLDATE varchar(50);
	DECLARE ARDATE varchar(50);
	DECLARE MINNAR int;
	DECLARE MAXXAR int;
	DECLARE ARSeries varchar(50);

	Select MIN(T0."VisOrder") into MINNAR from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAR from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into ARSeries FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	IF ARSeries NOT LIKE 'CL%' then
		WHILE MINNAR<=MAXXAR
		DO

			select MAX(T2."DocDate") into DLDATE FROM DLN1 T1 LEFT OUTER JOIN ODLN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN INV1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OINV T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR;

			select  MAX(T4."DocDate") into ARDATE FROM DLN1 T1 LEFT OUTER JOIN ODLN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN INV1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OINV T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR;

			IF DLDATE IS NOT NULL THEN
				IF DLDATE > ARDATE THEN
					error:='183';
					error_message :='Date issue.....';
				END IF;
			END IF;

			MINNAR = MINNAR + 1;
		END WHILE;
	END IF;
END IF;

IF object_type = 'Q_QCCH' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE RFPCode Nvarchar(50);
DECLARE AppWhs Nvarchar(50);
		select T0."U_ItemCode" INTO RFPCode from "@Q_QCCH" T0 WHERE T0."Code" = :list_of_cols_val_tab_del;
		select T0."U_AppWhs" INTO AppWhs from "@Q_QCCH" T0 WHERE T0."Code" = :list_of_cols_val_tab_del;
		IF  RFPCode LIKE '%RM%' and AppWhs LIKE '%FG%' THEN
			error :=185;
			error_message := N'Please select proper warehouse for RM...!';
		END IF;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE Packing Nvarchar(50);
DECLARE ICode Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGRN <= :MaxGRN DO
		SELECT T1."U_PTYPE" into Packing FROM PDN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGRN;
		SELECT T1."ItemCode" into ICode FROM PDN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGRN;

		IF ICode LIKE '%RM%' and ICode LIKE '%FG%' then
			IF Packing <> 'Bags' AND Packing <> 'Carboys' AND Packing <> 'IBC Tank' AND Packing <> 'HDPE Drums' AND
			 Packing <> 'MS Drum' AND Packing <> 'Jumbo bag' AND Packing <> 'Tanker Load' then
				error :=187;
				error_message := N'Please select proper packing type';
			END IF;
		END IF;

		MinGRN := MinGRN + 1;
	END WHILE;
END IF;

-------------------------------------------

IF Object_type = '15' and (:transaction_type ='A' OR :transaction_type = 'U') Then
DECLARE MinSO int;
DECLARE MaxSO int;
DECLARE SOItemCode nvarchar(50);
DECLARE SOName nvarchar(100);
DECLARE Freetext nvarchar(50);
DECLARE U_Agro_Chem nvarchar(50);
DECLARE U_Per_HM_CR nvarchar(50);
DECLARE U_Food nvarchar(50);
DECLARE U_Paints_Pigm nvarchar(50);
DECLARE U_Indus_Care nvarchar(50);
DECLARE U_Lube_Additiv nvarchar(50);
DECLARE U_Oil_Gas nvarchar(50);
DECLARE U_Textile nvarchar(50);
DECLARE Series nvarchar(50);
DECLARE U_CAS_No nvarchar(50);
DECLARE U_Other2 nvarchar(50);
DECLARE U_Other1 nvarchar(50);
DECLARE U_Pharma nvarchar(50);
DECLARE U_Mining nvarchar(50);

	(SELECT min(T0."VisOrder") Into MinSO FROM DLN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxSO FROM DLN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT T0."SeriesName" into Series FROM ODLN T1 INNER JOIN NNM1 T0 ON T0."Series"=T1."Series"
		WHERE T1."DocEntry"=:list_of_cols_val_tab_del);
	WHILE MinSO <= MaxSO
	DO
	(SELECT T1."ItemCode" into SOItemCode FROM DLN1 T1 LEFT JOIN ODLN T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);
	(SELECT T1."Dscription" into SOName FROM DLN1 T1 WHERE T1."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);
	(SELECT T1."FreeTxt" into Freetext FROM DLN1 T1 LEFT JOIN ODLN T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);
	select "U_Agro_Chem" into U_Agro_Chem from oitm where "ItemCode" = SOItemCode;
	select "U_Per_HM_CR" into U_Per_HM_CR from oitm where "ItemCode" = SOItemCode;
	select "U_Food" into U_Food from oitm where "ItemCode"= SOItemCode;
	select "U_Paints_Pigm" into U_Paints_Pigm from oitm where "ItemCode"= SOItemCode;
	select "U_Indus_Care" into U_Indus_Care from oitm where "ItemCode"= SOItemCode;
	select "U_Lube_Additiv" into U_Lube_Additiv from oitm where "ItemCode"= SOItemCode;
	select "U_Textile" into U_Textile from oitm where "ItemCode"= SOItemCode;
	select "U_Oil_Gas" into U_Oil_Gas  from oitm where "ItemCode"= SOItemCode;
	select "U_CAS_No" into U_CAS_No  from oitm where "ItemCode"= SOItemCode;
	select "U_Other1" into U_Other1  from oitm where "ItemCode"= SOItemCode;
	select "U_Other2" into U_Other2  from oitm where "ItemCode"= SOItemCode;
	select "U_Pharma" into U_Pharma  from oitm where "ItemCode"= SOItemCode;
	select "U_Mining" into U_Mining  from oitm where "ItemCode"= SOItemCode;

		IF Series NOT LIKE 'CL%' then
		IF (SOItemCode NOT LIKE 'SC%' AND SOItemCode NOT LIKE 'PCPM%' AND SOItemCode NOT LIKE 'FA%' AND SOItemCode NOT LIKE 'WS%') THEN
			IF SOName = Freetext then
			else
				IF Freetext = U_Agro_Chem then
				else
					IF Freetext = U_Per_HM_CR then
					else
						IF Freetext = U_Food then
						else
							IF Freetext = U_Paints_Pigm then
							else
								IF Freetext = U_Indus_Care then
								else
									IF Freetext = U_Textile then
									else
										IF Freetext = U_Lube_Additiv then
										else
											IF Freetext = U_Oil_Gas then
											else
												IF Freetext = U_CAS_No then
												else
													IF Freetext = U_Other1 then
													else
														IF Freetext = U_Other2 then
														else
															IF Freetext = U_Pharma then
															else
																IF Freetext = U_Mining then
																else
																	error:=188;
																	error_message:=N'Please Select Proper Alias Name Delivery (Alias Name not in master)';
																END IF;
															END IF;
														END IF;
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
		END IF;
	 MinSO=MinSO+1;
	END WHILE;
END IF;

IF Object_type = '13' and (:transaction_type ='A' OR :transaction_type = 'U') Then
DECLARE MinSO int;
DECLARE MaxSO int;
DECLARE SOItemCode nvarchar(50);
DECLARE SOName nvarchar(100);
DECLARE Freetext nvarchar(50);
DECLARE U_Agro_Chem nvarchar(50);
DECLARE U_Per_HM_CR nvarchar(50);
DECLARE U_Food nvarchar(50);
DECLARE U_Paints_Pigm nvarchar(50);
DECLARE U_Indus_Care nvarchar(50);
DECLARE U_Lube_Additiv nvarchar(50);
DECLARE U_Oil_Gas nvarchar(50);
DECLARE U_Textile nvarchar(50);
DECLARE Series nvarchar(50);
DECLARE U_CAS_No nvarchar(50);
DECLARE U_Other2 nvarchar(50);
DECLARE U_Other1 nvarchar(50);
DECLARE U_Pharma nvarchar(50);
DECLARE U_Mining nvarchar(50);

	(SELECT min(T0."VisOrder") Into MinSO FROM INV1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxSO FROM INV1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT T0."SeriesName" into Series FROM OINV T1 INNER JOIN NNM1 T0 ON T0."Series"=T1."Series"
		WHERE T1."DocEntry"=:list_of_cols_val_tab_del);
	WHILE MinSO <= MaxSO
	DO
	(SELECT T1."ItemCode" into SOItemCode FROM INV1 T1 LEFT JOIN OINV T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);
	(SELECT T1."Dscription" into SOName FROM INV1 T1 WHERE T1."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);
	(SELECT T1."FreeTxt" into Freetext FROM INV1 T1 LEFT JOIN OINV T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);
	select "U_Agro_Chem" into U_Agro_Chem from oitm where "ItemCode" = SOItemCode;
	select "U_Per_HM_CR" into U_Per_HM_CR from oitm where "ItemCode" = SOItemCode;
	select "U_Food" into U_Food from oitm where "ItemCode"= SOItemCode;
	select "U_Paints_Pigm" into U_Paints_Pigm from oitm where "ItemCode"= SOItemCode;
	select "U_Indus_Care" into U_Indus_Care from oitm where "ItemCode"= SOItemCode;
	select "U_Lube_Additiv" into U_Lube_Additiv from oitm where "ItemCode"= SOItemCode;
	select "U_Textile" into U_Textile from oitm where "ItemCode"= SOItemCode;
	select "U_Oil_Gas" into U_Oil_Gas  from oitm where "ItemCode"= SOItemCode;
	select "U_CAS_No" into U_CAS_No  from oitm where "ItemCode"= SOItemCode;
	select "U_Other1" into U_Other1  from oitm where "ItemCode"= SOItemCode;
	select "U_Other2" into U_Other2  from oitm where "ItemCode"= SOItemCode;
	select "U_Pharma" into U_Pharma  from oitm where "ItemCode"= SOItemCode;
	select "U_Mining" into U_Mining  from oitm where "ItemCode"= SOItemCode;

		IF Series NOT LIKE 'CL%' then
		IF (SOItemCode NOT LIKE 'SC%' AND SOItemCode NOT LIKE 'PCPM%' AND SOItemCode NOT LIKE 'WSTG%' AND SOItemCode NOT LIKE 'FA%' AND SOItemCode <> 'PCFG0406') THEN
			IF SOName = Freetext then
			else
				IF Freetext = U_Agro_Chem then
				else
					IF Freetext = U_Per_HM_CR then
					else
						IF Freetext = U_Food then
						else
							IF Freetext = U_Paints_Pigm then
							else
								IF Freetext = U_Indus_Care then
								else
									IF Freetext = U_Textile then
									else
										IF Freetext = U_Lube_Additiv then
										else
											IF Freetext = U_Oil_Gas then
											else
												IF Freetext = U_CAS_No then
												else
													IF Freetext = U_Other1 then
													else
														IF Freetext = U_Other2 then
														else
															IF Freetext = U_Pharma then
															else
																IF Freetext = U_Mining then
																else
																	error:=1808;
																	error_message:=N'Please Select Proper Alias Name in Invoice (Alias Name not in master)';
																END IF;
															END IF;
														END IF;
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
		END IF;
	 MinSO=MinSO+1;
	END WHILE;
END IF;

----------------- Alias name not match--------

IF Object_type = '13' and (:transaction_type ='A' OR :transaction_type = 'U') Then
DECLARE MinSO int;
DECLARE MaxSO int;
DECLARE SOItemCode nvarchar(50);
DECLARE SOName nvarchar(100);
DECLARE FreetextAR nvarchar(50);
DECLARE FreetextDL nvarchar(50);
DECLARE ARSeries nvarchar(50);
DECLARE ARbstype varchar(50);


	(SELECT min(T0."VisOrder") Into MinSO FROM INV1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxSO FROM INV1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT T0."SeriesName" into ARSeries FROM OINV T1 INNER JOIN NNM1 T0 ON T0."Series"=T1."Series"
		WHERE T1."DocEntry"=:list_of_cols_val_tab_del);
	WHILE MinSO <= MaxSO
	DO
	(SELECT T1."ItemCode" into SOItemCode FROM INV1 T1 LEFT JOIN OINV T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);
	--(SELECT T1."Dscription" into SOName FROM INV1 T1 WHERE T1."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);
	(SELECT T1."FreeTxt" into FreetextAR FROM INV1 T1 LEFT JOIN OINV T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);
	Select INV1."BaseType" into ARbstype from INV1 WHERE INV1."DocEntry" = :list_of_cols_val_tab_del and INV1."VisOrder" =  MinSO;
		IF ARSeries NOT LIKE 'CL%' and ARbstype = '15' then

	select T1."FreeTxt" into FreetextDL FROM DLN1 T1 LEFT OUTER JOIN ODLN T2 ON T1."DocEntry" = T2."DocEntry"
		LEFT OUTER JOIN INV1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
		AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OINV T4 ON T3."DocEntry" = T4."DocEntry"
		WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MinSO;


			IF (SOItemCode NOT LIKE 'SC%' AND SOItemCode NOT LIKE 'PCPM%') THEN
					IF FreetextDL <> FreetextAR then
						error:=1809;
						error_message:=N'Alias name not match with Delivery';
					END IF;
			END IF;
		END IF;
	 MinSO=MinSO+1;
	END WHILE;
END IF;

IF Object_type = '13' and (:transaction_type ='A' OR :transaction_type = 'U') Then
DECLARE MinSO int;
DECLARE MaxSO int;
DECLARE SOItemCode nvarchar(50);
DECLARE SOName nvarchar(100);
DECLARE FreetextAR nvarchar(50);
DECLARE FreetextDL nvarchar(50);
DECLARE ARSeries nvarchar(50);
DECLARE ARbstype varchar(50);


	(SELECT min(T0."VisOrder") Into MinSO FROM INV1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxSO FROM INV1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT T0."SeriesName" into ARSeries FROM OINV T1 INNER JOIN NNM1 T0 ON T0."Series"=T1."Series"
		WHERE T1."DocEntry"=:list_of_cols_val_tab_del);
	WHILE MinSO <= MaxSO
	DO
	(SELECT T1."ItemCode" into SOItemCode FROM INV1 T1 LEFT JOIN OINV T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);
	--(SELECT T1."Dscription" into SOName FROM INV1 T1 WHERE T1."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);
	(SELECT T1."FreeTxt" into FreetextAR FROM INV1 T1 LEFT JOIN OINV T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);
	Select INV1."BaseType" into ARbstype from INV1 WHERE INV1."DocEntry" = :list_of_cols_val_tab_del and INV1."VisOrder" =  MinSO;
		IF ARSeries NOT LIKE 'CL%' and ARbstype = '17' then

	select T1."FreeTxt" into FreetextDL FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
		LEFT OUTER JOIN INV1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
		AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OINV T4 ON T3."DocEntry" = T4."DocEntry"
		WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MinSO;


			IF (SOItemCode NOT LIKE 'SC%' AND SOItemCode NOT LIKE 'PCPM%') THEN
					IF FreetextDL <> FreetextAR then
						error:=1810;
						error_message:=N'Alias name not match with Sales order';
					END IF;
			END IF;
		END IF;
	 MinSO=MinSO+1;
	END WHILE;
END IF;

--------------------------------------------------------------

IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE GRPOIC Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE GRPOQTY INT;
DECLARE GRPOItem Nvarchar(50);
DECLARE Series Nvarchar(50);
DECLARE GRPOWhs Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinLinePDQ<=MaxLinePDQ DO
		SELECT PDN1."U_UNE_QTY" INTO GRPOQTY FROM PDN1  where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;
		SELECT PDN1."ItemCode" INTO GRPOItem FROM PDN1  where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;
		SELECT PDN1."WhsCode" INTO GRPOWhs FROM PDN1  where PDN1."DocEntry" =:list_of_cols_val_tab_del and PDN1."VisOrder"=MinLinePDQ ;

		IF (GRPOItem <> 'PCRM0018') and (GRPOItem <> 'OFRM0001') and (GRPOWhs NOT IN ('GJCM','PDI','ADVP','SSPL')) then
			IF GRPOItem LIKE '%RM%' then
				IF GRPOQTY = 0 then
					error :=189;
					error_message := N'Please Enter Kanta chiththi no....';
				END IF;
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;

IF object_type = '59' AND (:transaction_type = 'A') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE DRGR Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGR <= :MaxGR DO
		SELECT IGN1."OcrCode" into DRGR FROM IGN1 WHERE IGN1."DocEntry" = :list_of_cols_val_tab_del and IGN1."VisOrder"=MinGR;
		IF DRGR IS NULL OR DRGR = '' then
			error :=203;
			error_message := N'Select Distribution rule';
		END IF;
		MinGR := MinGR+1;
	END WHILE;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE PMGRN Nvarchar(50);
DECLARE PMQTY decimal;

	SELECT Min(T0."VisOrder") INTO MinGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGRN <= :MaxGRN DO
		SELECT PDN1."ItemCode" into PMGRN FROM PDN1 WHERE PDN1."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN;
		SELECT SUBSTR_AFTER(PDN1."Quantity",'.') into PMQTY FROM PDN1 WHERE PDN1."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN;
		IF PMGRN LIKE '%PM%' then
			IF 	PMQTY > 0 then
				error :=204;
				error_message := N'Decimal not allowed for Packing';
			END IF;
		END IF;
		MinGRN := MinGRN+1;
	END WHILE;
END IF;

IF object_type = '24' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE UTRSWIFT Nvarchar(50);

		SELECT ORCT."U_UTRSWIFT" into UTRSWIFT FROM ORCT WHERE ORCT."DocEntry" = :list_of_cols_val_tab_del;
		IF UTRSWIFT = '' OR UTRSWIFT IS NULL then
			error :=205;
			error_message := N'Please Enter Ref No(UTR/Swift/Cheque)';
		END IF;

END IF;

IF Object_type = '18' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare Cumutotal Int;
Declare MinAP Int;
Declare MaxAP Int;
Declare Wtax Int;
Declare CdAP Nvarchar(50);
Declare Party Nvarchar(50);
Declare Series Nvarchar(50);
Declare DType Nvarchar(50);
Declare invntry Nvarchar(50);
Declare date1 date;
Declare date2 date;

		SELECT Min(T0."VisOrder") INTO MinAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

		WHILE :MinAP <= :MaxAP DO
		(Select OPCH."DocType" into DType from OPCH where OPCH."DocEntry"=list_of_cols_val_tab_del);
		IF DType = 'I' then
		(Select IFNULL(OITM."InvntItem",'A') into invntry from PCH1 INNER JOIN OITM ON OITM."ItemCode" = PCH1."ItemCode" where PCH1."DocEntry"=list_of_cols_val_tab_del and PCH1."VisOrder" = MinAP);
		(Select OPCH."CardCode" into Party from OPCH where OPCH."DocEntry"=list_of_cols_val_tab_del);
		(Select NNM1."SeriesName" into Series from OPCH INNER JOIN NNM1 ON NNM1."Series" = OPCH."Series" where OPCH."DocEntry"=list_of_cols_val_tab_del);
		(Select OPCH."DocDate" into date1 from OPCH where OPCH."DocEntry"=list_of_cols_val_tab_del);
		(Select OPCH."TaxDate" into date2 from OPCH where OPCH."DocEntry"=list_of_cols_val_tab_del);
		(Select SUM(OPCH."DocTotal") into Cumutotal from OPCH where OPCH."CardCode" = Party and OPCH."DocDate" >= '20230401' and OPCH."DocDate" <= '20240331' and OPCH."CANCELED" = 'N');
		(Select sum(PCH5."WTAmnt") into Wtax From PCH5 Where PCH5."AbsEntry"=list_of_cols_val_tab_del);

		IF invntry = 'Y' then
			IF Party <> 'VPRD0033' and Party <> 'VEXP0391' and Party <> 'VPRD0010' AND Party <> 'VSRD0115' and Series NOT LIKE 'I%' then
				IF date2>='20210701' then
					IF (Cumutotal > 5000000) and Wtax IS NULL then
					    error :=211;
				        error_message := N'Please select withholding tax for this party FY2324';
				    End If;
				End IF;
			END IF;
		END IF;
		END IF;

		MinAP := MinAP+1;
	END WHILE;
End If;

IF object_type = '202' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinSO Nvarchar(50);
DECLARE MinSO1 Nvarchar(50);
DECLARE MinSO2 Nvarchar(50);
DECLARE MinSO3 Nvarchar(50);
DECLARE MinSO4 Nvarchar(50);
DECLARE MinSO5 Nvarchar(50);
DECLARE MaxSO Int;
DECLARE ItemCd Nvarchar(50);
DECLARE UsrCod Nvarchar(50);
DECLARE value1 INT;
DECLARE Origin Int;

	select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;
	IF UsrCod LIKE 'prod%' then
	 	select OWOR."ItemCode" into ItemCd from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
		select OWOR."OriginAbs" into Origin from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;



		SELECT Max(T0."VisOrder") INTO MaxSO from RDR1 T0 WHERE T0."DocEntry" = Origin;

		IF MaxSO = 0 then
			SELECT "ItemCode" INTO MinSO from RDR1 T0 WHERE T0."DocEntry" = Origin and T0."VisOrder" = 0;
		END IF;
		IF MaxSO = 1 then
			SELECT "ItemCode" INTO MinSO from RDR1 T0 WHERE T0."DocEntry" = Origin and T0."VisOrder" = 0;
			SELECT "ItemCode" INTO MinSO1 from RDR1 T0 WHERE T0."DocEntry" = Origin and T0."VisOrder" = 1;
		END IF;
		IF MaxSO = 2 then
			SELECT "ItemCode" INTO MinSO from RDR1 T0 WHERE T0."DocEntry" = Origin and T0."VisOrder" = 0;
			SELECT "ItemCode" INTO MinSO1 from RDR1 T0 WHERE T0."DocEntry" = Origin and T0."VisOrder" = 1;
			SELECT "ItemCode" INTO MinSO2 from RDR1 T0 WHERE T0."DocEntry" = Origin and T0."VisOrder" = 2;
		END IF;
		IF MaxSO = 3 then
			SELECT "ItemCode" INTO MinSO from RDR1 T0 WHERE T0."DocEntry" = Origin and T0."VisOrder" = 0;
			SELECT "ItemCode" INTO MinSO1 from RDR1 T0 WHERE T0."DocEntry" = Origin and T0."VisOrder" = 1;
			SELECT "ItemCode" INTO MinSO2 from RDR1 T0 WHERE T0."DocEntry" = Origin and T0."VisOrder" = 2;
			SELECT "ItemCode" INTO MinSO3 from RDR1 T0 WHERE T0."DocEntry" = Origin and T0."VisOrder" = 3;
		END IF;

		IF MaxSO = 0 then
			IF MinSO <>  ItemCd THEN
				error :=214;
				error_message := N'Sales Order item code & production item code not match';
			END IF;
		END IF;
		IF MaxSO = 1 then
			IF MinSO <>  ItemCd and MinSO1 <> ItemCd THEN
				error :=214;
				error_message := N'Sales Order item code & production item code not match1';
			END IF;
		END IF;
		IF MaxSO = 2 then
			IF MinSO <>  ItemCd and MinSO1 <> ItemCd and MinSO2 <>  ItemCd THEN
				error :=214;
				error_message := N'Sales Order item code & production item code not match2';
			END IF;
		END IF;
		IF MaxSO = 3 then
			IF MinSO <>  ItemCd and MinSO1 <> ItemCd and MinSO2 <>  ItemCd and MinSO3 <> ItemCd THEN
				error :=214;
				error_message := N'Sales Order item code & production item code not match3';
			END IF;
		END IF;

	END IF;
END IF;

IF object_type = '18' and (:transaction_type = 'A' or :transaction_type = 'U') THEN

	Declare BASEDOCNO int;
	Declare SOQTY int;
	Declare APQTY int;
	Declare ITEMCODE  varchar(50);
	Declare BASECODE  varchar(50);
	Declare BASETYPE  varchar(50);
	Declare Countt int;
	DECLARE MINN int;
	DECLARE MAXX int;
	Declare APSeries  varchar(50);
	Declare APCC  varchar(50);

	Select MIN(T0."VisOrder") into MINN from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXX from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into APSeries FROM OPCH T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del;
	SELECT T0."CardCode" into APCC FROM OPCH T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	IF APSeries NOT LIKE 'CL%' then
			WHILE MINN<=MAXX DO
					Select T0."U_BASEDOCNO" into BASEDOCNO from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINN;

					Select T0."U_UNE_ITCD" into BASECODE from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINN;

					select SUM("Quantity") INTO SOQTY from INV1 INNER JOIN OINV ON OINV."DocEntry" = INV1."DocEntry" WHERE OINV."DocNum" = BASEDOCNO and INV1."ItemCode" = BASECODE;

					select "Quantity" INTO APQTY from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINN;

					IF APQTY > SOQTY THEN
						error:='215';
						error_message :='AP Qty greater than AR Qty. ';
					END IF;
				 MINN = MINN + 1;
			END WHILE;
	END IF;
END IF;

IF Object_type = '202' and (:transaction_type ='A' OR :transaction_type = 'U') Then
Declare purity nvarchar(50);
DECLARE Item Nvarchar(50);
DECLARE UsrCod Nvarchar(50);
select OWOR."U_Purity" into purity from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;
select OWOR."ItemCode" into Item from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;
select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF UsrCod LIKE '%prod01%' THEN
		IF (Item LIKE '%SCFG%') then
			IF (purity IS NULL OR purity = '') then
		         error :=216;
		         error_message := N'Please enter purity';
		     END IF;
		END IF;
	END IF;
END IF;

If object_type = '13' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	DECLARE Qty double;
	DECLARE AQty double;
	Declare Series nvarchar(50);

	select "SeriesName" into Series FROM OINV T0 INNER JOIN NNM1 T1 ON T1."Series" = T0."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del;
	IF Series NOT LIKE 'CL%' then
	select SUM(T1."Quantity") into Qty FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del;
	select SUM(T2."U_ActualQty") into AQty FROM INV7 T2  WHERE T2."DocEntry"= :list_of_cols_val_tab_del;

	IF Qty IS NOT NULL THEN
		IF Qty <> AQty THEN
			error:='218';
			error_message :='Invoice and packing slip quantity is not matched';
		END IF;
	END IF;
	END IF;
END IF;

If object_type = '13' and (:transaction_type = 'A') then
	Declare PrtLoad nvarchar(50);
	Declare Series nvarchar(50);
	Declare Prtno int;

	select "SeriesName" into Series FROM OINV T0 INNER JOIN NNM1 T1 ON T1."Series" = T0."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del;
	select "U_PLoad" into PrtLoad FROM OINV T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del;
	select count("U_PortName") into Prtno from "@PORTMASTER" T2 WHERE T2."U_PortName" = PrtLoad;

	IF Series LIKE 'E%' then
		IF Prtno <> 1 THEN
			error:='220';
			error_message :='Please select proper port of loading';
		END IF;
	END IF;
END IF;

If object_type = '203' and (:transaction_type = 'A') then
	Declare PrtLoad nvarchar(100);
	Declare Series nvarchar(50);
	Declare Prtno int;

	select "SeriesName" into Series FROM ODPI T0 INNER JOIN NNM1 T1 ON T1."Series" = T0."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del;
	select "U_PLoad" into PrtLoad FROM ODPI T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del;
	select count(*) into Prtno  from "@PORTMASTER" T2 WHERE T2."U_PortName" = PrtLoad;
	IF Series LIKE 'E%' then
		IF Prtno <> 1 THEN
			error:='221';
			error_message :='Please select proper port of loading';
		END IF;
	END IF;
END IF;

If object_type = '13' and (:transaction_type = 'A') then
	Declare Prtdschrge nvarchar(50);
	Declare Series nvarchar(50);
	Declare Prtno int;

	select "U_PDischrg" into Prtdschrge FROM OINV T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del;
	select "SeriesName" into Series FROM OINV T0 INNER JOIN NNM1 T1 ON T1."Series" = T0."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del;
	select count("U_PortName") into Prtno from "@PORTMASTER" T2 WHERE T2."U_PortName" = Prtdschrge;

	IF Series LIKE 'E%' then
		IF Prtno <> 1 THEN
			error:='222';
			error_message :='Please select proper port of discharge';
		END IF;
	END IF;
END IF;

If object_type = '203' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	Declare Prtdschrge nvarchar(100);
	Declare Series nvarchar(50);
	Declare Prtno int;

	select "SeriesName" into Series FROM ODPI T0 INNER JOIN NNM1 T1 ON T1."Series" = T0."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del;
	select "U_PDischrg" into Prtdschrge FROM ODPI T0  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;
	select count(*) into Prtno  from "@PORTMASTER" T2 WHERE T2."U_PortName" = Prtdschrge;

	IF Series LIKE 'E%' then
		IF Prtno <> 1 THEN
			error:='223';
			error_message :='Please select proper port of discharge';
		END IF;
	END IF;
END IF;

If object_type = '13' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	Declare Inco nvarchar(50);
	Declare Series nvarchar(50);
	Declare Prtno int;

	select "SeriesName" into Series FROM OINV T0 INNER JOIN NNM1 T1 ON T1."Series" = T0."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del;
	select "U_Incoterms" into Inco FROM OINV T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del;
	select count("U_PortName") into Prtno from "@INCOTERMMASTER" T2 WHERE T2."U_PortName" = Inco;

	IF Series LIKE 'E%' then
		IF Prtno <> 1 THEN
			error:='224';
			error_message :='Please select proper Inco term';
		END IF;
	END IF;
END IF;

If object_type = '203' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	Declare Inco nvarchar(100);
	Declare Series nvarchar(50);
	Declare Prtno int;

	select "SeriesName" into Series FROM ODPI T0 INNER JOIN NNM1 T1 ON T1."Series" = T0."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del;
	select "U_Incoterms" into Inco FROM ODPI T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del;
	select count(*) into Prtno  from "@INCOTERMMASTER" T2 WHERE T2."U_PortName" = Inco;

	IF Series LIKE 'E%' then
		IF Prtno <> 1 THEN
			error:='225';
			error_message :='Please select proper Inco term';
		END IF;
	END IF;
END IF;

-------------------------------

IF Object_type = '202' and (:transaction_type ='A' OR :transaction_type ='U') Then
Declare Starttime int;
Declare Endtime int;
Declare Series nvarchar(50);
Declare Status nvarchar(50);
Declare EntryType nvarchar(50);
Declare Spc_Reason nvarchar(50);

select Count(T0."U_Starttime") into Starttime from WOR1 T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."VisOrder" = 0;
select Count(T0."U_Endtime") into Endtime from WOR1 T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."VisOrder" = 0;
select NNM1."SeriesName" into Series from OWOR INNER JOIN NNM1 ON OWOR."Series" = NNM1."Series" where OWOR."DocEntry"= :list_of_cols_val_tab_del;

	select OWOR."Status" into Status from OWOR where OWOR."DocEntry"= list_of_cols_val_tab_del;
	select OWOR."Type" into EntryType from OWOR where OWOR."DocEntry"= list_of_cols_val_tab_del;
	select OWOR."U_sp_ent_reason" into Spc_Reason from OWOR where OWOR."DocEntry"= list_of_cols_val_tab_del;


		IF Status IN ('R','L') THEN
			IF EntryType = 'S' OR (Spc_Reason IN ('Actual Blending','Special Blending') AND  EntryType = 'P' ) THEN
				IF (Series LIKE 'PC%') then
					IF (Starttime = 0) then
				         error :=226;
				         error_message := N'Please Enter Start time of production order';
				    END IF;
				    IF (Endtime = 0) then
				         error :=226;
				         error_message := N'Please Enter End time of production order';
				    END IF;
				END IF;
			END IF;
		END IF;

END IF;

------------------------

If object_type = '15' and (:transaction_type = 'A') then

	DECLARE Whsee nvarchar(50);
	DECLARE Return1 nvarchar(50);
	DECLARE date1 nvarchar(50);
	DECLARE date2 nvarchar(50);
	DECLARE date3 nvarchar(50);
	DECLARE date4 nvarchar(50);
	DECLARE Challan1 int;
	DECLARE Challan2 int;
	DECLARE Challan3 int;
	DECLARE Challan4 int;
	DECLARE SC1 nvarchar(50);
	DECLARE Challanqty1 int;
	DECLARE Challanqty2 int;
	DECLARE Challanqty3 int;
	DECLARE Challanqty4 int;
	DECLARE SC1Dt nvarchar(50);
	DECLARE MINN int;
	DECLARE MAXX int;

	Select MIN(T0."VisOrder") into MINN from DLN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXX from DLN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

		WHILE MINN<=MAXX DO
			select T1."WhsCode" into Whsee FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_Return" into Return1 FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select OWHS."U_UNE_JAPP" into Whsee from DLN1 INNER JOIN OWHS ON DLN1."WhsCode" = OWHS."WhsCode" where DLN1."DocEntry"=list_of_cols_val_tab_del and DLN1."VisOrder"=MINN;
			select T1."U_JobChallan1" into Challan1 FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JobChallan2" into Challan2 FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JobChallan3" into Challan3 FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JobChallan4" into Challan4 FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty1" into Challanqty1 FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty2" into Challanqty2 FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty3" into Challanqty3 FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty4" into Challanqty4 FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate" into date1 FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate2" into date2 FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate3" into date3 FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate4" into date4 FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_Schln1" into SC1 FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_Schld1" into SC1Dt FROM DLN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;

			IF Whsee = 'Y' and Return1 = 'Yes' THEN
				IF Challan1 IS NULL then
					error:='230';
					error_message :='Please Enter jobwork challan no1';
				End IF;
				IF Challanqty1 IS NULL then
					error:='230';
					error_message :='Please Enter jobwork challan Quantity1';
				End IF;
				IF date1 IS NULL then
					error:='230';
					error_message :='Please Enter jobwork challan Date1';
				End IF;
				IF SC1 IS NULL then
					error:='230';
					error_message :='Please Enter Subsidary no1';
				End IF;
				IF SC1Dt IS NULL then
					error:='230';
					error_message :='Please Enter Subsidary date1';
				End IF;
				IF Challan2 IS NOT NULL then
					IF Challanqty2 IS NULL THEN
						error:='230';
						error_message :='Please Enter jobwork challan Quantity2';
					END IF;
					IF date2 IS NULL THEN
						error:='230';
						error_message :='Please Enter jobwork challan date2';
					END IF;
				End IF;
				IF Challan3 IS NOT NULL then
					IF Challanqty3 IS NULL THEN
						error:='230';
						error_message :='Please Enter jobwork challan Quantity3';
					END IF;
					IF date3 IS NULL THEN
						error:='230';
						error_message :='Please Enter jobwork challan date3';
					END IF;
				End IF;
				IF Challan4 IS NOT NULL then
					IF Challanqty4 IS NULL THEN
						error:='230';
						error_message :='Please Enter jobwork challan Quantity4';
					END IF;
					IF date4 IS NULL THEN
						error:='230';
						error_message :='Please Enter jobwork challan date4';
					END IF;
				End IF;
			END IF;
			MINN = MINN + 1;
		END WHILE;
END IF;

If object_type = '13' and (:transaction_type = 'A') then

	DECLARE Whsee nvarchar(50);
	DECLARE Return1 nvarchar(50);
	DECLARE date1 nvarchar(50);
	DECLARE date2 nvarchar(50);
	DECLARE date3 nvarchar(50);
	DECLARE date4 nvarchar(50);
	DECLARE Challan1 int;
	DECLARE Challan2 int;
	DECLARE Challan3 int;
	DECLARE Challan4 int;
	DECLARE SC1 int;
	DECLARE Challanqty1 int;
	DECLARE Challanqty2 int;
	DECLARE Challanqty3 int;
	DECLARE Challanqty4 int;
	DECLARE SC1Dt date;
	DECLARE MINN int;
	DECLARE MAXX int;

	Select MIN(T0."VisOrder") into MINN from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXX from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

		WHILE MINN<=MAXX DO
			select T1."U_Return" into Return1 FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."WhsCode" into Whsee FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JobChallan1" into Challan1 FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JobChallan2" into Challan2 FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JobChallan3" into Challan3 FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JobChallan4" into Challan4 FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate" into date1 FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate2" into date2 FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate3" into date3 FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate4" into date4 FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty1" into Challanqty1 FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty2" into Challanqty2 FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty3" into Challanqty3 FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty4" into Challanqty4 FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_Schln1" into SC1 FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_Schld1" into SC1Dt FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;

			IF Return1 = 'Yes' THEN
				IF Challan1 IS NULL then
					error:='231';
					error_message :='Please Enter jobwork challan no1';
				End IF;
				IF  Challanqty1 IS NULL then
					error:='231';
					error_message :='Please Enter jobwork challan Quantity1';
				End IF;
				IF date1 IS NULL then
					error:='231';
					error_message :='Please Enter jobwork challan Date1';
				End IF;
				IF SC1 IS NULL then
					error:='231';
					error_message :='Please Enter Subsidary no1';
				End IF;
				IF SC1Dt IS NULL then
					error:='231';
					error_message :='Please Enter Subsidary date1';
				End IF;
				IF Challan2 IS NOT NULL and Challan2 >0 then
					IF Challanqty2 IS NULL THEN
						error:='105';
						error_message :='Please Enter jobwork challan Quantity2';
					END IF;
					IF date2 IS NULL THEN
						error:='231';
						error_message :='Please Enter jobwork challan date2';
					END IF;
				End IF;
				IF Challan3 IS NOT NULL  and Challan3 >0 then
					IF Challanqty3 IS NULL THEN
						error:='231';
						error_message :='Please Enter jobwork challan Quantity3';
					END IF;
					IF date3 IS NULL THEN
						error:='231';
						error_message :='Please Enter jobwork challan date3';
					END IF;
				End IF;
				IF Challan4 IS NOT NULL and Challan4 >0 then
					IF Challanqty4 IS NULL THEN
						error:='231';
						error_message :='Please Enter jobwork challan Quantity4';
					END IF;
					IF date4 IS NULL THEN
						error:='231';
						error_message :='Please Enter jobwork challan date4';
					END IF;
				End IF;
			END IF;
			MINN = MINN + 1;
		END WHILE;
END IF;

If object_type = '13' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE Return1 nvarchar(50);
	DECLARE Whsee nvarchar(50);
	DECLARE MINN int;
	DECLARE MAXX int;

	Select MIN(T0."VisOrder") into MINN from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXX from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

		WHILE MINN<=MAXX DO
			select T1."U_Return" into Return1 FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select OWHS."U_UNE_JAPP" into Whsee from INV1 INNER JOIN OWHS ON INV1."WhsCode" = OWHS."WhsCode" where INV1."DocEntry"=list_of_cols_val_tab_del and INV1."VisOrder"=MINN;

			IF Whsee = 'Y' then
				IF Return1 IS NULL OR Return1 = '' THEN
					error:='232';
					error_message :='Please Select return or not';
				END IF;
			END IF;
			MINN = MINN + 1;
		END WHILE;
END IF;

IF Object_type = '13' and (:transaction_type ='A') Then

Declare dayss int;
Declare foter nvarchar(250);
Declare Srs nvarchar(250);
Declare Base int;

	select distinct DAYS_BETWEEN(t4."DocDate",CURRENT_DATE) into dayss from OINV t4 where  t4."DocEntry"=list_of_cols_val_tab_del;
	select t5."SeriesName" into Srs from OINV t4 INNER JOIN NNM1 t5 ON t5."Series" = t4."Series" where  t4."DocEntry"=list_of_cols_val_tab_del;

		IF (dayss <> 0) and Srs NOT LIKE 'CL%' then
			error :=233;
			error_message := N'You are not allowed to create invoice in other than todays date';
		End If;

END IF;
IF Object_type = '67' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare dayss int;
Declare foter nvarchar(250);
Declare Base int;
Declare date1 nvarchar(250);

	select distinct DAYS_BETWEEN(t4."DocDate",t4."U_UNE_CHDT") into dayss from OWTR t4 where  t4."DocEntry"=list_of_cols_val_tab_del;
	select  t4."U_UNE_CHDT" into date1 from OWTR t4 where t4."DocEntry"=list_of_cols_val_tab_del;

		IF date1 IS NOT NULL THEN
			IF (dayss > 0) then
				error :=234;
				error_message := N'Error1';
			End If;
		END IF;

END IF;

IF Object_type = '13' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare dayss int;
Declare foter nvarchar(250);
Declare Srs nvarchar(250);
Declare Base int;

	select distinct DAYS_BETWEEN(t4."DocDate",t4."U_UNE_CHDT") into dayss from OINV t4 where  t4."DocEntry"=list_of_cols_val_tab_del;
	select t5."SeriesName" into Srs from OINV t4 INNER JOIN NNM1 t5 ON t5."Series" = t4."Series" where  t4."DocEntry"=list_of_cols_val_tab_del;

		IF (dayss > 0) and Srs NOT LIKE 'CL%' then
			error :=235;
			error_message := N'Error2';
		End If;

END IF;

IF Object_type = '13' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare Pterm nvarchar(250);
Declare Pdcdate nvarchar(250);
Declare Pdcchqno nvarchar(250);
Declare advanceno nvarchar(250);
Declare dominvoice int;

	select T0."U_PDCDate" into Pdcdate from OINV T0 where T0."DocEntry"=list_of_cols_val_tab_del;
	select T0."U_PDCChequeNo" into Pdcchqno from OINV T0 where T0."DocEntry"=list_of_cols_val_tab_del;
	select T0."U_AdvanceNo" into advanceno from OINV T0 where T0."DocEntry"=list_of_cols_val_tab_del;
	select T1."PymntGroup" into Pterm from OINV T0  INNER JOIN OCTG T1 ON T0."GroupNum" = T1."GroupNum"
		where T0."DocEntry"=list_of_cols_val_tab_del;
	select T0."DocRate" into dominvoice from OINV T0  where T0."DocEntry"=list_of_cols_val_tab_del;

	IF Pterm LIKE '%PDC%' then
		IF Pdcchqno IS NULL OR Pdcchqno = '' then
			error :=236;
			error_message := N'Please enter PDC Cheque no';
		End If;
		IF Pdcdate IS NULL OR Pdcdate = '' then
			error :=236;
			error_message := N'Please enter PDC Date';
		End If;
	End If;
	IF Pterm LIKE '%Advance%' then
		IF advanceno IS NULL OR advanceno = '' then
			error :=236;
			error_message := N'Please enter Advance Cheque no';
		End If;
		IF Pdcdate IS NULL OR Pdcdate = '' then
			error :=236;
			error_message := N'Please enter Advance Date';
		End If;
	End If;

END IF;

IF Object_type = 'SHIPMASTER' and (:transaction_type ='U') Then

Declare pterm date;
Declare InvDet Int;
Declare DlDet Int;
Declare DlDet1 Int;
Declare DlDetdate date;
Declare Invremark varchar(500);

		SELECT "U_InvDet1" INTO InvDet FROM "@SHIPMASTER" T0 WHERE T0."Code" = list_of_cols_val_tab_del;

		IF InvDet IS NOT NULL THEN
			SELECT distinct "BaseEntry" INTO DlDet FROM INV1 T0 WHERE T0."DocEntry" = InvDet;

			SELECT "U_RMKPRD" INTO Invremark FROM ODLN T0 WHERE T0."DocEntry" = DlDet;


			SELECT top 1 DAYS_BETWEEN(T1."DocDate",T0."U_BLDate") INTO DlDet1  FROM "@SHIPMASTER" T0 INNER JOIN OINV T1
			ON T0."U_InvDet1"=T1."DocEntry"
		 	WHERE T1."DocEntry" = InvDet;

			IF DlDet1 > 10  THEN
				IF Invremark IS NULL THEN
					error :=238;
					error_message := N'Please Enter BL delay remark in delivery & AR invoice';
				END IF;
			End If;
		END IF;

END IF;

IF Object_type = 'SHIPMASTER' and (:transaction_type ='U') Then

Declare InvDet Int;
Declare DlDet Int;
Declare bldate date;
Declare DlDet1 Int;
Declare etadate date;


	SELECT "U_InvDet1" INTO InvDet FROM "@SHIPMASTER" T0 WHERE T0."Code" = list_of_cols_val_tab_del;

	IF InvDet IS NOT NULL THEN
		SELECT T0."U_BLDate" INTO bldate  FROM "@SHIPMASTER" T0 WHERE T0."Code" = list_of_cols_val_tab_del;

		SELECT distinct "BaseEntry" INTO DlDet FROM INV1 T0 WHERE T0."DocEntry" = InvDet;

		SELECT "U_TrnspDate3" INTO etadate FROM ODLN T0 WHERE T0."DocEntry" = DlDet;

		IF bldate IS NOT NULL  THEN
			IF etadate IS NULL THEN
				error :=239;
				error_message := N'Please Enter ETA in Delivery & AR invoice';
			END IF;
		End If;
	END IF;

END IF;

If object_type = '13' and (:transaction_type = 'A') then

	DECLARE Icode nvarchar(50);
	DECLARE ItmHSN nvarchar(50);
	DECLARE InvHSN nvarchar(50);
	DECLARE MINN int;
	DECLARE MAXX int;

	Select MIN(T0."VisOrder") into MINN from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXX from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

		WHILE MINN<=MAXX DO
			select T1."ItemCode" into Icode FROM INV1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;

			IF Icode <> 'SER0121' and Icode <> 'WSTG0001' then
				select concat(concat(concat(concat("Chapter",'.'),"Heading"),'.'),"SubHeading") into ItmHSN from OCHP T0
				INNER JOIN OITM T1 ON T0."AbsEntry" = T1."ChapterID"
				INNER JOIN INV1 T2 ON T2."ItemCode" = T1."ItemCode"
				WHERE T1."ItemCode" = Icode and T2."DocEntry" = :list_of_cols_val_tab_del and T2."VisOrder" = MINN;

				select concat(concat(concat(concat("Chapter",'.'),"Heading"),'.'),"SubHeading") into InvHSN from OCHP T0
				INNER JOIN INV1 T1 ON T1."HsnEntry" = T0."AbsEntry"
				WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder" = MINN;

				IF ItmHSN <> InvHSN then
					error:='241';
					error_message :='HSN not match with master. HSN : '||InvHSN|| Icode;
				END IF;
			END IF;
			MINN = MINN + 1;
		END WHILE;
END IF;



If object_type = '20' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE Icode nvarchar(50);
	DECLARE Whs nvarchar(50);
	DECLARE MINN int;
	DECLARE MAXX int;

	Select MIN(T0."VisOrder") into MINN from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXX from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

		WHILE MINN<=MAXX DO
			select T1."ItemCode" into Icode FROM PDN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;

			select T1."WhsCode" into Whs FROM PDN1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;

			IF Icode <> 'SCRM0016' THEN
				IF Icode LIKE 'SC%' and (Whs LIKE '%PC%' OR Whs LIKE '2EX%') then
					error:='242';
					error_message := 'Warehouse selection error.pls coordinate SAP team.';
				END IF;
				IF Icode LIKE 'PC%' and Whs LIKE 'SC%' then
					error:='242';
					error_message := 'Warehouse selection error.pls coordinate SAP team.';
				END IF;
			END IF;
			MINN = MINN + 1;
		END WHILE;
END IF;

If object_type = '13' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE Icode nvarchar(50);
	DECLARE LCLFCL nvarchar(50);
	DECLARE Series1 nvarchar(50);

	select T1."U_UNE_FGRF" into LCLFCL FROM OINV T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del;
	select T1."SeriesName" into Series1 FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	IF Series1 LIKE 'E%' then
		IF LCLFCL IS NULL then
			error:='243';
			error_message :='PLease enter LCL/FCL for invoice : ';
		END IF;
		IF LCLFCL NOT IN('FCL','LCL') then
			error:='243';
			error_message :='PLease enter LCL/FCL for invoice : ';
		END IF;
	END IF;

END IF;

IF object_type = '202' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE SONO Nvarchar(50);
DECLARE FITEMPRO Nvarchar(50);
DECLARE Pack1 Nvarchar(50);
DECLARE Pack2 Nvarchar(50);
DECLARE Pack3 Nvarchar(50);
DECLARE Pack4 Nvarchar(50);
DECLARE Pack5 Nvarchar(50);
DECLARE Pack6 Nvarchar(50);
DECLARE Pack7 Nvarchar(50);
DECLARE Pack8 Nvarchar(50);
DECLARE Pack9 Nvarchar(50);
DECLARE Pack10 Nvarchar(50);
DECLARE Pack11 Nvarchar(50);
DECLARE Pack12 Nvarchar(50);
DECLARE Pack13 Nvarchar(50);
DECLARE Pack14 Nvarchar(50);
DECLARE Pack15 Nvarchar(50);
DECLARE Tanker Nvarchar(50);
DECLARE PITEMPRO Int;
DECLARE PPITEMPRO Nvarchar(50);
DECLARE PPITEMPRO1 Nvarchar(500);
DECLARE ITEMSO Nvarchar(50);
DECLARE SOPCODE Int;
DECLARE SOPCODE1 Nvarchar(50);
DECLARE CountPRO Int;

	SELECT Min(T0."VisOrder") INTO MinPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."OriginAbs" into SONO FROM OWOR T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."ItemCode" into FITEMPRO FROM OWOR T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."U_UNE_LINE" into Tanker FROM OWOR T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	WHILE :MinPRO <= :MaxPRO DO
		IF SONO IS NOT NULL and Tanker = 'N' and FITEMPRO <> 'PCFG0344' and FITEMPRO <> 'PCFG0345' THEN
			SELECT T0."U_Pack1" into Pack1 from "@SOPACKING" T0 WHERE T0."Code" = FITEMPRO;
			SELECT T0."U_Pack2" into Pack2 from "@SOPACKING" T0 WHERE T0."Code" = FITEMPRO;
			SELECT T0."U_Pack3" into Pack3 from "@SOPACKING" T0 WHERE T0."Code" = FITEMPRO;
			SELECT T0."U_Pack4" into Pack4 from "@SOPACKING" T0 WHERE T0."Code" = FITEMPRO;
			SELECT T0."U_Pack5" into Pack5 from "@SOPACKING" T0 WHERE T0."Code" = FITEMPRO;
			SELECT T0."U_Pack6" into Pack6 from "@SOPACKING" T0 WHERE T0."Code" = FITEMPRO;

			SELECT T0."U_Pack7" into Pack7 from "@SOPACKING" T0 WHERE T0."Code" = FITEMPRO;
			SELECT T0."U_Pack8" into Pack8 from "@SOPACKING" T0 WHERE T0."Code" = FITEMPRO;
			SELECT T0."U_Pack9" into Pack9 from "@SOPACKING" T0 WHERE T0."Code" = FITEMPRO;
			SELECT T0."U_Pack10" into Pack10 from "@SOPACKING" T0 WHERE T0."Code" = FITEMPRO;

			SELECT T0."U_Pack11" into Pack11 from "@SOPACKING" T0 WHERE T0."Code" = FITEMPRO;

			SELECT T0."U_Pack12" into Pack12 from "@SOPACKING" T0 WHERE T0."Code" = FITEMPRO;
			SELECT T0."U_Pack13" into Pack13 from "@SOPACKING" T0 WHERE T0."Code" = FITEMPRO;
			SELECT T0."U_Pack14" into Pack14 from "@SOPACKING" T0 WHERE T0."Code" = FITEMPRO;
			SELECT T0."U_Pack15" into Pack15 from "@SOPACKING" T0 WHERE T0."Code" = FITEMPRO;

			SELECT T1."ItemCode" into PPITEMPRO FROM WOR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinPRO;
			SELECT T1."ItemName" into PPITEMPRO1 FROM WOR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinPRO;

			IF 	PPITEMPRO LIKE 'PCPM%' then
				If PPITEMPRO1 NOT LIKE '%Pallet%' then
					IF Pack1 <> PPITEMPRO THEN
						IF Pack2 <> PPITEMPRO THEN
							IF Pack3 <> PPITEMPRO THEN
								IF Pack4 <> PPITEMPRO THEN
									IF Pack5 <> PPITEMPRO THEN
										IF Pack6 <> PPITEMPRO THEN
											IF Pack7 <> PPITEMPRO THEN
												IF Pack8 <> PPITEMPRO THEN
													IF Pack9 <> PPITEMPRO THEN
														IF Pack10 <> PPITEMPRO THEN
															IF Pack11 <> PPITEMPRO THEN
																IF Pack12 <> PPITEMPRO THEN
																	IF Pack13 <> PPITEMPRO THEN
																		IF Pack14 <> PPITEMPRO THEN
																			IF Pack15 <> PPITEMPRO THEN
																				error :=245;
																				error_message := N'Packing Code of Production & Standardisation not matched';
																			END IF;
																		END IF;
																	END IF;
																END IF;
															END IF;
														END IF;
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
		MinPRO := MinPRO + 1;
	END WHILE;
END IF;

IF object_type = '15' AND (:transaction_type = 'A') THEN
DECLARE DLQTD Int;
DECLARE MinLineDLQ Int;
DECLARE MaxLineDLQ Int;
DECLARE SOQTB Int;
DECLARE ItemCD Nvarchar(50);
DECLARE DOCTP Nvarchar (50);

	SELECT Min(T0."VisOrder") INTO MinLineDLQ from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineDLQ from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE MinLineDLQ<=MaxLineDLQ DO
		SELECT Distinct (DLN1."Quantity") INTO DLQTD FROM DLN1  where DLN1."DocEntry" =:list_of_cols_val_tab_del and DLN1."VisOrder"=MinLineDLQ ;
		SELECT Distinct (DLN1."BaseOpnQty") INTO SOQTB FROM DLN1  where DLN1."DocEntry" =:list_of_cols_val_tab_del and DLN1."VisOrder"=MinLineDLQ ;
		SELECT Distinct (DLN1."ItemCode") INTO ItemCD FROM DLN1 where DLN1."DocEntry" =:list_of_cols_val_tab_del and DLN1."VisOrder"=MinLineDLQ ;
		SELECT Distinct (ODLN."DocType") INTO DOCTP FROM ODLN Inner JOIN DLN1 ON ODLN."DocEntry"=DLN1."DocEntry" Where ODLN."DocEntry" =:list_of_cols_val_tab_del ;

		IF DOCTP = 'I' And (DLQTD > SOQTB) THEN
			error :=247;
			error_message := N'Delivery Qty. should not greater then S.O Qty...!'||ItemCD;
		END IF;

		MinLineDLQ := MinLineDLQ+1;
	END WHILE;
END IF;

IF object_type = '13' AND (:transaction_type = 'A') THEN

DECLARE ARQTD Int;
DECLARE MinLineARQ Int;
DECLARE MaxLineARQ Int;
DECLARE SOQTB Int;
DECLARE Itm varchar(50);
DECLARE ARSeries varchar(50);
DECLARE DocTyp varchar(50);

	SELECT Min(T0."VisOrder") INTO MinLineARQ from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineARQ from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into ARSeries FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	  Select OINV."DocType" into DocTyp from OINV WHERE OINV."DocEntry" = :list_of_cols_val_tab_del;

	IF DocTyp = 'I' then
		WHILE :MinLineARQ<=MaxLineARQ DO

			SELECT Distinct (INV1."Quantity") INTO ARQTD FROM INV1  where INV1."DocEntry" =:list_of_cols_val_tab_del and INV1."VisOrder"=MinLineARQ ;
			SELECT Distinct (INV1."BaseOpnQty") INTO SOQTB FROM INV1  where INV1."DocEntry" =:list_of_cols_val_tab_del and INV1."VisOrder"=MinLineARQ ;
			Select OITM."InvntItem" into Itm from INV1 INNER JOIN OITM ON INV1."ItemCode" = OITM."ItemCode" WHERE INV1."DocEntry" = :list_of_cols_val_tab_del and INV1."VisOrder" =  MinLineARQ;

			IF Itm = 'N' and ARSeries NOT LIKE 'CL%' then
				IF SOQTB > 0 THEN
					IF  (ARQTD > SOQTB) THEN
						error :=248;
						error_message := 'AR Qty. should not greater then S.O Qty.... Line No'||MinLineARQ;
					END IF;
				END IF;
			END IF;
			MinLineARQ := MinLineARQ+1;
		END WHILE;
	END IF;
END IF;

---------------------Price diff in sales-------------------

If object_type = '15' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE SOUNITPRICE varchar(50);
	DECLARE DLUNITPRICE varchar(50);
	DECLARE MINNDL int;
	DECLARE MAXXDL int;
	DECLARE DLSeries varchar(50);
	DECLARE DLCode varchar(50);
	Declare BaseDln int;

	Select MIN(T0."VisOrder") into MINNDL from DLN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXDL from DLN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	select "BaseType" into BaseDln from DLN1 T0 Where T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder"=:MINNDL;
	SELECT T1."SeriesName" into DLSeries FROM ODLN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del;
	IF BaseDln=17
	Then

	IF DLSeries NOT LIKE 'CL%' then
		WHILE MINNDL<=MAXXDL
		DO
			select T0."ItemCode" into DLCode from DLN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINNDL;

			IF DLCode NOT LIKE 'PCPM%' THEN
				select T1."Price" into SOUNITPRICE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DLN1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODLN T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNDL;

				select T3."Price" into DLUNITPRICE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DLN1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODLN T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNDL;

				IF SOUNITPRICE IS NOT NULL THEN
					IF SOUNITPRICE != DLUNITPRICE THEN
						error:='249';
						error_message :='Price difference. Line No'||MINNDL;
					END IF;
				END IF;
			END IF;
			MINNDL = MINNDL + 1;
		END WHILE;
	END IF;
	End If;
END IF;

If object_type = '13' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE DLUNITPRICE varchar(50);
	DECLARE ARUNITPRICE varchar(50);
	DECLARE MINNAR int;
	DECLARE MAXXAR int;
	DECLARE Itms varchar(50);
	DECLARE ARSeries varchar(50);
	DECLARE ARbstype varchar(50);

	Select MIN(T0."VisOrder") into MINNAR from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAR from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into ARSeries FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	WHILE MINNAR<=MAXXAR
	DO
		Select INV1."BaseType" into ARbstype from INV1 WHERE INV1."DocEntry" = :list_of_cols_val_tab_del and INV1."VisOrder" =  MINNAR;
		IF ARSeries NOT LIKE 'CL%' and ARbstype = '15' then
			select T1."Price" into DLUNITPRICE FROM DLN1 T1 LEFT OUTER JOIN ODLN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN INV1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OINV T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR;

			select T3."Price" into ARUNITPRICE FROM DLN1 T1 LEFT OUTER JOIN ODLN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN INV1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OINV T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR;

			IF DLUNITPRICE IS NOT NULL THEN
				IF DLUNITPRICE != ARUNITPRICE THEN
					error:='250';
					error_message :='Price difference. Line No';
				END IF;
			END IF;
		END IF;
		MINNAR = MINNAR + 1;
	END WHILE;
END IF;

If object_type = '13' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE DLUNITPRICE varchar(50);
	DECLARE ARUNITPRICE varchar(50);
	DECLARE MINNAR int;
	DECLARE MAXXAR int;
	DECLARE Itms varchar(50);
	DECLARE ARSeries varchar(50);
	DECLARE ARbstype varchar(50);

	Select MIN(T0."VisOrder") into MINNAR from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAR from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into ARSeries FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	WHILE MINNAR<=MAXXAR
	DO
		Select INV1."BaseType" into ARbstype from INV1 WHERE INV1."DocEntry" = :list_of_cols_val_tab_del and INV1."VisOrder" =  MINNAR;
		IF ARSeries NOT LIKE 'CL%' and ARbstype = '17' then
			select T1."Price" into DLUNITPRICE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN INV1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OINV T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR;

			select T3."Price" into ARUNITPRICE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN INV1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OINV T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR;

			IF DLUNITPRICE IS NOT NULL THEN
				IF DLUNITPRICE != ARUNITPRICE THEN
					error:='2500';
					error_message :='Price difference. Line No(Price not match with SO)';
				END IF;
			END IF;
		END IF;
		MINNAR = MINNAR + 1;
	END WHILE;
END IF;

---------------------------------------------------

IF Object_type = '20' and (:transaction_type = 'A' OR :transaction_type = 'U') then

Declare GateEntno nvarchar(50);
Declare GateEntDt nvarchar(50);
Declare Vehicle nvarchar(50);
Declare Series nvarchar(50);
Declare ItemCodeGRN nvarchar(50);
Declare MINNGRN Int;
Declare MAXXGRN Int;

select OPDN."U_UNE_GENO" into GateEntno from OPDN  where OPDN."DocEntry"= :list_of_cols_val_tab_del;
select OPDN."U_UNE_GEDT" into GateEntDt from OPDN where OPDN."DocEntry"=:list_of_cols_val_tab_del;
select OPDN."U_UNE_VehicleNo" into Vehicle from OPDN where OPDN."DocEntry"=:list_of_cols_val_tab_del;
Select MIN(T0."VisOrder") into MINNGRN from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
Select MAX(T0."VisOrder") into MAXXGRN from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

select NNM1."SeriesName" into Series FROM NNM1 INNER JOIN OPDN ON NNM1."Series" = OPDN."Series" WHERE  OPDN."DocEntry"= :list_of_cols_val_tab_del;
	WHILE MINNGRN<=MAXXGRN
	DO
		select T1."ItemCode" into ItemCodeGRN FROM PDN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder" = MINNGRN;

		If Series NOT LIKE 'J%' and Series NOT LIKE 'CL%' THEN
			IF ( GateEntno IS NULL OR GateEntno = '' ) then
				error :=251;
				error_message := N'Please enter Gate entry no.';
			End If;
			IF ( Vehicle IS NULL OR Vehicle = '' ) then
				error :=251;
				error_message := N'Please enter Vehicle no.';
			End If;
			IF ( GateEntDt IS NULL OR GateEntDt = '' ) then
				error :=251;
				error_message := N'Please enter Gate entry date.';
			End If;
		End If;
	MINNGRN = MINNGRN + 1;
	END WHILE;
End If;

-------------------------------------------------------------------------------------------------
/*IF object_type = '202' AND (:transaction_type = 'U') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE Typ Nvarchar(50);
DECLARE Approve Nvarchar(150);
DECLARE UsrCod Nvarchar(150);
DECLARE Series Nvarchar(150);

 	select OWOR."Type" into Typ from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OWOR."U_Approve" into Approve from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select NNM1."SeriesName" into Series from NNM1 INNER JOIN OWOR ON NNM1."Series" = OWOR."Series" where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF Typ = 'P' THEN
		IF (Series LIKE 'PC1%') THEN
			IF UsrCod <> 'engg05' then
				IF Approve IS NULL OR Approve <> 'Approved'  then
					error :=253;
					error_message := N'Take approval of Mukesh sir for special production order.';
				END IF;
			END IF;
		END IF;
	END IF;
END IF;*/

/*IF object_type = '202' AND (:transaction_type = 'U') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE Typ Nvarchar(50);
DECLARE Approve Nvarchar(150);
DECLARE UsrCod Nvarchar(150);
DECLARE Series Nvarchar(150);

 	select OWOR."Type" into Typ from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OWOR."U_Approve" into Approve from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select NNM1."SeriesName" into Series from NNM1 INNER JOIN OWOR ON NNM1."Series" = OWOR."Series" where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF Typ = 'P' THEN
		IF (Series LIKE 'PC2%') THEN
			IF UsrCod <> 'engg05' then
				IF Approve IS NULL OR Approve <> 'Approved'  then
					error :=253;
					error_message := N'Take approval of Mathew sir for special production order.';
				END IF;
			END IF;
		END IF;
	END IF;
END IF;*/


/*IF object_type = '202' AND (:transaction_type = 'U') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE Typ Nvarchar(50);
DECLARE Approve Nvarchar(150);
DECLARE UsrCod Nvarchar(150);
DECLARE Series Nvarchar(150);

 	select OWOR."Type" into Typ from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OWOR."U_Approve" into Approve from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
	select NNM1."SeriesName" into Series from NNM1 INNER JOIN OWOR ON NNM1."Series" = OWOR."Series" where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF Typ = 'P' THEN
		IF Series LIKE 'JW%' THEN
			IF UsrCod <> 'ramesh' then
				IF Approve IS NULL OR Approve <> 'Approved'  then
					error :=253;
					error_message := N'Take approval of Ramesh sir for special production order.';
				END IF;
			END IF;
		END IF;
	END IF;
END IF;*/

------------------------------------------------------------------------
-------------Approval for 2PE----------

/*IF object_type = '202' AND (:transaction_type = 'U') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE Typ Nvarchar(50);
DECLARE Approve Nvarchar(150);
DECLARE UsrCod Nvarchar(150);
DECLARE ItemCodePro Nvarchar(20);
DECLARE Series Nvarchar(150);

 	select OWOR."Type" into Typ from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OWOR."U_Approve" into Approve from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OWOR."ItemCode" into ItemCodePro from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select NNM1."SeriesName" into Series from NNM1 INNER JOIN OWOR ON NNM1."Series" = OWOR."Series" where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF Typ = 'S' THEN
		IF (Series LIKE 'PC2%') THEN
			IF ItemCodePro IN ('PCFG0366','PCFG0260','PCFG0376','PCFG0405') THEN
				IF UsrCod <> 'project3' then
					IF Approve IS NULL OR Approve <> 'Approved'  then
						error :=253;
						error_message := N'To By-pass Deviation for this product, Please take Mathew sir approval.';
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;
END IF;*/

/*IF object_type = '202' AND (:transaction_type = 'U') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE Typ Nvarchar(50);
DECLARE Approve Nvarchar(150);
DECLARE UsrCod Nvarchar(150);
DECLARE ItemCodePro Nvarchar(20);
DECLARE Series Nvarchar(150);

 	select OWOR."Type" into Typ from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OWOR."U_Approve" into Approve from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OWOR."ItemCode" into ItemCodePro from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select NNM1."SeriesName" into Series from NNM1 INNER JOIN OWOR ON NNM1."Series" = OWOR."Series" where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF Typ = 'S' THEN
		IF (Series LIKE 'PC1%') THEN
			IF ItemCodePro IN ('PCFG0366','PCFG0260','PCFG0376','PCFG0405') THEN
				IF UsrCod <> 'engg05' then
					IF Approve IS NULL OR Approve <> 'Approved'  then
						error :=253;
						error_message := N'To By-pass Deviation for this product, Please take Mukesh sir approval.';
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;
END IF;*/

/*IF object_type = '202' AND (:transaction_type = 'U') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE Typ Nvarchar(50);
DECLARE Approve Nvarchar(150);
DECLARE ItemCodePro Nvarchar(20);
DECLARE UsrCod Nvarchar(150);
DECLARE Series Nvarchar(150);

 	select OWOR."Type" into Typ from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OWOR."U_Approve" into Approve from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
	select OWOR."ItemCode" into ItemCodePro from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
	select NNM1."SeriesName" into Series from NNM1 INNER JOIN OWOR ON NNM1."Series" = OWOR."Series" where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF Typ = 'S' THEN
		IF Series LIKE 'JW%' THEN
			IF ItemCodePro IN ('PCFG0366','PCFG0260','PCFG0376','PCFG0405') THEN
				IF UsrCod <> 'ramesh' then
					IF Approve IS NULL OR Approve <> 'Approved'  then
						error :=253;
						error_message := N'To By-pass Deviation for this product, Please take Ramesh sir approval.';
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;
END IF;*/

--------------------------------------------------

/*IF object_type = '202' AND (:transaction_type = 'U') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE Typ Nvarchar(50);
DECLARE Approve Nvarchar(150);
DECLARE dev Nvarchar(500);
DECLARE UsrCod Nvarchar(500);
DECLARE Series Nvarchar(150);

 	select OWOR."Type" into Typ from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OWOR."U_Devallow" into dev from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;
	select NNM1."SeriesName" into Series from NNM1 INNER JOIN OWOR ON NNM1."Series" = OWOR."Series" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF Typ = 'P' and UsrCod = 'ramesh' THEN
		IF Series LIKE 'JW%' then
			IF  dev IS NULL OR dev = '' then
				error :=253;
				error_message := N'Please enter deviation percentage.';
			END IF;
		END IF;
	END IF;
END IF;*/

/*IF object_type = '202' AND (:transaction_type = 'U') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE Typ Nvarchar(50);
DECLARE Approve Nvarchar(150);
DECLARE dev Nvarchar(500);
DECLARE UsrCod Nvarchar(500);
DECLARE Series Nvarchar(150);

 	select OWOR."Type" into Typ from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OWOR."U_Devallow" into dev from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;
	select NNM1."SeriesName" into Series from NNM1 INNER JOIN OWOR ON NNM1."Series" = OWOR."Series" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF Typ = 'P' and UsrCod = 'engg05' THEN
		IF Series LIKE 'PC%' then
			IF  dev IS NULL OR dev = '' then
				error :=253;
				error_message := N'Please enter deviation percentage.';
			END IF;
		END IF;
	END IF;
END IF;*/

IF object_type = '202' AND (:transaction_type = 'U') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE Typ Nvarchar(50);
DECLARE Qty11 decimal;
DECLARE MainItemPRO Nvarchar(150);
DECLARE PlannedQt decimal;
DECLARE Qtity decimal;
DECLARE ItemPRO Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
 	select OWOR."Type" into Typ from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OWOR."ItemCode" into MainItemPRO from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
	select OWOR."PlannedQty" into PlannedQt from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF Typ = 'S' and MainItemPRO LIKE 'PC%' THEN
		WHILE :MinPRO <= :MaxPRO DO
			SELECT T1."ItemCode" into ItemPRO FROM WOR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinPRO;
			IF ItemPRO NOT LIKE '%PM%' THEN
				select ifnull(ITT1."Quantity",0) into Qty11 from OITT INNER JOIN ITT1 ON OITT."Code" = ITT1."Father" WHERE OITT."Code" = MainItemPRO
				and ITT1."Code" = ItemPRO;
				IF ItemPRO IS NOT NULL and Qty11 > 0 THEN
					SELECT T1."PlannedQty" into Qtity FROM WOR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinPRO and T1."ItemCode" NOT LIKE '%PM%';
					If (round((Qty11 * PlannedQt),3) <> round(Qtity,3)) then
				         error :=254;
				         error_message := N'Planned Qty not as per BOM. Planned Quantity : '||(Qty11 * PlannedQt);
					END IF;
				END IF;
			END IF;
			MinPRO := MinPRO + 1;
		END WHILE;
	END IF;
END IF;

IF object_type = '59' AND ( :transaction_type = 'A') THEN

DECLARE CNT Int;
	SELECT COUNT(*) INTO CNT FROM IGN1 T1 INNER JOIN IBT1 T0 ON T1."DocEntry" = T0."BaseEntry" and T0."BaseType" = '59'
	INNER JOIN OBTN ON OBTN."DistNumber" = T0."BatchNum"
	where T1."DocEntry" = :list_of_cols_val_tab_del and T1."WhsCode" NOT LIKE '%BT%' and T1."ItemCode" Like '%FG%' AND OBTN."MnfSerial" in
	(Select Ifnull(OBTN."MnfSerial",'') from IBT1 T0 INNER JOIN OBTN ON OBTN."DistNumber" = T0."BatchNum"
	INNER JOIN IGN1 T1 ON T1."DocEntry" = T0."BaseEntry" and T0."BaseType" = '59'
	where T1."ItemCode" Like '%FG%' and T1."DocEntry" <> :list_of_cols_val_tab_del);

	IF :CNT>0 THEN
		error := 25600;
		error_message := 'Duplicate Batch Number Exist Check Batch No Again';
		CNT:= 0;
	END IF;
END IF;

IF object_type = '202' AND (:transaction_type = 'U' OR :transaction_type = 'A') THEN
DECLARE IC varchar(50);
DECLARE remark varchar(500);
--DECLARE Series varchar(20);
DECLARE BPLId int;
DECLARE Date1 date;

	SELECT T1."Comments" INTO remark FROM OWOR T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."ItemCode" INTO IC FROM OWOR T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."PostDate" INTO Date1 FROM OWOR T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	--SELECT T1."SeriesName" INTO Series FROM OWOR T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT OWHS."BPLid" INTO BPLId FROM OWOR INNER JOIN OWHS ON OWOR."Warehouse" = OWHS."WhsCode" Where OWOR."DocEntry" = :list_of_cols_val_tab_del;

	IF BPLId = 3 THEN
		IF IC LIKE 'PC%' then
			IF (Date1 >= '20220101' and Date1 <= '20221231')  and remark NOT LIKE '2022/%' THEN
				error := 256;
				error_message := 'Batch may wrong';
			END IF;
			IF Date1 < '20220101' and remark NOT LIKE '2021/%' THEN
				error := 256;
				error_message := 'Batch may wrong';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and remark NOT LIKE '2023/U1/____' THEN
				error := 256;
				error_message := 'Batch may wrong';
			END IF;
		END IF;
	END IF;

	IF BPLId = 4 THEN
		IF IC LIKE 'PC%' then
			IF (Date1 >= '20220101' and Date1 <= '20221231')  and remark NOT LIKE '2022/U2/%' THEN
				error := 256;
				error_message := 'Batch may wrong';
			END IF;
			IF Date1 < '20220101' and remark NOT LIKE '2021/%' THEN
				error := 256;
				error_message := 'Batch may wrong';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and remark NOT LIKE '2023/U2/____' THEN
				error := 256;
				error_message := 'Batch may wrong';
			END IF;
		END IF;
	END IF;
END IF;


IF object_type = '59' AND ( :transaction_type = 'A') THEN

DECLARE remark varchar(500);
DECLARE Ref varchar(50);
DECLARE Series varchar(50);
DECLARE Branch varchar(50);
DECLARE Date1 date;

	SELECT T1."Comments" INTO remark FROM OIGN T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T0."SeriesName" INTO Series FROM OIGN T1 INNER JOIN NNM1 T0 ON T0."Series" = T1."Series" WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."DocDate" INTO Date1 FROM OIGN T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."Ref2" INTO Ref FROM OIGN T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."BPLName" INTO Branch FROM OIGN T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;

	IF Series LIKE 'PC%' then
		IF Branch = 'UNIT - I' THEN
			IF (Date1 >= '20220101' and Date1 <= '20221231')  and remark NOT LIKE '2022/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20220101' and Date1 <= '20221231') and Ref NOT LIKE '2022/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and remark NOT LIKE '2021/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and Ref NOT LIKE '2021/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231')  and remark NOT LIKE '2023/U1/____' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and Ref NOT LIKE '2023/U1/____' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
		END IF;

		IF Branch = 'UNIT - II' THEN
			IF (Date1 >= '20220101' and Date1 <= '20221231')  and remark NOT LIKE '2022/U2/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20220101' and Date1 <= '20221231') and Ref NOT LIKE '2022/U2/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and remark NOT LIKE '2021/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and Ref NOT LIKE '2021/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231')  and remark NOT LIKE '2023/U2/____' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and Ref NOT LIKE '2023/U2/____' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
		END IF;
	END IF;
END IF;

IF object_type = '60' AND ( :transaction_type = 'A') THEN

DECLARE remark varchar(500);
DECLARE Ref varchar(50);
DECLARE Series varchar(50);
DECLARE Branch varchar(50);
DECLARE Date1 date;

	SELECT T0."SeriesName" INTO Series FROM OIGE T1 INNER JOIN NNM1 T0 ON T0."Series" = T1."Series" WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."Comments" INTO remark FROM OIGE T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."Ref2" INTO Ref FROM OIGE T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."DocDate" INTO Date1 FROM OIGE T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."BPLName" INTO Branch FROM OIGE T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;

	IF Series LIKE 'PC%' then
		IF Branch = 'UNIT - I' THEN
			IF (Date1 >= '20220101' and Date1 <= '20221231') and remark NOT LIKE '2022/%' THEN
				error := 2580;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20220101' and Date1 <= '20221231') and Ref NOT LIKE '2022/%' THEN
				error := 2581;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and remark NOT LIKE '2021/%' THEN
				error := 2582;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and Ref NOT LIKE '2021/%' THEN
				error := 2583;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and remark NOT LIKE '2023/U1/____' THEN
				error := 2584;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and Ref NOT LIKE '2023/U1/____' THEN
				error := 2585;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
		END IF;

		IF Branch = 'UNIT - II' THEN
			IF (Date1 >= '20220101' and Date1 <= '20221231') and remark NOT LIKE '2022/U2/%' THEN
				error := 2586;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20220101' and Date1 <= '20221231') and Ref NOT LIKE '2022/U2/%' THEN
				error := 2586;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and remark NOT LIKE '2021/%' THEN
				error := 2587;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and Ref NOT LIKE '2021/%' THEN
				error := 2588;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and remark NOT LIKE '2023/U2/____' THEN
				error := 2589;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and Ref NOT LIKE '2023/U2/____' THEN
				error := 25801;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
		END IF;
	END IF;
END IF;

---------------------------------------------------------- Above 5 % deviation---------------------------

-----------update 1.4

-- FORM Name     : Production Order
-- Updated Date  : 12-05-2023
-- Note          : This SP will allow user to add attachment after production order approved.


IF object_type = '202' AND (:transaction_type = 'U') THEN

DECLARE TotalAttachment Int; -- CHANGES 1.4

DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE Typ Nvarchar(50);
DECLARE Devallow Nvarchar(50);
DECLARE MainItemPRO Nvarchar(150);
DECLARE SeriesPRO Nvarchar(150);
DECLARE Approve Nvarchar(150);
DECLARE IssuedQtyPRO decimal;
DECLARE SUMIssuedQtyPRO decimal;
DECLARE SUMBaseQtyPRO decimal;
DECLARE Ratio decimal;
DECLARE BaseRatio decimal;
DECLARE BaseQty decimal;
DECLARE ItemPRO Nvarchar(50);
DECLARE UsrCod Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del ;
	SELECT Max(T0."VisOrder") INTO MaxPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
 	select OWOR."Type" into Typ from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select NNM1."SeriesName" into SeriesPRO from OWOR INNER JOIN NNM1 ON OWOR."Series" = NNM1."Series" where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OWOR."U_Approve" into Approve from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
	select OWOR."U_Devallow" into Devallow from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
	select OWOR."ItemCode" into MainItemPRO from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into UsrCod from OWOR INNER JOIN OUSR ON OUSR."USERID" = OWOR."UserSign" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF MainItemPRO NOT IN ('PCFG0366','PCFG0260','PCFG0376','PCFG0405') THEN
		IF Typ = 'S' and SeriesPRO NOT LIKE 'SC%' THEN
			IF Approve = 'Approved' and (UsrCod = 'prod04' OR UsrCod = 'prod05' OR UsrCod = 'prod06')  then
			SELECT 	SUM(T1."IssuedQty") into SUMIssuedQtyPRO FROM WOR1 T1 WHERE T1."DocEntry" = list_of_cols_val_tab_del AND T1."ItemCode" NOT LIKE 'PCPM%'
			AND T1."ItemCode" NOT IN ('PCRM0017','PCRM0010','PCRM0001','PCRM0020','SCBP0005','PCRM0093','PCRM0076','SCRM0026','SCRM0041','PCRM0032','PCRM0120','PCRM0119');
			SELECT 	SUM(T1."BaseQty") into SUMBaseQtyPRO FROM WOR1 T1 WHERE T1."DocEntry" = list_of_cols_val_tab_del AND T1."ItemCode" NOT LIKE 'PCPM%'
			AND T1."ItemCode" NOT IN ('PCRM0017','PCRM0010','PCRM0001','PCRM0020','SCBP0005','PCRM0093','PCRM0076','SCRM0026','SCRM0041','PCRM0032','PCRM0120','PCRM0119');
				WHILE :MinPRO <= :MaxPRO DO
					SELECT T1."ItemCode" into ItemPRO FROM WOR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinPRO;
					SELECT T1."IssuedQty" into IssuedQtyPRO FROM WOR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinPRO;
					SELECT T1."BaseQty" into BaseQty FROM WOR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinPRO;

					IF ItemPRO <> 'PCRM0017' then
						IF ItemPRO <> 'PCRM0010' then
							IF ItemPRO <> 'PCRM0001' then
								IF ItemPRO <> 'PCRM0020' then
									IF ItemPRO <> 'PCRM0093' then
										IF ItemPRO <> 'PCRM0076' then
											IF ItemPRO <> 'SCRM0026' then
												IF ItemPRO <> 'SCRM0041' then
													IF ItemPRO <> 'PCRM0032' then
														IF ItemPRO <> 'PCRM0120' then
															IF ItemPRO <> 'PCRM0119' then
																IF ItemPRO <> 'SCRM0041' then
																	IF ItemPRO IS NOT NULL and IssuedQtyPRO > 0 and ItemPRO NOT LIKE '%PM%' THEN
																		SELECT (IssuedQtyPRO/SUMIssuedQtyPRO) into Ratio FROM WOR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinPRO and T1."ItemCode" NOT LIKE '%PM%';
																		SELECT (BaseQty/SUMBaseQtyPRO) into BaseRatio FROM WOR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinPRO and T1."ItemCode" NOT LIKE '%PM%';

																		SELECT COUNT(*) INTO TotalAttachment FROM OATC AS T0 LEFT JOIN OWOR AS T1 ON T1."AtcEntry" = T0."AbsEntry" WHERE T1."DocEntry" = :list_of_cols_val_tab_del; -- CHANGES 1.4
																		IF TotalAttachment = 0 THEN -- CHANGES 1.4

																		    IF (Ratio - BaseRatio) > ((BaseRatio*Devallow)/100) then
																			   error := 358100;
																			   error_message := 'As per approval. Only '||Devallow||'% deviation allowed.1   Line - '||MinPRO;
																		   END IF;
																		   IF (BaseRatio - Ratio) > ((BaseRatio*Devallow)/100) then
																		   	   error := 358444;
																			   error_message := 'As per approval. Only '||Devallow||'% deviation allowed.2   Line - '||MinPRO;
																		   END IF;

																		END IF; -- CHANGES 1.4

																	END IF;
																END IF;
															END IF;
														END IF;
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
					MinPRO := MinPRO + 1;
				END WHILE;
			END IF;
		END IF;
	END IF;
END IF;


-------------------------------------------------------------------------------------------------------------------

IF object_type = '202' AND (:transaction_type = 'U') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE Typ Nvarchar(50);
DECLARE Devallow Nvarchar(50);
DECLARE Qty11 decimal;
DECLARE MainItemPRO Nvarchar(150);
DECLARE SeriesPRO Nvarchar(150);
DECLARE Approve Nvarchar(150);
DECLARE PlannedQt decimal;
DECLARE Qtity decimal;
DECLARE IssuedQtyPRO decimal;
DECLARE CompletedQty decimal;
DECLARE ItemPRO Nvarchar(50);
DECLARE UsrCod Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del ;
	SELECT Max(T0."VisOrder") INTO MaxPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
 	select OWOR."Type" into Typ from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select NNM1."SeriesName" into SeriesPRO from OWOR INNER JOIN NNM1 ON OWOR."Series" = NNM1."Series" where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OWOR."U_Approve" into Approve from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
	select OWOR."U_Devallow" into Devallow from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
	select OWOR."PlannedQty" into PlannedQt from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
	select OWOR."CmpltQty" into CompletedQty from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF Typ = 'S' and SeriesPRO NOT LIKE 'SC%' THEN
		IF Approve = 'Approved' and (UsrCod ='prod04' OR UsrCod ='prod05') and CompletedQty > 0 then
			If (CompletedQty - PlannedQt) > ((PlannedQt*Devallow)/100) then
				 error :=259;
				 error_message := N'As per approval. Only '||Devallow||'% deviation allowed for receipt.1';
			END IF;
			If (PlannedQt - CompletedQty) > ((PlannedQt*Devallow)/100) then
				 error :=259;
				 error_message := N'As per approval. Only '||Devallow||'% deviation allowed for receipt.2';
			END IF;
		END IF;
	END IF;
END IF;


IF object_type = '202' AND (:transaction_type = 'U' OR :transaction_type = 'A') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE Typ Nvarchar(50);
DECLARE Status Nvarchar(50);
DECLARE Devallow Nvarchar(50);
DECLARE Qty11 decimal;
DECLARE MainItemPRO Nvarchar(150);
DECLARE SeriesPRO Nvarchar(150);
DECLARE Approve Nvarchar(150);
DECLARE ItemPRO Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del ;
	SELECT Max(T0."VisOrder") INTO MaxPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
 	select OWOR."Type" into Typ from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OWOR."Status" into Status from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select NNM1."SeriesName" into SeriesPRO from OWOR INNER JOIN NNM1 ON OWOR."Series" = NNM1."Series" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF Typ = 'P' and Status = 'R' and (SeriesPRO NOT LIKE 'SC%' AND SeriesPRO NOT LIKE 'BA%') THEN
	WHILE MinPRO<=MaxPRO DO
		SELECT T1."ItemCode" into ItemPRO FROM WOR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinPRO;
		IF ItemPRO <> 'PCRM0017' THEN
			IF ItemPRO LIKE 'PCRM%' then
				error := 260;
				error_message := 'You are not allowed to add PCRM in special production order';
			END IF;
		END IF;
	MinPRO = MinPRO + 1;
	END WHILE;
	END IF;
END IF;



IF object_type = '202' AND (:transaction_type = 'U' OR :transaction_type = 'A') THEN

DECLARE CNT Int;
DECLARE Comments Nvarchar(150);
DECLARE stts Nvarchar(150);

	SELECT "Comments" INTO Comments FROM OWOR T1 where T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT "Status" INTO stts FROM OWOR T1 where T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT COUNT(*) INTO CNT FROM OWOR T1 where T1."Comments" = Comments and T1."Status" <> 'C';

	IF :CNT>1  and Comments IS NOT NULL THEN
		error := 261;
		error_message := 'Duplicate Batch Number Exist Check Batch No Again';
		CNT:= 0;
	END IF;
END IF;

IF object_type = '59' AND (:transaction_type = 'U' OR :transaction_type = 'A') THEN

DECLARE CNT Int;
DECLARE Comments Nvarchar(254);
DECLARE Srs Nvarchar(250);

	SELECT "Comments" INTO Comments FROM OIGN T1 where T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT "SeriesName" INTO Srs FROM OIGN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT COUNT(*) INTO CNT FROM OIGN T1 where T1."Comments" = Comments;

	IF :CNT>1 and Srs NOT LIKE 'SC%' and Comments IS NOT NULL THEN
		error := 262;
		error_message := 'Duplicate Batch Number Exist Check Batch No Again';
		CNT:= 0;
	END IF;

END IF;

IF object_type = '60' AND (:transaction_type = 'U' OR :transaction_type = 'A') THEN

DECLARE CNT Int;
DECLARE Comments Nvarchar(500);
DECLARE Srs Nvarchar(500);
	SELECT "Comments" INTO Comments FROM OIGE T1 where T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT "SeriesName" INTO Srs FROM OIGE T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT COUNT(*) INTO CNT FROM OIGE T1 where T1."Comments" = Comments;

	IF :CNT>1 and Srs NOT LIKE 'SC%' and Comments IS NOT NULL THEN
		error := 263;
		error_message := 'Duplicate Batch Number Exist Check Batch No Again';
		CNT:= 0;
	END IF;
END IF;



IF object_type = '59' AND (:transaction_type = 'U' OR :transaction_type = 'A') THEN

DECLARE CNT Int;
DECLARE Comments Nvarchar(150);
DECLARE Srs Nvarchar(150);
	SELECT "Ref2" INTO Comments FROM OIGN T1 where T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT "SeriesName" INTO Srs FROM OIGN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT COUNT(*) INTO CNT FROM OIGN T1 where T1."Ref2" = Comments;

	IF :CNT>1 and Srs NOT LIKE 'SC%' and Comments IS NOT NULL THEN
		error := 264;
		error_message := 'Duplicate Batch Number Exist Check Batch No Again';
		CNT:= 0;
	END IF;
END IF;

IF object_type = '60' AND ( :transaction_type = 'A') THEN

DECLARE MINN int;
DECLARE MAXX int;
DECLARE CNT Int;
DECLARE Comments Nvarchar(150);
DECLARE Srs Nvarchar(150);
Declare Itm nvarchar(250);

	Select MIN(T0."VisOrder") into MINN from IGE1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXX from IGE1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT "Ref2" INTO Comments FROM OIGE T1 where T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."SeriesName" INTO Srs FROM OIGE T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT COUNT(*) INTO CNT FROM OIGE T1 where T1."Ref2" = Comments;
	WHILE MINN<=MAXX DO
		select "ItemCode" into Itm FROM IGE1 T0 WHERE T0."DocEntry"=list_of_cols_val_tab_del and T0."VisOrder" = MINN;
		IF Itm LIKE 'PC%' then
		IF :CNT>1 and Srs NOT LIKE 'SC%' and Comments IS NOT NULL THEN
			error := 265;
			error_message := 'Duplicate Batch Number Exist Check Batch No Again';
			CNT:= 0;
		END IF;
		END IF;
	MINN = MINN + 1;
	END WHILE;


END IF;

IF object_type = 'QcInProcess' AND ( :transaction_type = 'A' OR :transaction_type = 'U')   THEN

DECLARE CNT Int;
Declare Batch nvarchar(50);

	SELECT T0."U_Batch_No" Into Batch  FROM "@QCINPROCESS" T0 WHERE T0."DocEntry" = list_of_cols_val_tab_del;
	SELECT COUNT(*) INTO CNT FROM "@QCINPROCESS" where "U_Batch_No" = Batch;

	IF Batch IS NULL THEN
		error := 272;
		error_message := 'Batch number blank';
		CNT:= 0;
	END IF;
	IF :CNT>1 THEN
		error := 273;
		error_message := 'Duplicate Batch Number Exist Check Batch No Again';
		CNT:= 0;
	END IF;
END IF;

IF object_type = '202' AND (:transaction_type = 'U' OR :transaction_type = 'A') THEN

DECLARE Approve Nvarchar(150);
DECLARE Dpercentage Int;
DECLARE PType Nvarchar(150);

	SELECT "Type" INTO PType FROM OWOR T1 where T1."DocEntry" = :list_of_cols_val_tab_del;
	IF PType = 'S' THEN
		SELECT "U_Approve" INTO Approve FROM OWOR T1 where T1."DocEntry" = :list_of_cols_val_tab_del;
		SELECT "U_Devallow" INTO Dpercentage FROM OWOR T1 where T1."DocEntry" = :list_of_cols_val_tab_del;

		IF Approve IS NOT NULL THEN
			IF Dpercentage IS NULL THEN
			error := 274;
			error_message := 'Please Select approved deviation percentage';
			END IF;
		END IF;
	END IF;
END IF;

/*IF object_type = '13' AND (:transaction_type = 'U' OR :transaction_type = 'A') THEN

DECLARE Pterm Nvarchar(150);
DECLARE Rate Int;
DECLARE Bsdoc Int;
DECLARE MinAR int;
DECLARE MaxAR int;
DECLARE DocNumber int;

	(SELECT min(T0."VisOrder") Into MinAR FROM INV1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxAR FROM INV1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	SELECT "DocRate" INTO Rate FROM OINV T1  where T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT UPPER("PymntGroup") INTO Pterm FROM OINV T1 INNER JOIN OCTG T2 ON T1."GroupNum" = T2."GroupNum" where T1."DocEntry" = :list_of_cols_val_tab_del;

	IF Pterm LIKE '%ADVANCE%' and Rate = 1 THEN
		WHILE MinAR <= MaxAR
		DO
		SELECT "BaseEntry" INTO Bsdoc FROM INV1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinAR;
		SELECT Count("RefDocEntr") INTO DocNumber from RCT9 T1 where T1."RefDocEntr" = Bsdoc;

			IF DocNumber = 0 THEN
				error:=2755;
				error_message:=N'Error. Payment not received';
			END IF;

		MinAR=MinAR+1;
		END WHILE;
	END IF;
	IF Pterm LIKE '%Advance%' and Rate > 1 THEN
		WHILE MinAR <= MaxAR
		DO
		SELECT T2."BaseEntry" INTO Bsdoc FROM INV1 T1 INNER JOIN DLN1 T2 ON T1."BaseEntry" = T2."DocEntry" where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinAR;
		SELECT Count("RefDocEntr") INTO DocNumber from RCT9 T1 where T1."RefDocEntr" = Bsdoc;

			IF DocNumber = 0 THEN
				error:=276;
				error_message:=N'Error. Payment not received';
			END IF;

		MinAR=MinAR+1;
		END WHILE;
	END IF;
END IF;*/

IF Object_type = '60' and (:transaction_type ='A') Then
Declare Code1 nvarchar(50);
Declare UsrCod nvarchar(50);
DECLARE MinGI int;
DECLARE MaxGI int;
DECLARE CNT int;

	(SELECT min(T0."VisOrder") Into MinGI FROM IGE1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGI FROM IGE1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	select OUSR."USER_CODE" into UsrCod from OIGE INNER JOIN OUSR ON OUSR."USERID" = OIGE."UserSign" where OIGE."DocEntry"=list_of_cols_val_tab_del;

	WHILE MinGI <= MaxGI
	DO
		SELECT COUNT("ItemCode") INTO CNT FROM IGE1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGI
		and T1."BaseEntry" IS NULL;
		If UsrCod = 'prod05' AND CNT > 0 then
		SELECT "ItemCode" INTO Code1 FROM IGE1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGI
		and T1."BaseEntry" IS NULL;
	         IF (Code1 NOT LIKE '%PM%' ) then
	              error :=278;
	              error_message := N'Error';
	         End If;
     	End If;
     MinGI=MinGI+1;
	END WHILE;
End If;

IF object_type = 'QcInProcess' AND (:transaction_type = 'C' OR :transaction_type = 'L')   THEN

DECLARE Creator nvarchar(50);

	SELECT T0."Creator" Into Creator  FROM "@QCINPROCESS" T0 WHERE T0."DocEntry" = list_of_cols_val_tab_del;

	IF Creator <> 'manager' THEN
		error := 279;
		error_message := 'You are not allowed to perform this action';
	END IF;

END IF;

IF object_type = '59' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare SPGR double;
Declare SPGI double;
Declare Srss Nvarchar(150);
Declare IC Nvarchar(150);
Declare BE int;
DECLARE MinGR int;
DECLARE MaxGR int;

	(SELECT min(T0."VisOrder") Into MinGR FROM IGN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGR FROM IGN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	(SELECT T1."SeriesName" Into Srss FROM OIGN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del);

	IF Srss LIKE '%BT%' then
		WHILE MinGR <= MaxGR
		DO
			SELECT "Price" Into SPGR FROM IGN1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGR;
			SELECT "BaseEntry" Into BE FROM IGN1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGR;
			--SELECT "ItemCode" Into IC FROM IGN1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGR;
			SELECT "StockPrice" Into SPGI FROM IGE1 T1 where T1."DocEntry" = BE AND T1."VisOrder"=MinGR;

			IF SPGR <> SPGI THEN
		    	error :=280;
		        error_message := N'Not match rate. please contact SAP team.'||SPGR||SPGI||MinGR;
	     	End If;
	     MinGR=MinGR+1;
		END WHILE;
	END IF;
END IF;

IF object_type = '59' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare Srss Nvarchar(150);
Declare Whss Nvarchar(150);
DECLARE MinGR int;
DECLARE MaxGR int;

	(SELECT min(T0."VisOrder") Into MinGR FROM IGN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGR FROM IGN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	(SELECT T1."SeriesName" Into Srss FROM OIGN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del);

	IF Srss LIKE '%BT%' then
		WHILE MinGR <= MaxGR
		DO
			SELECT "WhsCode" Into Whss FROM IGN1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGR;

			IF Whss NOT LIKE '%BT%' THEN
		    	error :=281;
		        error_message := N'Select BT warhouse for BT Series.';
	     	End If;
	     MinGR=MinGR+1;
		END WHILE;
	END IF;
END IF;

IF object_type = '59' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare Srss Nvarchar(150);
Declare Whss Nvarchar(150);
DECLARE MinGR int;
DECLARE MaxGR int;

	(SELECT min(T0."VisOrder") Into MinGR FROM IGN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGR FROM IGN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	(SELECT T1."SeriesName" Into Srss FROM OIGN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del);

		WHILE MinGR <= MaxGR
		DO
			SELECT "WhsCode" Into Whss FROM IGN1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGR;

			IF Whss LIKE '%BT%' THEN
				IF Srss NOT LIKE '%BT%' then
		    		error :=282;
		        	error_message := N'Select BT warhouse for BT Series.';
		        END IF;
	     	End If;
	     MinGR=MinGR+1;
		END WHILE;

END IF;


IF object_type = '60' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare Srss Nvarchar(150);
Declare Whss Nvarchar(150);
DECLARE MinGI int;
DECLARE MaxGI int;

	(SELECT min(T0."VisOrder") Into MinGI FROM IGE1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGI FROM IGE1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	(SELECT T1."SeriesName" Into Srss FROM OIGE T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del);

		WHILE MinGI <= MaxGI
		DO
			SELECT "WhsCode" Into Whss FROM IGE1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGI;

			IF Whss LIKE '%BT%' THEN
				IF Srss NOT LIKE '%BT%' then
		    		error :=283;
		        	error_message := N'Select BT warhouse for BT Series.';
		        END IF;
	     	End If;
	     MinGI=MinGI+1;
		END WHILE;

END IF;

IF object_type = '60' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare Srss Nvarchar(150);
Declare Whss Nvarchar(150);
DECLARE MinGI int;
DECLARE MaxGI int;

	(SELECT min(T0."VisOrder") Into MinGI FROM IGE1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGI FROM IGE1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	(SELECT T1."SeriesName" Into Srss FROM OIGE T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del);

	IF Srss LIKE '%BT%' then
		WHILE MinGI <= MaxGI
		DO
			SELECT "WhsCode" Into Whss FROM IGE1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGI;

			IF Whss NOT LIKE '%BT%' THEN
		    	error :=284;
		        error_message := N'Select BT warhouse for BT Series.';
	     	End If;
	     MinGI=MinGI+1;
		END WHILE;
	END IF;

END IF;



IF object_type = '18' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare ICode Nvarchar(150);
Declare QAQC Nvarchar(150);
DECLARE MinPR int;
DECLARE MaxPR int;

	(SELECT min(T0."VisOrder") Into MinPR FROM PCH1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxPR FROM PCH1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	WHILE MinPR <= MaxPR
	DO
		SELECT "ItemCode" Into ICode FROM PCH1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinPR;
		SELECT "U_QCRD" Into QAQC FROM PCH1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinPR;

		IF ICode LIKE 'LB%' then
			IF QAQC IS NULL THEN
		    	error :=286;
		    	error_message := N'Please select purchase invoice is for R&D or QC department';
		    END IF;
		    IF QAQC = '-' THEN
		    	error :=286;
		    	error_message := N'Please select purchase invoice is for R&D or QC department';
		    END IF;
	    End If;

	    MinPR=MinPR+1;
	END WHILE;

END IF;

IF object_type = '60' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN
Declare ICode Nvarchar(150);
Declare Iname Nvarchar(150);
Declare Srs Nvarchar(150);
Declare IBE int;
DECLARE MinGI int;
DECLARE MaxGI int;

	(SELECT min(T0."VisOrder") Into MinGI FROM IGE1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGI FROM IGE1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

		WHILE MinGI <= MaxGI
		DO
			SELECT "ItemCode" Into ICode FROM IGE1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGI;
			SELECT "Dscription" Into Iname FROM IGE1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGI;
			SELECT NNM1."SeriesName" Into Srs FROM OIGE T1 INNER JOIN NNM1 ON NNM1."Series" = T1."Series" where T1."DocEntry" = :list_of_cols_val_tab_del;
			SELECT ifnull("BaseEntry",0) Into IBE FROM IGE1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGI;
			IF IBE = 0 then
				IF Srs NOT LIKE '%BT%' then
					IF ICode = 'SCPM0004' or ICode = 'SCPM0005' THEN
				    	error :=287;
				        error_message := N'Not allowed to issue Jumbo bag.';
			     	End If;


			     	IF ICode LIKE '%RM%'AND ICode <> 'SCRM0016' AND ICode <> 'PCRM0017' AND ICode <> 'SCRM0025' THEN
				    	error :=287;
				        error_message := N'Not allowed to issue RM directly. Contact SAP team';
			     	End If;

			     	IF ICode LIKE '%FG%' THEN
				    	error :=287;
				        error_message := N'Not allowed to issue FG directly. Contact SAP team';
			     	End If;
			     	IF ICode LIKE '%PM%' THEN
			     		IF Iname NOT LIKE '%Ply%' and Iname NOT LIKE '%Pallet%' and Iname NOT LIKE '%Seal%' and Iname NOT LIKE '%seal%' and Iname <> 'Box strapping roll' and Iname <> 'Stretch film' then
					    	error :=28701;
					        error_message := N'Not allowed to issue PM directly. Contact SAP team' || Iname ;
				     	End If;
			     	End If;
		     	END IF;
	     	END IF;
	     MinGI=MinGI+1;
		END WHILE;
END IF;

IF object_type = '59' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN
Declare ICode Nvarchar(150);
DECLARE MinGR int;
Declare DateP int;
DECLARE MaxGR int;

	(SELECT min(T0."VisOrder") Into MinGR FROM IGN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGR FROM IGN1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

		WHILE MinGR <= MaxGR
		DO
			SELECT "ItemCode" Into ICode FROM IGN1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGR;
			select DAYS_BETWEEN(T0."DocDate",NOW()) INTO DateP from OIGN T0 where T0."DocEntry" = :list_of_cols_val_tab_del;
			IF ICode LIKE 'SC%' THEN
				IF  DateP > 5 THEN
		    	error :=288;
		        error_message := N'Not allowed to add receipt in back date';
		        END IF;
	     	End If;
	     	IF ICode LIKE 'PC%' THEN
				IF  DateP > 1 THEN
		    	error :=288;
		        error_message := N'Not allowed to add receipt in back date';
		        END IF;
	     	End If;
	     MinGR=MinGR+1;
		END WHILE;
END IF;
------------------------------- Gate pass return-----------------------
IF object_type = 'GPReturn' AND (:transaction_type = 'C' OR :transaction_type = 'L')   THEN

DECLARE Creator nvarchar(50);

	SELECT T0."Creator" Into Creator  FROM "@GATEPASSRH" T0 WHERE T0."DocEntry" = list_of_cols_val_tab_del;
		IF Creator <> 'manager' THEN
			error := 289;
			error_message := 'You are not allowed to cancle the document';
		END IF;
END IF;


IF object_type = 'GPReturn' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

DECLARE DocNum int;
DECLARE GPRItemCode nvarchar(50);
--DECLARE GPItemCode nvarchar(50);
Declare minGPR Int;
Declare maxGPR Int;

	(SELECT min(T0."LineId") Into minGPR FROM "@GATEPASSRR" T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."LineId") Into maxGPR FROM "@GATEPASSRR" T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	WHILE minGPR <= maxGPR DO

	SELECT T1."U_DocNum" Into DocNum FROM "@GATEPASSRH" T1 WHERE T1."DocEntry" = list_of_cols_val_tab_del;

	SELECT COUNT(T0."U_ItemCode") Into GPRItemCode FROM "@GATEPASSRR" T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."LineId" = minGPR AND
		T0."U_ItemCode" IN (SELECT T0."U_ItemCode" FROM "@GPDL" T0 WHERE T0."DocEntry" = DocNum);

			IF GPRItemCode = 0 THEN
				error := 290;
				error_message := 'You are not allowed to select items other than gate pass items';
			END IF;
	minGPR=minGPR+1;
	END WHILE;

END IF;

IF object_type = 'GPReturn' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

DECLARE DocNum int;
DECLARE GPRItemCode nvarchar(50);
DECLARE GPRQuantity int;
DECLARE GPQty int;
DECLARE SGPQty int;
DECLARE SumQty int;
Declare minGPR Int;
Declare maxGPR Int;

	(SELECT min(T0."LineId") Into minGPR FROM "@GATEPASSRR" T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."LineId") Into maxGPR FROM "@GATEPASSRR" T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	WHILE minGPR <= maxGPR DO
	SELECT T1."U_DocNum" Into DocNum FROM "@GATEPASSRH" T1 WHERE T1."DocEntry" = list_of_cols_val_tab_del;

	SELECT T1."U_ItemCode" Into GPRItemCode FROM "@GATEPASSRR" T1 WHERE T1."DocEntry" = list_of_cols_val_tab_del AND T1."LineId" = minGPR ;

	SELECT SUM(T0."U_Quantity") Into SumQty FROM "@GATEPASSRR" T0 INNER JOIN "@GATEPASSRH" T1 ON T0."DocEntry" = T1."DocEntry"
 	WHERE T1."U_DocNum" = DocNum AND T0."U_ItemCode" = GPRItemCode;

	SELECT SUM(T2."U_Quantity") Into SGPQty FROM "@GPDL" T2 WHERE T2."DocEntry" = DocNum AND T2."U_ItemCode" = GPRItemCode;

 		IF SGPQty < SumQty THEN
			error := 291;
			error_message := 'Total return quantity exceeds actaul gate pass quantity for item - '||GPRItemCode ;
		END IF;
	minGPR=minGPR+1;
	END WHILE;

END IF;

IF object_type = 'GPReturn' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

DECLARE Series nvarchar(50);
DECLARE Branch nvarchar(50);
DECLARE DocDate date;

	SELECT T1."U_Series" Into Series FROM "@GATEPASSRH" T1 WHERE T1."DocEntry" = list_of_cols_val_tab_del;
	SELECT T1."U_Branch" Into Branch FROM "@GATEPASSRH" T1 WHERE T1."DocEntry" = list_of_cols_val_tab_del;
	SELECT T1."U_DocDate" Into DocDate FROM "@GATEPASSRH" T1 WHERE T1."DocEntry" = list_of_cols_val_tab_del;

			IF DocDate <= '20230331' THEN
			IF  Branch = 'UNIT - I' AND Series <> 'GR1/2223' THEN
				error := 292;
				error_message := 'Please select document series GR1/2223 for UNIT - I ';
			END IF;

			IF  Branch = 'UNIT - II' AND Series <> 'GR2/2223' THEN
				error := 292;
				error_message := 'Please select document series GR2/2223 for UNIT - II ';
			END IF;
			END IF;

			IF DocDate >= '20230401' AND DocDate <= '20240331' THEN
			IF  Branch = 'UNIT - I' AND Series <> 'GR1/2324' THEN
				error := 292;
				error_message := 'Please select document series GR1/2324 for UNIT - I ';
			END IF;

			IF  Branch = 'UNIT - II' AND Series <> 'GR2/2324' THEN
				error := 292;
				error_message := 'Please select document series GR2/2324 for UNIT - II ';
			END IF;
			END IF;

END IF;

IF object_type = 'GPReturn' AND (:transaction_type = 'U')   THEN

DECLARE UserID nvarchar(50);

	SELECT T0."UserSign" Into UserID  FROM "@GATEPASSRH" T0 WHERE T0."DocEntry" = list_of_cols_val_tab_del;

	IF UserID <> 1 THEN
		error := 293;
		error_message := 'You are not allowed to Update the document';
	END IF;

END IF;

IF object_type = '60' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare Srss Nvarchar(150);
Declare VN Nvarchar(150);
Declare TN Nvarchar(150);
Declare MN Nvarchar(150);

	(SELECT T1."SeriesName" Into Srss FROM OIGE T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del);

	IF Srss LIKE '%BT%' then

		SELECT "U_UNE_VehicleNo" Into VN FROM OIGE T1 where T1."DocEntry" = :list_of_cols_val_tab_del ;
		SELECT "U_UNE_TransportName" Into TN FROM OIGE T1 where T1."DocEntry" = :list_of_cols_val_tab_del;
		SELECT "U_Mobile_No" Into MN FROM OIGE T1 where T1."DocEntry" = :list_of_cols_val_tab_del;

		IF VN IS NULL THEN
		    error :=295;
		    error_message := N'Please enter vehicle no';
	    End If;
	    IF MN IS NULL THEN
		    error :=296;
		    error_message := N'Please enter Mobile no';
		End If;
	    IF TN IS NULL THEN
		    error :=297;
		    error_message := N'Please enter Transport name';
	    End If;

	END IF;
END IF;

IF object_type = '59' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare Srss Nvarchar(150);
Declare VN Nvarchar(150);
Declare TN Nvarchar(150);
Declare MN Nvarchar(150);

	(SELECT T1."SeriesName" Into Srss FROM OIGN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del);

	IF Srss LIKE '%BT%' then
		SELECT "U_UNE_VehicleNo" Into VN FROM OIGN T1 where T1."DocEntry" = :list_of_cols_val_tab_del;
		SELECT "U_UNE_TransportName" Into TN FROM OIGN T1 where T1."DocEntry" = :list_of_cols_val_tab_del;
		SELECT "U_Mobile_No" Into MN FROM OIGN T1 where T1."DocEntry" = :list_of_cols_val_tab_del;

		IF VN IS NULL THEN
		    error :=298;
		    error_message := N'Please enter vehicle no';
	    End If;
	    IF MN IS NULL THEN
		    error :=299;
		    error_message := N'Please enter Mobile no';
	   	End If;
	    IF TN IS NULL THEN
		    error :=300;
		    error_message := N'Please enter Transport name';
	    End If;
	END IF;
END IF;

IF object_type = '18' AND (:transaction_type = 'A' or :transaction_type='U') THEN
DECLARE APDate date;
DECLARE APBase Int;
DECLARE APBaseType Int;
DECLARE GRNDate date;
DECLARE PODate date;
DECLARE DocumentDate date;

		SELECT T1."DocDate",T1."TaxDate" into APDate,DocumentDate FROM OPCH T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
		SELECT MAX(T0."BaseEntry") into APBase FROM OPCH T1 INNER JOIN PCH1 T0 ON T0."DocEntry" = T1."DocEntry" WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
		SELECT distinct T0."BaseType" into APBaseType FROM OPCH T1 INNER JOIN PCH1 T0 ON T0."DocEntry" = T1."DocEntry" WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
		IF APBase IS NOT NULL THEN
			IF APBaseType = 20 THEN
				SELECT T1."DocDate" into GRNDate FROM OPDN T1 WHERE T1."DocEntry" = APBase;

				IF APDate < GRNDate then
					error :=306;
					error_message := N'AP Invoice posting date should be greater or equal GRN posting date. GRN Date : '||GRNDate;
				END IF;
			END IF;
			IF APBaseType = 22 THEN
				SELECT T1."DocDate" into PODate FROM OPOR T1 WHERE T1."DocEntry" = APBase;

				IF APDate < PODate then
					error :=307;
					error_message := N'AP Invoice posting date should be greater or equal PO posting date. PO Date : '||GRNDate;
				END IF;
			END IF;
		END IF;

		IF APDate < DocumentDate THEN
			error := 3071;
			error_message := N'AP Invoice posting date should be greater or equal Document Date : '||DocumentDate;
		END IF;
END IF;

------------------------------------------------------------------------------------------
IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type='U') THEN
    DECLARE APDate DATE;
    DECLARE APBase INT;
    DECLARE APBaseType INT;
    DECLARE APBaseTypeCount INT;
    DECLARE GRNDate DATE;
    DECLARE PODate DATE;
    DECLARE DocumentDate date;

    SELECT ODRF."ObjType" INTO DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del;

    IF DraftObj = 18 THEN
        SELECT T1."DocDate",T1."TaxDate" into APDate,DocumentDate FROM ODRF T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del AND T1."ObjType"=18;
        SELECT MAX(T0."BaseEntry") INTO APBase FROM ODRF T1
        INNER JOIN PCH1 T0 ON T0."DocEntry" = T1."DocEntry"
        WHERE T1."DocEntry" = :list_of_cols_val_tab_del AND T1."ObjType"=18;

        SELECT COUNT(DISTINCT IFNULL(T0."BaseType",0)) INTO APBaseTypeCount FROM ODRF T1
        INNER JOIN PCH1 T0 ON T0."DocEntry" = T1."DocEntry"
        WHERE T1."DocEntry" = :list_of_cols_val_tab_del AND T1."ObjType"=18;

        IF APBaseTypeCount > 0 THEN
            SELECT max(T0."BaseType") INTO APBaseType FROM ODRF T1
            INNER JOIN DRF1 T0 ON T0."DocEntry" = T1."DocEntry"
            WHERE T1."DocEntry" = :list_of_cols_val_tab_del AND T1."ObjType" = 18;
        END IF;

        IF APBase IS NOT NULL THEN
            IF APBaseType = 20 THEN
                SELECT T1."DocDate" INTO GRNDate FROM OPDN T1 Inner Join PCH1 T2 on T1."ObjType"=T2."BaseType" and T1."DocEntry"=T2."BaseEntry"
                WHERE T2."VisOrder"=0 and T2."DocEntry" =:list_of_cols_val_tab_del;

                IF APDate < GRNDate THEN
                    error := 306;
                    error_message := N'AP Invoice posting date should be greater or equal GRN posting date. GRN Date : '||GRNDate;
                END IF;
            END IF;

            IF APBaseType = 22 THEN
                SELECT T1."DocDate" INTO PODate FROM OPOR T1 WHERE T1."DocEntry" =:list_of_cols_val_tab_del;

                IF APDate < PODate THEN
                    error := 307;
                    error_message := N'AP Invoice posting date should be greater or equal PO posting date. PO Date : '||PODate;
                END IF;
            END IF;
        END IF;

        IF APDate < DocumentDate THEN
			error := 3071;
			error_message := N'AP Invoice posting date should be greater or equal Document Date : '||DocumentDate;
		END IF;
    END IF;
END IF;
------------------------ Sales and A/R invoice should be of same branch-----------

IF object_type = '13' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE BaseEntry Int;
DECLARE BRIN Int;
DECLARE BRS nvarchar(50);
DECLARE BROR Int;
Declare BaseAP int;

	SELECT Min(T0."VisOrder") INTO MinIN from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OINV."BPLId" into BRIN FROM OINV WHERE OINV."DocEntry" = :list_of_cols_val_tab_del;
	Select T0."BaseType" into BaseAP from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."VisOrder"=:MinIN;
	SELECT NNM1."SeriesName" into BRS FROM OINV INNER JOIN NNM1 ON NNM1."Series" = OINV."Series" WHERE OINV."DocEntry" = :list_of_cols_val_tab_del;

	If BaseAP=17 then
	IF BRS LIKE 'D%' then
	WHILE :MinIN <= :MaxIN DO
		SELECT INV1."BaseEntry" into BaseEntry FROM INV1 WHERE INV1."DocEntry" = :list_of_cols_val_tab_del and INV1."VisOrder"=MinIN;

		SELECT ORDR."BPLId" into BROR FROM ORDR WHERE ORDR."DocEntry" = BaseEntry;


		IF BRIN <> BROR THEN
				error :=313;
				error_message := N'Sale order and invoice should be of same Branch';
		END IF;

		MinIN := MinIN+1;
	END WHILE;
	END IF;
	End if;
END IF;

IF object_type = '15' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE BaseEntry Int;
DECLARE BRIN Int;
DECLARE BROR Int;
DECLARE BRS nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinIN from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODLN."BPLId" into BRIN FROM ODLN WHERE ODLN."DocEntry" = :list_of_cols_val_tab_del;
	SELECT NNM1."SeriesName" into BRS FROM ODLN INNER JOIN NNM1 ON NNM1."Series" = ODLN."Series" WHERE ODLN."DocEntry" = :list_of_cols_val_tab_del;

	IF BRS LIKE 'E%' then
	WHILE :MinIN <= :MaxIN DO
		SELECT DLN1."BaseEntry" into BaseEntry FROM DLN1 WHERE DLN1."DocEntry" = :list_of_cols_val_tab_del and DLN1."VisOrder"=MinIN;

		SELECT ORDR."BPLId" into BROR FROM ORDR WHERE ORDR."DocEntry" = BaseEntry;

		IF BRIN <> BROR THEN
				error :=314;
				error_message := N'SO and Delivery should be of same Branch';
		END IF;

		MinIN := MinIN+1;
	END WHILE;
	END IF;
END IF;

IF object_type = '203' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE BaseEntry Int;
DECLARE BRIN Int;
DECLARE BROR Int;
DECLARE BRS nvarchar(50);
Declare BaseRDR int;

	SELECT Min(T0."VisOrder") INTO MinIN from DPI1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DPI1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODPI."BPLId" into BRIN FROM ODPI WHERE ODPI."DocEntry" = :list_of_cols_val_tab_del;
	SELECT NNM1."SeriesName" into BRS FROM ODPI INNER JOIN NNM1 ON NNM1."Series" = ODPI."Series" WHERE ODPI."DocEntry" = :list_of_cols_val_tab_del;
	select "BaseType" into BaseRDR from DPI1 where "DocEntry"=:list_of_cols_val_tab_del and "VisOrder"=:MinIN;

	If BaseRDR=17
	Then
	IF BRS LIKE 'E%' then
	WHILE :MinIN <= :MaxIN DO
		SELECT DPI1."BaseEntry" into BaseEntry FROM DPI1 WHERE DPI1."DocEntry" = :list_of_cols_val_tab_del and DPI1."VisOrder"=MinIN;

		SELECT ORDR."BPLId" into BROR FROM ORDR WHERE ORDR."DocEntry" = BaseEntry;

		IF BRIN <> BROR THEN
				error :=314;
				error_message := N'SO and Downpayment should be of same Branch';
		END IF;

		MinIN := MinIN+1;
	END WHILE;
	END IF;
	End if;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE BaseEntry Int;
DECLARE BRIN Int;
DECLARE BROR Int;
DECLARE ICOD varchar(50);
DECLARE Series varchar(50);

	SELECT Min(T0."VisOrder") INTO MinIN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OPDN."BPLId" into BRIN FROM OPDN WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del;
	SELECT NNM1."SeriesName" into Series FROM NNM1 INNER JOIN OPDN ON OPDN."Series" = NNM1."Series" WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del;

	IF Series NOT LIKE 'CL%' THEN
	WHILE :MinIN <= :MaxIN DO
		SELECT PDN1."ItemCode" into ICOD FROM PDN1 WHERE PDN1."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=MinIN;
		IF ICOD <> 'PCPM0095' and ICOD <> 'PCPM0094' and ICOD <> 'PCPM0096' and ICOD <> 'PCPM0097' and ICOD <> 'PCPM0098' and ICOD <> 'PCPM0098' THEN
			SELECT PDN1."BaseEntry" into BaseEntry FROM PDN1 WHERE PDN1."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=MinIN;

			SELECT OPOR."BPLId" into BROR FROM OPOR WHERE OPOR."DocEntry" = BaseEntry;

			IF BRIN <> BROR THEN
					error :=315;
					error_message := N'PO and GRN should be of same Branch';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
	END IF;
END IF;

IF object_type = '18' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE BaseEntry Int;
DECLARE BaseType Int;
DECLARE BRIN Int;
DECLARE BROR Int;

	SELECT Min(T0."VisOrder") INTO MinIN from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OPCH."BPLId" into BRIN FROM OPCH WHERE OPCH."DocEntry" = :list_of_cols_val_tab_del;

	WHILE :MinIN <= :MaxIN DO
		SELECT PCH1."BaseType" into BaseType FROM PCH1 WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder"=MinIN;

		IF BaseType = '20' then
			SELECT PCH1."BaseEntry" into BaseEntry FROM PCH1 WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder"=MinIN;
			SELECT OPDN."BPLId" into BROR FROM OPDN WHERE OPDN."DocEntry" = BaseEntry;
		END IF;
		IF BaseType = '22' then
			SELECT PCH1."BaseEntry" into BaseEntry FROM PCH1 WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder"=MinIN;
			SELECT OPOR."BPLId" into BROR FROM OPOR WHERE OPOR."DocEntry" = BaseEntry;
		END IF;

		IF BRIN <> BROR THEN
				error :=316;
				error_message := N'Base & Target document should be of same Branch';
		END IF;

		MinIN := MinIN+1;
	END WHILE;
END IF;

IF object_type = '13' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE BaseEntry Int;
DECLARE BaseType Int;
DECLARE BRIN Int;
DECLARE BROR Int;

	SELECT Min(T0."VisOrder") INTO MinIN from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OINV."BPLId" into BRIN FROM OINV WHERE OINV."DocEntry" = :list_of_cols_val_tab_del;

	WHILE :MinIN <= :MaxIN DO
		SELECT INV1."BaseType" into BaseType FROM INV1 WHERE INV1."DocEntry" = :list_of_cols_val_tab_del and INV1."VisOrder"=MinIN;
		IF BaseType = '17' then
			SELECT INV1."BaseEntry" into BaseEntry FROM INV1 WHERE INV1."DocEntry" = :list_of_cols_val_tab_del and INV1."VisOrder"=MinIN;
			SELECT ODLN."BPLId" into BROR FROM ODLN WHERE ODLN."DocEntry" = BaseEntry;
			IF BRIN <> BROR THEN
					error :=318;
					error_message := N'AR & Delivery should be of same Branch';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;

IF object_type = '202' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE ICPRO varchar(50);
DECLARE MPPRO varchar(50);
DECLARE CAPPRO Int;
DECLARE BaseType Int;
DECLARE BRIN Int;
DECLARE BROR Int;

	SELECT Min(T0."VisOrder") INTO MinPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinPRO <= :MaxPRO DO
		SELECT WOR1."ItemCode" into ICPRO FROM WOR1 WHERE WOR1."DocEntry" = :list_of_cols_val_tab_del and WOR1."VisOrder"=MinPRO;
		SELECT WOR1."U_Capacity" into CAPPRO FROM WOR1 WHERE WOR1."DocEntry" = :list_of_cols_val_tab_del and WOR1."VisOrder"=MinPRO;
		SELECT OITM."U_MainPacking" into MPPRO FROM WOR1 INNER JOIN OITM ON OITM."ItemCode" = WOR1."ItemCode"
			WHERE WOR1."DocEntry" = :list_of_cols_val_tab_del and WOR1."VisOrder"=MinPRO;

		IF ICPRO LIKE 'PCPM%' and MPPRO = 'Y' then
			IF CAPPRO IS NULL THEN
				error :=319;
				error_message := N'PLease enter packing capacity of packing material';
			END IF;
		END IF;
		MinPRO := MinPRO+1;
	END WHILE;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE ICGRN Nvarchar(50);
DECLARE PCGRN Int;
DECLARE BRGRN Int;
	SELECT Min(T0."VisOrder") INTO MinGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGRN <= :MaxGRN DO
		SELECT PDN1."ItemCode" into ICGRN FROM PDN1 INNER JOIN OITM ON OITM."ItemCode" = PDN1."ItemCode"
			WHERE PDN1."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN;
		IF ICGRN = 'Y' then
			SELECT PDN1."U_UNE_FACT" into PCGRN FROM PDN1 WHERE PDN1."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN;
			IF PCGRN IS NULL THEN
				error :=320;
				error_message := 'Enter packing capacity of packing material GRN';
			END IF;
		END IF;
		MinGRN := MinGRN+1;
	END WHILE;
END IF;

IF object_type = '202' AND (:transaction_type = 'U') THEN
DECLARE MinPRO Int;
DECLARE MaxPRO Int;
DECLARE plnned Int;
DECLARE issued Int;
DECLARE ICMPPRO Nvarchar(50);
DECLARE IPRO Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxPRO from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

		WHILE :MinPRO <= :MaxPRO DO
			SELECT WOR1."ItemCode" into ICMPPRO FROM WOR1 WHERE WOR1."DocEntry" = :list_of_cols_val_tab_del and WOR1."VisOrder"=MinPRO;
			SELECT OITM."U_MainPacking" into IPRO FROM WOR1 INNER JOIN OITM ON OITM."ItemCode" = WOR1."ItemCode"
			WHERE WOR1."DocEntry" = :list_of_cols_val_tab_del and WOR1."VisOrder"=MinPRO;

			IF ICMPPRO LIKE 'PCPM%' and IPRO = 'Y' then
				SELECT WOR1."PlannedQty" into plnned FROM WOR1 WHERE WOR1."DocEntry" = :list_of_cols_val_tab_del and WOR1."VisOrder"=MinPRO;
				SELECT WOR1."IssuedQty" into issued FROM WOR1 WHERE WOR1."DocEntry" = :list_of_cols_val_tab_del and WOR1."VisOrder"=MinPRO;
				IF issued > 0 then
				IF plnned <> issued then
					error:=321;
					error_message:=N'Planned packing Qty & Completed packing Qty not match';
				END IF;
				END IF;
			END IF;
			MinPRO := MinPRO + 1;
		END WHILE;

END IF;

IF object_type = '202' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE ItemCd Nvarchar(50);
DECLARE value1 INT;
DECLARE PROBRANCH Int;
DECLARE SOBRANCH Int;
DECLARE Origin Int;

	select OWOR."ItemCode" into ItemCd from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
	IF ItemCd LIKE 'PC%' then

		select OWHS."BPLid" into PROBRANCH from OWOR INNER JOIN OWHS ON OWHS."WhsCode" = OWOR."Warehouse"
			where OWOR."DocEntry"=list_of_cols_val_tab_del;
		select ORDR."BPLId" into SOBRANCH from ORDR INNER JOIN OWOR ON ORDR."DocEntry" = OWOR."OriginAbs"
			 where OWOR."DocEntry"=list_of_cols_val_tab_del;

		IF PROBRANCH <> SOBRANCH then
			error :=326;
			error_message := N'Sales Order & production order branch not same';
		END IF;

	END IF;
END IF;

IF object_type = '202' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE SOQty INT;
DECLARE plnqty INT;
DECLARE Cmptqty Int;
DECLARE ItemCd Nvarchar(50);

	select OWOR."ItemCode" into ItemCd from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
	IF ItemCd LIKE 'PC%' then

		select SUM(RDR1."Quantity") into SOQty from ORDR
			INNER JOIN OWOR ON ORDR."DocEntry" = OWOR."OriginAbs"
			INNER JOIN RDR1 ON ORDR."DocEntry" = RDR1."DocEntry"
			 where OWOR."DocEntry"=list_of_cols_val_tab_del and OWOR."ItemCode" = RDR1."ItemCode";

		select OWOR."PlannedQty" into plnqty from OWOR WHERE OWOR."DocEntry"=list_of_cols_val_tab_del;
		select SUM(OWOR."CmpltQty") into Cmptqty from OWOR INNER JOIN RDR1 ON RDR1."DocEntry" = OWOR."OriginAbs"
			and OWOR."ItemCode" = RDR1."ItemCode";

		IF  (plnqty + Cmptqty) > SOQty then
			error :=327;
			error_message := N'Production order quantity greater than SO Qty';
		END IF;

	END IF;
END IF;

-----------------------------------Estimated cost header level--------------

IF object_type = '13' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

--DECLARE MinAR int;
--DECLARE MaxAR int;
DECLARE SeriesAR nvarchar(50);
DECLARE Incoterm nvarchar(250);
DECLARE TransCost Double;
DECLARE CustCCCost Double;
DECLARE OceanFUSD Double;
DECLARE OceanFINR Double;
DECLARE FFcharges Double;


		(SELECT T1."SeriesName" into SeriesAR FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del);

		IF SeriesAR LIKE 'EX%' THEN

		SELECT OINV."U_Incoterms" into Incoterm FROM OINV WHERE OINV."DocEntry" = list_of_cols_val_tab_del;

		SELECT OINV."U_E_Trans_Cost"  into TransCost FROM OINV WHERE OINV."DocEntry" = list_of_cols_val_tab_del;
		SELECT OINV."U_E_C_Clear_Chrgs" into CustCCCost FROM OINV WHERE OINV."DocEntry" = list_of_cols_val_tab_del;
		SELECT OINV."U_E_O_Frght_USD" into OceanFUSD FROM OINV WHERE OINV."DocEntry" = list_of_cols_val_tab_del;
		SELECT OINV."U_E_O_Frght_INT" into OceanFINR FROM OINV WHERE OINV."DocEntry" = list_of_cols_val_tab_del;
		SELECT OINV."U_E_Frght_Forw_Chrgs" into FFcharges FROM OINV WHERE OINV."DocEntry" = list_of_cols_val_tab_del;

				IF Incoterm = 'FOB' THEN

						IF TransCost IS NULL OR TransCost = 0.000 then
								error :=328;
								error_message := N'Please entre Estimated transportation cost';
						END IF;

						IF CustCCCost IS NULL OR CustCCCost = 0.000 then
								error :=329;
								error_message := N'Please entre Estimated Custom clearance cost';
						END IF;

						IF FFcharges IS NULL OR FFcharges = 0.000 then
								error :=330;
								error_message := N'Please entre Estimated freight forwarder charges';
						END IF;

				END IF;

				IF (Incoterm <> 'EXW' AND Incoterm <> 'FOB') THEN

						IF TransCost IS NULL OR TransCost = 0.000 then
								error :=331;
								error_message := N'Please entre Estimated transportation cost';
						END IF;

						IF CustCCCost IS NULL OR CustCCCost = 0.000 then
								error :=332;
								error_message := N'Please Estimated Custom clearance cost';
						END IF;

						IF OceanFUSD IS NULL OR OceanFUSD = 0.000 then
								error :=333;
								error_message := N'Please entre Estimated Ocean freight USD';
						END IF;

						IF OceanFINR IS NULL OR OceanFINR = 0.000 then
								error :=334;
								error_message := N'Please entre Estimated Ocean freight INR';
						END IF;

						IF FFcharges IS NULL OR FFcharges = 0.000 then
								error :=335;
								error_message := N'Please entre Estimated freight forwarder charges';
						END IF;

				END IF;
		END IF;
END IF;
--------------------------Item not match with SO DL AR----------------------------
If object_type = '13' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE itemCodeSO varchar(50);
	DECLARE itemCodeAR varchar(50);
	DECLARE MINNAR int;
	DECLARE MAXXAR int;
	DECLARE Itms varchar(50);
	DECLARE ARSeries varchar(50);
	DECLARE ARbstype varchar(50);

	Select MIN(T0."VisOrder") into MINNAR from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAR from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into ARSeries FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	WHILE MINNAR<=MAXXAR
	DO
		Select INV1."BaseType" into ARbstype from INV1 WHERE INV1."DocEntry" = :list_of_cols_val_tab_del and INV1."VisOrder" =  MINNAR;
		IF ARSeries NOT LIKE 'CL%' and ARbstype = '17' then
			select T1."ItemCode" into itemCodeSO FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN INV1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OINV T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR;

			select T3."ItemCode" into itemCodeAR FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN INV1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OINV T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR;

			IF itemCodeSO IS NOT NULL THEN
				IF itemCodeSO != itemCodeAR THEN
					error:='336';
					error_message :='Item Not match in SO and Invoice';
				END IF;
			END IF;
		END IF;
		MINNAR = MINNAR + 1;
	END WHILE;
END IF;

If object_type = '13' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE itemCodeDL varchar(50);
	DECLARE itemCodeAR varchar(50);
	DECLARE MINNAR int;
	DECLARE MAXXAR int;
	DECLARE Itms varchar(50);
	DECLARE ARSeries varchar(50);
	DECLARE ARbstype varchar(50);

	Select MIN(T0."VisOrder") into MINNAR from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAR from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into ARSeries FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	WHILE MINNAR<=MAXXAR
	DO
		Select INV1."BaseType" into ARbstype from INV1 WHERE INV1."DocEntry" = :list_of_cols_val_tab_del and INV1."VisOrder" =  MINNAR;
		IF ARSeries NOT LIKE 'CL%' and ARbstype = '15' then
			select T1."ItemCode" into itemCodeDL FROM DLN1 T1 LEFT OUTER JOIN ODLN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN INV1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OINV T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR;

			select T3."ItemCode" into itemCodeAR FROM DLN1 T1 LEFT OUTER JOIN ODLN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN INV1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN OINV T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR;

			IF itemCodeDL IS NOT NULL THEN
				IF itemCodeDL != itemCodeAR THEN
					error:='337';
					error_message :='Item Not match in Delivery and Invoice';
				END IF;
			END IF;
		END IF;
		MINNAR = MINNAR + 1;
	END WHILE;
END IF;


If object_type = '15' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE itemCodeSO varchar(50);
	DECLARE itemCodeDL varchar(50);
	DECLARE MINNDL int;
	DECLARE MAXXDL int;
	DECLARE DLSeries varchar(50);
	DECLARE DLCode varchar(50);
	Declare base int;

	Select MIN(T0."VisOrder") into MINNDL from DLN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXDL from DLN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into DLSeries FROM ODLN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del;
	select "BaseType" into base from DLN1 where "DocEntry"=:list_of_cols_val_tab_del and "VisOrder"=MINNDL;

	if base=17
	then

	IF DLSeries NOT LIKE 'CL%' then
		WHILE MINNDL<=MAXXDL
		DO
			select T0."ItemCode" into DLCode from DLN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINNDL;

			IF DLCode NOT LIKE 'PCPM%' THEN
				select T1."ItemCode" into itemCodeSO FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DLN1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODLN T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNDL;

				select T3."ItemCode" into itemCodeDL FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DLN1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODLN T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNDL;

				IF itemCodeSO IS NOT NULL THEN
					IF itemCodeSO != itemCodeDL THEN
						error:='338';
						error_message :='Item Not match in SO and Delivery';
					END IF;
				END IF;
			END IF;
			MINNDL = MINNDL + 1;
		END WHILE;
	END IF;
	end if;
END IF;

IF Object_type = '20' and (:transaction_type ='A' OR :transaction_type ='U' ) Then
DECLARE GRNDelayRrk Int;
DECLARE DelayMstr1 Int;
DECLARE DelayMstr2 Int;
DECLARE DelayMstr3 Int;
DECLARE DelayMstr4 Int;
DECLARE DelayMstr5 Int;
DECLARE DelayMstr6 Int;
DECLARE DelayMstr7 Int;
DECLARE DelayMstr8 Int;
DECLARE DelayMstr9 Int;
DECLARE DelayMstr10 Int;
DECLARE DelayMstr11 Int;
DECLARE DelayMstr12 Int;

	(SELECT LENGTH(T0."U_RMKPRD") into GRNDelayRrk FROM OPDN T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del);

		(SELECT LENGTH("Name") INTO DelayMstr1 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 01);
		(SELECT LENGTH("Name") INTO DelayMstr2 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 02);
		(SELECT LENGTH("Name") INTO DelayMstr3 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 03);
		(SELECT LENGTH("Name") INTO DelayMstr4 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 04);
		(SELECT LENGTH("Name") INTO DelayMstr5 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 05);
		(SELECT LENGTH("Name") INTO DelayMstr6 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 06);
		(SELECT LENGTH("Name") INTO DelayMstr7 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 07);
		(SELECT LENGTH("Name") INTO DelayMstr8 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 08);
		(SELECT LENGTH("Name") INTO DelayMstr9 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 09);
		(SELECT LENGTH("Name") INTO DelayMstr10 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 10);
		(SELECT LENGTH("Name") INTO DelayMstr11 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 11);
		(SELECT LENGTH("Name") INTO DelayMstr12 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 12);

	  	IF GRNDelayRrk <> DelayMstr1 then
	  		IF GRNDelayRrk <> DelayMstr2 then
	  			IF GRNDelayRrk <> DelayMstr3 then
	  				IF GRNDelayRrk <> DelayMstr4 then
	  					IF GRNDelayRrk <> DelayMstr5 then
	  						IF GRNDelayRrk <> DelayMstr6 then
	  							IF GRNDelayRrk <> DelayMstr7 then
	  								IF GRNDelayRrk <> DelayMstr8 then
	  									IF GRNDelayRrk <> DelayMstr9 then
	  										IF GRNDelayRrk <> DelayMstr10 then
	  											IF GRNDelayRrk <> DelayMstr11 then
	  												IF GRNDelayRrk <> DelayMstr12 then
														error:=340;
														error_message:=N'GRN Delay remark doen not match with master';
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
END IF;

-------------------------------- GRN not allowed for other branch user------------
IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;

	SELECT OPDN."BPLId" into BRGRN FROM OPDN WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN OPDN ON OUSR."USERID" = OPDN."UserSign"
	WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN OPDN ON OUSR."USERID" = OPDN."UserSign2"
	WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del;


		IF BRGRN = 3 THEN
			IF (UserName = 'engg07' OR UserNameU = 'engg07') THEN
				error :=343;
				error_message := N'You are not allowed for UNIT - I GRN entry';
			END IF;
		END IF;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;

	SELECT OPDN."BPLId" into BRGRN FROM OPDN WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN OPDN ON OUSR."USERID" = OPDN."UserSign"
	WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN OPDN ON OUSR."USERID" = OPDN."UserSign2"
	WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del;


		IF BRGRN = 4 THEN
			IF (UserName = 'engg02' OR UserNameU = 'engg02') THEN
				error :=344;
				error_message := N'You are not allowed for UNIT - II GRN entry';
			END IF;
		END IF;
END IF;
-----------------------------
IF object_type = '67' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;

	SELECT OWTR."BPLId" into BRGRN FROM OWTR WHERE OWTR."DocEntry" = :list_of_cols_val_tab_del;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN OWTR ON OUSR."USERID" = OWTR."UserSign"
	WHERE OWTR."DocEntry" = :list_of_cols_val_tab_del;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN OWTR ON OUSR."USERID" = OWTR."UserSign2"
	WHERE OWTR."DocEntry" = :list_of_cols_val_tab_del;

		IF BRGRN = 3 THEN
			IF (UserName = 'engg07' OR UserNameU =  'engg07') THEN
				error :=345;
				error_message := N'You are not allowed for UNIT - I Inventory transfer entry';
			END IF;
		END IF;
END IF;

IF object_type = '67' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;

	SELECT OWTR."BPLId" into BRGRN FROM OWTR WHERE OWTR."DocEntry" = :list_of_cols_val_tab_del;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN OWTR ON OUSR."USERID" = OWTR."UserSign"
	WHERE OWTR."DocEntry" = :list_of_cols_val_tab_del;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN OWTR ON OUSR."USERID" = OWTR."UserSign2"
	WHERE OWTR."DocEntry" = :list_of_cols_val_tab_del;

		IF BRGRN = 4 THEN
			IF (UserName = 'engg02' OR UserNameU = 'engg02') THEN
				error :=346;
				error_message := N'You are not allowed for UNIT - II Inventory transfer entry';
			END IF;
		END IF;
END IF;
----------------
IF object_type = '60' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;

	SELECT OIGE."BPLId" into BRGRN FROM OIGE WHERE OIGE."DocEntry" = :list_of_cols_val_tab_del;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN OIGE ON OUSR."USERID" = OIGE."UserSign"
	WHERE OIGE."DocEntry" = :list_of_cols_val_tab_del;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN OIGE ON OUSR."USERID" = OIGE."UserSign2"
	WHERE OIGE."DocEntry" = :list_of_cols_val_tab_del;

		IF BRGRN = 3 THEN
			IF (UserName = 'engg07' OR UserNameU =  'engg07') THEN
				error :=347;
				error_message := N'You are not allowed for UNIT - I Goods issue entry';
			END IF;
		END IF;
END IF;

IF object_type = '60' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;

	SELECT OIGE."BPLId" into BRGRN FROM OIGE WHERE OIGE."DocEntry" = :list_of_cols_val_tab_del;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN OIGE ON OUSR."USERID" = OIGE."UserSign"
	WHERE OIGE."DocEntry" = :list_of_cols_val_tab_del;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN OIGE ON OUSR."USERID" = OIGE."UserSign2"
	WHERE OIGE."DocEntry" = :list_of_cols_val_tab_del;

		IF BRGRN = 4 THEN
			IF (UserName = 'engg02' OR UserNameU = 'engg02') THEN
				error :=348;
				error_message := N'You are not allowed for UNIT - II Goods issue entry';
			END IF;
		END IF;
END IF;
-------------------------
IF object_type = '59' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;

	SELECT OIGN."BPLId" into BRGRN FROM OIGN WHERE OIGN."DocEntry" = :list_of_cols_val_tab_del;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN OIGN ON OUSR."USERID" = OIGN."UserSign"
	WHERE OIGN."DocEntry" = :list_of_cols_val_tab_del;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN OIGN ON OUSR."USERID" = OIGN."UserSign2"
	WHERE OIGN."DocEntry" = :list_of_cols_val_tab_del;

		IF BRGRN = 3 THEN
			IF (UserName = 'engg07' OR UserNameU =  'engg07') THEN
				error :=349;
				error_message := N'You are not allowed for UNIT - I Goods receipt entry';
			END IF;
		END IF;
END IF;

IF object_type = '59' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;

	SELECT OIGN."BPLId" into BRGRN FROM OIGN WHERE OIGN."DocEntry" = :list_of_cols_val_tab_del;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN OIGN ON OUSR."USERID" = OIGN."UserSign"
	WHERE OIGN."DocEntry" = :list_of_cols_val_tab_del;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN OIGN ON OUSR."USERID" = OIGN."UserSign2"
	WHERE OIGN."DocEntry" = :list_of_cols_val_tab_del;

		IF BRGRN = 4 THEN
			IF (UserName = 'engg02' OR UserNameU = 'engg02') THEN
				error :=350;
				error_message := N'You are not allowed for UNIT - II Goods receipt entry';
			END IF;
		END IF;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE Price Decimal;
DECLARE ItemCode Nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinGRN <= :MaxGRN DO

	SELECT PDN1."ItemCode" INTO ItemCode FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry"
	WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN;

		IF ItemCode LIKE 'PCPM%' THEN

		SELECT PDN1."Price" into Price FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry"
		WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN;

			IF (Price = 0) THEN
				error :=351;
				error_message := N'Please enter price';
			END IF;
		END IF;
	MinGRN := MinGRN+1;
	END WHILE;
END IF;
-------------------------- Remarks with minimun 20 words---------------

IF object_type IN ('59') AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE Comments Int;
DECLARE JrnalMemo Nvarchar(50);


			SELECT T0."JrnlMemo" into JrnalMemo FROM OIGN T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
			IF JrnalMemo = 'Goods Receipt' THEN
				SELECT LENGTH(T0."Comments") into Comments FROM OIGN T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

					IF (Comments < 50 OR Comments IS NULL) THEN
						error :=352;
						error_message := N'Please mention remarks with minimum 20 words';
					END IF;
			END IF;
END IF;

IF object_type IN ('60') AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE Comments Int;
DECLARE JrnalMemo Nvarchar(50);

		SELECT T0."JrnlMemo" into JrnalMemo FROM OIGE T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
			IF JrnalMemo = 'Goods Issue' THEN
				SELECT LENGTH(T0."Comments") into Comments FROM OIGE T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
					IF (Comments < 50 OR Comments IS NULL) THEN
						error :=353;
						error_message := N'Please mention remarks with minimum 20 words';
					END IF;
			END IF;
END IF;

IF object_type IN ('14') AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE Comments Int;

			SELECT LENGTH(T0."Comments") into Comments FROM ORIN T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
				IF (Comments < 50 OR Comments IS NULL) THEN
					error :=354;
					error_message := N'Please mention remarks with minimum 20 words';
				END IF;
END IF;

IF object_type IN ('19') AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE Comments Int;

			SELECT LENGTH(T0."Comments") into Comments FROM ORPC T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
				IF (Comments < 50 OR Comments IS NULL) THEN
				error :=355;
				error_message := N'Please mention remark with minimum 20 words';
		END IF;
END IF;

IF object_type IN ('18') AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE Comments Int;

			SELECT LENGTH(T0."Comments") into Comments FROM OPCH T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
				IF (Comments < 50 OR Comments IS NULL) THEN
				error :=356;
				error_message := N'Please mention remark with minimum 20 words';
		END IF;
END IF;

IF object_type IN ('24') AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE Comments Int;

			SELECT LENGTH(T0."Comments") into Comments FROM ORCT T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
				IF (Comments < 50 OR Comments IS NULL) THEN
				error :=358;
				error_message := N'Please mention remark with minimum 20 words';
		END IF;
END IF;

IF object_type IN ('30') AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE Memo Int;
DECLARE TransType Int;

		SELECT T0."TransType" into TransType FROM OJDT T0 WHERE T0."TransId" = :list_of_cols_val_tab_del;
		SELECT LENGTH(T0."Memo") into Memo FROM OJDT T0 WHERE T0."TransId" = :list_of_cols_val_tab_del;
			IF TransType = 30 THEN
				IF (Memo < 50 OR Memo IS NULL) THEN
					error :=359;
					error_message := N'Please mention remark with minimum 20 words';
				END IF;
			END IF;
END IF;

--------------------Delay Remarks-------

IF object_type = '13' AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE DelayRemark Nvarchar(50);

		SELECT T1."U_RMKSTR" into DelayRemark FROM OINV T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;

		IF DelayRemark <> 'Booking pending from forwarder' AND DelayRemark <> 'Container arrange as per planning' AND DelayRemark <> 'FOB shipment' AND DelayRemark <> 'ISO arrange as per planning'
			AND DelayRemark <> 'LCL shipment' AND DelayRemark <> 'Party asking for late dispatch' then
			error :=360;
			error_message := N'Please select proper Invoie delay remark';
		END IF;

END IF;

IF object_type = '13' AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE BLdelayRemark Nvarchar(50);

		SELECT T1."U_RMKPRD" into BLdelayRemark FROM OINV T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;

		IF BLdelayRemark <> 'Container available on this vessel' AND BLdelayRemark <> 'Vessel delay' then
			error :=361;
			error_message := N'Please select proper BL delay remark';
		END IF;

END IF;

IF object_type = '46' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE DocType Nvarchar(50);
DECLARE TransfAcc Int;
DECLARE TransFSum Int;

		SELECT OVPM."DocType" into DocType FROM OVPM WHERE OVPM."DocEntry" = :list_of_cols_val_tab_del;
		SELECT OVPM."TrsfrAcct" into TransfAcc FROM OVPM WHERE OVPM."DocEntry" = :list_of_cols_val_tab_del;
		SELECT OVPM."TrsfrSum" into TransFSum FROM OVPM WHERE OVPM."DocEntry" = :list_of_cols_val_tab_del;

		IF DocType = 'A' AND TransfAcc = 10601002 then
			IF 	TransFSum > 9999 then
				error :=362;
				error_message := N'Cash entry not allowed more than 10000 Rs';
			END IF;
		END IF;
END IF;

IF object_type = 'QcInProcess' AND ( :transaction_type = 'A' OR :transaction_type = 'U')   THEN
DECLARE IC varchar(50);
DECLARE Batch varchar(500);
--DECLARE Series varchar(20);
DECLARE Branch varchar(50);
DECLARE Date1 date;

	SELECT T1."U_Batch_No" INTO Batch FROM "@QCINPROCESS" T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."U_ItemCode" INTO IC FROM "@QCINPROCESS" T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."U_DocDate" INTO Date1 FROM "@QCINPROCESS" T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."U_Branch" INTO Branch FROM "@QCINPROCESS" T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;

	IF Branch = 'UNIT - I' THEN
		IF Batch <> '2023/U1/1112' THEN
		IF IC LIKE 'PC%' then
			IF (Date1 >= '20220101' and Date1 <= '20221231')  and Batch NOT LIKE '2022/%' THEN
				error := 364;
				error_message := 'Inprocess Batch may wrong';
			END IF;
			IF Date1 < '20220101' and Batch NOT LIKE '2021/%' THEN
				error := 365;
				error_message := 'Inprocess Batch may wrong';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and Batch NOT LIKE '2324/PU1/____' THEN
				error := 367;
				error_message := 'Inprocess Batch may wrong';
			END IF;
		END IF;
		END IF;
	END IF;

	IF Branch = 'UNIT - II' THEN
		IF IC LIKE 'PC%' then
			IF (Date1 >= '20220101' and Date1 <= '20221231')  and Batch NOT LIKE '2022/U2/%' THEN
				error := 368;
				error_message := 'Inprocess Batch may wrong';
			END IF;
			IF Date1 < '20220101' and Batch NOT LIKE '2021/%' THEN
				error := 369;
				error_message := 'Inprocess Batch may wrong';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and Batch NOT LIKE '2324/PU2/____' THEN
				error := 370;
				error_message := 'Inprocess Batch may wrong';
			END IF;
		END IF;
	END IF;
END IF;
-----------------------------------------

IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE project nvarchar(50);
DECLARE BROR Int;

	SELECT Min(T0."VisOrder") INTO MinIN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OPDN."BPLId" into BROR FROM OPDN WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del;

	WHILE :MinIN <= :MaxIN DO

		IF BROR = 3 THEN

			SELECT PDN1."Project" into project FROM PDN1 WHERE PDN1."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=MinIN;

			IF project IS NULL OR project = '' THEN
					error :=375;
					error_message := N'For unit 1 Please select project as corporate or NA';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE project nvarchar(50);
DECLARE BROR Int;

	SELECT Min(T0."VisOrder") INTO MinIN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OPDN."BPLId" into BROR FROM OPDN WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del;

	WHILE :MinIN <= :MaxIN DO

		IF BROR = 4 THEN

			SELECT PDN1."Project" into project FROM PDN1 WHERE PDN1."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=MinIN;

			IF project = 'Corpo. House' OR project = 'NA' THEN
					error :=376;
					error_message := N'For unit 2 do not select project' ||  MinIN;
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE project nvarchar(50);
DECLARE BROR Int;

	SELECT Min(T0."VisOrder") INTO MinIN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OPDN."BPLId" into BROR FROM OPDN WHERE OPDN."DocEntry" = :list_of_cols_val_tab_del;

	WHILE :MinIN <= :MaxIN DO

		IF BROR = 5 THEN

			SELECT PDN1."Project" into project FROM PDN1 WHERE PDN1."DocEntry" = :list_of_cols_val_tab_del and PDN1."VisOrder"=MinIN;

			IF project = 'Corpo. House' OR project = 'NA' THEN
					error :=377;
					error_message := N'For unit 3 do not select project';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;

IF object_type = '18' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE project nvarchar(50);
DECLARE BROR Int;

	SELECT Min(T0."VisOrder") INTO MinIN from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OPCH."BPLId" into BROR FROM OPCH WHERE OPCH."DocEntry" = :list_of_cols_val_tab_del;

	WHILE :MinIN <= :MaxIN DO

		IF BROR = 3 THEN

			SELECT PCH1."Project" into project FROM PCH1 WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder"=MinIN;

			IF project IS NULL OR project = '' THEN
					error :=378;
					error_message := N'For unit 1 Please select project as corporate or NA';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;

IF object_type = '18' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE project nvarchar(50);
DECLARE BROR Int;

	SELECT Min(T0."VisOrder") INTO MinIN from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OPCH."BPLId" into BROR FROM OPCH WHERE OPCH."DocEntry" = :list_of_cols_val_tab_del;

	WHILE :MinIN <= :MaxIN DO

		IF BROR = 4 THEN

			SELECT PCH1."Project" into project FROM PCH1 WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder"=MinIN;

			IF project = 'Corpo. House' OR project = 'NA' THEN
					error :=379;
					error_message := N'For unit 2 do not select project';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;

IF object_type = '18' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE project nvarchar(50);
DECLARE BROR Int;

	SELECT Min(T0."VisOrder") INTO MinIN from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OPCH."BPLId" into BROR FROM OPCH WHERE OPCH."DocEntry" = :list_of_cols_val_tab_del;

	WHILE :MinIN <= :MaxIN DO

		IF BROR = 5 THEN

			SELECT PCH1."Project" into project FROM PCH1 WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder"=MinIN;

			IF project = 'Corpo. House' OR project = 'NA' THEN
					error :=380;
					error_message := N'For unit 3 do not select project';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;

-------------------------
-- FORM Name   : Production Order
-- Added Date  : 12-05-2023
-- Note        : This SP will restrict user to add Attachments if production order is not approved.


IF object_type = '202' AND (:transaction_type = 'U') THEN

DECLARE TotalAttachment Int;
DECLARE Approve Nvarchar(150);

SELECT OWOR."U_Approve" INTO Approve FROM OWOR WHERE OWOR."DocEntry"=list_of_cols_val_tab_del;
SELECT COUNT(*) INTO TotalAttachment FROM OATC AS T0 LEFT JOIN OWOR AS T1 ON T1."AtcEntry" = T0."AbsEntry" WHERE T1."DocEntry" = :list_of_cols_val_tab_del;

		IF Approve != 'Approved' AND TotalAttachment >0 THEN
			error := 381;
			error_message := 'Attachments are not allowed because prodcution order is not approved.';
		END IF;
END IF;

---------------- Qc-Inprocess not allowed to change manually parameter---------
-- FORM Name   : Qc InProcess Form
-- Note        : Qc-Inprocess not allowed to change manually parameter But Some special parameters allowed.

IF object_type = 'QcInProcess' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE parameter Nvarchar(500);
DECLARE parameterCP Nvarchar(500);
DECLARE Count Int;
DECLARE Cnt1 Int;
DECLARE Cnt2 Int;

DECLARE ItemCode Nvarchar(20);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE CntLine Int;

	SELECT Min(T0."LineId") INTO MinLinePDQ from "@QCINPROCESSR" T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."LineId") INTO MaxLinePDQ from "@QCINPROCESSR" T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT count(*) INTO CntLine from "@QCINPROCESSR" T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinLinePDQ<=MaxLinePDQ DO

	select count(*) INTO CntLine from "@QCINPROCESSR" T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."LineId" = MinLinePDQ;

		IF (CntLine > 0) THEN

			select T0."U_ItemCode" INTO ItemCode from "@QCINPROCESS" T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
			select T0."U_Parameter" INTO parameter from "@QCINPROCESSR" T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."LineId" = MinLinePDQ;

			IF(parameter IS NULL OR parameter = '' ) THEN
			 	 	error :=382;
	                error_message := N'Parameter field should not be blank : '   ;
	        ELSE
		       SELECT count(*) INTO Cnt1 FROM "@Q_CTS1" T0 INNER JOIN "@Q_QCTS" T1 ON  T0."Code" = T1."Code"
						WHERE T1."U_ItemCode" =  ItemCode AND T0."U_ParamName" = parameter;

				SELECT count(*) INTO Cnt2 from "@QCINPROCESSCP"  Where "Code" = ItemCode AND "U_Parameter" =parameter;

			 	IF (Cnt1 = 0 AND Cnt2 = 0) THEN
		     	 	error :=383;
		            error_message := N'Please select parameter, You are not allowed to write parameter manually : ' || parameter ;
		     	END If;
			END IF;

     	End If;
	    MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;
-------------------------------Estinmated freight for Domestic sales--------------

IF object_type = '13' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE SeriesAR nvarchar(50);

DECLARE TransCost Double;


		(SELECT T1."SeriesName" into SeriesAR FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del);

		IF SeriesAR LIKE 'DM%' THEN

		SELECT OINV."U_E_Trans_Cost" into TransCost FROM OINV WHERE OINV."DocEntry" = list_of_cols_val_tab_del;

				IF TransCost IS NULL OR TransCost = 0.000 then
					error :=384;
					error_message := N'For domestic invoive please entre Estimated transportation cost';
				END IF;

		END IF;
END IF;

---------------------------------------------------------------
-- FORM Name   : A/R Down payment Request
-- Added Date  : 25-05-2023
-- Note        : This SP will check port name must be from the list.

IF Object_type = '203' and (:transaction_type = 'A' OR :transaction_type = 'U') Then

DECLARE PLoad nvarchar(50);
DECLARE PDischrg nvarchar(50);
DECLARE ADSeries nvarchar(50);
DECLARE PrtCnt Int;
DECLARE PrtCnt1 Int;

	(SELECT T0."U_PLoad" into PLoad FROM ODPI T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del);
	(SELECT T0."U_PDischrg" into PDischrg FROM ODPI T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del);
	(SELECT T1."SeriesName" into ADSeries FROM ODPI T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"=:list_of_cols_val_tab_del );

		IF (ADSeries LIKE 'EX%') THEN

		       SELECT count(*) INTO PrtCnt FROM "@PORTMASTER" T0 WHERE "U_PortName" =:PLoad;
		       IF (PrtCnt = 0) THEN
				 	error:=385;
					error_message:=N'Please Select Proper [Port of Loading] from Port Master List';
		       END IF;

		       SELECT count(*) INTO PrtCnt1 FROM "@PORTMASTER" T0 WHERE "U_PortName" =:PDischrg;
		       IF (PrtCnt1 = 0) THEN
				 	error:=386;
					error_message:=N'Please Select Proper [Port of Discharge] from Port Master List';
		       END IF;

		END IF;
END IF;

---------------------------------------------------------------
-- FORM Name   : Delivery
-- Added Date  : 25-05-2023
-- Note        : This SP will check port name must be from the list.

IF Object_type = '15' and (:transaction_type = 'A' OR :transaction_type = 'U') Then

DECLARE PLoad nvarchar(50);
DECLARE PDischrg nvarchar(50);
DECLARE ADSeries nvarchar(50);
DECLARE PrtCnt Int;
DECLARE PrtCnt1 Int;

	(SELECT T0."U_PLoad" into PLoad FROM ODLN T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del);
	(SELECT T0."U_PDischrg" into PDischrg FROM ODLN T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del);
	(SELECT T1."SeriesName" into ADSeries FROM ODLN T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"=:list_of_cols_val_tab_del );

		IF (ADSeries LIKE 'EX%') THEN

		       SELECT count(*) INTO PrtCnt FROM "@PORTMASTER" T0 WHERE "U_PortName" =:PLoad;
		       IF (PrtCnt = 0) THEN
				 	error:=387;
					error_message:=N'Please Select Proper [Port of Loading] from Port Master List';
		       END IF;

		       SELECT count(*) INTO PrtCnt1 FROM "@PORTMASTER" T0 WHERE "U_PortName" =:PDischrg;
		       IF (PrtCnt1 = 0) THEN
				 	error:=388;
					error_message:=N'Please Select Proper [Port of Discharge] from Port Master List';
		       END IF;
		END IF;
END IF;

---------------------------------------------------------------
-- FORM Name   : A/R Invoice
-- Added Date  : 25-05-2023
-- Note        : This SP will check port name must be from the list.

-- Commented Because Approval of Ramesh sir and ruchit sir is pending

IF Object_type = '13' and (:transaction_type = 'A' OR :transaction_type = 'U') Then

DECLARE PLoad nvarchar(50);
DECLARE PDischrg nvarchar(50);
DECLARE ADSeries nvarchar(50);
DECLARE PrtCnt Int;
DECLARE PrtCnt1 Int;

	(SELECT T0."U_PLoad" into PLoad FROM OINV T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del);
	(SELECT T0."U_PDischrg" into PDischrg FROM OINV T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del);
	(SELECT T1."SeriesName" into ADSeries FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"=:list_of_cols_val_tab_del );

		IF (ADSeries LIKE 'EX%') THEN

		       SELECT count(*) INTO PrtCnt FROM "@PORTMASTER" T0 WHERE "U_PortName" =:PLoad;
		       IF (PrtCnt = 0) THEN
				 	error:=389;
					error_message:=N'Please Select Proper [Port of Loading] from Port Master List';
		       END IF;

		       SELECT count(*) INTO PrtCnt1 FROM "@PORTMASTER" T0 WHERE "U_PortName" =:PDischrg;
		       IF (PrtCnt1 = 0) THEN
				 	error:=390;
					error_message:=N'Please Select Proper [Port of Discharge] from Port Master List';
		       END IF;
		END IF;
END IF;

----------------------------------
-- FORM Name   : IMEX TRACKING
-- Added Date  : 29-05-2023
-- Note        : 1.B/L Date should not more than 2 months from dispatch date and not less than dispatch date

IF Object_type = 'SHIPMASTER' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
Declare BLDate date;
Declare InvDocDate date;
Declare InvDDPl2 date;
Declare InvDet1 Int;
Declare dayss Int;
Declare VesselETD date;
Declare VesselETA nvarchar(100);
Declare TransitDays INT;

		SELECT "U_BLDate" INTO BLDate FROM "@SHIPMASTER" T0 WHERE T0."Code" = list_of_cols_val_tab_del;
		SELECT "U_InvDet1","U_TransTime" INTO InvDet1,TransitDays FROM "@SHIPMASTER" T0 WHERE T0."Code" = list_of_cols_val_tab_del;

		IF InvDet1 IS NOT NULL THEN
			SELECT  T0."DocDate" INTO InvDocDate from OINV T0 WHERE T0."DocEntry" = InvDet1;
			SELECT T0."U_ETA",T0."U_ETADis" INTO VesselETD,VesselETA from "@SHIPMASTER" T0 where T0."Code" = list_of_cols_val_tab_del;

				IF BLDate IS NOT NULL THEN
				  SELECT DAYS_BETWEEN(InvDocDate,BLDate) INTO dayss FROM dummy;
				  SELECT ADD_MONTHS(InvDocDate,2) INTO InvDDPl2 FROM dummy;

				  IF (dayss < 0) THEN
				    error :=391;
				    error_message := N'BL date should not less than dispatch date';
				  END IF;

				  IF (BLDate > InvDDPl2 ) THEN
				     error :=392;
				     error_message := N'BL date should not more than 2 months from dispatch date';
				  END IF;
			    End If;

			    IF IFNULL(VesselETD,'') = '' THEN
			    	error :=393;
				    error_message := N'Please select Vessel ETD.';
				END IF;

				IF IFNULL(VesselETA,'') NOT LIKE_REGEXPR '^[0-3][0-9]/[0-1][0-9]/[0-9]{2}$' THEN
				    error := 394;
				    error_message := N'ETA must be in DD/MM/YY format (e.g., 11/12/25).';
				END IF;

				IF IFNULL(TransitDays,0) = 0 THEN
					error :=394;
				    error_message := N'Please select Transit Days.';
				END IF;
		END IF;
END IF;
----------------------------- Receipt quantity---------------

IF Object_type = '20' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare ItCode nvarchar(50);
Declare RecQty int;
DECLARE MinGRN int;
DECLARE MaxGRN int;

	SELECT Min(T0."VisOrder") INTO MinGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE MinGRN<=MaxGRN DO
		(Select PDN1."ItemCode" into ItCode from PDN1 WHERE PDN1."DocEntry"=list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN);
		(Select PDN1."U_UNE_ACQT" into RecQty from PDN1 WHERE PDN1."DocEntry"=list_of_cols_val_tab_del and PDN1."VisOrder"=MinGRN);

		IF (ItCode LIKE '%RM%' OR ItCode LIKE '%FG%' OR ItCode LIKE '%TR%') THEN
	         IF (RecQty IS NULL OR RecQty = 0) then
	         	  error :=393;
	              error_message := N'Please enter receipt quantity';
	            END IF;
	         END IF;
     MinGRN := MinGRN+1;
	END WHILE;
End If;
--------------------- Tag number------------
IF object_type = '18' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinPO Int;
DECLARE MaxPO Int;
DECLARE ItemCode Nvarchar(50);
DECLARE Tagnum Nvarchar(5000);
DECLARE BRPO Int;

	SELECT Min(T0."VisOrder") INTO MinPO from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxPO from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	SELECT OPCH."U_Tag_number" into Tagnum FROM OPCH WHERE OPCH."DocEntry" = :list_of_cols_val_tab_del;

	IF Tagnum IS NULL THEN

	WHILE :MinPO <= :MaxPO DO
			SELECT PCH1."ItemCode" into ItemCode FROM PCH1 WHERE PCH1."DocEntry" = :list_of_cols_val_tab_del and PCH1."VisOrder"=MinPO;
				IF ItemCode NOT IN ('FURN0021','FURN0020') THEN
					IF (ItemCode LIKE 'FA%' OR ItemCode LIKE 'FU%') THEN
						error :=395;
						error_message := N'For Fixed asset items, please enter Tag number';
					END IF;
				END IF;
			MinPO := MinPO+1;
		END WHILE;
	END IF;
END IF;
----------A/R Credit Memo--------------
IF Object_type = '14' and (:transaction_type ='A' or :transaction_type ='U' ) Then
DECLARE MinAP Int;
DECLARE MaxAP Int;
Declare OcrCode nvarchar(50);
Declare ItmCode nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinAP from RIN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from RIN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinAP <= :MaxAP DO
		(Select RIN1."OcrCode" into OcrCode from RIN1 where RIN1."DocEntry"=list_of_cols_val_tab_del and RIN1."VisOrder"=MinAP);
		(Select RIN1."ItemCode" into ItmCode from RIN1 where RIN1."DocEntry"=list_of_cols_val_tab_del and RIN1."VisOrder"=MinAP);
	          IF (OcrCode = '' OR OcrCode IS NULL) then
	          	error :=396;
	          	error_message := N'Please Select Distr. Rule in Document'||ItmCode;
	         End If;
         MinAP := MinAP+1;
		END WHILE;
End If;
----------A/P Credit Memo--------------
IF Object_type = '19' and (:transaction_type ='A' or :transaction_type ='U' ) Then
DECLARE MinAP Int;
DECLARE MaxAP Int;
Declare OcrCode nvarchar(50);
Declare ItmCode nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinAP from RPC1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from RPC1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinAP <= :MaxAP DO
		(Select RPC1."OcrCode" into OcrCode from RPC1 where RPC1."DocEntry"=list_of_cols_val_tab_del and RPC1."VisOrder"=MinAP);
		(Select RPC1."ItemCode" into ItmCode from RPC1 where RPC1."DocEntry"=list_of_cols_val_tab_del and RPC1."VisOrder"=MinAP);
	          IF (OcrCode = '' OR OcrCode IS NULL) then
	          	error :=397;
	          	error_message := N'Please Select Distr. Rule in Document'||ItmCode;
	         End If;
         MinAP := MinAP+1;
		END WHILE;
End If;

----------Reactor number in Production


IF Object_type = '202' and (:transaction_type ='A' OR :transaction_type = 'U') Then
Declare ReactorNo nvarchar(20);
Declare EntryType nvarchar(50);
Declare Spc_Reason nvarchar(50);

select OWOR."U_Reactor_num" into ReactorNo from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;
select OWOR."Type" into EntryType from OWOR where OWOR."DocEntry"= :list_of_cols_val_tab_del;
select OWOR."U_sp_ent_reason" into Spc_Reason from OWOR where OWOR."DocEntry"= :list_of_cols_val_tab_del;


	IF EntryType = 'S' OR (Spc_Reason IN ('Actual Blending','Special Blending') AND  EntryType = 'P' ) THEN
		IF (ReactorNo IS NULL OR ReactorNo = '') THEN
		    error :=398;
		    error_message := N'Please select reactor number';
		END IF;
	END IF;
END IF;

--------------------------------------------------

IF Object_type = '202' and (:transaction_type ='A' OR :transaction_type = 'U') Then

Declare ReactorNo nvarchar(20);
Declare REACTORPC1 INT;
Declare REACTORPC2 INT;
Declare REACTORDI1 INT;
Declare Series nvarchar(20);
Declare Branch nvarchar(20);
Declare EntryType nvarchar(50);
Declare Spc_Reason nvarchar(50);

select OWOR."Type" into EntryType from OWOR where OWOR."DocEntry"= :list_of_cols_val_tab_del;
select OWOR."U_sp_ent_reason" into Spc_Reason from OWOR where OWOR."DocEntry"= :list_of_cols_val_tab_del;

IF EntryType = 'S' OR (Spc_Reason IN ('Actual Blending','Special Blending') AND  EntryType = 'P' ) THEN

	select OWOR."U_Reactor_num" into ReactorNo from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;
	select NNM1."SeriesName" into Series from OWOR LEFT JOIN NNM1 ON NNM1."Series" = OWOR."Series" WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;
	select COUNT(T0."Code") INTO REACTORPC1 from "@REACTOR_MASTER" T0 WHERE T0."U_Division" = 'PC' AND T0."U_Unit" = 'UNIT - I' AND T0."Code" = ReactorNo ;
	select COUNT(T0."Code") INTO REACTORPC2 from "@REACTOR_MASTER" T0 WHERE T0."U_Division" = 'PC' AND T0."U_Unit" = 'UNIT - II' AND T0."Code" = ReactorNo ;
	select COUNT(T0."Code") INTO REACTORDI1 from "@REACTOR_MASTER" T0 WHERE T0."U_Division" = 'SC' AND T0."U_Unit" = 'UNIT - I' AND T0."Code" = ReactorNo ;

			IF Series LIKE 'PC1/%' THEN
			 	IF REACTORPC1 = 0 THEN
				    error :=399;
				    error_message := N'Please select correct reactor number ';
			    END IF;
			END IF;

			IF Series LIKE 'PC2/%' THEN
			 	IF REACTORPC2 = 0 THEN
				    error :=400;
				    error_message := N'Please select correct reactor number ';
			    END IF;
			END IF;

			IF Series LIKE 'SC1/%' THEN
			 	IF REACTORDI1 = 0 THEN
				    error :=401;
				    error_message := N'Please select correct reactor number ';
			    END IF;
			END IF;
	END IF;

END IF;
-------------
-- FORM Name   : QC In Process
-- Note        : Remarks column should not be blank and less than 20 words if status is Other.
IF object_type = 'QcInProcess' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE CntLine Int;
DECLARE DlyRsn Nvarchar(250);
DECLARE Remarks Nvarchar(250);
DECLARE SpaceCount Int;

DECLARE ItemCode Nvarchar(20);

	SELECT Min(T0."LineId") INTO MinLinePDQ from "@QCINPROCESSR" T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."LineId") INTO MaxLinePDQ from "@QCINPROCESSR" T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinLinePDQ<=MaxLinePDQ DO

	  		SELECT COUNT(*) INTO CntLine from "@QCINPROCESSR" T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."LineId" = MinLinePDQ;
		 	  IF (CntLine > 0) THEN

		 		 SELECT T0."U_DlyRsn" INTO DlyRsn from "@QCINPROCESSR" T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."LineId" = MinLinePDQ;

				 IF (DlyRsn = 'other') THEN
				    SELECT T0."U_remarks" INTO Remarks from "@QCINPROCESSR" T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."LineId" = MinLinePDQ;

				    IF (Remarks IS NULL OR Remarks = '') THEN
				   			error :=411;
				            error_message := N'Remark column should not be blank because you have seleted [Other] in Status column.';
				    ELSE
				        SELECT LENGTH(Remarks) - LENGTH(REPLACE(Remarks,' ', '')) INTO SpaceCount FROM Dummy;
				         IF (SpaceCount < 2) THEN
				   			error :=412;
				            error_message := N'Remarks column must contain minimum 2 words.';
				        END If;
				    End If;
		 		 End If;
		   	  End If;
	 MinLinePDQ := MinLinePDQ+1;

	END WHILE;

END IF;
------------------Not allowed to select Expended warehouse ----------------

IF object_type = '20' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE warehouse Nvarchar(50);
DECLARE ItemCode Nvarchar(20);
DECLARE BPLId Int;
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	SELECT T0."BPLId" INTO BPLId FROM OPDN T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del;

	IF BPLId = 4 THEN

		WHILE :MinLinePDQ<=MaxLinePDQ DO

			select T0."ItemCode" INTO ItemCode from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

			IF ItemCode LIKE 'PCPM%' THEN
			select T0."WhsCode" INTO warehouse from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
				IF (warehouse <> '2EX1PCPM' AND warehouse <> '2PC-PAC') THEN
					error :=413;
					error_message := N'For packing material select 2PC-PAC OR Extended Packing warehouse...!';
				END IF;
			END IF;

			IF ItemCode NOT LIKE 'PCPM%' THEN
			select T0."WhsCode" INTO warehouse from PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
				IF (warehouse LIKE '2EX%') THEN
					error :=414;
					error_message := N'Not allowed to select Extended warehouse...!';
				END IF;
			END IF;
		MinLinePDQ := MinLinePDQ+1;
		END WHILE;
	END IF;
END IF;

IF object_type = '18' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE warehouse Nvarchar(50);
DECLARE ItemCode Nvarchar(20);
DECLARE BPLId Int;
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	SELECT T0."BPLId" INTO BPLId FROM OPCH T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del;

	IF BPLId = 4 THEN

		WHILE :MinLinePDQ<=MaxLinePDQ DO

			select T0."ItemCode" INTO ItemCode from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

			IF ItemCode LIKE 'PCPM%' THEN
			select T0."WhsCode" INTO warehouse from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

				IF (warehouse <> '2EX1PCPM' AND warehouse <> '2PC-PAC') THEN
					error :=417;
					error_message := N'For packing material select 2PC-PAC OR Extended Packing warehouse...!';
				END IF;
			END IF;

			IF ItemCode NOT LIKE 'PCPM%' THEN
			select T0."WhsCode" INTO warehouse from PCH1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
				IF (warehouse LIKE '2EX%') THEN
					error :=418;
					error_message := N'Not allowed to select Extended warehouse...!';
				END IF;
			END IF;
		MinLinePDQ := MinLinePDQ+1;
		END WHILE;
	END IF;
END IF;

IF object_type = '13' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE warehouse Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinLinePDQ<=MaxLinePDQ DO

		select T0."WhsCode" INTO warehouse from INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
			IF warehouse LIKE '2EX%' THEN
				error :=419;
				error_message := N'Not allowed to select Extended warehouse...!';
			END IF;
	MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;

IF object_type = '60' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE warehouse Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinLinePDQ<=MaxLinePDQ DO

		select T0."WhsCode" INTO warehouse from IGE1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
			IF warehouse LIKE '2EX%' THEN
				error :=420;
				error_message := N'Not allowed to select Extended warehouse...!';
			END IF;
	MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;

IF object_type = '59' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE warehouse Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinLinePDQ<=MaxLinePDQ DO

		select T0."WhsCode" INTO warehouse from IGN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
			IF warehouse LIKE '2EX%' THEN
				error :=421;
				error_message := N'Not allowed to select Extended warehouse...!';
			END IF;
	MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;

IF Object_type = '67' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare Usr nvarchar(50);
Declare Frmwhs nvarchar(50);
DECLARE MinLineITQ Int;
DECLARE MaxLineITQ Int;

	SELECT Min(T0."VisOrder") INTO MinLineITQ from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineITQ from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into Usr from OWTR INNER JOIN OUSR ON OUSR."USERID" = OWTR."UserSign" where OWTR."DocEntry"= :list_of_cols_val_tab_del;

	WHILE :MinLineITQ<=MaxLineITQ DO
		select WTR1."FromWhsCod" into Frmwhs from WTR1 where WTR1."DocEntry"= :list_of_cols_val_tab_del
		and WTR1."VisOrder"=MinLineITQ;
		If (Usr NOT IN ('engg07') AND Frmwhs LIKE '2EX1%') then
		    error :=422;
		    error_message := N'You are not allowed to do inventory transfer from Extended Warehouse'||MinLineITQ;
		END IF;
		MinLineITQ := MinLineITQ+1;
	END WHILE;
END IF;

IF object_type = '67' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE ITCode Nvarchar(50);
DECLARE ITWhsCode Nvarchar(50);
DECLARE Branch Nvarchar(50);
	SELECT Min(T0."VisOrder") INTO MinIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OBPL."BPLName" INTO Branch FROM OWTR INNER JOIN OBPL ON OBPL."BPLId" = OWTR."BPLId" WHERE OWTR."DocEntry" =:list_of_cols_val_tab_del;

	IF Branch = 'UNIT - II' THEN

	WHILE :MinIT <= :MaxIT DO
		SELECT WTR1."ItemCode" into ITCode FROM WTR1 WHERE WTR1."DocEntry" = :list_of_cols_val_tab_del and WTR1."VisOrder"=MinIT;
		SELECT WTR1."WhsCode" into ITWhsCode FROM WTR1 WHERE WTR1."DocEntry" = :list_of_cols_val_tab_del and WTR1."VisOrder"=MinIT;
		IF ITWhsCode NOT LIKE '%QCR%' and ITWhsCode NOT LIKE '%TRD%' and ITWhsCode NOT LIKE '%GJCM%' and ITWhsCode NOT LIKE '%PSC%' and ITWhsCode NOT LIKE '%SSPL%' and ITWhsCode NOT LIKE '%ADVP%' and ITWhsCode NOT LIKE '%DE%' and ITWhsCode NOT LIKE '%RSC%' THEN
			IF ITCode LIKE '%PM%' THEN
				IF (ITWhsCode = '2PC-PAC' and ITWhsCode = '2EX1PCPM' AND ITWhsCode NOT LIKE '%BT%') THEN
					error :=423;
					error_message := N'Wrong warehouse for packing material';
				END IF;
			END IF;
		END IF;
		MinIT := MinIT+1;
	END WHILE;
	END IF;
END IF;

---------Exchange rate check-----------------

IF object_type = '20' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE Vendor Nvarchar(20);
DECLARE ExRate Double;
DECLARE U_ExRate Double;

	SELECT "CardCode" INTO Vendor FROM OPDN T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del;

		IF Vendor LIKE 'V__I%' THEN

			SELECT "DocRate" INTO ExRate FROM OPDN T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del;

			SELECT "U_Exchange_Rate" INTO U_ExRate FROM OPDN T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del;

				IF U_ExRate IS NULL THEN
					error :=424;
					error_message := N'Please enter Exchange rate in UDF column';
				END IF;

				IF ExRate <> U_ExRate THEN
					error :=425;
					error_message := N'Please check exchange rate at Header level';
				END IF;
		END IF;
END IF;

----------------------------------------------------------
-- FORM Name : Delivey
-- Purpose : Payment Terms must be as per Sales Order
IF object_type = '15' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE MinLinePDQ INT;
DECLARE MaxLinePDQ INT;
DECLARE BaseRef INT;
DECLARE BaseEntry INT;
DECLARE BaseType INT;
DECLARE SOPayment nvarchar(200);
DECLARE ARPayment nvarchar(200);
DECLARE DLPayment nvarchar(200);
DECLARE CardCode nvarchar(200);

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
 	SELECT T0."CardCode" INTO CardCode FROM ODLN T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	 			IF BaseType = 17 THEN
    WHILE :MinLinePDQ<=MaxLinePDQ DO
	SELECT T0."BaseRef" INTO BaseRef FROM DLN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
	SELECT T0."BaseEntry" INTO BaseEntry FROM DLN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
	SELECT T0."BaseType" INTO BaseType FROM DLN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
	SELECT OCTG."PymntGroup" INTO DLPayment FROM ODLN INNER JOIN OCTG ON ODLN."GroupNum" = OCTG."GroupNum"
	                           WHERE ODLN."DocEntry"= :list_of_cols_val_tab_del;

			     SELECT OCTG."PymntGroup" INTO SOPayment FROM ORDR INNER JOIN OCTG ON ORDR."GroupNum" = OCTG."GroupNum"
	                           WHERE ORDR."DocEntry"= BaseEntry;
	               IF DLPayment <> SOPayment THEN
	               			error := 427;
	           				error_message := N'Delivery payment terms : [' || DLPayment || '] is not same as base document sales order payment terms [' || SOPayment || ']';
	               END IF;
	MinLinePDQ := MinLinePDQ+1;
	END WHILE;
 END IF;
END IF;
-----------------------------
-- FORM Name : A/R Invoice
-- Purpose : Payment Terms must be as per Sales Order
IF object_type = '13' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE MinLinePDQ INT;
DECLARE MaxLinePDQ INT;
DECLARE BaseRef INT;
DECLARE BaseEntry INT;
DECLARE BaseType INT;
DECLARE SOPayment nvarchar(200);
DECLARE ARPayment nvarchar(200);
DECLARE DLPayment nvarchar(200);
DECLARE CardCode nvarchar(200);

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from INV1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
 	SELECT T0."CardCode" INTO CardCode FROM OINV T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT OCTG."PymntGroup" INTO ARPayment FROM OINV INNER JOIN OCTG ON OINV."GroupNum" = OCTG."GroupNum" WHERE OINV."DocEntry"= :list_of_cols_val_tab_del;

    WHILE :MinLinePDQ<=MaxLinePDQ DO
	 		SELECT T0."BaseRef" INTO BaseRef FROM INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
			SELECT T0."BaseEntry" INTO BaseEntry FROM INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
			SELECT T0."BaseType" INTO BaseType FROM INV1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

			IF BaseType = 17 THEN
			     SELECT OCTG."PymntGroup" INTO SOPayment FROM ORDR INNER JOIN OCTG ON ORDR."GroupNum" = OCTG."GroupNum" WHERE ORDR."DocEntry"= BaseEntry;
	               IF ARPayment <> SOPayment THEN
	               			error := 428;
	           				error_message := N'Invoice payment terms : [' || ARPayment || '] is not same as base document sales order payment terms [' || SOPayment || ']';
	               END IF;
			END IF;

			-- For Export A/R Invoices we will check Delivery as base document.
			IF BaseType = 15 THEN
			     SELECT OCTG."PymntGroup" INTO DLPayment FROM ODLN INNER JOIN OCTG ON ODLN."GroupNum" = OCTG."GroupNum"
	                           WHERE ODLN."DocEntry"= BaseEntry;
	               IF ARPayment <> DLPayment THEN
	               			error := 429;
	           				error_message := N'Invoice payment terms : [' || ARPayment || '] is not same as base document delivery payment terms [' || DLPayment || ']';
	               END IF;
			END IF;
	MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;
-------------
IF Object_type = '202' and (:transaction_type ='A') Then
Declare ItemCode nvarchar(20);
Declare PlanQty Double;

	select OWOR."ItemCode" into ItemCode from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;
	select OWOR."PlannedQty" into PlanQty from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;

		IF ItemCode LIKE 'SC%' THEN
			IF PlanQty = 1 THEN
		    error :=398;
		    error_message := N'Not allowed to add production order with quantity as 1';
		    END IF;
		END IF;
END IF;

IF object_type = '13' AND (:transaction_type = 'U') THEN
DECLARE SeriesAR nvarchar(50);
DECLARE Incoterm nvarchar(250);
DECLARE TransCost Double;
DECLARE CustCCCost Double;
DECLARE OceanFUSD Double;
DECLARE OceanFINR Double;
DECLARE FFcharges Double;
DECLARE TransCostOld Double;
DECLARE CustCCCostOld Double;
DECLARE OceanFUSDOld Double;
DECLARE OceanFINROld Double;
DECLARE FFchargesOld Double;

		(SELECT T1."SeriesName" into SeriesAR FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del);

		IF SeriesAR LIKE 'EX%' THEN

		 SELECT OINV."U_E_Trans_Cost"  into TransCost FROM OINV WHERE OINV."DocEntry" = list_of_cols_val_tab_del;
		 SELECT OINV."U_E_C_Clear_Chrgs" into CustCCCost FROM OINV WHERE OINV."DocEntry" = list_of_cols_val_tab_del;
		 SELECT OINV."U_E_O_Frght_USD" into OceanFUSD FROM OINV WHERE OINV."DocEntry" = list_of_cols_val_tab_del;
		 SELECT OINV."U_E_O_Frght_INT" into OceanFINR FROM OINV WHERE OINV."DocEntry" = list_of_cols_val_tab_del;
		 SELECT OINV."U_E_Frght_Forw_Chrgs" into FFcharges FROM OINV WHERE OINV."DocEntry" = list_of_cols_val_tab_del;

		 SELECT  TOP 1 "U_E_Trans_Cost"  into TransCostOld FROM "ADOC" WHERE "ObjType" = '13' AND "DocEntry" = list_of_cols_val_tab_del ORDER BY "LogInstanc" DESC;
		 SELECT  TOP 1 "U_E_C_Clear_Chrgs"  into CustCCCostOld FROM "ADOC" WHERE "ObjType" = '13' AND "DocEntry" = list_of_cols_val_tab_del ORDER BY "LogInstanc" DESC;
		 SELECT  TOP 1 "U_E_O_Frght_USD"  into OceanFUSDOld FROM "ADOC" WHERE "ObjType" = '13' AND "DocEntry" = list_of_cols_val_tab_del ORDER BY "LogInstanc" DESC;
		 SELECT  TOP 1 "U_E_O_Frght_INT"  into OceanFINROld FROM "ADOC" WHERE "ObjType" = '13' AND "DocEntry" = list_of_cols_val_tab_del ORDER BY "LogInstanc" DESC;
		 SELECT  TOP 1 "U_E_Frght_Forw_Chrgs"  into FFchargesOld FROM "ADOC" WHERE "ObjType" = '13' AND "DocEntry" = list_of_cols_val_tab_del ORDER BY "LogInstanc" DESC;


		 If (TransCost <> TransCostOld) THEN
		    error := 434;
			error_message := N'Estimated Transportation Cost update is not allowed.';
		  END IF;
		 If (CustCCCost <> CustCCCostOld) THEN
		    error := 434;
			error_message := N'Estimated Custom Clearance & Concor Charges update is not allowed.';
		  END IF;
		  If (OceanFUSD <> OceanFUSDOld) THEN
		    error := 434;
			error_message := N'Estimated Ocean Freight Actual USD update is not allowed.';
		  END IF;
		  If (OceanFINR <> OceanFINROld) THEN
		    error := 434;
			error_message := N'Estimated Ocean Freight Actual INR update is not allowed.';
		  END IF;
		  If (FFcharges <> FFchargesOld) THEN
		    error := 434;
			error_message := N'Estimated Freight Forwarder Charges update is not allowed.';
		  END IF;
		END IF;
END IF;
---------------Equipment list fot Engg issue---------------

IF object_type = '60' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE MinLine INT;
DECLARE MaxLine INT;
DECLARE BPLName Nvarchar(10);
DECLARE ItemCode Nvarchar(50);
DECLARE Machinery Nvarchar(254);
DECLARE Remark Nvarchar(500);
DECLARE JMemo Nvarchar(50);

	select T0."JrnlMemo" INTO JMemo from OIGE T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	IF JMemo = 'Goods Issue' THEN

	select T0."BPLName" INTO BPLName from OIGE T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	IF BPLName = 'UNIT - II' THEN

		SELECT Min(T0."VisOrder") INTO MinLine from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxLine from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

		WHILE :MinLine<=MaxLine DO

			select T0."ItemCode" INTO ItemCode from IGE1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLine;

			IF ItemCode LIKE 'E%' THEN

				select T0."U_Machinery" INTO Machinery from IGE1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLine;
				IF Machinery = '' OR Machinery IS NULL THEN
					error :=435;
					error_message := N'Please select Machinery for which item you are issuing...!';
				END IF;

			END IF;
		MinLine := MinLine+1;
		END WHILE;
	END IF;
	END IF;
END IF;

IF object_type = '60' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE MinLine INT;
DECLARE MaxLine INT;
DECLARE BPLNameGI Nvarchar(10);
DECLARE BPLNameE Nvarchar(10);
DECLARE ItemCode Nvarchar(50);
DECLARE Machinery Nvarchar(254);
DECLARE JMemo Nvarchar(50);

	select T0."JrnlMemo" INTO JMemo from OIGE T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	IF JMemo = 'Goods Issue' THEN

	SELECT T0."BPLName" INTO BPLNameGI from OIGE T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	IF BPLNameGI = 'UNIT - II' THEN

		SELECT Min(T0."VisOrder") INTO MinLine from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxLine from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

		WHILE :MinLine<=MaxLine DO

		SELECT T0."ItemCode" INTO ItemCode from IGE1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLine;

		IF ItemCode LIKE 'E%' THEN

			SELECT T0."U_Machinery" INTO Machinery from IGE1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLine;

			IF (Machinery <> '' OR Machinery IS NOT NULL) THEN
			 	SELECT T0."U_BPLName" INTO BPLNameE FROM "@EQUIPMENT" T0 WHERE T0."Code" = Machinery;

				IF BPLNameE <> BPLNameGI THEN
					error :=437;
					error_message := N'Selected Machinery belongs to another branch...!';
				END IF;
			END IF;

		END IF;

		MinLine := MinLine+1;
		END WHILE;
	END IF;
	END IF;
END IF;
----------------------Post vessel (YES/NO)-----------

IF Object_type = '202' and (:transaction_type ='A' OR :transaction_type = 'U') Then

Declare PVName nvarchar(50);
Declare PVused nvarchar(20);
Declare PVStartDate Date;
Declare PVStartTime nvarchar(20);
Declare PVEndDate Date;
Declare PVEndTime nvarchar(20);


select OWOR."U_PV_Used" into PVused from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;

	IF PVused = 'NO' THEN

	select OWOR."U_PV_Name" into PVName from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;

	select OWOR."U_PV_StartD" into PVStartDate from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;

	select OWOR."U_PV_StartT" into PVStartTime from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;

	select OWOR."U_PV_EndD" into PVEndDate from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;

	select OWOR."U_PV_EndT" into PVEndTime from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;

		IF (PVName IS NOT NULL OR PVStartDate IS NOT NULL OR PVStartTime IS NOT NULL OR PVEndDate IS NOT NULL OR PVEndTime IS NOT NULL) THEN
			    error :=438;
			    error_message := N'Please do not select post vessel TAg no., date and time as Post Vessel is not used ';
		 END IF;
	END IF;

END IF;

---------------------------------------------

IF Object_type = '202' and (:transaction_type ='A' OR :transaction_type = 'U') Then

Declare PVName nvarchar(50);
Declare PVused nvarchar(20);
Declare PVStartDate Date;
Declare PVStartTime nvarchar(20);
Declare PVEndDate Date;
Declare PVEndTime nvarchar(20);


select OWOR."U_PV_Used" into PVused from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;

	IF PVused = 'YES' THEN

	select OWOR."U_PV_Name" into PVName from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;

	select OWOR."U_PV_StartD" into PVStartDate from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;

	select OWOR."U_PV_StartT" into PVStartTime from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;

	select OWOR."U_PV_EndD" into PVEndDate from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;

	select OWOR."U_PV_EndT" into PVEndTime from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;

		IF (PVName IS NULL OR PVStartDate IS NULL OR PVStartTime IS NULL OR PVEndDate IS NULL OR PVEndTime IS NULL) THEN
			    error :=439;
			    error_message := N'Please select post vessel Tag no., date and time as Post Vessel is used ';
		 END IF;
	END IF;

END IF;

IF Object_type = '202' and (:transaction_type ='A') Then

Declare ReactorNo nvarchar(50);
Declare Entry INT;
Declare StartDate Date;
Declare StartTime nvarchar(20);
Declare Temp nvarchar(20);

	select OWOR."U_Reactor_num" into ReactorNo from OWOR WHERE OWOR."DocEntry"= :list_of_cols_val_tab_del;

	select WOR1."U_Startdate" into StartDate from WOR1 WHERE WOR1."DocEntry"= :list_of_cols_val_tab_del AND WOR1."LineNum" = 0;

	select WOR1."U_Starttime" into StartTime from WOR1 WHERE WOR1."DocEntry"= :list_of_cols_val_tab_del AND WOR1."LineNum" = 0;

	select COUNT(OWOR."DocEntry") into Entry from OWOR INNER JOIN WOR1 ON OWOR."DocEntry" = WOR1."DocEntry" WHERE OWOR."U_Reactor_num"= ReactorNo AND WOR1."U_Enddate" = StartDate AND WOR1."U_Endtime" > StartTime AND WOR1."U_Starttime" < StartTime ;

		IF Entry > 0 THEN

		select "DocNum" into Temp from OWOR INNER JOIN WOR1 ON OWOR."DocEntry" = WOR1."DocEntry" WHERE OWOR."U_Reactor_num"= ReactorNo AND WOR1."U_Enddate" = StartDate AND WOR1."U_Endtime" > StartTime AND WOR1."U_Starttime" < StartTime ;

			error :=440;
			error_message := N'Please check the Start date for production order' || ReactorNo || StartDate ||  StartTime ||  Entry || ' Check This ' || Temp ;

		END IF;

END IF;
-----------------
-- FORM Name   : Production Order
-- Note        : For Special Production order, [Special Entry Reason] is mandatory. IF 'Others' is selected in [Special Entry Reason] then remarks must not be empty.

IF object_type='202' AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE TypePO Nvarchar(10);
DECLARE SPReason Nvarchar(50);
DECLARE SPRemark Nvarchar(254);

	SELECT  T0."Type" INTO TYPEPO FROM OWOR T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT  T0."U_sp_ent_reason" INTO SPReason FROM OWOR T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT  T0."PickRmrk" INTO SPRemark FROM OWOR T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del;

	     IF TYPEPO = 'P' AND SPReason IS NULL THEN
			error :=441;
			error_message := N'Please select [Special Entry Type] for this production order.';
		END IF;
	  	IF TYPEPO = 'P' AND SPReason = 'Others' AND SPRemark IS NULL THEN
	  	 	error :=442;
			error_message := N'Please add special entry type in [Special Production Remark] field for this production order.';
	 	END IF;
END IF;
------------------------------------

IF object_type='1250000001' AND (:transaction_type = 'A') THEN

DECLARE MinLine INT;
DECLARE MaxLine INT;
DECLARE Quantity Int;
DECLARE Qty_in_Whs Int;

	SELECT Min(T0."VisOrder") INTO MinLine FROM IGE1 T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLine FROM IGE1 T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinLine<=MaxLine DO

	SELECT T2."OnHand" INTO Qty_in_Whs FROM OWTQ T0 INNER JOIN  WTQ1 T1 ON T0."DocEntry" = T1."DocEntry" INNER JOIN OITW T2 ON T1."ItemCode" = T2."ItemCode" AND
	T1."FromWhsCod" = T2."WhsCode" WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T1."VisOrder" = MinLine;

	SELECT T1."Quantity" INTO Quantity FROM WTQ1 T1 INNER JOIN OWTQ T0 ON T0."DocEntry" = T1."DocEntry"
	WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T1."VisOrder" = MinLine;

	     IF Quantity > Qty_in_Whs  THEN
			error :=443;
			error_message := N'Entered Quantity is not available in selected warehouse' || Quantity;
		END IF;

	MinLine = MinLine +1;
	END WHILE;

END IF;

---------------------------------------------

IF Object_type = '202' and (:transaction_type ='A' OR :transaction_type = 'U')
Then
Declare OWOR_U_Q_DIFG nvarchar(50);
Declare OWOR_U_Q_DIFG2 nvarchar(50);
Declare OWOR_U_Q_DIFG3 nvarchar(50);
Declare OWOR_U_Q_PCFG nvarchar(50);
Declare OWOR_U_Q_PCFG2 nvarchar(50);
Declare OWOR_U_Q_PCFG3 nvarchar(50);
Declare OWOR_ItemCode Nvarchar(50);
Declare OWOR_Code Nvarchar(50);

select  DISTINCT(T2."Location") INTO OWOR_Code
 From OWOR T0
LEFT JOIN WOR1 T1 ON T1."DocEntry"=T0."DocEntry"
LEFT JOIN OLCT T2 ON T2."Code"=T1."LocCode"
WHERE  T0."DocEntry"= :list_of_cols_val_tab_del ;

Select "ItemCode" into OWOR_ItemCode from  OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;

SELECT Count(T0."DocEntry")   INTO OWOR_U_Q_DIFG FROM OWOR T0  WHERE T0."DocEntry" =list_of_cols_val_tab_del and ifnull(T0."U_Q_DIFG",'')='';

SELECT Count(T0."DocEntry")   INTO OWOR_U_Q_DIFG2 FROM OWOR T0  WHERE T0."DocEntry" =list_of_cols_val_tab_del and ifnull(T0."U_Q_DIFG2",'')='';

SELECT Count(T0."DocEntry")   INTO OWOR_U_Q_DIFG3 FROM OWOR T0  WHERE T0."DocEntry" =list_of_cols_val_tab_del and ifnull(T0."U_Q_DIFG3",'')='';

SELECT Count(T0."DocEntry")   INTO OWOR_U_Q_PCFG FROM OWOR T0  WHERE T0."DocEntry" =list_of_cols_val_tab_del and ifnull(T0."U_Q_PCFG",'')='';

SELECT Count(T0."DocEntry")   INTO OWOR_U_Q_PCFG2 FROM OWOR T0  WHERE T0."DocEntry" =list_of_cols_val_tab_del and ifnull(T0."U_Q_PCFG2",'')='';

SELECT Count(T0."DocEntry")   INTO OWOR_U_Q_PCFG3 FROM OWOR T0  WHERE T0."DocEntry" =list_of_cols_val_tab_del and ifnull(T0."U_Q_PCFG3",'')='';

		if (OWOR_ItemCode like 'SC%' AND OWOR_Code = 'UNIT - I')
		then
		IF OWOR_U_Q_DIFG >0
		THEN
		error := 27271;
		error_message := 'Q_DIFG Should be mandatory ';
	END IF;
	END IF;

		if (OWOR_ItemCode like 'SC%' AND OWOR_Code = 'UNIT - II')
		then
		IF OWOR_U_Q_DIFG2 >0
		THEN
		error := 27272;
		error_message := 'Q_DIFG2 Should be mandatory ';
	END IF;
	END IF;

		if (OWOR_ItemCode like 'SC%' AND OWOR_Code = 'UNIT - III')
		then
		IF OWOR_U_Q_DIFG3 >0
		THEN
		error := 27273;
		error_message := 'Q_DIFG3 Should be mandatory ';
	END IF;
	END IF;

		if (OWOR_ItemCode like 'PC%' AND OWOR_Code = 'UNIT - I')
		then
		IF OWOR_U_Q_PCFG >0
		THEN
		error := 27274;
		error_message := 'Q_PCFG Should be mandatory ';
	END IF;
	END IF;

		if (OWOR_ItemCode like 'PC%' AND OWOR_Code = 'UNIT - II')
		then
		IF OWOR_U_Q_PCFG2 >0
		THEN
		error := 27275;
		error_message := 'Q_PCFG2 Should be mandatory ';
	END IF;
	END IF;

		if (OWOR_ItemCode like 'PC%' AND OWOR_Code = 'UNIT - III')
		then
		IF OWOR_U_Q_PCFG3 >0
		THEN
		error := 27276;
		error_message := 'Q_PCFG3 Should be mandatory ';
	END IF;
	END IF;

END IF;
---------------------------------------

/*IF Object_type = '202' and (:transaction_type ='A' OR :transaction_type = 'U')
Then
Declare OWOR_U_Q_DIFG nvarchar(50);
DECLARE OWOR_U_Q_Batch Nvarchar(50);
Declare OWOR_ItemCode Nvarchar(50);
Declare OWOR_WhsCode Nvarchar(50);

SELECT COUNT(T0."DocEntry") INTO OWOR_U_Q_Batch FROM OWOR T0  WHERE T0."DocEntry" =list_of_cols_val_tab_del and Ifnull(T0."U_Q_Batch",'')= '';


		if OWOR_U_Q_Batch >0
		THEN

		error := 272727;
		error_message := 'Batch index  Should be Manadatory ';
	END IF;
End IF;*/

------------Sales order Port of loading and dischasrge must be match with A/R invoice--------------

IF Object_type = '13' and (:transaction_type = 'A' OR :transaction_type = 'U') Then

DECLARE PLoad nvarchar(50);
DECLARE PDischrg nvarchar(50);
DECLARE PLoadSO nvarchar(50);
DECLARE PDischrgSO nvarchar(50);
DECLARE ADSeries nvarchar(50);
DECLARE PrtCnt Int;
DECLARE PrtCnt1 Int;


	(SELECT T1."SeriesName" into ADSeries FROM OINV T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"=:list_of_cols_val_tab_del );

		IF (ADSeries LIKE 'EX%') THEN

			(SELECT T0."U_PLoad" into PLoad FROM OINV T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del);
			(SELECT T0."U_PDischrg" into PDischrg FROM OINV T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del);

			SELECT DISTINCT t5."U_PLoad" INTO PLoadSO from RDR1 t4 left join ORDR t5 on t5."DocEntry"=t4."DocEntry"
			left join DLN1 t8 on t4."DocEntry"=t8."BaseEntry" and t4."LineNum"=t8."BaseLine" and t4."ObjType"=t8."BaseType" left join ODLN t9 on t9."DocEntry"=t8."DocEntry"
			left join INV1 t88 on t8."DocEntry"=t88."BaseEntry" and t8."LineNum"=t88."BaseLine" and t8."ObjType"=t88."BaseType"
			left join OINV t89 on t89."DocEntry"=t88."DocEntry" WHERE t89."DocEntry"=:list_of_cols_val_tab_del;

			SELECT DISTINCT t5."U_PDischrg" INTO PDischrgSO from RDR1 t4 left join ORDR t5 on t5."DocEntry"=t4."DocEntry"
			left join DLN1 t8 on t4."DocEntry"=t8."BaseEntry" and t4."LineNum"=t8."BaseLine" and t4."ObjType"=t8."BaseType" left join ODLN t9 on t9."DocEntry"=t8."DocEntry"
			left join INV1 t88 on t8."DocEntry"=t88."BaseEntry" and t8."LineNum"=t88."BaseLine" and t8."ObjType"=t88."BaseType"
			left join OINV t89 on t89."DocEntry"=t88."DocEntry" WHERE t89."DocEntry"=:list_of_cols_val_tab_del;

			       --IF PLoad <> PLoadSO THEN
					 	--error:=447;
						--error_message:=N'Sales order and A/R Invoice - Port of Loading is not matching';
			       --END IF;

			       IF PDischrg <> PDischrgSO THEN
					 	error:=448;
						error_message:=N'Sales order and A/R Invoice - Port of Discharge is not matching';
			       END IF;
		END IF;
END IF;

----------------------------------------

IF object_type = '46' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE BoENo Nvarchar(20);
DECLARE ImportInv Nvarchar(20);
DECLARE ImportInvDate Date;
DECLARE BoEDate Date;
DECLARE AccCode INT;
DECLARE MinLinePDQ INT;
DECLARE MaxLinePDQ INT;

	SELECT Min(VPM4."LineId") INTO MinLinePDQ from VPM4 INNER JOIN OVPM ON VPM4."DocNum" = OVPM."DocEntry" WHERE OVPM."DocEntry" = :list_of_cols_val_tab_del;
	SELECT Max(VPM4."LineId") INTO MaxLinePDQ from VPM4 INNER JOIN OVPM ON VPM4."DocNum" = OVPM."DocEntry" WHERE OVPM."DocEntry" = :list_of_cols_val_tab_del;

	WHILE :MinLinePDQ<=MaxLinePDQ DO

		SELECT VPM4."AcctCode" INTO AccCode FROM VPM4 INNER JOIN OVPM ON VPM4."DocNum" = OVPM."DocEntry" WHERE OVPM."DocEntry" = :list_of_cols_val_tab_del AND VPM4."LineId" = MinLinePDQ ;

		IF AccCode = '10801010' THEN --IGST Receivable Account- Import

			SELECT OVPM."U_Bill_of_Entry" into BoENo FROM OVPM WHERE OVPM."DocEntry" = :list_of_cols_val_tab_del;
			SELECT OVPM."U_Import_Inv_No" into ImportInv FROM OVPM WHERE OVPM."DocEntry" = :list_of_cols_val_tab_del;
			SELECT OVPM."U_Import_Inv_Date" into ImportInvDate FROM OVPM WHERE OVPM."DocEntry" = :list_of_cols_val_tab_del;
			SELECT OVPM."U_BoE_Date" into BoEDate FROM OVPM WHERE OVPM."DocEntry" = :list_of_cols_val_tab_del;

				IF BoENo = '' OR BoENo IS NULL then
					error :=449;
					error_message := N'Please Enter Bill of Entry Number';
				END IF;

				IF ImportInv = '' OR ImportInv IS NULL then
					error :=450;
					error_message := N'Please Enter Import Invoice Number';
				END IF;

				IF ImportInvDate = '' OR ImportInvDate IS NULL then
					error :=451;
					error_message := N'Please Enter Import Invoice Date';
				END IF;

				IF BoEDate = '' OR BoEDate IS NULL then
					error :=452;
					error_message := N'Please Enter Bill of Entry Date';
				END IF;
		END IF;
	MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;

IF object_type = '202' AND (:transaction_type = 'U' OR :transaction_type = 'A') THEN

DECLARE Typ Nvarchar(50);
DECLARE Status Nvarchar(50);
DECLARE CompletedQty decimal;
DECLARE IssuedQty decimal;
DECLARE MainItemPRO Nvarchar(150);
DECLARE SeriesPRO Nvarchar(150);

 	select OWOR."Type" into Typ from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select OWOR."Status" into Status from OWOR where OWOR."DocEntry"=list_of_cols_val_tab_del;
 	select NNM1."SeriesName" into SeriesPRO from OWOR INNER JOIN NNM1 ON OWOR."Series" = NNM1."Series" where OWOR."DocEntry"=list_of_cols_val_tab_del;

	IF Typ = 'P' and Status = 'R' and (SeriesPRO NOT LIKE 'SC%' AND SeriesPRO NOT LIKE 'BA%') THEN

	SELECT T1."CmpltQty" into CompletedQty FROM OWOR T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;

		SELECT SUM(T1."IssuedQty") into IssuedQty FROM WOR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;

			IF IssuedQty < CompletedQty THEN
				error := 453;
				error_message := 'Please check Issue and Receipt Quantity for the this special production order';
			END IF;
		END IF;
END IF;

If Object_Type = '112' and (:transaction_type='A' ) then
Declare PrdSeries  Nvarchar(50);
Declare PrdUser  Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
select "SeriesName" into PrdSeries From ODRF INNER JOIN NNM1 ON NNM1."Series" = ODRF."Series" where ODRF."DocEntry"= :list_of_cols_val_tab_del and ODRF."ObjType"=59;
select OUSR."USER_CODE" into PrdUser from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign" where ODRF."DocEntry"= :list_of_cols_val_tab_del and ODRF."ObjType"=59;

		if PrdUser NOT LIKE '%prod01%' and PrdSeries LIKE 'SC%' then
        	error :=22;
        	error_message := N'You are not allowed to select SC Series1';
		end if;
END IF;
end if;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE PMGI Nvarchar(50);
DECLARE PMQTY decimal;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	SELECT Min(T0."VisOrder") INTO MinGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGI <= :MaxGI DO
		SELECT DRF1."ItemCode" into PMGI FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
		SELECT SUBSTR_AFTER(DRF1."Quantity",'.') into PMQTY FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
		IF PMGI LIKE '%PM%' then
			IF 	PMQTY > 0 then
				error :=23;
				error_message := N'Decimal not allowed for Packing';
			END IF;
		END IF;
		MinGI := MinGI+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' ) THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE JWDate Nvarchar(50);
DECLARE JWDate2 Nvarchar(50);
DECLARE Code Nvarchar(50);
DECLARE JWDate3 Nvarchar(50);
DECLARE JWChallan1 Int;
DECLARE JWChallan2 Int;
DECLARE JWChallan3 Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	SELECT Min(T0."VisOrder") INTO MinGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

		WHILE :MinGI<= :MaxGI DO
			SELECT DRF1."ItemCode" into Code FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI and DRF1."ObjType"=60;

			SELECT Count(DRF1."U_JobChallan1") into JWChallan1 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI and DRF1."ObjType"=60;
			SELECT ifnull(DRF1."U_JWDate",'') into JWDate FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI and DRF1."ObjType"=60;

			SELECT Count(DRF1."U_JobChallan2") into JWChallan2 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI and DRF1."ObjType"=60;
			SELECT ifnull(DRF1."U_JWDate2",'') into JWDate2 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI and DRF1."ObjType"=60;

			SELECT Count(DRF1."U_JobChallan3") into JWChallan3 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI and DRF1."ObjType"=60;
			SELECT ifnull(DRF1."U_JWDate3",'') into JWDate3 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI and DRF1."ObjType"=60;

			IF Code <> 'PCRM0017' then
				IF JWChallan1 > 0  then
					IF JWDate = '' OR JWDate IS NULL THEN
						error :=25;
						error_message := N'Please enter our job work challan date1.'||MinGI;
					END IF;
				END IF;
				IF JWChallan2 > 0 then
					IF JWDate2 = '' OR JWDate2 IS NULL THEN
						error :=25;
						error_message := N'Please enter our job work challan date2.'||MinGI;
					END IF;
				END IF;
				IF JWChallan3 > 0 then
					IF JWDate3 = '' OR JWDate3 IS NULL THEN
						error :=25;
						error_message := N'Please enter our job work challan date3.'||MinGI;
					END IF;
				END IF;
			END IF;
			MinGI := MinGI+1;
		END WHILE;
END IF;
END IF;
---------------------------------------------
IF object_type='112' AND (:transaction_type = 'A' ) THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE JWQty1 decimal(18,2);
DECLARE JWQty2 decimal(18,2);
DECLARE JWQty3 decimal(18,2);
DECLARE JWChallan1 Int;
DECLARE JWChallan2 Int;
DECLARE JWChallan3 Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	SELECT Min(T0."VisOrder") INTO MinGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."ObjType"=60;
	SELECT Max(T0."VisOrder") INTO MaxGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."ObjType"=60;

		WHILE :MinGI<= :MaxGI DO
			SELECT Count(DRF1."U_JobChallan1") into JWChallan1 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI and DRF1."ObjType"=60;
			SELECT ifnull(DRF1."U_JWQty1",0) into JWQty1 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI and DRF1."ObjType"=60;

			SELECT Count(DRF1."U_JobChallan2") into JWChallan2 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI and DRF1."ObjType"=60;
			SELECT ifnull(DRF1."U_JWQty2",0) into JWQty2 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI and DRF1."ObjType"=60;

			SELECT Count(DRF1."U_JobChallan3") into JWChallan3 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI and DRF1."ObjType"=60;
			SELECT ifnull(DRF1."U_JWQty3",0) into JWQty3 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI and DRF1."ObjType"=60;

			IF JWChallan1 > 0  then
				IF JWQty1 = 0 THEN
					error :=26;
					error_message := N'Please enter our job work challan qty1.'||MinGI;
				END IF;
			END IF;
			IF JWChallan2 > 0  then
				IF JWQty2 = 0 then
					error :=26;
					error_message := N'Please enter our job work challan qty2.'||MinGI;
				END IF;
			END IF;
			IF JWChallan3 > 0  then
				IF JWQty3 = 0 THEN
					error :=26;
					error_message := N'Please enter our job work challan qty3.'||MinGI;
				END IF;
			END IF;
			MinGI := MinGI+1;
		END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE WhsGI Nvarchar(50);
DECLARE ItemGI Nvarchar(50);
DECLARE SeriesGI Nvarchar(50);
DECLARE VNoGI Nvarchar(50);
DECLARE CNoGI Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	SELECT Min(T0."VisOrder") INTO MinGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinGI<= :MaxGI DO
		SELECT DRF1."WhsCode" into WhsGI FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
		SELECT DRF1."ItemCode" into ItemGI FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
		SELECT T0."SeriesName" into SeriesGI FROM NNM1 T0 INNER JOIN ODRF T1 ON T0."Series" = T1."Series" WHERE T1."DocEntry" = :list_of_cols_val_tab_del AND T1."ObjType"=60;
		SELECT ODRF."U_UNE_CHNO" into VNoGI FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=60;
		SELECT ODRF."U_UNE_VehicleNo" into CNoGI FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=60;

		IF ItemGI LIKE '%FG%' and ItemGI <> 'PCFG0247' and SeriesGI NOT LIKE 'BT%' THEN
			IF WhsGI NOT LIKE '%FG%' and WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%DE%' and WhsGI NOT LIKE '%TRD%' THEN
				error :=27;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
		END IF;
		IF ItemGI LIKE '%RM%' and SeriesGI NOT LIKE 'BT%' and ItemGI <> 'SCRM0016' THEN
			IF WhsGI NOT LIKE '%RAW%' and WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%AP%' and WhsGI NOT LIKE '%DE%' THEN
				error :=27;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
		END IF;
		IF ItemGI LIKE '%PM%' and SeriesGI NOT LIKE 'BT%' and ItemGI <> 'SCPM0018' THEN
			IF WhsGI NOT LIKE '%PAC%' and WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%AP%'  and WhsGI NOT LIKE '%DE%' and WhsGI NOT LIKE '%RSC%' THEN
				error :=27;
				error_message := N'Please Enter Proper Warehouse..PM';
			END IF;
		END IF;
		IF SeriesGI LIKE  '%JW%' and  ItemGI <> 'PCRM0017' THEN
			IF WhsGI NOT LIKE '%SSPL%' and WhsGI NOT LIKE '%PSC%' and WhsGI NOT LIKE '%ADVP%' and WhsGI NOT LIKE '%GJCM%' and WhsGI NOT LIKE '%AP%' and WhsGI NOT LIKE '%DE%' and WhsGI NOT LIKE '%RSC%' THEN
				error :=27;
				error_message := N'Please Enter Proper Warehouse..JW';
			END IF;
		END IF;
		MinGI := MinGI+1;
	END WHILE;
END IF;
END IF;

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare ItemCode nvarchar(50);
DECLARE MinGI Nvarchar(50);
DECLARE MaxGI Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	SELECT Min(T0."VisOrder") INTO MinGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MinGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE MinGI<=MaxGI DO
		(Select DRF1."ItemCode" into ItemCode from DRF1 WHERE DRF1."DocEntry"=list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI);
          IF (ItemCode LIKE 'E%' ) then
                  error :=28;
                  error_message := N'Not allowed..';
         End If;
    	MinGI := MinGI+1;
	END WHILE;
END IF;
End If;

/*IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE Series Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	SELECT Min(T0."VisOrder") INTO MinGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

		WHILE MinGR<= MaxGR DO

			SELECT T0."SeriesName" into Series FROM ODRF T1 INNER JOIN NNM1 T0 ON T0."Series" = T1."Series"
				 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=59;
			SELECT TOP 1 T1."WhsCode" into WhsGR FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
			IF Series LIKE 'JW%' THEN
				IF (WhsGR NOT LIKE '%JW%' or WhsGR NOT LIKE 'JW-QC' or WhsGR NOT LIKE 'OF-PORT') THEN
					error :=34;
					error_message := N'Please Select JW-QC Warehouse for JW Series.';
				END IF;
			END IF;
			MinGR := MinGR+1;
		END WHILE;
END IF;
END IF;*/

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE ItemGR Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	SELECT Min(T0."VisOrder") INTO MinGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGR <= :MaxGR DO
		SELECT DRF1."WhsCode" into WhsGR FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGR;
		IF WhsGR LIKE '%SCSP%' THEN
			error :=36;
			error_message := N'You are not allowed to select SCSP warehouse ';
		END IF;
		MinGR := MinGR+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE JCGR Nvarchar(50);
DECLARE JCGRDT Nvarchar(50);
DECLARE UsrCod Nvarchar(50);
DECLARE ItmGR Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	SELECT Min(T0."VisOrder") INTO MinGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Count(ODRF."U_UNE_CHNO") into JCGR FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=59;
	SELECT Count(ODRF."U_UNE_CHDT") into JCGRDT FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=59;
	select OUSR."USER_CODE" into UsrCod from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign"
			where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=59;

	IF UsrCod LIKE '%prod05%' THEN
		WHILE :MinGR <= :MaxGR DO
			SELECT DRF1."WhsCode" into WhsGR FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGR;
			SELECT DRF1."ItemCode" into ItmGR FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGR;
			IF ItmGR <> 'PCFG0247' then
				IF WhsGR LIKE '%JW%' THEN
					IF JCGR = 0 THEN
						error :=38;
						error_message := N'Please enter subsidary challan no.';
					END IF;
					IF JCGRDT = 0 THEN
						error :=38;
						error_message := N'Please enter subsidary challan date.';
					END IF;
				END IF;
			END IF;
			MinGR := MinGR+1;
		END WHILE;
	END IF;
END IF;
END IF;

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare OcrCode nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
(Select  count(DRF1."OcrCode") into OcrCode
	from DRF1 inner join ODRF on ODRF."DocEntry"=DRF1."DocEntry" where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=59 and ifnull(DRF1."OcrCode",'')<>'' );
          IF (OcrCode = 0) then
                  error :=39;
                  error_message := N'Please Select Distr. Rule in Document';
         End If;
End If;
END IF;


IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then

DECLARE MinGR Int;
DECLARE MaxGR Int;
Declare ChallanNo nvarchar(50);
Declare ChallanDate nvarchar(50);
Declare SCDate nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
		SELECT Min(T0."VisOrder") INTO MinGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		WHILE :MinGR <= :MaxGR DO
			select "U_JobChallan1" into ChallanNo from DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinGR;

			IF (ChallanNo IS NOT NULL) then
				IF ChallanNo LIKE '40%' then
					Select OPDN."DocDate" into ChallanDate from OPDN WHERE OPDN."DocNum" = ChallanNo;
				else
					Select OWTR."DocDate" into ChallanDate from OWTR WHERE OWTR."DocNum" = ChallanNo;
				END IF;
				select "U_UNE_CHDT" into SCDate from ODRF WHERE ODRF."DocEntry" = list_of_cols_val_tab_del and ODRF."ObjType"=59;
		         IF (SCDate < ChallanDate) then
		               error :=40;
		               error_message := N'SC Challan Date not greater than job work challan date';
		         End If;
		    END IF;
	    MinGR := MinGR+1;
		END WHILE;
END IF;
End If;


IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE WhsGI Nvarchar(50);
DECLARE ItemGI Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	SELECT Min(T0."VisOrder") INTO MinGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGI<= :MaxGI DO
		SELECT DRF1."WhsCode" into WhsGI FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
		SELECT DRF1."ItemCode" into ItemGI FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;

		IF (ItemGI LIKE '%RM%' or ItemGI LIKE '%PM%') THEN
			IF (WhsGI NOT LIKE '%RAW%' AND WhsGI NOT LIKE '%PAC%' AND WhsGI NOT LIKE '%SSPL%' AND WhsGI NOT LIKE '%PDI%' AND WhsGI NOT LIKE '%ADVP%' AND WhsGI NOT LIKE '%GJCM%' AND WhsGI NOT LIKE '%AP%' AND WhsGI LIKE '%DE%') THEN
				error :=41;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
		END IF;
		MinGI := MinGI+1;
	END WHILE;
END IF;
END IF;


IF Object_type = '112' and (:transaction_type ='A') Then
Declare OcrCode nvarchar(50);
Declare ItmCode nvarchar(50);
DECLARE MinGI Int;
DECLARE MaxGI Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	SELECT Min(T0."VisOrder") INTO MinGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGI<= :MaxGI DO
		(Select  ifnull(DRF1."OcrCode",'') into OcrCode from DRF1 where DRF1."DocEntry"=list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI);
		(Select  DRF1."ItemCode" into ItmCode from DRF1 where DRF1."DocEntry"=list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI);
          IF (OcrCode = '' OR OcrCode IS NULL) then
                  error :=42;
                  error_message := N'Please Select Distr. Rule in Document'||ItmCode;
         End If;
    MinGI := MinGI+1;
	END WHILE;
END IF;
End If;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE QtyGI decimal;
DECLARE JbQtyGI1 decimal;
DECLARE JbQtyGI2 decimal;
DECLARE JbQtyGI3 decimal;
DECLARE JbQtyGI4 decimal;
DECLARE JbQtyGI5 decimal;
DECLARE JbQtyGI6 decimal;
DECLARE JbQtyGI7 decimal;
DECLARE UsrCod Nvarchar(50);
DECLARE WhsGI Nvarchar(50);
DECLARE CdGI Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	SELECT Min(T0."VisOrder") INTO MinGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	select OUSR."USER_CODE" into UsrCod from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign" where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=60;

	IF UsrCod LIKE '%prod05%' THEN	--'%prod05%'
		WHILE :MinGI<= :MaxGI DO
			SELECT "Quantity" into QtyGI FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
			SELECT "ItemCode" into CdGI FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
			SELECT OWHS."U_UNE_JAPP" into WhsGI FROM DRF1 INNER JOIN OWHS ON DRF1."WhsCode" = OWHS."WhsCode" WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
			SELECT ifnull("U_JWQty1",0) into JbQtyGI1 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
			SELECT ifnull("U_JWQty2",0) into JbQtyGI2 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
			SELECT ifnull("U_JWQty3",0) into JbQtyGI3 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
			SELECT ifnull("U_JWQty4",0) into JbQtyGI4 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
			SELECT ifnull("U_JWQty5",0) into JbQtyGI5 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
			SELECT ifnull("U_JWQty6",0) into JbQtyGI6 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
			SELECT ifnull("U_JWQty7",0) into JbQtyGI7 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;

			IF WhsGI = 'Y' and CdGI <> 'PCRM0017' and CdGI <> 'PCFG0345' and CdGI <> 'PCFG0344' and CdGI <> 'PCFG0347' and CdGI <> 'PCFG0346' THEN

				IF JbQtyGI4 =0 THEN
					IF JbQtyGI3 <>0 THEN
						IF JbQtyGI2<>0 THEN
							IF JbQtyGI1 <>0 THEN
								IF QtyGI <> (JbQtyGI1 + JbQtyGI2 + JbQtyGI3) THEN
									error :=44;
									error_message := N'Job work challan quantity is not match with issue quantity.3. Line No '||MinGI;
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
				IF JbQtyGI3 =0 THEN
					IF JbQtyGI2 <>0 THEN
						IF JbQtyGI1<>0 THEN
							IF QtyGI <> (JbQtyGI1 + JbQtyGI2) THEN
								error :=44;
								error_message := N'Job work challan quantity is not match with issue quantity.2. Line No '||MinGI;
							END IF;
						END IF;
					END IF;
				END IF;
				IF JbQtyGI3 =0 THEN
					IF JbQtyGI2= 0 THEN
						IF JbQtyGI1 <>0 THEN
							IF QtyGI <> JbQtyGI1 THEN
								error :=44;
								error_message := N'Job work challan quantity is not match with issue quantity.1. Line No '||MinGI;
							END IF;
						END IF;
					END IF;
				END IF;
				IF JbQtyGI5=0 THEN
					IF JbQtyGI4<>0 THEN
						IF JbQtyGI3 <>0 THEN
							IF JbQtyGI2<>0 THEN
								IF JbQtyGI1<>0 THEN
									IF QtyGI <> (JbQtyGI1 + JbQtyGI2 + JbQtyGI3 + JbQtyGI4) THEN
										error :=44;
										error_message := N'Job work challan quantity is not match with issue quantity.4.'||(JbQtyGI1 + JbQtyGI2 + JbQtyGI3 + JbQtyGI4);
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
			MinGI := MinGI+1;
		END WHILE;
	END IF;
END IF;
END IF;


IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE entry int;
Declare MinIT Int;
Declare MaxIT Int;
Declare Count1 int;
Declare IC varchar(50);
Declare Itm varchar(50);
entry:=0;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
		SELECT Min(T0."VisOrder") INTO MinIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		WHILE MinIT <= MaxIT DO

			select "VisOrder" into IC from DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT;

			select Count("DocEntry") into Count1  from (SELECT "DocEntry" FROM DRF1 T1
			INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
			WHERE T2."Warehouse" = T1."WhsCode" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
			AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
			Group By T1."DocEntry"
			HAVING Sum(T2."InQty"-T2."OutQty") < 0)a;

			SELECT "ItemCode" into IC FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT;


			if(Count1>0) then
				(SELECT Count(T1."DocEntry") into entry FROM DRF1 T1 INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
						WHERE T2."Warehouse" = T1."WhsCode" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
						AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
						Group By T1."DocEntry"
					HAVING Sum(T2."InQty"-T2."OutQty") < 0);
			END IF;
			IF (entry > 0) THEN
				error :=45;
				error_message := N'Negative stock...'||MinIT|| IC ;
			END IF;
			MinIT := MinIT+1;
		END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE WhsGI Nvarchar(50);
DECLARE JCNOGI Nvarchar(50);
DECLARE JCQTYGI decimal(18,2);
DECLARE UsrCod Nvarchar(50);
DECLARE ItemCd Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	SELECT Min(T0."VisOrder") INTO MinGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into UsrCod from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign" where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=60;

	IF UsrCod LIKE '%prod05%' THEN --prod05
		WHILE :MinGI<= :MaxGI DO
			SELECT ifnull(OWHS."U_UNE_JAPP",'') into WhsGI FROM DRF1 INNER JOIN OWHS ON DRF1."WhsCode" = OWHS."WhsCode" WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
			SELECT ifnull(DRF1."U_JobChallan1",0) into JCNOGI FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
			SELECT DRF1."ItemCode" into ItemCd FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
			SELECT ifnull(DRF1."U_JWQty1",0) into JCQTYGI FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
			IF WhsGI = 'Y' and ItemCd <> 'PCRM0017' and ItemCd <> 'PCFG0345' and ItemCd <> 'PCFG0344' and ItemCd <> 'PCFG0346' and ItemCd <> 'PCFG0347' and ItemCd <> 'PCFG0361'  THEN
				IF JCNOGI =0 THEN
					error :=45;
					error_message := N'Please enter our job work challan no at row level.'||MinGI;
				END IF;
				IF JCQTYGI =0 THEN
					error :=45;
					error_message := N'Please enter our job work challan quantity at row level.'||MinGI;
				END IF;
			END IF;
			MinGI := MinGI+1;
		END WHILE;
	END IF;
END IF;

END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGI Int;
DECLARE MaxGI Int;
DECLARE WhsGI Nvarchar(50);
DECLARE JCNOGI1 Nvarchar(50);
DECLARE JCQTYGI1 Nvarchar(50);
DECLARE JCNOGI2 Nvarchar(50);
DECLARE JCQTYGI2 Nvarchar(50);
DECLARE JCNOGI3 Nvarchar(50);
DECLARE JCQTYGI3 Nvarchar(50);
DECLARE JCNOGI4 Nvarchar(50);
DECLARE JCQTYGI4 Nvarchar(50);
DECLARE JCITEMGI1 Nvarchar(50);
DECLARE JCITEMGI2 Nvarchar(50);
DECLARE JCITEMGI3 Nvarchar(50);
DECLARE JCITEMGI4 Nvarchar(50);
DECLARE ITITEMGI1 Nvarchar(50);
DECLARE ITITEMGI2 Nvarchar(50);
DECLARE ITITEMGI3 Nvarchar(50);
DECLARE ITITEMGI4 Nvarchar(50);
DECLARE JobChallan1 Nvarchar(50);
DECLARE JobChallan2 Nvarchar(50);
DECLARE JobChallan3 Nvarchar(50);
DECLARE JobChallan4 Nvarchar(50);
DECLARE JobChallan6 Nvarchar(50);
DECLARE Datejb Nvarchar(50);
DECLARE UsrCod Nvarchar(50);
DECLARE JWDate1 date;
DECLARE JWDate2 date;
DECLARE JWDate3 date;
DECLARE JWDate4 date;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	SELECT Min(T0."VisOrder") INTO MinGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into UsrCod from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign" where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=60;
	select ODRF."DocDate" into Datejb from ODRF where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=60;

		IF UsrCod LIKE '%prod05%' THEN --prod05
			WHILE :MinGI<= :MaxGI DO

				SELECT OWHS."U_UNE_JAPP" into WhsGI FROM DRF1 INNER JOIN OWHS ON DRF1."WhsCode" = OWHS."WhsCode" WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;

				IF WhsGI = 'Y' THEN
					SELECT DRF1."ItemCode" into JCITEMGI1 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
					SELECT Replace(DRF1."U_JobChallan1",',','') into JobChallan1 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
					SELECT DRF1."U_JWDate" into JWDate1 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;

						IF JWDate1 >= '20230401' then
							IF JobChallan1 LIKE '10%'  then
								SELECT WTR1."ItemCode" into ITITEMGI1 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan1 and OWTR."DocDate" >= '20230401';
								IF ITITEMGI1 <> JCITEMGI1 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan1 LIKE '20%' then
								SELECT PDN1."ItemCode" into ITITEMGI1 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan1 and OPDN."DocDate" >= '20220401' and PDN1."VisOrder" = 0;
								IF ITITEMGI1 <> JCITEMGI1 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						ELSEIF JWDate1 >= '20210401' then
							IF JobChallan1 LIKE '40%' then
								SELECT WTR1."ItemCode" into ITITEMGI1 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan1 and OWTR."DocDate" >= '20210401';
								IF ITITEMGI1 <> JCITEMGI1 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan1 LIKE '30%' then
								SELECT PDN1."ItemCode" into ITITEMGI1 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan1 and OPDN."DocDate" >= '20210401' and PDN1."VisOrder" = 0 and PDN1."ItemCode" LIKE 'PC%';
								IF ITITEMGI1 <> JCITEMGI1 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						else
							IF length(JobChallan1) = 3 then
								SELECT concat('30',DRF1."U_JobChallan1") into JobChallan6 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
								SELECT WTR1."ItemCode" into ITITEMGI1 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan6 and OWTR."DocDate" < '20210401';
								IF ITITEMGI1 <> JCITEMGI1 THEN
									error :=189;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan1 LIKE '40%' then
								SELECT PDN1."ItemCode" into ITITEMGI1 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan1 and OPDN."DocDate" < '20210401' and PDN1."VisOrder" = 0;
								IF ITITEMGI1 <> JCITEMGI1 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan1 LIKE '30%' then
								SELECT WTR1."ItemCode" into ITITEMGI1 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan1 and OWTR."DocDate" < '20210401';
								IF ITITEMGI1 <> JCITEMGI1 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							End IF;
						End IF;


					SELECT DRF1."ItemCode" into JCITEMGI2 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
					SELECT DRF1."U_JobChallan2" into JobChallan2 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
					SELECT DRF1."U_JWDate2" into JWDate2 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;


						IF JWDate2 >= '20230401' then
							IF JobChallan2 LIKE '10%' then
								SELECT WTR1."ItemCode" into ITITEMGI2 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan2 and OWTR."DocDate" >= '20230401';
								IF ITITEMGI2 <> JCITEMGI2 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan2 LIKE '20%' then
								SELECT PDN1."ItemCode" into ITITEMGI2 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan2 and OPDN."DocDate" >= '20220401' and PDN1."VisOrder" = 0;
								IF ITITEMGI2 <> JCITEMGI2 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						ELSEIF JWDate2 >= '20210401' then
							IF JobChallan2 LIKE '40%' then
								SELECT WTR1."ItemCode" into ITITEMGI2 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan2 and OWTR."DocDate" >= '20210401';
								IF ITITEMGI2 <> JCITEMGI2 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan2 LIKE '30%' then
								SELECT PDN1."ItemCode" into ITITEMGI2 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan2 and OPDN."DocDate" >= '20210401' and PDN1."VisOrder" = 0;
								IF ITITEMGI2 <> JCITEMGI2 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						else
							IF length(JobChallan2) = 3 then
								SELECT concat('30',DRF1."U_JobChallan2") into JobChallan6 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
								SELECT WTR1."ItemCode" into ITITEMGI2 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan6 and OWTR."DocDate" < '20210401';
								IF ITITEMGI2 <> JCITEMGI2 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan2 LIKE '40%' then
								SELECT PDN1."ItemCode" into ITITEMGI2 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan2 and OPDN."DocDate" < '20210401';
								IF ITITEMGI2 <> JCITEMGI2 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan2 LIKE '30%' then
								SELECT WTR1."ItemCode" into ITITEMGI2 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan2 and OWTR."DocDate" < '20210401';
								IF ITITEMGI2 <> JCITEMGI2 THEN
									error :=46;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							End IF;
						End IF;


					SELECT DRF1."ItemCode" into JCITEMGI3 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
					SELECT DRF1."U_JobChallan3" into JobChallan3 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
					SELECT DRF1."U_JWDate3" into JWDate3 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;


						IF JWDate3 >= '20220401' then
							IF JobChallan3 LIKE '10%' then
								SELECT WTR1."ItemCode" into ITITEMGI3 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan3 and OWTR."DocDate" >= '20220401';
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan3 LIKE '20%' then
								SELECT PDN1."ItemCode" into ITITEMGI3 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan3 and OPDN."DocDate" >= '20220401' and PDN1."VisOrder" = 0;
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						ELSEIF JWDate3 >= '20210401' then
							IF JobChallan3 LIKE '40%' then
								SELECT WTR1."ItemCode" into ITITEMGI3 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan3 and OWTR."DocDate" >= '20210401';
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan3 LIKE '30%' then
								SELECT PDN1."ItemCode" into ITITEMGI3 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan3 and OPDN."DocDate" >= '20210401' and PDN1."VisOrder" = 0;
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						else
							IF length(JobChallan3) = 3 then
								SELECT concat('30',DRF1."U_JobChallan3") into JobChallan6 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
								SELECT WTR1."ItemCode" into ITITEMGI3 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan6 and OWTR."DocDate" < '20210401';
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan3 LIKE '40%' then
								SELECT PDN1."ItemCode" into ITITEMGI3 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan3 and OPDN."DocDate" < '20210401';
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan3 LIKE '30%' then
								SELECT WTR1."ItemCode" into ITITEMGI3 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan3 and OWTR."DocDate" < '20210401';
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							End IF;
						End IF;

					SELECT DRF1."ItemCode" into JCITEMGI4 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
					SELECT DRF1."U_JobChallan4" into JobChallan4 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
					SELECT DRF1."U_JWDate4" into JWDate4 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;


						IF JWDate4 >= '20220401' then
							IF JobChallan4 LIKE '10%' then
								SELECT WTR1."ItemCode" into ITITEMGI4 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan4 and OWTR."DocDate" >= '20220401';
								IF ITITEMGI4 <> JCITEMGI4 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan4 LIKE '20%' then
								SELECT PDN1."ItemCode" into ITITEMGI4 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan4 and OPDN."DocDate" >= '20220401' and PDN1."VisOrder" =0 ;
								IF ITITEMGI4 <> JCITEMGI4 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						ELSEIF JWDate4 >= '20210401' then
							IF JobChallan4 LIKE '40%' then
								SELECT WTR1."ItemCode" into ITITEMGI4 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan4 and OWTR."DocDate" >= '20210401';
								IF ITITEMGI4 <> JCITEMGI4 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan4 LIKE '30%' then
								SELECT PDN1."ItemCode" into ITITEMGI4 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan4 and OPDN."DocDate" >= '20210401';
								IF ITITEMGI4 <> JCITEMGI4 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							end IF;
						else
							IF length(JobChallan4) = 3 then
								SELECT concat('30',DRF1."U_JobChallan4") into JobChallan6 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
								SELECT WTR1."ItemCode" into ITITEMGI4 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan6 and OWTR."DocDate" < '20210401';
								IF ITITEMGI3 <> JCITEMGI3 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan4 LIKE '40%' then
								SELECT PDN1."ItemCode" into ITITEMGI4 FROM PDN1 INNER JOIN OPDN ON OPDN."DocEntry" = PDN1."DocEntry" WHERE OPDN."DocNum" = JobChallan4 and OPDN."DocDate" < '20210401';
								IF ITITEMGI4 <> JCITEMGI4 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							elseif JobChallan4 LIKE '30%' then
								SELECT WTR1."ItemCode" into ITITEMGI4 FROM WTR1 INNER JOIN OWTR ON OWTR."DocEntry" = WTR1."DocEntry" WHERE OWTR."DocNum" = JobChallan4 and OWTR."DocDate" < '20210401';
								IF ITITEMGI4 <> JCITEMGI4 THEN
									error :=47;
									error_message := N'Challan No Item not matched. Line '||MinGI;
								END IF;
							End IF;
						End IF;


					SELECT Count(DRF1."U_JobChallan1") into JCNOGI1 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
					SELECT DRF1."U_JWQty1" into JCQTYGI1 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;

					SELECT Count(DRF1."U_JobChallan2") into JCNOGI2 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
					SELECT DRF1."U_JWQty2" into JCQTYGI2 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;

					SELECT Count(DRF1."U_JobChallan3") into JCNOGI3 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
					SELECT DRF1."U_JWQty3" into JCQTYGI3 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;

					SELECT Count(DRF1."U_JobChallan4") into JCNOGI4 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;
					SELECT DRF1."U_JWQty4" into JCQTYGI4 FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGI;

					IF JCNOGI1 > 0 THEN
						IF JCQTYGI1 = '' OR JCQTYGI1 IS NULL THEN
							error :=47;
							error_message := N'Please enter our job work challan Quantity if job work challan no is there. Line '||MinGI;
						END IF;
					END IF;
					IF JCNOGI2 > 0 THEN
						IF JCQTYGI2 = '' OR JCQTYGI2 IS NULL THEN
							error :=47;
							error_message := N'Please enter our job work challan Quantity if job work challan no is there. Line '||MinGI;
						END IF;
					END IF;
					IF JCNOGI3 > 0 THEN
						IF JCQTYGI3 = '' OR JCQTYGI3 IS NULL THEN
							error :=47;
							error_message := N'Please enter our job work challan Quantity if job work challan no is there. Line '||MinGI;
						END IF;
					END IF;
					IF JCNOGI4 > 0 THEN
						IF JCQTYGI4 = '' OR JCQTYGI4 IS NULL THEN
							error :=47;
							error_message := N'Please enter our job work challan Quantity if job work challan no is there. Line '||MinGI;
						END IF;
					END IF;
				END IF;
				MinGI := MinGI+1;
			END WHILE;
		END IF;
END IF;
END IF;

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare BaseType nvarchar(50);
Declare BaseYN nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
(Select OCRD."U_Base_Doc" into BaseYN
	from ODRF inner join OCRD on ODRF."CardCode"=OCRD."CardCode" where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=20);
(Select max(DRF1."BaseType") into BaseType
	from DRF1 inner join ODRF on ODRF."DocEntry"=DRF1."DocEntry" where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=20);
		IF(BaseYN='Y') Then
          IF (BaseType = '-1') then
                  error :=48;
                  error_message := N'Please Select Base Document';
         End If;
	End If;
END If;
End If;


IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE DRGRN Nvarchar(50);
DECLARE BRGRN Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."BPLId" into BRGRN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20;
	WHILE :MinGRN <= :MaxGRN DO
		SELECT DRF1."OcrCode" into DRGRN FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGRN;
		IF BRGRN = 3 THEN
			IF DRGRN LIKE '2%' THEN
				error :=49;
				error_message := N'Select proper Distribution rule';
			END IF;
		END IF;

		MinGRN := MinGRN+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE DRGRN Nvarchar(50);
DECLARE BRGRN Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."BPLId" into BRGRN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20;
	WHILE :MinGRN <= :MaxGRN DO
		SELECT DRF1."OcrCode" into DRGRN FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGRN;
		IF BRGRN = 4 THEN
			IF DRGRN NOT LIKE '2%' THEN
				error :=49;
				error_message := N'Select proper Distribution rule';
			END IF;
		END IF;
		MinGRN := MinGRN+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE GRPOIC Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE GRPOWC Nvarchar(50);
DECLARE Series Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	Select T1."SeriesName" into Series from ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry"=list_of_cols_val_tab_del and T0."ObjType"=20;

	WHILE :MinLinePDQ<=MaxLinePDQ DO
		SELECT DRF1."ItemCode" INTO GRPOIC FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT DRF1."WhsCode" INTO GRPOWC FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;

		IF GRPOWC LIKE '%QC%' then
			IF GRPOIC LIKE 'E%' and Series NOT LIKE 'CL%' THEN
			error :=50;
			error_message := N'Please Enter proper warehouse....';
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE GRPOIC Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE GRPOWC Nvarchar(50);
DECLARE Series Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	Select T1."SeriesName" into Series from ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry"=list_of_cols_val_tab_del and T0."ObjType"=20;

	WHILE :MinLinePDQ<=MaxLinePDQ DO
		SELECT DRF1."ItemCode" INTO GRPOIC FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT DRF1."WhsCode" INTO GRPOWC FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;

		IF GRPOWC <> 'GJCM' then
			IF GRPOIC LIKE 'PCFG%' AND GRPOWC NOT IN ('PC-QC-TR','2PC-QCTR') and Series NOT LIKE 'CL%' THEN
			error :=51;
			error_message := N'Please Enter proper warehouse....';
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;
END IF;


IF object_type='112' AND (:transaction_type = 'A') THEN

DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE GRNCode Nvarchar(50);
DECLARE GRNSeries Nvarchar(50);
DECLARE GRNType Nvarchar(50);
DECLARE ITWhsCode Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT NNM1."SeriesName" into GRNSeries FROM ODRF INNER JOIN NNM1 ON NNM1."Series" = ODRF."Series" WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20;

	IF MinGRN = MaxGRN and MinGRN = 0 THEN
		SELECT DRF1."ItemCode" into GRNCode FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=0;
		SELECT DRF1."U_PTYPE" into GRNType FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=0;

		IF GRNSeries NOT LIKE 'CL%' and GRNSeries NOT LIKE 'JC%' THEN
			IF GRNCode LIKE '%PCRM%' and GRNType LIKE '%Drum%'  then
				error :=51;
				error_message := N'Please add packing code & its detail';
			END IF;
			IF GRNCode LIKE '%PCRM%' and GRNType LIKE '%Tank' then
				error :=51;
				error_message := N'Please add packing code & its detail';
			END IF;
		END IF;
	END IF;
END IF;
END IF;


IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare OcrCode nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
(Select  count(DRF1."OcrCode") into OcrCode
	from DRF1 inner join ODRF on ODRF."DocEntry"=DRF1."DocEntry" where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=20 and DRF1."OcrCode" is not null );
          IF (OcrCode = 0) then
                  error :=52;
                  error_message := N'Please Select Distr. Rule in Document';
         End If;
End If;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE ItemCDPQD Nvarchar(50);
Declare PackType Nvarchar(50);
Declare COUNT1 Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinLinePDQ<=MaxLinePDQ DO
		SELECT DRF1."U_PTYPE" into PackType FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ;
		SELECT Distinct (DRF1."ItemCode") INTO ItemCDPQD FROM DRF1 where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;

		select Count(*) INTO COUNT1 from "@TANKERLOAD" WHERE "Code" IN(ItemCDPQD);
		IF COUNT1 > 0 THEN
			IF PackType IS NULL THEN
				error :=53;
				error_message := N'Please Enter Packing Type for : '||ItemCDPQD;
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;
END IF;


IF object_type='112' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE GRPOQTD Int;
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE POQTB Int;
DECLARE ItemCDPQD Nvarchar(50);
DECLARE DOCTPDQ Nvarchar (50);
Declare COUNT1 Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinLinePDQ<=MaxLinePDQ DO
		SELECT Distinct (DRF1."Quantity") INTO GRPOQTD FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (DRF1."BaseOpnQty") INTO POQTB FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (DRF1."ItemCode") INTO ItemCDPQD FROM DRF1 where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (ODRF."DocType") INTO DOCTPDQ FROM ODRF Inner JOIN DRF1 ON ODRF."DocEntry"=DRF1."DocEntry" Where ODRF."DocEntry" =:list_of_cols_val_tab_del and ODRF."ObjType"=20 ;
		select Count(*) INTO COUNT1 from "@TANKERLOAD" WHERE "Code" IN(ItemCDPQD);

		IF COUNT1 = 0 THEN
			IF ItemCDPQD NOT LIKE 'E%' THEN
			IF  :DOCTPDQ = 'I' And (:GRPOQTD > POQTB) THEN
				error :=54;
				error_message := N'GRPO Qty. should not greater then P.O Qty...!'||ItemCDPQD;
			END IF;
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;
END IF;


IF object_type='112' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE GRPOQTD Int;
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE POQTB Int;
DECLARE ItemCDPQD Nvarchar(50);
DECLARE DOCTPDQ Nvarchar (50);
Declare PackType Nvarchar(50);
Declare COUNT1 Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinLinePDQ<=MaxLinePDQ DO
		SELECT Distinct (DRF1."Quantity") INTO GRPOQTD FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (DRF1."BaseOpnQty") INTO POQTB FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (DRF1."ItemCode") INTO ItemCDPQD FROM DRF1 where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (ODRF."DocType") INTO DOCTPDQ FROM ODRF Inner JOIN DRF1 ON ODRF."DocEntry"=DRF1."DocEntry" Where ODRF."DocEntry" =:list_of_cols_val_tab_del and ODRF."ObjType"=20;
		SELECT DRF1."U_PTYPE" INTO PackType FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ;
		select Count(*) INTO COUNT1 from "@TANKERLOAD" WHERE "Code" IN(ItemCDPQD);
		IF PackType LIKE '%Tanker%' THEN
			IF COUNT1 > 0 THEN
				IF  :DOCTPDQ = 'I' And (:GRPOQTD > (POQTB + ((POQTB*3)/100))) THEN
					error :=55;
					error_message := N'GRPO Qty. should not greater then P.O Qty.3%.'||ItemCDPQD;
				END IF;
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;
END IF;


IF object_type='112' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE GRPOQTD Int;
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE POQTB Int;
DECLARE ItemCDPQD Nvarchar(50);
DECLARE DOCTPDQ Nvarchar (50);
Declare PackType Nvarchar(50);
Declare COUNT1 Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinLinePDQ<=MaxLinePDQ DO
		SELECT Distinct (DRF1."Quantity") INTO GRPOQTD FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (DRF1."BaseOpnQty") INTO POQTB FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (DRF1."ItemCode") INTO ItemCDPQD FROM DRF1 where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (ODRF."DocType") INTO DOCTPDQ FROM ODRF Inner JOIN DRF1 ON ODRF."DocEntry"=DRF1."DocEntry" Where ODRF."DocEntry" =:list_of_cols_val_tab_del and ODRF."ObjType"=20 ;
		SELECT DRF1."U_PTYPE" INTO PackType FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ;
		select Count(*) INTO COUNT1 from "@TANKERLOAD" WHERE "Code" IN(ItemCDPQD);

		IF PackType NOT LIKE '%Tanker%' THEN
			IF COUNT1 > 0 THEN
				IF  :DOCTPDQ = 'I' And (:GRPOQTD > POQTB) THEN
					error :=56;
					error_message := N'GRPO Qty. should not greater then P.O Qty..!!'||ItemCDPQD;
				END IF;
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;
END IF;

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
DECLARE MinAP Int;
DECLARE MaxAP Int;
Declare OcrCode nvarchar(50);
Declare ItmCode nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
	SELECT Min(T0."VisOrder") INTO MinAP from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinAP <= :MaxAP DO
		(Select DRF1."OcrCode" into OcrCode from DRF1 where DRF1."DocEntry"=list_of_cols_val_tab_del and DRF1."VisOrder"=MinAP);
		(Select DRF1."ItemCode" into ItmCode from DRF1 where DRF1."DocEntry"=list_of_cols_val_tab_del and DRF1."VisOrder"=MinAP);
	          IF (OcrCode = '' OR OcrCode IS NULL) then
	          	error :=59;
	          	error_message := N'Please Select Distr. Rule in Document'||ItmCode;
	         End If;
         MinAP := MinAP+1;
		END WHILE;
END IF;
End If;


IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinAP Int;
DECLARE MaxAP Int;
DECLARE TCAP Nvarchar(50);
DECLARE CurrAP Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
	SELECT Min(T0."VisOrder") INTO MinAP from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."DocCur" into CurrAP FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=18 ;


IF CurrAP <> 'INR' THEN
		WHILE :MinAP <= :MaxAP DO
			SELECT DRF1."TaxCode" into TCAP FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinAP;
			IF TCAP = 'RIGST18' THEN
				error :=60;
				error_message := N'Select proper "RIGST18T" Taxcode for import party';
			END IF;
			MinAP := MinAP+1;
		END WHILE;
	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinAP Int;
DECLARE MaxAP Int;
DECLARE TCAP Nvarchar(50);
DECLARE ICode Nvarchar(50);
DECLARE CurrAP Nvarchar(50);
DECLARE CCode Nvarchar(50);
DECLARE SCNO Nvarchar(50);
DECLARE SCDATE Nvarchar(50);
DECLARE Countt Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
	SELECT Min(T0."VisOrder") INTO MinAP from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinAP <= :MaxAP DO
		SELECT ODRF."CardCode" into CCode FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=18;
		SELECT DRF1."ItemCode" into ICode FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinAP;

		SELECT DRF1."U_Schln1" into SCNO FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinAP;
		SELECT DRF1."U_Schld1" into SCDATE FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinAP;
	Select Count(T0."ItemCode") into Countt from DRF1 T0 INNER JOIN ODRF T1 ON T0."DocEntry" = T1."DocEntry" WHERE T0."U_BASEDOCNO" = SCNO
		and T0."ItemCode" = 'SER0038' and T1."CardCode" = CCode and T1."ObjType"=18;
		IF ICode = 'SER0038' and SCDATE IS NULL THEN
			error :=61;
			error_message := N'Please enter Subsidary challan date';
		END IF;
		IF ICode = 'SER0038' and SCNO IS NULL THEN
			error :=61;
			error_message := N'Please enter Subsidary challan no';
		END IF;
		IF Countt > 1 THEN
			error :=61;
			error_message := N'Duplicate subsidary challan no';
		END IF;
		MinAP := MinAP+1;
	END WHILE;
END IF;
END IF;

--------------------A/P Credit Memo----------------
IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare OcrCode nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 19
THEN
(Select  count(DRF1."OcrCode") into OcrCode
	from DRF1 inner join ODRF on ODRF."DocEntry"=DRF1."DocEntry" where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=19 and DRF1."OcrCode" is not null );
          IF (OcrCode = 0) then
                  error :=62;
                  error_message := N'Please Select Distr. Rule in Document';
         End If;
END IF;
End If;


IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE entry int;
Declare MinIT Int;
Declare MaxIT Int;
Declare Count1 int;
entry:=0;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 15
THEN

		SELECT Min(T0."VisOrder") INTO MinIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		WHILE MinIT <= MaxIT DO
			select Count("DocEntry") into Count1  from ( SELECT "DocEntry" FROM DRF1 T1
			INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
			WHERE T2."Warehouse" = T1."WhsCode" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
			AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
			Group By T1."DocEntry"
			HAVING Sum(T2."InQty"-T2."OutQty") < 0 )a;

			if(Count1>0) then
				(SELECT Count(T1."DocEntry") into entry FROM DRF1 T1 INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
						WHERE T2."Warehouse" = T1."WhsCode" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
						AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
						Group By T1."DocEntry"
					HAVING Sum(T2."InQty"-T2."OutQty") < 0);
			END IF;
			IF (entry > 0) THEN
				error :=67;
				error_message := N'Negative stock...';
			END IF;
			MinIT := MinIT+1;
		END WHILE;
		END IF;
END IF;


IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare OcrCode nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 14
THEN
(Select  count(DRF1."OcrCode") into OcrCode
	from DRF1 inner join ODRF on ODRF."DocEntry"=DRF1."DocEntry" where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=14 and DRF1."OcrCode" is not null );
          IF (OcrCode = 0) then
                  error :=68;
                  error_message := N'Please Select Distr. Rule in Document';
         End If;
End If;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE DRIN Nvarchar(50);
DECLARE BRIN Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	SELECT Min(T0."VisOrder") INTO MinIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."BPLId" into BRIN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=13;
	WHILE :MinIN <= :MaxIN DO
		SELECT DRF1."OcrCode" into DRIN FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;

		IF BRIN = 3 THEN
			IF DRIN LIKE '2%' THEN
				error :=71;
				error_message := N'Select proper Distribution rule';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE entry int;
Declare MinIT Int;
Declare MaxIT Int;
Declare Count1 int;
entry:=0;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
		SELECT Min(T0."VisOrder") INTO MinIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		WHILE MinIT <= MaxIT DO
			select Count("DocEntry") into Count1  from ( SELECT "DocEntry" FROM DRF1 T1
			INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
			WHERE T2."Warehouse" = T1."WhsCode" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
			AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
			Group By T1."DocEntry"
			HAVING Sum(T2."InQty"-T2."OutQty") < 0 )a;

			if(Count1>0) then
				(SELECT Count(T1."DocEntry") into entry FROM DRF1 T1 INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
						WHERE T2."Warehouse" = T1."WhsCode" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
						AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
						Group By T1."DocEntry"
					HAVING Sum(T2."InQty"-T2."OutQty") < 0);
			END IF;
			IF (entry > 0) THEN
				error :=74;
				error_message := N'Negative stock...' || MinIT;
			END IF;
			MinIT := MinIT+1;
		END WHILE;
END IF;
END IF;

IF Object_type = '112' and (:transaction_type ='A' OR :transaction_type = 'U') Then

DECLARE ItemCodeIN Nvarchar(50);
DECLARE MinIN Int;
DECLARE MaxIN Int;
SELECT Min(T0."VisOrder") INTO MinIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
SELECT Max(T0."VisOrder") INTO MaxIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	WHILE :MinIN <= :MaxIN DO
	select DRF1."ItemCode" into ItemCodeIN from ODRF INNER JOIN DRF1 ON ODRF."DocEntry" = DRF1."DocEntry"
		where ODRF."DocEntry"= :list_of_cols_val_tab_del and ODRF."ObjType"=13 and DRF1."VisOrder"=0;
		IF ItemCodeIN = 'PCFG0247' THEN
		    error :=75;
		    error_message := N'Something went wrong';
		END IF;
		IF ItemCodeIN = 'SCFG0016' THEN
		    error :=75;
		    error_message := N'Something went wrong';
		END IF;
	MinIN := MinIN+1;
	END WHILE;
END IF;
END IF;

IF Object_type='112' and (:transaction_type ='A') Then
DECLARE DLParty nvarchar(50);
DECLARE DLCurrency nvarchar(50);
DECLARE DLSeries nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 15
THEN
	(SELECT T0."CardCode" into DLParty FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType"=15);
	(SELECT T0."DocCur" into DLCurrency FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType"=15);
	(SELECT T1."SeriesName" into DLSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType"=15);
		IF (DLParty LIKE 'CPE%' and DLCurrency = 'INR') THEN
			error:=79;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (DLParty LIKE 'CSE%' and DLCurrency = 'INR') THEN
			error:=79;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (DLSeries NOT LIKE 'CL%' and DLSeries NOT LIKE 'DM%') THEN
			IF (DLParty LIKE 'CSE%' and DLSeries NOT LIKE 'EX%' ) THEN
				error:=79;
				error_message:=N'Please Select Proper Series';
			END IF;
			IF (DLParty LIKE 'CPE%' and DLSeries NOT LIKE 'EX%') THEN
				error:=79;
				error_message:=N'Please Select Proper Series';
			END IF;
		END IF;
END IF;
END IF;


IF Object_type='112' and (:transaction_type ='A') Then

DECLARE ADParty nvarchar(50);
DECLARE ADCurrency nvarchar(50);
DECLARE ADSeries nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 203
THEN
	(SELECT T0."CardCode" into ADParty FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType"=203);
	(SELECT T0."DocCur" into ADCurrency FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType"=203);
	(SELECT T1."SeriesName" into ADSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType"=203);
		IF (ADParty LIKE 'CPE%' and ADCurrency = 'INR') THEN
			error:=80;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (ADParty LIKE 'CSE%' and ADCurrency = 'INR') THEN
			error:=80;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (ADParty LIKE 'CSE%' and ADSeries NOT LIKE 'EX%' ) THEN
			error:=80;
			error_message:=N'Please Select Proper Series';
		END IF;
		IF (ADParty LIKE 'CPE%' and ADSeries NOT LIKE 'EX%' ) THEN
			error:=80;
			error_message:=N'Please Select Proper Series';
		END IF;
END IF;
END IF;

IF Object_type='112' and (:transaction_type ='A') Then
DECLARE GRNParty nvarchar(50);
DECLARE GRNCurrency nvarchar(50);
DECLARE GRNSeries nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	(SELECT T0."CardCode" into GRNParty FROM ODRF T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=20);
	(SELECT T0."DocCur" into GRNCurrency FROM ODRF T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=20);
	(SELECT T1."SeriesName" into GRNSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=20);
	  	IF GRNParty <> 'VPRI0017' then
			IF (GRNParty LIKE 'VPRI%' and GRNCurrency = 'INR' and GRNParty <> 'VPRI0011') THEN
				error:=82;
				error_message:=N'Please Select Proper Currency';
			END IF;
			IF (GRNParty LIKE 'VSRI%' and GRNCurrency = 'INR' and GRNParty <> 'VPRI0011') THEN
				error:=82;
				error_message:=N'Please Select Proper Currency';
			END IF;

			IF (GRNParty LIKE 'VPRI%' and GRNSeries NOT LIKE 'IM%' and GRNSeries NOT LIKE 'JC%' and GRNSeries <> 'CL1/2324' and GRNParty <> 'VPRI0011') THEN
				error:=82;
				error_message:=N'Please Select Proper Series';
			END IF;
			IF (GRNParty LIKE 'VSRI%' and GRNSeries NOT LIKE 'IM%' and GRNSeries NOT LIKE 'JC%' and GRNSeries <> 'CL1/2324' and GRNParty <> 'VPRI0011') THEN
				error:=82;
				error_message:=N'Please Select Proper Series';
			END IF;
		END IF;
END IF;
END IF;

IF Object_type='112' and (:transaction_type ='A') Then
DECLARE APParty nvarchar(50);
DECLARE APCurrency nvarchar(50);
DECLARE APSeries nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
	(SELECT T0."CardCode" into APParty FROM ODRF T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=18);
	(SELECT T0."DocCur" into APCurrency FROM ODRF T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=18);
	(SELECT T1."SeriesName" into APSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=18);

		IF (APParty LIKE 'VPRI%' and APCurrency = 'INR' and APParty <> 'VPRI0011' and APParty <> 'VPRI0017') THEN
			error:=83;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (APParty LIKE 'VSRI%' and APCurrency = 'INR' and APParty <> 'VPRI0011' and APParty <> 'VPRI0017') THEN
			error:=83;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (APParty LIKE 'VPRI%' and APSeries NOT LIKE 'IM%' and APParty <> 'VPRI0011' and APParty <> 'VPRI0017') THEN
			error:=83;
			error_message:=N'Please Select Proper Series';
		END IF;
		IF (APParty LIKE 'VSRI%' and APSeries NOT LIKE 'IM%' and APParty <> 'VPRI0011' and APParty <> 'VPRI0017')  THEN
			error:=83;
			error_message:=N'Please Select Proper Series';
		END IF;
	END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE WhseGRN Nvarchar(50);
DECLARE ItemGRN Nvarchar(50);
DECLARE SrsGRN Nvarchar(50);
DECLARE Branch Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20 THEN
	SELECT T0."BPLId" INTO Branch FROM ODRF T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del and T0."ObjType"=20;

	IF Branch = 3 THEN

		SELECT Min(T0."VisOrder") INTO MinGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT T1."SeriesName" INTO SrsGRN from ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" =:list_of_cols_val_tab_del and T0."ObjType"=20;

		IF SrsGRN NOT LIKE 'J%' and SrsGRN NOT LIKE 'CL%'THEN
			WHILE MinGRN<=MaxGRN DO
				SELECT DRF1."WhsCode" into WhseGRN FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinGRN;
				SELECT DRF1."ItemCode" into ItemGRN FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinGRN;

				IF ItemGRN LIKE '%FG%' and (WhseGRN NOT LIKE '%TR%' and WhseGRN NOT LIKE '%OF%')  THEN
					error :=8511;
					error_message := N'Please Enter Proper Warehouse.FG.';
				END IF;
				IF ItemGRN LIKE 'PCRM0018' and WhseGRN NOT LIKE '%RAW%' THEN
					error :=8512;
					error_message := N'Please Enter Proper Warehouse..';
				END IF;
				MinGRN := MinGRN+1;
			END WHILE;
		END IF;
	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE WhseGRN Nvarchar(50);
DECLARE ItemGRN Nvarchar(50);
DECLARE SrsGRN Nvarchar(50);
DECLARE Branch Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT T0."BPLId" INTO Branch FROM ODRF T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del and T0."ObjType"=20;

	IF Branch = 4 THEN

		SELECT Min(T0."VisOrder") INTO MinGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT T1."SeriesName" INTO SrsGRN from ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" =:list_of_cols_val_tab_del and T0."ObjType"=20;

		IF SrsGRN NOT LIKE 'J%' and SrsGRN NOT LIKE 'CL%'THEN
			WHILE MinGRN<=MaxGRN DO
				SELECT DRF1."WhsCode" into WhseGRN FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinGRN;
				SELECT DRF1."ItemCode" into ItemGRN FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinGRN;

				IF ItemGRN LIKE '%FG%' and WhseGRN NOT LIKE '%TR%' THEN
					error :=8521;
					error_message := N'Please Enter Proper Warehouse.FG.';
				END IF;
				IF ItemGRN LIKE 'PCRM0018' and WhseGRN NOT LIKE '2PC-FLOR' THEN
					error :=8522;
					error_message := N'Please select 2PC-FLOR Warehouse..';
				END IF;
				MinGRN := MinGRN+1;
			END WHILE;
		END IF;
	END IF;
END IF;
END IF;

/*IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE MinAP Int;
DECLARE MaxAP Int;
DECLARE WhseAP Nvarchar(50);
DECLARE ItemAP Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18 THEN
	SELECT Min(T0."VisOrder") INTO MinAP from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinAP<=MaxAP DO
		SELECT DRF1."WhsCode" into WhseAP FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinAP;
		SELECT DRF1."ItemCode" into ItemAP FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinAP;
		IF ItemAP LIKE '%FG%' and WhseAP NOT LIKE '%TR%' and WhseAP NOT LIKE '%GJCM%' and WhseAP <> 'JW-OF' THEN
			error :=86;
			error_message := N'Please Enter Proper Warehouse.FG.';
		END IF;
		MinAP := MinAP+1;
	END WHILE;
END IF;
END IF;*/

IF Object_type='112' and (:transaction_type ='A') Then
DECLARE MinGRN int;
DECLARE MaxGRN int;
DECLARE GRNEntryType nvarchar(50);
DECLARE GRNItemCode int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	(SELECT min(T0."VisOrder") Into MinGRN FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGRN FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	WHILE MinGRN <= MaxGRN
	DO
	(SELECT T1."U_EntryType" into GRNEntryType FROM DRF1 T1 LEFT JOIN ODRF T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType"=20 AND T1."VisOrder"=MinGRN);
	(SELECT Count(T1."ItemCode") into GRNItemCode FROM DRF1 T1 LEFT JOIN ODRF T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType"=20 AND T1."VisOrder"=MinGRN and (T1."ItemCode"  LIKE 'PCRM%' OR T1."ItemCode"  LIKE 'SCRM%' OR T1."ItemCode"  LIKE 'SCFG%' OR T1."ItemCode"  LIKE 'PCFG%'));

		IF (GRNEntryType = 'Blank' and GRNItemCode>0) THEN
			error:=88;
			error_message:=N'Please Select Entry Type : Normal or Trading in "Entry Type" Column at Row level';
			select :error, :error_message FROM dummy;
			Return;
		END IF;
	 MinGRN=MinGRN+1;
	END WHILE;
END IF;
END IF;

IF Object_type='112' and (:transaction_type ='A') Then
DECLARE MinGRN int;
DECLARE MaxGRN int;
DECLARE GRNSeries nvarchar(50);
DECLARE GRNItemCode nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	(SELECT min(T0."VisOrder") Into MinGRN FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGRN FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	WHILE MinGRN <= MaxGRN
	DO
	(SELECT T1."SeriesName" into GRNSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  	WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=20);
	(SELECT T1."ItemCode" into GRNItemCode FROM DRF1 T1 LEFT JOIN ODRF T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType"=20 AND T1."VisOrder"=MinGRN);

		IF (GRNSeries NOT LIKE 'CL%') THEN
			IF (GRNSeries NOT LIKE 'EG%' and GRNItemCode LIKE 'E%') THEN
				error:=89;
				error_message:=N'Please Select Engineering Series';
				select :error, :error_message FROM dummy;
				Return;
			END IF;
		END IF;
	 	MinGRN=MinGRN+1;
	END WHILE;
END IF;
END IF;


IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE ItemGR Nvarchar(50);
DECLARE Series Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	SELECT Min(T0."VisOrder") INTO MinGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	SELECT T2."SeriesName" into Series FROM ODRF T1 INNER JOIN NNM1 T2 ON T1."Series" = T2."Series"
		WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=59;

	IF Series NOT LIKE 'BT%' AND Series NOT LIKE 'BA%' then
		WHILE MinGR<= MaxGR DO
			SELECT T1."WhsCode" into WhsGR FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
			SELECT T1."ItemCode" into ItemGR FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;

			IF ItemGR LIKE  'PCFG%' and WhsGR NOT LIKE '%QC%' and ItemGR <> 'PCFG0247'
				and ItemGR <> 'PCFG0299' and ItemGR <> 'PCFG0292' and ItemGR <> 'PCFG0291' and ItemGR <> 'PCFG0290' and ItemGR <> 'PCFG0289'
				and ItemGR <> 'PCFG0288' and ItemGR <> 'SCFG0016' THEN
				error :=90;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
			MinGR := MinGR+1;
		END WHILE;
	END IF;
END IF;
END IF;


IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE ItemGR Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	SELECT Min(T0."VisOrder") INTO MinGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE MinGR<= MaxGR DO
		SELECT T1."WhsCode" into WhsGR FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
		SELECT T1."ItemCode" into ItemGR FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
		IF WhsGR LIKE '%QC%' and (ItemGR = 'PCFG0299' OR ItemGR = 'PCFG0292' OR ItemGR = 'PCFG0291' OR ItemGR = 'PCFG0290'
			OR ItemGR = 'PCFG0289' OR ItemGR = 'PCFG0288') THEN
			error :=91;
			error_message := N'Please Enter PC-FG Warehouse.';
		END IF;
		MinGR := MinGR+1;
	END WHILE;
END IF;
END IF;


IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE ItemGR Nvarchar(50);
DECLARE Series Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	SELECT Min(T0."VisOrder") INTO MinGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T2."SeriesName" into Series FROM ODRF T1 INNER JOIN NNM1 T2 ON T1."Series" = T2."Series" WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=59;

	IF Series NOT LIKE 'BT%' AND Series NOT LIKE 'BA%' then
		WHILE MinGR<= MaxGR DO
			SELECT T1."WhsCode" into WhsGR FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
			SELECT T1."ItemCode" into ItemGR FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
			IF ItemGR LIKE 'PCRM%' and WhsGR NOT LIKE '%QC%' and ItemGR <> 'PCRM0018' and ItemGR <> 'PCRM0017' THEN
				error :=92;
				error_message := N'Please Enter Proper Warehouse........';
			END IF;
			MinGR := MinGR+1;
		END WHILE;
	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN

DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE ItemGR Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	SELECT Min(T0."VisOrder") INTO MinGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE MinGR<= MaxGR DO
		SELECT T1."WhsCode" into WhsGR FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
		SELECT T1."ItemCode" into ItemGR FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;

		IF ItemGR LIKE 'SCFG%' and WhsGR NOT LIKE '%QC%' and ItemGR <> 'SCFG0016' THEN
			error :=93;
			error_message := N'Please Enter Proper Warehouse....';
		END IF;
		MinGR := MinGR+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN

DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE ItemGR Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	SELECT Min(T0."VisOrder") INTO MinGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE MinGR<= MaxGR DO
		SELECT T1."WhsCode" into WhsGR FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
		SELECT T1."ItemCode" into ItemGR FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;

		IF WhsGR NOT LIKE '%BT%' THEN
			IF ItemGR LIKE 'SCRM%' and WhsGR NOT LIKE '%QC%' THEN
				error :=94;
				error_message := N'Please Enter Proper Warehouse..';
			END IF;
		END IF;
		MinGR := MinGR+1;
	END WHILE;
END IF;
END IF;

IF Object_type='112' and (:transaction_type ='A') Then
DECLARE MinGRN int;
DECLARE MaxGRN int;
DECLARE GRNWhse nvarchar(50);
DECLARE GRNItemCode nvarchar(50);
DECLARE GRNBranch nvarchar(50);
DECLARE Series nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	(SELECT min(T0."VisOrder") Into MinGRN FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGRN FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT T0."BPLId" Into GRNBranch FROM ODRF T0 where T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=20);
	(SELECT T0."Series" Into Series FROM ODRF T0 where T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=20);
	WHILE MinGRN <= MaxGRN
	DO
	(SELECT T1."WhsCode" into GRNWhse FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del AND T1."VisOrder"=MinGRN);
	(SELECT T1."ItemCode" into GRNItemCode FROM DRF1 T1 WHERE T1."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinGRN);

		IF (GRNBranch = 4) and Series NOT LIKE 'CL%' THEN
			IF (GRNWhse NOT LIKE 'E%' and GRNItemCode LIKE 'E%' and GRNWhse <> 'FBU2' and GRNWhse <> 'OBU2' and GRNWhse <> '2PC-GEN') THEN
				error:=100;
				error_message:=N'Please Select Proper Warehouse';
				select :error, :error_message FROM dummy;
				Return;
			END IF;
		END IF;
	 MinGRN=MinGRN+1;
	END WHILE;

END IF;
END IF;

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare ITCardCode nvarchar(50);
Declare ITSeries nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN
		select ODRF."CardCode" into ITCardCode from ODRF where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=67;
		select ODRF."Series" into ITSeries from ODRF where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=67;

		IF  ITSeries <> 775 and ITCardCode = 'VPPD0015' and ITCardCode = 'VPRD0018' and ITCardCode = 'VPRD0041' and ITCardCode = 'VPPD0012' THEN
			error :=102;
			error_message := N'Please select JC1/2021 Series ..';
		END IF;
End If;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE ITCode Nvarchar(50);
DECLARE ITWhsCode Nvarchar(50);
DECLARE Branch Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN
	SELECT Min(T0."VisOrder") INTO MinIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT OBPL."BPLName" INTO Branch FROM ODRF INNER JOIN OBPL ON OBPL."BPLId" = ODRF."BPLId" WHERE ODRF."DocEntry" =:list_of_cols_val_tab_del and ODRF."ObjType"=67;

	IF Branch = 'UNIT - I' THEN

	WHILE :MinIT <= :MaxIT DO
		SELECT DRF1."ItemCode" into ITCode FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT;
		SELECT DRF1."WhsCode" into ITWhsCode FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT;
		IF ITWhsCode NOT LIKE '%QCR%' and ITWhsCode NOT LIKE '%TRD%' and ITWhsCode NOT LIKE '%GJCM%' and ITWhsCode NOT LIKE '%PSC%' and ITWhsCode NOT LIKE '%SSPL%' and ITWhsCode NOT LIKE '%ADVP%' and ITWhsCode NOT LIKE '%DE%' and ITWhsCode NOT LIKE '%RSC%' THEN
			IF ITCode LIKE '%RM%' THEN
				IF (ITWhsCode NOT LIKE '%RAW%' and ITWhsCode NOT LIKE '%BT%') THEN
					error :=103;
					error_message := N'Wrong warehouseqq';
				END IF;
			END IF;
			IF ITCode LIKE '%FG%' THEN
				IF (ITWhsCode NOT LIKE '%FG%' and ITWhsCode NOT LIKE '%BT%') THEN
					error :=103;
					error_message := N'Wrong warehouse';
				END IF;
			END IF;
		END IF;
		MinIT := MinIT+1;
	END WHILE;
	END IF;
END IF;
END IF;


------------UNIT-2 "2PC-Flor"---------------

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE ITCode Nvarchar(50);
DECLARE ITWhsCode Nvarchar(50);
DECLARE FromWhsCode Nvarchar(50);
DECLARE Branch Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN
	SELECT Min(T0."VisOrder") INTO MinIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	SELECT OBPL."BPLName" INTO Branch FROM ODRF INNER JOIN OBPL ON OBPL."BPLId" = ODRF."BPLId" WHERE ODRF."DocEntry" =:list_of_cols_val_tab_del and ODRF."ObjType"=67;

	IF Branch = 'UNIT - II' THEN

	WHILE :MinIT <= :MaxIT DO
		SELECT DRF1."ItemCode" into ITCode FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT;
		SELECT DRF1."WhsCode" into ITWhsCode FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT;
		SELECT DRF1."FromWhsCod" into FromWhsCode FROM DRF1 where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT;
		IF ITWhsCode NOT LIKE '%QCR%' and ITWhsCode NOT LIKE '%TRD%' and ITWhsCode NOT LIKE '%GJCM%' and ITWhsCode NOT LIKE '%PSC%' and ITWhsCode NOT LIKE '%SSPL%' and ITWhsCode NOT LIKE '%ADVP%' and ITWhsCode NOT LIKE '%DE%' and ITWhsCode NOT LIKE '%RSC%' THEN
			IF ITCode LIKE '%RM%' THEN
				-----By pass some items for transfer to 2PC-flor--------
				IF ITCode NOT IN ('PCRM0005','PCRM0033','PCRM0045','PCRM0027','PCRM0050','PCRM0009') THEN
					IF FromWhsCode = '2PC-QC' THEN
						IF (ITWhsCode NOT LIKE '2PC-RAW' and ITWhsCode NOT LIKE '%BT%') THEN
							error :=1031;
							error_message := N'Wrong warehouse';
						END IF;
					END IF;
				END IF;

				IF ITCode IN  ('PCRM0005','PCRM0033','PCRM0045','PCRM0027','PCRM0050','PCRM0009') THEN
					IF FromWhsCode = '2PC-QC' THEN
						IF (ITWhsCode NOT LIKE '2PC-FLOR' and ITWhsCode NOT LIKE '%BT%') THEN
							error :=1032;
							error_message := N'Wrong warehouse';
						END IF;
					END IF;
				END IF;
				IF FromWhsCode = '2PC-RAW' THEN
					IF (ITWhsCode NOT LIKE '2PC-FLOR' and ITWhsCode NOT LIKE '%BT%') THEN
						error :=1032;
						error_message := N'Wrong warehouse';
					END IF;
				END IF;
				IF FromWhsCode = '2PC-FLOR' THEN
					IF (ITWhsCode NOT LIKE '2PC-RAW') THEN
						error :=1033;
						error_message := N'Wrong warehouse';
					END IF;
				END IF;
			END IF;

			IF ITCode LIKE '%FG%' THEN
				IF FromWhsCode = '2PC-QC' THEN
					IF (ITWhsCode NOT LIKE '2PC-FLOR' and ITWhsCode NOT LIKE '%BT%') THEN
						error :=1034;
						error_message := N'Wrong warehouse';
					END IF;
				END IF;
				IF FromWhsCode = '2PC-FG' THEN
					IF (ITWhsCode NOT LIKE '2PC-FLOR' and ITWhsCode NOT LIKE '%BT%') THEN
						error :=1035;
						error_message := N'Wrong warehouse';
					END IF;
				END IF;
				IF FromWhsCode = '2PC-FLOR' THEN
					IF (ITWhsCode NOT LIKE '2PC-FG' and ITWhsCode NOT LIKE '%BT%') THEN
						error :=1036;
						error_message := N'Wrong warehouse';
					END IF;
				END IF;
			END IF;
		END IF;
		MinIT := MinIT+1;
	END WHILE;
	END IF;
END IF;
END IF;


-----------Inventory transfer 'FT2' Series

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE SeriesName Varchar (50);
DECLARE Fromwhs Varchar(50);
DECLARE Whscode Varchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN
	SELECT Min(T0."VisOrder") INTO MinIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT NNM1."SeriesName" INTO SeriesName FROM ODRF INNER JOIN NNM1 ON NNM1."Series" = ODRF."Series" where ODRF."DocEntry" =:list_of_cols_val_tab_del and ODRF."ObjType"=67;
	WHILE :MinIT <= :MaxIT DO
		SELECT DRF1."FromWhsCod" into Fromwhs FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT;

		IF Fromwhs <> '2PC-QC' THEN
		SELECT DRF1."WhsCode" into Whscode FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT;

			IF (Fromwhs = '2PC-FLOR' OR Whscode = '2PC-FLOR') THEN
				IF SeriesName NOT LIKE 'FT2%' THEN
					error :=1037;
					error_message := N'Please select FT2 Series';
				END IF;
			END IF;
		END IF;
		MinIT := MinIT+1;
	END WHILE;
END IF;
END IF;

--------------------------------------------------------
--------------------------------------------------------
----------------inventory transfer Base document (Floor warehouse)
IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE BaseType Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN
	SELECT Min(T0."VisOrder") INTO MinIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinIT <= :MaxIT DO
		SELECT MAX(DRF1."BaseType") into BaseType FROM ODRF INNER JOIN DRF1 ON ODRF."DocEntry" = DRF1."DocEntry" INNER JOIN NNM1 ON NNM1."Series" = ODRF."Series"
		WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT and ODRF."ObjType"=67 AND NNM1."SeriesName" LIKE 'FT2%';
			IF (BaseType = '-1') THEN
				error :=1038;
				error_message := N'Please select base Document';
			END IF;
		MinIT := MinIT+1;
	END WHILE;
END IF;
END IF;

-----------------Inventory transfer request 2PC-Flor------------------

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE SeriesName Varchar (50);
DECLARE Fromwhs nVarchar(50);
DECLARE Whscode nVarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 1250000001
THEN
	SELECT Min(T0."VisOrder") INTO MinIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIT from WTR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT NNM1."SeriesName" INTO SeriesName FROM ODRF INNER JOIN NNM1 ON NNM1."Series" = ODRF."Series" where ODRF."DocEntry" =:list_of_cols_val_tab_del and ODRF."ObjType"=1250000001;
	WHILE :MinIT <= :MaxIT DO
		SELECT DRF1."FromWhsCod" into Fromwhs FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT and DRF1."ObjType"=1250000001;

		IF Fromwhs <> '2PC-QC' THEN
		SELECT DRF1."WhsCode" into Whscode FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT;

			IF (Fromwhs = '2PC-FLOR' OR Whscode = '2PC-FLOR') THEN
				IF SeriesName NOT LIKE 'FT2%' THEN
					error :=10370;
					error_message := N'Please select FT2 Series';
				END IF;
			END IF;
		END IF;
		MinIT := MinIT+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' ) THEN
DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE ITCapacity Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN
	SELECT Min(T0."VisOrder") INTO MinIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinIT <= :MaxIT DO
		SELECT DRF1."Factor1" into ITCapacity FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT;
			IF ITCapacity <> 950 and ITCapacity <> 180 and ITCapacity <> 230 and ITCapacity <> 20 and ITCapacity <> 1 and ITCapacity <> 25
			and ITCapacity <> 50 and ITCapacity <> 200 and ITCapacity <> 170 and ITCapacity <> 190 and ITCapacity <> 220 and ITCapacity <> 850 and ITCapacity <> 900
			and ITCapacity <> 1000 and ITCapacity <> 160 and ITCapacity <> 165 and ITCapacity <> 800 and ITCapacity <> 197 and ITCapacity <> 30 and ITCapacity <> 35 and ITCapacity <> 250
			and ITCapacity <> 215 and ITCapacity <> 185 and ITCapacity <> 225 and ITCapacity <> 228 and ITCapacity <> 210 and ITCapacity <> 15 and ITCapacity <> 232 and ITCapacity <> 235
			and ITCapacity <> 300 and ITCapacity <> 270 and ITCapacity <> 245 and ITCapacity <> 231 THEN
				error :=104;
				error_message := N'Capacity may wrong';
			END IF;
		MinIT := MinIT+1;
	END WHILE;
END IF;
END IF;

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then

Declare fROMWHS nvarchar(50);
Declare tOwHS nvarchar(50);
Declare Challan1 nvarchar(50);
Declare MinIT Int;
Declare MaxIT Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN
		SELECT Min(T0."VisOrder") INTO MinIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		WHILE :MinIT <= :MaxIT DO
			select DRF1."FromWhsCod" into fROMWHS from DRF1 where DRF1."DocEntry"=list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT;
			select OWHS."U_UNE_JAPP" into tOwHS from DRF1 INNER JOIN OWHS ON OWHS."WhsCode" = DRF1."WhsCode" where DRF1."DocEntry"=list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT;
			select DRF1."U_JobChallan1" into Challan1 from DRF1 where DRF1."DocEntry"=list_of_cols_val_tab_del and DRF1."VisOrder"=MinIT;

			IF  fROMWHS LIKE '%TR%' THEN
				IF tOwHS = 'Y' THEN
					IF Challan1 = '' then
						error :=106;
						error_message := N'Something went wrong ..';
					End If;
				END IF;
			END IF;
		MinIT := MinIT+1;
		END WHILE;
END IF;
End If;

IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE entry int;
Declare MinIT Int;
Declare MaxIT Int;
Declare Count1 int;
entry:=0;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN
		SELECT Min(T0."VisOrder") INTO MinIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		WHILE MinIT <= MaxIT DO
			select Count("DocEntry") into Count1  from ( SELECT "DocEntry" FROM DRF1 T1
			INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
			WHERE T2."Warehouse" = T1."FromWhsCod" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
			AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
			Group By T1."DocEntry"
			HAVING Sum(T2."InQty"-T2."OutQty") < 0 )a;

			if(Count1>0) then
				(SELECT Count(T1."DocEntry") into entry FROM DRF1 T1 INNER JOIN OINM T2 ON T1."ItemCode" = T2."ItemCode"
						WHERE T2."Warehouse" = T1."FromWhsCod" and T1."VisOrder"=MinIT and T1."DocEntry" IS NOT NULL
						AND T2."DocDate" <= T1."DocDate" AND T1."DocEntry" = :list_of_cols_val_tab_del
						Group By T1."DocEntry"
					HAVING Sum(T2."InQty"-T2."OutQty") < 0);
			END IF;
			IF (entry > 0) THEN
				error :=107;
				error_message := N'Negative stock...';
			END IF;
			MinIT := MinIT+1;
		END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE WhsGR Nvarchar(50);
DECLARE WhsGI Nvarchar(50);
DECLARE BaseGR Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN
	SELECT Min(T0."VisOrder") INTO MinGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

		WHILE MinGR<= MaxGR DO
			SELECT TOP 1 T1."BaseRef" into BaseGR FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
			SELECT TOP 1  T1."WhsCode" into WhsGI FROM IGE1 T1 WHERE T1."BaseRef" = BaseGR;
			SELECT TOP 1 T1."WhsCode" into WhsGR FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;
			IF WhsGI LIKE 'GJCM%' OR WhsGI LIKE 'ADVP%' OR WhsGI LIKE 'PDI%' OR WhsGI LIKE 'AP%' OR WhsGI LIKE 'SSPL%' OR WhsGI LIKE 'SVC%' OR WhsGI LIKE 'DE%' THEN
				IF WhsGR NOT LIKE '%JW%' THEN
					error :=108;
					error_message := N'Please Enter Proper Warehouse.!';
				END IF;
			END IF;
			MinGR := MinGR+1;
		END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIT Int;
DECLARE MaxIT Int;
DECLARE PTYPE Nvarchar(50);
DECLARE UsrCod Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN
	SELECT Min(T0."VisOrder") INTO MinIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIT from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

		WHILE MinIT<= MaxIT DO

			SELECT T1."U_PTYPE" into PTYPE FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinIT;
			select OUSR."USER_CODE" into UsrCod from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign"
			where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=67;

			IF UsrCod = 'dispatch01' THEN
				IF PTYPE IS NULL OR PTYPE = ''  THEN
					error :=109;
					error_message := N'Please Enter Packing Type.';
				END IF;
			END IF;
			MinIT := MinIT+1;
		END WHILE;
END IF;
END IF;

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
DECLARE LRNo Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 15
THEN
		SELECT T0."U_UNE_LRNo" into LRNo FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=15;
		IF LRNo IS NULL THEN
			error :=123;
			error_message := N'Please Enter LR No.';
		END IF;
End If;
END IF;

IF object_type='112' AND (:transaction_type = 'A' or :transaction_type='U') THEN
DECLARE MinDL Int;
DECLARE MaxDL Int;
DECLARE FOBDL Nvarchar(50);
DECLARE CardCodeDL Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 15
THEN
	SELECT Min(T0."VisOrder") INTO MinDL from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxDL from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."CardCode" into CardCodeDL FROM ODRF T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=15;
	WHILE :MinDL <= :MaxDL DO
		SELECT T1."U_fob_value" into FOBDL FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;

		IF FOBDL IS NULL and CardCodeDL LIKE 'C_E%'  THEN
			error :=124;
			error_message := N'Please Enter FOB.';
		END IF;
		MinDL := MinDL + 1;
	END WHILE;
END IF;
END IF;

--------------------------------A/R Invoice------------------
IF Object_type = '112' and (:transaction_type ='A' ) Then
Declare BaseType nvarchar(50);
Declare GSTTranTyp nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
(Select max(DRF1."BaseType") into BaseType
	from DRF1 inner join ODRF on ODRF."DocEntry"=DRF1."DocEntry" where ODRF."DocEntry"= :list_of_cols_val_tab_del and ODRF."ObjType"=13);
(Select ODRF."GSTTranTyp" into GSTTranTyp from ODRF where ODRF."DocEntry"= :list_of_cols_val_tab_del and ODRF."ObjType"=13);
          IF (BaseType = '-1' and GSTTranTyp != 'GD') then
                  error :=127;
                  error_message := N'Please Select Base Document';
         End If;
End If;
END IF;
------------------
IF Object_type = '112' and (:transaction_type ='A' ) Then
Declare OcrCode nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
(Select  count(DRF1."OcrCode") into OcrCode
	from DRF1 inner join ODRF on ODRF."DocEntry"=DRF1."DocEntry" where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=13 and DRF1."OcrCode" is not null );
          IF (OcrCode = 0) then
                  error :=128;
                  error_message := N'Please Select Distr. Rule in Document';
         End If;
End If;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN

DECLARE MinAR Int;
DECLARE MaxAR Int;
DECLARE WhseAR Nvarchar(50);
DECLARE SeriesAR Nvarchar(50);
DECLARE ItmAR Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	SELECT Min(T0."VisOrder") INTO MinAR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinAR<=MaxAR DO
		SELECT DRF1."WhsCode" into WhseAR FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinAR;
		SELECT DRF1."ItemCode" into ItmAR FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinAR;
		(SELECT T1."SeriesName" into SeriesAR FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13);

		IF SeriesAR NOT LIKE 'CL%' THEN
			IF ItmAR LIKE '%BY%' then
				IF WhseAR NOT LIKE '%BYP%' and WhseAR NOT LIKE '%TRD%' THEN
					error :=129;
					error_message := N'Please Enter Proper Warehouse';
				END IF;
			END IF;
			IF ItmAR LIKE '%FG%' then
				IF WhseAR NOT LIKE '%FG%' and WhseAR NOT LIKE '%TRD%' and WhseAR NOT LIKE '%GJCM%' and WhseAR NOT LIKE '%ADVP%' and WhseAR NOT LIKE '%GJCM%' and WhseAR NOT LIKE '%PSC%' and WhseAR NOT LIKE '%SSPL%' and WhseAR NOT LIKE '%DE%' and WhseAR NOT LIKE '%RSC%' and WhseAR NOT LIKE '%OF%' THEN
					error :=129;
					error_message := N'Please Enter Proper Warehouse';
				END IF;
			END IF;
		END IF;
		MinAR := MinAR+1;
	END WHILE;
END IF;
END IF;

IF Object_type='112' and (:transaction_type ='A' ) Then

DECLARE INParty nvarchar(50);
DECLARE INCurrency nvarchar(50);
DECLARE INSeries nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	(SELECT T0."CardCode" into INParty FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType"=13);
	(SELECT T0."DocCur" into INCurrency FROM ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType"=13);
	(SELECT T1."SeriesName" into INSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"=:list_of_cols_val_tab_del  and T0."ObjType"=13);
		IF (INParty LIKE 'CPE%' and INCurrency = 'INR') THEN
			error:=130;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (INParty LIKE 'CSE%' and INCurrency = 'INR') THEN
			error:=130;
			error_message:=N'Please Select Proper Currency';
		END IF;
		IF (INSeries NOT LIKE 'CL%') THEN
			IF (INParty LIKE 'CSE%' and INSeries NOT LIKE 'EX%' and INSeries NOT LIKE 'EM%') THEN
				error:=130;
				error_message:=N'Please Select Proper Series';
			END IF;
			IF (INParty LIKE 'CPE%' and INSeries NOT LIKE 'EX%' and INSeries NOT LIKE 'EM%') THEN
				error:=130;
				error_message:=N'Please Select Proper Series';
			END IF;
		END IF;
END IF;
END IF;

IF Object_type = '112' and (:transaction_type ='A' ) Then

DECLARE ARrate decimal;
DECLARE ARExrate decimal;
DECLARE ARDocCur Nvarchar(50);
DECLARE ARdate date;
DECLARE ARCardCode Nvarchar(50);
DECLARE ARSeries Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
		SELECT ifnull(T0."DocRate",0) into ARrate FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=13 ;
		SELECT T0."DocDate" into ARdate FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=13;
		SELECT T0."DocCur" into ARDocCur FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=13;
		SELECT T0."CardCode" into ARCardCode FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=13;
		(SELECT T1."SeriesName" into ARSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13);

		IF ARCardCode LIKE 'C_E%' and ARSeries <> 'CL1/2223' THEN

			SELECT T0."Rate" into ARExrate FROM ORTT T0 WHERE T0."Currency" = ARDocCur and T0."RateDate" = ARdate;
			IF ARExrate <> ARrate THEN
				error :=131;
				error_message := N'Not allowed to change exchange rate.' || ARrate;
			END IF;
		END IF;
End If;
END IF;

IF object_type='112' AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE MinARD Int;
DECLARE MaxARD Int;
DECLARE PerUntQty Nvarchar(50);
DECLARE Ttlunt Nvarchar(50);
DECLARE Wghtpckng Nvarchar(50);
DECLARE pckngtype Nvarchar(50);
DECLARE typpltibc Nvarchar(50);
DECLARE lictype Nvarchar(50);
DECLARE licno Nvarchar(50);
DECLARE pltibc Nvarchar(50);
DECLARE Nopltibc Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 203
THEN
	SELECT Min(T0."VisOrder") INTO MinARD from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxARD from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinARD <= :MaxARD DO
		SELECT T1."Factor1" into PerUntQty FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."Factor3" into Ttlunt FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."U_WOPT" into Wghtpckng FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."U_PTYPE" into pckngtype FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."U_TOPLT" into typpltibc FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."U_LicenseType" into lictype FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."U_LicenseNum" into licno FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."U_NoPalates" into pltibc FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;
		SELECT T1."U_TAmount" into Nopltibc FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinARD;

		IF PerUntQty IS NULL  then
			error :=132;
			error_message := N'Please enter Per unit quantity';
		END IF;
		IF Ttlunt IS NULL  then
			error :=132;
			error_message := N'Please enter Total unit';
		END IF;
		IF Wghtpckng IS NULL  then
			error :=132;
			error_message := N'Please enter weight of packing type';
		END IF;
		IF pckngtype IS NULL  then
			error :=132;
			error_message := N'Please enter packing type';
		END IF;
		IF pckngtype <> 'Bags' AND pckngtype <> 'Carboys' AND pckngtype <> 'Carboys' AND pckngtype <> 'IBC Tank' AND pckngtype <> 'HDPE Drums' AND
		 pckngtype <> 'MS Drum' AND pckngtype <> 'Jumbo bag' AND pckngtype <> 'Loose' AND pckngtype <> 'Tanker Load' AND pckngtype <> 'ISO Tank' AND pckngtype <> 'Box' then
			error :=132;
			error_message := N'Please select proper packing type';
		END IF;
		IF typpltibc IS NULL  then
			error :=132;
			error_message := N'Please enter Type of pallets/IBC';
		END IF;
		IF typpltibc <> 'COUNTRY WOOD PALLETS' and typpltibc <> 'IBC TANK' and typpltibc <> 'ISO TANK' and
		typpltibc <> 'PINE WOOD PALLETS' and typpltibc <> 'PLASTIC PALLETS' and typpltibc <> 'BAGS' and typpltibc <> 'BOX' then
			error :=132;
			error_message := N'Please enter proper word Type of pallets/IBC';
		END IF;
		IF lictype IS NULL  then
			error :=132;
			error_message := N'Please enter License Type';
		END IF;
		IF pltibc IS NULL  then
			error :=132;
			error_message := N'Please enter Pallates/IBC';
		END IF;
		IF pltibc <> 'PALLETS' AND  pltibc <> 'IBC Tank' AND  pltibc <> 'ISO Tank' AND  pltibc <> 'BAGS' AND  pltibc <> 'BOX' then
			error :=132;
			error_message := N'Please enter proper word PALLETS/IBC Tank/ISO Tank';
		END IF;
		IF Nopltibc IS NULL  then
			error :=132;
			error_message := N'Please enter No of Pallates/IBC';
		END IF;
		MinARD := MinARD + 1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE MinAR Int;
DECLARE MaxAR Int;
DECLARE PerUntQty Nvarchar(50);
DECLARE Ttlunt Nvarchar(50);
DECLARE Wghtpckng Nvarchar(50);
DECLARE pckngtype Nvarchar(50);
DECLARE typpltibc Nvarchar(50);
DECLARE lictype Nvarchar(50);
DECLARE licno Nvarchar(50);
DECLARE pltibc Nvarchar(50);
DECLARE Nopltibc Nvarchar(50);
DECLARE SeriesAR Nvarchar(50);
DECLARE QCBatchNo Nvarchar(25);
DECLARE ItemCd Nvarchar(10);
DECLARE ExportAR Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13 THEN
	SELECT Min(T0."VisOrder") INTO MinAR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	(SELECT T1."SeriesName" into SeriesAR FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  	WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13);
    (SELECT T0."ImpORExp" into ExportAR FROM DRF12 T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del);

	WHILE :MinAR <= :MaxAR DO

		SELECT T1."Factor1" into PerUntQty FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."Factor3" into Ttlunt FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_WOPT" into Wghtpckng FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_PTYPE" into pckngtype FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_TOPLT" into typpltibc FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_LicenseType" into lictype FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_LicenseNum" into licno FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_NoPalates" into pltibc FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_TAmount" into Nopltibc FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."ItemCode" into ItemCd FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_QCBatchNo" into QCBatchNo FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;

		IF SeriesAR LIKE 'E%' then
			IF PerUntQty IS NULL  then
				error :=133;
				error_message := N'Please enter Per unit quantity';
			END IF;
			IF Ttlunt IS NULL  then
				error :=133;
				error_message := N'Please enter Total unit';
			END IF;
			IF Wghtpckng IS NULL  then
				error :=133;
				error_message := N'Please enter weight of packing type';
			END IF;
			IF pckngtype IS NULL  then
				error :=133;
				error_message := N'Please enter packing type';
			END IF;
			IF pckngtype <> 'Bags' AND pckngtype <> 'Carboys' AND pckngtype <> 'Carboys' AND pckngtype <> 'IBC Tank' AND pckngtype <> 'HDPE Drums' AND
		 	pckngtype <> 'MS Drum' AND pckngtype <> 'Jumbo bag' AND pckngtype <> 'Loose' AND pckngtype <> 'Tanker Load' AND pckngtype <> 'ISO Tank' AND pckngtype <> 'Box' then
				error :=133;
				error_message := N'Please select proper packing type';
			END IF;
			IF typpltibc IS NULL  then
				error :=133;
				error_message := N'Please enter Type of pallets/IBC';
			END IF;
			IF typpltibc <> 'COUNTRY WOOD PALLETS' and typpltibc <> 'IBC TANK' and typpltibc <> 'ISO TANK' and
			typpltibc <> 'PINE WOOD PALLETS' and typpltibc <> 'PLASTIC PALLETS' and typpltibc <> 'BAGS' and typpltibc <> 'BOX' then
				error :=133;
				error_message := N'Please enter Type of pallets/IBC/ISO';
			END IF;
			IF lictype IS NULL  then
				error :=133;
				error_message := N'Please enter License Type';
			IF lictype <> 'No Required' then
				IF licno IS NULL THEN
					error :=133;
					error_message := N'Please enter License No';
				END IF;
			END IF;
			END IF;
			IF pltibc IS NULL  then
				error :=189;
				error_message := N'Please enter Pallates/IBC';
			END IF;
			IF pltibc <> 'PALLETS' AND  pltibc <> 'IBC Tank' AND  pltibc <> 'ISO Tank' AND  pltibc <> 'BAGS' AND  pltibc <> 'BOX' then
				error :=133;
				error_message := N'Please enter proper word PALLETS/IBC Tank/ISO Tank';
			END IF;
			IF Nopltibc IS NULL  then
				error :=133;
				error_message := N'Please enter No of Pallates/IBC';
			END IF;
		END IF;
		--IF ItemCd in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013') and (QCBatchNo IS NULL or QCBatchNo = '') then
			--error := 133;
			--error_message := N'Please enter QC Batch No.';
		--END IF;

		IF ExportAR='Y' THEN
			IF lictype IS NULL  then
				error :=133;
				error_message := N'Please enter License Type';
			END IF;
			IF lictype <> 'No Required' then
				IF licno IS NULL THEN
					error :=1355;
					error_message := N'Please enter License No';
				END IF;
			END IF;
		END IF;
		MinAR := MinAR + 1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN

DECLARE MinAR Int;
DECLARE MaxAR Int;
DECLARE typpltibc Nvarchar(50);
DECLARE Nopltibc Nvarchar(50);
DECLARE SeriesAR Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	SELECT Min(T0."VisOrder") INTO MinAR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	(SELECT T1."SeriesName" into SeriesAR FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13);

	WHILE :MinAR <= :MaxAR DO
		SELECT T1."U_TOPLT" into typpltibc FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		SELECT T1."U_TAmount" into Nopltibc FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinAR;
		IF SeriesAR LIKE 'E%' then
			IF typpltibc IS NULL  then
				error :=134;
				error_message := N'Please enter Type of pallets/IBC';
			END IF;
			IF typpltibc <> 'COUNTRY WOOD PALLETS' and typpltibc <> 'IBC TANK' and typpltibc <> 'ISO TANK' and
			typpltibc <> 'PINE WOOD PALLETS' and typpltibc <> 'PLASTIC PALLETS' and typpltibc <> 'BAGS'  and typpltibc <> 'BOX' then
				error :=134;
				error_message := N'Please enter proper Type of pallets/IBC';
			END IF;
			IF Nopltibc IS NULL  then
				error :=134;
				error_message := N'Please enter No of Pallates/IBC';
			END IF;
		END IF;
		MinAR := MinAR + 1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN

DECLARE MinDL Int;
DECLARE MaxDL Int;
DECLARE PerUntQty decimal(18,2);
DECLARE Ttlunt decimal(18,2);
DECLARE Wghtpckng decimal(18,2);
DECLARE pckngtype Nvarchar(50);
DECLARE typpltibc Nvarchar(50);
DECLARE lictype Nvarchar(50);
DECLARE licno Nvarchar(50);
DECLARE pltibc Nvarchar(50);
DECLARE Nopltibc float;
DECLARE SeriesDL Nvarchar(50);
DECLARE QCBatchNo Nvarchar(25);
DECLARE ItemCd Nvarchar(10);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 15
THEN
	SELECT Min(T0."VisOrder") INTO MinDL from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxDL from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	(SELECT T1."SeriesName" into SeriesDL FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"	WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=15);

	WHILE :MinDL <= :MaxDL DO
		SELECT ifnull(T1."Factor1",0) into PerUntQty FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT ifnull(T1."Factor3",0) into Ttlunt FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT ifnull(T1."U_WOPT",0) into Wghtpckng FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT ifnull(T1."U_PTYPE",'') into pckngtype FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT ifnull(T1."U_TOPLT",'') into typpltibc FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT ifnull(T1."U_LicenseType",'') into lictype FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT ifnull(T1."U_LicenseNum",'') into licno FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT ifnull(T1."U_NoPalates",'') into pltibc FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT ifnull(T1."U_TAmount",0) into Nopltibc FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT T1."ItemCode" into ItemCd FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;
		SELECT T1."U_QCBatchNo" into QCBatchNo FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinDL;

		IF SeriesDL LIKE 'E%' then
			IF PerUntQty = 0  then
				error :=135;
				error_message := N'Please enter Per unit quantity';
			END IF;
			IF Ttlunt=0  then
				error :=135;
				error_message := N'Please enter Total unit';
			END IF;
			IF Wghtpckng IS NULL or Wghtpckng=0  then
				error :=135;
				error_message := N'Please enter weight of packing type';
			END IF;
			IF pckngtype IS NULL or pckngtype='' then
				error :=135;
				error_message := N'Please enter packing type';
			END IF;
			IF pckngtype <> 'Bags' AND pckngtype <> 'Carboys' AND pckngtype <> 'Carboys' AND pckngtype <> 'IBC Tank' AND pckngtype <> 'HDPE Drums' AND
		 		pckngtype <> 'MS Drum' AND pckngtype <> 'Jumbo bag' AND pckngtype <> 'Loose' AND pckngtype <> 'Tanker Load' AND pckngtype <> 'ISO Tank' AND pckngtype <> 'Box' then
				error :=135;
				error_message := N'Please select proper packing type';
			END IF;
			IF typpltibc IS NULL or typpltibc=''  then
				error :=135;
				error_message := N'Please enter Type of pallets/IBC';
			END IF;
			IF typpltibc <> 'COUNTRY WOOD PALLETS' and typpltibc <> 'IBC TANK' and typpltibc <> 'ISO TANK' and
				typpltibc <> 'PINE WOOD PALLETS' and typpltibc <> 'PLASTIC PALLETS' and typpltibc <> 'BAGS' and typpltibc <> 'BOX' then
				error :=135;
				error_message := N'Please enter proper Type of pallets/IBC/ISO';
			END IF;
			IF lictype IS NULL or lictype=''  then
				error :=135;
				error_message := N'Please enter License Type';
			END IF;
			IF (licno IS NULL or licno='') and lictype <> 'DBK' then
				error :=135;
				error_message := N'Please enter License No';
			END IF;
			IF pltibc IS NULL or pltibc='' then
				error :=135;
				error_message := N'Please enter Pallates/IBC';
			END IF;
			IF pltibc <> 'PALLETS' AND  pltibc <> 'IBC Tank' AND  pltibc <> 'ISO Tank' AND  pltibc <> 'BAGS' AND  pltibc <> 'BOX' then
				error :=135;
				error_message := N'Please enter proper word PALLETS/IBC Tank/ISO Tank';
			END IF;
			IF Nopltibc IS NULL or Nopltibc=0 then
				error :=135;
				error_message := N'Please enter No of Pallates/IBC';
			END IF;
			IF ItemCd in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013') and (QCBatchNo IS NULL or QCBatchNo = '') then
				error := 135;
				error_message := N'Please enter QC Batch No.';
			END IF;
		END IF;
		MinDL := MinDL + 1;
	END WHILE;
END IF;
END IF;

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare BaseType nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
(Select max(DRF1."BaseType") into BaseType
	from DRF1 inner join ODRF on ODRF."DocEntry"=DRF1."DocEntry"
	inner join OITM on DRF1."ItemCode" = OITM."ItemCode" and OITM."InvntItem" = 'Y'
	where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=18);
          IF (BaseType = '22') then
                  error :=137;
                  error_message := N'Please Select proper Base Document';
         End If;
End If;
END IF;

IF object_type = '112' and (:transaction_type = 'A' ) THEN
	Declare BASEDOCTYPE  varchar(50);
	DECLARE MINNAP int;
	DECLARE MAXXAP int;
	DECLARE APSeries varchar(50);
	DECLARE BaseCode varchar(50);
	DECLARE BaseMainItem varchar(50);
	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
	  Select MIN(T0."VisOrder") into MINNAP from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	  Select MAX(T0."VisOrder") into MAXXAP from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	  (SELECT T1."SeriesName" into APSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=18);

	WHILE MINNAP<=MAXXAP
	DO
		Select T0."U_BASETYPE" into BASEDOCTYPE from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = :MINNAP;
		Select T0."ItemCode" into BaseMainItem from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = :MINNAP;

		Select T0."U_UNE_ITCD" into BaseCode from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = :MINNAP;

		IF BaseMainItem <> 'SCRM0016' then
			IF (BASEDOCTYPE IS NULL OR BASEDOCTYPE = '') and APSeries NOT LIKE 'CL%'THEN
				 error:='140';
				 error_message :='Please select Base Doc Type. ' ;
			END IF;
			IF (BASEDOCTYPE <> 'NA' and BaseMainItem = 'SER0038')  then
				IF (BaseCode IS NULL OR BaseCode = '') and APSeries NOT LIKE 'CL%' THEN
					error:='140';
					 error_message :='Please select Base Doc item code ' ;
				END IF;
			END IF;
		END IF;
		 MINNAP = MINNAP + 1;
	END WHILE;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE POUNITPRICE varchar(50);
	DECLARE GRPOUNITPRICE varchar(50);
	DECLARE MINNGRPO int;
	DECLARE MAXXGRPO int;
	DECLARE GRPOSeries varchar(50);
	DECLARE GRPOCode varchar(50);
	Declare POUNITPRICECount int;
	DECLARE GRPOUNITPRICECount int;

	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	Select MIN(T0."VisOrder") into MINNGRPO from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXGRPO from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into GRPOSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=20;
	IF GRPOSeries NOT LIKE 'CL%' then
		WHILE MINNGRPO<=MAXXGRPO
		DO
			select T0."ItemCode" into GRPOCode from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINNGRPO;

			IF GRPOCode NOT LIKE 'PCPM%' THEN

				select Count(T1."Price") into POUNITPRICECount FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO and T4."ObjType"=20;

				if POUNITPRICECount>0 THEN
				select T1."Price" into POUNITPRICE FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO and T4."ObjType"=20;
				END IF;

				select Count(T3."Price") into GRPOUNITPRICECount FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO and T4."ObjType"=20;

				if GRPOUNITPRICECount>0 then
				select T3."Price" into GRPOUNITPRICE FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO and T4."ObjType"=20;
				END IF;

				IF POUNITPRICE IS NOT NULL THEN
					IF POUNITPRICE != GRPOUNITPRICE THEN
						error:='141';
						error_message :='Price difference. Line No'||MINNGRPO;
					END IF;
				END IF;
			END IF;
			MINNGRPO = MINNGRPO + 1;
		END WHILE;
	END IF;
END IF;
END IF;


If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE GRPOUNITPRICE varchar(50);
	DECLARE APUNITPRICE varchar(50);
	DECLARE MINNAP int;
	DECLARE MAXXAP int;
	DECLARE Itms varchar(50);
	DECLARE APSeries varchar(50);
	DECLARE APbstype varchar(50);
	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18 THEN
	Select MIN(T0."VisOrder") into MINNAP from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAP from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into APSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=18;

	WHILE MINNAP<=MAXXAP
	DO
		Select DRF1."BaseType" into APbstype from DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder" =  MINNAP;
		IF APSeries NOT LIKE 'CL%' and APbstype = '20' then
			select T1."Price" into GRPOUNITPRICE FROM PDN1 T1 LEFT OUTER JOIN OPDN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAP and T4."ObjType"=18;

			select T3."Price" into APUNITPRICE FROM PDN1 T1 LEFT OUTER JOIN OPDN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAP and T4."ObjType"=18;

			IF GRPOUNITPRICE IS NOT NULL THEN
				IF GRPOUNITPRICE != APUNITPRICE THEN
					error:='142';
					error_message :='Price difference. Line No';
				END IF;
			END IF;
		END IF;
		MINNAP = MINNAP + 1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE APQTD Int;
DECLARE MinLineAPQ Int;
DECLARE MaxLineAPQ Int;
DECLARE POQTB Int;
DECLARE Itm varchar(50);
DECLARE APSeries varchar(50);
DECLARE DocTyp varchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18 THEN
	SELECT Min(T0."VisOrder") INTO MinLineAPQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineAPQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into APSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=18;
  Select ODRF."DocType" into DocTyp from ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=18;

	IF DocTyp = 'I' then
		WHILE :MinLineAPQ<=MaxLineAPQ DO

			SELECT Distinct (DRF1."Quantity") INTO APQTD FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLineAPQ ;
			SELECT Distinct (DRF1."BaseOpnQty") INTO POQTB FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLineAPQ ;
			Select OITM."InvntItem" into Itm from DRF1 INNER JOIN OITM ON DRF1."ItemCode" = OITM."ItemCode" WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder" =  MinLineAPQ;

			IF Itm = 'N' and APSeries NOT LIKE 'CL%' then
				IF POQTB > 0 THEN
					IF  (APQTD > POQTB) THEN
						error :=144;
						error_message := 'AP Qty. should not greater then P.O Qty.... Line No'||MinLineAPQ;
					END IF;
				END IF;
			END IF;
			MinLineAPQ := MinLineAPQ+1;
		END WHILE;
	END IF;
END IF;
END IF;

IF Object_type = '112' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare Usr nvarchar(50);
Declare Frmwhs nvarchar(50);
DECLARE MinLineITQ Int;
DECLARE MaxLineITQ Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN
	SELECT Min(T0."VisOrder") INTO MinLineITQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineITQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into Usr from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign" where ODRF."DocEntry"= :list_of_cols_val_tab_del and ODRF."ObjType"=67;

	WHILE :MinLineITQ<=MaxLineITQ DO
		select DRF1."FromWhsCod" into Frmwhs from DRF1 where DRF1."DocEntry"= :list_of_cols_val_tab_del
		and DRF1."VisOrder"=MinLineITQ;
		If (Usr <> 'qc02' AND Usr <> 'qc03' and Frmwhs LIKE '%QC%') then
		    error :=145;
		    error_message := N'You are not allowed to do inventory transfer from QC Warehouse'||MinLineITQ;
		END IF;
		MinLineITQ := MinLineITQ+1;
	END WHILE;
END IF;
END IF;

---------Only QC dept can transfer material from QC warehouse------------
IF Object_type = '112' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare Usr nvarchar(50);
Declare Frmwhs nvarchar(50);
DECLARE MinLineITQ Int;
DECLARE MaxLineITQ Int;

(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN

	SELECT Min(T0."VisOrder") INTO MinLineITQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineITQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into Usr from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign" where ODRF."DocEntry"= :list_of_cols_val_tab_del
	and ODRF."ObjType"=67;

	WHILE :MinLineITQ<=MaxLineITQ DO
		select DRF1."FromWhsCod" into Frmwhs from DRF1 where DRF1."DocEntry"= :list_of_cols_val_tab_del
		and DRF1."VisOrder"=MinLineITQ;

			IF Frmwhs IN ('2PC-QCTR','SC-QC-TR','SC-QC','2SC-QC','JW-QC','PC-QC-TR','PC-QC','2PC-QC','3PC-QC') THEN
				If (Usr not in ('qc02','qc03','manager')) then
				    error :=14501;
				    error_message := N'You are not allowed to do inventory transfer from QC Warehouse'||MinLineITQ;
				END IF;
			END IF;

		MinLineITQ := MinLineITQ+1;
	END WHILE;
END IF;
END IF;

----------------Qc dept can transfer rejected material only to QC related warehouse---------
IF Object_type = '112' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare Usr nvarchar(50);
Declare Frmwhs nvarchar(50);
Declare Towhs nvarchar(50);
DECLARE MinLineITQ Int;
DECLARE MaxLineITQ Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN

	SELECT Min(T0."VisOrder") INTO MinLineITQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineITQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into Usr from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign" where ODRF."DocEntry"= :list_of_cols_val_tab_del
	and ODRF."ObjType"=67;

	WHILE :MinLineITQ<=MaxLineITQ DO
		select DRF1."FromWhsCod" into Frmwhs from DRF1 where DRF1."DocEntry"= :list_of_cols_val_tab_del
		and DRF1."VisOrder"=MinLineITQ;
		select DRF1."WhsCode" into Towhs from DRF1 where DRF1."DocEntry"= :list_of_cols_val_tab_del
		and DRF1."VisOrder"=MinLineITQ;

			IF Frmwhs LIKE '%QCR' THEN
				IF Towhs LIKE '%BT' AND Usr <> 'engg02' AND Usr <> 'engg07' THEN
					If (Usr <> 'qc02' AND Usr <> 'qc03' AND Towhs NOT IN ('2PC-QCTR','SC-QC-TR','SC-QC','2SC-QC','JW-QC','PC-QC-TR','PC-QC','2PC-QC','3PC-QC')) then
					    error :=14502;
					    error_message := N'You are not allowed to do inventory transfer by using QC Warehouse'||MinLineITQ;
					END IF;
				END IF;
			END IF;

		MinLineITQ := MinLineITQ+1;
	END WHILE;
END IF;
END IF;

----------------------------Branch Transfer is allowed to store dept only-------------

IF Object_type = '112' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare Usr nvarchar(50);
Declare Frmwhs nvarchar(50);
Declare ToWhs nvarchar(50);
DECLARE MinLineITQ Int;
DECLARE MaxLineITQ Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN

	SELECT Min(T0."VisOrder") INTO MinLineITQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineITQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into Usr from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign" where ODRF."DocEntry"= :list_of_cols_val_tab_del
	and ODRF."ObjType"=67;

	WHILE :MinLineITQ<=MaxLineITQ DO
		select DRF1."FromWhsCod" into Frmwhs from DRF1 where DRF1."DocEntry"= :list_of_cols_val_tab_del
		and DRF1."VisOrder"=MinLineITQ;

		select DRF1."WhsCode" into ToWhs from DRF1 where DRF1."DocEntry"= :list_of_cols_val_tab_del
		and DRF1."VisOrder"=MinLineITQ;

			IF Frmwhs LIKE '%BT' THEN
				If (Usr <> 'engg02' AND Usr <> 'engg07') then
				    error :=14503;
				    error_message := N'You are not allowed to do inventory transfer from BT Warehouse'||MinLineITQ;
				END IF;
			END IF;

			IF ToWhs LIKE '%BT' THEN
				If (Usr <> 'engg02' AND Usr <> 'engg07') then
				    error :=14504;
				    error_message := N'You are not allowed to do inventory transfer by using BT Warehouse'||MinLineITQ;
				END IF;
			END IF;

		MinLineITQ := MinLineITQ+1;
	END WHILE;
END IF;
END IF;
---------------- Only Store dept can transfer rejected matrial to only BT warehouse and vice-varsa----------------
IF Object_type = '112' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare Usr nvarchar(50);
Declare Frmwhs nvarchar(50);
Declare Towhs nvarchar(50);
DECLARE MinLineITQ Int;
DECLARE MaxLineITQ Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN

	SELECT Min(T0."VisOrder") INTO MinLineITQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineITQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into Usr from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign" where ODRF."DocEntry"= :list_of_cols_val_tab_del
	and ODRF."ObjType"=67;

	WHILE :MinLineITQ<=MaxLineITQ DO
		select DRF1."FromWhsCod" into Frmwhs from DRF1 where DRF1."DocEntry"= :list_of_cols_val_tab_del
		and DRF1."VisOrder"=MinLineITQ;
		select DRF1."WhsCode" into Towhs from DRF1 where DRF1."DocEntry"= :list_of_cols_val_tab_del
		and DRF1."VisOrder"=MinLineITQ;

			IF Frmwhs LIKE '%QCR' THEN
				If (Usr = 'engg02' AND Usr = 'engg07' AND Towhs NOT LIKE '%BT' ) then
				    error :=14505;
				    error_message := N'You are only allowed to transfer rejected material to BT Warehouse'||MinLineITQ;
				END IF;
			END IF;

			IF Frmwhs LIKE '%BT' THEN
				If (Usr = 'engg02' AND Usr = 'engg07' AND Towhs NOT LIKE '%QCR' ) then
				    error :=14506;
				    error_message := N'You are only allowed to transfer rejected material to Rejected Warehouse'||MinLineITQ;
				END IF;
			END IF;

		MinLineITQ := MinLineITQ+1;
	END WHILE;
END IF;
END IF;

---------------------------------------------------

IF object_type='112' AND (:transaction_type = 'A') THEN

DECLARE MinAP Int;
DECLARE MaxAP Int;
DECLARE LicenseAP Nvarchar(50);
DECLARE LicneseMainAP Nvarchar(50);
DECLARE LicTypeMainAP Nvarchar(50);
DECLARE APSeries varchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
	SELECT Min(T0."VisOrder") INTO MinAP from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into APSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=18;

	IF APSeries NOT LIKE 'CL%' then
		WHILE :MinAP<=MaxAP DO
			SELECT DRF1."U_LicenseType" into LicTypeMainAP FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinAP;
			SELECT DRF1."U_LicenseNum" into LicenseAP FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinAP;
			SELECT count("U_LCNumber") into LicneseMainAP FROM "@LICENSEMANAGER" WHERE "U_LCNumber" = LicenseAP;
			IF LicTypeMainAP NOT LIKE 'D%' then
				IF LicenseAP IS NOT NULL THEN
					IF LicneseMainAP = 0 THEN
						error :=146;
						error_message := N'This License No not available in License Master.'||LicenseAP;
					END IF;
				END IF;
			END IF;
			MinAP := MinAP+1;
		END WHILE;
	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN

DECLARE MinAR Int;
DECLARE MaxAR Int;
DECLARE LicenseAR Nvarchar(50);
DECLARE LicenseTypeAR Nvarchar(50);
DECLARE LicneseMainAR Nvarchar(50);
DECLARE ARSeries varchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	SELECT Min(T0."VisOrder") INTO MinAR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into ARSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13;

	IF ARSeries NOT LIKE 'CL%' then
		WHILE :MinAR<=MaxAR DO
			SELECT DRF1."U_LicenseNum" into LicenseAR FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinAR;
			SELECT DRF1."U_LicenseType" into LicenseTypeAR FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinAR;
			SELECT count("U_LCNumber") into LicneseMainAR FROM "@LICENSEMANAGER" WHERE "U_LCNumber" = LicenseAR;
			IF LicenseAR IS NOT NULL and LicneseMainAR = 'ADVANCE' THEN
				IF LicneseMainAR = 0 THEN
					error :=147;
					error_message := N'This License No. not available in License Master.'||LicenseAR;
				END IF;
			END IF;
			MinAR := MinAR+1;
		END WHILE;
	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN

DECLARE MinARD Int;
DECLARE MaxARD Int;
DECLARE LicenseARD Nvarchar(50);
DECLARE LicneseMainARD Nvarchar(50);
DECLARE ARDSeries varchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 203
THEN
	SELECT Min(T0."VisOrder") INTO MinARD from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxARD from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into ARDSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=203;

	IF ARDSeries NOT LIKE 'CL%' then
		WHILE :MinARD<=MaxARD DO
			SELECT DRF1."U_LicenseNum" into LicenseARD FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinARD;
			SELECT count("U_LCNumber") into LicneseMainARD FROM "@LICENSEMANAGER" WHERE "U_LCNumber" = LicenseARD;

			IF LicenseARD IS NOT NULL THEN
				IF LicneseMainARD = 0 THEN
					error :=148;
					error_message := N'This License No. not available in License Master.'||LicenseARD;
				END IF;
			END IF;
			MinARD := MinARD+1;
		END WHILE;
	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN

DECLARE MinDL Int;
DECLARE MaxDL Int;
DECLARE LicenseDL Nvarchar(50);
DECLARE LicenseTypeDL Nvarchar(50);
DECLARE LicneseMainDL Nvarchar(50);
DECLARE DLSeries varchar(50);
DECLARE ItemDL varchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 15
THEN
	SELECT Min(T0."VisOrder") INTO MinDL from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxDL from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into DLSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=15;

	IF DLSeries NOT LIKE 'CL%' then
		WHILE :MinDL<=MaxDL DO
			SELECT DRF1."U_LicenseNum" into LicenseDL FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinDL;
			SELECT DRF1."U_LicenseType" into LicenseTypeDL FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinDL;
			SELECT count("U_LCNumber") into LicneseMainDL FROM "@LICENSEMANAGER" WHERE "U_LCNumber" = LicenseDL;
			SELECT DRF1."ItemCode" into ItemDL FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinDL;

			IF LicenseDL IS NOT NULL and LicenseTypeDL = 'ADVANCE' THEN
				IF LicneseMainDL = 0 THEN
					error :=149;
					error_message := N'This License No. not available in License Master.' ||ItemDL;
				END IF;
			END IF;
			MinDL := MinDL+1;
		END WHILE;
	END IF;
END IF;
END IF;

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare CardCode nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13 THEN
(Select ODRF."CardCode" into CardCode from ODRF WHERE ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=13);
          IF (CardCode = 'CPD0125') then
                  error :=157;
                  error_message := N'Something went wrong..';
         End If;
End If;
END IF;

-------------------------------------------------
/*IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare ItCode nvarchar(50);
Declare whssss nvarchar(50);
Declare WhsType nvarchar(50);
DECLARE MinGRN int;
DECLARE MaxGRN int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20 THEN
	SELECT Min(T0."VisOrder") INTO MinGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE MinGRN<=MaxGRN DO
		(Select DRF1."WhsCode" into whssss from DRF1 WHERE DRF1."DocEntry"=list_of_cols_val_tab_del and DRF1."VisOrder"=MinGRN);
		(Select DRF1."ItemCode" into ItCode from DRF1 WHERE DRF1."DocEntry"=list_of_cols_val_tab_del and DRF1."VisOrder"=MinGRN);
		(Select OWHS."U_UNE_JAPP" into WhsType from DRF1 INNER JOIN OWHS ON OWHS."WhsCode" = DRF1."WhsCode"
			WHERE DRF1."DocEntry"=list_of_cols_val_tab_del and DRF1."VisOrder"=MinGRN);

		IF WhsType = 'N' THEN
	         IF (ItCode LIKE '%PM%') then
	         	IF  whssss NOT LIKE '%PAC%'  then
	              error :=159;
	              error_message := N'please select packing material warehouse..';
	            END IF;
	         END IF;
        END IF;
    	MinGRN := MinGRN+1;
	END WHILE;
End If;
END IF;*/

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare Unit nvarchar(50);
Declare Series nvarchar(50);
Declare UsrCod nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
		Select NNM1."SeriesName" into Series from ODRF INNER JOIN NNM1 ON ODRF."Series" = NNM1."Series" WHERE ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=13;

		IF Series NOT LIKE 'CL%' THEN
			Select ODRF."BPLName" into Unit from ODRF WHERE ODRF."DocEntry" = list_of_cols_val_tab_del and ODRF."ObjType"=13;
			select OUSR."USER_CODE" into UsrCod from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign" where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=13;

	         IF (Unit = 'UNIT - I' and Series NOT LIKE '%M%'  and UsrCod = 'dispatch01') then
	               error :=161;
	               error_message := N'Please Select DM1/2021 Series';
	         End If;
         End If;
End If;
END IF;

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare Unit nvarchar(50);
Declare Series nvarchar(50);
Declare UsrCod nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
		Select NNM1."SeriesName" into Series from ODRF INNER JOIN NNM1 ON ODRF."Series" = NNM1."Series"	WHERE ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=13;
		Select ODRF."BPLName" into Unit from ODRF WHERE ODRF."DocEntry" = list_of_cols_val_tab_del and ODRF."ObjType"=13;
		select OUSR."USER_CODE" into UsrCod from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign" where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=13;

		IF Series NOT LIKE 'CL2%' THEN
         IF (Unit = 'UNIT - II' and Series NOT LIKE 'DM2%' and UsrCod = 'dispatch01') then
               error :=161;
               error_message := N'Please Select DM2/2021 Series';
         End If;
        END IF;

End If;
END IF;

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare IssueDate nvarchar(50);
Declare ReceiptDate nvarchar(50);
Declare Baserefno nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
		select distinct "BaseEntry" into Baserefno from DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del;
		IF (Baserefno IS NOT NULL) then
			Select MAX(OIGE."DocDate") into IssueDate from IGE1 INNER JOIN OIGE ON OIGE."DocEntry" = IGE1."DocEntry" WHERE IGE1."BaseEntry" = Baserefno;

			select "DocDate" into ReceiptDate from ODRF WHERE ODRF."DocEntry" = list_of_cols_val_tab_del and ODRF."ObjType"=59;

	         IF (ReceiptDate < IssueDate) then
	               error :=162;
	               error_message := N'Receipt date must be after or equal to Issue date';
	         End If;
	    END IF;
End If;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	DECLARE POUNIT varchar(50);
	DECLARE GRPOUNIT varchar(50);
	DECLARE MINNGRPO int;
	DECLARE MAXXGRPO int;
	DECLARE GRPOSeries varchar(50);
	DECLARE Code varchar(50);
	DECLARE POUNITCount int;
	DECLARE GRPOUNITCount varchar(50);

	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	Select MIN(T0."VisOrder") into MINNGRPO from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXGRPO from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into GRPOSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=20;

	IF GRPOSeries NOT LIKE 'CL%' then
		WHILE MINNGRPO<=MAXXGRPO
		DO
			select T1."ItemCode" into Code FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder" = MINNGRPO;
			IF Code <> 'PCPM0094' and Code <> 'PCPM0095' and Code <> 'PCPM0096' and Code <> 'PCPM0097' and Code <> 'PCPM0098' then

				select Count(ifnull(T2."BPLId",0)) into POUNITCount FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO and T4."ObjType"=20;

				if POUNITCount>0
				THEN
				select T2."BPLId" into POUNIT FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO and T4."ObjType"=20;
				END IF;

				select Count(ifnull(T4."BPLId",0)) into GRPOUNITCount FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO and T4."ObjType"=20;

				if GRPOUNITCount>0
				THEN
				select T4."BPLId" into GRPOUNIT FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO and T4."ObjType"=20;
				END IF;

				IF POUNIT IS NOT NULL THEN
					IF POUNIT != GRPOUNIT THEN
						error:='164';
						error_message :='Something went wrong.UNIT.'||MINNGRPO;
					END IF;
				END IF;
			End IF;
			MINNGRPO = MINNGRPO + 1;
		END WHILE;
	END IF;
END IF;
END IF;


----Commented becuase GRN do not go in approval------
IF object_type='112' AND (:transaction_type = 'A' ) THEN
DECLARE DateGRN1 date;
Declare Seris varchar(100);
Declare ItemC varchar(100);
DECLARE MINNIT int;
DECLARE MAXXIT int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
		Select MIN(T0."VisOrder") into MINNIT from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		Select MAX(T0."VisOrder") into MAXXIT from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		WHILE MINNIT<=MAXXIT
		DO
		select T0."DocDate" INTO DateGRN1 from ODRF T0 where T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=20;
		select T0."ItemCode" INTO ItemC from DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINNIT;
		Select NNM1."SeriesName" into Seris from ODRF INNER JOIN NNM1 ON ODRF."Series" = NNM1."Series"
			 WHERE ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=20;
			IF Seris NOT LIKE 'CL%' THEN
				IF ItemC <> 'SCRM0016' THEN
					IF  DateGRN1 <> CURRENT_DATE THEN
						error :=166;
						error_message := N'GRN Not allowed in back date..';
					END IF;
				END IF;
			END IF;
		MINNIT = MINNIT + 1;
		END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE DateGR Int;
DECLARE DateCHDT Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59 THEN
		select  DAYS_BETWEEN(T0."U_UNE_CHDT",T0."DocDate") INTO DateGR from ODRF T0 where T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=59;
		select  Count(T0."U_UNE_CHDT") INTO DateCHDT from ODRF T0 where T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=59;
		IF DateCHDT > 0 THEN
			IF  DateGR > 2 THEN
				error :=167;
				error_message := N'Challan Date not allowed in back days than Receipt date..';
			END IF;
		END IF;
END IF;
END IF;

------------------------GRN in 2PC-FLOR-------------	----------
IF object_type='112' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE GRPWHS Nvarchar(50);
DECLARE Branch Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT T0."BPLId" INTO Branch FROM ODRF T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del and T0."ObjType"=20;

	IF Branch = 3 THEN

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinLinePDQ<=MaxLinePDQ DO
		select T0."WhsCode" INTO GRPWHS from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		IF  GRPWHS LIKE '%FLOR%' THEN
			error :=1701;
			error_message := N'Not allowed to select FLOR warehouse...!';
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;

	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE GRPWHS Nvarchar(50);
DECLARE ItemCode Nvarchar(50);
DECLARE Branch Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT T0."BPLId" INTO Branch FROM ODRF T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del and T0."ObjType"=20;

	IF Branch = 4 THEN

	SELECT Min(T0."VisOrder") INTO MinLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinLinePDQ<=MaxLinePDQ DO
		select T0."WhsCode" INTO GRPWHS from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
		select T0."ItemCode" INTO ItemCode from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

			IF ItemCode <> 'PCRM0018' THEN
				IF  GRPWHS LIKE '%FLOR%' THEN
					error :=1702;
					error_message := N'Not allowed to select FLOR warehouse...!';
				END IF;
			END IF;
	MinLinePDQ := MinLinePDQ+1;
	END WHILE;

	END IF;
END IF;
END IF;
-----------------------------------------------


IF object_type='112' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE Seris Nvarchar(50);
DECLARE GRPWHS Nvarchar(50);
DECLARE UsrCod Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into UsrCod from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign" where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=20;
	Select NNM1."SeriesName" into Seris from ODRF INNER JOIN NNM1 ON ODRF."Series" = NNM1."Series" WHERE ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=20;

	WHILE :MinLinePDQ<=MaxLinePDQ DO
		select T0."WhsCode" INTO GRPWHS from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		IF UsrCod = 'dispatch01' and Seris NOT LIKE 'CL%' THEN --'dispatch01'
			IF GRPWHS NOT LIKE '%SSPL%' AND GRPWHS NOT LIKE '%PDI%' AND GRPWHS NOT LIKE '%ADVP%' AND GRPWHS NOT LIKE '%GJCM%' AND GRPWHS NOT LIKE '%AP%' AND GRPWHS NOT LIKE '%DE%' THEN
				error :=173;
				error_message := N'Wrong warehouse selection...!';
			END IF;
			IF Seris NOT LIKE 'JC%' THEN
				error :=173;
				error_message := N'Please select job work series...!';
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;

END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE Seris Nvarchar(50);
DECLARE GRPWHS Nvarchar(50);
DECLARE UsrCod Nvarchar(50);
DECLARE Address Int;
DECLARE Address2 Int;
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	select OUSR."USER_CODE" into UsrCod from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign" where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=20;
	Select NNM1."SeriesName" into Seris from ODRF INNER JOIN NNM1 ON ODRF."Series" = NNM1."Series" WHERE ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=20;
	Select LENGTH(ODRF."Address2") into Address2 from ODRF WHERE ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=20;
	WHILE :MinLinePDQ<=MaxLinePDQ DO
		select T0."WhsCode" INTO GRPWHS from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		select LENGTH(T0."U_UNE_CUCD") INTO Address from OWHS T0 WHERE T0."WhsCode" = GRPWHS;

		IF UsrCod = 'dispatch01' and Seris NOT LIKE '%CL%' THEN
			IF Address <> Address2 THEN
				error :=174;
				error_message := N'Please check ship to address...!';
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;

END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE Factor1 decimal;
DECLARE Seris Nvarchar(50);
DECLARE Factor3 decimal;
DECLARE Factor2 decimal;
DECLARE Code Nvarchar(50);
DECLARE Packing Nvarchar(50);
DECLARE Qty Int;
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	Select NNM1."SeriesName" into Seris from ODRF INNER JOIN NNM1 ON ODRF."Series" = NNM1."Series"
			 WHERE ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=20;

	WHILE :MinLinePDQ<=MaxLinePDQ DO

		select T0."U_PTYPE" INTO Packing from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		select T0."ItemCode" INTO Code from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		select T0."Factor1" INTO Factor1 from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		select T0."Factor2" INTO Factor2 from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		select T0."Factor3" INTO Factor3 from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		select T0."Quantity" INTO Qty from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;

		IF Code <> 'SCRM0016' and Code <> 'DIRM0026' THEN
			IF Packing NOT LIKE '%anker%' and Code LIKE '%RM%' and Seris NOT LIKE '%CL%' and Packing NOT LIKE '%oose%' and Factor2 = 1 THEN
				IF (Factor1 * Factor3) <> Qty THEN
					error :=175;
					error_message := N'per Unit Quantity or Total unit may worng...!';
				END IF;
			END IF;
			IF Factor2 <> 1 then
				IF (Factor1 * Factor3 * Factor2) <> Qty THEN
					error :=175;
					error_message := N'per Unit Quantity or Total unit may worng...!';
				END IF;
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;

END IF;
END IF;
IF object_type='112' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE Seris Nvarchar(50);
DECLARE Code Nvarchar(50);
DECLARE Packing Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	Select NNM1."SeriesName" into Seris from ODRF INNER JOIN NNM1 ON ODRF."Series" = NNM1."Series"
			 WHERE ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=20;

	WHILE :MinLinePDQ<=MaxLinePDQ DO

		select T0."U_PTYPE" INTO Packing from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
		select T0."ItemCode" INTO Code from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinLinePDQ;
		IF Code <> 'SCRM0016' THEN
			IF Seris NOT LIKE '%CL%' and Code LIKE '%RM%' THEN
				IF Packing <> 'Bags' and Packing <> 'Carboys' and Packing <> 'HDPE Drums' and Packing <> 'IBC Tank'
					and Packing <> 'MS Drum' and Packing <> 'Jumbo bag' and Packing <> 'Loose' and Packing <> 'Tanker Load' THEN
					error :=176;
					error_message := N'Please select Proper packing type...!';
				END IF;
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;

END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	DECLARE PODATE varchar(50);
	DECLARE GRPODATE varchar(50);
	DECLARE MINNGRPO int;
	DECLARE MAXXGRPO int;
	DECLARE GRPOSeries varchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	Select MIN(T0."VisOrder") into MINNGRPO from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXGRPO from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into GRPOSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=20;

	IF GRPOSeries NOT LIKE 'CL%' then
		WHILE MINNGRPO<=MAXXGRPO
		DO

			select MAX(T2."DocDate") into PODATE FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO and T4."ObjType"=20;

			select MAX(T4."DocDate") into GRPODATE FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNGRPO and T4."ObjType"=20;

			IF PODATE IS NOT NULL THEN
				IF PODATE > GRPODATE THEN
					error:='177';
					error_message :='Date issue...';
				END IF;
			END IF;

			MINNGRPO = MINNGRPO + 1;
		END WHILE;
	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinLinePD Int;
DECLARE MaxLinePD Int;
DECLARE ItemCDPD Nvarchar(50);
DECLARE ItemCount Int;
Declare Whse Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinLinePD from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePD from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinLinePD<=MaxLinePD DO
		SELECT DRF1."ItemCode" into ItemCDPD FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePD;
		SELECT DRF1."WhsCode" INTO Whse FROM DRF1 where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePD;

		select Count("Code") into ItemCount From "@UNE_STAGE" WHERE "Code" =  ItemCDPD;
		IF ItemCount > 0 THEN
			IF Whse LIKE '%QC%'  THEN
				error:='178';
				error_message :='For this Item QC not required.. please select SC-RAW warehouse';
			END IF;
		END IF;
		MinLinePD := MinLinePD+1;
	END WHILE;

END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinLinePD Int;
DECLARE MaxLinePD Int;
DECLARE ItemCDPD Nvarchar(50);
Declare Whse Nvarchar(50);
Declare Series Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinLinePD from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePD from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	SELECT T0."SeriesName" into Series FROM ODRF T1 INNER JOIN NNM1 T0 ON T0."Series" = T1."Series"
				 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=20;

	IF ItemCDPD LIKE 'CL%' THEN
		WHILE :MinLinePD<=MaxLinePD DO
			SELECT DRF1."ItemCode" into ItemCDPD FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePD;
			SELECT DRF1."WhsCode" INTO Whse FROM DRF1 where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePD;

			IF ItemCDPD LIKE 'E%' THEN
				IF Whse LIKE '%QC%'  THEN
					error:='179';
					error_message :='Wrong warehouse';
				END IF;
			END IF;
			MinLinePD := MinLinePD+1;
		END WHILE;
	END IF;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	DECLARE SODATE varchar(50);
	DECLARE ARDATE varchar(50);
	DECLARE MINNAR int;
	DECLARE MAXXAR int;
	DECLARE Itm varchar(50);
	DECLARE ARSeries varchar(50);
	DECLARE ARbstype varchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	Select MIN(T0."VisOrder") into MINNAR from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAR from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into ARSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13;

	WHILE MINNAR<=MAXXAR
	DO
		Select DRF1."BaseType" into ARbstype from DRF1
		WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder" =  MINNAR;

		IF ARSeries NOT LIKE 'CL%' and ARbstype = '17' then

			select MAX(T2."DocDate") into SODATE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR and T4."ObjType"=13;

			select Top 1 T4."DocDate" into ARDATE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR and T4."ObjType"=13;

			IF SODATE IS NOT NULL THEN
				IF SODATE > ARDATE THEN
					error:='180';
					error_message :='Date issue.';
				END IF;
			END IF;

		END IF;
		MINNAR = MINNAR + 1;
	END WHILE;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	DECLARE PODATE varchar(50);
	DECLARE APDATE varchar(50);
	DECLARE MINNAP int;
	DECLARE MAXXAP int;
	DECLARE Itm varchar(50);
	DECLARE APSeries varchar(50);
	DECLARE APbstype varchar(50);
	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
	Select MIN(T0."VisOrder") into MINNAP from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAP from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into APSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=18;

	WHILE MINNAP<=MAXXAP
	DO
		Select DRF1."BaseType" into APbstype from DRF1
		WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder" =  MINNAP;

		IF APSeries NOT LIKE 'CL%' and APbstype = '22' then

			select MAX(T2."DocDate") into PODATE FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAP and T4."ObjType"=18;

			select MAX(T4."DocDate") into APDATE FROM POR1 T1 LEFT OUTER JOIN OPOR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAP and T4."ObjType"=18;

			IF PODATE IS NOT NULL THEN
				IF PODATE > APDATE THEN
					error:='181';
					error_message :='Date issue..';
				END IF;
			END IF;

		END IF;
		MINNAP = MINNAP + 1;
	END WHILE;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	DECLARE SODATE varchar(50);
	DECLARE DLDATE varchar(50);
	DECLARE MINNDL int;
	DECLARE MAXXDL int;
	DECLARE DLSeries varchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 15
THEN
	Select MIN(T0."VisOrder") into MINNDL from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXDL from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into DLSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=15;

	IF DLSeries NOT LIKE 'CL%' then
		WHILE MINNDL<=MAXXDL
		DO

			select MAX(T2."DocDate") into SODATE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNDL and T4."ObjType"=15;

			select MAX(T4."DocDate") into DLDATE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNDL and T4."ObjType"=15;

			IF SODATE IS NOT NULL THEN
				IF SODATE > DLDATE THEN
					error:='182';
					error_message :='Date issue....';
				END IF;
			END IF;

			MINNDL = MINNDL + 1;
		END WHILE;
	END IF;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	DECLARE DLDATE varchar(50);
	DECLARE ARDATE varchar(50);
	DECLARE MINNAR int;
	DECLARE MAXXAR int;
	DECLARE ARSeries varchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	Select MIN(T0."VisOrder") into MINNAR from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAR from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into ARSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13;

	IF ARSeries NOT LIKE 'CL%' then
		WHILE MINNAR<=MAXXAR
		DO

			select MAX(T2."DocDate") into DLDATE FROM DLN1 T1 LEFT OUTER JOIN ODLN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR and T4."ObjType"=13;

			select  MAX(T4."DocDate") into ARDATE FROM DLN1 T1 LEFT OUTER JOIN ODLN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR and T4."ObjType"=13;

			IF DLDATE IS NOT NULL THEN
				IF DLDATE > ARDATE THEN
					error:='183';
					error_message :='Date issue.....';
				END IF;
			END IF;

			MINNAR = MINNAR + 1;
		END WHILE;
	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE Packing Nvarchar(50);
DECLARE ICode Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGRN <= :MaxGRN DO
		SELECT T1."U_PTYPE" into Packing FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGRN;
		SELECT T1."ItemCode" into ICode FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGRN;

		IF ICode LIKE '%RM%' and ICode LIKE '%FG%' then
			IF Packing <> 'Bags' AND Packing <> 'Carboys' AND Packing <> 'IBC Tank' AND Packing <> 'HDPE Drums' AND
			 Packing <> 'MS Drum' AND Packing <> 'Jumbo bag' AND Packing <> 'Tanker Load' then
				error :=187;
				error_message := N'Please select proper packing type';
			END IF;
		END IF;

		MinGRN := MinGRN + 1;
	END WHILE;
END IF;
END IF;

-------------------------------------------

IF Object_type='112' and (:transaction_type ='A' OR :transaction_type = 'U') Then
DECLARE MinSO int;
DECLARE MaxSO int;
DECLARE SOItemCode nvarchar(50);
DECLARE SOName nvarchar(100);
DECLARE Freetext nvarchar(50);
DECLARE U_Agro_Chem nvarchar(50);
DECLARE U_Per_HM_CR nvarchar(50);
DECLARE U_Food nvarchar(50);
DECLARE U_Paints_Pigm nvarchar(50);
DECLARE U_Indus_Care nvarchar(50);
DECLARE U_Lube_Additiv nvarchar(50);
DECLARE U_Oil_Gas nvarchar(50);
DECLARE U_Textile nvarchar(50);
DECLARE Series nvarchar(50);
DECLARE U_CAS_No nvarchar(50);
DECLARE U_Other2 nvarchar(50);
DECLARE U_Other1 nvarchar(50);
DECLARE U_Pharma nvarchar(50);
DECLARE U_Mining nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 15
THEN
	(SELECT min(T0."VisOrder") Into MinSO FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxSO FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT T0."SeriesName" into Series FROM ODRF T1 INNER JOIN NNM1 T0 ON T0."Series"=T1."Series"
		WHERE T1."DocEntry"=:list_of_cols_val_tab_del and T1."ObjType"=15);
	WHILE MinSO <= MaxSO
	DO
	(SELECT T1."ItemCode" into SOItemCode FROM DRF1 T1 LEFT JOIN ODRF T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del and T0."ObjType"=15 AND T1."VisOrder"=MinSO);
	(SELECT T1."Dscription" into SOName FROM DRF1 T1 WHERE T1."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);
	(SELECT T1."FreeTxt" into Freetext FROM DRF1 T1 LEFT JOIN ODRF T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO and T0."ObjType"=15);
	select "U_Agro_Chem" into U_Agro_Chem from oitm where "ItemCode" = SOItemCode;
	select "U_Per_HM_CR" into U_Per_HM_CR from oitm where "ItemCode" = SOItemCode;
	select "U_Food" into U_Food from oitm where "ItemCode"= SOItemCode;
	select "U_Paints_Pigm" into U_Paints_Pigm from oitm where "ItemCode"= SOItemCode;
	select "U_Indus_Care" into U_Indus_Care from oitm where "ItemCode"= SOItemCode;
	select "U_Lube_Additiv" into U_Lube_Additiv from oitm where "ItemCode"= SOItemCode;
	select "U_Textile" into U_Textile from oitm where "ItemCode"= SOItemCode;
	select "U_Oil_Gas" into U_Oil_Gas  from oitm where "ItemCode"= SOItemCode;
	select "U_CAS_No" into U_CAS_No  from oitm where "ItemCode"= SOItemCode;
	select "U_Other1" into U_Other1  from oitm where "ItemCode"= SOItemCode;
	select "U_Other2" into U_Other2  from oitm where "ItemCode"= SOItemCode;
	select "U_Pharma" into U_Pharma  from oitm where "ItemCode"= SOItemCode;
	select "U_Mining" into U_Mining  from oitm where "ItemCode"= SOItemCode;

		IF Series NOT LIKE 'CL%' then
		IF (SOItemCode NOT LIKE 'SC%' AND SOItemCode NOT LIKE 'PCPM%' AND SOItemCode NOT LIKE 'FA%' AND SOItemCode NOT LIKE 'WS%') THEN
			IF SOName = Freetext then
			else
				IF Freetext = U_Agro_Chem then
				else
					IF Freetext = U_Per_HM_CR then
					else
						IF Freetext = U_Food then
						else
							IF Freetext = U_Paints_Pigm then
							else
								IF Freetext = U_Indus_Care then
								else
									IF Freetext = U_Textile then
									else
										IF Freetext = U_Lube_Additiv then
										else
											IF Freetext = U_Oil_Gas then
											else
												IF Freetext = U_CAS_No then
												else
													IF Freetext = U_Other1 then
													else
														IF Freetext = U_Other2 then
														else
															IF Freetext = U_Pharma then
															else
																IF Freetext = U_Mining then
																else
																	error:=188;
																	error_message:=N'Please Select Proper Alias Name Delivery (Alias Name not in master)';
																END IF;
															END IF;
														END IF;
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
		END IF;
	 MinSO=MinSO+1;
	END WHILE;
END IF;
END IF;



IF Object_type='112' and (:transaction_type ='A' OR :transaction_type = 'U') Then
DECLARE MinSO int;
DECLARE MaxSO int;
DECLARE SOItemCode nvarchar(50);
DECLARE SOName nvarchar(100);
DECLARE Freetext nvarchar(50);
DECLARE U_Agro_Chem nvarchar(50);
DECLARE U_Per_HM_CR nvarchar(50);
DECLARE U_Food nvarchar(50);
DECLARE U_Paints_Pigm nvarchar(50);
DECLARE U_Indus_Care nvarchar(50);
DECLARE U_Lube_Additiv nvarchar(50);
DECLARE U_Oil_Gas nvarchar(50);
DECLARE U_Textile nvarchar(50);
DECLARE Series nvarchar(50);
DECLARE U_CAS_No nvarchar(50);
DECLARE U_Other2 nvarchar(50);
DECLARE U_Other1 nvarchar(50);
DECLARE U_Pharma nvarchar(50);
DECLARE U_Mining nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	(SELECT min(T0."VisOrder") Into MinSO FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxSO FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT T0."SeriesName" into Series FROM ODRF T1 INNER JOIN NNM1 T0 ON T0."Series"=T1."Series"
		WHERE T1."DocEntry"=:list_of_cols_val_tab_del and T1."ObjType"=13);
	WHILE MinSO <= MaxSO
	DO
	(SELECT T1."ItemCode" into SOItemCode FROM DRF1 T1 LEFT JOIN ODRF T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO and T0."ObjType"=13);
	(SELECT T1."Dscription" into SOName FROM DRF1 T1 WHERE T1."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);
	(SELECT T1."FreeTxt" into Freetext FROM DRF1 T1 LEFT JOIN ODRF T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO and T0."ObjType"=13);
	select "U_Agro_Chem" into U_Agro_Chem from oitm where "ItemCode" = SOItemCode;
	select "U_Per_HM_CR" into U_Per_HM_CR from oitm where "ItemCode" = SOItemCode;
	select "U_Food" into U_Food from oitm where "ItemCode"= SOItemCode;
	select "U_Paints_Pigm" into U_Paints_Pigm from oitm where "ItemCode"= SOItemCode;
	select "U_Indus_Care" into U_Indus_Care from oitm where "ItemCode"= SOItemCode;
	select "U_Lube_Additiv" into U_Lube_Additiv from oitm where "ItemCode"= SOItemCode;
	select "U_Textile" into U_Textile from oitm where "ItemCode"= SOItemCode;
	select "U_Oil_Gas" into U_Oil_Gas  from oitm where "ItemCode"= SOItemCode;
	select "U_CAS_No" into U_CAS_No  from oitm where "ItemCode"= SOItemCode;
	select "U_Other1" into U_Other1  from oitm where "ItemCode"= SOItemCode;
	select "U_Other2" into U_Other2  from oitm where "ItemCode"= SOItemCode;
	select "U_Pharma" into U_Pharma  from oitm where "ItemCode"= SOItemCode;
	select "U_Mining" into U_Mining  from oitm where "ItemCode"= SOItemCode;

		IF Series NOT LIKE 'CL%' then
		IF (SOItemCode NOT LIKE 'SC%' AND SOItemCode NOT LIKE 'PCPM%' AND SOItemCode NOT LIKE 'WSTG%' AND SOItemCode NOT LIKE 'FA%' AND SOItemCode <> 'PCFG0406') THEN
			IF SOName = Freetext then
			else
				IF Freetext = U_Agro_Chem then
				else
					IF Freetext = U_Per_HM_CR then
					else
						IF Freetext = U_Food then
						else
							IF Freetext = U_Paints_Pigm then
							else
								IF Freetext = U_Indus_Care then
								else
									IF Freetext = U_Textile then
									else
										IF Freetext = U_Lube_Additiv then
										else
											IF Freetext = U_Oil_Gas then
											else
												IF Freetext = U_CAS_No then
												else
													IF Freetext = U_Other1 then
													else
														IF Freetext = U_Other2 then
														else
															IF Freetext = U_Pharma then
															else
																IF Freetext = U_Mining then
																else
																	error:=1808;
																	error_message:=N'Please Select Proper Alias Name in Invoice (Alias Name not in master)';
																END IF;
															END IF;
														END IF;
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
		END IF;
	 MinSO=MinSO+1;
	END WHILE;
END IF;
END IF;

----------------- Alias name not match--------

IF Object_type='112' and (:transaction_type ='A' OR :transaction_type = 'U') Then
DECLARE MinSO int;
DECLARE MaxSO int;
DECLARE SOItemCode nvarchar(50);
DECLARE SOName nvarchar(100);
DECLARE FreetextAR nvarchar(50);
DECLARE FreetextDL nvarchar(50);
DECLARE ARSeries nvarchar(50);
DECLARE ARbstype varchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN

	(SELECT min(T0."VisOrder") Into MinSO FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxSO FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT T0."SeriesName" into ARSeries FROM ODRF T1 INNER JOIN NNM1 T0 ON T0."Series"=T1."Series"
		WHERE T1."DocEntry"=:list_of_cols_val_tab_del and T1."ObjType"=13);
	WHILE MinSO <= MaxSO
	DO
	(SELECT T1."ItemCode" into SOItemCode FROM DRF1 T1 LEFT JOIN ODRF T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO and T0."ObjType"=13);
	--(SELECT T1."Dscription" into SOName FROM DRF1 T1 WHERE T1."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);

	(SELECT T1."FreeTxt" into FreetextAR FROM DRF1 T1 LEFT JOIN ODRF T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO and T0."ObjType"=13);
	Select DRF1."BaseType" into ARbstype from DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder" =  MinSO;
		IF ARSeries NOT LIKE 'CL%' and ARbstype = '15' then

	select T1."FreeTxt" into FreetextDL FROM DLN1 T1 LEFT OUTER JOIN ODLN T2 ON T1."DocEntry" = T2."DocEntry"
		LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
		AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
		WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MinSO and T4."ObjType"=13;


			IF (SOItemCode NOT LIKE 'SC%' AND SOItemCode NOT LIKE 'PCPM%') THEN
					IF FreetextDL <> FreetextAR then
						error:=1809;
						error_message:=N'Alias name not match with Delivery';
					END IF;
			END IF;
		END IF;
	 MinSO=MinSO+1;
	END WHILE;
END IF;
END IF;

IF Object_type='112' and (:transaction_type ='A' OR :transaction_type = 'U') Then
DECLARE MinSO int;
DECLARE MaxSO int;
DECLARE SOItemCode nvarchar(50);
DECLARE SOName nvarchar(100);
DECLARE FreetextAR nvarchar(50);
DECLARE FreetextDL nvarchar(50);
DECLARE ARSeries nvarchar(50);
DECLARE ARbstype varchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN

	(SELECT min(T0."VisOrder") Into MinSO FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxSO FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT T0."SeriesName" into ARSeries FROM ODRF T1 INNER JOIN NNM1 T0 ON T0."Series"=T1."Series"
		WHERE T1."DocEntry"=:list_of_cols_val_tab_del and T1."ObjType"=13);
	WHILE MinSO <= MaxSO
	DO
	(SELECT T1."ItemCode" into SOItemCode FROM DRF1 T1 LEFT JOIN ODRF T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO and T0."ObjType"=13);
	--(SELECT T1."Dscription" into SOName FROM DRF1 T1 WHERE T1."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO);
	(SELECT T1."FreeTxt" into FreetextAR FROM DRF1 T1 LEFT JOIN ODRF T0 ON T0."DocEntry"=T1."DocEntry"
		WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND T1."VisOrder"=MinSO and T0."ObjType"=13);
	Select DRF1."BaseType" into ARbstype from DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder" =  MinSO;
		IF ARSeries NOT LIKE 'CL%' and ARbstype = '17' then

	select T1."FreeTxt" into FreetextDL FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
		LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
		AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
		WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MinSO and T4."ObjType"=13;


			IF (SOItemCode NOT LIKE 'SC%' AND SOItemCode NOT LIKE 'PCPM%') THEN
					IF FreetextDL <> FreetextAR then
						error:=1810;
						error_message:=N'Alias name not match with Sales order';
					END IF;
			END IF;
		END IF;
	 MinSO=MinSO+1;
	END WHILE;
END IF;
END IF;

--------------------------------------------------------------

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE GRPOIC Nvarchar(50);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE GRPOQTY INT;
DECLARE GRPOItem Nvarchar(50);
DECLARE Series Nvarchar(50);
DECLARE GRPOWhs Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinLinePDQ<=MaxLinePDQ DO
		SELECT DRF1."U_UNE_QTY" INTO GRPOQTY FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT DRF1."ItemCode" INTO GRPOItem FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT DRF1."WhsCode" INTO GRPOWhs FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;

		IF GRPOItem <> 'PCRM0018' and GRPOWhs NOT IN ('GJCM','PDI','ADVP','SSPL') then
			IF GRPOItem LIKE '%RM%' then
				IF GRPOQTY = 0 then
					error :=189;
					error_message := N'Please Enter Kanta chiththi no....';
				END IF;
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE MinGR Int;
DECLARE MaxGR Int;
DECLARE DRGR Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	SELECT Min(T0."VisOrder") INTO MinGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGR <= :MaxGR DO
		SELECT DRF1."OcrCode" into DRGR FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGR;
		IF DRGR IS NULL OR DRGR = '' then
			error :=203;
			error_message := N'Select Distribution rule';
		END IF;
		MinGR := MinGR+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE PMGRN Nvarchar(50);
DECLARE PMQTY decimal;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGRN <= :MaxGRN DO
		SELECT DRF1."ItemCode" into PMGRN FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGRN;
		SELECT SUBSTR_AFTER(DRF1."Quantity",'.') into PMQTY FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGRN;
		IF PMGRN LIKE '%PM%' then
			IF 	PMQTY > 0 then
				error :=204;
				error_message := N'Decimal not allowed for Packing';
			END IF;
		END IF;
		MinGRN := MinGRN+1;
	END WHILE;
END IF;
END IF;

IF object_type = '112' and (:transaction_type = 'A' or :transaction_type = 'U') THEN

	Declare BASEDOCNO int;
	Declare SOQTY int;
	Declare APQTY int;
	Declare ITEMCODE  varchar(50);
	Declare BASECODE  varchar(50);
	Declare BASETYPE  varchar(50);
	Declare Countt int;
	DECLARE MINN int;
	DECLARE MAXX int;
	Declare APSeries  varchar(50);
	Declare APCC  varchar(50);
	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
	Select MIN(T0."VisOrder") into MINN from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXX from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into APSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=18;
	SELECT T0."CardCode" into APCC FROM ODRF T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=18;

	IF APSeries NOT LIKE 'CL%' then
			WHILE MINN<=MAXX DO
					Select T0."U_BASEDOCNO" into BASEDOCNO from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINN;

					Select T0."U_UNE_ITCD" into BASECODE from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINN;

					select SUM("Quantity") INTO SOQTY from INV1 INNER JOIN OINV ON OINV."DocEntry" = INV1."DocEntry" WHERE OINV."DocNum" = BASEDOCNO and INV1."ItemCode" = BASECODE;

					select "Quantity" INTO APQTY from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINN;

					IF APQTY > SOQTY THEN
						error:='215';
						error_message :='AP Qty greater than AR Qty. ';
					END IF;
				 MINN = MINN + 1;
			END WHILE;
	END IF;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	DECLARE Qty double;
	DECLARE AQty double;
	Declare Series nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	select "SeriesName" into Series FROM ODRF T0 INNER JOIN NNM1 T1 ON T1."Series" = T0."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13;
	IF Series NOT LIKE 'CL%' then
	select SUM(T1."Quantity") into Qty FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del;
	select SUM(T2."U_ActualQty") into AQty FROM DRF7 T2  WHERE T2."DocEntry"= :list_of_cols_val_tab_del;

	IF Qty IS NOT NULL THEN
		IF Qty <> AQty THEN
			error:='218';
			error_message :='Invoice and packing slip quantity is not matched';
		END IF;
	END IF;
	END IF;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A') then
	Declare PrtLoad nvarchar(50);
	Declare Series nvarchar(50);
	Declare Prtno int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	select "SeriesName" into Series FROM ODRF T0 INNER JOIN NNM1 T1 ON T1."Series" = T0."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13;
	select "U_PLoad" into PrtLoad FROM ODRF T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."ObjType"=13;
	select count("U_PortName") into Prtno from "@PORTMASTER" T2 WHERE T2."U_PortName" = PrtLoad;

	IF Series LIKE 'E%' then
		IF Prtno <> 1 THEN
			error:='220';
			error_message :='Please select proper port of loading';
		END IF;
	END IF;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A') then
	Declare PrtLoad nvarchar(100);
	Declare Series nvarchar(50);
	Declare Prtno int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 203
THEN
	select "SeriesName" into Series FROM ODRF T0 INNER JOIN NNM1 T1 ON T1."Series" = T0."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=203;
	select "U_PLoad" into PrtLoad FROM ODRF T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."ObjType"=203;
	select count(*) into Prtno  from "@PORTMASTER" T2 WHERE T2."U_PortName" = PrtLoad;
	IF Series LIKE 'E%' then
		IF Prtno <> 1 THEN
			error:='221';
			error_message :='Please select proper port of loading';
		END IF;
	END IF;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A') then
	Declare Prtdschrge nvarchar(50);
	Declare Series nvarchar(50);
	Declare Prtno int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	select "U_PDischrg" into Prtdschrge FROM ODRF T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."ObjType"=13;
	select "SeriesName" into Series FROM ODRF T0 INNER JOIN NNM1 T1 ON T1."Series" = T0."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13;
	select count("U_PortName") into Prtno from "@PORTMASTER" T2 WHERE T2."U_PortName" = Prtdschrge;

	IF Series LIKE 'E%' then
		IF Prtno <> 1 THEN
			error:='222';
			error_message :='Please select proper port of discharge';
		END IF;
	END IF;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	Declare Prtdschrge nvarchar(100);
	Declare Series nvarchar(50);
	Declare Prtno int;
	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 203
THEN
	select "SeriesName" into Series FROM ODRF T0 INNER JOIN NNM1 T1 ON T1."Series" = T0."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=203;
	select "U_PDischrg" into Prtdschrge FROM ODRF T0  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=203;
	select count(*) into Prtno  from "@PORTMASTER" T2 WHERE T2."U_PortName" = Prtdschrge;

	IF Series LIKE 'E%' then
		IF Prtno <> 1 THEN
			error:='223';
			error_message :='Please select proper port of discharge';
		END IF;
	END IF;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	Declare Inco nvarchar(50);
	Declare Series nvarchar(50);
	Declare Prtno int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	select "SeriesName" into Series FROM ODRF T0 INNER JOIN NNM1 T1 ON T1."Series" = T0."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13;
	select "U_Incoterms" into Inco FROM ODRF T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."ObjType"=13;
	select count("U_PortName") into Prtno from "@INCOTERMMASTER" T2 WHERE T2."U_PortName" = Inco;

	IF Series LIKE 'E%' then
		IF Prtno <> 1 THEN
			error:='224';
			error_message :='Please select proper Inco term';
		END IF;
	END IF;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then
	Declare Inco nvarchar(100);
	Declare Series nvarchar(50);
	Declare Prtno int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 203
THEN
	select "SeriesName" into Series FROM ODRF T0 INNER JOIN NNM1 T1 ON T1."Series" = T0."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=203;
	select "U_Incoterms" into Inco FROM ODRF T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."ObjType"=203;
	select count(*) into Prtno  from "@INCOTERMMASTER" T2 WHERE T2."U_PortName" = Inco;

	IF Series LIKE 'E%' then
		IF Prtno <> 1 THEN
			error:='225';
			error_message :='Please select proper Inco term';
		END IF;
	END IF;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A') then

	DECLARE Whsee nvarchar(50);
	DECLARE Return1 nvarchar(50);
	DECLARE date1 nvarchar(50);
	DECLARE date2 nvarchar(50);
	DECLARE date3 nvarchar(50);
	DECLARE date4 nvarchar(50);
	DECLARE Challan1 int;
	DECLARE Challan2 int;
	DECLARE Challan3 int;
	DECLARE Challan4 int;
	DECLARE SC1 nvarchar(50);
	DECLARE Challanqty1 int;
	DECLARE Challanqty2 int;
	DECLARE Challanqty3 int;
	DECLARE Challanqty4 int;
	DECLARE SC1Dt nvarchar(50);
	DECLARE MINN int;
	DECLARE MAXX int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 15
THEN
	Select MIN(T0."VisOrder") into MINN from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXX from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

		WHILE MINN<=MAXX DO
			select T1."WhsCode" into Whsee FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_Return" into Return1 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select OWHS."U_UNE_JAPP" into Whsee from DRF1 INNER JOIN OWHS ON DRF1."WhsCode" = OWHS."WhsCode" where DRF1."DocEntry"=list_of_cols_val_tab_del and DRF1."VisOrder"=MINN;
			select T1."U_JobChallan1" into Challan1 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JobChallan2" into Challan2 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JobChallan3" into Challan3 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JobChallan4" into Challan4 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty1" into Challanqty1 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty2" into Challanqty2 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty3" into Challanqty3 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty4" into Challanqty4 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate" into date1 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate2" into date2 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate3" into date3 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate4" into date4 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_Schln1" into SC1 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_Schld1" into SC1Dt FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;

			IF Whsee = 'Y' and Return1 = 'Yes' THEN
				IF Challan1 IS NULL then
					error:='230';
					error_message :='Please Enter jobwork challan no1';
				End IF;
				IF Challanqty1 IS NULL then
					error:='230';
					error_message :='Please Enter jobwork challan Quantity1';
				End IF;
				IF date1 IS NULL then
					error:='230';
					error_message :='Please Enter jobwork challan Date1';
				End IF;
				IF SC1 IS NULL then
					error:='230';
					error_message :='Please Enter Subsidary no1';
				End IF;
				IF SC1Dt IS NULL then
					error:='230';
					error_message :='Please Enter Subsidary date1';
				End IF;
				IF Challan2 IS NOT NULL then
					IF Challanqty2 IS NULL THEN
						error:='230';
						error_message :='Please Enter jobwork challan Quantity2';
					END IF;
					IF date2 IS NULL THEN
						error:='230';
						error_message :='Please Enter jobwork challan date2';
					END IF;
				End IF;
				IF Challan3 IS NOT NULL then
					IF Challanqty3 IS NULL THEN
						error:='230';
						error_message :='Please Enter jobwork challan Quantity3';
					END IF;
					IF date3 IS NULL THEN
						error:='230';
						error_message :='Please Enter jobwork challan date3';
					END IF;
				End IF;
				IF Challan4 IS NOT NULL then
					IF Challanqty4 IS NULL THEN
						error:='230';
						error_message :='Please Enter jobwork challan Quantity4';
					END IF;
					IF date4 IS NULL THEN
						error:='230';
						error_message :='Please Enter jobwork challan date4';
					END IF;
				End IF;
			END IF;
			MINN = MINN + 1;
		END WHILE;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A') then

	DECLARE Whsee nvarchar(50);
	DECLARE Return1 nvarchar(50);
	DECLARE date1 nvarchar(50);
	DECLARE date2 nvarchar(50);
	DECLARE date3 nvarchar(50);
	DECLARE date4 nvarchar(50);
	DECLARE Challan1 int;
	DECLARE Challan2 int;
	DECLARE Challan3 int;
	DECLARE Challan4 int;
	DECLARE SC1 int;
	DECLARE Challanqty1 int;
	DECLARE Challanqty2 int;
	DECLARE Challanqty3 int;
	DECLARE Challanqty4 int;
	DECLARE SC1Dt date;
	DECLARE MINN int;
	DECLARE MAXX int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	Select MIN(T0."VisOrder") into MINN from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXX from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

		WHILE MINN<=MAXX DO
			select T1."U_Return" into Return1 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."WhsCode" into Whsee FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JobChallan1" into Challan1 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JobChallan2" into Challan2 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JobChallan3" into Challan3 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JobChallan4" into Challan4 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate" into date1 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate2" into date2 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate3" into date3 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWDate4" into date4 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty1" into Challanqty1 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty2" into Challanqty2 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty3" into Challanqty3 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_JWQty4" into Challanqty4 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_Schln1" into SC1 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select T1."U_Schld1" into SC1Dt FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;

			IF Return1 = 'Yes' THEN
				IF Challan1 IS NULL then
					error:='231';
					error_message :='Please Enter jobwork challan no1';
				End IF;
				IF  Challanqty1 IS NULL then
					error:='231';
					error_message :='Please Enter jobwork challan Quantity1';
				End IF;
				IF date1 IS NULL then
					error:='231';
					error_message :='Please Enter jobwork challan Date1';
				End IF;
				IF SC1 IS NULL then
					error:='231';
					error_message :='Please Enter Subsidary no1';
				End IF;
				IF SC1Dt IS NULL then
					error:='231';
					error_message :='Please Enter Subsidary date1';
				End IF;
				IF Challan2 IS NOT NULL and Challan2 >0 then
					IF Challanqty2 IS NULL THEN
						error:='105';
						error_message :='Please Enter jobwork challan Quantity2';
					END IF;
					IF date2 IS NULL THEN
						error:='231';
						error_message :='Please Enter jobwork challan date2';
					END IF;
				End IF;
				IF Challan3 IS NOT NULL  and Challan3 >0 then
					IF Challanqty3 IS NULL THEN
						error:='231';
						error_message :='Please Enter jobwork challan Quantity3';
					END IF;
					IF date3 IS NULL THEN
						error:='231';
						error_message :='Please Enter jobwork challan date3';
					END IF;
				End IF;
				IF Challan4 IS NOT NULL and Challan4 >0 then
					IF Challanqty4 IS NULL THEN
						error:='231';
						error_message :='Please Enter jobwork challan Quantity4';
					END IF;
					IF date4 IS NULL THEN
						error:='231';
						error_message :='Please Enter jobwork challan date4';
					END IF;
				End IF;
			END IF;
			MINN = MINN + 1;
		END WHILE;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE Return1 nvarchar(50);
	DECLARE Whsee nvarchar(50);
	DECLARE MINN int;
	DECLARE MAXX int;
	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	Select MIN(T0."VisOrder") into MINN from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXX from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

		WHILE MINN<=MAXX DO
			select T1."U_Return" into Return1 FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;
			select OWHS."U_UNE_JAPP" into Whsee from DRF1 INNER JOIN OWHS ON DRF1."WhsCode" = OWHS."WhsCode" where DRF1."DocEntry"=list_of_cols_val_tab_del and DRF1."VisOrder"=MINN;

			IF Whsee = 'Y' then
				IF Return1 IS NULL OR Return1 = '' THEN
					error:='232';
					error_message :='Please Select return or not';
				END IF;
			END IF;
			MINN = MINN + 1;
		END WHILE;
END IF;
END IF;


IF Object_type = '112' and (:transaction_type ='A') Then

Declare dayss int;
Declare foter nvarchar(250);
Declare Srs nvarchar(250);
Declare Base int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	select distinct DAYS_BETWEEN(t4."DocDate",CURRENT_DATE) into dayss from ODRF t4 where  t4."DocEntry"=list_of_cols_val_tab_del and T4."ObjType"=13;
	select t5."SeriesName" into Srs from ODRF t4 INNER JOIN NNM1 t5 ON t5."Series" = t4."Series" where  t4."DocEntry"=list_of_cols_val_tab_del and T4."ObjType"=13;

		IF (dayss <> 0) and Srs NOT LIKE 'CL%' then
			error :=233;
			error_message := N'You are not allowed to create invoice in other than todays date';
		End If;

END IF;
END IF;
IF Object_type = '112' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare dayss int;
Declare foter nvarchar(250);
Declare Base int;
Declare date1 nvarchar(250);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN
	select distinct DAYS_BETWEEN(t4."DocDate",t4."U_UNE_CHDT") into dayss from ODRF t4 where  t4."DocEntry"=list_of_cols_val_tab_del and T4."ObjType"=67;
	select  t4."U_UNE_CHDT" into date1 from ODRF t4 where t4."DocEntry"=list_of_cols_val_tab_del and T4."ObjType"=67;

		IF date1 IS NOT NULL THEN
			IF (dayss > 0) then
				error :=234;
				error_message := N'Error1';
			End If;
		END IF;

END IF;
END IF;

IF Object_type = '112' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare dayss int;
Declare foter nvarchar(250);
Declare Srs nvarchar(250);
Declare Base int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	select distinct DAYS_BETWEEN(t4."DocDate",t4."U_UNE_CHDT") into dayss from ODRF t4 where  t4."DocEntry"=list_of_cols_val_tab_del and T4."ObjType"=13;
	select t5."SeriesName" into Srs from ODRF t4 INNER JOIN NNM1 t5 ON t5."Series" = t4."Series" where  t4."DocEntry"=list_of_cols_val_tab_del and T4."ObjType"=13;

		IF (dayss > 0) and Srs NOT LIKE 'CL%' then
			error :=235;
			error_message := N'Error2';
		End If;

END IF;
END IF;

IF Object_type = '112' and (:transaction_type ='A' OR :transaction_type ='U') Then

Declare Pterm nvarchar(250);
Declare Pdcdate nvarchar(250);
Declare Pdcchqno nvarchar(250);
Declare advanceno nvarchar(250);
Declare dominvoice int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	select T0."U_PDCDate" into Pdcdate from ODRF T0 where T0."DocEntry"=list_of_cols_val_tab_del and T0."ObjType"=13;
	select T0."U_PDCChequeNo" into Pdcchqno from ODRF T0 where T0."DocEntry"=list_of_cols_val_tab_del and T0."ObjType"=13;
	select T0."U_AdvanceNo" into advanceno from ODRF T0 where T0."DocEntry"=list_of_cols_val_tab_del and T0."ObjType"=13;
	select T1."PymntGroup" into Pterm from ODRF T0  INNER JOIN OCTG T1 ON T0."GroupNum" = T1."GroupNum"
		where T0."DocEntry"=list_of_cols_val_tab_del and T0."ObjType"=13;
	select T0."DocRate" into dominvoice from ODRF T0  where T0."DocEntry"=list_of_cols_val_tab_del and T0."ObjType"=13;

	IF Pterm LIKE '%PDC%' then
		IF Pdcchqno IS NULL OR Pdcchqno = '' then
			error :=236;
			error_message := N'Please enter PDC Cheque no';
		End If;
		IF Pdcdate IS NULL OR Pdcdate = '' then
			error :=236;
			error_message := N'Please enter PDC Date';
		End If;
	End If;
	IF Pterm LIKE '%Advance%' then
		IF advanceno IS NULL OR advanceno = '' then
			error :=236;
			error_message := N'Please enter Advance Cheque no';
		End If;
		IF Pdcdate IS NULL OR Pdcdate = '' then
			error :=236;
			error_message := N'Please enter Advance Date';
		End If;
	End If;

END IF;
END IF;


IF Object_type = '112' and (:transaction_type ='A' OR :transaction_type ='U') Then
Declare InvDet Int;
Declare InvDetCount int;
Declare Dlremark varchar(500);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 15 THEN

	select top 1 Count(DAYS_BETWEEN(T2."InDate",T11."DocDate")) INTO InvDetCount  from IBT1 T1 INNER JOIN OIBT T2 ON T1."BatchNum" = T2."BatchNum" and T1."ItemCode" = T2."ItemCode"
	INNER JOIN DRF1 T10 ON T1."BaseEntry" = T10."DocEntry" and T1."BaseType" = T10."ObjType"
	and T1."BaseLinNum" = T10."LineNum" and T1."ItemCode" = T10."ItemCode"
	INNER JOIN ODRF T11 ON T11."DocEntry" = T10."DocEntry"
	WHERE T11."DocEntry" = list_of_cols_val_tab_del and T11."ObjType"=15;

	if InvDetCount>0
	THEN
	select top 1 DAYS_BETWEEN(T2."InDate",T11."DocDate") INTO InvDet  from IBT1 T1 INNER JOIN OIBT T2 ON T1."BatchNum" = T2."BatchNum" and T1."ItemCode" = T2."ItemCode"
	INNER JOIN DRF1 T10 ON T1."BaseEntry" = T10."DocEntry" and T1."BaseType" = T10."ObjType"
	and T1."BaseLinNum" = T10."LineNum" and T1."ItemCode" = T10."ItemCode"
	INNER JOIN ODRF T11 ON T11."DocEntry" = T10."DocEntry"
	WHERE T11."DocEntry" = list_of_cols_val_tab_del and T11."ObjType"=15;
	END IF;

	select T11."U_RMKSTR" INTO Dlremark  from ODRF T11 WHERE T11."DocEntry" = list_of_cols_val_tab_del and T11."ObjType"=15;

	IF InvDet > 0  THEN
		IF Dlremark IS NULL THEN
		error :=240;
		error_message := N'Please Enter Invoice delay remark in delivery';
		END IF;
	End If;

END IF;
END IF;


If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE Icode nvarchar(50);
	DECLARE Whs nvarchar(50);
	DECLARE MINN int;
	DECLARE MAXX int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	Select MIN(T0."VisOrder") into MINN from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXX from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

		WHILE MINN<=MAXX DO
			select T1."ItemCode" into Icode FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;

			select T1."WhsCode" into Whs FROM DRF1 T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."VisOrder" = MINN;

			IF Icode <> 'SCRM0016' THEN
				IF Icode LIKE 'SC%' and Whs LIKE '%PC%' then
					error:='242';
					error_message := 'Warehouse selection error.pls coordinate SAP team.';
				END IF;
				IF Icode LIKE 'PC%' and Whs LIKE 'SC%' then
					error:='242';
					error_message := 'Warehouse selection error.pls coordinate SAP team.';
				END IF;
			END IF;
			MINN = MINN + 1;
		END WHILE;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE Icode nvarchar(50);
	DECLARE LCLFCL nvarchar(50);
	DECLARE Series1 nvarchar(50);
	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	select T1."U_UNE_FGRF" into LCLFCL FROM ODRF T1 WHERE T1."DocEntry"= :list_of_cols_val_tab_del and T1."ObjType"=13;
	select T1."SeriesName" into Series1 FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13;

	IF Series1 LIKE 'E%' then
			IF LCLFCL IS NULL then
			error:='243';
			error_message :='PLease enter LCL/FCL for invoice : ';
			END IF;
			IF LCLFCL NOT IN('FCL','LCL') then
			error:='243';
			error_message :='PLease enter LCL/FCL for invoice : ';
			END IF;
		END IF;
	END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE DLQTD Int;
DECLARE MinLineDLQ Int;
DECLARE MaxLineDLQ Int;
DECLARE SOQTB Int;
DECLARE ItemCD Nvarchar(50);
DECLARE DOCTP Nvarchar (50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 15 THEN
	SELECT Min(T0."VisOrder") INTO MinLineDLQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineDLQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE MinLineDLQ<=MaxLineDLQ DO
		SELECT Distinct (DRF1."Quantity") INTO DLQTD FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLineDLQ ;
		SELECT Distinct (DRF1."BaseOpnQty") INTO SOQTB FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLineDLQ ;
		SELECT Distinct (DRF1."ItemCode") INTO ItemCD FROM DRF1 where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLineDLQ ;
		SELECT Distinct (ODRF."DocType") INTO DOCTP FROM ODRF Inner JOIN DRF1 ON ODRF."DocEntry"=DRF1."DocEntry" Where ODRF."DocEntry" =:list_of_cols_val_tab_del and ODRF."ObjType"=15 ;

		IF DOCTP = 'I' And (DLQTD > SOQTB) THEN
			error :=247;
			error_message := N'Delivery Qty. should not greater then S.O Qty...!'||ItemCD;
		END IF;

		MinLineDLQ := MinLineDLQ+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN

DECLARE ARQTD Int;
DECLARE MinLineARQ Int;
DECLARE MaxLineARQ Int;
DECLARE SOQTB Int;
DECLARE Itm varchar(50);
DECLARE ARSeries varchar(50);
DECLARE DocTyp varchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	SELECT Min(T0."VisOrder") INTO MinLineARQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLineARQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into ARSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13;

	  Select ODRF."DocType" into DocTyp from ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=13;

	IF DocTyp = 'I' then
		WHILE :MinLineARQ<=MaxLineARQ DO

			SELECT Distinct (DRF1."Quantity") INTO ARQTD FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLineARQ ;
			SELECT Distinct (DRF1."BaseOpnQty") INTO SOQTB FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLineARQ ;
			Select OITM."InvntItem" into Itm from DRF1 INNER JOIN OITM ON DRF1."ItemCode" = OITM."ItemCode" WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder" =  MinLineARQ;

			IF Itm = 'N' and ARSeries NOT LIKE 'CL%' then
				IF SOQTB > 0 THEN
					IF  (ARQTD > SOQTB) THEN
						error :=248;
						error_message := 'AR Qty. should not greater then S.O Qty.... Line No'||MinLineARQ;
					END IF;
				END IF;
			END IF;
			MinLineARQ := MinLineARQ+1;
		END WHILE;
	END IF;
END IF;
END IF;

---------------------Price diff in sales-------------------

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE SOUNITPRICE varchar(50);
	DECLARE SOUNITPRICECount int;
	DECLARE DLUNITPRICE varchar(50);
	DECLARE DLUNITPRICECount int;
	DECLARE MINNDL int;
	DECLARE MAXXDL int;
	DECLARE DLSeries varchar(50);
	DECLARE DLCode varchar(50);
	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 15
THEN
	Select MIN(T0."VisOrder") into MINNDL from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXDL from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into DLSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=15;
	IF DLSeries NOT LIKE 'CL%' then
		WHILE MINNDL<=MAXXDL
		DO
			select T0."ItemCode" into DLCode from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINNDL;

			IF DLCode NOT LIKE 'PCPM%' THEN
			select Count(ifnull(T1."Price",0)) into SOUNITPRICECount FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNDL and T4."ObjType"=15;

			if SOUNITPRICECount>0
			THEN
				select T1."Price" into SOUNITPRICE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNDL and T4."ObjType"=15;

			END IF;

				select Count(ifnull(T3."Price",0)) into DLUNITPRICECount FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNDL and T4."ObjType"=15;

				if DLUNITPRICECount>0
				THEN
				select T3."Price" into DLUNITPRICE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNDL and T4."ObjType"=15;
				END IF;

				IF SOUNITPRICE IS NOT NULL THEN
					IF SOUNITPRICE != DLUNITPRICE THEN
						error:='249';
						error_message :='Price difference. Line No'||MINNDL;
					END IF;
				END IF;
			END IF;
			MINNDL = MINNDL + 1;
		END WHILE;
	END IF;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE DLUNITPRICE varchar(50);
	DECLARE ARUNITPRICE varchar(50);
	DECLARE MINNAR int;
	DECLARE MAXXAR int;
	DECLARE Itms varchar(50);
	DECLARE ARSeries varchar(50);
	DECLARE ARbstype varchar(50);
	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	Select MIN(T0."VisOrder") into MINNAR from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAR from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into ARSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13;

	WHILE MINNAR<=MAXXAR
	DO
		Select DRF1."BaseType" into ARbstype from DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder" =  MINNAR;
		IF ARSeries NOT LIKE 'CL%' and ARbstype = '15' then
			select T1."Price" into DLUNITPRICE FROM DLN1 T1 LEFT OUTER JOIN ODLN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR and T4."ObjType"=13;

			select T3."Price" into ARUNITPRICE FROM DLN1 T1 LEFT OUTER JOIN ODLN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR and T4."ObjType"=13;

			IF DLUNITPRICE IS NOT NULL THEN
				IF DLUNITPRICE != ARUNITPRICE THEN
					error:='250';
					error_message :='Price difference. Line No';
				END IF;
			END IF;
		END IF;
		MINNAR = MINNAR + 1;
	END WHILE;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE DLUNITPRICE varchar(50);
	DECLARE ARUNITPRICE varchar(50);
	DECLARE MINNAR int;
	DECLARE MAXXAR int;
	DECLARE Itms varchar(50);
	DECLARE ARSeries varchar(50);
	DECLARE ARbstype varchar(50);
	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	Select MIN(T0."VisOrder") into MINNAR from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAR from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into ARSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13;

	WHILE MINNAR<=MAXXAR
	DO
		Select DRF1."BaseType" into ARbstype from DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder" =  MINNAR;
		IF ARSeries NOT LIKE 'CL%' and ARbstype = '17' then
			select T1."Price" into DLUNITPRICE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR and T4."ObjType"=13;

			select T3."Price" into ARUNITPRICE FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR and T4."ObjType"=13;

			IF DLUNITPRICE IS NOT NULL THEN
				IF DLUNITPRICE != ARUNITPRICE THEN
					error:='2500';
					error_message :='Price difference. Line No(Price not match with SO)';
				END IF;
			END IF;
		END IF;
		MINNAR = MINNAR + 1;
	END WHILE;
END IF;
END IF;

---------------------------------------------------

IF Object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then

Declare GateEntno nvarchar(50);
Declare GateEntDt nvarchar(50);
Declare Vehicle nvarchar(50);
Declare Series nvarchar(50);
Declare ItemCodeGRN nvarchar(50);
Declare MINNGRN Int;
Declare MAXXGRN Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
select ODRF."U_UNE_GENO" into GateEntno from ODRF  where ODRF."DocEntry"= :list_of_cols_val_tab_del and ODRF."ObjType"=20;
select ODRF."U_UNE_GEDT" into GateEntDt from ODRF where ODRF."DocEntry"=:list_of_cols_val_tab_del and ODRF."ObjType"=20;
select ODRF."U_UNE_VehicleNo" into Vehicle from ODRF where ODRF."DocEntry"=:list_of_cols_val_tab_del and ODRF."ObjType"=20;
Select MIN(T0."VisOrder") into MINNGRN from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
Select MAX(T0."VisOrder") into MAXXGRN from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

select NNM1."SeriesName" into Series FROM NNM1 INNER JOIN ODRF ON NNM1."Series" = ODRF."Series" WHERE  ODRF."DocEntry"= :list_of_cols_val_tab_del and ODRF."ObjType"=20;
	WHILE MINNGRN<=MAXXGRN
	DO
		select T1."ItemCode" into ItemCodeGRN FROM DRF1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder" = MINNGRN;

		If Series NOT LIKE 'J%' and Series NOT LIKE 'CL%' THEN
			IF ( GateEntno IS NULL OR GateEntno = '' ) then
				error :=251;
				error_message := N'Please enter Gate entry no.';
			End If;
			IF ( Vehicle IS NULL OR Vehicle = '' ) then
				error :=251;
				error_message := N'Please enter Vehicle no.';
			End If;
			IF ( GateEntDt IS NULL OR GateEntDt = '' ) then
				error :=251;
				error_message := N'Please enter Gate entry date.';
			End If;
		End If;
	MINNGRN = MINNGRN + 1;
	END WHILE;
End If;
END IF;

IF object_type='112' AND ( :transaction_type = 'A') THEN

DECLARE remark varchar(500);
DECLARE Ref varchar(50);
DECLARE Series varchar(50);
DECLARE Branch varchar(50);
DECLARE Date1 date;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	SELECT T1."Comments" INTO remark FROM ODRF T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=59;
	SELECT T0."SeriesName" INTO Series FROM ODRF T1 INNER JOIN NNM1 T0 ON T0."Series" = T1."Series" WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=59;
	SELECT T1."DocDate" INTO Date1 FROM ODRF T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=59;
	SELECT T1."Ref2" INTO Ref FROM ODRF T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=59;
	SELECT T1."BPLName" INTO Branch FROM ODRF T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=59;

	IF Series LIKE 'PC%' then
		IF Branch = 'UNIT - I' THEN
			IF (Date1 >= '20220101' and Date1 <= '20221231')  and remark NOT LIKE '2022/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20220101' and Date1 <= '20221231') and Ref NOT LIKE '2022/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and remark NOT LIKE '2021/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and Ref NOT LIKE '2021/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231')  and remark NOT LIKE '2023/U1/____' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and Ref NOT LIKE '2023/U1/____' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
		END IF;

		IF Branch = 'UNIT - II' THEN
			IF (Date1 >= '20220101' and Date1 <= '20221231')  and remark NOT LIKE '2022/U2/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20220101' and Date1 <= '20221231') and Ref NOT LIKE '2022/U2/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and remark NOT LIKE '2021/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and Ref NOT LIKE '2021/%' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231')  and remark NOT LIKE '2023/U2/____' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and Ref NOT LIKE '2023/U2/____' THEN
				error := 257;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
		END IF;
	END IF;
END IF;
END IF;

IF object_type='112' AND ( :transaction_type = 'A') THEN

DECLARE remark varchar(500);
DECLARE Ref varchar(50);
DECLARE Series varchar(50);
DECLARE Branch varchar(50);
DECLARE Date1 date;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	SELECT T0."SeriesName" INTO Series FROM ODRF T1 INNER JOIN NNM1 T0 ON T0."Series" = T1."Series" WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=60;
	SELECT T1."Comments" INTO remark FROM ODRF T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=60;
	SELECT T1."Ref2" INTO Ref FROM ODRF T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=60;
	SELECT T1."DocDate" INTO Date1 FROM ODRF T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=60;
	SELECT T1."BPLName" INTO Branch FROM ODRF T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=60;

	IF Series LIKE 'PC%' then
		IF Branch = 'UNIT - I' THEN
			IF (Date1 >= '20220101' and Date1 <= '20221231') and remark NOT LIKE '2022/%' THEN
				error := 2580;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20220101' and Date1 <= '20221231') and Ref NOT LIKE '2022/%' THEN
				error := 2581;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and remark NOT LIKE '2021/%' THEN
				error := 2582;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and Ref NOT LIKE '2021/%' THEN
				error := 2583;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and remark NOT LIKE '2023/U1/____' THEN
				error := 2584;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and Ref NOT LIKE '2023/U1/____' THEN
				error := 2585;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
		END IF;

		IF Branch = 'UNIT - II' THEN
			IF (Date1 >= '20220101' and Date1 <= '20221231') and remark NOT LIKE '2022/U2/%' THEN
				error := 2586;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20220101' and Date1 <= '20221231') and Ref NOT LIKE '2022/U2/%' THEN
				error := 2586;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and remark NOT LIKE '2021/%' THEN
				error := 2587;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF Date1 < '20220101' and Ref NOT LIKE '2021/%' THEN
				error := 2588;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and remark NOT LIKE '2023/U2/____' THEN
				error := 2589;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
			IF (Date1 >= '20230101' and Date1 <= '20231231') and Ref NOT LIKE '2023/U2/____' THEN
				error := 25801;
				error_message := 'Batch may wrong. please contact SAP team.';
			END IF;
		END IF;
	END IF;
END IF;
END IF;

IF object_type='112' AND ( :transaction_type = 'A') THEN
DECLARE MINN int;
DECLARE MAXX int;
DECLARE CNT Int;
DECLARE Comments Nvarchar(150);
DECLARE Srs Nvarchar(150);
Declare Itm nvarchar(250);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60 THEN
	Select MIN(T0."VisOrder") into MINN from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXX from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT "Ref2" INTO Comments FROM ODRF T1 where T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=60;
	SELECT T1."SeriesName" INTO Srs FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=60;
	SELECT COUNT(*) INTO CNT FROM ODRF T1 where T1."Ref2" = Comments and T1."ObjType"=60;
	WHILE MINN<=MAXX DO
		select "ItemCode" into Itm FROM DRF1 T0 WHERE T0."DocEntry"=list_of_cols_val_tab_del and T0."VisOrder" = MINN;
		IF Itm LIKE 'PC%' then
		IF :CNT>1 and Srs NOT LIKE 'SC%' and Comments IS NOT NULL THEN
			error := 265;
			error_message := 'Duplicate Batch Number Exist Check Batch No Again';
			CNT:= 0;
		END IF;
		END IF;
	MINN = MINN + 1;
	END WHILE;

END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'U' OR :transaction_type = 'A') THEN

DECLARE Pterm Nvarchar(150);
DECLARE Rate Int;
DECLARE Bsdoc Int;
DECLARE MinAR int;
DECLARE MaxAR int;
DECLARE DocNumber int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13 THEN
	(SELECT min(T0."VisOrder") Into MinAR FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxAR FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	SELECT "DocRate" INTO Rate FROM ODRF T1  where T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=13;
	SELECT UPPER("PymntGroup") INTO Pterm FROM ODRF T1 INNER JOIN OCTG T2 ON T1."GroupNum" = T2."GroupNum" where T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=13;

	IF Pterm LIKE '%ADVANCE%' and Rate = 1 THEN
		WHILE MinAR <= MaxAR
		DO
		SELECT "BaseEntry" INTO Bsdoc FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinAR;
		SELECT Count("RefDocEntr") INTO DocNumber from RCT9 T1 where T1."RefDocEntr" = Bsdoc;

			IF DocNumber = 0 THEN
				error:=275;
				error_message:=N'Error. Payment not received';
			END IF;

		MinAR=MinAR+1;
		END WHILE;
	END IF;
	IF Pterm LIKE '%Advance%' and Rate > 1 THEN
		WHILE MinAR <= MaxAR
		DO
		SELECT T2."BaseEntry" INTO Bsdoc FROM DRF1 T1 INNER JOIN DLN1 T2 ON T1."BaseEntry" = T2."DocEntry" where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinAR;
		SELECT Count("RefDocEntr") INTO DocNumber from RCT9 T1 where T1."RefDocEntr" = Bsdoc;

			IF DocNumber = 0 THEN
				error:=276;
				error_message:=N'Error. Payment not received';
			END IF;

		MinAR=MinAR+1;
		END WHILE;
	END IF;
END IF;
END IF;


IF Object_type = '112' and (:transaction_type ='A') Then
Declare Code1 nvarchar(50);
Declare UsrCod nvarchar(50);
DECLARE MinGI int;
DECLARE MaxGI int;
DECLARE CNT int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	(SELECT min(T0."VisOrder") Into MinGI FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGI FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	select OUSR."USER_CODE" into UsrCod from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign" where ODRF."DocEntry"=list_of_cols_val_tab_del and ODRF."ObjType"=60;

	WHILE MinGI <= MaxGI
	DO
		SELECT COUNT("ItemCode") INTO CNT FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGI
		and T1."BaseEntry" IS NULL;
		If UsrCod = 'prod05' AND CNT > 0 then
		SELECT "ItemCode" INTO Code1 FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGI
		and T1."BaseEntry" IS NULL;
	         IF (Code1 NOT LIKE '%PM%' ) then
	              error :=278;
	              error_message := N'Error';
	         End If;
     	End If;
     MinGI=MinGI+1;
	END WHILE;
End If;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare SPGR double;
Declare SPGI double;
Declare Srss Nvarchar(150);
Declare IC Nvarchar(150);
Declare BE int;
DECLARE MinGR int;
DECLARE MaxGR int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	(SELECT min(T0."VisOrder") Into MinGR FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGR FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	(SELECT T1."SeriesName" Into Srss FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=59);

	IF Srss LIKE '%BT%' then
		WHILE MinGR <= MaxGR
		DO
			SELECT "Price" Into SPGR FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGR;
			SELECT "BaseEntry" Into BE FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGR;
			--SELECT "ItemCode" Into IC FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGR;
			SELECT "StockPrice" Into SPGI FROM IGE1 T1 where T1."DocEntry" = BE AND T1."VisOrder"=MinGR;

			IF SPGR <> SPGI THEN
		    	error :=280;
		        error_message := N'Not match rate. please contact SAP team.'||SPGR||SPGI||MinGR;
	     	End If;
	     MinGR=MinGR+1;
		END WHILE;
	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare Srss Nvarchar(150);
Declare Whss Nvarchar(150);
DECLARE MinGR int;
DECLARE MaxGR int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	(SELECT min(T0."VisOrder") Into MinGR FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGR FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	(SELECT T1."SeriesName" Into Srss FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=59);

	IF Srss LIKE '%BT%' then
		WHILE MinGR <= MaxGR
		DO
			SELECT "WhsCode" Into Whss FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGR;

			IF Whss NOT LIKE '%BT%' THEN
		    	error :=281;
		        error_message := N'Select BT warhouse for BT Series.';
	     	End If;
	     MinGR=MinGR+1;
		END WHILE;
	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare Srss Nvarchar(150);
Declare Whss Nvarchar(150);
DECLARE MinGR int;
DECLARE MaxGR int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	(SELECT min(T0."VisOrder") Into MinGR FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGR FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	(SELECT T1."SeriesName" Into Srss FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=59);

		WHILE MinGR <= MaxGR
		DO
			SELECT "WhsCode" Into Whss FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGR;

			IF Whss LIKE '%BT%' THEN
				IF Srss NOT LIKE '%BT%' then
		    		error :=282;
		        	error_message := N'Select BT warhouse for BT Series.';
		        END IF;
	     	End If;
	     MinGR=MinGR+1;
		END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare Srss Nvarchar(150);
Declare Whss Nvarchar(150);
DECLARE MinGI int;
DECLARE MaxGI int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	(SELECT min(T0."VisOrder") Into MinGI FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGI FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	(SELECT T1."SeriesName" Into Srss FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=60);

		WHILE MinGI <= MaxGI
		DO
			SELECT "WhsCode" Into Whss FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGI;

			IF Whss LIKE '%BT%' THEN
				IF Srss NOT LIKE '%BT%' then
		    		error :=283;
		        	error_message := N'Select BT warhouse for BT Series.';
		        END IF;
	     	End If;
	     MinGI=MinGI+1;
		END WHILE;

END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare Srss Nvarchar(150);
Declare Whss Nvarchar(150);
DECLARE MinGI int;
DECLARE MaxGI int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	(SELECT min(T0."VisOrder") Into MinGI FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGI FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	(SELECT T1."SeriesName" Into Srss FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=60);

	IF Srss LIKE '%BT%' then
		WHILE MinGI <= MaxGI
		DO
			SELECT "WhsCode" Into Whss FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGI;

			IF Whss NOT LIKE '%BT%' THEN
		    	error :=284;
		        error_message := N'Select BT warhouse for BT Series.';
	     	End If;
	     MinGI=MinGI+1;
		END WHILE;
	END IF;

END IF;
END IF;



IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare ICode Nvarchar(150);
Declare QAQC Nvarchar(150);
DECLARE MinPR int;
DECLARE MaxPR int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
	(SELECT min(T0."VisOrder") Into MinPR FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxPR FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

	WHILE MinPR <= MaxPR
	DO
		SELECT "ItemCode" Into ICode FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinPR;
		SELECT "U_QCRD" Into QAQC FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinPR;

		IF ICode LIKE 'LB%' then
			IF QAQC IS NULL THEN
		    	error :=286;
		    	error_message := N'Please select purchase invoice is for R&D or QC department';
		    END IF;
		    IF QAQC = '-' THEN
		    	error :=286;
		    	error_message := N'Please select purchase invoice is for R&D or QC department';
		    END IF;
	    End If;

	    MinPR=MinPR+1;
	END WHILE;

END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare ICode Nvarchar(150);
Declare Iname Nvarchar(150);
Declare Srs Nvarchar(150);
Declare IBE int;
DECLARE MinGI int;
DECLARE MaxGI int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	(SELECT min(T0."VisOrder") Into MinGI FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGI FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

		WHILE MinGI <= MaxGI
		DO
			SELECT "ItemCode" Into ICode FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGI;
			SELECT "Dscription" Into Iname FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGI;
			SELECT NNM1."SeriesName" Into Srs FROM ODRF T1 INNER JOIN NNM1 ON NNM1."Series" = T1."Series" where T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=60;
			SELECT ifnull("BaseEntry",0) Into IBE FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGI;
			IF IBE = 0 then
				IF Srs NOT LIKE '%BT%' then
					IF ICode = 'SCPM0004' or ICode = 'SCPM0005' THEN
				    	error :=287;
				        error_message := N'Not allowed to issue Jumbo bag.';
			     	End If;
			     	IF ICode LIKE '%RM%'AND ICode <> 'SCRM0016' AND ICode <> 'PCRM0017' AND ICode <> 'SCRM0025' THEN
				    	error :=287;
				        error_message := N'Not allowed to issue RM directly. Contact SAP team';
			     	End If;
			     	IF ICode LIKE '%FG%' THEN
				    	error :=287;
				        error_message := N'Not allowed to issue FG directly. Contact SAP team';
			     	End If;
			     	IF ICode LIKE '%PM%' THEN
			     		IF Iname NOT LIKE '%Ply%' and Iname NOT LIKE '%Pallet%' and Iname NOT LIKE '%Seal%' and Iname NOT LIKE '%seal%' and Iname <> 'Box strapping roll' and Iname <> 'Stretch film' then
					    	error :=287;
					        error_message := N'Not allowed to issue PM directly. Contact SAP team';
				     	End If;
			     	End If;
		     	END IF;
	     	END IF;
	     MinGI=MinGI+1;
		END WHILE;
END IF;
END IF;


IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare ICode Nvarchar(150);
DECLARE MinGR int;
Declare DateP int;
DECLARE MaxGR int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	(SELECT min(T0."VisOrder") Into MinGR FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);
	(SELECT max(T0."VisOrder") Into MaxGR FROM DRF1 T0 where T0."DocEntry" = :list_of_cols_val_tab_del);

		WHILE MinGR <= MaxGR
		DO
			SELECT "ItemCode" Into ICode FROM DRF1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del  AND T1."VisOrder"=MinGR;
			select DAYS_BETWEEN(T0."DocDate",NOW()) INTO DateP from ODRF T0 where T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=59;
			IF ICode LIKE 'SC%' THEN
				IF  DateP > 5 THEN
		    	error :=288;
		        error_message := N'Not allowed to add receipt in back date';
		        END IF;
	     	End If;
	     	IF ICode LIKE 'PC%' THEN
				IF  DateP > 1 THEN
		    	error :=288;
		        error_message := N'Not allowed to add receipt in back date';
		        END IF;
	     	End If;
	     MinGR=MinGR+1;
		END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare Srss Nvarchar(150);
Declare VN Nvarchar(150);
Declare TN Nvarchar(150);
Declare MN Nvarchar(150);
	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	(SELECT T1."SeriesName" Into Srss FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=60);

	IF Srss LIKE '%BT%' then

		SELECT "U_UNE_VehicleNo" Into VN FROM ODRF T1 where T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=60 ;
		SELECT "U_UNE_TransportName" Into TN FROM ODRF T1 where T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=60;
		SELECT "U_Mobile_No" Into MN FROM ODRF T1 where T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=60;

		IF VN IS NULL THEN
		    error :=295;
		    error_message := N'Please enter vehicle no';
	    End If;
	    IF MN IS NULL THEN
		    error :=296;
		    error_message := N'Please enter Mobile no';
		End If;
	    IF TN IS NULL THEN
		    error :=297;
		    error_message := N'Please enter Transport name';
	    End If;

	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U')   THEN

Declare Srss Nvarchar(150);
Declare VN Nvarchar(150);
Declare TN Nvarchar(150);
Declare MN Nvarchar(150);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	(SELECT T1."SeriesName" Into Srss FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" where T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=59);

	IF Srss LIKE '%BT%' then
		SELECT "U_UNE_VehicleNo" Into VN FROM ODRF T1 where T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=59;
		SELECT "U_UNE_TransportName" Into TN FROM ODRF T1 where T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=59;
		SELECT "U_Mobile_No" Into MN FROM ODRF T1 where T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=59;

		IF VN IS NULL THEN
		    error :=298;
		    error_message := N'Please enter vehicle no';
	    End If;
	    IF MN IS NULL THEN
		    error :=299;
		    error_message := N'Please enter Mobile no';
	   	End If;
	   		IF TN IS NULL THEN
		    error :=300;
		    error_message := N'Please enter Transport name';
	    	End If;
		END IF;
	END IF;
END IF;

IF object_type IN('112','112','112') AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE PTerm nvarchar(500);

		IF object_type = '112' then
		(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 22 THEN
			SELECT T1."PymntGroup" into PTerm FROM ODRF T0 INNER JOIN OCTG T1 ON T0."GroupNum" = T1."GroupNum" WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=22;
		END IF;
		END IF;
		IF object_type = '112' then
		(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 17 THEN
			SELECT T1."PymntGroup" into PTerm FROM ODRF T0 INNER JOIN OCTG T1 ON T0."GroupNum" = T1."GroupNum" WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=17;
		END IF;
		END IF;
		IF object_type = '112' then
		(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13 THEN
			SELECT T1."PymntGroup" into PTerm FROM ODRF T0 INNER JOIN OCTG T1 ON T0."GroupNum" = T1."GroupNum" WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=13;
		END IF;
		END IF;
		IF object_type = '112' then
		(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18 THEN
			SELECT T1."PymntGroup" into PTerm FROM ODRF T0 INNER JOIN OCTG T1 ON T0."GroupNum" = T1."GroupNum" WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=18;
		END IF;
		END IF;

		IF PTerm LIKE '%UNUSED%' THEN
			error :=308;
			error_message := N'Do not select unused payment term ';
		END IF;
END IF;

------------------------ Sales and A/R invoice should be of same branch-----------

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE BaseEntry Int;
DECLARE BRIN Int;
DECLARE BRS nvarchar(50);
DECLARE BROR Int;
DECLARE BRORCount Int;

(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	SELECT Min(T0."VisOrder") INTO MinIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."BPLId" into BRIN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=13;
	SELECT NNM1."SeriesName" into BRS FROM ODRF INNER JOIN NNM1 ON NNM1."Series" = ODRF."Series" WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=13;

	IF BRS LIKE 'D%' then
	WHILE :MinIN <= :MaxIN DO

		SELECT DRF1."BaseEntry" into BaseEntry FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;

		SELECT Count(ORDR."BPLId") into BRORCount FROM ORDR WHERE ORDR."DocEntry" = BaseEntry;
		if BRORCount>0
		THEN
		SELECT ORDR."BPLId" into BROR FROM ORDR WHERE ORDR."DocEntry" = BaseEntry;
		END IF;

		IF BRIN <> BROR THEN
				error :=313;
				error_message := N'Sale order and invoice should be of same Branch';
		END IF;

		MinIN := MinIN+1;
	END WHILE;
	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE BaseEntry Int;
DECLARE BRIN Int;
DECLARE BROR Int;
DECLARE BRS nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 15
THEN
	SELECT Min(T0."VisOrder") INTO MinIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."BPLId" into BRIN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=15;
	SELECT NNM1."SeriesName" into BRS FROM ODRF INNER JOIN NNM1 ON NNM1."Series" = ODRF."Series" WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=15;

	IF BRS LIKE 'E%' then
	WHILE :MinIN <= :MaxIN DO
		SELECT DRF1."BaseEntry" into BaseEntry FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;

		SELECT ORDR."BPLId" into BROR FROM ORDR WHERE ORDR."DocEntry" = BaseEntry;

		IF BRIN <> BROR THEN
				error :=314;
				error_message := N'SO and Delivery should be of same Branch';
		END IF;

		MinIN := MinIN+1;
	END WHILE;
	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE BaseEntry Int;
DECLARE BRIN Int;
DECLARE BROR Int;
DECLARE BRS nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 203
THEN
	SELECT Min(T0."VisOrder") INTO MinIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."BPLId" into BRIN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=203;
	SELECT NNM1."SeriesName" into BRS FROM ODRF INNER JOIN NNM1 ON NNM1."Series" = ODRF."Series" WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=203;

	IF BRS LIKE 'E%' then
	WHILE :MinIN <= :MaxIN DO
		SELECT DRF1."BaseEntry" into BaseEntry FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;

		SELECT ORDR."BPLId" into BROR FROM ORDR WHERE ORDR."DocEntry" = BaseEntry;

		IF BRIN <> BROR THEN
				error :=314;
				error_message := N'SO and Downpayment should be of same Branch';
		END IF;

		MinIN := MinIN+1;
	END WHILE;
	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE BaseEntry Int;
DECLARE BRIN Int;
DECLARE BROR Int;
DECLARE ICOD varchar(50);
DECLARE Series varchar(50);
DECLARE BRORCount Int;

(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."BPLId" into BRIN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20;
	SELECT NNM1."SeriesName" into Series FROM NNM1 INNER JOIN ODRF ON ODRF."Series" = NNM1."Series" WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20;

	IF Series NOT LIKE 'CL%' THEN
	WHILE :MinIN <= :MaxIN DO
		SELECT DRF1."ItemCode" into ICOD FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;
		IF ICOD <> 'PCPM0095' and ICOD <> 'PCPM0094' and ICOD <> 'PCPM0096' and ICOD <> 'PCPM0097' and ICOD <> 'PCPM0098' and ICOD <> 'PCPM0098' THEN
			SELECT DRF1."BaseEntry" into BaseEntry FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;

			SELECT Count(ifnull(OPOR."BPLId",0)) into BRORCount FROM OPOR WHERE OPOR."DocEntry" = BaseEntry;
			if BRORCount>0
			THEN
			SELECT ifnull(OPOR."BPLId",0) into BROR FROM OPOR WHERE OPOR."DocEntry" = BaseEntry;
			END IF;

			IF BRIN <> BROR THEN
					error :=315;
					error_message := N'PO and GRN should be of same Branch';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
	END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE BaseEntry Int;
DECLARE BaseType Int;
DECLARE BRIN Int;
DECLARE BROR Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
	SELECT Min(T0."VisOrder") INTO MinIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."BPLId" into BRIN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=18;

	WHILE :MinIN <= :MaxIN DO
		SELECT DRF1."BaseType" into BaseType FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;

		IF BaseType = '20' then
			SELECT DRF1."BaseEntry" into BaseEntry FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;
			SELECT OPDN."BPLId" into BROR FROM OPDN WHERE OPDN."DocEntry" = BaseEntry;
		END IF;
		IF BaseType = '22' then
			SELECT DRF1."BaseEntry" into BaseEntry FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;
			SELECT OPOR."BPLId" into BROR FROM OPOR WHERE OPOR."DocEntry" = BaseEntry;
		END IF;

		IF BRIN <> BROR THEN
				error :=316;
				error_message := N'Base & Target document should be of same Branch';
		END IF;

		MinIN := MinIN+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE BaseEntry Int;
DECLARE BaseType Int;
DECLARE BRIN Int;
DECLARE BROR Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	SELECT Min(T0."VisOrder") INTO MinIN from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DLN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."BPLId" into BRIN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=13;

	WHILE :MinIN <= :MaxIN DO
		SELECT DRF1."BaseType" into BaseType FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;
		IF BaseType = '17' then
			SELECT DRF1."BaseEntry" into BaseEntry FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;
			SELECT ODLN."BPLId" into BROR FROM ODLN WHERE ODLN."DocEntry" = BaseEntry;
			IF BRIN <> BROR THEN
					error :=318;
					error_message := N'AR & Delivery should be of same Branch';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE ICGRN Nvarchar(50);
DECLARE PCGRN Int;
DECLARE BRGRN Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGRN <= :MaxGRN DO
		SELECT DRF1."ItemCode" into ICGRN FROM DRF1 INNER JOIN OITM ON OITM."ItemCode" = DRF1."ItemCode"
			WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGRN;
		IF ICGRN = 'Y' then
			SELECT DRF1."U_UNE_FACT" into PCGRN FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinGRN;
			IF PCGRN IS NULL THEN
				error :=320;
				error_message := 'Enter packing capacity of packing material GRN';
			END IF;
		END IF;
		MinGRN := MinGRN+1;
	END WHILE;
END IF;
END IF;

-----------------------------------Estimated cost header level--------------
IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE SeriesAR nvarchar(50);
DECLARE Incoterm nvarchar(250);
DECLARE TransCost Double;
DECLARE CustCCCost Double;
DECLARE OceanFUSD Double;
DECLARE OceanFINR Double;
DECLARE FFcharges Double;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13 THEN

		(SELECT T1."SeriesName" into SeriesAR FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13);

		IF SeriesAR LIKE 'EX%' THEN

		SELECT ODRF."U_Incoterms" into Incoterm FROM ODRF WHERE ODRF."DocEntry" = list_of_cols_val_tab_del and ODRF."ObjType"=13;
		SELECT ODRF."U_E_Trans_Cost"  into TransCost FROM ODRF WHERE ODRF."DocEntry" = list_of_cols_val_tab_del and ODRF."ObjType"=13;
		SELECT ODRF."U_E_C_Clear_Chrgs" into CustCCCost FROM ODRF WHERE ODRF."DocEntry" = list_of_cols_val_tab_del and ODRF."ObjType"=13;
		SELECT ODRF."U_E_O_Frght_USD" into OceanFUSD FROM ODRF WHERE ODRF."DocEntry" = list_of_cols_val_tab_del and ODRF."ObjType"=13;
		SELECT ODRF."U_E_O_Frght_INT" into OceanFINR FROM ODRF WHERE ODRF."DocEntry" = list_of_cols_val_tab_del and ODRF."ObjType"=13;
		SELECT ODRF."U_E_Frght_Forw_Chrgs" into FFcharges FROM ODRF WHERE ODRF."DocEntry" = list_of_cols_val_tab_del and ODRF."ObjType"=13;

				IF Incoterm = 'FOB' THEN

						IF TransCost IS NULL OR TransCost = 0.000 then
								error :=328;
								error_message := N'Please entre Estimated transportation cost';
						END IF;

						IF CustCCCost IS NULL OR CustCCCost = 0.000 then
								error :=329;
								error_message := N'Please entre Estimated Custom clearance cost';
						END IF;

						IF FFcharges IS NULL OR FFcharges = 0.000 then
								error :=330;
								error_message := N'Please entre Estimated freight forwarder charges';
						END IF;

				END IF;

				IF (Incoterm <> 'EXW' AND Incoterm <> 'FOB') THEN

						IF TransCost IS NULL OR TransCost = 0.000 then
								error :=331;
								error_message := N'Please entre Estimated transportation cost';
						END IF;

						IF CustCCCost IS NULL OR CustCCCost = 0.000 then
								error :=332;
								error_message := N'Please Estimated Custom clearance cost';
						END IF;

						IF OceanFUSD IS NULL OR OceanFUSD = 0.000 then
								error :=333;
								error_message := N'Please entre Estimated Ocean freight USD';
						END IF;

						IF OceanFINR IS NULL OR OceanFINR = 0.000 then
								error :=334;
								error_message := N'Please entre Estimated Ocean freight INR';
						END IF;

						IF FFcharges IS NULL OR FFcharges = 0.000 then
								error :=335;
								error_message := N'Please entre Estimated freight forwarder charges';
						END IF;

				END IF;
		END IF;
END IF;
END IF;
--------------------------Item not match with SO DL AR----------------------------
If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE itemCodeSO varchar(50);
	DECLARE itemCodeAR varchar(50);
	DECLARE MINNAR int;
	DECLARE MAXXAR int;
	DECLARE Itms varchar(50);
	DECLARE ARSeries varchar(50);
	DECLARE ARbstype varchar(50);
	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	Select MIN(T0."VisOrder") into MINNAR from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAR from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into ARSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13;

	WHILE MINNAR<=MAXXAR
	DO
		Select DRF1."BaseType" into ARbstype from DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder" =  MINNAR;
		IF ARSeries NOT LIKE 'CL%' and ARbstype = '17' then
			select T1."ItemCode" into itemCodeSO FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR and T4."ObjType"=13;

			select T3."ItemCode" into itemCodeAR FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR and T4."ObjType"=13;

			IF itemCodeSO IS NOT NULL THEN
				IF itemCodeSO != itemCodeAR THEN
					error:='336';
					error_message :='Item Not match in SO and Invoice';
				END IF;
			END IF;
		END IF;
		MINNAR = MINNAR + 1;
	END WHILE;
END IF;
END IF;

If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE itemCodeDL varchar(50);
	DECLARE itemCodeAR varchar(50);
	DECLARE MINNAR int;
	DECLARE MAXXAR int;
	DECLARE Itms varchar(50);
	DECLARE ARSeries varchar(50);
	DECLARE ARbstype varchar(50);
	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN
	Select MIN(T0."VisOrder") into MINNAR from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXAR from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	SELECT T1."SeriesName" into ARSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series"
	  WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13;

	WHILE MINNAR<=MAXXAR
	DO
		Select DRF1."BaseType" into ARbstype from DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder" =  MINNAR;
		IF ARSeries NOT LIKE 'CL%' and ARbstype = '15' then
			select T1."ItemCode" into itemCodeDL FROM DLN1 T1 LEFT OUTER JOIN ODLN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR and T4."ObjType"=13;

			select T3."ItemCode" into itemCodeAR FROM DLN1 T1 LEFT OUTER JOIN ODLN T2 ON T1."DocEntry" = T2."DocEntry"
			LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
			AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
			WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNAR and T4."ObjType"=13;

			IF itemCodeDL IS NOT NULL THEN
				IF itemCodeDL != itemCodeAR THEN
					error:='337';
					error_message :='Item Not match in Delivery and Invoice';
				END IF;
			END IF;
		END IF;
		MINNAR = MINNAR + 1;
	END WHILE;
END IF;
END IF;


If object_type = '112' and (:transaction_type = 'A' OR :transaction_type = 'U') then

	DECLARE itemCodeSO varchar(50);
	DECLARE itemCodeDL varchar(50);
	DECLARE MINNDL int;
	DECLARE MAXXDL int;
	DECLARE DLSeries varchar(50);
	DECLARE DLCode varchar(50);
	(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 15
THEN
	Select MIN(T0."VisOrder") into MINNDL from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	Select MAX(T0."VisOrder") into MAXXDL from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	SELECT T1."SeriesName" into DLSeries FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=15;
	IF DLSeries NOT LIKE 'CL%' then
		WHILE MINNDL<=MAXXDL
		DO
			select T0."ItemCode" into DLCode from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MINNDL;

			IF DLCode NOT LIKE 'PCPM%' THEN
				select T1."ItemCode" into itemCodeSO FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNDL and T4."ObjType"=15;

				select T3."ItemCode" into itemCodeDL FROM RDR1 T1 LEFT OUTER JOIN ORDR T2 ON T1."DocEntry" = T2."DocEntry"
				LEFT OUTER JOIN DRF1 T3 ON T2."DocEntry" = T3."BaseEntry" AND T1."LineNum" = T3."BaseLine"
				AND T1."ItemCode" = T3."ItemCode" LEFT OUTER JOIN ODRF T4 ON T3."DocEntry" = T4."DocEntry"
				WHERE T4."DocEntry" = :list_of_cols_val_tab_del and T3."VisOrder" = MINNDL AND T4."ObjType"=15;

				IF itemCodeSO IS NOT NULL THEN
					IF itemCodeSO != itemCodeDL THEN
						error:='338';
						error_message :='Item Not match in SO and Delivery';
					END IF;
				END IF;
			END IF;
			MINNDL = MINNDL + 1;
		END WHILE;
	END IF;
END IF;
END IF;


------------------------GRN Delay remark------------------

IF Object_type='112' and (:transaction_type ='A' OR :transaction_type ='U' ) Then
DECLARE GRNDelayRrk nvarchar(200);
DECLARE GRNDate Date;
DECLARE GateEdate Date;
DECLARE Delay Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	(SELECT ifnull(T0."U_RMKPRD",'') into GRNDelayRrk FROM ODRF T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=20);
	(SELECT T0."DocDate" into GRNDate FROM ODRF T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=20);
	(SELECT T0."U_UNE_GEDT" into GateEdate FROM ODRF T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=20);
	(SELECT DAYS_BETWEEN(T0."U_UNE_GEDT",T0."DocDate") INTO Delay FROM ODRF T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=20);

	  	IF Delay > 0 then
			IF (GRNDelayRrk IS NULL OR GRNDelayRrk = '') THEN
				error:=339;
				error_message:=N'Please select GRN Delay remark';
			END IF;
		END IF;
END IF;
END IF;

IF Object_type='112' and (:transaction_type ='A' OR :transaction_type ='U' ) Then

DECLARE GRNDelayRrk Int;
DECLARE DelayMstr1 Int;
DECLARE DelayMstr2 Int;
DECLARE DelayMstr3 Int;
DECLARE DelayMstr4 Int;
DECLARE DelayMstr5 Int;
DECLARE DelayMstr6 Int;
DECLARE DelayMstr7 Int;
DECLARE DelayMstr8 Int;
DECLARE DelayMstr9 Int;
DECLARE DelayMstr10 Int;
DECLARE DelayMstr11 Int;
DECLARE DelayMstr12 Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	(SELECT LENGTH(T0."U_RMKPRD") into GRNDelayRrk FROM ODRF T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del  and T0."ObjType"=20);

		(SELECT LENGTH("Name") INTO DelayMstr1 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 01);
		(SELECT LENGTH("Name") INTO DelayMstr2 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 02);
		(SELECT LENGTH("Name") INTO DelayMstr3 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 03);
		(SELECT LENGTH("Name") INTO DelayMstr4 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 04);
		(SELECT LENGTH("Name") INTO DelayMstr5 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 05);
		(SELECT LENGTH("Name") INTO DelayMstr6 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 06);
		(SELECT LENGTH("Name") INTO DelayMstr7 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 07);
		(SELECT LENGTH("Name") INTO DelayMstr8 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 08);
		(SELECT LENGTH("Name") INTO DelayMstr9 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 09);
		(SELECT LENGTH("Name") INTO DelayMstr10 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 10);
		(SELECT LENGTH("Name") INTO DelayMstr11 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 11);
		(SELECT LENGTH("Name") INTO DelayMstr12 FROM "@GRNDELAY" WHERE "@GRNDELAY"."Code" = 12);

	  	IF GRNDelayRrk <> DelayMstr1 then
	  		IF GRNDelayRrk <> DelayMstr2 then
	  			IF GRNDelayRrk <> DelayMstr3 then
	  				IF GRNDelayRrk <> DelayMstr4 then
	  					IF GRNDelayRrk <> DelayMstr5 then
	  						IF GRNDelayRrk <> DelayMstr6 then
	  							IF GRNDelayRrk <> DelayMstr7 then
	  								IF GRNDelayRrk <> DelayMstr8 then
	  									IF GRNDelayRrk <> DelayMstr9 then
	  										IF GRNDelayRrk <> DelayMstr10 then
	  											IF GRNDelayRrk <> DelayMstr11 then
	  												IF GRNDelayRrk <> DelayMstr12 then
														error:=340;
														error_message:=N'GRN Delay remark doen not match with master';
													END IF;
												END IF;
											END IF;
										END IF;
									END IF;
								END IF;
							END IF;
						END IF;
					END IF;
				END IF;
			END IF;
		END IF;
END IF;
END IF;

---------------------Pipe and SS 2% Deviation allowed-------------
IF object_type='112' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE GRPOQTD Int;
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE POQTB Int;
DECLARE ItemCDPQD Nvarchar(50);
DECLARE DOCTPDQ Nvarchar (50);
Declare PackType Nvarchar(50);
Declare COUNT1 Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxLinePDQ from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinLinePDQ<=MaxLinePDQ DO
		SELECT Distinct (DRF1."Quantity") INTO GRPOQTD FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (DRF1."BaseOpnQty") INTO POQTB FROM DRF1  where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (DRF1."ItemCode") INTO ItemCDPQD FROM DRF1 where DRF1."DocEntry" =:list_of_cols_val_tab_del and DRF1."VisOrder"=MinLinePDQ ;
		SELECT Distinct (ODRF."DocType") INTO DOCTPDQ FROM ODRF Inner JOIN DRF1 ON ODRF."DocEntry"=DRF1."DocEntry" Where ODRF."DocEntry" =:list_of_cols_val_tab_del and ODRF."ObjType"=20 ;

		select Count(*) INTO COUNT1 from "@PIPEANDSS" WHERE "Code" IN(ItemCDPQD);
		IF ItemCDPQD LIKE 'E%' THEN
			IF COUNT1 > 0 THEN
				IF  :DOCTPDQ = 'I' And (:GRPOQTD > (POQTB + ((POQTB*2)/100))) THEN
					error :=342;
					error_message := N'GRPO Qty. should not greater then P.O Qty.2%.'||ItemCDPQD;
				END IF;
			END IF;
		END IF;
		MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;
END IF;
-------------------------------- GRN not allowed for other branch user------------
IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT ODRF."BPLId" into BRGRN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign2"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20;


		IF BRGRN = 3 THEN
			IF (UserName = 'engg07' OR UserNameU = 'engg07') THEN
				error :=343;
				error_message := N'You are not allowed for UNIT - I GRN entry';
			END IF;
		END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT ODRF."BPLId" into BRGRN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign2"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20;


		IF BRGRN = 4 THEN
			IF (UserName = 'engg02' OR UserNameU = 'engg02') THEN
				error :=344;
				error_message := N'You are not allowed for UNIT - II GRN entry';
			END IF;
		END IF;
END IF;
END IF;
-----------------------------
IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN
	SELECT ODRF."BPLId" into BRGRN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=67;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=67;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign2"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=67;

		IF BRGRN = 3 THEN
			IF (UserName = 'engg07' OR UserNameU =  'engg07') THEN
				error :=345;
				error_message := N'You are not allowed for UNIT - I Inventory transfer entry';
			END IF;
		END IF;
END IF;
END IF;


IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 67
THEN
	SELECT ODRF."BPLId" into BRGRN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=67;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=67;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign2"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=67;

		IF BRGRN = 4 THEN
			IF (UserName = 'engg02' OR UserNameU = 'engg02') THEN
				error :=346;
				error_message := N'You are not allowed for UNIT - II Inventory transfer entry';
			END IF;
		END IF;
END IF;
END IF;

----------------
IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	SELECT ODRF."BPLId" into BRGRN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=60;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=60;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign2"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=60;

		IF BRGRN = 3 THEN
			IF (UserName = 'engg07' OR UserNameU =  'engg07') THEN
				error :=347;
				error_message := N'You are not allowed for UNIT - I Goods issue entry';
			END IF;
		END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
	SELECT ODRF."BPLId" into BRGRN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=60;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=60;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign2"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=60;

		IF BRGRN = 4 THEN
			IF (UserName = 'engg02' OR UserNameU = 'engg02') THEN
				error :=348;
				error_message := N'You are not allowed for UNIT - II Goods issue entry';
			END IF;
		END IF;
END IF;
END IF;
-------------------------
IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	SELECT ODRF."BPLId" into BRGRN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=59;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=59;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign2"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=59;

		IF BRGRN = 3 THEN
			IF (UserName = 'engg07' OR UserNameU =  'engg07') THEN
				error :=349;
				error_message := N'You are not allowed for UNIT - I Goods receipt entry';
			END IF;
		END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE UserName Nvarchar(50);
DECLARE UserNameU Nvarchar(50);
DECLARE BRGRN Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	SELECT ODRF."BPLId" into BRGRN FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=59;
	SELECT OUSR."USER_CODE" into UserName FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=59;

	SELECT OUSR."USER_CODE" into UserNameU FROM OUSR INNER JOIN ODRF ON OUSR."USERID" = ODRF."UserSign2"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=59;

		IF BRGRN = 4 THEN
			IF (UserName = 'engg02' OR UserNameU = 'engg02') THEN
				error :=350;
				error_message := N'You are not allowed for UNIT - II Goods receipt entry';
			END IF;
		END IF;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinGRN Int;
DECLARE MaxGRN Int;
DECLARE Price Decimal;
DECLARE ItemCode Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE :MinGRN <= :MaxGRN DO

	SELECT DRF1."ItemCode" INTO ItemCode FROM DRF1 INNER JOIN ODRF ON ODRF."DocEntry" = DRF1."DocEntry"
	WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20 and DRF1."VisOrder"=MinGRN;

		IF ItemCode LIKE 'PCPM%' THEN

		SELECT DRF1."Price" into Price FROM DRF1 INNER JOIN ODRF ON ODRF."DocEntry" = DRF1."DocEntry"
		WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20 and DRF1."VisOrder"=MinGRN;

			IF (Price = 0) THEN
				error :=351;
				error_message := N'Please enter price';
			END IF;
		END IF;
	MinGRN := MinGRN+1;
	END WHILE;
END IF;
END IF;

---------------------------------------------------

IF object_type IN('112') AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE Comments Int;
DECLARE JrnalMemo Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN

			SELECT T0."JrnlMemo" into JrnalMemo FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=59;
			IF JrnalMemo = 'Goods Receipt' THEN
				SELECT LENGTH(T0."Comments") into Comments FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=59;

					IF (Comments < 50 OR Comments IS NULL) THEN
						error :=352;
						error_message := N'Please mention remarks with minimum 20 words';
					END IF;
			END IF;
END IF;
END IF;

IF object_type IN('112') AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE Comments Int;
DECLARE JrnalMemo Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 60
THEN
		SELECT T0."JrnlMemo" into JrnalMemo FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=60;
			IF JrnalMemo = 'Goods Issue' THEN
				SELECT LENGTH(T0."Comments") into Comments FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=60;
					IF (Comments < 50 OR Comments IS NULL) THEN
						error :=353;
						error_message := N'Please mention remarks with minimum 20 words';
					END IF;
			END IF;
END IF;
END IF;

IF object_type IN('112') AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE Comments Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 14 THEN
			SELECT LENGTH(T0."Comments") into Comments FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=14;
				IF (Comments < 50 OR Comments IS NULL) THEN
					error :=354;
					error_message := N'Please mention remarks with minimum 20 words';
				END IF;
END IF;
END IF;

IF object_type IN('112') AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE Comments Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 19 THEN
			SELECT LENGTH(T0."Comments") into Comments FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=19;
				IF (Comments < 50 OR Comments IS NULL) THEN
				error :=355;
				error_message := N'Please mention remark with minimum 20 words';
		END IF;
END IF;
END IF;

IF object_type IN('112') AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE Comments Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
			SELECT LENGTH(T0."Comments") into Comments FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=18;
				IF (Comments < 50 OR Comments IS NULL) THEN
				error :=356;
				error_message := N'Please mention remark with minimum 20 words';
		END IF;
END IF;
END IF;

--------------------Delay Remarks-------

IF object_type='112' AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE DelayRemark Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13 THEN
		SELECT T1."U_RMKSTR" into DelayRemark FROM ODRF T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=13;

		IF DelayRemark <> 'Booking pending from forwarder' AND DelayRemark <> 'Container arrange as per planning' AND DelayRemark <> 'FOB shipment' AND DelayRemark <> 'ISO arrange as per planning'
			AND DelayRemark <> 'LCL shipment' AND DelayRemark <> 'Party asking for late dispatch' then
			error :=360;
			error_message := N'Please select proper Invoie delay remark';
		END IF;
	END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' or :transaction_type='U') THEN

DECLARE BLdelayRemark Nvarchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13 THEN
		SELECT T1."U_RMKPRD" into BLdelayRemark FROM ODRF T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType"=13;

		IF BLdelayRemark <> 'Container available on this vessel' AND BLdelayRemark <> 'Vessel delay' then
			error :=361;
			error_message := N'Please select proper BL delay remark';
		END IF;
	END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE project nvarchar(50);
DECLARE BROR Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20 THEN
	SELECT Min(T0."VisOrder") INTO MinIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."BPLId" into BROR FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20;

	WHILE :MinIN <= :MaxIN DO

		IF BROR = 3 THEN

			SELECT DRF1."Project" into project FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;

			IF project IS NULL OR project = '' THEN
					error :=375;
					error_message := N'For unit 1 Please select project as corporate or NA';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE project nvarchar(50);
DECLARE BROR Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20 THEN
	SELECT Min(T0."VisOrder") INTO MinIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."BPLId" into BROR FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20;

	WHILE :MinIN <= :MaxIN DO

		IF BROR = 4 THEN

			SELECT DRF1."Project" into project FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;

			IF project = 'Corpo. House' OR project = 'NA' THEN
					error :=376;
					error_message := N'For unit 2 do not select project' ||  MinIN;
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE project nvarchar(50);
DECLARE BROR Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 20
THEN
	SELECT Min(T0."VisOrder") INTO MinIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."BPLId" into BROR FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=20;

	WHILE :MinIN <= :MaxIN DO

		IF BROR = 5 THEN

			SELECT DRF1."Project" into project FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;

			IF project = 'Corpo. House' OR project = 'NA' THEN
					error :=377;
					error_message := N'For unit 3 do not select project';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE project nvarchar(50);
DECLARE BROR Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
	SELECT Min(T0."VisOrder") INTO MinIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."BPLId" into BROR FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=18;

	WHILE :MinIN <= :MaxIN DO

		IF BROR = 3 THEN

			SELECT DRF1."Project" into project FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;

			IF project IS NULL OR project = '' THEN
					error :=378;
					error_message := N'For unit 1 Please select project as corporate or NA';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE project nvarchar(50);
DECLARE BROR Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
	SELECT Min(T0."VisOrder") INTO MinIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."BPLId" into BROR FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=18;

	WHILE :MinIN <= :MaxIN DO

		IF BROR = 4 THEN

			SELECT DRF1."Project" into project FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;

			IF project = 'Corpo. House' OR project = 'NA' THEN
					error :=379;
					error_message := N'For unit 2 do not select project';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE MinIN Int;
DECLARE MaxIN Int;
DECLARE project nvarchar(50);
DECLARE BROR Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
	SELECT Min(T0."VisOrder") INTO MinIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxIN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."BPLId" into BROR FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=18;

	WHILE :MinIN <= :MaxIN DO

		IF BROR = 5 THEN

			SELECT DRF1."Project" into project FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinIN;

			IF project = 'Corpo. House' OR project = 'NA' THEN
					error :=380;
					error_message := N'For unit 3 do not select project';
			END IF;
		END IF;
		MinIN := MinIN+1;
	END WHILE;
END IF;
END IF;

-------------------------------Estinmated freight for Domestic sales--------------

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE SeriesAR nvarchar(50);

DECLARE TransCost Double;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 13
THEN

		(SELECT T1."SeriesName" into SeriesAR FROM ODRF T0 INNER JOIN NNM1 T1 ON T0."Series" = T1."Series" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=13);

		IF SeriesAR LIKE 'DM%' THEN

		SELECT ODRF."U_E_Trans_Cost" into TransCost FROM ODRF WHERE ODRF."DocEntry" = list_of_cols_val_tab_del and ODRF."ObjType"=13;

				IF TransCost IS NULL OR TransCost = 0.000 then
					error :=384;
					error_message := N'For domestic invoive please entre Estimated transportation cost';
				END IF;

		END IF;
END IF;
END IF;

----------------------------- Receipt quantity---------------

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
Declare ItCode nvarchar(50);
Declare RecQty int;
DECLARE MinGRN int;
DECLARE MaxGRN int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 59
THEN
	SELECT Min(T0."VisOrder") INTO MinGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGRN from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	WHILE MinGRN<=MaxGRN DO
		(Select DRF1."ItemCode" into ItCode from DRF1 WHERE DRF1."DocEntry"=list_of_cols_val_tab_del and DRF1."VisOrder"=MinGRN);
		(Select DRF1."U_UNE_ACQT" into RecQty from DRF1 WHERE DRF1."DocEntry"=list_of_cols_val_tab_del and DRF1."VisOrder"=MinGRN);

		IF (ItCode LIKE '%RM%' OR ItCode LIKE '%FG%' OR ItCode LIKE '%TR%') THEN
	         IF (RecQty IS NULL OR RecQty = 0) then
	         	  error :=393;
	              error_message := N'Please enter receipt quantity';
	            END IF;
	         END IF;
     MinGRN := MinGRN+1;
	END WHILE;
End If;
END IF;

IF object_type='112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE MinPO Int;
DECLARE MaxPO Int;
DECLARE ItemCode Nvarchar(50);
DECLARE Tagnum Nvarchar(5000);
DECLARE BRPO Int;
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18 THEN
	SELECT Min(T0."VisOrder") INTO MinPO from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxPO from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT ODRF."U_Tag_number" into Tagnum FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=18;

	IF Tagnum IS NULL THEN
		WHILE :MinPO <= :MaxPO DO
			SELECT DRF1."ItemCode" into ItemCode FROM DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder"=MinPO ;
				IF 	ItemCode NOT IN ('FURN0021','FURN0020') THEN
					IF (ItemCode LIKE 'FA%' OR ItemCode LIKE 'FU%')  THEN
							error :=395;
							error_message := N'For Fixed asset items, please enter Tag number';
					END IF;
				END IF;
			MinPO := MinPO+1;
		END WHILE;
	END IF;
END IF;
END IF;

------- Cubic Meter for Argentina [DRAFT] --- Tushar 11-10-2024 ---
IF object_type = '112' AND (:transaction_type ='A' or :transaction_type ='U' ) THEN

	DECLARE CustomerCountry VARCHAR(100);
	DECLARE CustomerCountryCode NVARCHAR(100);
	DECLARE ApproxCBMCnt NVARCHAR(100);
	DECLARE ActualCBMCnt NVARCHAR(100);
	DECLARE BLNumCnt NVARCHAR(100);
	DECLARE BLDateCnt NVARCHAR(100);

	(select ODRF."ObjType" into DraftObj from ODRF where ODRF."DocEntry"= :list_of_cols_val_tab_del);

	if :DraftObj=13 then
		SELECT COUNT(t0."County"),COUNT(t0."Country") into CustomerCountry,CustomerCountryCode  from CRD1 t0 join ODRF t1 on t0."CardCode" = t1."CardCode"
			   where t1."DocEntry" = list_of_cols_val_tab_del AND ((t0."County" = 'Argentina') or (t0."Country" = 'AR')) AND t1."ObjType" = 13;
		SELECT COUNT(sm."U_BLNum"),COUNT(sm."U_BLDate") into BLNumCnt,BLDateCnt from ODRF T1 LEFT JOIN "@SHIPMASTER" sm ON sm."U_InvDet1" = T1."DocEntry"
			   WHERE T1."DocEntry"=:list_of_cols_val_tab_del AND t1."ObjType" = 13;

		IF (CustomerCountry > 0 OR CustomerCountryCode > 0) THEN
				(SELECT SUM(COALESCE(CAST(T0."U_Approx_CBM" AS INT),0)),SUM(COALESCE(CAST(T0."U_Actual_CBM" AS INT),0)) into ApproxCBMCnt,ActualCBMCnt from ODRF T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del AND t0."ObjType" = 13);

				IF ApproxCBMCnt = 0 THEN
						error := -1012;
						error_message := 'Approx Cubic Meter is mandatory.';
				END IF;

				IF (ActualCBMCnt > 0) AND (BLNumCnt = 0 OR BLDateCnt = 0) THEN
					error := -1013;
					error_message := 'Actual Cubic Meter should be entered after entering BL Date and BL Number.';
				END IF;

				IF ApproxCBMCnt > 100 OR ActualCBMCnt > 100 THEN
					error := -1014;
					error_message := 'Cubic Meter should be lesser or equal to 100.';
				END IF;
		END IF;
	end if;
END IF;

------- Cubic Meter for Argentina --- Tushar 11-10-2024 ---
IF object_type = '13' AND (:transaction_type ='A' or :transaction_type ='U' ) THEN

	DECLARE CustomerCountry VARCHAR(100);
	DECLARE CustomerCountryCode NVARCHAR(100);
	DECLARE ApproxCBMCnt NVARCHAR(100);
	DECLARE ActualCBMCnt NVARCHAR(100);
	DECLARE BLNumCnt NVARCHAR(100);
	DECLARE BLDateCnt NVARCHAR(100);

	SELECT COUNT(t0."County"),COUNT(t0."Country") into CustomerCountry,CustomerCountryCode  from CRD1 t0 join OINV t1 on t0."CardCode" = t1."CardCode"
		   where t1."DocEntry" = list_of_cols_val_tab_del AND ((t0."County" = 'Argentina') or (t0."Country" = 'AR'));
	SELECT COUNT(sm."U_BLNum"),COUNT(sm."U_BLDate") into BLNumCnt,BLDateCnt from OINV T1 LEFT JOIN "@SHIPMASTER" sm ON sm."U_InvDet1" = T1."DocEntry" WHERE T1."DocEntry"=:list_of_cols_val_tab_del;

	IF (CustomerCountry > 0 OR CustomerCountryCode > 0) THEN
			(SELECT SUM(COALESCE(CAST(T0."U_Approx_CBM" AS INT),0)),SUM(COALESCE(CAST(T0."U_Actual_CBM" AS INT),0)) into ApproxCBMCnt,ActualCBMCnt from OINV T0 WHERE T0."DocEntry"=:list_of_cols_val_tab_del);

			IF ApproxCBMCnt = 0 THEN
					error := -1015;
					error_message := 'Approx Cubic Meter is mandatory.';
			END IF;

			IF (ActualCBMCnt > 0) AND (BLNumCnt = 0 OR BLDateCnt = 0) THEN
				error := -1016;
				error_message := 'Actual Cubic Meter should be entered after entering BL Date and BL Number.';
			END IF;

			IF ApproxCBMCnt > 100 OR ActualCBMCnt > 100 THEN
				error := -1017;
				error_message := 'Cubic Meter should be lesser or equal to 100.';
			END IF;
	END IF;
END IF;

/* This Validation is Commented until U_Q_SONo field is not added in MSPL Database

--------------------------Same Batch in Invoice as Sales Order Validation------30-01-2025---------

IF object_type = '13' AND (:transaction_type = 'A' or :transaction_type = 'U' ) THEN
    DECLARE wrong_batch VARCHAR(100);
    DECLARE batch_count INTEGER;
BEGIN
    -- Initialize variables
    wrong_batch := NULL;
    batch_count := 0;

    -- Check count first
    SELECT COUNT(*) INTO batch_count
    FROM ORDR T0
    JOIN RDR1 T1 ON T0."DocEntry" = T1."DocEntry"
    JOIN INV1 T3 ON T3."BaseEntry" = T0."DocEntry"
        AND T3."BaseType" = T1."ObjType"
        AND T1."LineNum" = T3."BaseLine"
    JOIN OINV T2 ON T2."DocEntry" = T3."DocEntry"
    JOIN IBT1_LINK T4 ON T4."BaseEntry" = T2."DocEntry"
        AND T4."BaseType" = T2."ObjType"
        AND T3."ItemCode" = T4."ItemCode"
        AND T3."LineNum" = T4."BaseLinNum"
    WHERE T2."DocEntry" = :list_of_cols_val_tab_del
    AND T4."BatchNum" NOT IN (
        SELECT T4."DistNumber"
        FROM ORDR T0
        JOIN RDR1 T1 ON T1."DocEntry" = T0."DocEntry"
        JOIN INV1 T3 ON T3."BaseEntry" = T0."DocEntry"
            AND T3."BaseType" = T1."ObjType"
            AND T1."LineNum" = T3."BaseLine"
        JOIN OINV T2 ON T2."DocEntry" = T3."DocEntry"
        JOIN OBTN T4 ON T4."U_Q_SONo" = T1."DocEntry"
            AND T1."LineNum" = T4."U_Q_SOLine"
            AND T1."ItemCode" = T4."ItemCode"
        WHERE T2."DocEntry" = :list_of_cols_val_tab_del
    );

    -- Only proceed with SELECT INTO if we have records
    IF batch_count > 0 THEN
        SELECT T4."BatchNum" INTO wrong_batch
        FROM ORDR T0
        JOIN RDR1 T1 ON T0."DocEntry" = T1."DocEntry"
        JOIN INV1 T3 ON T3."BaseEntry" = T0."DocEntry"
            AND T3."BaseType" = T1."ObjType"
            AND T1."LineNum" = T3."BaseLine"
        JOIN OINV T2 ON T2."DocEntry" = T3."DocEntry"
        JOIN IBT1_LINK T4 ON T4."BaseEntry" = T2."DocEntry"
            AND T4."BaseType" = T2."ObjType"
            AND T3."ItemCode" = T4."ItemCode"
            AND T3."LineNum" = T4."BaseLinNum"
        WHERE T2."DocEntry" = :list_of_cols_val_tab_del
        AND T4."BatchNum" NOT IN (
            SELECT T4."DistNumber"
            FROM ORDR T0
            JOIN RDR1 T1 ON T1."DocEntry" = T0."DocEntry"
            JOIN INV1 T3 ON T3."BaseEntry" = T0."DocEntry"
                AND T3."BaseType" = T1."ObjType"
                AND T1."LineNum" = T3."BaseLine"
            JOIN OINV T2 ON T2."DocEntry" = T3."DocEntry"
            JOIN OBTN T4 ON T4."U_Q_SONo" = T1."DocEntry"
                AND T1."LineNum" = T4."U_Q_SOLine"
                AND T1."ItemCode" = T4."ItemCode"
            WHERE T2."DocEntry" = :list_of_cols_val_tab_del
        )
        LIMIT 1;

        IF wrong_batch IS NOT NULL THEN
            error := -1026;
            error_message := 'The batch (' || wrong_batch || ') you have selected is not according to Sales Order.';
        END IF;
    END IF;
END;
END IF;

--------------------------Same Batch in Delivery as Sales Order Validation------30-01-2025---------

IF object_type = '15' AND (:transaction_type = 'A' or :transaction_type = 'U' ) THEN
    DECLARE wrong_batch VARCHAR(100);
    DECLARE batch_count INTEGER;
BEGIN
    -- Initialize variables
    wrong_batch := NULL;
    batch_count := 0;

    -- Check count first
    SELECT COUNT(*) INTO batch_count
    FROM ORDR T0
    JOIN RDR1 T1 ON T0."DocEntry" = T1."DocEntry"
    JOIN DLN1 T3 ON T3."BaseEntry" = T0."DocEntry"
        AND T3."BaseType" = T1."ObjType"
        AND T1."LineNum" = T3."BaseLine"
    JOIN ODLN T2 ON T2."DocEntry" = T3."DocEntry"
    JOIN IBT1_LINK T4 ON T4."BaseEntry" = T2."DocEntry"
        AND T4."BaseType" = T2."ObjType"
        AND T3."ItemCode" = T4."ItemCode"
        AND T3."LineNum" = T4."BaseLinNum"
    LEFT JOIN
    (
    SELECT T4."DistNumber"
        FROM ORDR T0
        JOIN RDR1 T1 ON T1."DocEntry" = T0."DocEntry"
        JOIN DLN1 T3 ON T3."BaseEntry" = T0."DocEntry"
            AND T3."BaseType" = T1."ObjType"
            AND T1."LineNum" = T3."BaseLine"
        JOIN ODLN T2 ON T2."DocEntry" = T3."DocEntry"
        JOIN OBTN T4 ON T4."U_Q_SONo" = T1."DocEntry"
            AND T1."LineNum" = T4."U_Q_SOLine"
            AND T1."ItemCode" = T4."ItemCode"
        WHERE T2."DocEntry" = :list_of_cols_val_tab_del
    ) as B0 ON B0."DistNumber" = T4."BatchNum"
    WHERE T2."DocEntry" = :list_of_cols_val_tab_del
    AND B0."DistNumber" is null;

    -- Only proceed with SELECT INTO if we have records
    IF batch_count > 0 THEN
        SELECT T4."BatchNum" INTO wrong_batch
        FROM ORDR T0
        JOIN RDR1 T1 ON T0."DocEntry" = T1."DocEntry"
        JOIN DLN1 T3 ON T3."BaseEntry" = T0."DocEntry"
            AND T3."BaseType" = T1."ObjType"
            AND T1."LineNum" = T3."BaseLine"
        JOIN ODLN T2 ON T2."DocEntry" = T3."DocEntry"
        JOIN IBT1_LINK T4 ON T4."BaseEntry" = T2."DocEntry"
            AND T4."BaseType" = T2."ObjType"
            AND T3."ItemCode" = T4."ItemCode"
            AND T3."LineNum" = T4."BaseLinNum"
        LEFT JOIN
        (
        SELECT T4."DistNumber"
            FROM ORDR T0
            JOIN RDR1 T1 ON T1."DocEntry" = T0."DocEntry"
            JOIN DLN1 T3 ON T3."BaseEntry" = T0."DocEntry"
                AND T3."BaseType" = T1."ObjType"
                AND T1."LineNum" = T3."BaseLine"
            JOIN ODLN T2 ON T2."DocEntry" = T3."DocEntry"
            JOIN OBTN T4 ON T4."U_Q_SONo" = T1."DocEntry"
                AND T1."LineNum" = T4."U_Q_SOLine"
                AND T1."ItemCode" = T4."ItemCode"
            WHERE T2."DocEntry" = :list_of_cols_val_tab_del
        ) as B0 ON B0."DistNumber" = T4."BatchNum"
        WHERE T2."DocEntry" = :list_of_cols_val_tab_del
        AND B0."DistNumber" is null
        LIMIT 1;

        IF wrong_batch IS NOT NULL THEN
            error := -1027;
            error_message := 'The batch (' || wrong_batch || ') you have selected is not according to Sales Order.';
        END IF;
    END IF;
END;
END IF;
*/

---------------------------Closing Gatepass Validation------30-01-2025---------
IF Object_Type = 'GPass' AND (:transaction_type = 'L') THEN
    DECLARE status VARCHAR(10);
    DECLARE SentQty DECIMAL(18,2);
    DECLARE ReturnedQty DECIMAL(18,2);
    DECLARE Sent_ItemCode NVARCHAR(50);
    DECLARE MinIn INT;
    DECLARE MaxIn INT;
    DECLARE GPR VARCHAR(10);

    -- Get current status
    SELECT T0."Status"
    INTO status
    FROM "@GPHR" T0
    WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

    -- If status is Closing
    IF status = 'C' THEN
        -- Get range of items
        SELECT MIN("VisOrder"), MAX("VisOrder")
        INTO MinIn, MaxIn
        FROM "@GPDL"
        WHERE "DocEntry" = :list_of_cols_val_tab_del;

        -- Loop through each item
        WHILE :MinIn <= :MaxIn DO
            -- Get item code for current iteration
            SELECT "U_ItemCode", COALESCE(SUM("U_Quantity"),0)
            INTO Sent_ItemCode, SentQty
            FROM "@GPDL"
            WHERE "DocEntry" = :list_of_cols_val_tab_del
            GROUP BY "U_ItemCode";

            select case when not exists (SELECT 1
                FROM "@GATEPASSRH" T2
                JOIN "@GATEPASSRR" T3 ON T2."DocEntry" = T3."DocEntry"
                WHERE T2."U_DocNum" = :list_of_cols_val_tab_del
                AND T3."U_ItemCode" = Sent_ItemCode
                AND T2."Canceled" = 'N') then 'N' else 'Y' end into GPR from dummy;

            -- Check if Gatepass return exists
            IF GPR = 'N' THEN
                error := -1030;
                error_message := N'No return entry found for item ' || Sent_ItemCode;
            ELSE
	            -- Check quantity match

	            SELECT COALESCE(SUM(T3."U_Quantity"), 0)
	            INTO ReturnedQty
	            FROM "@GATEPASSRH" T2
	            JOIN "@GATEPASSRR" T3 ON T2."DocEntry" = T3."DocEntry"
	            WHERE T2."U_DocNum" = :list_of_cols_val_tab_del
	            AND T3."U_ItemCode" = :Sent_ItemCode
	            AND T2."Canceled" = 'N';

	            IF :ReturnedQty > :SentQty THEN
	                error := -1031;
	                error_message := N'Returned quantity (' || :ReturnedQty || ') is greater than sent quantity (' || :SentQty || ') for item ' || :Sent_ItemCode;
	            END IF;

	            IF :ReturnedQty < :SentQty THEN
	                error := -1032;
	                error_message := N'Returned quantity (' || :ReturnedQty || ') is less than sent quantity (' || :SentQty || ') for item ' || :Sent_ItemCode;
	            END IF;
	         END IF;
            MinIn := MinIn + 1;
        END WHILE;
    END IF;
END IF;

------- Production order should not be closed until receipt is made --- Tushar 07-02-2025 ---
IF object_type='202' AND (:transaction_type ='A' or :transaction_type ='U' or :transaction_type = 'L') THEN

	DECLARE Status VARCHAR(20);
	DECLARE Typ VARCHAR(20);
		Select OWOR."Status" into Status from OWOR WHERE OWOR."DocEntry"=list_of_cols_val_tab_del;
		Select OWOR."Type" into Typ from OWOR WHERE OWOR."DocEntry"=list_of_cols_val_tab_del;
	If Typ<>'D' then
	IF Status = 'L' THEN
		DECLARE RFP INT; -- Receipt From Production

		SELECT COUNT(*) INTO RFP FROM OWOR T0 JOIN ign1 t2 on t0."DocEntry" = t2."BaseEntry" and t0."ItemCode" = t2."ItemCode" and t0."ObjType" = t2."BaseType" WHERE T0."DocEntry" =:list_of_cols_val_tab_del;
		IF RFP = 0 THEN
			error :=-1035;
			error_message := N'Production order cannot be closed because receipt is not made.';
		END IF;
	END IF;
	End If;
END IF;


/*IF object_type='202' AND (:transaction_type = 'L') THEN

	DECLARE Status VARCHAR(20);
	Select OWOR."Status" into Status from OWOR WHERE OWOR."DocEntry"=list_of_cols_val_tab_del;
	IF Status = 'L' THEN
		DECLARE RFP INT; -- Receipt From Production
		DECLARE ProdRmrk NVARCHAR(200);
		DECLARE Batch NVARCHAR(200);

		SELECT COUNT(*) INTO RFP FROM OWOR T0 JOIN ign1 t2 on t0."DocEntry" = t2."BaseEntry" and t0."ItemCode" = t2."ItemCode" and t0."ObjType" = t2."BaseType" WHERE T0."DocEntry" =:list_of_cols_val_tab_del;
		IF RFP = 0 THEN
			error :=-1035;
			error_message := N'Production order cannot be closed because receipt is not made.';
		END IF;

		SELECT COUNT(T0."PickRmrk") INTO ProdRmrk FROM OWOR T0 WHERE T0."DocEntry" =:list_of_cols_val_tab_del AND T0."Type" = 'P';
		IF ProdRmrk = 0 THEN
			error := -1035;
			error_message := N'Enter Special Production Remark.';
		END IF;

		IF ProdRmrk > 0 THEN
			SELECT DISTINCT BatchData."UsedBatchNos" INTO Batch
			FROM OWOR T7
    		INNER JOIN (
        		SELECT "BaseEntry", STRING_AGG("U_BatchNo", ', ') AS "UsedBatchNos"
        		FROM (
            		SELECT DISTINCT T2."BaseEntry", T5."U_BatchNo"
            		FROM IGE1 T2
                	INNER JOIN OIGE T3 ON T3."DocEntry" = T2."DocEntry"
                	INNER JOIN OITL T4 ON T2."DocEntry" = T4."DocEntry" AND T2."LineNum" = T4."DocLine" AND T4."DocType" = 60
                	INNER JOIN ITL1 T6 ON T4."LogEntry" = T6."LogEntry"
                	INNER JOIN OBTN T5 ON T6."SysNumber" = T5."SysNumber" AND T2."ItemCode" = T5."ItemCode"
            		WHERE T2."BaseType" = '202' AND T5."U_BatchNo" IS NOT NULL AND T5."U_BatchNo" <> ''
        		) AS DistinctData
        		GROUP BY "BaseEntry"
    		) BatchData ON BatchData."BaseEntry" = :list_of_cols_val_tab_del
			WHERE T7."Type" = 'P';

			IF Batch <> ProdRmrk THEN
				error := -1035;
				error_message := N'Entered batches not matching issued batches.';
			END IF;
		END IF;
	END IF;
END IF;*/

IF object_type = 'Q_QCCH' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN
DECLARE status Nvarchar(500);
DECLARE MinLinePDQ Int;
DECLARE MaxLinePDQ Int;
DECLARE Result NVARCHAR(80);

	SELECT Min(T0."LineId") INTO MinLinePDQ from "@Q_CCH1" T0 where T0."Code" =:list_of_cols_val_tab_del;
	SELECT Max(T0."LineId") INTO MaxLinePDQ from "@Q_CCH1" T0 where T0."Code" =:list_of_cols_val_tab_del;

	WHILE :MinLinePDQ<=MaxLinePDQ DO
	select T0."U_Status" into status from "@Q_CCH1" T0 where T0."Code" = :list_of_cols_val_tab_del AND T0."LineId" = MinLinePDQ;
	select T0."U_Result1" into Result from "@Q_CCH1" T0 where T0."Code" = :list_of_cols_val_tab_del AND T0."LineId" = MinLinePDQ;

		IF Result is null or Result = '' THEN
			error :=-1107;
			error_message := N'Analysis is not entered at Line - '||MinLinePDQ;
		END IF;
	MinLinePDQ := MinLinePDQ+1;
	END WHILE;
END IF;

---------------------- GRN Invoice Lock -------------------------------


IF object_type = '20' AND (:transaction_type = 'A' or :transaction_type = 'U') THEN
DECLARE CustRef Nvarchar(200);
		select Count(T0."NumAtCard") INTO CustRef from OPDN T0 where T0."DocEntry" = :list_of_cols_val_tab_del;
		IF  CustRef = 0 THEN
			error := -1125;
			error_message := N'Enter Vendor Bill No.';
		END IF;
END IF;

IF object_type = '20' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
	DECLARE MinGRN INT;
    DECLARE MaxGRN INT;
    DECLARE CurrentItemCode NVARCHAR(50);
    DECLARE LineNum INT;
    DECLARE BaseEntry INT;
    DECLARE BaseLine INT;
    DECLARE PackingCode NVARCHAR(50);
    DECLARE IsPackingFound INT;
    DECLARE POPackCapacity INT;
    DECLARE GRNPackCapacity INT;
    DECLARE GRNQty INT;
    DECLARE GRNPackActualQty INT;
    DECLARE hasRM INT;
    DECLARE Series Nvarchar(250);
    DECLARE DocDate Date;
    DECLARE error int;
    DECLARE error_message nvarchar(200);

	SELECT T1."SeriesName" into Series FROM OPDN T0 JOIN NNM1 T1 ON T1."Series" = T0."Series" WHERE T0."DocEntry"=:list_of_cols_val_tab_del;

	IF Series NOT LIKE 'CL%' then
		SELECT Min(T0."VisOrder") INTO MinGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT Max(T0."VisOrder") INTO MaxGRN from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
		SELECT MAX(T0."BaseEntry") into BaseEntry FROM PDN1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
		SELECT COUNT(*) INTO hasRM from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and (T0."ItemCode" like '%RM%' OR T0."ItemCode" like '%FG%' OR T0."ItemCode" like '%TR%');
		SELECT T0."DocDate" into DocDate from OPOR T0 where T0."DocEntry" = :BaseEntry;

		IF DocDate >= '2025-04-17' then
			WHILE :MinGRN <= :MaxGRN DO
				SELECT T0."ItemCode",T0."LineNum",T0."BaseLine",T0."Quantity",T0."Factor1" INTO CurrentItemCode, LineNum,BaseLine,GRNQty,GRNPackCapacity FROM PDN1 T0
				WHERE T0."DocEntry" = :list_of_cols_val_tab_del AND T0."VisOrder" = :MinGRN;

					IF (CurrentItemCode like '%RM%' OR CurrentItemCode like '%FG%' OR CurrentItemCode like '%TR%') AND :BaseEntry IS NOT NULL THEN
			            -- Get the expected packing code from PO
			            SELECT P."U_Pcode",P."Factor1" INTO PackingCode,POPackCapacity FROM POR1 P WHERE P."DocEntry" = :BaseEntry AND P."LineNum" = :BaseLine;

			            -- Only proceed with validation if we have a packing code in the PO
			            IF :PackingCode IS NOT NULL THEN
			                -- Check if the packing code exists in the GRN
			                SELECT COUNT(*) INTO IsPackingFound
			                FROM PDN1 G
			                WHERE G."DocEntry" = :list_of_cols_val_tab_del
			                  AND G."ItemCode" = :PackingCode;

			                -- If packing code is not found, raise an error
			                IF :IsPackingFound = 0 THEN
			                    error := -1132;
			                    error_message := N'Please add Packing Code ' || :PackingCode || ' for Raw Material ' || :CurrentItemCode;
			                END IF;
			            END IF;

			            IF GRNPackCapacity <> POPackCapacity THEN
			            	error := -1133;
			                error_message := N'Packing Capacity is not same as PO at line - '||:MinGRN+1;
			            END IF;

			        ELSEIF :CurrentItemCode LIKE '%PM%' AND :hasRM > 1 THEN

			        	select SUM(CEILING(T1."U_UNE_ACQT"/T1."Factor1")) into GRNPackActualQty from PDN1 T1 where T1."DocEntry" = :list_of_cols_val_tab_del and T1."U_Pcode" = :CurrentItemCode;

			        	IF ABS(GRNQty-GRNPackActualQty)>1 then
			        		error := -1134;
			                error_message := N'Calculated quantity is ' || CAST(:GRNPackActualQty AS INT) || ' for ' || :CurrentItemCode || ' but receiving '|| CAST(GRNQty AS INT);
			            END IF;
			        END IF;
				MinGRN := MinGRN+1;
			END WHILE;
		end if;
	END IF;
END IF;

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
	DECLARE FromWhs NVARCHAR(15);
	DECLARE ToWhs NVARCHAR(15);
	DECLARE Series Nvarchar(250);
	DECLARE BPCode NVARCHAR(15);
	Declare date1 Date;
	DECLARE BPLName NVARCHAR(30);
	DECLARE BaseDoc INT;
	DECLARE TransportName VARCHAR(50);
	DECLARE VehicleNo VARCHAR(20);
	DECLARE MobileNo VARCHAR(20);
	DECLARE UsrCod nvarchar(50);
	DECLARE ERD DATE;

	(SELECT ODRF."ObjType" INTO DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );

	if DraftObj = 67 THEN

		select T0."Filler",T0."ToWhsCode",T0."CardCode" into FromWhs,ToWhs,BPCode from ODRF T0 where T0."DocEntry"=list_of_cols_val_tab_del and T0."ObjType" = 67;
		SELECT NNM1."SeriesName" INTO Series FROM ODRF T0 LEFT JOIN NNM1 ON NNM1."Series" = T0."Series" where T0."DocEntry"=list_of_cols_val_tab_del and T0."ObjType" = 67;
		SELECT T0."DocDate",T1."BPLName" Into date1,BPLName FROM ODRF T0 LEFT JOIN OBPL T1 ON T0."BPLId" = T1."BPLId" WHERE T0."DocEntry" = list_of_cols_val_tab_del and T0."ObjType" = 67;
		SELECT T0."U_UNE_TransportName",T0."U_UNE_VehicleNo",T0."U_Mobile_No",T1."USER_CODE",T0."U_RGP_ERD" Into TransportName,VehicleNo,MobileNo,UsrCod,ERD
			   FROM ODRF T0 JOIN OUSR T1 ON T1."USERID" = T0."UserSign"
			   WHERE T0."DocEntry" = list_of_cols_val_tab_del and T0."ObjType" = 67;

		IF (FromWhs = '1RGP' or ToWhs = '1RGP') and UsrCod not in ('engg02','engg05') THEN
			error :=-1135;
			error_message := N'You are not allowed to add RGP.';
		END IF;

		IF (FromWhs = '2RGP' or ToWhs = '2RGP') and UsrCod not in ('engg07','store01','project3') THEN
			error :=-1136;
			error_message := N'You are not allowed to add RGP.';
		END IF;

		IF FromWhs like '%RGP%' and Series NOT LIKE 'GR%' THEN
			error :=-1137;
			error_message := N'Please select GR Series.';
		END IF;

		IF ToWhs like '%RGP%' and Series NOT LIKE 'RG%' THEN
			error :=-1138;
			error_message := N'Please select RG Series.';
		END IF;

		IF FromWhs not like '%RGP%' and Series LIKE 'GR%' THEN
			error :=-1139;
			error_message := N'Please select RGP Warehouse in From Warehouse.';
		END IF;

		IF (ToWhs not like '%RGP%' and Series LIKE 'RG%') OR ((BaseDoc IS NOT NULL AND BaseDoc <> -1) AND ToWhs not like '%RGP%') THEN
			error :=-1140;
			error_message := N'Please select RGP Warehouse in To Warehouse.';
		END IF;

		IF FromWhs like '%RGP%' and ToWhs like '%RGP%' THEN
			error :=-1141;
			error_message := N'From-Warehouse and To-Warehouse both cannot be RGP.';
		END IF;

		IF (FromWhs like '%RGP%' or ToWhs like '%RGP%') and (BPCode IS NULL OR BPCode NOT LIKE 'V%') THEN
			error :=-1142;
			error_message := N'Please select vendor.';
		END IF;

		IF (FromWhs like '%RGP%' or ToWhs like '%RGP%') and (date1 >= '20240401' and date1 <= '20250331') and Series NOT LIKE '%2425%' then
			error :=-1143;
			error_message := N'Gate pass series may wrong please contact to SAP';
		END IF;

		IF (FromWhs like '%RGP%' or ToWhs like '%RGP%') and (date1 >= '20250401' and date1 <= '20260331') and Series NOT LIKE '%2526%' then
			error :=-1144;
			error_message := N'Gate pass series may wrong please contact to SAP';
		END IF;

		IF (FromWhs like '%RGP%' or ToWhs like '%RGP%') and BPCode IS NOT NULL AND BPCode IN ('VEXP0729','VEXP0846','VEXP1199','VEXP1312','VIRD0077') THEN
			error :=-1145;
			error_message := N'Internal material transfer is not allowed.';
		END IF;

		IF FromWhs like '%RGP%' THEN
			SELECT T1."RefDocEntr" INTO BaseDoc FROM ODRF T0 LEFT JOIN DRF21 T1 ON T0."DocEntry" = T1."DocEntry" WHERE T0."DocEntry" = list_of_cols_val_tab_del and T0."ObjType" = 67;
			IF (BaseDoc = -1 OR BaseDoc IS NULL) THEN
				error :=-1146;
				error_message := N'Base Document is required.';
			END IF;
		END IF;

		IF ToWhs like '%RGP%' THEN
			SELECT T1."RefDocEntr" INTO BaseDoc FROM ODRF T0 LEFT JOIN DRF21 T1 ON T0."DocEntry" = T1."DocEntry" WHERE T0."DocEntry" = list_of_cols_val_tab_del and T0."ObjType" = 67;
			IF (BaseDoc IS NOT NULL) THEN
				error :=-1147;
				error_message := N'Base Document is attached, cannot tranfer to RGP Warehouse.';
			END IF;
		END IF;

		IF (FromWhs like '%RGP%' or ToWhs like '%RGP%') and IFNULL(TransportName,'') = '' THEN
			error :=-1148;
			error_message := N'Transport Name is required.';
		END IF;

		IF (FromWhs like '%RGP%' or ToWhs like '%RGP%') and IFNULL(VehicleNo,'') = '' THEN
			error :=-1149;
			error_message := N'Vehicle No. is required.';
		END IF;

		IF (FromWhs like '%RGP%' or ToWhs like '%RGP%') and IFNULL(MobileNo,'') = '' THEN
			error :=-1150;
			error_message := N'Mobile No. is required.';
		END IF;

		IF ((FromWhs like '%NU' and ToWhs like '%BT') OR (FromWhs like '%BT' and ToWhs like '%NU')) AND Series not like 'IT%' THEN
			error := -1151;
			error_message := N'Please select IT Series for Internal transfer.';
		END IF;

		IF ToWhs like '%RGP' THEN
			IF ERD is null then
				error := -1153;
				error_message := N'Please select Expected Return Date.';
			end if;
		END IF;
	end if;
End If;

IF Object_type = '67' and (:transaction_type ='A' or :transaction_type ='U' ) Then
	DECLARE FromWhs NVARCHAR(15);
	DECLARE ToWhs NVARCHAR(15);
	DECLARE Series Nvarchar(250);
	DECLARE BPCode NVARCHAR(15);
	Declare date1 Date;
	DECLARE BaseDoc INT;
	DECLARE TransportName VARCHAR(50);
	DECLARE VehicleNo VARCHAR(20);
	DECLARE MobileNo VARCHAR(20);
	DECLARE UsrCod nvarchar(50);
	DECLARE ERD DATE;

	select T0."Filler",T0."ToWhsCode",T0."CardCode" into FromWhs,ToWhs,BPCode from OWTR T0 where T0."DocEntry"=list_of_cols_val_tab_del;
	SELECT NNM1."SeriesName" INTO Series FROM OWTR T0 LEFT JOIN NNM1 ON NNM1."Series" = T0."Series" where T0."DocEntry"=list_of_cols_val_tab_del;
	SELECT T0."DocDate" Into date1  FROM OWTR T0 WHERE T0."DocEntry" = list_of_cols_val_tab_del;
	SELECT T0."U_UNE_TransportName",T0."U_UNE_VehicleNo",T0."U_Mobile_No",T1."USER_CODE",T0."U_RGP_ERD" Into TransportName,VehicleNo,MobileNo,UsrCod,ERD
		   FROM OWTR T0 JOIN OUSR T1 ON T1."USERID" = T0."UserSign"
		   WHERE T0."DocEntry" = list_of_cols_val_tab_del and T0."ObjType" = 67;

	IF (FromWhs = '1RGP' or ToWhs = '1RGP') and UsrCod not in ('engg02','engg05') THEN
		error :=-1153;
		error_message := N'You are not allowed to add RGP.';
	END IF;

	IF (FromWhs = '2RGP' or ToWhs = '2RGP') and UsrCod not in ('engg07','store01','project3') THEN
		error :=-1154;
		error_message := N'You are not allowed to add RGP.';
	END IF;

	IF FromWhs like '%RGP%' and Series NOT LIKE 'GR%' THEN
		error :=-1155;
		error_message := N'Please select GR Series.';
	END IF;

	IF ToWhs like '%RGP%' and Series NOT LIKE 'RG%' THEN
		error :=-1156;
		error_message := N'Please select RG Series.';
	END IF;

	IF FromWhs not like '%RGP%' and Series LIKE 'GR%' THEN
		error :=-1157;
		error_message := N'Please select RGP Warehouse in From Warehouse.';
	END IF;

	IF (ToWhs not like '%RGP%' and Series LIKE 'RG%') OR ((BaseDoc IS NOT NULL AND BaseDoc <> -1) AND ToWhs not like '%RGP%') THEN
		error :=-1158;
		error_message := N'Please select RGP Warehouse in To Warehouse.';
	END IF;

	IF FromWhs like '%RGP%' and ToWhs like '%RGP%' THEN
		error :=-1159;
		error_message := N'From-Warehouse and To-Warehouse both cannot be RGP.';
	END IF;

	IF (FromWhs like '%RGP%' or ToWhs like '%RGP%') and (BPCode IS NULL OR BPCode NOT LIKE 'V%') THEN
		error :=-1160;
		error_message := N'Please select vendor.';
	END IF;

	IF (FromWhs like '%RGP%' or ToWhs like '%RGP%') and (date1 >= '20240401' and date1 <= '20250331') and Series NOT LIKE '%2425%' then
		error :=-1161;
		error_message := N'Gate pass series may wrong please contact to SAP';
	END IF;

	IF (FromWhs like '%RGP%' or ToWhs like '%RGP%') and (date1 >= '20250401' and date1 <= '20260331') and Series NOT LIKE '%2526%' then
		error :=-1162;
	   	error_message := N'Gate pass series may wrong please contact to SAP';
	END IF;

	IF (FromWhs like '%RGP%' or ToWhs like '%RGP%') and BPCode IS NOT NULL AND BPCode IN ('VEXP0729','VEXP0846','VEXP1199','VEXP1312','VIRD0077') THEN
		error :=-1163;
		error_message := N'Internal material transfer is not allowed.';
	END IF;

	IF FromWhs like '%RGP%' THEN
		SELECT T1."RefDocEntr" INTO BaseDoc FROM OWTR T0 LEFT JOIN WTR21 T1 ON T0."DocEntry" = T1."DocEntry" WHERE T0."DocEntry" = list_of_cols_val_tab_del;
		IF (BaseDoc = -1 OR BaseDoc IS NULL) THEN
			error :=-1164;
			error_message := N'Base Document is required.';
		END IF;
	END IF;

	IF ToWhs like '%RGP%' THEN
		SELECT T1."RefDocEntr" INTO BaseDoc FROM OWTR T0 LEFT JOIN WTR21 T1 ON T0."DocEntry" = T1."DocEntry" WHERE T0."DocEntry" = list_of_cols_val_tab_del;
		IF (BaseDoc IS NOT NULL) THEN
			error :=-1165;
			error_message := N'Base Document is attached, cannot tranfer to RGP Warehouse.';
		END IF;
	END IF;

	IF (FromWhs like '%RGP%' or ToWhs like '%RGP%') and IFNULL(TransportName,'') = '' THEN
		error :=-1166;
		error_message := N'Transport Name is required.';
	END IF;

	IF (FromWhs like '%RGP%' or ToWhs like '%RGP%') and IFNULL(VehicleNo,'') = '' THEN
		error :=-1167;
		error_message := N'Vehicle No. is required.';
	END IF;

	IF (FromWhs like '%RGP%' or ToWhs like '%RGP%') and IFNULL(MobileNo,'') = '' THEN
		error :=-1168;
		error_message := N'Mobile No. is required.';
	END IF;

	IF ((FromWhs like '%NU' and ToWhs like '%BT') OR (FromWhs like '%BT' and ToWhs like '%NU')) AND Series not like 'IT%' THEN
		error := -1169;
		error_message := N'Please select IT Series for Internal transfer.';
	END IF;

	IF ToWhs like '%RGP' THEN
		IF ERD is null then
			error := -1171;
			error_message := N'Please select Expected Return Date.';
		end if;
	END IF;
End If;

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
	DECLARE ItemCode NVARCHAR(50);
    DECLARE MinIn INT;
    DECLARE MaxIn INT;
    DECLARE GrpCode INT;
    DECLARE FromWhs NVARCHAR(15);
	DECLARE ToWhs NVARCHAR(15);
	DECLARE UsrCod nvarchar(50);

	(SELECT ODRF."ObjType" INTO DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );

	if DraftObj = 67 THEN
		SELECT MIN(T0."VisOrder"), MAX(T0."VisOrder") INTO MinIn, MaxIn FROM DRF1 T0 JOIN ODRF T1 ON T0."DocEntry" = T1."DocEntry"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T1."ObjType" = 67;
		select T0."Filler",T0."ToWhsCode" into FromWhs,ToWhs from ODRF T0 where T0."DocEntry"=list_of_cols_val_tab_del and T0."ObjType" = 67;

		IF FromWhs like '%RGP%' or ToWhs like '%RGP%' THEN
			WHILE :MinIn <= :MaxIn DO
		       SELECT T0."ItemCode",T1."ItmsGrpCod"
		       INTO ItemCode, GrpCode
		       FROM DRF1 T0 JOIN OITM T1 ON T0."ItemCode" = T1."ItemCode" JOIN ODRF T2 on T0."DocEntry" = T2."DocEntry"
		       WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinIn and T2."ObjType" = 67;

		       IF GrpCode IN (120,125) OR ItemCode LIKE 'MISC%' OR ItemCode LIKE 'WSTG%' THEN -- Scrap, Misc.
					error := -1171;
		            error_message := N'Scrap & Wastage and Miscellaneous Items are not allowed to transfer.';
		       END IF;
		       MinIn := MinIn + 1;
	    	END WHILE;
		END IF;
	end if;
End If;

IF Object_type = '67' and (:transaction_type ='A' or :transaction_type ='U' ) Then
	DECLARE ItemCode NVARCHAR(50);
    DECLARE MinIn INT;
    DECLARE MaxIn INT;
    DECLARE GrpCode INT;
    DECLARE FromWhs NVARCHAR(15);
	DECLARE ToWhs NVARCHAR(15);
	DECLARE BaseDoc INT;

	SELECT MIN(T0."VisOrder"), MAX(T0."VisOrder") INTO MinIn, MaxIn FROM WTR1 T0 JOIN OWTR T1 ON T0."DocEntry" = T1."DocEntry"
	WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	select T0."Filler",T0."ToWhsCode" into FromWhs,ToWhs from OWTR T0 where T0."DocEntry"=list_of_cols_val_tab_del;

	IF FromWhs like '%RGP%' or ToWhs like '%RGP%' THEN
		WHILE :MinIn <= :MaxIn DO
		   SELECT T0."ItemCode",T1."ItmsGrpCod"
		   INTO ItemCode, GrpCode
		   FROM WTR1 T0 JOIN OITM T1 ON T0."ItemCode" = T1."ItemCode" JOIN OWTR T2 on T0."DocEntry" = T2."DocEntry"
		   WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinIn;

		   IF GrpCode IN (120,125) OR ItemCode LIKE 'MISC%' OR ItemCode LIKE 'WSTG%' THEN -- Scrap, Misc.
				error := -1172;
		        error_message := N'Scrap & Wastage and Miscellaneous Items are not allowed to transfer.';
		   END IF;
		MinIn := MinIn + 1;
	    END WHILE;
	END IF;
End If;

IF Object_type = '67' and (:transaction_type ='A' or :transaction_type ='U' ) Then
	DECLARE ItemCode NVARCHAR(50);
	DECLARE ItemCnt INT;
    DECLARE MinIn INT;
    DECLARE MaxIn INT;
    DECLARE GrpCode INT;
    DECLARE FromWhs NVARCHAR(15);
    DECLARE ToWhs NVARCHAR(15);
	DECLARE BaseDoc INT;
	DECLARE SentQty INT;
	DECLARE ReceivedQty INT;
	DECLARE SendingQty INT;
	DECLARE SendFromWhs NVARCHAR(15);

	SELECT MIN(T0."VisOrder"), MAX(T0."VisOrder") INTO MinIn, MaxIn FROM WTR1 T0 JOIN OWTR T1 ON T0."DocEntry" = T1."DocEntry"
	WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	select T0."Filler",T0."ToWhsCode" into FromWhs,ToWhs from OWTR T0 where T0."DocEntry"=list_of_cols_val_tab_del;

	IF FromWhs like '%RGP%' THEN
		SELECT T1."RefDocEntr" INTO BaseDoc FROM OWTR T0 LEFT JOIN WTR21 T1 ON T0."DocEntry" = T1."DocEntry" WHERE T0."DocEntry" = list_of_cols_val_tab_del;
		select T0."Filler" into SendFromWhs from OWTR T0 where T0."DocEntry"= BaseDoc;
		IF SendFromWhs <> ToWhs then
			error := -1173;
			error_message := N'Please select '||SendFromWhs|| ' in To Warehouse.';
		ELSE
			IF (BaseDoc <> -1 AND BaseDoc IS NOT NULL) THEN
				WHILE :MinIn <= :MaxIn DO
				   SELECT COUNT(T0."ItemCode") INTO ItemCnt FROM WTR1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinIn
				   AND T0."ItemCode" IN (SELECT distinct T1."ItemCode" from WTR1 T1 WHERE T1."DocEntry" = BaseDoc);

				   SELECT T0."ItemCode",T0."Quantity" INTO ItemCode,SendingQty FROM WTR1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinIn;

				   IF ItemCnt = 0 THEN
						error := -1174;
				        error_message := N'You are not allowed to select item ('|| ItemCode ||') other than gate pass items at line - ' || MinIn+1 ;
				   ELSE
				   		SELECT COALESCE(SUM(T1."Quantity"),0) INTO SentQty FROM WTR1 T1 JOIN OWTR T0 ON T0."DocEntry" = T1."DocEntry" WHERE T0."DocEntry" = BaseDoc
				   		AND T1."ItemCode" = ItemCode AND T0."CANCELED" = 'N' AND T1."Quantity" > 0;

				   		SELECT COALESCE(SUM(T1."Quantity"),0) INTO ReceivedQty FROM WTR1 T1 JOIN OWTR T0 ON T0."DocEntry" = T1."DocEntry" LEFT JOIN WTR21 T21 ON T21."DocEntry" = T0."DocEntry"
				   		WHERE T21."RefDocEntr" = BaseDoc AND T1."DocEntry" <> list_of_cols_val_tab_del and T1."Quantity" > 0
				   		AND T1."ItemCode" = ItemCode AND T0."CANCELED" = 'N';

				   		IF SendingQty + ReceivedQty > SentQty THEN
				   			error := -1175;
				        	error_message := N''||ReceivedQty||'/'||SentQty||' is already received for ' || ItemCode;
				        END IF;

				   END IF;
				MinIn := MinIn + 1;
			    END WHILE;
			END IF;
		END IF;
	END IF;
End If;

IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then
	DECLARE ItemCode NVARCHAR(50);
	DECLARE ItemCnt INT;
    DECLARE MinIn INT;
    DECLARE MaxIn INT;
    DECLARE GrpCode INT;
    DECLARE FromWhs NVARCHAR(15);
    DECLARE ToWhs NVARCHAR(15);
	DECLARE BaseDoc INT;
	DECLARE SentQty INT;
	DECLARE ReceivedQty INT;
	DECLARE SendingQty INT;
	DECLARE SendFromWhs NVARCHAR(15);

	(SELECT ODRF."ObjType" INTO DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );

	if DraftObj = 67 THEN
		SELECT MIN(T0."VisOrder"), MAX(T0."VisOrder") INTO MinIn, MaxIn FROM DRF1 T0 JOIN ODRF T1 ON T0."DocEntry" = T1."DocEntry"
		WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType" = 67;
		select T0."Filler",T0."ToWhsCode" into FromWhs,ToWhs from ODRF T0 where T0."DocEntry"=list_of_cols_val_tab_del and T0."ObjType" = 67;

		IF FromWhs like '%RGP%' THEN
			SELECT T1."RefDocEntr" INTO BaseDoc FROM ODRF T0 LEFT JOIN DRF21 T1 ON T0."DocEntry" = T1."DocEntry" WHERE T0."DocEntry" = list_of_cols_val_tab_del and T0."ObjType" = 67;
			select T0."Filler" into SendFromWhs from OWTR T0 where T0."DocEntry"= BaseDoc;
			IF SendFromWhs <> ToWhs then
				error := -1176;
				error_message := N'Please select '||SendFromWhs|| ' in To Warehouse.';
			ELSE
				IF (BaseDoc <> -1 AND BaseDoc IS NOT NULL) THEN
					WHILE :MinIn <= :MaxIn DO
					   SELECT COUNT(T0."ItemCode") INTO ItemCnt FROM DRF1 T0 JOIN ODRF T1 ON T0."DocEntry" = T1."DocEntry"
					   WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinIn AND T1."ObjType" = 67
					   AND T0."ItemCode" IN (SELECT distinct T3."ItemCode" from WTR1 T3 JOIN OWTR T4 ON T3."DocEntry" = T4."DocEntry" WHERE T3."DocEntry" = BaseDoc);

					   SELECT T0."ItemCode",T0."Quantity" INTO ItemCode,SendingQty FROM DRF1 T0 JOIN ODRF T1 ON T0."DocEntry" = T1."DocEntry" WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."VisOrder" = MinIn and T1."ObjType" = 67;

					   IF ItemCnt = 0 THEN
							error := -1177;
					        error_message := N'You are not allowed to select item ('|| ItemCode ||') other than gate pass items at line - ' || MinIn+1 ;
					   ELSE
					   		SELECT COALESCE(SUM(T1."Quantity"),0) INTO SentQty FROM WTR1 T1 JOIN OWTR T0 ON T0."DocEntry" = T1."DocEntry" WHERE T0."DocEntry" = BaseDoc and T0."ObjType" = 67
					   		AND T1."ItemCode" = ItemCode AND T0."CANCELED" = 'N' AND T1."Quantity" > 0;

					   		SELECT COALESCE(SUM(T1."Quantity"),0) INTO ReceivedQty FROM WTR1 T1 JOIN OWTR T0 ON T0."DocEntry" = T1."DocEntry" LEFT JOIN WTR21 T21 ON T21."DocEntry" = T0."DocEntry"
					   		WHERE T21."RefDocEntr" = BaseDoc and T0."ObjType" = 67 AND T1."DocEntry" <> list_of_cols_val_tab_del and T1."Quantity" > 0
					   		AND T1."ItemCode" = ItemCode AND T0."CANCELED" = 'N';

					   		IF SendingQty + ReceivedQty > SentQty THEN
					   			error := -1178;
					        	error_message := N''||ReceivedQty||'/'||SentQty||' is already received for ' || ItemCode;
					        END IF;

					   END IF;
					MinIn := MinIn + 1;
				    END WHILE;
				END IF;
			END IF;
		END IF;
	end if;
End If;

IF object_type = '59' AND (:transaction_type = 'A' or :transaction_type ='U') THEN
	DECLARE MinGR Int;
	DECLARE MaxGR Int;
	DECLARE WhsGR Nvarchar(50);
	DECLARE Series Nvarchar(50);
	DECLARE ItemCode NVARCHAR(30);
	DECLARE Price FLOAT;
	DECLARE DefaultPrice FLOAT := 0.01;
	DECLARE UsrCod nvarchar(50);

	SELECT Min(T0."VisOrder") INTO MinGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGR from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;

	SELECT T0."SeriesName",T2."USER_CODE" into Series,UsrCod FROM OIGN T1 INNER JOIN NNM1 T0 ON T0."Series" = T1."Series"
	INNER JOIN OUSR T2 ON T2."USERID" = T1."UserSign" WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
	WHILE MinGR<= MaxGR DO
		SELECT T1."WhsCode",T1."ItemCode",T1."Price" into WhsGR,ItemCode,Price FROM IGN1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del and T1."VisOrder"=MinGR;

		IF (WhsGR LIKE '%NU%') and UsrCod not in ('account7','sap01','manager') THEN
			error :=-1184;
			error_message := N'You are not allowed to add stock in NU.';
		END IF;

	MinGR := MinGR+1;
	END WHILE;
END IF;

IF Object_type = '60' and (:transaction_type ='A') Then
Declare OcrCode nvarchar(50);
Declare ItemCode nvarchar(50);
DECLARE MinGI Int;
DECLARE MaxGI Int;
Declare PrdSeries  Nvarchar(50);
Declare PrdUser  Nvarchar(50);
Declare ISFA nvarchar(2);
DECLARE FRWHS NVARCHAR(10);
select "SeriesName" into PrdSeries From OIGE INNER JOIN NNM1 ON NNM1."Series" = OIGE."Series" where OIGE."DocEntry"= :list_of_cols_val_tab_del;
select OUSR."USER_CODE" into PrdUser from OIGE INNER JOIN OUSR ON OUSR."USERID" = OIGE."UserSign" where OIGE."DocEntry"= :list_of_cols_val_tab_del;

	SELECT Min(T0."VisOrder") INTO MinGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxGI from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	WHILE :MinGI<= :MaxGI DO
		(Select  T1."ItemCode",T1."U_IsFA",T0."WhsCode" into ItemCode,ISFA,FRWHS from IGE1 T0 JOIN OITM T1 ON T0."ItemCode" = T1."ItemCode" where T0."DocEntry"=list_of_cols_val_tab_del and T0."VisOrder"=MinGI);
          IF (ItemCode like 'NU%' and ISFA = 'Y' and PrdUser not in ('account7') and FRWHS NOT LIKE '%BT%') then
                  error :=-1187;
                  error_message := N''||ItemCode||' at Line-'||MinGI+1||' is Fixed Asset Item, you are not allowed to issue it.';
         End If;
    MinGI := MinGI+1;
	END WHILE;
End If;

If Object_Type = '112' and (:transaction_type='A' ) then
Declare OcrCode nvarchar(50);
Declare ItemCode nvarchar(50);
DECLARE MinGI Int;
DECLARE MaxGI Int;
Declare PrdSeries  Nvarchar(50);
Declare PrdUser  Nvarchar(50);
Declare ISFA nvarchar(2);
DECLARE FRWHS NVARCHAR(10);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
	if DraftObj = 59 THEN
		select "SeriesName" into PrdSeries From ODRF INNER JOIN NNM1 ON NNM1."Series" = ODRF."Series" where ODRF."DocEntry"= :list_of_cols_val_tab_del and ODRF."ObjType"=60;
		select OUSR."USER_CODE" into PrdUser from ODRF INNER JOIN OUSR ON OUSR."USERID" = ODRF."UserSign" where ODRF."DocEntry"= :list_of_cols_val_tab_del and ODRF."ObjType"=60;

		SELECT Min(T0."VisOrder") INTO MinGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."ObjType"=60;
		SELECT Max(T0."VisOrder") INTO MaxGI from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."ObjType"=60;
		WHILE :MinGI<= :MaxGI DO
			(Select  T1."ItemCode",T1."U_IsFA",T0."WhsCode" into ItemCode,ISFA,FRWHS from DRF1 T0 JOIN OITM T1 ON T0."ItemCode" = T1."ItemCode" where T0."DocEntry"=list_of_cols_val_tab_del and T0."VisOrder"=MinGI and T0."ObjType"=60);
	          IF (ItemCode like 'NU%' and ISFA = 'Y' and PrdUser not in ('account7') and FRWHS NOT LIKE '%BT%') then
	                  error :=-1188;
	                  error_message := N''||ItemCode||' at Line-'||MinGI+1||' is Fixed Asset Item, you are not allowed to issue it.';
	         End If;
    MinGI := MinGI+1;
	END WHILE;
	end if;
End if;

IF (Object_Type = 'GPass') AND (:transaction_type = 'A') THEN
	error :=-1189;
	error_message := N'Please use the new process for RGP.';
END IF;

----------------------------------  OF Validations Om - 07/03/2025 ------------------------------------
/*IF Object_type = '20' and (:transaction_type ='A' or :transaction_type ='U') Then
DECLARE GRNItemCode nvarchar(50);
DECLARE GRNWhsCode nvarchar(50);
DECLARE MinIn int;
DECLARE MaxIn int;

	 SELECT Min(T0."VisOrder"),Max(T0."VisOrder") INTO MinIn,MaxIn from PDN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	 WHILE :MinIn <= :MaxIn DO
	(SELECT T0."ItemCode" into GRNItemCode FROM PDN1 T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."VisOrder" = MinIn);
	(SELECT T0."WhsCode" into GRNWhsCode FROM PDN1 T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."VisOrder" = MinIn);

	  	IF (GRNItemCode in ('OFFG0001', 'OFFG0002','OFFG0003', 'OFFG0004', 'OFFG0005', 'OFRM0001', 'OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013') and GRNWhsCode <> 'JW-OF') then
				error := -1195;
				error_message := N'Please Select JW-OF Warehouse for Aniline.';
		END IF;
		IF (GRNWhsCode = 'JW-OF' and GRNItemCode not in ('OFFG0001', 'OFFG0002','OFFG0003', 'OFFG0004', 'OFFG0005', 'OFRM0001', 'OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013', 'PCPM0019')) then
				error := -1196;
				error_message := N'Please Select Warehouse other than JW-OF.';
		END IF;
	  MinIn := MinIn + 1;
	END WHILE;
END IF;*/
    ----------------------------------------------------------
IF Object_type = '59' and (:transaction_type ='A' or :transaction_type ='U') Then
DECLARE ReceiptItemCode nvarchar(50);
DECLARE ReceiptWhsCode nvarchar(50);
DECLARE MinIn int;
DECLARE MaxIn int;
DECLARE ProdType nvarchar(5);

	 SELECT Min(T0."VisOrder"),Max(T0."VisOrder") INTO MinIn,MaxIn from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	 WHILE :MinIn <= :MaxIn DO
	 (SELECT T1."Type" into ProdType from IGN1 T0 join OWOR T1 on T0."BaseEntry" = T1."DocEntry" where T0."DocEntry" =:list_of_cols_val_tab_del and T0."VisOrder" = MinIn);
	 (SELECT T0."ItemCode" into ReceiptItemCode FROM IGN1 T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."VisOrder" = MinIn);
	 (SELECT T0."WhsCode" into ReceiptWhsCode FROM IGN1 T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."VisOrder" = MinIn);

	IF ProdType = 'S' then
	  	IF (ReceiptItemCode in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013') and ReceiptWhsCode not in ('JW-QC', 'OF-PORT')) then
				error := -1197;
				error_message := N'Please select proper Warehouse.';
		END IF;
		IF (ReceiptWhsCode in ('JW-QC', 'OF-PORT') and ReceiptItemCode not in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013')) then
				error := -1198;
				error_message := N'Please select proper Item.';
		END IF;
	END IF;
	IF ProdType = 'P' then
	  	IF (ReceiptItemCode in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013') and ReceiptWhsCode not in ('JW-QC','OF-PT-DI')) then
				error := -1199;
				error_message := N'Please select proper Warehouse.';
		END IF;
		IF (ReceiptWhsCode in ('JW-QC','OF-PT-DI') and ReceiptItemCode not in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013')) then
				error := -1200;
				error_message := N'Please select proper Item.';
		END IF;
	END IF;
		MinIn := MinIn + 1;
	END WHILE;
END IF;
    ----------------------------------------------------------

/*IF Object_type = '60' and (:transaction_type ='A' or :transaction_type ='U') Then
DECLARE IssueItemCode nvarchar(50);
DECLARE IssueWhsCode nvarchar(50);
DECLARE MinIn int;
DECLARE MaxIn int;

	 SELECT Min(T0."VisOrder"),Max(T0."VisOrder") INTO MinIn,MaxIn from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	 WHILE :MinIn <= :MaxIn DO
	(SELECT T0."ItemCode" into IssueItemCode FROM IGE1 T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."VisOrder" = MinIn);
	(SELECT T0."WhsCode" into IssueWhsCode FROM IGE1 T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."VisOrder" = MinIn);

	  	IF (IssueItemCode = 'OFRM0001' and IssueWhsCode <> 'JW-OF') then
				error := -1201;
				error_message := N'Please Select JW-OF Warehouse for Aniline.';
		END IF;
		IF (IssueWhsCode = 'JW-OF' and IssueItemCode <> 'OFRM0001') then
				error := -1202;
				error_message := N'Please Select Warehouse other than JW-OF.';
		END IF;
		MinIn := MinIn + 1;
	END WHILE;
END IF;*/

    ----------------------------------------------------------

IF Object_type = '202' and (:transaction_type ='A' or :transaction_type ='U') Then
DECLARE ProdOrderItemCode nvarchar(50);
DECLARE ProdOrderWhsCode nvarchar(50);
DECLARE ProdOrderType nvarchar(50);

	(SELECT T0."ItemCode" into ProdOrderItemCode FROM OWOR T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del);
	(SELECT T0."Warehouse" into ProdOrderWhsCode FROM OWOR T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del);
	(SELECT T0."Type" into ProdOrderType FROM OWOR T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del);


	IF ProdOrderType = 'S' then
	  	IF (ProdOrderItemCode in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013') and ProdOrderWhsCode not in ('JW-QC', 'OF-PORT')) then
				error := -1203;
				error_message := N'Please select proper Warehouse.';
		END IF;
		IF (ProdOrderWhsCode in ('JW-QC', 'OF-PORT') and ProdOrderItemCode not in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013')) then
				error := -1204;
				error_message := N'Please select proper Item.';
		END IF;
	END IF;
	IF ProdOrderType = 'P' then
	  	IF (ProdOrderItemCode in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013') and ProdOrderWhsCode not in ('JW-QC','OF-PT-DI')) then
				error := -1205;
				error_message := N'Please select proper Warehouse.';
		END IF;
		IF (ProdOrderWhsCode in ('JW-QC','OF-PT-DI') and ProdOrderItemCode not in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013')) then
				error := -1206;
				error_message := N'Please select proper Item.';
		END IF;
	END IF;
END IF;

    ----------------------------------------------------------

/*IF Object_type = '202' and (:transaction_type ='A' or :transaction_type ='U') Then
DECLARE ProdItemCode nvarchar(50);
DECLARE ProdWhsCode nvarchar(50);
DECLARE MinIn int;
DECLARE MaxIn int;

	 SELECT Min(T0."VisOrder"),Max(T0."VisOrder") INTO MinIn,MaxIn from WOR1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	 WHILE :MinIn <= :MaxIn DO
	(SELECT T0."ItemCode" into ProdItemCode FROM WOR1 T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."VisOrder" = MinIn);
	(SELECT T0."wareHouse" into ProdWhsCode FROM WOR1 T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."VisOrder" = MinIn);

	  	IF (ProdItemCode = 'OFRM0001' and ProdWhsCode <> 'JW-OF') then
				error := -1207;
				error_message := N'Please Select JW-OF Warehouse for Aniline.';
		END IF;
		IF (ProdWhsCode = 'JW-OF' and ProdItemCode <> 'OFRM0001') then
				error := -1208;
				error_message := N'Please Select Warehouse other than JW-OF.';
		END IF;
		MinIn := MinIn + 1;
	END WHILE;
END IF;*/

----------------------------------------------------------

IF object_type = 'Q_QCCH' AND (:transaction_type = 'A' Or :transaction_type = 'U') THEN

DECLARE LotNo Nvarchar(50);
DECLARE ItemCodee Nvarchar(25);
DECLARE TankerNo Nvarchar(25);
DECLARE Whsss Nvarchar(25);

		select T0."U_LotNo" INTO LotNo from "@Q_QCCH" T0 WHERE T0."Code" = :list_of_cols_val_tab_del;
		select T0."U_ItemCode" INTO ItemCodee from "@Q_QCCH" T0 WHERE T0."Code" = :list_of_cols_val_tab_del;
		select T0."U_TankerNum" INTO TankerNo from "@Q_QCCH" T0 WHERE T0."Code" = :list_of_cols_val_tab_del;
		select T0."U_AppWhs" INTO Whsss from "@Q_QCCH" T0 WHERE T0."Code" = :list_of_cols_val_tab_del;

		IF (LotNo is null or LotNo = '' or LotNo = ' ') and (ItemCodee in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013')) then
			error := -1209;
			error_message := N'Please enter Lot No.';
		END IF;
		IF (TankerNo is null or TankerNo = '' or TankerNo = ' ') and (ItemCodee in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013')) then
			error := -1209;
			error_message := N'Please enter Tanker No.';
		END IF;
		IF (ItemCodee in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013')) and (Whsss not in ('JW-OF', 'OF-PT-DI')) then
			error := -1209;
			error_message := N'Please enter proper warehouse.';
		END IF;
END IF;

-----------------------------------------------------------------------------------------------
IF Object_type = 'Q_QCCH' and (:transaction_type ='A' or :transaction_type ='U') Then

    DECLARE LotNo NVARCHAR(100);
    DECLARE PostDate DATE;
    DECLARE WhsCodee NVARCHAR(50);
    DECLARE WhsID NVARCHAR(50);
    DECLARE DocEntryy INT;
    DECLARE FormattedDate NVARCHAR(6);
    DECLARE FormattedDocEntry NVARCHAR(5);
    DECLARE ExpectedLotNo NVARCHAR(100);
    DECLARE TempDocEntry NVARCHAR(20);
    DECLARE LeadingZeros NVARCHAR(5);
    DECLARE Day_Part NVARCHAR(2);
    DECLARE Month_Part NVARCHAR(2);
    DECLARE Year_Part NVARCHAR(2);
    DECLARE ItemCodee NVARCHAR(10);

    SELECT
        "@Q_QCCH"."U_LotNo",
        "@Q_QCCH"."U_CompDate",
        "@Q_QCCH"."U_AppWhs",
        "@Q_QCCH"."U_Number",
        "@Q_QCCH"."U_ItemCode"
    INTO
        LotNo,
        PostDate,
        WhsCodee,
        DocEntryy,
        ItemCodee
    FROM "@Q_QCCH"
    WHERE "Code" = :list_of_cols_val_tab_del;

    SELECT "U_WhsID" INTO WhsID FROM OWHS WHERE "WhsCode" = WhsCodee;

    Day_Part := SUBSTRING(TO_VARCHAR(PostDate, 'DD.MM.YYYY'), 1, 2);
    Month_Part := SUBSTRING(TO_VARCHAR(PostDate, 'DD.MM.YYYY'), 4, 2);
    Year_Part := SUBSTRING(TO_VARCHAR(PostDate, 'DD.MM.YYYY'), 9, 2);
    FormattedDate := Day_Part || Month_Part || Year_Part;

    TempDocEntry := TO_VARCHAR(DocEntryy);

    IF LENGTH(TempDocEntry) = 1 THEN
        LeadingZeros := '0000';
    ELSEIF LENGTH(TempDocEntry) = 2 THEN
        LeadingZeros := '000';
    ELSEIF LENGTH(TempDocEntry) = 3 THEN
        LeadingZeros := '00';
    ELSEIF LENGTH(TempDocEntry) = 4 THEN
        LeadingZeros := '0';
    ELSE
        LeadingZeros := '';
    END IF;

    FormattedDocEntry := LeadingZeros || TempDocEntry;

    ExpectedLotNo := 'M' || FormattedDate || '/' || WhsID || '/' || FormattedDocEntry;

    if LotNo <> ExpectedLotNo and ItemCodee in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013') then
    	error := -1210;
    	error_message := N'Incorrect Lot Number Format.   ' || 'Expected: ' || ExpectedLotNo;
    END IF;
END IF;

----------------------------------------------------------------------------------------------------------------

IF Object_type = '59' and (:transaction_type ='A' or :transaction_type ='U') Then
DECLARE ReceiptItemCode nvarchar(50);
DECLARE ReportNum nvarchar(50);
DECLARE MinIn int;
DECLARE MaxIn int;

	 SELECT Min(T0."VisOrder"),Max(T0."VisOrder") INTO MinIn,MaxIn from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	 WHILE :MinIn <= :MaxIn DO
	 (SELECT T0."ItemCode" into ReceiptItemCode FROM IGN1 T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."VisOrder" = MinIn);
	 (SELECT T1."U_Report_Num" into ReportNum FROM IGN1 T0 join OIGN T1 on T0."DocEntry" = T1."DocEntry" WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."VisOrder" = MinIn);

	  	IF (ReceiptItemCode in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013') and (ReportNum is null or ReportNum  = '' or ReportNum = ' ')) then
				error := -1211;
				error_message := N'Please select Report Num.';
		END IF;
		IF ((ReportNum is null or ReportNum  = '' or ReportNum = ' ') and ReceiptItemCode in ('OFFG0009', 'OFFG0010', 'OFFG0011', 'OFFG0012', 'OFFG0013')) then
				error := -1212;
				error_message := N'Please select Report Num.';
		END IF;
		MinIn := MinIn + 1;
	END WHILE;
END IF;

IF :object_type IN ('17','15') AND (:transaction_type = 'A')
THEN
    DECLARE cnt INT := 0;

    IF :object_type = '17' THEN
        SELECT COUNT(*) INTO   cnt FROM ORDR AS T0
        JOIN "@ADVERSELISTECGC" AS T1 ON T0."CardCode" = T1."U_CardCode"
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del
          AND  T0."GroupNum"   NOT IN ('79','20','34')
          AND  T1."U_Adverse_List" = 'Yes';
    ELSEIF :object_type = '15' THEN
        SELECT COUNT(*) INTO   cnt FROM ODLN AS T0
        JOIN "@ADVERSELISTECGC" AS T1 ON T0."CardCode" = T1."U_CardCode"
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del
          AND  T0."GroupNum"   NOT IN ('79','20','34')
          AND  T1."U_Adverse_List" = 'Yes';
    END IF;

    IF cnt > 0 THEN
        error := -1130;
        error_message := 'Customer is in Adverse List.';
    END IF;
END IF;

IF :object_type = '112' AND (:transaction_type = 'A')
THEN
    DECLARE cnt INT := 0;
        SELECT COUNT(*) INTO cnt FROM ODRF AS T0
        JOIN "@ADVERSELISTECGC" AS T1 ON T0."CardCode" = T1."U_CardCode"
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del
          AND  T0."GroupNum"   NOT IN ('79','20','34')
          AND  T1."U_Adverse_List" = 'Yes' AND T0."ObjType" IN ('17','15');

    IF cnt > 0 THEN
        error := -1131;
        error_message := 'Customer is in Adverse List. [DRAFT]';
    END IF;
END IF;

---------------------------------  NMA Validation  ---------------------------------------------------------

IF Object_type = '60' and (:transaction_type ='A' or :transaction_type ='U') Then
DECLARE RecWhs nvarchar(50);
DECLARE MinIn int;
DECLARE MaxIn int;
DECLARE ProdType nvarchar(5);
DECLARE BaseTypee int;
DECLARE JwQty1 int;
DECLARE JwQty2 int;
DECLARE JwQty3 int;
DECLARE JwQty4 int;
DECLARE JwQty5 int;
DECLARE JcQty1 int;
DECLARE JcQty2 int;
DECLARE JcQty3 int;
DECLARE Qty int;

	 SELECT count(T0."BaseEntry") into BaseTypee from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."BaseType" = '202';

	 if BaseTypee > 0 then
	 SELECT Min(T0."VisOrder"),Max(T0."VisOrder") INTO MinIn,MaxIn from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	 WHILE :MinIn <= :MaxIn DO
	(SELECT T1."Type" into ProdType from IGE1 T0 join OWOR T1 on T0."BaseEntry" = T1."DocEntry" where T0."DocEntry" =:list_of_cols_val_tab_del and T0."VisOrder" = MinIn and T0."BaseType" = '202');
	(SELECT T1."Warehouse" into RecWhs from IGE1 T0 join OWOR T1 on T0."BaseEntry" = T1."DocEntry" where T0."DocEntry" =:list_of_cols_val_tab_del and T0."VisOrder" = MinIn and T0."BaseType" = '202');
	 SELECT T0."U_JWQty1" INTO JwQty1 from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."VisOrder" = MinIn;
	 SELECT T0."U_JWQty2" INTO JwQty2 from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."VisOrder" = MinIn;
	 SELECT T0."U_JWQty3" INTO JwQty3 from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."VisOrder" = MinIn;
 	 SELECT T0."U_JWQty4" INTO JwQty4 from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."VisOrder" = MinIn;
 	 SELECT T0."U_JWQty5" INTO JwQty5 from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."VisOrder" = MinIn;
	 SELECT T0."U_JCQty1" INTO JcQty1 from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."VisOrder" = MinIn;
	 SELECT T0."U_JCQty2" INTO JcQty2 from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."VisOrder" = MinIn;
	 SELECT T0."U_JCQty3" INTO JcQty3 from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."VisOrder" = MinIn;
	 SELECT T0."Quantity" INTO Qty from IGE1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."VisOrder" = MinIn;

	IF ProdType = 'S' and RecWhs in ('OF-PORT', 'JW-QC') then
	  	IF (COALESCE(JwQty1, 0) + COALESCE(JwQty2, 0) + COALESCE(JwQty3, 0) + COALESCE(JwQty4, 0) + COALESCE(JwQty5, 0) + COALESCE(JcQty1, 0) + COALESCE(JcQty2, 0) + COALESCE(JcQty3, 0)) <> COALESCE(Qty, 0) THEN
	  		error := -1132;
	  		error_message := 'Issue Qty not equal to Jobwork Challan Qty';
	  	END IF;
	END IF;
		MinIn := MinIn + 1;
	END WHILE;
	END IF;
END IF;


--------------------------------------------------------------------
IF Object_type = '59' and (:transaction_type ='A' or :transaction_type ='U') Then
DECLARE ReceiptWhsCode nvarchar(50);
DECLARE MinIn int;
DECLARE MaxIn int;
DECLARE ProdType nvarchar(5);
DECLARE BaseTypee int;
DECLARE SubChNo nvarchar(50);
DECLARE SubChDt nvarchar(25);

	 SELECT count(T0."BaseEntry") into BaseTypee from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del and T0."BaseType" = '202';

	 if BaseTypee > 0 then
	 SELECT Min(T0."VisOrder"),Max(T0."VisOrder") INTO MinIn,MaxIn from IGN1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	 WHILE :MinIn <= :MaxIn DO
	 (SELECT T1."Type" into ProdType from IGN1 T0 join OWOR T1 on T0."BaseEntry" = T1."DocEntry" where T0."DocEntry" =:list_of_cols_val_tab_del and T0."VisOrder" = MinIn and T0."BaseType" = '202');
	 (SELECT T0."WhsCode" into ReceiptWhsCode FROM IGN1 T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."VisOrder" = MinIn);
	 (SELECT count(T0."U_UNE_CHNO") into SubChNo FROM OIGN T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del);
	 (SELECT count(T0."U_UNE_CHDT") into SubChDt FROM OIGN T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del);

	IF ProdType = 'S' and ReceiptWhsCode in ('OF-PORT', 'JW-QC') then
	  	IF (SubChNo = 0) then
				error := -1133;
				error_message := N'Please select Subsidiary Challan No.';
		END IF;
		IF (SubChDt = 0) then
				error := -1134;
				error_message := N'Please select Subsidiary Challan Date.';
		END IF;
	END IF;
		MinIn := MinIn + 1;
	END WHILE;
	END IF;
END IF;
-----------------------A/P Invoice attachment blank------------------
IF (:object_type = '18' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN
Declare Temp INT;
    SELECT COUNT(*) INTO Temp FROM OPCH WHERE "DocEntry" = :list_of_cols_val_tab_del AND "AtcEntry" IS NULL;
    IF :Temp > 0 THEN
        error := -1132;
        error_message := 'Attachment is missing. Please attach the document.';
    END IF;
END IF;

-----------------------A/P Invoice attachment blank Draft------------------
IF (:object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U')) THEN
    DECLARE Temp INT;
    SELECT COUNT(*) INTO Temp FROM ODRF WHERE "DocEntry" = :list_of_cols_val_tab_del AND "ObjType" = '18'  AND "AtcEntry" IS NULL;

    IF :Temp > 0 THEN
        error := -1133;
        error_message := 'Attachment is missing. Please attach the document.';
    END IF;
END IF;
-------------------------Journal Voucher attachment Compulsory------------
IF (:object_type = '30') AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
DECLARE has_attachment INT;
        -- Check if the U_AttachmentLink field is filled
        SELECT count(*) INTO has_attachment FROM OJDT WHERE "TransId" = :list_of_cols_val_tab_del AND "TransType"='30' AND "AtcEntry" IS NULL;  -- Or use DocEntry if your system uses it as the key

        IF has_attachment>0 THEN
            error := -1134;
            error_message := 'Attachment is required for Journal Voucher.';
        END IF;
END IF;

---------------------------------- AMC Service PO ---------------------------------------------------------

/*IF Object_type = '112' and (:transaction_type ='A' or :transaction_type ='U' ) Then

Declare Itemm nvarchar(25);
DECLARE MINN int;
DECLARE MAXX int;
Declare Amc int;

(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del);
IF DraftObj = 22 THEN

Select MIN(T0."VisOrder") into MINN from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=22;
Select MAX(T0."VisOrder") into MAXX from DRF1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType"=22;
	WHILE MINN<=MAXX DO
		select DRF1."ItemCode" into Itemm from DRF1 WHERE DRF1."DocEntry" = :list_of_cols_val_tab_del and DRF1."VisOrder" = MINN and DRF1."ObjType"=22;
		select count(ODRF."U_AMC") into Amc from ODRF WHERE ODRF."DocEntry" = :list_of_cols_val_tab_del and ODRF."ObjType"=22;
		if Itemm like 'SER%' and Amc = 0 then
			error := -1135;
			error_message := 'Please select AMC Yes/No';
		end if;
	MINN = MINN + 1;
	END WHILE;
END IF;
END IF;

-----------------------------------------------

IF Object_type = '22' and (:transaction_type ='A' or :transaction_type ='U' ) Then

Declare Itemm nvarchar(25);
DECLARE MINN int;
DECLARE MAXX int;
Declare Amc int;

Select MIN(T0."VisOrder") into MINN from POR1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
Select MAX(T0."VisOrder") into MAXX from POR1 T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
	WHILE MINN<=MAXX DO
		select POR1."ItemCode" into Itemm from POR1 WHERE POR1."DocEntry" = :list_of_cols_val_tab_del and POR1."VisOrder" = MINN;
		select count(OPOR."U_AMC") into Amc from OPOR WHERE OPOR."DocEntry" = :list_of_cols_val_tab_del;
		if Itemm like 'SER%' and Amc = 0 then
			error := -1136;
			error_message := 'Please select AMC Yes/No';
		end if;
	MINN = MINN + 1;
	END WHILE;
END IF;*/

--------------------Equipment---------------------------
IF :object_type = '176' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
  DECLARE eq_bp NVARCHAR(20);
  DECLARE eq_item NVARCHAR(50);
  DECLARE eq_inv NVARCHAR(20);
  DECLARE eq_bp_name NVARCHAR(100);
  DECLARE inv_match INT;

  -- Get values from Equipment Card
  SELECT "customer", "itemCode", "U_LinkARI", "custmrName" INTO eq_bp, eq_item, eq_inv, eq_bp_name FROM "OINS" WHERE "insID" = :list_of_cols_val_tab_del;

  -- Bypass condition: if item is 'SER' and customer name is 'SAMPLE'
  IF NOT (:eq_item Like 'SER%' AND :eq_bp_name Like 'Sample%') THEN
    -- Check if selected Invoice has same BP and Item
    SELECT COUNT(*) INTO inv_match FROM "OINV" H
    INNER JOIN "INV1" L ON H."DocEntry" = L."DocEntry"
	INNER JOIN NNM1 N ON N."Series"=H."Series"
    WHERE Concat(Replace(N."SeriesName",'/',''),H."DocNum") = :eq_inv
      AND H."CardCode" = :eq_bp
      AND L."ItemCode" = :eq_item;

    -- If no match, raise error
    IF :inv_match = 0 THEN
      error := 2001;
      error_message := 'Selected Invoice does not match the selected BP and Item.';
    END IF;
  END IF;
END IF;

IF :object_type = '17' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
    DECLARE CustomerRef NVARCHAR(100);
    DECLARE TotalQty INT;
    DECLARE SumQty INT;
    DECLARE OtherTotalQty INT;
    DECLARE SODate DATE;
    DECLARE CustomerRefDate DATE;
    DECLARE CombinedRef NVARCHAR(150);

    SELECT T0."NumAtCard", T0."U_BP_TotalQty", T0."DocDate", T0."TaxDate" INTO CustomerRef, TotalQty, SODate, CustomerRefDate
    FROM ORDR T0 WHERE T0."CardCode" LIKE 'C%' AND T0."DocEntry" = :list_of_cols_val_tab_del;

    IF SODate >= '2025-12-10' THEN
	    CustomerRef := CustomerRef || '_' || TO_NVARCHAR(CustomerRefDate,'DD/MM/YYYY');
	END IF;

    IF SODate < '2025-12-10' THEN

		SELECT SUM(T1."Quantity") INTO SumQty FROM ORDR H INNER JOIN RDR1 T1 ON H."DocEntry" = T1."DocEntry" WHERE H."NumAtCard" = CustomerRef AND H."CANCELED" = 'N';

	    IF IFNULL(TotalQty,0) = 0 THEN
	        error := -1222;
	        error_message := 'Customer Total Quantity cannot be empty.';
	    ELSEIF IFNULL(SumQty,0) > IFNULL(TotalQty,0) THEN
	        error := -1223;
	        error_message := 'Total Order Qty exceeds Customer''s PO ( '||CustomerRef||' PO Qty: '|| TotalQty ||' ) - By '|| IFNULL(SumQty,0) - IFNULL(TotalQty,0) ||'.';
	    END IF;

	    SELECT MAX(H."U_BP_TotalQty") INTO OtherTotalQty FROM ORDR H WHERE H."NumAtCard" = CustomerRef AND H."CANCELED" = 'N' AND H."DocEntry" <> :list_of_cols_val_tab_del;

	    IF OtherTotalQty IS NOT NULL AND IFNULL(OtherTotalQty,0) <> IFNULL(TotalQty,0) THEN
	        error := -1224;
	        error_message := 'Customer Total Quantity must match across all Sales Orders with the same Customer Reference No. ( '|| OtherTotalQty || ' Qty).';
	    END IF;

	ELSE

		SELECT SUM(T1."Quantity") INTO SumQty FROM ORDR H INNER JOIN RDR1 T1 ON H."DocEntry" = T1."DocEntry" WHERE (H."NumAtCard" || '_' || TO_NVARCHAR(H."TaxDate",'DD/MM/YYYY')) = CustomerRef AND H."CANCELED" = 'N';
		SELECT MAX(H."U_BP_TotalQty") INTO OtherTotalQty FROM ORDR H WHERE H."NumAtCard" = CustomerRef AND H."CANCELED" = 'N' AND H."DocEntry" <> :list_of_cols_val_tab_del;

		IF IFNULL(CustomerRefDate,'')='' THEN
			error := -1225;
			error_message := 'Please mention Customer Ref. Date.';
		END IF;

		IF UPPER(CustomerRef) like '%D%T%' THEN
			error := -1226;
			error_message := 'Please do not write date in Customer Ref. No., write it in Customer Ref. Date.';
		END IF;

		IF IFNULL(TotalQty,0) = 0 THEN
	        error := -1227;
	        error_message := 'Customer Total Quantity cannot be empty.';
	    ELSEIF IFNULL(SumQty,0) > IFNULL(TotalQty,0) THEN
	        error := -1228;
	        error_message := 'Total Order Qty exceeds Customer''s PO ( '||CustomerRef||' PO Qty: '|| TotalQty ||' ) - By '|| (IFNULL(SumQty,0) - IFNULL(TotalQty,0)) ||'.';
	    END IF;

	    IF OtherTotalQty IS NOT NULL AND IFNULL(OtherTotalQty,0) <> IFNULL(TotalQty,0) THEN
	        error := -1229;
	        error_message := 'Customer Total Quantity must match across all Sales Orders with the same Customer Reference No. ( '|| OtherTotalQty || ' Qty).';
	    END IF;

	END IF;

END IF;

IF :object_type = '112' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
	SELECT T0."ObjType" INTO DraftObj FROM ODRF T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

	IF DraftObj = 17 THEN
		DECLARE CustomerRef NVARCHAR(100);
        DECLARE TotalQty INT;
        DECLARE DraftQty INT;
        DECLARE ApprovedDraftQty INT;
        DECLARE OrderQty INT;
        DECLARE SumQty INT;
        DECLARE OtherTotalQtyMax INT;
        DECLARE OtherTotalQtyMin INT;
        DECLARE ApprovalEntry INT;
        DECLARE SODate DATE;
        DECLARE CustomerRefDate DATE;

	    SELECT T0."NumAtCard", T0."U_BP_TotalQty", T0."DocDate", T0."TaxDate" INTO CustomerRef, TotalQty, SODate, CustomerRefDate FROM ODRF T0 WHERE T0."CardCode" LIKE 'C%' AND T0."DocEntry" = :list_of_cols_val_tab_del and T0."ObjType" = 17;

	    IF SODate >= '2025-12-10' THEN
	    	CustomerRef := CustomerRef || '_' || TO_NVARCHAR(CustomerRefDate,'DD/MM/YYYY');
	    END IF;

	    IF :transaction_type = 'A' THEN

		    SELECT MAX("U_BP_TotalQty"),MIN("U_BP_TotalQty") INTO OtherTotalQtyMax,OtherTotalQtyMin FROM
		    (
		    	SELECT H."U_BP_TotalQty" FROM ORDR H WHERE H."NumAtCard" = CustomerRef AND H."CANCELED" = 'N'

		    	UNION ALL

		    	SELECT H."U_BP_TotalQty"
		    	FROM ODRF H INNER JOIN DRF1 T1 ON H."DocEntry" = T1."DocEntry"
		        LEFT JOIN OWDD W ON W."DraftEntry" = H."DocEntry" AND W."ObjType" = H."ObjType"
		        LEFT JOIN ORDR O ON O."DocEntry" = W."DocEntry" AND O."ObjType" = W."ObjType"
		        WHERE H."NumAtCard" = CustomerRef AND H."CANCELED" = 'N' AND H."ObjType" = 17 AND IFNULL(W."Status",'W') = 'W' AND IFNULL(O."CANCELED",'N') = 'N'
			);

	    ELSEIF :transaction_type = 'U' THEN

	    	SELECT MAX("U_BP_TotalQty"),MIN("U_BP_TotalQty") INTO OtherTotalQtyMax,OtherTotalQtyMin FROM
		    (SELECT H."U_BP_TotalQty" FROM ORDR H WHERE H."NumAtCard" = CustomerRef AND H."CANCELED" = 'N'

		    	UNION ALL

		    	SELECT H."U_BP_TotalQty"
		    	FROM ODRF H INNER JOIN DRF1 T1 ON H."DocEntry" = T1."DocEntry"
		        LEFT JOIN OWDD W ON W."DraftEntry" = H."DocEntry" AND W."ObjType" = H."ObjType"
		        LEFT JOIN ORDR O ON O."DocEntry" = W."DocEntry" AND O."ObjType" = W."ObjType"
		        WHERE H."NumAtCard" = CustomerRef AND H."CANCELED" = 'N' AND H."ObjType" = 17 AND IFNULL(W."Status",'W') = 'W' AND IFNULL(O."CANCELED",'N') = 'N' AND W."DocEntry" <> :list_of_cols_val_tab_del);

	    END IF;

	    IF (OtherTotalQtyMax IS NOT NULL AND OtherTotalQtyMin IS NOT NULL) AND ((IFNULL(OtherTotalQtyMax,0) <> IFNULL(TotalQty,0)) OR (IFNULL(OtherTotalQtyMin,0) <> IFNULL(TotalQty,0))) THEN
			error := -1230;
		    error_message := 'Customer Total Quantity must match across all Sales Orders with the same Customer Reference No. ( '|| IFNULL(OtherTotalQtyMax,OtherTotalQtyMin) || ' Qty).';

		ELSE
		    IF SODate < '2025-12-10' THEN

			    -- Draft Qty (exclude Rejected drafts from WDD1, Drafts punched and then rejected) --
			    SELECT COALESCE(SUM(T1."Quantity"),0) INTO DraftQty
		        FROM ODRF H INNER JOIN DRF1 T1 ON H."DocEntry" = T1."DocEntry"
		        LEFT JOIN OWDD W ON W."DraftEntry" = H."DocEntry" AND W."ObjType" = H."ObjType"
		        LEFT JOIN ORDR O ON O."DocEntry" = W."DocEntry" AND O."ObjType" = W."ObjType"
		        WHERE H."NumAtCard" = CustomerRef AND H."CANCELED" = 'N' AND H."ObjType" = 17 AND IFNULL(W."Status",'W') = 'W' AND IFNULL(O."CANCELED",'N') = 'N';

		        -- Approved Draft Qty --
				SELECT COALESCE(SUM(T1."Quantity"),0) INTO ApprovedDraftQty
		        FROM ODRF H INNER JOIN DRF1 T1 ON H."DocEntry" = T1."DocEntry"
		        LEFT JOIN OWDD W ON W."DraftEntry" = H."DocEntry" AND W."ObjType" = H."ObjType"
		        LEFT JOIN ORDR O ON O."DocEntry" = W."DocEntry" AND O."ObjType" = W."ObjType"
		        WHERE H."NumAtCard" = CustomerRef AND H."CANCELED" = 'N' AND H."ObjType" = 17 AND IFNULL(W."Status",'W') = 'Y' AND O."DocEntry" IS NULL;

				-- Confirmed order quantities --
		        SELECT COALESCE(SUM(R1."Quantity"),0) INTO OrderQty
		        FROM ORDR R0 INNER JOIN RDR1 R1 ON R1."DocEntry" = R0."DocEntry"
		        WHERE R0."NumAtCard" = CustomerRef AND IFNULL(R0."CANCELED",'N') = 'N'
		        AND R0."DocEntry" NOT IN (SELECT W."DocEntry"
		        							FROM ODRF H INNER JOIN DRF1 T1 ON H."DocEntry" = T1."DocEntry"
									        LEFT JOIN OWDD W ON W."DraftEntry" = H."DocEntry" AND W."ObjType" = H."ObjType"
									        LEFT JOIN ORDR O ON O."DocEntry" = W."DocEntry" AND O."ObjType" = W."ObjType"
									        WHERE H."NumAtCard" = CustomerRef AND H."CANCELED" = 'N' AND H."ObjType" = 17 AND IFNULL(W."Status",'W') = 'W' AND IFNULL(O."CANCELED",'N') = 'N'
									        GROUP BY W."DocEntry");

				SumQty := DraftQty + OrderQty + ApprovedDraftQty;

				IF IFNULL(TotalQty,0) = 0 THEN
			        error := -1231;
			        error_message := 'Customer Total Quantity cannot be empty.';
			    ELSEIF IFNULL(SumQty,0) > IFNULL(TotalQty,0) THEN
			        error := -1232;
			        error_message := 'Total Order Qty exceeds Customer''s PO ( '||CustomerRef||' PO Qty: '|| TotalQty ||' ) - By '|| IFNULL(SumQty,0) - IFNULL(TotalQty,0) ||'.';
			    END IF;
			ELSE

			    -- Draft Qty (exclude Rejected drafts from WDD1, Drafts punched and then rejected) --
			    SELECT COALESCE(SUM(T1."Quantity"),0) INTO DraftQty
		        FROM ODRF H INNER JOIN DRF1 T1 ON H."DocEntry" = T1."DocEntry"
		        LEFT JOIN OWDD W ON W."DraftEntry" = H."DocEntry" AND W."ObjType" = H."ObjType"
		        LEFT JOIN ORDR O ON O."DocEntry" = W."DocEntry" AND O."ObjType" = W."ObjType"
		        WHERE (H."NumAtCard" || '_' || TO_NVARCHAR(H."TaxDate",'DD/MM/YYYY')) = CustomerRef AND H."CANCELED" = 'N' AND H."ObjType" = 17
		        AND IFNULL(W."Status",'W') = 'W' AND IFNULL(O."CANCELED",'N') = 'N';

		        -- Approved Draft Qty --
				SELECT COALESCE(SUM(T1."Quantity"),0) INTO ApprovedDraftQty
		        FROM ODRF H INNER JOIN DRF1 T1 ON H."DocEntry" = T1."DocEntry"
		        LEFT JOIN OWDD W ON W."DraftEntry" = H."DocEntry" AND W."ObjType" = H."ObjType"
		        LEFT JOIN ORDR O ON O."DocEntry" = W."DocEntry" AND O."ObjType" = W."ObjType"
		        WHERE (H."NumAtCard" || '_' || TO_NVARCHAR(H."TaxDate",'DD/MM/YYYY')) = CustomerRef AND H."CANCELED" = 'N' AND H."ObjType" = 17 AND IFNULL(W."Status",'W') = 'Y' AND O."DocEntry" IS NULL;

			    -- Confirmed order quantities --
		        SELECT COALESCE(SUM(R1."Quantity"),0) INTO OrderQty
		        FROM ORDR R0 INNER JOIN RDR1 R1 ON R1."DocEntry" = R0."DocEntry"
		        WHERE (R0."NumAtCard" || '_' || TO_NVARCHAR(R0."TaxDate",'DD/MM/YYYY')) = CustomerRef AND IFNULL(R0."CANCELED",'N') = 'N'
		        AND R0."DocEntry" NOT IN (SELECT W."DocEntry"
		        							FROM ODRF H INNER JOIN DRF1 T1 ON H."DocEntry" = T1."DocEntry"
									        LEFT JOIN OWDD W ON W."DraftEntry" = H."DocEntry" AND W."ObjType" = H."ObjType"
									        LEFT JOIN ORDR O ON O."DocEntry" = W."DocEntry" AND O."ObjType" = W."ObjType"
									        WHERE (H."NumAtCard" || '_' || TO_NVARCHAR(H."TaxDate",'DD/MM/YYYY')) = CustomerRef AND H."CANCELED" = 'N' AND H."ObjType" = 17 AND IFNULL(W."Status",'W') = 'W' AND IFNULL(O."CANCELED",'N') = 'N'
									        GROUP BY W."DocEntry");
				SumQty := DraftQty + OrderQty + ApprovedDraftQty;
				IF IFNULL(CustomerRefDate,'')='' THEN
					error := -1233;
					error_message := 'Please mention Customer Ref. Date.';
				END IF;

				IF UPPER(CustomerRef) like '%D%T%' THEN
					error := -1234;
					error_message := 'Please do not write date in Customer Ref. No., write it in Customer Ref. Date.';
				END IF;

				IF IFNULL(TotalQty,0) = 0 THEN
			        error := -1235;
			        error_message := 'Customer Total Quantity cannot be empty.';
			    ELSEIF IFNULL(SumQty,0) > IFNULL(TotalQty,0) THEN
			        error := -1236;
			        error_message := 'Total Order Qty exceeds Customer''s PO ( '||CustomerRef||' PO Qty: '|| TotalQty ||' ) - By '|| IFNULL(SumQty,0) - IFNULL(TotalQty,0) ||'.';
			    END IF;

			END IF;
		END IF;
	END IF;
END IF;

-----------Sales Return Request validation for warhouse and batch number-------------------
IF (:object_type = '234000031') AND (:transaction_type IN ('A', 'U')) THEN
    DECLARE v_Warehouse NVARCHAR(10);
    DECLARE v_BatchNum NVARCHAR(50);
    DECLARE v_MinVisOrder INT;
    DECLARE v_MaxVisOrder INT;
    DECLARE v_BatchCount INT;
    DECLARE v_ItemCode NVARCHAR(10);
    DECLARE v_CardCode NVARCHAR(10);
    DECLARE v_Currency NVARCHAR(10);
    DECLARE v_Series NVARCHAR(10);

    SELECT T0."CardCode",T0."DocCur",T1."SeriesName" INTO v_CardCode,v_Currency,v_Series FROM ORRR T0
    Inner Join NNM1 T1 on T0."Series"=T1."Series" WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

    IF (v_CardCode like 'CPE%' or v_CardCode like 'CSE%' or v_CardCode like 'COE%') and v_Series like 'DM%' THEN
            error := -1220;
            error_message := 'The Customer code is Export, you must select the EX series.';
	ELSEIF (v_CardCode like 'CPD%' or v_CardCode like 'CSD%' or v_CardCode like 'COD%') and v_Series like 'EX%' THEN
            error := -1221;
            error_message := 'The Customer code is Domestic, you must select the DM series.';
    END IF;

    -- Step 1: Get the minimum and maximum VisOrder for row-level iteration
    SELECT MIN(T1."VisOrder") INTO v_MinVisOrder FROM RRR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
    SELECT MAX(T1."VisOrder") INTO v_MaxVisOrder FROM RRR1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;

    -- Step 2: Iterate through the lines to validate batch number and warehouse
    WHILE v_MinVisOrder <= v_MaxVisOrder DO

        SELECT T1."WhsCode",T1."ItemCode" INTO v_Warehouse,v_ItemCode FROM RRR1 T1
        WHERE T1."DocEntry" = :list_of_cols_val_tab_del AND T1."VisOrder" = v_MinVisOrder;

        -- Step 4: Link with Batch table (IBT1_Link) to check if Batch number is populated
Select count(*) INTO v_BatchCount from RRR1 T1
Left Join IBT1_Link T4 on T1."ObjType"=T4."BaseType" and T1."DocEntry"=T4."BaseEntry" and T1."LineNum"=T4."BaseLinNum" and T1."ItemCode"=T4."ItemCode"  and T4."Direction"='2'
WHERE T4."BatchNum" is null and T1."DocEntry"=:list_of_cols_val_tab_del;

        -- Step 5: Validate that batch number is not empty for specific warehouses
        IF v_BatchCount > 0 THEN
            error := -1220;
            error_message := 'Batch Number cannot be empty in Sales Return Request.';
        END IF;

        IF v_Warehouse Not like '%QCR%' THEN
            error := -1221;
            error_message := 'You must select the QCR warehouse(PC-QCR,SC-QCR,2PC-QCR,OF-QCR)';
        END IF;

        -- Step 6: Increment to the next row in the Sales Return Request line
        v_MinVisOrder := v_MinVisOrder + 1;
    END WHILE;
END IF;
---------Sales Quotation field blank validaiton for Sample Invoice-------------
IF (:object_type = '23') AND (:transaction_type IN ('A', 'U')) THEN
    DECLARE v_DocNo NVARCHAR(100);
    DECLARE v_Consignee_Name NVARCHAR(100);
    DECLARE v_Consignee_Add NVARCHAR(254);
    DECLARE v_Notify_Party NVARCHAR(100);
    DECLARE v_Notify_Add NVARCHAR(254);
    DECLARE v_Incoterms NVARCHAR(100);
    DECLARE v_OriginCountry NVARCHAR(100);
    DECLARE v_DestinationCountry NVARCHAR(100);
    DECLARE v_DealNo NVARCHAR(100);
    DECLARE v_FreeSample NVARCHAR(3);
    DECLARE v_Remarks NVARCHAR(254);
    DECLARE v_Currency NVARCHAR(10);
    DECLARE v_Party NVARCHAR(254);
    DECLARE v_Series NVARCHAR(10);
    DECLARE v_U_UNE_DEPT NVARCHAR(50);
    DECLARE v_U_UNE_Buyer NVARCHAR(100);
    DECLARE v_DocDate Date;
    -- New mandatory field validations for QUT1 (Sales Quotation Line)
    DECLARE v_U_UNE_ITCD NVARCHAR(50);
    DECLARE v_U_FRTXT NVARCHAR(100);
    DECLARE v_U_PR_TYPE NVARCHAR(50);
    DECLARE v_TaxCode NVARCHAR(50);
    DECLARE v_Department NVARCHAR(50);
    DECLARE v_MINN INT;
    DECLARE v_MAXX INT;
    DECLARE v_ResFrCust NVARCHAR(15);
    DECLARE v_ReasonFail NVARCHAR(254);
    DECLARE v_ApprCOA NVARCHAR(5);
    DECLARE v_PSS NVARCHAR(5);
    DECLARE v_Batch NVARCHAR(100);

    -- Get values from OQUT table
    SELECT T0."U_Consignee_Name",T0."U_Consignee_Add",T0."U_Notify_Party",T0."U_Notify_add",T0."U_Incoterms",T0."U_OConName",T0."U_DConName",
        T0."U_FreeSample",T0."Comments",T0."CardName",T0."DocCur",Left(T1."SeriesName", 3),"U_UNE_Buyer_Name", T0."DocDate"
    INTO v_Consignee_Name,v_Consignee_Add,v_Notify_Party,v_Notify_Add,v_Incoterms,v_OriginCountry,v_DestinationCountry,
        v_FreeSample,v_Remarks,v_Party,v_Currency,v_Series,v_U_UNE_Buyer, v_DocDate
    FROM OQUT T0
    JOIN NNM1 T1 ON T0."Series" = T1."Series"
    WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

    -- Validate fields
    IF v_Consignee_Name IS NULL OR LENGTH(TRIM(v_Consignee_Name)) = 0 THEN
        error := -1202;
        error_message := 'Consignee Name cannot be empty.';
    ELSEIF v_Consignee_Add IS NULL OR LENGTH(TRIM(v_Consignee_Add)) = 0 THEN
        error := -1203;
        error_message := 'Consignee Address cannot be empty.';
    ELSEIF v_Notify_Party IS NULL OR LENGTH(TRIM(v_Notify_Party)) = 0 THEN
        error := -1204;
        error_message := 'Notify Party cannot be empty.';
    ELSEIF v_Notify_Add IS NULL OR LENGTH(TRIM(v_Notify_Add)) = 0 THEN
        error := -1205;
        error_message := 'Notify Address cannot be empty.';
    ELSEIF v_Incoterms IS NULL OR LENGTH(TRIM(v_Incoterms)) = 0 THEN
        error := -1206;
        error_message := 'Incoterms cannot be empty.';
    ELSEIF v_OriginCountry IS NULL OR LENGTH(TRIM(v_OriginCountry)) = 0 THEN
        error := -1207;
        error_message := 'Origin Country cannot be empty.';
    ELSEIF v_DestinationCountry IS NULL OR LENGTH(TRIM(v_DestinationCountry)) = 0 THEN
        error := -1208;
        error_message := 'Destination Country cannot be empty.';
    --ELSEIF v_DealNo IS NULL OR LENGTH(TRIM(v_DealNo)) = 0 THEN
        --error := -1209;
        --error_message := 'Deal No cannot be empty.';
    ELSEIF v_FreeSample IS NULL OR LENGTH(TRIM(v_FreeSample)) = 0 THEN
        error := -1210;
        error_message := 'Free Sample cannot be empty.';
    ELSEIF v_Currency = 'INR' and v_Party <> 'Sample Customer Domestic' THEN
        error := -1211;
        error_message := 'The Currency is INR, you have to select "Sample Customer Domestic".';
    ELSEIF v_Currency <> 'INR' and v_Party <> 'Sample Customer Export' THEN
        error := -1212;
        error_message := 'The Currency is not INR, you have to select "Sample Customer Export".';
    ELSEIF v_Party = 'Sample Customer Domestic' AND v_Series NOT IN ('SD1', 'SD2') THEN
        error := -1213;
        error_message := 'For Sample Customer Domestic, only SD1 or SD2 series are allowed.';
    ELSEIF v_Party = 'Sample Customer Export' AND v_Series NOT IN ('SE1', 'SE2') THEN
        error := -1214;
        error_message := 'For Sample Customer Export, only SE1 or SE2 series are allowed.';
    ELSEIF v_U_UNE_Buyer IS NULL OR LENGTH(TRIM(v_U_UNE_Buyer)) = 0 THEN
        error := -1214;
        error_message := 'Kindly enter the actual Buyer Name.';
	ELSEIF (days_between(v_DocDate, NOW()) > 1 AND :transaction_type = 'A') THEN
        error := -1214;
        error_message := 'Entry not allowed in back date.';
    END IF;

    -- Get the minimum and maximum VisOrder values for row iteration
    SELECT MIN(T1."VisOrder") INTO v_MINN FROM QUT1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
    SELECT MAX(T1."VisOrder") INTO v_MAXX FROM QUT1 T1 WHERE T1."DocEntry" = :list_of_cols_val_tab_del;
    -- Start the loop to validate each row in QUT1
    WHILE v_MINN <= v_MAXX DO
        -- Retrieve values from QUT1 for mandatory fields for the current row
        SELECT T1."U_UNE_ITCD",T1."U_FRTXT",T1."U_PR_Type",T1."TaxCode",T1."U_Department", T1."U_ResFrCust", T1."U_ReasonFail", T1."U_Deal_ID", T1."U_ApprOnCOA", T1."U_PSS", T1."U_NoOfBatchRequired"
        INTO v_U_UNE_ITCD,v_U_FRTXT,v_U_PR_TYPE,v_TaxCode,v_Department,v_ResFrCust, v_ReasonFail, v_DealNo, v_ApprCOA, v_PSS, v_Batch
        FROM QUT1 T1
        WHERE T1."DocEntry" = :list_of_cols_val_tab_del
        AND T1."VisOrder" = v_MINN;

        -- Check if mandatory fields are populated for the current row
        IF v_U_UNE_ITCD IS NULL OR LENGTH(TRIM(v_U_UNE_ITCD)) = 0 THEN
            error := -1215;
            error_message := 'Item Code cannot be empty in Sales Quotation line.';
        ELSEIF v_U_FRTXT IS NULL OR LENGTH(TRIM(v_U_FRTXT)) = 0 THEN
            error := -1216;
            error_message := 'Brand Name cannot be empty in Sales Quotation line.';
        ELSEIF v_U_PR_TYPE IS NULL OR LENGTH(TRIM(v_U_PR_TYPE)) = 0 THEN
            error := -1217;
            error_message := 'Sample Type cannot be empty in Sales Quotation line.';
        ELSEIF v_TaxCode IS NULL OR LENGTH(TRIM(v_TaxCode)) = 0 THEN
            error := -1218;
            error_message := 'Tax Code cannot be empty in Sales Quotation line.';
	    ELSEIF v_Department IS NULL OR LENGTH(TRIM(v_Department)) = 0 THEN
    	    error := -1219;
        	error_message := 'Department cannot be empty.';
        ELSEIF v_Department = 'QC' AND v_U_PR_TYPE <> 'Existing Product' THEN
        	error := -1220;
        	error_message := 'For QC Dept, only Existing Product is allowed.';
        ELSEIF v_Department = 'RND' AND v_U_PR_TYPE NOT IN ('Slight Customization', 'New Product Development', 'Trading') THEN
        	error := -1221;
        	error_message := 'Type of Sample not allowed for RND.';
        ELSEIF v_ResFrCust = 'Fail' AND (v_ReasonFail IS NULL OR LENGTH(TRIM(v_ReasonFail)) = 0) THEN
        	error := -1222;
        	error_message := 'Reason for Fail cannot be empty.';
        ELSEIF v_DealNo IS NULL OR LENGTH(TRIM(v_DealNo)) = 0 THEN
        	error := -1223;
        	error_message := 'Deal No cannot be empty at row level.';
        ELSEIF v_Department = 'QC' AND (v_ApprCOA IS NULL OR LENGTH(TRIM(v_ApprCOA)) = 0) THEN
        	error := -1224;
        	error_message := 'Please enter Approval on COA as department is QC.';
		ELSEIF v_Department = 'QC' AND (v_PSS IS NULL OR LENGTH(TRIM(v_PSS)) = 0) THEN
        	error := -1225;
        	error_message := 'Please enter PSS Yes/No as department is QC.';
        ELSEIF v_Batch IS NULL OR LENGTH(TRIM(v_Batch)) = 0 THEN
        	error := -1226;
        	error_message := 'Please enter No. of Batches Required.';
        END IF;
        -- Increment the line index to move to the next row
         v_MINN = v_MINN + 1;
    END WHILE;
END IF;

IF :object_type = '13' AND (:transaction_type ='U') THEN
DECLARE portCode NVARCHAR(50);
DECLARE ExportAR Nvarchar(50);
DECLARE PortLoad Nvarchar(50);

    SELECT "PortCode","ImpORExp" INTO portCode,ExportAR FROM INV12
    WHERE "DocEntry" = :list_of_cols_val_tab_del;

    -- Normalize and check
	IF ExportAR = 'Y' THEN
	    IF portCode IS NULL OR LENGTH(TRIM(portCode)) = 0 OR portCode not like'IN%' THEN
    	    error := -1245;
        	error_message := 'Invalid Port Code.';
	    END IF;

	END IF;
END IF;

--------------------------------- Sample Request AR Invoice -----------------------------------------
IF Object_type = '13' AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
    DECLARE MinAR INT;
    DECLARE MaxAR INT;
    DECLARE AREntryType NVARCHAR(50);
    DECLARE ARItemCode INT;
    DECLARE SampleNotReady INT;
    DECLARE SampleReqExists INT;
    DECLARE BaseEntry INT;
    DECLARE CardCode NVARCHAR(50);
    DECLARE QCDeptCount INT;

    -- Get CardCode from the invoice
    SELECT T0."CardCode" INTO CardCode
    FROM OINV T0
    WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

    -- Check if any line in the invoice comes from a Quotation with U_Department = 'QC'
    SELECT COUNT(*) INTO QCDeptCount
    FROM INV1 T1
    LEFT JOIN QUT1 T2 ON T1."BaseEntry" = T2."DocEntry" AND T1."BaseLine" = T2."LineNum" AND T1."BaseType" = 23
    WHERE T1."DocEntry" = :list_of_cols_val_tab_del
    AND T2."U_Department" = 'QC';

    -- Only proceed with validations if CardCode matches AND there's at least one QC department line
    IF (CardCode = 'CPD0359' OR CardCode = 'CPE0381') AND QCDeptCount > 0 THEN

        -- Get min and max VisOrder for looping through invoice lines
        SELECT MIN(T0."VisOrder") INTO MinAR
        FROM INV1 T0
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

        SELECT MAX(T0."VisOrder") INTO MaxAR
        FROM INV1 T0
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

        -- Loop through each invoice line
        WHILE MinAR <= MaxAR DO
            -- Get BaseEntry for current line
            SELECT T1."BaseEntry" INTO BaseEntry
            FROM INV1 T1
            WHERE T1."DocEntry" = :list_of_cols_val_tab_del
            AND T1."VisOrder" = MinAR;

            -- Check if Sample Request exists for this BaseEntry
            SELECT COUNT(*) INTO SampleReqExists
            FROM INV1 T1
            JOIN "@SAMPLEREQH" T2 ON T2."U_ReqDocEntry" = T1."BaseEntry"
            WHERE T1."DocEntry" = :list_of_cols_val_tab_del
            AND T1."VisOrder" = MinAR;

            IF SampleReqExists = 0 THEN
                error := 74;
                error_message := N'Sample Ready QC Entry not found for this invoice line.';
            END IF;

            -- Check if there are any samples not ready for this base entry (only if sample req exists)
            IF SampleReqExists > 0 THEN
                SELECT COUNT(*) INTO SampleNotReady
                FROM INV1 T1
                JOIN "@SAMPLEREQH" T2 ON T2."U_ReqDocEntry" = T1."BaseEntry"
                JOIN "@SAMPLEREQD" T3 ON T2."DocEntry" = T3."DocEntry"
                WHERE T1."DocEntry" = :list_of_cols_val_tab_del
                AND T1."VisOrder" = MinAR
                AND IFNULL(T3."U_SampleReady", '') <> 'Yes';

                IF SampleNotReady > 0 THEN
                    error := 73;
                    error_message := N'Sample is not ready. Cannot create AR Invoice until all samples are marked as Ready.';
                END IF;
            END IF;

            MinAR := MinAR + 1;
        END WHILE;

    END IF; -- End of CardCode and QC Department check

END IF;

------------------------------------------ SAMPLE REQUEST (UDO) VLAIDATIONS ---------------------------------------
IF (:object_type = 'SPLREQ') AND (:transaction_type = 'U') THEN

DECLARE TEMP_COUNTER INT;
DECLARE DocDate Date;

SELECT T0."U_DocDate" INTO DocDate FROM "@SAMPLEREQH" T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
SELECT DAYS_BETWEEN(:DocDate, NOW()) INTO TEMP_COUNTER FROM DUMMY;
	IF :TEMP_COUNTER > 0 THEN
		error := -1237;
		error_message := N'Not allowed to Update.';
	END IF;
END IF;


IF (:object_type = 'SPLREQ') AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

DECLARE TEMP_COUNTER INT;
DECLARE DocDate Date;

SELECT T0."U_DocDate" INTO DocDate FROM "@SAMPLEREQH" T0 WHERE T0."DocEntry" = :list_of_cols_val_tab_del;
SELECT DAYS_BETWEEN(:DocDate, CURRENT_DATE) INTO TEMP_COUNTER FROM DUMMY;
	IF :TEMP_COUNTER > 0 THEN
		error := -1238;
		error_message := N'Document Date must be equal to Current Date.';
	END IF;
END IF;

IF object_type = 'SPLREQ' AND (:transaction_type = 'A' or :transaction_type = 'U')   THEN

DECLARE UserID nvarchar(50);

	SELECT T0."UserSign" Into UserID  FROM "@SAMPLEREQH" T0 WHERE T0."DocEntry" = list_of_cols_val_tab_del;
	IF UserID not in (56) THEN
		error := -1239;
		error_message := 'You are not allowed to Update the document';
	END IF;

END IF;


IF (:object_type = 'SPLREQ') AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN

    DECLARE TEMP_COUNTER INT;
    DECLARE DocDate Date;
    DECLARE DocDateCt INT;
    DECLARE SampleNo INT;
    DECLARE SampleDocEntry INT;
    DECLARE ItemDetails INT;
    DECLARE ItemCode INT;
    DECLARE BrandName INT;
    DECLARE TypeSample INT;
    DECLARE Packing INT;
    DECLARE Qty INT;
    DECLARE UoM INT;
    DECLARE SampleReadyCt INT;
    DECLARE SampleReady VARCHAR(5);
    DECLARE SampleReadyDate INT;
    DECLARE MaxLine INT;
    DECLARE MinLine INT;
    DECLARE Status NVARCHAR(50);

    -- Get max and min line numbers
    SELECT max(T1."VisOrder"), min(T1."VisOrder")
    INTO MaxLine, MinLine
    FROM "@SAMPLEREQH" T0
    JOIN "@SAMPLEREQD" T1 ON T0."DocEntry" = T1."DocEntry"
    WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

    -- Loop through each line
    WHILE MinLine <= MaxLine DO

        -- Get data for current line
        SELECT T1."U_SampleDate"
        INTO DocDate
        FROM "@SAMPLEREQH" T0
        JOIN "@SAMPLEREQD" T1 ON T0."DocEntry" = T1."DocEntry"
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del
        AND T1."VisOrder" = MinLine;  -- ADD THIS FILTER

        SELECT DAYS_BETWEEN(:DocDate, NOW()) INTO TEMP_COUNTER FROM DUMMY;

        -- Header level counts (these don't need line filter)
        SELECT count(T0."U_DocDate")
        INTO DocDateCt
        FROM "@SAMPLEREQH" T0
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

        SELECT count(T0."U_ReqDocEntry")
        INTO SampleDocEntry
        FROM "@SAMPLEREQH" T0
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

        SELECT count(T0."U_RequestNo")
        INTO SampleNo
        FROM "@SAMPLEREQH" T0
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

        -- Detail level checks - ADD LINE FILTER TO ALL
        SELECT
            CASE WHEN T1."U_ItemDetails" IS NOT NULL AND T1."U_ItemDetails" <> '' THEN 1 ELSE 0 END,
            CASE WHEN T1."U_ItemCode" IS NOT NULL AND T1."U_ItemCode" <> '' THEN 1 ELSE 0 END,
            CASE WHEN T1."U_BrandName" IS NOT NULL AND T1."U_BrandName" <> '' THEN 1 ELSE 0 END,
            CASE WHEN T1."U_SampleType" IS NOT NULL AND T1."U_SampleType" <> '' THEN 1 ELSE 0 END,
            CASE WHEN T1."U_Packing" IS NOT NULL AND T1."U_Packing" <> '' THEN 1 ELSE 0 END,
            CASE WHEN T1."U_Qty" IS NOT NULL THEN 1 ELSE 0 END,
            CASE WHEN T1."U_UoM" IS NOT NULL AND T1."U_UoM" <> '' THEN 1 ELSE 0 END,
            CASE WHEN T1."U_SampleReady" IS NOT NULL AND T1."U_SampleReady" <> '' THEN 1 ELSE 0 END,
            T1."U_SampleReady",
            CASE WHEN T1."U_SampleDate" IS NOT NULL THEN 1 ELSE 0 END,
            CASE WHEN T1."U_Status" IS NOT NULL AND T1."U_Status" <> '' AND T1."U_Status" <> 'NA' THEN 1 ELSE 0 END
        INTO ItemDetails, ItemCode, BrandName, TypeSample, Packing, Qty, UoM,
             SampleReadyCt, SampleReady, SampleReadyDate, Status
        FROM "@SAMPLEREQH" T0
        JOIN "@SAMPLEREQD" T1 ON T0."DocEntry" = T1."DocEntry"
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del
        AND T1."VisOrder" = MinLine;  -- CRITICAL: Filter by current line

        -- Validations
        IF (:TEMP_COUNTER > 1) THEN
            error := -1239;
            error_message := N'Only 1 day backdate allowed for Sample Ready Date at line ' || MinLine || '.';
        END IF;

        IF (:TEMP_COUNTER < 0) THEN
            error := -1240;
            error_message := N'Forward date not allowed for Sample Ready Date at line ' || MinLine || '.';
        END IF;

        IF (DocDateCt = 0 OR SampleDocEntry = 0 OR SampleNo = 0 OR ItemDetails = 0 OR
            ItemCode = 0 OR BrandName = 0 OR TypeSample = 0 OR Packing = 0 OR
            Qty = 0 OR UoM = 0 OR SampleReadyCt = 0) THEN
            error := -1241;
            error_message := N'Please enter all details at line ' || MinLine || '.';
        END IF;

        IF (SampleReady = 'Yes' AND SampleReadyDate = 0) THEN
            error := -1242;
            error_message := N'Please enter Sample Ready Date at line ' || MinLine || '.';
        END IF;

        IF (SampleReady = 'No' AND SampleReadyDate > 0) THEN
            error := -1243;
            error_message := N'Not allowed to enter Sample Ready Date at line ' || MinLine || '.';
        END IF;

        IF (Status = 1 AND SampleReadyDate = 1) THEN
            error := -1243;
            error_message := N'Status only allowed when Sample Ready Date is empty ' || MinLine || '.';
        END IF;

        MinLine := MinLine + 1;
    END WHILE;

END IF;


IF (:object_type = 'SPLREQ') AND (:transaction_type = 'A' OR :transaction_type = 'U') THEN
    DECLARE DuplicateLineNum INT;
    DECLARE CurrentLineNum INT;
    DECLARE CurrentReqDocEntry INT;
    DECLARE MinLine INT;
    DECLARE MaxLine INT;

    -- Get min and max VisOrder for the loop
    SELECT MIN("VisOrder"), MAX("VisOrder") INTO MinLine, MaxLine
    FROM "@SAMPLEREQD"
    WHERE "DocEntry" = :list_of_cols_val_tab_del;

    -- Get the U_ReqDocEntry for this document
    SELECT "U_ReqDocEntry" INTO CurrentReqDocEntry
    FROM "@SAMPLEREQH"
    WHERE "DocEntry" = :list_of_cols_val_tab_del;

    -- Loop through each line using VisOrder
    WHILE MinLine <= MaxLine DO

        -- Get the U_LineNum for current VisOrder line
        SELECT TOP 1 "U_LineNum" INTO CurrentLineNum
        FROM "@SAMPLEREQD"
        WHERE "DocEntry" = :list_of_cols_val_tab_del
            AND "VisOrder" = MinLine;

        -- Skip if no row found (in case VisOrder sequence has gaps)
        IF CurrentLineNum IS NOT NULL THEN
            -- Check for duplicate U_LineNum across all documents with same U_ReqDocEntry
            -- Exclude canceled documents (Canceled = 'Y')
            SELECT COUNT(*) INTO DuplicateLineNum
            FROM "@SAMPLEREQH" T0
            JOIN "@SAMPLEREQD" T1 ON T0."DocEntry" = T1."DocEntry"
            WHERE T0."U_ReqDocEntry" = CurrentReqDocEntry
                AND T1."U_LineNum" = CurrentLineNum
                AND T0."DocEntry" <> :list_of_cols_val_tab_del
                AND (T0."Canceled" <> 'Y' OR T0."Canceled" IS NULL); -- Exclude canceled entries

            IF (DuplicateLineNum > 0) THEN
                error := -1244;
                error_message := N'Line Number ' || CurrentLineNum || ' has already been used for this Requisition Document Entry.';
                BREAK;
            END IF;
        END IF;

        MinLine := MinLine + 1;
    END WHILE;
END IF;

--------------------- LICENSE IN AP INVOICE -------------------------------------------------------------

IF object_type='112' AND (:transaction_type = 'A') THEN

DECLARE MinAP Int;
DECLARE MaxAP Int;
DECLARE LicTypeMainAP INT;
DECLARE VendorCode varchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18
THEN
	SELECT Min(T0."VisOrder") INTO MinAP from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T0."CardCode" into VendorCode FROM ODRF T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=18;

	IF VendorCode LIKE 'V__I%' then
		WHILE :MinAP<=MaxAP DO
			SELECT COUNT(DRF1."U_LicenseType") into LicTypeMainAP FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinAP;
			IF LicTypeMainAP = 0  then
				error := 146;
				error_message := N'Please Select License Type.';
			END IF;
			MinAP := MinAP+1;
		END WHILE;
	END IF;
END IF;
END IF;


IF object_type = '18' AND (:transaction_type = 'A') THEN

DECLARE MinAP Int;
DECLARE MaxAP Int;
DECLARE LicTypeMainAP INT;
DECLARE VendorCode varchar(50);

	SELECT Min(T0."VisOrder") INTO MinAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T0."CardCode" into VendorCode FROM OPCH T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	IF VendorCode LIKE 'V__I%' then
		WHILE :MinAP<=MaxAP DO
			SELECT COUNT(PCH1."U_LicenseType") into LicTypeMainAP FROM PCH1 WHERE PCH1."DocEntry" = list_of_cols_val_tab_del and PCH1."VisOrder"=MinAP;
			IF LicTypeMainAP = 0 then
				error := 146;
				error_message := N'Please Select License Type.';
			END IF;
			MinAP := MinAP+1;
		END WHILE;
	END IF;
END IF;

IF object_type='112' AND (:transaction_type = 'A') THEN
DECLARE MinAP Int;
DECLARE MaxAP Int;
DECLARE LicenseAP Nvarchar(50);
DECLARE LicTypeMainAP Nvarchar(50);
DECLARE VendorCode varchar(50);
(SELECT ODRF."ObjType" into DraftObj FROM ODRF WHERE ODRF."DocEntry"=:list_of_cols_val_tab_del );
if DraftObj = 18 THEN
	SELECT Min(T0."VisOrder") INTO MinAP from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from DRF1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T0."CardCode" into VendorCode FROM ODRF T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del and T0."ObjType"=18;

	IF VendorCode LIKE 'V__I%' then
		WHILE :MinAP<=MaxAP DO
			SELECT DRF1."U_LicenseType" into LicTypeMainAP FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinAP;
			SELECT DRF1."U_LicenseNum" into LicenseAP FROM DRF1 WHERE DRF1."DocEntry" = list_of_cols_val_tab_del and DRF1."VisOrder"=MinAP;
			IF LicTypeMainAP = 'ADVANCE' then
				IF (LicenseAP IS NULL OR LicenseAP = '') THEN
					error := 146;
					error_message := N'License No cannot be empty as Advance License is selected.';
				END IF;
			END IF;
			MinAP := MinAP+1;
		END WHILE;
	END IF;
END IF;
END IF;

IF object_type = '18' AND (:transaction_type = 'A') THEN
DECLARE MinAP Int;
DECLARE MaxAP Int;
DECLARE LicenseAP Nvarchar(50);
DECLARE LicTypeMainAP Nvarchar(50);
DECLARE VendorCode varchar(50);

	SELECT Min(T0."VisOrder") INTO MinAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT Max(T0."VisOrder") INTO MaxAP from PCH1 T0 where T0."DocEntry" =:list_of_cols_val_tab_del;
	SELECT T0."CardCode" into VendorCode FROM OPCH T0 WHERE T0."DocEntry"= :list_of_cols_val_tab_del;

	IF VendorCode LIKE 'V__I%' then
		WHILE :MinAP<=MaxAP DO
			SELECT PCH1."U_LicenseType" into LicTypeMainAP FROM PCH1 WHERE PCH1."DocEntry" = list_of_cols_val_tab_del and PCH1."VisOrder"=MinAP;
			SELECT PCH1."U_LicenseNum" into LicenseAP FROM PCH1 WHERE PCH1."DocEntry" = list_of_cols_val_tab_del and PCH1."VisOrder"=MinAP;
			IF LicTypeMainAP = 'ADVANCE' then
				IF (LicenseAP IS NULL OR LicenseAP = '') THEN
					error := 146;
					error_message := N'License No cannot be empty as Advance License is selected.';
				END IF;
			END IF;
			MinAP := MinAP+1;
		END WHILE;
	END IF;
END IF;
----------------------Subsidary Challan Qty math with Jobwork Bill------------------------
IF :object_type = '18' AND :transaction_type IN ('A','U') THEN
    DECLARE v_SubChallanQty   DECIMAL(19,6) := 0;
    DECLARE v_JobworkBillQty  DECIMAL(19,6) := 0;
    DECLARE v_DiffQty         DECIMAL(19,6);
    DECLARE v_GLCount         INT := 0;

    /* Sub-Challan Quantity */
    SELECT IFNULL(SUM("U_UNE_TQTY"), 0) INTO v_SubChallanQty FROM PCH1
    WHERE "DocEntry" = :list_of_cols_val_tab_del;

    /* Job-Work Billing Quantity */
    SELECT IFNULL(SUM(T1."CmpltQty"), 0) INTO v_JobworkBillQty FROM PCH21 T0
    INNER JOIN OWOR T1 ON T0."RefDocEntr" = T1."DocEntry" AND T0."RefObjType" = T1."ObjType"
    WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

    /* Check specific GL presence */
    SELECT COUNT(*) INTO v_GLCount FROM PCH1
    WHERE "AcctCode" = '50201027' AND "DocEntry" = :list_of_cols_val_tab_del;

    IF v_GLCount > 0 THEN
	        IF v_SubChallanQty <> v_JobworkBillQty THEN

    	        v_DiffQty := v_SubChallanQty - v_JobworkBillQty;

        	    error := 1321;
            	error_message := N'The Challan Quantity does not match with the Total Billing Quantity. Difference: ' || TO_NVARCHAR(v_DiffQty);
			END IF;
    END IF;
        IF v_GLCount > 0 THEN
	        IF  v_SubChallanQty = 0 THEN

        	    error := 1321;
            	error_message := N'Enter the Jobwork Challan "Total Quantity" at row level and link the Production Order via the Accounting tab --> Reference Document. This is mandatory for Jobwork bill.';
			END IF;
    END IF;
END IF;
---------------------------- Consignee Master Validation-------------------------------
IF Object_type = 'Consignee Master' AND (:transaction_type = 'A' OR :transaction_type = 'U' OR :transaction_type = 'C') THEN
DECLARE UserId INT;
DECLARE Cnt INT;
DECLARE EUserId INT;

SELECT Max("UserSign") INTO EUserId FROM "@ACONSIGNEEM" WHERE "Code" = :list_of_cols_val_tab_del;
SELECT "UserSign" INTO UserId FROM "@CONSIGNEEM" WHERE "Code" = :list_of_cols_val_tab_del;
SELECT COUNT(*) INTO Cnt FROM OCRD WHERE "CardCode" = :list_of_cols_val_tab_del AND "CardType" = 'C';

	IF UserId Not In (1,146) THEN
		error := -1209;
		error_message := N'Access denied. Only SAP Team is authorized to add, update, or cancel Consignee Master records.';
	END IF;
---------------------- Validate Consignee Code exists as Customer (Code = Customer Code)-----------------------------
    IF Cnt = 0 THEN
        error := -1210;
        error_message := N'Invalid Customer Code. Consignee Code must exist in Customer Master (OCRD).';
    END IF;

    IF :transaction_type IN ('U','C') THEN
    	IF EUserId Not In (1,146) THEN
			error := -1211;
			error_message := N'Access denied. Only SAP Team is authorized to update, or cancel Consignee Master records.';
		END IF;
	END IF;
END IF;


-----------------------------------------------
-- Select the return values-
select :error, :error_message FROM dummy;

End