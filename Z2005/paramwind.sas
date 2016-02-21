





data _null_  ;
    extstdt="'2009-09-01'";
    extendt="'2009-09-30'";
    outpath="/caswork";
    Windowit:
    window paramwnd  columns=80 rows=20  color=black
    #2 @10 'Part A Denial Report Generator Check Program' color=yellow
    #5 @10 'Extract Start Date:' color=yellow @35 extstdt $12. attr=underline color=cyan  display=yes
    #6 @10 'Extract End Date:'   color=yellow @35 extendt $12. attr=underline color=cyan
    #7 @10 'Output Path'         color=yellow @35 outpath $30. attr=underline color=cyan
    ;
    display paramwnd;
    window confrmit columns=80 rows=20 color=black
    #2 @10 'Confirm Entered Values' color=red   
    #5 @10 'Extract Start Date:' protect=yes color=blue   @35 extstdt $12. protect = yes  color=blue display=yes
    #6 @10 'Extract End Date:'   protect=yes color=blue   @35 extendt $12. protect = yes  color=blue display=yes
    #7 @10 'Output Path'         protect=yes color=blue   @35 outpath $30. protect = yes  color=blue display=yes
    #9 @10 'Is this ok (y/n)?'   protect=yes color=red    @35 choice $3.   protect = no   color=red  attr=underline        
;
    display confrmit;
    if upcase(compress(choice))='N' then goto windowit;

    call symput('extract_start_date',extstdt);
    call symput('extract_end_date',extendt);
    call symput('outpath',outpath);
    stop;
run;

%put Note: results = &extract_start_date &extract_end_date &outpath;
