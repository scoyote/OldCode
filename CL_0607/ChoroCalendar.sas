/**********************************************************************
*	Program Name	:	$RCSfile: ChoroCalendar.sas,v $
*	REV/REV AUTH	:	$Revision: 1.2 $ $Author: scoyote $
*	REV DATE		:	$Date: 2007/05/31 20:34:20 $
* 
*   CREATOR:   SAMUEL T. CROKER
*   DATE:      25 May 2007
*   DESC:     Adapted from Robert Allison http://robslink.com/SAS/Home.htm
*	NOTE:	 This code is NOT intended to be run from Enterprise Guide
***********************************************************************/
libname RMWORKL clear;
options comamid=TCP remote=OYS4;
signon 'C:\Program Files\SAS\SAS 9.1\connect\saslink\tcpunix.scr' ;
*establish remote libraries;
RSUBMIT;
   LIBNAME RMWORK "/tpr/stcroker/output";
   libname tpmodel '/tpr/TRANS_MODELING/sasdata';
   libname Nmodel '/tpr/TRANS_MODELING/sasdata_05_06';
ENDRSUBMIT;
*Connect the remote library to the local machine;
libname RMWORKL  slibref=rmwork 	server=OYS4;
libname rmmodel  slibref=tpmodel	server=OYS4;
libname newdata slibref=nmodel	server=OYS4;

%let property=CHADT;
goptions reset=global;
data my_data; set newdata.data_for_modeling;
	where prop_code="&property";
	day=arrival_date;
	dayofyear=0; 
	dayofyear=put(day,julday3.);
 	year=0; 
	year=put(day,year4.);
 	monname=trim(left(put(day,monname.)));
run;

proc sql; 
	/* Macro variable containing minimum year */
	select min(year) into :min_year from my_data; 
	select max(year) into :max_year from my_data; 
	/* Start your annotate label data for each year */
	create table my_anno as select unique year from my_data;
quit; run;

/* My algorithm assumes you have an obs for each day, so create such a grid */
/* (not essential if you have no days with missing data, but go ahead and
   do it to be on the safe side) */
data grid_days;
	format day date7.;
	do day="01jan.&min_year"d to "31dec.&max_year"d by 1;
		weekday=put(day,weekday.);
		downame=trim(left(put(day,downame.)));
		monname=trim(left(put(day,monname.)));
		year=put(day,year.);
		output;
	end;
run;
/* Join your data with the grid-of-days */
proc sql;
	create table my_data as 
		select * 
		from grid_days 
			left join my_data 
		on grid_days.day eq my_data.day;
quit; run;

/* Add some flyover chart tip (could also add href drilldown here */
data my_data; set my_data;
	 length  myhtmlvar $200;
	 myhtmlvar=
	 'title='|| quote( put(day,downame.)||'0D'x||put(day,date.)||'0D'x||'Actual Demand: '||put(Actual_demand,10.0))||' '
	 ;
run;

/* Create a 'map' of the days, suitable for use in gmap */
/* If you had 'real' data, it might not be sorted, so sort it here */
/* (must be sorted to use the 'by' below) */
proc sort data=my_data out=datemap; 
	by year day;
run;
/* You must use 'by year', in order to use first.year */
/* You're starting with minimum date at top/left, max at bottom/right */
data datemap; set datemap;
	 keep day x y;
	 by year;
	 if first.year then x_corner=1;
	 else if trim(left(downame)) eq 'Sunday' then x_corner+1;
	 /* If this factor is 7, there will be no space between years */
	 y_corner=((&min_year-year)*8)-weekday;
	 x=x_corner; y=y_corner; output;
	 x=x+1; output;
	 y=y-1; output;
	 x=x-1; output; 
run;

/* Create darker outline to annotate around each month, since gmap
   can't automatically do a 2-level outline. */
data outline; set datemap;
	length yr_mon $ 15;
	yr_mon=trim(left(put(day,year.)))||'_'||trim(left(put(day,month.)));
	order+1;
run;

