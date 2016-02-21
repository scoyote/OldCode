goptions reset=global;
title;
data my_data; set edistobasin_part;
	length htmlvar $200;
	dayofday=1; 
	hour=hour(datetime);
	day=datepart(datetime);
	dayofday=put(datepart(datetime),julday3.); 
run;
proc sql; 
/* Macro variable containing minimum year */
	select min(day) format=28.6 into :minday from my_data; 
	select max(day) format=28.6 into :maxdatetime from my_data; 
	/* Start your annotate label data for each year */
	create table my_anno as select unique day from my_data;
quit; 

/* My algorithm assumes you have an obs for each day, so create such a grid */
/* (not essential if you have no days with missing data, but go ahead and
   do it to be on the safe side) */
data grid_days;
	do day=&minday to &maxdatetime by 3600;
		dayday=put(datepart(day),dayday.);
		downame=trim(left(put(datepart(day),downame.)));
		monname=trim(left(put(datepart(day),monname.)));
		output;
	end;
run;
/* Join your data with the grid-of-days */
proc sql;
	create table my_data as select * 
	from grid_days left join my_data 
	on grid_days.day eq my_data.day;
quit; run;

/* Add some flyover chart tip (could also add href drilldown here */
data my_data; set my_data;
 length  myhtmlvar $200;
 myhtmlvar=
 'title='|| quote( put(day,downame.)||'0D'x||put(day,date.)||'0D'x||'Severity: '||put(severity,comma5.1))||' '
 ;
run;

/* Create a 'map' of the days, suitable for use in gmap */
/* If you had 'real' data, it might not be sorted, so sort it here */
/* (must be sorted to use the 'by' below) */
proc sort data=my_data out=datemap; 
by day;
run;
/* You must use 'by year', in order to use first.year */
/* You're starting with minimum date at top/left, max at bottom/right */
data datemap; set datemap;
 keep day x y;
 by day;
 if first.day then x_corner=1;
 else if trim(left(downame)) eq 'Sunday' then x_corner+1;
 /* If this factor is 7, there will be no space between years */
 y_corner=((&min_day-day)*24)-day;
 x=x_corner; y=y_corner; output;
 x=x+1; output;
 y=y-1; output;
 x=x-1; output; 
run;

/* Create darker outline to annotate around each month, since gmap
   can't automatically do a 2-level outline. */
data outline; set datemap;
*length wk_mn_day $ 15;
*wk_mn_day=trim(left(put(day,day.)))||'_'||trim(left(put(day,month.)))'_'||trim(left(put(day,month.)));
order+1;
run;
/* Sort it, so you can use 'by' in next step */
proc sort data=outline out=outline;
by order;
run;
proc gremove data=outline out=outline;
  id day;
  by day;
run;
data outline;
 length COLOR FUNCTION $ 8;
 retain first_x first_y;
 xsys='2'; ysys='2'; size=1.75; when='A'; color='black';
 set outline; by day;
 if first.day then do;
  first_x=x; first_y=y;  /* Save these to use at the end, also */
  FUNCTION = 'Move'; output;
 end;
 else do;
  FUNCTION = 'Draw'; output;
 end;
 /* Also, connect the last point to the first point */
 if last.day then do;
  x=first_x; y=first_y; output;
  end;
run;


data my_anno; set my_anno;
length text $10;
function='LABEL';
position='4';
xsys='2'; ysys='2'; hsys='3'; when='A';
x=-6;
y=((&min_day-day)*8)-1.25;
style='"arial"';
size=2;
text=trim(left(day)); output;
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

 
 /* Use xpixels/ypixels, rather than hsize/vsize, to preserve proportions */
 goptions xpixels=700 ypixels=830;

 goptions gunit=pct htitle=5 htext=2 ftitle="arial/bo" ftext="arial"
   ctitle=black ctext=black;

 /* RGB hex values for color shades gotten from www.colorbrewer.com */
 pattern1 value=solid color=cxfed976; /* lightest */
 pattern2 value=solid color=cxfd8d3c;
 pattern3 value=solid color=cxf03b20;
 pattern4 value=solid color=cxbd0026; /* darkest */

 legend1 shape=bar(1.5,1.5) frame cshadow=gray label=none;


/*********************************************************************
  Step 1 ************************************************************
  First, submit this program as-is, to see the empty calendar grid.
 *********************************************************************/
 title "Custom gmap calendar grid";
 proc gmap data=datemap map=datemap all; 
  id day; 
  choro day / 
    levels=1   
    nolegend
    coutline=black 
    cempty=black 
    ; 
 run;

/*********************************************************************
  Step 2 *************************************************************
  Uncomment the following, to add the data/colors to the calendar.
 *********************************************************************/
/*
 title "With data/colors on the grid";
 proc gmap data=my_data map=datemap all; 
  id day; 
  choro severity / 
    levels=4   
    legend=legend1 
    coutline=black 
    cempty=black 
    ; 
 run;
*/


/*********************************************************************
  Step 3 *************************************************************
  Uncomment the following, to add the annotated labels to the calendar.
 *********************************************************************/
/*
 title "With annotated year, month, and day labels";
 proc gmap data=my_data map=datemap all anno=my_anno; 
  id day; 
  choro severity / 
    levels=4   
    legend=legend1 
    coutline=black 
    cempty=black 
    html=myhtmlvar 
    ; 
 run;
*/

/*********************************************************************
  Step 4 *************************************************************
  Uncomment the following, to add dark outlines around months.
 *********************************************************************/
/*
 title "Robert's Allergy History";
 proc gmap data=my_data map=datemap all anno=my_anno; 
  id day; 
  choro severity / 
    levels=4   
    legend=legend1 
    coutline=graycc 
    cempty=graycc 
    anno=outline 
    html=myhtmlvar 
    ; 
 run;
*/
/*********************************************************************
  Step 5 *************************************************************
  Edit the "data" at the top of the program, and change some values,
  and add some observations for special dates you will recognize
  (such as your birthday, anniversary, etc).  Also, if you want, 
  change the colors in the pattern statements.  Then submit the code 
  again -- this will demonstrate how easy it is to re-use this 
  code with different data :)
 ********************************************
