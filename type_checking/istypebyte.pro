FUNCTION IsTypeByte, v

    CASE Size(v, /TYPE) OF
        1: RETURN, 1
    ELSE: RETURN, 0
    ENDCASE
END