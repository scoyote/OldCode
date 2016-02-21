/**********************************************************************
*	Program Name	:	$RCSfile: shapirowilktest.sas,v $
*	REV/REV AUTH	:	$Revision: 1.1 $ $Author: scoyote $
*	REV DATE		:	$Date: 2007/05/31 11:45:43 $
* 
*   CREATOR:   SAMUEL T. CROKER
*   DATE:      9 May 2007
*   DESC:      Sample size sensitivity for normality tests
***********************************************************************/ 

proc format;
	value pcateg 
		low - 0.05 	= "Reject (alpha=0.05)"
		0.05 - high	 	= "Fail to Reject (alpha=0.05)";
run;

/* Build a small population from the normal distribution*/ 
data sorted;
	do i=1 to 500;
		ran_nor=rannor('09may2007'd);
		output;
	end;
run;

%macro testswsample(numsamples);
	%local i;
	options nonotes;
	%do i=1 %to &numsamples;
		%put DOSTATUS: &i of &numsamples;
		data sample;
			set sorted;
			rnum=ranuni('10may2007'd+&i);
		run;
		proc sort data=sample; by rnum; run;
		data sample; set sample(obs=50);run;
		ods output TestsForNormality=norm;
		proc univariate data=sample NORMALTEST;
			var ran_nor;
		run;quit;
		data fullnorm;
			set %if &i>1 %then %do; fullnorm %end;norm;
		run;	
	%end;
	options notes;quit;
%mend;
%testswsample(100);

data shapwilk;
	set fullnorm;
	obs=_n_;
	where testlab='W';
run;

proc freq data=shapwilk ;
	format pvalue pcateg.;
	table pvalue;
run;


/* test on real data */

proc sort data=tpmodel.data_for_modeling
	out=sorted 
	nodup;
    	by 
		prop_code 
		room_category
		arrival_date;
	where  prop_code="SJCGA" and room_category=1
		and actual_demand>0 and ~missing(room_category);

run;	
data sorted;
	set sorted;
	logdemand=log(actual_demand);
	logratio=log(ratio);
	rtdemand=sqrt(actual_demand);
	rtlogdemand=sqrt(log(actual_demand));
run;

%macro testswsample(numsamples);
	%local i;
	options nonotes;
	%do i=1 %to &numsamples;
		%put DOSTATUS: &i of &numsamples;
		data sample;
			set sorted;
			rnum=ranuni('09may2007'd+&i);
		run;
		proc sort data=sample; by rnum; run;
		data sample; set sample(obs=50);run;
		ods output TestsForNormality=demandnorm;
		proc univariate data=sample NORMALTEST;
			var logdemand;
		run;
		ods output TestsForNormality=rationorm;
		proc univariate data=sample normaltest;
			var ratio;
		run;
		data fulldemandnorm;
			set %if &i>1 %then %do; fulldemandnorm %end; demandnorm;
		run;	
		data fullrationorm;
			set %if &i>1 %then %do; fullrationorm %end; rationorm;
		run;
		
	%end;
	options notes;
	quit;
%mend;
%testswsample(100);

data RAT_shapwilk;
	set fullrationorm;
	obs=_n_;
	where testlab='W';
	keep prop_code room_category pvalue;
	rename pvalue=RAT_pvalue;
run;

data DMD_shapwilk;
	set fulldemandnorm;
	obs=_n_;
	where testlab='W';
	keep prop_code room_category pvalue;
	rename pvalue=DMD_pvalue;
run;

proc freq data=rat_shapwilk ;
	format rat_pvalue pcateg.;
	table rat_pvalue;
run;

proc freq data=dmd_shapwilk ;
	format dmd_pvalue pcateg.;
	table dmd_pvalue;
run;

