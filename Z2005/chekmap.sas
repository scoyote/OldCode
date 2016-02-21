PROC IMPORT OUT= WORK.sacu02 
            DATAFILE= "N:\MSAD\CAS\adhoc\SACU Intelligence Maps 3rd Quarter 2009\sacu09102602.xls" 
            DBMS=EXCEL REPLACE;
     SHEET="'SACU-091026-02$'"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

PROC IMPORT OUT= WORK.sacu03a 
            DATAFILE= "N:\MSAD\CAS\adhoc\SACU Intelligence Maps 3rd Quarter 2009\sacu09102603a.xls" 
            DBMS=EXCEL REPLACE;
     SHEET="'SACU-091026-03a$'"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;


data sacu2_region;
	length jurisq1 jurisq2 $1.;
	set sacu02;
	if state_abbr__ in ('DC','MD','DE','NJ','CT','RI','MA','ME','NH','VT','NY','PA')
	then jurisq1='A';
	if state_abbr__ in ('DC','MD','DE','NJ','CT','RI','MA','ME','NH','VT','NY','PA')
	then jurisq2='A';
	if state_abbr__ in ('KY','OH','IN','IL','MI','WI','MN')
	then jurisq1='B';
	if state_abbr__ in ('KY','OH','IN','IL','MI','WI','MN')
	then jurisq2='B';
	if state_abbr__ in ('NC','SC','GA','FL','AL','TN','MS','LA','AR','OK','TX','CO','NM','PR','VI','VA','WV')
	then jurisq1='C';
	if state_abbr__ in ('NC','SC','GA','FL','AL','TN','MS','LA','AR','OK','TX','CO','NM','PR','VI','VA','WV')
	then jurisq2='C';
	if state_abbr__ in ('AS','GU','MP','WA','OR','CA','ID','NV','MT','WY','ND','SD','NE','KS','MO','IA','AK','HI','UT','AZ')
	then jurisq1='D';
	if state_abbr__ in ('AS','GU','MP','WA','OR','CA','ID','NV','MT','WY','ND','SD','NE','KS','MO','IA','AK','HI','UT','AZ')
	then jurisq2='D';
run;


proc means data=sacu02 noprint nway;
	class STATE_NAME_ county_name_;
	output out=sacu_county sum(_009q2_)=q2Total sum(_009q3)=Q3Total;
	where state_abbr__ in ('NJ');*,'CA','TX','FL','NY');
run;

proc sort data=sacu_county out=counties;
	by state_name_ descending q3total;	
run;
proc print data=counties;
	var state_name_ county_name_ q3total ;
run;




proc means data=sacu2_region noprint;
	class state_name_  jurisq1 jurisq2;
	output out=sacu_summary sum(_009q2_)=q2Total sum(_009q3)=Q3Total;
run;

data sacu_summary; set sacu_summary;
	diff=q3total-q2total;
run;
proc sort data=sacu_summary out=states;
	by descending q3total;	
	where missing(jurisq1) and missing(jurisq2);
run;
proc print data=states;
	var state_name_ q2total q3total diff;
run;







proc print data=sacu_summary;
	var jurisq1 jurisq2 q2total q3total diff;
	where ~missing(jurisq1) or ~missing(jurisq2);
run;



data sacu03a;set sacu03a;
	length stfips 8;
	stfips=state_fips_;
run;
proc sql;
	create table stateabr as select 
		distinct state_name_ as start
		, fipstate(stfips) as label 
		,'c' as type
		,'stcd' as fmtname
		from sacu03a where ~missing(stfips);
quit;
proc format cntlin=stateabr; run;
data sacu03a;set sacu03a;
	length stfips 8;
	stateabr=put(state_name_,$stcd.);
run;
data sacu3_region;
	length jurisq1 jurisq2 $1.;
	set sacu03a;
	if stateabr in ('DC','MD','DE','NJ','CT','RI','MA','ME','NH','VT','NY','PA')
	then jurisq1='A';
	if stateabr in ('DC','MD','DE','NJ','CT','RI','MA','ME','NH','VT','NY','PA')
	then jurisq2='A';
	if stateabr in ('KY','OH','IN','IL','MI','WI','MN')
	then jurisq1='B';
	if stateabr in ('KY','OH','IN','IL','MI','WI','MN')
	then jurisq2='B';
	if stateabr in ('NC','SC','GA','FL','AL','TN','MS','LA','AR','OK','TX','CO','NM','PR','VI','VA','WV')
	then jurisq1='C';
	if stateabr in ('NC','SC','GA','FL','AL','TN','MS','LA','AR','OK','TX','CO','NM','PR','VI','VA','WV')
	then jurisq2='C';
	if stateabr in ('AS','GU','MP','WA','OR','CA','ID','NV','MT','WY','ND','SD','NE','KS','MO','IA','AK','HI','UT','AZ')
	then jurisq1='D';
	if stateabr in ('AS','GU','MP','WA','OR','CA','ID','NV','MT','WY','ND','SD','NE','KS','MO','IA','AK','HI','UT','AZ')
	then jurisq2='D';
run;


proc means data=sacu3_region noprint;
	class state_name_ jurisq1 jurisq2;
	output out=sacu_summary sum(_009q2_)=q2Total sum(_009q3)=Q3Total;
	types state_name_  jurisq1 jurisq2 ;
run;
data sacu_summary; set sacu_summary;
	diff=q3total-q2total;
run;
proc sort data=sacu_summary out=state;
	by descending q3total;
		where missing(jurisq1) and missing(jurisq2);
run;
proc print data=state;
	var state_name_ q2total q3total diff;

run;

proc print data=sacu_summary;
	var jurisq1 jurisq2 q2total q3total diff;
	where ~missing(jurisq1) or ~missing(jurisq2);
run;





proc means data=sacu03a noprint nway;
	class STATEabr county_name_;
	output out=sacu_county sum(_009q2_)=q2Total sum(_009q3)=Q3Total;
	where stateabr in ('TX','FL','NJ','CA','NY');
run;

proc sort data=sacu_county out=counties;
	by stateabr descending q3total;	
run;
proc print data=counties;
	var stateabr county_name_ q3total ;
	where q3total>0 and stateabr='NJ';
run;
