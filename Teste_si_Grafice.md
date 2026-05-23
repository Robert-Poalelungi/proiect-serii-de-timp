# Teste statistice și grafice diagnostice

## 1. Stationaritate

### Teste ADF — seria în nivel
1. ADF `type="none"` → tau1 = -0.52 (val. critică 5%: -1.95) — **nestaționar**
2. ADF `type="drift"` → tau2 = -2.93 (val. critică 5%: -2.86) — **nestaționar**
3. ADF `type="trend"` → tau3 = -3.15 (val. critică 5%: -3.41) — **nestaționar**

### Teste KPSS și Phillips-Perron — seria în nivel
4. KPSS → 1.4869 (val. critică 1%: 0.739) — **nestaționar**
5. Phillips-Perron → p = 0.629 — **nestaționar**

### Grafice diagnostice — nivel
![ACF – nivel](grafice/06_acf_nivel.png)
![ACF – prima diferență](grafice/07_acf_diferenta.png)

---

### Teste ADF — prima diferență
6. ADF `type="none"` → tau1 = -11.32 (val. critică 1%: -2.58) — **staționar**
7. ADF `type="drift"` → tau2 = -11.31 (val. critică 1%: -3.43) — **staționar**
8. ADF `type="trend"` → tau3 = -11.31 (val. critică 1%: -3.96) — **staționar**

### Grafic diagnostic — prima diferență
![ACF – d1 (confirmare stationaritate)](grafice/08_acf_d1.png)

**Concluzie: seria este I(1). `ndiffs = 1`, `nsdiffs = 0`.**

---

## 2. Holt-Winters multiplicativ

### Teste diagnostice reziduuri
9. Ljung-Box → Q* = 18.77, df = 8, **p = 0.016** — autocorelare prezentă
10. ARCH-LM lag 2 → Chi² = 23.06, df = 2, **p = 9.77e-06** — efecte ARCH prezente
11. ARCH-LM lag 12 → Chi² = 45.83, df = 12, **p = 4.66e-05** — efecte ARCH prezente

### Grafice diagnostice
![Reziduuri HW](grafice/09_hw_reziduuri.png)
![Histogramă reziduuri HW](grafice/10_hw_histogram.png)
![ACF reziduuri HW](grafice/11_hw_acf_reziduuri.png)
![Checkresiduals HW](grafice/12_hw_checkresiduals.png)
![ACF pătrat reziduuri HW](grafice/13_hw_acf_patrat.png)

---

## 3. SARIMA(0,1,1)(0,0,1)[12]

### Identificare — grafice Box-Jenkins
![Training serie](grafice/15_training_serie.png)
![Training tsdisplay nivel](grafice/18_training_tsdisplay.png)
![Training tsdisplay d1](grafice/19_training_d1_tsdisplay.png)
![Training tsdisplay D1](grafice/20_training_D1_tsdisplay.png)
![Training tsdisplay d1+D1](grafice/21_training_d1D1_tsdisplay.png)

### Teste coeficienți
12. z-test **ma1** = 0.1858, SE = 0.0517 → z = 3.593, **p = 0.0003** — semnificativ
13. z-test **sma1** = -0.0881, SE = 0.0594 → z = -1.483, **p = 0.138** — nesemnificativ

### Teste diagnostice reziduuri
14. Ljung-Box → Q* = 17.51, df = 22, **p = 0.776** — fără autocorelare ✓
15. ARCH-LM lag 12 → Chi² = 24.01, df = 12, **p = 0.020** — efecte ARCH prezente

### Grafice diagnostice
![Checkresiduals SARIMA](grafice/22_sarima_checkresiduals.png)

---

## 4. ETS(M,A,N)

### Test diagnostic reziduuri
16. Ljung-Box → Q* = 28.46, df = 19, **p = 0.074** — marginal la 5%

### Grafice diagnostice
![Checkresiduals ETS](grafice/23_ets_checkresiduals.png)

