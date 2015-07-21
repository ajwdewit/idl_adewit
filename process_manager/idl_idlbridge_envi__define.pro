COMPILE_OPT IDL2, STRICTARRSUBS

PRO IDL_IDLBridge_ENVI::Reset
    ; Reset the IDL Bridge to pristine state, useful for client programs that
    ; leave garbage hanging around. Re-initialize ENVI as well.
    self -> IDL_IDLBridge_NT::Init
    self -> Execute, 'Envi, /RESTORE_BASE_SAVE_FILES & Message, /RESET'
    self -> Execute, 'Envi_Batch_Init & Message, /RESET'
END

;------------------------------------------------------------------------------
FUNCTION IDL_IDLBridge_ENVI::init, _EXTRA=extra

    Catch, error_status
    IF error_status NE 0 THEN BEGIN
        Catch, /cancel
        Help, /LAST_MESSAGE, OUTPUT=traceback
        FOR j=0, N_Elements(traceback)-1 DO Print, traceback[j]
        RETURN, 0
    ENDIF

    IF NOT self -> IDL_IDLBridge_NT::Init(_EXTRA=extra) THEN $
        Message, "IDL_IDLBridge_NT failed to initialize in IDL_IDLBridge_ENVI!"
    self -> Execute, 'Envi, /RESTORE_BASE_SAVE_FILES & Message, /RESET'
    self -> Execute, 'Envi_Batch_Init & Message, /RESET'
    RETURN, 1
    
END

PRO IDL_IDLBridge_ENVI__Define
    void = {IDL_IDLBridge_ENVI, $
            INHERITS IDL_IDLBridge_NT}
END
