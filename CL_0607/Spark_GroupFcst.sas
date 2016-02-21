/* ACF, IACF and PACF Plots */
%let property=DTWDT;
%let asofdate='31dec2004'd;



libname RMWORKL clear;
options comamid=TCP remote=OYS4;
signon 'C:\Program Files\SAS\SAS 9.1\connect\saslink\tcpunix.scr' ;
*establish remote libraries;
RSUBMIT;
	LIBNAME RMWORK "/ty/stcroker/output";
	libname GRPFCST '/ty/grpfcst/ins';
ENDRSUBMIT;
*Connect the remote library to the local machine;
libname RMWORKL  slibref=rmwork 	server=OYS4;
%syslput property=&property;;
options fmtsearch=(work rmworkl.grcfmt);

rsubmit;
proc sort data=grpfcst.sleep_grcocc_filtered out=ts;
	by staydate;
	where prop_code="&property";
run;
proc timeseries data=ts out=rmwork.ts;
	id staydate interval=day accumulate=total;
	var demand;
run;
ods output chisqauto		=rmwork.chisqauto
		descstats			=rmwork.descstats
		tentativeorders	=rmwork.tentativeorders
		stationaritytests	=rmwork.stationaritytests;

proc arima data=rmwork.ts; 
      identify var=demand nlag=728 outcov=rmwork.outcov scan esacf minic stationarity=(adf=(1,2,3,4,5,6,7,28,364)); 
      run; quit;
endrsubmit;
data rmworkl.ts;
	set rmworkl.ts;
	month=month(staydate);
	year=year(staydate);
	dow=weekday(staydate);
	qtr=qtr(staydate);
	zero=0;
run;

		
data highlag;
	do highlight=0 to 728 by 364;output; end;
run;

%plotspark(rmworkl.outcov,highlag,corr,lag,xorderstmt=0 to 728 by 28,interpol=needle,device=sp17,hi=Y);
%plotspark(rmworkl.outcov,highlag,invcorr,lag,xorderstmt=0 to 728 by 28,interpol=needle,device=sp17,hi=Y);
%plotspark(rmworkl.outcov,highlag,partcorr,lag,xorderstmt=0 to 728 by 28,interpol=needle,device=sp17,hi=Y);

%plotspark(rmworkl.outcov,highlag,corr,lag,xorderstmt=0 to 30 by 1,interpol=needle,device=spacf,width=200,othsf=zoom);
%plotspark(rmworkl.outcov,highlag,invcorr,lag,xorderstmt=0 to 30 by 1,interpol=needle,device=spacf,width=200,othsf=zoom);
%plotspark(rmworkl.outcov,highlag,partcorr,lag,xorderstmt=0 to 30 by 1,interpol=needle,device=spacf,width=200,othsf=zoom);

%plotspark(rmworkl.ts,high,demand,staydate,xorderstmt='01jan02'd to '31dec02'd by 28,device=sp16,wherestmt=where year(staydate)=2002,othsf=02);
%plotspark(rmworkl.ts,high,demand,staydate,xorderstmt='01jan03'd to '31dec03'd by 28,device=sp16,wherestmt=where year(staydate)=2003,othsf=03);
%plotspark(rmworkl.ts,high,demand,staydate,xorderstmt='01jan04'd to '31dec04'd by 28,device=sp16,wherestmt=where year(staydate)=2004,othsf=04);
%plotspark(rmworkl.ts,high,demand,staydate,xorderstmt='01jan05'd to '31dec05'd by 28,device=sp16,wherestmt=where year(staydate)=2005,othsf=05);
%plotspark(rmworkl.ts,high,demand,staydate,xorderstmt='01jan06'd to '31dec06'd by 28,device=sp16,wherestmt=where year(staydate)=2006,othsf=06);
%plotspark(rmworkl.ts,high,demand,staydate,xorderstmt='01jan07'd to '31dec07'd by 28,device=sp16,wherestmt=where year(staydate)=2007,othsf=07);
%plotspark(rmworkl.ts,high,zero,staydate,xorderstmt='01jan03'd to '01jan04'd by month.,device=spax,wherestmt=where year(staydate)=2003,plot=axis,xaxisfmt=monname3);


