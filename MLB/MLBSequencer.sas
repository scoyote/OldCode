
/* loadteam gets the csv schedule from mlb.com for a specific team and date range.
   it creates temporary data files for the team by the team abbreviation so
   Yankees would be nyy.sas7bdat.*/
%loadteam(nyy,Yankees,'01aug2009'd,'31aug2009'd);
%macro loadteam(
		team		/* official MLB team abbreviation */
		,teamname	/* teamname, best to load from teamdata */
		,dt1	 	/* start date of range  -1 here loads entire season including preseason which is not mapped*/
		,dt2		/* end date of range*/
	);
	filename tmpfile url "http://www.mlb.com/downloads/downloadable_schedules/y2009/&team..csv";
	data &team;
		infile tmpfile dlm=',' missover dsd firstobs=2 end=eof;
		/* the descriptions are Marlins at Braves - this regex changes at to @ */			
		if _n_=1 then do;
			re=prxparse("s/\sat\s/@/");
	 		if missing(re) then put "ERROR: Malformed Regular Expression";
			retain re;
		end;
		informat 
			START_DATE anydtdte. 
			START_TIME anydttme. 
			START_TIME_ET anydttme. 
			SUBJECT $50.
	 		LOCATION $50. 
			DESCRIPTION $50.; 
		format 
			START_DATE mmddyy10. 
			START_TIME tod5. 
			START_TIME_ET tod5. 
			SUBJECT $50.
	 		LOCATION $50. 
			DESCRIPTION $50.; 
		input start_date start_time start_time_et subject $ location $ description $ ;
		/* activate the regex substitution */
		call prxchange(re,-1,subject);
		/* break up the subject into home and away - yes this probably could have been done in a single regex step*/
		away=scan(subject,1,'@');
		home=scan(subject,2,'@');
		if home="&teamname"
		and start_date >= &dt1 and  start_date<=&dt2

		;
		drop subject;
run;
filename tmpfile clear;
%mend;


/* Load all 30 teams */
%macro buildteams(dt1,dt2);
	/* load the teams into a macro array */
	proc sql noprint;
		select count(teamabr) into :teamnum from perm.teamdata;
		%let teamnum=&teamnum;
		select teamabr,teamname into :team1-:team&teamnum,:tmname1-:tmname&teamnum from perm.teamdata;
	quit;
	/* loop through the team array loading the team each time around and making a master dataset */
	%do tm = 1 %to 30;
		%global &&team&tm &&tmname&tm; /* I dont remember why I did this--vestigial?*/
		%loadteam(&&team&tm,&&tmname&tm,&dt1,&dt2);
					data teamsequence;
				/* create teamsequence.sas7bdat if first team */
				%if &tm>1 %then %do;
					set teamsequence &&team&tm;
				%end;
				%else %do;
					set  &&team&tm;
				%end;
				by start_date;
			run;
	%end;
	proc sort data=teamsequence; by home away; run;

%mend;


%macro buildseq(
	 abbr			/* mlb team abbreviation of starting home game.  Be sure they have a home game on stdt!*/
	,stdt			/* start date of search */
	,days			/* number of days to build a sequence */
	,dist			/* max daily distance */
	,restrict=NO	/* restrict prevents doubling back and staying put */
);
	data _null_;
		a=&stdt;
		call symput('stdt',a);
	run;
	%let totrows=1;
	%let countteam1=1;
	
	%put stdt=&stdt;

	/* the approach I took here was to build datasets for each day transition.  So team1 has the
		choices for day 1.  Should be a single row.  Team 2 would have the choices for day 2 based upon
		distance traveled and restrictions.  This goes on until day n.  */
	data team1; 
		set &abbr;
		where start_date = &stdt;
		length previously $50;
		keep home away location start_date start_time distance previously;
		distance=0;
		rename  location=stadium start_date=gameday start_time=gametime;
	run;
	proc sql noprint;
		select distinct home into :hometeams from team1;
		%let hometeams="%cmpres(&hometeams)";
	quit;
	/* build the rest of the team datasets --actually the choices */
	%do day=2 %to &days;
		%let gameday=%eval(&stdt+&day-1);
		%put gameday=&gameday;
		proc sql noprint;
			/* prepare a macro variable for a NOT IN statement later for the no-double-back idea */
			select distinct home into :hm separated by '","' from team%eval(&day-1);
			select count(distinct home) into :cthm from team%eval(&day-1);
			%if &cthm>0 %then %let hometeams = &hometeams,"&hm";
			%put &hometeams;
			/* build the choice table for day<n> */
			create table team&day as
				select distinct
					 b.gcdist as distance
					, a.stadium as previously
					, c.away as away
					, c.home as home
					, c.location as stadium
					, c.start_time as gametime
					, c.start_date as gameday format=mmddyy10.
				from 
					/* ok, this joins the previous day with the distance mapping file.  I am not
						thoroughly satisfied with this approach but it works */
					(	team%eval(&day-1) a
					inner join			/* join previous days home team with..*/
						stadrec b		/* the distances file */
					on a.home=b.team1) /* remember team1 & team2 refer to the distances (stadrec) */
					left join			/* then join all this with the sequence data that has all the details */
						teamsequence c
					on b.team2=c.home   /* look at all the choices by joining team2 with home in teamsequence */
					where gcdist <= &dist 	/* distance filter */
					and c.start_date=&gameday 	/* ensure we are on the correct date in the sequence*/
					%if %upcase(&restrict)=NOREP %then %do; /* it might be nice to break these apart */
						and gcdist ~= 0			/* restrict to no-stay-put */
					%end;
					;
				/* look at the number of rows... if using LE like me then you can only have 1500...this comes later*/
				select count(*) into :countteam&day from team&day;
				%let totrows=%sysevalf(&totrows * &&countteam&day);
				%if %upcase(&restrict)=NOREP %then %do;
				data team&day;
					set team&day;
					if home in (&hometeams) then do;
						put "Removing " home away " due to repeat";
					end;
					else output;
				run;
				%end;
	%end;
	/* build a list of all the choices - this is nice for debugging and getting a handle...*/
	data list;
		set 
		%do day=1 %to &days;
		team&day
		%end;;
		by gameday;
		/* add a sequence number */
		if first.gameday then distseq=1;
		else distseq+1;

	run;	

	%put totrows= &totrows;
	%do i=1 %to &days;
		%put Team&i = &&countteam&i;
	%end;
	/* dont build the cart-prod if you go above the threshold */
	%if &totrows>1500 %then %put ERROR: Total routes is &totrows;
	%else %do;

		proc sql noprint;
			/* put the team datasets together into a single row... again the thought here was the 1500 row limit 
				but this came in handy for reporting */
			create table tmp as
			select 
				/* this builds a long select statement */
				%do i=1 %to &days;
					%if &i>1 %then %do; , %end;
					 team&i..gameday as gameday&i
					,team&i..previously as previously&i
					,team&i..distance as distance&i
					,team&i..stadium as stadium&i
					,team&i..home as home&i
					,team&i..away as away&i
				%end;
				from 
				/* this builds a long cartesian product statement since there are no joins*/
				%do i = 1 %to &days;
					%if &i>1 %then %do; , %end;
						team&i
				%end;
