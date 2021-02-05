***************************
*** AFH 
*** NSS61-Non-Housing Poverty Line (2004)
*** Prepared by Aline Weng
*** Date:2/4/2021
***************************

clear 
set more off 

if "`c(username)'" == "wb308830" local pc = 0
if "`c(username)'" != "wb308830" local pc = 1
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 61"
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS61"
if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS"

cd "${root}"

global r_input "${root}\Raw Data & Dictionaries"
global r_output "${root}\Data Output Files"

log using "${script}\NSS61\01_NSS61_Poverty_Line.log",replace
set linesize 255


***********************************************************************************
*Step 1: Prepare data on rent and conveyance, MPCE. 
***********************************************************************************
use "${r_input}\Block 10_Monthly expenditure on miscellaneous goods and services including medical (non-institutional), rents and taxes.dta",clear
merge m:1 HHID using "${r_input}\Block 3.dta"
drop _merge
merge m:1 HHID using "${r_input}\Block 3 Part 2_Household Characteristics.dta"
drop _merge

gen hh_size = B3_q1
   
/* poverty line is by state and by sector */

    *estimate housing related expenditure:
	  
	  *Rent house rent, garage rent(10: code = 529, 30 days recall period)
	  gen double rent = B10_q4*(B10_q1 == "520")
	  
	  *Rent all
	  gen double rent_all = B10_q4*(B10_q1 == "529")
	  
	  *Conveyance (10: 519, 30 days recall period)
	  gen double convy = B10_q4*(B10_q1 == "519")
	  
	  *Collapse at household level for water ant rent
	  foreach var in rent rent_all convy { 
	  egen double total_`var' = sum(`var'), by(HHID)
	  } 
	  bys HHID: keep if _n == 1 // keep only one observation for each HH

merge 1:m HHID using "${r_input}\Block 6_Monthly consumption of fuel & light.dta"
drop _merge
	  
	  *Fuel and light (12: 359, 30 days recall period)
	  gen double fuel = B6_q6*(B6_q1 == "359")
	  egen double total_fuel = sum(fuel), by(HHID)
	  bys HHID: keep if _n == 1
	  
merge 1:m HHID using "${r_input}\Block 11_Expenditure for purchase and construction (including repair and maintenance) of durable goods for domestic use.dta"
drop _merge
        
	  *Durable goods. (11: 639, 365 days recall period)
	  gen double durable = B11_q14*(B11_q1 == "639")*30/365
	  egen double total_durable = sum(durable), by(HHID)
	  bys HHID: keep if _n == 1

merge 1:m HHID using "${r_input}\Block 5_Monthly consumption of food, pan, tobacco and intoxicants.dta"
drop _merge

      *Cereal (5: 129, 30 days recall period)
	  gen double cereal = B5_q6*(B5_q1 == "129")
	  egen double total_cereal = sum(cereal), by(HHID)
	  bys HHID: keep if _n == 1
	  
rename HHID hhid
merge 1:1 hhid using "${r_input}\NSS_61_Poverty_For_Aline.dta"
keep if _merge == 3
drop _merge

	*Total rent and coveyance expenditure (all rent)
	egen double exp_rc = rowtotal(total_rent total_convy) //using rent_all instead of just house rent to keep consistency with the poverty measure

	*Total rent and coveyance expenditure (house, garage rent only)
	egen double exp_rc_all = rowtotal(total_rent_all total_convy) 

    *Rent and coveyance consumption per capita
	gen double exp_rc_pp = exp_rc/hh_size 
	gen double exp_rc_al_pp = exp_rc_all/hh_size 
	
	*Light and Fuel exp. per capita
	gen double exp_fl_pp = total_fuel/hh_size 
	
	*Cereal exp. per capita
	gen double exp_cl_pp = total_cereal/hh_size 
	
	*Durable goods exp. per capita
	gen double exp_dg_pp = total_durable/hh_size 
	
    *Identify renters
	gen renter = (total_rent > 0 & !mi(total_rent)) & B3_q16 == "2" //rent is positive and tenure status is hire. 


***********************************************************************************
*Step 2: Identify the urban MPCE class and the budget share of rent conveyance exp
***********************************************************************************

/*
Try to identify the window of MPCE class that used to constructed the rent component of the 
poverty line. 
*/

*Urban MPCE Classes (decile)
keep if sector == 2 //keep only urban households. 

foreach i in 10 100 {
xtile mpce_`i' = mpce_mrp [aw = pwt] , n(`i') //urban mpce classes
}

table mpce_100 [aw = pwt] ,c(min mpce_mrp max mpce_mrp) //579Rs is 26 percentile
table mpce_10 [aw = pwt] ,c(min mpce_mrp max mpce_mrp) //the same class for 579Rs(20-30 percentile), however higher value of MPCE for every class compared to the method paper.

*Share of the rent and conveyance, fuel, cereal. 
foreach var in rc rc_al fl cl dg {
gen exp_`var'_ratio = exp_`var'_pp/mpce_mrp *100 
}

table mpce_10 [aw = pwt], c(med exp_rc_al_ratio med exp_rc_ratio med exp_fl_ratio med exp_cl_ratio) //(2.5/2.4), 11.6, 15.9 benchmark to rent 3.5, fuel 12.2, cereal 16.7 

*Absolute exp. for rent and conveyance 
table mpce_10 [aw = pwt], c(med exp_rc_al_pp med exp_rc_pp med exp_fl_pp med exp_cl_pp) //(14.4/14)， 66, 91 at the MPCE class, benchmark to rent 30.68， fuel 70.4, cereal 96.5

log close
