# SCRATCH-CellCommunication

## Introduction
SCRATCH-CellCommunication performs ligand–receptor based cell–cell communication analysis from an annotated, non-malignant, batch corrected single-cell Seurat object.
It integrates **LIANA**, **CellChat**, and **NicheNet** in a unified, containerized pipeline to provide complementary views of intercellular signaling:

- **LIANA**: broad ligand–receptor inference (ranked interaction candidates)
- **CellChat**: network-level communication modeling and pathway summaries
- **NicheNet**: sender → receiver → target-gene prioritization linking ligands to downstream programs

This module is a key component of the SCRATCH single-cell analysis ecosystem and is fully orchestrated through **Nextflow DSL2 + Quarto (QMD)** with support for **Docker** and **Singularity/Apptainer** execution.

---

## Prerequisites  
- Nextflow ≥ 21.04.0  
- Java ≥ 8  
- Docker or Singularity/Apptainer  
- Git  

### R packages (via container)
Seurat, liana, CellChat, nichenetr, dplyr, tidyr, ggplot2, Matrix, readr, purrr, ComplexHeatmap, circlize

---

## Key files
**main.nf** — primary entrypoint  
**modules/local/Cell_Communication/main.nf** — processes that render QMD notebooks (LIANA / CellChat / NicheNet / final report)  
**subworkflow/local/SCRATCH_CellComm.nf** — orchestrates tool execution and data handoff between tools  
**nextflow.config** — default parameters, containers, and resource settings  
**assets/** — QMD notebooks and any supporting templates/resources

---

## Quick Start

### Minimal example (Docker) 
```
nextflow run main.nf -profile docker \
  --input_seurat_object non-malignant_batchCorrected-SeuratObject.RDS \
  --celltype_col azimuth_labels \
  --min_cells_per_group 10 \
  --project_name CellCommDemo \
  --outdir CellComm_OUT
```
### Minimal example (Singularity)  
```
nextflow run main.nf -profile singularity \
  --input_seurat_object non-malignant_batchCorrected-SeuratObject.RDS \
  --celltype_col azimuth_labels \
  --min_cells_per_group 10 \
  --project_name CellCommDemo \
  --outdir CellComm_OUT
```

---

## Typical Workflow Execution

1. **LIANA:** runs first and exports:
   - all generated results under `data/` and `figures/`
   - the key interaction table: `data/liana_results.csv`

2. **CellChat:** CellChat runs in parallel with LIANA and exports:
   - all generated results under `data/` and `figures/`
   - the core CellChat object: `data/cellchat_object.rds`

3. **NicheNet:** NicheNet runs after both are complete and explicitly consumes:
   - `liana_results.csv` from LIANA
   - `cellchat_object.rds` from CellChat   
  
It then infers ligand activities and links signaling to receiver DE targets, producing per-receiver and global summaries.

---

## Key Parameters
| Parameter | Description |
|---|---|
| `--input_seurat_object` | non-malignant batchCorrected SeuratObject `.RDS` file |
| `--project_name` | Project label used in output paths |
| `--outdir` | Output directory |
| `--celltype_col` | Metadata column for cell type labels |
| `--min_cells_per_group` | Minimum cells per cell type to keep for analysis |
| `--condition_col` | Metadata column defining condition/grouping (used by NicheNet DE) |
| `--condition_ref` | Reference condition label (e.g., Control) |
| `--condition_test` | Test condition label (e.g., Case) |
| `--receiver_mode` | Receiver selection: `auto` or `manual` |
| `--sender_mode` | Sender selection: `auto_top_outgoing`, `all_other`, or `manual` |

**Note:** additional tool-specific parameters are available in nextflow.config and passed into QMD notebooks via quarto render -P ....

---

## Outputs  
The module publishes per-tool outputs plus an integrated report directory. 

**Example layout:**
```
<outdir>/<project_name>/cellcommunication/
├── liana/
│   ├── report/
│   ├── figures/
│   └── data/
│       └── liana_results.csv
├── cellchat/
│   ├── report/
│   ├── figures/
│   └── data/
│       └── cellchat_object.rds
├── nichenet/
│   ├── report/
│   ├── figures/
│   └── data/
│       └── nichenet_summary.csv

```

---

## Deliverables
  - LIANA ligand–receptor interaction rankings (liana_results.csv) + plots  
  - CellChat communication networks + pathway summaries + serialized object (cellchat_object.rds)  
  - NicheNet ligand activity + sender/receiver/target prioritization + per-receiver outputs  

---

## Example Full Run
bash 
```
nextflow run main.nf -profile docker \
  --input_seurat_object non-malignant_batchCorrected-SeuratObject.RDS \
  --celltype_col azimuth_labels \
  --condition_col timepoint \
  --min_cells_per_group 10 \
  --project_name Ovarian_CellComm \
  --outdir TESTOUT \
  -resume
```
---

## Documentation

All analyses are implemented in Quarto `.qmd` notebooks with annotated code, figures, and parameter injection via Nextflow.  
You can review/modify notebooks in `modules/local` (or the configured QMD paths in `nextflow.config`) to customize plots, thresholds, sender/receiver selection logic, and reporting.

---

## License  
Licensed under the GNU General Public License v3.0 (GPLv3).

---

## Developers
lwang22@mdanderson.org  
sazaidi@mdanderson.org

---
