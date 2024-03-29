% Rotate - rotate x and y according to angle.

% 2022-07-08. Leonardo Molina.
% 2022-07-08. Last modified.
function [x2, y2] = rotate(angle, x, y)
    cosR = cos(angle);
    sinR = sin(angle);
    x2 = x .* cosR - y .* sinR;
    y2 = y .* cosR + x .* sinR;
end