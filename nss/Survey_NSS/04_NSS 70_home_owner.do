use "${root}\Data Output Files\NSS70_All.dta",clear

gen home_owner = (building_dwelling > 0)*100
table urban [aw = hhwgt],c(mean home_owner) 

gen home_price = building_dwelling/building_dwelling_area

sum building_dwelling [aw = hhwgt],de
sum home_price [aw = hhwgt],de
