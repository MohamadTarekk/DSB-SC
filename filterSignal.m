function [filteredSignalSpectrum, filteredSignal] = filterSignal(y, Fs)

Y = fftshift(fft(y));

N = length(y);
numberOfOnes = floor(N * 8000 / Fs);
numberOfZeros = floor((N - numberOfOnes) / 2);
remainder = mod((N - numberOfOnes), 2);
rect = ones(numberOfOnes, 1);
filter = padarray(rect, numberOfZeros, 'pre');
filter = padarray(filter, numberOfZeros + remainder, 'post');
filteredSignalSpectrum = filter .* Y;
%{
dF = Fs / N;
freq = -Fs/2:dF:Fs/2-dF;
plot(freq, abs(filteredSignal)/N);
%}
filteredSignal = real(ifft(ifftshift(filteredSignalSpectrum)));

end