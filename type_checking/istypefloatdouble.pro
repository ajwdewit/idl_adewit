FUNCTION IsTypeFloatSingle, v

    CASE Size(v, /TYPE) OF
        5: RETURN, 1
    ELSE: RETURN, 0
    ENDCASE
END