

local l = 100000
local r = 0.10 // annual  
local n = 120  // months 

local pmt =  (`l' * `r'/12) / (1 - (1+`r'/12)^-`n')

di `pmt'
