/**********************************************************************
*	Program Name	:	$RCSfile: Marriott\040Setup\040Remote\040Libraries\040Snippet.sas,v $
*	REV/REV AUTH	:	$Revision: 1.2 $ $Author: scoyote $
*	REV DATE		:	$Date: 2007/07/13 18:15:20 $
* 
*   CREATOR:   SAMUEL T. CROKER
*   DATE:      8 JANUARY 2007
*   DESC:      Establishes a connection to the XXX and provides
*				SAS/CONNECT functionality.
***********************************************************************/ 
** START PROCESSING ON THE SERVER SIDE **;

libname RMWORKL clear;
options comamid=TCP remote=XXXX;
signon 'C:\Program Files\SAS\SAS 9.1\connect\saslink\tcpunix.scr' ;
*establish remote libraries;
RSUBMIT;
   LIBNAME RMWORK “/XX/stcroker/output";
ENDRSUBMIT;
*Connect the remote library to the local machine;
libname RMWORKL  slibref=rmwork 	server=XXXX;

proc catalog catalog= scgseg.gseg kill; run;
proc fontreg;
	fontpath 'c:\windows\fonts';
run;

%macro boxsparkline(prop,varprefix);
options;
	data ish_anno;
		set rmworkl.ishstats;
		where prop_code="&prop" ;
		by prop_code;
	   xsys='2'; 
		ysys='3'; 
		when='a'; 
	   length function color $8 style $20;
	   midpoint=prop_code;
	   size=1;  
		style='solid'; 
		line=0;
	   	   /* Zero Reference Line */
	   if first.prop_code then do;
		   color="lib";
		   size=1;
		   function='move'; x=0; y=0;  output;
		   function='bar'; x=0; y=100;  output;
		end;	  
	   /* draw the outer box */ 
		color="ligr";
	   function='move'; x=&varprefix.l; function='move'; y=ifn(dataset="COMP",20,70); output;
	   function='bar';  x=&varprefix.h; y=ifn(dataset="COMP",30,80);  output;
	  
	 /* draw the inner box */
	   function='move'; x=&varprefix.1; y= ifn(dataset="COMP",7,58); output;
	   function='bar';  x=&varprefix.3; y=ifn(dataset="COMP",42,93); output;

	   /* Median Line (median is &varprefix.M, mean is &varprefix.X) */
	   color="white";
	   function='move'; x=&varprefix.M; y=ifn(dataset="COMP",0,50);  output;
	   function='bar'; x=&varprefix.M; y=ifn(dataset="COMP",50,100);  output;


		/* Mean point*/
		   color="green";
		   function='move'; x=&varprefix.X; y=ifn(dataset="COMP",17,68);  output;
		   function='bar'; x=&varprefix.X; y=ifn(dataset="COMP",32,83);  output;
	run;
	%let annosys=4;
	data labelanno;
	   xsys="&annosys"; ysys="&annosys"; 
	   length function color $8 style $20;
	   color="gray";
	   function='label';size=30;text="&prop"; position='C'; x=0;  y=3.5;  output;
	run;

	data labelanno2;
	   xsys="&annosys"; ysys="&annosys"; 
	   length function color $8 style $20;
	   color="black";
	   function='label';size=10;text="COMP"; position='C'; x=0;  y=5;  output;
	   function='label';size=10;text="ORIG"; position='C'; x=0;  y=17;  output;
	run;

	title;
	footnote;
	proc catalog catalog=gseg kill; run;
	goptions reset=all device=png nodisplay ; 
	 ;
	proc ganno 
			anno=ish_anno
			name="%cmpres(&prop.%substr(&varprefix,1,3))"
	          gout=gseg
	          description="Boxplot Sparkline for &prop statistic=&varprefix" 
			datasys;
	run;
	goptions reset=all ftext='Arial '   device=png fontres=presentation  nodisplay; 
	proc ganno 
			anno=labelanno
			name="label"
	          gout=gseg
	          description="&prop" 
			;
	run;
	goptions reset=all  ftext='Arial Narrow'  device=png fontres=presentation nodisplay ;   
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
	       urx=10 ury=100
	       lrx=10  lry=0
		
		2/llx=12   lly=0
	       ulx=12   uly=100
	       urx=95 	 ury=100
	       lrx=95   lry=0
		
		3/llx=95  lly=0
	       ulx=95   uly=100
	       urx=100 ury=100
	       lrx=100  lry=0;
		
	   template newtemp;
	   list template;
	quit;

	goptions reset=all device=png xpixels=1000 ypixels=50; 
	libname scgseg 'C:\Documents and Settings\scrok586\Desktop\Output\sparklines\';
	ods html gpath='C:\Documents and Settings\scrok586\Desktop\Output\sparklines\'(url=none)
			body="C:\Documents and Settings\scrok586\Desktop\Output\sparklines\&prop..htm";
	proc greplay igout=work.gseg 
				gout=scgseg.gseg
	               tc=work.tempcat nofs;
	   template=newtemp;
	   treplay 1:label
	           2:%cmpres(&prop.%substr(&varprefix,1,3))
	           3:label2
		name="&prop.&varprefix";
	quit;
	ods html close;
%mend boxsparkline;

/*%boxsparkline(NYCMQ,err);*/


%macro propspark(sparktype);
	proc sql noprint;
		select count(distinct prop_code) into :propnum from rmworkl.ishstats 	
/*			where prop_code in ('NYCXX’,’DTWXX’,’PDXXX’,’PHXXX’,’SANXX’,’WASXX’,’WASXX','MCOXX’,’CHIXX’)*/
		;
		%let propnum=&propnum;
		select distinct prop_code into :propn1-:propn&propnum from rmworkl.ishstats
/*			where prop_code in ('NYCXX’,’DTWXX’,’PDXXX’,’PHXXX’,’SANXX’,’WASXX’,’WASXX’,’MCOXX’,’CHIXX’)*/
		;
	quit;

	%do i=1 %to &propnum;
	%put &&propn&i;
		%boxsparkline(&&propn&i,&sparktype);
	%end;
%mend propspark;
%propspark(sape);

/*proc catalog catalog=scgseg.gseg; contents; run;*/

