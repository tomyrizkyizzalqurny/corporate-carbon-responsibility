# Public release status

Repository: `tomyrizkyizzalqurny/corporate-carbon-responsibility`

## Safety gate
- Licensed LSEG/Refinitiv row-level observations: **excluded**.
- Raw `GridExport_*.xlsx` vendor files: **excluded**.
- Real company identifiers in the public synthetic workflow: **not permitted**.
- Machine-specific Windows paths: **removed from the public source copies released here**.
- `.gitignore`: configured to block raw vendor data, private analytical datasets, and generated production outputs.

## Source-code gate
- V15 Python reconstruction helper: **public**.
- Python synthetic demonstration: **public**.
- V24 Extended Data Stata code: **public**.
- V15 submission post-processing Stata code: **public**.
- Final Q1 Stata inference patch: **public as a checksum-documented gzip archive**.
- Sanitized V15 production master: **public as a checksum-documented two-part gzip archive**.
- Reconstruction/extraction instructions: `code/stata/archive/README.md`.

## Reproducibility gate
- Python synthetic demonstration: **executed successfully (PASS)**.
- Public demonstration scope: computational/workflow validation only.
- Numerical reproduction of article coefficients: requires authorized LSEG/Refinitiv source fields.
- Final Q1 two-stage bootstrap evidence: 999 requested, 951 estimable, 48 non-estimable; aggregate summary released.
- Publication-time synthetic dataset and Extended Data workbook: archived permanently on Zenodo.

## Publication links
- GitHub source-code repository: https://github.com/tomyrizkyizzalqurny/corporate-carbon-responsibility
- Archived package: https://doi.org/10.5281/zenodo.22764482
- Code license: MIT License
- Synthetic data/documentation license: CC BY 4.0

This status file does not authorize redistribution of third-party licensed source data.
