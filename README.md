# Academic Projects — Mariam Abdillahi Ahmed

M2 student in **Econometrics & Statistics (Econometrics & Data Science track)** at the Aix-Marseille School of Economics (AMSE).
My interests are **causal inference**, **time-series modelling** and **machine learning applied to economics**.

This repository gathers two of my Master's projects. Both were group projects, so each project README states **exactly which part I did**.

| Project | Question | Methods | Tools |
|---|---|---|---|
| [**Mobile money & economic behaviour**](./mobile-money-staggered-did) | Does reaching high mobile-money adoption change consumption, savings and investment across countries? | Staggered Difference-in-Differences (de Chaisemartin & D'Haultfœuille), TWFE, event studies, robustness and heterogeneity analysis | Stata |
| [**Violent crime prediction with conformal prediction**](./violent-crime-conformal-prediction) | How reliable are machine-learning predictions of violent crime rates across U.S. communities? | Data preprocessing and EDA, Linear Regression / Decision Tree / Random Forest / Neural Network, Split Conformal Prediction and CV+ | Python (pandas, scikit-learn, Keras) |

## My contributions at a glance

- **Mobile money (empirical econometrics):** I **wrote the report** and built the **staggered Difference-in-Differences model**.
- **Violent crime (machine learning):** I did the **data preprocessing** and the **conformal prediction** analysis.

## Repository structure

```
academic-projects/
├── mobile-money-staggered-did/          # Empirical project (Stata)
│   ├── code/        # 01 cleaning & merge → 02 staggered DiD / TWFE / heterogeneity → 03 robustness
│   ├── data/        # Merged and cleaned country-year panel (2020–2023)
│   ├── figures/     # Key event-study figure
│   └── report/      # Full written report (PDF)
└── violent-crime-conformal-prediction/  # Machine learning project (Python)
    ├── notebook/    # Full Jupyter notebook with outputs
    ├── figures/     # Key conformal-prediction figure
    └── report/      # Full written report (PDF)
```
