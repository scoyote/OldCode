/* issues that have arisen

1) need to remove the axes completely
2) not happy with text

*/


proc sort data=sashelp.class out=class;
by sex; run;
proc boxplot data=class;
	plot weight*sex /outbox=pbox;
	run;
	proc transpose data=pbox out=box;
	 by sex ;
	id _type_;
	var _value_;
run;
data anno;
	set box end=eof;
	xsys='2'; ysys='3'; when='a'; 
	length function color $8 style $20;
	size=1;  style='solid'; line=0;
	/* draw the outer box */ 
	color="grey";
	function='move'; x=min; function='move'; y=ifn(sex='M',20,70); output;
	function='bar';  x=max; y=ifn(sex='M',30,80);  output;
	/* draw the inner box */
	function='move'; x=q1; y= ifn(sex='M',5,55); output;
	function='bar';  x=q3; y=ifn(sex='M',45,95); output;

	/* Median Line (median is &varprefix.M, mean is &varprefix.X) */
	color="white";
	function='move'; x=Median; y=ifn(sex='M',0,50);  output;
	function='bar'; x=Median; y=ifn(sex='M',50,100);  output;

	/* Mean point*/
	color="white";
	function='symbol';size=10;style='MARKER';text="P";position='5'; x=mean; y=ifn(sex='M',25,75);  output;

run;

title;
footnote;

libname gdevice0 'C:\Documents and Settings\scrok586\Desktop\Output';
proc gdevice nofs catalog=gdevice0.devices;
	/* include this row to build the device, then comment it out */
/*	   copy pdfc from=sashelp.devices newname=spcolor2;*/
	   modify spcolor1
	     description='PDF Sparkline 12pt*144pt'
			/* the dimensions are a factor of 30 */
			xmax=3.750in	horigin=0.000	hsize=3.750
			ymax=0.125in	vorigin=0.000	vsize=0.125
			xpixels=3000
			ypixels=100
			prows=0
			pcols=0		
			lrows=31
			lcols=60
			;
	quit;

	proc gdevice nofs catalog=gdevice0.devices;
	/* include this row to build the device, then comment it out */
	   copy pdfC from=sashelp.devices newname=sp16;
	   modify sp16
	     description='PDF Sparkline 12pt*144pt'
			/* the dimensions are a factor of 30 */
			xmax=5in	horigin=0.000	hsize=5in
			ymax=0.125in	vorigin=0.000	vsize=0.125
			xpixels=10000
			ypixels=250
			prows=0
			pcols=0		
			lrows=31
			lcols=60
			;
	quit;
		proc gdevice nofs catalog=gdevice0.devices;
	/* include this row to build the device, then comment it out */
	   copy pdfc from=sashelp.devices newname=spcosq;
	   modify spcosq
	     description='PDF Color 7x7in'
			/* the dimensions are a factor of 30 */
			xmax=7in	horigin=0.000	hsize=7
			ymax=7in	vorigin=0.000	vsize=7
			xpixels=2500
			ypixels=2500
			prows=0
			pcols=0		
			lrows=31
			lcols=60
			;
	quit;
	filename gsasfile "C:\Documents and Settings\scrok586\Desktop\Output\boxspark.pdf"; 

	goptions 			
		reset=all 
		device=spcolor1
		cback=white
		noborder
		gaccess=gsasfile
		gsfmode=replace
		ftext=helvetica;
	proc ganno 
			anno=anno
			name='boxplot'
	          gout=gseg
			datasys;
	run;

	goptions 			
		reset=all 
		device=spcolor1
		cback=white
		noborder
		gaccess=gsasfile
		gsfmode=replace
		ftext=helvetica;
		symbol1 i=j w=5 v=none    c=black;

		axis1 
			label=none 
			value=none 
			major=none 
			minor=none 
			c=white;
		axis2
			label=none
			value=none 
			major=none 
			minor=none 
			c=white;

proc gplot data=sashelp.air gout=work.gseg;
	plot air*date /name='graph'  haxis=axis1 vaxis=axis2;
run;quit;


/* ACF, IACF and PACF Plots */

