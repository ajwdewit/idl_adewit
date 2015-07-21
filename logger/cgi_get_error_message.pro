FUNCTION cgi_Get_Error_Message, USER_TRACEBACK=user_traceback

    raw_message = !Error_State.Msg
    help, /LAST_MESSAGE, output=raw_traceback

;    ; Get the call stack and the calling routine's name.
    Help, Calls=callStack
    callingRoutine = (StrSplit(StrCompress(callStack[1])," ", /Extract))[0]

    doublecolon = StrPos(raw_message, "::")
    IF doublecolon NE -1 THEN BEGIN
   
        prefix = StrMid(raw_message, 0, doublecolon+2)
        submessage = StrMid(raw_message, doublecolon+2)
        colon = StrPos(submessage, ":")
        IF colon NE -1 THEN BEGIN
   
           ; Extract the text up to the colon. Is this the same as
           ; the callingRoutine? If so, strip it.
           IF StrMid(raw_message, 0, colon+StrLen(prefix)) EQ callingRoutine THEN $
              raw_message = StrMid(raw_message, colon+1+StrLen(prefix))
         ENDIF
    ENDIF ELSE BEGIN
  
        colon = StrPos(raw_message, ":")
        IF colon NE -1 THEN BEGIN
   
           ; Extract the text up to the colon. Is this the same as
           ; the callingRoutine? If so, strip it.
           IF StrMid(raw_message, 0, colon) EQ callingRoutine THEN $
               raw_message = StrMid(raw_message, colon+1)
        ENDIF
  
    ENDELSE

    ; If this is an error produced with the MESSAGE command, it is a trapped
    ; error and will have the name "IDL_M_USER_ERR".
    IF !ERROR_STATE.NAME EQ "IDL_M_USER_ERR" THEN BEGIN
        fmt = '(%"Trapped error in %s: %s")'
        return_message = [String(callingRoutine, raw_message, FORMAT=fmt)]
        IF Keyword_Set(user_traceback) THEN BEGIN
            r = StrSplit(raw_traceback[1], /EXTRACT)
            fmt = '(%"Occurred at line %i in %s")'
            return_message = [return_message, String(r[5], r[6], FORMAT=fmt)]
        ENDIF
    ENDIF ELSE BEGIN
   
        ; Otherwise, this is an IDL system error.
        fmt = '(%"System error in %s: %s")'
        return_message = [String(callingRoutine, raw_message, FORMAT=fmt)]
        r = StrSplit(raw_traceback[1], /EXTRACT)
        fmt = '(%"Occurred at line %i in %s")'
        return_message = [return_message, String(r[5], r[6], FORMAT=fmt)]
    ENDELSE

  RETURN, return_message
END