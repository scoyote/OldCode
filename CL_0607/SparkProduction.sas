/*******************************************************************************
*       Program Name    :       $RCSfile: SparkProduction.sas,v $
*       REV/REV AUTH    :       $Revision: 1.2 $ $Author: scoyote $
*       REV DATE        :       $Date: 2007/11/11 10:25:04 $
********************************************************************************/
%let goutdir=C:\Documents and Settings\scrok586\Desktop\Output;

/* set up a library for your modified device entry */
libname gdevice0 "&goutdir";
/* modify the color pdf device.  This is nice due to the 
vector graphics... it looks great small */
proc gdevice nofs catalog=gdevice0.devices;
     copy pdfC from=sashelp.devices newname=sp12pt;
     modify sp12pt
     description='PDF Sparkline 12pt*144pt'
          /* 1 in = 72 pt */
          /* the dimensions are a factor of 30 */
          xmax=2in       horigin=0.000  hsize=2in
          ymax=.083in    vorigin=0.000  vsize=.083in
          /* generate BIG so it looks good small. Especially important for fonts */
          xpixels=10000
          ypixels=333
          prows=0
          pcols=0        
          lrows=31
          lcols=60
          ;
quit;
/* prepare some data... */
proc sql;
     select mean(log(air)), min(date), max(date),max(log(air)), min(log(air)) 
          into :meanlogair,:mindate,:maxdate,:maxlogair,:minlogair from sashelp.air;
quit;
/* generate some high and low points for fun... */
data air;
     set sashelp.air;
     meanlogair=dif(log(air)-&meanlogair);
     if round(log(air),.0001)=round(&minlogair,.0001) then minlogair=meanlogair; 
     if round(log(air),.0001)=round(&maxlogair,.0001) then maxlogair=meanlogair; 
run;

   filename gsasfile "&goutdir\spark_air.pdf"; 
          goptions            
               reset=all 
               device=sp12pt
               cback=white
               noborder
               gaccess=gsasfile
               gsfmode=replace;
               symbol1 v=dot  i=none c=red height=40;
               symbol2 v=dot  i=none c=green   height=40; 
               symbol3 v=none i=join c=black width=1;
               axis1 
                    label=none 
                    value=none 
                    major=none 
                    minor=none 
                    offset=(0,0)
                    style=0; 
               axis2 
                    label=none 
                    value=none 
                    major=none 
                    minor=none
                    style=0;
 
proc gplot data=air;
     plot ( minlogair maxlogair meanlogair)*date 
          / overlay noframe haxis=axis1 vaxis=axis1;
run;quit;