libname RMWORKL clear;
options comamid=TCP remote=OYS4;
signon 'C:\Program Files\SAS\SAS 9.1\connect\saslink\tcpunix.scr' ;
*establish remote libraries;
RSUBMIT;
   LIBNAME RMWORK "/ty/stcroker/output";
ENDRSUBMIT;
*Connect the remote library to the local machine;
libname RMWORKL  slibref=rmwork 	server=OYS4;

rsubmit;
proc sort data=rmwork.tprsjcga out=ts;
by arrival_date;
run;
proc timeseries data=ts out=tst;
	id staydate interval=day accumulate=total;
	var demand;
run;
proc arima data=tst; 
      identify var=demand nlag=728 outcov=rmwork.outcov; 
      run; quit;
endrsubmit;

%macro plotcorr(var);
	filename gsasfile "C:\Documents and Settings\scrok586\Desktop\Output\spark_&var..pdf"; 
	goptions 			
		reset=all 
		device=sp16
		cback=white
		noborder
		gaccess=gsasfile
		gsfmode=replace
		ftext=helvetica;
		symbol1 i=needle  v=none    c=black;
		axis1 
			label=none 
			value=none 
			major=none 
			minor=none 
			order=(0 to 728 by 28)
			c=white; /* prevent clashing with the axes*/
		axis2 
			label=none 
			value=none 
			major=none 
			minor=none 
			c=white;
	proc gplot data=rmworkl.outcov;
		plot &var*lag /  vref=0 href=364 chref=blue cvref=white haxis=axis1 vaxis=axis2;run;
	run;quit;
%mend;
%plotcorr(corr);
%plotcorr(cov);
%plotcorr(invcorr);
%plotcorr(partcorr);

rsubmit;
libname tpmodel '/tpr/TRANS_MODELING/sasdata';
data rmwork.tprsjcga; 
	set tpmodel.reservations_su_merged2;
	where prop_code='NYCMQ' ;
	total_demand=sum(actual_rooms,additional_demand);
	daysout=sum(arrival_date,-book_date);
	if daysout>90 then daysout=90;
	if daysout<0 then daysout=0;
	keep prop_code  total_demand arrival_date daysout  ;
run;
endrsubmit;
proc sort data=rmworkl.tprsjcga;
	by prop_code arrival_date descending daysout;
run;
proc means data=rmworkl.tprsjcga  noprint nway;
	class prop_code arrival_date ;
 output out=means1	sum(total_demand)=ademand;
run;
proc means data=rmworkl.tprsjcga  noprint nway;
	class prop_code arrival_date daysout;
 output out=means2	sum(total_demand)=dodemand;
run;
data all last;
	merge means1 (in=y1)
		 means2 (in=y2);
	by prop_code arrival_date;
	if y1 ;
	if first.arrival_date then cumsum=ademand;
	else cumsum+(-dodemand);
	if cumsum<.01 then cumsum=0;
	pctrem=cumsum/ademand;
	month=month(arrival_date);
	dow=weekday(arrival_date);	
	output all;
	if last.arrival_date then 	output last;
	
run;
	goptions 			
		reset=all 
		device=spcosq 
		cback=white
		noborder
		gaccess=gsasfile
		gsfmode=replace
		ftext='helvetica';
		axis1 
			order=(0 to 90 by 30 );
		axis2
			order=(1 to 0 by -0.1);

%macro gensym;
	%do i=1 %to 99;
	symbol&i c=blue repeat=99 i=j v=none;
	%end;
%mend; %gensym;
proc sort data=all;
	by prop_code dow arrival_date daysout;
run;

proc gplot data=all;
	by prop_code dow;
	where week(arrival_date)=14;
	plot pctrem*daysout=arrival_date  /haxis=axis1 vaxis=axis2 nolegend; 
run;
quit;

proc g3grid data=all out=default;
   grid daysout*dow=pctrem 
			 ;
run;
proc g3d data=All;
   plot daysout*dow=pctrem /rotate=-65 ctop=red cbottom=black;
run;
quit;
proc gcontour data=all;
   plot daysout*dow=pctrem ;
run;
quit;

/* Fonts fonts and fonts */
proc fontreg msglevel=verbose;
   fontpath 'C:\WINDOWS\Fonts';
run;


