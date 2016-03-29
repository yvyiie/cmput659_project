load('concat_roi_avg.mat')
holdout_set = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, ...
               93, 94, 95, 96, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, ...
               128, 129, 130, 131, 132, 201, 202, 203, 204, 205, 206, 207, 208, 209, ...
               210, 211, 212, 213, 214, 215, 216, 293, 294, 295, 296, 297, 298, 299, ...
               300, 373, 374, 375, 376, 377, 378, 379, 380]';
holdout_labels = labels(holdout_set);

inds = 1:length(labels);
train_set = setdiff(inds, holdout_set)';
train_labels = labels(train_set);
save(['holdout.mat'], 'holdout_set', 'holdout_labels', 'train_set', 'train_labels')