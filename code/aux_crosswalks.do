// Author:          Oscar Suen
// Date Modified:   08/24/2020
// Description:     Generate geography crosswalk files

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
log using $log/aux_crosswalks_`daterun'.log, text replace

// Input filenames
local zipcty zipcty.csv
local ctycz ctycz.xls
local pumacty pumacty.csv
local statereg statereg.xls
local ctypop pop_yearcty.dta

// Output filenames
local zip2cty zip2cty_crosswalk.dta
local puma2cty puma2cty_crosswalk.dta
local cty2cz cty2cz_crosswalk.dta
local puma2cz puma2cz_crosswalk.dta
local zip2cz zip2cz_crosswalk.dta
local state2reg state2reg_crosswalk.dta
local cz2state cz2state_crosswalk.dta

********************************
* Generate crosswalks          *
********************************

* ZIP3 -> County
********************************
import delimited $raw/`zipcty', varnames(1) rowrange(3) stringcols(1 2 3 4) numericcols(5 6) clear
recast str5 zcta5
recast str5 county
rename zcta5 zip5
drop cntyname zipname
generate zip3 = substr(zip5,1,3)
bysort zip5 : egen zip5pop=total(pop2k)
bysort zip3 : egen zip3pop=total(pop2k)
generate alpha = zip5pop/zip3pop
generate beta = pop2k/zip5pop
generate gamma = alpha * beta
collapse (sum) gamma, by(zip3 county)
save $dta/`zip2cty', replace

* PUMA2000 -> County
********************************
import delimited $raw/`pumacty', varnames(1) rowrange(3) stringcols(3 4 5) numericcols(1 2 6 7) clear
recast str5 county
generate puma2k = (10000*state) + puma5
bysort puma2k : egen pumapop=total(pop2k)
generate alpha = pop2k/pumapop
keep puma2k county alpha
save $dta/`puma2cty', replace

* County -> Commuting Zone
********************************
import excel using $raw/`ctycz', clear firstrow
rename FIPS county
rename CommutingZoneID2000 cz
keep county cz
save $dta/`cty2cz', replace

* PUMA2000 -> Commuting Zone
********************************
use $dta/`puma2cty', clear
merge m:1 county using $dta/`cty2cz'
collapse (sum) alpha, by(puma2k cz)
save $dta/`puma2cz', replace

* ZIP3 -> Commuting Zone
********************************
use $dta/`zip2cty', clear
merge m:1 county using $dta/`cty2cz'
collapse (sum) gamma, by(zip3 cz)
save $dta/`zip2cz', replace

* State -> Census Region
*******************************
import excel $raw/`statereg', clear cellrange(A7)
rename A region
rename B division
rename C state
drop D
drop if state=="00"
order state, first
sort state
save $dta/`state2reg', replace

* Commuting Zone -> State
********************************
use $dta/`ctypop', clear
keep if year==2003
keep county pop_a_all
rename pop_a_all pop
replace county="08001" if county=="08014" // new county in CO
// Alaska county changes
replace county="02232" if county=="02230" | county=="02105"
replace county="02280" if county=="02195"
replace county="02201" if county=="02198"
replace county="02280" if county=="02275" // moved new county into old

merge m:1 county using $dta/`cty2cz'
list if _merge != 3
drop if _merge != 3
drop _merge
generate state = substr(county, 1, 2)

collapse (sum) pop, by(cz state)
replace pop=-pop
sort cz pop
collapse (first) state, by(cz)

save $dta/`cz2state', replace


log close
