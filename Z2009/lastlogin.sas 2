


libname core '/sas/adminscripts/data';
filename last pipe "last";

/* look at the overall file system usage */
data lastlogin;
    length
         k_id $8
         term $8
         fromaddr $50
         timestr $50
;
    ;
    format sdatetime edatetime elaptime datetime16. elaptime time5.;

    infile last missover;
    input k_id ?? $ term ?? $ fromaddr ?? $ timestr && $;
    if substr(k_id,1,1)="k" then do;
         mon=scan(timestr,1,' -');
         day=scan(timestr,2,' -');
         stime=input(scan(timestr,3,' -'),time5.);
         etime=input(scan(timestr,4,' -'),time5.);
         otpos=index(timestr,'(');
         oepos=index(timestr,')');

         if otpos>0 then do;
              elapday=scan(substr(timestr,otpos,oepos-1),1,'()+');
              elaptime=input(scan(substr(timestr,otpos,oepos-1),2,'()+'),time5.);
         end;
         else do;
              elaptime=etime-stime;
              elapday=0;
         end;
         *year=year(datetime());
         sdatetime=dhms(
                   input(cats(day,mon,2009),date9.)
                  ,hour(input(scan(timestr,3,' -'),time5.))
                  ,minute(input(scan(timestr,3,' -'),time5.))
                  ,0);
         edatetime=dhms(
                   input(cats(day+elapday,mon,2009),date9.)
                  ,hour(input(scan(timestr,4,' -'),time5.))
                  ,minute(input(scan(timestr,4,' -'),time5.))
                  ,0)+(elapday*86400);
         output;
    end;
    keep k_id term fromaddr sdatetime edatetime elaptime ;
run;

proc sort data=lastlogin;
    by k_id descending sdatetime ;
run;

data last_login_report;
    set lastlogin;
    by k_id descending sdatetime;
    if first.k_id then login=1;
    else login+1;
run;
proc print;
    where login=1;
run;
