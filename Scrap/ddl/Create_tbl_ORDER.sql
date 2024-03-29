-- INVOICE
-- CREATION OF SEQUENCE FOR ORDER_ID
CREATE SEQUENCE ORDER_ID_SEQ START WITH 1 INCREMENT BY 1;

-- CREATION OF TABLE ORDER
CREATE TABLE ORDERS 
(	
ORDER_ID  			NUMBER DEFAULT ORDER_ID_SEQ.NEXTVAL,
ORDER_REF 			VARCHAR2(8),
ORDER_DATE 			DATE,
SUPPLIER_NAME   	VARCHAR2(100),
INVOICE_ID  		NUMBER,
ORDER_TOTAL_AMOUNT 	NUMBER(10,2), 
ORDER_DESCRIPTION 	VARCHAR2(100), 
ORDER_STATUS 		VARCHAR2(1000), 
ORDER_LINE_AMOUNT 	NUMBER(10,2),
PRIMARY KEY (ORDER_ID, ORDER_REF),
CONSTRAINT FK_SUPPLIER
    FOREIGN KEY (SUPPLIER_NAME)
    REFERENCES SUPPLIER(SUPPLIER_NAME),
CONSTRAINT FK_INVOICE
    FOREIGN KEY (INVOICE_ID)
    REFERENCES INVOICE(INVOICE_ID)	
) ;
