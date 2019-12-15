function [demodulatedSignalSpectrum , demodulatedSignal] = demodulate(signal, carrierFs, fs, fc, phase, snr)

% add noise to modulated to signal (channel noise simulation)
receivedSignal = awgn(signal, snr);
% generate carrier
vectorLength = length(receivedSignal);
time = linspace(0, vectorLength/carrierFs, vectorLength).';
carrier = cos(2*pi*fc*time + phase*pi/180);
% demodulate
detectedSignal = receivedSignal .* carrier;
[demodulatedSignalSpectrum , demodulatedSignal] = filterSignal(detectedSignal, fs);
% filter
demodulatedSignal = resample(demodulatedSignal, fs, carrierFs);

end