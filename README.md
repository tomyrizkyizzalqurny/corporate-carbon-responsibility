# Corporate Carbon Responsibility in Indonesia and the United States

Public source code and reproducibility materials for the F1000Research article:

**Corporate Carbon Responsibility in Indonesia and the United States: A Moral-Economy Perspective on Climate Governance, Carbon Intensity, and Economic Outcomes**

Authors: Tomy Rizky Izzalqurny, Rani Destia Wahyuningsih, Oktaviana Safitri, Astriyanti Astriyanti, Bagus Aditoro, Annisa Dwi Putri, Muhammad Ghozali, and Nuriah Muyassaroh.

## Repository purpose

This repository provides the current public version-control location for author-written source code used in the study and a deterministic synthetic demonstration dataset. The article's archived reproducibility and Extended Data package is deposited on Zenodo at DOI **10.5281/zenodo.22764482**.

The empirical study uses licensed LSEG/Refinitiv firm-level observations. Those observations are **not redistributed here**. Full numerical reproduction of the published coefficients requires authorized access to the relevant LSEG/Refinitiv source fields. The public synthetic dataset is intended to demonstrate computational structure only and contains no real firm identifiers or licensed row-level observations.

## Repository structure

- `code/stata/` — frozen/archival Stata production, Extended Data, post-processing, and final Q1 inference code.
- `code/python/` — deterministic raw-export reconstruction helper and open-source synthetic-data demonstration.
- `data/` — deterministic synthetic demonstration dataset only.
- `documentation/` — reproducibility architecture and scope documentation.
- `validation/` — executed validation material retained for traceability.

## Key code files

- `00_MASTER_MORAL_ECONOMY_FINAL_V15_HARDENED.do` — end-to-end Stata production master for authorized LSEG/Refinitiv inputs.
- `_build_refinitiv_raw_to_canonical_V15.py` — Python standard-library helper used by the production master to reconstruct the canonical panel from licensed vendor exports.
- `03_EXTENDED_DATA_V24.do` — post-freeze Extended Data production and repository audit.
- `99_POSTPROCESSING_SUBMISSION_V15.do` — submission-stage post-estimation outputs.
- `12_FINAL_PATCH_Q1_v1.do` — final Q1 inference patch, including the two-stage firm-cluster bootstrap that re-estimates the comparability model, overlap weights, and outcome model within each replication.
- `PUBLIC_REPLICATION_PYTHON_V28.py` — open-source computational demonstration using only the synthetic dataset.

Historical internal file labels (for example, V15, V24, V28, or older working article titles embedded in comments) are retained where they are necessary for provenance. They do not indicate separate publications or different datasets.

## Quick public demonstration

From the repository root, create a Python environment with `numpy`, `pandas`, and `statsmodels`, then run:

```bash
python code/python/PUBLIC_REPLICATION_PYTHON_V28.py
```

The script reads `data/PUBLIC_REPLICATION_SYNTHETIC_V26.csv` and writes demonstration outputs to `outputs_python_v28/`. These outputs validate workflow logic; they are not expected to reproduce the article's numerical estimates.

## Licensed-data production route

Researchers with authorized LSEG/Refinitiv access can use the field map and archived repository materials on Zenodo to reconstruct equivalent source fields. For the production master, place authorized raw workbooks in a local `Data Mentah/` directory at the repository root. That directory is excluded by `.gitignore` and must never be committed.

The public copies of the production scripts have only machine-specific local paths removed; the scientific model definitions and guardrails are otherwise preserved.

## Software

The production analysis used Stata/MP 17 and Python 3. Figures were generated using Matplotlib 3.10.8. Stata is proprietary software; the repository also includes an open-source Python demonstration route.

## Licensing

Author-written Stata/Python source code is released under the **MIT License**. Synthetic demonstration data and repository documentation are provided under **CC BY 4.0**. Licensed LSEG/Refinitiv source observations are excluded from these licenses and are not redistributed.

## Citation

Archived software and reproducibility package:

> Izzalqurny, T. R., et al. (2026). *Corporate Carbon Responsibility in Indonesia and the United States: Reproducibility and Extended Data Package*. Zenodo. https://doi.org/10.5281/zenodo.22764482

See `CITATION.cff` for machine-readable citation metadata.

## Reproducibility boundary

The public repository supports transparency of code, transformations, model definitions, and a synthetic workflow demonstration. It does not turn licensed third-party data into open data and should not be interpreted as independent numerical replication of results without authorized LSEG/Refinitiv access.
