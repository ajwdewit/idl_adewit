; $Id: cgi_taskmanager__define.pro,v 1.1 2008/03/05$
;
; Copyright (c) 2008, Allard de Wit
;+
; NAME:
;     CGI_TASKMANAGER__DEFINE
;
; PURPOSE:
;     Provides simple task manager for IDL
;
;
; CALLING SEQUENCE:
;     taskmanager_object = OBJ_NEW("cgi_taskmanager", tasks)
;
; INPUTS:
;     Tasks = Array of structures define the parameters for each task as
;                 structure tags.
;
; KEYWORD PARAMETERS:
;         None
;
; OUTPUTS:
;         None
;
; EXAMPLE:
;         tasks = Replicate({var1:0UL}, 25)
;         tasks[*].var1 = Indgen(25)+25000000UL
;         tm = OBJ_NEW("CGI_TASKMANAGER", tasks)
;         WHILE tm -> tasks_available() EQ 1 DO BEGIN
;           print, tm -> get_task_id()
;           print, tm -> get_task()
;         ENDWHILE
;         obj_destroy, tm
;
; MODIFICATION HISTORY:
;   Written by:  Allard de Wit, January 2008
;
; LICENSE:
;   This software is made available under the GPL. See http://www.gnu.org/licenses/gpl.html
;-
COMPILE_OPT IDL2, STRICTARRSUBS

FUNCTION CGI_TASKMANAGER::Get_Task_ID

  RETURN, self.task_id

END

;------------------------------------------------------------------------------
FUNCTION CGI_TASKMANAGER::Tasks_Available

  IF self.task_id LT N_Elements(*self.tasks) THEN $
    RETURN, 1 $
  ELSE $
    RETURN, 0

END

;------------------------------------------------------------------------------
FUNCTION CGI_TASKMANAGER::Get_Task

  IF self.task_id LT N_Elements(*self.tasks) THEN BEGIN
    new_task = (*self.tasks)[self.task_id]
    self.task_id += 1
  ENDIF ELSE BEGIN
    Message, "No more tasks left in tasklist!"
  ENDELSE

  RETURN, new_task

END

;------------------------------------------------------------
FUNCTION CGI_TASKMANAGER::Cleanup

  Ptr_Free, self.tasks

END

;------------------------------------------------------------------------------
FUNCTION CGI_TASKMANAGER::Init, tasks

  self.tasks = Ptr_New(tasks)
  self.task_id = 0
  RETURN, 1

END

;------------------------------------------------------------------------------
PRO CGI_TASKMANAGER__DEFINE

  void={CGI_TASKMANAGER, $
        tasks : Ptr_New(), $     ; ptr to tasklist
        task_id : 0L}            ; counter for keeping track of task number

END
