






libname  msad
         db2
         database=msad
         schema=ADHOC
         user=&user
         using=&mypw
         insertbuff=1000     /* no single row inserts or reads... */
         readbuff=1000;

proc surveyselect
          data=msad.desc_nsc_provider
          method=srs
          n=5
          out=sample_prov;
     where as_date='02nov2009'd;
run;


proc surveyselect
          data=msad.desc_nsc_owner
          method=srs
          n=5
          out=sample_owner;
     where as_date='02nov2009'd;
run;



proc surveyselect
          data=msad.desc_nsc_specialty
          method=srs
          n=5
          out=sample_specialty;
     where as_date='02nov2009'd;
run;







proc template;
   define style Styles.Samsprint;
      parent = styles.Printer;
      replace fonts /
         'TitleFont2' = ("Arial, Helvetica",8pt,Bold)
         'TitleFont' = ("Arial, Helvetica",8pt,Bold)
         'StrongFont' = ("ITC Bookman, Times Roman",6pt,Bold)
         'EmphasisFont' = ("ITC Bookman, Times Roman",6pt,Italic)
         'FixedEmphasisFont' = ("Courier New",6pt,Italic)
         'FixedStrongFont' = ("Courier New",6pt,Bold)
         'FixedHeadingFont' = ("Courier New",6pt,Bold)
         'BatchFixedFont' = ("SAS Monospace, Courier",6pt)
         'FixedFont' = ("Courier New",6pt)
         'headingEmphasisFont' = ("ITC Bookman, Times Roman",8pt,Bold Italic)

         'headingFont' = ("ITC Bookman, Times Roman",8pt,Bold)
         'docFont' = ("ITC Bookman, Times Roman",8pt);
      style Table from output/
         background = _undef_
         frame = box
		 rules = all
         cellpadding = 4pt
         cellspacing = 0.75pt
         borderwidth = 0.75pt;
      replace HeadersAndFooters from Cell /
         font = fonts('FixedStrongFont')
		 just = l
		;
	  replace RowHeader from Cell /
         font = fonts('FixedFont')
 		;
	  replace data from cell /
         font = fonts('FixedFont');
    end;
run;


options orientation=landscape;
ods pdf
     file='/abiwork/nscdata/Nov2009/samples.pdf'
    style=styles.samsprint
;

title Providers;
proc print data=sample_prov; run;
title Owners;
proc print data=sample_owner; run;
title Specialties;
proc print data=sample_specialty; run;
title;
ods pdf close;
