// Author:          Oscar Suen
// Date Modified:   04/07/2018
// Description:     Event study analysis

// Reset stata
cap log close
clear all
set more off

// Date last run CHANGE
local daterun 20180417
local workfiledaterun 20180417

// File locations REPLACE root
global root         "/bbkinghome/osuen/project"
global analysis     $root/analysis
global code         $analysis/code
global dta          $analysis/dta
global out          $analysis/out
global log         $analysis/log
global acs          $root/acs/dta
global arcos        $root/arcos/dta
global pop          $root/pop/dta
global crosswalks   $root/crosswalks/dta

// Export graph filetype
global expt ".pdf"

// Starts log
log using $log/event_analysis_`daterun'.log, text replace

// Input filenames
local panel_yearcz acs_yearcz.dta
local czpop pop_yearcz.dta
local czwt wt_yearcz.dta
local opioid_rate opioid_rate.dta
local cz_elderly cz_elderly.dta
local cz2state cz2state_crosswalk.dta
local state2reg state2reg_crosswalk.dta

// Output filenames
local workfile event_workfile_`workfiledaterun'.dta
local firststage_raw event_fs
local firststage_adj event_fs_adj
local reducedform event_rf
local longdifftable table_longdiff.tex

// Section switches
local switch_workfile=      0
local switch_fsgraphs=      0
local switch_rfgraphs=      0
local switch_longdiff=      1

********************************
* Workfile                     *
********************************

* Generate workfile
********************************
if `switch_workfile' {
    use $pop/`cz_elderly', clear
    rename elderly_share sh_elderly03
    rename popwt popwt03
    save $dta/temp.dta, replace

    use $arcos/`opioid_rate'
    merge m:1 cz using $dta/temp.dta
    assert _merge==3
    drop _merge

    rename percap opioid_rate

    merge 1:1 cz year using $acs/`panel_yearcz'
    tab year if _merge==1
    tab year if _merge==2
    drop _merge

    forvalues yr = 2000/2016 {
        generate inst`yr' = sh_elderly03 * (year == `yr')
    }
    drop inst2005

    merge m:1 cz using $crosswalks/`cz2state'
    drop if _merge==2
    assert _merge==3
    drop _merge

    merge m:1 state using $crosswalks/`state2reg'
    drop if _merge==2
    assert _merge==3
    drop _merge

    egen stateyear = group(state year)
    egen divisionyear = group(division year)

    xtset cz year, yearly

    erase $dta/temp.dta
    save $dta/`workfile', replace
}

********************************
* Analysis                     *
********************************

* Graphs
********************************
if `switch_fsgraphs' {
    use $dta/`workfile', clear
    generate tmp=1

    drop if year > 2011
    quietly xi: xtreg opioid_rate inst* i.divisionyear [w=popwt03], fe cluster(cz)

    statsby _b _se, clear by(tmp): regress
    keep tmp _b_inst* _se_inst*
    reshape long _b_inst _se_inst, i(tmp) j(year)
    drop tmp

    tset year, yearly
    rename _b_inst b
    rename _se_inst se

    local new = _N + 1
    set obs `new'
    replace year=2005 in `new'
    replace b=0 in `new'
    replace se=0 in `new'
    sort year

    generate ci_l = b - 1.96*se
    generate ci_h = b + 1.96*se

    graph twoway (scatter b year, connect(direct)) || (rcap ci_l ci_h year) if year<= 2011, legend(off) xtitle("Year")
    graph save $out/`firststage_raw', replace
    graph export $out/`firststage_raw'$expt, replace



    use $dta/`workfile', clear
    generate tmp=1

    drop if year > 2011
    generate timetrend = sh_elderly03 * year
    quietly xi: xtreg opioid_rate inst* i.divisionyear timetrend [w=popwt03], fe cluster(cz)

    statsby _b _se, clear by(tmp): regress
    keep tmp _b_inst* _se_inst*
    reshape long _b_inst _se_inst, i(tmp) j(year)
    drop tmp

    tset year, yearly
    rename _b_inst b
    rename _se_inst se

    local new = _N + 1
    set obs `new'
    replace year=2005 in `new'
    replace b=0 in `new'
    replace se=0 in `new'
    sort year

    generate ci_l = b - 1.96*se
    generate ci_h = b + 1.96*se

    graph twoway (scatter b year, connect(direct)) || (rcap ci_l ci_h year) if year<= 2011, legend(off) xtitle("Year")
    graph save $out/`firststage_adj', replace
    graph export $out/`firststage_adj'$expt, replace
}


if `switch_longdiff' {
    use $dta/`workfile', clear
    keep if year==2005 | year==2011
    foreach var in lfp unemp lgrlinc noincome {
        eststo longdiff_`var': quietly xi: xtivreg2 `var'_2554 (opioid_rate=inst2011) i.divisionyear [w=popwt03], fe cluster(cz)
    }
    esttab longdiff_* using $out/`longdifftable', replace b(a2) se(a2) keep(opioid_rate) stats(r2_a N, labels("\$\bar{R}^2\$" "\$N\$")) star(* 0.05 ** 0.01)
}


if `switch_rfgraphs' {
    use $dta/`workfile', clear
    generate tmp=1

    quietly xi: xtreg lfp_2554 inst* i.divisionyear [w=popwt03], fe cluster(cz)

    statsby _b _se, clear by(tmp): regress
    keep tmp _b_inst* _se_inst*
    reshape long _b_inst _se_inst, i(tmp) j(year)
    drop tmp

    tset year, yearly
    rename _b_inst b
    rename _se_inst se

    local new = _N + 1
    set obs `new'
    replace year=2005 in `new'
    replace b=0 in `new'
    replace se=0 in `new'
    sort year

    generate ci_l = b - 1.96*se
    generate ci_h = b + 1.96*se

    graph twoway (scatter b year, connect(direct)) || (rcap ci_l ci_h year), legend(off) xtitle("Year")
    graph save $out/`reducedform', replace
    graph export $out/`reducedform'$expt, replace
}


log close


