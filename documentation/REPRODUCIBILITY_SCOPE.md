# Reproducibility scope

## What this repository makes public

This repository makes the author-written analytical source code, reproducibility documentation, and deterministic synthetic demonstration data publicly inspectable under version control.

## What this repository does not distribute

The empirical article uses third-party LSEG/Refinitiv firm-level observations obtained under an institutional subscription. Raw or reconstructed row-level licensed observations are not distributed in this repository. No public file contains real firm identifiers copied from the licensed dataset.

## Numerical versus computational reproducibility

The synthetic dataset demonstrates computational structure and allows the open-source demonstration workflow to run. It is not row-derived from the licensed firm-level panel and cannot reproduce or independently validate the published coefficients. Full numerical reproduction requires authorized access to equivalent LSEG/Refinitiv source fields.

## Frozen empirical architecture

The final analytical architecture uses the frozen 2021–2024 comparable sample of 3,792 firm-year observations from 1,116 firms (250 Indonesia; 3,542 United States). The primary carbon construct is `ln(1 + Scope 1 + Scope 2 intensity)`. Main inference uses overlap weighting, year and sector fixed effects, firm-clustered inference, BH-FDR adjustment, and robustness/diagnostic layers documented in the archived Extended Data package.

## Version-control note

The public GitHub copies remove machine-specific local filesystem paths. This portability edit does not alter the substantive model definitions, estimands, or analytical guardrails.

## Permanent archive

The archived reproducibility and Extended Data package is available from Zenodo: DOI 10.5281/zenodo.22764482.
