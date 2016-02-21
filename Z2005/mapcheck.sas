/* test section */
%let adhocnum=SACU09102607;

libname adhoc "N:\MSAD\CAS\adhoc\NSC\&adhocnum";

data tst;
    set adhoc.&adhocnum(rename=(fips_state=fs fips_county=fc) drop=state county);
    length state county 8;
    state=putc(fs,8.);
    county=putc(fc,8.);
	keep state county count;
run;
proc sort data=tst;
	by state county;
run;

%annomac;
%MACRO makecountymaps(state,anotsize=1);
%put NOTE: Processing &State;
data mapd badd;
		merge maps.uscounty(in=y1 where=(upcase(fipstate(state))="&state"))
			  maps.cntyname(in=y2 where=(upcase(fipstate(state))="&state"))
			  tst(in=y3 where=(upcase(fipstate(state))="&state"));
		by state county;
		if y1 and y2 then do;
			if ~y3 then count=0;
			output mapd;
		end;
		if y3 and ~y2 or y3 and ~y1 then output badd;
	run;

%CENTROID(mapd, annoprep, state county countynm count);
data annot;
	length function  color $8 style $30 ;
	retain flag 0 xsys ysys '2' hsys '3' when 'a' ;
	set annoprep;
	function='label';
	style="'Courier'";
	color='black';
	text=strip(COUNTYNM);
	size=&anotsize;
	position='2';
	output ANNOt;
	text=strip(count);
	position='8';
	output ANNOt;
run;

	
filename outgraph "d:/map_&state..pdf"; 
options orientation=landscape;
goptions  
     reset=all 
     device=pdfc
	 colors=(white bwh palg ywh pkwh lipk )
     xmax=11.01in  horigin=0.001pt  hsize=10.5in   xpixels=10000
     ymax=8.51in   vorigin=0.001pt  vsize=8in   ypixels=7619
     cback=white
     noborder
     gsfname=outgraph
     gsfmode=replace
	 ctext=black;
title "MAP CHECK FOR &state" h=2 c=black;
	proc gmap map=mapd data=mapd anno=annot;
	   id state county;
	  choro count /missing coutline=gray levels=6 ;
	run;
	quit;
%mend;

%makecountymaps(MD,anotsize=.8);
%makecountymaps(FL,anotsize=.7);

%macro runstates;
	%let wherecl=where state='TX';
	proc sql noprint;
		select count(distinct state) into :statecount from adhoc.&adhocnum;
		%let statecount=&statecount;
		select distinct state into :st1-:st&statecount from adhoc.&adhocnum;
		select count(distinct county) into :countycount from mapd where fipstate(state)='TX';
	quit;
	%put countycount=&countycount;
/*	%do state=1 %to &statecount;	*/
/*		%if "&state" ~=  "--" %then %do;*/
/*			*/
/*		%end;*/
/*	%end;*/
%mend;
%runstates;



proc means data=tst nway noprint;
    class fips_state;
    output out=mapstate sum(count)=count;
run;	
goptions reset=global gunit=pct border cback=white
     colors=(bwh blue green yellow orange red magenta)
     ctext=black ftext=swiss htitle=6 htext=3;
title All States;
proc gmap map=map data=mapstate;
   id fips_state;
  choro count / coutline=gray levels=6;
run;
quit;


