% Test for circular uniformity using Rayleigh test.
% circular.rayleigh(angles)
% circular.rayleigh(..., expectedPhase, alpha)
% 
%   expectedPhase:
%      expected phase when using modified Rayleigh's test.
%      set empty to use a non-modified Rayleigh's test (default).
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
% 2024-04-24. Last modified.
function [pValue, chiSquare, delta, meanAngle] = rayleigh(angles, expectedAngle, alpha)
    if nargin < 2
        expectedAngle = [];
    end
    if nargin < 3
        alpha = 0.05;
    end
    x = mean(cos(angles), 'OmitNaN');
    y = mean(sin(angles), 'OmitNaN');
    n = sum(~isnan(angles));
    % Equation 27.1, page 625.
    r = sqrt(x ^ 2 + y ^ 2);
    R = n * r;
    meanAngle = atan2(y, x);
    modifiedRayleigh = numel(expectedAngle) == 1;
    if modifiedRayleigh
        % Equation 27.5, page 626.
        v = R * cos(meanAngle - expectedAngle);
        % Equation 27.6, page 626.
        u = v * sqrt(2 / n);
        % Table B.35: Critical Values of u for the V Test of Circular Uniformity, page 844.
        pValue = lookup.CircularUniformity(n, u);
    else
        % Equation 27.4, page 625.
        pValue = exp(sqrt(1 + 4 * n + 4 * (n ^ 2 - R ^ 2)) - (1 + 2 * n));
    end
    % Table B.1: Critical Values of the Chi-Square (x^2) Distribution, page 672.
    dof = 1;
    chiSquare = lookup.ChiSquare(dof, alpha);
    % Equation 26.24 and 26.25, page 618.
    if r <= 0.9
        delta = acos(sqrt(2 * n * (2 * R ^ 2 - n * chiSquare) / (4 * n - chiSquare)) / R);
    else
        delta = acos(sqrt(n ^ 2 - (n ^ 2 - R ^ 2) * exp(chiSquare / n)) / R);
    end
end