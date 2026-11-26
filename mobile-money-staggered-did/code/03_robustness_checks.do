/*==============================================================================
  Project : How Mobile Money Affects Individuals' Economic Behaviour
  Step 3  : Robustness checks - treatment threshold lowered to MMPI >= 3,
            alternative samples, log outcome, country-specific trends
  Input   : data/cleaned_data.dta
  Output  : event-study graphs in output/
  Run from: the project folder (mobile-money-staggered-did/)
==============================================================================*/

********************************************************************************
**# ROBUSTENESS CHECK 1 #
********************************************************************************
* Check if the results still hold if we change the threshold from MMPI>=4 to MMPI>=3. Means if we change the treatment to MMPI switch to medium, will the causual effect still hold.


clear 
use "data/cleaned_data.dta", clear
capture mkdir "output"

* Encode: Convert string iso3 to numeric cid (country_id)
encode iso3, gen(cid)


ssc install did_multiplegt_dyn, replace all
ssc install event_plot, replace
ssc install gtools
 
 
*  panel structure
xtset cid year
xtdescribe

**# treatment variables #

* Binary treatment: high mobile money (mmpi >= 3)
gen treated = (mmpi >= 3) if !missing(mmpi)

* Identify first year of treatment
bysort cid (year): gen first_treat = year if treated == 1
bysort cid: egen treatment_year = min(first_treat)


* Event time for staggered structure
gen event_time = year - treatment_year

* show always-treated countries (treated in first year)
gen always_treated = (treatment_year == 2020)

* drop always-treated countries 
drop if always_treated==1


** SDID on consumption 
set level 90
did_multiplegt (old) consumption cid year treated, ///
    robust_dynamic                                     ///
    dynamic(1)                                         ///
    placebo(1)                                         ///
    breps(50)                                          ///
    cluster(cid)                                       ///
	
	
graph export "output/SDID consumption T=3.png", as(png) name("Graph")
	
** SDID on savings 
set level 90
did_multiplegt (old) savings cid year treated, ///
    robust_dynamic                                     ///
    dynamic(1)                                         ///
    placebo(1)                                         ///
    breps(50)                                          ///
    cluster(cid)                                       ///
   
graph export "output/SDID savings T=3.png", as(png) name("Graph")


** SDID on investment 	
set level 90
did_multiplegt (old) investment cid year treated, ///
    robust_dynamic                                     ///
    dynamic(1)                                         ///
    placebo(1)                                         ///
    breps(50)                                          ///
    cluster(cid)                                       ///

graph export "output/SDID investment T=3.png", as(png) name("Graph")
	




********************************************************************************
**# ROBUSTENESS CHECK 2 #
********************************************************************************
	
* Exclude never-treated countries (use only switchers + always-treated)
reghdfe consumption mmpi if !missing(treatment_year), ///
    absorb(cid year) cluster(cid)

*  Exclude always-treated countries (already done in DiD sample)
* re-run on the restricted sample you already have

* Log transformation of consumption (if not already using ln_consumption)
reghdfe ln_consumption mmpi gdp_pc inflation mobile_subs trade, ///
    absorb(cid year) cluster(cid)

* Add country-specific time trends
reghdfe consumption mmpi gdp_pc inflation mobile_subs trade, ///
    absorb(cid year cid#c.year) cluster(cid)