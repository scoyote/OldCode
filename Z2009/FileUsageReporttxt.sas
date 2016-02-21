***************************************************************
***                                                         ***
***           User Disk Utilization Reporting Program       ***
***                                                         ***
***                                                         ***
*** Purpose:  Render general usages statistics for general  ***
***           awarness.                                     ***
*** Author:   Samuel T. Croker                              ***
*** Create:   4/5/09                                        ***
*** changes:  05/08/09 streamlined for text based emailing  ***
*** changes:  05/13/09 added docuemntation                  ***
*** changes:  06/10/09 changed to global support email      ***
***************************************************************;
/* global paramaters */
%let server        = SAS Analysis 026;
%let threshold     = 130000; /* 130,000MB~=4,178,944MB/30 users */
%let homethreshold = 80; /*80= 4096MB/50 users - have to be more careful... */
%let comsas        = commercialsassupport@astrazeneca.com;



/* boilerplate issues */
x 'cd /sas/adminscripts';

/* date for reports */
%let dt=%sysfunc(putn(%sysfunc(date()),mmddyy8.));
%put &dt;

/* initialize the macros for this program */
%include '/sas/adminscripts/ReportingMacros.sas';


libname permunix '/sas/adminscripts';
/* this library contains the user admin file */
libname core '/sas/adminscripts/data';

/* text files created daily by root user in /sas/adminscripts/buildusagereport */
filename evrythng "/sas/adminscripts/prodreport.txt";      /* from buildusagereport */
filename work     "/sas/adminscripts/workreport.txt";      /* from buildusagereport */
filename fullwork "/sas/adminscripts/fullworkreport.txt";  /* from buildusagereport */
filename home     "/sas/adminscripts/homereport.txt";      /* from buildusagereport */
filename user     "/sas/adminscripts/userfile.txt";
filename cleanwrk "/sas/adminscripts/cleanworkreport.txt";

/* other pipes */
filename ps pipe 'ps -ef';
filename dfg pipe "df -g";
filename mon pipe "ps -ef|grep sasmon";
filename last pipe "last";

%loaduserlist;

/* generate the different report datasets */
%ParseReport(RALT,alldirs,evrythng);
%ParseReport(ALT,saswork,work);
%ParseReport(RALT,fullwork,fullwork);
%ParseReport(RALT,home,home);

/* look at the overall file system usage */
data diskutil;
    length
         reportdate 8
         filesystem $50
         gbblocks free pctused iused pctiused 8
         mount $50
    ;
    informat
         pctused pctiused percent5.;
    format
         pctiused percent5. reportdate date9.;

    infile dfg firstobs=2 missover;
    input filesystem  $ gbblocks ??  free ?? pctused ?? iused ?? pctiused ??  mount $;
    reportdate=date();
    if scan(mount,1)='sas' or scan(mount,1)='home';
run;


/* Group the file extensions into meaningful categories */

%let p1=%sysevalf(&threshold/4);
%let p2=%sysevalf((&threshold/4)*2);
%let p3=%sysevalf((&threshold/4)*3);

%let hp1=%sysevalf(&homethreshold/4);
%let hp2=%sysevalf((&homethreshold/4)*2);
%let hp3=%sysevalf((&homethreshold/4)*3);

proc format;
    value paintpct
         low-.65='white'
         .65-.85='yellow'
         .85-.95='orange'
         .95-high='red' ;

    value paintmb
         low-&p1 = 'white'
         &p1-&p2 = 'yellow'
         &p2-&p3 = 'orange'
         &p3-&threshold='red'
         &threshold-high='magenta';

    value painthom
         low-&hp1 = 'white'
         &hp1-&hp2 = 'yellow'
         &hp2-&hp3 = 'orange'
         &hp3-&homethreshold='red'
         &homethreshold-high='magenta';


    value $fileex
         'pdf'='PDF'
         'htm'='HTML'
         'html'='HTML'
         'xls'='Excel'
         'rtf'='Document'
         'doc'='Document'
         'sas7bdat'='SAS Binary'
         'sas7bcat'='SAS Binary'
         'sas'='SAS Source'
         'log'='SAS Logs'
         'lst'='SAS Output'
         'txt'='TXT CSV DAT'
         'csv'='TXT CSV DAT'
         'dat'='TXT CSV DAT'
         'xpt'='Transport Files'
         'png'='Graphics'
         'jpg'='Graphics'
         'bmp'='Graphics'
         'gif'='Graphics'
         other='Other';
