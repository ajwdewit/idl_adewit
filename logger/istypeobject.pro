FUNCTION IsTypeObject, v

    CASE Size(v, /TYPE) OF
        11: RETURN, 1
    ELSE: RETURN, 0
    ENDCASE
END