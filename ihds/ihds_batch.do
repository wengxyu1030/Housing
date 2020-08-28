/* This file is to consolidate the ihds survey and produce the tables */

*****************************
***Consolidate the Surveys***
*****************************

global github "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all/Housing_git/ihds"
global do "${github}"

***run files by survey****
do "${do}/ihds1.do"
do "${do}/ihds2.do"


***set the environment****
global ROOT "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all"
global raw "${ROOT}/raw"
global inter "${ROOT}/inter"
global final "${ROOT}/final"

/*
This file is to:
1. Consolidate the surveys
2. Calculate the indicators
*/

***Specify the Surveys***
global surveys "ihds1 ihds2"

//log using "${final}/output_table_india_6576",replace

*data source
use "${raw}/ihds1.dta", clear	
append using "${raw}/ihds2.dta"

*calculate indicators

*chang unit for percentage unit

*label and order the vars. 

save "${final}/ihds",replace
save "${github}/ihds",replace