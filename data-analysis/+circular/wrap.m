% Wrap - Wrap data within range.
% d = wrap(data, range)
% Example:
% circular.wrap([-720, -180, 180, 720], [-180, 180])

% 2022-07-18. Leonardo Molina.
% 2022-07-18. Last modified.
function d = wrap(data, range)
    d = mod(data + range(2), diff(range)) + range(1);
end