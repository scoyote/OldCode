
/* this block will only run at startup befoe you have run proc gdevice 
	due to locking within the session */
libname gdevice0 'C:\Documents and Settings\scrok586';
proc catalog  catalog=gdevice0.devices kill; run; quit;
proc gdevice nofs catalog=gdevice0.devices;
/* include this row to build the device, then comment it out */
   *copy pdfc from=sashelp.devices newname=spark12;
   modify spark12
     description='PDF Sparkline 12pt*144pt'
		xmax=1.52in
		ymax=0.126in
		hsize=0
		vsize=0
		xpixels=576
		ypixels=48
		horigin=0
		vorigin=0
		prows=0
		pcols=0		
		lrows=31
		lcols=60
		;

quit;

/* sample usage */

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
   *copy pdfc from=sashelp.devices newname=spark12;
   modify spark12
     description='PDF Sparkline 12pt*144pt'
	/* base 1.52x0.126  or use a 12 point factor*/
		xmax=3.04in
		ymax=0.126in
		xpixels=1152
		ypixels=48
		;
quit;
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


goptions 
	reset=all ;
symbol1 i=boxf25t c=grey co=black cv=white bwidth=15 ;
axis1 
	offset=(5,20)
	label=none 
	value=none 
	major=none 
	minor=none 
	c=white;
proc gplot data=sashelp.class;
	plot weight*sex / noframe noaxes ;
run;quit;

proc gdevice nofs catalog=gdevice0.devices;
/* include this row to build the device, then comment it out */
   *copy pdfc from=sashelp.devices newname=spark12;
   modify spark12
     description='PDF Sparkline 12pt*144pt'
	/* base 1.52x0.126  or use a 12 point factor*/
		xmax=3.04in
		ymax=0.126in
		xpixels=1152
		ypixels=48
		rotate=landscape
		;
quit;
