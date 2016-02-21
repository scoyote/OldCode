options mstored sasmstore=sf;
%symdel %globlist;
proc catalog catalog=work.gseg force kill; run;quit;

proc datasets library=work force kill; run;quit;
proc catalog catalog=work.sasmacr force kill; run; quit;
%let period=12;

%loadriverdata(saluda,&period,02168504,03,04);
%loadriverdata(bush,&period,02167582,01,02);
%loadriverdata(salware,&period,02163500,15,16);
%loadriverdata(little,&period,02167450,01,11);

%loadriverdata(reedy,&period,02164000,01,02);
%loadriverdata(salchap,&period,02167000,02,01);

%loadriverdata(broad,&period,02161000,01,02);
%loadriverdata(congaree,&period,02169500,01,02);
%loadriverdata(swamp,&period,02169625,02,02);
%loadriverdata(rabon,&period,02165200,04,05);
%loadriverdata(usaluda,&period,02166501,04,17);

%loadriverdata(ediden,&period,02173000,05,15,expandfrom=dthour,undup=N);
%loadriverdata(ediora,&period,02173500,01,02,expandfrom=dthour,undup=N);
%loadriverdata(edigiv,&period,02175000,08,18,expandfrom=dthour,undup=N);



/*
%let input1=&varprefix._02173000;
%let input2=&varprefix._02173500;
%let output=&varprefix._02175000;
%let numinputs=2;
%let mergestatement=merge  ediora ediden edigiv;  


%let input1=&varprefix._02167582;
%let input2=&varprefix._02164000;
%let input3=&varprefix._02163500;
%let output=&varprefix._02168504;
%let numinputs=3;
%let mergestatement=merge saluda bush salware reedy ;  

%let input1=&varprefix._02167582;
%let input2=&varprefix._02167450;
%let input3=&varprefix._02167000;
%let output=&varprefix._02168504;
%let numinputs=3;
%let mergestatement=merge saluda bush  lr salchap;

%let input1=&varprefix._02167582;
%let input2=&varprefix._02164000;
%let input3=&varprefix._02163500;
%let input4=&varprefix._02167450;
%let input5=&varprefix._02165200;
%let output=&varprefix._02168504;
%let numinputs=5;
%let mergestatement=merge saluda bush salware reedy lr rabon;
 
%let input1=&varprefix._02168504;
%let input2=&varprefix._02161000;
%let output=&varprefix._02169500;
%let numinputs=2;
%let mergestatement=merge saluda broad congaree;

%let input1=&varprefix._02167582;
%let input2=&varprefix._02166501;
%let output=&varprefix._02168504;
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
     legend1 label=('&varprefix. Height for Stations') down=%eval(&numinputs+1) shape=line(7) 
     value=(f='tahoma' h=1.5 );
   
     proc gplot data=sf.water ;
          title1 "River &varprefix. - Period Profile";
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
   *);*/;/*'*/ /*"*/; %MEND;run;quit;;;;;

%let varprefix=stage;
%let log=;
%let numinputs=3;
%let input1=&varprefix._02167582;
%let input2=&varprefix._02167450;
%let input3=&varprefix._02163500;
%let output=&varprefix._02168504;
%let mergestatement=merge saluda salware bush little ;  
%buildwater;
%macro setdates(numinputs);
     %global startdate enddate;
     proc sql noprint;
          %do i=1 %to &numinputs;
               select min(dtm) format=datetime28. into :min&i from sf.water where &&input&i~=.; 
               select max(dtm) format=datetime28. into :max&i from sf.water where &&input&i~=.; 
               %put &&input&i;
               %put MIN: &&min&i;
               %put MAX: &&max&i;
          %end;
          select min(dtm) format=datetime28. into :minout from sf.water where &output is not null;
          select max(dtm) format=datetime28. into :maxout from sf.water where &output is not null; 
          %put &output;
          %put MIN: &minout;
          %put MAX: &maxout;
          data _null_;
               %do i=1 %to &numinputs;
                    dmax&i="&&max&i"dt;
                    dmin&i="&&min&i"dt;
               %end;
               dmax%eval(&numinputs+1)="&maxout"dt;
               dmin%eval(&numinputs+1)="&minout"dt;
               a=max(of dmin1-dmin%eval(&numinputs+1));
               b=min(of dmax1-dmax%eval(&numinputs+1));
               call symput("enddate",b);
               call symput("startdate",a);
               put "Start Date/Time: " a datetime28.;
               put "End Date/Time:   " b datetime28.;
          run;
