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
| `role` | `primary` (default) or `control`. See below. Optional: an `anchors.csv` without the column reads as all-primary. |
| `extra_covars` | Optional covariates for this lane only, space-separated, added to its interaction models (GxE, the metabolome-wide screen, the GxCovar sensitivity) but not to the marginal Y~G / E~G checks, which lanes can share. |
| `provenance` | Why the lane is here. |

**Control lanes** (`role = "control"`) exist for one purpose: to calibrate the cross-cohort
concordance statistic in `03c`. That statistic correlates a lane's MESA GxM estimates with its
FHS ones across the whole alignable panel, and on its own it cannot distinguish a signal
specific to the lane's SNP from an artifact of the exposure or the platform that would
replicate for *any* SNP. A control lane holds the outcome, the exposure, the covariates and
the feature set fixed and varies only `G`, which is exactly that comparison. They are
screened and never reported:

* `02b` screens them, but restricted to the **alignable panel**, and excludes them from the
  known-association checks, the hit-driven sensitivity fits, `mesa_signif_GxMs.csv`, the
  metabolome-wide M~E screen and `n_lanes`. That last exclusion is not cosmetic: `M_E_mwide`'s
  design-only row set is the intersection over every lane sharing an exposure, so a control
  lane sharing `mvpa_wins` would move the **primary** lanes' alpha.
* `03c` screens them and reports their concordance beside the primary lanes', but gives them
  no kinship refits, no meta-analysis and no place in the FHS threshold.
* `02c`, `02a`, `01c`, `manuscript.Rmd` and `exploration.Rmd` drop them on read.

Comparing correlations across SNPs is only valid if every lane screens the **same** features,
so control lanes require `SCREEN_TOP_K <- NULL` (the full alignable panel) in `03c`; `02b`'s
restriction of controls to that same panel is what keeps the two sides matched, and `03c`
restricts the contrast to the features every lane in a (Y, E) family carries.

The contrast itself is a **paired cluster bootstrap on the difference** `r_primary - r_control`:
one resample of coelution blocks is applied to every lane at once, so the noise the lanes share
cancels instead of accumulating. That is why two control lanes suffice — a test that treated
controls as a sample from a distribution would need ten or more to estimate its spread.
`CONTROL_N_FEATURES` in `02b` can subsample the panel if the control count ever grows; it is
`NULL` (no subsampling) while there are only two.

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

# Project status (2026-09-22)

**Lanes** (`anchors.csv`): 5 primary + 2 control. Reported: `clasp1_mvpa_hdl`, `cetp_bmi_hdl`.
Screened but not reported (`include = FALSE`): `fto_mvpa_bmi`, `lipc_bmi_tg`, `lhx1_mvpa_hdl`.
Controls: `fads_mvpa_hdl` and `fads_mvpa_bmi`, one per MVPA family (added 2026-09-22).
`cetp_bmi_tg` was removed on 2026-09-14.

**Where the applied results stand.** The screen is calibrated and empty. The 2026-09-16 `02b` run
(3,219 features after the void-volume filter, Li & Ji M_eff 1,020, p < 4.9e-5) returns **zero hits
in all four lanes**, with lambda 0.96-1.09 and best p 6.6e-5 to 4.2e-4. Nothing survives the
pre-committed D2 design. The dilution identity explains why rather than excusing it: with
beta_GxE ~ -0.026 and typical |alpha| ~ 0.03-0.05, the implied per-feature interaction is ~1e-3,
about an order of magnitude below the MDE at n ~ 9,000.

