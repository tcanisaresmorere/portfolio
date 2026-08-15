# ==============================================================================
# Analyse statistique : influence de la météo sur la dispersion latérale
# des avions en approche finale
# ==============================================================================
rm(list = ls())
required_pkgs <- c("arrow", "dplyr", "MASS", "leaps", "car", "lme4", "mgcv")
missing_pkgs <- setdiff(required_pkgs, rownames(installed.packages()))
if (length(missing_pkgs) > 0) {
  cat("Installation des packages manquants :",
      paste(missing_pkgs, collapse = ", "), "\n")
  install.packages(missing_pkgs)
}
invisible(suppressMessages(lapply(required_pkgs,
                                  library,
                                  character.only = TRUE)))

# ------------------------------------------------------------------------------
# 0 — Configuration
# ------------------------------------------------------------------------------
input_parquet   <- "cache/trajectoires_meteo_points_v3.parquet"
output_dir      <- "resultats_R"
dir.create(output_dir, showWarnings = FALSE)

final_segment_min_km   <- 0.3
final_segment_max_km   <- 8.0
min_points_final       <- 20
max_extrapolation_rate <- 0.20
traffic_window_min     <- 20
top_n_companies        <- 8

points <- read_parquet(input_parquet)
cat(sprintf("Points chargés : %s (colonnes : %s)\n",
            nrow(points),
            ncol(points)))
final_pts <- points |>
  filter(!go_around,
         distance_to_threshold_km >= final_segment_min_km,
         distance_to_threshold_km <= final_segment_max_km)
cat(sprintf("Points retenus [%.1f ; %.1f] km : %s\n",
            final_segment_min_km,
            final_segment_max_km,
            nrow(final_pts)))

approach_level <- final_pts |>
  group_by(approach_id, airport_icao) |>
  summarise(
    n_points_final            = n(),
    company                   = first(company),
    start_time                = min(timestamp),
    lateral_dispersion_km     = sd(cross_track_km, na.rm = TRUE),
    mean_cross_track_km       = mean(cross_track_km, na.rm = TRUE),
    mean_crosswind_ms         = mean(crosswind_ms, na.rm = TRUE),
    sd_crosswind_ms           = sd(crosswind_ms, na.rm = TRUE),
    p90_abs_crosswind_ms      = quantile(abs(crosswind_ms), 0.9, na.rm = TRUE),
    mean_headwind_ms          = mean(headwind_ms, na.rm = TRUE),
    sd_headwind_ms            = sd(headwind_ms, na.rm = TRUE),
    mean_wind_speed_ms_pt     = mean(wind_speed_ms_pt, na.rm = TRUE),
    sd_wind_speed_ms_pt       = sd(wind_speed_ms_pt, na.rm = TRUE),
    mean_temp_C               = mean(t_pt, na.rm = TRUE) - 273.15,
    mean_rh                   = mean(r_pt, na.rm = TRUE),
    mean_convective_water     = mean(convective_water_content_pt, na.rm = TRUE),
    mean_abs_wind_shear       = mean(abs(wind_shear_ms_per_km_pt),
                                     na.rm = TRUE),
    weather_extrapolated_rate = mean(weather_extrapolated, na.rm = TRUE),
    .groups = "drop"
  ) |>
  filter(n_points_final >= min_points_final,
         weather_extrapolated_rate <= max_extrapolation_rate,
         !is.na(lateral_dispersion_km))

cat(sprintf("Approches conservées après agrég et filtres : %s / %s\n",
            nrow(approach_level), n_distinct(points$approach_id)))

top_companies <- approach_level |>
  count(company, sort = TRUE) |>
  slice_head(n = top_n_companies) |>
  pull(company)
approach_level <- approach_level |>
  mutate(company_grp = factor(ifelse(company %in% top_companies,
                                     company,
                                     "AUTRE")))
cat("\nRépartition des compagnies (regroupées) :\n")
print(table(approach_level$company_grp))

