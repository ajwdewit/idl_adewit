PRO resize_event, ev

END

PRO test_logger

    tlb = Widget_Base(/COLUMN, /TLB_SIZE_EVENTS)
    twid = Widget_Text(tlb, /SCROLL, XSIZE=600, YSIZE=400)
    widget_control, tlb, /realize
   ; xmanager, ''

    logger = Obj_New('cgi_advlogger')
    consolehandler = Obj_New('cgi_consolehandler', RESPONSE_LEVEL='info')
    logger->Add_Handler, consolehandler
    filehandler = Obj_New('cgi_filehandler', RESPONSE_LEVEL='debug', LOGFILE='logtest.txt')
    logger->Add_Handler, filehandler
    twhandler = Obj_New('cgi_textwidgethandler', RESPONSE_LEVEL='debug', TWID=twid)
    logger->Add_Handler, twhandler


    logger->debug, ["Testing logging at DEBUG level.", "second line of debug information", $
                    "third line of debug information"]
    logger->info, "Testing logging at INFO level."
    logger->warning, "Testing logging at WARNING level."
    logger->error, ["Testing logging at ERROR level.", "second line of error information"]
    logger->critical, "Testing logging at CRITICAL level."
    Obj_Destroy, logger

END