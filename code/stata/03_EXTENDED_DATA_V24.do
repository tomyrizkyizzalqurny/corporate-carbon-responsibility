********************************************************************************
* 03_EXTENDED_DATA_V24.do
* KBK 2023 A++ | F1000Research
* The Moral Economy of Carbon Responsibility
*
* PURPOSE
*   Post-freeze V24 extension. DO NOT re-estimate or alter the frozen V15 core.
*   1) Verify the frozen final analysis base and expected V15 outputs.
*   2) Produce the missing moral-configuration threshold sensitivity.
*   3) Convert the verified two-stage cluster bootstrap replications into a
*      compact repository-ready summary, if the replication file is present.
*   4) Write an Extended Data completion audit and README.
*
* RUN AFTER THE FROZEN V15 PRODUCTION RUN.
*
* IMPORTANT
*   - The main sample, outcome, covariates, overlap-weighting design, BH-FDR
*     families, and core model architecture remain frozen.
*   - This file adds Extended Data only. It does not replace V15.
*   - Country remains an institutional context, not a causal treatment.
*   - Moral configurations remain descriptive/interpretive; they do not infer
*     greenwashing, intent, moral character, or causal mechanisms.
********************************************************************************

version 17.0
clear all
set more off
set varabbrev off
set linesize 255
set seed 20260903

********************************************************************************
* 00. PROJECT ROOT — EDIT ONLY THIS LINE IF YOUR FOLDER MOVES
********************************************************************************
global ROOT "`c(pwd)'"

capture cd "$ROOT"
if _rc {
    display as error "PROJECT ROOT NOT FOUND:"
    display as error "$ROOT"
    display as error "Edit only the global ROOT line in 03_EXTENDED_DATA_V24.do."
    exit 601
}

local DAT "$ROOT/02_FINAL_DATA"
local SRC "$ROOT/03_FINAL_OUTPUTS/FINAL_V7_RAW_STATS"
local ED  "$ROOT/03_FINAL_OUTPUTS/09_EXTENDED_DATA_V24"

capture mkdir "$ROOT/03_FINAL_OUTPUTS"
capture mkdir "`ED'"

capture log close
log using "`ED'/03_EXTENDED_DATA_V24.log", text replace

display as text "=============================================================="
display as text "V24 EXTENDED DATA PRODUCTION — START"
display as text "=============================================================="

********************************************************************************
* 01. LOAD + HARD GUARDRAILS
********************************************************************************
capture confirm file "`DAT'/FINAL_MORAL_ECONOMY_V7_ANALYSIS_BASE.dta"
if _rc {
    display as error "FROZEN V15 ANALYSIS BASE NOT FOUND:"
    display as error "`DAT'/FINAL_MORAL_ECONOMY_V7_ANALYSIS_BASE.dta"
    display as error "Run the frozen V15 production master first."
    log close
    exit 601
}

use "`DAT'/FINAL_MORAL_ECONOMY_V7_ANALYSIS_BASE.dta", clear

isid firm_id year
assert inrange(year,2021,2024)
assert is_financial==0
assert inlist(indonesia,0,1)
assert ow_final>0 & ow_final<1

quietly count
assert r(N)==3792

quietly count if indonesia==1
assert r(N)==250

quietly count if indonesia==0
assert r(N)==3542

egen byte __tagfirm=tag(firm_id)
quietly count if __tagfirm==1
assert r(N)==1116
drop __tagfirm

foreach v in ln_s12_int gov_depth sector_id country indonesia {
    capture confirm variable `v'
    if _rc {
        display as error "REQUIRED V24 VARIABLE MISSING: `v'"
        log close
        exit 111
    }
}

display as result "Frozen guardrails PASS: 3,792 firm-years / 1,116 firms."

********************************************************************************
* 02. AUDIT EXPECTED V15 EXTENDED-DATA SOURCE OUTPUTS
********************************************************************************
tempname af
postfile `af' str244 relative_path byte found ///
    using "`ED'/V24_SOURCE_OUTPUT_AUDIT.dta", replace

