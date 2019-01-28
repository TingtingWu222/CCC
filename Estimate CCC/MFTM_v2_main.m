function MFTM_v2_main(fileID)
% 
% This function is used to read and organize the data (in .xlsx or .xls
% format) of the MFTM experiment. A .mat file containing information of
% task condition, accuracy, and RT in each trial will be generated for
% each participant.
%
% --------------------------------
% Input:
% - 'fileID': Name of the excel file
%
% Results will be displayed in the command window as a table
%
% Examples: 
%    If the file is under current working directory:
%    >> MFTM_v1_main('MFTM-M2_behavioral_all.xls');
%
%    The file name with full paths can be also used as the input
%    >> MFTM_v1_main('/Volumes/Data/MFTM/MFTM-M2_behavioral_all.xls');
%
% Wrote   by Tingting Wu   03/18/2015
% Revised by Tingting Wu   03/17/2017

    clc
    
    %% Default parameters (can be changed)
    C_range = [0,20]; % Search range of the CCC
    c_Resp = 0.95; % criterion for percentage of trials with valid responses.
    c_ACC  = 0.80; % criterion for validating the emprical accuracy in congurent conditions
    n_SD   = 3;    % Trials with RT excesses n_SD of the mean in that condition 
                   % will be excluded for RT analyses

    %% Check and load the Excel file (if it exists), and convert it to .mat format
    ID = MFTM_v2_xls2mat(fileID);
    
    %% Loop over subjects. Analysis the behavioral results and estimate CCC
    for xSub = 1 : length(ID)
        filename = sprintf('Sub_%d.mat', ID(xSub));
        [CCC(xSub), ACC(:,:, xSub), ACC_predicted(:,:, xSub), RT(:,:, xSub), ...
            ~, validity(xSub)] = MFTM_v2_Capacity_MLE(filename, n_SD, C_range, c_Resp, c_ACC);
        % assigns the variable to workspace
        assignin('base', 'CCC', CCC);
        assignin('base', 'ACC', ACC);
        assignin('base', 'ACC_predicted', ACC_predicted);
        assignin('base', 'RT', RT);
        assignin('base', 'validity', validity);
        assignin('base', 'ID', ID);
    end
    
    %% Report results in the command window
       fprintf('\n\n ID\tCCC\tValidity\n--------------------------\n');
       for xSub = 1 : length(ID)
           fprintf(' %d\t%.2f\t', ID(xSub), CCC(xSub));
           if validity(xSub) == 1
              fprintf('yes\n');
           else
              fprintf('no\n');
           end
       end
       fprintf('--------------------------\n');
       
end