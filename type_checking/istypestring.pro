FUNCTION IsTypeString, v

    CASE Size(v, /TYPE) OF
        7: RETURN, 1
    ELSE: RETURN, 0
    ENDCASE
END