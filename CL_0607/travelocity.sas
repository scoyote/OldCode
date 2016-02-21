
filename airl url 'http://www.expedia.com/pub/agent.dll?qscr=fexp&flag=q&city1=Washington%2C+DC+%28DCA%2DRonald+Reagan+National%29&citd1=cae&date1=1/26/2007&time1=362&date2=1/29/2007&time2=362&cAdu=1&cSen=&cChi=&cInf=&infs=2&tktt=&trpt=2&ecrc=&eccn=&qryt=8&load=1&airp1=DCA&dair1=&rfrr=-429';

data test;
	infile airl lrecl=32000;
	file 'C:\Documents and Settings\scrok586\Desktop\output.txt';
	input;
	if ~missing(_infile_) then put _infile_;
run;

filename airl clear;

data urlsearch;
	input urlid $100. 
datalines;
http://travel.travelocity.com/flights/InitialSearch.do?flightType=roundtrip	Service=TRAVELOCITY	last_pgd_page=ushpnbff.pgd	maxConnections=	entryPoint=CB	leavingFrom=CAE	goingTo=dca	dateTypeSelect=exactDates	leavingDate=1%2F26%2F2007	dateLeavingTime=Anytime	departDateFlexibility=1	returningDate=1%2F29%2F2007	dateReturningTime=Anytime	returnDateFlexibility=1	departure_dt=Jan	arrival_dt=May	adults=1	children=0	seniors=0	minorsAge0=	minorsAge1=	minorsAge2=	minorsAge3=	minorsAge4=	submitFO=0		
;
run
	if _n_=1 then do;
		prx_airline =	prxparse('/<td class="tfAirline " valign="top">/');
		prx_depart =	prxparse('/<td class="tfDepart "/');
		prx_arrive =	prxparse('/<td class="tfArrive "/');
		prx_row = 	prxparse('/<TR ID="Flight/');
		retain 
			prx_airline
			prx_depart
			prx_arrive
			prx_table;
	end;

*);*/;/*'*/ /*"*/; %MEND;run;quit;;;;;
*);*/;/*'*/ /*"*/; %MEND;run;quit;;;;;
*);*/;/*'*/ /*"*/; %MEND;run;quit;;;;;
*);*/;/*'*/ /*"*/; %MEND;run;quit;;;;;
*);*/;/*'*/ /*"*/; %MEND;run;quit;;;;;
*);*/;/*'*/ /*"*/; %MEND;run;quit;;;;;
	if tableflag=0 then 
	else do; 
		do until(index(_infile_,"</tr>")>0);
			input;
			datarow=trim(datarow)||_infile_;
			put datarow;
		end;
	end;
