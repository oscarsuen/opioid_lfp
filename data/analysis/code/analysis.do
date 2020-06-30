// Author:          Oscar Suen
// Date Modified:   04/07/2018
// Description:     Analysis of data

// Reset stata
cap log close
clear all
set more off

// Increase matsize for regressions
set matsize 10000

// Date last run CHANGE
local workfile_daterun 20180429
local daterun 20180804

// File locations REPLACE root
global root         "/bbkinghome/osuen/project"
global analysis     $root/analysis
global code         $analysis/code
global dta          $analysis/dta
global out          $analysis/out
global logs         $analysis/log
global acs          $root/acs/dta
global arcos        $root/arcos/dta
global pop          $root/pop/dta
global crosswalks   $root/crosswalks/dta

// Export graph filetype
global expt ".pdf"

// Starts log
log using $logs/analysis_`daterun'.log, text replace

// Input filenames
local panel_yearcz acs_yearcz.dta
local czpop pop_yearcz.dta
local czwt wt_yearcz.dta
local opioid_rate opioid_rate.dta
local cz_elderly cz_elderly.dta
local cz2state cz2state_crosswalk.dta
local state2reg state2reg_crosswalk.dta

// Output filenames
local workfile workfile_`workfile_daterun'.dta
local estimates estimates.sters
local firststagetable firststage.tex
local tslstable tsls.tex
local outcomestable outcomes.tex
local agetable age.tex
local gendertable gender.tex
local racetable race.tex
local eductable educ.tex
local binscatter binscatter.gph
local binscatterexpt binscatter$expt

// Section switches
local switch_workfile=      0
local switch_estimates=     1
local switch_tables=        0
local switch_graphs=        0

********************************
* Workfile                     *
********************************

* Generate Workfile
********************************
if `switch_workfile' {
    use $acs/`panel_yearcz', clear
    rename popwt popwtacs

    foreach file in $pop/`czpop' $pop/`czwt' $arcos/`opioid_rate' {
        merge 1:1 year cz using `file'
        tab year if _merge==1
        tab year if _merge==2
        keep if _merge==3
        drop _merge
    }
    save $dta/`workfile', replace

    use $pop/`cz_elderly', clear
    rename elderly_share sh_elderly03
    rename popwt popwt03
    save $dta/temp.dta, replace

    use $dta/`workfile', clear
    merge m:1 cz using $dta/temp.dta
    assert _merge==3
    drop _merge

    rename percap opioid_rate

    merge m:1 cz using $crosswalks/`cz2state'
    drop if _merge==2
    assert _merge==3
    drop _merge

    merge m:1 state using $crosswalks/`state2reg'
    drop if _merge==2
    assert _merge==3
    drop _merge

    generate instrument = sh_elderly03 * (year >= 2006)

    egen stateyear = group(state year)
    egen divisionyear = group(division year)

    xtset cz year, yearly

    save $dta/`workfile', replace
    erase $dta/temp.dta
}

********************************
* Regressions                  *
********************************

* Generate estimates
********************************
if `switch_estimates' {
    use $dta/`workfile', clear

    // First Stage
    eststo firststage_simpleunw: regress opioid_rate instrument, cluster(cz)
    eststo firststage_simplewtd: regress opioid_rate instrument [w=popwt03], cluster(cz)
    eststo firststage_year: reghdfe opioid_rate instrument [w=popwt03], absorb(year) cluster(cz)
    eststo firststage_cz: reghdfe opioid_rate instrument [w=popwt03], absorb(cz) cluster(cz)
    eststo firststage_czyr: reghdfe opioid_rate instrument [w=popwt03], absorb(cz year) cluster(cz)
    eststo firststage_czdivyrunw: reghdfe opioid_rate instrument, absorb(cz divisionyear) cluster(cz)
    eststo firststage_czdivyr: reghdfe opioid_rate instrument [w=popwt03], absorb(cz divisionyear) cluster(cz)
    eststo firststage_czstateyr: reghdfe opioid_rate instrument [w=popwt03], absorb(cz stateyear) cluster(cz)
    eststo firststage_timetrend: reghdfe opioid_rate instrument c.sh_elderly03#c.year [w=popwt03], absorb(cz divisionyear) cluster(cz)

    * CONTROLS NEEDED? ABSORBED BY INDICATORS? *
    // local controls

    foreach var in lfp unemp lgrlinc ihsrlinc noincome poverty {
        foreach age in 1664 1654 2564 2554 {
            eststo ols_`var'_`age'_: reghdfe `var'_`age' opioid_rate [w=popwt03], absorb(cz divisionyear) cluster(cz)
            eststo red_`var'_`age'_: reghdfe `var'_`age' instrument [w=popwt03], absorb(cz divisionyear) cluster(cz)
            eststo ivr_`var'_`age'_: reghdfe `var'_`age' (opioid_rate=instrument) [w=popwt03], absorb(cz divisionyear) cluster(cz)
        }
        foreach age in 1624 2534 3544 4554 5564 {
            eststo ivr_`var'_`age'_age: reghdfe `var'_`age' (opioid_rate=instrument) [w=popwt03], absorb(cz divisionyear) cluster(cz)
        }
        foreach age in 2554 {
            foreach sex in m f {
                eststo ivr_`var'_2554_sex_`sex': reghdfe `var'_`age'`sex' (opioid_rate=instrument) [w=popwt03], absorb(cz divisionyear) cluster(cz)
            }
        }
    }

    estwrite * using $out/`estimates', replace
}

* Generate Tables
********************************
if `switch_tables' {
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
}


* Generate Graphs
********************************
if `switch_graphs' {
    use $dta/`workfile', clear
    binscatter opioid_rate instrument [aw=popwt03], controls(i.divisionyear) absorb(cz) xtitle("Instrument") ytitle("Opioid Rate")
    graph save $out/`binscatter', replace
    graph export $out/`binscatterexpt', replace
}

log close

