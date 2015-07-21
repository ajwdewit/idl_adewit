COMPILE_OPT idl2, strictarrsubs

PRO Pass
    ; Do Nothing
END
;-------------------------------------------------------------------------------
PRO cgi_FileHandler::Add_Log_Message, msg, LEVEL=level
    
    fmt = ['(%"%s %8s: %s")', '(%"%s %8s: + %s")'] 
    IF self->Respond(level) THEN BEGIN
        now = strmid(systime(),11,8)
        strlvl = self.log_levels[level]
        FOR i=0, N_Elements(msg)-1 DO $
            Printf, self.logunit, String(now, strlvl, msg[i], FORMAT=fmt[i<1])
    ENDIF

END

;-------------------------------------------------------------------------------
PRO cgi_FileHandler::Cleanup
    Printf, self.logunit, "Log closed at: " + SysTime()
    Free_LUN, self.logunit
END

;-------------------------------------------------------------------------------
FUNCTION cgi_FileHandler::Init, RESPONSE_LEVEL=response_level, LOGFILE=logfile, $
        INITMSG=initmsg

    Catch, Error_Status
    IF Error_Status NE 0 THEN BEGIN
        Catch, /CANCEL
        Help, /LAST_MESSAGE, OUTPUT=traceback
        FOR i=0, N_Elements(traceback)-1 DO $
            Print, traceback[i]
        RETURN, 0
    ENDIF
    
    r = self -> cgi_BaseHandler::Init(RESPONSE_LEVEL=response_level)

    CASE 1 OF
      IstypeUndefined(initmsg) : $
          initmsg = "Log file created by IDL advanced logger"
      IstypeString(initmsg): Pass
      ELSE: Message, "INITMSG incorrectly specified."
    ENDCASE

    CASE 1 OF
      IstypeUndefined(logfile) : $ 
          self.logfile = FilePath('IDL_log.txt', /TMP)
      IsTypeString(logfile) : $
          BEGIN
            CD, CURRENT=pwd
            self.logfile = pwd + path_sep() + logfile
          END
    ELSE: Message, "LOGFILE incorrectly specified."
    ENDCASE

    ; Open log file for output
    OpenW, unit, self.logfile, ERROR=error, BUFSIZE=0, $
        WIDTH=1024, /GET_LUN
    IF (error NE 0) THEN Message, "Could not open log file: " + self.logfile
    print, "Writing log file to: " + self.logfile
    self.logunit = unit
    
    ; Print starting message
    Printf, self.logunit, "Log started at: " + SysTime()
    Printf, self.logunit, initmsg

    RETURN, 1
END

;-------------------------------------------------------------------------------
PRO cgi_FileHandler__Define

    void = {cgi_FileHandler,$
            INHERITS cgi_BaseHandler,$
            logfile:"", $
            logunit:0L}
END
