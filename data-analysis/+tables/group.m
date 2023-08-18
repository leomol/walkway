% tbl = group(tbl, groupVariables, handle)
% Similar to grpstats(tbl, groupVariables, handle) except allowing non-numeric columns.
% The handling function isn't applied to non-numeric columns, instead the first element in the group is returned.

% 2022-08-09. Leonardo Molina.
% 2022-08-10. Last modified.
function tbl = group(tbl, groupVariables, handle)
    if nargin < 3
        handle = @(column) mean(column, 1);
    end
    columnNames = tbl.Properties.VariableNames;
    tbl = grpstats(tbl, groupVariables, @(column) attempt(handle, column));
    tbl = tbl(:, [1:numel(groupVariables), numel(groupVariables) + 2:end]);
    tbl.Properties.VariableNames = [groupVariables, setdiff(columnNames, groupVariables, 'stable')];
    tbl.Properties.RowNames = {};
end

function value = attempt(handle, column)
    try
        value = handle(column);
    catch
        value = column(1);
    end
end