%mend setdates;
%setdates(3);

%let back=8;
%let lead=96;
/* set the lock in back calculator */
*%let back=%sysevalf(%eval(&enddate-1454051700)/900);
*%put &baccer;

%let inputdiff=(96);

%let input1=&log.&varprefix._02167582;
%let input2=&log.&varprefix._02167450;
%let input3=&log.&varprefix._02163500;
%let output=&log.&varprefix._02168504;
%let plotstart=%eval(%eval(&enddate-(96*900)));
%let plotend=%eval(%eval(&enddate+%eval(&lead*900)));
%let fcref=%eval(&enddate-(%eval(&back)-1)*900);
data _null_;
     a=&plotstart;
     b=&plotend;
     c=&back;
     d=&fcref;
     e=&enddate;
     put a= datetime28.  a= / b= datetime28. b= / c=  / d= datetime28. d= / e= datetime28. e=;
run;

   proc statespace data=sf.water interval=minute15 back=&back lead=&lead out=statespaceforecast; 
      id dtm;
      where dtm <=&enddate and dtm>=&startdate;
      var &output.&inputdiff &input1.&inputdiff &input2.&inputdiff &input3.&inputdiff; 
      *restrict f(3,2)=0 f(3,4)=0 
               g(3,2)=0 g(4,1)=0 g(5,1)=0; 
   run;
   
     data out(  drop=    sval0 sval1 sval2)
          low0( keep=dtm sval0 sval1 sval2)
          high0(keep=dtm sval0 sval1 sval2)
          low1( keep=dtm sval0 sval1 sval2)
          high1(keep=dtm sval0 sval1 sval2)
          low2( keep=dtm sval0 sval1 sval2)
          high2(keep=dtm sval0 sval1 sval2);
     set statespaceforecast;
          forecast=for1;
          l95=for1-1.65*std1;
          u95=for1+1.65*std1;
          &output=&output;

     /* pull out the predicted values to be compared with the predictions */
     output out;
     if dtm > &fcref and  dtm <= &enddate then do; sval0=l95; output low0; sval0=u95; output high0; end;
     if dtm > &enddate then do; sval1=l95; output low1; sval1=u95; output high1; end;
     if dtm <= &fcref then do;sval2=l95; output low2; sval2=u95; output high2; end;
     run;

     proc sort data=low0; by descending dtm; run;
     proc sort data=low1; by descending dtm; run;
     proc sort data=low2; by descending dtm; run;
     data forecast; set low2 high2 low1 high1 low0 high0 out; 
          if dtm=. then delete; 

     run;
 data DayLines; set statespaceforecast(keep=dtm );
          length color function $8 text $50 wdate $50;
          retain xsys '2' ysys '1' when 'a';
          k=%eval(&plotend-&plotstart);
          where dtm between &plotstart and &plotend;
          if hour(dtm)=0 and minute(dtm)=0 then do;
               wdate=put(datepart(dtm),worddatx12.);
               function='move'; x=dtm; y=0; output;
               function='draw'; x=dtm; y=100; color='lib'; size=1; output;
               function='label'; x=dtm; y=1; size=1; position='3';angle=90;color='black'; style='swiss';text=left(trim(wdate)); output;
          end;
          if dtm=&fcref then do;
               wdate=put(datepart(&fcref),worddatx12.)||put(timepart(&fcref),timeampm.);
               function='move'; x=dtm; y=0; output;
               function='draw'; x=dtm; y=100; color='pink'; size=1; output;
               function='label'; x=dtm; y=1; size=1; position='3';angle=90;color='black'; style='swiss';text="Forecast Start:"; output;
               function='label'; x=dtm; y=1; size=1; position='9';angle=90;color='black'; style='swiss';text=left(trim(wdate)); output;
          end;

     run;

     ods html file="D:\SAS Repository\output\activex.htm";
