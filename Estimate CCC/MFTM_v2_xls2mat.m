function ID = MFTM_v2_xls2mat(filename, varargin)
% 
% This function is used to read and orgnize the data (in .xlsx or .xls
% format) of the MFTM experiment. A .mat file comprising information of
% task condition, accuracy, and RT in each trial will be genenrated for
% each participant.
%
% Tingting Wu wrote it 08/18/2015
%
% --------------------------------
% Input:
% - 'filename': Name of the excel file
%
% Optinal inputs:
% - 'Path': Directory of the excel file. 
%           Default: current working directory.
%
% Output:
% - numSub: number of participants
% - Flag: 1. Sucessed. 0:Fail.
%
% Examples:
% ---------------------------------
% [numSub, Flag] = MFTM3_xls2mat(C_filename);
% C_filename: Costomized name of the excel file. e.g. 'MFTM_data.xlsx'
% Example: [numSub, Flag] = MFTM3_xls2mat('MFTM_data.xlsx');
%
% [numSub, Flag] = MFTM3_xls2mat(C_filename,c_directory);
% C_directory: Costomized directory of the excel file. e.g.'/users/xxx/Desktop/data/'
% Example: [numSub, Flag] = MFTM3_xls2mat('MFTM_data.xlsx', '/users/TW/Desktop/data/');

    shiftVal = 2; % The row in the excel file contains the labels list
    
    %% Check inputs and load the Excel file (if it exists)
    if ~ischar(filename) || isempty(filename)
        error('Error: File name should be in char format!\n');
    end

    if exist(filename,'file')
       [~,~,c] = fileparts(filename);
       if strcmp(c,'.xlsx') || strcmp(c,'.xls')
          disp('Loading the Excel file ...');
          [~, ~, rawData] = xlsread(filename); %load file
       else
           error('Error: File should be in .xlsx or .xls format!\n');
       end
    else
        error('Error: File does not exist!\n');
    end
    output_Dir = fullfile(pwd,'MFTM_MAT');
    if ~exist(output_Dir,'dir'); mkdir(output_Dir); end
    
    %% Extract information
     Label = rawData(shiftVal,:);
     ID_list = cell2mat(rawData(shiftVal+1:end,findLabel(Label,'Subject')));
     Session_idx_all = cell2mat(rawData(shiftVal+1:end,findLabel(Label,'Session'))); 
     Block_idx_all = cell2mat(rawData(shiftVal+1:end,findLabel(Label,'Block'))); 
     ArrowRatio_all = cell2mat(rawData(shiftVal+1:end,findLabel(Label,'ArrowRatio')));
     ET_all = cell2mat(rawData(shiftVal+1:end,findLabel(Label,'SOA')))/1000;
     ACC_all = cell2mat(rawData(shiftVal+1:end,findLabel(Label,'SlideTarget.ACC')));
     RT_all = cell2mat(rawData(shiftVal+1:end,findLabel(Label,'SlideTarget.RT'))); 
     Resp_all = cell2mat(rawData(shiftVal+1:end,findLabel(Label,'SlideTarget.RESP'))); 
     
     ID = unique(ID_list);
    %% Index of response and correct response: 1. Left; 2. Right
%     for i = 1: length(Resp_all)
%         if strcmp(Resp_all{i}(1),'f') || strcmp(Resp_all{i}(1),'F')
%             Resp_idx_all(i,1) = 1;
%         elseif strcmp(Resp_all{i}(1),'j') || strcmp(Resp_all{i}(1),'J')
%             Resp_idx_all(i,1) = 2;
%         else
%             Resp_idx_all(i,1) = 0;
%         end
%     end
    ACC_all(Resp_all ~= 1 & Resp_all ~= 2) = 0;
   
    %% Save data for each subject in .mat format
    for xSub = 1 : length(ID)
        filename = sprintf('Sub_%d.mat',ID(xSub));
        Session_idx = Session_idx_all(ID_list == ID(xSub));
        Block_idx = Block_idx_all(ID_list == ID(xSub));
        ArrowRatio = ArrowRatio_all(ID_list == ID(xSub));
        ET = ET_all(ID_list == ID(xSub));
        Resp_idx = Resp_all(ID_list == ID(xSub));
        ACC = ACC_all(ID_list == ID(xSub));
        RT = RT_all(ID_list == ID(xSub));
        
        save(fullfile(output_Dir,filename),'Block_idx','Session_idx','ArrowRatio',...
            'ET','Resp_idx','ACC','RT');
    end     
end

function [ flag ] = findLabel( Label,target)
%
% Function to return the column number in the label list which matchs the target
%
% Inputs:
% - Label: a cells structure contains all labels, exctracted from the
%          'shiftVal' row of the Excel file
% - target: a string, the name of the target label
%
% Output:
% - flag: the column number of the target label in original Excel file
%
    celllength = cellfun('length',Label); %Number of strings in each cell
    
    %find cells which contain target string
    targetcell = strfind(Label,target);  
    
    %transform targetcell from cell to matrix, empty cells are replaced
    %with 0
    temp = cellfun('isempty',targetcell);%find all empty cells
    for i = 1:length(temp)
        if temp(i) == 1
            targetcell{i} = 0;
        end
    end
    targetmat=cell2mat(targetcell);
    
    flag = 0;
    for i = 1:length(Label)
        if targetmat(i) == 1 && celllength(i) == length(target)%5
            flag = i;
        end
    end

end


