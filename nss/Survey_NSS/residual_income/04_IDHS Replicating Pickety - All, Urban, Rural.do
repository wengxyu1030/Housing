
****************************************************************************
* Description: Use NSS68 and UMD HDS data estimate income, this file to 
* describe the income-exp ratio. 
* Date: Feb. 15, 2021
* Version 2
* Last Editor: Aline 
****************************************************************************

****************************************************************************
clear 
clear matrix
****************************************************************************

****************************************************************************
* Determine Whose Machine is running the code and set the global directory
****************************************************************************
if "`c(username)'" == "wb308830" local pc = 0
if "`c(username)'" != "wb308830" local pc = 1
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\IDHS" //please correct accordingly
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS68"
if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS\NSS68"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"
di "${r_output}"

set more off 
clear 
********************************************************************************

*******************************************
*Load Data
*******************************************

use "${r_input}\DS0002\36151-0002-Data.dta",clear //UMD DHS data

foreach var of var * {
rename `var' `= lower("`var'")'
}

replace income = 0 if income < 0 //assumption there's no negative income.

egen con_1 = rowtotal(co1x co2x co3x co4x co5x co6x co7x co8x co9x co10x co11x co12x ///
co13x co14x) //constructed
egen con_2 = rowtotal(co15-co30) 
egen con_3 = rowtotal(co31-co33)
egen con_4 = rowtotal(co34-co52) //annual

replace cototal= (con_1+con_2+con_3)*12+con_4
drop con_1-con_4
sum cototal [aw = indwt]
rename cototal exp



*Trim and Save
tempfile e_i_trans all urban 
keep exp income urban2011 indwt 
save `e_i_trans'

*All Households 
use `e_i_trans'
local tile = 100
xtile exp_100 = exp [aw=indwt], nq(`tile')
xtile inc_100 = income [aw=indwt], nq(`tile')

egen mean_income_q = wtmean(income), by(inc_100) weight(indwt)
egen mean_exp_q = wtmean(exp), by(exp_100) weight(indwt)

gen alpha_a1 = (mean_income_q / mean_exp_q)

keep if inc_100 == exp_100
keep exp_100 alpha
duplicates drop
count
save `all'

*Urban Households 
use `e_i_trans'
keep if urban2011 == 1
local tile = 100
xtile exp_100 = exp [aw=indwt], nq(`tile')
xtile inc_100 = income [aw=indwt], nq(`tile')

egen mean_income_q = wtmean(income), by(inc_100) weight(indwt)
egen mean_exp_q = wtmean(exp), by(exp_100) weight(indwt)

gen alpha_a1 = (mean_income_q / mean_exp_q)

keep if inc_100 == exp_100
keep exp_100 alpha_a1
duplicates drop
count
*ren exp_100
ren alpha_a1 alpha_a1_u
sort exp_100
save `urban'

*Rural Households 
use `e_i_trans'
keep if urban2011 == 0
local tile = 100
xtile exp_100 = exp [aw=indwt], nq(`tile')
xtile inc_100 = income [aw=indwt], nq(`tile')

egen mean_income_q = wtmean(income), by(inc_100) weight(indwt)
egen mean_exp_q = wtmean(exp), by(exp_100) weight(indwt)

gen alpha_a1 = (mean_income_q / mean_exp_q)

keep if inc_100 == exp_100
keep exp_100 alpha_a1
duplicates drop
count
*ren exp_100
ren alpha_a1 alpha_a1_r
sort exp_100

merge 1:1 exp_100 using `all'
drop _merge 

merge 1:1 exp_100 using `urban'
drop _merge 


*Graph alpha a1 for all, urban and rural 
twoway (line alpha_a1 exp_100) (line alpha_a1_u exp_100) (line alpha_a1_r exp_100), legend(row(1)) graphr(c(white)) legend(label(1 "All") label(2 "Urban") label(3 "Rural"))

codebook alpha*, c
*Interpolate for urban and rural - 
 ipolate alpha_a1_u exp_100, gen(alpha_a1_u_ip) epolate
 ipolate alpha_a1_r exp_100, gen(alpha_a1_r_ip) epolate
 codebook alpha*, c
 

 *Graph INTERPOLATED alpha a1 for all, urban and rural 
twoway (line alpha_a1 exp_100) (line alpha_a1_u_ip exp_100) (line alpha_a1_r_ip exp_100), legend(row(1)) graphr(c(white)) legend(label(1 "All") label(2 "Urban-interpolated") label(3 "Rural-interpolated"))

*Replace interpolate with regular 
drop alpha_a1_u alpha_a1_r
ren alpha_a1_u_ip alpha_a1_u
ren alpha_a1_r_ip alpha_a1_r

*Gen A2 and A0 

gen alpha_a2 = max(1,alpha_a1)
gen alpha_a2_u = max(1,alpha_a1_u)
gen alpha_a2_r = max(1,alpha_a1_r)

gen alpha_a0 = 0.5 * (alpha_a1 + alpha_a2)
gen alpha_a0_u = 0.5 * (alpha_a1_u + alpha_a2_u)
gen alpha_a0_r = 0.5 * (alpha_a1_r + alpha_a2_r)

*Graph all three 
twoway line alpha_a1 alpha_a0 alpha_a2 exp_100, legend(row(1)) graphr(c(white)) title("All")

twoway line alpha_a1_u alpha_a0_u alpha_a2_u exp_100, legend(row(1)) graphr(c(white)) title("Urban")

twoway line alpha_a1_r alpha_a0_r alpha_a2_r exp_100, legend(row(1)) graphr(c(white)) title("Rural")



compress 
save "${root}/IDHS_Exp_To_Income_All_Urban_Rural.dta", replace

