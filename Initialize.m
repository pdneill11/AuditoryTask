% Define the digital input, digital output, and analog output channels
device = 'Dev2'; %Specify location of DAQ device

lickleftPin = 'Port0/Line0';    % Specify the digital input pin for left lick port
lickrightPin = 'Port0/Line1';   % Specify the digital input pin for right lick port
dispenseleftPin = 'Port0/Line2';  % Specify the digital output pin for dispense left
dispenserightPin = 'Port0/Line3'; % Specify the digital output pin for dispense right
speakerPin = 'ao0';             % Specify the analog output channel for the speaker
voltagePin = 'ai0';

% Define parameters
dispenseDuration = 1; % Dispense duration (in seconds)
prepareLick = 1; % Dispense time to prepare solenoid valves (in seconds)
responseTime = 3; % Allowed response time in seconds
numTrials = 5; % Set number of total trials
trialDelayRange = [0.5, 2]; % Trial delay between 500 and 2000ms
lockoutDurationRange = [2, 4]; % Lockout duration between 2000 and 4000ms
cutOffFrequency = 16000; % Cutoff frequency for correct response (left or right)

% Define tone frequencies, duration, and volume
fs = 250000;  % Sampling frequency (samples per second)
leftToneFreq = 8000;   % Frequency in Hz for the left tone (e.g., 8 kHz)
rightToneFreq = 32000; % Frequency in Hz for the right tone (e.g., 32 kHz)
toneDuration = 1;    % Duration in seconds
samples = fs * toneDuration; % Total number of samples
amplitude = 10;   % Adjusts volume of tone

% Create two DataAcquisition objects
daqLickSample=daq('ni');
daqObjClocked = daq('ni'); % For clocked operations (tone generation)
daqObjInput = daq('ni');  % For on-demand operations (digital I)
daqObjOutput = daq('ni');  % For on-demand operations (digital O)

% Add analog input channel for the lick detection to the clocked object
addinput(daqLickSample, device, voltagePin,'Voltage');

% Add analog output channel for the speaker to the clocked object
addoutput(daqObjClocked, device, speakerPin, 'Voltage');

% Add digital input channels for lick ports to the on-demand object
addinput(daqObjInput, device, lickleftPin, 'Digital');
addinput(daqObjInput, device, lickrightPin, 'Digital');

% Add digital output channels for left and right dispensers to the on-demand object
addoutput(daqObjOutput, device, dispenseleftPin, 'Digital');
addoutput(daqObjOutput, device, dispenserightPin, 'Digital');

% Set the clocked rate for the lick recording and tone generation
daqLickSample.Rate = 1000; % Sampling rate in Hz (samples per second)
daqObjClocked.Rate = fs;

% Preallocate response matrix
responseMatrix = nan(numTrials, 11);

% Define labels for the responseMatrix columns
responseMatrixLabels = {
    'Correct Response', ...
    'Incorrect Response', ...
    'No Response', ...
    'Expected', ...
    'Response Time (s)', ...
    'Trial Type (0 = Train, 1 = Test)', ...
    'Tone Frequency (Hz)', ...
    'Trial Delay (s)', ...
    'Lockout Duration (s)', ...
    'Lockout Violations', ...
    'Absolute Time (s)'};

completedTrials = 0;




% Run water through solenoid valve to prevent dry-runs

write(daqObjOutput, [1, 1]);
pause(prepareLick);
write(daqObjOutput, [0, 0]);
pause(0.1);