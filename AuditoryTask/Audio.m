% NI-DAQ Configuration
device = 'Dev4';  % Change to your actual NIDAQ device name
aoChannel = 'ao0'; % Analog output channel (adjust if needed)

fs = 250000;   % Sampling rate (Hz)
duration = 2;  % Tone duration (seconds)
f = 100;      % Frequency of sine wave (Hz)
amplitude = 1;

t = 0:1/fs:duration;   % Time vector
y = amplitude * sin(2 * pi * f * t);  % Generate sine wave at full range (+/-10V)

% Create NI-DAQ Analog Output Object
flush(dq);
dq = daq("ni");
addoutput(dq, device, aoChannel, "Voltage");
dq.Rate = 250000;
% Output Data in Chunks to Avoid Buffer Overflows
blockSize = 5000;  % Number of samples per block
%numBlocks = ceil(length(y) / blockSize);

%for i = 1:numBlocks
%    startIdx = (i-1) * blockSize + 1;
%    endIdx = min(i * blockSize, length(y));
%write(dq, y(startIdx:endIdx)'); % Transmit data in small chunks

preload(dq, y);
start(dq, "repeatoutput");
disp('Tone played');

pause(duration);
stop(dq);

% Cleanup
disp('Tone playback complete.');
