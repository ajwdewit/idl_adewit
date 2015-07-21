; $Id: CGI_PROCESS_CLIENT.pro,v 1.1 2008/03/05 $
;
;+
; NAME:
;   CGI_PROCESS_CLIENT
;
; PURPOSE:
;   Client script for starting multiple IDL processes on multi-cpu system
;
; CATEGORY:
;   Process management/parallelel processing
;
; CALLING SEQUENCE:
;   CGI_PROCESS_CLIENT, sav_file, task_id
;
; INPUTS:
;   sav_file: String providing the name of the IDL SAVE file that the client needs to 
;             restore. The client retrieves the parameters needed to start the process 
;             from the restored SAVE file.
;   task_id:  Number identying the task, this is only used for writing an error log in
;             case something fails during processing.
;
; KEYWORD VARIABLES
;  None
;
; SIDE EFFECTS:
;  Code at line 69 has to be adapted to your specific application
;  Uses the PROGRESSBAR module from the David Fannings Coyote library
;
; MODIFICATION HISTORY:
;   Written by:  Allard de Wit, January 2008
;
; LICENSE:
;   This software is made available under the European Union Public License (EUPL), see LICENSE file
;-
COMPILE_OPT IDL2, STRICTARRSUBS

PRO run_process_example, A, task_id
   
   ;Message, "Error raised on purpose!"
   progressbar = Obj_New("PROGRESSBAR", /FAST_LOOP, /NOCANCEL, /START, XSIZE=200, $
                         TITLE = ('Running task ' + StrCompress(task_id , /REMOVE_ALL)))
   t = 0UL
   FOR i=0UL, A DO BEGIN
     t += i
     if (i mod 1000) EQ 0  THEN progressBar -> Update, (i/Float(A))*100
   ENDFOR
   print, "Finished task:, ",task_id, " Result = ", t
   progressBar -> Destroy
END

;-------------------------------------------------------------------------------
PRO cgi_process_client, sav_file, task_id

  ;Define error handler for CGI_PROCESS_CLIENT routine
  Catch, error_status
  IF error_status NE 0 THEN BEGIN
    Catch, /CANCEL   
    Help, /LAST_MESSAGE, OUTPUT=traceback
    task_logfile = FilePath("task_" + StrCompress(task_id, /REMOVE_ALL) $
                            + ".error", /TMP) 
    Openw, unit, task_logfile, /GET_LUN
    FOR j=0, N_Elements(traceback)-1 DO Printf, unit, traceback[j]
    Close, unit & Free_lun, unit
    RETURN
  ENDIF
  
  ; Restore variables from SAVE file
  Restore, filename=sav_file

  ; Put your application specific code here
  Run_Process_Example, task.var1, task_id
  
END
