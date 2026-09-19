********************************************************************************
* 99_POSTPROCESSING_SUBMISSION_V15.do
* VERSION 15.1 â€” POST-ESTIMATION / SUBMISSION PACKAGING ONLY
* DATE: 03 September 2026
*
* ARTICLE
* The Moral Economy of Carbon Responsibility:
* Formal Climate Governance, Substantive Carbon Performance, and
* Uneven Economic Valuation in Indonesia and the United States
*
* PURPOSE
* This DO DOES NOT rebuild raw Refinitiv/LSEG data and DOES NOT rerun the full
* V15 production pipeline. It uses the locked V15 final analysis dataset and
* existing V15 result CSVs to produce only the additional outputs needed after
* full empirical review:
*
*   1. RQ4 governance x country simple slopes (US vs Indonesia) with 95% CI.
*   2. RQ1 overlap-weighted adjusted carbon means by country with 95% CI.
*   3. Robust NPM descriptives (median + pooled P1/P99 winsorized sensitivity).
*   4. Compact summary of the existing two-stage cluster-bootstrap replications.
*   5. One consolidated FINAL_REVIEW_WORKBOOK_V15.xlsx for manuscript work.
*   6. Figure-ready PNG for the adjusted RQ1 country gap (optional/capture-safe).
*
* DESIGN LOCK
* - Country is an institutional context, NOT a causal treatment.
* - Main models remain overlap-weighted and firm-clustered exactly as in V15.
* - Governance simple slopes decompose already-estimated RQ4 interactions;
*   they are not a new hypothesis family.
* - exp(adjusted log mean)-1 is labelled a geometric-scale transformation,
*   NOT an arithmetic predicted mean of raw carbon intensity.
* - Raw NPM is never overwritten. Winsorization is presentation sensitivity only.
* - Original V15 outputs and final analysis dataset are never modified.
********************************************************************************

version 17.0
clear all
set more off
set varabbrev off
set linesize 255
capture set maxvar 10000
set seed 20260903

********************************************************************************
* 0. PROJECT PATHS â€” EDIT ONLY ROOT IF THE PROJECT MOVES
********************************************************************************

global ROOT "`c(pwd)'"

capture cd "$ROOT"
if _rc {
    display as error "PROJECT ROOT NOT FOUND:"
    display as error "$ROOT"
    display as error "Edit only global ROOT at the top of this DO and rerun."
    exit 601
}

local DAT   "$ROOT/02_FINAL_DATA"
local BASE  "$ROOT/03_FINAL_OUTPUTS/FINAL_V7_RAW_STATS"
local QA    "`BASE'/01_QA"
local CORE  "`BASE'/02_CORE"
local RQ2   "`BASE'/03_RQ2_GOV_ARCHITECTURE"
local RQ3   "`BASE'/04_RQ3_ECONOMIC_CONSEQUENCES"
local RQ4   "`BASE'/05_RQ4_INSTITUTIONAL_CONTEXT"
local ROB   "`BASE'/06_ROBUSTNESS"
local INT   "`BASE'/07_INTERPRETIVE"
local STAT  "`BASE'/08_STATISTICAL_REVIEW"
local POST  "`BASE'/09_POSTPROCESSING"
local BOOK  "`POST'/FINAL_REVIEW_WORKBOOK_V15.xlsx"
local FINALDATA "`DAT'/FINAL_MORAL_ECONOMY_V7_ANALYSIS_BASE.dta"

capture mkdir "`POST'"

capture log close
log using "`POST'/99_POSTPROCESSING_SUBMISSION_V15.log", text replace

noi display as text "=============================================================="
noi display as text "V15.1 POST-PROCESSING â€” NO RAW REBUILD / NO FULL PIPELINE RERUN"
noi display as text "=============================================================="

********************************************************************************
* 1. PRE-FLIGHT: REQUIRE THE LOCKED V15 FINAL ANALYSIS DATASET
********************************************************************************

capture confirm file "`FINALDATA'"
if _rc {
    display as error "LOCKED V15 ANALYSIS DATASET NOT FOUND:"
    display as error "`FINALDATA'"
    display as error "Run the completed V15 master first; do not reconstruct raw data here."
    log close
    exit 601
}

use "`FINALDATA'", clear

