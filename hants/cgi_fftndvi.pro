;+
; NAME: 
;   CGI_FFTNDVI
;
; PURPOSE: 
;   Apply fourier analyses through NDVI time series
;
; CATEGORY: 
;   1D signal processing
;
; CALLING SEQUENCE: 
;   Result = CGI_FFTNDVI(Data, FET=FET, FREQS=[f0,f1,f2,..], RANGE=[min, max],$
;                     smNDVI=variable, iNDVI=variable, TAT=TAT, STATUS=STATUS, /PLOT)
;
; INPUTS:
;     data : 1D array with NDVI values to fit fourier function through
;
; KEYWORD VARIABLES:
;     FET:    Fit Error Tolerance, is maximum tolerable downward deviation
;             between fourier fit and NDVI data values (in DN values)
;     FREQS:  1D array with frequences that should be selected from the
;             fourier spectrum. i.e. freqs=[0,1,2,3] to use the fourier
;             compoments 0 (mean), 1 (1 sine wave), 2 (2 sine waves) and 3.
;     RANGE:  Array of size 2 to specify the minimum and maximum valid data
;             values. i.e. range=[1,254]
;     PLOT:   Visualise the optimisation process. Only applied for debugging
;             because it is very slow!
;     smNDVI: smNDVI will contain the array of smoothed NDVI values as calculated
;             from the fourier analyses.
;     iNDVI:  iNDVI will contain the array of interpolated NDVI values.
;     STATUS: Status will contain the number of NDVI values that have been used
;             for fitting the fourier analyses (int)
;     TAT:    Throw-Away-Threshold: Maximum nr. of points that may be thrown away by the FFT fitting
;     iMAX:   Maximum nr of iterations to be performed
;
;
; OUTPUTS
;   Result: Contains an array with the values of the specified fourier components
;           as DCOMPLEX values. Other outputs are passed back through variables smNDVI,
;           iNDVI and status.
;
; SIDE EFFECTS:
;   None
;
; EXAMPLE:
;   Data=[0.57989997, 0.0000000, 0.58050001, 0.57650000, 0.0000000, 0.58260000, 0.59230000, 0.56879997, 0.43089998, $
;         0.66119999, 0.74509996, 0.71450001, 0.67490000, 0.81219995, 0.61610001, 0.77689999,0.78009999, 0.70429999, $
;         0.71419996, 0.52649999, 0.57489997, 0.17590000, 0.44669998, 0.57989997]
;
;   Result = CGI_FFTNDVI( Data, FET=0.1, FREQS=[0,1,2], RANGE=[0.01,1.0], $
;     smNDVI=smNDVI, iNDVI=iNDVI, iMAX=10, TAT=5, /plot)
;
;
; MODIFICATION HISTORY:  
;   Written by:  Allard de Wit, Aug 2003
;   Modified by: Allard de Wit, April 2004
;   Modified by: Allard de Wit, May 2005 (Error handler added and additional checks)
;   Modified by: Allard de Wit, May 2005 (Now returns correct FFT coefficients)
;
; LICENSE: 
;   This software is made available under the GPL. See http://www.gnu.org/licenses/gpl.html
;-

