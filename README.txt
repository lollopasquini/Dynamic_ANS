May 14th 2021
Lorenzo Pasquini
lorenzo.pasquini@ucsf.edu

Code used to generate some of the findings in: 
Pasquini et al. 2021 Dynamic autonomic nervous system patterns differentiate human emotions and manifest in resting physiology

The three MATLAB scripts are used to analyze phsyiological time series data of autonomic nervous system (ANS) activity acquired during an emotional reactivity task.
Besides MATLAB and the excel sheet, no other dependencies are needed.

Input: Pasquini_et_al_2021_data.xlsx
This excel sheet contains the prerocessed ANS time series data of eight phsyiological channels acquired in 45 healthy participants.
The first sheet contains data assessed during an emotional reactivity task were participants transitioned between baselines and viewing emotiona videos.
The videos were selected to induce awe, sadness, amusement, disgust, and nurturant love and presented in this order.
The second sheet contains ~2min of resting physiology assessed for the same ANS channels in the same participants prior to the emotional reactivity task.

All three scripts perfrom a principal component analyzis to decompose the ANS data.
Each script then runs specific code to derive:
1. The low dimensional manifold as in Figure 2B of the paper.
2. The cluster states as in Figure 2D.
3. The occupancy of ANS states under resting conditions as in Figure 3F-G.

IMPORTANT: 
For the findings shown in the paper, I performed the principal component analyses decomposition on R (version 4.0.2 [2020-06-22]; RStudioVersion 1.3.1073).
Here, all analyzes are run in MATLAB (R2020a).
There are inconsistencies across both softwares on the sign assigned to each component. 
This sign indeterminancy problem is intrinsic to decomposition methods such as principal component analysis.
MATLAB (pca.m) enforces a convention such that the largest component (by absolute magnitude) will be positive, while R does not.
Therefore I had to inverse the sign of some components on a couple of occasions to make sure that the plots look identical to the ones in the paper.
However, this mathematical operation does not substantally affect the findings, which are identical across both softwares.