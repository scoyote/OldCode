
/**********************************************************************
 *   PRODUCT:   SAS
 *   VERSION:   8.2
 *   CREATOR:   SAMUEL T. CROKER
 *   DATE:      07DEC05
 *   DESC:
 ***********************************************************************/
LIBNAME RMDB2 DB2 DATABASE=MSAD USER=&USERNAME PASSWORD=&PASSWORD SCHEMA=ADHOC;
LIBNAME RMWORK "//saswork/rx16n/RM";

libname intrnet "//histest/sasintrnet/data/beta/dashboard";

%macro plotautoreg(
      ds             /* the data - sas dataset */
      ,grpbyvar      /* the grouping unit (hcpcs, prov_id etc... - must be singular - build datasets this way */
      ,graphprefix   /* prefix for graph name */
      ,var           /* the analysis variable - must be singular */
      ,log=0         /* 0 = do not transform, 1 = take natural log transform before processing */
      ,lag=1         /* how many time units to forecast.  keep in mind that the most current day is always included in the forecast period */
      ,fclag=1       /* number of time units to hold out from the model estimation for comparison with predictions*/
      ,plotback=30   /* number of days to plot prior to end */
      );

   options msglevel=n nosource nonotes;
   proc format;
      picture  plotdate low-high='%a %d ' (datatype=date);
   run;

   /* Adjust the sadmerc_receipt_dt into a SASDATE */
   data working; set &ds;
      /*get rid of special characters in miscoded hcpcs codes */
      &grpbyvar=compress(compress(&grpbyvar,'"&%'),"'");
      date=sadmerc_receipt_dt;
   run;
   proc sql noprint; select &grpbyvar into :var1 from working; quit;
   %put Analyzing &grpbyvar =&var1 variable=&var ;


   proc sql noprint; select count(*), max(date),min(date) into :ct,:maxdt,:mindt from working ; quit;
   %let ct=&ct;
      %let maxdt=&maxdt;
      %let mindt=&mindt;

      /* Fill in missing dates */
      /* build table of possible dates */
      data days;
         do i=&mindt to %eval(&maxdt+&lag) by 1;
            date=i;
            if weekday(i) ~in (1,7) then output;
         end;
      run;
      /* merge the possible to the existing leaving missing values for proc autoreg to estimate */
      proc sort data=working; by date; run;
      proc sort data=days; by date; run;
      data specific; merge days (in=y1) working (in=y2);
        by date;
        if y1;
        if intervention~=. then do a=intervention; retain a;  end;
        if intervention=. then intervention=a;
        if date >= %eval(&maxdt-&fclag) then do; holdval=&var; &var=.; intervention=2; end;
      run;

      %logtest(&ds,&var);
      %if &logtest=LOG %then %put A log transform will be computed based upon the results of the LOGTEST macro;
      options msglevel=n nosource nonotes;

      data specific; set specific;
        %if &logtest=LOG %then %do;
           if &var~=0 and &var~=. then &var=log(&var);
           if holdval~=0 and holdval~=. then holdval=log(holdval);
        %end;
      run;
      /* Conduct the autoregression analysis */
      proc autoreg data=specific outest=testoutest covout;
         mdl1: model &var=date  /nlag=12 backstep method=ml noprint ;
         output out=out p=forecast pm=structfc lcl=lcl ucl=ucl lclm=lclm uclm=uclm alphacli=.1 residual=residual;
      run;
      data out; merge out specific(keep=date intervention);
      run;

      /* rebuild the output data so that the cis plot as polygons */
      data out(  drop=     sval0 sval1 sval2)
           low0( keep=date sval0 sval1 sval2)
           high0(keep=date sval0 sval1 sval2)
           low1( keep=date sval0 sval1 sval2)
           high1(keep=date sval0 sval1 sval2)
           low2( keep=date sval0 sval1 sval2)
           high2(keep=date sval0 sval1 sval2);
        set out;
         /* pull out the predicted values to be compared with the predictions */
         if residual=. and intervention < 2 then Act_var=forecast;
         if residual=. and intervention = 2 then &var=holdval;
         output out;
         if intervention=0 then do; sval0=lcl; output low0; sval0=ucl; output high0; end;
         if intervention=1 then do; sval1=lcl; output low1; sval1=ucl; output high1; end;
         if intervention=2 then do; sval2=lcl; output low2; sval2=ucl; output high2; end;
      run;

      proc sort data=low0; by descending date; run;
      proc sort data=low1; by descending date; run;
      proc sort data=low2; by descending date; run;

      data forecast; set low2 high2 low1 high1 low0 high0 out; if date=. then delete; run;

      /* plot the forecasts */
         %let forecaststart=%eval(&maxdt-&plotback);
         %let forecastend=%eval(&maxdt+&lag);
         %let fcref=%eval(&maxdt-&fclag);
         proc gplot data=forecast gout=work.gseg;
            goptions reset=all ftext="SWISS" htitle=2 cback=white nodisplay device=jpeg ;
            symbol1 i=ms                                 c=bwh    co=libgr;
            symbol2 i=ms                                 c=gwh    co=libgr;
            symbol3 i=ms                                 c=pkwh   co=libgr;
            symbol4 i=none    v=dot          h=1   w=2   c=degb;
            symbol5 i=j       v=none   l=1   h=2   w=1.5 c=vigb;
            symbol7 i=none    v=circle       h=1         c=red;
            symbol6 i=j       v=none   l=3               c=vlipb;

            %let a=; %let order=;
            %do dt=&forecaststart %to &forecastend;
               %let dayval= %sysfunc(weekday(%eval(&dt)));
               %if %sysfunc(weekday(%eval(&fcref)))=1 %then %let fcref=%eval(&fcref+1);
               %if %sysfunc(weekday(%eval(&fcref)))=7 %then %let fcref=%eval(&fcref+2);
               %if &dayval > 1 %then %if &dayval < 7 %then %do;
                   %let order=&a &dt; %let a=&order;
               %end;
            %end;
            title "%upcase(&var)";
            axis1 label=none value=(f='SWISS' h=1.5 angle=90 rotate=0) minor=none order=(&order) ;
            axis2 label=none value=(h=2);
            where date between &forecaststart and &forecastend;
            plot sval0*date=1 sval1*date=2 sval2*date=3 &var*date=4 forecast*date=5 structfc*date=6 act_var*date=7
                 / name="&graphprefix.&var1" des="Forecast for &var where &grpbyvar=&var1 "
                   grid  haxis=axis1 vaxis=axis2 overlay href=&fcref chref=palg;
            format date plotdate. ;
         run; quit;

         proc sql noprint;
           create table monthly as
             select
                sum(&var) as sum,
                mdy(month(sadmerc_receipt_dt),1,year(sadmerc_receipt_dt)) as date
                from &ds group by date;
           select min(date), max(date), max(sum) into :mindt, :maxdt, :maxdata from monthly;
         quit;

         %let maxdata=%sysevalf(&maxdata+&maxdata*.05);
         %let plotint=%sysfunc(round(%sysevalf(&maxdata/15),10));

         proc gplot data=monthly gout=work.gseg;
            goptions reset=all ftext="SWISS" cback=white nodisplay device=jpeg;
            symbol1 i=j    v=dot          h=1  w=2   c=stgb;

            axis1 label=none value=(f='SWISS' h=1 angle=90 rotate=0)
                        order=(&mindt to &maxdt by month) minor=none ;
            axis2 label=none order=(0 to &maxdata by &plotint);
            title "%upcase(&var)";
            plot sum*date
                 / name="M&graphprefix&var1" des="Monthly Profile for &var where &grpbyvar=&var1 "
                   grid  haxis=axis1 vaxis=axis2 overlay href=&fcref chref=palg;
            format date mmddyy10. ;
         run; quit;
         %put Forecasting done.; %put;
   options msglevel=n source notes;
