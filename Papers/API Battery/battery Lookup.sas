/************************************************************
*    Windows API Interface for Querying PC Power Sources    *
*    Samuel T. Croker                                       *
*    August 31, 2006                                        *
*    SAS 9.1.3                                              *
*    Adapted from code by Richard A. DeVenezia              * 
*                         http://www.devenezia.com          *
*                         Thanks again for great code!      *
*    Gets the battery status either singly or over a time   *
*    period and displays the results                        *
************************************************************/
/* set up the required SASCBTBL filename.  This filename is 
     used by the modulen function to get the prototype */
filename SASCBTBL CATALOG 'work.example.winexec.source';

/* Write the routine statement prototype to the SASCBTBL
     file so that it can be used by the MODULEN function */
data _null_;
  file SASCBTBL;
  input;
  put _infile_;
cards4;
ROUTINE GetSystemPowerStatus
	minarg=6
	maxarg=6
	stackpop=called
	module=kernel32
	returns=long;

* LPSYSTEM_POWER_STATUS lpSystemPowerStatus ;
arg 1 num output fdstart format=ib1.;
arg 2 num output format=ib1.;
arg 3 num output format=ib1.;
arg 4 num output format=ib1.;
arg 5 num output format=ib4.;
arg 6 num output format=ib4.;
;;;;
run;

%macro scanbattery( 
                    group     =    0              /* zero means create a new ds, > appends */
                   ,cutoff    =    10             /* lowest percent to monitor */
                   ,sampleint =    5              /* sampling interval in seconds */
                   ,dsname    =    BatteryLife    /* unit dataset name */
                   ,appendto  =    none           /* dataset to append new results to */
                  );
     /* restrict log information */
     options nonotes nosource;
     data &dsname;
          length sequenceno 8;
          group=&group;
          /* set up parameters from the  lpSystemPowerStatus data structure in the api */
          ACStatus_&group=.;
          BatteryFlag_&group=.;
          BatteryLifePercent_&group=.;
          Reserved_&group=.;
          BatteryLifeTime_&group=.;
          BatteryFullLifeTime_&group=.;
          /* column header */
          put @1 'SEQ' @5 'Date/Time' @30 'AC' @35 'Flag' @41 '%' @45 'LF' @55 'LF_F';
          /* sample until the battery life percent falls below the cutoff threshold */
          do until (batterylifepercent_&group<&cutoff);        
               rc= modulen ("*e",'GetSystemPowerStatus',ACStatus_&group,batteryflag_&group,batterylifepercent_&group,reserved_&group,batterylifetime_&group,batteryfulllifetime_&group);
               if rc=0 then do;
                    put "ERROR: GetSystemPowerStatus returned a fail code.";
                    stop;
               end;
               /* nondimensional increment number to simplify graphing */
               sequenceno+1;
               /* add a datetime value for interest */
               date_time_&group=datetime();   
               /* write out the last observation to the log for interest */
               put @1 sequenceno @5 date_time_&group datetime19. @30 acstatus_&group @35 batteryflag_&group @41 batterylifepercent_&group @45 Batterylifetime_&group @55 batteryfulllifetime_&group;
               /* save the last observation */
               output;
               /* wait before continuing.  The 1 stands for seconds and the sampleint is the number of seconts to wait */
               call sleep(&sampleint,1);
          end;
          format date_time datetime28.;
     run;
     %if &appendto~=none %then %do;
          data &appendto;
               merge &appendto &dsname;
               by sequenceno;
          run;
     %end;
     options notes source;
%mend ScanBattery;

/* Usage:  In the following example an initial permanent result set is
created (BatteryTest1) first.  The subsequent statments append the result
set to this BatteryTest1 dataset, differentiating the runs with the group 
variable.  Do it this way because the plotbatteryresults macro will then
make columns out of the percents for the groups so that they can be easily
plotted against each other.  This is useful for evaluating and displaying the 
power drop curves for multiple power profile configurations.*/
%scanbattery(group=1,dsname=Presentate,cutoff=25,sampleint=1,appendto=none);


options notes source;
%macro plotbatteryresults( 
                    dsname    /* dataset name containing series of data to graph*/
                   ,startgroup /* starting group number*/
                   ,endgroup

                  );
ods html;
     goptions reset=all device=activex;
     symbol1 v=none i=j c=blue ;
     symbol2 v=none i=j c=green ;
     symbol3 v=none i=j c=cyan ;
     symbol4 v=none i=j c=purple ;
     symbol5 v=none i=j c=orange ;
     symbol6 v=none i=j c=magenta ;
     proc gplot data=&dsname;
          plot
          %do dsi=&startgroup %to &endgroup; 
               batterylifetime_&dsi.*sequenceno                              
          %end; 
          /overlay legend;
          plot2
          %do dsi=&startgroup %to &endgroup; 
               batterylifepercent_&dsi.*sequenceno                              
          %end; 
          /overlay legend;
     run;
     quit;
     ods html close;
%mend plotbatteryresults;
%plotbatteryresults(presentate,1,1);
goptions reset=all;
symbol1 v=none i=spline c=steel ;
symbol2 v=none i=spline c=ligr;
proc gplot data=batterytest1;
     plot batterylifetime_0*sequenceno;
     plot2 batterylifepercent_0*sequenceno;
run;
quit;


/* simple single run for testing and such - see full macro for documentation */
%macro scanbatterysingle;
     options nonotes nosource;
     data _null_;
          ACStatus=.;
          BatteryFlag=.;
          BatteryLifePercent=.;
          Reserved=.;
          BatteryLifeTime=.;
          BatteryFullLifeTime=.;
          put @1 'SEQ' @5 'Date/Time' @30 'AC' @35 'Flag' @41 '%' @45 'LF' @55 'LF_F';
          rc= modulen ("*e",'GetSystemPowerStatus',ACStatus,batteryflag,batterylifepercent,reserved,batterylifetime,batteryfulllifetime);
          sequenceno+1;
          date_time=datetime();   
          put @1 sequenceno @5 date_time datetime19. @30 acstatus @35 batteryflag @41 batterylifepercent @45 Batterylifetime @55 batteryfulllifetime;
          format date_time datetime28.;
     run;
     options notes source;
%mend;
