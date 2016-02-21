PROC IMPORT OUT= WORK.Hurricanes 
            DATAFILE= "C:\Documents and Settings\scrok586\My Documents\ADMINSamC\hurricanes.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
%let monthabb=('JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC');

data hurricanes;
	set hurricanes;
	a=scan(dates,1,'- ');
	b=scan(dates,2,'- ');
	c=scan(dates,3,'- ');
	d=scan(dates,4,'- ');
	if b in &monthabb then do;
		startdate=input(compress(a||b||storm_year),date9.);
		enddate=input(compress(c||d||storm_year),date9.);
	end;
	else do;
		startdate=input(compress(a||c||storm_year),date9.);
		enddate=input(compress(b||c||storm_year),date9.);
	end;
	storm_month=month(startdate);
	storm_day=day(startdate);
	drop a--d;
	format startdate enddate mmddyy10.;
	label startdate='Storm Start Date';
	label enddate='Storm End Date';

	/* data clean */
	if pressure < 700 then pressure=.;
run;
%let chekdate=%sysfunc(date());

%let chekmonth=%sysfunc(month(&chekdate)) ;
%let chekday=%sysfunc(day(&chekdate) );
proc sql noprint;
	create table weightcat as
		select storm_year
			, count(*) as catcount
			, category
			from hurricanes
			group by storm_year,category
			order by storm_year,category;
quit;
data weightscale;
	set weightcat;
	by storm_year category;
	if missing(category) then category=0;
	if first.storm_year then do;
		eavg=0;
		sumstorm=0;
	end;
	eweight=catcount*exp(category);
	eavg+eweight;
	sumstorm+catcount;
	if last.storm_year then do;
		eavg=log(eavg/sumstorm);
		output;
	end;
	keep storm_year eavg;
	label eavg='Exp Wgt Avg';
run;

proc means data=hurricanes noprint;
	class storm_year;
	
	output out=medcat median(category)=medcat max(category)=maxcat;
run;

proc sql;
	create table monthstorms as
	select 	 storm_year label="Year"
	 		,storm_month label="Month"
			,count(*) as m_numstorms label="Number of Storms(year)"
			,avg(wind) as m_avgwind label="Mean Wind(year)" format=8.2
			,std(wind) as m_stdwind label="STD Wind(year)" format=8.2
			,avg(pressure) as m_avgpressure label="Mean Pressure(year)" format=8.2
			,std(pressure) as m_stdpressure label="STD Pressure(year)"  format=8.2
		from hurricanes 
		group by storm_year, storm_month
		order by storm_year, storm_month;
	create table yearstorms as
	select 	 storm_year label="Year"
			,count(*) as y_numstorms label="Number of Storms(year)"
			,avg(wind) as y_avgwind label="Mean Wind(year)" format=8.2
			,std(wind) as y_stdwind label="STD Wind(year)" format=8.2
			,avg(pressure) as y_avgpressure label="Mean Pressure(year)" format=8.2
			,std(pressure) as y_stdpressure label="STD Pressure(year)"  format=8.2
		from hurricanes 
		group by storm_year;
	create table TODATE as
	select 	 storm_year  label="Year"
			,count(*) as td_numstorms label="Number of Storms(to date)"
			,avg(wind) as td_avgwind label="Mean Wind(to date)" format=8.2
			,std(wind) as td_stdwind label="STD Wind(to date)" format=8.2
			,avg(pressure) as td_avgpressure label="Mean Pressure(to date)" format=8.2
			,std(pressure) as td_stdpressure label="STD Pressure(to date)"  format=8.2
		from hurricanes 
		where storm_month<=&chekmonth and storm_day<=&chekday 
		group by storm_year;
	create table full_to_date as
		select * from 
			todate a left join yearstorms b on a.storm_year=b.storm_year left join weightscale c on a.storm_year=c.storm_year;
quit;

title Storms as of %cmpres(&chekmonth/&chekday);
proc print data=full_to_date;
run;

goptions reset=all;
symbol1 c=black 	i=j 	v=dot h=.5 ;
symbol2 c=green 	i=j 	v=dot h=.5 ;
symbol3 c=blue 	i=j 	v=dot h=.5 ;
symbol4 c=purple 	i=j 	v=dot h=.5 ;
symbol5 c=cyan  	i=j 	v=dot h=.5 ;
symbol6 c=red  	i=j 	v=dot h=.5 ;
symbol7 c=black 	i=j 	v=diamond h=.5 l=3;
symbol8 c=green 	i=j 	v=diamond h=.5 l=3;
symbol9 c=blue 	i=j 	v=diamond h=.5 l=3;
symbol10 c=purple 	i=j 	v=diamond h=.5 l=3;
symbol11 c=cyan  	i=j 	v=diamond h=.5 l=3;
symbol12 c=red  	i=j 	v=diamond h=.5 l=3;

proc gplot data=monthstorms;
	where storm_year>2000;
	plot  m_numstorms*storm_month=storm_year /overlay;
	plot2 m_avgwind*storm_month=storm_year /overlay;
run;

proc gplot data=yearstorms;
	plot numstorms*storm_year / legend ;
	plot2 avgwind*storm_year/legend ;
	where month(startdate)<=&chekmonth and day(startdate)<=&chekday ;
run;
quit;
title;

symbol1 color=blue 	i=j 	v=dot h=.5 l=3;
symbol2 color=green	i=j 	v=dot h=.5 l=3;


proc gplot data=hurricanes;
	plot pressure*storm_month=storm_year / legend ;
	where storm_year >=1996;
run;
quit;
title;
