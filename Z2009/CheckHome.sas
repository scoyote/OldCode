


filename swork pipe 'ls -Alt /home';       
libname core '/sas/adminscripts/data';

options ps=max;

%include "/sas/adminscripts/ReportingMacros.sas";
%loaduserlist;
%ParseReport(RALT,home,swork);

title -------------------------  SASWORK Use by User   -------------------------;
title2 Entries in this report could signify orphaned sessions;

proc means data=swork noprint nway;
class 
run;

proc printto print='/sas/adminscripts/CheckHome.out' new;
run;
     proc sort data=swork;
	by descending tstamp;
	run;
     proc print data=swork label;
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


