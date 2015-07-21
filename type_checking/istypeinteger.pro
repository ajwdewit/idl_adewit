FUNCTION IsTypeInteger, v

    CASE Size(v, /TYPE) OF
        1: RETURN, 1
        2: RETURN, 1
        3: RETURN, 1
       12: RETURN, 1
       13: RETURN, 1
       14: RETURN, 1
       15: RETURN, 1
    ELSE: RETURN, 0
    ENDCASE
END
