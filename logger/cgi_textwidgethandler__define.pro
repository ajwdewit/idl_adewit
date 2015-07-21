COMPILE_OPT idl2, strictarrsubs

PRO Pass
    ; Do Nothing
END
;-------------------------------------------------------------------------------
PRO cgi_TextWidgetHandler::Add_Log_Message, msg, LEVEL=level
    
    fmt = ['(%"%s %8s: %s")', '(%"%s %8s: + %s")'] 
    IF self->Respond(level) THEN BEGIN
        now = strmid(systime(),11,8)
        strlvl = self.log_levels[level]
        FOR i=0, N_Elements(msg)-1 DO $
            Widget_Control, self.textwidget_id, /APPEND, $
                SET_VALUE=String(now, strlvl, msg[i], FORMAT=fmt[i<1])
    ENDIF

END

;-------------------------------------------------------------------------------
PRO cgi_TextWidgetHandler::Cleanup
    Pass
END

;-------------------------------------------------------------------------------
FUNCTION cgi_TextWidgetHandler::Init, RESPONSE_LEVEL=response_level, TWID=twid, $
        INITMSG=initmsg, TITLE=title

    Catch, Error_Status
    IF Error_Status NE 0 THEN BEGIN
        Catch, /CANCEL
        Help, /LAST_MESSAGE, OUTPUT=traceback
        FOR i=0, N_Elements(traceback)-1 DO $
            Print, traceback[i]
        RETURN, 0
    ENDIF
    
    r = self -> cgi_BaseHandler::Init(RESPONSE_LEVEL=response_level)
    
    ; Check for initmsg
    CASE 1 OF
      IstypeUndefined(initmsg) : $
          initmsg = "Log created by IDL advanced logger"
      IstypeString(initmsg): Pass
      ELSE: Message, "INITMSG incorrectly specified."
    ENDCASE

    ; Check for title
    CASE 1 OF
      IstypeUndefined(initmsg) : $
          title = "IDL Log Console"
      IstypeString(title): Pass
      ELSE: Message, "TITLE incorrectly specified."
    ENDCASE

    CASE 1 OF
      IsTypeInteger(twid) : $
            self.textwidget_id = twid
      ELSE: $
        BEGIN
            tlb = Widget_Base(/COLUMN, /TLB_SIZE_EVENTS, TITLE=title)
            twid = Widget_Text(tlb, /SCROLL, XSIZE=120, YSIZE=30)
            widget_control, tlb, /realize
            self.textwidget_id = twid
        END
    ENDCASE

    ; Print starting message to text widget
    widget_value = ["Log started at: " + SysTime(), initmsg]
    widget_control, self.textwidget_id, set_value=widget_value, /APPEND

    RETURN, 1
END

;-------------------------------------------------------------------------------
PRO cgi_TextWidgetHandler__Define

    void = {cgi_TextWidgetHandler,$
            INHERITS cgi_BaseHandler,$
            textwidget_id:0L}
END
