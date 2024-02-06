--BCM_ORDER_MGT_CLEANED

DECLARE
  v_table_exists NUMBER;
  v_sequence_exists NUMBER;
BEGIN
  -- Check if the table exists
  SELECT COUNT(*) INTO v_table_exists FROM user_tables WHERE table_name = 'BCM_ORDER_MGT_CLEANED';
  
  -- If the table exists, drop it
  IF v_table_exists = 1 THEN
    EXECUTE IMMEDIATE 'DROP TABLE BCM_ORDER_MGT_CLEANED';
  END IF;
  
  -- Check if the sequence exists
  SELECT COUNT(*) INTO v_sequence_exists FROM user_sequences WHERE sequence_name = 'MAIN_ID_SEQ';
  
  -- If the sequence exists, drop it
  IF v_sequence_exists = 1 THEN
    EXECUTE IMMEDIATE 'DROP SEQUENCE MAIN_ID_SEQ';
  END IF;

  -- Create the sequence
  EXECUTE IMMEDIATE 'CREATE SEQUENCE MAIN_ID_SEQ START WITH 1 INCREMENT BY 1';

  -- Create the cleaned data table
  EXECUTE IMMEDIATE '
    CREATE TABLE BCM_ORDER_MGT_CLEANED
    (
      MAIN_ID                    NUMBER DEFAULT MAIN_ID_SEQ.NEXTVAL PRIMARY KEY,
      ORDER_REF                  VARCHAR2(8),
      ORDER_DATE                 DATE,
      SUPPLIER_NAME              VARCHAR2(100),
      SUPP_CONTACT_NAME          VARCHAR2(100),
      SUPPLIER_building_number   VARCHAR2(50),
      SUPPLIER_street            VARCHAR2(50),
      SUPPLIER_TOWN              VARCHAR2(50),
      SUPPLIER_COUNTRY           VARCHAR2(50),
      SUPP_CONTACT_NUMBER1       CHAR(8),
      SUPP_CONTACT_NUMBER2       CHAR(8),
      SUPP_EMAIL                 VARCHAR2(100),
      ORDER_TOTAL_AMOUNT         NUMBER(10,2),
      ORDER_DESCRIPTION          VARCHAR2(100),
      ORDER_STATUS               VARCHAR2(1000),
      ORDER_LINE_AMOUNT          NUMBER(10,2),
      INVOICE_REFERENCE          VARCHAR2(12),
      INVOICE_DATE               DATE,
      INVOICE_STATUS             VARCHAR2(10),
      INVOICE_HOLD_REASON        VARCHAR2(100),
      INVOICE_AMOUNT             NUMBER(10,2),
      INVOICE_DESCRIPTION        VARCHAR2(100)
    )';
END;
/