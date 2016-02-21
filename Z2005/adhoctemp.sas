



libname msad db2 database=msad schema=ADHOC user=&user
                 using=&mypw insertbuff=1000 readbuff=1000;


%let  updatedt='2009-10-01';
%let excludestate=
          'AK','AL','AR','AZ','AS','CA','CO','CT','DC','DE'
         ,'FL','GA','GU','HI','IA','ID','IL','IN','KS','KY'
         ,'LA','MA','MD','ME','MI','MN','MO','MP','MS','MT'
         ,'NC','ND','NE','NH','NJ','NM','NV','NY','OH','OK'
         ,'OR','PA','PR','RI','SC','SD','TN','TX','UT','VA'
         ,'VI','VT','WA','WI','WV','WY';

proc sql ;
    connect to db2 (db=msad user=&user using=&mypw schema=ADHOC);



    %let selectstmt =
         select
            distinct
               prv_no
              ,lctn_no
              ,adr_typ
              ,p_l3_adr
              ,p_l4_adr
              ,p_l5_adr
              ,cty_adr
              ,state
              ,zip
              ,case
                   when adr_typ='01' and lctn_no !=0 then 'ls01'
                   when adr_typ='02' and lctn_no  =0 then 'glob02'
                   when adr_typ='02' and lctn_no !=0 then 'ls02'
                   when adr_typ='02' and lctn_no  =0 then 'glob02'
                   when adr_typ='03' and lctn_no !=0 then 'ls03'
                   when adr_typ='03' and lctn_no  =0 then 'glob03'
                   when adr_typ='08' and lctn_no !=0 then 'ls08'
                   when adr_typ='08' and lctn_no  =0 then 'glob08'
               end as adr_group
         from adhoc.t31
         where adr_typ in ('01','02','03','08')
         and update_dt=&updatedt
         and par_trm ='9901-01-01'
         and svs_ind ='N'
         ;
    execute(declare global temporary table session.r140p_t31 as (&selectstmt)
             definition only with replace on commit preserve rows in userbig_temp) by db2;
    execute(insert into session.r140p_t31 &selectstmt) by db2;
    select * into :t31count from connection to db2(select count(*) from session.r140p_t31);


