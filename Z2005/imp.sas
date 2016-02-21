PROC IMPORT OUT= WORK.inet 
            DATAFILE= "D:\phoneverifinet.xls" 
            DBMS=EXCEL REPLACE;
     SHEET="PHONE_VERIF_01DEC2009_1881$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;
