url = 'https://ssd.mathworks.com/supportfiles/audio/google_speech.zip';
downloadFolder = 'D:\';
dataFolder = fullfile(downloadFolder,'google_speech');

if ~exist(dataFolder,'dir')
    disp('Downloading data set (1.4 GB) ...')
    unzip(url,downloadFolder)
end