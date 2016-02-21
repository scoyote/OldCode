
options mstored sasmstore=sf;

%macro plotprofile(dataset) /store ;
     goptions reset=all ftext="tahoma" ftitle="tahoma" htitle=2.5 htext=1.5 fontres=PRESENTATION  ;

     axis1 label=none value=(f='tahoma' h=1 angle=90 rotate=0) minor=none 
               order=(&startdate to &enddate by dtday) ;
     axis2 label=none value=(h=1);
     legend1 label=('Stations') down=4 shape=line(7) value=(f='tahoma' h=1.5 );
     symbol1 v=none  i=j c=blue     l=1 pointlabel=none;
     symbol2 v=none  i=j c=black    l=2 pointlabel=none;
     symbol3 v=none  i=j c=green    l=3 pointlabel=none;

     proc gplot data=&dataset ;
          title1 "River Stage - Period Profile";
          title2 &w1date - &w2date;
          plot
               &input1*dtm
               &input2*dtm
               &output*dtm
          /overlay haxis=axis1 vaxis=axis2 legend=legend1 ;
          format dtm datetime9.;
     run;
     quit;
%mend plotprofile;
%macro plotacf(
     acf_dataset,   /* outcov dataset from proc arima */
     lags,          /* number of lags to plot */
     type,          /* 0 for single 1 for cross */
     titles,        /* title statement */
     num,           /* maybe graphics labeling???*/
     yuplim=1,       /* upper and lower y axis limits */
     ydnlim=-1
     ) /store;
    options orientation=landscape;
    data &acf_dataset;
      set &acf_dataset;
        nstderr=-stderr;
        label nstderr="Standard Error Lower Bound"
               stderr="Standard Error Upper Bound";
        if lag=0 then do;
            corr=0;
            partcorr=0;
        end;
    run;
    goptions reset=all ftext="tahoma" ftitle="tahoma" htitle=2.5 htext=1.5
             fontres=PRESENTATION ;

        proc gplot data=&acf_dataset;
        title1 "ACF Plot &titles";
        plot corr*lag stderr*lag nstderr*lag / name="acf&num" overlay haxis=axis1 vaxis=axis2 legend=legend1 ;
        symbol1 v=none  I=needle c=black pointlabel=none;
        symbol2 v=none  I=spline c=orange l=3 pointlabel=none;
        symbol3 v=none  I=spline c=orange l=3 pointlabel=none;
        legend1 value=(f='tahoma' h=1.5) down=3 shape=line(7);
        axis1 label=(f='tahoma' h=2 ) value=(f='tahoma' h=1) order=(0 to &lags by 1) ;
        axis2 label=(f='tahoma' h=1 angle=90) value=( f='tahoma' h=1);* order=(-1 to 1 by .2);
        %if &type=1 %then %do;
            where crossvar="";
        %end;
    run;quit;
        goptions reset=all ftext="tahoma" ftitle="tahoma" htitle=2.5 htext=1.5
             fontres=PRESENTATION  ;
        title1 "PACF Plot &titles"; 
        symbol1 v=none  I=needle c=black pointlabel=none;
        symbol2 v=none  I=spline c=orange l=3 pointlabel=none;
        symbol3 v=none  I=spline c=orange l=3 pointlabel=none;
        legend1 value=(f='tahoma' h=1.5) down=3 shape=line(7);
        axis1 label=(f='tahoma' h=2 ) value=(f='tahoma' h=1) order=( 0 to &lags by 1) ;
        axis2 label=(f='tahoma' h=1 angle=90) value=( f='tahoma' h=1) order=(-1 to 1 by .2 );
    proc gplot data=&acf_dataset;
        plot partcorr*lag stderr*lag nstderr*lag / name="pacf&num" overlay haxis=axis1 vaxis=axis2 legend=legend1 ;
        %if &type=1 %then %do;
            where crossvar="";
        %end;
    run;quit;
        goptions reset=all ftext="tahoma" ftitle="tahoma" htitle=2.5 htext=1.5 fontres=PRESENTATION  ;
        title1 "Inverse ACF Plot &titles";  
        symbol1 v=none  I=needle c=black pointlabel=none;
        symbol2 v=none  I=spline c=orange l=3 pointlabel=none;
        symbol3 v=none  I=spline c=orange l=3 pointlabel=none;
        legend1 value=(f='tahoma' h=1.5) down=3 shape=line(7);
        axis1 label=(f='tahoma' h=2 ) value=(f='tahoma' h=1) order=( 0 to &lags by 1) ;
        axis2 label=(f='tahoma' h=1 angle=90) value=( f='tahoma' h=1);* order=(-1 to 1 by .2 );
    proc gplot data=&acf_dataset;
        plot INVcorr*lag stderr*lag nstderr*lag / name="iacf&num" overlay haxis=axis1 vaxis=axis2 legend=legend1 ;
        %if &type=1 %then %do;
            where crossvar="";
        %end;
    run;quit;
    options orientation=portrait;
