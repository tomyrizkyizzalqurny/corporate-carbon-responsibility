# Repository manifest

This manifest describes the public GitHub release supporting the F1000Research manuscript **Corporate Carbon Responsibility in Indonesia and the United States: A Moral-Economy Perspective on Climate Governance, Carbon Intensity, and Economic Outcomes**.

## Public version-control components

### Source code
- `code/python/_build_refinitiv_raw_to_canonical_V15.py` — sanitized production reconstruction helper; no licensed observations are embedded.
- `code/python/PUBLIC_REPLICATION_PYTHON_V28.py` — open-source demonstration using synthetic data only.
- `code/stata/03_EXTENDED_DATA_V24.do` — Extended Data production/audit code.
- Additional frozen Stata production and validation scripts are part of the archived reproducibility package and should be mirrored here before manuscript resubmission.

### Documentation
- `README.md`
- `documentation/REPRODUCIBILITY_SCOPE.md`
- `documentation/RUN_INSTRUCTIONS.md`
- `documentation/EXTENDED_DATA_MASTER_ARCHITECTURE_V24.txt`
- `documentation/DATA_DICTIONARY_AND_FIELD_MAP_V26.xlsx`

### Validation
- `validation/FINAL_Q1_BOOTSTRAP_SUMMARY.csv` — aggregate bootstrap evidence only; no company-level observations.

## Archived package

Permanent archive: Zenodo DOI `10.5281/zenodo.22764482`.

The Zenodo archive is the persistent publication-time record. GitHub is the public version-control location for source code and documentation.

## Restricted material intentionally excluded

The following must not be committed: licensed LSEG/Refinitiv row-level observations, raw vendor workbooks, reconstructed firm-level datasets, `.dta` analytical files based on licensed observations, and private credentials or machine-specific secrets.

## Licensing

Author-written Stata/Python code: MIT License. Synthetic demonstration data and public documentation: CC BY 4.0. Third-party LSEG/Refinitiv observations are excluded from these licenses.
