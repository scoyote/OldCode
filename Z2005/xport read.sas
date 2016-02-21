
libname w "d:\workspace"; /*LOCATION OF FOLDER FOR WEEK*/
*libname tran xport "d:\workspace\xport002"; /*LOCATION OF DOWNLOADED MAINFRAME DATA*/
libname tran xport "d:\workspace\xport002"; /*LOCATION OF DOWNLOADED MAINFRAME DATA*/

****READ IN DOWNLOADED MAINFRAME DATA;

proc copy in=tran out=w; run;

***********************************************************************************************;
* Program: weekly report xport.sas
* Purpose: To generate the weekly NSC standard reports (INACT, REACT LIST, NEW SUPPLIER NUMBERS)
* Created by: Kim Adams Checked by: Abdul Qayyum
* Program Notes: Data extracted from Mainframe on second business day of week.  This program is
                 run on the PC and exports the mainframe data to Excel files.
***********************************************************************************************;

****AUTOMATIC MACRO VARIABLES TO DETERMINE REPORT SETUP DATE RANGE;

data _null_;
format x DATE9.;
  if weekday(today()) > 1      /* TODAY IS MON, OR TUE, OR ..., SAT */
  then x = today() - weekday(today()) + 1;
  else                         /* TODAY IS SUN */
       x = today() - 7;
  call symput('date1', substr(put(x-6, yymmddd10.),6,5)); /*REPORT BEGIN DATE*/
  call symput('date2', substr(put(x, yymmddd10.),6,5)); /*REPORT END DATE*/
run;

%put date1 is "&date1";
%put date2 is "&date2";

libname w "d:\workspace\NSC &date1"; /*LOCATION OF FOLDER FOR WEEK*/
libname tran xport "d:\workspace\NSC &date1\xport002"; /*LOCATION OF DOWNLOADED MAINFRAME DATA*/

****READ IN DOWNLOADED MAINFRAME DATA;

proc copy in=tran out=w; run;

****LABEL VARIABLES - INACT REPORT;

data inact;
set w.inact;
label SUPPID='SUPPLIER NUMBER';
label NO='SEQUENCE NUMBER';
label END='INACTIVATION END DATE';
label STATUS='STATUS AND REASON';
label STATUS2='STATUS';
label IND='VOID INDICATOR';
label SETUP='INACTIVATION SETUP DATE';
label STATE='STATE';
run;

****LABEL VARIABLES - REACT LIST REPORT;

data react_lt;
set w.react_lt;
label SUPPID='SUPPLIER NUMBER';
label STATUS='STATUS AND REASON';
label A_SETUP='REACTIVATION SETUP DATE';
label A_END='REACTIVATION END DATE';
label COMPANY='COMPANY';
label ADDRESS='ADDRESS';
label CITY='CITY';
label STATE='STATE';
label ZIP='ZIP';
label TEL='TELEPHONE';
run;

****LABEL VARIABLES - NEW SUPPLIER NUMBERS REPORT;

data new_supp;

label SUPPID='SUPPLIER NUMBER'; 
label STATUS='STATUS';
label COMPANY='COMPANY';
label ADDRESS='ADDRESS';
label CITY='CITY';
label STATE='STATE';
label ZIP='ZIP';
label TEL='TELEPHONE';
label SETUP='SETUP DATE';
label NO='T13 OPERATOR NUMBER';
label CODE='FLI CODE';
label REC_BEG='FLI BEGIN DATE';
label SLTO_NO='T92 OPERATOR NUMBER';
set w.new_supp(drop=PRV_NO  _name_ LCTN_NO suppid_);

run;

****READ IN DDE MACRO;

%include 'N:\msad\cas\SASMacros\sastoexcel_nsc_parta.sas';

%let rpt1=Inact; /*INACTIVATIONS*/
%let rpt2=React List; /*REACTIVATIONS*/
%let rpt3=New Supplier Numbers; /*NEW SUPPLIER NUMBERS*/
%let extract_dt=%sysfunc(date(),mmddyy10.); /*DATE OF NSC DATA EXTRACT - MUST BE HARD-CODED IF 
											  NOT RUN ON SECOND BUSINESS DAY OF WEEK*/
%let run_date=%sysfunc(date(),mmddyy10.); /*REPORT RUN DATE* - MUST BE HARD-CODED IF NOT RUN ON
											SECOND BUSINESS DAY OF WEEK*/
%let setup=November 9, 2009 - November 16, 2009; /*REPORT SETUP DATE RANGE*/

****CREATE INACT REPORT;

data _null_;
header1="Inactivations";
header2="Sorted By Supplier Number";
header3="Setup Dates: &setup.";
header4=" ";
fnote1="Source of Report: Medicare Statistical Analysis Department (&rpt1.)";
fnote2="NSC Data as of &extract_dt.";
fnote3="Run Date: &run_date.";
call symput('header1',header1);
call symput('header2',header2);
call symput('header3',header3);
call symput('header4',header4);
call symput('fnote1',fnote1);
call symput('fnote2',fnote2);
call symput('fnote3',fnote3);
run;

****EXPORT INACT REPORT TO EXCEL;

%sastoxl(libin=work,
         dsin=inact,
         cell1row=1, 
         cell1col=1, 
         nrows=, 
         ncols=, 
         tmplpath=,
         tmplname=, 
         sheet=&rpt1., 
         savepath=d:\workspace, 
         savename=&rpt1.,
         stdfmtng=  
		 );

****CREATE REACT LIST REPORT;

data _null_;
header1="Reactivations";
header2="Sorted By Supplier Number";
header3="Setup Dates: &setup.";
header4=" ";
fnote1="Source of Report: Medicare Statistical Analysis Department (&rpt2.)";
fnote2="NSC Data as of &extract_dt.";
fnote3="Run Date: &run_date.";
call symput('header1',header1);
call symput('header2',header2);
call symput('header3',header3);
call symput('header4',header4);
call symput('fnote1',fnote1);
call symput('fnote2',fnote2);
call symput('fnote3',fnote3);
run;

****EXPORT REACT LIST REPORT TO EXCEL;

%sastoxl(libin=work, 
         dsin=react_lt, 
         cell1row=1, 
         cell1col=1,  
         nrows=, 
         ncols=, 
         tmplpath=,
         tmplname=, 
         sheet=&rpt2., 
         savepath=d:\workspace, 
         savename=&rpt2., 
         stdfmtng=
         );

****CREATE NEW SUPPLIER NUMBERS REPORT;

data _null_;
header1="New Supplier Numbers";
header2="Sorted By Supplier Number";
header3="Setup Dates: &setup.";
header4=" ";
fnote1="Source of Report: Medicare Statistical Analysis Department (&rpt3.)";
fnote2="NSC Data as of &extract_dt.";
fnote3="Run Date: &run_date.";
call symput('header1',header1);
call symput('header2',header2);
call symput('header3',header3);
call symput('header4',header4);
call symput('fnote1',fnote1);
call symput('fnote2',fnote2);
call symput('fnote3',fnote3);
run;

****EXPORT NEW SUPPLIER NUMBERS REPORT TO EXCEL;



%sastoxl(libin=work, 
         dsin=new_supp, 
         cell1row=1, 
         cell1col=1, 
         nrows=, 
         ncols=, 
         tmplpath=,
         tmplname=, 
         sheet=&rpt3., 
         savepath=d:\workspace, 
         savename=&rpt3., 
         stdfmtng=
         );
