/**********************************************************************
*	Program Name	:	$RCSfile: ArimaSimulator.sas,v $
*	REV/REV AUTH	:	$Revision: 1.1 $ $Author: scoyote $
*	REV DATE		:	$Date: 2007/05/31 20:34:20 $
* 
*   CREATOR:   SAMUEL T. CROKER
*   DATE:      24 May 2007
*   DESC:      ARIMA Simulator
***********************************************************************/ 
/* one working parameterization for testing is ARIMA((1)(2)(7),1,1)
	array mu{2} 			_temporary_ (1,20);
	array phi{2,7}		_temporary_ ((-0.25,0,0,0,0,0,0)
 							  	  ,(0.25,0.15,0,0,0,0,0.05));
	array theta{2,7} 		_temporary_ ((-0.75,0,0,0,0,0,0)
								  ,(-0.85,0,0,0,0,0,0));

	array coeff{2}		_temporary_ (-1.5,3);
*/	

/* the following are the regression terms that are added to the mix */



data arimasim;
	array demand{1000} 		_temporary_;
	array price{1000} 		_temporary_;
	array e1{1000}			_temporary_;
	array e2{1000}			_temporary_;
	/* these 2d arrays are constructed as follows:
			(price term elements, demand term elements) */
	/* at this time, only one differencing component can be selected */
	array diff{2}			_temporary_ (1,7); /* 1=on/0=off, differencing order) */ 
	array mu{2} 			_temporary_ (1,20);
	array phi{2,7}			_temporary_ ((0,0,0,0,0,0,0)
								  ,(0,0,0,0,0,0,0));
	array theta{2,7} 		_temporary_ ((0,0,0,0,0,0,0)
								  ,(0,0,0,0,0,0,0));
	array coeff{2}			_temporary_ (-1.5,3);

	/* random iid shocks */
	do i=1 to 1000;
		e1{i} = rannor( 33165 ); 
		e2{i} = rannor( 54321 ); 
	end;

	do t=1 to 1000;
		/*   burn in period necessary for differencing.  The 50 is 
			just a number bigger than the differencing will require.*/
		if t<50 then do;
			demand{t}=e1{t};
			price{t}=e2{t};
		end;
		/* actual time series */
		else do;
			price{t}=
				mu{1}
				+ phi{1,1}*price{t-1}
				+ theta(1,1)*e2{t-1}
				+ e2{t};
			demand{t}=
				mu{2} 
				/* differencing terms */
				+ diff{1}*demand{t-diff{2}} 				
				/* autoregressive terms */	
				+ phi{2,1}*(demand{t-1}-demand{t-2}) 
				+ phi{2,2}*(demand{t-2}-demand{t-3}) 
				+ phi{2,3}*(demand{t-3}-demand{t-4}) 
				+ phi{2,4}*(demand{t-4}-demand{t-5}) 
				+ phi{2,5}*(demand{t-5}-demand{t-6}) 
				+ phi{2,6}*(demand{t-6}-demand{t-7}) 
				+ phi{2,7}*(demand{t-7}-demand{t-8}) 
				/* moving average terms */
				- theta{2,1}*e1{t-1}
				- theta{2,2}*e1{t-2}
				- theta{2,3}*e1{t-3}
				- theta{2,4}*e1{t-4}
				- theta{2,5}*e1{t-5}
				- theta{2,6}*e1{t-6}
				- theta{2,7}*e1{t-7}
				/* regression components */
				+&regressionterm
				/* noise */
				+ e1{t};
		end;
	end;
	/* output the burnt-in values only */
	do t=100 to 1000;
		dmd=demand{t};
		rat=price{t};
		time+1;
		output;
	end;
run;

title Checking the Estimates for the Crosscorrelated Series;
ods select ParameterEstimates;
proc arima data=arimasim;
	identify var=rat scan esacf minic;
	estimate  method=ml;
	identify var=dmd(7) cross=rat scan esacf minic;
	estimate input=(rat)   method=ml;
run;
title;
