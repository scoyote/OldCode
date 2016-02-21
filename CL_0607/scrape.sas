
%macro addtocars(infile,ds);
	filename carmax url "&infile";
	data _null_;
		infile carmax lrecl=32000;
		input;
		if _n_=1 then do;
			rowpat =	prxparse('/<td class="tc1">/');
			fpat=	prxparse("s/((<td).*?>)/\//");
			fpat2=	prxparse("s/(<.*?>)/ /");

			retain rowpat fpat fpat2 ;
		end;
		file 'C:\Documents and Settings\scrok586\Desktop\cars.txt';
	      /* Use PRXMATCH to find the position of the pattern match. */
	   	position=prxmatch(rowpat, _infile_);
	   	if position>0 then do;
			datarow=	_infile_;
			caridpos=	index(datarow,":pf(");
			if caridpos>5 then carid=substr(datarow,caridpos+5,7);
			datarow= 	prxchange(fpat, -1, datarow);
			datarow= 	prxchange(fpat2, -1, datarow);
			if ~missing(carid) then put carid  datarow;
		end;
	run;

	filename carmax clear;

	data temp; 
		length carid  f1  f2  year  Make  Model  ltd  Desc  f3  price  miles  Color  trans $24 unk $5 location  transfer $25;
		keep dateloadtime carid year  Make  Model  ltd  Desc  price  miles  Color  trans  location  transfer ;
		dateloadtime=datetime();
		infile 'C:\Documents and Settings\scrok586\Desktop\cars.txt' dlm='/' dsd;
		input carid $ f1 $ f2 $ year $ Make $ Model $ ltd $ Desc $ f3 $ price $ miles $ Color $ trans $ unk $ location $ transfer $;
	run;
	proc sql;
		insert into stc.&ds select * from temp;
		drop table temp;
	quit;

%mend;
/*
proc sql;
delete from stc.vr;
quit;
*/
libname stc "C:\Documents and Settings\scrok586\My Documents\ADMINSamC";
%addtocars(%nrstr(http://www.carmax.com/dyn/search/searchresults.aspx?newused=1&make=GM&model=0&vehtype=80&locnum=7265&pr1=2&pr2=12&es=T&esx=1&zd=&m=28),VR);
%addtocars(%nrstr(http://www.carmax.com/dyn/search/searchresults.aspx?newused=1&make=CH&model=0&vehtype=70&locnum=7265&pr1=2&pr2=7&es=T&esx=1&zd=&m=28),VR);
%addtocars(%nrstr(http://www.carmax.com/dyn/search/searchresults.aspx?newused=1&make=FO&model=0&vehtype=80&locnum=7265&pr1=2&pr2=12&es=F&esx=1&zd=&m=28),VR);

proc sql;
title "Duplicate Cars";
select 
	 carid
	, count(*) 
	from stc.vr 
	group by carid having count(*)>1;
quit;
proc sort data=stc.vr nodup;
	by dateloadtime carid;
run;
