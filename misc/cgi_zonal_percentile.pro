COMPILE_OPT IDL2

; $Id: CGI_ZONAL_PERCENTILE.PRO,v 1.0 2008/05/14 wita $
;
;+
; NAME:
; 	CGI_ZONAL_PERCENTILE
;
; PURPOSE:
;	 Calculates the given percentile of data over the zones.
;
; CATEGORY:
;   Zonal statistics
;
; CALLING SEQUENCE:
;	  Result = Cgi_Zonal_Percentile(zones, data, percentile, $
;                                   BINSIZE=binsize)
;
; INPUTS:
;	  Zones: Array of type integer 
;     Data : Array of any numeric type, except complex, for which 
;            the value of a given
;            percentile in the distribution needs to determined.
;     Percentile: Percentile to be determined, for example percentile
;                 50 should be the median.
;     
; OPTIONAL INPUTS:
;  None
;	
; KEYWORD PARAMETERS:
;  BINSIZE: specify the binsize to be used in calculating the histogram
;           for determining the percentile. If not specified then 
;           BINSIZE=1 is assumed.
;
; OUTPUTS:
;	Structure of the following type:
;     {zone_id:Lonarr(c), zone_mean:DblArr(c), zone_median:DblArr(c), 
;      zone_stdev:DblArr(c), zone_count:Lonarr(r)}
;   Where c is the number of unique zones
;
; EXAMPLE:
PRO test_CGI_Zonal_percentile
    percentile = 50
    binsize = 1
  	t = [indgen(100), indgen(100)]
	z = [intarr(100), intarr(100)+1]
	s1 = SysTime(1)
	print, "Starting stats calculation"
	r = cgi_zonal_percentile(z,t, percentile, BINSIZE=binsize)
	s2 = SysTime(2)
    Print, "       Zone ID     Percentile     # in zone"
	FOR i=0l, n_elements(r.zone_id)-1 DO $
	   print, r.zone_id[i], r.zone_percentile[i], r.zone_count[i]
	print, s2-s1, FORMAT='(%"Finished calculating zonal percentile in %i Seconds.")'
END
;
; MODIFICATION HISTORY:
; 	Written by:	Allard de Wit, 14/5/2008
;-

;------------------------------------------------------------------------------
FUNCTION Calc_Percentile, zone, data, percentile, binsize
    c = N_Elements(data)
	h = (Total(Histogram(data, BINSIZE=binsize, LOCATIONS=locs), $
	          /CUMULATIVE)/Float(c)) * 100
	i = Where(h GT percentile, cnt)
	IF cnt GT 0 THEN $
	  p = locs[i[0]] $
	ELSE $
	  p = !VALUES.D_NAN

    RETURN, [zone, p, c]
END

;------------------------------------------------------------------------------
FUNCTION CGI_Zonal_Percentile, zones, data, percentile, BINSIZE=binsize

    ; Check for binsize and data type of zones
    IF (N_Elements(zones) EQ 0) OR (N_Elements(data) EQ 0) OR $
	   (N_Elements(percentile) EQ 0) THEN BEGIN
        Print, "Usage: r = cgi_zonal_percentile(zones, data, percentile, binsize)"
        RETURN, -1
    ENDIF
    IF (Size(zones, /TYPE) GE 4) AND (Size(zones, /TYPE) LE 11) THEN BEGIN
        Print, "Zones input should be of integer type!"
        RETURN, -1
    ENDIF
    IF (Size(zones, /TYPE) GE 6) AND (Size(zones, /TYPE) LE 11) THEN BEGIN
        Print, "data input should be of Numeric type (not complex)!"
        RETURN, -1
    ENDIF
    
    IF NOT Keyword_Set(BINSIZE) THEN binsize=1
    
	; First create a histogram of the zones in order to use the reverse indices
	; to map out the index locations of these zones
	h = Histogram(zones, OMIN=omin, REVERSE_INDICES=ri)
	
	; Loop over the reverse indices and append the statistics for each zone
	t = DblArr(3, N_Elements(h))
	t[*] = !VALUES.D_NAN
    FOR j=0L, N_Elements(h)-1 DO IF ri[j+1] GT ri[j] THEN $
      t[*,j] = Calc_Percentile(omin+j, data[ri[ri[j]:ri[j+1]-1]], percentile, $
	                           binsize)

	; Filter out the empty bins from the zonal statistics
	index = Where(Finite(t[0,*]) EQ 1, cnt)
	IF cnt LT N_Elements(h) THEN $
  	  zonal_stats = t[*,index] $
	ELSE $
	  zonal_stats = t

    RETURN, {zone_id:Long(Reform(zonal_stats[0,*], /OVERWRITE)), $
	         zone_percentile:Reform(zonal_stats[1,*], /OVERWRITE), $
			 zone_count: Long(Reform(zonal_stats[2,*], /OVERWRITE))}

END
