% Returns the phase of the walking cycle for each time index.
% phase = getPhases(pawX, pawY, angle, threshold, window)
%   0: stance
%   1: swing
% 
% Input arguments:
%   pawX and pawY: x and y coordinates of a single paw.
%   angle: Angle in radians of forward movement.
%   threshold: Fraction of the mean change setting appart swing and stance.
%   window: Window size to apply a median filter in the form [left, right].

% 2022-07-11. Leonardo Molina.
% 2023-08-15. Last modified.
function phases = getPhases(pawX, pawY, angle, threshold, window)
    nSamples = numel(pawX);
    if nSamples >= 3
        % Get paw extension.
        pawM = rotate(-circular.mean(angle), pawX, pawY);
        
        % Flag phase changes.
        delta = diff(pawM(:));
        phases = delta > mean(delta) * threshold;
        phases = [phases(1); phases];
        % Remove artifacts.
        phases = median(shift(phases, window(1):window(2)), 2, 'omitnan') == 1;
        
        % Debounce signal.
        nPoints = numel(phases);
        accepted = phases(1);
        debounced = NaN(size(phases));
        duration = min(diff(window), nPoints);
        for i = 1:nPoints - duration
            if numel(unique(phases(i:i + duration - 1))) == 1
                accepted = phases(i);
            end
            debounced(i) = accepted;
        end
        debounced(end - duration + 1:end) = phases(end);
        phases = debounced;
    else
        phases = false(size(pawX));
    end
end