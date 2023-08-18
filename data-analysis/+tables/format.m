% format(tbl, 'sex', @(x) x);
function tbl = format(tbl, varargin)
    for i = 1:2:numel(varargin)
        target = varargin{i};
        change = varargin{i + 1};
        if ismember(target, tbl.Properties.VariableNames)
            tbl.(target) = cellfun(change, tbl.(target), 'UniformOutput', false);
        end
    end
end