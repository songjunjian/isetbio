function [adaptedCur, params] = osAddNoise(curNF, params)
%% Add noise to membrane current in cone adaptataion
%   adaptedCur = osAddNoise(curNF, params)
%
%  Noise in cone adaptation is independent of cone signal. The noise is
%  Gaussian additive and the spectral power distribution can be
%  characterized by the sum of two lorentz function.
%
%  Inputs:
%    curNF  - noise free cone adapted membrane current, see
%             osAdaptTemporal
%    params - parameter structure, could include:
%      .seed     - noise seed
%      .sampTime - sample time interval, see sensorGet(s, 'time interval');
%
%  Outputs:
%    adaptedCur - membrance current with noise added
%
%  Example:
%    params.sampTime = 1/5000;
%    [noise, params] = osAddNoise(zeros(10,10,10000), params);
%    noiseF = squeeze(mean(mean(abs(fft(noise, [], 3)).^2)));
%    vcNewGraphWin; loglog(params.freq, noiseF(1:length(params.freq)));
%    xlabel('Frequency(Hz)'); ylabel('Power Spectrum (pA^2/Hz)'); 
%    xlim([1 1e3]); ylim([1e-4 1]);
%
%  See also:
%    coneAdapt, osAdaptSteadyState, osAdaptTemporal
%
%  (HJ) ISETBIO, 2014

%% Init
if notDefined('curNF'), error('noise-free adapted current required'); end
if notDefined('params'), params = []; end

if isfield(params, 'seed'), rng(params.seed); else params.seed = rng; end
if isfield(params, 'sampTime'), sampTime = params.sampTime;
else sampTime = 0.001; % 1 ms
end

%% Build model and generate noise
%  Make sure curNF is [row, col, time] 3D matrix
if isvector(curNF), curNF = reshape(curNF, [1 1 length(curNF)]); end

if (ndims(curNF) == 3)
    temporalDimIndex = 3;
elseif (ndims(curNF) == 2)
    temporalDimIndex = 2;
end


% Generate the noise according to the noise spectral
% distribution
k = ceil((size(curNF, temporalDimIndex)-1)/2);
params.freq = (0:k)/ sampTime / size(curNF, temporalDimIndex);

LorentzCoeffs = [0.16  55  4;
                 0.045 190 2.5];
noiseSPD = lorentzSum(LorentzCoeffs, params.freq);

% make-up the negative frequency part
noiseSPD = [noiseSPD noiseSPD(end:-1:1)];

noiseSPD = noiseSPD(1:size(curNF, temporalDimIndex));
if (temporalDimIndex == 3)
    noiseSPD = reshape(noiseSPD, [1 1 length(noiseSPD)]);
elseif (temporalDimIndex == 2)
    noiseSPD = reshape(noiseSPD, [1 length(noiseSPD)]);
end
% Have a look at the noise in the frequency domain
% vcNewGraphWin;loglog(squeeze(sqrt(noiseSPD)));

% generate white gaussian noise
noise = randn(size(curNF));
noiseFFT = fft(noise, [], temporalDimIndex); % / sqrt(size(noise, 3));

% adjust the spectral power distribution of the noise
noiseFFT = bsxfun(@times, noiseFFT, sqrt(noiseSPD));

noise = real(ifft(noiseFFT, [], temporalDimIndex)) / sqrt(2*sampTime); % take real part

%figure(2); plot(squeeze(noise));

% add to noise-free signal
adaptedCur = curNF + noise;

end