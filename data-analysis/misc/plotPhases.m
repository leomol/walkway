% plotPhases - Plot swing and stance.
% plotPhases(FLM, FRM, BLM, BRM, FLW, FLC, FRW, FRC, BLW, BLC, BRW, BRC, framerate)
% plotPhases(FLX, FLY, FRX, FRY, BLX, BLY, BRX, BRY, CX, CY, CA, framerate, threshold, window, criteria)
% plotPhases(loader, framerate, threshold, window, criteria)

% 2022-07-11. Leonardo Molina.
% 2023-08-18. Last modified.
function axs = plotPhases(varargin)
    if nargin == 13
            [FLM, FRM, BLM, BRM, FLW, FLC, FRW, FRC, BLW, BLC, BRW, BRC, framerate] = deal(varargin{:});
            nFrames = numel(FLM);
    else
        if nargin == 15
            [FLX, FLY, FRX, FRY, BLX, BLY, BRX, BRY, CX, CY, CA, framerate, threshold, window, criteria] = deal(varargin{:});
        elseif nargin == 5
            [loader, framerate, threshold, window, criteria] = deal(varargin{:});
            [FLX, FLY, FRX, FRY, BLX, BLY, BRX, BRY, CX, CY, CA] = loader();
        end
            
        % Distance along axis of motion.
        angle = circular.mean(CA);
        FLM = rotate(-angle, FLX - CX, FLY - CY);
        FRM = rotate(-angle, FRX - CX, FRY - CY);
        BLM = rotate(-angle, BLX - CX, BLY - CY);
        BRM = rotate(-angle, BRX - CX, BRY - CY);

        getter = @(x, y, ~) phases2strides(getPhases(x, y, CA, threshold, window), criteria, true);
        [FLW, FLC] = getter(FLX, FLY, CA);
        [FRW, FRC] = getter(FRX, FRY, CA);
        [BLW, BLC] = getter(BLX, BLY, CA);
        [BRW, BRC] = getter(BRX, BRY, CA);
        nFrames = numel(FLX);
    end
    time = (0:nFrames - 1) / framerate;
    
    cmap = [0.91, 0.91, 0.91
            0.85, 0.85, 0.85];
    
    plotOptions = {'k-', 'HandleVisibility', 'off'};
    middle = @(M) (min(M) + max(M)) / 2;

    axs(1) = subplot(4, 1, 1);
    hold('all');
    plot(time, FLM, plotOptions{:});
    text(0.01 * time(end), middle(FLM), 'FL');
    patchPlot(FLW, FLC, framerate, cmap);
    
    axs(2) = subplot(4, 1, 2);
    hold('all');
    plot(time, FRM, plotOptions{:});
    text(0.01 * time(end), middle(FRM), 'FR');
    patchPlot(FRW, FRC, framerate, cmap);
    
    axs(3) = subplot(4, 1, 3);
    hold('all');
    plot(time, BLM, plotOptions{:});
    text(0.01 * time(end), middle(BLM), 'BL');
    patchPlot(BLW, BLC, framerate, cmap);
    
    axs(4) = subplot(4, 1, 4);
    hold('all');
    plot(time, BRM, plotOptions{:});
    text(0.01 * time(end), middle(BRM), 'BR');
    p = patchPlot(BRW, BRC, framerate, cmap);
    
    h = legend(p, {'Swing', 'Stance'});
    h.Units = 'Pixels';
    h.Position(1:2) = 2;

    xlabel('Time (s)');
    ylabel('Amplitude (cm)');
    
    for ax = axs
        set(ax, 'Children', flipud(allchild(ax)));
    end
    
    set(axs(1:3), 'xTick', []);
    axis(axs, 'tight');
end

function h = patchPlot(swingEpochs, stanceEpochs, frequency, cmap, ylims)
    if nargin < 5
        ylims = ylim();
    end
    swingEpochs = (swingEpochs - 1) / frequency;
    stanceEpochs = (stanceEpochs - 1) / frequency;
    [swingFaces, swingVertices] = epochs.export.patch(swingEpochs, ylims(1), ylims(2));
    h(1) = patch('Faces', swingFaces, 'Vertices', swingVertices, 'FaceColor', cmap(1, :), 'EdgeColor', 'none', 'DisplayName', 'Swing');
    [stanceFaces, stanceVertices] = epochs.export.patch(stanceEpochs, ylims(1), ylims(2));
    h(2) = patch('Faces', stanceFaces, 'Vertices', stanceVertices, 'FaceColor', cmap(2, :), 'EdgeColor', 'none', 'DisplayName', 'Stance');
end