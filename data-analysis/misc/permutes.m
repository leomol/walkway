% Return permutations where items repeat.
% Example:
%   permutes([7, 0, 9, 9, 0])
%      1     1     1     1
%      5     2     5     2
%      4     4     3     3
%      3     3     4     4
%      2     5     2     5

% 2022-10-25. Leonardo Molina.
% 2022-10-26. Last modified.
function expanded = permutes(ids, n)
    if nargin < 2
        n = Inf;
    end
    
    nIds = numel(ids);
    % Find time permutations for each repetition.
    uIds = unique(ids, 'stable');
    nUIds = numel(uIds);
    permutations = cell(1, nUIds);
    for i = 1:nUIds
        uId = uIds(i);
        k = find(ids == uId);
        if numel(k) > 1
            permutations{i} = perms(k)';
        else
            permutations{i} = k;
        end
    end
    
    % Find rotations for all permutations combined.
    dimensions = cellfun(@(x) size(x, 2), permutations);
    combinations = rotator(dimensions);
    nCombinations = size(combinations, 2);

    % Return upto n combinations sampled evenly.
    n = min(nCombinations, max(n, 1));
    ks = floor(linspace(1, nCombinations, n));
    
    % Expand rotations by extracting value pointed by permutations, for each rotation.
    expanded = zeros(nIds, n);
    for c = 1:n
        for i = 1:nUIds
            uId = uIds(i);
            k = ks(c);
            expanded(ids == uId, c) = permutations{i}(:, combinations(i, k));
        end
    end
end