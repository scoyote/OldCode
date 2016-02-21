*********************************************************;
*********************************************************;
**** PROGRAM: D01D02InitialForm.sas                     *;
**** PURPOSE: PARAMETER SELECTION PAGE FOR D01D02       *;
**** CREATED: January 13, 2010 by Sam Croker            *;
*********************************************************;
*********************************************************;

filename MSADCODE '/sasonline2/programs/msad';
%include MSADCODE(SetSessionStateNsc.sas);

****SELECT LIST OF NSC EXTRACT DATES;

proc sql;
create table paidyearmonth as
select distinct update_dt
from DB2DATA.t13
order by update_dt descending;
quit;

****FORMAT EXTRACT DATE;

data paidyearmonth;
set paidyearmonth;
length keep_dt $20.;
keep_dt=put(update_dt,worddate20.);
run;

%include MSADCODE(WriteStandardPageOpening.sas);
%include MSADCODE(AssignStaticSaveVars.sas);

data _null_;
file _webout;
if _n_=1 then do;
put '<h1 style="text-align:center">' "&SAVE_LOBNAME" '</h1>';
put '<h1 style="text-align:center">Interactive Reporting</h1>';
put '<h2 style="text-align:center">Monthly Standard Reports</h2>';
put '<br>';
put '<h3 style="text-align:center">' "&SAVE_REPORTNAME" ' Report Parameter Selection</h3>';
put '<br>';
put '<hr size="2">';
put '<br>';
put '<form method="post" action="/sas-cgi/broker.exe">';
put '<input type="hidden" name="_DEBUG" value="' "&_DEBUG" '">';
put '<input type="hidden" name="_PORT" value="' "&_PORT" '">';
put '<input type="hidden" name="_PROGRAM" value="NSCCODE.D01D02Controller.sas">';
put '<input type="hidden" name="_SERVER" value="' "&_SERVER" '">';
put '<input type="hidden" name="_SERVICE" value="' "&_SERVICE" '">';
put '<input type="hidden" name="_SESSIONID" value="' "&_SESSIONID" '">';
put '<input type="hidden" name="SAVE_SORTCOLUMN" value="STATUS">';
put '<input type="hidden" name="SAVE_SORTORDER">';
put '<input type="hidden" name="SAVE_FUNCTION" value="BUILD">';
put '<table>';
put '<tr>';
put '<td class="Controls1A">';
put 'Date of Extract:';
put '</td>';
put '<td class="Controls1B">';
put '<select name="SAVE_SELECTED_YYYYMM">';
end;
set paidyearmonth end=DONE;
put '<option value="' update_dt +(-1) '">' keep_dt +(-1)'</option>';
if DONE then do;
put '</select>';
put '</td>';
put '</tr>';
put '<td class="Controls1A">';
put '<span>(Click "Submit" after selecting parameters.)</span>';
put '</td>';
put '<td class="Controls1C">';
put '<input type="button" value="Main Menu" alt="Return to Main Menu"';
put 'onClick="this.form._PROGRAM.value=''MSADCODE.WriteReportSelectPageNsc.sas'';this.form.submit()">';
put '<input type="button" value="Submit"';
put 'onClick="var okToSubmit=true';
put ';if(okToSubmit) submit(this.form)">';
put '<input type="Reset">';
put '</td>';
put '</tr>';
put '</table>';
put '</form>';
put '<br>';
put '<br>';
end;
run;

%include MSADCODE(WriteStandardPageClosing.sas);
