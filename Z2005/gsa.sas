/*libname dd 'D:\My Documents\demodata';*/

data gsapd;
	set dd.gsapd;
	oldcounty=county;
	if _n_ = 1 then pattern = prxparse("s/,\sand|\sand|\//,/");
	retain pattern;
	call prxchange(pattern,-1,county);
	c2=count(county,',');

	do i=0 to c2;
		cty=strip(scan(county,i+1,','));
		if ~missing(cty) then output;
	end;
run;

proc sql noprint;
	create table counties as
	select 
		 state
		,cty
		,max(lodging) as lodging
		,max(m_ie) as m_ie
		,max(total) as total
		,max(hourly) as hourly
		from gsapd
		group by 
			 state
			,cty
	;
quit;

proc sort data=counties(rename=(state=statename cty=countynm)); 
	by statename countynm;
run;
proc sort data=sashelp.zipcode out=zips;
	by statename countynm;
run;

data badparse matched;
	merge counties (in=y1)
		  zips (in=y2)
	;
	by statename countynm;
	if y1 and ~y2 then output badparse;
	else if y1 and y2 then output matched;
	else if ~y1 and y2 then do;
		lodging=70;
		m_ie=46;
		total=116;
		hourly=14.5;
		output matched;
	end;
run;
PROC FORMAT;
	value pdrates
		low - 17.999 = -1
		18 - 21.999	= 1
		22 - 24.999	= 2
		25 - 27.999	= 3
		28 -31.999		=4
		32 -high		=5;
run;
		 

proc sql noprint;
	create table countychoro as
	select 
		 state, statename
		,county, countynm
		,max(lodging) as lodging
		,max(m_ie) as m_ie
		,max(total) as total
		,max(hourly) as hourly
		,put(max(hourly),pdrates.) as cola_comp 
		from matched
		group by 
			 state, statename
			,county, countynm
	;
quit;

goptions reset=global gunit=pct border cback=white
         colors=(bwh blue green yellow orange red magenta)
         ctext=black ftext=swiss htitle=6 htext=3;

proc gmap map=maps.uscounty data=countychoro;
   id state county;
   where fipSTATE(state) in ('SC','NC','GA','FL','VA','MD','DE','PA');
  choro hourly / coutline=gray   midpoints = 14 18 22 26 30 34 38;
run;
quit;
proc sql;
	select cola_comp, count(*) from countychoro where fipSTATE(state) in ('SC','NC') group by  cola_comp;
	quit;
