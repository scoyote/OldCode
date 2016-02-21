libname tmp 'N:\MSAD\CAS\std_nsc\RPTQTFLI';
proc format;
	value $fli "S" = "Medium Risk"
			   "T" = "High Risk  ";
run;
proc means data=tmp.qtrfli_20093 nway noprint;
	class state code;
	output out=pstates n=count;
	where code in ("S","T");
	format code $fli.;
run; quit;
proc transpose data=pstates out=states(drop=_name_);
	by state;
	id code;
	var _freq_;
run;
data states;
	set states;
	total=sum(medium_risk,high_risk);
	stnamex=stname(state);
run;
options orientation=portrait ps=80;
proc sort data=states;
	by descending total high_risk medium_risk;

run;
proc print; run;



proc means data=tmp.qtrfli_20093 nway noprint;
	class state county code;
	output out=pcounties n=count;
	where code in ("S","T") AND state in ('CA','MI','FL','TX','NY');
	format code $fli.;
run; quit;
proc transpose data=pcounties out=counties (drop=_name_);
	by state county;
	id code;
	var _freq_;
run;

data counties;
	merge counties;
	total=sum(medium_risk,high_risk);
	stnamex=stname(state);
run;
PROC IMPORT OUT= WORK.nationalfips 
            DATAFILE= "D:\My Documents\demodata\nationalfips.txt" 
            DBMS=DLM REPLACE;
     DELIMITER='2C'x; 
     GETNAMES=YES;
     DATAROW=2; 
RUN;
options source notes;
data centroid;
	set maps.uscounty;
	by state county;
	if first.county;
run;
proc sql noprint;
	create table ordcounty as
		select a.*
				, round(c.x,.01) as xc
				, round(c.y,.001) as yc
			from counties a
			left join nationalfips b 
				on a.state=b.state 
				and a.county=b.county
			left join centroid c
				on b.fips=c.state and b.code=c.county
		where ~missing(a.county)
		order by state, xc, yc
		;
quit;


proc print; 
	by state;
	where state='TX';
run;

