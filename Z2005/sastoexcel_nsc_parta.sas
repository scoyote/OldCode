%******************************************************************************;
%* Andrea: Good luck QCing this! --Shane                                      *;
%******************************************************************************;
%*                                                                            *;
%* SOURCE   : sastoxl.sas                                                     *;
%*                                                                            *;
%* PURPOSE  : To pour the contents of a SAS data set into a MS Excel spread-  *;
%*            sheet using DDE. The resulting spreadsheet receives some basic  *;
%*            formatting and is saved to a specified location. Values are     *;
%*            entered with their formats applied, whenever there is one       *;
%*            defined on the data set. An existing Excel file can be written  *;
%*            to, rather than a blank document. Custom sheetnames are sup-    *;
%*            ported, either existing ones or new ones ...                    *;
%*                                                                            *;
%* CREATED  : 08DEC1999 by Koen Vyverman                                      *;
%*                                                                            *;
%* MODIFIED : 31DEC2000 by Koen Vyverman                                      *;
%*              Re-wrote some of the macro decision code in a more canonical  *;
%*              form that will ensure proper SASv8 functioning.               *;
%*                                                                            *;
%*            04JAN2001 by Koen Vyverman                                      *;
%*              Added quite a slab of code to take care of custom sheet-names *;
%*              in the output spreadsheet. Introduced some long filenames in  *;
%*              the process, so this now no longer works with SAS v6.12 and   *;
%*              earlier ... Can be easily repaired though if necessary.       *;
%*              In the same go, removed all traces of the early WAPTWAP me-   *;
%*              thodology for resolving macro-variables before throwing them  *;
%*              at the DDE-link. Now, resolution is forced by means of dummy  *;
%*              text-variables (see DDECMD and MACCMD in the code ...)        *;
%*                                                                            *;
%* USAGE    : Macro parameters :                                              *;
%*                                                                            *;
%*            libin    (required): SAS library where the input SAS data set   *;
%*                                 lives.                                     *;
%*                                                                            *;
%*            dsin     (required): Name of the SAS data set (part of) which   *;
%*                                 needs to be dumped into Excel format.      *;
%*                                                                            *;
%*            cell1row (optional): The row number of the first cell of the XL *;
%*                                 spreadsheet where data should be inserted. *;
%*                                 i.e. the upper left corner of the output   *;
%*                                 data range.                                *;
%*                                 Default = 1.                               *;
%*                                                                            *;
%*            cell1col (optional): The column number of the first cell of the *;
%*                                 XL spreadsheet where data should be in-    *;
%*                                 serted.                                    *;
%*                                 i.e. the upper left corner of the output   *;
%*                                 data range.                                *;
%*                                 Default = 1.                               *;
%*                                                                            *;
%*            nrows    (optional): The number of rows/observations to be in-  *;
%*                                 serted. If none is specified, an attempt   *;
%*                                 will be made to insert all observations    *;
%*                                 into XL.                                   *;
%*                                 Needless to say, this number needs to be   *;
%*                                 smaller than the maximal number of rows    *;
%*                                 supported by Excel...                      *;
%*                                                                            *;
%*            ncols    (optional): The number of columns/variables to be in-  *;
%*                                 serted. If none is specified, an attempt   *;
%*                                 will be made to insert all variables into  *;
%*                                 XL.                                        *;
%*                                 Needless to say, this number needs to be   *;
%*                                 smaller than the maximal number of columns *;
%*                                 supported by Excel...                      *;
%*                                                                            *;
%*            tmplpath (optional): The full path to the directory where the   *;
%*                                 Excel spreadsheet resides to which the     *;
%*                                 data needs to be written. To be used in    *;
%*                                 conjunction with TMPLNAME. If none is spe- *;
%*                                 cified, a standard new XL workbook will be *;
%*                                 used. Do _not_ end the path with a back-   *;
%*                                 slash character.                           *;
%*                                                                            *;
%*            tmplname (optional): The filename of the Excel workbook in the  *;
%*                                 directory specified by TMPLPATH to which   *;
%*                                 the data needs to be written. To be used   *;
%*                                 in conjunction with TMPLPATH. If none is   *;
%*                                 specified, a standard new XL workbook will *;
%*                                 be used. Do _not_ end the name with a .xls *;
%*                                 filename extension.                        *;
%*                                                                            *;
%*            sheet    (optional): The name of the worksheet within the Excel *;
%*                                 workbook to which the data will be writ-   *;
%*                                 ten. When left blank, this defaults to a   *;
%*                                 name of the form 'SheetN' where N is the   *;
%*                                 smallest available positive integer not    *;
%*                                 yet in use in the Excel workbook. Just try *;
%*                                 some, pretty cool :-)                      *;
%*                                                                            *;
%*            savepath (optional): The full path to the directory where the   *;
%*                                 finalized Excel workbook needs to be       *;
%*                                 saved. May be used independently from      *;
%*                                 SAVENAME. Do _not_ end the path with a     *;
%*                                 back-slash character.                      *;
%*                                 Default = c:\temp                          *;
%*                                                                            *;
%*            savename (optional): The filename by which the finalized Excel  *;
%*                                 workbook should be saved in the directory  *;
%*                                 specified by SAVEPATH. May be used inde-   *;
%*                                 pendently from SAVEPATH.                   *;
%*                                 Default = SASTOXL Output                   *;
%*                                                                            *;
%*            stdfmtng (optional): Standard formatting flag. Off by default.  *;
%*                                 Give a value of 1 to turn on. This will    *;
%*                                 apply some basic formatting to the         *;
%*                                 inserted data. The label row will be bol-  *;
%*                                 dened. Font will be set to Courier. Column *;
%*                                 width will be set to best fit. Freeze      *;
%*                                 panes will be turned on for the label row. *;
%*                                                                            *;
%* EXAMPLE  : 1) Suppose the data set WORK.SOMETHNG needs to be exported to   *;
%*               an Excel spreadsheet, and saved as 'c:\temp\Some data.xls'.  *;
%*               The data should end up in a worksheet with the default name  *;
%*               'Sheet1', and have the standard formatting applied to them.  *;
%*               To accomplish this, submit the following macro call:         *;
%*               %sastoxl(                                                    *;
%*                        libin=work,                                         *;
%*                        dsin=somethng,                                      *;
%*                        savepath=c:\temp,                                   *;
%*                        savename=Some Data,                                 *;
%*                        stdfmtng=1                                          *;
%*                       );                                                   *;
%*                                                                            *;
%*            2) Suppose only the first 125 rows of data set WORK.SOMETHNG    *;
%*               need to be exported to an existing Excel spreadsheet, and    *;
%*               saved as 'c:\temp\Some data.xls'. Suppose the full path and  *;
%*               name of the document in which the data need to be inserted   *;
%*               is 'n:\sasok\data\blank dox\Serious Fun.xls', and the block  *;
%*               of data is wanted at row 37, column 3 of a worksheet named   *;
%*               'Stuff from SAS'. If 'Stuff from SAS' does not exist yet on  *;
%*               'Serious Fun.xls', then it should be added as an extra sheet.*;
%*               To accomplish this, submit the following macro call:         *;
%*               %sastoxl(                                                    *;
%*                        libin=work,                                         *;
%*                        dsin=somethng,                                      *;
%*                        cell1row=37,                                        *;
%*                        cell1col=3,                                         *;
%*                        nrows=125,                                          *;
%*                        tmplpath=n:\sasok\data\blank dox,                   *;
%*                        tmplname=Serious Fun,                               *;
%*                        sheet=Stuff from SAS,                               *;
%*                        savepath=c:\temp,                                   *;
%*                        savename=Some Data,                                 *;
%*                        stdfmtng=1                                          *;
%*                       );                                                   *;
%*                                                                            *;
%* CAVEAT   : Specifying either TMPLPATH or TMPLNAME without the other will   *;
%*            result in both values being reset to their default settings. As *;
%*            a consequence, a standard new document will be used.            *;
%*                                                                            *;
%*            Specifying a SHEET that already exists on the target workbook   *;
%*            will result in the content thereof (if any) being at least      *;
%*            partially over-written by the exported SAS data. Pay attention. *;
%*                                                                            *;
%*            The names of worksheets in an Excel workbook are _not_ case     *;
%*            sensitive, even if they look as if they are because one is      *;
%*            allowed to use mixed case in the naming. The same goes for the  *;
%*            filenames under Windows by the way ...                          *;
%*                                                                            *;
%******************************************************************************;


