
%macro CheckForUnprintables(
	 ds		/*dataset name*/
	,var 	/*variable name*/
	);
	/* Build a list of unprintable characters in ascii, store them as
	hex in a macro variable */
	data cds;
		do ascii=0 to 255;
			hexcd=put(ascii,$hex2.);
			if ascii< 32 or ascii > 126 then output;
		end;
	run;
	/* write it out to a macro variable for use in an IN statement later */
	proc sql noprint;
		select "'"||hexcd||"'" into :hexval separated by ',' from cds;
	quit;

	data _null_;
		file print;
		if _n_=1 then k=0;
		set &ds end=eof1;
		/* step through each character and compare hex values to see if it
			is printable */
		do i=1 to vlength(&var);
			asciicd = substr(&var,i,1);
			hexcd=put(asciicd,$hex2.);
			if hexcd in(&hexval) then do;

				if k<=40 then put "HEX(" hexcd +(-1) ") found at position " i "of &var on row " _n_ ":" &var;
				k+1;
			end;
		end;
		if eof1 then put "There were " k " observations with unprintable characters";
	run;
%mend CheckForUnprintables;

%macro check(lib,dsn,uniquecutoff=40);

	PROC SQL noprint ;
		select count(*) into :numcols
		from dictionary.columns 
		where libname="%upcase(&lib)" 
		  and memname="%upcase(&dsn)"
		; 
		%let numcols=&numcols;
		select 
	  		name
			, label
			, type
			, length
			, format
			, informat 
		into 
			  :name1-:name&numcols
			, :label1-:label&numcols
			, :type1-:type&numcols
			, :length1-:length&numcols
			, :format1-:format&numcols
			, :informat1-:informat&numcols
		from dictionary.columns 
		where libname="%upcase(&lib)" 
		  and memname="%upcase(&dsn)";
	quit;

	%do col=1 %to &numcols;
		%if %upcase(&&type&col)=NUM %then %do;
			/* univariate */
			title Profile of %upcase(&LIB..&DSN);
			title2 Column: %upcase(&&name&col);
			title3 %upcase(&&label&col);
			proc univariate data=&lib..&dsn ;
				var &&name&col ;
			run;
		%end;
		%if %upcase(&&type&col)=CHAR %then %do;

			title Profile of %upcase(&LIB..&DSN);
			title2 Column: %upcase(&&name&col);
			title3 %upcase(&&label&col);
			proc freq data=&lib..&dsn noprint;
				tables &&name&col /missing out=freq_&&name&col;
			run;
			proc sql noprint;
				select count(*) into :fcount from freq_&&name&col;
				%let fcount=&fcount;
			quit;
			%if &fcount >&uniquecutoff %then %do;
				title4 First &uniquecutoff Sorted by Count;
				proc sort data= freq_&&name&col;
					by descending count;
				run;
				proc print data=freq_&&name&col(obs=&uniquecutoff) noobs;
				run;
				title4 Last &uniquecutoff Sorted by Count;
				proc sort data= freq_&&name&col;
					by count;
				run;
				proc print data=freq_&&name&col(obs=&uniquecutoff) noobs;
				run;

				title4 First &uniquecutoff Sorted by &&name&col;
				proc sort data= freq_&&name&col;
					by &&name&col;
				run;
				proc print data=freq_&&name&col(obs=&uniquecutoff) noobs;
				run;

				proc sort data= freq_&&name&col;
					by descending &&name&col;
				run;
				title4 Last &uniquecutoff Sorted by &&name&col;
				proc print data=freq_&&name&col(obs=&uniquecutoff) noobs;
				run;
			%end;
			%else %do;
				title4 All Unique Values;
				proc print data=freq_&&name&col(obs=&uniquecutoff) noobs;
				run;
			%end;
			%CheckForUnprintables(&lib..&dsn,&&name&col);
		%end;
	%end;
%mend;


libname t 'n:\msad\cas\adhoc\nsc\nsc09121402\chkr';

%check(t,nsc09121402);
