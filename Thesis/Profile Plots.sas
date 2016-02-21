/****************************************************	
*****	Saluda 1995-2002 Exploration Program 	*****
*****   SaludaExploratory.sas					*****
*****   Created 11-27-2003						*****
*****   Created by Sam Croker					*****
*****************************************************/	
options orientation=landscape;
*ods path ref.templat(update)
         sasuser.templat(read)
         sashelp.tmplmst(read);
*	run;
%let dataset= Saluda.Allrivers95_02;
%let inputvar1=logsal9000_flow;
%let inputvar2=logals1000_flow;
%let outputvar1=logcong9500_flow;
%let outputvar2=logcong9625_flow;

ods pdf file='C:\Documents and Settings\Samuel  Croker\Desktop\Thesis\Thesis Final\AllRiversProfiles.pdf';
goptions reset=all ftext="Tahoma";
	axis1 label=(f='tahoma' h=1.5) value=(f='tahoma'  h=1);
	axis2 label=( f='tahoma' h=1.5 angle=90 "Flow") value=(f='tahoma' h=1); 
	legend1 label=('Stations') value=(f='tahoma' h=1);
	symbol1 v=none	I=j c=blue 		pointlabel=none;
	symbol2 v=none	I=j c=green 	pointlabel=none;
	symbol3 v=none	I=j c=red 		pointlabel=none;
	symbol4 v=none	I=j c=orange 	pointlabel=none;
/*Plot the datetime profile*/
proc gplot data=&dataset;
	title1;
	plot 	&inputvar1*datetime &inputvar2*datetime	&outputvar1*datetime
			 /overlay haxis=axis1 vaxis=axis2 legend=legend1;
	where datetime between '01jan95/00:00:00'DT and '31dec95/00:00:00'DT ;
	format datetime datetime18.;
run;quit;
proc gplot data=&dataset;
	plot 	&inputvar1*datetime &inputvar2*datetime	&outputvar1*datetime
			 /overlay haxis=axis1 vaxis=axis2 legend=legend1;
	where datetime between '01jan96/00:00:00'DT and '31dec96/00:00:00'DT ;
	format datetime datetime18.;
run;quit;
proc gplot data=&dataset;
	plot 	&inputvar1*datetime &inputvar2*datetime	&outputvar1*datetime
			 /overlay haxis=axis1 vaxis=axis2 legend=legend1;
	where datetime between '1jan97/00:00:00'DT and '31dec97/00:00:00'DT ;
	format datetime datetime18.;
run;quit;
proc gplot data=&dataset;
	plot 	&inputvar1*datetime &inputvar2*datetime	&outputvar1*datetime
			 /overlay haxis=axis1 vaxis=axis2 legend=legend1;
	where datetime between '1jan98/00:00:00'DT and '31dec98/00:00:00'DT ;
	format datetime datetime18.;
run;quit;
proc gplot data=&dataset;
	plot 	&inputvar1*datetime &inputvar2*datetime	&outputvar1*datetime
			 /overlay haxis=axis1 vaxis=axis2 legend=legend1;
	where datetime between '1jan99/00:00:00'DT and '31dec99/00:00:00'DT ;
	format datetime datetime18.;
run;quit;
proc gplot data=&dataset;
	plot 	&inputvar1*datetime &inputvar2*datetime	&outputvar1*datetime
			 /overlay haxis=axis1 vaxis=axis2 legend=legend1;
	where datetime between '1jan00/00:00:00'DT and '31dec00/00:00:00'DT ;
	format datetime datetime18.;
run;quit;
proc gplot data=&dataset;
	plot 	&inputvar1*datetime &inputvar2*datetime	&outputvar1*datetime
			 /overlay haxis=axis1 vaxis=axis2 legend=legend1;
	where datetime between '1jan01/00:00:00'DT and '31dec01/00:00:00'DT ;
	format datetime datetime18.;
run;quit;
proc gplot data=&dataset;
	plot 	&inputvar1*datetime &inputvar2*datetime	&outputvar1*datetime
			 /overlay haxis=axis1 vaxis=axis2 legend=legend1;
	where datetime between '1jan02/00:00:00'DT and '31dec02/00:00:00'DT ;
	format datetime datetime18.;
run;quit;
ods pdf close;