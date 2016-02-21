

proc template;
	define style styles.nobreak;
		parent=styles.default;
			style body from body /pagebreakhtml=_undef_;
			style table /  borderwidth=0; 
	end;
run;

goptions reset=all hsize=3in vsize=2in;
symbol1 v=dot c=blue h=.5;
symbol2 v=dot c=green h=.5;

ods html style=styles.nobreak;
	proc gplot data=sashelp.class;
		ods layout start columns=2;
			ods region;
			plot height*age;run;
			ods region;
			plot weight*age;run;
		ods layout end;
	quit;
ods html close;