%mend plotacf;

%macro plotccf(
     /*required*/
     ccft_dataset,
     xlag1,     /* lower limit of x axis */
     xlag2,     /* upper limit of x axis */
     /*not required*/
     font=tahoma,
     htitle=2.5,
     htext=1.5, 
     hyaxisval=1,
     hyaxislab=2,
     hyaxisangle=90,
     hxaxisval=1,
     hxaxislab=2,
     hlegendlab=1.5
     ) /store;
     %let xmark=%sysfunc(int(%sysevalf(%eval(%sysfunc(abs(&xlag1))+%sysfunc(abs(&xlag2)))/10)));
     options orientation=landscape;
     goptions reset=all ftext="&font" ftitle="&font" htitle=&htitle htext=&htext fontres=PRESENTATION  ;
     symbol1 v=none  i=spline c=blue  l=1 ;
     symbol2 v=none  i=spline c=green l=1 ;
     axis1 label=(f="&font" h=&hxaxislab ) 
           value=(f="&font" h=&hxaxisval) 
           order=(&xlag1 to &xlag2 by &xmark) ;
     axis2 label=(f="&font" h=&hyaxislab angle=&hyaxisangle) 
           value=( f="&font" h=&hyaxisval);
     legend1   label=('Stations') 
               value=(f="&font" h=&hlegendlab);
     title1 "Prewhitened Complete Cross Correlation Function";
     proc gplot data=&ccft_dataset;
          label corr="Cross Correlation Function (CCF)";
          format corr 4.3;
          where crossvar<>"";
          plot corr*lag=crossvar / haxis=axis1 vaxis=axis2 legend=legend1 autohref chref=lilg autovref cvref=lilg;
     run;quit;
     options orientation=portrait;
%mend plotccf;

%macro plotforecast(
     forecast,      /* forecast dataset name */
     dataset,       /* original dataset name */
     plotinterval,  /* number of the set interval to plot 2= pi*/
     pi,            /* dtm multiplier 900=15 minutes */
     output,        /* forecasted variable */
     ylab,          /* y axis label */
     forecastlags,  /* number of forecasted lags */
     backval        /* how many back to start forecasts */
     ) /store;
     %let numpint = %eval(&plotinterval*&pi);
     %let href=%eval(&enddate - &backval*900);
     %let forecaststart=%eval(&href-&backval*&pi*&plotinterval);
     %let forecastend=%eval(&enddate+%eval(&forecastlags*900));
     %put Note: Plottin from &forecaststart to &forecastend;
     data forecast; merge &forecast (in=y1) &dataset (in=y2);
          by dtm;
          if y1;
     run;
        options orientation=landscape;
        goptions reset=all ftext="tahoma" ftitle="tahoma" htitle=2.5 htext=1.5 fontres=PRESENTATION  ;
        title1 "Forecasts for Congaree at Columbia";
        title2 "&w1date - &w2date";
        symbol1 v=none  I=join c=red    l=2     pointlabel=none;
        symbol2 v=none  I=join c=red    l=2     pointlabel=none;
        symbol3 v=none  I=join c=blue   l=1     pointlabel=none;
        symbol4 v=dot h=.25 I=join c=black  l=4     pointlabel=none;
        axis1 label=(f='tahoma' h=1 "Hour") value=(f='tahoma'  h=.75 rotate=0 angle=45  ) 
            order=(&forecaststart to &forecastend by dthour) minor=(number=3);

        axis2 label=( f='tahoma' h=2 angle=90 "&ylab") value=(f='tahoma' h=1) ; 
        legend1 label=('Forecasts') value=(f='tahoma' h=1.5) down=4 shape=line(7);
        proc gplot data=&FORECAST;
                where dtm between &forecaststart and &forecastend ;
        plot l95*dtm u95*dtm forecast*dtm &output*dtm 
            /overlay haxis=axis1 vaxis=axis2 legend=legend1
             href=(&href) chref=lilg;
        format dtm dateampm18.;
        label forecast="Forecast";
    run;quit;
    options orientation=portrait;
%mend plotforecast;
