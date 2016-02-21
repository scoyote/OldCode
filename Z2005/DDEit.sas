
filename sas2xl dde 'excel|system' notab;
FILENAME data DDE "EXCEL|sheet1!r2c1:r20c5";

%let library=sashelp;
%let dsname =class;
proc sql noprint;
	select count(*) into :numrows from &library..&dsname;
	select count(*) into :numvars from dictionary.columns where libname="%upcase(&library)" and memname="%upcase(&dsname)";
	%let numrows=&numrows;
	%let numvars=&numvars;
	select name into :var1-:var&numvars from dictionary.columns where libname="%upcase(&library)" and memname="%upcase(&dsname)" order by varnum;
quit;
FILENAME cellhead DDE "EXCEL|sheet1!r1c1:r1c7";
%let r=%bquote(");
data _null_;
		 if _n_=1 then do;
			   file sas2xl;
			   put "[page.setup(""&header1" '0d'x "&header2" '0d'x "&header3" '0d'x "&header4"",,0.75,0.75,1.26,1.20,False,False,False,False,2)]";
			   put "[PAGE.SETUP(,""%nrstr(&L)&fnote1" '0d'x "%nrstr(&L)&fnote2" '0d'x "%nrstr(&L)&fnote3" "%nrstr(&R)Page %nrstr(&P) of %nrstr(&N)"")]";
/*			   put '[select("r1c1:r1c7"))]';*/
/*			   put '[Format.Font("Courier New",8,True,False,False,False,0)]';*/
/*	           put '[Alignment(,True)]';*/
/*			   put '[column.width(,,,3)]';*/
/*			   put '[select("r2c1:r20.c7")]';*/
/*			   put '[Format.Font("Courier New",8,False,False,False,False,0)]';*/
			end;
			length ddecmd $200;
			headcell=0;
		   if not eof1 then do;

			   set sashelp.vcolumn(where=(libname="%upcase(&library)" and memname="%upcase(&dsname)")) end=eof1;
			   file cellhead;
				headcell+1;
			   ddecmd = compress('[select("r1c'|| headcell|| '")]');
			   put ddecmd;
			   put name;
			end;
			if eof1 then do;
				set sashelp.class;
				file data;
				put name sex age height weight;
			end;
run;
*);*/;/*'*/ /*"*/; %MEND;run;quit;;;;;
*);*/;/*'*/ /*"*/; %MEND;run;quit;;;;;
*);*/;/*'*/ /*"*/; %MEND;run;quit;;;;;
*);*/;/*'*/ /*"*/; %MEND;run;quit;;;;;
