# Process manager

The process manager is a tool for parallel processing of indepent tasks.
It is particularly useful for independent tasks that have no benefit
from the internal multi-threading of IDL.

## main routines and function

The process manager consists of three main routines:
- cgi_process_manager which handles the details of starting bridges,
  sending tasks to bridges and cleaning up when everything is done. 
- cgi_task_manager which handles the available tasks.
- cgi_process_client which is the code that is executed on the IDL_IDLBridge
  itself. This will need to be adapted in order to execute your own processes
  on the IDL_IDLBridge.

## How the process manager works

The main process manager routine needs to be provided with a list of
tasks. This consist of an array of structure where each task is 
represented by structure and the variables identified by the structure 
tags provide the information needed to run the task. 

A general limitation of the IDL_IDLBridge is that only simple variables can be
transferred from the main process to an 
IDL_IDLBridge (only scalars and arrays of numeric and string type). Moreover,
transferring large amounts of data to the bridge can be highly inefficient.
Therefore, the general approach is to define the task in such a way that 
the process running on the IDL_IDLBridge can figure out where to find the data
it needs to proces rather then to transfer data directly to the IDL_IDLBridge.

However, since a task is represented by a structure, we cannot directly 
transfer this structure to the bridge because the `SetVar` method does
not support structures. To get around this limitation, a solution was found
by first writing the structure to a .SAV file. This .SAV file is then 
restored by the client on the IDL_IDLBridge and based on the information
in the structure it will start its proces.

The process manager contains an example in the header of the 
cgi_process_manager.pro file. This will define 25 tasks with only 1
parameter (`var1`). When these tasks are sent to the client on the bridge
it will run the routine 'run_process_example' with `var1` and the task ID
as input. This example will only run a FOR loop counting upwards and it
displays a progress bar showing the progress (the PROGRESSBAR utility
from David Fannings library). 
Note that several progress bars will be stacked upon eachother depending
on how many CPUs you have.  

the cgi_process_client will need to be adapted in order to run
you own processes. 
