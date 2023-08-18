% epochs = epochs.import.cuts(cuts, range, overlap);
% 
% Get epochs from cuts in a range. Optional overlap offsets the start and
% end points of each epoch.
% 
% Example:
%   range = [1, 100];
%   cuts = [20, 50];
%   overlap = [0, 1];
%   epochs = epochs.import.cuts(cuts, range, overlap);
%      1    20    50
%     19    49    99

% 2022-08-25. Leonardo Molina.
% 2023-08-17. Last modified.
function output = cuts(inputCuts, range, overlap)
    if nargin < 3
        overlap = [0, 0];
    end
    inputCuts = inputCuts(:)';
    steps = unique([range(1), inputCuts, range(2)]);
    output = [steps(1:end - 1) + overlap(1); steps(2:end) - overlap(2)];
end