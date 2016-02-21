
libname stc "C:\Documents and Settings\scrok586\My Documents\ADMINSamC";
filename metros url 'http://www.wmata.com/metrorail/stations.cfm';

data metrostationnumbers;
	infile metros lrecl=32000;
	input;
	length statname $30 stationid $3 icontitle $30;
	if _n_=1 then do;
		rowpat =	prxparse('/station=/');
		retain rowpat;
	end;
	/*file 'C:\Documents and Settings\scrok586\Desktop\cars.txt';*/
      /* Use PRXMATCH to find the position of the pattern match. */
   	position=prxmatch(rowpat, _infile_);
   	if position>0 then do;
		datarow=	_infile_;
		start=index(_infile_,'<!-- DNT -->')+12;
		end=index(_infile_,'<!-- /DNT -->');
		statname=substr(_infile_,start,end-start);

		start2=index(_infile_,'delays/')+7;
		end2=index(_infile_,'gif')-1;
		icontitle=substr(_infile_,start2,end2-start2);
	
		stationid=substr(datarow,position+8,3);
		endstring=indexc(stationid,'"');
		if endstring>0 then stationid=substr(stationid,1,endstring+3);
		if ~missing(stationid) then output;
	end;
	keep statname stationid icontitle;
run;
proc sort data=metrostationnumbers;
	by stationid;
run;
%put _user_;

%macro loadstationaddress;
	proc sql noprint;
		select count(*) into :stationidnum from metrostationnumbers;
		%let stationidnum=&stationidnum;
		select 	stationid
				,statname
				,icontitle
			into 
			 :station1-:station&stationidnum 
			,:stationname1-:stationname&stationidnum
			,:icon1-:icon&stationidnum
			from metrostationnumbers;
	quit;
	%do i=1 %to &stationidnum;
		%put NOTE: Trying station&i=&&station&i;
		%loadsinglestationaddress(&&station&i,"&&stationname&i","&&icon&i");
	%end;
%mend;


%macro loadsinglestationaddress(stationnum,stationname,icon);
	filename station url "http://www.wmata.com/metrorail/Stations/station.cfm?station=&stationnum";
	%put "http://www.wmata.com/metrorail/Station/stations.cfm?station=&stationnum";
	data temp;	
		length stationid 8 stataddr $100 stationname $30 icon $30;
		keep stationid stataddr stationname icon;
		infile station lrecl=10000;
		input;
		if _n_=1 then do;
			rowpat =	prxparse('/Station address:/');
			retain rowpat;
		end;
		/* Use PRXMATCH to find the position of the pattern match. */
	   	position=prxmatch(rowpat, _infile_);
	   	if position>0 then do;
			start=index(_infile_,'<!-- DNT -->')+12;
			end=index(_infile_,'<!-- /DNT -->');
			stataddr=substr(_infile_,start,end-start);

			stationid=&stationnum;
			stationname=&stationname;
			icon=&icon;
			output;
			put stataddr= stationid= stationname=;
			stop;
		end;
	run;
	
	proc sql;
		insert into stc.stations select stationid, stataddr, stationname, icon from temp;
	quit;
%Mend;

proc sql;
	create table stc.stations (stationid int, stataddr varchar(100), stationname varchar(30), icon varchar(30));
quit;
options nonotes;
%loadstationaddress;			
options notes;

data _null_; set stc.stations;
	file 'C:\Documents and Settings\scrok586\Desktop\metrostations.txt';
	put "showAddress('" stataddr "');";
run;

		

data _null_; set stc.stations end=eof;
	file 'C:\Documents and Settings\scrok586\Desktop\metroinsert.txt';
	put 'insert into metrostat values (' stationid ',"' stationname'","' stataddr '","' icon '");';
run;


