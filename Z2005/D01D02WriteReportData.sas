****************************************************;
****************************************************;
**** PROGRAM: D01D02WriteReportData.sas           *;
**** PURPOSE: TO OUTPUT D01D02 REPORT TO WEB      *;
**** CREATED: January 13, 2010 by Sam Croker       *;
****************************************************;
****************************************************;

filename MSADCODE '/sasonline2/programs/msad';
filename MSADDOCS '/sasonline2/docs/msad';

%global SAVE_SELECTED_YYYYMM EXTRACT_DT CHAIN_CNT ACTIVES;

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

proc sql;
   select LABEL format=$200.
   into  :SAVE_SORTCOLUMNLABEL
   from   DICTIONARY.COLUMNS
   where  LIBNAME="&SAVE_LIBNAME"
   and    MEMNAME="&SAVE_MEMNAME"
   and    NAME="&SAVE_SORTCOLUMN"
   ;
   ;
quit;

%include MSADCODE(WriteStandardPageOpening.sas);
%include MSADCODE(WriteFormTagsetNsc.sas);

data _NULL_;
   file _WEBOUT;
   put '<div id="header">';
   put +1 '<h4>';
   put +2 'Count of Supplier Numbers By Status';
   put +2 '<br>';
   put +2 "Sorted by &SAVE_SORTORDER &SAVE_SORTCOLUMNLABEL";
   put +2 '<br>';
   put +2 "NSC Data Extracted &EXTRACT_DT";
   put +2 '<br>';
   put +2 '<br>';
   put +2 "Of the &ACTIVES active suppliers &CHAIN_CNT are part of a large chain.";
   put +1 '</h4>';
   put '</div>'; /*end of id="header"*/
run;

%include MSADCODE(WriteTableTagset.sas);
%include MSADCODE(WriteStandardPageClosing.sas);
/********************************************* E N D **********************************************/
