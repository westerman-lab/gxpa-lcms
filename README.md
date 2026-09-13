# Dependencies

These scripts depend on pulling data from a Terra workspace. To run all code, you will need access to the following workspaces:

* [`bdcmsg22/QC_metabolomics`](https://app.terra.bio/#workspaces/bdcmsg22/QC_metabolomics)
* [`mgb-KEW-K01-GCP/gxpa-lcms-mediation`](https://app.terra.bio/#workspaces/mgb-KEW-K01-GCP/gxpa-lcms-mediation)
* [`manning-lab-2024-2025/manning-lab-2024-2025-topmed-analysis`](https://app.terra.bio/#workspaces/manning-lab-2024-2025/manning-lab-2024-2025-topmed-analysis)

In addition, script `01b` will only work if run in Terra, as it depends on the `tnu` command for fast random access of the TOPMed genotype data.

If you only want to run the analysis scripts (`02*` and beyond), you only need access to [`mgb-KEW-K01-GCP/gxpa-lcms-mediation`](https://app.terra.bio/#workspaces/mgb-KEW-K01-GCP/gxpa-lcms-mediation).

This code will only work on Linux or Mac (not Windows), because it uses `parallel::mcMap/mclapply`.

# GxPA LC-MS

The overall goal of this project is to identify metabolite mediators of a previously-identified gene-physical activity interaction, using MESA as the primary dataset.

The analysis is organized as a set of R Jupyter notebooks (`.ipynb`), numbered in the order in which they
should be run. The numbering groups them into stages: `01*` prepares the MESA data, `02*` is the MESA
analysis, `03*` is the FHS replication, and `04` is the simulation study, which depends on no other step
and can be run at any time. `manuscript.Rmd` is the final synthesis and reads results from all of them.

* `00_picsure.ipynb`: Downloads phenotype data from PIC-SURE. **Note**: you must log into [https://picsure.biodatacatalyst.nhlbi.nih.gov/](https://picsure.biodatacatalyst.nhlbi.nih.gov/), get an API access token, and store it in a file named `picsure_token.txt` in your working directory.
* `01a_metabolomics_preprocessing.ipynb`: Formats and QCs the MESA LC-MS metabolomics data. Also separates the sample/metabolite metadata into separate files.
* `01b_genotype_preprocessing.ipynb`: This notebook **only works on Terra** because it depends on the `tnu` command to access genetic data files through DRS URIs (specified in `geno_files_drs.csv`). This script extracts the dosages for the variants specified in `variants_of_interest.csv` from the MESA and FHS VCF files.
* `01c_phenotype_preprocessing_and_merging.ipynb`: Merges all phenotypic data from PIC-SURE, metabolomics data, and variant dosages into one big dataframe.
* `02a_exploratory_plots.ipynb`: Exploratory analysis testing various sets of covariates, metabolite PC ~ covariate associations, and plotting phenotype variable distributions.
* `02b_analysis.ipynb`: Main analysis.
* `02c_mummichog.ipynb`: Runs mummichog using the GxMetabolite interaction estimates from the MWIS from step `02b`. **Note**: mummichog requires Python 3.8 specifically, so it may be more convenient to run this notebook locally using [`pyenv`](https://github.com/pyenv/pyenv) than on Terra.
* `03a_aligned_metabolomics_preprocessing.ipynb`: Analogous to step `01a`, but for the FHS+MESA+WHI aligned metabolomics data.
* `03b_fhs_phenotype_merging.ipynb`: Analogous to step `01c`, but for FHS instead of MESA.
* `03c_fhs_analysis.ipynb`: Analogous to step `02b`, but for FHS instead of MESA. Additionally, this script reads the results of `02b` and only seeks to replicate results for the metabolites that were significant in MESA, to save computational cost (models take much longer to run in FHS than in MESA, likely because the FHS kinship matrix is more dense than in MESA which means adjusting for kinship takes longer).
* `04_simulation.ipynb`: Simulation study characterizing the operating characteristics (power and Type I error) of the GxE molecular-mediator screening pipeline across four causal scenarios (downstream signaling, upstream bioaccumulation, reverse causation, and a confounded null). Self-contained: it reads no project data and depends on no other notebook.
* `manuscript.Rmd`: Renders the tables and figures for the manuscript from the results written by the numbered notebooks. Reads only from `results/`, never refits a model, and skips any section whose input is absent.

# Upstream QC artifacts (`results/qc/`)

`manuscript.Rmd` reads `results/` and nothing else. That is deliberate: `analysis_df-mesa.csv`
and the metabolite intensity matrices are individual-level TOPMed data and stay on Terra, which
is why the report's redundancy section goes blank on a local knit. So every upstream QC decision
that has to be auditable in the report is written out as a small summary table into `results/qc/`,
published to the workspace bucket by the notebook that makes it, and rendered by the report's
**Upstream QC** section.

| Written by | Files | What it settles |
|---|---|---|
| `01a` | `metabolite_qc_steps`, `metabolite_distributions`, `metabolite_qc_quantiles` | Features and samples surviving each QC step, missingness, and the pooled-QC CV |
| `01b` | `genotype_qc` | Call rate and which allele each dosage counts |
| `01c` | `sample_flow`, `metabolomics_lane_coverage`, `imputation_ledger`, `variable_distributions`, `lipid_medication`, `icc`, `metabolite_icc`, `metabolite_icc_summary`, `genotype_by_race` | The Methods n's, what was imputed, exposure/outcome distributions by exam, within-person ICCs, allele frequency by self-identified race |
| `02a` | `table_s1_characteristics`, `analysis_n_by_exam`, `covariate_ladder`, `covariate_variance_explained`, `mpc_covariate_pvalues` | Table S1, and the evidence for the adjustment set |
| `02b` | `m_eff_estimators`, `metabolite_eigenvalues` | The effective number of tests, and how much the screen threshold depends on which estimator is used |

To refresh them locally after a re-run on Terra:

```
gcloud storage cp 'gs://fc-secure-4a392455-5587-4d6f-b8bd-01a1f834ae63/results/qc/*' ../results/qc/
```

Sections whose input is missing print what they are waiting for rather than failing the render,
so a partially copied `results/qc/` still knits.

# Hand-maintained tables

Three small CSVs are edited by hand rather than produced by a notebook. All three are
versioned here, but **the copy that takes effect is the one published to the workspace
bucket**, because that is the only copy the notebooks can read:

| File | Read by | Ground truth |
|---|---|---|
| `anchors.csv` | `01c`, `02a`, `02b`, `02c`, `03c`, `manuscript.Rmd` | **workspace bucket** |
| `variants_of_interest.csv` | `01b`, `02b`, `03c`, `manuscript.Rmd` | **workspace bucket** |
| `geno_files_drs.csv` | `01b` | **workspace bucket** |

On Terra only `*.ipynb` files are copied into the VM's working directory, so a notebook
running there cannot read a CSV that lives only in the repo.

**After editing any of them, publish it** — otherwise the change is invisible to every
notebook, and the two copies silently diverge:

```
gcloud storage cp anchors.csv variants_of_interest.csv geno_files_drs.csv \
  gs://fc-secure-4a392455-5587-4d6f-b8bd-01a1f834ae63/
```

Run that from this directory on a machine with `gcloud` authenticated; it does not involve
the Terra notebook-sync path. `manuscript.Rmd` reads the published copies and flags any
that the repo copy has drifted from.

## Lanes (`anchors.csv`)

A **lane** is one declared (SNP, outcome, exposure) triple whose interaction the paper
follows up. `anchors.csv` is the single declaration of them: no notebook names a SNP, an
outcome or an exposure itself, so adding, removing or parking a lane is one row here.

| Column | Meaning |
|---|---|
| `lane_id` | Short unique key, e.g. `fto_mvpa_bmi`. Every results file is keyed by it. |
| `G`, `Y`, `E` | Dosage column, outcome and exposure, as named in the analysis frame. `G` must equal the `cpaid` in `variants_of_interest.csv`, which in turn must equal `chr_pos_ref_alt` — `01b` names dosage columns from ref/alt, and `02b` stops if they disagree. |
| `rsid`, `gene`, `label` | Display. |
| `include` | `TRUE` = reported by `manuscript.Rmd`. `FALSE` lanes are **still screened** by `02b` and replicated by `03c`; their rows stay in `results/` and are simply not reported. |
| `extra_covars` | Optional covariates for this lane only, space-separated, added to its interaction models (GxE, the metabolome-wide screen, the GxCovar sensitivity) but not to the marginal Y~G / E~G checks, which lanes can share. |
| `provenance` | Why the lane is here. |

Rules enforced on read, in every notebook:

* **A lane may not use one trait on both sides.** Traits are compared ignoring the
  derivation suffix, so `bmi_covariate` and `bmi` are the same trait and such a lane is
  refused outright.
* **No model adjusts for its own outcome or exposure.** Covariates — including
  `extra_covars` — are filtered by trait, not by name. A name-level `setdiff` would miss
  exactly the case that matters: `bmi_covariate` as a precision covariate in a lane whose
  outcome is `bmi`.
* The **primary lane** is the first `include = TRUE` row. It defines the sample Table S1
  and the n-by-exam export describe, so reordering rows changes it.

BMI appears under two names on purpose, and the difference is imputation. `bmi` is the
value **as measured** -- neither winsorized nor filled in -- and is the **outcome** of the
FTO lane. `bmi_covariate` is a copy that is winsorized, median-imputed at exam 1 and carried
forward, and is what the CETP lanes use as their **exposure** and what any lane would use as
a covariate. The rule is the same for every outcome: an imputed value is acceptable on the
right-hand side of a model, never on the left -- which is also why HDL and TG are not carried
forward. BMI is left untransformed (per-allele FTO effects are conventionally reported in
kg/m2), whereas the lipid outcomes are logged.

# Repository workflow

The source of truth for this project is the GitHub repository [`westerman-lab/gxpa-lcms`](https://github.com/westerman-lab/gxpa-lcms). Notebooks are versioned as `.ipynb`, and cell outputs are stripped automatically on commit by [`nbstripout`](https://github.com/kynan/nbstripout) (declared in `.gitattributes`), so only clean source is tracked. Generated outputs (HTML, figures, `*_cache/`, `*_files/`, data files) are gitignored.

* **Terra (run and edit):** Clone this repo onto the cloud-environment persistent disk in a directory that is *not* named after a workspace, so Terra's notebook auto-sync leaves it alone. Edit and run in JupyterLab from that folder, then commit and push from the Terra terminal. See [`TERRA_SETUP.md`](TERRA_SETUP.md) for the one-time setup.
* **Laptop (inspect and version):** `git pull` to inspect; commit and push as usual.

Any clone that will commit notebooks must have `nbstripout` installed and `nbstripout --install` run once, which configures the per-clone git filter. The shared `.gitattributes` declares the filter, but the filter program itself must be present in each clone (`pip install nbstripout`).

# Notes:

* Running locally, you need to install the [GCloud CLI](https://cloud.google.com/sdk/docs/install) and do `gcloud auth login`. The scripts rely on pulling data from the Terra workspace bucket.
