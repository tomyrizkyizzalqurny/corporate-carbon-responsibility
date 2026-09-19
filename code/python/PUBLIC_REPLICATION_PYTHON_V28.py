#!/usr/bin/env python3
"""Open-source computational demonstration for the Moral Economy of Carbon Responsibility paper.

Uses deterministic synthetic/representative data only. It demonstrates key variable construction,
overlap weighting, clustered regression, BH-FDR, interactions, and moral-configuration logic.
It does NOT reproduce or validate the article's numerical estimates. Full numerical replication
requires authorized access to the licensed LSEG/Refinitiv source fields.
"""
from pathlib import Path
import sys
import numpy as np
import pandas as pd
import statsmodels.api as sm
import statsmodels.formula.api as smf

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data" / "PUBLIC_REPLICATION_SYNTHETIC_V26.csv"
OUT = ROOT / "outputs_python_v28"
OUT.mkdir(exist_ok=True)

def bh(p):
    p=np.asarray(p,float); n=len(p); order=np.argsort(p); ranked=p[order]*n/np.arange(1,n+1)
    q=np.minimum.accumulate(ranked[::-1])[::-1]; out=np.empty(n); out[order]=np.minimum(q,1); return out

def fit_wls(formula, data, weights, cluster):
    m=smf.wls(formula, data=data, weights=weights).fit(cov_type='cluster', cov_kwds={'groups':cluster})
    return m

# Load full synthetic 2021-2025 panel
x=pd.read_csv(DATA)
assert len(x)==500 and x['firm_id'].nunique()==100 and set(x['year'])==set(range(2021,2026))
x=x.sort_values(['firm_id','year']).copy()

# Frozen core derivations
assert np.allclose(x['s12_int'], x['s1_int']+x['s2_int'], rtol=1e-10, atol=1e-10)
x['ln_s12_int']=np.log1p(x['s12_int'])
x['ln_assets']=np.log(x['assets'].where(x['assets']>0))
x['roa']=x['net_income']/x['assets']
x['tangibility']=x['ppe']/x['assets']
x['cash_ratio']=x['cash']/x['assets']
x['npm']=x['net_income']/x['revenue'].where(x['revenue']>0)
x['ln_revenue']=np.log(x['revenue'].where(x['revenue']>0))
x['dln_revenue']=x.groupby('firm_id')['ln_revenue'].diff()
x['dln_assets']=x.groupby('firm_id')['ln_assets'].diff()
x['asset_turn']=x['revenue']/((x['assets']+x.groupby('firm_id')['assets'].shift(1))/2)
x['current_ratio']=x['current_assets']/x['current_liab'].where(x['current_liab']>0)
x['wc_assets']=(x['current_assets']-x['current_liab'])/x['assets']
for v in ['roa','npm','dln_revenue','dln_assets','asset_turn','cash_ratio','current_ratio','wc_assets','ln_s12_int']:
    x[f'f1_{v}']=x.groupby('firm_id')[v].shift(-1)

# Formative governance architecture: missing is not zero
g9=['clim_policy','clim_commit','clim_riskopp','clim_strategy','clim_riskassess','scenario','risk_integrated','carbon_price_flag','emiss_trading']
gcommit=['clim_policy','clim_commit','clim_strategy']
ginteg=['clim_riskopp','clim_riskassess','scenario','risk_integrated']
gimpl=['carbon_price_flag','emiss_trading','phaseout_carbon']
for c in g9+['phaseout_carbon']:
    x[c]=pd.to_numeric(x[c], errors='coerce')
x['gov_breadth9']=x[g9].mean(axis=1).where(x[g9].notna().all(axis=1))
x['gov_commit']=x[gcommit].mean(axis=1).where(x[gcommit].notna().all(axis=1))
x['gov_integration']=x[ginteg].mean(axis=1).where(x[ginteg].notna().all(axis=1))
x['gov_implementation']=x[gimpl].mean(axis=1).where(x[gimpl].notna().all(axis=1))
x['gov_depth']=((x['gov_integration']+x['gov_implementation'])/2).where(x[['gov_integration','gov_implementation']].notna().all(axis=1))
x['gov_coherence']=x[['gov_commit','gov_integration','gov_implementation']].min(axis=1).where(x[['gov_commit','gov_integration','gov_implementation']].notna().all(axis=1))

# Predictor period
m=x.loc[x['year'].between(2021,2024)].copy()
assert len(m)==400 and m['firm_id'].nunique()==100

# Nonlinear propensity balancing device (country is context, not treatment)
ps_formula='indonesia ~ ln_assets + I(ln_assets**2) + roa + I(roa**2) + tangibility + I(tangibility**2) + cash_ratio + I(cash_ratio**2) + C(year) + C(sector_id)'
ps=smf.glm(ps_formula, data=m, family=sm.families.Binomial()).fit()
m['pscore']=ps.predict(m)
m['ow_final']=np.where(m['indonesia'].eq(1),1-m['pscore'],m['pscore'])
assert ((m['ow_final']>0)&(m['ow_final']<1)).all()
controls='ln_assets + roa + tangibility + cash_ratio + C(year) + C(sector_id)'

