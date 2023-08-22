% Split- Split epochs.
% [swingEpochs, stanceEpochs] = epochs.split(swingStarts, input)

% 2022-07-12. Leonardo Molina.
% 2023-08-18. Last modified.
function [swingEpochs, stanceEpochs] = split(swingStarts, input)
    n = numel(input);
    isOdd = mod(n, 2);
    range1 = 1:n -  isOdd;
    range2 = 2:n - ~isOdd;
    if swingStarts
        swingEpochs = input(range1);
        stanceEpochs = input(range2);
    else
        swingEpochs = input(range2);
        stanceEpochs = input(range1);
    end
end