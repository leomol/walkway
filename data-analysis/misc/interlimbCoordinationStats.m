% Statistical tests for interlimb coordination.
% 
% The 'offset' columns contain phase differences between pairs of limbs.
% For example offsetFLBR is the phase offset between front left and back
% right. The offset is represented in cartesian coordinates (X and Y).
% 
% With the WatsonWilliams test we want to test whether two (or more) groups
% animals have the same phase difference, for the same pair of limbs.
% For example, the FL to BL limbs has a phase difference K1, K2, ... for the
% injured group and Q1, Q2, ... for the control group, are these two different?
% 
% With the Rayleigh test we want to test whether a pair of limbs have a
% given phase difference. For example, are the FL and BL limbs offset by
% 180 degrees?
% 
% Run the library's startup.m script every time MATLAB is restarted.

% 2023-09-14. Leonardo Molina.
% 2024-04-24. Last modified.

%% Configuration.
% Specify full path of input csv file with 'offset' columns.
filename = 'U:\JC\outputs\gaitData-mean.csv';

% Rayleigh test - Specify the expected phase for each pair of limbs.
expectedPhases = struct();
expectedPhases.FRFL = 180;
expectedPhases.BRBL = 180;
expectedPhases.FLBL = 180;
expectedPhases.FRBR = 180;
expectedPhases.FRBL = 0;
expectedPhases.FLBR = 0;

% Rayleigh test - Specify range of rows to compare. For example 2:22.
rayleighRows = 17:21;

% Watson-Williams test - Specify range of rows to be compared. For example {2:22, 23:42}.
watsonWilliamsRows = {2:6, 17:21};

%% Run tests.
% Load data.
tbl = readtable(filename);

fnames = fieldnames(expectedPhases);
nPairs = numel(fnames);
nMetrics = 3;
rayleighData = NaN(nPairs, nMetrics);
watsonWilliamsData = NaN(nPairs, nMetrics);
header = {'p-value', 'average (deg)', 'error'};
for i = 1:nPairs
    fname = fnames{i};
    xName = ['offset' fname 'X'];
    yName = ['offset' fname 'Y'];
    x = tbl{rayleighRows - 1, xName};
    y = tbl{rayleighRows - 1, yName};
    x = repmat(x, 5, 1);
    y = repmat(y, 5, 1);
    % Run the Rayleigh test.
    expectedPhase = deg2rad(expectedPhases.(fname));
    phases = cart2pol(x, y);
    [p, ~, phaseError, meanPhase] = circular.rayleigh(phases, expectedPhase);
    meanPhase(meanPhase < 0) = meanPhase(meanPhase < 0) + 2 * pi;
    rayleighData(i, :) = [p, wrapTo360(rad2deg(meanPhase)), rad2deg(phaseError)];
    % Run the Watson Williams test.
    rows1 = watsonWilliamsRows{1} - 1;
    rows2 = watsonWilliamsRows{2} - 1;
    x1 = tbl{rows1, xName};
    y1 = tbl{rows1, yName};
    u1 = cart2pol(x1, y1);
    x2 = tbl{rows2, xName};
    y2 = tbl{rows2, yName};
    u2 = cart2pol(x2, y2);
    [p, ~, phaseError, meanPhase] = circular.watsonWilliams(u1, u2);
    watsonWilliamsData(i, :) = [p, wrapTo360(rad2deg(meanPhase)), rad2deg(phaseError)];
end
rayleighData = array2table(rayleighData, 'VariableNames', header, 'RowNames', fnames);
watsonWilliamsData = array2table(watsonWilliamsData, 'VariableNames', header, 'RowNames', fnames);
fprintf('Rayleigh test:\n');
disp(rayleighData);
fprintf('Watson-Williams test:\n');
disp(watsonWilliamsData);