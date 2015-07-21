# idl_adewit

My repository of IDL and ENVI scripts and programs.
It contains the following content:

## Harmonical Analysis of NDVI Time-series

This is an IDL implementation of the HANTS algorithm. Note that this version
of HANTS has some limitations particularly because it is limited to 
observations that are regularly sampled in time. The good thing is that it
is much faster than the true HANTS algorithm because it can use the Fast 
Fourier Transform.

See the documentation for more details

## Logger

This is an implementation of a logging framework for use in IDL. Currently 
(e.g. IDL 8.4) IDL has no decent tools for logging instead of the hopelessly 
inadequate 'Journal' program. This provides some classes for setting up logging,
inspired on the logging package in python. First a logger must be created and in
a second step log handlers must be added to the logger. Currently log handlers are
available for logging to a console, to a file and to a textwidget. The logging 
framework supports five log levels (debug, info, warning, error and critical) and
each handler can be instructed to handle message above a certain log level (e.g.
info message and up to a file, warning message and up to the console.

For setting up the logging easily, see the cgi_simple_Logger function which
returns a logger object sending message to the file and the console.

## Misc

Some general image processing utilities including a generic tiling loop for 
ENVI and some zonal statistics.

## Process manager

A manager for executing `independent` parallel processes. The module uses
the IDL_IDLBridge to start parallel processes using as many CPUs as 
available on the host machine. See the documentation in the program folder
for more details.

## sagof

This is an implementation of the Savitsky-Golay filter for processing
time-series of satellite data. It uses ENVI for tiling over the stack
of satellite images. This implementation is very close to the original
implementation by Chen et al (2004) but it has some drawbacks that it
does not do iterative filtering like HANTS does (could be added 
easily though).

for more information see:
   Jin Chen, Per. Jonsson, Masayuki Tamura, Zhihui Gu, Bunkei Matsushita, Lars Eklundh. 2004.
   A simple method for reconstructing a high-quality NDVI time-series data set based on 
   the Savitzky–Golay filter. Remote Sensing of Environment 91: 332–344

## type_checking

This is a small (and incomplete) library for type_checking of IDL variables because
I got fed up with riddling my code with unreadable lines like:

	IF NOT Size(myvar, /TYPE) EQ 4 THEN $
	   Message, "Float input expected!"
	   
Instead the type_checking module allows you to write:

    IF NOT IsTypeFloat(myvar) THEN $
       Message, "Float input expected!"
 
   
   