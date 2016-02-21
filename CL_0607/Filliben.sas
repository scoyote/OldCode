/**********************************************************************
*	Program Name	:	$RCSfile: Filliben.sas,v $
*	REV/REV AUTH	:	$Revision: 1.2 $ $Author: scoyote $
*	REV DATE		:	$Date: 2007/05/31 11:45:43 $
* 
*   CREATOR:   SAMUEL T. CROKER
*   DATE:      23 May 2007
*   DESC:      Filliben: Normal Probability Plot Correlation Coefficient
***********************************************************************/ 




/* filliben take 1  - From Filliben (1975) */
%let n=7;
data filliben; 
	if _n_=1 then m=1-0.5**(1/&n);
	else if _N_<&n then m=(_n_-0.3175)/(&n+0.365);
	else m=0.5**(1/&n);	
	t=sqrt(log(1/(m**2)));
	c0=2.515517;
	c1=0.802853;
	c2=0.010328;
	d1=1.432788;
	d2=0.189269;
	d3=0.001308;
	xp=-(t-((c0+c1*t+c2*t**2)/(1+d1*t+d2*t**2+d3*t**3)));
	input x @@;
	output;
datalines;
-4 -2 0 1 5 6 8
;
run;
symbol1 v=dot c=blue;
proc gplot data=filliben;
plot x*xp;
run;
proc corr data=filliben;
	var x xp;
run;



   
/* From data */
proc sort data=tpmodel.data_for_modeling
	out=sorted 
	nodup;
    	by 
		prop_code 
		room_category
		arrival_date;
	where  prop_code="NYCMQ" and room_category=1
		and actual_demand>0 
		and ~missing(ratio)
		and ~missing(room_category);

run;	
data sorted;
	set sorted;
	logdemand=log(actual_demand);
	logratio=log(ratio);
	rtdemand=sqrt(actual_demand);
	rtlogdemand=sqrt(log(actual_demand));
run;

proc sql; 
	select count(*) 
		into :n 
		from sorted 
		where room_category=1;
quit;

%let n=&n;
proc sort data=sorted;
	by ratio;
run;
data filliben; 
	set sorted;
	if _n_=1 then m=1-0.5**(1/&n;
	else if _N_<&n then m=(_n_-0.3175)/(&n+0.365);
	else m=0.5**(1/&n);
	t=sqrt(log(1/(m**2)));
	c0=2.515517;
	c1=0.802853;
	c2=0.010328;
	d1=1.432788;
	d2=0.189269;
	d3=0.001308;
	xp=-(t-((c0+c1*t+c2*t**2)/(1+d1*t+d2*t**2+d3*t**3)));
	keep ratio xp m;
run;

title "Normal Probability Plot Correlation Coefficient R";
symbol1 v=dot c=blue;
proc gplot data=filliben;
plot xp*ratio;
run;
proc corr data=filliben;
	var ratio xp;
run;
title Normal QQ Plot for Ratio;
ods select TestsForNormality;
proc univariate data=filliben normaltest;
	var ratio;
	qqplot ratio;
run;


/* take 3 - generate the empirical probability tables */

%macro fillibenprob(samp_n,tn);
	%local i;
	options nonotes;
	%do i=1 %to &tn;
		%put LOOPDETAILS: &i of &tn;
		data randomnormal;
			do i=1 to &samp_n;
				x=rannor(&i);
				output;
			end;
		run;quit;
		proc sort data=randomnormal; 
			by x; 	
		run;quit;
		data filliben; 
			set randomnormal;
			if _n_=1 then m=1-5**(1/&samp_n);
			else if _N_<&samp_n then m=(_n_-0.3175)/(&samp_n+0.365);
			else m=0.5**(1/&samp_n);
			t=sqrt(log(1/(m**2)));
			c0=2.515517;
			c1=0.802853;
			c2=0.010328;
			d1=1.432788;
			d2=0.189269;
			d3=0.001308;
			xp=-(t-((c0+c1*t+c2*t**2)/(1+d1*t+d2*t**2+d3*t**3)));
			keep x xp m;
		run;quit;
		proc corr data=filliben out=corr&i noprint;
			var x xp;
		run;quit;
		data corr;
			set %if &i>1 %then %do; corr %end; corr&i(where=(_name_='xp'));
		run;quit;
		proc sql; drop table corr&i; quit;
	%end;
	options notes;
	quit;
%mend;
%fillibenprob(100,1000);

proc univariate data=corr;
	var x;
	qqplot x; histogram x;
	output out=Pctls pctlpre=x pctlpts = .05 1 2.5 5 10 25 50 75 90 95 97.5 99 99.5
						pctlname=_p_005 _p_01 _p_025 _p_05 _p_1 _p_25 _p_5 _p_75 _p_90 _p_95 _p_975 _p_99 _p995;
run;

