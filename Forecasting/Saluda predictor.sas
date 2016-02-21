options mstored sasmstore=sf;
%symdel %globlist;
proc catalog catalog=work.gseg force kill; run;quit;

proc datasets library=work force kill; run;quit;
proc catalog catalog=work.sasmacr force kill; run; quit;
%let period=5;

%loadriverdata(saluda,&period,02168504,03,04);

%*loadriverdata(broad,&period,02161000,01,02);
*%loadriverdata(congaree,&period,02169500,01,02);
*%loadriverdata(swamp,&period,02169625,02,02);

%loadriverdata(bush,&period,02167582,01,02);
%loadriverdata(salware,&period,02163500,15,16);
%loadriverdata(reedy,&period,02164000,01,02);
*%loadriverdata(lr,&period,02167450,01,11);
*%loadriverdata(rabon,&period,02165200,04,05);
*%loadriverdata(salchap,&period,02167000,02,01);
*%loadriverdata(usaluda,&period,02166501,04,17);


*%loadriverdata(ediden,&period,02173000,05,15,expandfrom=dthour,undup=N);
*%loadriverdata(ediora,&period,02173500,01,02,expandfrom=dthour,undup=N);
*%loadriverdata(edigiv,&period,02175000,08,18,expandfrom=dthour,undup=N);

%global startdate enddate;
     

%let input1=stage_02167582;
%let input2=stage_02164000;
%let input3=stage_02163500;
%let output=stage_02168504;
%let numinputs=3;
%let mergestatement=merge saluda bush salware reedy ;  

/*
%let input1=stage_02173000;
%let input2=stage_02173500;
%let output=stage_02175000;
%let numinputs=2;
%let mergestatement=merge  ediora ediden edigiv;  


%let input1=stage_02167582;
%let input2=stage_02164000;
%let input3=stage_02163500;
%let output=stage_02168504;
%let numinputs=3;
%let mergestatement=merge saluda bush salware reedy ;  

%let input1=stage_02167582;
%let input2=stage_02167450;
%let input3=stage_02167000;
%let output=stage_02168504;
%let numinputs=3;
%let mergestatement=merge saluda bush  lr salchap;

%let input1=stage_02167582;
%let input2=stage_02164000;
%let input3=stage_02163500;
%let input4=stage_02167450;
%let input5=stage_02165200;
%let output=stage_02168504;
%let numinputs=5;
%let mergestatement=merge saluda bush salware reedy lr rabon;

 
   %let input1=stage_02168504;
     %let input2=stage_02161000;
     %let output=stage_02169500;
     %let numinputs=2;
     %let mergestatement=merge saluda broad congaree;

     %let input1=stage_02167582;
     %let input2=stage_02166501;
     %let output=stage_02168504;
     %let numinputs=2;
     %let mergestatement=merge saluda bush usaluda;



*/
%macro buildsymbols(numsymbols);
     %do symnum=1 %to &numsymbols;
          symbol&symnum v=none i=j w=1 l=&symnum pointlabel=none;
     %end;
