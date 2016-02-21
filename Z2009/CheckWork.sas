


filename swork pipe 'ls -Alt /sas/saswork';
libname core '/sas/adminscripts/data';

options ps=max;

%include "/sas/adminscripts/ReportingMacros.sas";
%loaduserlist;
%ParseReport(ALT,saswork,swork);

title -------------------------  SASWORK Use by User   -------------------------;
title2 Entries in this report could signify orphaned sessions;

%calldu;
proc sql; create table swork as
   select datetime() as tstamp ,a.fname, a.lastaccess, a.userid, a.k_id, b.sizemb from saswork a
    left join saswork2 b
    on a.fname = b.fname;
quit;
proc sort data=swork;
    by lastaccess;
run;
/*
data core.worklist (compress=yes);
    set swork(keep=tstamp fname userid k_id lastaccess sizemb);
run;
*/

proc append base=core.worklist data=swork;
run;

proc printto print='/sas/adminscripts/CheckWork.out' new;
run;
     proc sort data=core.worklist;
	by descending tstamp;
	run;
     proc print data=core.worklist label;
         label fname="SASWORK Directory" userid='User' lastaccess="Creation Date" sizemb "Dir Size (MB)";
         where SUBSTR(fname,1,4)="SAS_";
         by descending tstamp; 

         format sizemb comma15.2 tstamp datetime28.;
         var tstamp
      ;
         var fname ;
         var userid;
         var k_id;
         var lastaccess;
         var sizemb;
         sum sizemb;
     run;

proc printto; run;