%plotspark(rmworkl.ts,high,demand,month,xorderstmt=1 to 12 by 1,interpol=box25t,device=spbx,wherestmt=where year=2002,othsf=2002,plot=box);
%plotspark(rmworkl.ts,high,demand,month,xorderstmt=1 to 12 by 1,interpol=box25t,device=spbx,wherestmt=where year=2003,othsf=2003,plot=box);
%plotspark(rmworkl.ts,high,demand,month,xorderstmt=1 to 12 by 1,interpol=box25t,device=spbx,wherestmt=where year=2004,othsf=2004,plot=box);
%plotspark(rmworkl.ts,high,demand,month,xorderstmt=1 to 12 by 1,interpol=box25t,device=spbx,wherestmt=where year=2005,othsf=2005,plot=box);
%plotspark(rmworkl.ts,high,demand,month,xorderstmt=1 to 12 by 1,interpol=box25t,device=spbx,wherestmt=where year=2006,othsf=2006,plot=box);
%plotspark(rmworkl.ts,high,demand,month,xorderstmt=1 to 12 by 1,interpol=box25t,device=spbx,wherestmt=where year=2007,othsf=2007,plot=box);

%plotspark(rmworkl.st_errords,high,actual,staydate,xorderstmt='01jan02'd to '31dec02'd by 28,device=sp16,wherestmt=where year(staydate)=2002,othsf=02,plot=FCST);
%plotspark(rmworkl.st_errords,high,actual,staydate,xorderstmt='01jan03'd to '31dec03'd by 28,device=sp16,wherestmt=where year(staydate)=2003,othsf=03,plot=FCST);
%plotspark(rmworkl.st_errords,high,actual,staydate,xorderstmt='01jan04'd to '31dec04'd by 28,device=sp16,wherestmt=where year(staydate)=2004,othsf=04,plot=FCST);
%plotspark(rmworkl.st_errords,high,actual,staydate,xorderstmt='01jan05'd to '31dec05'd by 28,device=sp16,wherestmt=where year(staydate)=2005,othsf=05,plot=FCST);
%plotspark(rmworkl.st_errords,high,actual,staydate,xorderstmt='01jan06'd to '31dec06'd by 28,device=sp16,wherestmt=where year(staydate)=2006,othsf=06,plot=FCST);
%plotspark(rmworkl.st_errords,high,actual,staydate,xorderstmt='01jan07'd to '31dec07'd by 28,device=sp16,wherestmt=where year(staydate)=2007,othsf=07,plot=FCST);

proc sql; select distinct grc from rmworkl.st_errords;quit;
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan02'd to '31dec02'd by 28,device=sp40,wherestmt=where year(staydate)=2002 and grc='0000',othsf=02_0000,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan02'd to '31dec02'd by 28,device=sp40,wherestmt=where year(staydate)=2002 and grc='0100',othsf=02_0100,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan02'd to '31dec02'd by 28,device=sp40,wherestmt=where year(staydate)=2002 and grc='0203',othsf=02_0203,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan02'd to '31dec02'd by 28,device=sp40,wherestmt=where year(staydate)=2002 and grc='0405',othsf=02_0405,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan02'd to '31dec02'd by 28,device=sp40,wherestmt=where year(staydate)=2002 and grc='0607',othsf=02_0607,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan02'd to '31dec02'd by 28,device=sp40,wherestmt=where year(staydate)=2002 and grc='0809',othsf=02_0809,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan02'd to '31dec02'd by 28,device=sp40,wherestmt=where year(staydate)=2002 and grc='1011',othsf=02_1011,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan02'd to '31dec02'd by 28,device=sp40,wherestmt=where year(staydate)=2002 and grc='1200',othsf=02_1200,plot=FCST);

%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan03'd to '31dec03'd by 28,device=sp40,wherestmt=where year(staydate)=2003 and grc='0000',othsf=03_0000,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan03'd to '31dec03'd by 28,device=sp40,wherestmt=where year(staydate)=2003 and grc='0100',othsf=03_0100,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan03'd to '31dec03'd by 28,device=sp40,wherestmt=where year(staydate)=2003 and grc='0203',othsf=03_0203,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan03'd to '31dec03'd by 28,device=sp40,wherestmt=where year(staydate)=2003 and grc='0405',othsf=03_0405,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan03'd to '31dec03'd by 28,device=sp40,wherestmt=where year(staydate)=2003 and grc='0607',othsf=03_0607,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan03'd to '31dec03'd by 28,device=sp40,wherestmt=where year(staydate)=2003 and grc='0809',othsf=03_0809,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan03'd to '31dec03'd by 28,device=sp40,wherestmt=where year(staydate)=2003 and grc='1011',othsf=03_1011,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan03'd to '31dec03'd by 28,device=sp40,wherestmt=where year(staydate)=2003 and grc='1200',othsf=03_1200,plot=FCST);

