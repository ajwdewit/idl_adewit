COMPILE_OPT idl2, strictarrsubs

;-------------------------------------------------------------------------------
PRO cgi_AdvLogger::Send_Msg_To_Handlers, msg, LEVEL=level

    ; Check for presence of handlers
    IF self.handlers_present EQ 0 THEN $
        Message, "Logger has no handlers to treat log message!"
        
    ; Check if there is a handler with a response_level GE to the
    ; level provided. Otherwise do nothing.
    IF level GE self->Lowest_Response_Level() THEN BEGIN
        ; Ensure that msg is of type string
        IF NOT IsTypeString(msg) THEN $
            Message, "Message passed to logger not of type STRING."
        handlers = (*self.handlers)[1:*]
        for i=0, N_Elements(handlers)-1 DO $
            handlers[i]->Add_Log_Message, msg, LEVEL=level
    ENDIF
END

;-------------------------------------------------------------------------------
PRO cgi_AdvLogger::Debug, msg
    self->Send_Msg_To_Handlers, msg, level=0
END

;-------------------------------------------------------------------------------
PRO cgi_AdvLogger::Info, msg
    self->Send_Msg_To_Handlers, msg, level=1
END

;-------------------------------------------------------------------------------
PRO cgi_AdvLogger::Warning, msg
    self->Send_Msg_To_Handlers, msg, level=2
END

;-------------------------------------------------------------------------------
PRO cgi_AdvLogger::Error, msg
    self->Send_Msg_To_Handlers, msg, level=3
END

;-------------------------------------------------------------------------------
PRO cgi_AdvLogger::Critical, msg
    self->Send_Msg_To_Handlers, msg, level=4
END

;-------------------------------------------------------------------------------
PRO cgi_AdvLogger::Add_Handler, handler
    IF Obj_Valid(handler) THEN BEGIN
        ; Add the handler to the list of handlers
        (*self.handlers)[0] = handler
        (*self.handlers) = [Obj_New(), (*self.handlers)]
        self.handlers_present = 1B
        ; Add its response level to the list of response levels
        handler->GetProperty, RESPONSE_LEVEL=response_level
        (*self.response_levels)[0] = response_level
        (*self.response_levels) = [5B, (*self.response_levels)]
    ENDIF ELSE BEGIN
        Message, "Tried to add an invalid handler object to the Logger."    
    ENDELSE
END

;-------------------------------------------------------------------------------
FUNCTION cgi_AdvLogger::Lowest_Response_Level
    ; Returns the lowest response level among the handlers
    IF self.handlers_present THEN $
        RETURN, Min((*self.response_levels)) $
    ELSE $
        Message, "Cannot return minimum reponse level: Logger has no handlers!"
END

;-------------------------------------------------------------------------------
PRO cgi_AdvLogger::Cleanup
    Obj_Destroy, (*self.handlers)
END

;-------------------------------------------------------------------------------
FUNCTION cgi_AdvLogger::Init
    self.handlers = Ptr_New(ObjArr(1))
    self.response_levels = Ptr_New(BytArr(1)+5B)
    RETURN, 1
END

;-------------------------------------------------------------------------------
PRO cgi_AdvLogger__Define

    void = {cgi_AdvLogger,$
        handlers:Ptr_New(), $        ; List of handlers
        response_levels:Ptr_New(), $ ; Response level corresponding to handlers
        lrl:0B, $                    ; Lowest response level among handlers
        handlers_present:0B $        ; Are there any handlers yet
        }
END
