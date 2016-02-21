

filename df pipe 'df -g';

data dfg;
    infile df firstobs=2 missover;
    length
         filesys   $50
         gb_blocks 8
         free      8
         pctused   8
         iused     8
         pctiused  8
         mount     $50
    ;
    informat
         pctused  percent4.
         pctiused percent4.
    ;

    input filesys $
          GB_Blocks ??
          free      ??
          pctused   ??
          iused     ??
          pctiused  ??
          mount $;
run;
proc print; run;


%let rootdir=/caswork;

filename fngr pipe "finger &user";
data _null_;
    infile fngr;
    length realnm $100;
    input;
    put _infile_;
    call symput ('fullname',scan(_infile_,3,':'));
    stop;
run;

filename ls pipe "ls -RAlt &rootdir";

data userfiles;
    infile ls ;
    length parent $150
           perms $10
           username $8
           group    $8
           size     8
           mon      $3
           day      8
           yrtm     $5
           filenm   $50
    ;
    input;

    if _n_=1 then do;
         parent="&rootdir";
         retain parent;
    end;
    if ~missing(_infile_) then if substr(_infile_,1,1) in ('.','/')  then do;
         parent=compress(scan(_infile_,1,' '),':');
         retain parent;
    end;
    else if substr(_infile_,1,1) in ('d','-') then do;
         perms = scan(_infile_,1,' ');
         username = scan(_infile_,3,' ');
         group  = scan(_infile_,4,' ');
         size  = scan(_infile_,5,' ');
         mon   = scan(_infile_,6,' ');
         day   = scan(_infile_,7,' ');
         yrtm  = scan(_infile_,8,' ');
         filenm  = scan(_infile_,9,' ');

         label perms="Permissions"
               username = "User"
               group    = "UNIX Group"
               size     = "Size(B)"
               mon      ="Create Month"
               day      = "Create Day"
               yrtm     = "Create Time/Year"
               filenm   = "File Name"
               parent   = "Directory"
         ;
    end;
    format size comma28.;
    if username ne "&user" then delete;
run;
proc sort data=userfiles;
    by parent size;
run;

proc means data=userfiles;
    class username;
    output out=summ sum(size)=total;
run;
proc print data=summ;run;

title &FullName (&user) All Objects Under &rootdir;
proc print data=userfiles noobs label;
    format size comma22.;
    var parent perms size mon day yrtm filenm;
    sum size;
run;

title &FullName (&user) SAS Datasets in &rootdir;
proc print data=userfiles noobs label;
    where scan(filenm,2,'.')='sas7bdat';
    format size comma22.;
    var parent perms size mon day yrtm filenm;
    sum size;
run;


title &FullName (&user) Large Files in &rootdir;
proc print data=userfiles noobs label;
    where size > 500000;
    format size comma22.;
    var parent perms size mon day yrtm filenm;
    sum size;
run;
