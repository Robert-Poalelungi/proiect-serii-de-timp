library(fpp2)
library(forecast)
library(readr)
library(tseries)
library(urca)
library(lmtest)
library(FinTS)
library(vars)
library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)
library(e1071)
library(zoo)
library(scales)
library(fGarch)
library(rugarch)

# 0. IMPORT DATE

petrol_df <- read.csv("C:/Users/Robert/Desktop/SERII/proiect/petrol/pret_petrol_lunar.csv", stringsAsFactors = FALSE)
colnames(petrol_df) <- c("Luni", "Pret", "Variatie_procentuala", "Variatie_absoluta", "Curs_USD_EUR")
petrol_df$Pret <- as.numeric(petrol_df$Pret)
pret_petrol  <- ts(petrol_df$Pret,        start = c(1999, 1), frequency = 12)
curs_usd_eur <- ts(petrol_df$Curs_USD_EUR, start = c(1999, 1), frequency = 12)

# 1. VIZUALIZARE

autoplot(pret_petrol) +
  ggtitle("Pretul petrolului brut (USD/baril)") +
  xlab("Timp") + ylab("USD/baril") +
  theme_bw()

autoplot(diff(pret_petrol)) +
  ggtitle("Variatia lunara a pretului petrolului (USD/baril)") +
  xlab("Timp") + ylab("Variatie USD/baril") +
  theme_bw()

ggseasonplot(pret_petrol, year.labels = TRUE, year.labels.left = TRUE) +
  ylab("USD/baril") +
  ggtitle("Seasonal plot: pretul petrolului brut")

ggsubseriesplot(pret_petrol) +
  ylab("USD/baril") +
  ggtitle("Seasonal subseries plot: pretul petrolului brut") +
  theme_bw()

pret_petrol %>%
  stl(t.window = 13, s.window = "periodic", robust = TRUE) %>%
  autoplot() +
  ggtitle("Descompunere STL: pretul petrolului brut") +
  theme_bw()

# 2. STATIONARITATE

ggAcf(pret_petrol, lag.max = 48)
ggAcf(diff(pret_petrol), lag.max = 48)

rw_none <- ur.df(pret_petrol, type = "none", selectlags = c("AIC"))
summary(rw_none)

rw_t <- ur.df(pret_petrol, type = "drift", selectlags = c("AIC"))
summary(rw_t)

rw_ct <- ur.df(pret_petrol, type = "trend", selectlags = c("AIC"))
summary(rw_ct)

pret_petrol %>% ur.kpss() %>% summary()

PP.test(pret_petrol)

ndiffs(pret_petrol)
nsdiffs(pret_petrol)

pret_petrol_d1 <- diff(pret_petrol)

rw_none_d1 <- ur.df(pret_petrol_d1, type = "none", selectlags = c("AIC"))
summary(rw_none_d1)

rw_t_d1 <- ur.df(pret_petrol_d1, type = "drift", selectlags = c("AIC"))
summary(rw_t_d1)

rw_ct_d1 <- ur.df(pret_petrol_d1, type = "trend", selectlags = c("AIC"))
summary(rw_ct_d1)

pret_petrol_d1 %>% ur.kpss() %>% summary()
PP.test(pret_petrol_d1)
ggAcf(pret_petrol_d1, lag.max = 48)

# 3. HOLT-WINTERS

fit_hw_mu <- hw(pret_petrol, seasonal = "multiplicative")
round(forecast::accuracy(fit_hw_mu), 2)
summary(fit_hw_mu)

res_hw_mu <- residuals(fit_hw_mu)

autoplot(res_hw_mu) + xlab("Time") + ylab("") +
  ggtitle("Residuals from HW multiplicative") +
  theme_bw()

gghistogram(res_hw_mu) + ggtitle("Histogram of residuals") + theme_bw()

jarque.bera.test(res_hw_mu)

ggAcf(res_hw_mu) + ggtitle("ACF of residuals") + theme_bw()

Box.test(res_hw_mu, lag = 1)
Box.test(res_hw_mu, lag = 2)
Box.test(res_hw_mu, lag = 3)
Box.test(res_hw_mu, lag = 4)
Box.test(res_hw_mu, lag = 5)
Box.test(res_hw_mu, lag = 10)

Box.test(res_hw_mu, lag = 1,  type = "Lj")
Box.test(res_hw_mu, lag = 2,  type = "Lj")
Box.test(res_hw_mu, lag = 3,  type = "Lj")
Box.test(res_hw_mu, lag = 4,  type = "Lj")
Box.test(res_hw_mu, lag = 5,  type = "Lj")
Box.test(res_hw_mu, lag = 10, type = "Lj")

checkresiduals(fit_hw_mu)

