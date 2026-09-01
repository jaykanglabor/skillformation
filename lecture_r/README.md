# RStudio lecture project

This folder is a self-contained teaching project for the child skill-formation
demonstration.

## Main file

Open `chs_working_sample_demo_r.qmd` in RStudio and click **Render**. The
document uses Quarto with the `knitr` engine and defines the transparent
`N = 2,219` working sample from the local A9 teaching extract.

The demonstration includes:

- the actual Appendix A9 working-sample definition;
- child-skill, investment, maternal-skill, and adult-outcome measures;
- the complete CHS-style measurement and transition system;
- a numerical decomposition of every likelihood block for one observed child;
- Monte Carlo integration over a complete latent history; and
- a contrasting Agostinelli--Wiswall sequential IV calculation.

The Monte Carlo section is a transparent teaching implementation of the
integrated latent-state likelihood, not the original CHS mixture-of-normals
unscented Kalman filter code. The AW section illustrates the estimator's logic
and is not a replication of the published estimates.

## Files

- `chs_working_sample_demo_r.qmd`: recommended lecture source;
- `chs_working_sample_demo_r.html`: rendered self-contained lecture page;
- `prepare_adult_outcomes.py`: extracts the selected adult outcomes from the
  very wide public-use CYA file; and
- `data/`: small teaching extracts loaded by the lecture.

The multi-gigabyte raw NLSY79/CYA files are not included. They remain in the
parent project's ignored `data/raw/` directory. The child-measure extraction
script is available one level up as `../make_chs_white_children.R`.

## Render from the project directory

```r
quarto::quarto_render("chs_working_sample_demo_r.qmd")
```

Or use the **Render** button in RStudio. If Quarto does not find R on Windows,
set the `QUARTO_R` environment variable to the R `bin` directory, for example:

```powershell
$env:QUARTO_R = "C:\Program Files\R\R-4.6.1\bin"
```
