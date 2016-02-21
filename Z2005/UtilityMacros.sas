/*************************************************************
***                                                        ***
*** UtilityMacros.sas                                      ***
*** Purpose: These macros perform utility actions that     ***
*** I use in my checking programs.  They are not essential ***
*** to program execution and generally may be removed from ***
*** programs without issue.                                ***
*** Author:  Samuel Croker                                 ***
*** Created: 8/27/09                                       ***
*** Dependencies:                                          ***
***     user and mypw macro variables containing SADWH     ***
***      login information                                 ***
*** Paths:                                                 ***
***     output:&rawpath/output                             ***
*** ResultDS:                                              ***
*** Modifications:                                         ***
***                                                        ***
***                                                        ***
*** Notes:                                                 ***
*************************************************************/

%macro comprow(
/* This macro takes three parameters, two input datasets to be compared and
    a string of BY variables.  It sorts both datasets by the by variables
    checks the row counts and runs proc compare.  For my benefit, if the
    rowcounts are different, then it reports this and runs an unmatched
    query against both datasets using the BY variables.
    Unmatched queries are run in both directions and the results are
    printed to the output.
    It does not really matter which dataset is base and which is compare but
    it is important to understand which is which when interpreting the results
    of proc compare so it is best to use the base as the original or previous
    and the compare as the check or current dataset.

    The proc compare run is exact and does not use the by values except for
    the sort order of the incoming datasets.
*/
      base    /* input dataset #1 */
     ,comp    /* input dataset #2 */
     ,byvar   /* string of by variables */
     );

     /* the compare procedure and the data step unmatched queries require sorting. */
     proc sort data=&base;
         by &byvar;
     run;
     proc sort data=&comp;
         by &byvar;
     run;

     /* Get the rowcounts from both tables to see if they are equal. */
     proc sql noprint;
          select count(*) into :basecount from &base;
          select count(*) into :compcount from &comp;
     quit;

     /* When the row counts do not match, then run the unmatched queries in both directions.
        Just matching on rows does not mean that the datasets have comparable attributes, but
        this will show up in the proc compare.  If the datasets do not have comparable rows then
         the proc compare will be really off but it is not so easy to see what the differences are
         as by looking at the unmatched queries.*/
     %if %eval(&basecount-&compcount) ~= 0 %then %do;
         %put ERROR: %upcase(&base): %cmpres(&basecount) Rows (comprow macro);
         %put ERROR: %upcase(&comp): %cmpres(&compcount) Rows (comprow macro);
         %let syscc=%eval(&syscc+1000); /* add an arbitrary 1000 to syscc to raise error */
         /* execute unmatched queries.  I used the data step here over
              proc sql since the by variable string would be cumbersome
              if delimtied by commas - since it is a macro variable and
              all.
         */

         /* forward unmatched query */
         title Rows on %upcase(&base) not on %upcase(&comp) (comprow macro);
         data nocomp;
              merge &base (in=y1)
                    &comp (in=y2);
              if y1 and ~y2;
              by &byvar;
         run;
         proc print;
            format _Character_ $10.;
         run;

         /* reverse unmatched query */
         title Rows on %upcase(&comp) not on %upcase(&base) (comprow macro);
         data nocomp;
              merge &comp (in=y1)
                    &base (in=y2);
              if y1 and ~y2;
              by &byvar;
         run;
         proc print;
            format _Character_ $10.;
         run;

         title;

         %put WARNING: Since the number of rows are not equal, PROC COMPARE was not run (comprow macro);
    %end;
    %else %do;
        %put NOTE: %upcase(&base) rowcount(%cmpres(&basecount)) = %upcase(&comp) rowcount(%cmpres(&compcount)) (comprow macro);

        /* strict comparison */
        title Compare Procedure of %upcase(&base) and %upcase(&comp) (comprow macro);
        proc compare
                  base=&base
                  compare=&comp
                  outnoequal
                  out=compareout
                  ;
        run;
        proc sql noprint;
         select count(*) into :unequalrows from compareout;
        quit;
        %if &unequalrows>0 %then %do;
             %put ERROR: Compare Procedure for &base and &comp resulted in %cmpres(&unequalrows) unequal rows. ;
             %let syscc=%eval(&syscc+5);
        %end;
    %end;
%mend comprow;

%macro db2Runstats(
/* The point of this macro is to execute the runstats command against a table and capture the
   text returned from DB2 into the SAS log.  To do this, I redirect the output from the shell
   command using the 2>amp1 to make sure that all of the results going to stdout end up in the
   text file log, which is then written to the SAS log with a data _null_.
*/
               database                   /*DB2 database where target table resides */
              ,schema                     /*DB2 schema where the target database and table reside */
              ,table                      /*Target DB2 table (in the db and schema above */
              ,log=&outpath.db2log.log    /*directory for the output from the x command */
    );
    /* Dependencies:  NONE */

    x "db2 connect to &database user &user using &mypw >&log 2>&1";
    %put COMMMAND EXECUTED: db2 runstats on table &schema..&table with distribution and detailed indexes all;
    x "db2 'runstats on table &schema..&table with distribution and detailed indexes all' >> &log 2>&1";
    x "db2 disconnect all >> &log 2>&1";
    data _null_;infile "&log"; input;  put _infile_; run;
    proc sql;
         connect to db2 (db=&database user=&user using=&mypw schema=&schema);
              select
                      tabname               format=$20.
                     ,tabschema             format=$10.
                     ,tbspace               format=$10.
                     ,definer               format=$8.
                     ,create_time           format=datetime16.
                     ,stats_time            format=datetime16.
                     ,card                  as cardinality format=comma16.
                     ,compression           format=$1.
                   from connection to db2 (
                        select *
                        from syscat.tables
                        where tabname    =%bquote(')%upcase(&table)%bquote(')
                              and
                              tabschema  =%bquote(')%upcase(&schema)%bquote(')
               );
         disconnect from db2;
    quit;
%mend;

%macro reporterror;
/* This utility macro takes the syscc code and reports its status.  The usage
    is intended to be as follows:
    1) Set syscc to zero at the beginning of the program (%let syscc=0;)
    2) execute bulk of program
    3) at end of program , run the reporterror macro which will display session level error message
*/
    %if &syscc>0 %then %do;
     %put ERROR: *****************************************************************;
     %put ERROR: ***** Errors or Warnings were generated during execution    *****;
     %put ERROR: *****                 (syscc=&syscc)                             ;
     %put ERROR: ***** This program did not run clean.  Check the log.       *****;
     %put ERROR: *****************************************************************;
    %end;
%mend reporterror;
