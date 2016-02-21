
data lex;
		merge maps.uscounty(in=y1 where=(upcase(fipstate(state))="SC"))
			  maps.cntyname(in=y2 where=(upcase(fipstate(state))="SC"));
		by state county;
		if y1 and y2;
		count=int(ranuni(12345)*100);
	run;
%annomac;
%CENTROID(lex, lex2, state county countynm);
data annot;
	length function $8 ;
	retain flag 0 xsys ysys '2' hsys '3' when 'a' style 'Courier';
	set lex2;
	function='label';
	text=COUNTYNM;
	size=1;
	position='5';
run;

	goptions reset=all gunit=pct border cback=white
	         colors=(bwh blue green yellow orange red magenta)
	         ctext=black ftext=swiss htitle=6 htext=3;
	title;

	proc gmap map=lex data=lex anno=annot;
	   id state county;
	   choro count / coutline=gray levels=6 ;
	run;
	quit;
