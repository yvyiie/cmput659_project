function LearnSFMN
% 1. Generate a scale-free Gaussian Markov network
% 2. Sample N  instenaces

% use B-A Scale-Free Network Generation and Visualization package by
% by Mathew Neil George
% global UniverseData;

% seed network
seed =[0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1; 
       1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ; 
       1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;  
       1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0;  
       1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;  
       1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0;  
       1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;  
       1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0;  
       1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;  
       1 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0;
       1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
       1 0 0 0 0 0 0 0 0 1 0 0 0 0 1 0;
       1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0;
       1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
       1 0 0 1 0 1 0 1 0 1 0 1 1 0 0 0;
       1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]; 
% generate a scale-free network's adjacency matrix

p=100; % number of nodes/variables
max_trials = 5;
maxrep = 1; %repetitions in cross-validation
inds = [20:20:100];
th_inds=[0.05:0.02:0.05];

inv_corr_true_pos = zeros(length(inds),length(th_inds),max_trials);
inv_corr_true_neg = zeros(length(inds),length(th_inds),max_trials); 

corr_true_pos = zeros(length(inds),length(th_inds),max_trials);
corr_true_neg = zeros(length(inds),length(th_inds),max_trials); 
L1_true_pos = zeros(length(inds),length(th_inds),max_trials);
L1_true_neg = zeros(length(inds),length(th_inds),max_trials); 
 
for trial = 1:max_trials
Net = SFNG(p, 5, seed);

%maximum value for cov that does not violate pos-def constaint depends on p
const = 0.1; % for p=300; covariance value for each pair of nodes setting to 0.15 and larger violates positive-definiteness

