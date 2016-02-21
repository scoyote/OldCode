/****************************************************	
*****	Saluda 1995-2002 Exploration Program 	*****
*****   SaludaExploratory.sas					*****
*****   Created 11-27-2003						*****
*****   Created by Sam Croker					*****
*****************************************************/	

libname saluda 'C:\Documents and Settings\Samuel  Croker\Desktop\Thesis Final\';
proc means data=saluda.allrivers95_02 mean;
	var logsal8504_flow logals1000_flow logcong9500_flow;
	output out=meanser mean(logsal8504_flow logals1000_flow logcong9500_flow)=;
run;
data _null_; set meanser;
  call symput('alsmean',logals1000_flow);
  call symput('salmean',logsal8504_flow);
  call symput('congmean',logcong9500_flow);
 run;
 data rivers; set saluda.allrivers95_02;
   if logsal8504_flow =. then logsal8504_flow=&salmean;
   if logals1000_flow =. then logals1000_flow=&alsmean;
   if logcong9500_flow =. then logcong9500_flow=&congmean;
run;

%let startdate=		'01feb98/00:00:00'DT;
%let forecaststart= '01mar98/00:00:00'DT;
%let enddate=		'01mar98/00:00:00'DT;
%let forecastend=   '02mar98/00:00:00'DT;
%let ar_a=1  ;
%let ma_a=0  ;
%let ar_b=1  ;
%let ma_b=0  ;
%let ar_md=2 ;
%let ma_md=1 ;
%let delay1=3;
%let delay2=6;
%let plotinterval=  2; *days;
***********************************************************;
options orientation=landscape papersize=letter symbolgen;
*set the starting and ending dates for graphing;
%let numpint = %eval(&plotinterval*86400);
data _null_;
  call symput('g1date',put(datepart(&startdate),date7.));
  call symput('g2date',put(datepart(&enddate),date7.));
run;
ods pdf file="C:\Documents and Settings\Samuel  Croker\Desktop\Thesis Final\Saluda_&g1date._&g2date..pdf";

%let yaxisvar=      Logged Flow;
%let inputvar1=		logsal8504_flow;
%let inputvar3=		logals1000_flow;
%let outputvar1=	logcong9500_flow;
%let outputvar2=	logcong9625_flow;
%let dataset=		rivers;

%let inputvar1lab = Logged Upper Saluda Streamflow;
%let inputvar3lab=  Logged Alston Broad Streamflow;
%let outputvar1lab= Logged Congaree at Columbia Streamflow;
%let outputvar2lab= Logged Congaree National Park Streamflow;
title1 "Sam Croker";
title2 "&g1date - &g2date";
title3 "Prewhiten Inputs: AR(&ar_a,&ma_a) AR(&ar_b,&ma_b)";
title4 "Transfer Function: AR(&ar_md,&ma_md) B1:&delay1 B2:&delay2";
	*Plot the Profile;
		goptions reset=all ftext="swiss";
			axis1 label=(f='swiss' h=1) value=(f='swiss'  h=1) 
		          order=(&startdate to &enddate by &numpint);
			axis2 label=( f='swiss' h=1.5 angle=90 "&yaxisvar") value=(f='swiss' h=1); 
			legend1 label=('Stations') 
		         value=(f='swiss' h=1 
		                "&inputvar1lab"
		                "&inputvar3lab" "&outputvar1lab" "&outputvar2lab");
			symbol1 v=none	I=j c=blue 		pointlabel=none;
			symbol2 v=none	I=j c=green 	pointlabel=none;
			symbol3 v=none	I=j c=red 		pointlabel=none;
			symbol4 v=none	I=j c=magenta	pointlabel=none;
			symbol5 v=none	I=j c=Black	    pointlabel=none;

		proc gplot data=&dataset;
			title1 "&yaxisvar from &g1date to &g2date";
			title2 "&g1date - &g2date";
			title3 "Prewhiten Inputs: AR(&ar_a,&ma_a) AR(&ar_b,&ma_b)";
			title4 "Transfer Function: AR(&ar_md,&ma_md) B1:&delay1 B2:&delay2";
			plot 	&inputvar1*datetime &inputvar3*datetime &outputvar1*datetime &outputvar2*datetime 
					 /overlay haxis=axis1 vaxis=axis2 legend=legend1 ;
			where datetime between &startdate and &enddate ;
			format datetime datetime18.;
		run;quit;
*identification of inputs;
/*Fit the ARMA Model ********************************************************/
proc arima data=&dataset out=poo aslfd; 
	title1 "ARIMA Model Identification, Estimation, and Forecast";
	title2 "&g1date - &g2date";
	title3 "Prewhiten Inputs: AR(&ar_a,&ma_a) AR(&ar_b,&ma_b)";
	title4 "Transfer Function: AR(&ar_md,&ma_md) B1:&delay1 B2:&delay2";
	where datetime between &startdate and &enddate;
	identify clear var=&inputvar1 scan nlag=12  noprint ;
	estimate p=&ar_a q=&ma_a method=ml noprint;
	identify var=&inputvar3  scan nlag=12 noprint;
	estimate p=&ar_b q=&ma_b method=ml noprint;
	identify var=&outputvar1 scan crosscorr=(&inputvar1 &inputvar3) nlag=20 outcov=ccft esacf ;*prewhitening step; 
	estimate p=&ar_md q=&ma_md input=(&delay1$(1)/(1)&inputvar1 &delay2$(1)/(1)&inputvar3 ) plot method=ml ;
	forecast lead=24 out=forecast id=datetime interval=hour noprint;
