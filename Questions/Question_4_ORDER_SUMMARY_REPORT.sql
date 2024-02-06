 -- Question 4
 /*
 IT WORKS EXCEPT WRITING ON A CSV USING UTL_FILE, ISSUE WITH FORMAT '999,999,990.00'
 DBMS_OUTPUT WORKS 
 You need to create your directory and give proper rights before running the PROCEDURE
 CREATE OR REPLACE DIRECTORY your_directory AS '/your/actual/directory/path';
 GRANT READ, WRITE ON DIRECTORY your_directory TO your_user;
 In this example your_directory -> MY_DIR
 */

CREATE OR REPLACE PROCEDURE ORDER_SUMMARY_REPORT AS
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
/

