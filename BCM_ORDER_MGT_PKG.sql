-- Create a database package

CREATE OR REPLACE PACKAGE BCM_ORDER_MGT_PKG AS

  -- PROCEDURE INSERT_DATA_PROCEDURE
  PROCEDURE INSERT_DATA_PROCEDURE;

  -- PROCEDURE ORDER_SUMMARY_REPORT
  PROCEDURE ORDER_SUMMARY_REPORT;

  -- PROCEDURE MedianOrderTotal
  PROCEDURE MedianOrderTotal;

  -- PROCEDURE SUPPLIER_ORDER_SUMMARY
  PROCEDURE SUPPLIER_ORDER_SUMMARY;

END BCM_ORDER_MGT_PKG;
/

CREATE OR REPLACE PACKAGE BODY BCM_ORDER_MGT_PKG AS

  -- PROCEDURE INSERT_DATA_PROCEDURE
  PROCEDURE INSERT_DATA_PROCEDURE AS
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

  -- PROCEDURE ORDER_SUMMARY_REPORT
  PROCEDURE ORDER_SUMMARY_REPORT AS
	DECLARE
    file_handle UTL_FILE.FILE_TYPE;
	BEGIN
	   -- Open the file for writing
	   file_handle := UTL_FILE.FOPEN('MY_DIR', 'Order_Summary_Report.csv', 'W');
	   
	   FOR region_record IN (SELECT DISTINCT SUPPLIER_TOWN FROM SUPPLIER) LOOP 
		  -- Write to the file
		  UTL_FILE.PUT_LINE(file_handle, region_record.SUPPLIER_TOWN);

		  -- Headers
		  UTL_FILE.PUT_LINE(file_handle,    'Order Reference;'
										 || 'Order Period;'
										 || 'Supplier Name;'
										 || 'Order Total Amount;'
										 || 'Order Status;'
										 || 'Invoice Reference;'
										 || 'Invoice Total Amount;'
										 || 'Action');

		  DBMS_OUTPUT.PUT_LINE('Region: ' || region_record.SUPPLIER_TOWN);

		  FOR order_record IN (
			 SELECT
				TO_NUMBER(SUBSTR(o.ORDER_REF, 3, 3)) AS ORDER_NUMBER,
				TO_CHAR(o.ORDER_DATE, 'YYYY-MM') AS ORDER_PERIOD,
				INITCAP(s.SUPPLIER_NAME) AS SUPPLIER_NAME,
				TO_CHAR(o.ORDER_TOTAL_AMOUNT, '999,999,990.00') AS ORDER_TOTAL_AMOUNT,
				o.ORDER_STATUS AS ORDER_STATUS,
				i.INVOICE_REFERENCE AS INVOICE_REFERENCE,
				TO_CHAR(i.INVOICE_AMOUNT, '999,999,990.00') AS INVOICE_TOTAL_AMOUNT,
				CASE
				   WHEN EXISTS (SELECT 1 FROM INVOICE WHERE INVOICE_STATUS = 'Pending' AND INVOICE.INVOICE_ID = i.INVOICE_ID) THEN 'To follow up'
				   WHEN EXISTS (SELECT 1 FROM INVOICE WHERE INVOICE_STATUS = 'NO_STATUS' AND INVOICE.INVOICE_ID = i.INVOICE_ID) THEN 'To verify'
				   ELSE 'No Action'
				END AS Action
			 FROM
				SUPPLIER s
				JOIN ORDERS o ON s.SUPPLIER_NAME = o.SUPPLIER_NAME
				JOIN INVOICE i ON o.INVOICE_ID = i.INVOICE_ID
			 WHERE
				s.SUPPLIER_TOWN = region_record.SUPPLIER_TOWN
			 ORDER BY
				o.ORDER_DATE DESC
		  ) LOOP
			 UTL_FILE.PUT_LINE(file_handle,    order_record.ORDER_NUMBER || ';'
											||  order_record.ORDER_PERIOD || ';'
											||  order_record.SUPPLIER_NAME || ';'
											||  order_record.ORDER_TOTAL_AMOUNT || ';'
											||  order_record.ORDER_STATUS|| ';'
											||  order_record.INVOICE_REFERENCE || ';'
											||  order_record.INVOICE_TOTAL_AMOUNT || ';'
											||  order_record.Action
								  );            
			 DBMS_OUTPUT.PUT_LINE(
				'Order Reference: ' || order_record.ORDER_NUMBER ||
				'  | Order Period: ' || order_record.ORDER_PERIOD ||
				'  | Supplier Name: ' || order_record.SUPPLIER_NAME ||
				'  | Order Total Amount: ' || order_record.ORDER_TOTAL_AMOUNT ||
				'  | Order Status: ' || order_record.ORDER_STATUS ||
				'  | Invoice Reference: ' || order_record.INVOICE_REFERENCE ||
				'  | Invoice Total Amount: ' || order_record.INVOICE_TOTAL_AMOUNT||
				'  | Action: ' || order_record.Action
			 );
		  END LOOP;

		  DBMS_OUTPUT.PUT_LINE(''); -- Separate regions with an empty line
	   END LOOP;
	   -- Close the file
	   UTL_FILE.FCLOSE(file_handle);
	  EXCEPTION
		WHEN OTHERS THEN
		  DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
	  END ORDER_SUMMARY_REPORT;

  -- PROCEDURE MedianOrderTotal
  PROCEDURE MedianOrderTotal AS
	  BEGIN
		FOR results IN (
			SELECT 
				TO_NUMBER(SUBSTR(o.ORDER_REF, 3, 3)) AS ORDER_NUMBER,
				TO_CHAR(o.ORDER_DATE, 'YYYY-MM') AS ORDER_PERIOD,
				-- INITCAP ensures Only first letter of each word is uppercase 
				INITCAP(s.SUPPLIER_NAME) AS SUPPLIER_NAME,
				-- Calculating sum of ORDER_TOTAL_AMOUNT per ORDER_REF(1,2,3,4,...)
				TO_CHAR(SUM(o.ORDER_TOTAL_AMOUNT), '999,999,990.00') AS ORDER_TOTAL_AMOUNT,
				-- Concatenation of distinct values for INVOICE_REFERENCES
				LISTAGG(DISTINCT 
					CASE 
					-- Catering for null values, here called 'NO_REF'
						WHEN i.INVOICE_REFERENCE = 'NO_REF' THEN ''
						ELSE i.INVOICE_REFERENCE
					END, ' | ') WITHIN GROUP (ORDER BY i.INVOICE_REFERENCE) AS INVOICE_REFERENCES
			FROM
				SUPPLIER s
				JOIN ORDERS o ON s.SUPPLIER_NAME = o.SUPPLIER_NAME
				JOIN INVOICE i ON o.INVOICE_ID = i.INVOICE_ID
			WHERE 
				TO_NUMBER(SUBSTR(o.ORDER_REF, 3, 3)) = (
					SELECT TO_NUMBER(SUBSTR(ORDER_REF, 3, 3))
					FROM ORDERS
					WHERE ORDER_TOTAL_AMOUNT = (
						SELECT ORDER_TOTAL_AMOUNT
						FROM ORDERS
						/*
						Finding the amount closest to the average in the column of ORDER_TOTAL_AMOUNT
						The ABS function is used to get the absolute difference between each ORDER_TOTAL_AMOUNT and the average. 
						This gives a measure of how far each order's total amount is from the average.
						*/
						ORDER BY ABS(ORDER_TOTAL_AMOUNT - (SELECT 
																-- Finding the average amount 
																AVG(ORDER_TOTAL_AMOUNT) FROM ORDERS))
						-- Ensuring that only the first row (the one with the order closest to the average) is selected
						FETCH FIRST 1 ROW ONLY
						
					)
				)
			GROUP BY 
				TO_NUMBER(SUBSTR(o.ORDER_REF, 3, 3)),
				TO_CHAR(o.ORDER_DATE, 'YYYY-MM'),
				INITCAP(s.SUPPLIER_NAME)
		) LOOP
			DBMS_OUTPUT.PUT_LINE('Order Reference: ' || results.ORDER_NUMBER);
			DBMS_OUTPUT.PUT_LINE('Order Date: ' || results.ORDER_PERIOD);
			DBMS_OUTPUT.PUT_LINE('Supplier Name: ' || results.SUPPLIER_NAME);
			DBMS_OUTPUT.PUT_LINE('Order Total Amount : ' || results.ORDER_TOTAL_AMOUNT);
			DBMS_OUTPUT.PUT_LINE('Invoice References: ' || results.INVOICE_REFERENCES);
		END LOOP;
	  EXCEPTION
		WHEN OTHERS THEN
		  DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END MedianOrderTotal;

  -- PROCEDURE SUPPLIER_ORDER_SUMMARY
  PROCEDURE SUPPLIER_ORDER_SUMMARY AS
    DECLARE
    file_handle UTL_FILE.FILE_TYPE;
	BEGIN
			-- Open the file for writing
		   file_handle := UTL_FILE.FOPEN('MY_DIR', 'Supplier_Order_Summary.csv', 'W');
		FOR month_record IN (SELECT DISTINCT TO_CHAR(ORDER_DATE, 'Month YYYY') AS O_DATE FROM ORDERS WHERE ORDER_DATE BETWEEN TO_DATE('2023-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-08-31', 'YYYY-MM-DD')) LOOP
			  -- Write to the file
			 UTL_FILE.PUT_LINE(file_handle, month_record.O_DATE);
			 -- Headers
			 UTL_FILE.PUT_LINE(file_handle,   'Supplier Name ;'
										   || 'Supplier Contact Name;'
										   || 'Supplier Contact No. 1'
										   || 'Supplier Contact No. 2'
										   || 'Order Status;'
										   || 'Total Orders'
										   || 'Order Total Amount');
										   
			DBMS_OUTPUT.PUT_LINE('Month: ' || month_record.O_DATE);
			
			FOR supplier_record IN (
				SELECT
					s.SUPPLIER_NAME,
					s.SUPP_CONTACT_FIRST_NAME || ' ' || s.SUPP_CONTACT_LAST_NAME AS Supplier_Contact_Name,
					CASE
						WHEN SUBSTR(SUPP_CONTACT_NUMBER1,1,1) = 5 THEN SUBSTR(s.SUPP_CONTACT_NUMBER1, 1, 4) || '-' || SUBSTR(s.SUPP_CONTACT_NUMBER1, 5, 4)
						ELSE SUBSTR(s.SUPP_CONTACT_NUMBER1, 1, 3) || '-' || SUBSTR(s.SUPP_CONTACT_NUMBER1, 4, 4)
					END  AS Supplier_Contact_No1,
					CASE
						WHEN SUBSTR(SUPP_CONTACT_NUMBER2,1,1) = 'N' THEN 'No Second Number'
						WHEN SUBSTR(SUPP_CONTACT_NUMBER2,1,1) = 5 THEN SUBSTR(s.SUPP_CONTACT_NUMBER2, 1, 4) || '-' || SUBSTR(s.SUPP_CONTACT_NUMBER2, 5, 4)
						ELSE SUBSTR(s.SUPP_CONTACT_NUMBER2, 1, 3) || '-' || SUBSTR(s.SUPP_CONTACT_NUMBER2, 4, 4)
					END  AS Supplier_Contact_No2,
					COUNT(o.ORDER_ID) AS Total_Orders,
					TO_CHAR(SUM(o.ORDER_TOTAL_AMOUNT), 'FM999,999,990.00') AS Order_Total_Amount
				FROM
					SUPPLIER s
					LEFT JOIN ORDERS o ON s.SUPPLIER_NAME = o.SUPPLIER_NAME
				WHERE
					 TO_CHAR(o.ORDER_DATE, 'Month YYYY') = month_record.O_DATE
				GROUP BY
					s.SUPPLIER_NAME,
					s.SUPP_CONTACT_FIRST_NAME || ' ' || s.SUPP_CONTACT_LAST_NAME,
					s.SUPP_CONTACT_NUMBER1,
					s.SUPP_CONTACT_NUMBER2
				ORDER BY
					Total_Orders DESC
			) LOOP
				UTL_FILE.PUT_LINE(file_handle,    	   supplier_record.SUPPLIER_NAME || ';'
									   ||  supplier_record.Supplier_Contact_Name || ';'
									   ||  supplier_record.Supplier_Contact_No1 || ';'
									   ||  supplier_record.Supplier_Contact_No2 || ';'
									   ||  supplier_record.Total_Orders|| ';'
									   ||  supplier_record.Order_Total_Amount 
									   );    
				DBMS_OUTPUT.PUT_LINE(
					'Supplier Name: ' || supplier_record.SUPPLIER_NAME ||
					' | Supplier Contact Name: ' || supplier_record.Supplier_Contact_Name ||
					' | Supplier Contact No. 1: ' || supplier_record.Supplier_Contact_No1 ||
					' | Supplier Contact No. 2: ' || supplier_record.Supplier_Contact_No2 ||
					' | Total Orders: ' || supplier_record.Total_Orders ||
					' | Order Total Amount: ' || supplier_record.Order_Total_Amount
				);
			END LOOP;
		END LOOP;
			   -- Close the file
	   UTL_FILE.FCLOSE(file_handle);
	  EXCEPTION
		WHEN OTHERS THEN
		  DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
	  END SUPPLIER_ORDER_SUMMARY;

END BCM_ORDER_MGT_PKG;
/