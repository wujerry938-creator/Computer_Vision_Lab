clear all;
close all;
clc;

%% Lab 3 Part II: Gaussian Mixture Model

videoFile = 'car-tracking.mp4';

% Parameter sets to test
NumGaussians_list = [2, 3, 5];
NumTrainingFrames_list = [10, 30, 50];
MinimumBackgroundRatio_list = [0.5, 0.7, 0.9];

caseID = 0;

for ng = NumGaussians_list

    for nt = NumTrainingFrames_list

        for mbr = MinimumBackgroundRatio_list

            caseID = caseID + 1;

            source = VideoReader(videoFile);

            detector = vision.ForegroundDetector( ...
                'NumGaussians', ng, ...
                'NumTrainingFrames', nt, ...
                'MinimumBackgroundRatio', mbr);

            outputName = sprintf('GMM_case%d_NG%d_NT%d_MBR%.1f.mp4', ...
                                 caseID, ng, nt, mbr);

            output = VideoWriter(outputName, 'MPEG-4');
            open(output);

            frameCount = 0;

            while hasFrame(source)

                frameCount = frameCount + 1;

                frame = readFrame(source);

                % Apply GMM foreground detector
                fgMask = step(detector, frame);

                % Optional: remove noise
                fgMask = bwareaopen(fgMask, 30);
                fgMask = imclose(fgMask, strel('rectangle', [3,3]));

                fg = uint8(fgMask) * 255;

                % Display selected frames
                if frameCount == 20 || frameCount == 50 || frameCount == 80

                    figure;
                    subplot(1,2,1), imshow(frame), title('Original Frame');
                    subplot(1,2,2), imshow(fgMask), ...
                        title(sprintf('GMM: NG=%d, NT=%d, MBR=%.1f', ng, nt, mbr));

                    saveas(gcf, sprintf('GMM_case%d_Frame%d.png', caseID, frameCount));
                end

                writeVideo(output, fg);

            end

            close(output);

        end

    end

end