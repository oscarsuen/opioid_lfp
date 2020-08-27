// Author:          Oscar Suen
// Date Modified:   08/24/2020
// Description:     Generate QWI {yr,qtr}/cz panel

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
log using $log/qwi_clean_`daterun'.log, text replace

// Input filenames
local raw_csv qwi.csv
local cty2cz cty2cz_crosswalk.dta
local czpop pop_yearcz.dta

// Output filenames
local temp _temp_qwi.dta
local long_panel _qwi_long.dta
local county_panel _qwi_cty.dta
local yearcz_panel qwi_yearcz.dta
local qtrcz_panel qwi_qtrcz.dta


********************************
* Generate Panel               *
********************************

import delimited using $raw/`raw_csv', clear 

replace county = state * 1000 + county
tostring county, replace format("%05.0f")
drop state

generate quarter = quarterly(time, "YQ")
format quarter %tq
drop time

save $dta/`long_panel', replace

joinby quarter using $dta/`inflation', unmatched(both)
tabulate quarter _merge if _merge != 3
drop if _merge == 2
assert _merge == 3
drop _merge

generate realinc = earnbeg * cpi/247.5851 // Constant 2016 USD
generate lgrlinc = log(realinc)

generate sex_str = ""
replace sex_str = "_a" if sex == 0
replace sex_str = "_m" if sex == 1
replace sex_str = "_f" if sex == 2
drop sex

generate age_str = ""
replace age_str = "_all" if agegrp == "A00"
replace age_str = "_1418" if agegrp == "A01"
replace age_str = "_1921" if agegrp == "A02"
replace age_str = "_2224" if agegrp == "A03"
replace age_str = "_2534" if agegrp == "A04"
replace age_str = "_3544" if agegrp == "A05"
replace age_str = "_4554" if agegrp == "A06"
replace age_str = "_5564" if agegrp == "A07"
replace age_str = "_6599" if agegrp == "A08"
drop agegrp

generate grp_str = sex_str + age_str
drop sex_str age_str
reshape wide emp realinc lgrlinc, i(county quarter) j(grp_str) string

// County changes
replace county="08001" if county=="08014" // new county in CO
// Alaska county changes
replace county="02232" if county=="02230" | county=="02105"
replace county="02280" if county=="02195"
replace county="02201" if county=="02198"
replace county="02280" if county=="02275" // moved new county into old

collapse (sum) emp_* realinc_* lgrlinc_*, by(county quarter)
xtset county quarter

local sexes a m f
foreach sex in `sexes' {
    generate emp_`sex'_2554 = emp_`sex'_2534 + emp_`sex'_3544 + emp_`sex'_4554
    // replace 14->15 (unlikely to be many 14yos)
    generate emp_`sex'_1524 = emp_`sex'_1418 + emp_`sex'_1921 + emp_`sex'_2224
    generate emp_`sex'_1554 = emp_`sex'_1524 + emp_`sex'_2554
    generate emp_`sex'_2564 = emp_`sex'_2554 + emp_`sex'_5564
    generate emp_`sex'_1564 = emp_`sex'_1524 + emp_`sex'_2554 + emp_`sex'_5564
}
local vars realinc lgrlinc
foreach var in `vars' {
    foreach sex in `sexes' {
        generate `var'_`sex'_2554 = (`var'_`sex'_2534*emp_`sex'_2534 + `var'_`sex'_3544*emp_`sex'_3544 + `var'_`sex'_4554*emp_`sex'_4554) / emp_`sex'_2554
        generate `var'_`sex'_1524 = (`var'_`sex'_1418*emp_`sex'_1418 + `var'_`sex'_1921*emp_`sex'_1921 + `var'_`sex'_2224*emp_`sex'_2224) / emp_`sex'_1424
        generate `var'_`sex'_1554 = (`var'_`sex'_1524*emp_`sex'_1524 + `var'_`sex'_2554*emp_`sex'_2554) / emp_`sex'_2554
        generate `var'_`sex'_2564 = (`var'_`sex'_2554*emp_`sex'_2554 + `var'_`sex'_5564*emp_`sex'_5564) / emp_`sex'_2564
        generate `var'_`sex'_1564 = (`var'_`sex'_1524*emp_`sex'_1524 + `var'_`sex'_2554*emp_`sex'_2554 + `var'_`sex'_5564*emp_`sex'_5564) / emp_`sex'_1464
    }
}

drop *_1418 *_1921 *_2224
save $dta/`county_panel', replace

local ages 1524 2534 3544 4554 5564 6599 all 2554 1554 2564 1564

joinby county using $dta/`cty2cz', unmatched(both)
tabulate county _merge if _merge != 3
drop if _merge == 2
assert _merge == 3
drop _merge

collapse (mean) emp_* realinc_* lgrlinc_*, by(cz quarter)

generate year = yofd(dofq(quarter))
drop if year < 2000 // TODO: extend analysis

joinby cz year using $dta/`czpop', unmatched(both)
tabulate year _merge if _merge != 3
drop if _merge == 2
assert _merge == 3
drop _merge

foreach sex in `sexes' {
    foreach age in `ages' {
        generate epop_`sex'_`age' = emp_`sex'_`age' / pop_`sex'_`age'
    }
}

save $dta/`temp', replace

keep cz quarter epop_* realinc_* lgrlinc_*
order cz quarter epop_* realinc_* lgrlinc_*
xtset cz quarter
save $dta/`qtrcz_panel', replace

use $dta/`temp', clear
collapse (mean) epop_* realinc_* lgrlinc_*, by(cz year)
order cz year epop_* realinc_* lgrlinc_*
xtset cz year
save $dta/`yearcz_panel', replace

erase $dta/`temp'

log close
