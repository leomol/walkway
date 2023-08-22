% For a pair of paws, get their phase offset for each stance.
% [meanCartesian, phases] = getPhaseOffset(swingPhasesA, stancePhasesA, swingPhasesB, stancePhasesB)

% 2023-08-04. Leonardo Molina.
% 2023-08-09. Last modified.
function [meanCartesian, phases] = getPhaseOffset(swingPhasesA, stancePhasesA, swingPhasesB, stancePhasesB)
    % Stance onsets for paw A.
    onsets1 = union(stancePhasesA(1, :), swingPhasesA(2, :));
    % Stance onsets for paw B.
    onsets2 = union(stancePhasesB(1, :), swingPhasesB(2, :));
    % Compare a matching number of stance periods.
    periods = diff(onsets2);
    n = min(numel(onsets1), numel(periods));
    phases = NaN(n, 1);
    for i = 1:n
        delta = onsets1(i) - onsets2(i);
        phases(i) = delta / periods(i);
    end
    phases(phases < 0) = phases(phases < 0) + 1;
    phases = phases * 2 * pi;
    meanCartesian = [mean(cos(phases)), mean(sin(phases))];
end