**FHS (2026-09-21, top-100 per lane).** 1,687 of 3,219 features are alignable (52%); n ~ 2,900;
SE inflation 2.0-4.0x. **No feature replicates** -- the three rows that clear FHS's own threshold
are 5.5-6.8x MESA's beta and heterogeneous with it (Cochran p 0.002-0.004), i.e. FHS-specific.
What did appear is **panel-wide concordance**: MESA-vs-FHS effect correlation of 0.563 (CLASP1)
and 0.361 (FTO), block-permutation p <= 0.0005, against 0.081 (CETP) and -0.103 (LIPC). It
survives adjustment for alpha (partial r 0.572, so not dilution), rises with ICC (0.21/0.70/0.74
by tertile for CLASP1, flat or negative in the null lanes), and has regression slope 0.79 --
shrunk as winner's curse predicts, not a scale artifact.

**That result is why the control lanes exist.** A cross-cohort correlation alone cannot separate a
G-specific signal from an exposure- or platform-level artifact, and the FTO lane makes the worry
concrete: its outcome-level GxE is exactly zero in MESA (beta = -0.0002, p = 0.97), so the dilution
identity predicts no concordance at all, yet r = 0.36. The control is rs102275 (FADS), never
ascertained on physical activity, at MAF 0.426 — at or above every MVPA anchor, so a null from it
cannot be blamed on power. **Until that comparison is run, the concordance result is not
reportable.**

The other GxPA loci in the panel -- LHX1, PTPRZ1, and the too-rare SNTA1 and CNTNAP2 -- are
**positive** comparators, not negative ones: they were reported for MVPA interaction on HDL-C by
the same scan that produced CLASP1. `lhx1_mvpa_hdl` was added as a primary lane on 2026-09-22 for
that reason. It makes the design a predicted gradient rather than a single contrast: if the
concordance statistic tracks real GxPA biology, reported GxPA loci should concord more than the
never-ascertained controls, and LHX1 at MAF 0.396 is better powered than CLASP1 at 0.148.

The Aug-1 finding still frames the paper: the CLASP1 hits are not mediators under the dilution
identity, so the applied section is an honest worked example with a stated limitation.

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
| 2026-09-16 | Variant panel corrected in `variants_of_interest.csv` (LIPC, APOC1, DOCK7/ANGPTL3 positions/alleles; blank alts filled; TCF7L2 rs7903146 added as a positive control). LIPC HDL-C went from meaningless to -0.114, p = 3.2e-9; every other locus unchanged to three digits. |
| 2026-09-16 | `lipc_bmi_tg` added as a lane on **external** grounds (2022 vQTL panel, TG x BMI p = 6e-9 in UKB), `include = FALSE`. MESA's own GxE (p = 0.048, same direction) is reported as consistency, not as the reason the lane exists. |
| 2026-09-22 | FHS screen moved to the **full alignable panel** (`SCREEN_TOP_K <- NULL`). Required by the control comparison, which needs every lane on one feature set; it also supplies the metabolome-wide meta-analysis. |
| 2026-09-22 | The contrast is a **paired cluster bootstrap on the difference** `r_primary - r_control`, not a comparison against a control distribution: one resample of coelution blocks is applied to every lane at once, so the shared feature-sampling noise cancels. That is what makes two control lanes sufficient where a distribution-based test would have needed ten. Validated on synthetic lanes: with one control and only 100 features, a true delta of 0.61 gives p = 1e-6 and a weak one of 0.38 gives p = 0.004. |
| 2026-09-22 | `lhx1_mvpa_hdl` added as a **primary** lane (`include = FALSE`), on the external report (same GxPA-HDL-C scan as CLASP1), not on MESA's own GxE, which is flat (p = 0.98). It is the positive comparator for the concordance statistic. Every `mvpa_wins` lane SNP has call rate 1.0, so adding it does not change `M_E_mwide`'s shared row set or the primary lanes' alpha. PTPRZ1 was not added; SNTA1 and both CNTNAP2 alleles remain unusable on MAF (0.010, 0.008, 0.0003). |
| 2026-09-22 | **Control lanes** (`role = "control"`): two, `fads_mvpa_hdl` and `fads_mvpa_bmi`, one per MVPA family, screened over the alignable panel and never reported. Declared *before* any control estimate was seen, to calibrate the cross-cohort concordance statistic. **Eligibility is ascertainment, not MESA's GxE p-value:** a SNP reported for a physical-activity interaction anywhere cannot be an MVPA control, however null it looks here — which rules out the whole `old` GxPA set (CLASP1, LHX1, SNTA1, PTPRZ1, CNTNAP2) and FTO. rs102275 (TMEM258/FADS1-2) was chosen on two grounds: MAF 0.426 is at or above every MVPA anchor (CLASP1 0.148, LHX1 0.396, FTO 0.399), so a null result cannot be blamed on the control being underpowered; and the fatty-acid desaturase locus has large metabolome-wide main effects, making it the most stringent available test of whether broad metabolite association alone produces concordance. |

