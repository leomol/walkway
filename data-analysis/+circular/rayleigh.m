% Test for circular uniformity using Rayleigh test.
% circular.rayleigh(angles, expectedPhase, alpha)
%   expectedPhase:
%      expected phase when using modified Rayleigh's test.
%      set empty to use a non-modified Rayleigh's test.
%
% Reference:
%   Biostatistical Analysis by Jerrold H Zar (5th edition).
%   (PDF page = book page + 4)
%   Example 26.6, page 619
%   Example 27.3, page 628
%
% Example 27.2, page 627:
%   angles = [66, 75, 86, 88, 88, 93, 97, 101, 118, 130] / 180 * pi;
%   expectedPhase = 90 / 180 * pi;
%   [pValue, f, delta, meanAngle] = circular.rayleigh(angles, expectedPhase)

% 2023-08-09. Leonardo Molina.
% 2023-08-21. Last modified.
function [pValue, f, delta, meanAngle] = rayleigh(angles, expectedAngle, alpha)
    if nargin < 3
        alpha = 0.05;
    end
    modifiedRayleigh = numel(expectedAngle) == 1;
    x = mean(cos(angles));
    y = mean(sin(angles));
    m = sqrt(x ^ 2 + y ^ 2);
    % Equation 27.1, page 625.
    nPoints = numel(angles);
    r = nPoints * m;
    meanAngle = atan2(y, x);
    if modifiedRayleigh
        % Equation 27.5, page 626.
        v = r * cos(meanAngle - expectedAngle);
        % Equation 27.6, page 626.
        u = v * sqrt(2 / nPoints);
        % Table B.35: Critical Values of u for the V Test of Circular Uniformity, page 844.
        pValue = lookup.CircularUniformity(nPoints, u);
    else
        % Equation 27.4, page 625.
        pValue = exp(sqrt(1 + 4 * nPoints + 4 * (nPoints ^ 2 - r ^ 2)) - (1 + 2 * nPoints));
    end
    % Table B.1: Critical Values of the Chi-Square (x^2) Distribution, page 672.
    dof = 1;
    f = lookup.ChiSquare(dof, alpha);
    % Equation 26.25, page 618.
    delta = acos(sqrt(nPoints ^ 2 - (nPoints ^ 2 - r ^ 2) * exp(f / nPoints)) / r);
end