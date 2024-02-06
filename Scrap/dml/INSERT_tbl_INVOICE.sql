--INVOICE

-- INSERT OF DATA INTO INVOICE FROM BCM_ORDER_MGT
INSERT INTO INVOICE (
    INVOICE_REFERENCE,
    INVOICE_DATE,
    INVOICE_STATUS,
    INVOICE_HOLD_REASON,
    INVOICE_AMOUNT
)
SELECT 
    INVOICE_REFERENCE,
    CASE 
		WHEN REGEXP_LIKE(INVOICE_DATE, '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$') THEN TO_CHAR(TO_DATE(INVOICE_DATE, 'DD-MON-YYYY'), 'DD-MON-YYYY')
		WHEN REGEXP_LIKE(INVOICE_DATE, '^[0-9]{2}-[0-9]{2}-[0-9]{4}$') THEN TO_CHAR(TO_DATE(INVOICE_DATE, 'DD-MM-YYYY'), 'DD-MON-YYYY')
		WHEN REGEXP_LIKE(INVOICE_DATE, '^[0-9]{2}-[A-Za-z]{3}-[0-9]{2}$') THEN TO_CHAR(TO_DATE(INVOICE_DATE, 'DD-MON-YY'), 'DD-MON-YYYY')
		WHEN REGEXP_LIKE(INVOICE_DATE, '^[0-9]{2}-[0-9]{2}-[0-9]{2}$') THEN TO_CHAR(TO_DATE(INVOICE_DATE, 'DD-MM-YY'), 'DD-MON-YYYY')
    ELSE NULL 
	END AS INVOICE_DATE,
    INVOICE_STATUS,
    INVOICE_HOLD_REASON,
    TO_NUMBER(TRANSLATE(NVL(REPLACE(UPPER(INVOICE_AMOUNT), ',', ''),0), 'IOS', '105')) AS INVOICE_AMOUNT
FROM 
    BCM_ORDER_MGT b
WHERE NOT EXISTS (
    SELECT 1
    FROM INVOICE i
    WHERE 
		(i.INVOICE_REFERENCE = b.INVOICE_REFERENCE OR (i.INVOICE_REFERENCE IS NULL AND b.INVOICE_REFERENCE IS NULL))
        AND (
            (   i.INVOICE_DATE IS NOT NULL AND
                b.INVOICE_DATE IS NOT NULL AND
                i.INVOICE_DATE = 
                    CASE 
                        WHEN REGEXP_LIKE(b.INVOICE_DATE, '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$') THEN TO_CHAR(TO_DATE(b.INVOICE_DATE, 'DD-MON-YYYY'), 'DD-MON-YYYY')
                        WHEN REGEXP_LIKE(b.INVOICE_DATE, '^[0-9]{2}-[0-9]{2}-[0-9]{4}$') THEN TO_CHAR(TO_DATE(b.INVOICE_DATE, 'DD-MM-YYYY'), 'DD-MON-YYYY')
                        WHEN REGEXP_LIKE(b.INVOICE_DATE, '^[0-9]{2}-[A-Za-z]{3}-[0-9]{2}$') THEN TO_CHAR(TO_DATE(b.INVOICE_DATE, 'DD-MON-YY'), 'DD-MON-YYYY')
                        WHEN REGEXP_LIKE(b.INVOICE_DATE, '^[0-9]{2}-[0-9]{2}-[0-9]{2}$') THEN TO_CHAR(TO_DATE(b.INVOICE_DATE, 'DD-MM-YY'), 'DD-MON-YYYY')
                        ELSE NULL 
                    END
            )
         OR (i.INVOICE_DATE IS NULL AND b.INVOICE_DATE IS NULL))
        AND (i.INVOICE_STATUS = b.INVOICE_STATUS OR (i.INVOICE_STATUS IS NULL AND b.INVOICE_STATUS IS NULL))
        AND (i.INVOICE_HOLD_REASON = b.INVOICE_HOLD_REASON OR (i.INVOICE_HOLD_REASON IS NULL AND b.INVOICE_HOLD_REASON IS NULL))
        AND (i.INVOICE_AMOUNT = TO_NUMBER(TRANSLATE(NVL(REPLACE(UPPER(b.INVOICE_AMOUNT), ',', ''),0), 'IOS', '105')) OR (i.INVOICE_AMOUNT IS NULL AND b.INVOICE_AMOUNT IS NULL))
)
ORDER BY ORDER_REF;