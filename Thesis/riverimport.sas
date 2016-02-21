PROC IMPORT OUT= BM.ALSTON 
            DATAFILE= "C:\Documents and Settings\Samuel  Croker\Desktop\
Thesis\Broad_alston_02161000.txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
