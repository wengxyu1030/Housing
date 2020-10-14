****************************************************************************
* Description: Generate clusters for housing condition using nss76 (rural)
* Date: September 30, 2020
* Version 1.0
* Last Editor: Aline
****************************************************************************


****************************************************************************
* Determine Whose Machine is running the code and set the global directory
****************************************************************************
if "`c(username)'" == "wb308830" local pc = 0
if "`c(username)'" != "wb308830" local pc = 1
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 76"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS76"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"

****************************************************************************
* Load the data
****************************************************************************
use "${root}\Data Output Files\NSS76_All.dta",clear

****************************************************************************
* Get the Variable List to Make a Summary Table 
****************************************************************************
label var hh_size "Size of Household"

**** MATERIALS ****
gen in_wall_permanent = 100*(b7_15== 6 | b7_15== 8 | b7_15== 9) // exclude timber and metal sheet
label var in_wall_permanent "Wall: Cement or Stone (%)"

gen in_wall = "Katcha"
replace in_wall = "Permanent" if in_wall_permanent == 100
replace in_wall = "Metal" if inlist(b7_15,5,7) //metal or timber.
label var in_wall "Wall Material"

gen in_roof_permanent = 100*(b7_16== 6 | b7_16== 8 | b7_16== 9) // exclude metal and asbestos sheets
label var in_roof_permanent "Roof: Cement or Stone (%)"

gen in_roof = "Katcha"
replace in_roof = "Permanent" if in_roof_permanent == 100
replace in_roof = "Metal" if b7_16 == 7
label var in_roof "Roof Material"

gen in_floor_permanent = 100*(inrange(b7_14,3,6)) // exclude mud, bamboo and log
label var in_floor_permanent "Floor: Cement or Stone (%)"

gen in_floor = "Katcha"
replace in_floor = "Permanent" if in_floor_permanent == 100

sum *permanent

gen in_all_permanent = (in_wall_permanent*in_roof_permanent*in_floor_permanent) / 1e4
label var in_all_permanent "All Materials: Cement or Stone (%)"

gen in_sep_kitch = 100*inrange(b7_12,1,2) 
label var in_sep_kitch "Separate Kitchen (%)" 

gen in_flat = 100 * (b7_1 == 2)
label var in_flat "Flat (%)"

