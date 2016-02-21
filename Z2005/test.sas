//JAA#JDLN JOB (10108,RFF43,,),'S CROKER- MSAD',CLASS=A,                JOB10714
//         MSGCLASS=X,MSGLEVEL=(1,1),TIME=(,02),NOTIFY=&SYSUID                  
//*                                                                             
//STEP01 EXEC SAS,OPTIONS=FILECC                                                
//*                                                                             
//SYSIN DD *                                                                    
***************************************************;                            
*****  Sam Crokers Generic Test Program       *****;                            
***************************************************;                            
PROC FORMAT;                                                                    
     PICTURE NLZD  (DEFAULT=10)                                                 
     LOW-HIGH='%m-%d-%Y' (DATATYPE=DATE)   ;                                    
RUN;                                                                            
DATA _NULL_;                                                                    
     DO DT='01JAN2009'D TO '01JAN2010'D BY 7;                                   
          put "picture" dt nlzd.;                                               
     END;                                                                       
RUN;                                                                            
