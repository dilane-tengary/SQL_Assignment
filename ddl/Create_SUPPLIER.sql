-- SUPPLIER 

DECLARE
  v_table_exists NUMBER;
BEGIN
  -- Check if the table exists
  SELECT COUNT(*) INTO v_table_exists FROM user_tables WHERE table_name = 'SUPPLIER';
  
  -- If the table exists, drop it
  IF v_table_exists = 1 THEN
    EXECUTE IMMEDIATE 'DROP TABLE SUPPLIER';
  END IF;

  -- Create the SUPPLIER table
  EXECUTE IMMEDIATE '
    CREATE TABLE SUPPLIER (
      SUPPLIER_NAME           VARCHAR2(100) PRIMARY KEY,
      SUPP_CONTACT_FIRST_NAME VARCHAR2(100),
      SUPP_CONTACT_LAST_NAME  VARCHAR2(100),
      SUPPLIER_building_number VARCHAR2(50),
      SUPPLIER_street          VARCHAR2(50),
      SUPPLIER_TOWN            VARCHAR2(50),
      SUPPLIER_COUNTRY         VARCHAR2(50),
      SUPP_CONTACT_NUMBER1     CHAR(8),
      SUPP_CONTACT_NUMBER2     CHAR(8),
      SUPP_EMAIL               VARCHAR2(100)
    )';
END;
/