local expected_files ///
    "00_RAW_QA/REBUILT_SOURCE_COUNTS_V15.csv" ///
    "00_RAW_QA/FULL_PANEL_COUNTRY_YEAR_V15.csv" ///
    "01_QA/FORMULA_DENOMINATOR_AUDIT_V7.csv" ///
    "01_QA/COVERAGE_EXPANDED_FULL_PANEL_V7.csv" ///
    "01_QA/BALANCE_FIRST_SECOND_MOMENTS_V7.csv" ///
    "01_QA/OVERLAP_WEIGHT_DIAGNOSTICS_V7.csv" ///
    "01_QA/OVERLAP_WEIGHT_ESS_V7.csv" ///
    "01_QA/BALANCE_CATEGORICAL_V7.csv" ///
    "01_QA/FINAL_MISSINGNESS_EXPANDED_V7.csv" ///
    "01_QA/MODEL_SPECIFIC_BALANCE_V7.csv" ///
    "01_QA/FIRM_LEVEL_DESIGN_COUNTS_V7.csv" ///
    "01_QA/CARBON_PERSISTENCE_AUDIT_V7.csv" ///
    "01_QA/FINAL_SAMPLE_COUNTRY_YEAR_V7.csv" ///
    "01_QA/VALIDITY_DIAGNOSTICS_V7.csv" ///
    "02_CORE/DESCRIPTIVES_EXPANDED_BY_COUNTRY_V7.csv" ///
    "02_CORE/RQ1_CORE_V7.csv" ///
    "03_RQ2_GOV_ARCHITECTURE/RQ2A_INDIVIDUAL_BH_FDR_V7.csv" ///
    "03_RQ2_GOV_ARCHITECTURE/RQ2_ARCHITECTURE_CORE_BH_FDR_V7.csv" ///
    "03_RQ2_GOV_ARCHITECTURE/RQ2_DOMAIN_DECOMPOSITION_BH_FDR_V7.csv" ///
    "03_RQ2_GOV_ARCHITECTURE/RQ2_ACCOUNTABILITY_EXTENSIONS_BH_FDR_V7.csv" ///
    "03_RQ2_GOV_ARCHITECTURE/RQ2_TEMPORAL_BH_FDR_V7.csv" ///
    "03_RQ2_GOV_ARCHITECTURE/RQ2_TEMPORAL_BASELINE_ADJ_BH_FDR_V7.csv" ///
    "03_RQ2_GOV_ARCHITECTURE/RQ2_GOVERNANCE_ADOPTION_V7.csv" ///
    "04_RQ3_ECONOMIC_CONSEQUENCES/RQ3_CORE_T1_BH_FDR_V7.csv" ///
    "04_RQ3_ECONOMIC_CONSEQUENCES/RQ3_STANDARDIZED_EFFECTS_T1_V7.csv" ///
    "04_RQ3_ECONOMIC_CONSEQUENCES/RQ3_T2_BH_FDR_V7.csv" ///
    "04_RQ3_ECONOMIC_CONSEQUENCES/RQ3_BASELINE_ADJUSTED_V7.csv" ///
    "05_RQ4_INSTITUTIONAL_CONTEXT/RQ4_GOV_ARCHITECTURE_INTERACTIONS_BH_FDR_V7.csv" ///
    "05_RQ4_INSTITUTIONAL_CONTEXT/RQ4_ECONOMIC_INTERACTIONS_BH_FDR_V7.csv" ///
    "05_RQ4_INSTITUTIONAL_CONTEXT/RQ3_COUNTRY_SPECIFIC_V7.csv" ///
    "06_ROBUSTNESS/RQ1_ROBUSTNESS_V7.csv" ///
    "06_ROBUSTNESS/RQ2_ARCHITECTURE_ROBUSTNESS_V7.csv" ///
    "06_ROBUSTNESS/RQ2_NONLINEAR_ARCHITECTURE_BH_FDR_V7.csv" ///
    "06_ROBUSTNESS/RQ3_WINSORIZED_OUTCOMES_V7.csv" ///
    "06_ROBUSTNESS/RQ3_FIRM_FE_V7.csv" ///
    "06_ROBUSTNESS/RQ3_OTHER_SENSITIVITIES_V7.csv" ///
    "06_ROBUSTNESS/RQ3_NONLINEAR_CARBON_BH_FDR_V7.csv" ///
    "06_ROBUSTNESS/FIRM_LEVEL_WEIGHT_SENSITIVITY_V7.csv" ///
    "07_INTERPRETIVE/MORAL_CONFIGURATION_COUNTS_V7.csv" ///
    "07_INTERPRETIVE/MORAL_CONFIGURATION_ECONOMIC_PROFILES_V7.csv" ///
    "08_STATISTICAL_REVIEW/GOVERNANCE_MEASUREMENT_AUDIT_V7.csv" ///
    "08_STATISTICAL_REVIEW/GOVERNANCE_COMPONENT_CORRELATIONS_V7.csv" ///
    "08_STATISTICAL_REVIEW/VIF_SUBSTANTIVE_V7.csv" ///
    "08_STATISTICAL_REVIEW/CLASSICAL_DIAGNOSTICS_V7.csv" ///
    "08_STATISTICAL_REVIEW/RESIDUAL_DEPENDENCE_V7.csv" ///
    "08_STATISTICAL_REVIEW/CLUSTER_COUNTS_BY_COUNTRY_V7.csv" ///
    "08_STATISTICAL_REVIEW/MEASUREMENT_VALIDITY_RELIABILITY_POSITION_V7.txt" ///
    "08_STATISTICAL_REVIEW/STATISTICAL_ASSUMPTION_POSITION_V7.txt" ///
    "ANALYSIS_PROTOCOL_LOCK_V7.txt" ///
    "OUTPUT_MANIFEST_V7.txt"

