# Spec: an FTO x intentional-exercise -> BMI lane (`fto_pa_bmi`)

Drafted 2026-10-16. **Status:** Kenny accepted the Stage 0 defaults the same day (README decisions
row, 2026-10-16), and the code side is implemented:

- `anchors.csv` has the row (published, not committed).
- 02b has the A2 and B1 edits; 01c has A3.
- `manuscript.Rmd` labels `pa_log` / `pa` correctly.
- `specs/fto_pa_bmi_checks.R` runs Stage 0a, the D2 sensitivity and the Stage A checks from inside
  the 02b kernel.

Stages A and B ran as one 02b run with a pause after the known associations; README's "To re-run
on Terra" has the steps. **Done 2026-10-16.**
- D2: exam-5 `exercm` looks rescored; Kenny kept it as is.
- B3, B4 and B5 were done in scratch, plus an `exploration.Rmd` re-render.
- The numbers are in README's decisions table (three 2026-10-16 rows).

Outcome: a clean null. The GxE is +0.006 (p 0.26) in all participants but ~0 in the metabolomics
samples. The screen is unchanged (r 0.998 with `fto_mvpa_bmi`, zero hits), and nothing survives
any audit design. Exercise's metabolite associations mirror BMI's more than MVPA's do (r -0.72 vs
-0.56).

Read `CLAUDE.md` and README's **Project status** before starting; their contracts and working
agreements apply throughout and are not repeated here.

## Goal

Find out whether MESA shows the FTO x physical-activity interaction on BMI when "physical activity"
is intentional exercise rather than total MVPA. Add it as a **new lane** beside the unchanged
`fto_mvpa_bmi`. If the new lane's interaction is non-null, carry it through the PA-metabolite
coupling (alpha) layer, so the dilution check and the exclusion bound can be applied to FTO.

## Why (facts already checked; don't re-derive them)

- **The two variables are different constructs** (01c, the `melt()` in the base-frame cell):
  - `pa` = MESA `exercm*c`, *intentional exercise*.
  - `mvpa` = `pamvcm*c`, *all* moderate and vigorous activity, including occupational, household
    and caregiving activity, so it follows SES/occupation.
  - Both are /60 (MET-h/wk), SD-winsorized and carried forward.
  - `mvpa_wins` additionally uses `winsor()`, which caps at the **90th percentile**
    (`quantile(c(0, 0.9))`).
  - `pa_log = log(pa + 1)`.
  - So the swap changes both the construct and the transform.
- **Kenny's observation:** `pa_log` vs BMI correlation p ~ 1e-32; `mvpa_wins` p ~ 0.3, in the wrong
  direction. The p-value is presumably from pooled rows, so it overstates the evidence; the
  covariate-adjusted LMM is what gets recorded (A3).
- **Current FTO lane** (`fto_mvpa_bmi`, all from `results/`):
  - FTO -> BMI: -0.042 SD per T allele, p 0.036.
  - FTO -> MVPA: p 0.20.
  - GxE: -0.0002 (SE 0.0052), p 0.97. Per method: C8/C18/HILIC p 0.23-0.41; Amide -0.0149, p 0.019,
    with the sign opposite to the literature.
  - Screen: lambda 1.09, zero hits, best p 9.2e-5.
- **The GxM screen barely depends on E.** The stored MWIS formula carries E only as a `G*E`
  adjustment (`bmi ~ G*M + G*E + covars + G:sex + gPC*M + batch + RE`). So beta_GxM, lambda and the
  zero hits should be nearly invariant to the swap.
  - FHS has no PA variable. 03c fits MVPA lanes with no E term at all, so FHS estimates for an FTO
    lane are identical whatever E is.
- **What the swap does move:** Y~E, E~G, the lane GxE (overall and per LC-MS method), the
  metabolome-wide M~E alpha, and everything built on alpha. That covers the dilution sign check,
  the exclusion bound, the E-associated design subsets, and labels like "MVPA-associated".
