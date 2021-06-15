%% Dynamic autonomic nervous system patterns differentiate human emotions and manifest in resting physiology - Autonomic states at task
% May 13 2021
% Lorenzo Pasquini, PhD - contact: lorenzo.pasquini@ucsf.com
% This script performs the primary analyses from the paper Pasquini et al.
% 2021 Dynamic autonomic nervous system patterns differentiate human emotions and manifest in resting physiology.
% Besides Matlab and the excel sheet with the data, there are no
% dependencies. 
% The script extracts the autonomic nervous system states found during the emotion reactivity task.
% Check out the README.txt file for more information.

clear all;
close all; 
clc;

%% Load the preprocessed physiological time series from the emotional reactivity task
table_task = readtable('../Pasquini_et_al_2021_data.xlsx','Sheet','emot_react_concat');

% Select the physiological channels
task_tcs(:,1) = table_task.FPA;
task_tcs(:,2) = table_task.FPT;
task_tcs(:,3) = table_task.IBI;
task_tcs(:,4) = table_task.ICI;
task_tcs(:,5) = table_task.RSA;
task_tcs(:,6) = table_task.RSD;
task_tcs(:,7) = table_task.SCL;
task_tcs(:,8) = table_task.ST;

nsub = length(unique(table_task.Subject_ID)); % number of subjects
ntask = length(unique(table_task.Participant_seconds)); % length of emotional reactivity task

%% Perform PCA
[coeff_task, score_task, latent_task, tsquared_task, explained_task, mu_task] = pca(task_tcs);

% The sign of these components needs to be inversed to attain identical
% correpondence between the tpcs derived in R in the original paper and
% Matlab here, but the findings are substantially the same
score_task(:,1) = -1*score_task(:,1);
score_task(:,5) = -1*score_task(:,5);

%% Group-averaged tPCs
% Calculate the group-mean tpcs
pcn = 5; % pcs that exlpain ~75% of variance

for nc=1:pcn % first five components
    mean_tpcs_task(:,nc) = mean(reshape(score_task(:,nc),[],nsub),2);
end

group_task_labels = table_task.Trial_coded(1:ntask); % emotional reactivity task structure
group_task_tc(:,1) = 1:ntask; % emotional reactivity task seconds

%% Generate autonomic nervous system activity states
% Select only emotional trial periods
trial_tpcs_task = mean_tpcs_task(group_task_labels~=1,:);

% K-means
rng(1);
nclusters = 5;

[clust,C,sumd,D] = kmeans(trial_tpcs_task, nclusters, ...
    'MaxIter', 10000, 'Replicates',10); 

% Silhouette
figure;
silhouette(trial_tpcs_task,clust);
set(gcf,'color','w');

figure;
% plot centroids
scatter3(C(1,1),C(1,4),C(1,5),200,'x','black','LineWidth',5);
hold on;
scatter3(C(2,1),C(2,4),C(2,5),200,'x','black','LineWidth',5);
scatter3(C(3,1),C(3,4),C(3,5),200,'x','black','LineWidth',5);
scatter3(C(4,1),C(4,4),C(4,5),200,'x','black','LineWidth',5);
scatter3(C(5,1),C(5,4),C(5,5),200,'x','black','LineWidth',5);
% plot time points
scatter3(trial_tpcs_task(clust==1,1), trial_tpcs_task(clust==1,4), trial_tpcs_task(clust==1,5),'MarkerEdgeColor','k','MarkerFaceColor','blue');
scatter3(trial_tpcs_task(clust==2,1), trial_tpcs_task(clust==2,4), trial_tpcs_task(clust==2,5),'MarkerEdgeColor','k','MarkerFaceColor','cyan');
scatter3(trial_tpcs_task(clust==3,1), trial_tpcs_task(clust==3,4), trial_tpcs_task(clust==3,5),'MarkerEdgeColor','k','MarkerFaceColor','yellow');
scatter3(trial_tpcs_task(clust==4,1), trial_tpcs_task(clust==4,4), trial_tpcs_task(clust==4,5),'MarkerEdgeColor','k','MarkerFaceColor','red');
scatter3(trial_tpcs_task(clust==5,1), trial_tpcs_task(clust==5,4), trial_tpcs_task(clust==5,5),'MarkerEdgeColor','k','MarkerFaceColor','green');
% description
xlabel('tPC1');
ylabel('tPC4');
zlabel('tPC5');
set(gcf,'color','w');

%% Individual fractional occupancies
% Calculate cluster apparteneace based on distance to centroid
for nt = 1:size(score_task,1)
    my_dist = pdist2(C, score_task(nt,1:5));
    new_cl_centroid(nt,:) = find(my_dist==min(my_dist));
end

new_cl_centroid = new_cl_centroid(table_task.Trial_coded~=1,:); %removing baseline
resh_new_cl_centroid = reshape(new_cl_centroid, [], nsub);

% Fractional occupancies in states calculated for each trial
for i = 1:nsub
    for nc = 1:5
        frac_oc(i,nc,1) = sum(resh_new_cl_centroid(1:88,i)==nc); % awe task
        frac_oc(i,nc,2) = sum(resh_new_cl_centroid((88+1):(88+95),i)==nc); % sadness task
        frac_oc(i,nc,3) = sum(resh_new_cl_centroid((88+95+1):(88+95+104),i)==nc); % amusement task
        frac_oc(i,nc,4) = sum(resh_new_cl_centroid((88+95+104+1):(88+95+104+93),i)==nc); % disgust task
        frac_oc(i,nc,5) = sum(resh_new_cl_centroid((88+95+104+93+1):(88+95+104+93+88),i)==nc); % nurturant love task
    end
end

% Boxplot, order of states presented differently as in main paper
trialn = ({'Awe', 'Sadness', 'Amusement', 'Disgust', 'Nurt. Love'});
figure('Renderer', 'painters', 'Position', [10 10 1200 600]);
for nc = 1:5
    subplot(2,3,nc);
    boxplot(frac_oc(:,:,nc));
    title(trialn{nc});
    ylabel('fractional occupancy in %');
    xticklabels({'State 3', 'State 5','State 4', 'State 2', 'State 1'});
    set(gcf,'color','w');
end