foreach f of local expected_files {
    capture confirm file "`SRC'/`f'"
    local ok=(_rc==0)
    post `af' ("`f'") (`ok')
}
postclose `af'

preserve
    use "`ED'/V24_SOURCE_OUTPUT_AUDIT.dta", clear
    export delimited using "`ED'/V24_SOURCE_OUTPUT_AUDIT.csv", replace
    quietly count
    local n_expected=r(N)
    quietly count if found==1
    local n_found=r(N)
restore

display as result "V15 source outputs found: `n_found' of `n_expected'."

********************************************************************************
* 03. MORAL-CONFIGURATION THRESHOLD SENSITIVITY
*
* Main V15 map:
*   - governance: pooled P50 of gov_depth
*   - carbon: sector-year P50 of ln_s12_int
*
* V24 sensitivity:
*   - governance cut: pooled P40 / P50 / P60
*   - carbon cut: sector-year P40 / P50 / P60
*   - 9 predeclared threshold combinations
*
* Lower carbon intensity = better performance.
********************************************************************************
tempname cfgpost
postfile `cfgpost' int gov_percentile int carbon_percentile ///
    double gov_cut_value str16 country byte configuration ///
    str60 configuration_label long N_config long N_country ///
    double pct_country ///
    using "`ED'/ED_CONFIGURATION_THRESHOLD_SENSITIVITY_V24.dta", replace

local gps "40 50 60"
local cps "40 50 60"