compute_traffic_density <- function(df, window_min) {
  w <- window_min * 60
  df |>
    arrange(airport_icao, start_time) |>
    group_by(airport_icao) |>
    mutate(traffic_density = {
      t <- as.numeric(start_time)
      n_i <- length(t)
      dens <- integer(n_i)
      lo <- 1L
      hi <- 1L
      for (k in seq_len(n_i)) {
        while (lo < k && t[k] - t[lo] > w) lo <- lo + 1L
        while (hi < n_i && t[hi + 1L] - t[k] <= w) hi <- hi + 1L
        dens[k] <- (hi - lo + 1L) - 1L
      }
      dens
    }) |>
    ungroup()
}
approach_level <- compute_traffic_density(approach_level, traffic_window_min)
cat(sprintf("\nDensité de trafic : médiane = %.0f, max = %.0f\n",
            median(approach_level$traffic_density),
            max(approach_level$traffic_density)))

write.csv(approach_level,
          file.path(output_dir,
                    "approche_level_agrege_v3.csv"),
          row.names = FALSE)

# ------------------------------------------------------------------------------
# 1 — Chargement et nettoyage des données
# ------------------------------------------------------------------------------
if (!file.exists("resultats_R/approche_level_agrege_v3.csv")) {
  stop("Générer le fichier 'resultats_R/approche_level_agrege_v3.csv'.")
}
data <- read.csv("resultats_R/approche_level_agrege_v3.csv", header = TRUE)

cat("Nombre d'observations initiales :", nrow(data), "\n")
data <- subset(data, lateral_dispersion_km > 0)
cat("Nombre d'observations après retrait des valeurs nulles :",
    nrow(data),
    "\n")

data$log_dispersion <- log(data$lateral_dispersion_km)
data$airport_icao   <- as.factor(data$airport_icao)
data$company_grp    <- as.factor(data$company_grp)
print(summary(data$log_dispersion))

# ------------------------------------------------------------------------------
# 2 — Étude préliminaire
# ------------------------------------------------------------------------------
cat("\n--- ÉTUDE PRÉLIMINAIRE PAR AÉROPORT ---\n")
liste_aeroports <- levels(data$airport_icao)
for (ap in liste_aeroports) {
  data_sub <- subset(data, airport_icao == ap)
  if (nrow(data_sub) > 5) {
    cat("\n--> Traitement de la plateforme :",
        ap, "(",
        nrow(data_sub),
        "approches )\n")
    cor_test <- cor.test(data_sub$sd_crosswind_ms, data_sub$log_dispersion)
    cat("   Corrélation r =",
        round(cor_test$estimate, 4),
        " | p-value =",
        cor_test$p.value,
        "\n")
    x11(title = paste("Régression simple —", ap))
    plot(data_sub$sd_crosswind_ms, data_sub$log_dispersion,
         xlab = "Écart-type du vent de travers (m/s)",
         ylab = "Log Dispersion Latérale (km)",
         main = paste("Influence des rafales sur la dispersion —", ap),
         pch = "+",
         col = "darkgray")
    reg_simple_sub <- lm(log_dispersion ~ sd_crosswind_ms, data = data_sub)
    abline(reg_simple_sub, col = "red", lwd = 2)
    print(coefficients(reg_simple_sub))
  }
}

cat("\n--- ÉTUDE PRÉLIMINAIRE PAR COMPAGNIE ---\n")
for (comp in levels(data$company_grp)) {
  data_sub <- subset(data, company_grp == comp)
  if (nrow(data_sub) > 15) {
    cat(sprintf("--> %s (%d approches) : médiane log-dispersion = %.3f\n",
                comp, nrow(data_sub), median(data_sub$log_dispersion)))
  }
}