%macro sastoxl(
               libin=,
               dsin=,
               cell1row=1,
               cell1col=1,
               nrows=,
               ncols=,
               tmplpath=,
               tmplname=,
               sheet=,
               savepath=c:\temp,
               savename=SASTOXL Output,
               stdfmtng=
			   month=
			   ,xlsfont=courier
              );


  %local
    ready
    misspar
    cnotes
    csource
    csource2
    cmlogic
    csymbolg
    cmprint
    tab
    ulrowlab
    ulcollab
    lrrowlab
    lrcollab
    ulrowdat
    ulcoldat
    lrrowdat
    lrcoldat
    lrecl
    types
    vars
    i
    colind
    nsheets
    shxists
    oldshnam
    ;
    
    
  %let ready=0;
  %let misspar=0;
  %let cnotes=0;
  %let csource=0;
  %let csource2=0;
  %let cmlogic=0;
  %let csymbolg=0;
  %let cmprint=0;
  %let tab='09'x;
  %let ulrowlab=;
  %let ulcollab=;
  %let lrrowlab=;
  %let lrcollab=;
  %let ulrowdat=;
  %let ulcoldat=;
  %let lrrowdat=;
  %let lrcoldat=;
  %let lrecl=;
  %let types=;
  %let vars=;
  %let i=0;
  %let colind=;
  %let nsheets=0;
  %let shxists=0;
  %let oldshnam=;
   %let L = L;
   %let R = R;
   %let P = P;
   %let N = N;

  %* First we determine the values of certain SAS System options.             *;
  %if %sysfunc(getoption(notes))=NOTES %then %do;
    %let cnotes=1;
    %end;
    
    
  %if %sysfunc(getoption(source))=SOURCE %then %do;
    %let csource=1;
    %end;
    
    
  %if %sysfunc(getoption(source2))=SOURCE2 %then %do;
    %let csource2=1;
    %end;


  %if %sysfunc(getoption(mlogic))=MLOGIC %then %do;
    %let cmlogic=1;
    %end;


  %if %sysfunc(getoption(symbolgen))=SYMBOLGEN %then %do;
    %let csymbolg=1;
    %end;


  %if %sysfunc(getoption(mprint))=MPRINT %then %do;
    %let cmprint=1;
    %end;

  
  %put;


  %* We then turn all those options off, this to minimize the amount of junk  *;
  %* that the usage of this macro would otherwise insert between the lines of *;
  %* the LOG of the code in which it gets used...                             *;
  *options
    nonotes
    nosource
    nosource2
    nomlogic
    nosymbolgen
    nomprint
    ;


  %* Then, we do some parameter checking...                                   *;
  %if ("&libin"="") %then %do;
    %put ER%str()ROR: The LIBIN parameter is missing in a call to the SASTOXL macro!;
    %let misspar=1;
    %end;


  %if ("&dsin"="") %then %do;
    %put ER%str()ROR: The DSIN parameter is missing in a call to the SASTOXL macro!;
    %let misspar=1;
    %end;


  %if &misspar %then %do;
    %put;
    %put ER%str()ROR: The SASTOXL macro bombed due to errors...;
    %put;
    %goto mquit;
    %end;


  %* If we are still there, we fill in the values of some of the optional     *;
  %* parameters that were either left blank, or were inadvertently reset to   *;
  %* blank in the macro call.                                                 *;
  %if ("&cell1row"="") %then %do;
    %let cell1row=1;
    %put;
    %put NO%str()TE: The default value of the CELL1ROW parameter appears to have been;
    %put ----- overwritten by a _NULL_ value during invocation of the SASTOXL;
    %put ----- macro. It has been reset to '1' in order to allow macro execution.;
    %put;
    %end;


  %if ("&cell1col"="") %then %do;
    %let cell1col=1;
    %put;
    %put NO%str()TE: The default value of the CELL1COL parameter appears to have been;
    %put ----- overwritten by a _NULL_ value during invocation of the SASTOXL;
    %put ----- macro. It has been reset to '1' in order to allow macro execution.;
    %put;
    %end;


  %if ("&savepath"="") %then %do;
    %let savepath=c:\temp;
    %put;
    %put NO%str()TE: The default value of the SAVEPATH parameter appears to have been;
    %put ----- overwritten by a _NULL_ value during invocation of the SASTOXL;
    %put ----- macro. It has been reset to 'c:\temp' in order to allow macro execution.;
    %put;
    %end;


  %if ("&savename"="") %then %do;
    %let savename=SASTOXL Output;
    %put;
    %put NO%str()TE: The default value of the SAVENAME parameter appears to have been;
    %put ----- overwritten by a _NULL_ value during invocation of the SASTOXL;
    %put ----- macro. It has been reset to 'SASTOXL Output' in order to allow macro execution.;
    %put;
    %end;


  %if ("&nrows"="") %then %do;
    proc sql noprint;
      select 
        trim(left(put(nobs,20.))) into :nrows
      from 
        sashelp.vtable
      where 
        (libname=upcase("&libin"))
        and
        (memname=upcase("&dsin"))
      ;
    quit;
    %end;


  %if ("&ncols"="") %then %do;
    proc sql noprint;
      select 
        trim(left(put(nvar,20.))) into :ncols
      from 
        sashelp.vtable
      where 
        (libname=upcase("&libin"))
        and
        (memname=upcase("&dsin"))
      ;
    quit;
    %end;


  %* To make sure that a put-statement to one of our DDE-filenames remains on *;
  %* one single row of the spreadsheet, we calculate a LRECL for the filename *;
  %* that will (hopefully) be large enough to accommodate all the formatted   *;
  %* values that we will want to push through. In the old SAS 6.12 spirit, we *;
  %* assume that 200 bytes per variable will do the trick. When exporting v8  *;
  %* data sets with extremely long character variables, this may obviously    *;
  %* lead to trouble and should be coded a bit more robustly at some point.   *;
  %let lrecl=%eval(200*&ncols);


  %* The parameters TMPLPATH and TMPLNAME should be used in conjunction with  *;
  %* each other. Check if this is the case. When necessary, reset both to a   *;
  %* _NULL_ value...                                                          *;
  %if (("&tmplpath"="") and ("&tmplname" ne "")) or (("&tmplpath" ne "") and ("&tmplname"="")) %then %do;
    %let tmplpath=;
    %let tmplname=;
    %put;
    %put NO%str()TE: During invocation of the SASTOXL macro, either the parameter TMPLPATH;
    %put ----- was specified without TMPLNAME, or vice versa. The macro expects either;
    %put ----- both or none of them. They have been reset to a _NULL_ value to allow macro execution.;
    %put;
    %end;


  %* The following either launches MS Excel, or does nothing if an instance   *;
  %* of the application is already running. The trick for finding out is sim- *;
  %* le: define the proper filename, and then give it a poke to see if it ge- *;
  %* nerates an error or not ...                                              *;
  filename sas2xl dde 'excel|system';
  
  data _null_;
    file sas2xl;
  run;


  options
    noxwait
    noxsync
    ;
  

  %if &syserr ne 0 %then %do;
    
    x '"c:\program files\microsoft office\office11\excel.exe"';
 
    data _null_;
      x=sleep(10);
    run;
  
    %end;


  %* We then open a DDE link to MS Excel for the sending of system commands.  *;
  filename sas2xl dde 'excel|system';

  %* If TMPLPATH and TMPLNAME were given, we open the document they specify.  *;
  %* Otherwise, we ask for a new blank document of the workbook type.         *;
  %if (("&tmplpath" ne "") and ("&tmplname" ne "")) %then %do;
    data _null_;
      length
        ddecmd $ 200
        ;
      file sas2xl;
      put '[error(false)]';
      ddecmd='[open("'||"&tmplpath"||'\'||"&tmplname"||'")]';
      put ddecmd;
 run;
    %end;
  %else %do;
    data _null_;
      file sas2xl;
      put '[error(false)]';
      put '[new(1)]';
