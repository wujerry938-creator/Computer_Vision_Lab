clear all;
close all;
clc;

%% ================================
% Lab 4: Robot Treasure Hunting
% ================================

imageFiles = {
    'Treasure_medium_case.jpg'
    'Treasure_easy_case.jpg'
    'Treasure hunting - difficult case.jpg'
};

caseNames = {'Easy', 'Medium', 'Difficult'};

for caseID = 1:length(imageFiles)

    %% Read image
    img = imread(imageFiles{caseID});
    figure;
    imshow(img);
    title([caseNames{caseID}, ' Original Image']);

    %% Convert to HSV
    hsvImg = rgb2hsv(img);
    H = hsvImg(:,:,1);
    S = hsvImg(:,:,2);
    V = hsvImg(:,:,3);

    %% Binarisation: detect white arrows and bright objects
    grayImg = rgb2gray(img);
    bin_threshold = 0.20;
    binImg = imbinarize(grayImg, bin_threshold);

    % Remove small noise
    binImg = bwareaopen(binImg, 20);

    figure;
    imshow(binImg);
    title([caseNames{caseID}, ' Binary Image']);
    exportgraphics(gcf, ['lab4_', caseNames{caseID}, '_binary.png'], 'Resolution', 300);

    %% Connected components
    CC = bwconncomp(binImg);
    stats = regionprops(CC, 'Area', 'Centroid', 'BoundingBox', 'PixelIdxList');

    %% Detect red starting arrow
    redMask = (H < 0.05 | H > 0.95) & S > 0.5 & V > 0.4;
    redMask = bwareaopen(redMask, 20);

    redStats = regionprops(redMask, 'Centroid', 'BoundingBox', 'Area');

    if isempty(redStats)
        warning('No red start arrow found in %s', caseNames{caseID});
        continue;
    end

    [~, maxRedIdx] = max([redStats.Area]);
    startPoint = redStats(maxRedIdx).Centroid;

    %% Detect treasures by colour
    % Green clove
    greenMask = H > 0.22 & H < 0.45 & S > 0.35 & V > 0.25;
    greenMask = bwareaopen(greenMask, 30);

    % Orange / yellow sun
    orangeMask = H > 0.04 & H < 0.15 & S > 0.45 & V > 0.45;
    orangeMask = bwareaopen(orangeMask, 30);

    % Gold / yellow treasure
    yellowMask = H > 0.10 & H < 0.18 & S > 0.35 & V > 0.45;
    yellowMask = bwareaopen(yellowMask, 30);

    %% Detect white arrows
    % White arrows are low saturation and high value
    whiteMask = S < 0.25 & V > 0.75;
    whiteMask = bwareaopen(whiteMask, 20);

    CC_arrow = bwconncomp(whiteMask);
    arrowStats = regionprops(CC_arrow, 'Area', 'Centroid', 'BoundingBox', 'PixelIdxList');

    % Filter arrow-like components by area
    arrowCentres = [];
    arrowBoxes = [];

    for i = 1:length(arrowStats)
        area = arrowStats(i).Area;
        box = arrowStats(i).BoundingBox;

        if area > 30 && area < 2000
            arrowCentres = [arrowCentres; arrowStats(i).Centroid];
            arrowBoxes = [arrowBoxes; box];
        end
    end

    %% Build approximate path
    % Start from red arrow. Move to nearest white arrow repeatedly.
    currentPoint = startPoint;
    path = currentPoint;

    used = false(size(arrowCentres,1),1);

    maxSteps = min(40, size(arrowCentres,1));

    for step = 1:maxSteps

        if isempty(arrowCentres)
            break;
        end

        distances = sqrt((arrowCentres(:,1) - currentPoint(1)).^2 + ...
                         (arrowCentres(:,2) - currentPoint(2)).^2);

        distances(used) = inf;

        [minDist, idx] = min(distances);

        if isinf(minDist)
            break;
        end

        nextPoint = arrowCentres(idx,:);
        path = [path; nextPoint];

        used(idx) = true;
        currentPoint = nextPoint;

        % Stop if near a treasure
        if is_near_treasure(currentPoint, greenMask, orangeMask, yellowMask)
            break;
        end

    end

    %% Display result path
    figure;
    imshow(img);
    hold on;

    plot(path(:,1), path(:,2), 'r-o', 'LineWidth', 2, 'MarkerSize', 5);

    % Mark start
    plot(startPoint(1), startPoint(2), 'go', 'MarkerSize', 10, 'LineWidth', 2);

    % Mark treasures
    show_mask_boundary(greenMask, 'g');
    show_mask_boundary(orangeMask, 'y');
    show_mask_boundary(yellowMask, 'c');

    title([caseNames{caseID}, ' Treasure Hunting Path']);
    legend('Robot Path', 'Start Point');

    hold off;

    exportgraphics(gcf, ['lab4_', caseNames{caseID}, '_path.png'], 'Resolution', 300);

end

%% ================================
% Helper function: check treasure distance
% ================================
function flag = is_near_treasure(point, greenMask, orangeMask, yellowMask)

    flag = false;

    masks = {greenMask, orangeMask, yellowMask};

    for k = 1:length(masks)
        mask = masks{k};

        stats = regionprops(mask, 'Centroid', 'Area');

        if isempty(stats)
            continue;
        end

        for i = 1:length(stats)
            if stats(i).Area < 30
                continue;
            end

            c = stats(i).Centroid;
            d = sqrt((point(1)-c(1))^2 + (point(2)-c(2))^2);

            if d < 80
                flag = true;
                return;
            end
        end
    end
end

%% ================================
% Helper function: show mask boundary
% ================================
function show_mask_boundary(mask, colour)

    B = bwboundaries(mask);

    for k = 1:length(B)
        boundary = B{k};

        if size(boundary,1) > 10
            plot(boundary(:,2), boundary(:,1), colour, 'LineWidth', 2);
        end
    end
end