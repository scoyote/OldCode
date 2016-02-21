*****************************************************************
* Create report using a CR Toolkit graph4 call.
****************************************************************;
proc catalog catalog=gseg kill; run;quit;

data air;
	set sashelp.air;
	logair=log(air);
	rootair=sqrt(air);
run;
title2 air vs date;
ods document name=sdocument(write);
	symbol1 v=dot h=.5 i=j c=blue;
	proc gplot data=air;
		plot air*date ;
		plot logair*date;
		plot rootair*date;
	run;quit;
	proc print data=sashelp.class label;
	run;
ods document close;

/*** Get the document information for bookmark removal ***/
ods output properties=docds(keep=path type label);
proc document name=sdocument;
	list /details levels=all;
	run;
quit;
ods output close;

proc document name=sdocument;
	setlabel ^\Gplot#1 "TopLevelGraph";
	setlabel ^\Gplot#1\gplot#1 "Air*Date";
	setlabel ^\Gplot#1\gplot1#1 "LOG(Air)*Date";
	setlabel ^\Gplot#1\gplot2#1 "SQRT(Air)*Date";
	setlabel ^\Print#1 "ToplevelPrint";
	setlabel ^\Print#1\Print#1 "Class Report";
run;
quit;

ods pdf file="C:\Documents and Settings\scrok586\Desktop\Output\odocument_all.pdf";

	proc document;
		doc name=sdocument;
		replay ^ ;
	run;
	quit;
ods pdf close;





data _null_; set docds;
/*(where=(type ne "Dir"));*/
	if type='Dir' then do;
		lev+1;
		call symput('lev',compress(lev));
		entrycount=0;
	end;
	else do;
		entrycount+1;
		Call symput(compress("count"||lev),trim(entrycount));
	end;
	call symput(compress('type'||lev||'_'||entrycount),type);
	Call symput(compress("path"||lev||'_'||entrycount),trim(left(path)));
	Call symput(compress("label"||lev||'_'||entrycount),trim(left(label)));
run;

%macro listlevels;
	%do i=1 %to &lev;
		%put count&i=&&count&i;
		%put type&i._0=&&type&i._0;
		%do j=1 %to &&count&i;
			%put type&i._&j=&&type&i._&j;
			%put path&i._&j=&&path&i._&j;
		%end;
	%end;
%mend;
%listlevels;


/*** Replay the document into pdf with bookmarks ***/
/*** removed and titles as bookmark text ***/
filename g1 "C:\Documents and Settings\scrok586\Desktop\Output\";
ods pdf file="C:\Documents and Settings\scrok586\Desktop\Output\odocument_all.pdf";
%macro listlevels;
	proc document;
		doc name=sdocument;
		%do i=1 %to &lev;
			copy &&path&i._0 to \G1;
			setlabel \G1 "%trim(&&label&i._0)";
			replay \G1 /levels=1;
			%put count&i=&&count&i;
			%do j=1 %to &&count&i;
				%put type&i._&j=&&type&i._&j;
				%put path&i._&j=&&path&i._&j;
				copy &&path&i._&j to \G1;
				setlabel \G1 "%trim(&&label&i._&j)";
				replay \G1 /levels=1;
			%end;
		%end;
	run;
	quit;
%mend;
%listlevels;
ods pdf close;
/*** removed and titles as bookmark text ***/