run;quit;
*title1 "Diagnostics for Dates &g1date -- &g2date";
*%plotacf(ccft,12);
title1 "Prewhitened Cross Correlation Function &g1date - &g2date";
title2 "&g1date - &g2date";
title3 "Prewhiten Inputs: AR(&ar_a,&ma_a) AR(&ar_b,&ma_b)";
title4 "Transfer Function: AR(&ar_md,&ma_md) B1:&delay1 B2:&delay2";
%plotccf(ccft,-20,20,2);
%plotccf_combined(ccft,-20,20,2);

title1 "Forecast for &g1date - &g2date";
title2 "&g1date - &g2date";
title3 "Prewhiten Inputs: AR(&ar_a,&ma_a) AR(&ar_b,&ma_b)";
title4 "Transfer Function: AR(&ar_md,&ma_md) B1:&delay1 B2:&delay2";
%plotforecast(forecast);

title1 "Diagnostics for Residual Series &g1date - &g2date";
title2 "&g1date - &g2date";
title3 "Prewhiten Inputs: AR(&ar_a,&ma_a) AR(&ar_b,&ma_b)";
title4 "Transfer Function: AR(&ar_md,&ma_md) B1:&delay1 B2:&delay2";
proc arima data=forecast  ;
  	identify clear var=residual scan nlag=9 outcov=acfresid; *stationarity=(adf=(3)) ;
run;quit;
*%plotacf(acfresid,9);
ods pdf close;


*****************************************************************************************;
%macro plotccf_combined(ccft_dataset,lag1,lag2,offset);
   data c1 c2; set &ccft_dataset;
     if crossvar="&inputvar1" then output c1;
	 if crossvar="&inputvar3" then output c2;
	run;
	data new;
	  merge c1 c2; 
		by lag;
	  keep lag corr;
	run;
	
 	proc gplot data=new ;
		symbol1 v=none	I=needle c=black pointlabel=("#corr" f="swiss" h=1);
		axis1 label=(f='swiss' h=1.5 ) value=(f='swiss' h=1) order=( &lag1 to &lag2 by &offset) ;
		axis2 label=(f='swiss' h=1.5 angle=90) value=( f='swiss' h=1) ;
	    label corr="Combined Cross Correlation Function (CCF)";
		legend1 label=('Stations') value=(f='swiss' h=1 "Combined" ) ;
		format corr 4.3;
		plot corr*lag
	        / haxis=axis1 vaxis=axis2 legend=legend1 
			autohref chref=lilg
			autovref cvref=lilg;
  run;quit;
%mend plotc_ccf;
%macro plotccf(ccft_dataset,lag1,lag2,offset);
   proc gplot data=&ccft_dataset;
		symbol1 v=none	I=spline c=blue pointlabel=none;
	    symbol2 v=none 	I=spline c=black pointlabel=none;
		axis1 label=(f='swiss' h=1.5 ) value=(f='swiss' h=1) order=( &lag1 to &lag2 by &offset) ;
		axis2 label=(f='swiss' h=1.5 angle=90) value=( f='swiss' h=1) order=(-1 to 1 by .2);
	    label corr="Cross Correlation Function (CCF)";
		legend1 label=('Stations') value=(f='swiss' h=1) down=2 ;
		format corr 4.3;
		where crossvar<>"";
		plot corr*lag=crossvar 
	        / haxis=axis1 vaxis=axis2 legend=legend1 
			autohref chref=lilg
			autovref cvref=lilg;
  run;quit;
options orientation=portrait;
%mend plotccf;

%macro plotacf(acf_dataset,lags);
options orientation=landscape;
	  proc gplot data=&acf_dataset;
		label corr="ACF" partcorr="PACF";
		plot corr*lag partcorr*lag /haxis=axis1 vaxis=axis2 legend=legend1;
		symbol1 v=none 	I=needle c=black pointlabel=none;
		axis1 label=(f='swiss' h=2 ) value=(f='swiss' h=1) order=( 0 to &lags by 1) ;
		axis2 label=(f='swiss' h=2 angle=90) value=( f='swiss' h=1) order=(-1 to 1 by .2);
		where crossvar="";
	run;quit;
options orientation=portrait;
%mend plotacf;

%macro plotforecast(fcstdata);
		symbol1 v=none 	I=join c=red pointlabel=none;
		symbol2 v=none 	I=join c=pink pointlabel=none;
		symbol3 v=none 	I=join c=blue pointlabel=none;
		symbol4 v=none 	I=join c=black pointlabel=none;
		axis1 label=(f='swiss' h=1.5 ) value=(f='swiss'  h=1 angle=30);
		axis2 label=( f='swiss' h=1.5 angle=90) value=(f='swiss' h=1) ; 
		legend1 label=('Forecasts') value=(f='swiss' h=1) down=2 across=2;
	proc gplot data=&Fcstdata;
		format datetime datetime18.;
		where datetime between &forecaststart and &forecastend;
		plot l95*datetime u95*datetime forecast*datetime &outputvar1*datetime /overlay haxis=axis1 vaxis=axis2 legend=legend1;
	run;quit;
%mend plotforecast;