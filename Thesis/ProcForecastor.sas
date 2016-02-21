*forecastor;

data riverwork; set thesis.allrivers95_02;
	format datetime datetime. forby YYQ4. ;
	dtme=datepart(datetime);
	*month=month(dtme);
	*tme=timepart(datetime);
	forby=yyq(year(dtme),qtr(dtme));
run;

proc forecast 
	data=riverwork
	method=stepar
	out=forecast_out
	outall
	outest=forest;
	by forby;
	var sal8504_stage als1000_stage cong9500_stage;
run;
	