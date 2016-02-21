***************************************************************
***                                                         ***
***           Reporting Macros                              ***
***                                                         ***
***                                                         ***
*** Purpose:  Macros for running the periodic reports       ***
*** Author:   Samuel T. Croker                              ***
*** Create:   7/16/09                                       ***
*** changes:                                                ***
***************************************************************;

%macro EmailReport(
     path
   , directory
   , subject
   , in1
   , filename
   , to
   , from
   , textmessage);
     x "cd &path";
     %if &directory~=NONE %then %do;
          x "tar -cvf report.tar &directory/";
          x "gzip -f report.tar";
          x "uuencode  report.tar.gz &filename..tar.gz > atch.tar.gz";
          x "cat &textmessage atch.tar.gz > combined.txt";
          x " mailx -s '&subject' -r &from &to < combined.txt";
         /* x " mailx -s '&subject' -r &from sam.croker@astrazeneca.com < combined.txt";  */

          x "rm atch.tar.gz combined.txt";
     %end;
     %else %do;
          x "uuencode &in1..htm report.htm > atch.htm ";
          x "cat &textmessage atch.htm > combined.txt";
          x " mailx -s '&subject' -r &from &to < combined.txt";
          /*x " mailx -s '&subject' -r &from sam.croker@astrazeneca.com < combined.txt";  */
          x "rm atch.htm combined.txt";
     %end;
%mend EmailReport;

%macro calldu;
    proc sql noprint;
         select count(distinct fname) into :numfname from saswork;
         %let numfname=&numfname;
         select distinct fname into :fname1-:fname&numfname from saswork;
    quit;

    %do file=1 %to &numfname;
         filename dupipe pipe "du -ms /sas/saswork/&&fname&file";
         data sasworktemp;
             infile dupipe missover dlm ='09'x;
             length sizemb 8 path $50;
             informat sizemb 20.2;
             input sizemb path $;
             call symput("s&file",sizemb);
             call symput("p&file",scan(path,-1,'/'));
         run;
         filename dupipe clear;
    %end;
   data saswork2;
         length fname $50;
         %do i=1 %to &numfname;
              sizemb = &&s&i;
              fname  = "&&p&i";
              output;
         %end;
    run;

%mend;


%macro ParseReport(
      reporttype   /* Differetiator between types of ls command output */
     ,outds        /* name of the resulting dataset */
     ,infile       /* file to be processed */
     );
     /* read in the ls -RAlt listing into a dataset */
     /* RAlt will give the last modification time of the file which
        is probably more app. than access time..*/
     data temp;
         length
              parent         $80
              type           $12
              fname           $80
              size           8
              lastaccess     8
              fileext        $25
              user group     $20

     ;
         format
              size           comma18.
              lastaccess     mmddyy10.
     ;
         %if %upcase(&reporttype)=RALT %then %do;
              if _n_=1 then parent="";   /* default the parent at the start */
              retain parent;
         %end;
         drop mon day timeyear;
         infile &infile  missover;         /* read in the piped ls command */
         input t $2. @ ;                    /* differentiate the input */
         /* if the first character does not indicate a data line then iterate */
         if missing(t) or substr(t,1,1)~in('d','l','-','/')  then return;
         /* otherwise continue in the ILDS */
         type=substr(t,1,1);

         %if %upcase(&reporttype)=RALT %then %do;
              /* look for when the parent directory changes and change the parent to reflect this */
              if type='/' then do;
                   input @1 parent $  ;
                   parent=translate(parent,'/',':');
                   return;
              end;
              /* if not a parent indicator, read in the file data */
              else do;
         %end;
              input
                   permissions    $    1-10
                   Directories         12-15
                   uid         $    17-24
                   group          $    26-33
                   size
                   mon            $
                   day
                   timeyear       $
                   fname
          ;
              /* if not a directory then get the file extension */
              if substr(t,1,1)='-' then fileext=scan(fname,-1,'.');
              /* timeyear can be time or year value so look to see which it is */
              if index(timeyear,':')~=0 then year=year(date());  /* reset to year if time */
              else if ~missing(timeyear) then year=timeyear;
              sizemb=size/1048576;         /* calculate MB */
              LastAccess=input(cats(day,mon,year),date9.);   /* create a lastaccess as sasdate */
              output;
         %if %upcase(&reporttype)=RALT %then %do;
         end;
         %end;
     run;
     proc sql noprint;
         create table &outds as
              select * from
               temp a left join
               core.sasusers b
               on a.uid=b.k_id
          ;
     quit;
     data &outds; set &outds;
         m_uid=missing(k_id);
         if ~m_uid then userid=compbl(translate(display_name,' ',','));
         else userid=uid;
     run;
     proc sql;
         drop table temp;
     quit;
%mend ParseReport;