%mend plotautoreg;


%macro prepdata(hcpcscd);
options nosource nonotes;
data old; set rmwork.historical_daily;
      where hcpcs="&hcpcscd" and sadmerc_receipt_dt<'01dec2005'd;
      intervention=0;
      run;

data new; set rmwork.recent_daily;
      where hcpcs="&hcpcscd" and sadmerc_receipt_dt>='01dec2005'd;
      intervention=1;
      run;
data agg&hcpcscd;
set old new;
run;
options source notes;
%mend prepdata;

%macro plotchoro(hcpcs,month);
   proc sql;
      create table sum_mrd_sthc as
        select input(fips_cd,8.) as state, b.state_cd, dmerc_region, hcpcs_cd, hicn_dcnt, clm_dcnt,submit_amt_tot,allow_amt_tot
             from rmdb2.desc_state as a left join (
             select  state_cd, hcpcs_cd, clm_dcnt,submit_amt_tot,allow_amt_tot,hicn_dcnt
             from rmdb2.sum_mrd_sthc
             where hcpcs_cd="&hcpcs"
             and rec_year_month=&month) as b
         on a.state_cd=b.state_cd;
     quit;
  run;

  goptions reset=global;
  goptions gunit=pct cback=white htitle=10 htext=3 nodisplay
  ftext=swissb ctext=black ;
  pattern1 v=s c=bwh;
  pattern2 v=s c=gwh;
  pattern3 v=s c=ywh;
  pattern4 v=s c=yellow;
  pattern5 v=s c=orange;
  pattern6 v=s c=red;

   proc gmap all map=rmwork.us data=sum_mrd_sthc ;
    id state;
    title DCN Count;
    choro clm_dcnt       /nolegend name="mpa" des="ChoroPlot of hcpcs=&hcpcs for &month";
    run;
    title Allow Amount;
    choro allow_amt_tot  /nolegend name="mpb" des="ChoroPlot of hcpcs=&hcpcs for &month";
    run;
    title Submit Amount;
    choro submit_amt_tot / nolegend name="mpc" des="ChoroPlot of hcpcs=&hcpcs for &month";
    run;
    title HICN Count;
    choro hicn_dcnt       /nolegend name="mpd" des="ChoroPlot of hcpcs=&hcpcs for &month";
    run;
   quit;

