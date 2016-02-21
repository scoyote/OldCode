/*******************************************************************************
*       Program Name    :       $RCSfile: fourprop.sas,v $
*       REV/REV AUTH    :       $Revision: 1.1 $ $Author: scoyote $
*       REV DATE        :       $Date: 2007/11/11 10:39:21 $
********************************************************************************/
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
options fmtsearch=(work rmworkl.grcfmt);
%include "C:\Documents and Settings\scrok586\Desktop\SCOYOTENETCVS\CL_0607\sparktsmacros.sas";
%let outdir=G:\STCroker\Group\Fourprop\images;
/* SEAWF LAXAH SANDT SJCGA */
%let property=SJCGA;
%let dif=;
%macro gends(yearnum);
%let yearnum=&yearnum;
	%plotspark(rmworkl.grcarimaforecast,high,actual,staydate,xorderstmt="01jan&yearnum."d to "31dec&yearnum."d by 28,device=sp40,wherestmt=where year(staydate)=20&yearnum. and grc="0000" and prop_code="&property",othsf=&yearnum._0000_&dif._&property,plot=FCST);
	%plotspark(rmworkl.grcarimaforecast,high,actual,staydate,xorderstmt="01jan&yearnum."d to "31dec&yearnum."d by 28,device=sp40,wherestmt=where year(staydate)=20&yearnum. and grc="0100" and prop_code="&property",othsf=&yearnum._0100_&dif._&property,plot=FCST);
	%plotspark(rmworkl.grcarimaforecast,high,actual,staydate,xorderstmt="01jan&yearnum."d to "31dec&yearnum."d by 28,device=sp40,wherestmt=where year(staydate)=20&yearnum. and grc="0203" and prop_code="&property",othsf=&yearnum._0203_&dif._&property,plot=FCST);
	%plotspark(rmworkl.grcarimaforecast,high,actual,staydate,xorderstmt="01jan&yearnum."d to "31dec&yearnum."d by 28,device=sp40,wherestmt=where year(staydate)=20&yearnum. and grc="0405" and prop_code="&property",othsf=&yearnum._0405_&dif._&property,plot=FCST);
	%plotspark(rmworkl.grcarimaforecast,high,actual,staydate,xorderstmt="01jan&yearnum."d to "31dec&yearnum."d by 28,device=sp40,wherestmt=where year(staydate)=20&yearnum. and grc="0607" and prop_code="&property",othsf=&yearnum._0607_&dif._&property,plot=FCST);
	%plotspark(rmworkl.grcarimaforecast,high,actual,staydate,xorderstmt="01jan&yearnum."d to "31dec&yearnum."d by 28,device=sp40,wherestmt=where year(staydate)=20&yearnum. and grc="0809" and prop_code="&property",othsf=&yearnum._0809_&dif._&property,plot=FCST);
	%plotspark(rmworkl.grcarimaforecast,high,actual,staydate,xorderstmt="01jan&yearnum."d to "31dec&yearnum."d by 28,device=sp40,wherestmt=where year(staydate)=20&yearnum. and grc="1011" and prop_code="&property",othsf=&yearnum._1011_&dif._&property,plot=FCST);
	%plotspark(rmworkl.grcarimaforecast,high,actual,staydate,xorderstmt="01jan&yearnum."d to "31dec&yearnum."d by 28,device=sp40,wherestmt=where year(staydate)=20&yearnum. and grc="1200" and prop_code="&property",othsf=&yearnum._1200_&dif._&property,plot=FCST);
%mend;
%macro graphprops(property,dif);
options nonotes;

%plotspark(rmworkl.arimaforecast,high,zero,staydate,xorderstmt='01jan03'd to '01jan04'd by month.,device=spax,wherestmt=where year(staydate)=2003,plot=axis,xaxisfmt=monname3);
%plotspark(rmworkl.arimaforecast,high,actual,staydate,xorderstmt='01jan02'd to '31dec02'd by 28,device=sp16,wherestmt=where year(staydate)=2002 and prop_code="&property",othsf=02_&dif._&property.,plot=FCST);
%plotspark(rmworkl.arimaforecast,high,actual,staydate,xorderstmt='01jan03'd to '31dec03'd by 28,device=sp16,wherestmt=where year(staydate)=2003 and prop_code="&property",othsf=03_&dif._&property.,plot=FCST);
%plotspark(rmworkl.arimaforecast,high,actual,staydate,xorderstmt='01jan04'd to '31dec04'd by 28,device=sp16,wherestmt=where year(staydate)=2004 and prop_code="&property",othsf=04_&dif._&property.,plot=FCST);
%plotspark(rmworkl.arimaforecast,high,actual,staydate,xorderstmt='01jan05'd to '31dec05'd by 28,device=sp16,wherestmt=where year(staydate)=2005 and prop_code="&property",othsf=05_&dif._&property.,plot=FCST);
%plotspark(rmworkl.arimaforecast,high,actual,staydate,xorderstmt='01jan06'd to '31dec06'd by 28,device=sp16,wherestmt=where year(staydate)=2006 and prop_code="&property",othsf=06_&dif._&property.,plot=FCST);
%plotspark(rmworkl.arimaforecast,high,actual,staydate,xorderstmt='01jan07'd to '31dec07'd by 28,device=sp16,wherestmt=where year(staydate)=2007 and prop_code="&property",othsf=07_&dif._&property.,plot=FCST);
quit;


