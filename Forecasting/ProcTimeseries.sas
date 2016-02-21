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
%loadriverdata(usaluda,&period,02166501,04,17);


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
   ods html;* file='D:\SAS Repository\Forecasting\Output\timeseriestest.htm';
   ods graphics on;

   title "Illustration of ODS Graphics";
   proc timeseries data=sf.water out=_null_ 
      plot=(series corr decomp)
      crossplot=all;
      id dtm interval=minute15;
      var stage_02168504;
      crossvar stage_02167582 stage_02163500 stage_02164000;
   run;

   ods graphics off;
   ods html close;