# ------------------------------------------------------------------------------
# 3 — Régression multiple
# ------------------------------------------------------------------------------
cat("\n--- RÉGRESSION MULTIPLE (PRÉDICTEURS CONTINUS ÉLARGIS) ---\n")
x11()
par(mfrow = c(3, 3))
hist(data$mean_crosswind_ms, main = "Moyenne Vent Travers")
hist(data$sd_crosswind_ms, main = "SD Vent Travers (Rafales)")
hist(data$p90_abs_crosswind_ms, main = "P90 |Vent Travers|")
hist(data$mean_headwind_ms, main = "Moyenne Vent Face")
hist(data$sd_headwind_ms, main = "SD Vent Face")
hist(data$mean_abs_wind_shear, main = "Cisaillement vertical (nouveau)")
hist(data$traffic_density, main = "Densité de trafic (nouveau)")
hist(data$mean_temp_C, main = "Température (°C)")
hist(data$mean_convective_water, main = "Eau convective")
x11()
pairs(data[, c("log_dispersion", "sd_crosswind_ms", "mean_abs_wind_shear",
               "traffic_density", "p90_abs_crosswind_ms")])

predictors_continus <- c("mean_crosswind_ms", "sd_crosswind_ms",
                         "p90_abs_crosswind_ms", "mean_headwind_ms",
                         "sd_headwind_ms", "mean_wind_speed_ms_pt",
                         "sd_wind_speed_ms_pt", "mean_temp_C",
                         "mean_convective_water", "mean_abs_wind_shear",
                         "traffic_density")

regmult <- lm(as.formula(paste("log_dispersion ~",
                               paste(predictors_continus, collapse = " + "))),
              data = data)
print(summary(regmult))

x11()
par(mfrow = c(2, 2))
plot(fitted(regmult),
     residuals(regmult),
     main = "Hypothèse d'homoscédasticité",
     xlab = "Valeurs ajustées",
     ylab = "Résidus")
abline(h = 0, col = "red")
qqnorm(residuals(regmult), main = "Q-Q Plot des résidus")
qqline(residuals(regmult), col = "red")
acf(residuals(regmult),
    main = "Autocorrélation des résidus (indicatif, cf. note précédente)")

# ------------------------------------------------------------------------------
# 4 — ANOVA : Effet de l'aéroport
# ------------------------------------------------------------------------------
cat("\n--- ANOVA : EFFET DE L'AÉROPORT ---\n")
anova.out <- lm(log_dispersion ~ airport_icao, data = data)
print(summary(anova.out))

# ------------------------------------------------------------------------------
# 5 — ANCOVA et sélection automatique BIC
# ------------------------------------------------------------------------------
cat("\n--- ANCOVA COMPLÈTE & SÉLECTION AUTOMATIQUE (PRÉDICTEURS ÉLARGIS) ---\n")
all_predictors <- c(predictors_continus, "airport_icao", "company_grp")
form_full <- as.formula(paste("log_dispersion ~",
                              paste(all_predictors, collapse = " + ")))
regcomplet <- lm(form_full, data = data)
print(summary(regcomplet))
n_obs <- nrow(data)

# Recherche exhaustive du meilleur sous-ensemble par BIC.
regfit <- regsubsets(form_full,
                     data = data,
                     nvmax = length(all_predictors) + 20,
                     nbest = 1,
                     really.big = TRUE)
rs <- summary(regfit)
best_size <- which.min(rs$bic)
cat(sprintf("Meilleur nombre de variables selon BIC : %d\n", best_size))
selected_dummies <- names(coef(regfit, best_size))[-1]
orig_vars <- unique(sapply(selected_dummies, function(v) {
  hit <- all_predictors[sapply(all_predictors, function(p) startsWith(v, p))]
  if (length(hit) == 0) v else hit[which.max(nchar(hit))]
}))
cat("Variables retenues dans regbic :\n")
print(orig_vars)

orig_vars <- union(orig_vars, c("airport_icao", "company_grp"))
regbic <- lm(as.formula(paste("log_dispersion ~",
                              paste(orig_vars, collapse = " + "))),
             data = data)
cat("\n=== regbic : effets principaux, sélection BIC ===\n")
print(summary(regbic))
cat(sprintf("R2 ajusté = %.3f | BIC = %.1f\n",
            summary(regbic)$adj.r.squared,
            BIC(regbic)))

cat("\n--- RECHERCHE D'INTERACTIONS D'ORDRE 2 ---\n")
cont_orig_vars <- setdiff(orig_vars, c("airport_icao", "company_grp"))
lower_form <- ~ airport_icao + company_grp
upper_form <- as.formula(paste("~ (", paste(cont_orig_vars, collapse = " + "),
                               ")^2 + airport_icao + company_grp"))