FUNCTION cgi_fftndvi, data, fet=fet, freqs=freqs, range=range, plot=plot, $
            smNDVI=smNDVI, iNDVI=iNDVI, status=status, tat=tat, iMAX=iMAX

  ;Define error handler for CGI_FFTNDVI routine
  CATCH, error_status
  IF error_status NE 0 THEN BEGIN
    smNDVI=FLTARR(s)
    iNDVI=FLTARR(s)
    status=[-1,-1,-1]
    datafft[*]= 0.0
    CATCH, /CANCEL
    RETURN, datafft[freqs]
  ENDIF
  
  ;find size of arrays and set some arrays variables
  data=REFORM(data)
  s=N_ELEMENTS(data)
  data=DOUBLE(data)
  data_copy=data
  xseries=INDGEN(s)
  bad_data=BYTARR(s)

  ;Create filter based on specified frequencies
  filter=cgi_make_fft_filter(freqs, s)

  ;Perform forward Fourier transformation
  datafft=FFT(data, -1)

  ;Perform first reconstruction using specified number of frequencies (freqs[])
  data_back=FFT(datafft*filter, 1)

  ;find pixels with values out of range
  index_OOR=WHERE((data LT range[0]) OR (data GT range[1]))
  IF index_OOR[0] NE -1 THEN bad_data[index_OOR]=1B

  ;Search for out-of-range points and overwrite with reconstructed points
  bad_index=WHERE(bad_data eq 1)
  good_index=WHERE(bad_data eq 0)
  if bad_index[0] NE -1 THEN data[bad_index]=data_back[bad_index]

  ;Plot if plot keyword is set
  IF KEYWORD_SET(plot) THEN BEGIN
    WINDOW, 2, retain=2, xsize=600, ysize=400
    WINDOW, 1, /pixmap, xsize=600, ysize=400
    WSET, 1
    PLOT, xseries, data_back, YRANGE=range
    OPLOT, xseries, data_copy, linestyle=1
    IF ((bad_index[0] NE -1) AND (good_index[0] NE -1)) THEN BEGIN
      OPLOT, xseries[bad_index], data_copy[bad_index], PSYM=2
      OPLOT, xseries[good_index], data_copy[good_index], PSYM=4
    ENDIF
    WSET, 2
    DEVICE, copy=[0,0,600,400,0,0,1]
    WAIT, 0.5
  ENDIF

  ;Loop until all points are within FET tolerance or the maximum nr of points that
  ;may be discarded is reached.
  i=0
  REPEAT BEGIN
    ;perform forward FFT
    datafft=FFT(data,-1)

    ;Filter FFT spectrum using specified frequencies and reconstruct series
    data_back=Real_Part(FFT(datafft*filter, 1))

    ;find pixels which deviate more than the FET value
    index_fet=WHERE(data LE (data_back-fet))
    IF index_fet[0] ne -1 THEN bad_data[index_fet]=1B

    ;overwrite corrupted data points with reconstructed points
    bad_index=WHERE(bad_data eq 1)
    good_index=WHERE(bad_data eq 0)
    IF bad_index[0] NE -1 THEN data[bad_index]=data_back[bad_index]

    ;Plot reconstructed series if plot keyword set
    IF KEYWORD_SET(plot) THEN BEGIN
      WSET, 1
      PLOT, xseries, data_back, YRANGE=range
      OPLOT, xseries, data_copy, LINESTYLE=1
      IF ((bad_index[0] NE -1) AND (good_index[0] NE -1)) THEN BEGIN
        oplot, xseries[bad_index], data_copy[bad_index], PSYM=2
        oplot, xseries[good_index], data_copy[good_index], PSYM=4
      ENDIF
      WSET, 2
      DEVICE, copy=[0,0,600,400,0,0,1]
      WAIT, 0.5
    ENDIF
    i=i+1
  ENDREP UNTIL ((index_fet[0] EQ -1) OR (N_ELEMENTS(bad_index) GE tat) OR (i GE iMAX))


;Loop until the profile stabilizes without searching for corrupt data points.
;Update the points that have been marked as 'bad_data' after each inverse
;transform and repeat this until the shift in the data is below 1% of the
;average NDVI value.
  j=0
;Check if there is any good data left
  IF good_index[0] NE -1 THEN BEGIN 
    ;Calculate average NDVI
    tmp=MOMENT(data[good_index])
    avgNDVI=tmp[0]
    REPEAT BEGIN
      ;perform forward FFT
      datafft=FFT(data,-1)

      ;Filter FFT spectrum using specified frequencies and reconstruct series
      data_back=Real_Part(FFT(datafft*filter, 1))

      ;Calculated difference between previous and current loop
      IF bad_index[0] NE -1 THEN $
        diff=TOTAL(ABS(data[bad_index]-data_back[bad_index])) $
      ELSE diff=0.

      ;overwrite corrupted data points detected in previous loop with reconstructed points
      IF bad_index[0] NE -1 THEN data[bad_index]=data_back[bad_index]

      ;Plot reconstructed series if plot keyword set
      IF KEYWORD_SET(plot) THEN BEGIN
        WSET, 1
        PLOT, xseries, data_back, YRANGE=range
        OPLOT, xseries, data_copy, LINESTYLE=1
        IF ((bad_index[0] NE -1) AND (good_index[0] NE -1)) THEN BEGIN
          OPLOT, xseries[bad_index], data_copy[bad_index], PSYM=2
          OPLOT, xseries[good_index], data_copy[good_index], PSYM=4
        ENDIF
        WSET, 2
        DEVICE, copy=[0,0,600,400,0,0,1]
        WAIT, 0.5
      ENDIF
      j=j+1
    ENDREP UNTIL ((diff LT avgNDVI/100.) OR (j GE iMAX))

    ; perform one last forward/backward FFT to update the stabilized profile
    datafft=FFT(data,-1)
    data_back=Real_Part(FFT(datafft*filter, 1))

    ;Assign return values in case everything went fine
    smNDVI=FLOAT(data_back)
    iNDVI=FLOAT(data_copy)
    IF bad_index[0] NE -1 THEN iNDVI[bad_index]=smNDVI[bad_index]
    status=[N_ELEMENTS(good_index),i,j]
  ENDIF ELSE BEGIN 
    ;If no good data is left then generate an error
    MESSAGE, "All NDVI points were discarded by the algorithm: check your input data!"
  ENDELSE  
  
  ;CGI_FFTNDVI returns only half the FFT spectrum therefore multiply return 
  ;FFT coeffients by two in order to have the correct amplitudes. 
  tdatafft = Prepare_FFT_Output(datafft)
  RETURN, tdatafft[freqs]

END