gen in_size = b7_8 
label var in_size "Dwelling Size (sq ft)"
sum in_size [aw = hh_weight] if hh_urban ==0 ,de
gen in_size_big = 100*(in_size > `r(p50)') if hh_urban == 0 

recode in_room (7/41 = 7), gen(in_room_grp)
tostring in_room_grp, replace
replace in_room_grp = ">6" if in_room_grp == "7"

sum in_room [aw = hh_weight] if hh_urban == 0,de
gen in_room_big = 100*(in_room > `r(p50)') if hh_urban == 0 
label var in_room_big "More Rooms"

gen in_ppl_room = hh_size / in_room
label var in_ppl_room "People per room"
gen crowd_room =  100*(in_ppl_room > 1)
label var crowd_room "Overcrowd-room"

gen in_ppl_area = in_size / hh_size
label var in_ppl_area "Area in sq ft per person"

**** WATER and SANITATION ****
gen h20_piped_in = 100* (b5_1 == 2 | b5_1 == 1 |b5_1 == 10 | b5_1 == 11)
label var h20_piped_in "Water: Piped into Dwelling (%)"

gen h20_yard = 100* (b5_1 == 3 | b5_1 ==4 )
label var h20_yar "Water: Piped into Yard (%)"

gen h20_pump_in = 100* inrange(b5_1,5,8)*(b5_5 <= 2) // include a protected well
label var h20_pump_in "Water: Pump/Tubewell in Premises (%)"

gen h20_pump_out = 100* inrange(b5_1,5,8)*(b5_5 > 2) // include a protected well
label var h20_pump_out "Water: Pump/Tubewell Outside Premises (%)"

gen h20_other = 100* (h20_piped_in!=100 & h20_pump_in!=100 & h20_pump_out!=100 & h20_yard!=100)
label var h20_other "Water: Other (%)"

gen h20 = ""
replace h20 = "Piped in" if h20_piped_in == 100
replace h20 = "Yard" if h20_yard == 100
replace h20 = "Pump in" if h20_pump_in == 100
replace h20 = "Pump out" if h20_pump_out == 100
replace h20 = "Other" if h20_other == 100
label var h20 "Water Access"

gen san_flush = 100*inrange(b5_26,1,2)
label var san_flush "Sanitation: Flush (%)"

gen san_imp_pit = 100*inrange(b5_26,6,7)
label var san_imp_pit "Sanitation: Improved Pit (%)"

gen san_single_twin_pit = 100*inrange(b5_26,3,4)
label var san_single_twin_pit "Sanitation: Single/Twin Pit (%)"

gen san_other = 100*(san_flush!=100&san_imp_pit!= 100 & san_single_twin_pit!=100)
label var san_other "Sanitation: Other (%)"

gen san = ""
replace san = "Flush" if san_flush == 100
replace san = "Improved Pit" if san_imp_pit == 100
replace san = "Single/Twin Pit" if san_single_twin_pit == 100
replace san = "Other" if san_other == 100
label var san "Sanitation Access"

****** Check Weights for Large Cities ****** 
gen hh_district = substr(b1_id,19,2)
destring hh_district, replace

gen n = 1 
egen district_pop_num = sum(n*hh_weight) ,by(hh_state hh_dist)
egen district_pop_denom = sum(hh_weight)
gen district_pop = district_pop_num / district_pop_denom

gsort -district_pop
order hh_state hh_dist *pop
gen state_dist = hh_state + "-" + string(hh_dist)
table state_dist if district_pop > 0.005, c(count hh_urban mean hh_urban mean district_pop) row 

gen big_city  = district_pop > 0.005 & hh_urban ==1 
 
/*
*Mumbai - district == 23
table hh_district if hh_state == "27", c(sum hh_weight mean hh_weight sd hh_weight sd hh_urban count hh_weight)
*Chennai
table hh_district if hh_state == "33", c(sum hh_weight mean hh_weight sd hh_weight sd hh_urban count hh_weight)
*HYderabad
table hh_district if hh_state == "36", c(sum hh_weight mean hh_weight sd hh_weight sd hh_urban count hh_weight)
*delhi
table hh_district if hh_state == "07", c(sum hh_weight mean hh_weight sd hh_weight sd hh_urban count hh_weight)
*Banglore
table hh_district if hh_state == "29", c(sum hh_weight mean hh_weight sd hh_weight sd hh_urban count hh_weight)
*/


local var_summary hh_size in_* h20* san*

*only focus on urban households with housing. 
keep if infra_has_dwell == 1 & hh_urban == 0

save "${root}\Data Output Files\NSS76_All_clst_r.dta",replace

****************************************************************************
*Cluster of housing quality (matching Dendrogram)
****************************************************************************
use "${root}\Data Output Files\NSS76_All_clst_r.dta",replace

*decide the housing material cluster
preserve 

    keep in_roof_permanent in_floor_permanent in_wall_permanent

    matrix dissimilarity houseD = , variables matching dissim(oneminus)
    matlist houseD

    clustermat singlelink houseD, name(house) clear labelvar(question)
    describe
    cluster dendrogram house, labels(question) title(Single-linkage clustering) ytitle(Matching similarity)
	
restore 

*combine housing infra with area, separate kitchen
preserve 

    keep in_roof_permanent in_floor_permanent in_wall_permanent in_size_big in_room_big in_sep_kitch

    matrix dissimilarity houseD = , variables matching dissim(oneminus)
    matlist houseD

    clustermat singlelink houseD, name(house) clear labelvar(question)
    describe
    cluster dendrogram house, labels(question) title(Single-linkage clustering) ytitle(Matching similarity) xlabel(, angle(90) labsize(*.75))
	
restore 

*combine housing infra with water
preserve 

    keep in_roof_permanent in_floor_permanent in_wall_permanent h20*

    matrix dissimilarity houseD = , variables matching dissim(oneminus)
    matlist houseD

    clustermat singlelink houseD, name(house) clear labelvar(question)
    describe
    cluster dendrogram house, labels(question) title(Single-linkage clustering) ytitle(Matching similarity) xlabel(, angle(90) labsize(*.75))
	
restore 

*combine housing infra with sanitation
preserve 

    keep in_roof_permanent in_floor_permanent in_wall_permanent san*

    matrix dissimilarity houseD = , variables matching dissim(oneminus)
    matlist houseD

    clustermat singlelink houseD, name(house) clear labelvar(question)
    describe
    cluster dendrogram house, labels(question) title(Single-linkage clustering) ytitle(Matching similarity) xlabel(, angle(90) labsize(*.75))
	
restore 

*combine housing infra, water, sanitation

preserve 

    keep in_roof_permanent in_floor_permanent in_wall_permanent san* h20* 

    matrix dissimilarity houseD = , variables matching dissim(oneminus)
    matlist houseD

    clustermat singlelink houseD, name(house) clear labelvar(question)
    describe
    cluster dendrogram house, labels(question) title(Single-linkage clustering) ytitle(Matching similarity) xlabel(, angle(90) labsize(*.75))
	
restore 

*combine housing infra, water, sanitation, and size separate kitchen 

preserve 

    keep in_roof_permanent in_floor_permanent in_wall_permanent san* h20* in_size_big in_room_big in_sep_kitch

    matrix dissimilarity houseD = , variables matching dissim(oneminus)
    matlist houseD

    clustermat singlelink houseD, name(house) clear labelvar(question)
    describe
    cluster dendrogram house, labels(question) title(Single-linkage clustering) ytitle(Matching similarity) xlabel(, angle(90) labsize(*.75))
	
restore 

****************************************************************************
*Crosstab the principal variables. 
****************************************************************************

*housing material grouping: 42% is whole pucca structure.  
sort in_wall_permanent in_roof_permanent in_floor_permanent
gen house_material = string(in_wall_permanent)+"-"+string(in_floor_permanent)+"-"+string(in_roof_permanent)
tab house_material 

gen hse_material_grp = 1
replace hse_material_grp = 3 if house_material == "100-100-100"
replace hse_material_grp = 2 if house_material == "100-100-0"
tab hse_material_grp [aw = hh_weight]

gen hse_material_grp_p = 0
replace hse_material_grp_p = 1 if house_material == "100-100-100"
tab hse_material_grp_p [aw = hh_weight]

****************************************************************************
*Cluster of observations
****************************************************************************

*all the indicators add up
sort hse_material_grp h20_piped_in san_flush in_size_big
gen hse_quality = string(hse_material_grp)+"-"+string(h20_piped_in)+"-"+string(san_flush)+"-"+string(in_size_big)+"-"+string(in_sep_kitch)
tab hse_quality [aw = hh_weight],sort //15% has none of the indicators met. 

*crosstab service and other indicator. 
gen hse_service = string(h20_piped_in)+"-"+string(san_flush)
tab hse_service [aw = hh_weight] //more than 90% of them do not have complete water and sanitation in house. 
tab hse_service hse_material_grp [aw = hh_weight],cell

    gen hse_service_grp = 0
    replace hse_service_grp = 1 if hse_service == "100-100"
	
	*with housing materia
	tab hse_service_grp hse_material_grp [aw = hh_weight],cell
	tab hse_service_grp hse_material_grp_p [aw = hh_weight],cell
	
	*with dwelling size
	tab hse_service_grp in_size_big [aw = hh_weight],cell //half of them is overcrowded. 
	
	*with separate kitchen
	tab hse_service_grp in_sep_kitch [aw = hh_weight],row //majority of them is with separate kitchen with good service. 

gen hse_quality_grp = string(hse_material_grp_p)+"-"+string(hse_service_grp)+"-"+string(in_size_big)
tab hse_quality_grp [aw = hh_weight]
tab hse_quality_grp [aw = hh_weight],sort

*cross validate with other indicator: slum, consumption, rent, overcrowding

**distribution of slum and renter
tab hse_quality_grp legal_rent [aw = hh_weight],col

**mean
table hse_quality_grp [aw = hh_weight],c(mean hq_slum med hh_umce mean legal_rent med cost_rent mean in_ppl_area ) format(%9.2f) center
table hse_quality_grp [aw = hh_weight],c(mean  in_sep_kitch) format(%9.2f) center

**sd (binary no need to check sd.)


****************************************************************************
*Cluster using k-means (matching)
****************************************************************************
use "${root}\Data Output Files\NSS76_All_clst_r.dta",replace

gen hse_material_grp_p = 0
replace hse_material_grp_p = 100 if in_floor_permanent == 100 & in_wall_permanent == 100 & in_roof_permanent == 100

********housing material:
**no roof/all
preserve 
    cluster kmeans  in_floor_permanent in_roof_permanent in_wall_permanent, k(2) ///
    name(gr2) start(firstk) measure(Jaccard)
    tab gr2
    table gr2,c(mean in_wall_permanent mean in_roof_permanent mean in_floor_permanent) format(%9.2f) center
restore

**only wall/no roof/all
preserve 
    cluster kmeans  in_floor_permanent in_roof_permanent in_wall_permanent, k(3) ///
    name(gr3) start(firstk) measure(Jaccard)
    tab gr3
    table gr3,c(mean in_wall_permanent mean in_roof_permanent mean in_floor_permanent) format(%9.2f) center
restore

********water:
**with/without water from yard. (12% has yard water)
preserve 
    cluster kmeans  h20_piped_in h20_yard h20_pump_in h20_pump_out h20_other, k(2) ///
    name(gr2) start(firstk) measure(Jaccard)
    tab gr2
    table gr2,c(mean h20_piped_in mean h20_yard mean h20_pump_in mean h20_pump_out mean h20_other) format(%9.2f) center
restore

**yard, pump put, other combination. (12% only has yard water, 21% pump out)
preserve 
    cluster kmeans  h20_piped_in h20_yard h20_pump_in h20_pump_out h20_other, k(3) ///
    name(gr3) start(firstk) measure(Jaccard)
    tab gr3
    table gr3,c(mean h20_piped_in mean h20_yard mean h20_pump_in mean h20_pump_out mean h20_other) format(%9.2f) center
restore


********sanitation:
**with/without flush (38% flush)
preserve 
    cluster kmeans  san_flush san_imp_pit san_single_twin_pit san_other, k(2) ///
    name(gr2) start(firstk) measure(Jaccard)
    tab gr2
    table gr2,c(mean san_flush mean san_imp_pit mean san_single_twin_pit mean san_other) format(%9.2f) center
restore

**flush/other (28% other, 38% flush)
preserve 
    cluster kmeans  san_flush san_imp_pit san_single_twin_pit san_other, k(3) ///
    name(gr3) start(firstk) measure(Jaccard)
    tab gr3
    table gr3,c(mean san_flush mean san_imp_pit mean san_single_twin_pit mean san_other) format(%9.2f) center
restore

********water and sanitation:
**with/out both (55%)
preserve 
    cluster kmeans  san_flush h20_piped_in, k(2) ///
    name(gr2) start(firstk) measure(Jaccard)
    tab gr2
    table gr2,c(mean san_flush mean h20_piped_in) format(%9.2f) center
restore

**without both/ without pipe_in water (55%, 28%)
preserve 
    cluster kmeans  san_flush h20_piped_in, k(3) ///
    name(gr2) start(firstk) measure(Jaccard)
    tab gr2
    table gr2,c(mean san_flush mean h20_piped_in) format(%9.2f) center
restore

********infra, water and sanitation:

preserve 
    cluster kmeans in_floor_permanent in_roof_permanent in_wall_permanent san_flush h20_piped_in, k(3) ///
    name(gr3) start(firstk) measure(Jaccard)
    tab gr3
    table gr3,c(mean in_floor_permanent mean in_roof_permanent mean in_wall_permanent mean san_flush mean h20_piped_in) format(%9.2f) center
restore

preserve 
    cluster kmeans in_floor_permanent in_roof_permanent in_wall_permanent san_flush h20_piped_in, k(4) ///
    name(gr4) start(firstk) measure(Jaccard)
    tab gr4
    table gr4,c(mean in_floor_permanent mean in_roof_permanent mean in_wall_permanent mean san_flush mean h20_piped_in) format(%9.2f) center
restore

********infra, water and sanitation, size:

preserve 
    cluster kmeans in_floor_permanent in_roof_permanent in_wall_permanent san_flush h20_piped_in in_size_big, k(3) ///
    name(gr3) start(firstk) measure(Jaccard)
    tab gr3
    table gr3,c(mean in_floor_permanent mean in_roof_permanent mean in_wall_permanent mean san_flush mean h20_piped_in) format(%9.2f) center
	table gr3,c(mean in_size_big) format(%9.2f) center
restore

preserve 
    cluster kmeans in_floor_permanent in_roof_permanent in_wall_permanent san_flush h20_piped_in in_size_big, k(4) ///
    name(gr3) start(firstk) measure(Jaccard)
    tab gr3
    table gr3,c(mean in_floor_permanent mean in_roof_permanent mean in_wall_permanent mean san_flush mean h20_piped_in) format(%9.2f) center
	table gr3,c(mean in_size_big) format(%9.2f) center
restore

preserve //best
    cluster kmeans in_floor_permanent in_roof_permanent in_wall_permanent san_flush h20_piped_in in_size_big, k(5) ///
    name(gr3) start(firstk) measure(Jaccard)
    tab gr3
    table gr3,c(mean in_floor_permanent mean in_roof_permanent mean in_wall_permanent mean san_flush mean h20_piped_in) format(%9.2f) center
	table gr3,c(mean in_size_big) format(%9.2f) center
restore

********infra, water and sanitation, size, separate kitchen:

preserve 
    cluster kmeans in_floor_permanent in_roof_permanent in_wall_permanent san_flush h20_piped_in in_size_big in_sep_kitch, k(5) ///
    name(gr3) start(firstk) measure(Jaccard)
    tab gr3
    table gr3,c(mean in_floor_permanent mean in_roof_permanent mean in_wall_permanent mean san_flush mean h20_piped_in) format(%9.2f) center
	table gr3,c(mean in_size_big mean in_sep_kitch) format(%9.2f) center
restore

preserve //best
    cluster kmeans in_floor_permanent in_roof_permanent in_wall_permanent san_flush h20_piped_in in_size_big in_sep_kitch, k(6) ///
    name(gr3) start(firstk) measure(Jaccard)
    tab gr3
    table gr3,c(mean in_floor_permanent mean in_roof_permanent mean in_wall_permanent mean san_flush mean h20_piped_in) format(%9.2f) center
	table gr3,c(mean in_size_big mean in_sep_kitch) format(%9.2f) center
restore

preserve
    cluster kmeans in_floor_permanent in_roof_permanent in_wall_permanent san_flush h20_piped_in in_size_big in_sep_kitch, k(7) ///
    name(gr3) start(firstk) measure(Jaccard)
    tab gr3
    table gr3,c(mean in_floor_permanent mean in_roof_permanent mean in_wall_permanent mean san_flush mean h20_piped_in) format(%9.2f) center
	table gr3,c(mean in_size_big mean in_sep_kitch) format(%9.2f) center
restore


*********consolidate with k-mode on indicators
forvalues r = 40(1)45 {
preserve 
    cluster kmeans hse_material_grp_p san_flush h20_piped_in in_room_big in_sep_kitch, k(6) ///
    name(gr_`r') start(kr(`r')) measure(Jaccard)
    tab gr_`r'
    table gr_`r',c(mean hse_material_grp_p mean san_flush mean h20_piped_in mean in_size_big mean in_sep_kitch) format(%9.2f) center
restore
}

//when r = 43 the cluster is the best. (more evenly distributed ans separated the poor households out)

********cross validate with other indicator: slum, consumption, rent, overcrowding********
use "${root}\Data Output Files\NSS76_All_clst_r.dta",replace

cluster kmeans in_all_permanent san_flush h20_piped_in in_room_big in_sep_kitch, k(6) ///
    name(cluster) start(kr(43)) measure(Jaccard)
    tab cluster
    table cluster,c(mean in_all_permanent mean in_sep_kitch mean in_room_big mean h20_piped_in mean san_flush) format(%9.2f) center


**mean
table cluster [aw = hh_weight],c(med cost_rent med hh_umce mean hh_size mean legal_own med in_ppl_room) format(%9.2f) center

**the mode for each group
sort in_floor_permanent in_roof_permanent in_wall_permanent san_flush san_imp_pit h20_piped_in h20_pump_in in_size_big in_sep_kitch

gen hq_cluster_name = string(in_wall_permanent)+"-"+string(in_floor_permanent)+"-"+string(in_roof_permanent) ///
+"-"+string(san_flush) ///
+"-"+string(h20_piped_in) ///
+"-"+string(in_room_big)+"-"+string(in_sep_kitch) 

bysort cluster: tab hq_cluster_name  [aw = hh_weight],sort

save "${root}\Data Output Files\NSS76_rural_kmeans.dta",replace