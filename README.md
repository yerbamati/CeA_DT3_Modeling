# CeA DT3 Modeling

Code accompanying:

Castro et al., 2026 (under review)

Preprint:
https://www.biorxiv.org/content/10.64898/2026.05.11.724330v1

This repository contains analysis code for CeA single-unit recordings collected during ethanol self-administration in a discretized task. Analyses include single-unit GLMs, population decoding, behavioral analyses, and figure generation.

Tested in MATLAB R2024b.

Required toolboxes:
- Statistics and Machine Learning Toolbox
- Signal Processing Toolbox
- Parallel Computing Toolbox (for parfor loops)

External packages:
- glmnet (Friedman et al. 2010)
- ffmpeg
- DeepLabCut (Mathis et al. 2018)

# Structure
<pre>
├── analysis/                  # Analysis codes 
│   ├── a_preprocessing.m          # Preprocessing of .NEX files
│   ├── a_coordinateextraction.m   # Feature-extraction of DLC coordinate data, also movement comparisons
│   ├── b_PSTHs.m                  # Make raw and z-scored PSTH traces, raw PSTHs to be used for example neuron raster diagrams
│   ├── c_GroupLevelAnalysis.m     # Comparisons of behavioral data, within and across groups
│   ├── d_encodingdecoding.m       # single-unit GLM, population-level SVM
│   ├── CeA_DT3_figures.m          # Recreates manuscript figures
│   ├── multiseed_decoding.m       # To address the first round of reviewer comments, we implemented changes to the code that made it clear
                                   that the interaction between Group x Time for the comparisons between SVM accuracy in the model with and
                                   without movement-modulated neurons was unstable. As such, we implemented 2 additional controls, namely
                                   an SVM where movement-modulated and not-movement-modulated were selectively depleted to size-matched groups,
                                   and an SVM where, across groups, the population of not-movement-modulated neurons were size matched across
                                   groups (see <i>Classifier Analysis</i> in the <b>Methods</b> section). We also implemented a reproducible, multi-seed
                                   approach, such that we created a population of statistical results for the ANOVA comparisons, to determine
                                   the stability of the comparison between the groups at the different time points. Code for creation of
                                   Figures 5D-G and Figure 6E is in this script.
│
├── supporting programs/         # Support codes 
└── README.md
</pre>
Some quick notes on the main scripts:

- `a_preprocessing.m`
    preprocesses NeuroExplorer `.NEX` files and aligns behavioral variables

- `a_coordinateextraction.m`
    extracts DLC movement features and compares movement variables across trial types

- `b_PSTHs.m`
    generates raw and z-scored PSTHs, for later example rasters

- `c_GroupLevelAnalysis.m`
    group-level behavioral/statistical analyses

- `d_encodingdecoding.m`
    single-unit Poisson GLMs + population SVM decoding

- `CeA_DT3_figures.m`
    recreates manuscript figures

## Data

Processed datasets used for the paper can be found here:
https://gin.g-node.org/yerba.mati/CeA_DT3_Modeling/src/master/data

Raw electrophysiology recordings are available upon request.

## Running analyses

Typical order was roughly:

### 1. Preprocessing

```matlab
run('analysis/a_preprocessing.m')
```

creates:
```text
RAW*GroupName*.mat
```

### 2. Add movement/video variables

```matlab
run('analysis/a_coordinateextraction.m')
```

adds DLC-derived variables into 
```text
RAW*GroupName*.mat
```

### 3. Generate PSTHs

```matlab
run('analysis/b_PSTHs.m')
```

creates:
```text
R*GroupName*.mat
```

### 4. GLM inputs

```matlab
run('analysis/d_encodingdecoding.m % Prediction Matrix Construction')
```

creates:
```text
*GroupName*GLMinputs25ms.mat
```

Spike trains were binned at 25 ms resolution.

### 5. Fit GLMs

```matlab
run('analysis/d_encodingdecoding.m % perform GLM with all predictors')
```

creates files of the form:
```text
*GroupName*25msinteraction[...].mat
```

GLMs were fit neuron-by-neuron using Poisson regression with ridge regularization.

### 6. Population decoding

```matlab
run('analysis/d_encodingdecoding.m % Pointwise GIANT RAT SVM (DECODER)')
```

creates:
```text
*GroupName*_SVM.mat
```

Decoder analyses can also be rerun after excluding specific neuron populations.

### 7. Figures

```matlab
run('analysis/CeA_DT3_Figures.m')
```

Figures were finalized in Inkscape.

## Contact

Matilde Castro | mati.castro.06@gmail.com

Work completed at Johns Hopkins University.
