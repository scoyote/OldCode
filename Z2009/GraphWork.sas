libname core '/sas/adminscripts/data';


data worklist;
    set core.worklist;
    sizegb=sizemb/1000;

proc means data=worklist noprint nway;
    class tstamp;
    output out=sums sum(sizegb)=;
run;

proc sgplot data=sums;
    format tstamp datetime7.;
    series y=sizegb x=tstamp;
run;quit;
