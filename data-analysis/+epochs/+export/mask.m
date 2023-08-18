% mask = mask(input, nSamples)

% 2022-07-14. Leonardo Molina.
% 2023-06-07. Last modified.
function mask = mask(input, nSamples)
    mask = false(nSamples, 1);
    n = numel(input);
    for e = 1:2:n - 1
        a = input(e);
        b = input(e + 1);
        mask(a:b) = true;
    end
end