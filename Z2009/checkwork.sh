#!/usr/bin/ksh
/sas/sas92/SASFoundation/9.2/sas /sas/adminscripts/CheckWork.sas
#mailx -s 'Work Report' -r sam.croker@astrazeneca.com sam.croker@astrazeneca.com< /sas/adminscripts/CheckWork.out
