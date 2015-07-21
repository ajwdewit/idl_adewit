COMPILE_OPT idl2, strictarrsubs

;-------------------------------------------------------------------------------
PRO cgi_ConsoleHandler::Add_Log_Message, msg, LEVEL=level
    
    fmt = ['(%"%s %8s: %s")', '(%"%s %8s: + %s")'] 
    
    IF self->Respond(level) THEN BEGIN
        now = strmid(systime(),11,8)
        strlvl = self.log_levels[level]
        FOR i=0, N_Elements(msg)-1 DO $
            print, String(now, strlvl, msg[i], FORMAT=fmt[i<1])
    ENDIF

END

;-------------------------------------------------------------------------------
PRO cgi_ConsoleHandler::Cleanup
END
;-------------------------------------------------------------------------------
FUNCTION cgi_ConsoleHandler::Init, RESPONSE_LEVEL=response_level

    Catch, Error_Status
    IF Error_Status NE 0 THEN BEGIN
        Catch, /CANCEL
        Help, /LAST_MESSAGE, OUTPUT=traceback
        FOR i=0, N_Elements(traceback)-1 DO $
            Print, traceback[i]
        RETURN, 0
    ENDIF
    
    r = self -> cgi_BaseHandler::Init(RESPONSE_LEVEL=response_level)
    
    RETURN, 1
END

;-------------------------------------------------------------------------------
PRO cgi_ConsoleHandler__Define

    void = {cgi_ConsoleHandler,$
            INHERITS cgi_BaseHandler}
END
