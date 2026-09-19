# Run instructions

## A. Open-source demonstration (no licensed data required)

Requirements: Python 3 plus `numpy`, `pandas`, and `statsmodels`.

From the repository root:

```bash
python code/python/PUBLIC_REPLICATION_PYTHON_V28.py
```

Input: `data/PUBLIC_REPLICATION_SYNTHETIC_V26.csv`.

Output: `outputs_python_v28/`.

The demonstration validates workflow logic only and does not reproduce article coefficients.

## B. Licensed-data production route

Requirements: authorized LSEG/Refinitiv exports, Stata/MP 17, and Python 3.

1. Clone the repository.
2. Create `Data Mentah/` at the repository root.
3. Place only your authorized LSEG/Refinitiv production exports in that local directory. The directory is ignored by Git and must not be committed.
4. Start Stata with the repository root as the working directory.
5. Run `code/stata/00_MASTER_MORAL_ECONOMY_FINAL_V15_HARDENED.do`.
6. After the frozen production run, use `code/stata/03_EXTENDED_DATA_V24.do` and `code/stata/99_POSTPROCESSING_SUBMISSION_V15.do` as documented.
7. `code/stata/12_FINAL_PATCH_Q1_v1.do` is retained as the executed final Q1 inference patch and expects the historical Q1 intermediate files described inside that script.

## Important

The production helper contains structural expectations for the audited vendor export partitions. It does not contain the underlying licensed observations. If a future authorized export changes the vendor workbook layout, the parsing guardrails may require adaptation rather than silent coercion.
