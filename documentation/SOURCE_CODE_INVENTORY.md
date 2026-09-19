# Source-code inventory

This GitHub repository is the public version-control location for the study's author-written source code. The permanent publication-time snapshot is deposited on Zenodo at DOI **10.5281/zenodo.22764482**.

## Publicly version-controlled here

- `code/python/_build_refinitiv_raw_to_canonical_V15.py` — deterministic standard-library reconstruction helper for authorized LSEG/Refinitiv exports. The public copy removes the original machine-specific fallback path while preserving parsing logic and guardrails.
- `code/python/PUBLIC_REPLICATION_PYTHON_V28.py` — open-source synthetic-data demonstration of key derivations, overlap weighting, clustered regression, BH-FDR, context interactions, and descriptive configuration logic.
- `code/stata/03_EXTENDED_DATA_V24.do` — post-freeze Extended Data and repository-audit production code.
- `code/stata/99_POSTPROCESSING_SUBMISSION_V15.do` — submission-stage post-estimation and packaging code, with the machine-specific project root replaced by the current working directory.
- `code/stata/archive/12_FINAL_PATCH_Q1_v1.do.gz` — compressed public copy of the final Q1 inference patch. `code/stata/archive/README.md` provides the extraction command and SHA-256 checksum for the reconstructed `.do` file.
- `code/stata/archive/00_MASTER_MORAL_ECONOMY_FINAL_V15_HARDENED.do.gz.part00` and `part01` — two consecutive parts of the compressed sanitized V15 production master. The archive README documents exact reconstruction commands and SHA-256 checksums.

## Public documentation and validation material

- `documentation/DATA_DICTIONARY_AND_FIELD_MAP_V26.xlsx` — variable definitions, derivations, source-field roles, and licensing boundaries.
- `documentation/EXTENDED_DATA_MASTER_ARCHITECTURE_V24.txt` — Extended Data architecture and provenance.
- `documentation/RUN_INSTRUCTIONS.md` — public-demo and authorized-data workflow.
- `documentation/DATA_ACCESS_AND_LICENSING.md` — public/private data boundary.
- `validation/FINAL_Q1_BOOTSTRAP_SUMMARY.csv` — aggregate final Q1 bootstrap evidence only; no firm-level observations.
- `validation/PUBLIC_DEMO_VALIDATION_STATUS_PYTHON_V28.txt` — status record from the executed open-source demonstration.

## Archived on Zenodo

The Zenodo snapshot preserves the publication-time reproducibility package, including the synthetic demonstration dataset, publication-facing Extended Data workbook, full source package, validation materials, and executed bootstrap evidence.

## Licensing boundary

Author-written source code is released under the MIT License. Synthetic demonstration data and public documentation are provided under CC BY 4.0. Licensed LSEG/Refinitiv row-level observations are not public, are not included in either public repository, and are not relicensed.

## Reproducibility interpretation

The public repository supports inspection of computational logic and version control. Full numerical reproduction of article coefficients requires authorized access to equivalent LSEG/Refinitiv source fields. The synthetic demonstration workflow validates computational structure only and is not an independent numerical replication of the article results.
