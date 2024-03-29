% Table B.35: Critical Values of u for the V Test of Circular Uniformity, page 844.
% Biostatistical Analysis by Jerrold H Zar (5th edition).
% 
% pValue = CircularUniformity(nPoints, u)

% 2023-08-09. Leonardo Molina.
% 2023-08-21. Last modified.
function pValue = CircularUniformity(nPoints, u)
    persistent data alphas counts;
    if isempty(data)
        alphas = [0.25, 0.1, 0.05, 0.025, 0.01, 0.005, 0.0025, 0.001, 0.0005];
        counts = [8:30, 32:2:50, 55:5:80, 90, 100, 120:200, 300, Inf];
        data = [
                0.6880, 1.2960, 1.6490, 1.9470, 2.2800, 2.4980, 2.6910, 2.9160, 3.0660
                0.6870, 1.2940, 1.6490, 1.9480, 2.2860, 2.5070, 2.7050, 2.9370, 3.0940
                0.6850, 1.2930, 1.6480, 1.9500, 2.2900, 2.5140, 2.7160, 2.9540, 3.1150
                0.6840, 1.2920, 1.6480, 1.9500, 2.2930, 2.5200, 2.7250, 2.9670, 3.1330
                0.6840, 1.2910, 1.6480, 1.9510, 2.2960, 2.5250, 2.7320, 2.9780, 3.1470
                0.6830, 1.2900, 1.6470, 1.9520, 2.2990, 2.5290, 2.7380, 2.9870, 3.1590
                0.6820, 1.2900, 1.6470, 1.9530, 2.3010, 2.5320, 2.7430, 2.9950, 3.1690
                0.6820, 1.2890, 1.6470, 1.9530, 2.3020, 2.5350, 2.7480, 3.0020, 3.1770
                0.6810, 1.2890, 1.6470, 1.9530, 2.3040, 2.5380, 2.7510, 3.0080, 3.1850
                0.6810, 1.2880, 1.6470, 1.9540, 2.3050, 2.5400, 2.7550, 3.0130, 3.1910
                0.6810, 1.2880, 1.6470, 1.9540, 2.3060, 2.5420, 2.7580, 3.0170, 3.1970
                0.6800, 1.2870, 1.6470, 1.9540, 2.3080, 2.5440, 2.7610, 3.0210, 3.2020
                0.6800, 1.2870, 1.6460, 1.9550, 2.3080, 2.5460, 2.7630, 3.0250, 3.2070
                0.6800, 1.2870, 1.6460, 1.9550, 2.3090, 2.5470, 2.7650, 3.0280, 3.2110
                0.6790, 1.2870, 1.6460, 1.9550, 2.3100, 2.5490, 2.7670, 3.0310, 3.2150
                0.6790, 1.2860, 1.6460, 1.9550, 2.3110, 2.5500, 2.7690, 3.0340, 3.2180
                0.6790, 1.2860, 1.6460, 1.9560, 2.3110, 2.5510, 2.7700, 3.0360, 3.2210
                0.6790, 1.2860, 1.6460, 1.9560, 2.3120, 2.5520, 2.7720, 3.0380, 3.2240
                0.6790, 1.2860, 1.6460, 1.9560, 2.3130, 2.5530, 2.7730, 3.0400, 3.2270
                0.6780, 1.2860, 1.6460, 1.9560, 2.3130, 2.5540, 2.7750, 3.0420, 3.2290
                0.6780, 1.2850, 1.6460, 1.9560, 2.3140, 2.5550, 2.7760, 3.0440, 3.2310
                0.6780, 1.2850, 1.6460, 1.9560, 2.3140, 2.5550, 2.7770, 3.0460, 3.2330
                0.6780, 1.2850, 1.6460, 1.9570, 2.3150, 2.5560, 2.7780, 3.0470, 3.2350
                0.6780, 1.2850, 1.6460, 1.9570, 2.3150, 2.5570, 2.7800, 3.0500, 3.2390
                0.6780, 1.2850, 1.6460, 1.9570, 2.3160, 2.5580, 2.7810, 3.0520, 3.2420
                0.6770, 1.2850, 1.6460, 1.9570, 2.3160, 2.5590, 2.7830, 3.0540, 3.2450
                0.6770, 1.2840, 1.6460, 1.9570, 2.3170, 2.5600, 2.7840, 3.0560, 3.2470
                0.6770, 1.2840, 1.6460, 1.9570, 2.3170, 2.5610, 2.7850, 3.0580, 3.2490
                0.6770, 1.2840, 1.6460, 1.9580, 2.3180, 2.5620, 2.7860, 3.0600, 3.2510
                0.6770, 1.2840, 1.6460, 1.9580, 2.3180, 2.5620, 2.7870, 3.0610, 3.2530
                0.6770, 1.2840, 1.6460, 1.9580, 2.3190, 2.5630, 2.7880, 3.0620, 3.2550
                0.6770, 1.2840, 1.6450, 1.9580, 2.3190, 2.5640, 2.7890, 3.0630, 3.2560
                0.6770, 1.2840, 1.6450, 1.9580, 2.3190, 2.5640, 2.7900, 3.0650, 3.2580
                0.6760, 1.2840, 1.6450, 1.9580, 2.3200, 2.5650, 2.7910, 3.0670, 3.2610
                0.6760, 1.2830, 1.6450, 1.9580, 2.3200, 2.5660, 2.7930, 3.0690, 3.2630
                0.6760, 1.2830, 1.6450, 1.9580, 2.3210, 2.5670, 2.7940, 3.0710, 3.2650
                0.6760, 1.2830, 1.6450, 1.9580, 2.3210, 2.5670, 2.7950, 3.0720, 3.2670
                0.6760, 1.2830, 1.6450, 1.9590, 2.3220, 2.5680, 2.7960, 3.0730, 3.2690
                0.6760, 1.2830, 1.6450, 1.9590, 2.3220, 2.5680, 2.7960, 3.0740, 3.2700
                0.6760, 1.2830, 1.6450, 1.9590, 2.3220, 2.5690, 2.7970, 3.0760, 3.2720
                0.6760, 1.2830, 1.6450, 1.9590, 2.3230, 2.5700, 2.7980, 3.0770, 3.2740
                0.6750, 1.2820, 1.6450, 1.9590, 2.3230, 2.5710, 2.8000, 3.0800, 3.2770
                0.6750, 1.2820, 1.6450, 1.9590, 2.3240, 2.5720, 2.8010, 3.0810, 3.2790
                0.6750, 1.2820, 1.6450, 1.9590, 2.3240, 2.5720, 2.8020, 3.0820, 3.2800
                0.6750, 1.2820, 1.6450, 1.9590, 2.3240, 2.5730, 2.8020, 3.0830, 3.2820
                0.6750, 1.2820, 1.6450, 1.9590, 2.3250, 2.5730, 2.8030, 3.0840, 3.2820
                0.6750, 1.2820, 1.6450, 1.9600, 2.3250, 2.5740, 2.8040, 3.0860, 3.2850
                0.6747, 1.2818, 1.6449, 1.9598, 2.3256, 2.5747, 2.8053, 3.0877, 3.2873
        ];
    end
    
    row = find(nPoints <= counts, 1);
    if isempty(row)
        row = 1;
    end
    column = find(u <= data(row, :), 1);
    if isempty(column)
        column = numel(alphas);
    end
    pValue = alphas(column);
end