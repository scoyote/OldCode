






libname  j1a
         db2
         database=j1a
         schema=ADHOC
         user=&user
         using=&mypw
         insertbuff=1000     /* no single row inserts or reads... */
         readbuff=1000;

data j1a.r140p_class;
    set sashelp.class;
run;

/* page 108 graeme birchall db2 9.1 cookbook */

proc sql ;
    connect to db2 (db=j1a user=&user using=&mypw schema=ADHOC);
    select * from connection to db2 (
         select
               sex
              ,age
              ,count(*) as agesexfreq
              ,sum(count(*)) over (order by sex,age rows unbounded preceding) as cumfreq
              ,sum(count(*)) over (partition by sex) as sexfreq
              ,sum(count(*)) over (partition by age) as agefreq
              ,rank() over (partition by sex order by count(*) desc) as rank
              ,count(*)/double(sum(count(*)) over ()) as agepercent_oversex
         from adhoc.&user._class
         group by
               sex
              ,age
    );
    disconnect from db2;
quit;



    x "db2 connect to j1a user &user using &mypw >runst.txt 2>&1";
    x "db2 'runstats on table adhoc.r140p_class with distribution and detailed indexes all' >> runst.txt 2>&1";
    x "db2 disconnect all >> &log 2>&1";
    data _null_;infile "runst.txt"; input;  put _infile_; run;
