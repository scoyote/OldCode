
options mstored sasmstore=sf;
%macro loadsites /store;
     options nonotes;
     filename riverf url 'http://waterdata.usgs.gov/sc/nwis/current?index_pmcode_STATION_NM=1&index_pmcode_DATETIME=2&index_pmcode_00065=3&index_pmcode_00060=4&index_pmcode_MEAN=&index_pmcode_MEDIAN=&index_pmcode_00010=&sort_key=site_no&group_key=NONE&format=sitefile_output&sitefile_output_format=rdb&column_name=agency_cd&column_name=site_no&column_name=station_nm&sort_key_2=site_no&html_table_group_key=NONE&rdb_compression=file&survey_email_address=&list_of_search_criteria=realtime_parameter_selection';
     %put Loading Site File from USGS;
     data sites;
          length agency $4 siteno $30 sitename $100;
          infile riverf lrecl=255 dlm='09'x truncover;
          input agency $ Siteno $ SiteName $char100.;
          if agency~='USGS' then delete;
     run;
      proc sql; 
          select count(*) into :numsites from sites;%let numsites=&numsites;
          select siteno into :siteno1-:siteno&numsites from sites;
     quit;
     %put &numsites Sites will be processed.;
     %do i=1 %to &numsites;
          %put Processing #&i of &numsites: &&siteno&i;
          %loadriverdata_vars(&&siteno&i);
          %if &i=1 %then %do;
               proc sql;
                    create table fullsites as select * from lines;
               quit;
          %end;
          %else %do;
               data fullsites; 
                    set fullsites lines; 
               run;
          %end;
     %end;/*end numsites loop*/
     %put Finished;
     title List of Parameter Descriptions;
     proc freq data=sf.fullsites;
          table description /nocol norow nopercent;
     run;
     options notes;
%mend;
%macro loadriverdata_vars(siteno,fslist=NO);
     %let filename=http://waterdata.usgs.gov/sc/nwis/uv?dd_cd=01%nrstr(&)format=rdb%nrstr(&)period=7%nrstr(&)site_no=&SITENO;

     *ods html file=_webout;
     filename river url "&filename";
     %if &fslist=YES %then %do;
          proc fslist file=river; run;
     %end;

     data lines (drop=startflag) ;
          length site_no $30;
          if _n_=1 then startflag=0;
               length dd $2 parameter $5 description $100 site_no $30;
               infile river truncover lrecl=255 end=eof;
               if startflag=0 then do;
                    input;
               end;
               site_no="&siteno";
               if _infile_="#  DD parameter - Description" then startflag=1;
               retain startflag;
               if startflag=1 then do;
                    input @4 dd @9 parameter @19 description $char100.;
                    if missing(dd) then stop;
                    if dd="--" then delete;
                    else numv+1;
                    output;
               end;
            
          run;
     *ods html close;
