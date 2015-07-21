COMPILE_OPT IDL2

; $Id: CGI_ZONAL_STATS.PRO,v 1.0 2008/05/14 wita $
;
;+
; NAME:
; 	CGI_ZONAL_STATS
;
; PURPOSE:
;	 Calculates the statistics of data over the zones, usually this kind
;    of analyses is used for calculating image statistics (e.g. average
;    NDVI) for certain regions of interest (zones) in the image.
;
; CATEGORY:
;   Zonal statistics
;
; CALLING SEQUENCE:
;	  Result = Cgi_Zonal_Statiscs(zones, data)
;
; INPUTS:
;	  Zones: Array of type integer 
;     Data : Array of any numeric type whose values need to be summarized
;
; OPTIONAL INPUTS:
;  None
;	
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;	Structure of the following type:
;     {zone_id:Lonarr(c), zone_mean:DblArr(c), zone_median:DblArr(c), 
;      zone_stdev:DblArr(c), zone_count:Lonarr(r)}
;   Where c is the number of unique zones
;
; EXAMPLE:
   PRO test_CGI_Zonal_Stats
  	   t = Fix(Dist(1000)/10.)
	   z = t
	   s1 = SysTime(1)
	   print, "Starting stats calculation"
	   r = cgi_zonal_stats(z,t)
	   s2 = SysTime(2)
	   FOR i=0l, n_elements(r.zone_id)-1 DO $
		  print, r.zone_id[i], r.zone_mean[i], r.zone_stdev[i], r.zone_count[i]
	   print, s2-s1, FORMAT='(%"Finished calculating stats in %i Seconds.")'
   END
;
; MODIFICATION HISTORY:
; 	Written by:	Allard de Wit, 14/5/2008
;-


;------------------------------------------------------------------------------
FUNCTION Calc_Stats, zone, data
    c = N_Elements(data)
    IF c GT 1 THEN BEGIN
       mean = (Moment(data, SDEV=sdev, MAXMOMENT=2))[0]
	   median = Median(data)
    ENDIF ELSE BEGIN
	   mean = data
	   median = Median(data)
	   sdev = !VALUES.D_NAN
    ENDELSE
    RETURN, [zone, mean, median, sdev, c]
END

;------------------------------------------------------------------------------
FUNCTION CGI_Zonal_Stats, zones, data

    ; Check for inputs and data type of inputs
    IF N_Elements(zones) EQ 0 OR N_Elements(data) EQ 0 THEN BEGIN
        Print, "Usage: r = cgi_zonal_stats(zones, data)"
		Print, "  zones: Integer array of zones to summarize over."
  	  	Print, "  data: Numeric array of values that should be summarized."
		print, "  r: A structure having tags, zone_id, zone_mean, zone_stdev " + $
		  	   "  zone_count and zone_median."
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

    
	; First create a histogram of the zones in order to use the reverse indices
	; to map out the index locations of the zones
	h = Histogram(zones, OMIN=omin, REVERSE_INDICES=ri)
	
	; Loop over the reverse indices and calculate the statistics for each zone
	t = DblArr(5, N_Elements(h))
	t[*] = !VALUES.D_NAN
    FOR j=0L, N_Elements(h)-1 DO IF ri[j+1] GT ri[j] THEN $
      t[*,j] = Calc_Stats(omin+j, data[ri[ri[j]:ri[j+1]-1]])

	; Filter out the empty bins from the zonal statistics
	index = Where(Finite(t[0,*]) EQ 1, cnt)
	IF cnt LT N_Elements(h) THEN $
  	  zonal_stats = t[*,index] $
	ELSE $
	  zonal_stats = t

    RETURN, {zone_id:Long(Reform(zonal_stats[0,*], /OVERWRITE)), $
	         zone_mean:Reform(zonal_stats[1,*], /OVERWRITE), $
	         zone_median:Reform(zonal_stats[2,*], /OVERWRITE), $
             zone_stdev:Reform(zonal_stats[3,*], /OVERWRITE), $
			 zone_count: Long(Reform(zonal_stats[4,*], /OVERWRITE))}

END