FinTS::ArchTest(res_hw_mu, lags = 1)
FinTS::ArchTest(res_hw_mu, lags = 2)
FinTS::ArchTest(res_hw_mu, lags = 3)
FinTS::ArchTest(res_hw_mu, lags = 4)
FinTS::ArchTest(res_hw_mu, lags = 5)

e <- res_hw_mu - mean(res_hw_mu)
ggAcf(e^2)

# 4. ARIMA/SARIMA

h <- 12
n <- length(pret_petrol)

training <- window(pret_petrol, end   = time(pret_petrol)[n - h])
test     <- window(pret_petrol, start = time(pret_petrol)[n - h + 1])

autoplot(training, series = "Training") +
  autolayer(test, series = "Test") +
  xlab("Time") + ylab("USD/baril") +
  ggtitle("Impartirea seriei in training si test") +
  guides(colour = guide_legend(title = "Esantion")) +
  theme_bw()

autoplot(training) +
  ggtitle("Seria de training – pretul petrolului brut") +
  xlab("An") + ylab("USD/baril") +
  theme_bw()

ggsubseriesplot(training) +
  ylab("USD/baril") +
  ggtitle("Subserii sezoniere – pretul petrolului brut") +
  theme_bw()

ggseasonplot(training) +
  ylab("USD/baril") +
  ggtitle("Grafic sezonier – pretul petrolului brut") +
  theme_bw()

ggtsdisplay(training)

# 4.1 Stationaritate pe training

adf_none <- ur.df(training, type = "none",  selectlags = "AIC")
summary(adf_none)

adf_drift <- ur.df(training, type = "drift", selectlags = "AIC")
summary(adf_drift)

adf_trend <- ur.df(training, type = "trend", selectlags = "AIC")
summary(adf_trend)

training %>% ur.kpss() %>% summary()
PP.test(training)

training_d1 <- diff(training)
ggtsdisplay(training_d1)

summary(ur.df(training_d1, type = "none",  selectlags = "AIC"))
summary(ur.df(training_d1, type = "drift", selectlags = "AIC"))
summary(ur.df(training_d1, type = "trend", selectlags = "AIC"))
training_d1 %>% ur.kpss() %>% summary()
PP.test(training_d1)

training_D1 <- diff(training, lag = 12)
ggtsdisplay(training_D1)

summary(ur.df(training_D1, type = "none",  selectlags = "AIC"))
summary(ur.df(training_D1, type = "drift", selectlags = "AIC"))
summary(ur.df(training_D1, type = "trend", selectlags = "AIC"))
training_D1 %>% ur.kpss() %>% summary()
PP.test(training_D1)

training_d1D1 <- diff(diff(training, lag = 12), differences = 1)
ggtsdisplay(training_d1D1)

summary(ur.df(training_d1D1, type = "none",  selectlags = "AIC"))
summary(ur.df(training_d1D1, type = "drift", selectlags = "AIC"))
summary(ur.df(training_d1D1, type = "trend", selectlags = "AIC"))
training_d1D1 %>% ur.kpss() %>% summary()
PP.test(training_d1D1)

# 4.2 Estimare SARIMA

fit_sarima <- Arima(training, order = c(0,1,1), seasonal = c(0,0,1))
coeftest(fit_sarima)
summary(fit_sarima)

# 4.4 Diagnostic SARIMA

checkresiduals(fit_sarima, lag = 48)

Box.test(residuals(fit_sarima), lag = 12, type = "Ljung")
Box.test(residuals(fit_sarima), lag = 24, type = "Ljung")
Box.test(residuals(fit_sarima), lag = 36, type = "Ljung")
Box.test(residuals(fit_sarima), lag = 48, type = "Ljung")

jarque.bera.test(residuals(fit_sarima))

ArchTest(residuals(fit_sarima), lags = 12)
ArchTest(residuals(fit_sarima), lags = 24)
ArchTest(residuals(fit_sarima), lags = 36)
ArchTest(residuals(fit_sarima), lags = 48)

# 4.5 Estimare ETS

fit_ets <- ets(training)
summary(fit_ets)
checkresiduals(fit_ets)

# 5. PREDICTIE

fc_sarima <- forecast(fit_sarima, h = h)
fc_ets    <- forecast(fit_ets,    h = h)

forecast::accuracy(fc_sarima, test)
forecast::accuracy(fc_ets,    test)

autoplot(training, series = "Train") +
  autolayer(test, series = "Test") +
  autolayer(fc_sarima$mean, series = "Prognoza SARIMA") +
  xlab("Time") + ylab("USD/baril") +
  ggtitle("Prognoza out-of-sample – model SARIMA") +
  guides(colour = guide_legend(title = "Serie")) +
  theme_bw()

