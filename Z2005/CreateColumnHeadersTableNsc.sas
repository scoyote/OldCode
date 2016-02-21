/***************************************************************************************************
PROGRAM: CreateColumnHeadersTable.sas
PURPOSE: Creates metadata table and macro-variables, used to generate HTML via secondary data-steps.
CREATES:
   Tables:
   -SAVE.COLUMNHEADERS (contains column-name, format, label, and justification, for each report-table column, in order of creation (VARNUM order))
   Macro-variables:
   -SAVE_COLUMNCOUNT (contains the number of report-table columns)
   -SAVE_COLUMNNAMES (contains list of quoted report-table column-names)
   -SAVE_COLUMNJUSTS (contains list of quoted report-table column-justifications)
CREATED: Mark Beezhold, February 2007
CHANGED:
NOTES:   This program picks up the justification-value (JUST), from the DB2DATA.COLUMNPRESENTATION table,
NOTES:   and the labels and formats, from the &SAVE_LIBNAME..&SAVE_MEMNAME table.
NOTES:   The assumption is that the standard formats and labels have already been assigned and possibly
NOTES:   modified, before this file is executed.
REQUIRE:
   Libnames:
   -DB2DATA (Connection to SADWH, to read PGB.ADHOC.COLUMNPRESENTATION table)
   Tables:
   -Report-table (referenced via &SAVE_LIBNAME..&SAVE_MEMNAME)
   -PGB.ADHOC.COLUMNPRESENTATION (preexisting meta-data table)
   Macro-variables:
   -&SAVE_LOB     (associated once, per session)
   -&SAVE_LIBNAME (library where the report-table exists)
   -&SAVE_MEMNAME (report-table's name)
EXAMPLE: Intended to be used, according to the following example:

   %let SAVE_LOB=PGB;
   %let SAVE_LIBNAME=SAVE;
   %let SAVE_MEMNAME=REPORTDATA;
   %include MSADCODE(CreateColumnHeadersTable.sas);
***************************************************************************************************/
%include MSADCODE(SetSessionStateNsc.sas);

%global
   SAVE_LOB
   SAVE_LIBNAME
   SAVE_MEMNAME
   ;

proc sql noprint;
   create table SAVE.COLUMNHEADERS as
   select A.VARNUM
   ,      A.NAME
   ,      A.FORMAT
   ,      A.LABEL
   ,      case when B.JUST^='' then B.JUST else 'R' end as JUST
   from   DICTIONARY.COLUMNS as A
   left
   join   DB2DATA.COLUMNPRESENTATION as B
   on     B.LOB="&SAVE_LOB"
   and    B.NAME=A.NAME
   where  A.LIBNAME="&SAVE_LIBNAME"
   and    A.MEMNAME="&SAVE_MEMNAME"
   order
   by     A.VARNUM
   ;
   select compress(put(count(*),3.))
   into  :SAVE_COLUMNCOUNT
   from   SAVE.COLUMNHEADERS
   ;
   select quote(trim(NAME))
   ,      quote(trim(JUST))
   into  :SAVE_COLUMNNAMES separated by ' '
   ,     :SAVE_COLUMNJUSTS separated by ' '
   from   SAVE.COLUMNHEADERS
   ;
quit;




/********************************************* E N D **********************************************/