local reqvars "firm_id country indonesia year sector_id ow_final ln_s12_int ln_assets roa tangibility cash_ratio npm gov_breadth9 gov_depth gov_coherence"
foreach v of local reqvars {
    capture confirm variable `v'
    if _rc {
        display as error "REQUIRED VARIABLE MISSING FROM V15 FINAL DATA: `v'"
        log close
        exit 111
    }
}

isid firm_id year
assert inrange(year,2021,2024)
assert inlist(indonesia,0,1)
assert ow_final>0 & ow_final<1 if !missing(ow_final)

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

noi display as result "PRE-FLIGHT PASS: 3,792 firm-years / 1,116 firms / ID=250 / US=3,542."

********************************************************************************
* 2. RQ4 GOVERNANCE x COUNTRY SIMPLE SLOPES
*    Same specification as V15 RQ4A.
********************************************************************************

local govlist "gov_breadth9 gov_depth gov_coherence"

tempname slopepost
postfile `slopepost' str24 architecture str16 contrast ///
    double beta se pvalue ci_lo ci_hi long N ///
    using "`POST'/PP_RQ4_GOV_SIMPLE_SLOPES_V15.dta", replace

foreach x of local govlist {
    quietly regress ln_s12_int c.`x'##i.indonesia ///
        c.ln_assets c.roa c.tangibility c.cash_ratio ///
        i.year i.sector_id if !missing(`x') [pw=ow_final], ///
        vce(cluster firm_id)
    local nmodel = e(N)

    * United States slope (Indonesia=0 reference group).
    capture quietly lincom `x'
    if _rc {
        display as error "Simple-slope decomposition failed for US / `x'."
        postclose `slopepost'
        log close
        exit 498
    }
    post `slopepost' ("`x'") ("United States") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`nmodel')

    * Indonesia slope = US slope + interaction.
    capture quietly lincom `x' + 1.indonesia#c.`x'
    if _rc {
        display as error "Simple-slope decomposition failed for Indonesia / `x'."
        postclose `slopepost'
        log close
        exit 498
    }
    post `slopepost' ("`x'") ("Indonesia") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`nmodel')

    * Formal cross-country slope difference (same RQ4 interaction coefficient).
    capture quietly lincom 1.indonesia#c.`x'
    if _rc {
        display as error "Interaction decomposition failed for `x'."
        postclose `slopepost'
        log close
        exit 498
    }
    post `slopepost' ("`x'") ("ID minus US") ///
        (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (`nmodel')
}
postclose `slopepost'

* Attach the original BH-FDR q-value of the interaction family to all rows.
tempfile __govq
capture confirm file "`RQ4'/RQ4_GOV_ARCHITECTURE_INTERACTIONS_BH_FDR_V7.csv"
if !_rc {
    preserve
        import delimited using "`RQ4'/RQ4_GOV_ARCHITECTURE_INTERACTIONS_BH_FDR_V7.csv", ///
            clear varnames(1)
        keep architecture q_bh fdr05 fdr10
        rename q_bh interaction_q_bh
        rename fdr05 interaction_fdr05
        rename fdr10 interaction_fdr10
        save "`__govq'", replace
    restore
}

preserve
    use "`POST'/PP_RQ4_GOV_SIMPLE_SLOPES_V15.dta", clear
    capture confirm file "`__govq'"
    if !_rc {
        merge m:1 architecture using "`__govq'", nogen keep(master match)
    }
    capture confirm variable interaction_q_bh
    if _rc {
        gen double interaction_q_bh=.
        gen byte interaction_fdr05=.
        gen byte interaction_fdr10=.
    }
    order architecture contrast beta se pvalue ci_lo ci_hi interaction_q_bh interaction_fdr05 interaction_f²È="25¸€Ä)É•Á±…”¥Ñ•´ô‰AÉ¥µ…Éä½ÕÑ½µ”ˆ¥¸€È)É•Á±…”‘•Ñ…¥°ô‰±¸ Ä€¬M½Á”€Ä€¬M½Á”€È…É‰½¸¥¹Ñ•¹Í¥Ñä¤¸ˆ¥¸€È)É•Á±…”¥Ñ•´ô‰½Õ¹ÑÉä¥¹Ñ•ÉÁÉ•Ñ…Ñ¥½¸ˆ¥¸€Ì)É•Á±…”‘•Ñ…¥°ô‰%¹‘½¹•Í¥„ÙÌU¹¥Ñ•MÑ…Ñ•Ì¥Ì¥¹ÍÑ¥ÑÕÑ¥½¹…°µ½¹Ñ•áÐ½µÁ…É¥Í½¸ì¹½Ð„…ÕÍ…°ÑÉ•…Ñµ•¹Ð¸ˆ¥¸€Ì)É•Á±…”¥Ñ•´ô‰IDÄˆ¥¸€Ð)É•Á±…”‘•Ñ…¥°ô‰‘©ÕÍÑ•½Á•É…Ñ¥½¹…°…É‰½¸…Àì½Ù•É±…ÀÝ•¥¡Ñ¥¹œ€¬™¥É´µ±ÕÍÑ•É•¥¹™•É•¹”¸ˆ¥¸€Ð)É•Á±…”¥Ñ•´ô‰IDÈˆ¥¸€Ô)É•Á±…”‘•Ñ…¥°ô‰½Ù•É¹…¹”…É¡¥Ñ•ÑÕÉ”¥Ì™½Éµ…Ñ¥Ù”ì‰É•…‘Ñ ½‘•ÁÑ ½½¡•É•¹”ì¹¼É½¹‰… µ…±Á¡„…Ñ”¸ˆ¥¸€Ô)É•Á±…”¥Ñ•´ô‰IDÌˆ¥¸€Ø)É•Á±…”‘•Ñ…¥°ô‰½¹½µ¥Œ½¹Í•ÅÕ•¹•Ì…É”µÕ±Ñ¥‘¥µ•¹Í¥½¹…°ì¹Õ±°½HÉ•ÍÕ±ÑÌÉ•Ñ…¥¹•¸ˆ¥¸€Ø)É•Á±…”¥Ñ•´ô‰IDÐˆ¥¸€Ü)É•Á±…”‘•Ñ…¥°ô‰%¹ÍÑ¥ÑÕÑ¥½¹…°¡•Ñ•É½•¹•¥ÑäÙ¥„½Ù•É¹…¹”à½Õ¹ÑÉä…¹…É‰½¸à½Õ¹ÑÉä¥¹Ñ•É…Ñ¥½¹Ì¸ˆ¥¸€Ü)É•Á±…”¥Ñ•´ô‰M¥µÁ±”Í±½Á•Ìˆ¥¸€à)É•Á±…”‘•Ñ…¥°ô‰A½ÍÐµ•ÍÑ¥µ…Ñ¥½¸‘•½µÁ½Í¥Ñ¥½¸½˜IDÐ½Ù•É¹…¹”¥¹Ñ•É…Ñ¥½¹Ìì¹½Ð„¹•Ü¡åÁ½Ñ¡•Í¥Ì™…µ¥±ä¸ˆ¥¸€à)É•Á±…”¥Ñ•´ô‰‘©ÕÍÑ•µ•…¹Ìˆ¥¸€ä)É•Á±…”‘•Ñ…¥°ô‰•áÀ¡…‘©ÕÍÑ•±½œµ•…¸¤´Ä¥Ì•½µ•ÑÉ¥ŒµÍ…±”¥¹Ñ•¹Í¥Ñä°¹½Ð…É¥Ñ¡µ•Ñ¥ŒÉ…Üµ•…¸¸ˆ¥¸€ä)É•Á±…”¥Ñ•´ô‰9A4ˆ¥¸€ÄÀ)É•Á±…”‘•Ñ…¥°ô‰I…Ü9A4É•Ñ…¥¹•ìµ•‘¥…¸…¹Á½½±•@Ä½@ääÝ¥¹Í½É¥é•‘•ÍÉ¥ÁÑ¥Ù•Ì…É”ÁÉ•Í•¹Ñ…Ñ¥½¸Í•¹Í¥Ñ¥Ù¥Ñä¸ˆ¥¸€ÄÀ)É•Á±…”¥Ñ•´ô‰	½½ÑÍÑÉ…Àˆ¥¸€ÄÄ)É•Á±…”‘•Ñ…¥°ô‰MÕµµ…ÉäÉ•…‘Ì•á¥ÍÑ¥¹œXÄÔÉ•Á±¥…Ñ¥½¸™¥±”ìÑ¡¥Ì<¹•Ù•ÈÉ•ÉÕ¹ÌÑ¡”€äääµÉ•À‰½½ÑÍÑÉ…À¸ˆ¥¸€ÄÄ()…ÁÑÕÉ”¹½¥Í¥±ä•áÁ½ÉÐ•á•°ÕÍ¥¹œ€‰	==,œˆ°Í¡••Ð ‰I5ˆ¤™¥ÉÍÑÉ½Ü¡Ù…É¥…‰±•Ì¤É•Á±…”)¥˜}ÉŒì(€€€‘¥ÍÁ±…ä…Ì•ÉÉ½È€‰%1Q<IQ=9M=1%Q]=I-	==,è	==,œˆ(€€€±½œ±½Í”(€€€•á¥Ð}ÉŒ)ô((¨!•±Á•Èè…‘„MX…Ì½¹”Í¡••ÐÝ¥Ñ¡½ÕÐ¥¹Ñ•ÉÉÕÁÑ¥¹œÑ¡”<¥˜…¸½ÁÑ¥½¹…°MX¥Ì…‰Í•¹Ð¸)…ÁÑÕÉ”ÁÉ½É…´‘É½À}ÁÁ}ÍÙÍ¡••Ð)ÁÉ½É…´‘•™¥¹”}ÁÁ}ÍÙÍ¡••Ð(€€€Íå¹Ñ…à€°%1¡ÍÑÉ¥¹œ¤M!P¡ÍÑÉ¥¹œ¤	==,¡ÍÑÉ¥¹œ¤((€€€…ÁÑÕÉ”½¹™¥É´™¥±”€‰™¥±”œˆ(€€€±½…°}}™ÉŒ€ô}ÉŒ((€€€¥˜}}™ÉŒœì(€€€€€€€‘¥ÍÁ±…ä…ÌÑ•áÐ€‰M-%@½ÁÑ¥½¹…°Ý½É­‰½½¬Í¡••ÐÍ¡••ÐœƒŠPÍ½ÕÉ”¹½Ð™½Õ¹¸ˆ(€€€ô(€€€•±Í”ì(€€€€€€€ÁÉ•Í•ÉÙ”(€€€€€€€€€€€…ÁÑÕÉ”¹½¥Í¥±ä¥µÁ½ÉÐ‘•±¥µ¥Ñ•ÕÍ¥¹œ€‰™¥±”œˆ°±•…ÈÙ…É¹…µ•Ì Ä¤(€€€€€€€€€€€±½…°}}¥ÉŒ€ô}ÉŒ((€€€€€€€€€€€¥˜}}¥ÉŒœì(€€€€€€€€€€€€€€€‘¥ÍÁ±…ä…Ì•ÉÉ½È€‰M-%@Ý½É­‰½½¬Í¡••ÐÍ¡••ÐœƒŠPÍ½ÕÉ”MX½Õ±¹½Ð‰”¥µÁ½ÉÑ•¸ˆ(€€€€€€€€€€€ô(€€€€€€€€€€€•±Í”ì(€€€€€€€€€€€€€€€…ÁÑÕÉ”¹½¥Í¥±ä•áÁ½ÉÐ•á•°ÕÍ¥¹œ€‰‰½½¬œˆ°Í¡••Ð ‰Í¡••Ðœˆ¤€¼¼¼(€€€€€€€€€€€€€€€€€€€™¥ÉÍÑÉ½Ü¡Ù…É¥…‰±•Ì¤Í¡••ÑÉ•Á±…”(€€€€€€€€€€€€€€€±½…°}}•ÉŒ€ô}ÉŒ(€€€€€€€€€€€€€€€¥˜}}•ÉŒœì(€€€€€€€€€€€€€€€€€€€‘¥ÍÁ±…ä…Ì•ÉÉ½È€‰]I9%9èÝ½É­‰½½¬Í¡••ÐÍ¡••Ðœ½Õ±¹½Ð‰”ÝÉ¥ÑÑ•¸¸ˆ(€€€€€€€€€€€€€€€ô(€€€€€€€€€€€ô(€€€€€€€É•ÍÑ½É”(€€€ô)•¹((¨½µÁ…Ðµ…¥¸µÁ…Á•È€¼É•Ù¥•Ý•Èµ™…¥¹œÍ¡••ÑÌ¸)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰Eœ½%91}M5A1}=U9QIe}eI}XÜ¹ÍØˆ¤Í¡••Ð ‰M…µÁ±”ˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰=Iœ½MI%AQ%YM}aA9}	e}=U9QIe}XÜ¹ÍØˆ¤Í¡••Ð ‰•ÍÉ¥ÁÑ¥Ù•Ìˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰A=MPœ½AA}9A5}I=	UMQ}MI%AQ%YM}XÄÔ¹ÍØˆ¤Í¡••Ð ‰9A5}I½‰ÕÍÐˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰Eœ½	19}%IMQ}M=9}5=59QM}XÜ¹ÍØˆ¤Í¡••Ð ‰	…±…¹”ˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰Eœ½=YI1A}]%!Q}%9=MQ%M}XÜ¹ÍØˆ¤Í¡••Ð ‰]•¥¡ÑÌˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰=Iœ½IDÅ}=I}XÜ¹ÍØˆ¤Í¡••Ð ‰IDÅ}½É”ˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰I=œ½IDÅ}I=	UMQ9MM}XÜ¹ÍØˆ¤Í¡••Ð ‰IDÅ}I½‰ÕÍÐˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰A=MPœ½AA}IDÅ})UMQ}I	=9}59M}XÄÔ¹ÍØˆ¤Í¡••Ð ‰IDÅ}‘©5•…¹Ìˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰IDÈœ½IDÉ}I!%QQUI}=I}	!}I}XÜ¹ÍØˆ¤Í¡••Ð ‰IDÉ}É ˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰IDÈœ½IDÉ}=5%9}=5A=M%Q%=9}	!}I}XÜ¹ÍØˆ¤Í¡••Ð ‰IDÉ}½µ…¥¹Ìˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰IDÈœ½IDÉ}Q5A=I1}	M1%9})}	!}I}XÜ¹ÍØˆ¤Í¡••Ð ‰IDÉ}Q•µÁ½É…°ˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰IDÌœ½IDÍ}=I}PÅ}	!}I}XÜ¹ÍØˆ¤Í¡••Ð ‰IDÍ}ÐÄˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰IDÌœ½IDÍ}PÉ}	!}I}XÜ¹ÍØˆ¤Í¡••Ð ‰IDÍ}ÐÈˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰IDÐœ½IDÑ}=Y}I!%QQUI}%9QIQ%=9M}	!}I}XÜ¹ÍØˆ¤Í¡••Ð ‰IDÑ}½Ù%¹Ðˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰A=MPœ½AA}IDÑ}=Y}M%5A1}M1=AM}XÄÔ¹ÍØˆ¤Í¡••Ð ‰IDÑ}M±½Á•Ìˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰IDÐœ½IDÑ}=9=5%}%9QIQ%=9M}	!}I}XÜ¹ÍØˆ¤Í¡••Ð ‰IDÑ}½¹%¹Ðˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰%9Pœ½5=I1}=9%UIQ%=9}=U9QM}XÜ¹ÍØˆ¤Í¡••Ð ‰5½É…±}½¹™¥œˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰Eœ½Y1%%Qe}%9=MQ%M}XÜ¹ÍØˆ¤Í¡••Ð ‰Y…±¥‘¥Ñäˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰MQPœ½Y%}MU	MQ9Q%Y}XÜ¹ÍØˆ¤Í¡••Ð ‰Y%ˆ¤‰½½¬ ‰	==,œˆ¤)}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰MQPœ½1MM%1}%9=MQ%M}XÜ¹ÍØˆ¤Í¡••Ð ‰¥…¹½ÍÑ¥Ìˆ¤‰½½¬ ‰	==,œˆ¤)¥˜	M=,œôôÄì(€€€}ÁÁ}ÍÙÍ¡••Ð°™¥±” ‰A=MPœ½AA}IDÅ}	==QMQIA}MU55Ie}XÄÔ¹ÍØˆ¤Í¡••Ð ‰	½½ÑÍÑÉ…Àˆ¤‰½½¬ ‰	==,œˆ¤)ô()…ÁÑÕÉ”ÁÉ½É…´‘É½À}ÁÁ}ÍÙÍ¡••Ð((¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨(¨€Ü¸A=MPµAI=MM%959%MP€¼%90UII%1L(¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨()ÕÍ”€‰%91Qœˆ°±•…È)¥Í¥™¥Éµ}¥å•…È)ÅÕ¥•Ñ±ä½Õ¹Ð)…ÍÍ•ÉÐÈ¡8¤ôôÌÜäÈ)ÅÕ¥•Ñ±ä½Õ¹Ð¥˜¥¹‘½¹•Í¥„ôôÄ)…ÍÍ•ÉÐÈ¡8¤ôôÈÔÀ)ÅÕ¥•Ñ±ä½Õ¹Ð¥˜¥¹‘½¹•Í¥„ôôÀ)…ÍÍ•ÉÐÈ¡8¤ôôÌÔÐÈ()…ÁÑÕÉ”½¹™¥É´™¥±”€‰A=MPœ½AA}IDÑ}=Y}M%5A1}M1=AM}XÄÔ¹ÍØˆ)¥˜}ÉŒì(€€€‘¥ÍÁ±…ä…Ì•ÉÉ½È€‰A=MPµAI=MM%9=UQAUP5%MM%9èAA}IDÑ}=Y}M%5A1}M1=AM}XÄÔ¹ÍØˆ(€€€±½œ±½Í”(€€€•á¥Ð€ØÀÄ)ô)…ÁÑÕÉ”½¹™¥É´™¥±”€‰A=MPœ½AA}IDÅ})UMQ}I	=9}59M}XÄÔ¹ÍØˆ)¥˜}ÉŒì(€€€‘¥ÍÁ±…ä…Ì•ÉÉ½È€‰A=MPµAI=MM%9=UQAUP5%MM%9èAA}IDÅ})UMQ}I	=9}59M}XÄÔ¹ÍØˆ(€€€±½œ±½Í”(€€€•á¥Ð€ØÀÄ)ô)…ÁÑÕÉ”½¹™¥É´™¥±”€‰A=MPœ½AA}9A5}I=	UMQ}MI%AQ%YM}XÄÔ¹ÍØˆ)¥˜}ÉŒì(€€€‘¥ÍÁ±…ä…Ì•ÉÉ½È€‰A=MPµAI=MM%9=UQAUP5%MM%9èAA}9A5}I=	UMQ}MI%AQ%YM}XÄÔ¹ÍØˆ(€€€±½œ±½Í”(€€€•á¥Ð€ØÀÄ)ô)…ÁÑÕÉ”½¹™¥É´™¥±”€‰	==,œˆ)¥˜}ÉŒì(€€€‘¥ÍÁ±…ä…Ì•ÉÉ½È€‰A=MPµAI=MM%9]=I-	==,5%MM%9è%91}IY%]}]=I-	==-}XÄÔ¹á±Íàˆ(€€€±½œ±½Í”(€€€•á¥Ð€ØÀÄ)ô()™¥±”½Á•¸ÁÁ¹½Ñ”ÕÍ¥¹œ€‰A=MPœ½A=MQAI=MM%9}59%MQ}XÄÔ¹ÑáÐˆ°ÝÉ¥Ñ”É•Á±…”)™¥±”ÝÉ¥Ñ”ÁÁ¹½Ñ”€‰XÄÔ¸ÄA=MPµAI=MM%9=5A1Qˆ}¸)™¥±”ÝÉ¥Ñ”ÁÁ¹½Ñ”€‰9¼É…Üa1M`É•½¹ÍÑÉÕÑ¥½¸Ý…ÌÁ•É™½Éµ•¸ˆ}¸)™¥±”ÝÉ¥Ñ”ÁÁ¹½Ñ”€‰9¼™Õ±°XÄÔµ½‘•°™…µ¥±äÝ…ÌÉ•ÉÕ¸¸ˆ}¸)™¥±”ÝÉ¥Ñ”ÁÁ¹½Ñ”€‰1½­•¥¹ÁÕÐè€ÀÉ}%91}Q½%91}5=I1}=9=5e}XÝ}91eM%M}	M¹‘Ñ„ˆ}¸)™¥±”ÝÉ¥Ñ”ÁÁ¹½Ñ”€‰½É”Í…µÁ±”Õ…É‘É…¥±Ìè€Ì°ÜäÈ™¥É´µå•…ÉÌì€Ä°ÄÄØ™¥ÉµÌì%¹‘½¹•Í¥„ôÈÔÀìULôÌ°ÔÐÈ¸ˆ}¸)™¥±”ÝÉ¥Ñ”ÁÁ¹½Ñ”€‰9•Ü½ÕÑÁÕÐ€ÄèAA}IDÑ}=Y}M%5A1}M1=AM}XÄÔ¹ÍØˆ}¸)™¥±”ÝÉ¥Ñ”ÁÁ¹½Ñ”€‰9•Ü½ÕÑÁÕÐ€ÈèAA}IDÅ})UMQ}I	=9}59M}XÄÔ¹ÍØˆ}¸)™¥±”ÝÉ¥Ñ”ÁÁ¹½Ñ”€‰9•Ü½ÕÑÁÕÐ€ÌèAA}9A5}I=	UMQ}MI%AQ%YM}XÄÔ¹ÍØˆ}¸)¥˜	M=,œôôÄ™¥±”ÝÉ¥Ñ”ÁÁ¹½Ñ”€‰9•Ü½ÕÑÁÕÐ€ÐèAA}IDÅ}	==QMQIA}MU55Ie}XÄÔ¹ÍØ€¡•á¥ÍÑ¥¹œÉ•Á±¥…Ñ¥½¹ÌÍÕµµ…É¥é•ì¹½ÐÉ•ÉÕ¸¤¸ˆ}¸)¥˜	M=,œôôÀ™¥±”ÝÉ¥Ñ”ÁÁ¹½Ñ”€‰	½½ÑÍÑÉ…ÀÍÕµµ…ÉäÕ¹…Ù…¥±…‰±”‰•…ÕÍ”•á¥ÍÑ¥¹œÉ•Á±¥…Ñ¥½¸™¥±”Ý…Ì…‰Í•¹Ð½Õ¹É•½¹¥é•ì¹¼‰½½ÑÍÑÉ…ÀÝ…ÌÉ•ÉÕ¸¸ˆ}¸)™¥±”ÝÉ¥Ñ”ÁÁ¹½Ñ”€‰½¹Í½±¥‘…Ñ•Ý½É­‰½½¬è%91}IY%]}]=I-	==-}XÄÔ¹á±Íàˆ}¸)™¥±”ÝÉ¥Ñ”Á¹½Ñ”€‰%¹Ñ•ÉÁÉ•Ñ¥Ù”Õ…É‘É…¥°è½Õ¹ÑÉä½•™™¥¥•¹ÑÌ½¥¹Ñ•É…Ñ¥½¹Ì…É”…ÍÍ½¥…Ñ¥½¹…°¥¹ÍÑ¥ÑÕÑ¥½¹…°µ½¹Ñ•áÐ•Ù¥‘•¹”°¹½Ð…ÕÍ…°•™™•ÑÌ¸ˆ}¸)™¥±”ÝÉ¥Ñ”Á¹½Ñ”€‰QÉ…¹Í™½Éµ…Ñ¥½¸Õ…É‘É…¥°è•áÀ¡…‘©ÕÍÑ•±½œµ•…¸¤´Ä¥Ì•½µ•ÑÉ¥ŒµÍ…±”¥¹Ñ•¹Í¥Ñä°¹½Ð…É¥Ñ¡µ•Ñ¥ŒÉ…Üµ•…¸¸ˆ}¸)™¥±”±½Í”ÁÁ¹½Ñ”()¹½¤‘¥ÍÁ±…ä…ÌÑ•áÐ€ˆôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôˆ)¹½¤‘¥ÍÁ±…ä…ÌÉ•ÍÕ±Ð€‰XÄÔ¸ÄA=MPµAI=MM%9=5A1Qˆ)¹½¤‘¥ÍÁ±…ä…ÌÉ•ÍÕ±Ð€‰=ÕÑÁÕÑÌèA=MPœˆ)¹½¤‘¥ÍÁ±…ä…ÌÉ•ÍÕ±Ð€‰]½É­‰½½¬è	==,œˆ)¹½¤‘¥ÍÁ±…ä…ÌÑ•áÐ€‰9¼É…Ü‘…Ñ„Ý•É”É•‰Õ¥±Ð…¹Ñ¡”€äääµÉ•À‰½½ÑÍÑÉ…ÀÝ…Ì¹½ÐÉ•ÉÕ¸¸ˆ)¹½¤‘¥ÍÁ±…ä…ÌÑ•áÐ€ˆôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôôˆ()±½œ±½Í”(