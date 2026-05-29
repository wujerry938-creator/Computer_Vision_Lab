clear all;
close all;
clc;

%% ================================
% Lab 2: Red Square Tracking + RMSE
% Optical Flow Method
% ================================

%% 1. Read video and ground truth
videoFile = 'red_square_video.mp4';
gtFile = 'new_red_square_gt.mat';

videoReader = VideoReader(videoFile);

load(gtFile);

% Check variable names in the .mat file
whos

% If your ground truth variable has a different name,
% change this line after checking "whos"
gt = ground_truth_track_spatial_coordinates;

%% 2. Initialise optical flow
opticFlow = opticalFlowLK('NoiseThreshold', 0.009);

%% 3. Read first frame
frameRGB = readFrame(videoReader);
frameGray = rgb2gray(frameRGB);

% Initialise optical flow object
flow = estimateFlow(opticFlow, frameGray);

%% 4. Detect corners in first frame
corners = corner(frameGray, 20);

figure;
imshow(frameRGB);
hold on;
plot(corners(:,1), corners(:,2), 'r*');
title('Detected Corners in First Frame');
hold off;

%% 5. Select initial point
% Recommended: use the top-left corner of red square manually if needed.
% Here we use the nearest detected corner to the first ground truth point.

initial_gt = gt(1,:);

distances = sqrt((corners(:,1) - initial_gt(1)).^2 + ...
                 (corners(:,2) - initial_gt(2)).^2);

[~, idx] = min(distances);
initial_point = corners(idx,:);

track = initial_point;

%% 6. Tracking loop
while hasFrame(videoReader)

    frameRGB = readFrame(videoReader);
    frameGray = rgb2gray(frameRGB);

    % Estimate optical flow between current and previous frame
    flow = estimateFlow(opticFlow, frameGray);

    % Detect corner points in current frame
    corners = corner(frameGray, 20);

    % Previous estimated point
    prev_point = track(end,:);

    % Find nearest corner point to previous estimated position
    distances = sqrt((corners(:,1) - prev_point(1)).^2 + ...
                     (corners(:,2) - prev_point(2)).^2);

    [~, idx] = min(distances);
    nearest_corner = corners(idx,:);

    corner_x = nearest_corner(1);
    corner_y = nearest_corner(2);

    % Avoid index out of boundary
    corner_x_round = round(corner_x);
    corner_y_round = round(corner_y);

    corner_x_round = max(1, min(corner_x_round, size(flow.Vx,2)));
    corner_y_round = max(1, min(corner_y_round, size(flow.Vx,1)));

    % Update position using optical flow
    x_new = corner_x + flow.Vx(corner_y_round, corner_x_round);
    y_new = corner_y + flow.Vy(corner_y_round, corner_x_round);

    track = [track; x_new, y_new];

end

%% 7. Match trajectory length with ground truth
n = min(size(track,1), size(gt,1));

track = track(1:n,:);
gt = gt(1:n,:);

%% 8. Plot estimated trajectory and ground truth
figure;
imshow(frameRGB);
hold on;
plot(track(:,1), track(:,2), 'r-', 'LineWidth', 2);
plot(gt(:,1), gt(:,2), 'g--', 'LineWidth', 2);
plot(track(1,1), track(1,2), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
plot(gt(1,1), gt(1,2), 'go', 'MarkerSize', 8, 'LineWidth', 2);
legend('Estimated Trajectory', 'Ground Truth', ...
       'Estimated Start', 'GT Start');
title('Estimated Trajectory vs Ground Truth');
hold off;

%% 9. Calculate RMSE for each frame
error_x = gt(:,1) - track(:,1);
error_y = gt(:,2) - track(:,2);

rmse_x = sqrt(error_x.^2);
rmse_y = sqrt(error_y.^2);
rmse_xy = sqrt(error_x.^2 + error_y.^2);

avg_rmse_x = mean(rmse_x);
avg_rmse_y = mean(rmse_y);
avg_rmse_xy = mean(rmse_xy);

fprintf('\n===== Average RMSE Results =====\n');
fprintf('Average RMSE X  = %.4f pixels\n', avg_rmse_x);
fprintf('Average RMSE Y  = %.4f pixels\n', avg_rmse_y);
fprintf('Average RMSE XY = %.4f pixels\n', avg_rmse_xy);

%% 10. Plot RMSE results
frames = 1:n;

figure;
plot(frames, rmse_x, 'LineWidth', 1.5);
xlabel('Frame');
ylabel('RMSE X (pixels)');
title('RMSE of X Coordinate over Frames');
grid on;

figure;
plot(frames, rmse_y, 'LineWidth', 1.5);
xlabel('Frame');
ylabel('RMSE Y (pixels)');
title('RMSE of Y Coordinate over Frames');
grid on;

figure;
plot(frames, rmse_xy, 'LineWidth', 1.5);
xlabel('Frame');
ylabel('Combined RMSE XY (pixels)');
title('Combined RMSE over Frames');
grid on;