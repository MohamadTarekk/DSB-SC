function [modulatedMessage, carrierFs] = modulate(message, fs, fc)

carrierFs = 5 * fc;
resampledMessage = resample(message, carrierFs, fs);
vectorLength = length(resampledMessage);
time = linspace(0, vectorLength/carrierFs, vectorLength).';
carrier = cos(2 * pi * fc * time);

modulatedMessage = carrier .* resampledMessage;

end