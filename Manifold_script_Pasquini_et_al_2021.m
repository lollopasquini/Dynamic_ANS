%% Dynamic autonomic nervous system patterns differentiate human emotions and manifest in resting physiology - Manifold
% May 13 2021
% Lorenzo Pasquini, PhD - contact: lorenzo.pasquini@ucsf.com
% This script performs the primary analyses from the paper Pasquini et al.
% 2021 Dynamic autonomic nervous system patterns differentiate human emotions and manifest in resting physiology.
% Besides Matlab and the excel sheet with the data, there are no
% dependencies. 
% The script generates the low dimensional manifold.
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

% Explained variance
figure; 
plot(explained_task);
set(gcf,'color','w');
ylabel('Explained variance');
xlabel('PCs');

%% Group-averaged tPCs
% Calculate the group-mean tpcs
pcn = 5; % pcs that exlpain ~75% of variance

for nc=1:pcn % first five components
    mean_tpcs_task(:,nc) = mean(reshape(score_task(:,nc),[],nsub),2);
end

group_task_labels = table_task.Trial_coded(1:ntask); % emotional reactivity task structure
group_task_tc(:,1) = 1:ntask; % emotional reactivity task seconds

figure;
scatter(group_task_tc(group_task_labels==1,1), mean_tpcs_task(group_task_labels==1,1),'o','blue');
hold on;
scatter(group_task_tc(group_task_labels~=1,1), mean_tpcs_task(group_task_labels~=1,1),'o','red');
set(gcf,'color','w');
xlabel('time in sec');
ylabel('tPC1 amplitude z-score');
grid;
legend('task','baseline');

%% Baseline data
% Each cell is a distinct baseline block
pc1_baseline{1} = mean_tpcs_task(1:61,1:5);
pc1_baseline{2} = mean_tpcs_task(150:241,1:5);
pc1_baseline{3} = mean_tpcs_task(337:428,1:5);
pc1_baseline{4} = mean_tpcs_task(533:624,1:5);
pc1_baseline{5} = mean_tpcs_task(718:809,1:5);
pc1_baseline{6} = mean_tpcs_task(898:928,1:5);

% Only in between-task baselines are selected
% Reshape to calculate average time series across baseline time series
reshape_pc1_baseline(:,:,1) = pc1_baseline{2};
reshape_pc1_baseline(:,:,2) = pc1_baseline{3};
reshape_pc1_baseline(:,:,3) = pc1_baseline{4};
reshape_pc1_baseline(:,:,4) = pc1_baseline{5};
mean_reshape_pc1_baseline = mean(reshape_pc1_baseline,3);

%% Task data
% Each cell is a distinct emotional trial
pc1_task{1} = mean_tpcs_task(62:149,1:5);
pc1_task{1}(89:104,:) = NaN(104-88,5); % length made equal across cells and filled with NaNs
pc1_task{1} = fillmissing(pc1_task{1},'linear'); % NaNs filled with linear interpolation
pc1_task{2} = mean_tpcs_task(242:336,1:5);
pc1_task{2}(96:104,:) = NaN(104-95,5);
pc1_task{2} = fillmissing(pc1_task{2},'linear');
pc1_task{3} = mean_tpcs_task(429:532,1:5);
pc1_task{4} = mean_tpcs_task(625:717,1:5);
pc1_task{4}(94:104,:) = NaN(104-93,5);
pc1_task{4} = fillmissing(pc1_task{4},'linear');
pc1_task{5} = mean_tpcs_task(808:897,1:5);
pc1_task{5}(91:104,:) = NaN(104-90,5);
pc1_task{5} = fillmissing(pc1_task{5},'linear');

% Reshape to calculate average time series across interpolated task time
% series
reshape_pc1_task(:,:,1) = pc1_task{1};
reshape_pc1_task(:,:,2) = pc1_task{2};
reshape_pc1_task(:,:,3) = pc1_task{3};
reshape_pc1_task(:,:,4) = pc1_task{4};
reshape_pc1_task(:,:,5) = pc1_task{5};

mean_reshape_pc1_task = mean(reshape_pc1_task,3);

%% Plot data
% Concat task and baseline
lowdim_man = vertcat(mean_reshape_pc1_task,mean_reshape_pc1_baseline);

figure;
scatter3(lowdim_man(1:104,1), ...
         lowdim_man(1:104,2), ...
         lowdim_man(1:104,3), ...
         100,'MarkerEdgeColor','k','MarkerFaceColor','blue');
hold on;
scatter3(lowdim_man(105:end,1), ...
         lowdim_man(105:end,2), ...
         lowdim_man(105:end,3), ...
         100,'MarkerEdgeColor','k','MarkerFaceColor','red');
for i =1:(size(lowdim_man(:,1),1)-1)
    line(lowdim_man(i:(i+1),1),lowdim_man(i:(i+1),2),lowdim_man(i:(i+1),3),'Color','black');
end
set(gcf,'color','w');
xlabel('tPC1');
ylabel('tPC2');
zlabel('tPC3');
