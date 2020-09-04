// Author:          Oscar Suen
// Date Modified:   08/24/2020
// Description:     Event study analysis

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
global figs $root/out/figs
global tabs $root/out/tabs
global dta  $root/data/dta

// Export graph filetype
global expt ".pdf"

// Starts log
log using $log/analysis_event_`daterun'.log, text replace

// Input filenames
local workfile_qtr workfile_quarter.dta
local workfile_yr workfile_year.dta

// Output filenames
local event_workfile _workfile_event.dta
local firststage_raw_qtr event_fs_qtr
local firststage_adj_qtr event_fs_adj_qtr
local reducedform_qtr event_rf_qtr
local firststage_raw_yr event_fs_yr
local firststage_adj_yr event_fs_adj_yr
local reducedform_yr event_rf_yr
local longdifftable table_longdiff.tex


********************************
* QUARTERLY                    *
********************************
use $dta/`workfile_qtr', clear

global beginqtr 160 // 2000q1
global endqtr 239 // 2019q4
keep if $beginqtr <= quarter & quarter <= $endqtr
forvalues qtr = $beginqtr/$endqtr {
    generate inst_`qtr' = sh_elderly03 * (quarter == `qtr')
}
global baseqtr 183 // 2005q4
drop inst_$baseqtr

save $dta/`event_workfile', replace

program quartergraph
    statsby _b _se, clear by(): regress
    keep _b_inst_* _se_inst_*
    generate tmp = 1
    reshape long _b_inst_ _se_inst_, i(tmp) j(quarter)
    drop tmp

    tset quarter, quarterly
    rename _b_inst_ b
    rename _se_inst_ se

    local new = _N + 1
    set obs `new'
    replace quarter=$baseqtr in `new'
    replace b=0 in `new'
    replace se=0 in `new'
    sort quarter

    generate ci_l = b - 1.96*se
    generate ci_h = b + 1.96*se

    graph twoway (scatter b quarter, connect(direct)) || (rcap ci_l ci_h quarter), legend(off) xtitle("Quarter")
end

* Graphs
********************************
use $dta/`event_workfile', clear
quietly xi: xtreg opioid_rate inst_* i.divqtr [w=popwt03], fe cluster(cz)
quartergraph
graph export $figs/`firststage_raw_qtr'$expt, replace

use $dta/`event_workfile', clear
generate timetrend = sh_elderly03 * quarter
quietly xi: xtreg opioid_rate inst_* i.divqtr timetrend [w=popwt03], fe cluster(cz)
quartergraph
graph export $figs/`firststage_adj_qtr'$expt, replace

use $dta/`event_workfile', clear
quietly xi: xtreg epop_a_2554 inst_* i.divqtr [w=popwt03] if consistent_sample, fe cluster(cz)
quartergraph
graph export $figs/`reducedform_qtr'$expt, replace


********************************
* YEARLY                       *
********************************
use $dta/`workfile_yr', clear

global beginyr 2000
global endyr 2019
keep if $beginyr <= year & year <= $endyr
forvalues yr = $beginyr/$endyr {
    generate inst_`yr' = sh_elderly03 * (year == `yr')
}
global baseyr 2005
drop inst_$baseyr

save $dta/`event_workfile', replace

program yeargraph
    statsby _b _se, clear by(): regress
    keep _b_inst_* _se_inst_*
    generate tmp = 1
    reshape long _b_inst_ _se_inst_, i(tmp) j(year)
    drop tmp

    rename _b_inst_ b
    rename _se_inst_ se

    local new = _N + 1
    set obs `new'
    replace year=$baseyr in `new'
    replace b=0 in `new'
    replace se=0 in `new'
    sort year
    tset year, yearly

    generate ci_l = b - 1.96*se
    generate ci_h = b + 1.96*se

    graph twoway (scatter b year, connect(direct)) || (rcap ci_l ci_h year), legend(off) xtitle("Year")
end

* Graphs
********************************
use $dta/`event_workfile', clear
quietly xi: xtreg opioid_rate inst_* i.divyr [w=popwt03], fe cluster(cz)
yeargraph
graph export $figs/`firststage_raw_yr'$expt, replace

use $dta/`event_workfile', clear
generate timetrend = sh_elderly03 * year
quietly xi: xtreg opioid_rate inst_* i.divyr timetrend [w=popwt03], fe cluster(cz)
yeargraph
graph export $figs/`firststage_adj_yr'$expt, replace

use $dta/`event_workfile', clear
quietly xi: xtreg epop_a_2554 inst_* i.divyr [w=popwt03] if consistent_sample, fe cluster(cz)
yeargraph
graph export $figs/`reducedform_yr'$expt, replace

erase $dta/`event_workfile'
log close


//use $dta/`workfile', clear
//keep if year==2005 | year==2011
//foreach var in lfp unemp lgrlinc noincome {
//    eststo longdiff_`var': quietly xi: xtivreg2 `var'_2554 (opioid_rate=inst2011) i.divisionyear [w=popwt03], fe cluster(cz)
//}
//esttab longdiff_* using $tabs/`longdifftable', replace b(a2) se(a2) keep(opioid_rate) stats(r2_a N, labels("\$\bar{R}^2\$" "\$N\$")) star(* 0.05 ** 0.01)
