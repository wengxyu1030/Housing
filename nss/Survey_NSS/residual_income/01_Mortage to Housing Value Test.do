

* Code to replicate monthly of $1000 for 1 year (12 months) at 0.4% monthly (4.8% annual) to get NPV of 11,693.74 

global term = 12
global rate = 0.004 
global cf = 1000

local npv = $cf * (1 - ((1+$rate)^-$term)) / $rate

di `npv'

* Using RIA approach. mean interest 11%, mean of term = 108 months (9 years)

clear
set obs 1
gen own_ria_1_hh = 5000

global rate = (1+0.11)^(1/12) - 1 
di ${rate}
global term = 108 
global ltv = 0.7

gen max_loan = own_ria_1_hh * (1 - ((1+$rate)^-$term)) / $rate
gen max_hse_val = max_loan / $ltv

format max_hse_val max_loan %15.0fc
list

**** TO DO - RIA 
* 1. Think about HH types, get 70% or more, just divide into adults / children, quick k means / modes 
* 2. Adding housing values for owners 
* 3. Clean up tables for logic presentation 
* 4. Rural? 
* 5. Repeat above for income 
* 6. produce graphs in USD, think about labeling x axis with percentile or quartiles "5,000 (p25)" / logs? / vertical lines 
