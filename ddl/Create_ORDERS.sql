DECLARE
  v_table_exists NUMBER;
  v_sequence_exists NUMBER;
BEGIN
  -- Check if the table exists
  SELECT COUNT(*) INTO v_table_exists FROM user_tables WHERE table_name = 'ORDERS';
  
  -- If the table exists, drop it
  IF v_table_exists = 1 THEN
    EXECUTE IMMEDIATE 'DROP TABLE ORDERS CASCADE CONSTRAINTS';
  END IF;

  -- Check if the sequence exists
  SELECT COUNT(*) INTO v_sequence_exists FROM user_sequences WHERE sequence_name = 'ORDER_ID_SEQ';
  
  -- If the sequence exists, drop it
  IF v_sequence_exists = 1 THEN
    EXECUTE IMMEDIATE 'DROP SEQUENCE ORDER_ID_SEQ';
  END IF;

  -- Create the ORDER_ID sequence
  EXECUTE IMMEDIATE 'CREATE SEQUENCE ORDER_ID_SEQ START WITH 1 INCREMENT BY 1';

  -- Create the ORDERS table
  EXECUTE IMMEDIATE '
    CREATE TABLE ORDERS (
      ORDER_ID            NUMBER DEFAULT ORDER_ID_SEQ.NEXTVAL,
      ORDER_REF           VARCHAR2(8),
      ORDER_DATE          DATE,
      SUPPLIER_NAME       VARCHAR2(100),
      INVOICE_ID          NUMBER,
      ORDER_TOTAL_AMOUNT  NUMBER(10,2),
      ORDER_DESCRIPTION   VARCHAR2(100),
      ORDER_STATUS        VARCHAR2(1000),
      ORDER_LINE_AMOUNT   NUMBER(10,2),
      PRIMARY KEY (ORDER_ID, ORDER_REF),
      CONSTRAINT FK_SUPPLIER
        FOREIGN KEY (SUPPLIER_NAME)
        REFERENCES SUPPLIER(SUPPLIER_NAME),
      CONSTRAINT FK_INVOICE
        FOREIGN KEY (INVOICE_ID)
        REFERENCES INVOICE(INVOICE_ID)
    )';
END;
/