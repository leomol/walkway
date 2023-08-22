% Format - Reformat values in a given column of table using a function handle.
% Example:
%   tables.format(tbl, 'sex', @(x) x);

% 2023-08-22. Leonardo Molina.
% 2023-08-22. Last modified.
function tbl = format(tbl, varargin)
    for i = 1:2:numel(varargin)
        target = varargin{i};
        change = varargin{i + 1};
        if ismember(target, tbl.Properties.VariableNames)
            tbl.(target) = cellfun(change, tbl.(target), 'UniformOutput', false);
        end
    end
end