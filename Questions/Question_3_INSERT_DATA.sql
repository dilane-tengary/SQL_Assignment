-- PROCEDURE INSERT_DATA_PROCEDURE

CREATE OR REPLACE PROCEDURE INSERT_DATA_PROCEDURE AS
BEGIN
  -- 1. Insert data into BCM_ORDER_MGT_CLEANED
  INSERT INTO BCM_ORDER_MGT_CLEANED (
    ORDER_REF,
    ORDER_DATE,
    SUPPLIER_NAME,
    SUPP_CONTACT_NAME,
    SUPPLIER_building_number,
    SUPPLIER_street,
    SUPPLIER_TOWN,
    SUPPLIER_COUNTRY,
    SUPP_CONTACT_NUMBER1,
    SUPP_CONTACT_NUMBER2,
    SUPP_EMAIL,
    ORDER_TOTAL_AMOUNT,
    ORDER_DESCRIPTION,
    ORDER_STATUS,
    ORDER_LINE_AMOUNT,
    INVOICE_REFERENCE,
    INVOICE_DATE,
    INVOICE_STATUS,
    INVOICE_HOLD_REASON,
    INVOICE_AMOUNT,
    INVOICE_DESCRIPTION
  )
  SELECT 
    ORDER_REF,
	-- Rewriting the date in DD-MON-YYYY format, changing the type from varchar to date
	-- Using REGEXP_LIKE to check different patterns because the dates in the dataset are written in different formats 
	CASE
        WHEN REGEXP_LIKE(b.ORDER_DATE, '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$') THEN TO_CHAR(TO_DATE(b.ORDER_DATE, 'DD-MON-YYYY'), 'DD-MON-YYYY')
        WHEN REGEXP_LIKE(b.ORDER_DATE, '^[0-9]{2}-[0-9]{2}-[0-9]{4}$') THEN TO_CHAR(TO_DATE(b.ORDER_DATE, 'DD-MM-YYYY'), 'DD-MON-YYYY')
        WHEN REGEXP_LIKE(b.ORDER_DATE, '^[0-9]{2}-[A-Za-z]{3}-[0-9]{2}$') THEN TO_CHAR(TO_DATE(b.ORDER_DATE, 'DD-MON-YY'), 'DD-MON-YYYY')
        WHEN REGEXP_LIKE(b.ORDER_DATE, '^[0-9]{2}-[0-9]{2}-[0-9]{2}$') THEN TO_CHAR(TO_DATE(b.ORDER_DATE, 'DD-MM-YY'), 'DD-MON-YYYY')
        ELSE NULL
    END AS ORDER_DATE,
	SUPPLIER_NAME,
	SUPP_CONTACT_NAME,
	-- Breaking down the supplier's address using RREGEXP_SUBSTR and , as delimiter
	REGEXP_SUBSTR(SUPP_ADDRESS, '[^,]+', 1, 1) AS SUPPLIER_building_number,
    TRIM(REGEXP_SUBSTR(SUPP_ADDRESS, '[^,]+', 1, 2) || ', ' ||
         REGEXP_SUBSTR(SUPP_ADDRESS, '[^,]+', 1, 3)) AS SUPPLIER_street,
    REGEXP_SUBSTR(SUPP_ADDRESS, '[^,]+', 1, 4) AS SUPPLIER_TOWN, -- QUESTION 3
    REGEXP_SUBSTR(SUPP_ADDRESS, '[^,]+', 1, 5) AS SUPPLIER_COUNTRY,
	-- Using translate as in some cases 1 is written as I, 0 as O and S as 5, also separating the 2 phone numbers using REGEXP_SUBSTR and , as delimiter
	REGEXP_SUBSTR(TRANSLATE(REGEXP_REPLACE(UPPER(SUPP_CONTACT_NUMBER), '[ .]', ''), 'IOS', '105'),'[^,]+', 1, 1) AS SUPP_CONTACT_NUMBER1,
	-- removing null value. Setting it to 'NoNumber' since the SUPP_CONTACT_NUMBER2 is a char(8) character
	NVL(REGEXP_SUBSTR(TRANSLATE(REGEXP_REPLACE(UPPER(SUPP_CONTACT_NUMBER), '[ .]', ''), 'IOS', '105'), '[^,]+', 1, 2), 'NoNumber') AS SUPP_CONTACT_NUMBER2,
	SUPP_EMAIL,
	TO_NUMBER(NVL(REPLACE(ORDER_TOTAL_AMOUNT, ',', ''), 0)) AS ORDER_TOTAL_AMOUNT,
	ORDER_DESCRIPTION,
	ORDER_STATUS,
	--Using translate as in some cases 1 is written as I, 0 as O and S as 5
	TO_NUMBER(TRANSLATE(NVL(REPLACE(UPPER(ORDER_LINE_AMOUNT), ',', ''), 0), 'IOS', '105')) AS ORDER_LINE_AMOUNT,
	-- Removing null values where possible except for dates
	NVL(INVOICE_REFERENCE, 'N/A'),
	-- Same manipulation as ORDER_DATE
	CASE 
		WHEN REGEXP_LIKE(INVOICE_DATE, '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$') THEN TO_CHAR(TO_DATE(INVOICE_DATE, 'DD-MON-YYYY'), 'DD-MON-YYYY')
		WHEN REGEXP_LIKE(INVOICE_DATE, '^[0-9]{2}-[0-9]{2}-[0-9]{4}$') THEN TO_CHAR(TO_DATE(INVOICE_DATE, 'DD-MM-YYYY'), 'DD-MON-YYYY')
		WHEN REGEXP_LIKE(INVOICE_DATE, '^[0-9]{2}-[A-Za-z]{3}-[0-9]{2}$') THEN TO_CHAR(TO_DATE(INVOICE_DATE, 'DD-MON-YY'), 'DD-MON-YYYY')
		WHEN REGEXP_LIKE(INVOICE_DATE, '^[0-9]{2}-[0-9]{2}-[0-9]{2}$') THEN TO_CHAR(TO_DATE(INVOICE_DATE, 'DD-MM-YY'), 'DD-MON-YYYY')
    ELSE NULL 
	END AS INVOICE_DATE,
    NVL(INVOICE_STATUS,'N/A'),
	NVL(INVOICE_HOLD_REASON,'N/A'),
    TO_NUMBER(TRANSLATE(NVL(REPLACE(UPPER(INVOICE_AMOUNT), ',', ''),0), 'IOS', '105')) AS INVOICE_AMOUNT,
	NVL(INVOICE_DESCRIPTION,'N/A')
  FROM 
    BCM_ORDER_MGT b
  -- Checking if rows already exist before inserting
  WHERE NOT EXISTS 
    (
      SELECT 1
      FROM BCM_ORDER_MGT_CLEANED c
      WHERE c.ORDER_REF = b.ORDER_REF
      AND c.SUPPLIER_NAME = b.SUPPLIER_NAME
      AND c.ORDER_DESCRIPTION = b.ORDER_DESCRIPTION
      AND c.ORDER_STATUS = b.ORDER_STATUS
      -- Not taking null values
    );
    

  -- 2. Insert data into SUPPLIER
  INSERT INTO SUPPLIER (
    SUPPLIER_NAME,
    SUPP_CONTACT_FIRST_NAME,
    SUPP_CONTACT_LAST_NAME,
    SUPPLIER_building_number,
    SUPPLIER_street,
    SUPPLIER_TOWN,
    SUPPLIER_COUNTRY,
    SUPP_CONTACT_NUMBER1,
    SUPP_CONTACT_NUMBER2, 	
    SUPP_EMAIL
  )
  SELECT 
    DISTINCT SUPPLIER_NAME,
    MAX(REGEXP_SUBSTR(SUPP_CONTACT_NAME, '[^ ]+', 1, 1)) AS SUPP_CONTACT_FIRST_NAME,
    MAX(REGEXP_SUBSTR(SUPP_CONTACT_NAME, '[^ ]+', 1, 2)) AS SUPP_CONTACT_LAST_NAME,
	MAX(SUPPLIER_building_number) AS SUPPLIER_building_number,
	MAX(SUPPLIER_street) AS SUPPLIER_street,
	MAX(SUPPLIER_TOWN) AS SUPPLIER_TOWN,
	MAX(SUPPLIER_COUNTRY) AS SUPPLIER_COUNTRY,
	MAX(SUPP_CONTACT_NUMBER1) AS SUPP_CONTACT_NUMBER1,
	MAX(SUPP_CONTACT_NUMBER2) AS SUPP_CONTACT_NUMBER2,
	MAX(SUPP_EMAIL) AS SUPP_EMAIL
	
	/*
	The DISTINCT keyword ensures that only unique SUPPLIER_NAME values are considered.
	The MAX function is used to select one of the values for each column. 
		If there's only one value for each SUPPLIER_NAME, MAX effectively selects that value.
	The GROUP BY SUPPLIER_NAME groups the data by SUPPLIER_NAME.
	*/
	
  FROM 
	BCM_ORDER_MGT_CLEANED b
  -- Checking if rows already exist before inserting
  WHERE NOT EXISTS 
    (
      SELECT 1
      FROM SUPPLIER s
      WHERE 
        s.SUPPLIER_NAME = b.SUPPLIER_NAME
    )
  GROUP BY SUPPLIER_NAME;

  -- 3. Insert data into INVOICE
  INSERT INTO INVOICE (
    MAIN_ID,
    INVOICE_REFERENCE,
    INVOICE_DATE,
    INVOICE_STATUS,
    INVOICE_HOLD_REASON,
    INVOICE_AMOUNT,
    INVOICE_DESCRIPTION
  )
  SELECT 
    MAIN_ID,
    INVOICE_REFERENCE,
    INVOICE_DATE,
    INVOICE_STATUS,
    INVOICE_HOLD_REASON,
    INVOICE_AMOUNT,
	INVOICE_DESCRIPTION
  FROM 
    BCM_ORDER_MGT_CLEANED b
  -- Checking if rows already exist before inserting
  WHERE NOT EXISTS 
    (
      SELECT 1
      FROM INVOICE i
      WHERE 
        i.INVOICE_REFERENCE = b.INVOICE_REFERENCE
        AND i.MAIN_ID = b.MAIN_ID
    )
  ORDER BY ORDER_REF;

  -- 4. Insert data into ORDERS
  INSERT INTO ORDERS (
    ORDER_REF,
    ORDER_DATE,
    SUPPLIER_NAME,
    INVOICE_ID,
    ORDER_TOTAL_AMOUNT,
    ORDER_DESCRIPTION,
    ORDER_STATUS,
    ORDER_LINE_AMOUNT
  )
  SELECT
    ORDER_REF,
    ORDER_DATE,
    SUPPLIER_NAME,
    INVOICE_ID,
	ORDER_TOTAL_AMOUNT,
    ORDER_DESCRIPTION,
    ORDER_STATUS,
    ORDER_LINE_AMOUNT
  FROM
    BCM_ORDER_MGT_CLEANED b
  -- Joining table BCM_ORDER_MGT and INVOICE
  JOIN
    INVOICE i ON
      i.INVOICE_REFERENCE = b.INVOICE_REFERENCE
      AND i.MAIN_ID = b.MAIN_ID
  -- Checking if rows already exist before inserting
  WHERE NOT EXISTS (
    SELECT 1
    FROM ORDERS o
    WHERE
      o.ORDER_REF = b.ORDER_REF
      AND o.INVOICE_ID = i.INVOICE_ID
  )
  -- Validating if supplier_name exist in supplier table
  AND EXISTS (
    SELECT 1
    FROM SUPPLIER s
    WHERE s.SUPPLIER_NAME = b.SUPPLIER_NAME
  )    
  ORDER BY b.ORDER_REF;
  EXCEPTION
  WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
	ROLLBACK;
  COMMIT;
END INSERT_DATA_PROCEDURE;
/