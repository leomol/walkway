% Get transition epochs from a logical array.
% [riseEpochs, fallEpochs] = epochs.import.flags(flags)
%   [riseEpochs, fallEpochs] = epochs.import.flags([0 0 0 0 1 1 0 0 1])
%   %  riseEpochs -->  5 9
%   %                  6 9
%   %  fallEpochs -->  1 7
%   %                  4 8

% 2019-04-30. Leonardo Molina.
% 2023-08-17. Last modification.
function [riseEpochs, fallEpochs] = flags(inputFlags, overlap)
    if nargin < 2
        overlap = false;
    end
    inputFlags = inputFlags(:);
    m = cat(1, find(diff(inputFlags)), numel(inputFlags));
    counts = cat(1, m(1), diff(m));
    to = cumsum(counts);
    from = [0; to(1:end - 1)] + 1;
    if overlap
        to(1:end - 1) = to(1:end - 1) + 1;
    end
    riseEpochs = [from(1:2:end), to(1:2:end)]';
    fallEpochs = [from(2:2:end), to(2:2:end)]';
    if ~inputFlags(1)
        [riseEpochs, fallEpochs] = deal(fallEpochs, riseEpochs);
    end
    riseEpochs = reshape(riseEpochs, 2, []);
    fallEpochs = reshape(fallEpochs, 2, []);
end