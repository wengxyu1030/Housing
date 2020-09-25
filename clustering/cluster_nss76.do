****************************************************************************
* Description: Generate clusters for housing condition using nss76
* Date: September 2, 2020
* Version 1.0
* Last Editor: Aline
****************************************************************************


global ROOT "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all/Housing_git/nss"
global root_survey "C:/Users/wb500886/OneDrive - WBG/7_Housing/survey_all/nss_data/NSS76"

global raw "${root_survey}/raw"
global dct "${raw}/dct"
global inter "${root_survey}/inter"
global final "${root_survey}/final"

****************************************************************************
*clean and prepare data
****************************************************************************

use "${final}/nss76",clear

*add state_iso and the udrbanization rate
do "${ROOT}/MASTER_NSS/do/01_Add State Names to Housing NSS Rounds v2.do"
merge m:1 hh_state using "${ROOT}/MASTER_NSS/final/state_code.dta"
drop if _merge == 2
drop _merge
rename isocode state_iso

merge m:1 state_iso using "${ROOT}/MASTER_NSS/nss_hse_own_93_18.dta"
drop if _merge == 2
drop _merge
drop n_18_own_r n_18_own_u n_18_own n_12_own_r n_12_own_u n_12_own n_12_urban n_08_own_r n_08_own_u n_08_own n_08_urban n_02_own_r n_02_own_u n_02_own n_02_urban n_93_own_r n_93_own_u n_93_own n_93_urban

    gen urbniz = (n_18_urban >= 50)
    tab state_iso if urbniz == 1 //TN is at the threshold

