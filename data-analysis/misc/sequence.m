% sequence(data)
% Represent a sequence of values as interrupted counts.
% For example:
%   [counts, numbers, from, to] = sequence([10 20 20 30 30 30 40 50])
%   %  counts -->  1,  2,  3,  1,  1
%   % numbers --> 10, 20, 30, 40, 50
%   %    from -->  1, 2, 4, 7, 8
%   %      to -->  1, 3, 6, 7, 8

% 2019-04-30. Molina.
% 2020-08-21. Last modified.
function [counts, numbers, from, to] = sequence(data)
    data = data(:);
    if isempty(data)
        counts = [];
        numbers = [];
        from = [];
        to = [];
    else
        m = cat(1, find(diff(data)), numel(data));
        counts = cat(1, m(1), diff(m));
        numbers = data(m);
        to = cumsum(counts);
        from = [0; to(1:end - 1)] + 1;
    end
end