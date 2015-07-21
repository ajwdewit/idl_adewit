FUNCTION IsTypeUndefined, v

    CASE Size(v, /TYPE) OF
        0 : RETURN, 1
    ELSE: RETURN, 0
    ENDCASE
END