autoplot(training, series = "Train") +
  autolayer(test, series = "Test") +
  autolayer(fc_ets$mean, series = "Prognoza ETS") +
  xlab("Time") + ylab("USD/baril") +
  ggtitle("Prognoza out-of-sample – model ETS") +
  guides(colour = guide_legend(title = "Serie")) +
  theme_bw()

autoplot(training, series = "Train") +
  autolayer(test, series = "Test") +
  autolayer(fc_sarima$mean, series = "Prognoza SARIMA") +
  autolayer(fc_ets$mean,    series = "Prognoza ETS") +
  xlab("Time") + ylab("USD/baril") +
  ggtitle("Comparatia prognozelor pe setul de test") +
  guides(colour = guide_legend(title = "Serie")) +
  theme_bw()

# 6. DIEBOLD-MARIANO

dm.test(residuals(fit_sarima), residuals(fit_ets))

# 7. ARCH/GARCH

# 7.1 Randamente logaritmice

pret_petrol_returns     <- diff(log(pret_petrol))
pret_petrol_returns_pct <- 100 * pret_petrol_returns

autoplot(log(pret_petrol)) +
  ggtitle("Pretul petrolului brut (log-nivel)") +
  ylab("log(USD/baril)") + xlab("Time") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5))

autoplot(pret_petrol_returns_pct) +
  ggtitle("Randamente logaritmice lunare ale petrolului (%)") +
  ylab("Returns (%)") + xlab("Time") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5))

# 7.2 Analiza distributionala

ggplot(data.frame(r = as.numeric(pret_petrol_returns_pct)), aes(x = r)) +
  geom_histogram(bins = 40) +
  ggtitle("Distributia randamentelor petrolului") +
  xlab("Returns (%)") + ylab("Frequency") +
  theme_bw()

summary(pret_petrol_returns_pct)
sd(pret_petrol_returns_pct)
tseries::jarque.bera.test(as.numeric(pret_petrol_returns_pct))

# 7.3 Stationaritate randamente

adf_level <- ur.df(log(pret_petrol), type = "trend", selectlags = "AIC")
summary(adf_level)

adf_returns <- ur.df(pret_petrol_returns_pct, type = "none", selectlags = "AIC")
summary(adf_returns)

ur.kpss(pret_petrol_returns_pct) %>% summary()

# 7.4 Ecuatia mediei

ggtsdisplay(pret_petrol_returns_pct, lag.max = 36)

arma11 <- Arima(pret_petrol_returns_pct, order = c(1,0,1), include.constant = TRUE)
summary(arma11)
coeftest(arma11)
checkresiduals(arma11)

# 7.5 Testare efecte ARCH

ArchTest(residuals(arma11), lags = 1)
ArchTest(residuals(arma11), lags = 2)
ArchTest(residuals(arma11), lags = 4)
ArchTest(residuals(arma11), lags = 8)

ggPacf(residuals(arma11)^2, lag.max = 12)

# 7.6 Estimare ARCH

arch1_fit <- garchFit(~ arma(1,1) + garch(1,0), data = pret_petrol_returns_pct, trace = FALSE)
arch2_fit <- garchFit(~ arma(1,1) + garch(2,0), data = pret_petrol_returns_pct, trace = FALSE)
arch3_fit <- garchFit(~ arma(1,1) + garch(3,0), data = pret_petrol_returns_pct, trace = FALSE)

summary(arch1_fit)
summary(arch2_fit)
summary(arch3_fit)

arch_fit <- arch3_fit

# 7.7 Estimare GARCH

garch11_fit <- garchFit(~ arma(1,1) + garch(1,1), data = pret_petrol_returns_pct, trace = FALSE)
summary(garch11_fit)

garch21_fit <- garchFit(~ arma(1,1) + garch(2,1), data = pret_petrol_returns_pct, trace = FALSE)
summary(garch21_fit)

garch_fit <- garch11_fit

summary(garch_fit)

coef_garch <- coef(garch_fit)
coef_garch

persistence <- coef_garch["alpha1"] + coef_garch["beta1"]
persistence

# 7.8 Diagnostic GARCH

std_resid <- residuals(garch_fit, standardize = TRUE)

Box.test(std_resid,    lag = 12, type = "Ljung")
Box.test(std_resid,    lag = 24, type = "Ljung")
Box.test(std_resid,    lag = 36, type = "Ljung")

Box.test(std_resid^2,  lag = 12, type = "Ljung")
Box.test(std_resid^2,  lag = 24, type = "Ljung")
Box.test(std_resid^2,  lag = 36, type = "Ljung")

ArchTest(std_resid, lags = 12)
ArchTest(std_resid, lags = 24)
ArchTest(std_resid, lags = 36)

jarque.bera.test(as.numeric(std_resid))

# 7.9 Volatilitate conditionata

garch_conditional_variance <- ts(garch_fit@h.t,
                                 start     = start(pret_petrol_returns_pct),
                                 frequency = frequency(pret_petrol_returns_pct))

