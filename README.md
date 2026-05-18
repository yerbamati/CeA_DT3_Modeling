# CeA DT3 Modeling

Code accompanying:

> [Castro et al., 2026, under review]
> DOI: [https://doi.org/10.64898/2026.05.11.724330 (preprint)]
> Preprint: [https://www.biorxiv.org/content/10.64898/2026.05.11.724330v1]

This repository contains code used to analyze neural spike data collected from neurons in the central nucelus of the amygala (CeA) during ethanol self-administration in a discretized task.
We performed both modeling of single-unit activity in addition to decoding from population data.

---
# Overview

Analyses included in this repository:
- Behavioral analysis
- Video-data feature extraction
- Data preprocessing
- Poisson GLM fitting of single-unit actiivty
- Population decoding using SVMs
- Statistical analyses
- Figure generation

---
# Structure
```text
├── data/                      # Processed datasets used for analyses
│
├── analysis/                  # Analysis codes 
│   ├── a_preprocessing.m          # Preprocessing of .NEX files
│   ├── a_coordinateextraction.m   # Feature-extraction of DLC coordinate data, also compares movement variables on different trials, both point-wise and in discrete windows
│   ├── b_PSTHs.m                  # Make raw and z-scored PSTH traces, raw PSTHs to be used for example neuron raster diagrams
│   ├── c_GroupLevelAnalysis.m     # Comparisons of behavioral data, within and across groups
│   ├── d_encodingdecoding.m       # single-unit GLM, population-level SVM
│   ├── CeA_DT3_figures.m          # Recreates manuscript figures
│
├── supporting programs/         # Support codes 
└── README.md
```

---
Tested in:
- MATLAB R2024b

Required toolboxes:
- Statistics and Machine Learning Toolbox
- Signal Processing Toolbox
- Parallel Computing Toolbox (to run parfor loops)

External packages:
- glmnet (Freidman et al. 2010)
- ffmpeg (https://ffmpeg.org/about.html)
- DeepLabCut (Mathis et al. 2018)
---

# Data availability

Processed datasets necessary to reproduce the main figures are included in:
```/data```

Raw electrophysiology recordings are available on DANDI: [LINK]

---

# Reproducing analyses

## Recommended execution order

### 1a. Preprocess neural data

```matlab
run('analysis/a_preprocessing.m')
```

Outputs:
- `RAW*GroupName*.mat`

### 1c. Add video features
```matlab
run('analysis/a_coordinateextraction.m')
```

Outputs:
- `RAW*GroupName*.mat` (now has added variables, but same name as before)

 ### 1c. Calculate raw PSTH
```matlab
run('analysis/b_PSTHs.m')
```

Outputs:
- `R*GroupName*.mat`
---

### 2. Build design matrices

```matlab
run('analysis/d_endcodingdecoding.m%Prediction Matrix Construction')
```

Outputs:
- `*GroupName*GLMinputs25ms.mat`

---

### 3. Fit GLMs

```matlab
run('analysis/d_endcodingdecoding.m%perform GLM with all predictors')
```

Outputs:
- `*GroupName*25msinteraction??video??XXtrialGLMridgepoissonFull.mat`
  
Notes:
- Poisson GLMs were fit neuron-by-neuron using ridge regularization.
- Spike trains were binned at 25 ms resolution.

---

### 4. Run decoding analyses

```matlab
run('analysis/d_endcodingdecoding.m%Pointwise GIANT RAT SVM (DECODER)')
```

Outputs:
- `*GroupName*_SVM.mat`

Note: Can be done flexibly, such that certain neurons are removed prior to SVM.

---
### 5. Figure creation

```matlab
run('analysis/CeA_DT3_Figures.m')
```
Figures were later adjusted in Inkscape.

---

# Contact

For questions regarding the code or analyses, please contact:

Matilde Castro | mati.castro.06@gmail.com | Work completed at Johns Hopkins University
