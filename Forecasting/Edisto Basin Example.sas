
libname RMWORKL clear;
options comamid=TCP remote=OYS4;
signon 'C:\Program Files\SAS\SAS 9.1\connect\saslink\tcpunix.scr' ;
*establish remote libraries;
RSUBMIT;
   LIBNAME RMWORK "/ty/stcroker/output";
ENDRSUBMIT;
*Connect the remote library to the local machine;
libname RMWORKL  slibref=rmwork 	server=OYS4;

rsubmit;
	data parameters;
		filename params url "http://nwis.waterdata.usgs.gov/usa/nwis/pmcodes?pm_group=ALL%nrstr(&)pm_search=%nrstr(&)format=rdb%nrstr(&)show=parameter_cd%nrstr(&)show=parameter_group_nm%nrstr(&)show=parameter_nm";
		infile params dlm='09'x ;
		length parameter_cd $5 parameter_group_nm $26 parameter_nm $176;
		input parameter_cd  @;
		if trim(substr(parameter_cd,1,2)) in ('#','pa','5s') then delete;
		else input parameter_group_nm	?? parameter_nm  ??;
	run;
	data sitelist;
		filename sitelist url  "http://waterdata.usgs.gov/sc/nwis/current?format=rdb";
		infile sitelist dlm='09'x dsd lrecl=500 truncover;
		length agency_cd $5	site_no $15 dd_nu $2	parameter_cd $5 ;
		input agency_cd $ site_no $ dd_nu $ parameter_cd  $ ;
		if substr(agency_cd,1,4)~='USGS' then delete;
	run;



	%let a0=http://waterdata.usgs.gov/sc/nwis/current;
	%let a1=?index_pmcode_ALL=ALL%nrstr(&)index_pmcode_STATION_NM=1%nrstr(&)index_pmcode_DATETIME=2;
	%let a2=%nrstr(&)index_pmcode_72019=%nrstr(&)index_pmcode_72020=%nrstr(&)index_pmcode_00062=%nrstr(&)index_pmcode_00065=3;
	%let a3=%nrstr(&)index_pmcode_MEAN=%nrstr(&)index_pmcode_MEDIAN=%nrstr(&)index_pmcode_00055=8%nrstr(&)index_pmcode_00060=4;
	%let a4=%nrstr(&)index_pmcode_62361=%nrstr(&)index_pmcode_00301=%nrstr(&)index_pmcode_00300=5%nrstr(&)index_pmcode_00096=;
	%let a5=%nrstr(&)index_pmcode_00480=%nrstr(&)index_pmcode_00095=%nrstr(&)index_pmcode_00010=6%nrstr(&)index_pmcode_63680=;
	%let a6=%nrstr(&)index_pmcode_00076=%nrstr(&)index_pmcode_00400=%nrstr(&)index_pmcode_00025=%nrstr(&)index_pmcode_00045=7;
	%let a7=%nrstr(&)index_pmcode_00052=%nrstr(&)index_pmcode_00020=%nrstr(&)index_pmcode_00021=%nrstr(&)index_pmcode_62608=;
	%let a8=%nrstr(&)index_pmcode_00036=%nrstr(&)index_pmcode_00035=%nrstr(&)index_pmcode_74207=%nrstr(&)sort_key=site_no;
	%let a9=%nrstr(&)group_key=NONE%nrstr(&)format=sitefile_output%nrstr(&)sitefile_output_format=rdb%nrstr(&)column_name=agency_cd;
	%let a10=%nrstr(&)column_name=site_no%nrstr(&)column_name=station_nm%nrstr(&)sort_key_2=site_no;
	%let a11=%nrstr(&)html_table_group_key=NONE%nrstr(&)rdb_compression=value;
	%let a12=%nrstr(&)list_of_search_criteria=realtime_parameter_selection;
	filename sitename url "&a0&a1&a2&a3&a4&a5&a6&a7&a8&a9&a10&a11&a12";

	data sitenames;
		infile sitename dlm='09'x dsd truncover;
		length agency_cd $5	site_no $15 station_nm $50;
		input agency_cd $ site_no $ station_nm ?? $;
		if substr(agency_cd,1,4)~='USGS' then delete;
		drop agency_cd;
	run;

	proc sort data=parameters; by parameter_cd;run;
	data parameters;
		set parameters;
		param_key=_n_;
	run;
	proc sort data=sitelist; by parameter_cd;run;
	
	data siteparams; 
		merge 
			sitelist (in=y1)
			parameters (in=y2);
		by parameter_cd;
		if y1;
	run;
	proc sort data=siteparams nodupkey;
		by site_no parameter_cd;
	run;

	proc transpose data=siteparams out=Sites_and_parameters prefix=p;
		by site_no;
		var parameter_nm;
		id parameter_cd;
	run;

	data allsites;
		merge	
			siteparams (in=y1)
			sitenames (in=y2);
		by site_no;
		if y1;
	run;

	