regbicint <- stepAIC(regbic,
                     scope = list(lower = lower_form, upper = upper_form),
                     direction = "both", k = log(n_obs), trace = FALSE)
cat("\n=== Formule finale sélectionnée par BIC (Avec Interactions) ===\n")
print(formula(regbicint))
print(summary(regbicint))
cat(sprintf("R2 ajusté = %.3f | BIC = %.1f\n",
            summary(regbicint)$adj.r.squared,
            BIC(regbicint)))
cat("\nVIF (effets principaux, regbic) :\n")
if (length(attr(terms(regbic), "term.labels")) >= 2) print(vif(regbic))

# ------------------------------------------------------------------------------
# 5bis — Modèle mixte
# ------------------------------------------------------------------------------
cat("\n--- MODÈLE MIXTE (AÉROPORT + COMPAGNIE EN EFFETS ALÉATOIRES) ---\n")
cont_vars_mixed <- intersect(orig_vars, predictors_continus)
if (length(cont_vars_mixed) == 0) cont_vars_mixed <- c("sd_crosswind_ms",
                                                       "mean_abs_wind_shear")
form_mixed <- as.formula(paste("log_dispersion ~",
                               paste(cont_vars_mixed,
                                     collapse = " + "),
                               "+ (1|airport_icao) + (1|company_grp)"))
m_mixed <- lmer(form_mixed, data = data, REML = FALSE)
print(summary(m_mixed))
var_fixed <- var(predict(m_mixed, re.form = NA))
vc <- as.data.frame(VarCorr(m_mixed))
var_airport <- vc$vcov[vc$grp == "airport_icao"]
var_company <- vc$vcov[vc$grp == "company_grp"]
var_resid   <- vc$vcov[vc$grp == "Residual"]
R2_marginal    <- var_fixed / (var_fixed + var_airport + var_company + var_resid)
R2_conditional <- (var_fixed + var_airport + var_company) / (var_fixed + var_airport + var_company + var_resid)
cat(sprintf("\nR² marginal (météo seule)              = %.3f\n", R2_marginal))
cat(sprintf("R² conditionnel (météo + aéroport/cie)  = %.3f\n", R2_conditional))
cat("(comparer R2_marginal à l'adj.r.squared de regbic : \n")

# ------------------------------------------------------------------------------
# 5ter — GAM
# ------------------------------------------------------------------------------
cat("\n--- GAM (TERMES LISSES) ---\n")
gam_vars <- intersect(predictors_continus, names(data))
gam_smooth_terms <- paste0("s(", gam_vars, ", k=5)", collapse = " + ")
form_gam <- as.formula(paste("log_dispersion ~",
                             gam_smooth_terms,
                             "+ airport_icao + company_grp"))
m_gam <- gam(form_gam, data = data)
cat(sprintf("Déviance expliquée (GAM) = %.3f \n",
            summary(m_gam)$dev.expl))
print(summary(m_gam))
x11()
par(mfrow = c(2, 3))
plot(m_gam, shade = TRUE, main = "Effets lisses estimés par le GAM")

# ------------------------------------------------------------------------------
# 6 — Évaluation des modèles et validation croisée (Apprentissage / Test)
# ------------------------------------------------------------------------------
cat("\n--- ÉVALUATION ET PERFORMANCES (TRAIN / TEST) ---\n")
score <- function(obs, prev) {
  rmse <- sqrt(mean((prev - obs)^2, na.rm = TRUE))
  biais <- mean(prev - obs, na.rm = TRUE)
  cat("Biais : ", round(biais, 5), " | RMSE : ", round(rmse, 5), "\n")
  return(c(biais, rmse))
}
set.seed(42)
nappr <- round(0.7 * nrow(data))
ii <- sample(1:nrow(data), nappr)
datapp        <- data[ii, ]
datatest_brut <- data[-ii, ]

liste_airports_train  <- unique(datapp$airport_icao)
liste_companies_train <- unique(datapp$company_grp)
datatest <- subset(datatest_brut,
                   airport_icao %in% liste_airports_train &
                     company_grp %in% liste_companies_train)
