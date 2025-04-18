% NI-DAQ Configuration
device = 'Dev4';  % Change to your actual NIDAQ device name
aoChannel = 'ao0'; % Analog output channel (adjust if needed)

% Initialize DAQ object
daqObjClocked = daq('ni');
addoutput(daqObjClocked, device, aoChannel, 'Voltage');

% Set the sampling rate and other parameters
fs = 250000;  % Sampling frequency (samples per second)
freq = 8000;  % Frequency of sine wave (1 kHz)
duration = 5; % Duration of the signal in seconds
samples = fs * duration; % Total number of samples (should be 250,000 for 1 second)

% Set the rate of the DAQ object
daqObjClocked.Rate = fs;  % Set DAQ sampling rate to match fs

% Time vector and sine wave generation
t = (0:samples-1) / fs;  % Time vector for 1 second
sineWave = 5*sin(2 * pi * freq * t);  % Generate sine wave with 1 kHz frequency

% Write the sine wave to the DAQ output
write(daqObjClocked, sineWave');  % Sine wave is transposed to match the format (column vector)

% Start the output generation
start(daqObjClocked);

% Wait for the duration before stopping
%pause(duration);  % Ensure the sine wave plays for exactly 1 second

% Stop the DAQ device
stop(daqObjClocked);
