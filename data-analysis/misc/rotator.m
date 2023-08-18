% rotator([3, 2, 1])
%      1     2     3     1     2     3
%      1     1     1     2     2     2
%      1     1     1     1     1     1

% 2022-10-25. Leonardo Molina.
% 2022-10-25. Last modified.
function coordinates = rotator(dimensions)
    % Remove singletons prior to getting rotations with ind2sub to save
    % significant computing time in vectors with many singleton dimensions.
    targets = dimensions > 1;
    nDigits = numel(dimensions);
    limit = dimensions(targets);
    nRotations = prod(limit);
    output = cell(1, numel(limit));
    [output{:}] = ind2sub(limit, 1:nRotations);
    output = cat(1, output{:});
    coordinates = ones(nDigits, nRotations);
    coordinates(targets, :) = output;
end