- **Power expectation:**
  - Assumption: ~27% attenuation in active people (Kilpelainen 2011), applied to MESA's own FTO
    effect.
  - Expected beta_GxE ~ **+0.007**; at the current SE of 0.0052, that is z ~ 1.4 (~2.4 if FTO's
    MESA effect were European-sized), i.e. about 15-60% power.
  - **Predicted sign: positive**, because G counts the non-risk T allele and its BMI-lowering
    effect shrinks with more exercise.
  - A null is therefore weak evidence against the literature.
- **Data caveats for `pa`** (from `results/qc/`):
  - ~23% zeros, against ~1% for MVPA.
  - Within-person ICC 0.43, against 0.50 for `mvpa_wins`.
  - **The exam-5 mean nearly doubles** (median 29.5 vs ~14 MET-h/wk at exams 1-4; zeros 6% vs 23%)
    while MVPA is flat. Exam 5 is 646 of 11,225 analysis rows. 02b has no exam term.

## Ground rules for this work

1. **Fix every Stage 0 decision, and write the README decisions row, before running any fit that
   involves G x `pa_log`.** The choice is made after `fto_mvpa_bmi`'s null, so it is marked
   "after results". Its defence is construct validity, not anything seen in the G x `pa_log` fits.
2. Add lanes; change no existing lane. `fto_mvpa_bmi`, the other lanes, `M_E_mwide_mvpa_wins.csv`,
   `M_E_mwide_bmi_covariate.csv` and the CLASP1 exclusion bound must come out unchanged.
3. Do not change the GxM model, the covariates, the threshold or any filter.
4. Notebook edits follow `CLAUDE.md`:
   - minimal and anchored by content;
   - R-parse every changed cell and validate with nbformat;
   - commit messages without a Co-Authored-By trailer;
   - `anchors.csv` is published to the bucket, never committed.
5. Report the result whichever way it comes out.

## Stage 0 - decisions (Kenny), then record them

| # | Decision | Default |
|---|---|---|
| D1 | Exposure column | `pa_log`. The alternative is `pa_wins` (same 90th-percentile cap as `mvpa_wins`, which isolates the construct change). Choose on distributional grounds only. |
| D2 | Exam-5 handling, after Stage 0a | Keep `pa_log` as is, and add one ad hoc GxE sensitivity fit excluding exam-5 rows (Stage A, step 5) |
| D3 | Predicted GxE sign | Positive (T coding) |
| D4 | Control lane `fads_pa_bmi` | **Do not add now.** Controls exist only to calibrate 03c's concordance. FHS fits are E-free and the MESA GxM is ~E-invariant, so FTO's concordance carries over. Add it only if the concordance for this lane will be reported. |
| D5 | Stage B gate | Run Stage B's M~E (design-only, no Y) and the lane's MWIS **whatever Stage A shows**, so nothing downstream is conditioned on the GxE (~6,400 kinship fits). The exclusion bound is then computed, or declared not meaningful under the existing rule (GxE ~ 0). |
| D6 | Reporting | `include = FALSE` until Kenny decides. Both FTO lanes go in the supplement whatever the outcome. |

**Decisions-table row to add to README** (fill the date; edit the wording to match D1-D6):

> | 2026-10-16 | `fto_pa_bmi` added as a primary lane (`include = FALSE`): FTO x intentional exercise (`pa_log`, MESA `exercm`) -> BMI, beside the unchanged `fto_mvpa_bmi`. **After results:** chosen after `fto_mvpa_bmi`'s GxE was null (p = 0.97), and after seeing that `mvpa_wins` is unrelated to BMI while intentional exercise is associated with lower BMI. MESA's MVPA total (`pamvcm`) counts occupational, household and caregiving activity. The grounds are construct validity: the FTO x PA literature measures leisure-time activity. Fixed before any G x `pa_log` estimate was seen. Predicted sign positive (G counts the non-risk T allele). Reported whatever the result. |

## Stage 0a - the exam-5 check (Terra, read-only, minutes)

Run this in a scratch R session on Terra; nothing is committed and nothing goes to `results/`:

