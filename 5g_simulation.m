%% 5G Network Simulation
clear; clc; close all;

%% Simulation Parameters
dataRate = 1e9;               % Data rate in bps
bandwidth = 20e6;             % Bandwidth in Hz
numSubcarriers = 1024;        % Number of subcarriers (OFDM)
modulationOrder = 16;         % 16-QAM
numSymbols = 1000;            % Number of OFDM symbols
carrierFrequency = 3.5e9;     % Carrier frequency in Hz (3.5 GHz for 5G)

% Channel parameters
snrRange = 0:5:30;            % Signal-to-Noise Ratio in dB
latencyTarget = 1e-3;         % Target latency in seconds
packetSize = 1500 * 8;        % Packet size in bits (1500 bytes)

%% Generate Random Data
data = randi([0 modulationOrder-1], numSubcarriers * numSymbols, 1);

%% OFDM Modulation
modulatedData = qammod(data, modulationOrder, 'UnitAveragePower', true);
ofdmSymbols = reshape(modulatedData, numSubcarriers, numSymbols);

% IFFT (OFDM Signal Generation)
ofdmTimeDomain = ifft(ofdmSymbols);

%% Channel Modeling
latency = zeros(length(snrRange), 1);
throughput = zeros(length(snrRange), 1);
packetErrorRate = zeros(length(snrRange), 1);

for idx = 1:length(snrRange)
    snr = snrRange(idx);

    % Add noise to the OFDM signal
    noisySignal = awgn(ofdmTimeDomain, snr, 'measured');
    
    % Channel effect (Rayleigh fading)
    h = (randn(size(noisySignal)) + 1j * randn(size(noisySignal))) / sqrt(2);
    receivedSignal = noisySignal .* h;

    % FFT (OFDM Demodulation)
    receivedSymbols = fft(receivedSignal);

    % QAM Demodulation
    demodulatedData = qamdemod(receivedSymbols(:), modulationOrder, 'UnitAveragePower', true);

    % Measure performance metrics
    numErrors = sum(data ~= demodulatedData);
    packetErrorRate(idx) = numErrors / length(data);
    throughput(idx) = (1 - packetErrorRate(idx)) * dataRate;
    latency(idx) = latencyTarget * (1 + packetErrorRate(idx));
end

%% Results
disp('Simulation Results:');
disp('SNR (dB) | Latency (ms) | Throughput (Mbps) | Packet Error Rate');
disp('-------------------------------------------------------------');
for idx = 1:length(snrRange)
    fprintf('%8.1f | %10.3f | %16.3f | %16.4f\n', ...
        snrRange(idx), latency(idx) * 1e3, throughput(idx) / 1e6, packetErrorRate(idx));
end

%% Plot Results
figure;
subplot(3, 1, 1);
plot(snrRange, latency * 1e3, '-o', 'LineWidth', 1.5);
title('Latency vs SNR');
xlabel('SNR (dB)'); ylabel('Latency (ms)');
grid on;

subplot(3, 1, 2);
plot(snrRange, throughput / 1e6, '-s', 'LineWidth', 1.5);
title('Throughput vs SNR');
xlabel('SNR (dB)'); ylabel('Throughput (Mbps)');
grid on;

subplot(3, 1, 3);
semilogy(snrRange, packetErrorRate, '-d', 'LineWidth', 1.5);
title('Packet Error Rate vs SNR');
xlabel('SNR (dB)'); ylabel('Packet Error Rate');
grid on;