%macro loaduserlist;
    /* ok, this is the lazy way of error trapping.  */
     /* load the current userlist from SAS04 */
     proc import out=core.sasusers
          dbms=excelcs
          replace

          datafile="E:\UnixSASAdmin\UNIXSASUserAdmin.xls";
          server="156.70.109.223" ;
         port=5042 ;
         version='2000';
         sheet="Active";
     run ;

     %if &syserr>0 %then %do;
         %put ERROR:  ******************************************************************;
         %put ERROR:  The PC File Server on USSBSAS04 was down, using previous user list;
         %put ERROR:  ******************************************************************;
    %end;

    data unixaccounts;
         length k_id $10 userinfo $50;
         infile "/etc/passwd" dlm=':' missover;
         input k_id f1 $ f2 $ f3 $ userinfo $;
         username=trim(left(scan(userinfo,4,'/')));
         if missing(username) then
              username=userinfo;
    run;

%mend;

%macro listuserfiles(uid,userid);
         title File Listings for &userid;
         proc report data=alldirs nowd;
              where uid="&uid";
              columns parent fname lastaccess sizemb;
              define parent /group "Directory" style=[width=4in];
              define fname  /group "File Name" style=[width=4in];
              define lastaccess /order "Modified" style(column)=[width=1in];
              define sizemb /analysis "File Size (MB)" style=[width=2in] format=comma17.4;
              break after parent /summarize page ol dul style=[background=bwh fontweight=bold];
              rbreak after /summarize ol style=[background=bwh fontweight=bold];
              /* so, I wanted to color the entire row, and this is the only way I could think of
                   to do it at the time */
              compute lastaccess;
                   if abs(date()-lastaccess) > 90 and abs(date()-lastaccess) <= 180 then do;
                        call define(_row_ ,
                               'style',
                               'style={background=yellow}');
                   end;
                   else if abs(date()-lastaccess) > 180 and abs(date()-lastaccess) < 365 then do;
                        call define(_row_ ,
                               'style',
                               'style={background=orange}');
                   end;
                   else if abs(date()-lastaccess) > 365  and abs(date()-lastaccess) <=720 then do;
                        call define(_row_ ,
                               'style',
                               'style={background=red}');
                   end;
                   else if abs(date()-lastaccess) > 720 then do;
                        call define(_row_ ,
                               'style',
                               'style={background=magenta}');
                   end;
                   else  do;
                        call define(_row_ ,
                               'style',
                               'style={background=white}');
                   end;

              endcompute;
         run; quit;
         title;
%mend listuserfiles;

%macro reportbyuser;
    proc sql noprint;
         select count(distinct uid) into :numuser from alldirs
              where uid ~in ('root','sas') and ~missing(uid);
         %let numuser=&numuser;
         select distinct uid
                       , userid
                       , email_address
                       , admin_report
                   into :uid1-:uid&numuser
                      , :user1-:user&numuser
                      , :email1-:email&numuser
                      , :admin1-:admin&numuser
              from alldirs
              where uid ~in ('root','sas');
    quit;

    %do i=1 %to &numuser;
         %if "&&uid&i" ~= "" %then %do;
            ods html
                   file      = "/sas/adminscripts/webreport/files/&&uid&i...htm"
                   style     = styles.statistical
                   newfile   = none
                   ;
                 options ps=50;
                 %utilgraph(&&uid&i., &&user&i);
                 options ps=max;
                 %listuserfiles(&&uid&i., &&user&i);
            ods html close;
            %put DEBUG: email&i=&&email&i admin&i=&&admin&i;
            %if "&&email&i"~= "" and %upcase(&&admin&i) = U %then %do;
                  %put EMAILED TO: &&uid&i to &&email&i;
                  %emailreport(
                         /sas/adminscripts/webreport/files
                        ,NONE
                        ,&&uid&i File Usage on &server
                        ,&&uid&i
                        ,FileReport
                        ,&&email&i
                        ,&comsas
                        ,/sas/adminscripts/webreport/files/message.txt);
            %end;
         %end;
    %end;
%mend reportbyuser;



%macro UtilGraph(uid,userid);
     title;
     proc chart data=alldirs;
         %if %upcase(&uid) ~= ALL %then %do;
              where uid="&uid";
         %end;
         label lastaccess = 'Creation/Modification Date'
               sizemb = 'Total Size (MB)';
         format
              lastaccess monyy5.
              sizemb comma15.
              fileext $fileex.
             ;
         label fileext="File Extension";
         options ps=25 ls=80;
         title &Userid - Graph of Utilization by Creation Date;
         vbar lastaccess /sumvar=sizemb discrete ;
         title &Userid - File Types;
         vbar fileext / sumvar=sizemb   ;
         run;
         options ps=max ls=100;
     quit;

     title;
%mend UtilGraph;


%macro Adminreport;
    proc sql ;
         select count(distinct k_id) into :numuser from core.sasusers
              where admin_report='A';
         %let numuser=&numuser;
         select distinct k_id
                       , email_address
                       , admin_report
                   into :uid1-:uid&numuser
                      , :email1-:email&numuser
                      , :admin1-:admin&numuser
              from core.sasusers
              where admin_report='A';
    quit;

    %do i=1 %to &numuser;
       %if "&&email&i"~= "" %then %do;
       %put EMAIL: Managers Report Sent to &&email&i;
             %emailreport(
                    /sas/adminscripts
                   ,webreport
                   ,Manager Weekly Utilization Report on &server
                   ,FileSystem
                   ,FileReport
                   ,&&email&i
                   ,&comsas
                   ,/sas/adminscripts/webreport/files/message.txt);
       %end;
    %end;
%mend adminreport;
