FUNCTION IsTypeFloat, v

    CASE Size(v, /TYPE) OF
        4: RETURN, 1
        5: RETURN, 1
    ELSE: RETURN, 0
    ENDCASE
END