/* now put the t13, t31 and t30 (lso1) information together as the physical addrssses*/

    %let selectstmt =
         select
               e_prv_no
              ,a.lctn_no
              ,a.prv_no
              ,a_nme
              ,tin
              ,tin_typ
              ,c.adr_typ
              ,c.p_l3_adr
              ,c.p_l4_adr
              ,c.p_l5_adr
              ,c.cty_adr
              ,c.state
              ,c.zip
         from (
           select distinct
               e_prv_no
              ,lctn_no
              ,prv_no
           from adhoc.t13
         where e_no_typ='98'
           and sts_cd='A'
           and void_ind='N'
           and rec_trm ='9901-01-01'
           and update_dt=&updatedt
         ) a
         left join (
           select prv_no,a_nme,tin,tin_typ from adhoc.t30
              where
                  update_dt = &updatedt
              and p_rc_trm  = '9901-01-01'
              and svs_ind   = 'N'
         ) b
         on a.prv_no=b.prv_no
         left join
           (select * from session.r140p_t31 where adr_group='ls01') c
              on a.prv_no=c.prv_no
              and a.lctn_no=c.lctn_no
         ;
    execute(declare global temporary table session.r140p_physical as (&selectstmt)
             definition only with replace on commit preserve rows in userbig_temp) by db2;
    execute(insert into session.r140p_physical &selectstmt) by db2;
    select * into :physicalcount from connection to db2(select count(*) from session.r140p_physical);


    %let selectstmt =
         select
               a.*
              ,b.newadd
         from
              session.r140p_physical a
              inner join
              (select
                prv_no
               ,lctn_no
               ,trim(p_l3_adr)||' '||
                trim(p_l4_adr)||' '||
                trim(p_l5_adr)||' '||
                trim(cty_adr) ||' '||
                trim(state)   ||' '||
                trim(zip)            as newadd
                 from session.r140p_t31
                 where adr_group in('ls02','ls03')
                   AND state  NOT in(&excludestate)
               ) b
              on a.prv_no=b.prv_no and a.lctn_no=b.lctn_no;

    execute(declare global temporary table session.r140p_group1 as (&selectstmt)
             definition only with replace on commit preserve rows in userbig_temp) by db2;

    execute(insert into session.r140p_group1 &selectstmt) by db2;

    select * into :Group1 from connection to db2(select count(*) from session.r140p_group1);


    %let selectstmt =
         select
               a.*
              ,b.newadd
         from
              session.r140p_physical a
              inner join
              (select
                prv_no
               ,lctn_no
               ,trim(p_l3_adr)||' '||
                trim(p_l4_adr)||' '||
                trim(p_l5_adr)||' '||
                trim(cty_adr) ||' '||
                trim(state)   ||' '||
                trim(zip)            as newadd
                 from session.r140p_t31
                 where adr_group ='glob02'
                   AND state not in(&excludestate)
               ) b
              on a.prv_no=b.prv_no and a.lctn_no=b.lctn_no;

    execute(declare global temporary table session.r140p_group2 as (&selectstmt)
             definition only
             with replace
             on commit preserve rows
             in userbig_temp) by db2;

    execute(insert into session.r140p_group2 &selectstmt) by db2;

    select * into :group2 from connection to db2(select count(*) from session.r140p_group2);


    %let selectstmt =
         select distinct tin,tin_typ,cty_adr,state,po_box,zip,forgnadd
         from adhoc.t62
         where
             update_dt=&updatedt
         and rec_trm ='9901-01-01'
         and svs_ind ='N'
         AND state  NOT in(&excludestate)
         ;

    execute(declare global temporary table session.r140p_t62 as (&selectstmt)
             definition only
             with replace
             on commit preserve rows in userbig_temp) by db2;

    execute(insert into session.r140p_t62 &selectstmt) by db2;
    title T62 Address Info;
    select * into :t62count from connection to db2(select count(*) from session.r140p_t62);



    %let selectstmt =
         select
              a.*
             ,b.cty_adr as cty_adr62
             ,b.state   as state62
             ,b.po_box  as po_box62
             ,b.zip     as zip62
             ,b.forgnadd as forgnadd62
         from
             session.r140p_physical a
             inner join
             session.r140p_t62   b
             on a.tin=b.tin and a.tin_typ=b.tin_typ;

    execute(declare global temporary table session.r140p_group3 as (&selectstmt)
             definition only with replace on commit preserve rows in userbig_temp) by db2;

    execute(insert into session.r140p_group3 &selectstmt) by db2;

    select * into :group3 from connection to db2(select count(*) from session.r140p_group3);


    select * into :ls01 from connection to db2(select count(*) from session.r140p_t31 where adr_group='ls01');
    select * into :ls02 from connection to db2(select count(*) from session.r140p_t31 where adr_group='ls02'
             and state NOT in(&excludestate));
    select * into :glob02 from connection to db2(select count(*) from session.r140p_t31 where adr_group='glob02'
             and state NOT in(&excludestate));
    select * into :ls03 from connection to db2(select count(*) from session.r140p_t31 where adr_group='ls03'
             and state NOT in(&excludestate));
    select * into :glob03 from connection to db2(select count(*) from session.r140p_t31 where adr_group='glob03'
             and state NOT in(&excludestate));

    select * into :ls08 from connection to db2(select count(*) from session.r140p_t31 where adr_group='ls08'
             and state NOT in(&excludestate));
    select * into :glob08 from connection to db2(select count(*) from session.r140p_t31 where adr_group='glob08'
             and state NOT in(&excludestate));
    disconnect from db2;
quit;



options nosource;
%put NOTE: &t31count rows in the T31 extract;
%put NOTE: &physicalcount rows in the Physical Address extract;
%put NOTE: &t62count rows selected in the T62 Extract;
%put NOTE: &ls01 in lso1;
%put NOTE: &ls02 in lso2;
%put NOTE: &glob02 in glob02;
%put NOTE: &ls03 in lso3;
%put NOTE: &glob03 in glob03;
%put NOTE: &ls08 in lso8;
%put NOTE: &glob08 in glob08;
%put NOTE: &group1 rows selected in the Physical Address inner Joined with the Location Specifics;
%put NOTE: &group2 rows selected in the Physical Address inner Joined with the Globals;
%put NOTE: &group3 rows selected in the Physical Address inner Joined with the T62 Data;
options source;
