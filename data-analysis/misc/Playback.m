% Playback a video.
% Shortcuts:
%   Space bar: play/pause.
%   Right arrow key: move 1 frame forward.
%   Left arrow key: move 1 frame backwards.

% 2023-07-07. Leonardo Molina.
% 2023-07-20. Last modified.
classdef Playback < handle
    properties
        playing = true
        step = 0
    end

    methods
        function obj = Playback(path, axs, fps)
            fig = figure();
            set(fig, 'KeyPressFcn', @(handle, data)obj.capture(handle));
            video = VideoReader(path);
            if nargin < 3
                fps = video.FrameRate;
            end
            lines = cell(size(axs));
            for i = 1:numel(axs)
                ylims = ylim(axs(i));
                lines{i} = plot(axs(i), NaN(1, 2), ylims, '--', 'HandleVisibility', 'off');
            end
            lines = [lines{:}];
            valid = @() all(ishandle([fig; axs(:)]));
            frame = readFrame(video);
            canvas = imshow(frame);
            target = gca();
            while valid()
                if obj.playing || obj.step ~= 0
                    frameId = round(video.CurrentTime * video.FrameRate);
                    if obj.playing || obj.step == 1
                        if ~hasFrame(video)
                            video.CurrentTime = 0;
                        end
                    elseif obj.step == -1
                        if frameId <= 1
                            video.CurrentTime = video.NumFrames / video.FrameRate;
                        else
                            video.CurrentTime = (frameId - 1.5) / video.FrameRate;
                        end
                    end
                    obj.step = 0;
                    frame = readFrame(video);
                    time = video.CurrentTime * video.FrameRate / fps;
                    frameId = round(video.CurrentTime * video.FrameRate);
                    canvas.CData = frame;
                    set(lines, 'XData', [time, time]);
                    title(target, sprintf('time: %.3fs | frame: %i', time, frameId));
                end
                pause(1 / fps);
            end
            if ishandle(fig)
                close(fig);
            end
            delete(lines)
        end

        function capture(obj, handle)
            switch get(handle, 'CurrentCharacter')
                case 32 % space bar.
                    obj.playing = ~obj.playing;
                case 28 % left arrow key.
                    obj.step = -1;
                    obj.playing = false;
                case 29 % right arrow key.
                    obj.step = +1;
                    obj.playing = false;
            end
        end
    end
end