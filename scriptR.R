library(fpp2)
library(forecast)
library(readr)
library(tseries)
library(urca)
library(lmtest)
library(FinTS)
library(vars)
library(ggplot2)
library(fGarch)

par(ask = FALSE)

# ── Folder grafice ────────────────────────────────────────────────────────────
gp <- "C:/Users/Robert/Desktop/SERII/proiect/petrol/grafice"
dir.create(gp, showWarnings = FALSE)
sg <- function(p, name) { ggsave(file.path(gp, name), p, width = 10, h = 6, dpi = 150); print(p) }
sb <- function(name, expr) { png(file.path(gp, name), width = 1500, height = 900, res = 150); force(expr); dev.off() }

# ── 0. DATE ──────────────────────────────────────────────────────────────────

petrol_df    <- read.csv("C:/Users/Robert/Desktop/SERII/proiect/petrol/pret_petrol_lunar.csv",
                          stringsAsFactors = FALSE)
colnames(petrol_df) <- c("Luni", "Pret", "Variatie_proc", "Variatie_abs", "Curs_USD_EUR")
petrol_df$Pret <- as.numeric(petrol_df$Pret)

pret_petrol  <- ts(petrol_df$Pret,         start = c(1999, 1), frequency = 12)
curs_usd_eur <- ts(petrol_df$Curs_USD_EUR,  start = c(1999, 1), frequency = 12)

# ── 1. VIZUALIZARE ────────────────────────────────────────────────────────────

sg(autoplot(pret_petrol) +
     ggtitle("Pretul petrolului brut Brent (USD/baril)") +
     xlab("Timp") + ylab("USD/baril") + theme_bw(),
   "01_serie_petrol.png")

sg(pret_petrol %>%
     stl(t.window = 13, s.window = "periodic", robust = TRUE) %>%
     autoplot() + ggtitle("Descompunere STL") + theme_bw(),
   "02_descompunere_stl.png")

# ── 2. STATIONARITATE ─────────────────────────────────────────────────────────

sg(ggAcf(pret_petrol, lag.max = 48) + ggtitle("ACF – nivel"),    "03_acf_nivel.png")
sg(ggAcf(diff(pret_petrol), lag.max = 48) + ggtitle("ACF – d(1)"), "04_acf_d1.png")

cat("\n--- ADF nivel ---\n")
summary(ur.df(pret_petrol,       type = "drift", selectlags = "AIC"))
cat("\n--- ADF prima diferenta ---\n")
summary(ur.df(diff(pret_petrol), type = "drift", selectlags = "AIC"))

cat("\n--- KPSS nivel ---\n")
pret_petrol %>% ur.kpss() %>% summary()

cat("\n--- Phillips-Perron petrol ---\n")
PP.test(pret_petrol)
PP.test(diff(pret_petrol))

cat("\nndiffs =", ndiffs(pret_petrol), "| nsdiffs =", nsdiffs(pret_petrol), "\n")

# ── 3. MODELE UNIVARIATE — train/test ─────────────────────────────────────────

train <- window(pret_petrol, end   = c(2024, 12))
test  <- window(pret_petrol, start = c(2025,  1))

sg(autoplot(pret_petrol) +
     autolayer(train, series = "Training") +
     autolayer(test,  series = "Test") +
     ggtitle("Impartire training / test") + theme_bw(),
   "05_train_test.png")

sb("06_tsdisplay_d1.png",
   ggtsdisplay(diff(train), lag.max = 36, main = "Prima diferenta – identificare SARIMA"))

# ── 3a. SARIMA(0,1,1)(0,0,1)[12] ─────────────────────────────────────────────

sarima_model <- Arima(train, order = c(0,1,1), seasonal = c(0,0,1))
cat("\n--- SARIMA ---\n"); print(summary(sarima_model))
cat("\n--- Coeficienti SARIMA ---\n"); print(coeftest(sarima_model))
sb("07_sarima_checkresiduals.png", checkresiduals(sarima_model))
Box.test(residuals(sarima_model), lag = 10, type = "Lj")
cat("\n--- Jarque-Bera SARIMA ---\n"); jarque.bera.test(residuals(sarima_model))
sb("08_sarima_radacini.png", autoplot(sarima_model))

# ── 3b. ETS ───────────────────────────────────────────────────────────────────

ets_model <- ets(train)
cat("\n--- ETS ---\n"); print(summary(ets_model))
sb("09_ets_checkresiduals.png", checkresiduals(ets_model))
cat("\n--- Jarque-Bera ETS ---\n"); jarque.bera.test(residuals(ets_model))

# ── 3c. Comparatie si prognoza ────────────────────────────────────────────────

fc_sarima <- forecast(sarima_model, h = length(test))
fc_ets    <- forecast(ets_model,    h = length(test))

cat("\n--- Acuratete SARIMA ---\n"); print(accuracy(fc_sarima, test))
cat("\n--- Acuratete ETS ---\n");    print(accuracy(fc_ets,    test))

cat("\n--- Diebold-Mariano ---\n")
print(dm.test(residuals(sarima_model), residuals(ets_model), alternative = "two.sided"))