%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan04'd to '31dec04'd by 28,device=sp40,wherestmt=where year(staydate)=2004 and grc='0000',othsf=04_0000,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan04'd to '31dec04'd by 28,device=sp40,wherestmt=where year(staydate)=2004 and grc='0100',othsf=04_0100,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan04'd to '31dec04'd by 28,device=sp40,wherestmt=where year(staydate)=2004 and grc='0203',othsf=04_0203,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan04'd to '31dec04'd by 28,device=sp40,wherestmt=where year(staydate)=2004 and grc='0405',othsf=04_0405,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan04'd to '31dec04'd by 28,device=sp40,wherestmt=where year(staydate)=2004 and grc='0607',othsf=04_0607,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan04'd to '31dec04'd by 28,device=sp40,wherestmt=where year(staydate)=2004 and grc='0809',othsf=04_0809,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan04'd to '31dec04'd by 28,device=sp40,wherestmt=where year(staydate)=2004 and grc='1011',othsf=04_1011,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan04'd to '31dec04'd by 28,device=sp40,wherestmt=where year(staydate)=2004 and grc='1200',othsf=04_1200,plot=FCST);

%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan05'd to '31dec05'd by 28,device=sp40,wherestmt=where year(staydate)=2005 and grc='0000',othsf=05_0000,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan05'd to '31dec05'd by 28,device=sp40,wherestmt=where year(staydate)=2005 and grc='0100',othsf=05_0100,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan05'd to '31dec05'd by 28,device=sp40,wherestmt=where year(staydate)=2005 and grc='0203',othsf=05_0203,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan05'd to '31dec05'd by 28,device=sp40,wherestmt=where year(staydate)=2005 and grc='0405',othsf=05_0405,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan05'd to '31dec05'd by 28,device=sp40,wherestmt=where year(staydate)=2005 and grc='0607',othsf=05_0607,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan05'd to '31dec05'd by 28,device=sp40,wherestmt=where year(staydate)=2005 and grc='0809',othsf=05_0809,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan05'd to '31dec05'd by 28,device=sp40,wherestmt=where year(staydate)=2005 and grc='1011',othsf=05_1011,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan05'd to '31dec05'd by 28,device=sp40,wherestmt=where year(staydate)=2005 and grc='1200',othsf=05_1200,plot=FCST);

%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan06'd to '31dec06'd by 28,device=sp40,wherestmt=where year(staydate)=2006 and grc='0000',othsf=06_0000,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan06'd to '31dec06'd by 28,device=sp40,wherestmt=where year(staydate)=2006 and grc='0100',othsf=06_0100,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan06'd to '31dec06'd by 28,device=sp40,wherestmt=where year(staydate)=2006 and grc='0203',othsf=06_0203,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan06'd to '31dec06'd by 28,device=sp40,wherestmt=where year(staydate)=2006 and grc='0405',othsf=06_0405,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan06'd to '31dec06'd by 28,device=sp40,wherestmt=where year(staydate)=2006 and grc='0607',othsf=06_0607,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan06'd to '31dec06'd by 28,device=sp40,wherestmt=where year(staydate)=2006 and grc='0809',othsf=06_0809,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan06'd to '31dec06'd by 28,device=sp40,wherestmt=where year(staydate)=2006 and grc='1011',othsf=06_1011,plot=FCST);
%plotspark(rmworkl.grc_errords,high,actual,staydate,xorderstmt='01jan06'd to '31dec06'd by 28,device=sp40,wherestmt=where year(staydate)=2006 and grc='1200',othsf=06_1200,plot=FCST);




%plotspark(rmworkl.chisqauto,highlag,probchisq,tolags,xorderstmt=0 to 728 by 6,interpol=needle,device=sp16,hi=N,yorderstmt=0 to 1 by 0.1);

data _null_;
	file "G:\STCroker\Group\SJCGA\intro.tex";
	put "\title{Analysis of Demand Forecast by Staydate for &property}";
	*put "\author{Samuel T. Croker \& Tomonori Ishikawa}";
run;

