COMPILE_OPT IDL2

FUNCTION Extract_ROI_data, roi_id, infid, nb, roi_name
    ; Extracts the ROI data, this was put in a auxillary function in order
    ; to catch off errors that may occur when extracting image data using ROIs.
    Catch, error_status
    IF error_status NE 0 THEN BEGIN
        Catch, /Cancel
        Print, "Failed to retrieve ROI data for ID: ", roi_name
        RETURN, -1
    ENDIF
    RETURN, Envi_Get_ROI_Data(roi_id, FID=infid, POS=Indgen(nb))
END

;-------------------------------------------------------------------------------
FUNCTION Strip_Ignore_Values, roi_data, ignore_values
    ; Removes the ignore values from the data
    
    IF N_Elements(ignore_values) EQ 0 THEN RETURN, roi_data
    
    ; Make a copy of the roi_data to make sure that the original data
    ; is not changed when roi_data is passed by reference
    tmp_data = roi_data
    
    FOR i=0, N_Elements(ignore_values)-1 DO BEGIN
        index = WHERE(tmp_data EQ ignore_values[i], COMPLEMENT=cmpl, $
                      NCOMPLEMENT=n_cmpl)
        IF n_cmpl GT 0 THEN $
          tmp_data = tmp_data[cmpl] $
        ELSE $
          RETURN, -1
    ENDFOR
    
    RETURN, tmp_data
END

;-------------------------------------------------------------------------------
FUNCTION Calc_ROI_stats, roi_data, nb, IGNORE_VALUES=ignore_values
    ; Calculates basic ROI statistics for each band and returns a
    ; structure with this data
    
    
    ; Calculate statistics by looping over bands
    band_means = [-99.99]
    band_sds = [-99.99]
    band_cnt = [-99]
    IF nb EQ 1 THEN roi_data = Reform(nb, N_Elements(roi_data), /OVERWRITE)
    FOR i=0, nb-1 DO BEGIN
        tmp_data = strip_ignore_values(roi_data[i,*], ignore_values)
        IF N_Elements(tmp_data) GT 1 THEN BEGIN
            band_means = [band_means, (Moment(tmp_data))[0]]
            band_sds = [band_sds, Sqrt((Moment(tmp_data))[1])]
            band_cnt = [band_cnt, N_Elements(tmp_data)]
        ENDIF ELSE BEGIN
            band_means = [band_means, !values.f_nan]
            band_sds = [band_sds, !values.f_nan]
            band_cnt = [band_cnt, N_Elements(tmp_data)]
        ENDELSE
    ENDFOR
    
    RETURN, {band_means:band_means[1:*], band_sds:band_sds[1:*], $
             band_cnt:band_cnt[1:*]}

END

;-------------------------------------------------------------------------------
PRO Test_Files_Available, ROI_filename, image_filename
    ; Test for existence of files, otherwise generate an error.
    IF NOT File_Test(ROI_filename, /READ, /REGULAR) THEN $
        Message, "ROI File does not exist!"
    IF NOT File_Test(image_filename, /READ, /REGULAR) THEN $
      Message, "Image File does not exist!"
END

;-------------------------------------------------------------------------------
PRO Print_Usage
    Print, "Procedure usage info to be updated"
    RETALL
END

;-------------------------------------------------------------------------------
FUNCTION Get_ROI_name, roi_id
    ; Strip the annotations from the roi name, we are only interested
    ; in the identifier which is between brackets
    r = Envi_Get_ROI(roi_id, ROI_NAME=roi_name)
    RETURN, (strsplit(roi_name, "()", /EXTRACT))[1]
END
;-------------------------------------------------------------------------------
FUNCTION cgi_ROI_Stats, ROI_filename, image_filename, $
                        IGNORE_VALUES=iv
    ; This procedure takes a filename with ROI and an associated image
    ; file to calculate image statistics per ROI

    Catch, error_status
    IF error_status NE 0 THEN BEGIN
        Catch, /Cancel
        Help, /LAST_MESSAGE, OUTPUT=traceback
        FOR j=0, N_Elements(traceback)-1 DO Print, traceback[j]
        Envi_Delete_ROIs, /ALL
        IF infid NE -1 THEN Envi_File_Mng, ID=infid, /REMOVE
        IF Obj_Valid(progress_bar) THEN progress_bar -> Destroy
        RETURN, -1
    ENDIF
    
    ; Initialize some variables, check parameters and existence of files
    infid = -1
    progress_bar = Obj_New()
    IF N_Elements(ROI_filename) NE 1 THEN print_usage
    IF N_Elements(image_filename) NE 1 THEN print_usage
    Test_Files_Available, ROI_filename, image_filename
    
    ; Open Image file
    Envi_Open_File, image_filename, r_fid=infid, /NO_INTERACTIVE_QUERY, $
      /NO_REALIZE
    IF (infid EQ -1) THEN BEGIN
      Message, "ERROR: Failed opening image '" + image_filename + "'!"
    ENDIF

    ; Query image file for information
    Envi_File_Query, infid, NB=nb
    map_info = Envi_Get_Map_Info(fid=infid)
    proj_info = Envi_Get_Projection(fid=infid)
    
    ; Restore ROIs and get ROI IDs that match the input image, only restore 
    ; if there are no ROIs already in memory
    IF NOT (envi_get_roi_ids(FID=infid))[0] EQ -1 THEN $
      Envi_Delete_ROIs, /ALL
    envi_restore_rois, ROI_filename
    roi_ids = envi_get_roi_ids(FID=infid, roi_names=roi_names)
    IF roi_ids[0] EQ -1 THEN $
      Message, "Failed to restore ROIs from file: ", ROI_filename $
    ELSE $
      print, "Restored ROIs in file: ", ROI_filename
    print, "# of ROI IDs available: ", N_Elements(roi_ids)
    
    ; Setup the progress bar
    progress_bar = Obj_New("PROGRESSBAR", /FAST_LOOP, /START, $
                           TEXT="Processing ROIs")

    ; Define output structure
    roi_statistics = {roi_names:StrArr(N_Elements(roi_ids)), $
                      roi_stats:PtrArr(N_Elements(roi_ids)), $
                      valid_stats:BytArr(N_Elements(roi_ids))}

    ; Start main processing loop
    FOR i=0L, N_Elements(roi_ids)-1 DO BEGIN
        ; Update progressbar and check for cancel button
        progress_bar -> Update, Float(i)/N_Elements(roi_ids) * 100
        c = progress_bar -> CheckCancel()
        IF c THEN Message, "Processing ROIs cancelled."
        ; Get the ROI name first
        roi_name = (strsplit(roi_names[i], "()", /EXTRACT))[1]
        ; Get the dims pointer
        dims = [envi_get_roi_dims_ptr(roi_ids[i]), 0,0,0,0]
        ; Then get the ROI DATA
        roi_data = Extract_ROI_data(roi_ids[i], infid, nb, roi_name)
        IF roi_data[0] EQ -1 THEN BEGIN
          stats = !VALUES.F_NAN 
          valid_stats = 0
        ENDIF ELSE BEGIN
          stats = Calc_ROI_stats(roi_data, nb, IGNORE_VALUES=iv)
          valid_stats = 1
        ENDELSE
        roi_statistics.roi_names[i] = roi_name
        roi_statistics.roi_stats[i] = Ptr_New(stats)
        roi_statistics.valid_stats[i] = valid_stats
    ENDFOR
    
    ;Clean up   
    Envi_Delete_ROIs, /ALL
    Envi_File_Mng, ID=infid, /REMOVE
    progress_bar -> Destroy

    RETURN, roi_statistics

END
