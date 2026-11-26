# Social Priors in Observational Learning

Data, analysis code, figures, and HTML reports for two studies examining group membership and competence cues in observational learning:

- **`action/`**: action-only study; participants observe demonstrator choices without outcomes.
- **`action_outcome/`**: action–outcome study; participants observe demonstrator choices and outcomes.

## Folder structure

Each study contains `code/` (R scripts and R Markdown analyses), `figures/` (exported plots), and `main_data/` (raw data, demographics, and preprocessed data). HTML reports contain the analysis code, figures, and model output.

## Data used

| Study | Raw-data folders | Input to the main analysis |
|---|---|---|
| Action-only | `female_session1`, `male_session1` | `all_action_only_approved_awaiting_with_demo.csv` |
| Action–outcome | `female_session1`, `female_session2`, `male_session1`, `male_session2` | `all_sessions_approved_combined_with_demo.csv` |

`data_filtering.R` matches Pavlovia exports to participant IDs in the demographics files and merges the selected data. Both studies include **APPROVED** submissions but action-outcome includes one more manually included direct-link completion specified in the script. The merged files retain `source_file` and `source_session` to identify their raw-data sources.

These merged datasets are **before analysis exclusions**. The main Rmd files apply the participant-quality criteria.

## How to use

1. Open the HTML reports in a browser to view the existing results (that has already been run).
2. To rerun an analysis, open `code/action_analysis_main.Rmd` or `code/outcome_analysis_main.Rmd` in RStudio, install the packages listed in its package chunk, and click **Knit**. Keep the folder structure intact; input paths are relative to the Rmd file. Figures are saved to the output directory configured near its beginning.
3. To rebuild a merged input dataset, first run that study's `data_filtering.R` with the working directory set to its `code/` folder, then knit the main analysis.
