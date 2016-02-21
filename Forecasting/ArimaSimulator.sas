/**********************************************************************
*	Program Name	:	$RCSfile: ArimaSimulator.sas,v $
*	REV/REV AUTH	:	$Revision: 1.1 $ $Author: scoyote $
*	REV DATE		:	$Date: 2007/07/13 18:15:56 $
* 
*   CREATOR:   SAMUEL T. CROKER
*   DATE:      24 May 2007
*   DESC:      ARIMA Simulator
***********************************************************************/ 

data arimasim;
	array y{1000} 		_temporary_;
	array e1{1000}			_temporary_;
	/* these 2d arrays are constructed as follows:
			(price term elements, y term elements) */
	/* at this time, only one differencing component can be selected */
	array diff{2}			_temporary_ (0,1); /* 1=on/0=off, differencing order) */ 
	array mu{1} 			_temporary_ (1);
	array phi{7}			_temporary_ (-0.25,-.12,0,0,0,0,0);
	array theta{7} 		_temporary_ (-0.75,0,0,0,0,0,0);
	
	/* random iid shocks */
	do i=1 to 1000;
		e1{i} = rannor( 33165 ); 
	end;

	do t=1 to 1000;
		/*   burn in period necessary for differencing.  The 50 is 
			just a number bigger than the differencing will require.*/
		if t<50 then do;
			y{t}=e1{t};
		end;
		/* actual time series */
		else do;
			y{t}=
				mu{1} 
				/* differencing terms */
				+ diff{1}*y{t-diff{2}} 				
				/* autoregressive terms */	
				+ phi{1}*(y{t-1}-y{t-2}) 
				+ phi{2}*(y{t-2}-y{t-3}) 
				+ phi{3}*(y{t-3}-y{t-4}) 
				+ phi{4}*(y{t-4}-y{t-5}) 
				+ phi{5}*(y{t-5}-y{t-6}) 
				+ phi{6}*(y{t-6}-y{t-7}) 
				+ phi{7}*(y{t-7}-y{t-8}) 
				/* moving average terms */
				- theta{1}*e1{t-1}
				- theta{2}*e1{t-2}
				- theta{3}*e1{t-3}
				- theta{4}*e1{t-4}
				- theta{5}*e1{t-5}
				- theta{6}*e1{t-6}
				- theta{7}*e1{t-7}
				/* regression components */
				/* noise */
				+ e1{t};
		end;
	end;
	/* output the burnt-in values only */
	do t=100 to 1000;
		time+1;
		yv=y{t};
		output;
	end;
	keep yv time;
run;

title Checking the Estimates for the Crosscorrelated Series;
ods select ParameterEstimates;
proc arima data=arimasim;
	identify var=yv scan esacf minic;
	estimate p=2 q=1	method=ml;
run;
title;

/* build an impulse response function */
data arimasim;


/* maybe run proc model first? */