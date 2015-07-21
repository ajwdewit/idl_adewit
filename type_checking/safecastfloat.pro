FUNCTION SafeCastFloat, input, output

    ON_IOERROR, casterror
    output = Float(input)
    RETURN, 1
    
    casterror:
    RETURN, 0

END