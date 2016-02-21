/**********************************************************************
*	Program Name	:	$RCSfile: threeregionforecast.sas,v $
*	REV/REV AUTH	:	$Revision: 1.2 $ $Author: scoyote $
*	REV DATE		:	$Date: 2007/03/05 21:27:31 $
***********************************************************************/ 

%macro threeregionforecast(
	/* positional parameters (required) */
	 ds                   /* dataset containing forecasts */
	,dataend              /* ending date of the time series - not the forecast series */
	,datastart            /* starting date of the time series */
	,plotback             /* how many date values to go back from the end of the series in the plot */
	,predictlag           /* how many date values to predict ahead */
	/* optional parameters */
	,order=               	/* date axis ordering (should be order=(<<data>>) )*/
	,lciname=L95          	/* variable name of the lower confidence bound */
	,uciname=U95          	/* variable name of the upper confidence bound */
	,rsname=residual      	/* variable name of the residual values */
	,fcname=forecast      	/* variable name of the forecast values */
	,varname=actual       	/* variable name of the actual values */
	,varlab=			  	/* label for the actual values */
	,fclab=			   	/* label for the predict values */
	,dtm=date             	/* variable name of the date axis variable */
	,dtdisplay=datetime28.	/* default format for the datetime axis */
	,dtformat=mmddyy8.    	/* format for time axis values */
	,gname=FCST           	/* name for the SAS graph output */
	,gcat=work.GSEG       	/* ouptut catalog */
	,gdesc=Forecast Plot  	/* description and title of the graph */
	,fontname=SWISS       	/* fonts */
	,htitle=1             	/* title height */
	,cback=white          	/* background color */
	,grtitle=		   		/* main title of the graph */
	,vaxisvalh=1          	/* vertical axis value height */
	,haxisvalh=1          	/* horizontal axis value height */
	,xinterval=hour.	   	/* order interval for the x axis */
	,xminorticks=none
	,ymajnum=10		   	/* number of y tick marks */
	,hatitle=		   		/* horizontal axis title */
	,vatitle=		   		/* vertical axis title */
	,cicol1=bwh           	/* first confidence region color */
	,cicol2=gwh           	/* second confidence region color */
	,cicol3=pkwh          	/* third confidence region color */
	/* the following apply to actual symbol values */        
	,actcol=vigb          	/* color */
	,acth=1               	/* height */
	,actw=1               	/* width */
	,actv=dot             	/* value type */
	,actl=1               	/* line type */
	,acti=none            	/* interpolation type */
	/* the following apply to forecast symbol values */        
	,fcstcol=degb         	/* color */
	,fcsth=1              	/* height */
	,fcstw=1            	/* width */
	,fcstl=1              	/* line type */
	,fcstv=none           	/* value type */
	,fcsti=j              	/* interpolation type */
	);	
	data _null_;
		format forecaststart forecastend 20.;
		forecaststart=intnx('dthour',&dataend,-&plotback);
		forecastend=intnx('dthour',forecaststart,&predictlag);
		plotstart=intnx('dthour',forecaststart,-&plotback); 
		call symput ('forecaststart',forecaststart);
		call symput ('forecastend',forecastend);
		call symput ('plotstart',plotstart);
	run;
	/* rebuild the output data so that the cis plot as polygons */
	data out(  drop=     sval0 sval1 sval2)
			low0( keep=&dtm sval0 sval1 sval2)
			high0(keep=&dtm sval0 sval1 sval2)
			low1( keep=&dtm sval0 sval1 sval2)
			high1(keep=&dtm sval0 sval1 sval2)
			low2( keep=&dtm sval0 sval1 sval2)
			high2(keep=&dtm sval0 sval1 sval2);
		set &ds;
		where &dtm>=&plotstart;
		output out;
		if &dtm <= &forecaststart then do;
			sval0=&lciname; output low0; 
			sval0=&uciname; output high0;
		end;
		if &dtm > &forecaststart and &dtm <= &dataend then do; 
			sval1=&lciname; output low1; 
			sval1=&uciname; output high1; 
		end;
		if &dtm > &dataend then do; 
			sval2=&lciname; output low2; 
			sval2=&uciname; output high2;
		end;
	run;
	/* sort the lower bound datasets so that the polygons will be drawn correctly */
	proc sort data=low0; by descending &dtm; run;
	proc sort data=low1; by descending &dtm; run;
	proc sort data=low2; by descending &dtm; run;

	/* stack the low and high datasets in this way so that the graphs will be drawn correctly */
	data forecast; 
		set  
			low2 high2 
			low1 high1 
			low0 high0 
			out; 
		if &dtm=. then delete; 
	run;

	/* generate vertical lines to denote the date, and highlight the start of the different regions */
	data DayLines; set forecast(keep=&dtm );
		length color function $8 text $25;
		retain xsys '2' ysys '1' when 'a';
		if hour(&dtm)=0 and minute(&dtm)=0 and &dtm>=intnx('dthour',&plotstart,-1) then do;
			wdate=put(datepart(&dtm),worddatx12.);
			function='move'; x=&dtm; y=0; 
				output;
			function='draw'; x=&dtm; 
				y=100; color='lib'; size=1; output;
			function='label';x=&dtm; 
				y=5; size=1; position='2';	
				angle=90;color='black'; text=wdate; output;
		end;
		if &dtm=intnx('dthour',&forecaststart,1) 
			or &dtm=intnx('dthour',&dataend,1) then do;
			function='move';x=&dtm; y=0; output;
			function='draw';x=&dtm; y=100; color='pink'; size=1; output;
		end;
	run;


