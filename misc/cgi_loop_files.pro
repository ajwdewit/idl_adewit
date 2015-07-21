; $Id: CGI_LOOP_FILES.PRO,  2004/01/15 00:25:29 wita Exp $
;
;+
; NAME:
;	  CGI_LOOP_FILES
;
; PURPOSE:
;	  Loop over a list of manually selected files
;
; CATEGORY:
;	  File handling
;
; CALLING SEQUENCE:
;	  CGI_LOOP_FILES
;
;
; OUTPUTS:
;	  None
;
;-


PRO cgi_loop_files
 
  filelist=dialog_pickfile(TITLE='Select input files', $
            /MULTIPLE_FILES, FILTER='*.txt')
  nrfiles=N_ELEMENTS(filelist)

  FOR i=0,nrfiles-1 DO BEGIN
    print, "You ought to to something on file: ", filelist[i]
  ENDFOR

END