run;



options
     ls           =100
     ps           =max
     orientation  =portrait
     nodate
     pageno       =1
     papersize    =letter
     leftmargin   =0.5in
     rightmargin  =0.5in
     topmargin    =0.5in
     bottommargin =0.5in
;

ods html
         style     = styles.statistical
         file      = '/sas/adminscripts/webreport/FileSystemReport.htm'
         newfile  = none
         ;

proc printto print="/sas/adminscripts/webreport/files/message.txt" new;   run;

data _null_;
    file print;
    put "Results as of 7:00AM &dt";
run;
title ------------------------- File System Statistics -------------------------;
proc print data=diskutil label noobs;
     format pctused percent6.;
     var mount gbblocks free ;
     var pctused /style={background=paintpct.};
     label mount="Mount" gbblocks="GB Total" free='GB Free' pctused='% Used';
 run;

%UtilGraph(ALL,Over All);

title -------------------------  SASWORK Use by User   -------------------------;
title2 Entries in this report older than today could signify orphaned sessions;
data cleanwork;
    infile cleanwrk;
    length f1 $20
           workdir $50;
    input f1 $ workdir $ f2 $ f3 $ f4 $ f5 $ f6 $ f7 $ pid;
    keep workdir pid;
    workdir=scan(workdir,-1,'/');
run;
data fullwork;
    set fullwork;
    maindir=scan(parent,3,'/');
    sizemb=size/1024000;
run;
proc means data=fullwork nway noprint;
    /* only maindir subsets here due to 1-1 correspondence of the rest with it */
    class maindir uid display_name email_address;
    output out=saswork_means
         sum(sizemb)=sizemb  min(lastaccess)=lastaccess
    ;
run;
proc sort data=saswork_means;
    by lastaccess display_name;
run;
proc print data=saswork_means label;
    label maindir="SASWORK Directory" uid='User' lastaccess="Creation Date" sizemb="Approx. Dir Size (MB)";
    format sizemb comma15.2;
    var maindir ;
    var uid;
    var display_name;
    var lastaccess;
    var sizemb;
run;

/* Report by user */
title -------------------------    Disk Use by User    -------------------------;
proc means data=alldirs nway noprint;
    class k_id userid ;
    output out=usermeans n=objectcount sum(sizemb)=totalmb;
run;
proc sort data=usermeans;
    by descending totalmb;
run;
ods proclabel="Disk Use By User";
proc report data=usermeans nowd;
    columns k_id userid totalmb;
    define k_id / "K ID" style=[width=1in];
    define userid /display  "User Name" style=[width=3in];
    define totalmb /order order=data "Total (MB)" format=comma15.2 style=[width=1.5in];
    compute k_id;
        urlstring="files/" || k_id || ".htm";
         call define(_col_, 'URL', compress(urlstring));
    endcomp;
run;quit;


options ls=80;
title ------------------------- File System Monitor Status -------------------------;
    data _null_;
         file print;
         infile mon;
         input;
         if index(_infile_,'grep ') = 0 then
              put _infile_;
    run;

/* Report by user */
title -----------------------    Home Disk Use by User    ----------------------;
proc means data=home nway noprint;
    class userid ;
    output out=usermeans n=objectcount sum(sizemb)=totalmb;
run;
proc sort data=usermeans;
    by descending totalmb;
run;

proc print label;
    format totalmb comma15.2;
    label userid='User' totalmb ="MB Used";
    var userid ;
    var totalmb /style={background=painthom.};
    sum totalmb;
run;


