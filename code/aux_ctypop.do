// Author:          Oscar Suen
// Date Modified:   08/24/2020
// Description:     Generating county population data

// Reset stata
cap log close
clear all
set more off

// Date last run
local daterun : di %tdCYND daily(c(current_date), "DMY")

// File locations
global root `c(pwd)'
global code $root/code
global raw  $root/data/raw
global log  $root/log
global out  $root/out
global dta  $root/data/dta

// Starts log
log using $log/aux_ctypop_`daterun'.log, text replace

// Input filenames
local pop2000 co-est00int-agesex-5yr.csv
local pop2010 cc-est2019-alldata.csv

// Output filenames
local raw2000 _pop_yearcty2000.dta
local raw2010 _pop_yearcty2010.dta
local yearcty pop_yearcty.dta


* Convert csv to dta
********************************
import delimited $raw/`pop2000', clear

tostring state, replace format("%02.0f")
rename county countyfip
tostring countyfip, replace format("%03.0f")
generate county = state+countyfip

keep county sex agegrp popestimate*
reshape long popestimate, i(county sex agegrp) j(year)

replace county="51019" if county=="51515"
collapse (sum) popestimate, by(county year sex agegrp)
drop if year == 2010

order county year sex agegrp popestimate
sort county year sex agegrp
save $dta/`raw2000', replace



import delimited $raw/`pop2010', clear

tostring state, replace format("%02.0f")
rename county countyfip
tostring countyfip, replace format("%03.0f")
generate county = state+countyfip

keep county year agegrp tot_*
drop if year < 3
replace year = year+2007
reshape long tot_, i(county year agegrp) j(sex_str) string
rename tot_ popestimate

generate byte sex = .
replace sex = 0 if sex_str == "pop"
replace sex = 1 if sex_str == "male"
replace sex = 2 if sex_str == "female"
assert sex != .
drop sex_str

replace county="02270" if county=="02158"
replace county="46113" if county=="46102"

order county year sex agegrp popestimate
sort county year sex agegrp
save $dta/`raw2010', replace



use $dta/`raw2000', clear
append using $dta/`raw2010'
rename popestimate pop

generate sex_str = ""
replace sex_str = "_a" if sex == 0
replace sex_str = "_m" if sex == 1
replace sex_str = "_f" if sex == 2
assert sex_str != ""

generate age_str = ""
replace age_str = "_all" if agegrp == 0
replace age_str = "_0004" if agegrp == 1
replace age_str = "_0509" if agegrp == 2
replace age_str = "_1014" if agegrp == 3
replace age_str = "_1519" if agegrp == 4
replace age_str = "_2024" if agegrp == 5
replace age_str = "_2529" if agegrp == 6
replace age_str = "_3034" if agegrp == 7
replace age_str = "_3539" if agegrp == 8
replace age_str = "_4044" if agegrp == 9
replace age_str = "_4549" if agegrp == 10
replace age_str = "_5054" if agegrp == 11
replace age_str = "_5559" if agegrp == 12
replace age_str = "_6064" if agegrp == 13
replace age_str = "_6569" if agegrp == 14
replace age_str = "_7074" if agegrp == 15
replace age_str = "_7579" if agegrp == 16
replace age_str = "_8084" if agegrp == 17
replace age_str = "_8599" if agegrp == 18
assert age_str != ""

generate grp_str = sex_str + age_str
drop sex agegrp sex_str age_str
reshape wide pop, i(county year) j(grp_str) string

local ages 1524 2534 3544 4554 5564 6599 all 2554 1554 2564 1564
local sexes a m f
foreach sex in `sexes' {
    generate pop_`sex'_1524 = pop_`sex'_1519 + pop_`sex'_2024
    generate pop_`sex'_2534 = pop_`sex'_2529 + pop_`sex'_3034
    generate pop_`sex'_3544 = pop_`sex'_3539 + pop_`sex'_4044
    generate pop_`sex'_4554 = pop_`sex'_4549 + pop_`sex'_5054
    generate pop_`sex'_5564 = pop_`sex'_5559 + pop_`sex'_6064
    generate pop_`sex'_6599 = pop_`sex'_6569 + pop_`sex'_7074 + pop_`sex'_7579 + pop_`sex'_8084 + pop_`sex'_8599
    generate pop_`sex'_2554 = pop_`sex'_2534 + pop_`sex'_3544 + pop_`sex'_4554
    generate pop_`sex'_1554 = pop_`sex'_1524 + pop_`sex'_2554
    generate pop_`sex'_2564 = pop_`sex'_2554 + pop_`sex'_5564
    generate pop_`sex'_1564 = pop_`sex'_1524 + pop_`sex'_2554 + pop_`sex'_5564
}
keep county year pop_*_1524 pop_*_2534 pop_*_3544 pop_*_4554 pop_*_5564  pop_*_6599 pop_*all pop_*_2554 pop_*_1554 pop_*_2564 pop_*_1564
sort county year
order county year pop_a_* pop_m_* pop_f_*
compress

save $dta/`yearcty', replace
erase $dta/`raw2000'
erase $dta/`raw2010'

log close
