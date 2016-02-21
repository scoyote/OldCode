/**********************************************************************
*	Program Name	:	$RCSfile: BoxplotGraphics.sas,v $
*	REV/REV AUTH	:	$Revision: 1.1 $ $Author: scoyote $
*	REV DATE		:	$Date: 2007/05/31 11:45:43 $
* 
*   CREATOR:   SAMUEL T. CROKER
*   DATE:      16 May 2007
*   DESC:      Hybrid template for boxplots. This is an experimental
*				program to test some of the abilities of 9.2 release
***********************************************************************/


data atlbk;
	set tpmodel.reservations_su_nonqual;
	dow=weekday(arrival_date);
	where  prop_code='ATLBK';
run;
proc sort data=atlbk out=sorted;
	by prop_code arrival_date;
	
run;

proc means data=sorted noprint nway;
	class prop_code dow;
	output out=moments(rename=(_freq_=N) drop=_type_)
		mean(actual_rooms)=mean 
		median(actual_rooms)=median 
		std(actual_rooms)=std
		q1(actual_rooms)=q1
		q3(actual_rooms)=q3
		p10(actual_rooms)=p10
		p90(actual_rooms)=p90
		kurt(actual_rooms)=kurt
		skew(actual_rooms)=skew
		;
run;
data plotset;
	merge sorted(in=y1)  moments;
	by prop_code;
	if y1;
run;

ODS PATH work.templat(update) sasuser.templat(read) sashelp.tmplmst(read);
proc template;	
	define statgraph mygraphs.boxplot;
		dynamic _mean _std _median _q1 _q3 _p10 _p90 _kurt _skew;
		layout gridded /columns=2 rows=2;
			layout overlay ;
				boxplot y=actual_rooms x=dow ;
			endlayout;
			layout overlay ;
				histogram actual_rooms ;
				densityplot actual_rooms;
			endlayout;
			layout overlay ;
				layout gridded / columns=2 ;
					entry "Mean:" / halign=left; 		entry _mean / halign=left format=10.2;
					entry "Std:" / halign=left; 		entry _std / halign=left format=10.2;
					entry "Median:" / halign=left;	entry _median / halign=left format=10.2;
					entry "Q1:" / halign=left;		entry _q1 / halign=left format=10.2;
					entry "Q3:" / halign=left;		entry _q3 / halign=left format=10.2;
					entry "P10:" / halign=left;		entry _p10 / halign=left format=10.2;
					entry "P90:" / halign=left;		entry _p90 / halign=left format=10.2;
					entry "Kurtosis:" / halign=left;	entry _kurt / halign=left format=10.2;
					entry "Skew:" / halign=left;		entry _skew / halign=left format=10.2;
				endlayout;
			endlayout;
		endlayout;
	end;
run;



data _null_;
	set plotset;
	by prop_code;
	file print ods=( template='mygraphs.boxplot' 
		dynamic=(
			_mean=mean 
			_std=std 
			_median=median
			_q1=q1
			_q3=q3
			_p10=p10
			_p90=p90
			_kurt=kurt
			_skew=skew
			));
	put _ods_;
run;

