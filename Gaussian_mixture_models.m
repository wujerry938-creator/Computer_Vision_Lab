clear all
close all  

% read the video
source = VideoReader('car-tracking.mp4');  

% create and open the object to write the results
output = VideoWriter('gmm_output.mp4', 'MPEG-4');
open(output);

% create foreground detector object
n_frames = 10;   % a parameter to vary
n_gaussians = 3;   % a parameter to vary
detector = vision.ForegroundDetector('NumTrainingFrames', n_frames, 'NumGaussians', n_gaussians);

% --------------------- process frames -----------------------------------
% loop all the frames
while hasFrame(source)
    fr = readFrame(source);     % read in frame
    
    fgMask = step(detector, fr);    % compute the foreground mask by Gaussian mixture models
    
    % create frame with foreground detection
    fg = uint8(zeros(size(fr, 1), size(fr, 2)));
    fg(fgMask) = 255;
    
    % visualise the results
    figure(1),subplot(2,1,1), imshow(fr)
    subplot(2,1,2), imshow(fg)
    drawnow
    
    writeVideo(output, fg);           % save frame into the output video
end


close(output); % save video