```r
library(data.table)
d <- fread('data/derived/analysis_df-mesa.csv',
           select = c('mesa_id','exam','pa','mvpa','pa__imp','mvpa__imp'))
d[, .(n = .N, med_pa = median(pa, na.rm=TRUE), zero_pa = mean(pa == 0, na.rm=TRUE),
      med_mvpa = median(mvpa, na.rm=TRUE), carried = mean(pa__imp)), by = exam][order(exam)]
w <- dcast(d[exam %in% c(3, 5)], mesa_id ~ exam, value.var = c('pa', 'mvpa'))
w[complete.cases(w), .(n = .N, d_pa = median(pa_5 - pa_3), d_mvpa = median(mvpa_5 - mvpa_3))]
```

Then compare the raw `exercm1c/2c/3c/5c` (and `pamvcm*`) in the PIC-SURE pull, and check the MESA
Exam 5 data dictionary or questionnaire for a change in what `exercm5c` sums.

- **Definition change** (documented, or a within-person exam-3 -> exam-5 jump in `pa` with none in
  `mvpa`): bring it to Kenny. The options are D2's default (keep `pa_log`, plus the exam-5-excluded
  sensitivity fit) or masking exam-5 `pa` in 01c, which would mean an 01c re-run.
- **No change:** record "checked, no change" in the decisions row.

## Stage A - known associations only (Terra, minutes)

**Edits**

- **A1. `anchors.csv`:** append one row at the end. Order matters only for `include = TRUE` rows.

  ```
  fto_pa_bmi,chr16_53786615_A_T,bmi,pa_log,rs9939609,FTO,FTO x exercise -> BMI,FALSE,"","Kilpelainen 2011 and others; the FTO x PA literature measures leisure-time activity, so the exposure is MESA intentional exercise (exercm, log(MET-h/wk + 1)) rather than total MVPA (pamvcm, which includes occupational, household and caregiving activity). Added 2026-10-16 after fto_mvpa_bmi's GxE was null; fixed before any G x pa_log estimate was seen. fto_mvpa_bmi is kept unchanged.",primary
  ```

  - The (G, trait(Y), trait(E)) key is (FTO, bmi, pa), so it does not collide with `fto_mvpa_bmi`.
  - Publish with `gcloud storage cp anchors.csv gs://fc-secure-4a392455-5587-4d6f-b8bd-01a1f834ae63/`.
    Do not commit.
  - `variants_of_interest.csv` needs no change: no panel row declares `pa_log`, so `GxE.csv` gains
    exactly one row.
- **A2. 02b, `Y~E` export** (recommended; it is the stated reason for the lane, and only aggregates
  go to `results/`):
  - Today the `Y~E` fits are display-only; the cell beginning `tbls <- Y_E_models[, .(Map(` refits
    and prints the top five terms.
  - Add one code cell right after the cell beginning `Y_E_models <-`. Model it on the E~G fit cell,
    and leave the display cell alone:

  ```r
  if (RUN$known_assoc) {
  i <- 0
  t0 <- Sys.time()
  Y_E_models[, term_pat := E
    ][, c('est','se','df','t','p','n') := transpose(mcMap(fmla,term_pat, mc.preschedule=FALSE, f=\(fmla,pat) {
          message('  ',(i<<-i+1)*getOption('mc.cores'),'/',.N,'\r',appendLF=F) # Progress bar.
          model <- myLmer(fmla,data,list(mesa_id=km))                          # Run LMM model.
          coefs <- summary(model)$coefficients                                 # Extract coefs.
          c( coefs[rownames(coefs) == pat,], nrow(model@frame) )               # Exact match: E is numeric.
        }))
  ]
  if (!is.numeric(Y_E_models$est)) stop('Y~E fits failed; results/Y_E.csv left as it was. Rerun this cell.', call.=FALSE) # See Y~G.
  fwrite(Y_E_models, 'results/Y_E.csv') # Checkpoint for the record; the display below still fits its own.
  print(Sys.time() - t0)
  }
  ```

  - Add `Y_E` to README's list of 02b outputs.
