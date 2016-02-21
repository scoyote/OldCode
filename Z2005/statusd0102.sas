 options missing=0;
 proc transpose
 	data=r140p.reportdata
 	out=treportdata(drop=_name_ _label_);
 	by state county;
 	id status;
 	var count;
 run;
 data treportdata;
 	array counttemp {0,0};
 	set treportdata;
 	D01=sum(D01,0);
 	D02=sum(D02,0);
 	counttemp(1)+d01;
 	counttemp(2)+d02;
 	rename D01=COUNT1;
 	rename D02=COUNT2;
 run;
*************************************************;
*************************************************;
**** PROGRAM: D01D02CreateReportData.sas        *;
**** PURPOSE: TO GENERATE DATA FOR D01D02       *;
**** CREATED: January 13, 2010 Sam Croker       *;
*************************************************;
*************************************************;
/*
%let detail=;
options  &detail.mprint &detail.mlogic &detail.symbolgen &detail.source &detail.source2;
proc printto log=_webout; run;
*/


%let SAVE_SELECTED_YYYYMM=04jan2010;


data _null_;
	a = intnx('month',"&SAVE_SELECTED_YYYYMM"d,-1);
	b = intnx('month',"&SAVE_SELECTED_YYYYMM"d,0)-1;
	call symput('obsperiod', put(a,worddate.) || ' - ' || put(b,worddate.)) ;
	call symput('update_dt',compress("'"||put("&SAVE_SELECTED_YYYYMM"d,mmddyy10.)||"'"));
	call symput('startdate',compress("'"||put(a,mmddyy10.)||"'"));
	call symput('enddate'  ,compress("'"||put(b,mmddyy10.)||"'"));
run;
%let REPMSG=Obeservational Site Visits During the Period of &OBSPERIOD;


%let selectstmt20=
         select
               prv_no
              ,lctn_no
              ,sts_cd
              ,sts_r_cd
              ,sts_dt
           from adhoc.t20
          where update_dt=&update_dt
            and sts_cd ='D'
	     and sts_dt >= &startdate
	     and sts_dt <= &enddate
         ;
%let selectstmt13=
    select
      e_prv_no
     ,prv_no
     ,lctn_no
     ,sts_cd
     ,rec_beg
    from adhoc.t13
     where     e_no_typ='98'
           and sts_cd='A'
           and void_ind='N'
           and rec_trm='01/01/9901'
           and update_dt=&update_dt
;

%let selectstmt31=
    select
      prv_no
     ,lctn_no
     ,p_l3_adr
     ,p_l4_adr
     ,p_l5_adr
     ,cty_adr
     ,state
     ,substr(zip,1,5) as zip
    from adhoc.t31
    where
          adr_typ='01'
      and lctn_no not in (0)
      and svs_ind='N'
      and par_trm='01/01/9901'
      and update_dt=&update_dt
;
/*
%let selectstmtx1=
    select
      b.e_prv_no
     ,b.prv_no
     ,b.lctn_no
     ,b.rec_beg
     ,a.sts_cd
     ,a.sts_r_cd
     ,a.sts_dt
     ,c.p_l3_adr
     ,c.p_l4_adr
     ,c.p_l5_adr
     ,c.cty_adr
     ,c.state
     ,c.zip
     ,d.county
      from  session.&user_id._x20 a
     left join
        session.&user_id._x13 b
        on  a.prv_no=b.prv_no
        and a.lctn_no=b.lctn_no
     left join
        session.&user_id._x31 c
        on  a.prv_no=c.prv_no
        and a.lctn_no=c.lctn_no
     left join
        adhoc.desc_zipcode d
        on  substr(c.zip,1,5)=d.zip_cd
     ;*/

%let selectstmtx=
    select
	 c.state
	,d.county
       ,concat(a.sts_cd,a.sts_r_cd) as status
      ,count(*) as count
      from ( session.&user_id._x20 a
     left join
        session.&user_id._x13 b
        on  a.prv_no=b.prv_no
        and a.lctn_no=b.lctn_no
     left join
        session.&user_id._x31 c
        on  a.prv_no=c.prv_no
        and a.lctn_no=c.lctn_no
     left join
        adhoc.desc_zipcode d
        on  substr(c.zip,1,5)=d.zip_cd)
     group by
	 c.state
	,d.county
	,concat(a.sts_cd,a.sts_r_cd)
	order by
	 c.state
	,d.county
	,concat(a.sts_cd,a.sts_r_cd)
     ;

proc sql noprint;
    connect to db2 (db=msad schema=adhoc user=&user_id using=&password);


    execute(
         declare global temporary table session.&user_id._x20
         as(
            &selectstmt20
         ) definition only
         on commit preserve rows
         not logged
         with replace
         in userbig_temp
    ) by db2;
    execute(
         insert into session.&user_id._x20
              &selectstmt20
    ) by db2;

    execute(
         declare global temporary table session.&user_id._x13
         as(
            &selectstmt13
         ) definition only
         on commit preserve rows
         not logged
         with replace
         in userbig_temp
    ) by db2;
    execute(
         insert into session.&user_id._x13
              &selectstmt13
    ) by db2;

    execute(
         declare global temporary table session.&user_id._x31
         as(
            &selectstmt31
         ) definition only
         on commit preserve rows
         not logged
         with replace
         in userbig_temp
    ) by db2;
    execute(
         insert into session.&user_id._x31
              &selectstmt31
    ) by db2;
	create table reportdata as
	select * from connection to db2 (&selectstmtx);
    disconnect from db2;
	
quit;


options missing=0;
proc transpose
	data=reportdata
	out=treportdata(drop=_name_ _label_);
	by state county;
	id status;
	var count;
run;

data treportdata;
	array counttemp{2}  _temporary_  (0,0);
	set treportdata end=eof;
	D01=sum(D01,0);
	D02=sum(D02,0);
	counttemp(1)+d01;
	counttemp(2)+d02;
	rename D01=COUNT1;
	rename D02=COUNT2;
 output;
if eof then do;
    state='';
    county='Total';
    d01=counttemp(1);
    d02=counttemp(2);
    output;
end;

run;
proc print; run;
   /*
proc sql;
    create table FREPORTDATA as
	select STATE, COUNTY, COUNT1 , COUNT2
		from WORK.tREPORTDATA;
drop table reportdata;
drop table treportdata;

quit;
     */
