; $Id: CGI_SAGOF.pro,v 1.0 2004/12/13 13:13:52 wita Exp $
;
;+
; NAME: 
;   CGI_SAGOF
;
; PURPOSE: 
;   ENVI wrapper for Savitsky Golay filtering of NDVI time series
;
; CATEGORY: 
;   1D signal processing
;
; CALLING SEQUENCE: 
;   CGI_SAGOF
;
; INPUTS:
;   None: routine will ask for input file through ENVI dialogue.
;
; OUTPUTS:
;   None: routine will ask for output file through ENVI dialogue.
;
; SIDE EFFECTS:
;   Will need ENVI to run 
;
; MODIFICATION HISTORY:  
;   Written by:  Allard de Wit, November 2004
;
; LICENSE: 
;   This software is made available under the European Union Public License (EUPL), see LICENSE file
;-

PRO CGI_SAGOF

  ;Select input VI file (NDVI or something else)
  envi_select, title='Input VI Filename', fid=infid, pos=inpos, dims=dims
  IF (infid eq -1) THEN RETURN

  ;Query input file for information (lines, columns, bands, etc)
  envi_file_query, infid, data_type=data_type, xstart=xstart,$
    ystart=ystart, interleave=interleave, nb=nb, nl=nl, ns=ns
  map_info=envi_get_map_info(fid=infid)
  proj_info=envi_get_projection(fid=infid)

  ;Select input Cloud file
  envi_select, title='Input Quality Filename', fid=clfid, pos=clpos, dims=cldims
  IF (clfid eq -1) THEN RETURN

  ;Select MASK file
  envi_select, title='Mask file', fid=maskfid, pos=maskpos
  IF (maskfid eq -1) THEN RETURN

  ; Get output files and check for an output filename
  outfile1=envi_pickfile(filter='*.img', title='Output file for Interpolated VI!')
  if (outfile1 eq '') THEN RETURN
  openw, unit1, outfile1, /GET_LUN

  outfile2=envi_pickfile(filter='*.img', title='Output file for SG smoothed VI!')
  IF (outfile2 eq '') THEN RETURN
  OPENW, unit2, outfile2, /GET_LUN

  ;Open input files and initialise tiling
  tile_id1 = envi_init_tile(infid, inpos, num_tiles=num_tiles, interleave=1)
  tile_id2 = envi_init_tile(maskfid, maskpos, num_tiles=mask_tiles, interleave=1)
  tile_id3 = envi_init_tile(clfid, clpos, num_tiles=cl_tiles, interleave=1)


  ;Initialise reporting
  rstr=['Applying SavGol Filter:','Output to : '+outfile1]
  envi_report_init, rstr, title="Processing", base=base, /interrupt
  envi_report_inc, base, num_tiles

  ;Main processing loop

  FOR i=0L, num_tiles-1 DO BEGIN
    envi_report_stat,base, i, num_tiles
    data = envi_get_tile(tile_id1, i)
    mask = envi_get_tile(tile_id2, i)
    cloud = envi_get_tile(tile_id3, i)

    datasize=SIZE(data,/dimensions)
    fitting=FLTARR(datasize[0])
    smNDVI=FLTARR(datasize[0], datasize[1])
    iNDVI=FLTARR(datasize[0], datasize[1])
    tmp1=FLTARR(datasize[1])  
    tmp2=FLTARR(datasize[1]) 
    
    FOR j=0, datasize[0]-1 DO BEGIN
      IF mask[j] EQ 1 THEN BEGIN
        tmp_cloud=cloud[j,*]
        tmp_data=data[j,*]
        cgi_interpol_sg,tmp_data, tmp_cloud, iNDVI=tmp1, smNDVI=tmp2
      ENDIF ELSE BEGIN
        tmp1=fltarr(datasize[1]) 
        tmp2=fltarr(datasize[1]) 
      ENDELSE
      iNDVI[j,*]=tmp1
      smNDVI[j,*]=tmp2
   ENDFOR


    WRITEU, unit1, iNDVI
    WRITEU, unit2, smNDVI

  ENDFOR

  envi_report_init, base=base, /finish
  envi_tile_done, tile_id1
  envi_tile_done, tile_id2
  envi_tile_done, tile_id3
  CLOSE, unit1, unit2
  FREE_LUN, unit1, unit2

  envi_setup_head, fname=outfile1, ns=ns, nl=nl, nb=datasize[1], $
    data_type=4, offset=0, interleave=1, $
    xstart=xstart+dims[1], ystart=ystart+dims[3], $
    descrip='SG interpolated VI', /write, /open, $
    map_info=map_info

  envi_setup_head, fname=outfile2, ns=ns, nl=nl, nb=datasize[1], $
    data_type=4, offset=0, interleave=1, $
    xstart=xstart+dims[1], ystart=ystart+dims[3], $
    descrip='SG smoothed VI', /write, /open, $
    map_info=map_info

 END