/* Sort it, so you can use 'by' in next step */
proc sort data=outline out=outline;
	by yr_mon order;
run;
proc gremove data=outline out=outline;
	by yr_mon; id day;
run;
data outline;
	 length COLOR FUNCTION $ 8;
	 retain first_x first_y;
	 xsys='2'; ysys='2'; size=1.75; when='A'; color='black';
	 set outline; by yr_mon;
	 if first.yr_mon then do;
	  first_x=x; first_y=y;  /* Save these to use at the end, also */
	  FUNCTION = 'Move'; output;
	 end;
	 else do;
	  FUNCTION = 'Draw'; output;
	 end;
	 /* Also, connect the last point to the first point */
	 if last.yr_mon then do;
	  x=first_x; y=first_y; output;
	  end;
run;

data my_anno; set my_anno;
	length text $10;
	function='LABEL';
	position='4';
	xsys='2'; ysys='2'; hsys='3'; when='A';
	x=-6;
	y=((&min_year-year)*8)-1.25;
	style='"arial"';
	size=2;
	text=trim(left(year)); output;
	x=-.1;
	size=1.5;
	text='Sunday'; output;
	y=y-1; text='Monday'; output;
	y=y-1; text='Tuesday'; output;
	y=y-1; text='Wednesday'; output;
	y=y-1; text='Thursday'; output;
	y=y-1; text='Friday'; output;
	y=y-1; text='Saturday'; output;
run;

data month_anno;
	length text $10;
	function='LABEL';
	position='5';
	xsys='2'; ysys='2'; hsys='3'; when='A';
	size=1.5;
	y=1;
	spacing=4.4;
	x=3.5; text='JAN'; output;
	x=x+spacing; text='FEB'; output;
	x=x+spacing; text='MAR'; output;
	x=x+spacing; text='APR'; output;
	x=x+spacing; text='MAY'; output;
	x=x+spacing; text='JUN'; output;
	x=x+spacing; text='JUL'; output;
	x=x+spacing; text='AUG'; output;
	x=x+spacing; text='SEP'; output;
	x=x+spacing; text='OCT'; output;
	x=x+spacing; text='NOV'; output;
	x=x+spacing; text='DEC'; output;
run;

data my_anno; set my_anno month_anno; run;

/* Put a fake map rectangle/area to the top/left of the map, to give room 
   for the annotated labels on the left & top (otherwise, gmap will rescale
   itself to fill all available space, and leave no white-space to the 
   left for the labels).  Note that this 'fake' map area will be drawn
   in the 'coutline' color you specify in the gmap options (you could
   maybe get clever here, and use 2 pattern colors, and have this one
   be the same color as the background, if you really want it to be
   totally 'invisible' (but then you have to figure out how to get it
   to not show up in the legend :) */
data fake;
 day=1;
 color='white';
 x=-10; y=1; output;
 x=x-.001; y=y+.001; output;
 x=x+.002; output;
run;
data datemap; set datemap fake;
run;




goptions reset=all;
filename _webout 'C:\Documents and Settings\scrok586\Desktop\Output\jmpop.htm';

goptions device=javameta;

/**  Create the HTML file that will display the  **/


 /* Use xpixels/ypixels, rather than hsize/vsize, to preserve proportions */
 goptions reset=all gunit=pct htitle=5 htext=2 ftitle="arial/bo" ftext="arial"
   ctitle=black ctext=black;


 /* RGB hex values for color shades gotten from www.colorbrewer.com */

 pattern1 color=cxdfe8df;
 pattern2 color=cx8ccb9d;
 pattern3 color=cx499965;
 pattern4 color=cx357446;
 pattern5 color=cx10472e;
 pattern6 color=black;

legend1 shape=bar(1.5,1.5) frame cshadow=gray label=none;
 title "&Property";

proc gmap data=my_data map=datemap all anno=my_anno ; 
	id day; 
	choro Actual_Demand/ 
		levels=6
		legend=legend1 
		coutline=graycc 
		cempty=graycc 
			anno=outline 
			html=myhtmlvar 
	; 
run;
quit;
