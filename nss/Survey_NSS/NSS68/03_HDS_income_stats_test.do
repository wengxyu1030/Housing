
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
if `pc' == 0 global root "C:\Users\wb308830\OneDrive - WBG\Documents\TN\Data\NSS 68\" //please correct accordingly
if `pc' != 0 global root "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\nss_data\NSS68"
if `pc' != 0 global script "C:\Users\wb500886\OneDrive - WBG\7_Housing\survey_all\Housing_git\nss\Survey_NSS\NSS68"

di "$root"
global r_input "${root}\Raw Data & Dictionaries"
di "${r_input}"
global r_output "${root}\Data Output Files"
di "${r_output}"

set more off 
clear 

putpdf begin
*******************************************
*******Estimate income expenditure ratio
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

//per capita expenditure and its log
gen exp_ind = exp/npersons 
gen exp_ind_ln = ln(exp_ind)

//per capita income and its log
gen income_ind = income/npersons
gen income_ind_ln = ln(income_ind)

//label the variables
label var income "Income(Household)"
label var income_ind "Income(Per Capita)"
label var income_ind_ln "Log Income(Per Capita)"

label var exp "Expenditure(Household)"
label var exp_ind "Expenditure(Per Capita)"
label var exp_ind_ln "Log Expenditure(Per Capita)"

label var npersons "Household Size"

*********the relation between income and exp (regression by quintile)*************
foreach i in 5 10 100 {
xtile exp_p_`i' = exp [aw = indwt],n(`i')
}

forvalues i = 1/5 {
 qui reg income_ind exp_ind  [aw = indwt] if exp_p_5 == `i', noconstant
 eststo q`i'
}

//regression result table 
 esttab q1 q2 q3 q4 q5, nose not label b("%9.2f") r2 ///
 stats(N r2 , label(Observations R2 ) fmt( %9.0gc %9.0gc %9.2f)) ///
 title("Regression of Income on Expenditure by Decile") ///
 addnotes("Regressions are weighted by survey weights.")

//scatter plot: income and expenditure median by percentile.
foreach var in exp income {
egen `var'_ind_med = median(`var'_ind),by(exp_p_100)
}
label var income_ind_med "Med. Income(Per Capita)"
label var exp_ind_med "Med. Expenditure(Per Capita)"

scatter income_ind_med exp_ind_med exp_p_100,msize(tiny tiny) ///
title("1. Median of Income and Expenditure by Exp. Percentile (All)",size(12pt)) 
graph export "${r_output}\scatter_1.png", replace
putpdf paragraph, halign(center)
putpdf image "${r_output}\scatter_1.png"

scatter income_ind_med exp_ind_med exp_p_100 if urban2011 == 1,msize(tiny tiny) ///
title("2. Median of Income and Expenditure by Exp. Percentile (Urban)",size(12pt)) 
graph export  "${r_output}\scatter_2.png", replace
putpdf paragraph, halign(center)
putpdf image  "${r_output}\scatter_2.png"

*********the relation between income and exp (regression)*************

**scatter of the log Expenditure and income
scatter income_ind_ln exp_ind_ln, msize(tiny)

**linear model 
 reg income_ind exp_ind [aw = indwt] 
 eststo reg_1 //linear with absolute value

 reg income_ind_ln exp_ind_ln [aw = indwt]
 eststo reg_2 //linear with log value

/*
centile exp [aw = indwt], c(10 90) //centile can not be weighted
return list
*/
 sum exp_ind_ln [aw = indwt],de
 reg income_ind_ln exp_ind_ln [aw = indwt] if inrange(exp_ind_ln, r(p10), r(p90))
 eststo reg_3  //remove expenditure outlier

 sum income_ind_ln [aw = indwt],de
 reg income_ind_ln exp_ind_ln [aw = indwt] if inrange(income_ind_ln, r(p10), r(p90))
 eststo reg_4 //remove income outlier

 sum income_ind_ln [aw = indwt],de
 gen income_lb = r(p10)
 gen income_ub = r(p90)
 sum exp_ind_ln [aw = indwt],de
 gen exp_lb = r(p10)
 gen exp_ub = r(p90)
 sum income_lb income_ub exp_lb exp_ub

 reg income_ind_ln exp_ind_ln [aw = indwt] if inrange(income_ind_ln,income_lb,income_ub) & inrange(exp_ind_ln,exp_lb,exp_ub)
 eststo reg_5 //remove both income and expenditure outlier. 
 
 predict fitted
 scatter income_ind_ln exp_ind_ln,msize(tiny) || line fitted exp_ind_ln

 esttab reg_1 reg_2 reg_3 reg_4 reg_5, nose not label b("%9.2f") r2 ///
 stats(N r2 , label(Observations R2 ) fmt( %9.0gc %9.0gc %9.2f)) ///
 title("Regression of Income on Expenditure") ///
 nonumbers mtitles("Linear" "Log Linear" "Excl. Exp. Outlier""Excl. Income Outliner""Excl. both Outliner") ///
 addnotes("Regressions are weighted by survey weights.")
 