# RQ1
rq1=fit_wls('ln_s12_int ~ indonesia + '+controls,m,m['ow_final'],m['firm_id'])
pd.DataFrame([{'model':'Synthetic RQ1 demonstration','beta_indonesia':rq1.params['indonesia'],'se':rq1.bse['indonesia'],'pvalue':rq1.pvalues['indonesia'],'N':int(rq1.nobs)}]).to_csv(OUT/'RQ1_PYTHON_DEMO_V28.csv',index=False)

# RQ2 architecture + BH
rows=[]
for v in ['gov_breadth9','gov_depth','gov_coherence']:
    z=m.dropna(subset=[v]).copy(); mod=fit_wls(f'ln_s12_int ~ {v} + indonesia + '+controls,z,z['ow_final'],z['firm_id'])
    rows.append({'architecture':v,'beta':mod.params[v],'se':mod.bse[v],'pvalue':mod.pvalues[v],'N':int(mod.nobs)})
rq2=pd.DataFrame(rows); rq2['q_bh']=bh(rq2['pvalue']); rq2.to_csv(OUT/'RQ2_PYTHON_DEMO_V28.csv',index=False)

# RQ3 t+1 economic outcomes + BH
yvars=['f1_roa','f1_npm','f1_dln_revenue','f1_dln_assets','f1_asset_turn','f1_cash_ratio','f1_current_ratio','f1_wc_assets']
rows=[]
for y in yvars:
    z=m.dropna(subset=[y]).copy(); mod=fit_wls(f'{y} ~ ln_s12_int + indonesia + '+controls,z,z['ow_final'],z['firm_id'])
    rows.append({'outcome':y,'beta_carbon':mod.params['ln_s12_int'],'se':mod.bse['ln_s12_int'],'pvalue':mod.pvalues['ln_s12_int'],'N':int(mod.nobs)})
rq3=pd.DataFrame(rows); rq3['q_bh']=bh(rq3['pvalue']); rq3.to_csv(OUT/'RQ3_PYTHON_DEMO_V28.csv',index=False)

# RQ4 governance x context demonstration
rows=[]
for v in ['gov_breadth9','gov_depth','gov_coherence']:
    z=m.dropna(subset=[v]).copy(); mod=fit_wls(f'ln_s12_int ~ {v} * indonesia + '+controls,z,z['ow_final'],z['firm_id'])
    term=f'{v}:indonesia'
    rows.append({'architecture':v,'interaction_beta':mod.params[term],'se':mod.bse[term],'pvalue':mod.pvalues[term],'N':int(mod.nobs)})
rq4=pd.DataFrame(rows); rq4['q_bh']=bh(rq4['pvalue']); rq4.to_csv(OUT/'RQ4_PYTHON_DEMO_V28.csv',index=False)

# Descriptive moral-economy map, exact P50 logic
gcut=m['gov_depth'].median()
m['high_gov']=np.where(m['gov_depth'].notna(),m['gov_depth'].ge(gcut),np.nan)
med=m.groupby(['year','sector_id'])['ln_s12_int'].transform('median')
m['better_carbon']=m['ln_s12_int'].le(med)
cond=[(m.high_gov==1)&m.better_carbon,(m.high_gov==1)&(~m.better_carbon),(m.high_gov==0)&m.better_carbon,(m.high_gov==0)&(~m.better_carbon)]
m['moral_config']=np.select(cond,[1,2,3,4],default=np.nan)
cfg=(m.dropna(subset=['moral_config']).groupby(['country','moral_config']).size().rename('N_config').reset_index())
cfg['N_country']=cfg.groupby('country')['N_config'].transform('sum'); cfg['pct_country']=100*cfg.N_config/cfg.N_country
cfg.to_csv(OUT/'MORAL_CONFIGURATION_PYTHON_DEMO_V28.csv',index=False)

(OUT/'PUBLIC_DEMO_VALIDATION_STATUS_PYTHON_V28.txt').write_text(
    'PUBLIC OPEN-SOURCE DEMONSTRATION V28 = PASS\n'
    'Input: deterministic synthetic/representative data only.\n'
    'Rows: 500 full panel; 400 predictor-period rows; 100 synthetic firms.\n'
    'Carbon formula identity: PASS.\n'
    'Overlap weights bounded in (0,1): PASS.\n'
    'RQ1-RQ4 and configuration outputs produced.\n'
    'This route validates workflow logic only and does not reproduce article coefficients.\n', encoding='utf-8')
print('PUBLIC OPEN-SOURCE DEMONSTRATION V28 = PASS')
