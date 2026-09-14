# Dependencies

These scripts depend on pulling data from a Terra workspace. To run all code, you will need access to the following workspaces:

* [`bdcmsg22/QC_metabolomics`](https://app.terra.bio/#workspaces/bdcmsg22/QC_metabolomics)
* [`mgb-KEW-K01-GCP/gxpa-lcms-mediation`](https://app.terra.bio/#workspaces/mgb-KEW-K01-GCP/gxpa-lcms-mediation)
* [`manning-lab-2024-2025/manning-lab-2024-2025-topmed-analysis`](https://app.terra.bio/#workspaces/manning-lab-2024-2025/manning-lab-2024-2025-topmed-analysis)

In addition, script `01b` will only work if run in Terra, as it depends on the `tnu` command for fast random access of the TOPMed genotype data.

If you only want to run the analysis scripts (`02*` and beyond), you only need access to [`mgb-KEW-K01-GCP/gxpa-lcms-mediation`](https://app.terra.bio/#workspaces/mgb-KEW-K01-GCP/gxpa-lcms-mediation).

This code will only work on Linux or Mac (not Windows), because it uses `parallel::mcMap/mclapply`.

# GxPA LC-MS

A methods paper on gene-by-molecular-feature (GxM) interaction screening: when a gene-by-exposure
(GxE) interaction acts through a molecular intermediate, testing G against the measured molecule can
recover an interaction that is too diluted to detect against the exposure itself. It has three parts:
a simulation study of the test's operating characteristics (`04`), an applied metabolome-wide
interaction screen (MWIS) in MESA for a small set of declared GxE "lanes" (`01*`, `02*`), and an FHS
replication (`03*`). See **Project status** below for where things stand.

The analysis is organized as a set of R Jupyter notebooks (`.ipynb`), numbered in the order in which they
should be run. The numbering groups them into stages: `01*` prepares the MESA data, `02*` is the MESA
analysis, `03*` is the FHS replication, and `04` is the simulation study, which depends on no other step
and can be run at any time. `manuscript.Rmd` is the final synthesis and reads results from all of them;
`exploration.Rmd` is a separate, read-only design audit that never feeds it.

* `00_picsure.ipynb`: Downloads phenotype data from PIC-SURE. **Note**: you must log into [https://picsure.biodatacatalyst.nhlbi.nih.gov/](https://picsure.biodatacatalyst.nhlbi.nih.gov/), get an API access token, and store it in a file named `picsure_token.txt` in your working directory.
* `01a_metabolomics_preprocessing.ipynb`: Formats and QCs the MESA LC-MS metabolomics data (zero-variance features; C18-neg features eluting in the void volume, RT < 1 min; >25% missingness; half-minimum imputation, log2, 5-SD winsorization). Also separates the sample/metabolite metadata into separate files, and exports the per-feature pooled-QC CV.
* `01b_genotype_preprocessing.ipynb`: This notebook **only works on Terra** because it depends on the `tnu` command to access genetic data files through DRS URIs (specified in `geno_files_drs.csv`). This script extracts the dosages for the variants specified in `variants_of_interest.csv` from the MESA and FHS VCF files.
* `01c_phenotype_preprocessing_and_merging.ipynb`: Merges all phenotypic data from PIC-SURE, metabolomics data, and variant dosages into one big dataframe.
* `02a_exploratory_plots.ipynb`: Exploratory analysis testing various sets of covariates, metabolite PC ~ covariate associations, and plotting phenotype variable distributions.
* `02b_analysis.ipynb`: Main analysis. For every lane in `anchors.csv`: the known-association checks (Y~E, Y~G, E~G, GxE), the metabolome-wide GxM screen (`Y ~ G*M + G*E + covariates + G:sex + gPC*M + batch`, kinship and person random effects), the screen threshold (Li & Ji effective number of tests, with a simulated max-statistic threshold exported alongside), and sensitivity models. Also fits the metabolome-wide M~E coupling for each lane exposure, on design-only rows, for the design audit.
* `02c_mummichog.ipynb`: Runs mummichog using the GxMetabolite interaction estimates from the MWIS from step `02b`. **Note**: mummichog requires Python 3.8 specifically, so it may be more convenient to run this notebook locally using [`pyenv`](https://github.com/pyenv/pyenv) than on Terra.
* `03a_aligned_metabolomics_preprocessing.ipynb`: Analogous to step `01a`, but for the FHS+MESA+WHI aligned metabolomics data.
* `03b_fhs_phenotype_merging.ipynb`: Analogous to step `01c`, but for FHS instead of MESA.
* `03c_fhs_analysis.ipynb`: Analogous to step `02b`, but for FHS instead of MESA. It confirms the known associations per lane (FHS has no MVPA, so MVPA lanes skip the E-dependent models) and replicates only the metabolites significant in MESA, matching the MESA model as far as FHS allows. The FHS kinship matrix is sparsified in `03b` (relatedness < 0.025 zeroed, 0.01 ridge), without which each fit takes hours.
* `04_simulation.ipynb`: Simulation study characterizing the operating characteristics (power and Type I error) of the GxE molecular-mediator screening pipeline across four causal scenarios (downstream signaling, upstream bioaccumulation, reverse causation, and a confounded null). Self-contained: it reads no project data and depends on no other notebook.
* `manuscript.Rmd`: Renders the tables and figures for the manuscript from the results written by the numbered notebooks. Reads only from `results/`, never refits a model, and skips any section whose input is absent.
* `exploration.Rmd`: Design audit (scoping, not results): whether the MESA screen has any sensitivity at a calibrated threshold under design-only restrictions (annotation, QC-pool CV, E-M association, FHS alignability), with stratified calibration diagnostics. Read-only on `results/`; renders to `output/exploration/` with every output prefixed `exp_`; fails loudly if a required input (including `02b`'s `M_E_mwide_*` files) is missing. Render from this directory with `rmarkdown::render("exploration.Rmd", output_dir = "output/exploration")`. Its pre-committed primary design is D2 (annotated features only).

# Upstream QC artifacts (`results/qc/`)

`manuscript.Rmd` reads `results/` and nothing else. That is deliberate: `analysis_df-mesa.csv`
and the metabolite intensity matrices are individual-level TOPMed data and stay on Terra, which
is why the report's redundancy section goes blank on a local knit. So every upstream QC decision
that has to be auditable in the report is written out as a small summary table into `results/qc/`,
published to the workspace bucket by the notebook that makes it, and rendered by the report's
**Upstream QC** section.

| Written by | Files | What it settles |
|---|---|---|
| `01a` | `metabolite_qc_steps`, `metabolite_distributions`, `metabolite_qc_quantiles`, `metabolite_qc_pool_cv` | Features and samples surviving each QC step, missingness, and the pooled-QC CV (binned, and per feature) |
| `01b` | `genotype_qc` | Call rate and which allele each dosage counts |
| `01c` | `sample_flow`, `metabolomics_method_coverage`, `imputation_ledger`, `variable_distributions`, `lipid_medication`, `icc`, `metabolite_icc`, `metabolite_icc_summary`, `genotype_by_race` | The Methods n's, what was imputed, exposure/outcome distributions, within-person ICCs (participant repeated measures across exams, one-way ICC(1), on analysis-scale values), allele frequency by self-identified race. `lipid_medication` and fasting glucose/HbA1c are harmonized but no longer reported. |
| `02a` | `table_s1_characteristics`, `analysis_n_by_exam`, `covariate_ladder`, `covariate_variance_explained`, `mpc_covariate_pvalues` | Table S1, and the evidence for the adjustment set |
| `02b` | `m_eff_estimators`, `metabolite_eigenvalues` | The effective number of tests under Bonferroni, simpleM (99.5%), Li & Ji (used) and a simulated max statistic |

`02b` also writes, to `results/` itself: `Y_G`, `E_G`, `GxE`, `GxM_results` (the full screen),
`mesa_signif_GxMs` (hits; read by `03c`), `M_E` and `GxMpGxEpGxC` (sensitivity models for the hits),
`M_E_mwide_<exposure>` (metabolome-wide M~E, one file per lane exposure) and `analysis_params`
(threshold, estimator name, and the max-statistic threshold).

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

# Project status (2026-09-14)

**Lanes** (`anchors.csv`): `clasp1_mvpa_hdl` and `cetp_bmi_hdl` are reported; `fto_mvpa_bmi` is
screened but not reported (`include = FALSE`). `cetp_bmi_tg` was removed on 2026-09-14.

**Where the applied results stand.** The last full `02b` run (2026-09-14, four lanes, before the
changes below) found nothing beyond chance in the reported lanes: 4 and 2 hits at the old threshold
against about 3 expected per lane under the global null, with flat QQ plots. Under Li & Ji no
reported-lane hit survives. Most of the FTO lane's 21 hits were sodium-formate cluster ions in the
C18-neg void volume, which is what motivated the void-volume filter. The earlier Aug-1 finding still
frames the paper: the CLASP1 hits are not mediators under the dilution identity (their M~E coupling
is ~100x too small to carry the observed GxE), so the applied section is likely an honest worked
example with a stated limitation. `exploration.Rmd` exists to settle that on design grounds.

**Decisions** (dated; "after results" marks a choice made after GxM results had been seen, with
the reason it is not selection on them):

| Date | Decision |
|---|---|
| 2026-09-13 | Lanes architecture: `anchors.csv` is the single declaration; results keyed by `lane_id`; exact matching; a lane's own Y/E traits are dropped from its covariates. |
| 2026-09-13 | Outcomes are never imputed. `bmi` (as measured) vs `bmi_covariate` (winsorized, imputed); HDL and TG not carried forward; BMI untransformed. |
| 2026-09-14 | CETP x BMI -> TG dropped from the lanes. |
| 2026-09-14 | Screen threshold: Li & Ji (2005) replaces the participation ratio (after results; on theory: the participation ratio equals p/(1+(p-1)·mean r²), which at p ≈ 4,000 gives 68 effective tests and a family-wise error near 85% under diffuse weak correlation). A simulated max-statistic threshold is exported for comparison. |
| 2026-09-14 | C18-neg features with RT < 1 min removed in `01a` (after results; on QC grounds: 798 features, half the ICC of the rest, 0.3% annotated, inflating lambda in every lane including null ones). |
| 2026-09-14 | Fasting glucose and HbA1c: harmonized in `01c`, excluded from every analysis and from the report. |
| 2026-09-14 | Design audit (`exploration.Rmd`): primary design D2 (annotated features) pre-committed before the audit is run; M_eff approximated as one third of the features a design retains; the sign-consistent one-sided test is dropped for now (it needs published GxE directions). |

**To re-run on Terra, in order** (the metabolome changed, so the screen must be refit, not just
re-thresholded):

1. `01a` (void-volume filter, per-feature QC-pool CV), then `01c` (merged frame, ICCs, QC exports).
2. `02a`, then `02b` in full: MWIS fit (uncomment its chunk), threshold, the metabolome-wide M~E
   chunk (about as costly as the MWIS; set `EM_KINSHIP <- FALSE` for the fast iid version), and the
   sensitivity chunks.
3. `02c` and `03c`. Optionally `01b`, which now annotates the FTO row of `genotype_qc` correctly.
4. Locally: copy `results/` down, then render `manuscript.Rmd` and `exploration.Rmd`.

**Open decisions:** correction across lanes (the threshold is per lane); whether the max statistic
should replace Li & Ji as primary if it is materially stricter; a BMI precision covariate for
`clasp1_mvpa_hdl` (`extra_covars`); M~G / variance-heterogeneity diagnostics for the FTO and CETP
(vQTL-derived) lanes; `manuscript.Rmd` does not yet render the FHS replication or mummichog outputs;
published GxE signs for the one-sided audit test.

# Repository workflow

The source of truth for this project is the GitHub repository [`westerman-lab/gxpa-lcms`](https://github.com/westerman-lab/gxpa-lcms). Notebooks are versioned as `.ipynb`, and cell outputs are stripped automatically on commit by [`nbstripout`](https://github.com/kynan/nbstripout) (declared in `.gitattributes`), so only clean source is tracked. Generated outputs (HTML, figures, `*_cache/`, `*_files/`, data files) are gitignored.

* **Terra (run and edit):** Clone this repo onto the cloud-environment persistent disk in a directory that is *not* named after a workspace, so Terra's notebook auto-sync leaves it alone. Edit and run in JupyterLab from that folder, then commit and push from the Terra terminal. See [`TERRA_SETUP.md`](TERRA_SETUP.md) for the one-time setup.
* **Laptop (inspect and version):** `git pull` to inspect; commit and push as usual.

Any clone that will commit notebooks must have `nbstripout` installed and `nbstripout --install` run once, which configures the per-clone git filter. The shared `.gitattributes` declares the filter, but the filter program itself must be present in each clone (`pip install nbstripout`).

# Notes:

* Running locally, you need to install the [GCloud CLI](https://cloud.google.com/sdk/docs/install) and do `gcloud auth login`. The scripts rely on pulling data from the Terra workspace bucket.