%macro buildlookupstring(site_no,fref);
	/*http://waterdata.usgs.gov/sc/nwis/uv?cb_00065=on&cb_00060=on&format=rdb&period=31&site_no=02173000 */
	%local i;
	%local paramstring;
	proc sql;
		select count(distinct parameter_cd) into :numparams from allsites where site_no="&site_no";
		%let numparams=&numparams;
		select parameter_cd 
			into :pstring1-:pstring&numparams
			from allsites where site_no="&site_no";
	quit;
	%let datalook=http://waterdata.usgs.gov/sc/nwis/uv?;
	%do i=1 %to &numparams;
		%let datalook=&datalook.%nrstr(%nrstr(&))cd_&&pstring&i.=on;
	%end;
	%let datalook=%cmpres(&datalook.%nrstr(%nrstr(&))format=rdb%nrstr(%nrstr(&))period=31%nrstr(%nrstr(&))site_no=&site_no);
	filename &fref url "&datalook";
	%put Fileref &fref = &datalook;
%mend;

%macro buildfilerefs;
	proc sql;
		select count(distinct site_no) into :numsites from allsites where lowcase(station_nm) contains "edisto";
		%let numsites=&numsites;
		select distinct site_no into :siteno1-:siteno&numsites from allsites where lowcase(station_nm) contains "edisto";
		select * from allsites where lowcase(station_nm) contains "edisto";
	quit;
	%do i=1 %to &numsites;	
		%buildlookupstring(&&siteno&i,%cmpres(FREF%substr(&&siteno&i,5,4)));
	%end;
	%do i=1 %to &numsites;
		data f&&siteno&i;
			infile %cmpres(FREF%substr(&&siteno&i,5,4)) end=eof&i dlm='09'x dsd;
			length agency_cd $5 site_no $30;
			input agency_cd @;
			if agency_cd~='USGS' then delete; 
			else input site_no $ dtm $16. fil1 $ stage&&siteno&i fil2 $ flow&&siteno&i;	
			tm=input(scan(dtm,2,' '),anydttme5.);
			dtstamp=dhms(input(scan(dtm,1,' '),anydtdte10.),hour(tm),minute(tm),second(tm));
			format dtstamp datetime28.;
			drop dtm tm fil1 fil2;
		run;
	%end;
	data edisto;
		merge
			%do i=1 %to &numsites;
				f&&siteno&i
			%end;
			;
		by dtstamp;

	run;
	%do i=1 %to &numsites;
		symbol&i l=&i i=j  v=none;
	%end;
	proc sql noprint;
		select min(dtstamp),max(dtstamp) into :mindtstamp, :maxdtstamp from edisto;
	quit;
	data daylines;
		set edisto;
		ysys='1';
		xsys='2';
		if hour(dtstamp)=0 then do;
			function='move'; x=dtstamp; y=0;output;
			function='draw'; x=dtstamp; color='bwh'; y=100;output;
		end;
	run;
	axis1 order=(&mindtstamp to &maxdtstamp by dtday7);
	axis2 label=(rotate=0 angle=90);
	proc gplot data=edisto annotate=daylines;
		format dtstamp datetime8.;
		title Stage Profile;
		plot (%do i=1 %to &numsites;
				stage&&siteno&i
			%end;)*dtstamp /overlay  autovref cvref=bwh legend haxis=axis1 vaxis=axis2;
		run;
		title Streamflow Profile;

		plot (%do i=1 %to &numsites;
				flow&&siteno&i
			%end;)*dtstamp /overlay autovref cvref=bwh legend haxis=axis1 vaxis=axis2;
		run;
	title;
	quit;
%mend buildfilerefs;
%buildfilerefs;

rsubmit;
ods graphics on;
ods html;
proc arima data=edisto;
	identify var=flow02173500(1) scan minic esacf noprint;run;estimate p=2 q=1 noprint;run;
	identify var=flow02173051(1) scan minic esacf noprint;run;estimate p=1 q=2 noprint;run;
	identify var=flow02175000(1) crosscorr=(flow02173051(1) flow02173500(1)) scan minic esacf outcov=outcov;
	run;
	estimate p=1 q=1 input=(50$/(1)flow02173051 54$/(1)flow02173500 )plot outest=outest outcov outcorr ;
