% Load body and paw midpoints, and full body orientation.

% 2022-07-11. Leonardo Molina.
% 2023-07-12. Last modified.
function [FLX, FLY, FRX, FRY, BLX, BLY, BRX, BRY, CX, CY, CA] = loadData(path, scale, angleSmoothWindow)
    data = loadDLC(path);
    data(:, :) = num2cell(table2array(data) * scale);

    % Body midpoints.
    CX = (data.MidPointLeft_x + data.MidPointRight_x) / 2;
    CY = (data.MidPointLeft_y + data.MidPointRight_y) / 2;

    % For a freely moving animal, define the angle of motion from position changes.
    if numel(CY) >= 2
        angles = atan2(diff(CY), diff(CX));
        confidence = min(data.MidPointLeft_p, data.MidPointRight_p);
        CA = circular.movmean(angleSmoothWindow, angles, confidence);
        CA = [CA; CA(end)];
    else
        CA = 0;
    end
    
    % Get paw centers from toes and heels.
    FLX = (data.FrontLeft2_x + data.FrontLeft1_x) / 2;
    FLY = (data.FrontLeft2_y + data.FrontLeft1_y) / 2;
    FRX = (data.FrontRight2_x + data.FrontRight1_x) / 2;
    FRY = (data.FrontRight2_y + data.FrontRight1_y) / 2;
    BLX = (data.HindLeft2_x + data.HindLeft1_x) / 2;
    BLY = (data.HindLeft2_y + data.HindLeft1_y) / 2;
    BRX = (data.HindRight2_x + data.HindRight1_x) / 2;
    BRY = (data.HindRight2_y + data.HindRight1_y) / 2;
end