# Dependencies

These scripts depend on pulling data from Terra workspace. To run all code, you will need access to the following workspaces:

* [`bdcmsg22/QC_metabolomics`](https://app.terra.bio/#workspaces/bdcmsg22/QC_metabolomics)
* [`mgb-KEW-K01-GCP/gxpa-lcms-mediation`](https://app.terra.bio/#workspaces/mgb-KEW-K01-GCP/gxpa-lcms-mediation)
* [`manning-lab-2024-2025/manning-lab-2024-2025-topmed-analysis`](https://app.terra.bio/#workspaces/manning-lab-2024-2025/manning-lab-2024-2025-topmed-analysis)

In addition, script `01b` will only work if run in Terra, as it depends on the `tnu` command for fast random access of the TOPMed genotype data.

If you only want to run the analysis scripts (`02*` and beyond), you only need access to [`mgb-KEW-K01-GCP/gxpa-lcms-mediation`](https://app.terra.bio/#workspaces/mgb-KEW-K01-GCP/gxpa-lcms-mediation).

This code will only work on Linux or Mac (not Windows), because it uses `parallel::mcMap/mclapply`.

# GxPA LC-MS
The overall goal of this project is to identify metabolite mediators of a previously-identified gene-physical activity interaction at the *CLASP1* locus, using MESA as the primary dataset.

RMarkdown notebooks are numbered in the order in which they should be run.

* `00_picsure.Rmd`: Downloads phenotype data from PIC-SURE. **Note**: you must log into [https://picsure.biodatacatalyst.nhlbi.nih.gov/](https://picsure.biodatacatalyst.nhlbi.nih.gov/), get an API access token, and store it in a file named `picsure_token.txt` in your working directory.
* `01a_metabolomics_preprocessing.Rmd`: Formats and QCs the MESA LC-MS metabolomics data. Also separates the sample/metabolite metadata into separate files.
* `01b_genotype_preprocessing.Rmd`: This notebook **only works on Terra** because it depends on the `tnu` command to access genetic data files through DRS URIs (specified in `geno_files_drs.csv`). This script extracts the dosages for the variants specified in `variants_of_interest.csv` from the MESA and FHS VCF files.
* `01c_phenotype_preprocessing.Rmd`: This notebook merges all phenotypic data from PIC-SURE, metabolomics data, and variant dosages into one big dataframe.
* `02a_exploratory_plots.Rmd`: Exploratory analysis testing various sets of covariates, metabolite PC ~ covariate associations, and plotting phenotype variable distributions.
* `02b_analysis.Rmd`: Main analysis.
* `03_mummichog.Rmd`: Runs mummichog using the GxMetabolite interaction estimates from the MWIS from step `02b`. **Note**: mummichog requires Python 3.8 specifically, so it may be more convenient to run this notebook locally using [`pyenv`](https://github.com/pyenv/pyenv) than on Terra.
* `04a_aligned_metabolomics_preprocessing.Rmd`: Analogous to step `01a`, but for the FHS+MESA+WHI aligned metabolomics data.
* `04b_fhs_phenotype_merging.Rmd`: Analogous to step `01c`, but for FHS instead of MESA.
* `04c_fhs_analysis.Rmd`: Analogous to step `02b`, but for FHS instead of MESA. Additionally, this script reads the results of `02b` and only seeks to replicate results for the metabolites that were significant in MESA, to save computational cost (models take much longer to run in FHS than in MESA, likely because the FHS kinship matrix is more dense than in MESA which means adjusting for kinship takes longer).

# Notes:
* Running locally, you need to install the [GCloud CLI](https://cloud.google.com/sdk/docs/install) and do `gcloud auth login`. The scripts rely on pulling data from the Terra workspace bucket.
* After making commits to GitHub, `push_to_terra.sh` and `push_to_dbx.sh` are used to copy the scripts from GitHub to Terra or DropBox. Pushing to Terra automatically converts the RMarkdown scripts to Jupyter notebooks.