run;

		data _null_;
		   file sas2xl;
		   put "[page.setup(""&header1" '0d'x "&header2" '0d'x "&header3" '0d'x "&header4"",,0.75,0.75,1.26,1.20,False,False,False,False,2)]";
		   put "[PAGE.SETUP(,""%nrstr(&L)&fnote1" '0d'x "%nrstr(&L)&fnote2" '0d'x "%nrstr(&L)&fnote3" "%nrstr(&R)Page %nrstr(&P) of %nrstr(&N)"")]";
		   put '[select("r1c1:r1c100")]';
		   put '[Format.Font("Courier New",8,True,False,False,False,0)]';
           put '[Alignment(,True)]';
		   put '[column.width(,,,3)]';
		   put '[select("r2c1:r63999c100")]';
		   put '[Format.Font("Courier New",8,False,False,False,False,0)]';

run;
    %end;


  %* We then need to define a DDE link pointing to the exact location where   *;
  %* data should be inserted. To do so, we need to know the filename. The     *;
  %* easiest way to find the filename is to save the document at the location *;
  %* specified by &SAVEPATH with the name &SAVENAME...                        *;
  data _null_;
    length
      ddecmd $ 200
      ;
    file sas2xl;
    put '[error(false)]';
    ddecmd='[save.as("'||"&savepath"||'\'||"&savename"||'")]';
    put ddecmd;
  run;

  %* In what follows, we may need an old-style macro-sheet to be available in *;
  %* the current Excel workbook. We assume the workbook to contain no such    *;
  %* sheets yet, so ours will be named Macro1 by default. We also want it to  *;
  %* sit on top of all the other sheets in the workbook. This is important in *;
  %* what follows ...                                                         *;
  data _null_;
    length
      ddecmd $ 200
      ;
    file sas2xl;
    %* In case the current workbook has more than one sheet selected, the     *;
    %* workbook.insert command will insert multiple new sheets before those   *;
    %* selected. We do not want that and therefore advance the selection by   *;
    %* one, just as a means of making sure that a single sheet is selected.   *;
    put '[workbook.next()]';
    %* Create the blank Macro1-sheet in front of the currently selected sheet.*;
    put '[workbook.insert(3)]';
    %* Move the Macro1-sheet to the top of the workbook.                      *;
    ddecmd='[workbook.move("Macro1","'||"&savename"||'.xls",1)]';
    put ddecmd;