- **A3. 01c, cosmetic (optional):** in the sample-flow cell, change
  `reason = if (trait(l$E) == 'mvpa')` to `if (trait(l$E) %in% c('mvpa', 'pa'))`. It only takes
  effect on an 01c re-run, which Stage A does not need: `pa_log` is already in
  `analysis_df-mesa.csv`, and 02b warns and skips the lane if it is not.

**Run**

1. `git pull`, then sync the VM's `results/` and `results/qc/` from the bucket (README step 0).
   **Save copies of the bucket's `Y_G.csv`, `E_G.csv`, `GxE.csv` and `GxE_mwis_sample.csv`** to
   compare against afterwards.
2. 02b with
   `RUN <- list(known_assoc=TRUE, mwis=FALSE, mwis_refit=FALSE, sensitivity=FALSE, m_e_mwide=FALSE, exports=TRUE)`.
   - The resume cell will list `fto_pa_bmi` with 3,219 to fit. That is expected; with
     `mwis = FALSE` nothing is fitted and `GxM_results.csv` is not rewritten.
   - `exports` rewrites `analysis_params.csv`: `n_lanes` goes 5 -> 6 and `lane_ids` gains
     `fto_pa_bmi`; the threshold is unchanged. It also pushes `results/` to the bucket.

**Checks before reading the result**

- Every pre-existing row of `Y_G`, `E_G`, `GxE` and `GxE_mwis_sample` is unchanged against the saved
  copies. LMM fits are deterministic; the 2026-10-09 run reproduced `Y_G` byte for byte.
- `Y_G.csv` gains one `fto_pa_bmi` row, identical to `fto_mvpa_bmi`'s (-0.0424, p 0.036).
- `E_G.csv` gains the (`pa_log`, FTO) row, and `GxE.csv` gains one row.
- `GxE_mwis_sample.csv` has 24 rows, and `fto_pa_bmi`'s n per method is within a few rows of
  `fto_mvpa_bmi`'s (9,271 / 9,282 / 9,277 / 7,305).
- `Y_E.csv`, if A2 was done: `bmi ~ pa_log` is negative; `bmi ~ mvpa_wins` is the null comparator.

**Steps 3-5**

3. Locally: pull `results/`, check MD5 against the bucket (README step 4), then read the numbers.
   - **`exploration.Rmd` will stop** until Stage B writes `M_E_mwide_pa_log.csv`, because every
     non-control lane's exposure file is a required input. Until then, render it with
     `params = list(anchors = c('clasp1_mvpa_hdl','cetp_bmi_hdl','fto_mvpa_bmi','lipc_bmi_tg','lhx1_mvpa_hdl'))`,
     or don't render it.
   - `manuscript.Rmd` skips `include = FALSE` lanes, but check that it still renders.
4. Record in README:
   - the GxE estimate, SE and p, overall and per method;
   - Y~E;
   - E~G (a large FTO -> exercise association would point to BMI -> exercise reverse causation);
   - the comparison with the expected +0.007.
5. If D2 is "keep + sensitivity": refit the overall `fto_pa_bmi` GxE once on `data[exam != 5]`, ad hoc
   on Terra, using the formula stored in `GxE.csv`, and record it beside the main estimate.

## Stage B - the alpha layer and the screen (Terra, hours; see D5)

- **B1. 02b, metabolome-wide M~E: fit only the new exposure.**
  - **Trap:** the `if (RUN$m_e_mwide) {` cell fits every exposure in `lanes_primary$E`. As written it
    would refit `mvpa_wins` and `bmi_covariate` too (~6,400 wasted kinship fits) and rewrite their
    files.
  - Minimal edit, mirroring the MWIS resume: before fitting, `sync_checkpoint()` each
    `results/M_E_mwide_<E>.csv`, then fit and write only the exposures with no file:

    ```r
    todo_E <- unique(M_E_mwide_models$E)
    for (e in todo_E) sync_checkpoint(paste0('results/M_E_mwide_', e, '.csv'))
    todo_E <- todo_E[!file.exists(paste0('results/M_E_mwide_', todo_E, '.csv'))]
    ```

    Apply `[E %in% todo_E]` to the fit and to the write loop.
  - The `pa_log` row set is the rows genotyped at FTO (call rate 1.0); the control lanes are already
    excluded, via `lanes_primary`.
  - Expect `M_E_mwide_pa_log.csv`: 3,219 rows, 0 fit errors.
  - Confirm afterwards that the other two files' MD5s match the bucket's.