autoplot(garch_conditional_variance) +
  ggtitle("Varianta conditionata estimata – model GARCH(1,1)") +
  ylab("Conditional variance") + xlab("Time") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5))

garch_conditional_sd <- sqrt(garch_conditional_variance)

autoplot(garch_conditional_sd) +
  ggtitle("Volatilitatea conditionata estimata – model GARCH(1,1)") +
  ylab("Conditional volatility") + xlab("Time") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5))

autoplot(pret_petrol_returns_pct) +
  autolayer(garch_conditional_sd, series = "Conditional volatility") +
  ggtitle("Randamente si volatilitate conditionata – model GARCH") +
  ylab("Returns / Volatility") + xlab("Time") +
  guides(colour = guide_legend(title = "Serie")) +
  theme_bw()

arch_conditional_variance <- ts(arch_fit@h.t,
                                start     = start(pret_petrol_returns_pct),
                                frequency = frequency(pret_petrol_returns_pct))
arch_conditional_sd <- sqrt(arch_conditional_variance)

autoplot(pret_petrol_returns_pct, series = "Returns") +
  autolayer(arch_conditional_sd,  series = "ARCH volatility") +
  autolayer(garch_conditional_sd, series = "GARCH volatility") +
  ggtitle("Compararea volatilitatii estimate: ARCH vs GARCH") +
  ylab("Returns / Volatility") + xlab("Time") +
  guides(colour = guide_legend(title = "Serie")) +
  theme_bw()

# 7.10 Value at Risk

arch_conditional_mean <- fitted(arch_fit)
arch_conditional_sd   <- sqrt(arch_conditional_variance)

length(pret_petrol_returns_pct)
length(arch_conditional_mean)
length(arch_conditional_sd)

n_var <- min(length(pret_petrol_returns_pct),
             length(arch_conditional_mean),
             length(arch_conditional_sd))

returns_var <- tail(as.numeric(pret_petrol_returns_pct), n_var)
mean_var    <- tail(as.numeric(arch_conditional_mean),   n_var)
sd_var      <- tail(as.numeric(arch_conditional_sd),     n_var)

time_var <- tail(time(pret_petrol_returns_pct), n_var)

alpha_95 <- 0.05
alpha_99 <- 0.01

z_95 <- qnorm(alpha_95)
z_99 <- qnorm(alpha_99)

VaR_95 <- mean_var + z_95 * sd_var
VaR_99 <- mean_var + z_99 * sd_var

var_data <- data.frame(
  Time    = time_var,
  Returns = returns_var,
  Mu      = mean_var,
  Sigma   = sd_var,
  VaR_95  = VaR_95,
  VaR_99  = VaR_99
)

head(var_data)
tail(var_data)

ggplot(var_data, aes(x = Time)) +
  geom_line(aes(y = Returns, colour = "Randamente"), linewidth = 0.3) +
  geom_line(aes(y = VaR_95,  colour = "VaR 95%"),    linewidth = 0.5) +
  geom_line(aes(y = VaR_99,  colour = "VaR 99%"),    linewidth = 0.5) +
  ggtitle("Randamente si Value at Risk conditionat") +
  xlab("Time") + ylab("Returns / VaR (%)") +
  scale_colour_manual(values = c("Randamente" = "black",
                                 "VaR 95%"    = "blue",
                                 "VaR 99%"    = "red")) +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5), legend.title = element_blank())

var_data$exceed_95 <- ifelse(var_data$Returns < var_data$VaR_95, 1, 0)
var_data$exceed_99 <- ifelse(var_data$Returns < var_data$VaR_99, 1, 0)

sum(var_data$exceed_95)
sum(var_data$exceed_99)
mean(var_data$exceed_95)
mean(var_data$exceed_99)

ggplot(var_data, aes(x = Time)) +
  geom_line(aes(y = Returns), colour = "black", linewidth = 0.3) +
  geom_line(aes(y = VaR_95),  colour = "blue",  linewidth = 0.5) +
  geom_point(data = subset(var_data, exceed_95 == 1),
             aes(y = Returns), colour = "blue", size = 1.5) +
  ggtitle("Depasirile Value at Risk la 95%") +
  xlab("Time") + ylab("Returns / VaR 95%") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5))

ggplot(var_data, aes(x = Time)) +
  geom_line(aes(y = Returns), colour = "black", linewidth = 0.3) +
  geom_line(aes(y = VaR_99),  colour = "red",   linewidth = 0.5) +
  geom_point(data = subset(var_data, exceed_99 == 1),
             aes(y = Returns), colour = "red", size = 1.5) +
  ggtitle("Depasirile Value at Risk la 99%") +
  xlab("Time") + ylab("Returns / VaR 99%") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5))

