; $Id: CGI_PROC_ENVI_GRID, 2004/06/01 wita $
;
;+
; NAME:
;	  CGI_PROC_ENVI_GRID
;
; PURPOSE:
;	  This wrapper grids ASCII data of the type 'LON, LAT, VALUE' into an 
;	  ENVI image file using the 'ENVI_GRID_DOIT' procedure. Note that the
;   ASCII data is read using the 'READ_ASCII' command which assumes that
;   you provide the template from the 'ASCII_TEMPLATE' command.
;
; CATEGORY:
;	  Gridding
;
; CALLING SEQUENCE:
;	  CGI_PROC_ENVI_GRID, Infile, Outfile, Template, Pixelsize
;
; INPUTS:
;	  Infile:	String with the name of the ASCII input file
;   Outfile: String with the name of the ENVI gridded ouput file
;		Template: Template for reading the input file. The template 
;             structure has to have 3 tags: lon, lat, value which contain
;             the arrays with longitude, latitude and data values.
;   Pixelsize: Array of size 2 that defines the X & & size of the gridded
;              data 
;
; OUTPUTS:
;	  No command line output variables. The gridded output is written to
;   a file that is defined by Outfile.
;
;
; MODIFICATION HISTORY:
; 	Written by:	Allard de Wit, July 2004.
;-

PRO cgi_proc_envi_grid, infile, outfile, templ, pixelsize

  r = READ_ASCII(infile, template=templ)

  ;Create output geographic projection
  o_proj = envi_proj_create(/geographic)

  ; Call the envi doit routine
  envi_doit, 'envi_grid_doit', x_pts=r.lon, y_pts=r.lat, $
    z_pts=r.value, out_dt=3, pixel_size=pixel_size, $
    o_proj=o_proj, out_name=out_name, interp=0, r_fid=r_fid

END
