% circular.rayleigh(angles, expectedPhase, alpha)
% Test for circular uniformity under the alternative of nonuniformity and a specified mean direction.
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
%   angles = [66, 75, 86, 88, 88, 93, 97, 101, 118, 130];
%   expectedPhase = 90;
%   [pValue, delta, meanPhase] = circular.rayleigh(angles / 180 * pi, expectedPhase / 180 * pi)

% 2023-08-09. Leonardo Molina.
% 2023-08-15. Last modified.
function [pValue, delta, meanPhase] = rayleigh(angles, expectedPhase, alpha)
    if nargin < 3
        alpha = 0.05;
    end
    modifiedRayleigh = numel(expectedPhase) == 1;
    x = mean(cos(angles));
    y = mean(sin(angles));
    m = sqrt(x ^ 2 + y ^ 2);
    % Equation 27.1, page 625.
    nSamples = numel(angles);
    r = nSamples * m;
    meanPhase = atan2(y, x);
    if modifiedRayleigh
        % Equation 27.5, page 626.
        v = r * cos(meanPhase - expectedPhase);
        % Equation 27.6, page 626.
        u = v * sqrt(2 / nSamples);
        % Table B.35: Critical Values of u for the V Test of Circular Uniformity, page 844.
        pValue = lookup.CircularUniformity(nSamples, u);
    else
        % Equation 27.4, page 625.
        pValue = exp(sqrt(1 + 4 * nSamples + 4 * (nSamples ^ 2 - r ^ 2)) - (1 + 2 * nSamples));
    end
    % Table B.1: Critical Values of the Chi-Square (x^2) Distribution, page 672.
    dof = 1;
    criticalValue = lookup.ChiSquare(dof, alpha);
    % Equation 26.25, page 618.
    delta = acos(sqrt(nSamples ^ 2 - (nSamples ^ 2 - r ^ 2) * exp(criticalValue / nSamples)) / r);
end