---

## 5. Comparație SARIMA vs ETS

### Test formal
17. Diebold-Mariano → DM = 8.498, **p = 7.73e-16** — diferență semnificativă, ETS superior

### Grafice prognoze
![Train/test split](grafice/14_train_test_split.png)
![Prognoza SARIMA](grafice/24_prognoza_sarima.png)
![Prognoza ETS](grafice/25_prognoza_ets.png)
![Comparație prognoze](grafice/26_prognoza_comparatie.png)

---

## 6. GARCH(1,1) — volatilitate

### Identificare efecte ARCH
18. ARCH-LM lag 5 → Chi² = 31.85, df = 5, **p = 6.46e-06** — ARCH prezent
19. ARCH-LM lag 12 → Chi² = 46.92, df = 12, **p = 3.01e-05** — ARCH prezent

### Grafice identificare
![Log-prețul petrolului](grafice/27_log_nivel.png)
![Randamente lunare](grafice/28_randamente.png)
![Distribuția randamentelor](grafice/29_distributie_randamente.png)
![Randamente tsdisplay](grafice/30_returns_tsdisplay.png)
![Checkresiduals ARMA(1,1)](grafice/31_arma11_checkresiduals.png)
![PACF pătrat reziduuri](grafice/32_pacf_rez_patrat.png)

### Grafice model GARCH estimat
![Varianța condiționată](grafice/33_garch_varianta_cond.png)
![Volatilitatea condiționată](grafice/34_garch_volatilitate_cond.png)
![Randamente și volatilitate](grafice/35_returns_si_volatilitate.png)
![ARCH vs GARCH comparație](grafice/36_arch_vs_garch.png)

---

## 7. VaR — backtesting

### Teste formale
20. Backtest binomial VaR 95% → 16/328 = 4.88%, **p = 1.000** — model valid ✓
21. Backtest binomial VaR 99% → 7/328 = 2.13%, **p = 0.049** — model respins la 5% ✗

### Grafice
![Randamente și VaR](grafice/37_var_randamente_si_var.png)
![Depășiri VaR 95%](grafice/38_var95_depasiri.png)
![Depășiri VaR 99%](grafice/39_var99_depasiri.png)

---

## 8. Cointegrare Johansen

### Teste formale
22. Johansen trace r=0 → 18.18 vs val. critică 5%: 19.96 — **nu se respinge H₀**
23. Johansen trace r≤1 → 2.02 vs val. critică 5%: 9.24 — **nu se respinge H₀**

**Concluzie: nu există cointegrare la 5% → VAR pe diferențe.**

### Grafice
![Serii bivariante](grafice/40_serii_bivariat.png)
![Petrol tsdisplay](grafice/41_petrol_tsdisplay.png)
![Curs tsdisplay](grafice/42_curs_tsdisplay.png)
![CCF petrol–curs](grafice/43_ccf.png)

---

## 9. VAR(2) — diagnostice

### Teste formale
24. Portmanteau serial test → Chi² = 55.37, df = 44, **p = 0.119** — fără autocorelare ✓
25. ARCH multivariat → Chi² = 247.43, df = 90, **p = 3.4e-16** — heterocedasticitate prezentă

### Grafice diagnostice
![Stabilitate VAR (SC)](grafice/44_stability_var_sc.png)
![Stabilitate VAR (AIC)](grafice/45_stability_var_aic.png)
![Reziduuri VAR — petrol](grafice/46_reziduuri_petrol.png)
![Reziduuri VAR — curs](grafice/47_reziduuri_curs.png)
![ACF reziduuri — petrol](grafice/48_acf_rez_petrol.png)
![ACF reziduuri — curs](grafice/49_acf_rez_curs.png)

---

## 10. Cauzalitate Granger

