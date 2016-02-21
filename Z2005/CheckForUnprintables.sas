/****************************************************************************
***                                                                       ***
*** CheckUnprintableChars.sas                                             ***
*** Purpose: Look at the character variables in a dataset to see if there ***
*** are any unprintable characters in it.  It does a char by char comp    ***
*** in hexadecimal to see if the character falls in the printable range.  ***
***                                                                       ***
*** Author:  Samuel Croker                                                ***
***                                                                       ***
*** Created: 9/21/2009                                                    ***
***                                                                       ***
*** Modifications:                                                        ***
***                                                                       ***
*** Notes:                                                                ***
***                                                                       ***
****************************************************************************/
/* the next utility macro and calls is necessary only if the error description table
    still contains 0D (carriage return) hex values at the end of the string. */
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
		set &ds;
		/* step through each character and compare hex values to see if it
			is printable */
		do i=1 to vlength(&var);
			asciicd = substr(&var,i,1);
			hexcd=put(asciicd,$hex2.);
			if hexcd in(&hexval) then do;
				put "WARNING: HEX(" hexcd +(-1) ") found at position " i "of &var on row " _n_ "in &ds";
				/* this is kindof sloppy but maybe useful in windows where the unprint gets a square */
				/*put &var;
 				put "----|----10---|----20---|----30---|----40---|----50---|----60---|----70---|----80---|----90---|----100--|";*/
			end;
		end;
	run;
%mend CheckForUnprintables;

%CheckForUnprintables(cert_revcd,error_desc);

