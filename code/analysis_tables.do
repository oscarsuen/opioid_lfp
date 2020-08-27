// Author:          Oscar Suen
// Date Modified:   08/24/2020
// Description:     Generate tables

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
global out  $root/out/tabs
global dta  $root/data/dta

// Starts log
log using $log/analysis_tables_`daterun'.log, text replace

// Input filenames
local estimates estimates.sters

// Output filenames
local firststagetable main_firststage.tex
local tslstable main_tsls.tex
local outcomestable main_outcomes.tex
local agetable main_age.tex
local gendertable main_gender.tex
local racetable main_race.tex
local eductable main_educ.tex


* Generate Tables
********************************
estread * using $out/`estimates'

local firststage firststage_czdivyr firststage_simpleunw firststage_czyr firststage_czdivyrunw firststage_czstateyr firststage_timetrend

// First Stage
esttab `firststage' using $out/`firststagetable', replace b(a2) se(a2) keep(instrument) indicate(Year FE = _Iyear_*) stats(ivar wtype r2_a N, labels("CZ FE" "Weighted" "\$\bar{R}^2\$" "\$N\$")) nomtitle star(* 0.05 ** 0.01)

// OLS v Reduced v 2SLS
capture erase $out/`tslstable'
foreach var in lfp unemp lgrlinc noincome {
    esttab *_`var'_2554_ using $out/`tslstable', append b(a2) se(a2) keep(opioid_rate instrument) stats(r2_a N, labels("\$\bar{R}^2\$" "\$N\$")) star(* 0.05 ** 0.01)
}

// Outcomes
capture erase $out/`outcomestable'
foreach var in lfp unemp lgrlinc noincome {
    local tempests ivr_`var'_1664_ ivr_`var'_1654_ ivr_`var'_2564_ ivr_`var'_2554_
    esttab `tempests' using $out/`outcomestable', append b(a2) se(a2) keep(opioid_rate) stats(r2_a N, labels("\$\bar{R}^2\$" "\$N\$")) star(* 0.05 ** 0.01)
}

// By Age
capture erase $out/`agetable'
foreach var in lfp unemp lgrlinc noincome {
    esttab ivr_`var'_*_age using $out/`agetable', append b(a2) se(a2) keep(opioid_rate) stats(r2_a N, labels("\$\bar{R}^2\$" "\$N\$")) star(* 0.05 ** 0.01)
}

// By Gender
capture erase $out/`gendertable'
foreach var in lfp unemp lgrlinc noincome {
    esttab ivr_`var'_2554_sex_* using $out/`gendertable', append b(a2) se(a2) keep(opioid_rate) stats(r2_a N, labels("\$\bar{R}^2\$" "\$N\$")) star(* 0.05 ** 0.01)
}


log close

