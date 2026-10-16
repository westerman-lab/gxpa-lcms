# Checks for the fto_pa_bmi lane (specs/fto_pa_bmi_lane.md). Run on Terra INSIDE the 02b kernel,
# after the known-association cells (Y~E, Y~G, E~G, GxE) and before the MWIS:
#
#   source('specs/fto_pa_bmi_checks.R')
#
# Prints only; writes nothing to results/. Copy the output back into the session.
#   1. Is pa's exam-5 jump a change of instrument? (decides D2 before the hours-long fits)
#   2. The FTO GxEs refitted without exam 5 (D2's sensitivity fit).
#   3. Did the known-association refit leave every pre-existing row unchanged?
#   4. The new lane's known associations, beside fto_mvpa_bmi's.

library(data.table)
bucket <- if (exists('ws_bucket')) ws_bucket else
  Sys.getenv('WORKSPACE_BUCKET', unset = 'gs://fc-secure-4a392455-5587-4d6f-b8bd-01a1f834ae63')
hdr <- \(x) cat('\n', strrep('=', 90), '\n', x, '\n', strrep('=', 90), '\n', sep = '')

# --- 1. pa by exam, on the unscaled frame ----------------------------------------------
hdr('1. Exam-5 check: pa (exercm, intentional exercise) vs mvpa (pamvcm), MET-h/wk, unscaled')
f <- 'data/derived/analysis_df-mesa.csv'
raw <- fread(f, select = intersect(c('mesa_id','exam','TOM_Id','pa','mvpa','pa__imp','mvpa__imp'),
                                   names(fread(f, nrows = 0))))
raw[, lcms := !is.na(TOM_Id) & nzchar(as.character(TOM_Id))]
by_exam <- \(d) d[!is.na(pa), .(n = .N, carried_fwd = round(mean(pa__imp), 3),
                               pa_median = median(pa), pa_zero = round(mean(pa == 0), 3),
                               mvpa_median = median(mvpa), mvpa_zero = round(mean(mvpa == 0), 3)),
                  keyby = exam]
cat('\nAll rows with PA:\n');       print(by_exam(raw))
cat('\nRows with an LC-MS sample:\n'); print(by_exam(raw[lcms == TRUE]))

# Within-person change between consecutive questionnaires, observed values only (exam 4 has
# no questionnaire, so 3 -> 5 is the only step into exam 5). Same instrument: ~0 change.
obs <- raw[pa__imp == FALSE & mvpa__imp == FALSE, .(mesa_id, exam, pa, mvpa)]
step <- \(a, b) {
  w <- merge(obs[exam == a], obs[exam == b], by = 'mesa_id', suffixes = c('_a', '_b'))
  w[, .(step = paste(a, '->', b), n = .N,
        pa_median_change = median(pa_b - pa_a), pa_spearman = round(cor(pa_a, pa_b, method = 'spearman'), 2),
        mvpa_median_change = median(mvpa_b - mvpa_a), mvpa_spearman = round(cor(mvpa_a, mvpa_b, method = 'spearman'), 2))]
}
cat('\nWithin-person change, observed questionnaires only:\n')
print(rbind(step(1, 2), step(2, 3), step(3, 5)))
cat('\nRead: if pa jumps at 3 -> 5 while mvpa does not, and the earlier steps are ~0, treat exam-5\n',
    'exercm as a definition change and STOP before the MWIS: that is decision D2 for Kenny.\n', sep = '')

# --- 2. FTO GxEs without exam 5 ---------------------------------------------------------
hdr('2. FTO GxE refitted without exam 5 (needs the 02b session objects)')
if (all(vapply(c('GxE_models', 'data', 'km', 'myLmer'), exists, TRUE)) &&
    'fto_pa_bmi' %in% GxE_models$lane_id) {
  ex5 <- GxE_models[lane_id %in% c('fto_mvpa_bmi', 'fto_pa_bmi'), .(lane_id, fmla, term_pat)]
  ex5[, c('est','se','df','t','p','n') := transpose(Map(fmla, term_pat, f = \(fmla, pat) {
        model <- myLmer(fmla, data[exam != '5'], list(mesa_id = km))
        coefs <- summary(model)$coefficients
        c(coefs[grepl(pat, rownames(coefs)), ], nrow(model@frame))
      }))]
  full <- fread('results/GxE.csv')[lane_id %in% ex5$lane_id, .(lane_id, est, se, p, n)]
  print(merge(full, ex5[, .(lane_id, est_no_exam5 = est, se_no_exam5 = se, p_no_exam5 = p, n_no_exam5 = n)],
              by = 'lane_id'))
} else cat('Skipped: run this from the 02b kernel after its GxE cell, with fto_pa_bmi in anchors.csv.\n')

# --- 3. Pre-existing rows unchanged -------------------------------------------------------
hdr('3. Known-association refit vs the bucket copy (the bucket is still pre-run until exports pushes)')
for (f in c('Y_G.csv', 'E_G.csv', 'GxE.csv', 'GxE_mwis_sample.csv', 'Y_E.csv')) {
  loc <- file.path('results', f)
  tmp <- tempfile(fileext = '.csv')
  system(paste0('gcloud storage cp ', bucket, '/results/', f, ' ', tmp), ignore.stdout = TRUE, ignore.stderr = TRUE)
  if (!file.exists(loc)) { cat(sprintf('%-22s not written locally yet\n', f)); next }
  if (!file.exists(tmp)) { cat(sprintf('%-22s new file (%d rows)\n', f, nrow(fread(loc)))); next }
  a <- fread(tmp); b <- fread(loc)
  keys <- intersect(c('lane_id', 'fmla', 'method'), names(a))
  m <- merge(a[, c(keys, 'est'), with = FALSE], b[, c(keys, 'est'), with = FALSE], by = keys, suffixes = c('_bucket', '_now'))
  cat(sprintf('%-22s bucket %3d rows, now %3d rows, %3d shared; max |change| in est on shared rows = %.3g\n',
              f, nrow(a), nrow(b), nrow(m), if (nrow(m)) max(abs(m$est_bucket - m$est_now)) else NA))
}
cat('Expected: every shared row unchanged (max |change| 0); Y_G, E_G and GxE +1 row each; GxE_mwis_sample 20 -> 24.\n')

# --- 4. The new lane's known associations --------------------------------------------------
hdr('4. Known associations, fto_pa_bmi beside fto_mvpa_bmi')
fto <- c('fto_mvpa_bmi', 'fto_pa_bmi')
cols <- \(d) d[, intersect(c('lane_id','method','Y','E','G','est','se','p','n'), names(d)), with = FALSE]
if (file.exists('results/Y_E.csv')) { cat('\nY ~ E (all lanes; one fit per (Y, E)):\n'); print(cols(fread('results/Y_E.csv'))) }
cat('\nY ~ G:\n');               print(cols(fread('results/Y_G.csv')[lane_id %in% fto]))
cat('\nE ~ G:\n');               print(cols(fread('results/E_G.csv')[lane_id %in% fto]))
cat('\nGxE, all participants:\n'); print(cols(fread('results/GxE.csv')[lane_id %in% fto]))
cat('\nGxE, per LC-MS method sample:\n'); print(cols(fread('results/GxE_mwis_sample.csv')[lane_id %in% fto]))
cat('\nPredicted GxE sign: POSITIVE (G counts the non-risk T allele). A literature-sized effect is\n',
    '~ +0.007 against an SE of ~0.005, so p > 0.05 is expected about half the time even if it is real.\n', sep = '')
