// Author:          Oscar Suen
// Date Modified:   08/24/2020
// Description:     Generate binscatter graph

// Reset stata
cap log close
clear all
set more off

set maxvar 20000

// Date last run
local daterun : di %tdCYND daily(c(current_date), "DMY")

// File locations
global root `c(pwd)'
global code $root/code
global raw  $root/data/raw
global log  $root/log
global out  $root/out/figs
global dta  $root/data/dta

// Export graph filetype
global expt ".pdf"

// Starts log
log using $log/analysis_binscatter_`daterun'.log, text replace

// Input filenames
local workfile workfile.dta

// Output filenames
local binscatter binscatter


* Generate Graphs
********************************
use $dta/`workfile', clear
binscatter opioid_rate instrument [aw=popwt03], controls(i.divisionyear) absorb(cz) xtitle("Instrument") ytitle("Opioid Rate")
graph save $out/`binscatter', replace
graph export $out/`binscatter'$expt, replace


log close

