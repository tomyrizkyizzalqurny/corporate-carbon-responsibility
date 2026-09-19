# Archived Stata source files

This directory contains compressed public copies of large Stata source files that could not be committed through the text-only contents endpoint used for the initial repository build. The files are author-written source code under the MIT License and contain no licensed LSEG/Refinitiv row-level observations.

## V15 production master

The sanitized production master is stored as two consecutive parts of one gzip stream:

- `00_MASTER_MORAL_ECONOMY_FINAL_V15_HARDENED.do.gz.part00`
- `00_MASTER_MORAL_ECONOMY_FINAL_V15_HARDENED.do.gz.part01`

Reconstruct on Linux/macOS/Git Bash:

```bash
cat 00_MASTER_MORAL_ECONOMY_FINAL_V15_HARDENED.do.gz.part00 \
    00_MASTER_MORAL_ECONOMY_FINAL_V15_HARDENED.do.gz.part01 \
    > 00_MASTER_MORAL_ECONOMY_FINAL_V15_HARDENED.do.gz

gunzip 00_MASTER_MORAL_ECONOMY_FINAL_V15_HARDENED.do.gz
```

SHA-256 of the reconstructed sanitized `.do` source:

`af4bda40e2ede50b4487cbf73e1e37af19a3fea74bea47bead9c2d07ea681683`

SHA-256 of the intermediate gzip archive:

`8e128305e43fa88fd2aa030a34d215ede8bd8bb61810584a4f3cb092a650c6ce`

## Final Q1 inference patch

`12_FINAL_PATCH_Q1_v1.do.gz` is a gzip-compressed copy of the final Q1 Stata inference patch.

```bash
gunzip 12_FINAL_PATCH_Q1_v1.do.gz
```

SHA-256 of the reconstructed `.do` source:

`0fde7ad6ecd1b83fca7f3f45c7274895857cc31705f60550412ed1bae7967c25`

SHA-256 of the gzip archive:

`057357076662bd05505c038da16fece6e1500bdc1cd79dc16b927406d21128ee`

The permanent publication-time snapshot is also archived on Zenodo at DOI `10.5281/zenodo.22764482`.
