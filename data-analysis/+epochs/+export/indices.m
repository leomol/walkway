% epochs = [1 5; 6 10; 11 15]';
% ind = epochs.export.indices(epochs)

% 2022-07-14. Leonardo Molina.
% 2023-08-17. Last modified.
function ind = indices(input)
    ind = zeros(0, 1);
    n = numel(input);
    for e = 1:2:n - 1
        a = input(e);
        b = input(e + 1);
        ind = cat(1, ind, colon(a, b)');
    end
    % If all epochs last the same, reshape.
    d = input(2:2:end) - input(1:2:end - 1);
    if sum(diff(d)) == 0
        ind = reshape(ind, d(1) + 1, []);
    end
end