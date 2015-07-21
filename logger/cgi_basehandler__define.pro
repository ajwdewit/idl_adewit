COMPILE_OPT idl2, strictarrsubs

FUNCTION cgi_BaseHandler::Respond, level
    IF level GE self.response_level THEN $
        RETURN, 1 $
    ELSE $
        RETURN, 0
END

;-------------------------------------------------------------------------------
PRO cgi_BaseHandler::Check_Log_Level, response_level

    CASE 1 OF
        IsTypeString(response_level) : $
          BEGIN
            lvl = Where(self.log_levels EQ StrUpCase(response_level), count)
            IF count EQ 1 THEN BEGIN
                self.response_level = lvl[0]
            ENDIF ELSE BEGIN
                fmt = '(%"Response level %s not recognized in call to Handler")'
                msg = String(response_level, FORMAT=fmt)
                Message, msg
            ENDELSE
          END
        IsTypeInteger(response_level) : $
          BEGIN
            IF (response_level GE 0) AND (response_level LE 4) THEN BEGIN
                self.response_level = response_level
            ENDIF ELSE BEGIN
                fmt = '(%"Response level %i not recognized in call to Handler")'
                msg = String(response_level, FORMAT=fmt)
                Message, msg                
            ENDELSE
          END
    ELSE: Message, "Invalid value for keyword RESPONSE_LEVEL."
    ENDCASE
END

;-------------------------------------------------------------------------------
PRO cgi_BaseHandler::GetProperty, RESPONSE_LEVEL=response_level

    IF Arg_Present(response_level) THEN $
       response_level = self.response_level

END

;-------------------------------------------------------------------------------
PRO cgi_BaseHandler::SetProperty, RESPONSE_LEVEL=response_level

     IF N_Elements(response_level) NE 0 THEN $
         self.response_level = response_level

END
;-------------------------------------------------------------------------------
FUNCTION cgi_BaseHandler::Init, RESPONSE_LEVEL=response_level

    Catch, Error_Status
    IF Error_Status NE 0 THEN BEGIN
        Catch, /CANCEL
        Help, /LAST_MESSAGE, OUTPUT=traceback
        FOR i=0, N_Elements(traceback)-1 DO $
            Print, traceback[i]
        RETURN, 0
    ENDIF
    
	self.log_levels = ['DEBUG','INFO','WARNING','ERROR','CRITICAL']
	self->Check_Log_Level, response_level
    RETURN, 1
    
END
;-------------------------------------------------------------------------------
PRO cgi_BaseHandler__Define

    void = {cgi_BaseHandler,$
        response_level:0B, $
		log_levels:StrArr(5) $
        }
END