run;

  %* Subsequently, we define a range in the first column of the macro-sheet,  *;
  %* sufficiently large to dump loads of Excel macro code into, but not so    *;
  %* large that the filename statement will take forever to compile. Yes,     *;
  %* this depends on the size of the cell-range to which it points ... We     *;
  %* assume that a thousand cells will do.                                    *;
  filename xlmacro dde "excel|macro1!r1c1:r1000c1" notab lrecl=200;


  %* As the next step in preparing for the actual writing out of data, we     *;
  %* need to implement some worksheet-logic. For starters, consider the case  *;
  %* where no values are given for either &TMPLPATH or &TMPLNAME. In this     *;
  %* case, the bit above will have created a new workbook with one worksheet  *;
  %* having the default name of 'Sheet1'. Therefore, if the &SHEET parameter  *;
  %* is left blank or has the value 'Sheet1', nothing needs to be done, just  *;
  %* dump the data in Sheet1 and be done with it. If OTOH &SHEET has a dif-   *;
  %* ferent value, we need to rename the default Sheet1 to reflect the de-    *;
  %* sired name. Note that sheet-names in Excel only look as if they are case *;
  %* sensitive. In fact they are not, and we always need to compare uppercase *;
  %* sheet-names ...                                                          *;
  %if (("&tmplpath"="") and ("&tmplname"="")) %then %do;

    %if (%upcase("&sheet")="") %then %do;

      %let sheet=sheet1;

      %end;

    %else %do;

   
      %* Write (and run) an Excel macro in the Macro1-sheet that will rename  *;
      %* the default worksheet 'Sheet1' to the desired name &SHEET.           *;
      data _null_;
        length
          maccmd $ 200
          ;
        file xlmacro;
        maccmd='=workbook.name("sheet1","'||"&sheet"||'")';
        put maccmd;
        put '=halt(true)';
        put '!dde_flush';
        file sas2xl;
        put '[run("macro1!r1c1")]';
        put '[error(false)]';
      run;


      %* Clear the Macro1-sheet in case we need it for another bit of code.   *;
      data _null_;
        file sas2xl;
        put '[workbook.activate("macro1",false)]';
        put '[select("r1c1:r1000c2")]';
        put '[clear(1)]';
        put '[select("r1c1")]';
      run;

      %end;

  %end;


  %* Now, if values were given for &TMPLPATH and &TMPLNAME, then we are oper- *;
  %* ating upon an existing workbook, and we must find out whether the &SHEET *;
  %* already exists therein or not. In this case, the first thing to do is to *;
  %* extract the list of existing sheet-names from the open workbook. We      *;
  %* store this in a temporary data set WORK._SHEET_NAMES We accomplish this  *;
  %* by writing an Excel-macro in the first column of the Macro1-sheet that   *;
  %* will load the sheetnames existing in the workbook into the second column *;
  %* of the Macro1-sheet. The following auxilliary macro will create the ne-  *;
  %* cessary Excel-macro code and run it:                                     *;
  %macro loadnames;

    %local
      sh
      wn
      ;

    %let sh=0;
    %let wn=0;

    %* Write and run an Excel macro in the Macro1-sheet that will put the     *;
    %* number of worksheets in the current workbook in cell $B$1 of the       *;
    %* Macro1-sheet.                                                          *;
    data _null_;
      file xlmacro;
      put '=set.value($b$1,get.workbook(4))';
      put '=halt(true)';
      put '!dde_flush';
      file sas2xl;
      put '[run("macro1!r1c1")]';
      put '[error(false)]';
    run;

    %* Define a DDE-link to this $B$1 cell ...                                *;
    filename nsheets dde "excel|macro1!r1c2:r1c2" notab lrecl=200;

    %* Read the number of sheets and store it in the SAS macro var &NSHEETS.  *;
    data _null_;
      length
        nsheets 8
        ;
      infile nsheets;
      input nsheets;
      call symput('nsheets',trim(left(put(nsheets,2.))));
    run;

    %* Note that the sheet-count &NSHEETS is actually one too many as it in-  *;
    %* cludes the temporary Macro1-sheet. Therefore ...                       *;
    %let nsheets=%eval(&nsheets-1);

    %* Clear the Macro1-sheet to make place for the next bit of Excel macro.  *;
    data _null_;
      file sas2xl;
      put '[workbook.activate("macro1",false)]';
      put '[select("r1c1:r1000c2")]';
      put '[clear(1)]';
      put '[select("r1c1")]';
    run;

    %* Write and run the Excel macro that will load the actual sheet-names:   *;
    data _null_;
      length
        maccmd $ 200
        ;
      file xlmacro;
      %do sh=1 %to &nsheets;
        maccmd="=select(!$b$&sh,!$b$&sh)";
        put maccmd;
        put '=set.name("cell",selection())';
        %do wn=1 %to &sh;
          put '=workbook.next()';
          %end;
        put '=set.value(cell,get.workbook(3))';
        put '=workbook.activate("Macro1",false)';
        %end;
      put '=halt(true)';
      put '!dde_flush';
      file sas2xl;
      put '[run("macro1!r1c1")]';
      put '[error(false)]';
    run;


    %* Define a DDE-link to the range of $B cells containing the names ...    *;
    filename sheets dde "excel|macro1!r1c2:r&nsheets.c2" lrecl=200;

    %* Read the sheetnames and dump into a small data set WORK._SHEET_NAMES   *;
    data _sheet_names;
      length
        bookname
        sheetname $ 100
        ;
      infile sheets delimiter=']';
      input
        bookname
        sheetname
        ;
      bookname=substr(bookname,2);
      bookname=left(reverse(substr(left(reverse(bookname)),5)));
    run;

    %* Clear the Macro1-sheet to make place for the next Excel macro ...      *;
    data _null_;
      file sas2xl;
      put '[workbook.activate("macro1",false)]';
      put '[select("r1c1:r1000c2")]';
      put '[clear(1)]';
      put '[select("r1c1")]';
    run;

    %* Minor clean-up ...                                                     *;
    filename nsheets clear;
    filename sheets clear;

  %mend loadnames;


  %if (("&tmplpath" ne "") and ("&tmplname" ne "")) %then %do;

    %loadnames;

    %* Now, if no &SHEET parameter was specified then we just need to add a   *;
    %* new worksheet (with the default name of SheetN, where N is the lowest  *;
    %* available integer that is not in use yet), dump the data in it, and be *;
    %* done. Sounds simple? Some tricky bits involved, though ...             *;
    %if (%upcase("&sheet")="") %then %do;

      data _null_;
        length
          ddecmd $ 200
          ;
        file sas2xl;
        %* Make sure only one sheet is selected ...                           *;
        put '[workbook.next()]';
        %* Insert a new worksheet somewhere, exact name as yet unknown.       *;
        put '[workbook.insert(1)]';
        %* Now we need to pick up the exact sheetname that just got created.  *;
        %* Rather than parse all names looking like 'Sheet...' from the data  *;
        %* set _SHEET_NAMES, we take the lazy approach and move the new sheet *;
        %* (which is at this point the active one) to the back of the work-   *;
        %* book. Leaving out the sheet-name in the workbook.name Excel func-  *;
        %* tion will act on the active sheet. However, leaving out the posi-  *;
        %* tion parameter will cause an error. Luckily we know &NSHEETS, to   *;
        %* which we need to add 1 to account for our temporary Macro1-sheet,  *;
        %* and add another 2 to get to the back of the row of sheets. For     *;
        %* some reason. Arf.                                                  *;
        ddecmd='[workbook.move(,"'||"&savename"||'.xls",'||%eval(&nsheets+3)||')]';
        put ddecmd;
      run;

      %* Then, running %LOADNAMES once more, we get the exact name of our new *;
      %* worksheet in the last obs of _SHEET_NAMES                            *;
      %loadnames;

      %* Pick it up, and stuff it into &SHEET.                                *;
      data _null_;
        set _sheet_names end=last;
        if last then do;
          call symput('sheet',trim(left(sheetname)));
          end;
      run;

      %end;

    %* If a name was specified for &SHEET, then we must first of all check    *;
    %* whether &SHEET already exists. We can do this because we have the data *;
    %* set _SHEET_NAMES. If the &SHEET already exists, we simply dump the     *;
    %* SAS data there, and done. This assumes that users know what they are   *;
    %* doing, at least to a certain degree, since extant data on the &SHEET   *;
    %* may be partially or completely over-written by the new data from SAS.  *;
    %* OTOH, if there is no &SHEET yet, we need to make it, using similar     *;
    %* techniques as in the above.                                            *;
    %else %do;

      %* Check if it exists ...                                               *;
      data _null_;
        set _sheet_names;
        if (upcase(sheetname)="%upcase(&sheet)") then do;
          call symput('shxists','1');
          end;
      run;

      %if &shxists=0 %then %do;

        %* Insert a new sheet and move it to the back.                        *;
        data _null_;
          length
            ddecmd $ 200
            ;
          file sas2xl;
          put '[workbook.next()]';
          put '[workbook.insert(1)]';
          ddecmd='[workbook.move(,"'||"&savename"||'.xls",'||%eval(&nsheets+3)||')]';
          put ddecmd;
        run;

		data _null_;
		   file sas2xl;
		   put "[page.setup(""&header1" '0d'x "&header2" '0d'x "&header3" '0d'x "&header4"",,0.75,0.75,1.26,1.20)]";
		   put "[PAGE.SETUP(,""%nrstr(&L)&fnote1" '0d'x "%nrstr(&L)&fnote2" '0d'x "%nrstr(&L)&fnote3" "%nrstr(&R)Page %nrstr(&P) of %nrstr(&N)"")]";
		   put '[select("r1c1:r1c100")]';
		   put '[Format.Font("Courier",8,True,False,False,False,0)]';