%mend buildsymbols;
%global startdate enddate w1date w2date;
%macro buildwater;
     %put Building sf.water dataset;
     data sf.Water; 
          &mergestatement;
          by dtm;
          %do inputnum=1 %to &numinputs;
               LOG&&input&inputnum=log(&&input&inputnum);
          %end;
          LOG&output=log(&output);
     run;    
     %put Calculating Starting and Ending dates for the multivariate series;
     %let sql1=;
     %do inputnum=2 %to &numinputs; 
          %let sql1=&sql1 and &&input&inputnum is not null;
     %end;
     %put SQL1=&sql1;
     proc sql noprint;
          select min(dtm) into :sd from sf.water where &input1 is not null &sql1;
          select max(dtm) into :ed from sf.water where &input1 is not null &sql1; 
     quit;
     data _null_;
          st=&sd;
          en=&ed;
          call symput('startdate',put(&sd,20.));
          call symput('enddate',put(&ed,20.));
          call symput('w1date',put(&sd,datetime20.2));
          call symput('w2date',put(&ed,datetime20.2));
     run;
     %put Calculated Start Date for series :&startdate &w1date;
     %put Calculated End Date for series   :&enddate &w2date;     
     %put;
     %put Plotting Profile;
     goptions reset=all ftext="tahoma" ftitle="tahoma" htitle=2.5 htext=1.5 fontres=PRESENTATION  ;
     %buildsymbols(&numinputs);
     axis1 label=none value=(f='tahoma' h=1 angle=90 rotate=0) minor=none;
     axis2 label=none value=(h=1);
     legend1 label=('Stage Height for Stations') down=%eval(&numinputs+1) shape=line(7) 
     value=(f='tahoma' h=1.5 );
   
     proc gplot data=sf.water ;
          title1 "River Stage - Period Profile";
          title2 "&w1date - &w2date";
          plot &output*dtm=1
          %do inputnum=1 %to &numinputs;
               &&input&inputnum*dtm
          %end;
          
          / overlay haxis=axis1 vaxis=axis2 legend=legend1 ;
          format dtm datetime9.;
     run;
     quit;
     %put Ending the build macro;
%mend buildwater;

/*set the number of inputs before running this macro */
%macro runlogtest;
     %put Performing LOGTEST;
     %do inputnum=1 %to &numinputs;
          %put ... on &&input&inputnum ...;
          %logtest(sf.water,&&input&inputnum); %put logtest for &&input&inputnum=&logtest;
               %if &logtest=LOG %then %let input&inputnum=log&&input&inputnum;
               %put ... results = &logtest so we will use &&input&inputnum;
     %end;
     %logtest(sf.water,&output); %put logtest for &output=&logtest;
               %put ... on &output ...;
               %if &logtest=LOG %then %let output=log&output;
               %put ... results = &logtest so we will use &output;
     %put Logtest Complete;
     %put;
%mend runlogtest;