quit;
ods html close;
ods graphics off;
endrsubmit;

symbol1 v=none i=needle l=1 c=black;
symbol2 v=none i=needle l=1 c=blue;
symbol3 v=none i=needle l=1 c=green ;

proc gplot data=outcov;
by crossvar;
	plot corr*lag ;
	where ~missing(crossvar);
run;quit;



rsubmit;

proc catalog catalog=SASHELP.HPFDFLT ; copy out=work.arima ; run;
proc catalog catalog=SASHELP.HPFDFLT kill ; run;quit;

proc hpfarimaspec repository=work.arima name=model1 label='First';
	forecast symbol=flow02175000 p=1 q=1 dif=1 transform=none; 
	input symbol=flow02173500  dif=1 num=1 den=1 delay=54 transform=none;
	input symbol=flow02173051 dif=1 num=1 den=1 delay=50 transform=none;
run;

proc catalog catalog=work.arima ; contents OUT=SPECS; run;
proc sql; select distinct name into :specs from specs; quit;
proc hpfselect 
		repository=work.arima
		name=first;
	select 
		criterion=mape 
		holdout=72;
	spec &specs;
run;
proc hpfengine data=edisto outfor=outfor
                    lead=24
				back=24
				inest=est
                    repository=work.arima
				task=select(holdout=364)
				globalselection=first
				print=(select);
        id       dtstamp interval=hour;
        forecast flow02175000;
        input flow02173500;
	   input flow02173051;
     run;
	proc hpfengine data=edisto outfor=outfor
                    lead=24
				back=24
				inest=est
				task=forecast
                    repository=work.arima
				globalselection=first
				print=all
				outfor=outfor;
        id       dtstamp interval=hour;
        forecast flow02175000;
        input flow02173500;
	   input flow02173051;
     run;

	ODS PATH work.templat(update) sasuser.templat(read) sashelp.tmplmst(read);
	proc template;
		define statgraph mygraphs.stcfor;
		layout lattice /width=2500 height=700;
			layout overlay ;				
				Band
					ylimitlower=fit_lower
					ylimitupper=fit_upper
					x=staydate / 
						fill=true 
						lines=false 
						fillcolor=ywh 
						legendlabel="Fit CI" 
						name="Conf1";
				Band
					ylimitlower=holdout_lower
					ylimitupper=holdout_upper
					x=staydate / 
						fill=true 
						lines=false 
						fillcolor=bwh
						legendlabel="Holdout CI" 
						name="Conf2";
				Band
					ylimitlower=fcst_lower
					ylimitupper=fcst_upper
					x=staydate / 
						fill=true 
						lines=false 
						fillcolor=pkwh
						legendlabel="Forecast CI" 
						name="Conf3";
				SERIES X=staydate Y=demand /name="act" legendlabel="Total Demand"  markers=true markersymbol=circlefilled markercolor=black linecolor=green;
				SERIES X=staydate Y=predict /name="pred" legendlabel="Total Demand Forecast" markers=false linecolor=blue;
				
			endlayout;
			SIDEBAR / ALIGN= BOTTOM ;
				DISCRETELEGEND 'Conf1' 'Conf2' 'Conf3' 'act' 'pred' /across=3 ;
			ENDSIDEBAR;
		endlayout;
		end;
	run;

	goptions device=gif;
/*	proc sql noprint;*/
/*		select max(staydate) into :maxdate from outfor;*/
/*	quit;*/
/*	data fit holdout fcst; set &forecastdataset;*/
/*		where staydate>=intnx('day',&maxdate,-&plotstart);*/
/*		if staydate<=intnx('day',&maxdate,-&forecaststart)  then output fit;*/
/*		else if staydate<= &maxdate then output holdout;*/
/*		else output fcst;*/
/*	run;*/
/*	data finalfor;*/
/*		set 	fit (rename=(lower=fit_lower upper=fit_upper))*/
/*			holdout (rename=( lower=holdout_lower upper=holdout_upper))*/
/*			fcst (rename=( lower=fcst_lower upper=fcst_upper));*/
/*	run;*/
/*	proc sort data=finalfor; by staydate;*/
	ods html;
	data _null_ ;
		set outfor;
			file print ods=( template='mygraphs.stcfor' 
				objectlabel='Forecast Plot');
			put _ods_;
	run;
	ods html close;
endrsubmit;
