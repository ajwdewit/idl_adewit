; $Id: CGI_UNIQUE_ZONES.PRO,v 1.5 2005/01/14 00:25:29 wita Exp $
;
;+
; NAME:
; 	CGI_UNIQUE_ZONES
;
; PURPOSE:
;	 Create a copy of the input image filled with uniquely numbered square 
;  blocks of size xaggr/yaggr. The first value in the image is value '1', 
;  value zero is reserved for nodata. This type of image is often useful
;  in combination with the HIST_2D function for zonal statistics.
;
; CATEGORY:
;   Image processing
;
; CALLING SEQUENCE:
;	  Result = CGI_UNIQUE_ZONES(Image, Xaggr, Yaggr)
;
; INPUTS:
;	  Image:	Image of size NxM, Note that nothing is done with it except
;	  	      that the size of the output image is derived from it.
;   Xaggr:  Aggregation factor in X direction, This should be a positive 
;           integer value
;   Yaggr:  Aggregation factor in Y direction, This should be a positive 
;           integer value
;
; OPTIONAL INPUTS:
;  None
;	
; KEYWORD PARAMETERS:
;  None
;
; OUTPUTS:
;	 Image of size NxM of type Long Integer with uniquely numbered blocks
;  of size xaggr, yaggr
;
; EXAMPLE:
;	  image =  dist(400,400)
;   r = unique_zones(image, 25, 25)
;   tvscl, image
;   tvscl, r
;
;
; MODIFICATION HISTORY:
; 	Written by:	Allard de Wit, 7/5/2004
;-

FUNCTION cgi_unique_zones, image, xaggr, yaggr

  dummy = SIZE(image, /dimensions)
  xsize = dummy[0]
  ysize = dummy[1]
  
  ;create image increasing in y direction
  tmp = LINDGEN(1,ysize)
  final_ydir = REBIN(tmp,xsize,ysize)

  ;create image increasing in x direction
  tmp = LINDGEN(xsize,1)
  final_xdir = REBIN(tmp,xsize,ysize)

  floorx = LONG(FLOOR(FLOAT(final_xdir)/xaggr))
  floory = LONG(FLOOR(FLOAT(final_ydir)/yaggr))

  max_x = MAX(floorx)
  floory = floory*(max_x+1)
  unique_zones = floorx+floory+1

  RETURN, unique_zones

END
