% Return a mask from epochs in an array with nSamples.
% mask = epochs.export.mask(data, nSamples)

% 2022-07-14. Leonardo Molina.
% 2023-06-07. Last modified.
function mask = mask(data, nSamples)
    mask = false(nSamples, 1);
    n = numel(data);
    for e = 1:2:n - 1
        a = data(e);
        b = data(e + 1);
        mask(a:b) = true;
    end
end