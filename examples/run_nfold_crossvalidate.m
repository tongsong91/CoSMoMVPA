%% n-fold cross-validation classification with LDA classifier

%% Define data
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

% Load the dataset with VT mask
ds = cosmo_fmri_dataset([data_path '/glm_T_stats_perrun.nii'], ...
                     'mask', [data_path '/vt_mask.nii']);

% remove constant features
ds=cosmo_remove_useless_data(ds);

%% set sample attributes

ds.sa.targets = repmat((1:6)',10,1);
ds.sa.chunks = floor(((1:60)-1)/6)'+1;

% Add labels as sample attributes
classes = {'monkey','lemur','mallard','warbler','ladybug','lunamoth'};
ds.sa.labels = repmat(classes,1,10)';

%%

nsamples=size(ds.samples,1);

% allocate space for output
all_pred=zeros(nsamples,1);

% get unique chunks, and ensure that fold_ids in the range 1..nfolds
% (in this case they already are, but in other datasets they may not)
[unq_folds,unused,fold_ids]=unique(ds.sa.chunks);
nfolds=numel(unq_folds);

for fold=1:nfolds
    % in each fold:
    % - slice the dataset twice, once to get a test dataset (which has
    %   samples where .sa.chunks match fold_ids) and once to get a
    %   training dataset (which has all other samples)
    % - use cosmo_classify_lda to get predictions
    % - store the results in all_pred at the locations index by test_msk
    test_msk=fold_ids==fold;
    ds_test=cosmo_slice(ds,test_msk);

    % >@@>
    train_msk=~test_msk;
    ds_train=cosmo_slice(ds,train_msk);

    pred=cosmo_classify_lda(ds_train.samples,ds_train.sa.targets,...
                                    ds_test.samples);
    all_pred(test_msk)=pred;
    % <@@<
end

expected_pred=[ 1 1 1 2 1 1 2 1 1 1
                2 1 2 2 2 2 2 2 2 2
                4 3 1 3 3 4 3 3 3 3
                4 4 2 4 4 4 4 4 3 2
                5 5 5 5 5 6 5 5 5 5
                6 6 6 6 6 6 6 6 6 6];


% the following code tests the code above (because it should give
% identical output)

% check that the output is as expected
if ~isequal(expected_pred(:),all_pred)
    error('expected predictions to be row-vector with [%s]''',...
            sprintf('%d ',all_pred_alt));
end

%% Compute accuracy
accuracy=mean(all_pred==ds.sa.targets);
fprintf('\nLDA all categories n-fold: accuracy %.3f\n', accuracy);

%% Show confusion matrix

% hint: use cosmo_confusion_matrix
% >@@>
confusion_matrix=cosmo_confusion_matrix(ds.sa.targets,all_pred);
% <@@<

% make a pretty figure
figure
imagesc(confusion_matrix,[0 10])
title('confusion matrix');
set(gca,'XTickLabel',classes);
set(gca,'YTickLabel',classes);
ylabel('target');
xlabel('predicted');
colorbar