m_simple_train  <- lm(log_dispersion ~ sd_crosswind_ms, data = datapp)
m_bic_train     <- lm(formula(regbic), data = datapp)
m_bicint_train  <- lm(formula(regbicint), data = datapp)
m_mixed_train   <- lmer(form_mixed, data = datapp, REML = FALSE)
m_gam_train     <- gam(form_gam, data = datapp)

cat("\n--- Scores sur données d'apprentissage (Train) ---\n")
cat("Modèle Simple   -> ")
score(datapp$log_dispersion, fitted(m_simple_train))
cat("Modèle BIC      -> ")
score(datapp$log_dispersion, fitted(m_bic_train))
cat("Modèle BIC Int  -> ")
score(datapp$log_dispersion, fitted(m_bicint_train))
cat("Modèle Mixte    -> ")
score(datapp$log_dispersion, fitted(m_mixed_train))
cat("GAM             -> ")
score(datapp$log_dispersion, fitted(m_gam_train))

cat("\n--- Scores sur données de validation (Test) ---\n")
cat("Modèle Simple   -> ")
score(datatest$log_dispersion, predict(m_simple_train, datatest))
cat("Modèle BIC      -> ")
score(datatest$log_dispersion, predict(m_bic_train, datatest))
cat("Modèle BIC Int  -> ")
score(datatest$log_dispersion, predict(m_bicint_train, datatest))
cat("Modèle Mixte    -> ")
score(datatest$log_dispersion, predict(m_mixed_train, datatest,
                                       allow.new.levels = TRUE))
cat("GAM             -> ")
score(datatest$log_dispersion, predict(m_gam_train, datatest))

x11()
plot(data$log_dispersion,
     type = "l",
     col = "gray",
     main = "Validation des modèles de dispersion",
     xlab = "Approches",
     ylab = "Log Dispersion Latérale (km)")
points(fitted(regbic), col = "blue", pch = "+", cex = 0.5)
points(fitted(regbicint), col = "green", pch = "+", cex = 0.5)
points(fitted(m_gam), col = "orange", pch = "+", cex = 0.5)
legend("topright", legend = c("Observé", "BIC", "BIC Interactions", "GAM"),
       col = c("gray", "blue", "green", "orange"), lty = c(1, NA, NA, NA),
       pch = c(NA, "+", "+", "+"), bty = "n")
cat("\nAnalyse terminée avec succès.\n")


# ------------------------------------------------------------------------------
# 6bis — GAM PARCIMONIEUX
# ------------------------------------------------------------------------------
cat("\n--- GAM RÉDUIT (4 TOP PRÉDICTEURS + CONTROLES) ---\n")
m_gam_small <- gam(
  log_dispersion ~ 
    s(mean_abs_wind_shear, k = 5) +
    s(sd_crosswind_ms, k = 5) +
    s(traffic_density, k = 5) +
    s(sd_wind_speed_ms_pt, k = 5) +
    airport_icao + company_grp,
  data = data,
  method = "REML"
)

print(summary(m_gam_small))
cat("\n=== COMPARATIF GAM COMPLET vs GAM RÉDUIT ===\n")
cat(sprintf("GAM Complet (11 vars) -> R² adj = %.3f | Déviance expliquée = %.1f%% | AIC = %.1f\n",
            summary(m_gam)$r.sq, 
            summary(m_gam)$dev.expl * 100, 
            AIC(m_gam)))

cat(sprintf("GAM Réduit  ( 4 vars) -> R² adj = %.3f | Déviance expliquée = %.1f%% | AIC = %.1f\n",
            summary(m_gam_small)$r.sq, 
            summary(m_gam_small)$dev.expl * 100, 
            AIC(m_gam_small)))
cat("\n--- Test de comparaison de modèles (ANOVA) ---\n")
print(anova(m_gam_small, m_gam, test = "F"))
plot(m_gam_small, pages = 1, shade = TRUE, seWithMean = TRUE, 
     main = "Effets lisses - GAM Réduit (Top 4)")