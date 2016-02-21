
%macro runarima(startdate, enddate);
%do ar_a=0 %to 3; 
	%do ma_a=0 %to 3;
		%do ar_b=0 %to 3;
			%do ma_b=0 %to 3;
				%do ar_md=0 %to 5;
					%do ma_md=0 %to 5;
						data _null_; call symput ("modelid",compress("M_&ar_a.&ma_a.&ar_b.&ma_b.&ar_md.&ma_md")); run;
						proc arima data=saluda.smoothed_rivers;
							title "ARIMA Model Identification, Estimation, and Forecast";
							where datetime between &startdate and &enddate;
							identify clear var=&inputvar1 scan nlag=12 outcov=&inputvar1._acf noprint; 
							estimate p=&ar_a q=&ma_a method=ml noprint;
							identify var=&inputvar3  scan nlag=12 outcov=&inputvar3._acf noprint;
							estimate p=&ar_b q=&ma_b method=ml noprint ;
							identify var=&outputvar1 scan crosscorr=(&inputvar1 &inputvar3) nlag=20 noprint;*outcov=outcov_&modelid noprint ;*prewhitening step; 
							estimate p=&ar_md q=&ma_md input=(3$(1)/(1)&inputvar1 8$(1)/(1)&inputvar3 ) noprint plot method=ml /*outest=outest outmodel=outmodel*/ outstat=outstat_&modelid ;
							forecast lead=24 out=forecast id=datetime interval=hour noprint;
						run;quit;
						data outstat_&modelid; set outstat_&modelid; format modelid $25.; informat modelid 25.; modelid=symget('modelid'); run;					    proc append base=outstat data=outstat_&modelid ;
						proc datasets; delete outstat_&modelid noprint;run;
					%end;
				%end;
 			%end;
 		%end;
	 %end;
%end;
%mend runarima;

libname saluda 'C:\Documents and Settings\Samuel  Croker\Desktop\Thesis Final';
options NOMLOGIC NOMPRINT NOMRECALL NOSYMBOLGEN NOMAUTOSOURCE;

%let startdate=		'01aug01/00:00:00'DT;
%let enddate=		'12aug01/00:00:00'DT;

%let plotinterval=  1; *days;
***********************************************************;
options orientation=landscape papersize=letter symbolgen;
*set the starting and ending dates for graphing;
%let numpint = %eval(&plotinterval*86400);
data _null_;
  call symput('g1date',put(datepart(&startdate),date7.));
  call symput('g2date',put(datepart(&enddate),date7.));
run;
%let inputvar2=		logsal9000_flow;
%let inputvar3=		logals1000_flow;

%let yaxisvar=      Logged Flow;
%let inputvar1=		logsal8504_flow;
%let outputvar1=	logcong9500_flow;
%let outputvar2=	logcong9625_flow;
%let dataset=		saluda.allrivers95_02;

%let inputvar1lab = Logged Upper Saluda Streamflow;
%let inputvar2lab=  Logged Lower Saluda Streamflow;
%let inputvar3lab=  Logged Alston Broad Streamflow;
%let outputvar1lab= Logged Congaree at Columbia Streamflow;
%let outputvar2lab= Logged Congaree National Park Streamflow;

proc sql; 
 create table outstat_&g1date._&g2date ( _type_ character(8), _stat_ character(8), _value_ double precision, modelid character(25)) ;
quit;
proc printto;* log='C:\Documents and Settings\Samuel  Croker\Desktop\Thesis Final\arima.log' new;
run;

%runarima(&startdate,&enddate);

proc sql; create table AICStat as select * from outstat where _stat_ = "AIC" order by _value_;quit;
data aicstat; set aicstat; aicorder=_n_; rename _value_=AIC; run;
data aicstat; set aicstat; where aicorder <=40; run;
proc sql;
	create table SSEStat as select * from outstat where _stat_ = "SSE" and modelid in (select modelid from aicstat) ;
 	create table SBCStat as select * from outstat where _stat_ = "SBC" and modelid in (select modelid from aicstat)  ;
  	create table NITERStat as select * from outstat where _stat_ = "NITER"  and modelid in (select modelid from aicstat) ;
  	create table CONVStat as select * from outstat where _stat_ = "CONV"  and modelid in (select modelid from aicstat) ;
quit;
proc sort data=aicstat; by modelid; run;
proc sort data=ssestat; by modelid; run;
proc sort data=sbcstat; by modelid; run;
proc sort data=niterstat; by modelid; run;
proc sort data=convstat; by modelid; run;

data ssestat; set ssestat; rename _value_=sse; run;
data sbcstat; set sbcstat; rename _value_=sbc; run;
data niterstat; set niterstat; rename _value_=niter; run;
data convstat; set convstat; rename _value_=conv; run;

data saluda.modelcomp_&g1date._&g2date; 
 merge aicstat (in=y1) ssestat(in=y2) sbcstat (in=y3) niterstat (in=y4) convstat (in=y5);
 by modelid;
 if y1 and y2 and y3 and y4 and y5;
 label aic="AIC" SSE="SSE" SBC="SBC" NITER="NITER" conv="CONV";
run;
proc sort data=saluda.modelcomp_&g1date._&g2date;
  by conv aic sse sbc niter;
  run;

  