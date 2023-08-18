% Convert phases to epochs and trim swing and stance epochs such that only full strides are kept.
% The resulting swing epochs consistently start at a swing or at a stance.

% 2022-07-11. Leonardo Molina.
% 2023-08-17. Last modified.
function [swingEpochs, stanceEpochs] = phases2strides(phases, criteria, overlap)
    if nargin < 2
        criteria = 'stance';
    end
    if nargin < 3
        overlap = false;
    end
    
    % -Remove the first and last epochs.
    % -Remove anything before the first stance (or swing).
    % -Remove anything after the last swing (or stance).
    % -Keep the same number of swings and stances.
    
    switch criteria
        case 'stance'
            % Stride is stance followed by swing.
            [swingEpochs, stanceEpochs] = trim( phases, overlap);
        case 'swing'
            % Stride is swing followed by stance.
            [stanceEpochs, swingEpochs] = trim(~phases, overlap);
        case 'best'
            % Stride is whichever of the two that leads to highest number of strides.
            [swingEpochs1, stanceEpochs1] = trim( phases, overlap);
            [stanceEpochs2, swingEpochs2] = trim(~phases, overlap);
            if size(swingEpochs1, 2) == size(swingEpochs2, 2)
                if numel(swingEpochs1) == 0
                    [swingEpochs, stanceEpochs] = deal(zeros(2, 0), zeros(2, 0));
                elseif min(swingEpochs1(1), stanceEpochs1(1)) <= min(swingEpochs2(1), stanceEpochs2(1))
                    [swingEpochs, stanceEpochs] = deal(swingEpochs1, stanceEpochs1);
                else
                    [swingEpochs, stanceEpochs] = deal(swingEpochs2, stanceEpochs2);
                end
            elseif size(swingEpochs1, 2) >= size(swingEpochs2, 2)
                [swingEpochs, stanceEpochs] = deal(swingEpochs1, stanceEpochs1);
            else
                [swingEpochs, stanceEpochs] = deal(swingEpochs2, stanceEpochs2);
            end
    end
end

function [swingEpochs, stanceEpochs] = trim(phases, overlap)
    % Swing and stance epochs may start/end right at the first/last frame.
    [swingEpochs, stanceEpochs] = epochs.import.flags(phases, overlap);
    nFrames = numel(phases);

    if numel(swingEpochs) > 0 && swingEpochs(1) == 1
        % If swing is the first epoch to appear, remove it.
        swingEpochs(:, 1) = [];
    elseif numel(stanceEpochs) > 0 && stanceEpochs(1) == 1
        % If stance is the first epoch to appear, remove it together with the first swing.
        stanceEpochs(:, 1) = [];
        if numel(swingEpochs) > 0
            swingEpochs(:, 1) = [];
        end
    end
    if numel(swingEpochs) > 1 && swingEpochs(end) == nFrames
        % If swing is the last epoch to appear, remove it together with the last stance.
        swingEpochs(:, end) = [];
        if numel(stanceEpochs) > 0
            stanceEpochs(:, end) = [];
        end
    elseif numel(stanceEpochs) > 0 && stanceEpochs(end) == nFrames
        % If stance is the last epoch to appear, remove it.
        stanceEpochs(:, end) = [];
    end
    % There should be no more swings than stances.
    n = min(size(stanceEpochs, 2), size(swingEpochs, 2));
    swingEpochs = swingEpochs(:, 1:n);
    stanceEpochs = stanceEpochs(:, 1:n);
end