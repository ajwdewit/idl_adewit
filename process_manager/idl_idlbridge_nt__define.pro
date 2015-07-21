COMPILE_OPT IDL2, STRICTARRSUBS

;------------------------------------------------------------------------------
PRO IDL_IDLBridge_NT::Reset
    ; Reset the IDL Bridge to pristine state, useful for client programs that
    ; leave garbage hanging around.
    self -> Execute, '.reset_session'
    self -> Execute, 'CPU, TPOOL_NTHREADS=1'
    
END

;------------------------------------------------------------------------------
FUNCTION IDL_IDLBridge_NT::init, _EXTRA=extra

    Catch, error_status
    IF error_status NE 0 THEN BEGIN
        Catch, /cancel
        Help, /LAST_MESSAGE, OUTPUT=traceback
        FOR j=0, N_Elements(traceback)-1 DO Print, traceback[j]
        RETURN, 0
    ENDIF

    IF NOT self -> IDL_IDLBridge::Init(_EXTRA=extra) THEN $
        Message, "IDL_IDLBridge failed to initialize in IDL_IDLBridge_NT!"
    ; Disable threading on the IDL Bridge
    self -> Execute, 'CPU, TPOOL_NTHREADS=1'
    RETURN, 1
    
END

;------------------------------------------------------------------------------
PRO IDL_IDLBridge_NT__Define
    void = {IDL_IDLBridge_NT, $
            INHERITS IDL_IDLBridge}
END
