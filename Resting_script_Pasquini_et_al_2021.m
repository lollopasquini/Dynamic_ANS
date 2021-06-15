%% Dynamic autonomic nervous system patterns differentiate human emotions and manifest in resting physiology - Autonomic states at rest
% Lorenzo Pasquini, PhD - contact: lorenzo.pasquini@ucsf.com
% This script performs primary analyses from the paper Pasquini et al.
% 2021 Dynamic autonomic nervous system patterns differentiate human emotions and manifest in resting physiology.
% Besides Matlab and the excel sheet with the data, there are no
% dependencies. 
% The script extracts the autonomic nervous system states at rest.
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
% correpondence between the tpcs derived in R in the original paper and in
% Matlab, but the findings are substantially the same
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

%% Resting physiology
table_rest = readtable('../Pasquini_et_al_2021_data.xlsx','Sheet','rest_phys_concat');

% Select the physiological channels
rest_tcs(:,1) = table_rest.FPA;
rest_tcs(:,2) = table_rest.FPT;
rest_tcs(:,3) = table_rest.IBI;
rest_tcs(:,4) = table_rest.ICI;
rest_tcs(:,5) = table_rest.RSA;
rest_tcs(:,6) = table_rest.RSD;
rest_tcs(:,7) = table_rest.SCL;
rest_tcs(:,8) = table_rest.ST;

%% Perform PCA on resting data
[coeff_rest, score_rest, latent_rest, tsquared_rest, explained_rest, mu_rest] = pca(rest_tcs);

% Assign corresponding components across decompositions based on cosine
% distance
figure('Renderer', 'painters', 'Position', [10 10 800 1000]);
subplot(2,1,1);
imagesc(pdist2(coeff_rest', coeff_task','cosine'));
colorbar;
ylabel('loadings PCs rest');
xlabel('loadings PCs task');
title('cosine distance');
subplot(2,1,2);
imagesc(pdist2(-1*coeff_rest', coeff_task','cosine'));
colorbar;
ylabel('inverse loadings PCs rest');
xlabel('loadings PCs task');
set(gcf,'color','w');

% The assignment across decompositions is based in the similarity of the
% loading coefficients, which can be assessed in the previously generated
% plot. The similarity is based on cosine distance. Since decompositions
% across distinct datasets can yield similar components but with inversed
% sign, the inverse of the loading coefficient loadings was also analyzed.
pc_rest_ind_reord(:,1) = score_rest(:,2);
pc_rest_ind_reord(:,2) = score_rest(:,3);
pc_rest_ind_reord(:,3) = score_rest(:,6);
pc_rest_ind_reord(:,4) = -1*score_rest(:,1); % Needs to be inversed based on Euclidean distance between task loadings and inversed rest loading 
pc_rest_ind_reord(:,5) = score_rest(:,4); % Needs to be inversed to ensure 

% The sign of these components needs to be inversed to attain identical
% correpondence between the tpcs derived in R in the original paper and in
% Matlab, but the findings are substantially the same
pc_rest_ind_reord(:,1) = -1*pc_rest_ind_reord(:,1);  
pc_rest_ind_reord(:,5) = -1*pc_rest_ind_reord(:,5);  

%% Individual fractional occupancies
% Calculate euclidean distance of individual data points to cluster
% centroids derived from the emotional reactivity task
for i=1:size(pc_rest_ind_reord,1)
    my_dist(i,:) = pdist2(C(1:5,:),pc_rest_ind_reord(i,:));
end

% Sparse similarity based on standard deviation from mean distance to
% centroids. Data points whose distance to a centroid is higher than one
% standard deviation below the mean are considered to far away and coded as
% unknown states (0)
sparse_sim_state = my_dist;
my_std =  std(my_dist);
my_mean = mean(my_dist);

for ns = 1:5
    sparse_sim_state(my_dist(:,ns)>my_mean(:,ns)-my_std(:,ns),ns) = 0; % Unknown states
end

% Generate state occupancy vectors based on closest centroid
tmp = sparse_sim_state;
tmp(tmp==0)=300; % Uknown states are coded as very distant
for i=1:size(pc_rest_ind_reord,1)
    my_ind = find(tmp(i,:)==min(tmp(i,:))); % If a data point is close enough to a set of centroids, it is assigned to the closest cetroid
    coded_state(i,1) = my_ind(1);
end

% Portions where no state is occupied put back to 0
coded_state(sum(sparse_sim_state,2)==0,1)=0; % Data points which are very distant from a centroid are relabeled as 0 for unknown

resh_new_cl_centroid = reshape(coded_state, [], nsub);

% Fractional occupancies in states calculated at rest
for i = 1:nsub
    for nc = 1:5
        frac_oc(i,nc) = size(resh_new_cl_centroid(resh_new_cl_centroid(:,i)==nc),1);
    end
end

% Boxplot, order of states presented differently as in main paper
figure('Renderer', 'painters', 'Position', [10 10 1200 600]);
boxplot(frac_oc/size(resh_new_cl_centroid,1)); % in percentagw
ylabel('fractional occupancy in % at rest');
xticklabels({'State 3', 'State 5','State 4', 'State 2', 'State 1'});
set(gcf,'color','w');

% Plot trajectory Subject 7
figure;
pp = 7; %Subject
ts_to_plot = pc_rest_ind_reord((1+121*(pp-1)):121*pp,:);
coded_to_plot = coded_state((1+121*(pp-1)):121*pp,:);
scatter3(ts_to_plot(:,1),ts_to_plot(:,4),ts_to_plot(:,5),100,'black');
hold on;
scatter3(ts_to_plot(coded_to_plot==1,1),ts_to_plot(coded_to_plot==1,4),ts_to_plot(coded_to_plot==1,5),100,'filled','green');
scatter3(ts_to_plot(coded_to_plot==2,1),ts_to_plot(coded_to_plot==2,4),ts_to_plot(coded_to_plot==2,5),100,'filled','red');
scatter3(ts_to_plot(coded_to_plot==3,1),ts_to_plot(coded_to_plot==3,4),ts_to_plot(coded_to_plot==3,5),100,'filled','blue');
scatter3(ts_to_plot(coded_to_plot==4,1),ts_to_plot(coded_to_plot==4,4),ts_to_plot(coded_to_plot==4,5),100,'filled','yellow');
scatter3(ts_to_plot(coded_to_plot==5,1),ts_to_plot(coded_to_plot==5,4),ts_to_plot(coded_to_plot==5,5),100,'filled','cyan');

scatter3(C(1,1),C(1,4),C(1,5),200,'x','k','LineWidth',4);
scatter3(C(2,1),C(2,4),C(2,5),200,'x','k','LineWidth',4);
scatter3(C(3,1),C(3,4),C(3,5),200,'x','k','LineWidth',4);
scatter3(C(4,1),C(4,4),C(4,5),200,'x','k','LineWidth',4);
scatter3(C(5,1),C(5,4),C(5,5),200,'x','k','LineWidth',4);
for i =1:(size(ts_to_plot(:,1),1)-1)
    line(ts_to_plot(i:(i+1),1),ts_to_plot(i:(i+1),4),ts_to_plot(i:(i+1),5),'Color','black');
end
set(gcf,'color','w');
xlabel('tPC1');
ylabel('tPC4');
zlabel('tPC5');
title(['subject ',num2str(pp)])
    