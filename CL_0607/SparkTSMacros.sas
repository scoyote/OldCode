libname gdevice0 'C:\Documents and Settings\scrok586\Desktop\Output';
proc gdevice nofs catalog=gdevice0.devices;
     copy pdfC from=sashelp.devices newname=sp1in;
     modify sp1in
     description='PDF Sparkline 2inX2in'
          /* the dimensions are a factor of 30 */
          xmax=1in  horigin=0.000  hsize=1in
          ymax=1in  vorigin=0.000  vsize=1in
          xpixels=1000
          ypixels=1000
          prows=0
          pcols=0        
          lrows=31
          lcols=60
          ;
quit;
proc gdevice nofs catalog=gdevice0.devices;
     copy pdfC from=sashelp.devices newname=sp3phi;
     modify sp3phi
     description='PDF Sparkline 3xphi'
          /* the dimensions are a factor of 30 */
          xmax=3.0in  horigin=0.000  hsize=3.0in
          ymax=1.85in  vorigin=0.000  vsize=1.85in
          xpixels=1618
          ypixels=1000
          prows=0
          pcols=0        
          lrows=31
          lcols=60
          ;
quit;
proc gdevice nofs catalog=gdevice0.devices;
     copy pdfC from=sashelp.devices newname=sp40;
     modify sp40
     description='PDF Sparkline 12pt*144pt'
          /* the dimensions are a factor of 30 */
          xmax=6in       horigin=0.000  hsize=6in
          ymax=0.15      vorigin=0.000  vsize=0.15in
          xpixels=10000
          ypixels=245
          prows=0
          pcols=0        
          lrows=31
          lcols=60
          ;
quit;

proc gdevice nofs catalog=gdevice0.devices;
     copy pdfC from=sashelp.devices newname=sp16;
     modify sp16
     description='PDF Sparkline 12pt*144pt'
          /* the dimensions are a factor of 30 */
          xmax=6in       horigin=0.000  hsize=6in
          ymax=0.25      vorigin=0.000  vsize=0.25in
          xpixels=10000
          ypixels=416
          prows=0
          pcols=0        
          lrows=31
          lcols=60
          ;
quit;
proc gdevice nofs catalog=gdevice0.devices;
     copy png from=sashelp.devices newname=sp16png;
     modify sp16png
     description='PDF Sparkline 12pt*144pt'
          /* the dimensions are a factor of 30 */
          xmax=6in       horigin=0.000  hsize=6in
          ymax=0.25      vorigin=0.000  vsize=0.25in
          xpixels=10000
          ypixels=416
          prows=0
          pcols=0        
          lrows=31
          lcols=60
          ;
quit;
proc gdevice nofs catalog=gdevice0.devices;
     copy pdf from=sashelp.devices newname=sp16gs;
     modify sp16gs
     description='PDF Sparkline 12pt*144pt'
          /* the dimensions are a factor of 30 */
          xmax=6in       horigin=0.000  hsize=6in
          ymax=0.25      vorigin=0.000  vsize=0.25in
          xpixels=10000
          ypixels=416
          prows=0
          pcols=0        
          lrows=31
          lcols=60
          ;
quit;
proc gdevice nofs catalog=gdevice0.devices;
     copy pdfC from=sashelp.devices newname=spax;
     modify spax
     description='PDF Sparkline 12pt*144pt'
          /* the dimensions are a factor of 30 */
          xmax=6in       horigin=0.000  hsize=6in
          ymax=0.1  vorigin=0.000  vsize=0.1in
          xpixels=10000
          ypixels=166
          prows=0
          pcols=0        
          lrows=31
          lcols=60
          ;
quit;
proc gdevice nofs catalog=gdevice0.devices;
     copy png from=sashelp.devices newname=spaxpng;
     modify spaxpng
     description='PDF Sparkline 12pt*144pt'
          /* the dimensions are a factor of 30 */
          xmax=6in       horigin=0.000  hsize=6in
          ymax=0.1  vorigin=0.000  vsize=0.1in
          xpixels=10000
          ypixels=166
          prows=0
          pcols=0        
          lrows=31
          lcols=60
          ;