*calculate indicators
    *pucca structure: roof, wall, and floor. 
	gen infra_pucca_strct = 0 if infra_has_dwell == 1
	replace infra_pucca_strct = 1 if infra_imp_wall == 1 & infra_imp_roof == 1 & infra_pucca_floor == 1 & infra_has_dwell == 1
	
    *overcrowding measured by dwelling room number 
    gen infra_crowd_r = hh_size / infra_room
    
	*overcrowding measured by dwelling area
    gen infra_crowd_a = infra_area / hh_size
	gen infra_crowd_a_ln = ln(infra_crowd_a)
	
	sum infra_crowd_a if hh_urban == 1 [aw = hh_weight],de
	gen infra_crowd_a_dm =(infra_crowd_a<`r(p50)') if hh_urban == 1 // urban measure for overcrowding
    
	*cost of rent to umce
	gen cost_rent_rate = cost_rent / hh_umce
	
	*cost of rent per square feet
	replace cost_rent = . if cost_rent == 0 | legal_rent != 1
	gen cost_rent_sq = cost_rent / infra_area
	
	*maximum distance normally travelled to the place of work: male (female worker median is 2, very skewed)
	gen hq_travel_m_dm = (hq_travel_m >=3)
	replace hq_travel_m_dm = . if hq_travel_m == .
	
*keep only those with dwelling
    keep if infra_has_dwell == 1

save "${final}/nss76_hse_cluster",replace

****************************************************************************
*Summarize of variables
****************************************************************************
use "${final}/nss76_hse_cluster",clear

sum [aw = hh_weight]

*data is not sufficient for analysis
	drop cost* *cost legal_move legal_move_reason hq_slum_doc hq_slum_be
*drop variable with sd <0.3
	drop hq_elec 
*drop not interested indicator
    drop hq_travel_m hq_travel_f hq_travel_t hq_resid

****************************************************************************
*Cluster of housing material (Jaccard)
****************************************************************************
tab infra_roof_type [aw = hh_weight]

recode infra_roof_type (1/4 = 1) (7 = 2) (5 6 8 9 = 3), gen(infra_roof_type_grp) //separate the metal sheet. 

tab infra_roof_type_grp, gen (roof)
tab infra_pucca_floor, gen (floor)
tab infra_imp_wall, gen (wall)

rename (wall1 wall2 floor1 floor2) (wall_np wall_p floor_np floor_p) 

*decide the housing material cluster
preserve 

    keep roof* floor* wall* 

    matrix dissimilarity houseD = , variables Jaccard dissim(oneminus)
    matlist houseD

    clustermat singlelink houseD, name(house) clear labelvar(question)
    describe
    cluster dendrogram house, labels(question) title(Single-linkage clustering) ytitle(Jaccard similarity)
restore 

*generate the housing material cluster
    gen conc_hse = (floor_p == 1 & wall_p == 1 & roof3 == 1)

    tab conc_hse,mi
    tab conc_hse, gen(conc_hse)
    rename (conc_hse1 conc_hse2)(n_conc_house conc_house)

****************************************************************************
*Cluster of variables 
****************************************************************************

*dummy indicators interested (matching)
preserve 

    keep if hh_urban == 1
    keep conc_hse infra_crowd_a_dm hq_water hq_water_su infra_water_in hq_san hq_san_in hq_dwell_indi hq_ventilation hq_married_sep hq_kitchen hq_period legal_stay10 hq_travel_m_dm urbniz
	
    matrix dissimilarity hqD = , variables matching dissim(oneminus)
    matlist hqD

    clustermat singlelink hqD, name(hq) clear labelvar(question)
    describe
	
    cluster dendrogram hq, labels(question) xlabel(, angle(90) labsize(*.75)) title(Single-linkage clustering: Urban) ytitle(matching similarity)
	
restore

*dummy indicators interested (Jaccard)
preserve 

    keep if hh_urban == 1
    keep n_conc_house conc_house infra_crowd_a_dm hq_water hq_water_su infra_water_in hq_san hq_san_in hq_dwell_indi hq_period hq_ventilation hq_married_sep hq_kitchen legal_stay10 hq_travel_m_dm urbniz

	
    matrix dissimilarity hqD = , variables Jaccard dissim(oneminus)
    matlist hqD

    clustermat singlelink hqD, name(hq) clear labelvar(question)
    describe
	
    cluster dendrogram hq, labels(question) xlabel(, angle(90) labsize(*.75)) title(Single-linkage clustering: Urban) ytitle(Jaccard similarity)
	
restore


****************************************************************************
*Cluster of observations
****************************************************************************

keep if hh_urban == 1 

*cluster adding var gradually

**housing infra and service (sanitation/water)
cluster kmeans conc_hse hq_san_in, k(3) ///
name(gr3) start(firstk) measure(Jaccard)
tab gr3
table gr3,c(mean conc_hse mean hq_san_in) format(%9.2f) center

cluster kmeans conc_hse infra_water_in, k(3) ///
name(gr3_2) start(firstk) measure(Jaccard)
tab gr3_2
table gr3_2,c(mean conc_hse mean infra_water_in) format(%9.2f) center

**housing infra, service (sanitation), and overcrowding
cluster kmeans conc_hse hq_san_in infra_crowd_a_dm, k(3) ///
name(gr4) start(firstk) measure(Jaccard)
tab gr4
table gr4,c(mean conc_hse mean hq_san_in mean infra_crowd_a_dm) format(%9.2f) center

**housing infra, service (sanitation), overcrowding, location, and housing type
cluster kmeans conc_hse hq_san_in infra_water_in infra_crowd_a_dm hq_travel_m_dm, k(3) ///
name(gr5) start(firstk) measure(Jaccard)
tab gr5 [aw = hh_weight]
table gr5 [aw = hh_weight],c(mean conc_hse mean hq_san_in mean infra_water_in ) format(%9.2f) center
table gr5 [aw = hh_weight],c(median hh_umce mean infra_crowd_a_dm mean hq_travel_m_dm) format(%9.2f) center
tab gr5 hq_nslum,col

cluster kmeans conc_hse hq_san_in infra_water_in infra_crowd_a_dm hq_travel_m_dm, k(4) ///
name(gr5_2) start(firstk) measure(Jaccard)
tab gr5_2 [aw = hh_weight]
table gr5_2 [aw = hh_weight],c(median hh_umce  mean conc_hse mean hq_san_in mean infra_water_in ) format(%9.2f) center 
table gr5_2 [aw = hh_weight],c(median hh_umce  mean infra_crowd_a_dm mean hq_travel_m_dm) format(%9.2f) center 
tab gr5_2 hq_nslum [aw = hh_weight],col //best pick up the slum (4 groups)

cluster kmeans conc_hse hq_san_in infra_water_in infra_crowd_a_dm hq_travel_m_dm , k(5) ///
name(gr5_2_1) start(firstk) measure(Jaccard)
tab gr5_2_1 [aw = hh_weight]
table gr5_2_1 [aw = hh_weight],c(median hh_umce  mean conc_hse mean hq_san_in mean infra_water_in ) format(%9.2f) center 
table gr5_2_1 [aw = hh_weight],c(median hh_umce  mean infra_crowd_a_dm mean hq_travel_m_dm) format(%9.2f) center 
tab gr5_2_1 hq_nslum [aw = hh_weight],col //best pick up the slum (5 groups)

cluster kmeans conc_hse hq_san_in infra_water_in infra_crowd_a_dm hq_travel_m_dm hq_dwell_indi, k(5) ///
name(gr5_2_2) start(firstk) measure(Jaccard)
tab gr5_2_2 [aw = hh_weight]
table gr5_2_2 [aw = hh_weight],c(median hh_umce  mean conc_hse mean hq_san_in mean infra_water_in) format(%9.2f) center 
table gr5_2_2 [aw = hh_weight],c(median hh_umce  mean infra_crowd_a_dm mean hq_travel_m_dm mean hq_dwell_indi) format(%9.2f) center 
tab gr5_2_2 hq_nslum [aw = hh_weight],col 




****************************************************************************
*Compare with sd using income 
****************************************************************************

xtile de_hh_umce_ln = hh_umce_ln [aw = hh_weight],n(5)

table gr5_2_1 [aw = hh_weight],c(median hh_umce sd conc_hse sd hq_san_in sd infra_water_in sd infra_crowd_a_dm) format(%9.2f) center //sd hq_travel_m_dm sd hq_dwell_indi
table gr5_2_1 [aw = hh_weight],c(median hh_umce sd hq_travel_m_dm) format(%9.2f) center 

table de_hh_umce_ln [aw = hh_weight],c(median hh_umce sd conc_hse sd hq_san_in sd infra_water_in sd infra_crowd_a_dm ) format(%9.2f) center
table de_hh_umce_ln [aw = hh_weight],c(median hh_umce sd hq_travel_m_dm) format(%9.2f) center

****************************************************************************
*Hedonic pricing
****************************************************************************

global reg_var "conc_hse hq_san_in infra_water_in infra_crowd_a_dm hq_travel_m_dm hq_dwell_indi"

foreach var in $reg_var {
reg hh_umce_ln `var' [pw=hh_weight]
}

reg hh_umce_ln $reg_var [pw=hh_weight]

reg hh_umce_ln $reg_var [pw=hh_weight], absorb(hh_state) cluster(hh_state) 



gen qual = string(conc_hse)+"-"+string(hq_san_in)+"-"+string(infra_water_in)+"-"+string(hq_san_in)+"-"+string(infra_crowd_a_dm)+"-"+string(hq_travel_m_dm)+"-"+string(hq_dwell_indi)