data _null_;
	set rmworkl.descstats end=eof;
	where prop_code="&property";
	 file "G:\STCroker\Group\SJCGA\descstats.tex";
	if _n_=1 then do;
		put '\tiny\begin{tabular}{lr}';
		put '\textbf{Statistic} & \textbf{Value} \\';
	end;
	format nvalue1 20.3;
	put  label1 ' & ' nvalue1 '  \\';
	if eof then do;
		put '\end{tabular}';
		put '\normalsize';
	end;
run;
proc transpose data=rmworkl.testunbiasedness  out=testunbiasedness;
	by prop_code;
	id source;
run;

data _null_;
	set testunbiasedness end=eof;
	where prop_code="&property";

	 file "G:\STCroker\Group\SJCGA\testunbiasedness.tex";
	if _n_=1 then do;
		put '\tiny\begin{tabular}{lrr}';
		put '\textbf{Statistic} & \textbf{Numerator} & \textbf{Denominator} \\';
	end;
	format nvalue1 20.3;
	put _name_ ' & ' numerator ' & ' denominator '  \\';
	if eof then do;
		put '\end{tabular}';
		put '\normalsize';
	end;
run;

data _null_;
	set rmworkl.stationaritytests end=eof;	
	where prop_code="&property";;

	 file "G:\STCroker\Group\SJCGA\stationaritytests.tex";
	if _n_=1 then do;
		put '\tiny\begin{tabular}{l|lrrrr}';
		put '\textbf{Type} & \textbf{Lags} & \textbf{$\rho$} & \textbf{$\tau$} & \textbf{F} \\';
	end;
	put type ' & ' lags' & $' probrho '$ & $' probtau '$ & $' probf '$ \\';
	if eof then put '\end{tabular}\normalsize';
run;
proc transpose data=rmworkl.st_outstat out=st_outstat;
	by prop_code;
	id _region_;
		var nmissa nobs nparms nmissp rmse mape mae adjrsq smape gmape mrae;

run;
data _null_;
	set st_outstat end=eof;	
	where prop_code="&property";
	format fit forecast rmse mape mae adjrsq smape gmape mrae comma19.3;
	file "G:\STCroker\Group\SJCGA\st_outstat.tex";
	if _n_=1 then do;
		put '\tiny\begin{tabular}{l|rr}';
		put '\textbf{Statistic} & \textbf{Fit} & \textbf{Forecast} \\\hline';
	end;
	put _label_ ' & ' fit  ' & ' forecast ' \\';
	if eof then put '\end{tabular}\normalsize';
run;

proc transpose data=rmworkl.grc_outstat out=grc_outstat;
	by prop_code grc;
	id _region_;
	var nmissa nobs nparms nmissp rmse mape mae adjrsq smape gmape mrae;
run;
data _null_;
	set grc_outstat end=eof;	
	where prop_code="&property";
	format fit forecast rmse mape mae adjrsq smape gmape mrae comma19.3 grc $grcfmt.;
	file "G:\STCroker\Group\SJCGA\grc_outstat.tex";
	if _n_=1 then do;
		put '\tiny\begin{tabular}{ll|rr}';
		put '\textbf{GRC} & \textbf{Statistic} & \textbf{Fit} & \textbf{Forecast} \\\hline';
	end;
	put grc ' & ' _label_ ' & ' fit  ' & ' forecast ' \\';
	if eof then put '\end{tabular}\normalsize';
run;
/* make sure all of the printed variables are in the dataset. 
	Sometimes these are not generated by proc arima if things
	are not conducive to it */
data tentativeorders; 
	where prop_code="&property";
	length scan_ar scan_ma scan_ic esacf_ar esacf_ma esacf_ic 8;
	set rmworkl.tentativeorders;	
run;
data _null_;
	set tentativeorders end=eof;	
	where prop_code="&property";
	file "G:\STCroker\Group\SJCGA\st_tentativeorders.tex";
	if _n_=1 then do;
		put '\tiny\begin{tabular}{rrrrrr}';
		put '\textbf{SCAN AR} & \textbf{SCAN MA} & \textbf{SCAN IC} & \textbf{ESACF AR} & \textbf{ESACF MA} & \textbf{ESACF IC} \\\hline';
	end;
	put SCAN_AR ' & ' SCAN_MA  ' & ' SCAN_IC ' & ' ESACF_AR ' & ' ESACF_MA  ' & ' ESACF_IC ' \\';
	if eof then put '\end{tabular}\normalsize';
run;

/*
	proc catalog catalog=work.gseg kill; run; quit;
*/


x "g:";
x "cd stcroker/group/&property";
x "pdflatex &property.tex";
x "&property.pdf";

