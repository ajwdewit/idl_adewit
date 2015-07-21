FUNCTION Prepare_FFT_output, d
  ; The FFT function in IDL returns a symmetric result. 
  ; This function removes the symmetry and compensates the
  ; loss of symmetry by multiplying each harmonic by 2.
  ;
  ; The Nyquist frequency needs special care because in case
  ; of the length of the variable "harmonics" is even it should be  
  ; multiplied by 2, in case of an odd length if should not.
  
  harmonic0 = DComplex(Abs(d[0]) * Cos(Atan(d[0], /PHASE)), 0.)
  harmonics = d[1:*]
  n = Size(harmonics, /DIM)
  IF (n MOD 2) EQ 0 THEN BEGIN ; even number; symmetrical at ps
      NF = n/2
      harmonics = harmonics[0:NF-1]*2
  ENDIF ELSE BEGIN ; Odd number; Nyquist Frequency (NF) not symmetrical
      NF = (n+1)/2
      harmonics = harmonics[0:NF-1]
      harmonics[0:NF-2] *= 2 
  ENDELSE
  
  RETURN, [harmonic0, harmonics]

END