options ls=180;
title ------------------------- User List Issues -------------------------;

    title Active Users on &server That Are Not on User List;
    proc sql;
         select distinct(userid) label= "Problematic Userid"
          from alldirs
         where ( m_uid
           or missing(email_address))
          and userid ~in('sasadmin','sas','sasprod','root');
    quit;
    proc sql;
         title Users Established on Server but not on Master User List;
         select a.k_id label= "K ID", a.username label= "User Name" from unixaccounts a left join core.sasusers b
              on a.k_id=b.k_id
              where b.k_id is null and substr(a.k_id,1,1)='k';

         title Users Established on Master User List but not Established on Server;
         select a.k_id label="K ID", a.display_name label= "User Name" from core.sasusers a left join unixaccounts b
              on a.k_id=b.k_id
              where b.k_id is null and substr(a.k_id,1,1)='k';
    quit;
    title;


/* Report by group */
title ------------------------- Largest Group Disk Use -------------------------;
proc means data=alldirs nway noprint;
    class group ;
    output out=groupmeans n=objectcount sum(sizemb)=totalmb;
run;
proc sort data=groupmeans;
    by descending totalmb;
run;
proc print label;
    format totalmb comma15.2;
    label group='Group' totalmb ="MB Used";
    var group totalmb;
    sum totalmb;
run;
title Disk Utilization Time Series;
data diskutil;
    set core.diskutil;
    used=gbblocks-free;
    obsday=datepart(reportdate);
run;

proc means data=diskutil nway noprint;
    class obsday filesystem;
    output out=diskrep max(pctused)=;
run;
proc transpose data=diskrep(drop=_freq_ _type_) out=tdiskrep(rename=(_dev_hd1=home _dev_saslv4=saswork _dev_saslv2=Datamart
                     _dev_saslv5=Userspace));
    by obsday;
    id filesystem;
    var pctused;
run;
options ps=40;
 proc plot data=tdiskrep;
    format obsday mmddyy10.;
    plot home*obsday='-'
         saswork*obsday='*'
         datamart*obsday='+'
         userspace*obsday='o'/overlay;

run;
quit;


proc printto; run;
options ls=max ps=max missing=0;

title User by Group;
proc tabulate data=alldirs exclusive ;
    class group userid ;
    var sizemb;
    format group  userid $25.  ;
    table (userid=' ')*
               (  sum=' '
               /*    rowpctsum*{s={background=paintpct.}} */
               )
               all="Total in Group"*(sum=' ' )
               ,
               (group='User Disk Use by Group (MB)' all="User Total")*sizemb=''*f=comma15.2
               /rts=20 row=float;
run;

title User by File Type;
proc tabulate data=alldirs exclusive ;
    class userid fileext;
    format fileext $fileex. userid $25. ;

    var sizemb;
    table (userid=' ')*
               (  sum=' '
                   /*rowpctsum*{s={background=paintpct.}}*/

               )
               all='Total Over User'*(sum=' ')
               ,
               (fileext='User Disk Use by File Type (MB)'
                  all='Total Over File Type')*sizemb=''*
                (f=comma15.2
                 )
               / rts=20 row=float;
run;

title;

title Last Login  by User;

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

proc sql noprint;
    create table last_login_report as
    select a.*, b.display_name
    from lastlogin a left join core.sasusers b
    on a.k_id=b.k_id
    order by k_id, sdatetime desc;
quit;
data last_login_report;
    set last_login_report;
    by k_id descending sdatetime;
    if first.k_id then login=1;
    else login+1;
run;
proc report data=last_login_report nowd;
    columns display_name k_id term sdatetime edatetime elaptime;
    where login=1;
    define display_name /'User Name';
    define k_id / 'User Id';
    define term / 'Terminal';
    define sdatetime /order descending order=internal 'Session Start';
    define edatetime / 'Session End';
    define elaptime / 'Elap Time';

run;

title List of Active User Processes ;
data psstat;
    infile ps firstobs=2;
    length uid $8 pid ppid c 8 stime $8 tty $10 ttime $8 cmd $80;
    input uid $
          pid
          ppid
          c
          stime $
          tty $
          ttime $
          cmd && $
     ;
run;
     proc sql ;
              select  b.display_name, a.* from
               psstat a left join
               core.sasusers b
               on a.uid=b.k_id
               where substr(a.uid,1,1)='k';
          ;
     quit;

ods html close;

%reportbyuser;

%adminreport;
