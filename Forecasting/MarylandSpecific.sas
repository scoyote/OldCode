filename maryland url "http://waterdata.usgs.gov/nwis/uv?period=31%str(&)multiple_site_no=01581920,01582000,01595000,01609000,01596500,01597500,01598500,01649150,03075500,03076500,01591000,03078000,03079000%str(&)format=rdb";
/**/
/*options datestyle=ydm;*/
/*data maryland;*/
/*	infile maryland end=eof dlm='09'x dsd;	*/
/*	length agency_cd $5 site_no $30 flow 8 stage 8 precip 8;*/
/*	input agency_cd @;*/
/*	if agency_cd~='USGS' then delete; */
/*	else input site_no $ dtm $16. fil1 $ stage fil2 $ flow ?? $fil3 $ ?? precip ??;*/
/*	date=input(substr(dtm,1,10),anydtdte10.);*/
/*	time=input(substr(dtm,12,5),anydttme5.);*/
/*datestamp=dhms(date,hour(time),minute(time),0);	*/
/*	drop  fil1 fil2 fil3 date time;*/
/*	format datestamp datetime16.;*/
/*run;*/

/* count the observations for each site */
proc sql;
	select site_no, count(*) from maryland
	group by site_no;
quit;

proc timeseries data=maryland out=working;
	by site_no;
	id datestamp interval=hour accumulate=max;
	var stage flow precip;
run;

proc sql;
	select site_no, count(*) from working
	group by site_no;
quit;

filename sitename url "http://waterdata.usgs.gov/nwis/inventory?multiple_site_no=01581920,01582000,01595000,01609000,01596500,01597500,01598500,01649150,03075500,03076500,01591000,03078000,03079000%str(&)format=rdb%str(&)column_name=agency_cd%str(&)column_name=site_no%str(&)column_name=station_nm";

data sitenames;
	infile sitename dlm='09'x dsd lrecl=500 truncover;
	length agency_cd $5	site_no $15 station_nm $50	 ;
	input agency_cd $ site_no $ station_nm  $ ;
	if substr(agency_cd,1,4)~='USGS' then delete;
run;

%macro buildarimaspecs;	
	%let mdl=0;
	%do p=0 %to 3;
		%do q=0 %to 3;
			%do d=0 %to 2;
				%if &d=0 %then %let dif=0;
				%if &d=1 %then %let dif=1;
				%if &d=2 %then %let dif=7;

				%let mdl=%eval(&mdl+1);
			 	proc hpfarimaspec repository=work.arima name=amd&mdl; 
			        forecast symbol=stage transform=none p=&p dif=&dif q=&q;
			        estimate method=ml;
			    run;
			 	proc hpfarimaspec repository=work.arima name=bmd&mdl; 
			        forecast symbol=stage transform=boxcox(0.5) p=&p dif=&dif q=&q;
			        estimate method=ml;
			    run;
			 	proc hpfarimaspec repository=work.arima name=cmd&mdl; 
			        forecast symbol=stage transform=none noint p=&p dif=&dif q=&q;
			        estimate method=ml;
			    run;
			 	proc hpfarimaspec repository=work.arima name=dmd&mdl; 
			        forecast symbol=stage transform=boxcox(0.5) noint p=&p dif=&dif q=&q;
			        estimate method=ml;
			    run;
			%end;
		%end;
	%end;
/*	 add some specs here for ucm and esm to complete the set */
/*	proc hpfesmspec */
/*		repository=work.arima*/
/*		label="Best ESM"*/
/*		name=ESMBEST;*/
/*		esm method=best transform=auto select=mape;*/
/*	run;*/
%mend buildarimaspecs;

proc catalog catalog=work.arima kill; run;quit;
%buildarimaspecs;
proc catalog catalog=work.arima; contents out=speccont; run; quit;
proc sql noprint;
	select distinct name into :spec separated by ' ' from speccont; 
quit;
%put &spec;
proc hpfselect repository=work.arima
         name=myselect 
         label="My Selection List"; 
	select criterion=mape holdout=72; 
	spec &spec ;
run;

%let interval=hour;
%let back=0;
%let lead=24;

