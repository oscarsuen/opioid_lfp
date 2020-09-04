// Author:          Oscar Suen
// Date Modified:   08/24/2020
// Description:     Generate opioid panel

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
log using $log/arcos_clean_`daterun'.log, text replace

// Input filenames
local raw_csv prescriptions.csv
local zip2cz zip2cz_crosswalk.dta
local czpop pop_yearcz.dta

// Output filenames
local temp _temp_opioids.dta
local raw_prescriptions _prescriptions_raw.dta
local raw_panel_count _qtrcz_count_raw.dta
local opioids_year opioid_yearcz.dta
local opioids_qtr opioid_qtrcz.dta


********************************
* Generate Panel               *
********************************

import delimited using $raw/`raw_csv', clear 
rename zipcode zip
tostring zip, replace format("%03.0f")

save $dta/`raw_prescriptions', replace

collapse (sum) q*, by(year zip drugcode) // TODO: balance panel
reshape long q, i(year zip drugcode) j(qtr)
rename q weight
generate int quarter = yq(year, qtr)
format quarter %tq
drop year

// TODO: investigate zips
// Puerto Rico
drop if zip=="006" | zip=="007" | zip=="008" | zip=="009"

// Replacing in same city
replace zip="191" if zip=="192" // Philly
replace zip="200" if zip=="202" | zip=="204" | zip=="205" // DC
replace zip="303" if zip=="311" // Atlanta
replace zip="331" if zip=="332" // Miami

// Not in use? investigate.
drop if zip=="345"
drop if zip=="353"

// Replacing in same city
replace zip="381" if zip=="375" // Memphis
replace zip="317" if zip=="398" // Albany, GA (weird)

// Not in use? investigate.
drop if zip=="702"

// Replacing in same city
replace zip="752" if zip=="753" // Dallas
replace zip="770" if zip=="772" // Houston
replace zip="850" if zip=="851" // Phoenix
replace zip="900" if zip=="901" // LA (weird)
replace zip="937" if zip=="938" // Fresno
replace zip="958" if zip=="942" // Sacramento

// Military? investigate.
drop if zip=="962"
drop if zip=="965"

// Guam
drop if zip=="969"

// Opioids
// Hydrocodone, Hydromorphone, Meperidine, Morphine, Oxycodone
keep if drugcode=="9120" | drugcode=="9193" | drugcode=="9150" | drugcode=="9220L" | drugcode=="9230" | drugcode=="9300" | drugcode=="9143"

// TODO: panel with only Hydrocodone and Oxycodone
generate mme = .
replace mme = 0.25 if drugcode=="9120" // Dihydrocodeine
replace mme = 1 if drugcode=="9193" // Hydrocodone
replace mme = 4 if drugcode=="9150" // Hydromorphone
replace mme = 11 if drugcode=="9220L" // Levorphanol
replace mme = 0.1 if drugcode=="9230" // Meperidine
replace mme = 1 if drugcode=="9300" // Morphine
replace mme = 1.5 if drugcode=="9143" // Oxycodone
assert mme != .

generate grams = weight * mme

collapse (sum) grams, by(zip quarter)

rename zip zip3

joinby zip3 using $dta/`zip2cz', unmatched(both)
tabulate quarter _merge if _merge != 3
drop if _merge == 2
drop _merge

collapse (sum) grams [pw=gamma], by(cz quarter)

save $dta/`raw_panel_count', replace

generate int year = yofd(dofq(quarter))
joinby year cz using $dta/`czpop', unmatched(both)
tab quarter _merge if _merge != 3
keep if _merge == 3
generate percap = grams/pop_a_all
save $dta/`temp', replace
keep quarter cz percap grams
xtset cz quarter
save $dta/`opioids_qtr', replace

use $dta/`temp', clear
collapse (sum) grams (first) pop_a_all, by(cz year)
generate percap = grams/pop_a_all
keep year cz percap grams
xtset cz year
save $dta/`opioids_year', replace
erase $dta/`temp'

log close
