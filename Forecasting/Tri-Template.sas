



%let max=90;
%let seg2=%sysevalf(&max/1.62);
%let seg1=%sysevalf(&max-&seg2);

proc greplay tc=tempcat nofs;
	%let linecolor=BLACK;
	tdef qpanel des='eight rectangles'
		1/	ULX=&seg1	ULY=&max	URX=&max	URY=&max
			LLX=&seg1	LLY=&seg1	LRX=&max	LRY=&seg1
			COLOR=&linecolor
		2/	ULX=0	ULY=&seg2	URX=&seg1	URY=&max
			LLX=0	LLY=0	LRX=&seg1	LRY=&seg1
			COLOR=&linecolor
		3/	ULX=&seg1	ULY=&seg1	URX=&max	URY=&seg1
			LLX=0	LLY=0	LRX=&seg2	LRY=0
			COLOR=&linecolor
	;
	template qpanel;
	preview qpanel;
run;
quit;

