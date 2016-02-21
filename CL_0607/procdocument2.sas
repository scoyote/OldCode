ods document name=Gdocument(write);
	ods graphics on ;
		title "PROC ARIMA Step";
		proc arima data=sashelp.air; 
			identify var=air(1,12) nlag=15; 
		run; 	
		quit;
	ods graphics off;
ods document close;

/* list things out - this is handy to see what paths you have but not necessary*/
ods output properties=docds(keep=path type label);
title PROC DOCUMENT Listing;
proc document name=gdocument;
	list /details levels=all;
run;
quit;
ods output close;
proc print data=docds noobs;
run;
title;
/* end listing */

/* replay both text and graphs into different reports */
ods rtf file='tables.rtf';
proc document;
	doc name=gdocument;
	replay \Arima#1\Identify#1\DescStats#1;
	replay \Arima#1\Identify#1\ChiSqAuto#1;
run;
quit;
ods html close;

ods rtf file='graphs.rtf';
proc document;
	doc name=gdocument;
	replay \Arima#1\Identify#1\SeriesACFPlot#1;
	replay \Arima#1\Identify#1\SeriesIACFPlot#1;
	replay \Arima#1\Identify#1\SeriesPACFPlot#1;
run;
quit;
ods rtf close;
title;




ods graphics on ;
		title "PROC ARIMA Step";
		proc arima data=sashelp.air; 
			identify var=air(1,12) nlag=15; 
		run; 	
		quit;
ods graphics off;
data _null_ ;
	set sashelp.air;
		file print ods=( template='statgraph.correlation.acfplot' 
			objectlabel='ACF Plot');
		put _ods_;
run;