; $Id: CGI_INTERPOL_sg.pro,v 1.1 2004/12/13 13:20:52 wita Exp $
;
;+
; NAME: 
;   CGI_INTERPOL_SG
;
; PURPOSE: 
;   Savitsky Golay filtering of NDVI time series
;
; MAJOR TOPICS: 
;   1D signal processing
;
; CALLING SEQUENCE: 
;   CGI_INTERPOL_SG, Data, Cloud, smNDVI=smNDVI, iNDVI=iNDVI, IMAX=IMAX
;
; INPUTS:
;     Data:   Array of length n with input vegetation index values
;     Cloud:  Binary array of length n cloud mask values (1 = cloudy; 0 = cloudfree)
;
; KEYWORD PARAMETERS:
;     smNDVI:   Output Savitsky Golay smoothed NDVI profile
;      iNDVI:   Output interpolated NDVI profile, with clouded points replaced by
;               Savitsky Golay filter estimate
;       iMAX:   Maximum nr of iterations in processing loop
;
; SIDE EFFECTS:
;   None 
;
; EXAMPLE:
;   Data=[0.57989997, 0.0000000, 0.58050001, 0.57650000, 0.0000000, 0.58260000, 0.59230000, 0.56879997, 0.43089998, $
;         0.66119999, 0.74509996, 0.71450001, 0.67490000, 0.81219995, 0.61610001, 0.77689999,0.78009999, 0.70429999, $
;         0.71419996, 0.52649999, 0.57489997, 0.17590000, 0.44669998, 0.57989997]
;   Cloud=[0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
;
;  CGI_INTERPOL_SG, Data, Cloud, smNDVI=smNDVI, iNDVI=iNDVI, iMAX=10
;
;  window, 10
;  plot, Data, xtitle='Time [dekad]', ytitle='NDVI [-]'
;  oplot, smndvi, linestyle=1
;
; MODIFICATION HISTORY:  
;   Written by:  Jin Chen, November 2003
;   Modified by: Allard de Wit, December 2004
;     *Replaced many FORTRANish pieces of code with native IDL (i.e. interpol)
;     *Removed call to SAVGOL() from iterative WHILE loop
;
; CODE IS BASED ON:
;   Jin Chen, Per. Jonsson, Masayuki Tamura, Zhihui Gu, Bunkei Matsushita, Lars Eklundh. 2004.
;   A simple method for reconstructing a high-quality NDVI time-series data set based on 
;   the Savitzky�Golay filter. Remote Sensing of Environment 91: 332�344
;
;-

PRO cgi_interpol_sg, data, cloud, smNDVI=smNDVI, iNDVI=iNDVI, iMax=iMax

  ;find size of arrays and reform array variables
  data  = REFORM(data)
  cloud = REFORM(cloud)
  s = N_ELEMENTS(data)
  i_data = FLOAT(data)

  IF NOT KEYWORD_SET(iMax) THEN imax = 10

  ;Perform first reconstruction of VI by linear interpolation
  ;Interpolating the cloudy data according to cloud flag
  xrange=INDGEN(s)
  index0 = WHERE((cloud EQ 0) OR  (xrange EQ 0) OR  (xrange EQ s-1))
  index1 = WHERE((cloud EQ 1) AND (xrange NE 0) AND (xrange NE s-1))

  IF index1[0] NE -1 THEN BEGIN
     r = INTERPOL(i_data[index0],index0,index1)
     i_data[index1] = r
  ENDIF

  ; The first Savitzky-Golay filtering for long term change trend fitting
  savgolFilter = SAVGOL(6,6,0,4)
  sgfit = CONVOL(i_data,savgolFilter,/EDGE_TRUNCATE)
  plot, i_data, psym=2
  oplot, sgfit, linestyle=1

  ; weight calculation
  dif  = ABS(i_data - sgfit)
  mm   = MAX(dif)
  resu = i_data - sgfit

  weights = FLTARR(s) + 1.
  index = WHERE(resu LE 0)
  IF index[0] NE -1 THEN weights[index] = 1 - (dif[index]/mm)
  gdis = TOTAL(ABS(dif * weights))

  ra4 = FLTARR(s)
  ormax = gdis
  it = 1
  savgolFilter = SAVGOL(3, 3, 0, 4)
  WHILE (gdis LE ormax) AND (it LT imax) DO BEGIN
    ;Substitute underestimated VI values by SG values and loop until
    ;reaching the point where the sum of weigthed differences starts
    ;to increase again.
    ra4 = i_data
    index = WHERE(i_data LT sgfit)
    IF index[0] NE -1 THEN ra4[index] = sgfit[index]

    ; The Savitzky-Golay fitting
    sgfit = CONVOL(ra4, savgolFilter, /EDGE_TRUNCATE)
    resu  = i_data - sgfit
    oplot, sgfit, line=0, color=fsc_color('red')

    ;Calculate the weighted difference
    ormax = gdis
    gdis = TOTAL(ABS(resu*weights))
    print, "gdis: ",gdis,"ormax:", ormax
    it++
  ENDWHILE

  ;Assign return values
  smNDVI=FLOAT(sgfit)
  iNDVI=data
  index = WHERE(cloud EQ 1)
  IF index[0] NE -1 THEN iNDVI[index]=sgfit[index]

END