%mend loadriverdata_vars;
%loadriverdata_vars(02175000,fslist=YES);
%macro loadriverdata(river, period, siteno,stageparam,flowparam,expandfrom=dtminute15,undup=Y) /store;
     %global startdate&river;
     %global enddate&river;
     %let filename=%nrstr(http://waterdata.usgs.gov/sc/nwis/uv?dd_cd=)&stageparam%nrstr(&dd_cd=)&flowparam%nrstr(&format=rdb&period=)&period%nrstr(&site_no=)&siteno;

   /*  %if river=greenwood %then 
          %let filename=%nrstr(http://waterdata.usgs.gov/sc/nwis/uv?dd_cd=04&dd_cd=17&format=rdb&period=)&period%nrstr(&site_no=02166501);
     %if river=saluda %then
          %let filename=%nrstr(http://waterdata.usgs.gov/sc/nwis/uv?dd_cd=03&dd_cd=04&format=rdb&period=)&period%nrstr(&site_no=02168504);
     %if river=broad %then
          %let filename=%nrstr(http://waterdata.usgs.gov/sc/nwis/uv?dd_cd=01&dd_cd=02&format=rdb&period=)&period%nrstr(&site_no=02161000);
     %if river=congaree %then
          %let filename=%nrstr(http://waterdata.usgs.gov/sc/nwis/uv?dd_cd=01&dd_cd=02&format=rdb&period=)&period%nrstr(&site_no=02169500);
     %if river=bush %then
          %let filename=%nrstr(http://waterdata.usgs.gov/sc/nwis/uv?dd_cd=01&dd_cd=02&format=rdb&period=)&period%nrstr(&site_no=02167582);
*/
     %put NOTE: filename=&filename;
     filename &river url "&filename";
     data &river;
          infile &river truncover dlm='09'x dsd end=eof1 ;
          informat datetimef $char16.;
          format dat mmddyy10. dtm datetime18.;
          input header $char80.@;
          if substr(header,1,7)="#  USGS" then do;
               call symput("LABEL",substr(header,18,60));
          end;
          input @1 agency $4. @;
          if agency ~= "USGS" then delete;
          
          n+1;
          input source $ siteno $ datetimef $ stage flow;
          substr(datetimef,11,1)='/';
          yr=substr(datetimef,1,4);
          mo=substr(datetimef,6,2);
          dy=substr(datetimef,9,2);
          hr=substr(datetimef,12,2);
          mn=substr(datetimef,15,2);
          dat=mdy(mo,dy,yr);
          dtm=dhms(dat,hr,mn,0);
          lflow=log(flow);          
          if minute=mn or abs(minute-mn)=1 or mn+1=60 then dupflag=1;else dupflag=0; 
          minute=mn;
          obsperiod=(dtm-dtm2)/60;
          dtm2=dtm;
          retain minute dtm2;

          keep dtm stage flow lflow dupflag obsperiod;
          call symput("flow",compress("FLOW_"||siteno));
          call symput("lflow",compress("LFLOW_"||siteno));
          call symput("stage",compress("STAGE_"||siteno));
          label dtm="Date/Time";
          if n=1 then call symput("startdate&river",put(dtm,datetime18.));
          if eof1 then call symput("enddate&river",put(dtm,datetime18.));
     run;
     %if %upcase(&undup)=Y %then %do;
          data &river(drop=dupflag); set &river;    
                              
               if minute(dtm) in (14,29,44,59) then do;
                     dtm=intnx('minute',dtm,1);
               end;
               where dupflag=0;
          run;
     %end;
     %put NOTE: *********** Macro Variables Created ***********;
     %put NOTE: Flow          =flow;
     %put NOTE: Logged Flow   =lflow;
     %put NOTE: Stage         =stage;
     %put NOTE: Startdate     =&&startdate&river;
     %put NOTE: Enddate       =&&enddate&river;
     %put NOTE: ***********************************************;
     proc expand data=&river out=&River from=&expandfrom ;
          id dtm;
          convert stage=estage flow=eflow /observed=beginning;
     run;
     data &river; set &river;
          if stage~=estage then extrapolated='Y';
          else extrapolated='N';
          rename eflow=&flow;
          rename estage=&stage;
          label eflow="&label";
          label estage="&label";
     run;
%mend loadriverdata;


%macro buildtemplate(preview=NO) /store;
     proc greplay tc=tempcat
                     nofs;
               /* define a template */
           %if %upcase(&preview)=YES %then %let linecolor=BLACK;
           %else %let linecolor=WHITE;
           tdef e8panel des='six squares of equal size'

                1/LLX=0   LLY=0   LRX=50  LRY=0
                  ULX=0   ULY=25  URX=50  URY=25
                  COLOR=&linecolor

                2/LLX=50  LLY=0   LRX=100  LRY=0
                  ULX=50  ULY=25  URX=100  URY=25
                  COLOR=&linecolor

                3/LLX=0   LLY=25  LRX=50  LRY=25
                  ULX=0   ULY=50  URX=50  URY=50
                  COLOR=&linecolor

                4/LLX=50  LLY=25  LRX=100  LRY=25
                  ULX=50  ULY=50  URX=100  URY=50
                  COLOR=&linecolor

                5/LLX=0   LLY=50  LRX=50   LRY=50
                  ULX=0   ULY=75 URX=50   URY=75
                  COLOR=&linecolor

                6/LLX=50  LLY=50  LRX=100  LRY=50
                  ULX=50  ULY=75  URX=100  URY=75
                  COLOR=&linecolor

                7/LLX=0   LLY=75  LRX=50   LRY=75
                  ULX=0   ULY=100 URX=50   URY=100
                  COLOR=&linecolor

                8/LLX=50  LLY=75  LRX=100  LRY=75
                  ULX=50  ULY=100 URX=100  URY=100
                  COLOR=&linecolor
               ;
                /* assign current template */
           template e8panel;
               /* list contents of current template */
           %if %upcase(&preview)=YES %then %do;
               preview e8panel;
          %end;
        quit;
%mend buildtemplate;

/*

/ Program   : globlist
/ Version   : 1.0
/ Author    : Roland Rashleigh-Berry
/ Date      : 30 August 2003
/ Contact   : rolandberry@hotmail.com
/ Purpose   : To return a list of current global macro variable names
/ SubMacros : none
/ Notes     : All global macro variable names will be in uppercase.
/ Usage     : %let glist=%globlist;
/ 
/================================================================================
/ PARAMETERS:
/-------name------- -------------------------description-------------------------
/ N/A
/================================================================================
/ AMENDMENT HISTORY:
/ init --date-- mod-id ----------------------description-------------------------
/ 
/================================================================================
/ This is public domain software. No guarantee as to suitability or accuracy is
/ given or implied. User uses this code entirely at their own risk.
/===============================================================================*/

%macro globlist /store;

%local dsid rc scope scopenum namenum globflag globlist;
%let globflag=0;


%let dsid=%sysfunc(open(sashelp.vmacro,is));
%if &dsid EQ 0 %then %do;
  %put ERROR: (globlist) sashelp.vmacro not opened due to the following reason:;
  %put %sysfunc(sysmsg());
  %goto error;
%end;
%else %do;
  %let scopenum=%sysfunc(varnum(&dsid,scope));
  %let namenum=%sysfunc(varnum(&dsid,name));
%end;

%readloop:
  %let rc=%sysfunc(fetch(&dsid));
  %if &rc %then %goto endoff;
  %let scope=%sysfunc(getvarc(&dsid,&scopenum));
  %if "&scope" NE "GLOBAL" and &globflag %then %goto endoff;
  %else %if "&scope" EQ "GLOBAL" and not &globflag %then %let globflag=1;
  %if &globflag %then %let globlist=&globlist %sysfunc(getvarc(&dsid,&namenum));
%goto readloop;


%endoff:
&globlist
%let rc=%sysfunc(close(&dsid));


%goto skip;
%error:
%put ERROR: (globlist) Leaving globlist macro due to error(s) listed;
%skip:
%mend;

%macro annotatedays(ds,xvar,fs,fe) /store;
 data DayLines; set &ds(keep=dtm );
          length color function $8 text $14;
          retain xsys '2' ysys '1' when 'a';
          k=%eval(&forecastend-&forecaststart);
          where &xvar between &fs and &fe;
          if hour(dtm)=0 and minute(dtm)=0 then do;
               wdate=put(datepart(dtm),worddatx12.);
               function='move'; x=dtm; y=0; output;
               function='draw'; x=dtm; y=100; color='lib'; size=1; output;
               function='label'; x=dtm; y=5; size=1; position='2';angle=90;color='black'; text=wdate; output;
          end;
     run;
%mend annotatedays;

