FUNCTION cgi_make_fft_filter, freqs, r

  ;Create filter based on specified frequencies.
  ;Output is a binary array of size r with values '1' on locations
  ;of specified frequencies, values '0' everywhere else.
  ;Note that this procedure doesn't do range checking. If you specify
  ;a frequency larger than r/2 (mathematically impossible) it will crash.
  ;
  ;EXAMPLE: result=make_fft_filter([0,1,2], 50)
  ;         This will get you a byte array of size 50 with values '1' on
  ;         the first three and last two positions, values '0' everywhere
  ;         else.
  
  filter=BYTARR(r)
  distf=FIX(DIST(r, 1))
  dummy=N_ELEMENTS(freqs)
  FOR i=0, dummy-1 DO BEGIN    ;loop through specified frequencies
    index=WHERE(distf EQ freqs[i])
    filter[index]=1B
  ENDFOR

  RETURN, filter

END
