libname sam 'D:\intrnet';

DATA repdat;
	set sam.reportdata(rename=(state=st));
	state=stfips(st);
	county=upcase(county);
	status=compress(sts_cd||sts_r_cd);
run;
proc means data=repdat noprint nway;
	class state county status;
	output out=repdatm(drop=_type_ _freq_) n(prv_no)=count;
run;
data county (rename=(countynm=county));
		merge maps.uscounty(in=y1 where=(upcase(fipstate(state))in ('SC','GA','FL','NC','AL','PR')))
			  maps.cntyname(in=y2 where=(upcase(fipstate(state))in ('SC','GA','FL','NC','AL','PR')));
		by state county;
		if y1 and y2;
		drop county;
run;
proc sort data=repdatm; by state county;run;
proc sort data=county; by state county;run;

data map;
		merge county(in=y1)
			  repdatm(in=y2);
		by state county;
		if y1;
	run;






/*	goptions reset=all gunit=pct border cback=white*/
/*	         colors=(bwh blue green yellow orange red magenta)*/
/*	         ctext=black ftext=swiss htitle=6 htext=3;*/
/*	title;*/

	proc gmap map=map data=map;
	   id state county;
	   choro count / coutline=gray levels=4 ;
	run;
	quit;

