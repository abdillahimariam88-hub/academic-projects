/*==============================================================================
  Project : How Mobile Money Affects Individuals' Economic Behaviour
  Step 2  : Staggered DiD (de Chaisemartin & D'Haultfoeuille), continuous-treatment
            TWFE, robustness checks and heterogeneity (income, education)
  Input   : data/cleaned_data.dta
  Output  : event-study graphs in output/, fe_results.rtf
  Run from: the project folder (mobile-money-staggered-did/)
==============================================================================*/

clear 
use "data/cleaned_data.dta", clear

* Encode: Convert string iso3 to numeric cid (country_id)
encode iso3, gen(cid)


ssc install did_multiplegt_dyn, replace all
ssc install event_plot, replace
ssc install gtools
 
 
*  panel structure
xtset cid year
xtdescribe

**# treatment variables #

* Binary treatment: high mobile money (mmpi >= 4)
gen treated = (mmpi >= 4) if !missing(mmpi)

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
	
	
graph export "output/SDID consumption.png", as(png) name("Graph")
	
** SDID on savings 
set level 90
did_multiplegt (old) savings cid year treated, ///
    robust_dynamic                                     ///
    dynamic(1)                                         ///
    placebo(1)                                         ///
    breps(50)                                          ///
    cluster(cid)                                       ///
   
graph export "output/SDID savings.png", as(png) name("Graph")


** SDID on investment 	
set level 90
did_multiplegt (old) investment cid year treated, ///
    robust_dynamic                                     ///
    dynamic(1)                                         ///
    placebo(1)                                         ///
    breps(50)                                          ///
    cluster(cid)                                       ///

graph export "output/SDID investment.png", as(png) name("Graph")
	
	


********************************************************************************
**# CONTINUOUS TREATMENT FIXED EFFECTS #5
********************************************************************************
ssc install ftools, replace
ssc install reghdfe, replace
ssc install require
ssc install estout, replace

* Baseline model - no controls
reghdfe consumption mmpi, absorb(cid year) cluster(cid)
estimates store cons_base
reghdfe savings mmpi, absorb(cid year) cluster(cid)
estimates store sav_base
reghdfe investment mmpi, absorb(cid year) cluster(cid)
estimates store inv_base

* Extended model - with controls
reghdfe consumption mmpi gdp_pc inflation mobile_subs trade, absorb(cid year) cluster(cid)
estimates store cons_ctrl

*regressed without gdp as controls**
reghdfe savings mmpi inflation mobile_subs trade, absorb(cid year) cluster(cid) 
estimates store sav_ctrl
reghdfe investment mmpi inflation mobile_subs trade, absorb(cid year) cluster(cid)
estimates store inv_ctrl

* Export table
esttab cons_base cons_ctrl sav_base sav_ctrl inv_base inv_ctrl using "fe_results.rtf", ///
    replace                                                                             ///
    b(3) se(3)                                                                         ///
    star(* 0.10 ** 0.05 *** 0.01)                                                      ///
    title("Fixed Effects Results: Continuous Treatment")                                ///
    mtitles("Consumption" "Consumption" "Savings" "Savings" "Investment" "Investment") ///
    keep(mmpi gdp_pc inflation mobile_subs trade)                                      ///
    stats(N r2_within, labels("Observations" "R² within"))

	
	

********************************************************************************
**# ROBUSTENESS CHECK  #
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
	
	
	
********************************************************************************
**# HETEROGENITY ANALYSIS #
********************************************************************************	
	
* Does the effect differ by income level?
* Create a low-income dummy (e.g. gdp_pc below median)
egen med_gdp = median(gdp_pc)
gen low_income = (gdp_pc < med_gdp)
gen high_income = (gdp_pc >= med_gdp)


*****CONSUMPTION ****
* Low income interaction 
reghdfe consumption c.mmpi##i.low_income gdp_pc inflation mobile_subs trade, ///
    absorb(cid year) cluster(cid)
estimates store cons_low_inc

* High income interaction
reghdfe consumption c.mmpi##i.high_income gdp_pc inflation mobile_subs trade, ///
    absorb(cid year) cluster(cid)
estimates store cons_high_inc


****For Savings (How do poor and wealthy countries behave differently in terms of savings with MM ? )

reghdfe savings c.mmpi##i.low_income inflation mobile_subs trade, ///
    absorb(cid year) cluster(cid)
estimates store sav_low_inc

reghdfe savings c.mmpi##i.high_income inflation mobile_subs trade, ///
    absorb(cid year) cluster(cid)
estimates store sav_low_inc

***Investments (Does mobile money unlock investment capacity more in low income countries or not? )

reghdfe investment c.mmpi##i.low_income inflation mobile_subs trade, ///
    absorb(cid year) cluster(cid)
estimates store inv_low_inc

reghdfe investment c.mmpi##i.high_income inflation mobile_subs trade, ///
    absorb(cid year) cluster(cid)
estimates store inv_low_inc

******************************************************************************

* 2. EDUCATION LEVEL HETEROGENEITY
* ============================================================
	
	
*does the effect differ by education level
* Create education dummy based on median school enrollment
* (use whichever education variable you have, e.g. school enrollment %)
egen med_educ = median(education)     // replace with your actual variable name
gen low_educ  = (education < med_educ)
gen high_educ = (education >= med_educ)



* Consumption
reghdfe consumption c.mmpi##i.low_educ gdp_pc inflation mobile_subs trade, ///
    absorb(cid year) cluster(cid)
estimates store cons_low_educ

reghdfe consumption c.mmpi##i.high_educ gdp_pc inflation mobile_subs trade, ///
    absorb(cid year) cluster(cid)
estimates store cons_high_educ

* Savings
reghdfe savings c.mmpi##i.low_educ inflation mobile_subs trade, ///
    absorb(cid year) cluster(cid)
estimates store sav_low_educ

reghdfe savings c.mmpi##i.high_educ inflation mobile_subs trade, ///
    absorb(cid year) cluster(cid)
estimates store sav_low_educ

* Investment
reghdfe investment c.mmpi##i.low_educ inflation mobile_subs trade, ///
    absorb(cid year) cluster(cid)
estimates store inv_low_educ

reghdfe investment c.mmpi##i.high_educ inflation mobile_subs trade, ///
    absorb(cid year) cluster(cid)
estimates store inv_low_educ





