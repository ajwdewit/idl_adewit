FUNCTION cgi_Simple_Logger, LOGFILE=logfile, INITMSG=initmsg

    logger = Obj_New('cgi_advlogger')
    consolehandler = Obj_New('cgi_consolehandler', RESPONSE_LEVEL='WARNING')
    logger->Add_Handler, consolehandler
    filehandler = Obj_New('cgi_filehandler', RESPONSE_LEVEL='INFO', $
                  LOGFILE=logfile, INITMSG=initmsg)
    logger->Add_Handler, filehandler

    RETURN, logger
END