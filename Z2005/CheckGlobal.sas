


libname compit '/abiwork/r140p';
libname  j1a
         db2
         database=j1a
         schema=ADHOC
         user=&user
         using=&mypw
         insertbuff=1000     /* no single row inserts or reads... */
         readbuff=1000;

libname  pga
         db2
         database=pga
         schema=ADHOC
         user=&user
         using=&mypw
         insertbuff=1000     /* no single row inserts or reads... */
         readbuff=1000;

proc sql;
    connect to db2(db=j1b user=&user using=&mypw schema=ADHOC);
         create table compit.desc_betos as
              ( select * from pga.descbetos);
    disconnect from db2;
quit;

proc sql;
    connect to db2(db=j1b user=&user using=&mypw schema=ADHOC);
    create table compit.rank_betos as
         select  a.*
                ,b.betosdesc as betos_description
           from connection to db2
         (
              select state_cd  as region
                   , betos_cd  as betos_code
                   , hicn_dcnt as beneficiaries
                   , clm_dcnt  as claims
                   , paid_prov_tot as reimbursement
                   , allow_amt_tot as allowed_charge
                   , allow_serv_tot as allowed_services
                   , rank() over( partition by state_cd order by allow_amt_tot desc) as betos_rank
              from adhoc.j1b_global_betos_by_region
              where state_cd in ('CN','CS','NI')
          ) as a
          left join compit.desc_betos b
            on a.betos_code = b.betos
          where betos_rank <=10
          order by  region
                   ,betos_rank
    ;
    disconnect from db2;
quit;

proc sql;
    connect to db2(db=j1b user=&user using=&mypw schema=ADHOC);
    create table compit.rankspec_betos as
         select
              a.region
             ,a.betos_code
             ,a.betos_rank
             ,a.betos_description
             ,b.rendering_provider_specialty
             ,b.spec_description
             ,b.spec_rank
             ,b.beneficiaries
             ,b.claims
             ,b.prov_reim
             ,b.allowed_charge
             ,b.allowed_services
           from connection to db2
         (
              select
                     state_cd as region
                   , betos_cd as betos_code
                   , rendering_prov_spec  as rendering_provider_specialty
                   , b.specdesc           spec_description
                   , hicn_dcnt as beneficiaries
                   , clm_dcnt  as claims
                   , paid_prov_tot as prov_reim
                   , allow_amt_tot as allowed_charge
                   , allow_serv_tot as allowed_services
                   , rank() over(partition by state_cd, betos_cd
                                 order by allow_amt_tot desc) as spec_rank
              from adhoc.j1b_global_betosspec_by_region a
              left join
                   adhoc.descspec b
              on a.rendering_prov_spec=b.specialty
              where state_cd in ('CN','CS','NI')
          ) as b
          inner join
          compit.rank_betos a
          on     a.region=b.region
             and a.betos_code=b.betos_code

          where
             spec_rank <= 10
          order by
                   region
                  ,betos_code
                  ,spec_rank
;
    disconnect from db2;
quit;



proc sql;
    connect to db2(db=j1b user=&user using=&mypw schema=ADHOC);
    create table compit.rankspecproc_betos as
         select
              a.region
             ,a.betos_code
             ,a.betos_rank
             ,a.betos_description
             ,a.rendering_provider_specialty
             ,a.spec_description
             ,a.spec_rank
             ,b.procedure_code
             ,b.proc_description
             ,b.beneficiaries
             ,b.claims
             ,b.prov_reim
             ,b.allowed_charge
             ,b.allowed_services
             ,b.proc_rank
           from connection to db2
         (
              select
                     state_cd                 as region
                   , betos_cd                 as betos_code
                   , rendering_prov_spec      as rendering_provider_specialty
                   , hcpcs_cd                 as procedure_code
                   , b.hcpcsdesc              as proc_description
                   , hicn_dcnt as beneficiaries
                   , clm_dcnt  as claims
                   , allow_amt_tot
                   , paid_prov_tot as prov_reim
                   , allow_amt_tot as allowed_charge
                   , allow_serv_tot as allowed_services
                   , rank() over(partition by state_cd, betos_cd, rendering_prov_spec
                                 order by allow_amt_tot desc) as proc_rank
              from adhoc.j1b_global_betosspecprocr a
              left join adhoc.deschcpcs b
                   on a.hcpcs_cd=b.hcpcs

              where state_cd in ('CN','CS','NI')

          ) as b
          inner join
          compit.rankspec_betos a
          on     a.region=b.region
             and a.betos_code=b.betos_code
             and a.rendering_provider_specialty = b.rendering_provider_specialty
          where
             proc_rank <= 10
          order by
                   region
                  ,betos_code
                  ,betos_rank
                  ,rendering_provider_specialty
                  ,spec_rank
                  ,proc_rank
;
    disconnect from db2;
quit;

filename cport1 '/abiwork/r140p/rank_betos.xpt';
proc cport  data=compit.rank_betos file=cport1; run;

filename cport1 '/abiwork/r140p/rankspec_betos.xpt';
proc cport  data=compit.rankspec_betos file=cport1; run;

filename cport1 '/abiwork/r140p/rankspecproc_betos.xpt';
proc cport  data=compit.rankspecproc_betos file=cport1; run;



/*

proc sql;
    connect to db2(db=j1b user=&user using=&mypw schema=ADHOC);
    select * from connection to db2 (
         select * from adhoc.j1b_global_betosspec_by_region
             where rendering_prov_spec = 'NULL'
              and state_cd='CS' and betos_cd='T1G'
    );
    disconnect from db2;
quit;

*/
