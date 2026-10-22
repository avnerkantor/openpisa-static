# Israel: girls minus boys within Hebrew and Arabic speakers (language of the test), 2022 and 2025.
# The gap and its change use the gap's own BRR standard error (same schools, so boys and girls are not independent).
# Linking error cancels in a change of a gap. Check: group means against RAMA's PISA 2025 report, table 1 (p.18).
suppressPackageStartupMessages(library(haven))
rw <- paste0("W_FSTURWT", 1:80); DOMS <- c("READ", "MATH", "SCIE")
f <- c("2022" = "C:/Users/Avner/PISA2022_data/CY08MSP_STU_QQQ.SAV", "2025" = "C:/Users/Avner/PISA2025_data/CY09_MS_STU_PUF/CY09_MS_STU_PUF.sav")
res <- list(); thetas <- list()
for (y in names(f)) {
  d <- read_sav(f[y], col_select = c("CNT", "ST004D01T", "LANGTEST_COG", "W_FSTUWT", all_of(rw), paste0("PV", rep(1:10, 3), rep(DOMS, each = 10))))
  d <- d[as.character(zap_labels(d$CNT)) == "ISR", ]
  lg <- as.character(as_factor(d$LANGTEST_COG)); sx <- as.numeric(zap_labels(d$ST004D01T))
  W <- cbind(as.numeric(d$W_FSTUWT), sapply(rw, function(v) as.numeric(d[[v]])))
  for (D in DOMS) { PV <- sapply(1:10, function(k) as.numeric(d[[paste0("PV", k, D)]]))
    for (L in c("Hebrew", "Arabic")) {
      th <- function(i) crossprod(W[i, ], PV[i, ]) / colSums(W[i, ])   # 81 x 10
      g <- th(lg %in% L & sx %in% 1); b <- th(lg %in% L & sx %in% 2); gap <- g - b
      thetas[[paste(y, D, L)]] <- gap
      for (nm in c("girls", "boys", "gap")) { E <- list(girls = g, boys = b, gap = gap)[[nm]]; t0 <- E[1, ]
        se <- sqrt(mean(colSums((E[-1, ] - rep(t0, each = 80))^2) / 20) + 1.1 * var(t0))
        res[[length(res) + 1]] <- data.frame(year = y, D = D, L = L, stat = nm, est = mean(t0), se = se,
          n = if (nm == "gap") sum(lg %in% L & sx %in% 1:2) else sum(lg %in% L & sx %in% if (nm == "girls") 1 else 2)) } } }
}
r <- do.call(rbind, res); r$est <- round(r$est, 1); r$se <- round(r$se, 1)
print(r, row.names = FALSE)
cat("\nChange in the gap 2022 -> 2025 (independent samples across cycles, so SEs add; linking error cancels)\n")
for (D in DOMS) for (L in c("Hebrew", "Arabic")) { a <- r[r$year == "2022" & r$D == D & r$L == L & r$stat == "gap", ]; b <- r[r$year == "2025" & r$D == D & r$L == L & r$stat == "gap", ]
  ch <- b$est - a$est; m <- 1.96 * sqrt(a$se^2 + b$se^2); cat(sprintf("%s %-6s gap %5.1f -> %5.1f  change %+5.1f ±%4.1f %s\n", D, L, a$est, b$est, ch, m, if (abs(ch) > m) "SIGNIFICANT" else "")) }
