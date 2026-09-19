# Source-code inventory

This GitHub repository is the public version-control location for the study's author-written source code. The permanent archived snapshot is deposited on Zenodo at DOI **10.5281/zenodo.22764482**.

## Publicly version-controlled here

- `code/python/_build_refinitiv_raw_to_canonical_V15.py` — deterministic standard-library reconstruction helper for authorized LSEG/Refinitiv exports. The public copy removes the original machine-specific fallback path but preserves the parsing logic and guardrails.
- `code/python/PUBLIC_REPLICATION_PYTHON_V28.py` — open-source synthetic-data demonstration of key derivations, overlap weighting, clustered regression, BH-FDR, context interactions, and descriptive configuration logic.
- `code/stata/03_EXTENDED_DATA_V24.do` — post-freeze Extended Data and repository-audit production code, with the machine-specific project root replaced by the current working directory.

## Archived on Zenodo

The Zenodo snapshot additionally preserves the frozen production, validation, post-processing, and final Q1 inference materials accompanying the article, including the Stata production master, validation materials, Extended Data, data dictionary/field map, synthetic demonstration data, and executed bootstrap evidence.

## Licensing boundary

Author-written source code is released under the MIT License. Synthetic demonstration data and documentation are provided under CC BY 4.0. Licensed LSEG/Refinitiv row-level observations are not public, are not included in either repository, and are not relicensed.

## Reproducibility interpretation

The public repository supports inspection of computational logic and version control. Full numerical reproduction of article coefficients requires authorized access to equivalent LSEG/Refinitiv source fields. The synthetic demonstration workflow is not an independent numerical replication of the article results.
