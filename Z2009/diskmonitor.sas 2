


libname core '/sas/adminscripts/data';
filename dfg pipe "df -g";

/* look at the overall file system usage */
data diskutil;
    length
         reportdate 8
         filesystem $50
         gbblocks free pctused iused pctiused 8
         mount $50
    ;
    informat
         pctused pctiused percent5.;
    format
         pctiused percent5. reportdate datetime 28.;

    infile dfg firstobs=2 missover;
    input filesystem  $ gbblocks ??  free ?? pctused ?? iused ?? pctiused ??  mount $;
    reportdate=datetime();
    if scan(mount,1)='sas' or scan(mount,1)='home';
run;
/*data core.diskutil; set diskutil; run; */
proc append base=core.diskutil data=diskutil; run;
