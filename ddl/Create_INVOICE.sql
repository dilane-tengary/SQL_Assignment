DECLARE
  v_table_exists NUMBER;
  v_sequence_exists NUMBER;
BEGIN
  -- Check if the table exists
  SELECT COUNT(*) INTO v_table_exists FROM user_tables WHERE table_name = 'INVOICE';
  
  -- If the table exists, drop it
  IF v_table_exists = 1 THEN
    EXECUTE IMMEDIATE 'DROP TABLE INVOICE CASCADE CONSTRAINTS';
  END IF;

  -- Check if the sequence exists
  SELECT COUNT(*) INTO v_sequence_exists FROM user_sequences WHERE sequence_name = 'INVOICE_ID_SEQ';
  
  -- If the sequence exists, drop it
  IF v_sequence_exists = 1 THEN
    EXECUTE IMMEDIATE 'DROP SEQUENCE INVOICE_ID_SEQ';
  END IF;

  -- Create the INVOICE sequence
  EXECUTE IMMEDIATE 'CREATE SEQUENCE INVOICE_ID_SEQ START WITH 1 INCREMENT BY 1';

  -- Create the INVOICE table
  EXECUTE IMMEDIATE '
    CREATE TABLE INVOICE (
      INVOICE_ID           NUMBER DEFAULT INVOICE_ID_SEQ.NEXTVAL,
      MAIN_ID              NUMBER,
      INVOICE_REFERENCE    VARCHAR2(12),
      INVOICE_DATE         DATE,
      INVOICE_STATUS       VARCHAR2(10),
      INVOICE_HOLD_REASON  VARCHAR2(100),
      INVOICE_AMOUNT       NUMBER(10,2),
      INVOICE_DESCRIPTION  VARCHAR2(100),
      PRIMARY KEY (INVOICE_ID),
      CONSTRAINT FK_MAIN
        FOREIGN KEY (MAIN_ID)
        REFERENCES BCM_ORDER_MGT_CLEANED(MAIN_ID)
    )';
END;
/