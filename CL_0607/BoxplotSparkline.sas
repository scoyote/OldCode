/*******************************************************************************
*       Program Name    :       $RCSfile: BoxplotSparkline.sas,v $
*       REV/REV AUTH    :       $Revision: 1.1 $ $Author: scoyote $
*       REV DATE        :       $Date: 2007/07/13 18:15:20 $
********************************************************************************/
%macro boxsparkline(prop,varprefix);

	data ish_anno;
		set ishstats;
		where prop_code="&prop" ;
		by prop_code;
	   xsys='2'; ysys='3'; when='a'; 
	   length function color $8 style $20;
	   midpoint=prop_code;
	   size=1;  style='solid'; line=0;
	   
	   /* draw the outer box */ 
		color="bwh";
	   function='move'; x=&varprefix.l; function='move'; y=ifn(dataset="COMP",20,70); output;
	   function='bar';  x=&varprefix.h; y=ifn(dataset="COMP",30,80);  output;
	  
	 /* draw the inner box */
	   function='move'; x=&varprefix.1; y= ifn(dataset="COMP",5,55); output;
	   function='bar';  x=&varprefix.3; y=ifn(dataset="COMP",45,95); output;

	   /* Median Line (median is &varprefix.M, mean is &varprefix.X) */
	   color="white";
	   function='move'; x=&varprefix.M; y=ifn(dataset="COMP",0,50);  output;
	   function='bar'; x=&varprefix.M; y=ifn(dataset="COMP",50,100);  output;
	   /* Mean point*/
	   color="grey";
	   function='symbol';size=5;style='MARKER';text="P";position='5'; x=&varprefix.X; y=ifn(dataset="COMP",25,75);  output;
	   /* Zero Reference Line */
	   if last.prop_code then do;
		   color="grey";
		   size=1;
		   function='move'; x=0; y=0;  output;
		   function='bar'; x=0; y=100;  output;
		end;
	run;
	data labelanno;
	   xsys='3'; ysys='3'; 
	   length function color $8 style $20;
	   color="black";
	   function='label';size=30;style='swissb';text="&prop"; position='F'; x=0;  y=60;  output;
	run;

	data labelanno2;
	   xsys='3'; ysys='3'; 
	   length function color $8 style $20;
	   color="black";
	   function='label';size=10;style='swissb';text="COMP"; position='4'; x=0;  y=30;  output;
	   function='label';size=10;style='swissb';text="ORIG"; position='4'; x=0;  y=80;  output;
	run;

	title;
	footnote;
	proc catalog catalog=gseg kill; run;
	goptions reset=all device=win fontres=presentation xpixels=800 ypixels=100 nodisplay; 
	 ;
	proc ganno 
			anno=ish_anno
			name='boxplot'
	          gout=gseg
	          description="&prop" 
			datasys;
	run;
	goptions reset=all device=win fontres=presentation xpixels=150 ypixels=100  nodisplay; 
	proc ganno 
			anno=labelanno
			name="label"
	          gout=gseg
	          description="&prop" 
			;
	run;
	goptions reset=all device=win fontres=presentation xpixels=50 ypixels=100  nodisplay;   
	proc ganno 
			anno=labelanno2
			name="label2"
	          gout=gseg
	          description="&prop" 
			;
	run;

	proc greplay tc=work.tempcat nofs;

	tdef newtemp des='Three panel template'

	     1/llx=0   lly=0
	       ulx=0   uly=100
	       urx=15  ury=100
	       lrx=15  lry=0
		
		2/llx=15   lly=0
	       ulx=15   uly=100
	       urx=95 	 ury=100
	       lrx=95   lry=0
		
		3/llx=95  lly=0
	       ulx=95   uly=100
	       urx=100 ury=100
	       lrx=100  lry=0;
		
	   template newtemp;
	   list template;
	quit;

	goptions reset=all device=win xpixels=250 ypixels=25; * xpixels=400 ypixels=25; 
	ods html gpath='/ty/stcroker/output/sparklines/'(url=none) body="/ty/stcroker/output/sparklines/&prop..htm";
	proc greplay igout=work.gseg gout=work.gseg
	             tc=work.tempcat nofs;
	   template=newtemp;
	   treplay 1:label
	           2:boxplot
	           3:label2
		name="&prop.&varprefix";
	quit;
	ods html close;
%mend boxsparkline;

%boxsparkline(NYCMQ,cape);
/*proc sql noprint;*/

/*	select count(distinct prop_code) into :propnum from ishstats;*/
/*	%let propnum=&propnum;*/
/*	select distinct prop_code into :propn1-:propn&propnum from ishstats;*/
/*quit;*/
/*%macro propspark;*/
/*	%do i=1 %to &propnum;*/
/*		%boxsparkline(&&prop&i);*/


proc catalog catalog=sashelp.fonts; contents; run;quit;