### Teste formale
26. Granger petrol → curs → F = 10.193, df = (2, 650), **p = 4.4e-05** — cauzalitate puternică
27. Granger curs → petrol → F = 3.197, df = (2, 650), **p = 0.042** — cauzalitate semnificativă

**Concluzie: cauzalitate Granger bidirecțională.**

### Grafice IRF
![IRF petrol → curs](grafice/50_irf_petrol_to_curs.png)
![IRF curs → petrol](grafice/51_irf_curs_to_petrol.png)
![IRF toate combinațiile](grafice/52_irf_all.png)
![IRF ggplot petrol → curs](grafice/53_irf_gg_petrol_curs.png)
![IRF ggplot curs → petrol](grafice/54_irf_gg_curs_petrol.png)

---

## 11. FEVD și prognoze VAR

### Grafice FEVD
![FEVD base R](grafice/55_fevd_base.png)
![FEVD stacked bar](grafice/56_fevd_col.png)
![FEVD area chart](grafice/57_fevd_area.png)
![FEVD line chart](grafice/58_fevd_line.png)

### Grafice prognoze VAR
![Prognoza VAR diferențe](grafice/59_var_prognoza_diferente.png)
![Prognoza VAR petrol nivel](grafice/60_var_prognoza_petrol_nivel.png)
![Prognoza VAR curs nivel](grafice/61_var_prognoza_curs_nivel.png)

---

## Sumar

| # | Test | Statistică | p-value | Concluzie |
|---|------|-----------|---------|-----------|
| 1–3 | ADF nivel (3 spec.) | -0.52 / -2.93 / -3.15 | >0.05 | Nestaționar |
| 4 | KPSS nivel | 1.4869 | <0.01 | Nestaționar |
| 5 | Phillips-Perron nivel | DF=-7.58 | 0.629 | Nestaționar |
| 6–8 | ADF d1 (3 spec.) | -11.32 | <0.01 | Staționar ✓ |
| 9 | Ljung-Box HW | Q*=18.77 | 0.016 | Autocorelare |
| 10 | ARCH-LM lag 2 HW | Chi²=23.06 | <0.001 | ARCH prezent |
| 11 | ARCH-LM lag 12 HW | Chi²=45.83 | <0.001 | ARCH prezent |
| 12 | z-test ma1 SARIMA | z=3.593 | 0.0003 | Semnificativ ✓ |
| 13 | z-test sma1 SARIMA | z=-1.483 | 0.138 | Nesemnificativ |
| 14 | Ljung-Box SARIMA | Q*=17.51 | 0.776 | Fără autocorelare ✓ |
| 15 | ARCH-LM SARIMA | Chi²=24.01 | 0.020 | ARCH prezent |
| 16 | Ljung-Box ETS | Q*=28.46 | 0.074 | Marginal |
| 17 | Diebold-Mariano | DM=8.498 | <0.001 | ETS superior |
| 18 | ARCH-LM lag 5 randamente | Chi²=31.85 | <0.001 | ARCH prezent |
| 19 | ARCH-LM lag 12 randamente | Chi²=46.92 | <0.001 | ARCH prezent |
| 20 | Backtest VaR 95% | 4.88% exceedances | 1.000 | Valid ✓ |
| 21 | Backtest VaR 99% | 2.13% exceedances | 0.049 | Respins ✗ |
| 22 | Johansen trace r=0 | 18.18 | >0.05 | Fără cointegrare |
| 23 | Johansen trace r≤1 | 2.02 | >0.05 | Fără cointegrare |
| 24 | Portmanteau VAR | Chi²=55.37 | 0.119 | Fără autocorelare ✓ |
| 25 | ARCH multivariat VAR | Chi²=247.43 | <0.001 | Heterocedasticitate |
| 26 | Granger petrol→curs | F=10.193 | <0.001 | Cauzalitate ✓ |
| 27 | Granger curs→petrol | F=3.197 | 0.042 | Cauzalitate ✓ |

**Total: 27 teste + 61 grafice diagnostice**