**model with square and cubic terms
foreach var in exp_ind_ln exp_ind {
gen `var'2 = `var'^2
gen `var'3 = `var'^3
}

 reg income_ind exp_ind2 exp_ind3 [aw = indwt] if urban2011 == 1
 eststo reg_1 //absolute value 
 
 reg income_ind_ln exp_ind_ln exp_ind_ln2 exp_ind_ln3 [aw = indwt] if urban2011 == 1
 eststo reg_2 //log on both side
 
 sum exp_ind_ln [aw = indwt],de
 reg income_ind_ln exp_ind_ln exp_ind_ln2 exp_ind_ln3 [aw = indwt] if inrange(exp_ind_ln, r(p10), r(p90)) & urban2011 == 1
 eststo reg_3  //remove expenditure outlier

 sum income_ind_ln [aw = indwt],de
 reg income_ind_ln exp_ind_ln exp_ind_ln2 exp_ind_ln3 [aw = indwt] if inrange(income_ind_ln, r(p10), r(p90)) & urban2011 == 1
 eststo reg_4 //remove income outlier
 
 reg income_ind_ln exp_ind_ln exp_ind_ln2 exp_ind_ln3 [aw = indwt] if inrange(income_ind_ln,income_lb,income_ub) & inrange(exp_ind_ln,exp_lb,exp_ub) & urban2011 == 1
 eststo reg_5 //remove both income and expenditure outlier. 
 predict fitted_poly
 scatter income_ind_ln exp_ind_ln,msize(tiny) || scatter fitted_poly exp_ind_ln
 
 esttab reg_1 reg_2 reg_3 reg_4 reg_5, nose not label b("%9.2f") r2 ///
 stats(N r2 , label(Observations R2 ) fmt( %9.0gc %9.0gc %9.2f)) ///
 title("Regression of Income on Expenditure (Square and Cubic Term)") ///
 nonumbers mtitles("Linear" "Polynomial" "Excl. Exp. Outlier""Excl. Income Outliner""Excl. both Outliner") ///
 addnotes("Regressions are weighted by survey weights.") 
 

 
*********the relation between income and exp (descriptive stats)*********
gen exp_in = exp_ind/income_ind

//table by quintile
table exp_p_10 [aw = indwt],c(mean exp_in med exp_in sd exp_in) row //all India
table exp_p_10 [aw = indwt]  if urban2011 == 1 ,c(mean exp_in med exp_in sd exp_in) row //urban only

//box plot
gen exp_in_ln = ln(exp_in)

graph box exp_in_ln [aw=indwt],over(exp_p_10) m(1,msize(tiny)) ///
title("3. Log of Exp. to Income. Ratio by Decile (All)",size(12pt)) ///
ytitle("Log Exp. to Income Ratio") yline(0, lcolor(red)) 
graph export  "${r_output}\box_3.png", replace
putpdf paragraph, halign(center)
putpdf image  "${r_output}\box_3.png"

egen exp_in_med_100 = median(exp_in),by(exp_p_100)
graph box exp_in_ln [aw=indwt] if urban2011 == 1,over(exp_p_10) m(1,msize(tiny)) ///
title("4. Log of Exp. to Income. Ratio by Decile (Urban)",size(12pt)) ///
ytitle("Log Exp. to Income Ratio") yline(0, lcolor(red)) 

graph export  "${r_output}\box_4.png", replace
putpdf paragraph, halign(center)
putpdf image  "${r_output}\box_4.png"

graph box exp_in_ln [aw=indwt] if urban2011 == 1,over(exp_p_100) m(1,msize(tiny)) ///
medtype(marker) medmarker(msymbol(diamond) msize(tiny)) yline(0, lcolor(blue)) ///
title("5. Log Exp. to Income. Ratio by Percentile (Urban)",size(12pt)) ///
ytitle("Log Exp. to Income Ratio")