% generate sparse inverse covariance matrix (capturing independence relationships
S1 = Net*const + eye(p);
S = inv(S1);

%figure(1);hist(sum(Net));
figure(2);hist(sum(abs(S1)));
figure(3);hist(sum(abs(S)));


%take  Cholesly factorization of S=C'C 
C=chol(S);
    
true_pos = [];
true_neg = [];
% total # of positves (1s) and negatives (zeros)
total_zeros = size(find(Net == 0),1);
total_ones = p*p - total_zeros;
    
% for different number of samples
ii = 0;

for n = inds 
    ii = ii +1;
    % generate Gaussian entries with zero mean and variance 1 in a nxp matrix Z
    Z = random('norm',0,1,[n,p]);
    ZZ = normalize_EN(Z);

    %and compute data = ZC as your data
    data= Z*C;
    %you'll still get zero means for each column i in X and the correponding
    %variable X_i will be a mixture of independent Gaussian variables corresponding to non-zero entries in the i-th column of S;
    %thus we get dependencies among columns of X that correspond to non-zero-pattern inS;
    %then we can normalize X to get unit variance.

    % compute adjacency matrix based on thresholded correlations
    corr_mat = corrcoef(data) - eye(p,p);
    inv_corr_mat = inv(corr_mat);
    % compute true postive (precision) and true negative (recall) ratios
    i1 = 0;

    %%%%% M&B method - fixed lambda (corresponding to some fixed bound %%%%% on the l1 norm of a solution
    alp = 0.05;
    % X = normalize_EN(X);
    % y = center(y);
    sigm = 1; % for normalized data with variance 1 %sqrt(y'*y/n);
    %mb_lambda = (n/2)*2*sigm*(1/sqrt(n))*( icdf('norm',(1- alp/(2*p*p)),0,1) );
    mb_lambda =  0.5*n*sigm*(1/sqrt(n))*( icdf('norm',(1- alp/(2*p)),0,1) );

    data = normalize_EN(data);
    data=standardize(data);
        
    % empirical covariance matrix
        
    Cov_emp = (1/size(data,1))*data'*data;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Banerjee's et al method 
        % Algorithm's parameters
        rho=0.6;            % Controls sparsity
        prec=1e-1;         % Numerical precision
        maxiter=2;         % Maximum Number of sweeps in coordinate descent
        algot='nest';        % Algorith for solving BoxQP: 'sedumi' uses SEDUMI, 'nest' uses smooth minimization (usually faster)
        maxnest=1000;   % Maximum number of iterations in the smooth BoxQP solver


        % Test block COVSEL code
        [Umat,X] = spmlcdvec(Cov_emp,rho,maxiter,prec,maxnest,algot); % Inverse covariance is stored in Umat
        
    for threshold = th_inds
        i1 = i1 + 1;

        Corr_graph = (abs(corr_mat) > threshold);        
        corr_true_pos(ii,i1,trial) = size(find(Corr_graph & Net),1)/total_ones;
        corr_true_neg(ii,i1,trial) = size(find(~Corr_graph  & ~Net),1)/total_zeros;
        
        Inv_corr_graph = (abs(inv_corr_mat) > threshold);
        inv_corr_true_pos(ii,i1,trial) = size(find(Inv_corr_graph & Net),1)/total_ones;
        inv_corr_true_neg(ii,i1,trial) = size(find(~Inv_corr_graph  & ~Net),1)/total_zeros;

    
        % plot the dependence of reconstruction accuracy based on thresholding
        % the (empirical) correlation matrix
   
        % perform Lasso (using LARS w/ lasso modification) for each node,
        % obtain all solutions
        neighborhood = [];
        neighborhood_no_cv = [];
        hybrid = [];
             hybrid1 = [];
        mb_beta=[];
           mb_beta1=[]; 
           
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Meinshausen & Buelmann's method, and its modifications (variable-wise regressions)
        for i=1:p
            y = data(:,i); % i-th variable is now the response variable 
            if i==1
                X = data(:,[2:p]);
            elseif i==p
                X = data(:,[1:(p-1)]);
            else
                X = [data(:,[1:(i-1)]) data(:,[(i+1):p])];
            end
 
 %%%%% Our method: stopping cond on LARS using corr matrix, combined with cross-val %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            tt = floor(0.7*n);
            rand('state',0);
       
            best_beta = [];
            best_ind=[];
            num = sum(Corr_graph(i,:),2); % bound on the number of neighbors according to the thresholded corr matrix
            
            %if maxrep < 1
                 beta = lars(X, y, 'lasso', -num, 0, [], 1);      
                 ind = size(beta,1);
                 if i==1
                        sol = [0 beta(ind,:)];
                 elseif i==p
                        sol = [beta(ind,:) 0];
                 else
                        sol = [beta(ind,[1:(i-1)]) 0 beta(ind,[i:(p-1)])];
                 end
                 neighborhood_no_cv = [neighborhood_no_cv; sol ~= 0]; % TAKE LAST SOLUTION
           % else
                for rep=1:maxrep
                % randomize the data and 
                % split data into 70% training and 30% cross-validation set
                    indrnd = randperm(n);
                    X = X(indrnd, :);
                    y = y(indrnd);

                    X_train = X(1:tt,:);
                    y_train = y(1:tt,:);
                    X_test = X((tt+1):n,:);
                    y_test = y((tt+1):n);

                    % to run Lasso, normalize X (so the variables have unit variance) and center y
    %                 X_train = normalize_EN(X_train);
    %                 y_train=center(y_train);

                     beta = lars(X_train, y_train, 'lasso', -num, 0, [], 1);

                    % choose the least-squares solution over all iterations 
                    L2err=[];
    %                 X_test = normalize_EN(X_test);
    %                 y_test=center(y_test);
                    for j=1:size(beta,1)
                        er = y_test-X_test*beta(j,:)';
                        L2err(j) = er'*er;
                    end
                    [err,ind]=min(L2err);

                    % this solution defines the neighborhood of i-th node using adaptive method (ours)
                    %create row in the new adjacency matrix (include the node itself with 0
                    if i==1
                        sol = [0 beta(ind,:)];
                    elseif i==p
                        sol = [beta(ind,:) 0];
                    else
                        sol = [beta(ind,[1:(i-1)]) 0 beta(ind,[i:(p-1)])];
                    end
                    best_beta = [best_beta; sol]; 
                    best_ind = [best_ind; ind];
                end
                %%%%%%%%%%%%  end of our method %%%%%%%%%%%%%%%%%%%%%%%
                our_possible_neighborhoods = (best_beta ~= 0);
                our_ANDneighborhood =  (sum(our_possible_neighborhoods,1) == maxrep); % all folds agree on this edge
                neighborhood = [neighborhood;  our_ANDneighborhood];
           % end
             
            %%%%% M&B method - fixed lambda (corresponding to some fixed
            %%%%% bound %%%%% on the l1 norm of a solution
 
%%%%%%%%%%%%%%%%mb_lambda = lambda/2
            [beta, numIters, activationHist, duals] = SolveLasso(X, y, p-1, 'lasso', 100*p, mb_lambda, 0, 0);
             beta=beta';
            if i==1
                sol = [0 beta];
            elseif i==p
                sol = [beta  0];
            else
                sol = [beta(1:(i-1)) 0 beta(i:(p-1))];
            end

            mb_beta=[mb_beta;sol];
            
            if  num < 40 % = sum(Corr_graph(i,:),2); % bound on the number of neighbors according to the thresholded corr matrix
                % choose MB solution, otherwise adaptive
                hybrid = [hybrid; (sol ~=0)];
            else
                hybrid = [hybrid;neighborhood_no_cv(i,:)];
            end
            
              if  num < 30 % = sum(Corr_graph(i,:),2); % bound on the number of neighbors according to the thresholded corr matrix
                % choose MB solution, otherwise adaptive
                hybrid1 = [hybrid1; (sol ~=0)];
            else
                hybrid1 = [hybrid1;neighborhood_no_cv(i,:)];
              end
            
 %%%%%%%%%%%%%%%%mb_lambda = lambda/4
            [beta, numIters, activationHist, duals] = SolveLasso(X, y, p-1, 'lasso', 100*p, mb_lambda/2, 0, 0);
             beta=beta';
            if i==1
                sol = [0 beta];
            elseif i==p
                sol = [beta  0];
            else
                sol = [beta(1:(i-1)) 0 beta(i:(p-1))];
            end

            mb_beta1=[mb_beta1;sol];
            


%%%%% end of M&B method %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
        Our_graph = neighborhood' & neighborhood; % choose edge if both nodes agree on it
        Our_graph_no_cv = neighborhood_no_cv' & neighborhood_no_cv;
        
        MB_neighborhood = (mb_beta ~= 0);
        MB_graph = MB_neighborhood'  & MB_neighborhood;
        
        MB1_neighborhood = (mb_beta1 ~= 0);
        MB1_graph = MB1_neighborhood'  & MB1_neighborhood;
        
        Hybrid_graph = hybrid' & hybrid;
        Hybrid_graph1 = hybrid1' & hybrid1;
     
        % compute true postive (precision) and true negative (recall) ratios
        L1_true_pos(ii,i1,trial) = size(find(Our_graph & Net),1)/total_ones;
        L1_true_neg(ii,i1,trial) = size(find(~Our_graph  & ~Net),1)/total_zeros;
        
        L1_true_pos_no_cv(ii,i1,trial) = size(find(Our_graph_no_cv & Net),1)/total_ones;
        L1_true_neg_no_cv(ii,i1,trial) = size(find(~Our_graph_no_cv  & ~Net),1)/total_zeros;
        
        MB_true_pos(ii,i1,trial) = size(find(MB_graph & Net),1)/total_ones;
        MB_true_neg(ii,i1,trial) = size(find(~MB_graph  & ~Net),1)/total_zeros;
        
                
        MB1_true_pos(ii,i1,trial) = size(find(MB1_graph & Net),1)/total_ones;
        MB1_true_neg(ii,i1,trial) = size(find(~MB1_graph  & ~Net),1)/total_zeros;
        
        hybrid_true_pos(ii,i1,trial) = size(find(Hybrid_graph & Net),1)/total_ones;
        hybrid_true_neg(ii,i1,trial) = size(find(~Hybrid_graph  & ~Net),1)/total_zeros;
        
        hybrid1_true_pos(ii,i1,trial) = size(find(Hybrid_graph1 & Net),1)/total_ones;
        hybrid1_true_neg(ii,i1,trial) = size(find(~Hybrid_graph1  & ~Net),1)/total_zeros;
    end
end
end

total_corr_true_pos = sum(corr_true_pos,3)/max_trials;
total_corr_true_neg = sum(corr_true_neg,3)/max_trials;

total_inv_corr_true_pos = sum(inv_corr_true_pos,3)/max_trials;
total_inv_corr_true_neg = sum(inv_corr_true_neg,3)/max_trials;


total_L1_true_pos = sum(L1_true_pos,3)/max_trials;
total_L1_true_neg = sum(L1_true_neg,3)/max_trials;
total_L1_true_pos_no_cv = sum(L1_true_pos_no_cv,3)/max_trials;
total_L1_true_neg_no_cv = sum(L1_true_neg_no_cv,3)/max_trials;
total_MB_true_pos = sum(MB_true_pos,3)/max_trials;
total_MB_true_neg = sum(MB_true_neg,3)/max_trials;
total_hybrid_true_pos = sum(hybrid_true_pos,3)/max_trials;
total_hybrid_true_neg = sum(hybrid_true_neg,3)/max_trials;

total_MB1_true_pos = sum(MB1_true_pos,3)/max_trials;
total_MB1_true_neg = sum(MB1_true_neg,3)/max_trials;
total_hybrid1_true_pos = sum(hybrid1_true_pos,3)/max_trials;
total_hybrid1_true_neg = sum(hybrid1_true_neg,3)/max_trials;


save res_th01_02_07_maxrep1_BA5

 i1 = 0;
 for threshold = th_inds
     i1 = i1 + 1;
%      figure(i1);
%     plot(inds,total_corr_true_pos(:,i1), 'bx-',inds, total_corr_true_neg(:,i1), 'ro-');
%     ylabel('Accuracy','fontsize',16);
%     xlabel('number of samples','fontsize',16);
%     [s,e]=sprintf('Thresholded-Correlation: threshold = %.2f', threshold); 
%     title(s,'fontsize',12);
%     legend('true positives (precision)','true negatives (recall)');
% % %     
%     figure(100+i1);
%     plot(inds,total_L1_true_pos(:,i1), 'bx-',inds, total_L1_true_neg(:,i1), 'ro-');
%     ylabel('Accuracy','fontsize',16);
%     xlabel('number of samples','fontsize',16);
%     [s,e]=sprintf('Lasso with Correlation-Prior(AND-rule): threshold = %.2f', threshold); 
%     title(s,'fontsize',12);
%     legend('true positives (precision)','true negatives (recall)');

    figure(1000+i1);
    plot(inds,total_inv_corr_true_pos(:,i1), 'k*-', inds,total_corr_true_pos(:,i1), 'kd-', inds,total_L1_true_pos(:,i1), 'bx--',inds, total_L1_true_pos_no_cv(:,i1), 'gx-',inds, total_MB_true_pos(:,i1), 'ro-',inds, total_hybrid_true_pos(:,i1), 'mv-','LineWidth',2, 'MarkerSize',12);
    ylabel('True positives','fontsize',16);
    xlabel('number of samples','fontsize',16);
    [s,e]=sprintf('True positives: MB vs adaptive Lasso vs corr (threshold = %.2f)', threshold); 
    title(s,'fontsize',12);
    legend('Inverse-correlation','Correlation','Adaptive Lasso (+cv)','Adaptive Lasso','MB','hybrid','Location','SouthEast');
   
    figure(1100+i1);
    plot(inds,total_inv_corr_true_neg(:,i1), 'k*-',inds,total_corr_true_neg(:,i1), 'kd-', inds, total_L1_true_neg(:,i1),'bx--' ,inds, total_L1_true_neg_no_cv(:,i1), 'gx-',inds, total_MB_true_neg(:,i1), 'ro-',inds, total_hybrid_true_neg(:,i1), 'mv-','LineWidth',2, 'MarkerSize',12);
    ylabel('True negatives','fontsize',16);
    xlabel('number of samples','fontsize',16);
    [s,e]=sprintf('True negatives: : MB vs adaptive Lasso vs corr (threshold = %.2f)', threshold); 
    title(s,'fontsize',12);
    legend('Inverse-correlation','Correlation','Adaptive Lasso  (+cv)','Adaptive Lasso','MB','hybrid', 'Location', 'SouthEast');
%  
%     figure(2000+i1);
%     hold on;
%     plot(total_corr_true_neg(:,i1), total_corr_true_pos(:,i1), 'k-');
%     plot(total_L1_true_neg(:,i1),total_L1_true_pos(:,i1));
%     plot(total_MB_true_neg(:,i1),total_MB_true_pos(:,i1), 'ro-');
%     ylabel('True positives','fontsize',16);
%     xlabel('True negatives','fontsize',16);
%     [s,e]=sprintf('True pos vs true neg: MB vs adaptive Lasso vs corr (threshold = %.2f)', threshold); 
%     title(s,'fontsize',12);
%     legend('Correlation','Adaptive Lasso','MB');

 end
% map each constraint t to corresponding value of lambda (knowing opt solution)

% choose best solution for each node (our method)

% choose fixed-lambda solution where lambda is suggested by  MB(meinhausen&bulman)  

% for each method, use OR and AND rules to reconstruct edges

% compute precision and recall (true positive and true negative errs)

 
