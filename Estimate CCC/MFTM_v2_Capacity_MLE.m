function [capacity, ACC, ACC_predicted, RT,p_RESP, validity] = MFTM_v2_Capacity_MLE(filename, n_SD, C_range, c_RESP, c_ACC)
%
% This function is used to estimate participant's capacity of cognitive
% control using MFTM data.
% Data of current participant should be converted into .mat format. Convert
% file using 'MFM3_xls2mat' function, or see this function for the content 
% of .mat file.
% Tingting Wu wrote it 08/18/2015
%
% --------------------------------
% Input:
% % - 'filename': Name of the .mat file for the current participant.
%
% Optinal inputs:
% - 'Path': Directory of the .mat file. 
%           Default: current working directory.
% Output:
% - capacity: Estimated capacity of cognitive control
% - ACC: empirical accuracy in each condition
% - ACC_predicted: predicted accuracy in each condition using the estimated
%                  capacity value
% - RT: reaction time in each condition
% - Eff: efficiency in each condition
% - validity: 1. valid data. 0:invalid data. See 'MFTM3_check_data'
%             subfunction
%
% Examples:
% ---------------------------------
% [capacity, ACC, ACC_predicted, RT, Eff, validity] = MFTM3_Capacity_MLE(C_filename)
% C_filename: Costomized name of the excel file. e.g. 'Sub_0001.mat'
% Example: [capacity, ACC, ACC_predicted, RT, Eff, validity] = MFTM3_Capacity_MLE('Sub_0001.mat');

