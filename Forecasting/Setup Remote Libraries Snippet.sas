/**********************************************************************
 *   PRODUCT:   SAS
 *   VERSION:   8.2
 *   CREATOR:   SAMUEL T. CROKER
 *   DATE:      07DEC05
 *   DESC:      
 ***********************************************************************/
** START PROCESSING ON THE SERVER SIDE **;

libname RMDB2L  clear;
libname RMWORKL clear;
options comamid=TCP remote=A70AMIP2;
signon 'C:\Program Files\SAS Institute\SAS\V8\connect\saslink\tcpunix.scr' ;
*establish remote libraries;
RSUBMIT;
   LIBNAME RMDB2 DB2 DATABASE=MSAD USER=&USERNAME PASSWORD=&PASSWORD SCHEMA=ADHOC;
   LIBNAME RMWORK "//saswork/rx16n/RM";
ENDRSUBMIT;
*Connect the remote library to the local machine;
libname RMDB2L  slibref=RMDB2  server=A70AMIP2;
libname RMWORKL slibref=RMWORK server=A70AMIP2;