foreach gp of local gps {
    quietly centile gov_depth if !missing(gov_depth), centile(`gp')
    scalar __gcut=r(c_1)

    foreach cp of local cps {
        tempvar __ccut __high __better __cfg

        bysort year sector_id: egen double `__ccut'=pctile(ln_s12_int), p(`cp')
        gen byte `__high'=gov_depth>=__gcut if !missing(gov_depth)
        gen byte `__better'=ln_s12_int<=`__ccut' ///
            if !missing(ln_s12_int,`__ccut')
        gen byte `__cfg'=.
        replace `__cfg'=1 if `__high'==1 & `__better'==1
        replace `__cfg'=2 if `__high'==1 & `__better'==0
        replace `__cfg'=3 if `__high'==0 & `__better'==1
        replace `__cfg'=4 if `__high'==0 & `__better'==0

        foreach cc in 0 1 {
            if `cc'==1 {
                local cname "Indonesia"
            }
            else {
                local cname "United States"
            }

            quietly count if indonesia==`cc' & !missing(`__cfg')
            local den=r(N)

            forvalues k=1/4 {
                if `k'==1 {
                    local klab "Responsibility-performance alignment"
                }
                else if `k'==2 {
                    local klab "Governance-performance decoupling"
                }
                else if `k'==3 {
                    local klab "Substantive performance without formalization"
                }
                else {
                    local klab "Carbon-intensive institutional status quo"
                }

                quietly count if indonesia==`cc' & `__cfg'==`k'
                local nn=r(N)

                local pp=.
                if `den'>0 {
                    local pp=100*`nn'/`den'
                }

                post `cfgpost' (`gp') (`cp') (__gcut) ("`cname'") ///
                    (`k') ("`klab'") (`nn') (`den') (`pp')
            }
        }
    }
}
postclose `cfgpost'

preserve
    use "`ED'/ED_CONFIGURATION_THRESHOLD_SENSITIVITY_V24.dta", clear
    sort gov_percentile carbon_percentile country configuration
    export delimited using "`ED'/ED_CONFIGURATION_THRESHOLD_SENSITIVITY_V24.csv", replace

    collapse (mean) mean_pct=pct_country ///
             (min) min_pct=pct_country ///
             (max) max_pct=pct_country, ///
             by(country configuration configuration_label)

    gen double range_pct=max_pct-min_pct
    sort country configuration
    export delimited using "`ED'/ED_CONFIGURATION_THRESHOLD_STABILITY_V24.csv", replace
restore

display as result "Configuration-threshold sensitivity COMPLETE."

********************************************************************************
* 04. COMPACT TWO-STAGE CLUSTER BOOTSTRAP SUMMARY
*
* V15 is the source of the bootstrap replications. V24 does not rerun them.
* It summarizes them only when the saved V15 replication file exists and a
* recognizable bootstrap-statistic variable is present.
********************************************************************************
local BS "`SRC'/08_STATISTICAL_REVIEW/RQ1_TWO_STAGE_CLUSTER_BOOTSTRAP_REPS_V7.dta"
local bootstrap_status 0