/* draw the graph */
	goptions reset=all
			device=activex 
			xpixels=800 
			ypixels=600 
			ftext="&fontname" 
			htitle=&htitle 
			cback=&cback  ;
	title &grtitle;
	symbol1 i=ms                                    c=&cicol1  co=libgr;
	symbol2 i=ms                                    c=&cicol2  co=libgr;
	symbol3 i=ms                                    c=&cicol3  co=libgr;
	symbol4 i=&acti  v=&actv    l=&actl  h=&acth    w=&actw    c=&actcol;
	symbol5 i=&fcsti v=&fcstv   l=&fcstl h=&fcsth   w=&fcstw   c=&fcstcol;
	legend1 across=3;
	title &grtitle;
	axis1 label=(&hatitle ) 
		value=(f="&fontname" h=&haxisvalh angle=90 rotate=0)  
		minor=(number=&xminorticks) 
		order=(&plotstart to &forecastend by &xinterval);
	axis2 label=(&vatitle angle=90 rotate=0) 
		value=(h=&vaxisvalh) 
		major=(number=&ymajnum);
	proc gplot data=forecast gout=work.gseg annotate=daylines;
		label sval0='Fit Region';
		label sval1='Holdout Region';
		label sval2='Forecast Region';
		label &varname=&varlab;
		label &fcname=&fclab;
		plot  sval0*&dtm=1 
		sval1*&dtm=2 
		sval2*&dtm=3 
		&varname*&dtm=4 
		&fcname*&dtm=5 
			/ 	name="&gname" des="&gdesc "
				grid
				haxis=axis1 
				vaxis=axis2 
				legend=legend1
				overlay 
				chref=palg;
		format &dtm &dtdisplay;
	run; quit;
%mend threeregionforecast;


/* Here you will need the sample source code from support.sas.com for Box-Jenkins Series J, and
add the following line to the data step:
    timeid='01jan2007/00:00:00'dt + (_n_*3600);

Here is the PROC ARIMA that was used on this data
 proc arima data=seriesj;
    identify var=x nlags=10;
    run;
    estimate p=3;
    run;
    identify var=y crosscorr=(x) nlags=10;
    run;
    estimate input=( 3$ (1,2)/(1,2) x ) plot;
    run;
    estimate p=2 input=( 3$ (1,2)/(1) x );
    run;
    forecast out=fcp back=24 lead=48 id=timeid interval=hour;
 quit;

*/

proc sql noprint;
select min(timeid) format=datetime28., max(timeid) format=datetime28. into :min,:max from seriesj;
quit;
%put &max &min;
options nomlogic nomprint nosymbolgen;
%threeregionforecast(
		/* positional parameters (required) */
		fcp                         /* dataset containing forecasts */
		,"13JAN2007:08:00:00"dt /* ending date of the time series - not the forecast series */
		,"01JAN2007:01:00:00"dt /* starting date of the time series */
		,24                        /* Corresponds to BACK in PROC ARIMA */
		,48                        /* Corresponds to LEAD in PROC ARIMA */
		,varname=y                 /* variable name of the actual values */
		,dtm=timeid                /* variable name of the date axis variable */
		,dtformat=dthour.
		,xinterval=hour4.
		,xminorticks=3
		,ymajnum=12
		,dtdisplay=tod5.
		,acth=.4
		,grtitle="Box Jenkins Series J"
		,hatitle="Date/Time of Observation"
		,vatitle='Output CO2 (%CO2)'
		,fclab='Forecasted Output CO2'
		,varlab='Actual Output CO2'
		);
