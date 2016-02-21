*****************************************************;
*****************************************************;
**** PROGRAM: D01D02Controller.sas                  *;
**** PURPOSE: CONTROLS INTERACTION FOR D01D02       *;
**** CREATED: January 13, 2010 by Sam Croker        *;
*****************************************************;
*****************************************************;

filename MSADCODE '/sasonline2/programs/msad';
filename NSCCODE '/sasonline2/programs/nsc';
%include MSADCODE(SetSessionStateNsc.sas);

%global
 SAVE_SELECTED_YYYYMM
 CHAIN_CNT
 ACTIVES
 EXTRACT_DT
 SAVE_SORTCOLUMNLABEL
 SAVE_SORTORDER
 SAVE_SORTCOLUMN;

%let SAVE_LIBNAME=SAVE;
%let SAVE_LOCKEDCOLUMNS=2;
%let SAVE_MEMNAME=REPORTDATA;
%let SAVE_DRILLCOLUMN=;

%macro DoControlLogic;
 %local MESSAGE;
 %if &SAVE_FUNCTION=BUILD %then %do;
  %include NSCCODE(D01D02CreateReportData.sas);
  %if %ReturnRowCountOf(&SAVE_LIBNAME..&SAVE_MEMNAME)>0 %then %do;
   %include MSADCODE(AssignStandardFormatsAndLabelsNsc.sas);
   %include MSADCODE(CreateMaxColumnWidthsTable.sas);
   %include MSADCODE(CreateColumnHeadersTable.sas);
   %include MSADCODE(SortTableRows.sas);
   %include NSCCODE(D01D02WriteReportData.sas);
  %end;
  %else %do;
   %let MESSAGE=No records were returned.;
   %include MSADCODE(WriteMessagePageNsc.sas);
  %end;
 %end;
 %else %if &SAVE_FUNCTION=SORT %then %do;
  %include MSADCODE(SortTableRows.sas);
  %include NSCCODE(D01D02WriteReportData.sas);
 %end;
 %else %if &SAVE_FUNCTION=EXPORT %then %do;
  %if &SAVE_EXPORTMEDIA=XLS %then %include NSCCODE(D01D02WriteXlsExport.sas);
 %end;
 %else %do;
  %let MESSAGE=No functions were performed.;
  %include MSADCODE(WriteMessagePageNsc.sas);
 %end;
 %let SAVE_FUNCTION=; /*reset*/
%mend DoControlLogic;

%DoControlLogic;
