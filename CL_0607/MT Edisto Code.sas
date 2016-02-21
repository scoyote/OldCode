libname stcroker '/ty/stcroker';
data edisto; set stcroker.testdata1;  run;


proc catalog catalog=SASHELP.HPFDFLT ; copy out=work.arima ; run;
proc catalog catalog=work.arima kill ; run;quit;

proc hpfarimaspec 
		repository=work.arima 
		name=smodel1 
		label='Sam1';
	forecast
		noint
		symbol=stage02175000 
		p=2 
		q=1 
		dif=1 ; 
	input symbol=stage02173051 dif=1 num=1 den=1 delay=54 ;
run;

proc catalog catalog=work.arima; contents OUT=SPECS; run;
proc sql; select distinct name into :specs from specs; quit;
proc hpfselect 
		repository=work.arima
		name=first;
	select 
		criterion=mape 
		holdout=24;
	spec &specs;
run;

proc hpfengine data=edisto
			outfor=outfor
                    repository=work.arima
				outest=est
				task=select(noaltlist)
				globalselection=first
				back=500
				print=(select);
        id       dtstamp interval=hour;
        forecast stage02175000;
		input stage02173500 /required=yes;
		input stage02173030 /required=yes;
		input stage02173000 /required=yes; 
		input stage02173051/ required=yes;
     run;
	proc hpfengine data=edisto
			outfor=outfor
                    repository=work.arima
				inest=est
				outest=est
				task=fit
				globalselection=first
				back=500
				print=(select);
        id       dtstamp interval=hour;
        forecast stage02175000;
		input stage02173500 /required=yes;
		input stage02173030 /required=yes;
		input stage02173000 /required=yes; 
		input stage02173051/ required=yes;
     run;
	proc hpfengine data=edisto 
                    lead=500
				back=500
				inest=est
				task=forecast
                    repository=work.arima
				globalselection=first
				print=all
				outfor=outfor;
        id       dtstamp interval=hour;
        forecast stage02175000;
		input stage02173500 /required=yes;
		input stage02173030 /required=yes;
		input stage02173000 /required=yes; 
		input stage02173051/ required=yes;
     run;

	ODS PATH work.templat(update) sasuser.templat(read) sashelp.tmplmst(read);
	proc template;
		define statgraph mygraphs.stcfor;
		layout lattice / width=1000 height=300;
			layout overlay ;				
				Band
					ylimitlower=fit_lower
					ylimitupper=fit_upper
					x=dtstamp / 
						fill=true 
						lines=false 
						fillcolor=ywh 
						legendlabel="Fit CI" 
						name="Conf1";
				Band
					ylimitlower=holdout_lower
					ylimitupper=holdout_upper
					x=dtstamp / 
						fill=true 
						lines=false 
						fillcolor=bwh
						legendlabel="Holdout CI" 
						name="Conf2";
				Band
					ylimitlower=fcst_lower
					ylimitupper=fcst_upper
					x=dtstamp / 
						fill=true 
						lines=false 
						fillcolor=pkwh
						legendlabel="Forecast CI" 
						name="Conf3";
				SERIES X=dtstamp Y=actual /name="act" legendlabel="stage"  markers=true markersymbol=circlefilled markercolor=black linecolor=green;
				SERIES X=dtstamp Y=predict /name="pred" legendlabel="stage" markers=false linecolor=blue;
				
			endlayout;
			SIDEBAR / ALIGN= BOTTOM ;
				DISCRETELEGEND 'Conf1' 'Conf2' 'Conf3' 'act' 'pred' /across=3 ;
			ENDSIDEBAR;
		endlayout;
		end;
	run;

	goptions device=activex;
	proc sql ;
		select max(dtstamp)  into :maxdate from edisto ;
	quit;

	data fit holdout fcst; set outfor;
	where dtstamp>=intnx('hour',&maxdate,-600);
		if dtstamp<intnx('hour',&maxdate,-500) then output fit;
		else if dtstamp<= &maxdate then output holdout;
		else output fcst;
	run;
	data finalfor;
		set 
			fit (rename=(lower=fit_lower upper=fit_upper))
			holdout (rename=( lower=holdout_lower upper=holdout_upper))
			fcst (rename=( lower=fcst_lower upper=fcst_upper));
	run;
	proc sort data=finalfor; by dtstamp;

	data _null_ ;
		set finalfor;
			file print ods=( template='mygraphs.stcfor' 
				objectlabel='Forecast Plot');
			put _ods_;
	run;