**To re-run on Terra, in order** (for the control-lane comparison; `anchors.csv` was republished
2026-09-22, so pull the notebooks before running anything — an old `02c` against the new
`anchors.csv` would launch 24 pathway jobs it should skip):

1. `02b`: uncomment the MWIS chunk and re-run it. The four existing primary lanes are already in
   `results/GxM_results.csv` and are **not** refit. New fits: 2 control lanes x 1,687 alignable
   features = 3,374, plus `lhx1_mvpa_hdl` over the full 3,219 because a primary lane gets the
   whole panel — about **6,600 in total, two thirds of one MWIS run**. The M~E chunk does not
   need re-running: control lanes are excluded from it by design and LHX1's call rate is 1.0, so
   `M_E_mwide_*.csv` is unchanged either way.
2. `03c` with `SCREEN_TOP_K <- NULL`: 7 lanes x 1,687 alignable features, about **11,800 `lm`
   fits** (kinship refits are primary-lane only). The fit cell
   times one fit and prints an estimate before the loop, and checkpoints every `CHUNK` fits with
   resume, so an interrupted run continues rather than restarting.
3. `02c` only if pathway results need refreshing; it now skips control lanes.
4. Locally: copy `results/` down, then render `manuscript.Rmd` and `exploration.Rmd`.

**Open decisions:** which lanes the manuscript reports, and whether the vignette rests on the
MVPA pair (CLASP1 + FTO, same exposure, one anchor reproducing and one not) — pending the control
result; correction across lanes (the threshold is per lane); whether the max statistic should
replace Li & Ji as primary; a BMI precision covariate for `clasp1_mvpa_hdl` (`extra_covars`);
`manuscript.Rmd` does not yet render the FHS screen, the concordance/control comparison or the
mummichog outputs; published GxE signs for the one-sided audit test.

# Repository workflow

The source of truth for this project is the GitHub repository [`westerman-lab/gxpa-lcms`](https://github.com/westerman-lab/gxpa-lcms). Notebooks are versioned as `.ipynb`, and cell outputs are stripped automatically on commit by [`nbstripout`](https://github.com/kynan/nbstripout) (declared in `.gitattributes`), so only clean source is tracked. Generated outputs (HTML, figures, `*_cache/`, `*_files/`, data files) are gitignored.

* **Terra (run and edit):** Clone this repo onto the cloud-environment persistent disk in a directory that is *not* named after a workspace, so Terra's notebook auto-sync leaves it alone. Edit and run in JupyterLab from that folder, then commit and push from the Terra terminal. See [`TERRA_SETUP.md`](TERRA_SETUP.md) for the one-time setup.
* **Laptop (inspect and version):** `git pull` to inspect; commit and push as usual.

Any clone that will commit notebooks must have `nbstripout` installed and `nbstripout --install` run once, which configures the per-clone git filter. The shared `.gitattributes` declares the filter, but the filter program itself must be present in each clone (`pip install nbstripout`).

# Notes:

* Running locally, you need to install the [GCloud CLI](https://cloud.google.com/sdk/docs/install) and do `gcloud auth login`. The scripts rely on pulling data from the Terra workspace bucket.
