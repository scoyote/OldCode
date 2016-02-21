options mstored sasmstore=sf;

%loadriverdata(saluda,&period,02168504,03,04);
%loadriverdata(broad,&period,02161000,01,02);
%loadriverdata(congaree,&period,02169500,01,02);
%loadriverdata(swamp,&period,02169625,02,02);

%setdates;

     proc sql noprint;
          select avg(stage_02168504) into :avg8504 from saluda;
          select avg(stage_02161000) into :avg1000 from broad;
          select avg(stage_02169500) into :avg9500 from congaree;
     quit;

     data sf.Water; 
          merge saluda broad congaree swamp;
          by dtm;
          NONE_stage_02168504=stage_02168504;
          NONE_stage_02161000=stage_02161000;
          NONE_stage_02169500=stage_02169500;
          
          LOG_stage_02168504=log(stage_02168504);
          LOG_stage_02161000=log(stage_02161000);
          LOG_stage_02169500=log(stage_02169500);
     run;
     
%buildtemplate(preview=no);
%plotprofile(sf.water);  
 
%logtest(sf.water,stage_02168504);%let salvar=&logtest._stage_02168504;
%logtest(sf.water,stage_02161000);%let brdvar=&logtest._stage_02161000;
%logtest(sf.water,stage_02169500);%let convar=&logtest._stage_02169500;
%put Using variable &salvar for Saluda Input;
%put Using variable &brdvar for Broad Input;
%put Using variable &convar for Congree Output;

     %let adflag=7;
     proc arima data=sf.water;
          where dtm between &startdate and &enddate;
               ods output tentativeorders=salorders StationarityTests=salstat;
               identify clear var=&salvar scan nlag=96 outcov=stage_02168504 stationarity=(adf=&adflag) ;
          run;
               ods output tentativeorders=brdorders StationarityTests=brdstat;
               identify clear var=&brdvar scan nlag=96 outcov=stage_02161000 stationarity=(adf=&adflag);
          run;
               ods output tentativeorders=mdlorders StationarityTests=mdlstat;
               identify var=&convar scan crosscorr=(&salvar &brdvar) nlag=192 outcov=stage_02169500 stationarity=(adf=&adflag) ;
          run;
     quit;
     proc sql noprint;
          select count(*) into :salorders from salorders; %let salorders=&salorders;
          select count(*) into :brdorders from brdorders; %let brdorders=&brdorders;
          select count(*) into :mdlorders from mdlorders; %let mdlorders=&mdlorders;
          select scan_ar,scan_ma into :salar1-:salar&salorders , :salma1-:salma&salorders from salorders;
          select scan_ar,scan_ma into :brdar1-:brdar&salorders , :brdma1-:brdma&brdorders from brdorders;
          select scan_ar,scan_ma into :mdlar1-:mdlar&salorders , :mdlma1-:mdlma&mdlorders from mdlorders;
          select min(lags) into :saldiff from salstat where probf<.05 and type='Trend';
          select min(lags) into :brddiff from brdstat where probf<.05 and type='Trend';
          select min(lags) into :mdldiff from mdlstat where probf<.05 and type='Trend';
     quit;
     %put saldiff=&saldiff;
     %put brddiff=&brddiff;
     %put mdldiff=&mdldiff;

     %let backforecast=24;
     
     proc arima data=sf.water;
          where dtm between &startdate and &enddate;
          identify clear var=stage_02168504(&saldiff) scan nlag=48 outcov=stage_02168504 ;
          estimate p=&salar1 q=&salma1 method=ml noprint;
          identify var=stage_02161000(&brddiff) scan nlag=48 outcov=stage_02161000;
          estimate p=&brdar1 q=&brdma1 method=ml noprint;
          identify var=stage_02169500(&mdldiff) scan esacf minic crosscorr=(stage_02168504(&saldiff) stage_02161000(&brddiff)) nlag=672 outcov=stage_02169500 ;
          estimate p=&mdlar1 q=&mdlma1 input=(12$(1)/(1)stage_02168504 30$(1)/(1)stage_02161000) method=ml;
          forecast lead=%sysfunc(ceil(%sysevalf(&backforecast*1.5))) out=forecast_stage_02169500 back=&backforecast id=dtm interval=minute15; 
     run;quit;

     %let backf=%eval(&enddate-%sysevalf(&backforecast*900));
     %put enddt=&enddate;
     %put backf=&backf;

     data out(  drop=    sval0 sval1 sval2)
          low0( keep=dtm sval0 sval1 sval2)
          high0(keep=dtm sval0 sval1 sval2)
          low1( keep=dtm sval0 sval1 sval2)
          high1(keep=dtm sval0 sval1 sval2)
          low2( keep=dtm sval0 sval1 sval2)
          high2(keep=dtm sval0 sval1 sval2);
     set forecast_stage_02169500;
          forecast=forecast;
          l95=l95;
          u95=u95;
          stage_02169500=stage_02169500;

     /* pull out the predicted values to be compared with the predictions */
     output out;
     if dtm > &backf and  dtm <= &enddate then do; sval0=l95; output low0; sval0=u95; output high0; end;
     if dtm > &enddate then do; sval1=l95; output low1; sval1=u95; output high1; end;
     if dtm <= &backf then do;sval2=l95; output low2; sval2=u95; output high2; end;
     run;

     proc sort data=low0; by descending dtm; run;
     proc sort data=low1; by descending dtm; run;
     proc sort data=low2; by descending dtm; run;

     data forecast; set low2 high2 low1 high1 low0 high0 out; if dtm=. then delete; run;

     %let forecaststart=%eval(&backf-(36*3600));
     %let forecastend=%eval(&enddate+(8*3600));
     %annotatedays(forecast_stage_02169500);
  
     proc gplot data=forecast gout=work.gseg annotate=daylines;
          goptions reset=all ftext="tahoma" htitle=2 cback=white;
          symbol1 i=ms                                 c=bwh    co=libgr;
          symbol2 i=ms                                 c=ywh    co=libgr;
          symbol3 i=ms                                 c=pkwh   co=libgr;
          symbol4 i=j       v=none         h=1    w=1  c=degb;
          symbol5 i=none    v=dot          h=.33  w=1  c=vigb;
          axis1 label=none value=(f='tahoma' h=1 angle=90 rotate=0) minor=none 
          order=(&forecaststart to &forecastend by dthour) ;
          axis2 label=none value=(h=1);
          where dtm between &forecaststart and &forecastend;
          plot sval2*dtm=1 sval0*dtm=2 sval1*dtm=3 forecast*dtm=4 stage_02169500*dtm=5
               / name="rivfc" des="Forecast for "
               grid  haxis=axis1 vaxis=axis2 overlay href=&backf chref=palg;
          format dtm tod5.;
          label forecast="Forecast";

     run; quit;


