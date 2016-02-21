/**********************************************************************
*	Program Name	:	$RCSfile: Scatterplotmatrices.sas,v $
*	REV/REV AUTH	:	$Revision: 1.1 $ $Author: scoyote $
*	REV DATE		:	$Date: 2007/05/31 11:45:43 $
* 
*   CREATOR:   SAMUEL T. CROKER
*   DATE:      16 May 2007
*   DESC:      Hybrid template for Scatterplots.
***********************************************************************/
ODS PATH work.templat(update) sasuser.templat(read) sashelp.tmplmst(read);
proc template;	
	define statgraph mygraphs.scatterplot;
		dynamic _pc _rc;
		layout gridded/ rows=2 height=1000 width=1000;
			layout gridded / columns=2 rows=1;
				entrytitle _pc ; 
				entrytitle _rc ;
			endlayout;
			scatterplotmatrix 	actual_demand 
							avg_net_rate_act 
							/*simple_avg_rate_td 
							property_occ 
							comp_occ 
							mkt_occ 
							group_occ*/ 
							comprate6avg
							rubmarrate6avg 
							ratio
					/markers=CIRCLEODDFILLED 
					 markersize=3px;

		endlayout;
	end;
run;

goptions device=activex;
data _null_ ;
	set tpmodel.data_for_modeling;
	where prop_code="IADDS" and room_category=1;
	file print ods=( template='mygraphs.scatterplot' 
		dynamic=(_pc=prop_code _rc=room_category) 
		objectlabel='Scatterplot Matrix');
	put _ods_;
run;


/* functionality to run all properties.  This is the part I am working on */


%macro gengraph(property,roomcat);
	ods proclabel "&property Room Category: &roomcat";
	data _null_ ;
		set tpmodel.data_for_modeling;
		where prop_code="&property" and room_category=&roomcat;
		file print ods=( template='mygraphs.scatterplot' 
			dynamic=(_pc=prop_code _rc=room_category) 
			objectlabel='Scatterplot Matrix');
		put _ods_;

	run;
%mend;

%macro multiplescatterplotreport;
	%local numprops prop;
	
	proc sql noprint;
		create table proptable as 
			select distinct prop_code, room_category from sorted;
		select count(*) into :numprops from proptable;
		%let numprops=&numprops;
	quit;
	%do prop=1 %to &numprops;
		%local rc&prop;
		%local pc&prop;
	%end;
	proc sql noprint;
		select distinct prop_code, room_category into :pc1-:pc&numprops, :rc1-:rc&numprops from proptable;
	quit;
	options nonotes;
	ods pdf file='/tpr/stcroker/output/scatterplotmatrices.pdf';
	%do prop=1 %to &numprops;
		%put PROCINFO: Printing &&pc&prop, &&rc&prop (&prop of &numprops);
		%gengraph(&&pc&prop,&&rc&prop);
	%end;
	ods pdf close;
	options notes;
%mend multiplescatterplotreport;
%multiplescatterplotreport;