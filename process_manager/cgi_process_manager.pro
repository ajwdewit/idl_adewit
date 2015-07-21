; $Id: CGI_PROCESS_MANAGER.pro,v 1.1 2008/03/05 $
;
;+
; NAME:
;   CGI_PROCESS_MANAGER
;
; PURPOSE:
;   Spawn multiple IDL processes on multi-cpu system
;
; CATEGORY:
;   Process management/parallel processing
;
; CALLING SEQUENCE:
;   CGI_PROCESS_MANAGER, tasks
;
; INPUTS:
;      tasks: Array of structures which defines for each task the parameters
;             needed for that task as structure tags. Include a
;             structure tag 'use_envi' (initialized to whatever) to indicate
;             that ENVI functionality should be initialized by the client.
;
; KEYWORD VARIABLES
;
;   Other Keywords (OPTIONAL):"
;     LOG_FILE: (full path to) Filename used to write the log to."
;
; SIDE EFFECTS:
;   Needs the cgi_logger__define object from the CGI IDL library
;   Needs the cgi_taskmanager__define object from the CGI IDL library
;   Needs the cgi_process_client procedure from the CGI IDL library
;
; EXAMPLE
;   tasks = replicate({var1:0UL}, 25)
;   tasks[*].var1 = indgen(25)+25000000UL
;   cgi_process_manager, tasks
;
; MODIFICATION HISTORY:
;   Written by:  Allard de Wit, January 2008
;
; LICENSE:
;   This software is made available under the GPL. See http://www.gnu.org/licenses/gpl.html
;-
COMPILE_OPT IDL2, STRICTARRSUBS

;---------------------------------------------------------------------------------------------------
PRO Pass
    ; Do Nothing, aka Python
END

;---------------------------------------------------------------------------------------------------
PRO Execute_Task_on_Bridge, tm, idl_bridges, i, logger
    ; Get a new task from the list
    task_id = tm -> Get_Task_Id()
    task = tm -> Get_Task()

    ; Send Log message
    fmt = '("Acquired bridge: ", I, " for task: ", I)'
    logstr = String(i, task_id, FORMAT=fmt)
    Print, logstr
    logger -> Add_Log_Message, logstr
    
    ; Save task info to .SAV files which will be restored by the client
    fmt = '("task_",A,".sav")'
    strtask_id = StrCompress(task_id, /REMOVE_ALL)
    sav_file = FilePath(String(strtask_id, FORMAT=fmt), /TMP)
    Save, task, FILENAME=sav_file

    ; Execute the task on the IDL_bridge
    idl_bridges[i] -> SetVar, 'task_id', task_id
    fmt = '("Cgi_Process_Client, ''", A,"'', task_id")'
    execstr = String(sav_file, FORMAT=fmt)
    idl_bridges[i] -> Execute, execstr, /NOWAIT
    