graph export  "${r_output}\box_5.png", replace
putpdf paragraph, halign(center)
putpdf image  "${r_output}\box_5.png"

save "${r_output}\hds",replace

*********the relation between income and exp (med for each percentile)*********
//get the median hh level urban income to exp ratio by percentile
preserve

collapse (median) exp_in [aw = indwt] if urban2011 == 1,by(exp_p_100) //egen with weight for median to be discussed. 
rename (exp_p_100 exp_in) (exp_p hat_ei_u)
save "${r_output}\hat_ie_u",replace

restore

//get the percentile for income and expenditure separately, and mathing the percentiles to get the ratio (not at hh level but percentile, assume income and exp positively correlated and linear)
xtile income_p = income[aw=indwt],n(100)
xtile exp_p= exp [aw=indwt],n(100)

gen income_ln = ln(income)
gen exp_ln = ln(exp)

kdensity income_ln
twoway kdensity income_ln [aw=indwt] || kdensity exp_ln [aw=indwt], title(Income and Expenditure by Percentile) 

tempfile income exp

preserve
keep income income_p indwt
collapse (mean) income [aw=indwt],by(income_p)
rename income_p decile
save `income'
restore

preserve
keep exp exp_p indwt
collapse (mean) exp [aw=indwt],by(exp_p)
rename exp_p decile
save `exp',replace
restore

use `income',clear
merge 1:1 decile using `exp'
gen e_i = exp/income
drop _merge
rename decile exp_p

scatter e_i exp_p
replace e_i = (1+e_i)/2 if e_i<1 //assumption for households with income lower than expenditure. 

keep exp_p e_i
rename e_i hat_ei

save "${r_output}\hat_ie",replace

//compare the two hat_ie (all at percentile level and urban at hh level )
use  "${r_output}\hat_ie",clear
merge 1:1 exp_p using "${r_output}\hat_ie_u"
label var hat_ei_u "Urban Per Capita Level"
label var hat_ei "All Percentile Level"
label var exp_p "Exp. Percentile Level"
scatter  hat_ei hat_ei_u exp_p,title("6. Exp. to Income Ratio by Percentile (Compare Dif. Methods)")

graph export  "${r_output}\scatter_6.png", replace
putpdf paragraph, halign(center)
putpdf image  "${r_output}\scatter_6.png"

*********compare the HDS and NSS on expenditure*********
use "${r_output}\hds",clear

rename urban2011 urban
rename indwt pwt
gen mpce_hds =  exp_ind/12 //convert the annual exp to month per capita exp. 

keep mpce_hds urban pwt

append using "${r_input}\poverty68.dta"
replace urban = sector - 1 if urban == .
rename mpce_mrp mpce_nss

keep mpce_nss mpce_hds urban pwt 
sum mpce_nss mpce_hds

foreach survey in nss hds {
gen mpce_`survey'_ln = ln(mpce_`survey')
}

twoway kdensity mpce_nss_ln [aw=pwt] || kdensity mpce_hds_ln [aw=pwt], title(7. Log Exp. for NSS and HDS (All)) 
graph export  "${r_output}\kdensity_7.png", replace
putpdf paragraph, halign(center)
putpdf image  "${r_output}\kdensity_7.png"

twoway kdensity mpce_nss_ln [aw=pwt] if urban == 1|| kdensity mpce_hds_ln [aw=pwt] if urban == 1, title(8. Log Exp. for NSS and HDS (Urban) ) 
graph export  "${r_output}\kdensity_8.png", replace
putpdf paragraph, halign(center)
putpdf image  "${r_output}\kdensity_8.png"

qqplot mpce_nss_ln mpce_hds_ln, title("9. Quantile-Quantile Plot (All)")
graph export  "${r_output}\qq_9.png", replace
putpdf paragraph, halign(center)
putpdf image  "${r_output}\qq_9.png"

qqplot mpce_nss_ln mpce_hds_ln if urban == 1, title("10.Quantile-Quantile Plot (Urban)")
graph export  "${r_output}\qq_10.png", replace
putpdf paragraph, halign(center)
putpdf image  "${r_output}\qq_10.png"


putpdf save "${r_output}\income_exp_figues.pdf", replace