var_summary <- data.frame(
  Nivel = c("VaR 95%", "VaR 99%"),
  Probabilitate.teoretica = c(0.05, 0.01),
  Numar.depasiri          = c(sum(var_data$exceed_95),  sum(var_data$exceed_99)),
  Frecventa.empirica      = c(mean(var_data$exceed_95), mean(var_data$exceed_99))
)
var_summary

# 7.11 Backtesting VaR

n_obs <- nrow(var_data)

expected_95 <- alpha_95 * n_obs
observed_95 <- sum(var_data$exceed_95)

expected_99 <- alpha_99 * n_obs
observed_99 <- sum(var_data$exceed_99)

expected_95
observed_95
expected_99
observed_99

binom.test(observed_95, n_obs, p = alpha_95)
binom.test(observed_99, n_obs, p = alpha_99)

# 7.12 Extensii rugarch

spec_sgarch <- ugarchspec(
  variance.model     = list(model = "sGARCH",   garchOrder = c(1,1)),
  mean.model         = list(armaOrder = c(1,0),  include.mean = TRUE),
  distribution.model = "norm"
)
fit_sgarch <- ugarchfit(spec = spec_sgarch, data = pret_petrol_returns_pct)
fit_sgarch

spec_egarch <- ugarchspec(
  variance.model     = list(model = "eGARCH",   garchOrder = c(1,1)),
  mean.model         = list(armaOrder = c(1,0),  include.mean = TRUE),
  distribution.model = "norm"
)
fit_egarch <- ugarchfit(spec = spec_egarch, data = pret_petrol_returns_pct)
fit_egarch

spec_gjr <- ugarchspec(
  variance.model     = list(model = "gjrGARCH", garchOrder = c(1,1)),
  mean.model         = list(armaOrder = c(1,0),  include.mean = TRUE),
  distribution.model = "norm"
)
fit_gjr <- ugarchfit(spec = spec_gjr, data = pret_petrol_returns_pct)
fit_gjr

spec_aparch <- ugarchspec(
  variance.model     = list(model = "apARCH",   garchOrder = c(1,1)),
  mean.model         = list(armaOrder = c(1,0),  include.mean = TRUE),
  distribution.model = "norm"
)
fit_aparch <- ugarchfit(spec = spec_aparch, data = pret_petrol_returns_pct)
fit_aparch

spec_igarch <- ugarchspec(
  variance.model     = list(model = "iGARCH",   garchOrder = c(1,1)),
  mean.model         = list(armaOrder = c(1,0),  include.mean = TRUE),
  distribution.model = "norm"
)
fit_igarch <- ugarchfit(spec = spec_igarch, data = pret_petrol_returns_pct)
fit_igarch

spec_csgarch <- ugarchspec(
  variance.model     = list(model = "csGARCH",  garchOrder = c(1,1)),
  mean.model         = list(armaOrder = c(1,0),  include.mean = TRUE),
  distribution.model = "norm"
)
fit_csgarch <- ugarchfit(spec = spec_csgarch, data = pret_petrol_returns_pct)
fit_csgarch

# 8. VAR - ANALIZA MULTIVARIATA

Y <- cbind(Petrol = pret_petrol, Curs = curs_usd_eur)

# 8.1 Analiza descriptiva

df <- data.frame(
  timp   = as.yearmon(time(pret_petrol)),
  petrol = as.numeric(pret_petrol),
  curs   = as.numeric(curs_usd_eur)
)

df_long <- df %>%
  pivot_longer(cols = c(petrol, curs),
               names_to  = "variabila",
               values_to = "valoare")

ggplot(df_long, aes(x = timp, y = valoare, color = variabila)) +
  geom_line(size = 1) +
  geom_hline(data = df_long %>% group_by(variabila) %>%
               summarise(mean_val = mean(valoare, na.rm = TRUE)),
             aes(yintercept = mean_val, color = variabila),
             linetype = "dashed", size = 0.8) +
  facet_wrap(~variabila, ncol = 1, scales = "free_y",
             labeller = labeller(
               variabila = c(petrol = "Pretul petrolului (USD/baril)",
                             curs   = "Cursul USD/EUR"))) +
  labs(x = "Timp", y = "", color = "") +
  scale_color_manual(values = c(petrol = "darkred", curs = "darkblue")) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none",
        strip.text = element_text(size = 12, face = "bold"))

stat_desc <- data.frame(
  Serie   = c("pret_petrol", "curs_usd_eur"),
  Media   = c(mean(pret_petrol),   mean(curs_usd_eur)),
  Mediana = c(median(pret_petrol), median(curs_usd_eur)),
  Min     = c(min(pret_petrol),    min(curs_usd_eur)),
  Max     = c(max(pret_petrol),    max(curs_usd_eur)),
  SD      = c(sd(pret_petrol),     sd(curs_usd_eur)),
  CV      = c(sd(pret_petrol)/mean(pret_petrol), sd(curs_usd_eur)/mean(curs_usd_eur))
)
stat_desc

