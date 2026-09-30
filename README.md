# Open PISA

Static version of the Open PISA dashboard (Hebrew and English). Plain HTML, CSS and JavaScript. The data are CSV files.

- `index.html` is the Hebrew page and `en.html` the English page.
- The trend charts cover PISA 2006 to 2025 for math, science and reading, by gender and economic status (ESCS).
- The table shows the link of each index in the student and school questionnaires (PISA 2025) to the scores.
- `data/` holds the CSV files that the pages read.
- `prepare/` holds the R scripts that build the data from the OECD files.

## Run locally

Browsers block reading CSV files from a page opened by double click. Serve the folder instead:

```
python -m http.server 4518
```

Then open http://127.0.0.1:4518/index.html

## Data

The scripts in `prepare/` read the OECD PISA 2022 and 2025 student and school files and write the CSV files in `data/`. The paths in the scripts are local to the author's computer. Run them in this order: `pisaScores2022_2025.R`, `pisaScoresMerge.R`, `analyzeData2025.R`, `israel2025.R`, `exportStatic.R`.

The OECD data are at https://www.oecd.org/pisa/data/

## Cite

Kantor, A., & Rafaeli, S. (2020, August). Open PISA: dashboard for large educational dataset. In *Proceedings of the Seventh ACM Conference on Learning@ Scale* (pp. 253-256). https://dl.acm.org/doi/abs/10.1145/3386527.3406721
