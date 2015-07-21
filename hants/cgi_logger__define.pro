; Copyright (c) 2005, Allard de Wit
;+
; NAME:
;	  CGI_LOGGER__DEFINE
;
; PURPOSE:
;	  Provides simple logging under IDL
;
;
; CALLING SEQUENCE:
;	  Logger_object = OBJ_NEW("cgi_logger")
;
; INPUTS:
;	  None
;
; KEYWORD PARAMETERS:
;	  LOG_FILE:	String keyword providing name of the log file for output.
;	 	          Using 'IDL_logger.txt' if not specified.
;
;   LOG_INIT_MESSAGE: First string written to the log file in order to 
;                     identify the log file. If not specified a default
;                     string will be used.
;
; OUTPUTS:
;   None
;
;
; EXAMPLE:
;		 logger = OBJ_NEW("cgi_logger", log_file="my_log.txt",$
;                      log_init_message="My first log file")
;
;   logger->add_log_message, "IDL is Cool"  
;   logger->add_log_message, ["Python is even cooler", "Or you better use both!"] 
;   logger->write_log_messages
;   OBJ_DESTROY, logger
;
; MODIFICATION HISTORY:
; 	Written by:	Allard de Wit, July 2005.
;-

PRO cgi_logger::write_log_messages
  
END

;------------------------------------------------------------

PRO cgi_logger::add_log_message, str
  
    msg = String(str)
    Printf, self.log_unit, msg

END

;------------------------------------------------------------

FUNCTION cgi_logger::cleanup

    PRINTF, self.log_unit, "Log closed at: " + SYSTIME()
    Free_LUN, log_unit

END

;------------------------------------------------------------

FUNCTION cgi_logger::init, log_file=log_file, log_init_message=log_init_message

    Catch, error_status
    IF error_status NE 0 THEN BEGIN
        Catch, /CANCEL
        Help, /LAST_MESSAGE, OUTPUT=traceback
        Print, "cgi_logger failed to initialize:"
        FOR j=0, N_Elements(traceback)-1 DO Print, traceback[j]
        RETURN, 0
    ENDIF
    
    IF N_ELEMENTS(log_init_message) EQ 0 THEN $
      log_init_message="Simple IDL logger created by Allard de Wit - 2005"
    IF N_ELEMENTS(log_file) EQ 0 THEN $
      log_file="IDL_logger.txt"

    self.log_filename = log_file
    OPENW, unit, log_file, /GET_LUN, BUFSIZE=0, WIDTH=1000
    self.log_unit = unit
  
    Printf, unit, STRING(log_init_message)
    Printf, unit, "Log created at: " + SYSTIME()

    print, "Logger initialised!"
    RETURN, 1

END

;------------------------------------------------------------

PRO cgi_logger__define

	void={cgi_logger, $
	      log_filename:"",$  ; file name of log file
          log_unit:0L}       ; unit number of log file

END
