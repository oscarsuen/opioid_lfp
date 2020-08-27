// Author:          Oscar Suen
// Date Modified:   08/24/2020
// Description:     Generate CPI dta

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
log using $log/aux_cpi_`daterun'.log, text replace

// Input filenames
local inflation_raw CPILFESL.csv

// Output filenames
local year cpi_year.dta
local quarter cpi_quarter.dta

* Generate CPI dta file
********************************
import delimited $raw/`inflation_raw', clear
rename cpilfesl cpi
generate date2 = date(date, "YMD")
drop date
rename date2 date
generate year = yofd(date)
format year %ty
generate quarter = qofd(date)
format quarter %tq
order year quarter, first

save temp_cpi.dta, replace

keep quarter cpi
save $dta/`quarter', replace

use temp_cpi.dta, clear
collapse (mean) cpi, by(year)
save $dta/`year', replace

erase temp_cpi.dta

log close