% [capacity, ACC, ACC_predicted, RT, Eff, validity] = MFTM3_Capacity_MLE(C_filename,c_directory);
% C_directory: Costomized directory of the excel file. e.g.'/users/xxx/Desktop/data/'
% Example: [capacity, ACC, ACC_predicted, RT, Eff, validity] = MFTM3_Capacity_MLE('Sub_0001.mat', '/users/TW/Desktop/data/);

    %% Parameters
    Ratio_list =   {'3:2','4:1','5:0'};
    ET_list = [.25, .5, 1, 2];
              
    %% Check inputs and load the .mat file (if it exists)
    if ~ischar(filename) || isempty(filename)
        error('Error: File name should be in char format!\n');
    end

    if exist(fullfile(pwd, 'MFTM_MAT', filename),'file')
       [~,b,c] = fileparts(filename);
       if strcmp(c,'.mat') 
          load(fullfile(pwd, 'MFTM_MAT', filename));
       else
           error('Error: File should be in .mat format! See MFTM3_xls2mat function.\n');
       end
    else
        error('Error: File does not exist!\n');
    end
    output_Dir = fullfile(pwd,'MFTM_Results');
    if ~exist(output_Dir,'dir'); mkdir(output_Dir); end    
    fprintf('Estimating %s\n',b);
    
    %% Behavioral responses in each condition. 
    Ratio_idx = unique(ArrowRatio);
    ACC_all = ACC;
    RT_all = RT;
    clear ACC RT
    
    for xCon = 1 : length(Ratio_list)
        for xET = 1 : length(ET_list)
            data_con = ACC_all(ArrowRatio == Ratio_idx(xCon) & ET == ET_list(xET));
            ACC(xCon, xET) = mean(data_con);
            RT(xCon, xET) = mean_nSD(RT_all(ArrowRatio == Ratio_idx(xCon) &...
                                     ET == ET_list(xET) & ACC_all == 1), n_SD);
        end
    end
    
    %% Check data quality    
    [p_RESP, validity] = MFTM3_check_data(ACC, Resp_idx, c_ACC, c_RESP);
    
    %% Estimate capacity
    if validity == 1
        [capacity, ACC_predicted] = MFTM_capacity_EST(ACC, C_range);
    else
        capacity = nan;
        ACC_predicted = zeros(length(Ratio_idx),4);
    end
    
    %% Save results
    filename_output = sprintf('Result_%s.mat',b);
    save(fullfile(output_Dir,filename_output), 'capacity', 'validity', 'ACC', 'RT', ...
         'Ratio_list', 'ET_list', 'ACC_predicted', 'p_RESP');
end

function clean_mean = mean_nSD(raw_data, nSD)
% Inputs: 
% - raw_data: raw data (e.g. RT) in a certain condition.
% - nSD: number of stander deviation.
% Output:
% -clean_mean: Mean of the remaining values after excluding any value excessing nSD of 
% the mean of raw_data.
  upper = mean(raw_data) + nSD * std(raw_data);
  lower = mean(raw_data) - nSD * std(raw_data);
  clean_data = raw_data(raw_data <= upper & raw_data >= lower);
  clean_mean = mean(clean_data);
end

function [p_RESP, validity] = MFTM3_check_data(ACC_empirical, response_all,c_ACC, c_Resp)
% Inputs:
% - ACC_empricial: mean emprical accuracy in each condition
% - response_all: response in each trial
% - c_ACC: criterion for validating the emprical accuracy.
% - c_Resp: criterion for validating the total percentage of valid responses.
% Output:
% - validity: 1. valid; 0: invalid
%
% Criterion for valid data:
% 1. Valid responses (button 1 or 2) should be made in at least 95% trials.
% 2. Accuracy in 5:0 conditions should be at lease 85% under 500, 1000, and
%    2000 ms SOA.
     validity = 0;
     p_RESP = sum(response_all ~= 0)/length(response_all);
     if p_RESP > c_Resp
           if ACC_empirical(3,1) >= c_ACC && ACC_empirical(3,2) >= c_ACC && ACC_empirical(3,3) >= c_ACC && ACC_empirical(3,4) >= c_ACC
              validity = 1;
          end
     end      
end

function [C_EST, ACC_predicted] = MFTM_capacity_EST(ACC_empirical, C_range)
% Estimate the capacity using empirical accuracy.
%
% Inputs:
% - ACC_empricial: mean emprical accuracy in each condition
% - C_range: search range for the capacity value (see MFTM experiment setup for the range)
%
% Outputs:
% - capacity: estimated capacity
% - ACC_predicted: predicted accuracy

    C_vector = min(C_range): .01 : max(C_range);
    %% Parameters
    SOA = [.25, .5, 1, 2];
    Set_size =     [5,    5,     5];
    N_congruent =  [3,    4,     5];
    
    P_guess = .5 * ones(length(Set_size), length(SOA));
    
    %% Reshape and p'
    ACC = reshape(ACC_empirical, length(Set_size), length(SOA));
 %    P_get = mean(ACC(3,:));
    P_get = max(ACC(3,:));

    if P_get == 1
        P_get = 0.999;
    end
    
    %% Maximum likelihood estimation
    for xC = 1 : length(C_vector)
        w(xC) = N2Likeli(P_PRE(Set_size, N_congruent, SOA, P_get, P_guess, C_vector(xC)),ACC);
    end
    [~, C_min] = min(w);
    C_EST = C_vector(C_min);
    ACC_predicted = P_PRE(Set_size, N_congruent, SOA, P_get, P_guess, C_EST);
end

function P_predicted = P_PRE(Set_size, N_congruent, SOA, P_get, P_guess, C)
% Predicted accuracy and number of scanned arrows using capacity value 'C'
%
    N_maj  =       ceil(Set_size/2);
    for i = 1 : length(Set_size)
        P_group(i) = (prod((N_congruent(i) - N_maj(i) + 1) : N_congruent(i)) / ...
                          prod((Set_size(i)    - N_maj(i) + 1) : Set_size(i)));
    end

    for xCon = 1 : length(Set_size)
        for xET = 1 : length(SOA)
            n_sti(xCon, xET) =  2^C * SOA(xET);
            n_sample = n_sti(xCon, xET) / N_maj(xCon); 
            P_detect = 1 - (1 - P_group(xCon))^ n_sample;
            P_predicted(xCon,xET) = P_detect * P_get + (1-P_detect) * P_guess(xCon, xET);
        end
    end
end

function w = N2Likeli(P_predicted, P_observed)
% -2 likelihood between predicted and observed data
    L = 1; % Initial likelihood
    L = log(L); % log likelihood

    [nCon,nObservation] = size(P_predicted);

    for xCon = 1 : nCon
        for xObs = 1 : nObservation
            if P_predicted(xCon,xObs) ~= 1 && P_predicted(xCon,xObs) ~= 0                
                L = L +  P_observed(xCon,xObs) * log(P_predicted(xCon,xObs)) + ...
                     (1 - P_observed(xCon,xObs)) * log(1 - P_predicted(xCon,xObs));
            else
                L = L;
            end
        end
    end
    w = -2* L;
end
