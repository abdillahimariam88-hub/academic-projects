/*==============================================================================
  Project : How Mobile Money Affects Individuals' Economic Behaviour
  Step 1  : Data cleaning and merge (World Bank WDI + GSMA MMPI), 2020-2023
  Input   : WDI export (already imported in Stata) and MMPI-2020-23-Public.xlsx
            (raw files not included - see README for sources)
  Output  : merged_data.dta (101 countries x 4 years)
  Run from: the project folder (mobile-money-staggered-did/)
==============================================================================*/

drop in 1

* Rename country identifiers
rename A country_name
rename B iso3

* Rename 2020 variables (columns C to J)
rename C  consumption_2020
rename D  savings_2020
rename E  investment_2020
rename F  education_2020
rename G  gdp_pc_2020
rename H  inflation_2020
rename I  mobile_subs_2020
rename J  trade_2020

* Rename 2021 variables (columns K to R)
rename K  consumption_2021
rename L  savings_2021
rename M  investment_2021
rename N  education_2021
rename O  gdp_pc_2021
rename P  inflation_2021
rename Q  mobile_subs_2021
rename R  trade_2021

* Rename 2022 variables (columns S to Z)
rename S  consumption_2022
rename T  savings_2022
rename U  investment_2022
rename V  education_2022
rename W  gdp_pc_2022
rename X  inflation_2022
rename Y  mobile_subs_2022
rename Z  trade_2022

* Rename 2023 variables (columns AA to AH)
rename AA consumption_2023
rename AB savings_2023
rename AC investment_2023
rename AD education_2023
rename AE gdp_pc_2023
rename AF inflation_2023
rename AG mobile_subs_2023
rename AH trade_2023


* Drop metadata rows at the bottom (empty rows + "Data from..." rows)
drop if iso3 == "" | iso3 == "."
drop if length(iso3) != 3
drop if country_name == "Data from database: World Development Indicators"
drop if country_name == "Last Updated: 02/24/2026"

* Replace WDI missing value indicator ".." with actual Stata missing
foreach var of varlist consumption_* savings_* investment_* education_* ///
                          gdp_pc_* inflation_* mobile_subs_* trade_* {
    replace `var' = "" if `var' == ".."
    destring `var', replace force
}

* Reshape from wide to long: one row per country-year
reshape long consumption_ savings_ investment_ education_ ///
             gdp_pc_ inflation_ mobile_subs_ trade_, ///
             i(iso3 country_name) j(year)

* Remove trailing underscores from variable names
rename consumption_  consumption
rename savings_      savings
rename investment_   investment
rename education_    education
rename gdp_pc_       gdp_pc
rename inflation_    inflation
rename mobile_subs_  mobile_subs
rename trade_        trade


* Create log of consumption per capita
gen ln_consumption = ln(consumption)

* Variable labels
label variable consumption    "HH consumption per capita (const. 2015 USD)"
label variable ln_consumption "Log HH consumption per capita (const. 2015 USD)"
label variable savings        "Gross savings (% of GDP)"
label variable investment     "Gross fixed capital formation (% of GDP)"
label variable education      "Secondary school enrollment (% gross)"
label variable gdp_pc         "GDP per capita (const. 2015 USD)"
label variable inflation      "Inflation, CPI (annual %)"
label variable mobile_subs    "Mobile cellular subscriptions (per 100 people)"
label variable trade          "Trade (% of GDP)"

di "WDI cleaned: `c(N)' observations"
save "wdi_clean.dta", replace

clear

*MMPI DATA

import excel using "MMPI-2020-23-Public.xlsx", ///
    cellrange(B3) firstrow clear
	
* After cellrange(B3), row 3 becomes the header
* Columns: Country | ISO3 | Mobile Money Prevalence (2020-2023) | Adult Pop...

rename Country      country_name
rename ISO3         iso3

* Rename MMPI columns — check exact names with: describe
* They should match: "Mobile Money Prevalence (2020)" etc.
* Rename to short names
capture rename (MobileMoneyPrevalence2020 MobileMoneyPrevalence2021 MobileMoneyPrevalence2022 MobileMoneyPrevalence2023) (mmpi_cat_2020 mmpi_cat_2021 mmpi_cat_2022 mmpi_cat_2023)

* If the above fails (column names differ), use positional rename:
* The 3rd, 4th, 5th, 6th columns after Country and ISO3 are the 4 MMPI years
* rename (C D E F) (mmpi_cat_2020 mmpi_cat_2021 mmpi_cat_2022 mmpi_cat_2023)

* Drop adult population columns (not needed)
keep country_name iso3 mmpi_cat_2020 mmpi_cat_2021 mmpi_cat_2022 mmpi_cat_2023

* Drop empty rows
drop if iso3 == "" | length(iso3) != 3

* Trim whitespace from category labels
foreach var of varlist mmpi_cat_* {
    replace `var' = strtrim(`var')
}

* Verify categories before recoding
di "=== MMPI Category Values ==="
tab mmpi_cat_2020, missing

* Reshape to long format
reshape long mmpi_cat_, i(iso3 country_name) j(year)
rename mmpi_cat_ mmpi_cat
keep if inlist(year, 2020, 2021, 2022, 2023)

* Recode MMPI from text to numeric ordinal (1-5)
gen mmpi = .
replace mmpi = 1 if mmpi_cat == "Very low"
replace mmpi = 2 if mmpi_cat == "Low"
replace mmpi = 3 if mmpi_cat == "Medium"
replace mmpi = 4 if mmpi_cat == "High"
replace mmpi = 5 if mmpi_cat == "Very high"

label define mmpi_lbl 1 "Very Low" 2 "Low" 3 "Medium" 4 "High" 5 "Very High"
label variable mmpi     "Mobile Money Prevalence Index (1=Very Low to 5=Very High)"
label variable mmpi_cat "MMPI category (text)"

di "GSMA cleaned: `c(N)' observations, `c(N)'/4 = countries"

save "gsma_clean.dta", replace


/*===========================================================
   STEP 3: MERGE WDI AND GSMA
   Merge key: iso3 + year
   
   Confirmed from data inspection:
   - WDI: 217 countries x 4 years = 868 obs
   - GSMA: 101 countries x 4 years = 404 obs
   - Expected merged: ~101 countries x 4 years = ~404 obs
     (some may drop due to missing WDI data)
===========================================================*/

use "wdi_clean.dta", clear

merge 1:1 iso3 year using "gsma_clean.dta"

* Check merge results
di "=== MERGE RESULTS ==="
tab _merge

* _merge == 1: in WDI only (no GSMA coverage) → exclude
* _merge == 2: in GSMA only (no WDI data) → exclude
* _merge == 3: matched → keep

keep if _merge == 3
drop _merge

di "Merged panel: `c(N)' observations, countries: " ///
   %3.0f `c(N)'/4
  
save "merged_data.dta", replace