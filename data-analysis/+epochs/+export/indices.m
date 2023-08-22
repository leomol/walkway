% Return array of indices from epoch ranges.
% data = [1 5; 6 10; 11 15]';
% ind = epochs.export.indices(data)

% 2022-07-14. Leonardo Molina.
% 2023-08-21. Last modified.
function ind = indices(data)
    ind = zeros(0, 1);
    n = numel(data);
    for e = 1:2:n - 1
        a = data(e);
        b = data(e + 1);
        ind = cat(1, ind, colon(a, b)');
    end
    % If all epochs last the same, reshape.
    d = data(2:2:end) - data(1:2:end - 1);
    if sum(diff(d)) == 0
        ind = reshape(ind, d(1) + 1, []);
    end
end