--INVOICE

-- INSERT OF DATA INTO INVOICE FROM BCM_ORDER_MGT
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
WHERE NOT EXISTS 
(
    SELECT 1
    FROM INVOICE i
    WHERE 
		i.INVOICE_REFERENCE = b.INVOICE_REFERENCE
        AND i.MAIN_ID = b.MAIN_ID
)
ORDER BY ORDER_REF;
commit;