proc registry list
startat="core\printing\freetype\fonts";
run;quit;



proc fontreg; fontpath "%sysget(systemroot)\Fonts"; run;

data _null_;
file "c:arialpdf.sasxreg";
input line $80.;
put line;
lines;
[CORE\PRINTING\PDF\FONT FAMILIES]
"Arial"="<ttf> Arial Unicode MS"
[CORE\PRINTING\ALIAS\FONTS\PDF]
"san-serif"="<ttf> Arial Unicode MS"
[CORE\PRINTING\PRINTERS\PDF\ADVANCED]
"FONT FAMILIES"=LINK:"\\CORE\\PRINTING\\PDF\\FONT FAMILIES"
[CORE\PRINTING\PRINTERS\PDF\DEFAULT SETTINGS]
"Font Typeface"="<ttf> Arial Unicode MS"
run;

proc registry import="c:arialpdf.sasxreg"; run;


libname gdevice0 'C:\Documents and Settings\scrok586\Desktop\Output';
proc gdevice nofs catalog=gdevice0.devices;
	/* include this row to build the device, then comment it out */
/*	   copy sasprtc from=sashelp.devices newname=prtc1;*/
	   modify prtc1
	     description='PDF Sparkline 12pt*144pt'
			/* the dimensions are a factor of 30 */
			xmax=7in	horigin=0.000	hsize=7
			ymax=1in	vorigin=0.000	vsize=1
			xpixels=3000
			ypixels=100
			prows=0
			pcols=0		
			lrows=31
			lcols=60
			;
	quit;

filename gfreg "C:\Documents and Settings\scrok586\Desktop\Output\gfreg.pdf"; 

goptions 			
	reset=all 
	device=sasprtc
	cback=white
	noborder
	ftext='Comic Sans MS' 
	gsfmode=replace;
	symbol1 i=j w=5 v=none    c=black;

options printerpath=(pdf gfreg) papersize=legal orientation=landscape ;*PAPERSIZE= (7.05in 1.05in) bottommargin=0 leftmargin=0 rightmargin=0 topmargin=0;



	


proc sql;
	select mean(log(air)), min(date), max(date),max(log(air)), min(log(air)) 
		into :meanlogair,:mindate,:maxdate,:maxlogair,:minlogair from sashelp.air;
quit;
data air;
	set sashelp.air;
	meanlogair=dif(log(air)-&meanlogair);
	if round(log(air),.0001)=round(&minlogair,.0001) then minlogair=meanlogair; 
	if round(log(air),.0001)=round(&maxlogair,.0001) then maxlogair=meanlogair; 
run;
options ps=max ls=max;
proc gdevice nofs catalog=gdevice0.devices;
/* include this row to build the device, then comment it out */
   copy pdfc from=sashelp.devices newname=spark12;
   modify spark12
     description='PDF Sparkline 12pt*144pt'
	/* base 1.52x0.126  or use a 12 point factor*/
		xmax=3.04in
		ymax=0.126in
		xpixels=1152
		ypixels=48
		;
quit;

/* Simplified LaTeX output that uses plain LaTeX tables */
ods tagsets.simplelatex file="c:\output\latex\simple.tex";

proc reg data=sashelp.class;
   model Weight = Height Age;
run;quit;
goptions 
	reset=all 
	gsfmode=replace
	device=spark12  /* here is where we include the device */
	;
axis1 
	label=none 
	value=none 
	major=none 
	minor=none 
	c=white;
symbol3 i=j v=none c=grey w=.25;
symbol1 i=none v=dot h=10 c=red ;
symbol2 i=none v=dot h=10 c=green ;

proc gplot data=air;
	plot ( minlogair maxlogair meanlogair)*date / overlay noframe haxis=axis1 vaxis=axis1;
run;quit;



ods tagsets.simplelatex close;

/* Run each document twice since the longtable package requires it */
x cd output\latex\;
x pdflatex  -output-directory c:\output\latex \output\latex\simple.tex;
x pdflatex  -output-directory c:\output\latex \output\latex\simple.tex;
/*proc gdevice  catalog=gdevice0.devices;run;quit;*/
/*proc catalog catalog=work.gseg kill; run; quit;*/