options notes;
proc transpose data=rmworkl.st_outstat out=st_outstat;
	by prop_code;
	id _region_;
		var nmissa nobs nparms nmissp rmse mape mae adjrsq smape gmape mrae;

run;
data _null_;
	set st_outstat end=eof;	
	where prop_code="&property";
	format fit forecast rmse mape mae adjrsq smape gmape mrae comma19.3;
	file "&outdir.\stoutstat_&dif._&property..tex";
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
	file "&outdir.\grcoutstat_&dif._&property..tex";
	if _n_=1 then do;
		put '\tiny\begin{tabular}{ll|rr}';
		put '\textbf{GRC} & \textbf{Statistic} & \textbf{Fit} & \textbf{Forecast} \\\hline';
	end;
	put grc ' & ' _label_ ' & ' fit  ' & ' forecast ' \\';
	if eof then put '\end{tabular}\normalsize';
run;
%let property=SANDT;
%let dif=364;
data _null_;
	set rmworkl.grcreconmape end=eof;	
	where prop_code="&property";
	file "&outdir.\grcreconmape_&dif._&property..tex";
	if _n_=1 then do;
		put '\tiny\begin{tabular}{l|r}';
		put '\textbf{Region} & \textbf{MAPE} ';
	end;
	put _region_  ' & ' mape ' \\';
	if eof then put '\end{tabular}\normalsize';
run;


/* build the selectedmodels dataset */
proc sort data=rmworkl.arimamdls out=arimamdls;
	by statistic; 
run;

data _null_;
	set arimamdls end=eof;
	format statistic 10.3;
	where prop_code="&property" and statistic~=.;
	 file "&outdir.\arimamdls_&dif._&property..tex";
	if _n_=1 then do;
		put '\begin{tabular}{lrlr}';
		put '\textbf{Selected} & \textbf{MAPE} & \textbf{Model} \\';
	end;
	put  selected ' & ' statistic ' &  ' label' \\';
	if _n_=10 then do;
		put '\end{tabular}';
		stop;
	end;

run;
proc sort data=rmworkl.grcmdls out=grcmdls;
	by statistic; 
run;

data _null_;
	set grcmdls end=eof;
	format statistic 10.3;
	where prop_code="&property" and selected="Yes";
	format grc $grcfmt.;
	 file "&outdir.\grcmdls_&dif._&property..tex";
	if _n_=1 then do;
		put '\begin{tabular}{llrlr}';
		put '\textbf{GRC} & \textbf{Selected} & \textbf{MAPE} & \textbf{Model} \\';
	end;
	put  grc ' & ' selected ' & ' statistic ' &  ' label' \\';
	if eof then do;
		put '\end{tabular}';
		stop;
	end;
run;


*%gends(03);
*%gends(04);
*%gends(05);
*%gends(06);
%put All Done;
options notes;
%mend;

%graphprops(LAXAH,0);


%macro writesascodetolatex(filename,indirectory,outdirectory);
	data _null_;
		infile "&indirectory\&filename..sas" lrecl=1000 end=eof ;
		file "&outdirectory\&filename..tex";
		line_no+1;
		input;
		if line_no=1 then put "\begin{verbatim}";
		put _infile_;
		if eof then put "\end{verbatim}";
	run;
%mend writesascodetolatex;
%writesascodetolatex(hpfgrouptotal,C:\Documents and Settings\scrok586\Desktop\Sandbox\stcroker,G:\STCroker\Group\Fourprop\images);
%writesascodetolatex(validproperties,C:\Documents and Settings\scrok586\Desktop\Sandbox\stcroker,G:\STCroker\Group\Fourprop\images);
%writesascodetolatex(forecastallvalidproperties,C:\Documents and Settings\scrok586\Desktop\Sandbox\stcroker,G:\STCroker\Group\Fourprop\images);
%writesascodetolatex(grcforecastallvalidproperties,C:\Documents and Settings\scrok586\Desktop\Sandbox\stcroker,G:\STCroker\Group\Fourprop\images);
%writesascodetolatex(macrodefinitions,C:\Documents and Settings\scrok586\Desktop\Sandbox\stcroker,G:\STCroker\Group\Fourprop\images);
%writesascodetolatex(eventsspecs,C:\Documents and Settings\scrok586\Desktop\Sandbox\stcroker,G:\STCroker\Group\Fourprop\images);


proc sort data=rmworkl.arimamdls;
	by prop_code descending statistic;
run;