cor(pret_petrol, curs_usd_eur, use = "complete.obs")

ggtsdisplay(pret_petrol,  main = "Pretul petrolului")
ggtsdisplay(curs_usd_eur, main = "Cursul USD/EUR")

ccf_res <- ccf(pret_petrol, curs_usd_eur, plot = FALSE)
df_ccf  <- data.frame(lag = ccf_res$lag, ccf = ccf_res$acf)
ggplot(df_ccf, aes(x = lag, y = ccf)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  geom_hline(yintercept = 0) +
  geom_hline(yintercept = c( 2/sqrt(length(pret_petrol)),
                             -2/sqrt(length(pret_petrol))),
             linetype = "dashed", color = "red") +
  labs(title = "CCF: Pret petrol vs Curs USD/EUR",
       x = "Lag", y = "Corelatie") +
  theme_minimal()

# 8.2 Stationaritate bivariata

adf_petrol_none  <- ur.df(pret_petrol, type = "none",  selectlags = "AIC")
adf_petrol_drift <- ur.df(pret_petrol, type = "drift", selectlags = "AIC")
adf_petrol_trend <- ur.df(pret_petrol, type = "trend", selectlags = "AIC")
summary(adf_petrol_none)
summary(adf_petrol_drift)
summary(adf_petrol_trend)

kpss_petrol_mu  <- ur.kpss(pret_petrol, type = "mu",  lags = "long")
kpss_petrol_tau <- ur.kpss(pret_petrol, type = "tau", lags = "long")
summary(kpss_petrol_mu)
summary(kpss_petrol_tau)

print(pp.test(pret_petrol, lshort = FALSE))

adf_petrol_none  <- ur.df(diff(pret_petrol), type = "none",  selectlags = "AIC")
adf_petrol_drift <- ur.df(diff(pret_petrol), type = "drift", selectlags = "AIC")
adf_petrol_trend <- ur.df(diff(pret_petrol), type = "trend", selectlags = "AIC")
summary(adf_petrol_none)
summary(adf_petrol_drift)
summary(adf_petrol_trend)

kpss_petrol_mu  <- ur.kpss(diff(pret_petrol), type = "mu",  lags = "long")
kpss_petrol_tau <- ur.kpss(diff(pret_petrol), type = "tau", lags = "long")
summary(kpss_petrol_mu)
summary(kpss_petrol_tau)

print(pp.test(diff(pret_petrol), lshort = FALSE))

adf_curs_none  <- ur.df(curs_usd_eur, type = "none",  selectlags = "AIC")
adf_curs_drift <- ur.df(curs_usd_eur, type = "drift", selectlags = "AIC")
adf_curs_trend <- ur.df(curs_usd_eur, type = "trend", selectlags = "AIC")
summary(adf_curs_none)
summary(adf_curs_drift)
summary(adf_curs_trend)

kpss_curs_mu  <- ur.kpss(curs_usd_eur, type = "mu",  lags = "long")
kpss_curs_tau <- ur.kpss(curs_usd_eur, type = "tau", lags = "long")
summary(kpss_curs_mu)
summary(kpss_curs_tau)

print(pp.test(curs_usd_eur, lshort = FALSE))

adf_curs_none  <- ur.df(diff(curs_usd_eur), type = "none",  selectlags = "AIC")
adf_curs_drift <- ur.df(diff(curs_usd_eur), type = "drift", selectlags = "AIC")
adf_curs_trend <- ur.df(diff(curs_usd_eur), type = "trend", selectlags = "AIC")
summary(adf_curs_none)
summary(adf_curs_drift)
summary(adf_curs_trend)

kpss_curs_mu  <- ur.kpss(diff(curs_usd_eur), type = "mu",  lags = "long")
kpss_curs_tau <- ur.kpss(diff(curs_usd_eur), type = "tau", lags = "long")
summary(kpss_curs_mu)
summary(kpss_curs_tau)

print(pp.test(diff(curs_usd_eur), lshort = FALSE))

# 8.3 Selectia lagului si cointegrare Johansen

lag_select <- VARselect(Y, lag.max = 8, type = "const")
print(lag_select)

p_opt <- lag_select$selection["AIC(n)"]
p_opt <- as.numeric(p_opt)

johansen_test <- ca.jo(Y, type = "trace", ecdet = "const", K = p_opt)
summary(johansen_test)

# 8.4 VAR pe diferente

petrol_d1 <- diff(pret_petrol)
curs_d1   <- diff(curs_usd_eur)

Y_d1 <- cbind(Petrol = petrol_d1, Curs = curs_d1)

lag_select_d1 <- VARselect(Y_d1, lag.max = 8, type = "const")
print(lag_select_d1)

p_opt_d1 <- lag_select_d1$selection["SC(n)"]
p_opt_d1 <- as.numeric(p_opt_d1)
cat("Lag optim SC pentru VAR pe diferente =", p_opt_d1, "\n")

var_model_d1 <- VAR(Y_d1, p = p_opt_d1, type = "const")
summary(var_model_d1)

cat("\n--- Ecuatia pentru DeltaPetrol ---\n")
print(summary(var_model_d1$varresult$Petrol))

cat("\n--- Ecuatia pentru DeltaCurs ---\n")
print(summary(var_model_d1$varresult$Curs))

# 8.5 Diagnostic VAR - model SC

roots(var_model_d1)
plot(stability(var_model_d1, type = "OLS-CUSUM"), main = "Test de stabilitate OLS-CUSUM")

serial.test(var_model_d1, lags.pt =  4, type = "PT.asymptotic")
serial.test(var_model_d1, lags.pt =  8, type = "PT.asymptotic")
serial.test(var_model_d1, lags.pt = 12, type = "PT.asymptotic")
serial.test(var_model_d1, lags.pt = 16, type = "PT.asymptotic")

p_opt_d2 <- lag_select_d1$selection["AIC(n)"]
p_opt_d2 <- as.numeric(p_opt_d2)
cat("Lag optim AIC pentru VAR pe diferente =", p_opt_d2, "\n")

var_model_d2 <- VAR(Y_d1, p = p_opt_d2, type = "const")
summary(var_model_d2)

cat("\n--- Ecuatia pentru DeltaPetrol ---\n")
print(summary(var_model_d2$varresult$Petrol))

cat("\n--- Ecuatia pentru DeltaCurs ---\n")
print(summary(var_model_d2$varresult$Curs))

# 8.6 Diagnostic VAR - model AIC

roots(var_model_d2)
plot(stability(var_model_d2, type = "OLS-CUSUM"), main = "Test de stabilitate OLS-CUSUM")

serial.test(var_model_d2, lags.pt = 12, type = "PT.asymptotic")
serial.test(var_model_d2, lags.pt = 16, type = "PT.asymptotic")

arch.test(var_model_d2, lags.multi = 12)
arch.test(var_model_d2, lags.multi = 16)

normality.test(var_model_d2)

resid_var  <- residuals(var_model_d2)
res_petrol <- ts(resid_var[, 1],
                 start     = time(petrol_d1)[p_opt_d2 + 1],
                 frequency = frequency(petrol_d1))
res_curs   <- ts(resid_var[, 2],
                 start     = time(curs_d1)[p_opt_d2 + 1],
                 frequency = frequency(curs_d1))

df_res <- data.frame(
  timp   = as.yearmon(as.numeric(time(res_petrol))),
  petrol = as.numeric(res_petrol),
  curs   = as.numeric(res_curs))

ggplot(df_res, aes(x = timp, y = petrol)) +
  geom_line(color = "darkred", linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(title = "Reziduuri ecuatia DeltaPetrol", x = "Timp", y = "") +
  theme_minimal()

ggplot(df_res, aes(x = timp, y = curs)) +
  geom_line(color = "darkblue", linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(title = "Reziduuri ecuatia DeltaCurs", x = "Timp", y = "") +
  theme_minimal()

ggAcf(res_petrol) + ggtitle("ACF reziduuri DeltaPetrol")
ggAcf(res_curs)   + ggtitle("ACF reziduuri DeltaCurs")

# 8.7 Cauzalitate Granger

causality(var_model_d2, cause = "Petrol")
causality(var_model_d2, cause = "Curs")

# 8.8 IRF

set.seed(123)
irf_petrol_to_curs <- irf(
  var_model_d2,
  impulse  = "Petrol",
  response = "Curs",
  n.ahead  = 12,
  boot     = TRUE,
  ci       = 0.95,
  ortho    = TRUE,
  runs     = 1000)
plot(irf_petrol_to_curs, main = "IRF: raspunsul DeltaCurs la un soc de DeltaPetrol")

irf_curs_to_petrol <- irf(
  var_model_d2,
  impulse  = "Curs",
  response = "Petrol",
  n.ahead  = 12,
  boot     = TRUE,
  ci       = 0.95,
  ortho    = TRUE,
  runs     = 1000)
plot(irf_curs_to_petrol, main = "IRF: raspunsul DeltaPetrol la un soc de DeltaCurs")

irf_all <- irf(
  var_model_d2,
  n.ahead = 12,
  boot    = TRUE,
  ci      = 0.95,
  ortho   = TRUE,
  runs    = 1000)
plot(irf_all)

irf_obj <- irf_all
df_irf  <- data.frame(
  perioada       = 0:12,
  petrol_to_curs = irf_obj$irf$Petrol[, "Curs"],
  curs_to_petrol = irf_obj$irf$Curs[,   "Petrol"]
)

ggplot(df_irf, aes(x = perioada, y = petrol_to_curs)) +
  geom_line(color = "darkred", linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(title = "IRF: raspunsul DeltaCurs la soc de DeltaPetrol",
       x = "Perioade", y = "Raspuns") +
  theme_minimal()

ggplot(df_irf, aes(x = perioada, y = curs_to_petrol)) +
  geom_line(color = "darkblue", linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(title = "IRF: raspunsul DeltaPetrol la soc de DeltaCurs",
       x = "Perioade", y = "Raspuns") +
  theme_minimal()

# 8.9 FEVD

fevd_var    <- fevd(var_model_d2, n.ahead = 12)
fevd_petrol <- as.data.frame(fevd_var$Petrol)
fevd_petrol$Orizont <- 1:nrow(fevd_petrol)
fevd_curs   <- as.data.frame(fevd_var$Curs)
fevd_curs$Orizont   <- 1:nrow(fevd_curs)

print(round(fevd_petrol, 2))
print(round(fevd_curs,   2))

plot(fevd_var)

fevd_petrol$Variabila <- "DeltaPetrol"
fevd_curs$Variabila   <- "DeltaCurs"
fevd_df   <- bind_rows(fevd_petrol, fevd_curs)
fevd_long <- fevd_df %>%
  pivot_longer(cols = c("Petrol", "Curs"),
               names_to  = "Soc",
               values_to = "Proportie")
fevd_long$Soc <- factor(fevd_long$Soc,
                        levels = c("Petrol", "Curs"),
                        labels = c("Soc DeltaPetrol", "Soc DeltaCurs"))

ggplot(fevd_long, aes(x = Orizont, y = Proportie, fill = Soc)) +
  geom_col(position = "stack", color = "white", width = 0.8) +
  facet_wrap(~Variabila, ncol = 1) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(title = "FEVD - Decompunerea variantei erorii de prognoza",
       x = "Orizont", y = "Proportie explicata", fill = "Tipul socului") +
  theme_minimal(base_size = 12) +
  theme(strip.text = element_text(face = "bold"), legend.position = "bottom")

ggplot(fevd_long, aes(x = Orizont, y = Proportie, fill = Soc)) +
  geom_area(alpha = 0.85, color = "white", linewidth = 0.3) +
  facet_wrap(~Variabila, ncol = 1) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(title = "FEVD - Structura surselor de variabilitate",
       x = "Orizont", y = "Proportie explicata", fill = "Tipul socului") +
  theme_minimal(base_size = 12) +
  theme(strip.text = element_text(face = "bold"), legend.position = "bottom")

ggplot(fevd_long, aes(x = Orizont, y = Proportie, color = Soc)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  facet_wrap(~Variabila, ncol = 1) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(title = "FEVD - Evolutia contributiei socurilor pe orizonturi",
       x = "Orizont", y = "Proportie explicata", color = "Tipul socului") +
  theme_minimal(base_size = 12) +
  theme(strip.text = element_text(face = "bold"), legend.position = "bottom")

# 8.10 Prognoza VAR

h_var <- 12

forecast_var_d1 <- predict(var_model_d2, n.ahead = h_var, ci = 0.95)
plot(forecast_var_d1)

fc_petrol_d1 <- forecast_var_d1$fcst$Petrol
fc_curs_d1   <- forecast_var_d1$fcst$Curs

last_petrol <- as.numeric(tail(pret_petrol, 1))
last_curs   <- as.numeric(tail(curs_usd_eur, 1))

fc_petrol_nivel <- last_petrol + cumsum(fc_petrol_d1[, "fcst"])
fc_curs_nivel   <- last_curs   + cumsum(fc_curs_d1[,   "fcst"])

start_fc           <- c(2026, 6)
fc_petrol_nivel_ts <- ts(fc_petrol_nivel, start = start_fc, frequency = 12)
fc_curs_nivel_ts   <- ts(fc_curs_nivel,   start = start_fc, frequency = 12)

autoplot(pret_petrol, series = "Observat") +
  autolayer(fc_petrol_nivel_ts, series = "Prognoza VAR") +
  xlab("Timp") + ylab("USD/baril") +
  ggtitle("Prognoza VAR reconvertita in nivel – pret petrol") +
  guides(colour = guide_legend(title = "Serie")) +
  theme_bw()

autoplot(curs_usd_eur, series = "Observat") +
  autolayer(fc_curs_nivel_ts, series = "Prognoza VAR") +
  xlab("Timp") + ylab("USD/EUR") +
  ggtitle("Prognoza VAR reconvertita in nivel – curs USD/EUR") +
  guides(colour = guide_legend(title = "Serie")) +
  theme_bw()
