% tbl = tables.convert(dataStruct, {suffix2a, suffix2b}, {suffix3a, suffix3b, suffix3C}, ...)
% Convert struct to table splitting fields with a given number of elements into separate columns.
% 
% Example:
%   data.center = [1, 2]
%   data.paw = [1, 2, 3, 4]
%   tbl = tables.convert(data, {'X', 'Y'}, {'FL', 'FR', 'BL', 'BR'});
%   disp(tbl.Properties.VariableNames)
%     centerX, centerY, pawFL, pawFR, pawBL, pawBR

% 2023-08-09. Leonardo Molina.
% 2023-08-09. Last modified.
function tbl = convert(data, varargin)
    counts = cellfun(@numel, varargin);
    tbl = struct2table(data);
    fnames = tbl.Properties.VariableNames;
    for i = 1:numel(fnames)
        target = fnames{i};
        item = data(1).(target);
        if isnumeric(item)
            k = counts == numel(item);
            if any(k)
                newNames = cellfun(@(suffix) [target, suffix], varargin{k}, 'UniformOutput', false);
                tbl = splitvars(tbl, target, 'NewVariableNames', newNames);
            end
        end
    end
end