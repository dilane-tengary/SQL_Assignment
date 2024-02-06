-- QUESTION 5

CREATE OR REPLACE PROCEDURE MedianOrderTotal AS
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
/
