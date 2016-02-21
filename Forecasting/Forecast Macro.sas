/**********************************************************************
*   PRODUCT:   SAS
*   VERSION:   8.2
*   CREATOR:   SAMUEL T. CROKER
*   DATE:      12 January 2006
*   DESC:      Plots a three region forecast typically used for 
*                 1.  1 step ahead
*                 2.  Holdout data or contiguous interventions
*                 3.  Future Predicions
*              Also plots missing data as red circles. 
***********************************************************************/ 
data tsid_control;
	input cutoff datetime. cutofflabel && $ ;
datalines;
11JAN2007:12:00:00 Plot Start
13JAN2007:09:00:00 Data End
14JAN2007:08:00:00 Forecast Start
;
run;

%macro parsetimeblocks(
				 /* positional parameters (required) */
				  ts                   /* dataset containing forecasts */
				 ,ctrl        		   /* control dataset name */
				 ,idvar=date
				 ,graphname=fcplt		/* handy for greplaying */
				 ,regionstyle=MS
				);
	%let actual=y;
	proc sort data=&ctrl out=control; by cutoff; run;
		data control;
		set control;
		cutnum=_n_;
	run;
	%let cutnum0=0;
	 /* rebuild the output data so that the cis plot as polygons */
	proc sql noprint;
		select count(*) into :numcutoffs from control;
		%let numcutoffs=&numcutoffs;
		select  cutnum
	 		  ,cutoff format=28.
			into 
				  :cutnum1-:cutnum&numcutoffs
				 ,:cutoff1-:cutoff&numcutoffs 
			from control;
		select 
			 min(&idvar)format=28.
			,max(&idvar)format=28. 
			into 
				 :cutoff0
				,:cutoff%eval(&numcutoffs+1) 
			from &ts;
	quit;
	data forecast_with_regions;
		set &ts;

		%do cp=0 %to &numcutoffs;
			%let cp1=%eval(&cp+1);
			if &idvar > %cmpres(&&cutoff&cp) and &idvar <= %cmpres(&&cutoff&cp1) then region=&&cutnum&cp;
		%end;
		if region=0 or missing(region) then delete;
	run;
	%let vallist=;
	%do i=0 %to &numcutoffs-1;
	 	%let vallist=&vallist sval&i ;
	%end;
  	data out (drop= &vallist
		)
		%do i=0 %to &numcutoffs;
		 	low&i(keep=region &idvar &vallist)
			high&i(keep=region &idvar &vallist)
		%end;
	;
         set forecast_with_regions;
	    label sval0="FIT Region" 
	    		sval1="HOLDOUT Region"
			sval2="FORECAST Region";
		%do i=0 %to &numcutoffs-1;
			if region=&i and region~=0 then do; 
				sval&i=l95; output low&i; 
				sval&i=u95; output high&i; 
			end;
		%end;
          output out;
      run;
	%do i=0 %to &numcutoffs-1;
		proc sort data=low&i; by descending &idvar; run;
		proc sort data=high&i; by &idvar; run;
	%end;
	data forecast; 
		set 
		%do i=&numcutoffs-1 %to 0 %by -1;
			low&i high&i 
		%end;
		out; 
		if &idvar=. then delete; 
	run;

	data DayLines; set forecast(keep=&idvar );
	     length color function $8 text $25;
	     retain xsys '2' ysys '1' when 'a';
	     if hour(&idvar)=0 and minute(&idvar)=0 then do;
	          wdate=put(datepart(&idvar),worddatx12.);
	          function='move'; x=&idvar; y=0; output;
	          function='draw'; x=&idvar; y=100; color='lib'; size=1; output;
	          function='label'; x=&idvar; y=5; size=1; position='2';angle=90;color='black'; text=wdate; output;
	     end;
	run;


	proc sql noprint;
		select min(y),max(y),min(forecast),max(forecast) into
			:miny,:maxy,:minyf,:maxyf
			from forecast;
		select max(&idvar) into :dataend from forecast;
	quit;
	%let miny=%sysfunc(min(&miny,&minyf));
	%let maxy=%sysfunc(max(&maxy,&maxyf));
	%put miny=&miny;
	%put maxy=&maxy;


	goptions reset=all device=activex transparency  ;

	axis1 
		order=(&cutoff1 to &dataend by dthour)
		    label=("Time Axis")		/* label the x axis */
		    major=(height=2)		/* specify the characteristics of the major ticks */
		    minor=(number=4 height=1)	/* specify the characteristics of the minor ticks */
		    offset=(2,2)			/* put some space at either end of the axis */
		    width=3;			/* specify the weight of the axis line */
	axis2 	order=(&miny to &maxy by %sysevalf((&maxy-&miny)/10))
		    label=("Output CO2" angle=90)
		    major=(height=2)
		    minor=(number=4 height=1)
		    offset=(2,2)
		    width=3;
	legend1 across=1;

	 proc gplot data=forecast annotate=daylines;
		  %do i=1 %to %eval(&numcutoffs);
	            symbol&i i=&regionstyle  c=&&cicol&i    co=libgr;
		  %end;
            symbol%eval(&numcutoffs+1) i=join  v=dot   c=blue  h=.75;
            symbol%eval(&numcutoffs+2) i=join  v=none  c=green;
            %let a=; %let order=;
     	  legend1 down=&numcutoffs;
            plot  
			%do i=1 %to &numcutoffs-1;
				sval&i*&idvar=%eval(&i+1)
			%end; 
                  &actual*&idvar=%eval(&numcutoffs+1)
                  forecast*&idvar=%eval(&numcutoffs+2)
                 / name="&graphname"
				legend=legend1
                   haxis=axis1 
                   vaxis=axis2 
                   overlay ;
         run; quit;
	    title;

%mend;

proc catalog catalog=gseg kill; run;
%let cicol1=bwh; %let cicol2=gwh; %let cicol3=pkwh; %let cicol4=pkwh;
%Parsetimeblocks(fcp,tsid_control,idvar=timeid,graphname=fcplt1,regionstyle=ms);

