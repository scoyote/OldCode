/****************************************************   
*****   Saluda 1995-2002 Exploration Program    *****
*****   SaludaExploratory.sas                   *****
*****   Created 11-27-2003                      *****
*****   Created by Sam Croker                   *****
*****************************************************/  
%let libloc = C:\Documents and Settings\Compaq_Administrator\Desktop\Thesis Final;
libname saluda "&libloc";
options mstored sasmstore=af ;
libname af "&libloc";
%include "&libloc\Final Programs\macros.sas";

%let startdate      = '05sep96/06:00:00'DT;
%let forecaststart  = '09sep96/06:00:00'DT;
%let enddate        = '10sep96/06:00:00'DT;

***********************************************************;
*setplotint(interval in days);
%let forecastlags=72;
%let plotinterval=2;
%setplotint;
%let yaxisvar=      Logged Flow;
%plotprofile(flow);
*fitflowarima(ar_a,ma_a,ar_b,ma_b,ar_md,ma_md,delay1,delay2);
%fitflowarima(2,1,2,0,2,1,3,10);
title1 "Streamflow Diagnostics";
%plotacf(salccft,20,2,Of Saluda Streamflow Data,f1);
%plotacf(brdccft,20,2,Of Broad Streamflow Data,f2);
%plotacf(ccft,20,1,Of Prewhitened System Streamflow Data,f3);
%plotccf(ccft,-20,20,2,1,flow);
%plotccf_combined(ccft,-20,20,2,1);

%put &forecaststart-&forecastend;
%plotforecast(forecast,&outputvar1,Logged Streamflow,21600);

%fitresidarima;
%plotacf(acfresid,20,2,Of Streamflow Residuals,fr);
title1 Residual Normal QQ Plot of Congaree at Columbia Streamflow Model;
title2 &w1date - &w2date;
%nqplot(data=forecast,var=residual,detrend=no);
%fitflowspect(0,2500000,250000,0,0,0);
***********************    stage  ****************************************************;
    
%let startdate=     '03sep96/00:00:00'DT;
%let forecaststart= '09sep96/00:00:00'DT;
%let enddate=       '10sep96/00:00:00'DT;
%let yaxisvar = Stage;
%plotprofile(stage);
%fitstagearima(2,1,3,2,9);
title1 "Stage Diagnostics";
%plotacf(congccft,20,2,Of Congaree at Columbia Stage Data,s1);
%plotacf(ccft,20,1,Of Prewhitened System Stage Data,s2);
%plotccf(ccft,-20,35,2,2,stage);
%plotccf_combined(ccft,-20,35,2,2);
%plotforecast(forecast,&outputvar2,Stage,86400);
%fitresidarima;
%plotacf(acfresid,20,2,Of Stage Residuals,sr);
title1 Residual Normal QQ Plot of Congaree Stage Model;
title2 &w1date - &w2date;
%nqplot(data=forecast,var=residual,detrend=no);
%fitstagespect(0,.05,0.005);

/****************************************************   
*****            21 - 23 July 1995              *****
*****************************************************/  

%let startdate=     '21jul95/00:00:00'DT;
%let forecaststart= '22jul95/12:00:00'DT;
%let enddate=       '23jul95/00:00:00'DT;
%let plotinterval=  1; *days;
%let forecastlags = 72;
%let yaxisvar=Logged Flow;
%setplotint;
%plotprofile(flow);
%fitflowarima(0,2,1,1,1,1,3,7);
title1 "Streamflow Diagnostics";
%plotacf(salccft,20,2,Of Saluda Streamflow Data,f1);
%plotacf(brdccft,20,2,Of Broad Streamflow Data,f2);
%plotacf(ccft,20,1,Of Prewhitened System Streamflow Data,f3);
%plotccf(ccft,-20,20,2,1,flow);
%plotccf_combined(ccft,-20,20,2,1);
%plotforecast(forecast,&outputvar1,Logged Streamflow,86400);
%fitresidarima;
%plotacf(acfresid,20,2,Of Logged Streamflow Residuals,fr);
title1 Residual Normal QQ Plot of Congaree at Columbia Streamflow Model;
title2 &w1date - &w2date;
%nqplot(data=forecast,var=residual,detrend=no);
%fitflowspect(0,2500000,2500000,0,1000,100);
*************************************************************************************
***********************    stage  ****************************************************;
%let yaxisvar = Stage;
%plotprofile(stage);
%fitstagearima(2,0,2,0,8);
title1 "Stage Diagnostics";
%plotacf(congccft,20,2,Of Congaree at Columbia Stage Data,s1);
%plotacf(ccft,20,1,Of Prewhitened System Stage Data,s2);
%plotccf(ccft,-20,35,2,2,stage);
%plotccf_combined(ccft,-20,35,2,2);
%plotforecast(forecast,&outputvar2,Stage,86400);
%fitresidarima;
%plotacf(acfresid,20,2,Of Stage Residuals,sr);
title1 Residual Normal QQ Plot of Congaree Stage Model;
title2 &w1date - &w2date;
%nqplot(data=forecast,var=residual,detrend=no);
%fitstagespect(0,40000,2500);



/****************************************************   
*****            28 Apr - 7 May 1999            *****
*****************************************************/  

%let startdate=     '28apr99/00:00:00'DT;
%let forecaststart= '28apr99/00:00:00'DT;
%let enddate=       '07may99/00:00:00'DT;
%let plotinterval=  3; *days;
%let forecastlags = 72;
%setplotint;
%let yaxisvar=      Logged Flow;
%plotprofile(flow);
%fitflowarima(1,1,4,2,5,2,3,6);
%plotacf(salccft,20,2,Of Saluda Streamflow Input Data,f1);
%plotacf(brdccft,20,2,Of Broad Streamflow Input Data,f2);
%plotacf(ccft,20,1,Of Prewhitened System Streamflow Data,f3);
%plotccf(ccft,-20,20,2,1,flow);
%plotccf_combined(ccft,-20,20,2,1);
%plotforecast(forecast,&outputvar1,Logged Streamflow,21600);
%fitresidarima;
%plotacf(acfresid,20,2,Of Logged Streamflow Residuals,fr);
title1 Residual Normal QQ Plot of Congaree at Columbia Streamflow Model;
title2 &w1date - &w2date;
%nqplot(data=forecast,var=residual,detrend=no);
%fitflowspect(0,1000,100,0,1000,100);
*************************************************************************************
***********************    stage  ****************************************************;
%let yaxisvar = Stage;
%plotprofile(stage);
%fitstagearima(3,3,3,2,7);
title1 "Stage Diagnostics";
%plotacf(congccft,20,2,Of Congaree at Columbia Stage Input Data,s1);
%plotacf(ccft,20,1,Of Prewhitened System Stage Data,s2);
%plotccf(ccft,-20,35,2,2,stage);
%plotccf_combined(ccft,-20,35,2,2);
%plotforecast(forecast,&outputvar2,Stage,21600);
%fitresidarima;
%plotacf(acfresid,20,2,Of Stage Residuals,sr);
title1 Residual Normal QQ Plot of Congaree Stage Model;
title2 &w1date - &w2date;
%nqplot(data=forecast,var=residual,detrend=no);
%fitstagespect(0,.01,.001);
