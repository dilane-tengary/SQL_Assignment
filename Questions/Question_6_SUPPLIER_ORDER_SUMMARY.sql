-- QUESTION 6
 /*
 IT WORKS EXCEPT WRITING ON A CSV USING UTL_FILE, ISSUE WITH FORMAT '999,999,990.00'
 DBMS_OUTPUT WORKS 
 You need to create your directory and give proper rights before running the PROCEDURE
 CREATE OR REPLACE DIRECTORY your_directory AS '/your/actual/directory/path';
 GRANT READ, WRITE ON DIRECTORY your_directory TO your_user;
 In this example your_directory -> MY_DIR
 */
CREATE OR REPLACE PROCEDURE SUPPLIER_ORDER_SUMMARY AS
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
END SUPPLIER_ORDER_SUMMARY;
/