- **B2. 02b, the MWIS for the new lane:** `RUN$mwis = TRUE`, `MWIS_RESUME = TRUE`. This fits only
  `fto_pa_bmi`'s 3,219 rows; everything else carries over.
  - **Check first:** cor(beta_GxM) with `fto_mvpa_bmi` should be > 0.98, lambda ~1.09 and zero hits.
  - If not, stop and investigate before interpreting anything. It would mean E is doing more than
    adjustment, for example through different rows.
  - Then `exports`.
- **B3. Dilution and bound** (scratch, as for CLASP1; see the memory note on the mediator exclusion
  bound):
  - f_min = 4.90 x SE_GxM x |alpha| / |beta_GxE|, per method, using `GxE_mwis_sample.csv`,
    `M_E_mwide_pa_log.csv` and `GxM_results.csv`.
  - Report it over the exercise-associated features (Bonferroni on alpha) and over all features.
  - Measurement-error calibration from `results/simulation/dilution_summary.csv`, at ICC_E ~ 0.43.
    Optional: add `pa_log` to 01c's `icc_vars` so the analysis-scale ICC is exported.
  - Only meaningful if the GxE is non-null; otherwise state that, as for FTO/LHX1 now.
  - If it is to reach the manuscript, it needs a notebook home (contract 1). The CLASP1 bound has
    the same gap.
- **B4. The reverse-causation caveat, to quantify and report:**
  - corr(alpha_pa_log, alpha_bmi_covariate) across the 3,219 features. Expect it to be strongly
    negative; for MVPA it is -0.56.
  - For the top dilution candidates, how much of alpha their BMI association alone predicts.
- **B5.** Re-render `exploration.Rmd` with every lane. D2 (annotated) remains the pre-committed
  primary; any E-associated design is post hoc for this lane and must be labelled so.
- **Skip unless asked:**
  - 03c: FHS fits are E-free, so they duplicate `fto_mvpa_bmi`'s. If run, `fto_pa_bmi`'s FHS rows
    must equal `fto_mvpa_bmi`'s, and the (bmi, pa_log) family prints "no contrast" without D4's
    control.
  - 02c mummichog: the GxM estimates are ~unchanged.

## Manuscript implications (flag them; don't edit the docx)

- If `fto_pa_bmi` is reported, Methods need a sentence defining the exposure. Proposed: "For the FTO
  lane the exposure was intentional exercise (MESA `exercm`: walking for exercise, sports and
  conditioning; MET-hours/week, log(x + 1)), because total moderate-to-vigorous activity in MESA
  includes occupational, household and caregiving activity."
- `manuscript.Rmd`'s `exposure_labels` needs `pa_log = "Exercise"`.

## Done when

- **Stage A:**
  - `anchors.csv` is published.
  - The bucket holds the new rows in `Y_G`, `E_G`, `GxE` and `GxE_mwis_sample` (and `Y_E.csv`),
    with every old row unchanged.
  - README has the decisions row, the Stage 0a outcome and the Stage A numbers.
  - The 02b edits are committed (they are pushed from Terra).
- **Stage B:**
  - `M_E_mwide_pa_log.csv` exists (0 errors), and the other M~E files are unchanged.
  - `GxM_results.csv` has 3,219 `fto_pa_bmi` rows (0 failures), with the invariance check recorded.
  - The bound/dilution numbers and the alpha-BMI correlation are recorded.
  - `exploration.Rmd` has been re-rendered.

## Out of scope

- Changing the exposure of CLASP1, LHX1 or any other lane.
- BMI-adjusting M~E. Adjusting for the outcome would condition on a descendant of M.
- Any change to the screen's model, threshold or filters.
- Flipping any `include` (ask Kenny).
