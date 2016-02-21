
/* build the url for the sites file - I don't like this part */
%let a0=http://waterdata.usgs.gov/sc/nwis/current?;
%let a1=index_pmcode_STATION_NM=1%nrstr(&)index_pmcode_DATETIME=%nrstr(&)index_pmcode_72019=%nrstr(&)index_pmcode_72020=%nrstr(&)index_pmcode_00062=;
%let a2=%nrstr(&)index_pmcode_00065=2%nrstr(&)index_pmcode_MEAN=%nrstr(&)index_pmcode_MEDIAN=%nrstr(&)index_pmcode_00055=%nrstr(&)index_pmcode_00060=3;
%let a3=%nrstr(&)index_pmcode_62361=%nrstr(&)index_pmcode_00301=4%nrstr(&)index_pmcode_00300=5%nrstr(&)index_pmcode_00096=%nrstr(&)index_pmcode_00480=;
%let a4=%nrstr(&)index_pmcode_00095=%nrstr(&)index_pmcode_00010=6%nrstr(&)index_pmcode_63680=%nrstr(&)index_pmcode_00076=%nrstr(&)index_pmcode_00400=;
%let a5=%nrstr(&)index_pmcode_00025=14%nrstr(&)index_pmcode_00045=7%nrstr(&)precipitation_interval=precip01h_va%nrstr(&)index_pmcode_00052=13;
%let a6=%nrstr(&)index_pmcode_00020=11%nrstr(&)index_pmcode_00021=12%nrstr(&)index_pmcode_62608=10%nrstr(&)index_pmcode_00036=8%nrstr(&)index_pmcode_00035=9;
%let a7=%nrstr(&)index_pmcode_74207=%nrstr(&)sort_key=site_no%nrstr(&)group_key=NONE%nrstr(&)sitefile_output_format=html_table%nrstr(&)column_name=agency_cd;
%let a8=%nrstr(&)column_name=site_no%nrstr(&)column_name=station_nm%nrstr(&)sort_key_2=site_no%nrstr(&)html_table_group_key=NONE%nrstr(&)format=rdb;
%let a9= %nrstr(&)rdb_compression=value%nrstr(&)list_of_search_criteria=realtime_parameter_selection;
filename sites url "&a0&a1&a2&a3&a4&a5&a6&a7&a8&a9";

/* get the parameters from the parameter list online */
	data parameters;
		filename params url "http://nwis.waterdata.usgs.gov/usa/nwis/pmcodes?pm_group=ALL%nrstr(&)pm_search=%nrstr(&)format=rdb%nrstr(&)show=parameter_cd%nrstr(&)show=parameter_group_nm%nrstr(&)show=parameter_nm";
		infile params dlm='09'x ;
		length parameter_cd $5 parameter_group_nm $26 parameter_nm $176;
		input parameter_cd  @;
		if trim(substr(parameter_cd,1,2)) in ('#','pa','5s') then delete;
		else input parameter_group_nm	?? parameter_nm  ??;
	run;

/* get the sites from the sitelist online */
	data sitelist;
		infile sites dlm='09'x dsd lrecl=500 truncover;
		length agency_cd $5 site_no $15 station_nm $50 dd_nu $2 precip_interval_tx $7 parameter_cd $5 result_dt $19 result_va $12 result_cd $2 result_md $12;
		input agency_cd $ site_no $ station_nm $ dd_nu $  precip_interval_tx $ parameter_cd $ result_dt $ result_va $ result_cd $ result_md $ ;
		file 'sites.txt';
		put _infile_;
		if substr(agency_cd,1,4)~='USGS' then delete;
	run;

	/* put the available parameters with the available sites */
	proc sort data=parameters; by parameter_cd;run;
	proc sort data=sitelist; by parameter_cd;run;
	data siteparams; 
		merge 
			sitelist (in=y1)
			parameters (in=y2);
		by parameter_cd;
		if y1;
	run;
	proc sort data=siteparams;
		by site_no parameter_cd;
	run;
	
/* for each available site, get the available data for the available parameters and store to a dataset */
%macro buildlookupstring(site_no);
	%local i;
	%local paramstring;
	proc sql noprint;
		select count(distinct parameter_cd) into :numparams from siteparams where site_no="&site_no";
		%let numparams=&numparams;
		select parameter_cd, parameter_nm
			into  :pstring1-:pstring&numparams
				,:parnm1-:parnm&numparams
			from siteparams where site_no="&site_no";
	quit;
	%let datalook=http://waterdata.usgs.gov/sc/nwis/uv?;
	%do i=1 %to &numparams;
		%put adding &&pstring&i;
		%let datalook=&datalook.%nrstr(%nrstr(&))cd_&&pstring&i.=on;
	%end;
	%let datalook=%cmpres(&datalook.%nrstr(%nrstr(&))format=rdb%nrstr(%nrstr(&))period=31%nrstr(%nrstr(&))site_no=&site_no);
	filename DATALOOK url "&datalook";
	%put &datalook;
	data station_&site_no;
		infile datalook dlm='09'x dsd;
		length agency_cd $4 site_no $15;
		input agency_cd $ @;
		if agency_cd~='USGS' then delete;
		else do;
			input site_no $ datetime YMDDTTM16.0 fill $1.
			%do i=1 %to &numparams;
					S&site_no._&&pstring&i  S&site_no._&&pstring&i.._cd $
			%end;
			;
		end;
		format datetime datetime19.;
		drop agency_cd fill site_no 
			%do i=1 %to &numparams;
				 S&site_no._&&pstring&i.._cd 
			%end;
		;
		%do i=1 %to &numparams;
			label S&site_no._&&pstring&i="&&parnm&i"; 
		%end;
	run;
%mend;

/* individual station loading */

%buildlookupstring(335358081331900);

%buildlookupstring(02175000);

data edistobasin_part;
	merge station_335358081331900 station_02175000;
	by datetime;
	if missing(S335358081331900_00045) then S335358081331900_00045=0;
run;

