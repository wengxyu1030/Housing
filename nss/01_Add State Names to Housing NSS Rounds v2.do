*------------"------------------------------------------------*
*
* Date:7/30/2020
* Desription: Fix state codes and apply state labels
*------------------------------------------------------------*

*------------------------------------------------------------*
* BASE
*------------------------------------------------------------*


destring id_survey hh_sector hh_state, replace

gen hh_state49 = hh_state if id_survey == 49

replace hh_state =28 if hh_state49 ==2 & id_survey == 49
replace hh_state =12 if hh_state49 ==3 & id_survey == 49
replace hh_state =18 if hh_state49 ==4 & id_survey == 49
replace hh_state =10 if hh_state49 ==5 & id_survey == 49
replace hh_state =30 if hh_state49 ==6 & id_survey == 49
replace hh_state =24 if hh_state49 ==7 & id_survey == 49
replace hh_state =6 if hh_state49 ==8 & id_survey == 49
replace hh_state =2 if hh_state49 ==9 & id_survey == 49
replace hh_state =1 if hh_state49 ==10 & id_survey == 49
replace hh_state =29 if hh_state49 ==11 & id_survey == 49
replace hh_state =32 if hh_state49 ==12 & id_survey == 49
replace hh_state =23 if hh_state49 ==13 & id_survey == 49
replace hh_state =27 if hh_state49 ==14 & id_survey == 49
replace hh_state =14 if hh_state49 ==15 & id_survey == 49
replace hh_state =17 if hh_state49 ==16 & id_survey == 49
replace hh_state =15 if hh_state49 ==17 & id_survey == 49
replace hh_state =13 if hh_state49 ==18 & id_survey == 49
replace hh_state =21 if hh_state49 ==19 & id_survey == 49
replace hh_state =3 if hh_state49 ==20 & id_survey == 49
replace hh_state =8 if hh_state49 ==21 & id_survey == 49
replace hh_state =11 if hh_state49 ==22 & id_survey == 49
replace hh_state =33 if hh_state49 ==23 & id_survey == 49
replace hh_state =16 if hh_state49 ==24 & id_survey == 49
replace hh_state =9 if hh_state49 ==25 & id_survey == 49
replace hh_state =19 if hh_state49 ==26 & id_survey == 49
replace hh_state =35 if hh_state49 ==27 & id_survey == 49
replace hh_state =4 if hh_state49 ==28 & id_survey == 49
replace hh_state =26 if hh_state49 ==29 & id_survey == 49
replace hh_state =25 if hh_state49 ==30 & id_survey == 49
replace hh_state =7 if hh_state49 ==31 & id_survey == 49
replace hh_state =31 if hh_state49 ==32 & id_survey == 49
replace hh_state =34 if hh_state49 ==33 & id_survey == 49

gen hh_state76 = hh_state if id_survey == 76
replace hh_state = 28 if hh_state76 == 36 & id_survey == 76

label define state 28 "Andhra Pardesh", add
label define state 12 "Arunachal Pradesh", add
label define state 18 "Assam", add
label define state 10 "Bihar", add
label define state 30 "Goa", add
label define state 24 "Gujarat", add
label define state 6 "Haryana", add
label define state 2 "Himachal Pradesh", add
label define state 1 "Jammu & Kashmir", add
label define state 29 "Karnataka", add
label define state 32 "Kerala", add
label define state 23 "Madhya Pradesh", add
label define state 27 "Maharastra", add
label define state 14 "Manipur", add
label define state 17 "Meghalaya", add
label define state 15 "Mizoram", add
label define state 13 "Nagaland", add
label define state 21 "Orissa", add
label define state 3 "Punjab", add
label define state 8 "Rajasthan", add
label define state 11 "Sikkim", add
label define state 33 "Tamil Nadu", add
label define state 16 "Tripura", add
label define state 9 "Uttar Pradesh", add
label define state 19 "West Bengal", add
label define state 35 "Andaman & Nicober", add
label define state 4 "Chandigarh", add
label define state 26 "Dadra & Nagar Haveli", add
label define state 25 "Daman & Diu", add
label define state 7 "Delhi", add
label define state 31 "Lakshadweep", add
label define state 34 "Pondicheri", add
label define state 22 "Chhattisgarh", add
label define state 20 "Jharkhand", add
label define state 5 "Uttaranchal", add
label define state 36 "Telangana", add

label values hh_state state

drop hh_tn 
gen hh_tn = hh_state == 33

drop hh_state49
drop hh_state76

compress





