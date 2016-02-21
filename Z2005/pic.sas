
proc format;
	picture nlzdt (default=10)
		low-high='%m/%0d/%Y' (DATATYPE=DATE);
RUN;
data sb6000;
	 infile "N:\MSAD\J1\std_parta\sb6000\New File Test\provtestfile091023.txt" LRECL=256 MISSOVER DLM='09'X;
	 LENGTH
		PROVNO 		$6
		REASON 		$5
		DCN	 		$23
		FILEDATE 	8
		HICN 		$12;
	INFORMAT FILEDATE MMDDYY10.;
	FORMAT   FILEDATE MMDDYY10.;

	input 
		  provno $
		  reason $
		  dcn $
		  FILEDATE 
		  F1 $
	      hicn $;
	DROP F1;
	if _n_ = 1 then do;
	FILEDATE='01JAN2009'D;
		call symput('filedt', compress(put(FILEDATE,NLZDT.)));
	end;
	run;


%put &filedt;