quit;
proc gdevice nofs catalog=gdevice0.devices;
     copy pdfC from=sashelp.devices newname=sp17;
     modify sp17
     description='PDF Sparkline 12pt*144pt'
          /* the dimensions are a factor of 30 */
          xmax=6in  horigin=0.000  hsize=6in
          ymax=0.5in     vorigin=0.000  vsize=0.5
          xpixels=10000
          ypixels=833
          prows=0
          pcols=0        
          lrows=31
          lcols=60
          ;
quit;
proc gdevice nofs catalog=gdevice0.devices;
     copy pdfC from=sashelp.devices newname=spBX;
     modify spbx
     description='PDF Sparkline 12pt*144pt'
          /* the dimensions are a factor of 30 */
          xmax=2in  horigin=0.000  hsize=2in
          ymax=0.67in    vorigin=0.000  vsize=0.67
          xpixels=10000
          ypixels=3333
          prows=0
          pcols=0        
          lrows=31
          lcols=60
          ;
quit;

proc gdevice nofs catalog=gdevice0.devices;
     copy pdfC from=sashelp.devices newname=spacf;
     modify spacf
     description='PDF Sparkline 12pt*144pt'
          /* the dimensions are a factor of 30 */
          xmax=2in  horigin=0.000  hsize=2in
          ymax=0.125in   vorigin=0.000  vsize=0.125
          xpixels=10000
          ypixels=625
          prows=0
          pcols=0        
          lrows=31
          lcols=60
          ;
quit;
proc gdevice nofs catalog=gdevice0.devices;
     copy png from=sashelp.devices newname=spacfpng;
     modify spacfpng
     description='PDF Sparkline 12pt*144pt'
          /* the dimensions are a factor of 30 */
          xmax=2in  horigin=0.000  hsize=2in
          ymax=0.125in   vorigin=0.000  vsize=0.125
          xpixels=10000
          ypixels=625
          prows=0
          pcols=0        
          lrows=31
          lcols=60
          ;
quit;

