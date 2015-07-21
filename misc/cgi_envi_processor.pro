; $Id: CGI_ENVI_PROCESSOR,v 1.1 2008/01/28$
;
;+
; NAME:
;	  CGI_ENVI_PROCESSOR
;
; PURPOSE:
;	  This is procedure implements a general purpose processing loop for 
;     procesing ENVI images, including tiling and a progress bar.
;
; CATEGORY:
;	  Image processing
;
; CALLING SEQUENCE:
;	  CGI_ENVI_PROCESSOR, inputfile, outputfile
;
; INPUTS:
;  	  inputfile = string specifying input file
;     outputfile =  string specifying output file
;
;
; OUTPUTS:
;	  This is dummy example which only converts the input image to float data
;
; SIDE EFFECTS:
;	  Needs ENVI to run ( if you don't see the 'ENVI>' prompt then you need
;     to start it by typing 'envi')
;
;
; MODIFICATION HISTORY:
; 	Written by:	Allard de Wit, June 2003
;                              January 2008 (modified)
;-

PRO cgi_envi_processor, inputfile, outputfile

    ;Define error handler for CGI_ENVI_PROCESSOR routine
    Catch, error_status
        IF error_status NE 0 THEN BEGIN
            Catch, /CANCEL
            ; Print error message to console
            Help, /LAST_MESSAGE, OUTPUT=traceback
            FOR j=0, N_Elements(traceback)-1 DO Print, traceback[j]

            ;Close any open files
            IF unit1 GT 0 THEN Free_LUN, unit1

            ; Cancel button was pressed
            IF cancel EQ 1 THEN BEGIN
              Envi_Report_Init, BASE=base, /FINISH
              Envi_Tile_Done, tile_id1
              Envi_Tile_Mng, ID=fid, /REMOVE
            ENDIF
        RETURN
    ENDIF

    ; Initialize some variables
    unit1 = 0
    cancel = 0

    ;Select input file
    IF N_Elements(inputfile) EQ 0 THEN BEGIN
        Envi_Select, TITLE='Select Input Filename', FID=fid, POS=pos, DIMS=dims
    ENDIF ELSE BEGIN
        Envi_Open_File, inputfile, R_FID=fid, /NO_REALIZE, /NO_INTERACTIVE_QUERY
    ENDELSE
    ; Return if no valid file was found
    IF (fid eq -1) THEN RETURN

    ; Select output file
    IF N_Elements(outputfile) EQ 0 THEN BEGIN
        outputfile = Envi_Pickfile(FILTER='*.img', TITLE='Select Output File!') 
        IF outputfile EQ "" THEN RETURN
    ENDIF 
    Openw, unit1, outputfile, /GET_LUN

    ;Query input file for information (lines, columns, bands, etc)
    Envi_File_Query, fid, DATA_TYPE=data_type, XSTART=xstart,$
      YSTART=ystart, INTERLEAVE=interleave, NB=nb, NL=nl, NS=ns
    map_info = Envi_Get_Map_Info(FID=infid)
    proj_info = Envi_Get_Projection(FID=infid)

    ; When input is specified on commandline, then process complete image
    IF N_Elements(pos) EQ 0 THEN pos = Indgen(nb)
    IF N_Elements(dims) EQ 0 THEN dims = [-1, 0, ns-1, 0, nl-1]

    ;Open input files and initialise tiling, use same interleave as input file
    tile_id1 = Envi_Init_Tile(fid, pos, NUM_TILES=num_tiles, INTERLEAVE=interleave)

    ;Initialise reporting
    rstr = ['Processing:','Output to : '+ outputfile]
    Envi_Report_Init, rstr, TITLE="Processing", BASE=base, /INTERRUPT
    Envi_Report_Inc, base, num_tiles

    ;Main processing loop
    FOR i=0L, num_tiles-1 DO BEGIN
        Envi_Report_Stat, base, i, num_tiles, CANCEL=cancel
        IF cancel THEN Message, "Processing interrupted by user!"
        data = Envi_Get_Tile(tile_id1, i)
        result = Float(data)
        Writeu, unit1, result
    ENDFOR

    ; Close output file
    Free_LUN, unit1

    ; Clean up progress bar
    Envi_Report_Init, BASE=base, /FINISH
    Envi_Tile_Done, tile_id1

    ; Remove input file from ENVI list
    Envi_File_Mng, Id=fid, /REMOVE

    ; Setup the header for the output file
    data_type = Size(result, /TYPE)
    Envi_Setup_Head, FNAME=outputfile, NS=ns, NL=nl, NB=nb, $
      DATA_TYPE=data_type, OFFSET=0, INTERLEAVE=interleave, $
      XSTART=xstart+dims[1], YSTART=ystart+dims[3], $
      DESCRIP='Image converted to float', /WRITE, /OPEN, $
      MAP_INFO=map_info

END
