/*options comamid=TCP remote=OYS4;*/
/*signon 'C:\Program Files\SAS\SAS 9.1\connect\saslink\tcpunix.scr' ;*/
/**/

filename gsasfile "c:/output/Croker_airlineminmax.png"; 
goptions  
     reset=all 
     device=png
     xmax=144pt  horigin=0.000pt  hsize=144pt xpixels=10000
     ymax=12pt   vorigin=0.000pt  vsize=12pt  ypixels=833
     cback=white
     noborder
     gaccess=gsasfile
     gsfmode=replace;
     symbol1 v=none i=j c=black width=50;
     axis1 label=none value=none major=none minor=none 
 offset=(0,0)
 style=0; 
     axis2 label=none value=none major=none minor=none
 style=0;
proc sql noprint;
     select min(air)
          , max(air)    
           into 
                 :minair 
               , :maxair
     from sashelp.air;
quit;
data air;
     set sashelp.air;
     if air=&maxair then maxair=air;
     if air=&minair then minair=air;
run;
symbol2 v=dot h=200 c=red i=none;
symbol3 v=dot h=200 c=green i=none;

proc gplot data=air;
     plot (air maxair minair)*date / overlay   haxis=axis1 vaxis=axis2;run;
quit;
