function [X_Train,Y_Train,X_Test,Y_Test]=generateDataSet(site,k)
% this returns the training set and test from the feature files.
% 1/k th portion of the data is selected for the test and the rest is
% selected for the training set
load('FBIRN/finaldata_AO/features\fBIRN_AudOdd_allsites_0003_log_degrees_Tlms_MFG_SFG_.mat');

if site==6 
    %Select from all the data (We dont worry about balancing the training
    %and the testing sets with equal number of patients and controls)
    Indices = crossvalind('Kfold', 95, k);
    % all the indices with number 5 is taken away as the testing set
    % Extend this indices to the 380 numbers
    Indices=kron(Indices,[1 1 1 1]');
    Train=data(find(Indices<=k-1),:);
    Test=data(find(Indices>k-1),:);
    X_Train=Train(:,1:(end-1));
    Y_Train=Train(:,end);
    X_Test=Test(:,1:(end-1));
    Y_Test=Test(:,end);
else
    
end