%mend plotchoro;

%macro buildtemplate;
     proc greplay tc=tempcat
                     nofs;
               /* define a template */
           tdef sasdash des='six squares of equal size'

                1/LLX=0   LLY=0   LRX=25  LRY=0
                  ULX=0   ULY=25  URX=25  URY=25
                  COLOR=white

                2/LLX=25  LLY=0   LRX=50  LRY=0
                  ULX=25  ULY=25  URX=50  URY=25
                  COLOR=white

                3/LLX=50  LLY=0   LRX=75  LRY=0
                  ULX=50  ULY=25  URX=75  URY=25
                  COLOR=white

                4/LLX=75  LLY=0   LRX=100 LRY=0
                  ULX=75  ULY=25  URX=100 URY=25
                  COLOR=white


                5/LLX=0   LLY=25  LRX=50  LRY=25
                  ULX=0   ULY=63  URX=50  URY=63
                  COLOR=white

                6/LLX=50  LLY=25  LRX=100  LRY=25
                  ULX=50  ULY=63  URX=100  URY=63
                  COLOR=white

                7/LLX=0   LLY=63  LRX=50   LRY=63
                  ULX=0   ULY=100 URX=50   URY=100
                  COLOR=white

                8/LLX=50  LLY=63  LRX=100  LRY=63
                  ULX=50  ULY=100 URX=100  URY=100
                  COLOR=white
               ;
                /* assign current template */
           template sasdash;
               /* list contents of current template */
        quit;
%mend buildtemplate;


%macro Runsingle(hcpcs);
   %buildtemplate;
   %prepdata(&hcpcs);
   %Plotautoreg(AGG&hcpcs,hcpcs,A,count_dcn,lag=7,fclag=5,plotback=30);
   %Plotautoreg(AGG&hcpcs,hcpcs,B,count_hicn,lag=7,fclag=5,plotback=30);
   %Plotautoreg(AGG&hcpcs,hcpcs,C,sum_allow_amt,lag=7,fclag=5,plotback=30);
   %Plotautoreg(AGG&hcpcs,hcpcs,D,sum_submit_amt,lag=7,fclag=5,plotback=30);
   %plotchoro(&hcpcs,200511);
   %if %sysfunc(cexist(intrnet.dashgraph.DS&hcpcs..grseg)) %then %do;
     proc catalog catalog=intrnet.dashgraph;  delete DS&hcpcs..grseg; run; quit;
   %end;
     proc greplay igout=work.gseg gout=intrnet.dashgraph tc=tempcat nofs ;
      template=sasdash;
      treplay  1:mpa 2:mpb 3:mpc 4:mpd 5:a&hcpcs 6:b&hcpcs 7:d&hcpcs 8:c&hcpcs;
      run; quit;
     proc greplay igout=intrnet.dashgraph nofs;
        modify template/ name="DS&hcpcs" des="DASHBOARD hcpcs=&hcpcs";
     run; quit;
     %looper:
     options notes source;
%mend runsingle;
%runsingle(A6233);



proc catalog catalog=work.gseg kill;run;quit;
proc datasets library=work kill;    run;quit;
proc datasets library=work force kill; run;  quit;