run;

      
       %loadnames;


        %* Read the name of it, store in &oldshnam.                           *;
        data _null_;
          set _sheet_names end=last;
          if last then do;
            call symput('oldshnam',trim(left(sheetname)));
            end;
        run;

        %* Write (and run) an Excel macro in the Macro1-sheet to rename the   *;
        %* worksheet &OLDSHNAM as &SHEET.                                     *;
        data _null_;
          length
            maccmd $ 200
            ;
          file xlmacro;
          maccmd='=workbook.name("'||"&oldshnam"||'","'||"&sheet"||'")';
          put maccmd;
          put '=halt(true)';
          put '!dde_flush';
          file sas2xl;
          put '[run("macro1!r1c1")]';
          put '[error(false)]';
        run;

        %* Clear the Macro1-sheet in case we need it for another bit of code ...  *;
        data _null_;
          file sas2xl;
          put '[workbook.activate("macro1",false)]';
          put '[select("r1c1:r1000c2")]';
          put '[clear(1)]';
          put '[select("r1c1")]';
        run;

        %end;
      %end;

    %end;


  %* Writing the labels and the data requires gathering some information      *;
  %* about the input data set:                                                *;
  proc contents data=&libin..&dsin
                out=____meta
                noprint;
  run;


  %* If a variable does not have a label defined, use the variable name...    *;
  data ____meta;
    set ____meta;
    if label=' ' then label=name;
  run;


  proc sort data=____meta;
    by
      varnum;
  run;


  %* Calculate the range of cells to which label data will be written. The    *;
  %* upper left cell is obviously defined by (&CELL1ROW,&CELL1COL). The lower *;
  %* right corner of the range, which incidentally is on the same row in case *;
  %* of the labels, is defined as follows.                                    *;
  %let ulrowlab=&cell1row;
  %let ulcollab=&cell1col;
  %let lrrowlab=&ulrowlab;
  %let lrcollab=%eval(&cell1col+&ncols-1);


  %* Calculate the range of cells to which the real data will be written. The *;
  %* upper left cell is obviously defined by (&CELL1ROW+1,&CELL1COL).         *;
  %let ulrowdat=%eval(&cell1row+1);
  %let ulcoldat=&cell1col;
  %let lrrowdat=%eval(&cell1row+&nrows);
  %let lrcoldat=%eval(&cell1col+&ncols-1);


  %* Now, before we even attempt to send any data to Excel, we select all     *;
  %* target cells to which we plan to write variables of type 2 (character)   *;
  %* and format them as text. Otherwise, MS Excel will try to be clever and   *;
  %* interpret the entered data, which we do not want to see happen. We leave *;
  %* the cells for numerical data alone, risking MS cleverness attempts. The  *;
  %* reason being that the autofilter tool performs badly on numerical data   *;
  %* with a text format imposed on it. Ah, well... cant have it all...        *;
  %* From ____META, we generate a list &TYPES of variable types, separated by *;
  %* blanks:                                                                  *;
  proc sql noprint;
    select distinct 
      type
    into
      :types separated by ' '
    from 
      ____meta
    order by
      varnum
    ;
  quit;


  data _null_;
    length
      ddecmd $ 200
      ;
    file sas2xl;
    put '[error(false)]';
    ddecmd='[workbook.activate("'||"&sheet"||'",false)]';
    put ddecmd;
                            %let i=1;
                            %let colind=;
                            %do %while (%length(%scan(&types,&i))>0);
                              %if ((%scan(&types,&i)=2) and (&i le &ncols)) %then %do;
                                %let colind=%eval(&ulcollab+&i-1);
    ddecmd='[select("r'||"&ulrowlab"||'c'||"&colind"||':r'||"&lrrowdat"||'c'||"&colind"||'")]';
    put ddecmd;
    put '[format.number("@")]';
                                %end;
                                %let i=%eval(&i+1);
                              %end;
  run;


  %* Now we can define the DDE link for the section of the spreadsheet where  *;
  %* the variable labels will be written:                                     *;
  filename xllabels dde "excel|&savepath.\[&savename..xls]&sheet!r&ulrowlab.c&ulcollab.:r&lrrowlab.c&lrcollab." notab lrecl=&lrecl;


  %* For the first &NCOLS variables, we write the labels to the DDE-filename  *;
  %* XLLABELS.                                                                *;
  data _null_;
    set ____meta end=last;
    file xllabels notab;
    if varnum<=&ncols then do;
      put label @@;
      if not last then put &tab @@;
      end;
  run;


  %* We proceed to define the DDE link to the section of the spreadsheet      *;
  %* where the actual data will be written:                                   *;
  filename xlsheet dde "excel|&savepath.\[&savename..xls]&sheet!r&ulrowdat.c&ulcoldat.:r&lrrowdat.c&lrcoldat." notab lrecl=&lrecl;


  %* From ____META, we generate a list &VARS of variable names, separated by  *;
  %* blanks:                                                                  *;
  proc sql noprint;
    select distinct 
      name
    into
      :vars separated by ' '
    from 
      ____meta
    order by
      varnum
    ;
  quit;


  %* And then we actually write the data...                                   *;
  data _null_;
    set &libin..&dsin(obs=&nrows);
    file xlsheet notab;
     put
                            %let i=1;
                            %do %while(%length(%scan(&vars,&i))>0);
       %scan(&vars,&i) &tab
                              %let i=%eval(&i+1);
                              %end;
       ; 
     
  run;
   
  %* If the &STDFMTNG flag is on, we apply some standard formatting to the    *;
  %* inserted range...                                                        *;
  %if ("&stdfmtng" eq "1") %then %do;

    %* First select all and set the font to Courier 10pt.                     *;
    %* Then select the row of labels, and turn them bold.                     *;
    %* Then select the column-range, and apply best fit column width.         *;
    %* Finally, do a freeze panes to keep the labels visible while scrolling. *;
    data _null_;
      length
        ddecmd $ 200
        ;
      file sas2xl;
      put '[error(false)]';
      ddecmd='[workbook.activate("'||"&sheet"||'",false)]';
      put ddecmd;
      ddecmd='[select("r'||"&ulrowlab"||'c'||"&ulcollab"||':r'||"&lrrowdat"||'c'||"&lrcoldat"||'")]';
      put ddecmd;
      put '[format.font("'|| "&xlsfont" || '",10,false,false,false,false,0,false,false)]';
      ddecmd='[select("r'||"&ulrowlab"||'c'||"&ulcollab"||':r'||"&lrrowlab"||'c'||"&lrcollab"||'")]';
      put ddecmd;      
      ddecmd='[format.font("'|| "&xlsfont" || '",10,true,false,false,false,0,false,false)]';      
      put ddecmd;
      *ddecmd='[column.width(0,"c'||"&ulcollab"||':c'||"&ncols"||'",false,3)]';
      ddecmd='[column.width(1,"c'||"&ulcollab"||':c'||"&lrcollab"||'",false,3)]';
      put ddecmd;
      /* Center Justify Headings and Wrap Text */  
	  *ddecmd = '[select("r1c1:r1c2")]';
	  put '[select("r1c1:r1c2")]';
      *ddecmd='[Alignment(2,False,2,0)]';
      put '[Alignment(2,False,2,0)]';
      *ddecmd='[select("r1c3:r1c7")]';
      put '[select("r1c3:r1c7")]';   
	  *ddecmd='[Alignment(4,False,2,0)]';
      put '[Alignment(4,False,2,0)]';
        
     run;  

    %end;

    
  %* We save the document once more with its intended name and close it. Oh,  *;
  %* and while at it, we discard the temporary Macro1-sheet.                  *;
  data _null_;
    length
      ddecmd $ 200
      ;
    file sas2xl;
    put '[error(false)]';
    put '[workbook.delete("Macro1")]';
    ddecmd='[save.as("'||"&savepath"||'\'||"&savename"||'")]';
    put ddecmd;
    put '[file.close(false)]';
  run;


  %* Did we get this far? If so, we want to clean up and therefore turn the   *;
  %* READY flag on.                                                           *;
  %let ready=1;


  %* Upon exiting the macro, we restore all the system options that we turned *;
  %* off earlier on...                                                        *;
  %mquit:;


  %if &cnotes %then %do;
    options notes;
    %end;
    
    
  %if &csource %then %do;
    options source;
    %end;
    
    
  %if &csource2 %then %do;
    options source2;
    %end;


  %if &cmlogic %then %do;
    options mlogic;
    %end;


  %if &csymbolg %then %do;
    options symbolgen;
    %end;


  %if &cmprint %then %do;
    options mprint;
    %end;


  %* Check if the macro actually executed some code (READY=1) or if we got    *;
  %* here because of lacking parameter errors (READY=0).                      *;
  %if &ready %then %do;

    options
      nonotes
      ;

    %* Clean up remaining junk in the local SAS session.                      *;
    proc datasets nolist lib=work;
      delete
        ____meta
        _sheet_names / memtype=data;
    quit;

    filename sas2xl clear;
    filename xlmacro clear;

    %if &cnotes %then %do;
      options notes;
      %end;

    %end;


%mend sastoxl; 