END
;---------------------------------------------------------------------------------------------------
PRO Cgi_Process_Manager, tasks, LOG_FILE=log_file, USE_ENVI=use_envi

    ;Define error handler for CGI_PROCESS_MANAGER routine
    Catch, error_status
    IF error_status NE 0 THEN BEGIN
        Catch, /CANCEL
        ; trace error message and send to log
        Help, /LAST_MESSAGE, OUTPUT=traceback
        IF Obj_Valid(logger) THEN BEGIN
            FOR j=0, N_Elements(traceback)-1 DO logger->add_log_message, traceback[j]
            logger -> Write_Log_Messages
        ENDIF ELSE BEGIN
            Print, "No valid Logger object, printing error to console:"
            FOR j=0, N_Elements(traceback)-1 DO Print, traceback[j]
        ENDELSE
        Obj_Destroy, [logger, tm]
        Obj_Destroy, idl_bridges
        Print, "Process manager exit with failures, see log for details."
        RETURN
    ENDIF
    
    IF N_Elements(tasks) EQ 0 THEN BEGIN
      Print, "No tasks provided to cgi_process_manager!"
      RETURN
    ENDIF

    ; Define empty placeholders for objects
    logger = Obj_New()
    tm = Obj_New()
    idl_bridges = Obj_New()

    ; Delete any dangling .SAV files or error log files
    f = File_Search(Filepath('task_*.sav', /TMP), COUNT=c)
    IF c GT 0 THEN File_Delete, f
    f = file_search(Filepath('task*.error', /TMP), COUNT=c)
    IF c GT 0 THEN File_Delete, f

    ; Start logging
    IF N_Elements(log_file) EQ 0 THEN $
       LOG_FILE=FilePath("cgi_process_manager_log.txt", /TMP)
    logger = Obj_New("CGI_LOGGER", LOG_FILE=log_file, $
                     LOG_INIT_MESSAGE="Log file created by cgi_process_manager.")

    ; Determine available cores and create bridges
    ncores = !CPU.hw_ncpu
    logstr = "Detected " + String(ncores) + " processing cores!"
    logger -> Add_Log_Message, logstr
    idl_bridges = ObjArr(ncores)
    IF Keyword_Set(use_envi) THEN $
        FOR i=0, ncores-1 DO idl_bridges[i] = Obj_New('IDL_IDLBridge_ENVI') $
    ELSE $
    	FOR i=0, ncores-1 DO idl_bridges[i] = Obj_New('IDL_IDLBridge_NT') 

    ; Create the task manager
    tm = Obj_New("CGI_TASKMANAGER", tasks)

    ; Start pushing tasks to IDL Bridges
    WHILE tm -> Tasks_Available() EQ 1 DO BEGIN
        available_cores = ncores
        FOR i=0, ncores-1 DO BEGIN
            terminate_loop = 0
            ; Test Status of bridge
            status = idl_bridges[i] -> Status(ERROR=errstr)
            CASE status OF
                0 : BEGIN ; Bridge is idle
                        Execute_Task_on_Bridge, tm, idl_bridges, i, logger
                        terminate_loop = 1
                    END
                1 : available_cores -= 1 ; Bridge executing task
                2 : BEGIN ; Task completed on bridge
                        ; Send message to log
                        completed_task = idl_bridges[i] -> GetVar('task_id')
                        fmt = '("Task ",I," completed successfully.")'
                        logger -> Add_Log_Message, String(completed_task, FORMAT=fmt)
                        ; Start new task on bridge
                        Execute_Task_on_Bridge, tm, idl_bridges, i, logger
                        terminate_loop = 1
                    END
                3 : BEGIN ; Task halted due to error
                        ; Send message to log
                        halted_task = idl_bridges[i] -> GetVar('task_id')
                        fmt = '("Task ",I ," halted with message: ", A)'
                        logger -> Add_Log_Message, String(halted_task, errstr, FORMAT=fmt)
                        logger -> Add_Log_Message, "See client log for details."
                        ; Start new task on bridge
                        Execute_Task_on_Bridge, tm, idl_bridges, i, logger
                        terminate_loop = 1
                        END
           ENDCASE
           ; Terminate FOR loop when a new task has been executed. 
           ; This is necessary in order to check tm -> Tasks_Available() as
           ; you might have executed the last task. 
           ; Note: You cannot put the BREAK in the CASE construct directly as
           ; this will terminate the CASE rather then the FOR loop.
           IF terminate_loop EQ 1 THEN BREAK
        ENDFOR

        IF available_cores EQ 0 THEN BEGIN
            Print, "Waiting for IDL bridges to become available."
            Wait, 1
        ENDIF
    ENDWHILE

    ; If no tasks left, then check whether all processes are done
    WHILE 1 DO BEGIN
        Print, "Waiting for all processes to finish!"
        processes_done = 0
        FOR i=0, ncores-1 DO BEGIN
            ; Test Status of bridge
            status = idl_bridges[i] -> Status(ERROR=errstr)
            CASE status OF
                0 : BEGIN ; Bridge is idle
                        processes_done += 1
                    END
                1 : Pass ; Bridge executing task
                2 : BEGIN ; Task completed on bridge
                        ; Send message to log
                        completed_task = idl_bridges[i] -> GetVar('task_id')
                        fmt = '("Task ",I," completed successfully.")'
                        logger -> Add_Log_Message, String(completed_task, FORMAT=fmt)
                        ; Increase counter
                        processes_done += 1
                    END
                3 : BEGIN ; Task halted due to error
                        ; Send message to log
                        halted_task = idl_bridges[i] -> GetVar('task_id')
                        fmt = '("Task ",I ," halted with message: ", A)'
                        logger -> Add_Log_Message, String(FORMAT=fmt, halted_task, errstr)
                        logger -> Add_Log_Message, "See client log for details."
                        ; Increase counter
                        processes_done += 1
                    END
           ENDCASE
        ENDFOR

        ; Terminate the while loop if all processes are finished.
        IF processes_done EQ ncores THEN BREAK

        ; Test for completion of tasks each second
        Wait, 1
    ENDWHILE

    ; Delete remaining .SAV files
    f = File_Search(Filepath('task_*.sav', /TMP), COUNT=c)
    IF c GT 0 THEN File_Delete, f

    ;close log and destroy objects
    logger -> Write_Log_Messages
    Obj_Destroy, [logger, tm]
    Obj_Destroy, idl_bridges

END
