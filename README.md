# Corporate Carbon Responsibility in Indonesia and the United States

Public source code and reproducibility materials for the F1000Research article:

**Corporate Carbon Responsibility in Indonesia and the United States: A Moral-Economy Perspective on Climate Governance, Carbon Intensity, and Economic Outcomes**

Authors: Tomy Rizky Izzalqurny, Rani Destia Wahyuningsih, Oktaviana Safitri, Astriyanti Astriyanti, Bagus Aditoro, Annisa Dwi Putri, Muhammad Ghozali, and Nuriah Muyassaroh.

## Repository purpose

This repository is the public version-control location for author-written source code and reproducibility documentation used in the study. The permanent publication-time reproducibility and Extended Data package is archived on Zenodo at DOI **10.5281/zenodo.22764482**.

The empirical study uses licensed LSEG/Refinitiv firm-level observations. Those observations are **not redistributed here**. Full numerical reproduction of the published coefficients requires authorized access to the relevant LSEG/Refinitiv source fields. The archived synthetic demonstration dataset contains no real firm identifiers or licensed row-level observations and is intended to demonstrate computational structure only.

## Repository structure

- `code/stata/` — Stata Extended Data and submission post-processing code; large frozen source files are preserved under `code/stata/archive/` with documented reconstruction commands and checksums.
- `code/python/` — deterministic raw-export reconstruction helper and open-source synthetic-data demonstration.
- `data/` — documentation for the public synthetic demonstration input; the publication-time dataset is archived on Zenodo.
- `extended_data/` — documentation linking to the permanent Extended Data archive.
- `documentation/` — data dictionary, reproducibility architecture, licensing boundary, source-code inventory, and run instructions.
- `validation/` — aggregate validation evidence and public-demo validation status.

## Key code files

- `code/stata/archive/00_MASTER_MORAL_ECONOMY_FINAL_V15_HARDENED.do.gz.part00` + `part01` — sanitized compressed V15 production master; reconstruction instructions and SHA-256 checksums are in `code/stata/archive/README.md`.
- `code/python/_build_refinitiv_raw_to_canonical_V15.py` — Python standard-library helper used by the production master to reconstruct the canonical panel from authorized vendor exports.
- `code/stata/03_EXTENDED_DATA_V24.do` — post-freeze Extended Data production and repository audit.
- `code/stata/99_POSTPROCESSING_SUBMISSION_V15.do` — submission-stage post-estimation and packaging outputs.
- `code/stata/archive/12_FINAL_PATCH_Q1_v1.do.gz` — compressed final Q1 inference patch, including the two-stage firm-cluster bootstrap; reconstruction instructions and checksum are in the archive README.
- `code/python/PUBLIC_REPLICATION_PYTHON_V28.py` — open-source computational demonstration using only the deterministic synthetic dataset.

Historical internal file labels (for example, V15, V24, V28, or older working article titles embedded in comments) are retained where necessary for provenance. They do not indicate separate publications or different empirical datasets.

## Quick public demonstration

Install the Python requirements:

```bash
python -m pip install -r requirements.txt
```

Download `PUBLIC_REPLICATION_SYNTHETIC_V26.csv` from the Zenodo reproducibility package (DOI `10.5281/zenodo.22764482`) and place it in `data/`, then run from the repository root:

```bash
python code/python/PUBLIC_REPLICATION_PYTHON_V28.py
```

The script writes demonstration outputs to `outputs_python_v28/`. The public route has been executed successfully and validates workflow logic only; it is not expected to reproduce the article's numerical estimates.

## Licensed-data production route

Researchers with authorized LSEG/Refinitiv access can use the public field map, reconstruction helper, and archived source code to reconstruct equivalent source fields. Place authorized raw workbooks in a local `Data Mentah/` directory at the repository root. That directory is excluded by `.gitignore` and must never be committed.

The public copies of the production scripts remove machine-specific local paths while preserving the scientific model definitions, audit checks, and guardrails. See `documentation/RUN_INSTRUCTIONS.md` and `documentation/DATA_ACCESS_AND_LICENSING.md` before use.

## Software

The production analysis used Stata/MP 17 and Python 3. Figures were generated using Matplotlib 3.10.8. Stata is proprietary software; the repository also includes an open-source Python demonstration route.

## Licensing

Author-written Stata/Python source code is released under the **MIT License**. Public synthetic demonstration data and repository documentation are provided under **CC BY 4.0**. Licensed LSEG/Refinitiv source observations are excluded from these licenses and are not redistributed.

## Citation

Archived software and reproducibility package:

> Izzalqurny, T. R., et al. (2026). *Corporate Carbon Responsibility in Indonesia and the United States: Reproducibility and Extended Data Package*. Zenodo. https://doi.org/10.5281/zenodo.22764482

See `CITATION.cff` for machine-readable citation metadata.

## Reproducibility boundary

This repository supports inspection and version control of code, transformations, model definitions, documentation, and the synthetic workflow. It does not turn licensed third-party data into open data and should not be interpreted as independent numerical replication of the published results without authorized LSEG/Refinitiv access.
