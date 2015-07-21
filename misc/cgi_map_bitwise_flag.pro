; $Id: cgi_map_bitwise_flag.pro,v 1.0 2008/01/10 $
;
;+
; NAME:
;   CGI_MAP_BITWISE_FLAG  
;
; PURPOSE:
;   Create a 0/1 mask from a certain bitposition in a status map, 
;   such as usually included with satellite data. To be used in
;   ENVI's bandmath module.
;
; CATEGORY:
;   satellite data processing
;
; CALLING SEQUENCE:
;   CGI_MAP_BITWISE_FLAG(statusmap, bitposition)
;
; INPUTS:
;      statusmap: Image with flags in certain bit positions
;      bitposition: the bitnumber that you want to extract
;                   note bits count from left to right so 1000000 = 128
;
; KEYWORD VARIABLES
;   None
;
; SIDE EFFECTS:
;   None
;
; EXAMPLE
;   d = byte(dist(250))
;   tvscl, d
;   r = map_bitwise_flag(d, 3)
;   tvscl, r
;
; MODIFICATION HISTORY:
;   Written by:  Allard de Wit, January 2008
;
; LICENSE:
;   This software is made available under the European Union Public License (EUPL), see LICENSE file
;-
FUNCTION cgi_map_bitwise_flag, statusmap, bitposition
  return, BYTE((statusmap AND (2UL^bitposition))/(2UL^bitposition))
END