/*				where */
/*					%do i=2 %to &days;*/
/*						team%eval(&i-1).stadium = team&i..previously */
/*						%if &i<&days %then %do; and %end;*/
/*					%end;*/
				;
				quit;
		data distances;
			set tmp;
			total = sum(%do i=1 %to &days;distance&i %if &i<&days %then %do;,%end;%end;);
		run;
	%end;
%mend; 

		
%macro Mapit(iter);
	data fmtlat;
		set perm.teamdata;
		fmtname='latit';
		type='c';
		start=teamname;
		label=latitude;
	run;

	data fmtlong;
		set perm.teamdata;
		fmtname='longit';
		type='c';
		start=teamname;
		label=longitude;
	run;
	proc format library=work cntlin=fmtlat;
	run;
	proc format library=work cntlin=fmtlong;
	run;
	data _null_;
		file "&path\report.htm";
		set distances end=eof;
		if _n_=1 then do;
			put "<html><body>";
		end;
		length link $1024;	
		put "<br><h2>Route "  _N_  "</h2>";
		link='<iframe width="600" height="300" frameborder="0" scrolling="no" marginheight="0" marginwidth="0" src="http://maps.google.com/maps?f=d&source=s_d';
	    link=trim(link)|| '&saddr='|| put(home1,$latit.)  ||',+' || put(home1,$longit.)|| '&daddr=';
		put "<table><tr><td>Day</td><td>Date</td><td>Stadium</td><td>Home</td><td>Away</td><td>Distance</td></tr>";
		put "<tr><td>1</td>";
	    put "<td>" gameday1 mmddyy8. "</td>";
		put "<td>" Stadium1 "</td>";
		put "<td>" home1 "</td>";
		put "<td>" away1 "</td>"; 
		put "<td>" distance1 "</td></tr>";	
		%do i=2 %to %eval(&iter);
			%if &i>2 %then %do; link=trim(link)||"+to:"; %end;
			link=trim(link)||put(home&i,$latit.)  ||',+' || put(home&i,$longit.);
			put "<tr><td>&i</td>";
		    put "<td>" gameday&i mmddyy8. "</td>";
			put "<td>" Stadium&i "</td>";
			put "<td>" home&i "</td>";
			put "<td>" away&i "</td>"; 
			put "<td>" distance&i "</td></tr>";	
		%end;
		put "</table>";
		link=trim(link)|| '&amp;ie=UTF8&amp;output=embed"></iframe><br><br><hr><br>';
		put link;

		if eof then do;
			put "</body></html>";
		end;
	run;
%mend;



data stadrec(keep=team1 team2 gcdist);
	set perm.teamdata end=eof;
	array std{30} $40 	_temporary_ ;
	array lat{30} 8 	_temporary_;
	array long{30} 8 	_temporary_;
	array dist{30,30} 8	_temporary_;
	std{_n_}=teamname;
	lat{_n_}=(3.14159*latitude)/180;
	long{_n_}=(3.14159*longitude)/180;

	if eof then do;
		file "&path\distances.dat" lrecl=32000;
		do i=1 to 30;
				if i=1 then do;
					do n=1 to 30;
						if ~missing(std{n}) then put @(14*(n)) std{n} @;
						if n=30 then put;
					end;
				end; 
			put @1 std{i} @; 
			do j=1 to 30;
				arg=sin(lat{j})*sin(lat{i}) + cos(lat{i})*cos(lat{j})*cos(long{i}-long{j});
				if std{i}=std{j} then dist{i,j}=0;
				else dist{i,j}=sum(round(3949.99*arcos(arg),1.0),0);
				if ~missing(std{i}) and ~missing(std{j})  then do;
					put @(14*(j)) dist{i,j} @;
						team1=std{i};
						team2=std{j};
						gcdist=dist{i,j}; 
						output;
				end;
			end; put;
		end;
		stop;
	end;
run;

proc sort data=stadrec;
	by team1 team2;
	run;


%let path=C:\Documents and Settings\Administrator\My Documents\MLB;
libname perm "&path";
%buildteams('9AUG09'd,'16AUG09'd);
%buildseq(was,'9AUG09'd,5,400,restrict=NOREP);
%mapit(5);
