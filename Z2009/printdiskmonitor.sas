


libname core '/sas/adminscripts/data';
proc print data=core.diskutil; format reportdate datetime28.; run;
