clc,clear,close all

%% Load the pre-trained network.
load('commandNet.mat')

%% Load a short speech signal where a person says "stop".
 [x,fs] = audioread('stop_command.flac');
 

%%
% Use the function |extractAuditoryFeature| to compute the auditory
% spectrogram. You will go through the details of feature extraction later
% in the example.
auditorySpect = helperExtractAuditoryFeatures(x,fs);

%%
% Classify the command based on its auditory spectrogram.
command = classify(trainedNet,auditorySpect);

%%
% Load the speech signal and listen to it.
x = audioread('play_command.flac');

%% Compute the auditory spectrogram.
auditorySpect = helperExtractAuditoryFeatures(x,fs);

%% Classify the signal.
command = classify(trainedNet,auditorySpect);

%% Create a one-second signal consisting of random noise.
x = pinknoise(16e3);

%% Compute the auditory spectrogram.
auditorySpect = helperExtractAuditoryFeatures(x,fs);

%% Classify the background noise.
command = classify(trainedNet,auditorySpect)

%% Detect Commands Using Streaming Audio from Microphone
% Test your pre-trained command detection network on streaming audio from
% your microphone. Try saying one of the commands, for example, _yes_,
% _no_, or _stop_. Then, try saying one of the unknown words such as
% _Marvin_, _Sheila_, _bed_, _house_, _cat_, _bird_, or any number from
% zero to nine.
%
% Specify the classification rate in Hz and create an audio device reader
% that can read audio from your microphone.

classificationRate = 20;
adr = audioDeviceReader('SampleRate',fs,'SamplesPerFrame',floor(fs/classificationRate));

%%
% Initialize a buffer for the audio. Extract the classification labels of
% the network. Initialize buffers of half a second for the labels and
% classification probabilities of the streaming audio. Use these buffers to
% compare the classification results over a longer period of time and by
% that build 'agreement' over when a command is detected. Specify
% thresholds for the decision logic.

audioBuffer = dsp.AsyncBuffer(fs);

labels = trainedNet.Layers(end).Classes;
YBuffer(1:classificationRate/2) = categorical("background");

probBuffer = zeros([numel(labels),classificationRate/2]);

countThreshold = ceil(classificationRate*0.2);
probThreshold = 0.7;

%%
% Create a figure and detect commands as long as the created figure exists.
% To run the loop indefinitely, set |timeLimit| to |Inf|. To stop the live
% detection, simply close the figure.

h = figure('Units','normalized','Position',[0.2 0.1 0.6 0.8]);

timeLimit = Inf;

u1=udp('192.168.43.157','RemotePort',25001);%设置将数据发送
u2=udp('192.168.43.157','RemotePort',25002);%设置将数据发送
data_send_pre = 5;
%fopen(u1);
tic
while ishandle(h) && toc < timeLimit
    
    % Extract audio samples from the audio device and add the samples to
    % the buffer.
    x = adr();
    write(audioBuffer,x);
    y = read(audioBuffer,fs,fs-adr.SamplesPerFrame);
    
    spec = helperExtractAuditoryFeatures(y,fs);
    
    % Classify the current spectrogram, save the label to the label buffer,
    % and save the predicted probabilities to the probability buffer.
    [YPredicted,probs] = classify(trainedNet,spec,'ExecutionEnvironment','cpu');
    YBuffer = [YBuffer(2:end),YPredicted];
    probBuffer = [probBuffer(:,2:end),probs(:)];
    
    % Plot the current waveform and spectrogram.
    subplot(2,1,1)
    plot(y)
    axis tight
    ylim([-1,1])
    
    subplot(2,1,2)
    pcolor(spec')
    caxis([-4 2.6445])
    shading flat
    
    % Now do the actual command detection by performing a very simple
    % thresholding operation. Declare a detection and display it in the
    % figure title if all of the following hold: 1) The most common label
    % is not background. 2) At least countThreshold of the latest frame
    % labels agree. 3) The maximum probability of the predicted label is at
    % least probThreshold. Otherwise, do not declare a detection.
    [YMode,count] = mode(YBuffer);
    
    maxProb = max(probBuffer(labels == YMode,:));
    subplot(2,1,1)
    if YMode == "background" || count < countThreshold || maxProb < probThreshold
        title(" ")
        data_send=5;
    else
        title(string(YMode),'FontSize',20)
        data_send=5;
        if YMode == "stop"
            data_send=0
        end
        if YMode == "go"
            data_send=1
        end
        if YMode == "left"
            data_send=2
        end
        if YMode == "right"
            data_send=3
        end
        if YMode == "down"
            data_send=4
        end

    end
    if data_send~=5 && data_send_pre~=data_send
        
        fopen(u1);
        fwrite(u1,data_send,'int8');%往端口写入数据，指定端口，数据，格式
        fclose(u1);%关闭端口
    
    end
    data_send
    fopen(u2);
    fwrite(u2,data_send,'int8');%往端口写入数据，指定端口，数据，格式
    fclose(u2);%关闭端口
    data_send_pre = data_send;
    drawnow
    %pause(0.5);%每5秒发一次
end
%fclose(u1);%关闭端口
delete(u1);%删除端口
 
clear u1;%清理缓存
delete(u2);%删除端口
 
clear u2;%清理缓存