capture confirm file "`BS'"
if !_rc {
    preserve
        use "`BS'", clear

        local bvar ""
        capture confirm variable b_indonesia
        if !_rc {
            local bvar "b_indonesia"
        }

        if "`bvar'"=="" {
            capture confirm variable _bs_1
            if !_rc {
                local bvar "_bs_1"
            }
        }

        if "`bvar'"=="" {
            capture confirm variable b
            if !_rc {
                local bvar "b"
            }
        }

        if "`bvar'"!="" {
            quietly count if !missing(`bvar')
            local bs_n=r(N)

            quietly summarize `bvar'
            scalar __bs_mean=r(mean)
            scalar __bs_sd=r(sd)

            quietly centile `bvar', centile(2.5 50 97.5)
            scalar __bs_p025=r(c_1)
            scalar __bs_p50 =r(c_2)
            scalar __bs_p975=r(c_3)

            clear
            set obs 1
            gen str80 statistic="RQ1 Indonesia coefficient, two-stage firm-cluster bootstrap"
            gen str32 source_variable="`bvar'"
            gen long N_reps=`bs_n'
            gen double mean=__bs_mean
            gen double sd=__bs_sd
            gen double p2_5=__bs_p025
            gen double p50=__bs_p50
            gen double p97_5=__bs_p975
            gen str100 interpretation="Supplementary robustness; core inference remains firm-clustered V15 model"
            export delimited using "`ED'/ED_BOOTSTRAP_COMPACT_SUMMARY_V24.csv", replace
            local bootstrap_status 1
        }
        else {
            display as error "Bootstrap reps file found, but statistic variable was not recognized."
        }
    restore
}
else {
    display as error "Bootstrap reps file not found. V24 will not claim bootstrap verification."
}

********************************************************************************
* 05. V24 COMPLETION STATUS
********************************************************************************
clear
set obs 6
gen str52 item=""
gen byte completed=.
gen str170 evidence=""

replace item="Frozen V15 analysis base guardrails" in 1
replace completed=1 in 1
replace evidence="FINAL_MORAL_ECONOMY_V7_ANALYSIS_BASE.dta reproduces N=3792, ID=250, US=3542, firms=1116." in 1

replace item="V15 Extended Data source-output inventory" in 2
replace completed=(`n_found'==`n_expected') in 2
replace evidence="`n_found' of `n_expected' expected V15 repository-facing source outputs were found." in 2

replace item="Configuration threshold sensitivity" in 3
replace completed=1 in 3
replace evidence="Governance P40/P50/P60 x sector-year carbon P40/P50/P60; 9 threshold combinations." in 3

replace item="Configuration threshold stability summary" in 4
replace completed=1 in 4
replace evidence="Mean/min/max/range of configuration shares across the 9 threshold combinations." in 4

replace item="Two-stage cluster bootstrap compact summary" in 5
replace completed=`bootstrap_status' in 5
replace evidence="Generated only from the saved V15 bootstrap replications; V24 never fabricates or reruns missing results." in 5

replace item="Synthetic/representative public replication dataset" in 6
replace completed=0 in 6
replace evidence="Not generated in V24. Build as next reproducibility stage without redistributing licensed LSEG observations." in 6

export delimited using "`ED'/V24_COMPLETION_STATUS.csv", replace

********************************************************************************
* 06. README
********************************************************************************
file open rd using "`ED'/README_EXTENDED_DATA_V24.txt", write replace
file write rd "V24 EXTENDED DATA — POST-FREEZE PRODUCTION" _n
file write rd "==========================================" _n _n
file write rd "This stage does NOT alter the frozen V15 scientific core." _n
file write rd "It adds repository-facing evidence required by the V23 manuscript." _n _n
file write rd "NEW V24 OUTPUTS" _n
file write rd "1. V24_SOURCE_OUTPUT_AUDIT.csv" _n
file write rd "2. ED_CONFIGURATION_THRESHOLD_SENSITIVITY_V24.csv" _n
file write rd "3. ED_CONFIGURATION_THRESHOLD_STABILITY_V24.csv" _n
file write rd "4. ED_BOOTSTRAP_COMPACT_SUMMARY_V24.csv — only if verified V15 bootstrap reps exist." _n
file write rd "5. V24_COMPLETION_STATUS.csv" _n
file write rd "6. 03_EXTENDED_DATA_V24.log" _n _n
file write rd "INTERPRETIVE BOUNDARY" _n
file write rd "- Threshold sensitivity is descriptive robustness for the moral-economy configuration map." _n
file write rd "- It does not convert the configuration map into a causal or latent-class model." _n
file write rd "- No configuration is evidence of intentional greenwashing." _n
file write rd "- Bootstrap remains supplementary; the frozen V15 clustered inference is primary." _n _n
file write rd "NEXT REPRODUCIBILITY STAGE" _n
file write rd "Build the non-proprietary public replication layer: variable dictionary/field map, synthetic or representative test data, open-source replication code, repository README, license, and persistent identifier." _n
file close rd

display as text "=============================================================="
display as result "V24 EXTENDED DATA PRODUCTION — COMPLETE"
display as result "Outputs: `ED'"
display as result "V15 source files found = `n_found' / `n_expected'"
if `bootstrap_status'==1 {
    display as result "Bootstrap compact summary = VERIFIED/GENERATED"
}
else {
    display as error "Bootstrap compact summary = NOT VERIFIED/NOT GENERATED"
}
display as text "=============================================================="

log close
********************************************************************************
* END
********************************************************************************