goptions reset   = all
         device  = activex
         gunit   = pct 
         border 
         xpixels = 800    
         ypixels = 600
         htitle  = 4 
         htext   = 4
         cback   = CXFFF7CE 
       ; 

   proc gplot data=forecast annotate=daylines ;
     label sval0="1 Step Ahead CI" sval1="Holdout Data Forecast CI" sval2="Forecast CI" forecast='Forecast' &output='Actual';
     axis1 label=(font='tahoma' "DATE" h=2) value=(angle=45 rotate=0 h=.9 font='tahoma');
     axis2 label=(angle=90 rotate=0 font='tahoma' "&varprefix." h=2) value=(font='tahoma');
     symbol1 i=ms                                 c=bwh    co=libgr;
     symbol2 i=ms                                 c=ywh    co=libgr;
     symbol3 i=ms                                 c=pkwh   co=libgr;
     symbol4 i=j       v=none         h=1    w=1  c=degb;
     symbol5 i=none    v=dot          h=.33  w=1  c=vigb;
     where dtm between &plotstart and &plotend;
     format dtm tod5.;
     plot sval2*dtm=1 sval0*dtm=2 sval1*dtm=3 forecast*dtm=4 &output*dtm=5
     /overlay vaxis=axis2 haxis=axis1  grid ;
     run;
     quit;

ods html close;

data SaludaRiverBasin;
     informat sitenumber $15. sitename $char255.;
     format sitename $char255.;
     input siteNumber $ @21 SiteName $50. ;
*1234567890123456789012345678901234567890123456789012345678901234567980123456798;
datalines ;
021630967 02162500            SALUDA RIVER NEAR GREENVILLE,S.C.                 
02163500  02163001            SALUDA RIVER NEAR WILLIAMSTON, SC                 
02163001  021630967           GROVE CREEK NEAR PIEDMONT, SC                     
02166500  02163500            SALUDA RIVER NEAR WARE SHOALS, SC                 
02164110  02164000            REEDY RIVER NEAR GREENVILLE, SC                   
021650905 02164110            REEDY RIVER ABOVE FORK SHOALS, S. C.              
02166500  021650905           Reedy River near Waterloo, SC                     
02166500  02165200            SOUTH RABON CREEK NEAR GRAY COURT,S.C.            
02166501  02166500            LAKE GREENWOOD NEAR CHAPPELLS, SC                 
02167000  02166501            LAKE GREENWOOD TAILRACE NR CHAPPELLS, SC          
02168500  02167000            SALUDA RIVER AT CHAPPELLS, SC                     
02168500  02167450            LITTLE RIVER NR SILVERSTREET, SC                  
02168500  02167582            BUSH RIVER NR PROSPERITY, S C                     
02167582  02167563            BUSH RIVER AT NEWBERRY, SC                        
02168500  02167600            SALUDA R NEAR PROSPERITY, SC                      
02168500  02167716            LITTLE SALUDA R NEAR PROSPERITY, SC               
02168501  02168500            LAKE MURRAY NEAR COLUMBIA, SC                     
02168504  02168501            LAKE MURRAY TAILRACE NEAR COLUMBIA, SC            
02169000  02168504            SALUDA RIVER BELOW LK MURRAY DAM NR COLUMBIA, SC  
end       02169000            SALUDA RIVER NEAR COLUMBIA, SC                    
02166500 340008081501800      RAINGAGE NEAR SALUDA, S.C.                        
02166501 341010081543900      Raingage at LK. Greenwood Tailrace nr Chappells,SC
02166500 341256082092000      RAINGAGE (SAMPLE BR) AT GREENWOOD, SC             
;
run;
%let codebase=C:\Program Files\SAS\SAS 9.1\common\applets;

         data father_and_sons;
input id $8. name $15. father $8.;
cards;
aaron   Aaron Parker        
bob     Bob Parker     aaron
charlie Charlie Parker aaron
david   David Parker   aaron
edward  Edward Parker  david
;
run;  

/* make sure ods listing is open when running macro */
ods listing;
 /* run the macro */
%ds2tree(ndata=father_and_sons,  /* data set */
         codebase=&codebase,
         xmltype=inline,
         htmlfile=d:\Sas Repository\output\tree.htm,
         nid=id,        /* use this variable as the id */
         cutoff=1,      /* display the name on every node */
         nparent=father,/* this identifies the parent of each node */
         nlabel=name,   /* display this on each node */
         height=400,          
         width=400,
         tcolor=navy,  
         fcolor=black);