proc hpfdiag data=maryland
		print=all 
		repository=work.arima  
		criterion=mape
		outest=diagest; 
	by site_no;
    id datestamp interval=hour accumulate=avg;
    forecast stage;
	arimax outlier=(detect=maybe) method=minic;
	trend dif=auto;
	transform type=auto;
run;


ods output modelselection=mdlselect parameterestimates=estimates;
proc hpfengine 
		repository=work.arima
/*		globalselection=myselect*/
		inest=diagest
		data=maryland
		outfor=outfor
		outest=outest 
		back=&back
		lead=&lead
        print=(select estimates);
	by site_no;
    id datestamp interval=hour accumulate=avg;
    forecast stage;
 run;


ODS PATH work.templat(update) sasuser.templat(read) sasuser.tmplmst(read);
proc template;
	define statgraph mygraphs.stcfor;
	dynamic graphtit;
	layout lattice /width=900 height=200 border=false;
		layout overlay /border=false	
			xaxisopts=(display=(values TICKS) )
			yaxisopts=(display=all label="Stage" ) 
;
		entrytitle graphtit/
				fontsize=12
				fontweight=bold
				halign=left
				padtop=0
				padbottom=0
				valign=top;

			Band
				ylimitlower=fit_lower
				ylimitupper=fit_upper
				x=datestamp / 
					fill=true 
					lines=false 
					fillcolor=ywh
					legendlabel="Fit CI" 
					name="Conf1";
			Band
				ylimitlower=holdout_lower
				ylimitupper=holdout_upper
				x=datestamp / 
					fill=true 
					lines=false 
					fillcolor=bwh
					legendlabel="Holdout CI" 
					name="Conf2";
			Band
				ylimitlower=fcst_lower
				ylimitupper=fcst_upper
				x=datestamp / 
					fill=true 
					lines=false 
					fillcolor=pkwh
					legendlabel="Forecast CI" 
					name="Conf3";
			scatter X=datestamp Y=actual  /name="act"  legendlabel="Actual Stage"  markers=true markersymbol=circlefilled markercolor=black ;
			SERIES X=datestamp Y=predict /name="pred" legendlabel="Predicted Stage" markers=false linecolor=blue;
		
		endlayout;
	endlayout;
	end;
run;

ODS PATH work.templat(update) sasuser.templat(read) sasuser.tmplmst(read);
proc template;
	define statgraph mygraphs.stcspk;

	layout lattice /width=900 height=200 border=false;
		layout overlay /border=false	
			xaxisopts=(display=none)
			yaxisopts=(display=none) 
;
			Band
				ylimitlower=fcst_lower
				ylimitupper=fcst_upper
				x=datestamp / 
					fill=true 
					lines=false 
					fillcolor=pkwh
					legendlabel="Forecast CI" 
					name="Conf3";
			scatter X=datestamp Y=actual  /name="act"  legendlabel="Actual Stage"  markers=true markersymbol=circlefilled markercolor=black ;
			SERIES X=datestamp Y=predict /name="pred" legendlabel="Predicted Stage" markers=false linecolor=blue;
		
		endlayout;
	endlayout;
	end;
run;


proc sql;
	select max(datestamp) into :MD from maryland where site_no='03078000';
quit;
data _null_;
			set outfor;
/*			where site_no='03078000';*/
			if datestamp>&MD then
					fcst_lower=lower; fcst_upper=upper;
			
				file print ods=( template='mygraphs.stcspk' 
					objectlabel='Forecast Plot' );
				put _ods_ ;
		run;


