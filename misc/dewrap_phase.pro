COMPILE_OPT IDL2, STRICTARRSUBS
;+
; NAME:
;   dewrap_phase
;
; PURPOSE:
;   Rescaling phase information towards the [-pi,pi] range. Can only be applied to 
;   floating point scalars or arrays. Float inputs will return float, Double inputs 
;   will return doubles.
;
; CATEGORY:
;   mathematical operators
;
; EXAMPLES
;      IDL> d1 = [-15.4, -6.2, -2.7, 2.7, 6.2, 15.4]
;      IDL> print, dewrap_phase(d1)
;           -2.83363    0.0831857     -2.70000      2.70000   -0.0831861      2.83363
;   
; SIDE EFFECTS:
;      None
;
; MODIFICATION HISTORY:
;   Written by:  Allard de Wit, October 2010
;
; LICENSE:
;   This software is licensed under the GPL. 
;   See http://www.gnu.org/licenses/gpl.html
;-
;------------------------------------------------------------------------------

FUNCTION Dewrap_phase, phase

    ; Check for float or double precision
    CASE Size(phase, /TYPE) OF
      4 : pi = !pi
      5 : pi = !dpi
    ELSE: Message, "Phase not a floating point value."
    ENDCASE
    twopi = 2*pi
    ; 1. Remove multiples to get between -2pi, 2pi
    ; 2. Add twopi to get between 0, 4pi
    ; 3. Again remove multiples
    ; 4. scale between -pi,pi by removing 2pi for positions gt pi 
    sphase = phase MOD (twopi)
    sphase += twopi
    sphase = sphase MOD (twopi)
    dwphase = sphase - (sphase GT pi)*twopi
        
    RETURN, dwphase
    
END
