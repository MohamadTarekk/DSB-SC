function [file, y, Fs] = readFile()
[file,path] = uigetfile({'*.wav'},'Selec a wav file');
if ~isequal(file,0)
    file_path = fullfile(path,file);
else
    file = 0;
    y = 0;
    Fs = 0;
    return;
end
[y, Fs] = audioread(file_path);
end