title;
%macro plotforecast;
	proc sql noprint;
		select count(distinct site_no) into :numsites from maryland;
		%let numsites=&numsites;
		select site_no
			 , max(datestamp) format=30.
			 , min(datestamp) format=30.
			into 
				 :siteno1-:siteno&numsites 
				,:maxdt1-:maxdt&numsites
				,:mindt1-:mindt&numsites
			from maryland 
			group by site_no;
	quit; 
	goptions device=pdfc;
	ods html gpath='C:\Documents and Settings\scoyote\Desktop\Output';
	%do i=1 %to &numsites;	
		%put EXECUTION: &&siteno&i &&maxdt&i back=&back;
		ods graphics on /reset imagename="&&siteno&i..B&back._L&lead._" imagefmt=jpeg border=off;
	
	
		data _null_;
			merge outfor(
						where=(compress(site_no)=compress("&&siteno&i") and datestamp>=intnx('hour',&&maxdt&i,-%sysevalf(&back+168)))
						rename=(lower=low upper=up)
						in=outfor)
				  sitenames;
			by site_no;
			call symput('sitename',station_nm);
			if outfor;
			if datestamp<=intnx('hour',&&maxdt&i,-&back) then do;
					fit_lower=low; fit_upper=up;
			end;
			else if datestamp<=&&maxdt&i then do;
					holdout_lower=low; holdout_upper=up;
			end;
			else if datestamp>&&maxdt&i then do;
					fcst_lower=low; fcst_upper=up;
			end;
				file print ods=( template='mygraphs.stcfor' 
					objectlabel='Forecast Plot' dynamic=(graphtit=station_nm) );
				put _ods_ ;
		run;

/*	%threeregionforecast(outfor(where=(site_no="&&siteno&i"))*/
/*		,&&maxdt&i*/
/*		,&&mindt&i*/
/*		,24*/
/*		,24*/
/*		,grtitle="sitename"*/
/*		,dtm=datestamp	*/
/*		,lciname=lower*/
/*		,uciname=upper*/
/*		,fcname=predict*/
/*		,varname=actual*/
/*		,dtformat=dthour.*/
/*		,xinterval=hour.*/
/*		,xminorticks=3*/
/*		,ymajnum=6*/
/*		,vaxisvalh=2*/
/*		,dtdisplay=tod5.*/
/*		,acth=.5*/
/*		,hatitle=""*/
/*		,vatitle="Stage"*/
/*		,mini=YES);*/
	%end;	
	ods html close;
	ods graphics off;
%mend;



libname gdevice0 'C:\Documents and Settings\scoyote\Desktop\Output';
proc gdevice nofs catalog=gdevice0.devices;
	/* include this row to build the device, then comment it out */
	   copy pdf from=sashelp.devices newname=spbw;
	   modify spbw
	     description='PDF Sparkline 12pt*144pt'
		 /* size+origin<=max */
/*			xmax=3.750in	horigin=0.000	hsize=3.750*/
/*			ymax=0.125in	vorigin=0.000	vsize=0.125*/
/*			xpixels=1200*/
/*			ypixels=42*/
			xmax=3.750in	horigin=0.000	hsize=3.750
			ymax=0.125in	vorigin=0.000	vsize=0.125
			xpixels=1200
			ypixels=42/* 48 naturally */
			prows=0
			pcols=0		
			lrows=31
			lcols=60

			;
	quit;
	proc gdevice nofs catalog=gdevice0.devices;
	/* include this row to build the device, then comment it out */
	   copy pdfc from=sashelp.devices newname=spcolor1;
	   modify spcolor1
	     description='PDF Sparkline 12pt*144pt'
		 /* size+origin<=max */
/*			xmax=3.750in	horigin=0.000	hsize=3.750*/
/*			ymax=0.125in	vorigin=0.000	vsize=0.125*/
/*			xpixels=1200*/
/*			ypixels=42*/
			xmax=3.750in	horigin=0.000	hsize=3.750
			ymax=0.125in	vorigin=0.000	vsize=0.125
			xpixels=1200
			ypixels=42/* 48 naturally */
			prows=0
			pcols=0		
			lrows=31
			lcols=60

			;
	quit;
/* sample usage */
%macro plotsparkline(siteno,variable);
	filename gsasfile "C:\Documents and Settings\scoyote\Desktop\Output\&variable&siteno..pdf"; 
	proc sql noprint;
		select min(datestamp), max(datestamp) into :mindt, :maxdt from maryland
			where site_no="&siteno";
	quit;
	goptions 
		reset=all 
		cback=white
		noborder
		gaccess=gsasfile
		gsfmode=replace
		device=spcolor1  /* here is where we include the device */
		;
	axis1 
		label=none 
		value=none 
		major=none 
		minor=none 
		order=(&mindt to &maxdt by 86400)
		c=white;
	axis2 
		label=none 
		value=none 
		major=none 
		minor=none 
		c=white;
	symbol1 i=j v=none c=black w=1;

	proc gplot data=maryland;
		plot &variable*datestamp /name="&variable&siteno" overlay noframe haxis=axis1 vaxis=axis2;
		where site_no="&siteno";
	run;quit;