%macro runarima(
      timeinterval=minute15         /* interval for the date/datetime forecast */
     ,ccfminimum=10                 /* empirical cutoff for the ccf delay parameters */
     ,ccfmaximum=100                /* empirical cutoff for the ccf delay parameters */
     ,backforecast=48
     ,diffall=0
     ,plotback=36
     ,plotfore=8
     );

     %let adflag=7;
     proc arima data=sf.water;
          %let crosscorrvar=;
          %do inputnum=1 %to &numinputs;
               ods output tentativeorders=&&input&inputnum..orders StationarityTests=&&input&inputnum..stat;
               identify clear var=&&input&inputnum scan nlag=96 stationarity=(adf=&adflag);
               %let crosscorrvar=&crosscorrvar &&input&inputnum;
               run;
          %end;
          %put CROSSCORRVAR ID1=&crosscorrvar;
          ods output tentativeorders=&output.orders StationarityTests=&output.stat;
          identify var=&output scan crosscorr=(&crosscorrvar) nlag=192 stationarity=(adf=&adflag) ;
          run;
     quit;
     
     proc sql noprint;
          %do inputnum=1 %to &numinputs;
               select count(*) into :numorders from &&input&inputnum..orders;
               %let numorders=&numorders;
               select scan_ar,scan_ma into :input&inputnum.ar1-:input&inputnum.ar&numorders
                                         , :input&inputnum.ma1-:input&inputnum.ma&numorders
                     from &&input&inputnum..orders;
               %let input&inputnum.ar1=&&input&inputnum.ar1;
               %let input&inputnum.ma1=&&input&inputnum.ma1;
               select min(lags) into :input&inputnum.diff from &&input&inputnum..stat where probf<.05 and type='Trend';
               %let input&inputnum.diff=&&input&inputnum.diff;
          %end;
          select count(*) into :numorders from &output.orders;
          %let numorders=&numorders;
          select scan_ar,scan_ma into :outputar1-:outputar&numorders , :outputma1-:outputma&numorders 
               from &output.orders;
          %let outputar1=&outputar1; %let outputma1=&outputma1;
          select min(lags) into :outputdiff from &output.stat where probf<.05 and type='Trend';
     quit;

     %do inputnum=1 %to &numinputs;
          %if &diffall=0 %then %do;
               data _null_; set &&input&inputnum..stat;
                    where type='Trend';
                    if lag=0 and probf<.05 then zeroflag=1;
               run;
               %if &&input&inputnum.diff > 0 %then %let input&inputnum.diff=(&&input&inputnum.diff);
               %else %let input&inputnum.diff=;
               %put Differencing Report: input&inputnum.diff=&&input&inputnum.diff;
          %end;
          %else %do;
               %let input&inputnum.diff=(&diffall);
               %put Differencing Report: input&inputnum.diff=&&input&inputnum.diff;
          %end;                
     %end;
     %if &diffall=0 %then %do;
          %if &outputdiff > 0 %then %let outputdiff=(&outputdiff);
          %else %let outputdiff=;
     %end;
     %else %do;
          %let outputdiff=(&diffall);
     %end;
     %put Differencing Report: outputdiff=&outputdiff;
     %let crosscorrvar=;     
     %put *************************************;
     %put Identifying the CCF;
     %put *************************************;
     proc arima data=sf.water;
          %do inputnum=1 %to &numinputs; 
               identify %if &inputnum=1 %then %do; clear %end;  scan nlag=48 var=&&input&inputnum..&&input&inputnum.diff  ;
               run;
               estimate p=&&input&inputnum.ar1 q=&&input&inputnum.ma1 method=ml noprint;
               run;
               %let crosscorrvar=&crosscorrvar &&input&inputnum..&&input&inputnum.diff;
          %end;
          %put CROSSCORRVAR ID2=&crosscorrvar;
          identify scan esacf minic crosscorr=(&crosscorrvar) nlag=100 outcov=&output._cov var=&output &outputdiff ;
     run;quit;
     %plotccf(&output._cov,%eval(&ccfminimum-1),&ccfmaximum);
          

     data abscorr; set &output._cov; abscorr=abs(corr); where lag>0;run;
          %do inputnum=1 %to &numinputs;
               proc sort data=abscorr out=abscorr_&&input&inputnum; 
                    by descending abscorr; 
                    where upcase(crossvar)="%upcase(&&input&inputnum)"  and lag >= &ccfminimum and lag < &ccfmaximum; 
               run;
               data _null_; 
                    set abscorr_&&input&inputnum;
                    if _n_=1 then call symput("input&inputnum._corr", lag); 
               run; 
               %let input&inputnum._corr=&&input&inputnum._corr;
           %end;

     %let crosscorrvar=;     
     %let crosscorrstmt=;

     %put *************************************;
     %put Fitting the ARIMA;
     %put *************************************;
     proc arima data=sf.water;
          %do inputnum=1 %to &numinputs;
              identify %if &inputnum=1 %then %do; clear %end;  scan nlag=48 var=&&input&inputnum..&&input&inputnum.diff  ;
              run;
               estimate p=&&input&inputnum.ar1 q=&&input&inputnum.ma1 method=ml noprint;
               run;
               %let crosscorrvar=&crosscorrvar &&input&inputnum &&input&inputnum.diff;
               %let crosscorrstmt=&crosscorrstmt  &&input&inputnum._corr.$(1)/(1)&&input&inputnum;
          %end;
          %put CROSSCORRVAR Full Arima=&crosscorrvar;
          %put CROSSCORRSTMT =&crosscorrstmt;

          identify var=&output.&outputdiff scan esacf minic crosscorr=(&crosscorrvar) nlag=100;
          estimate p=&outputar1 q=&outputma1 input=(&crosscorrstmt) method=ml ;
          forecast lead=%sysfunc(ceil(%sysevalf(&backforecast*1.5))) out=forecast_&output back=&backforecast id=dtm interval=&timeinterval; 
     run;     
     quit;
     %if       %upcase(&timeinterval)=MINUTE15 %then %let tscale=900;
     %else %if %upcase(&timeinterval)=HOUR     %then %let tscale=3600;
     %else %do;
          %put ERROR: Time Interval (&timeinterval) Not Defined for Backforecast Calculation ;
          %goto %lender;
     %end;
     %let backf=%eval(&enddate-%sysevalf(&backforecast*&tscale));
     data out(  drop=    sval0 sval1 sval2)
          low0( keep=dtm sval0 sval1 sval2)
          high0(keep=dtm sval0 sval1 sval2)
          low1( keep=dtm sval0 sval1 sval2)
          high1(keep=dtm sval0 sval1 sval2)
          low2( keep=dtm sval0 sval1 sval2)
          high2(keep=dtm sval0 sval1 sval2);
     set forecast_&output;
          forecast=forecast;
          l95=l95;
          u95=u95;
          &output=&output;

     /* pull out the predicted values to be compared with the predictions */
     output out;
     if dtm > &backf and  dtm <= &enddate then do; sval0=l95; output low0; sval0=u95; output high0; end;
     if dtm > &enddate then do; sval1=l95; output low1; sval1=u95; output high1; end;
     if dtm <= &backf then do;sval2=l95; output low2; sval2=u95; output high2; end;
     run;

     proc sort data=low0; by descending dtm; run;
     proc sort data=low1; by descending dtm; run;
     proc sort data=low2; by descending dtm; run;

     data forecast; set low2 high2 low1 high1 low0 high0 out; 
          if dtm=. then delete; 
          %if %substr(&output,1,3)=log %then %do;
               sval0=exp(sval0);
               sval1=exp(sval1);
               sval2=exp(sval2);
               forecast=exp(forecast);
               &output=exp(&output);
          %end; 
     run;

     %let forecaststart=%eval(&backf-(&plotback*3600));
     %let forecastend=%eval(&enddate+(&plotfore*3600));
     %annotatedays(forecast_&output,dtm,&forecaststart,&forecastend);
    
     %put >>>&tscale * &backforecast = &backf >>>&enddate;

     proc gplot data=forecast gout=work.gseg annotate=daylines;
          goptions reset=all ftext="tahoma" htitle=2 cback=white;
          symbol1 i=ms                                 c=bwh    co=libgr;
          symbol2 i=ms                                 c=ywh    co=libgr;
          symbol3 i=ms                                 c=pkwh   co=libgr;
          symbol4 i=j       v=none         h=1    w=1  c=degb;
          symbol5 i=none    v=dot          h=.33  w=1  c=vigb;
          axis1 label=none value=(f='tahoma' h=1 angle=90 rotate=0)  minor=none; 
          axis2 label=none value=(h=1);
          where dtm between &forecaststart and &forecastend;
          plot sval2*dtm=1 sval0*dtm=2 sval1*dtm=3 forecast*dtm=4 &output*dtm=5
               / name="rivfc" des="Forecast for "
               grid  haxis=axis1 vaxis=axis2 overlay href=&backf chref=palg;
          format dtm tod5.;
          label forecast="Forecast";

     run; quit;
     %put *******************************;
     %put ** CHOSEN PARAMETERS AND THAT**;
     %put *******************************;
     %do inputnum=1 %to &numinputs;
          %put input&inputnum= &&input&inputnum;
          %put Identify Var: &&input&inputnum  Diff: &&input&inputnum.diff;
          %put Orders: p=&&input&inputnum.ar1 q=&&input&inputnum.ma1;
     %end;
     %put crossvar: &crosscorrvar;
     %put Crosscorrstmt: &crosscorrstmt;

     %lender:
     options notes;
%mend runarima;
*options mprint mlogic symbolgen;
options nomprint nomlogic nosymbolgen;
options nonotes;

%buildwater;
%runlogtest;

%runarima(backforecast=12,plotfore=24);
options notes;
*%runarima(timeinterval=hour,ccfminimum=10,ccfmaximum=36,backforecast=24,diffall=1,plotback=72,plotfore=10);

