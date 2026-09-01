"""Extract a few actual adult outcomes from the very wide NLSCYA CSV.

The raw file has more than 86,000 columns.  Reading only the five columns
below creates a small file that the Quarto lecture can load quickly.
"""

from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw" / "nlscya_all_1979-2020" / "nlscya_all_1979-2020.csv"
OUT = ROOT / "lecture_r" / "data" / "chs_adult_outcomes_2020.csv"

rename = {
    "C0000100": "child_id",
    "Y4602900": "highest_grade_2020",
    "Y4603000": "highest_degree_2020",
    "Y4561200": "wage_income_2020",
    "Y4597100": "convicted_2020",
}
adult = pd.read_csv(RAW, usecols=list(rename), low_memory=False).rename(columns=rename)

# NLSY/CYA negative values are nonresponse or universe codes, not outcomes.
for name in adult.columns[1:]:
    adult.loc[adult[name] < 0, name] = pd.NA

OUT.parent.mkdir(parents=True, exist_ok=True)
adult.to_csv(OUT, index=False)
print(f"Wrote {len(adult):,} rows to {OUT}")
