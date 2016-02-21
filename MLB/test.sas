
%macro removem(days);
data dist2;
	set distances;
	%do d=2 %to &days;
		if previously&d~=stadium%eval(&d-1) then do;
			home&d="";
			away&d="";
			stadium&d="";
			distance&d=.;
		end;
	%end;
run;
%mend;
%removem(5);