sg(autoplot(train) +
     autolayer(fc_sarima, series = "SARIMA", PI = TRUE) +
     autolayer(fc_ets,    series = "ETS",    PI = FALSE) +
     autolayer(test,      series = "Real") +
     ggtitle("Prognoza SARIMA vs ETS") + theme_bw(),
   "10_prognoza_comparatie.png")

sg(autoplot(forecast(sarima_model, h = 24)) +
     ggtitle("Prognoza SARIMA – 24 luni") + theme_bw(),
   "11_prognoza_sarima.png")

sg(autoplot(forecast(ets_model, h = 24)) +
     ggtitle("Prognoza ETS – 24 luni") + theme_bw(),
   "12_prognoza_ets.png")

# ── 4. VOLATILITATE — GARCH(1,1) ─────────────────────────────────────────────

randamente <- diff(log(pret_petrol)) * 100

sg(autoplot(randamente) +
     ggtitle("Randamente log lunare (%)") + xlab("Timp") + ylab("%") + theme_bw(),
   "13_randamente.png")

cat("\n--- ARCH-LM test ---\n")
print(FinTS::ArchTest(randamente, lags = 1))
print(FinTS::ArchTest(randamente, lags = 5))
print(FinTS::ArchTest(randamente, lags = 12))

garch11 <- garchFit(~ arma(1,1) + garch(1,1), data = randamente, trace = FALSE)
cat("\n--- GARCH(1,1) ---\n"); print(summary(garch11))

sg(ggplot(data.frame(t = time(randamente), vol = garch11@sigma.t), aes(t, vol)) +
     geom_line(color = "steelblue") +
     ggtitle("Volatilitate conditionata GARCH(1,1) (%)") +
     xlab("Timp") + ylab("Sigma (%)") + theme_bw(),
   "14_volatilitate_garch.png")

VaR95 <- quantile(randamente, 0.05)
dep95 <- sum(randamente < VaR95)
cat("\nVaR 95%:", round(VaR95, 3), "| Depasiri:", dep95, "/", length(randamente))
cat(" | Proportie:", round(dep95/length(randamente)*100, 2), "%\n")
print(binom.test(dep95, length(randamente), p = 0.05))

# ── 5. ANALIZA MULTIVARIATA — VAR ─────────────────────────────────────────────

cat("\n--- ADF curs USD/EUR nivel ---\n")
summary(ur.df(curs_usd_eur, type = "drift", selectlags = "AIC"))
cat("\n--- KPSS curs USD/EUR nivel ---\n")
curs_usd_eur %>% ur.kpss() %>% summary()
cat("\n--- Phillips-Perron curs ---\n")
PP.test(curs_usd_eur)
PP.test(diff(curs_usd_eur))
cat("\n--- ADF curs USD/EUR prima diferenta ---\n")
summary(ur.df(diff(curs_usd_eur), type = "drift", selectlags = "AIC"))

sg(autoplot(cbind(pret_petrol, curs_usd_eur)) +
     ggtitle("Petrol si Curs USD/EUR") + theme_bw(),
   "15_serii_bivariat.png")

cat("\n--- Johansen cointegrare ---\n")
jo <- ca.jo(cbind(pret_petrol, curs_usd_eur), type = "trace", ecdet = "const", K = 2)
print(summary(jo))

d_petrol <- diff(pret_petrol)
d_curs   <- diff(curs_usd_eur)

cat("\n--- Selectie lag VAR ---\n")
print(VARselect(cbind(d_petrol, d_curs), lag.max = 12, type = "const")$selection)

var_model <- VAR(cbind(d_petrol, d_curs), p = 2, type = "const")
cat("\n--- VAR(2) summary ---\n"); print(summary(var_model))

cat("\n--- Serial test VAR ---\n")
print(serial.test(var_model, lags.pt = 12, type = "PT.asymptotic"))

sb("16_var_diagnostice.png", {
  par(mfrow = c(2, 2))
  acf(resid(var_model)[, "d_petrol"], main = "ACF reziduuri – petrol")
  acf(resid(var_model)[, "d_curs"],   main = "ACF reziduuri – curs")
  plot(resid(var_model)[, "d_petrol"], type = "l", main = "Reziduuri – petrol")
  plot(resid(var_model)[, "d_curs"],   type = "l", main = "Reziduuri – curs")
  par(mfrow = c(1, 1))
})

cat("\n--- Granger: petrol -> curs ---\n")
print(causality(var_model, cause = "d_petrol")$Granger)
cat("\n--- Granger: curs -> petrol ---\n")
print(causality(var_model, cause = "d_curs")$Granger)

irf_p2c <- irf(var_model, impulse = "d_petrol", response = "d_curs",
                ortho = TRUE, boot = TRUE, runs = 500, n.ahead = 20)
irf_c2p <- irf(var_model, impulse = "d_curs",   response = "d_petrol",
                ortho = TRUE, boot = TRUE, runs = 500, n.ahead = 20)
sb("17_irf_petrol_curs.png", plot(irf_p2c))
sb("18_irf_curs_petrol.png", plot(irf_c2p))

fevd_r <- fevd(var_model, n.ahead = 12)
cat("\n--- FEVD h=12 ---\n"); print(lapply(fevd_r, tail, 1))
sb("19_fevd.png", plot(fevd_r))

sb("20_prognoza_var.png", plot(predict(var_model, n.ahead = 12)))

cat("\n✓ Grafice salvate in:", gp, "\n")
