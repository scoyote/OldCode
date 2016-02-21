********************************************************;
********************************************************;
**** PROGRAM: D01D02WriteXlsExport.sas                 *;
**** PURPOSE: Enables exporting of report to Excel     *;
**** CREATED: January 13, 2010 by Sam Croker           *;
********************************************************;
********************************************************;

%global SAVE_SELECTED_YYYYMM EXTRACT_DT ACTIVES CHAIN_CNT;

%macro convert;
%local mo day yr;
%if %substr(&SAVE_SELECTED_YYYYMM,1,1)=0 %then %do;
 %let day=%substr(&SAVE_SELECTED_YYYYMM,2,1);
%end;
%if %substr(&SAVE_SELECTED_YYYYMM,1,1) ne 0 %then %do;
 %let day=%substr(&SAVE_SELECTED_YYYYMM,1,2);
%end;
%if %upcase(%substr(&SAVE_SELECTED_YYYYMM,3,3))=JAN %then %do;
 %let mo=January;
%end;
%if %upcase(%substr(&SAVE_SELECTED_YYYYMM,3,3))=FEB %then %do;
 %let mo=February;
%end;
%if %upcase(%substr(&SAVE_SELECTED_YYYYMM,3,3))=MAR %then %do;
 %let mo=March;
%end;
%if %upcase(%substr(&SAVE_SELECTED_YYYYMM,3,3))=APR %then %do;
 %let mo=April;
%end;
%if %upcase(%substr(&SAVE_SELECTED_YYYYMM,3,3))=MAY %then %do;
 %let mo=May;
%end;
%if %upcase(%substr(&SAVE_SELECTED_YYYYMM,3,3))=JUN %then %do;
 %let mo=June;
%end;
%if %upcase(%substr(&SAVE_SELECTED_YYYYMM,3,3))=JUL %then %do;
 %let mo=July;
%end;
%if %upcase(%substr(&SAVE_SELECTED_YYYYMM,3,3))=AUG %then %do;
 %let mo=August;
%end;
%if %upcase(%substr(&SAVE_SELECTED_YYYYMM,3,3))=SEP %then %do;
 %let mo=September;
%end;
%if %upcase(%substr(&SAVE_SELECTED_YYYYMM,3,3))=OCT %then %do;
 %let mo=October;
%end;
%if %upcase(%substr(&SAVE_SELECTED_YYYYMM,3,3))=NOV %then %do;
 %let mo=November;
%end;
%if %upcase(%substr(&SAVE_SELECTED_YYYYMM,3,3))=DEC %then %do;
 %let mo=December;
%end;
%let yr=%substr(&SAVE_SELECTED_YYYYMM,6,4);

data _null_;
call symput('EXTRACT_DT',"&mo"||' '||"&day"||', '||"&yr");
run;

%mend convert;

%convert

filename HOLDER temp;
data _NULL_;
   file HOLDER lrecl=1000;
   retain LineFeed '\000A';
   put '\0026C\0026\0022Courier New\,Bold\0022' @;
   put 'Count of Supplier Numbers By Status' @;
   put LineFeed +(-1) @;
   put "Sorted by &SAVE_SORTORDER &SAVE_SORTCOLUMNLABEL" @;
   put LineFeed +(-1) @;
   put "NSC Data Extracted &EXTRACT_DT" @;
   put LineFeed +(-1) @;
   put "Of the &ACTIVES active suppliers &CHAIN_CNT are part of a large chain.";
run;

data _NULL_;
   infile HOLDER lrecl=1000;
   input;
   call symput('SAVE_MSOHEADERDATA',compbl(_infile_));
run;
filename HOLDER clear;

%let SAVE_EXPORTFILENAME=&SAVE_REPORTNAME._&SAVE_SELECTED_YYYYMM;
filename MSADCODE '/sasonline2/programs/msad';
%include MSADCODE(SetSessionStateNsc.sas);
%include MSADCODE(WriteXlsExport.sas);
/********************************************* E N D **********************************************/
