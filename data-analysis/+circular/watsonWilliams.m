% Test multiple circular distributions.
% circular.watsonWilliams(angles1, angles2, ..., anglesN)
%
% Reference:
%   Biostatistical Analysis by Jerrold H Zar (5th edition).
%   (PDF page = book page + 4)
%   Example 27.7, page 633
%   Example 27.8, page 635
%   Table B.37
%   
%   angles1 = [135 145 125 140 165 170] / 180 * pi;
%   angles2 = [150 130 175 190 180 220] / 180 * pi;
%   angles3 = [140 165 185 180 125 175 140] / 180 * pi;
%   [pValue, f, delta, meanAngle] = circular.watsonWilliams(angles1, angles2, angles3)

% 2023-08-18. Leonardo Molina.
% 2023-09-15. Last modified.
function [pValue, f, delta, meanAngle] = watsonWilliams(varargin)
    samples = varargin;
    nSamples = numel(samples);
    rr = cellfun(@main, samples);
    if size(samples{1}, 1) == 1
        combined = cat(2, samples{:});
    else
        combined = cat(1, samples{:});
    end
    nPoints = sum(~isnan(combined));
    [r, meanAngle] = main(combined);
    % dof page 195 ~ 203
    % Table B.37.
    s = sum(rr);
    k = correctionFactor(s / nPoints);
    % Equation 27.14, page 634.
    f = k * (nPoints - nSamples) * (s - r) / (nSamples - 1) / (nPoints - s);
    dof1 = nSamples - 1;
    dof2 = nPoints - nSamples;
    pValue = 1 - fcdf(f, dof1, dof2);
    % Equation 26.25, page 618.
    delta = acos(sqrt(nPoints ^ 2 - (nPoints ^ 2 - r ^ 2) * exp(f / nPoints)) / r);
end

function [r, angle] = main(angles)
    n = sum(~isnan(angles));
    y = mean(sin(angles), 'OmitNan');
    x = mean(cos(angles), 'OmitNan');
    m = sqrt(x ^ 2 + y ^ 2);
    r = n * m;
    angle = atan2(y, x);
end

% Alternative to using table B.37 "Correction Factor, K, for the Watson and Williams Test"
% Extracted from:
%  Philipp Berens (2023). Circular Statistics Toolbox (Directional Statistics)
% https://www.mathworks.com/matlabcentral/fileexchange/10676-circular-statistics-toolbox-directional-statistics,
% MATLAB Central File Exchange. Retrieved August 21, 2023. 
function k = correctionFactor(rw)
    r = circular.mean(rw);
    n = numel(rw);
    if r < 0.53
        kappa = 2 * r + r ^ 3 + 5 * r ^ 5 / 6;
    elseif r >= 0.53 && r < 0.85
        kappa = -.4 + 1.39 * r + 0.43 / (1 - r);
    else
        kappa = 1 / (r ^ 3 - 4 * r ^ 2 + 3 * r);
    end
    
    if n < 15 && n > 1
        if kappa < 2
            kappa = max(kappa - 2 * (n * kappa) ^ -1, 0);    
        else
            kappa = (n - 1) ^ 3 * kappa / (n ^ 3 + n);
        end
    end
    k = 1 + 3 / (8 * kappa);
end