# Skill Formation

Lecture materials on child skill formation, measurement, and the estimation
of cognitive and noncognitive skill technologies.

## Contents

- `Lecture slides/`: compiled lecture slides.
- `estimation_demo/`: executable demonstrations for the skill-formation
  estimation workflow.
- `lecture_r/`: self-contained RStudio/Quarto lecture project.

## Replication materials

The current local project does not contain replication code, and no direct
public GitHub mirror was found in the initial search. The official author
website provides a download link for the code and data associated with:

- Cunha, Heckman, and Schennach (2010), “Estimating the Technology of
  Cognitive and Noncognitive Skill Formation,” *Econometrica*.

The replication package and NLSY data should be obtained from the authors and
the NLSY data provider. They are not redistributed in this repository.

- Official code and data page: <https://www.flaviocunha.com/codes-and-data>
- NLSY79 Child and Young Adult documentation: <https://www.nlsinfo.org/content/cohorts/nlsy79-children/other-documentation/codebook-supplement>

### Local CNLSY/79 teaching extract

The script [`make_chs_white_children.R`](make_chs_white_children.R) reads the
local public-use `nlscya_all_1979-2020.csv` file and creates a teaching extract
of firstborn children in the CHS white-sample definition (`CRACE == 3`). It
also reads the local NLSY79 respondent file to attach the maternal measures
listed in Web Appendix Table 9-3.

The raw NLSY files are intentionally ignored by Git. The derived files are
written to `data/derived/`. In addition to the broad child-by-wave extract,
the script creates:

- `chs_white_firstborn_appendix_a9_period.*`: one row per child and CHS age
  period, using the representative measures in Web Appendix Table 10-4;
- `chs_white_firstborn_appendix_a9_variable_dictionary.csv`: the A9 measure
  map by period;
- `chs_white_firstborn_appendix_a9_sample_counts.csv`: transparent counts
  after each observable-data restriction.

The public-use files reproduce the CHS sample definition and A9 measurement
construction, but the final published count is reported separately as the
CHS reference (`N = 2,207`). The exact published estimation sample may still
depend on additional sample flags or the authors' data vintage; it should not
be silently imposed by trimming observations until the count matches.

### Executable working-sample demonstration

[`estimation_demo/chs_working_sample_demo.qmd`](estimation_demo/chs_working_sample_demo.qmd)
is a QuantEcon-style, executable Python/Quarto page. It reads the A9 period
file, defines the transparent `N = 2,219` working sample, audits the selected
measures and their missingness, and estimates a simple proxy skill-formation
regression with an optional skill--investment interaction.

The R/Quarto version is
[`estimation_demo/chs_working_sample_demo_r.qmd`](estimation_demo/chs_working_sample_demo_r.qmd).
It uses the `knitr` engine and only base R plus `knitr::kable()`, so it is the
recommended version for the lecture demonstration.

The same source is available as a Jupyter notebook:
[`estimation_demo/chs_working_sample_demo.ipynb`](estimation_demo/chs_working_sample_demo.ipynb).
It can be opened locally in Jupyter or uploaded to Google Colab. The notebook
needs the two derived CSV files in `data/derived/` (or an equivalent uploaded
folder); the raw NLSY files are not needed for this demonstration.

From the repository root, render the HTML page with:

```bash
quarto render estimation_demo/chs_working_sample_demo_r.qmd
```

The R version can also be opened directly in RStudio or VSCode. In RStudio,
use the **Render** button; in VSCode, use the Quarto preview command. The
current Windows installation uses R 4.6.1; if Quarto does not find R
automatically, set `QUARTO_R` to the R `bin` directory.

For an RStudio-first workflow, open
[`lecture_r/lecture_r.Rproj`](lecture_r/lecture_r.Rproj). The project contains
the current likelihood lecture and the small public-use teaching extracts it
loads. The lecture decomposes a CHS-style latent-state likelihood, demonstrates
Monte Carlo integration for one observed child, and contrasts it with a simple
Agostinelli--Wiswall sequential IV calculation. The raw NLSY files are not
copied into this project.