%mend plotsparkline;

/*%plotsparkline(01581920,stage);*/
/*%plotsparkline(01582000,stage);*/
/*%plotsparkline(01595000,stage);*/
/*%plotsparkline(01609000,stage);*/
/*%plotsparkline(01596500,stage);*/
/*%plotsparkline(01597500,stage);*/
/*%plotsparkline(01598500,stage);*/
/*%plotsparkline(01649150,stage);*/
/*%plotsparkline(03075500,stage);*/
/*%plotsparkline(03076500,stage);*/
/*%plotsparkline(01591000,stage);*/
/*%plotsparkline(03078000,stage);*/
/*%plotsparkline(03079000,stage);*/


%macro plotsparklinefcst(siteno);
        proc sql noprint;
                select min(datestamp) format=30.,max(datestamp) format=30. into :mindt, :maxdt from outfor where site_no="&siteno";
                select max(datestamp) format=30. into :dataend from maryland where site_no="&siteno";
                select avg(stage)-1.5*std(stage),avg(stage)+1.5*std(stage) into :clow, :chigh from maryland where site_no="&siteno";

        quit;
        %put &mindt &maxdt &dataend;
        %let plotstart=%sysevalf(&dataend-(&lead*(3600*7)));
        %let forecaststart=&dataend;
        %put maxdt=%sysfunc(putn(&maxdt,datetime28.));
        %put dataend=%sysfunc(putn(&dataend,datetime28.));
        %put plotstart=%sysfunc(putn(&plotstart,datetime28.));
        %put forecaststart=%sysfunc(putn(&forecaststart,datetime28.));

        /* rebuild the output data so that the cis plot as polygons */
        data out(  drop=     sval)
                        low( keep=datestamp sval clev )
                        high(keep=datestamp sval clev);
                set outfor;
                where site_no="&siteno" and datestamp>=&plotstart;
                output out;
                if datestamp > &dataend then do;
                        sval=lower;clev=&clow; output low;
                        sval=upper;clev=&chigh; output high;
                end;
                else do;
                        sval=.;clev=&clow; output low;
                        sval=.;clev=&chigh; output high;
                end;
        run;
        /* sort the lower bound datasets so that the polygons will be drawn correctly */
        proc sort data=high; by datestamp;run;

        proc sort data=low; by descending datestamp; run;

        /* stack the low and high datasets in this way so that the graphs will be drawn correctly */
        data forecast;
                set 
                        low high
                        out;
                if datestamp=. then delete;
        run;

filename gsasfile "C:\Documents and Settings\scoyote\Desktop\Output\fc&siteno..pdf"; 

        /* draw the graph */
                goptions
                        reset=all
                        device=spcolor1
                        cback=white
                        noborder
                        gaccess=gsasfile
                        gsfmode=replace;
                title;
                symbol1 i=ms c=pkwh;
                symbol2 i=ms c=gwh;
                symbol3 i=j  v=none    c=black;

                axis1
                        label=none
                        value=none
                        major=none
                        minor=none
                        order=(&plotstart to &maxdt by dthour)
                        c=white;
                axis2
                        label=none
                        value=none
                        major=none
                        minor=none
                        c=white;

                proc gplot data=forecast;
                        plot 
                        clev*datestamp=2
                        sval*datestamp=1
                        predict*datestamp=3
                                /       haxis=axis1
                                        vaxis=axis2
                                        overlay ;
                run; quit;
%mend plotsparklinefcst;

%plotsparklinefcst(01581920);
%plotsparklinefcst(01582000);
%plotsparklinefcst(01595000);
%plotsparklinefcst(01609000);
%plotsparklinefcst(01596500);
%plotsparklinefcst(01597500);
%plotsparklinefcst(01598500);
%plotsparklinefcst(01649150);
%plotsparklinefcst(03075500);
%plotsparklinefcst(03076500);
%plotsparklinefcst(01591000);
%plotsparklinefcst(03078000);
%plotsparklinefcst(03079000);

