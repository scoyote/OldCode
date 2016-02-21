data a;
	input sts $;

datalines ;
a
s
a
a
d
a
s
s
d
d
d
e
d
;

run;	

data b;
	set a end = eof;
	ARRAY STC1(26) $1 _temporary_;
	ARRAY STC2(26) 8  _temporary_;
	link search;
	if eof then do;
		do i=1 to indexmax;
			put stc1(i)= stc2(i)=;
		end;
	end;
	return;
search:
	found=0;
	do i=1 to indexmax;
		if sts = stc1(i) then do;
			stc2(i)+1;
			found=1;
		end;
	end;
	if found=0 then do;
		indexmax+1;
		stc1(indexmax)=sts;
		stc2(indexmax)=1;
	end;
return;
run;
