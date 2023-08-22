% Table B.4: Critical Values of the F Distribution, page 680.
% Biostatistical Analysis by Jerrold H Zar (5th edition).
% 
% criticalValue = F(dof1, dof2, alpha)
% 
% Example 27.8, page 636.
% criticalValue = F(0.05, 1, 2, 16)
% %"F0.05(1),2,16" = 3.63

% 2023-08-21. Leonardo Molina.
% 2023-08-21. Last modified.
function criticalValue = F(alpha, nTails, dof1, dof2)
    persistent data alphas1 alphas2 dofs1 dofs2
    if isempty(data)
        alphas1 = [0.25, 0.10, 0.05, 0.025, 0.010, 0.005, 0.0025, 0.001, 0.0005];
        alphas2 = [0.50, 0.20, 0.10, 0.050, 0.020, 0.010, 0.0050, 0.002, 0.0010];
        dofs1 = [1:19 20:2:28 30:10:90 100:20:140 200 Inf];
        dofs2 = [1:30, 35:5:45, 50:10:90, 100:20:200, 300, 500, Inf];
        
        nColumns = numel(alphas1);
        folder = fileparts(mfilename('fullpath'));
        fid = fopen(fullfile(folder, 'private/F.csv'));
        data = textscan(fid, repmat('%f', 1, nColumns), 'Delimiter', ',');
        fclose(fid);
        data = [data{:}];
        nRows = 47;
        nTables = size(data, 1) / nRows;
        data = reshape(data', nColumns, nRows, nTables);
        data = permute(data, [2, 1, 3]);
    end
    
    dof2 = max(1, dof2);
    row = find(dof2 <= dofs2, 1);
    if nTails == 1
        alphas = alphas1;
    else
        alphas = alphas2;
    end
    alpha = min(alpha, alphas(1));
    column = find(alpha >= alphas, 1);
    
    dof1 = max(1, dof1);
    frame = find(dof1 <= dofs1, 1);

    criticalValue = data(row, column, frame);
end