%macro plotspark(dataset,highds,yvar,xvar,interpol=join,device=&extention.,xorderstmt=.,yorderstmt=,wherestmt=,othsf=,hi=N,plot=SERIES,xaxisfmt=,width=1,otherplotparam=,axislabheight=100,extention=pdf);
     %if %upcase(&hi)=Y %then %do;
          proc sql noprint;
               select distinct highlight into :highlt separated by ',' from &highds;
          quit;
               data annotateset;
                    set &dataset;
                    length color function $ 8 text $3;
                    retain  when 'a' xsys '2' ysys '2' hsys '3' size 1 color 'red';
                    if &xvar in (&highlt) then do;
                         function='move';x=&xvar;y=0    ;output;
                         function='draw';x=&xvar;y=&yvar;output;
                    end;
               run;
     %end;
     %else %if %upcase(&hi)=U %then %do;
          data annotateset;
               set &highds;
          run;
     %end;
     proc sql noprint;
          select min(&yvar), max(&yvar) into :miny , :maxy from &dataset;
          %let incr=%sysevalf((&maxy-&miny)/10);
     quit;
     %if %upcase(&plot)=SERIES %then %do;
          filename gsasfile "&outdir\spark_&yvar.&othsf..&extention."; 
          goptions            
               reset=all 
               device=&device
               cback=white
               noborder
               gaccess=gsasfile
               gsfmode=replace;
               symbol1 v=none i=&interpol   c=black width=&width;
               axis1 
                    label=none 
                    value=none 
                    major=none 
                    minor=none 
                    %if &xorderstmt~=. %then %do;
                         order=(&xorderstmt)
                    %end;
                    offset=(0,0)
                    style=0; 
               axis2 
                    label=none 
                    value=none 
                    major=none 
                    minor=none
                    %if "&yorderstmt"~="" %then %do;
                         order=(&yorderstmt)
                    %end;
                    style=0;
          proc gplot data=&dataset %if %upcase(&hi)~=N %then %do;annotate=annotateset %end;;
               &wherestmt;
               plot &yvar*&xvar /   &otherplotparam  haxis=axis1 vaxis=axis2;run;
          quit;
     %end;
     %else %if %upcase(&plot)=FCST %then %do;
          filename gsasfile "&outdir\sparkfcst_&yvar.&othsf..&extention."; 
          goptions            
               reset=all 
               device=&device
               cback=white
               noborder
               gaccess=gsasfile
               gsfmode=replace;
               symbol1 i=join  v=none c=black width=&width;
               symbol2 i=join  v=none c=green width=&width;
               symbol3 i=join  v=none c=blue width=&width;
               axis1 
                    label=none 
                    value=none 
                    major=none 
                    minor=none 
                    %if &xorderstmt~=. %then %do;
                         order=(&xorderstmt)
                    %end;
                    offset=(0,0)
                    style=0
                    c=black; 
               axis2 
                    label=none 
                    value=none 
                    major=none 
                    minor=none
                    %if "&yorderstmt"~="" %then %do;
                         order=(&yorderstmt)
                    %end;
                    style=0;
          data fore;
               set &dataset;
               if &xvar<&asofdate then bpredict=predict;
               else apredict=predict;
          run;
          proc gplot data=fore;
               &wherestmt;
               plot (actual bpredict apredict)*&xvar / overlay  &otherplotparam   haxis=axis1 vaxis=axis2;run;
          quit;

     %end;
     %else %if %upcase(&plot)=BOX %then %do;
          filename gsasfile "&outdir\sparkbox_&yvar.&othsf..&extention."; 

               goptions            
                    reset=all 
                    device=&device
                    cback=white
                    noborder
                    gaccess=gsasfile
                    gsfmode=replace
                    ftext='Helvetica';
                    symbol1 i=box25t  v=dot c=black;
                    axis1 
                         label=none
                         value=none
                         major=none 
                         minor=none 
                         offset=(0,0)
                         order=(&xorderstmt)
                         c=BLUE
                         STYLE=0
                         ; 
                    axis2 
                         label=none 
                         value=(h=4 )
                         order=(0 to %sysevalf(&maxy*1.10) by &maxy)
                         major=none
                         minor=none
                         STYLE=0
                         C=BLack;
                  symbol1 v=DOT c=RED;
             title;
          proc boxplot data=&dataset;
               format month mnthfmt.;
               plot demand*month /
                    boxstyle = schematic
                    cframe   = WHITE
                    cboxes   = dagr
                    cboxfill = WHITE
                    idcolor  = RED
                    nohlabel
                     &otherplotparam 
                    haxis=axis1 vaxis=axis2;
               &wherestmt;
          run;
          quit;
     %end;
     %else %if %upcase(&plot)=AXIS %then %do;
          filename gsasfile "&outdir\spark_&yvar._axis&othsf..&extention."; 
          goptions            
               reset=all 
               device=&device
               cback=white
               noborder
               gaccess=gsasfile
               gsfmode=replace
               ftext='Helvetica';
               symbol1 i=none v=none c=black;
               axis1 
                    label=none 
                    value=    (h=&axislabheight angle=0 rotate=0)
                    minor=none 
                    major=none
                    %if &xorderstmt~=. %then %do;
                         order=(&xorderstmt)
                    %end;
                    offset=(0,0)
                    style=0
                    color=black; 
               axis2 
                    label=none 
                    value=none
                    major=none 
                    minor=none
                    offset=(1,0)
                    style=0;
          proc gplot data=&dataset;
               format &xvar &xaxisfmt..;
               &wherestmt;    
               plot zero*&xvar/   &otherplotparam  haxis=axis1 vaxis=axis2;run;
          quit;
     %end;

%mend;
proc format;
     value mnthfmt
          1='JAN' 2='FEB' 3='MAR' 4='APR' 5='MAY' 6='JUN' 7='JUL' 8='AUG' 9='SEP' 10='OCT' 11='NOV' 12='DEC';
run;quit;
