log using "${final}/output_nss76",replace

**********************************
***NSS76 for housing condition****
**********************************

//This file is to produce the statistics.

global ROOT "C:/Users/wb500886/OneDrive - WBG/7_Housing/NSS76_Housing_new/analysis"
global raw "${ROOT}/raw"
global dct "${ROOT}/raw/dct"
global inter "${ROOT}/inter"
global final "${ROOT}/final"

****************************
*****set as survey data*****
****************************

/* 
based on the data consolidated using 
"C:\Users\wb500886\OneDrive - WBG\7_Housing\NSS76_Housing_new\analysis\dofile\nss76.do" 
*/

use "${final}/nss76",clear
svyset id [pw = hh_weight]

******************************
*****rural: TN vs. non-TN*****
******************************

***compare means***

/*indicators in order:
Housing quality:
1.	cost
2.	living facility
3.	location
4.	micro environment
5.	ownership
6.	overcrowding
7.	physical structure
Household feature:
8.  welfare
*/

#delimit ;
global var_q "

hq_water_cost 
hq_water_rate
hq_san_cost 
hq_san_rate
hq_rent_cost
hq_rent_rate

hq_water 
hq_water_su
hq_water_in
hq_san
hq_san_in

hq_nslum
hq_travel_m
hq_travel_f 
hq_travel_t

hq_nflood
hq_path

hq_tenure_se 
hq_own

hq_floor_n 
hq_crowd_n
hq_floor_a
hq_crowd_a
hq_married_sep

hq_level
hq_floor_n
hq_resid
hq_period
hq_str_good
hq_elec
hq_drainage
hq_dwell_indi
hq_room
hq_floor_a
hq_ventilation
hq_kitchen
hq_pfloor
hq_pwall
hq_proof

hh_land
hh_umce
"
;
#delimit cr

foreach var in $var_q {
svy,subpop(if hh_urban != 1) over(hh_tn): mean `var'
lincom [`var']TN - [`var']_subpop_1 
}

***compare distribution among umce (dummy and continuous)***
twoway kdensity hh_umce_ln if hh_tn == 1 & hq_own == 1 & hh_urban == 0|| ///
kdensity hh_umce_ln if hh_tn == 1  & hq_own == 0 & hh_urban == 0, ///
legend(label(1 "hq_own == 1") label(2 "hq_own == 0"))

//need to compare with other similar state instead of overall non-TN states?
reg hq_floor_a c.hh_umce_ln#i.hh_tn hh_umce_ln hh_size if hh_urban == 0,absorb(hh_state) cluster(hh_state)
reg hq_own c.hh_umce_ln#i.hh_tn hh_umce_ln hh_size if hh_urban == 0,absorb(hh_state) cluster(hh_state)

******************************
*****urban: TN vs. non-TN***** 
******************************

#delimit ;
global var_slum "
hq_nslum 
hq_slum_doc 
hq_slum_be
"
;
#delimit cr

foreach var in $var_q {
svy,subpop(if hh_urban != 1) over(hh_tn): mean `var'
lincom  [`var']TN - [`var']_subpop_1 
}

foreach var in $var_slum {
svy, over(hh_tn): mean `var'
lincom [`var']TN - [`var']_subpop_1 
}

//need to compare with other similar state instead of overall non-TN states?
reg hq_floor_a c.hh_umce_ln#i.hh_tn hh_umce_ln hh_size if hh_urban == 1,absorb(hh_state) cluster(hh_state)
reg hq_own c.hh_umce_ln#i.hh_tn hh_umce_ln hh_size if hh_urban == 1,absorb(hh_state) cluster(hh_state)

log close
