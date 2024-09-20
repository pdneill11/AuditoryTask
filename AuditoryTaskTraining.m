% Define the digital input, digital output, and analog output channels
lickleftPin = 'Port0/Line0';    % Specify the digital input pin for left lick port
lickrightPin = 'Port0/Line1';   % Specify the digital input pin for right lick port
dispenseleftPin = 'Port0/Line2';  % Specify the digital output pin for dispense left
dispenserightPin = 'Port0/Line3'; % Specify the digital output pin for dispense right
speakerPin = 'ao0';             % Specify the analog output channel for the speaker

% Define parameters
dispenseDuration = 1; % Dispense duration in seconds
responseTime = 3; % Allowed response time in seconds
numTrials = 400; % Set number of total trials
trialDelayRange = [0.5, 2]; % Trial delay between 500 and 2000ms
lockoutDurationRange = [4, 6]; % Lockout duration between 4000 and 6000ms
cutOffFrequency = 16000; % Cutoff frequency for correct response (left or right)

% Define tone frequencies and duration
leftToneFreq = 8000;   % Frequency in Hz for the left tone (e.g., 8 kHz)
rightToneFreq = 32000; % Frequency in Hz for the right tone (e.g., 32 kHz)
toneDuration = 0.3;    % Duration in seconds
leftAmplitude = 1;   % Adjusts volume of left tone
rightAmplitude = 1;  % Adjusts volume of right tone

% Create DataAcquisition objects
daqObjClocked = daq('ni');
daqObjDemand = daq('ni');

% Add digital input channels for lick ports
addinput(daqObjDemand, 'Dev1', lickleftPin, 'Digital');
addinput(daqObjDemand, 'Dev1', lickrightPin, 'Digital');

% Add digital output channels for left and right dispensers
addoutput(daqObjDemand, 'Dev1', dispenseleftPin, 'Digital');
addoutput(daqObjDemand, 'Dev1', dispenserightPin, 'Digital');

% Add analog output channel for the speaker
addoutput(daqObjClocked, 'Dev1', speakerPin, 'Voltage');
daqObjClocked.Rate = 10000;

% Generate time vector
time = linspace(0, toneDuration, daqObjClocked.Rate * toneDuration)';

% Preallocate response matrix: Columns -> 
% [Correct, Incorrect, No Response, Response Time, Trial Type (0=Train, 1=Test),
%  Tone Frequency, Trial Delay, Lockout Duration, Lockout Violations, Absolute Time]
responseMatrix = nan(numTrials, 10);  % Initialize with NaN values

% Define labels for the responseMatrix columns
responseMatrixLabels = {
    'Correct Response', ...
    'Incorrect Response', ...
    'No Response', ...
    'Response Time (s)', ...
    'Trial Type (0 = Train, 1 = Test)', ...
    'Tone Frequency (Hz)', ...
    'Trial Delay (s)', ...
    'Lockout Duration (s)', ...
    'Lockout Violations', ...
    'Absolute Time (s)'  % Added label for absolute time
};

completedTrials = 0;  % Initialize the counter for completed trials

% Main trial loop
for trial = 1:numTrials
    disp(['Trial ', num2str(trial), ' of ', num2str(numTrials)]);
    
    % Randomly select between leftToneFreq and rightToneFreq with equal probability
    if rand <= 0.5
        toneFreq = leftToneFreq;
        responseMatrix(trial, 5) = 0; % Mark as train trial
        correctPin = 1; % 1 corresponds to lickleftPin
        dispensePin = dispenseleftPin; % Activate dispenseleftPin
        disp('Playing left tone...');
    else
        toneFreq = rightToneFreq;
        responseMatrix(trial, 5) = 0; % Mark as train trial
        correctPin = 2; % 2 corresponds to lickrightPin
        dispensePin = dispenserightPin; % Activate dispenserightPin
        disp('Playing right tone...');
    end
    
    % Generate the tone signal
    toneSignal = sin(2 * pi * toneFreq * time);
    
    % Output the tone to the speaker
    preload(daqObjClocked, toneSignal);
    
    % Capture the system time at the onset of the tone
    onsetTime = datetime('now');
    
    start(daqObjClocked);
    disp('Tone played');
    
    % Wait for the tone duration to elapse
    pause(toneDuration);
    stop(daqObjClocked);
    
    % Convert datetime to seconds since the experiment started
    absoluteTime = seconds(onsetTime - datetime('today'));
    
    % Record the start time of the response period
    responseStartTime = tic;
    
    % Initialize response tracking
    responseDetected = false;
    incorrectResponse = false;
    lockoutViolations = 0;  % Initialize lockout violation counter
    
    % Randomize trial delay and lockout duration for this trial
    trialDelay = rand * diff(trialDelayRange) + trialDelayRange(1);
    lockoutDuration = rand * diff(lockoutDurationRange) + lockoutDurationRange(1);
    
    % Allow up to responseTime for a response
    startTime = tic;
    while toc(startTime) < responseTime
        % Read the current state of digital inputs
        inputVals = read(daqObjDemand, "OutputFormat", "Matrix");
        
        % Check if the correct pin was activated
        if inputVals(1, correctPin) == 1
            responseDetected = true;
            responseTimeElapsed = toc(responseStartTime);  % Record response time
            
            % Dispense reward for correct response
            disp('Correct response detected! Triggering output...');
            if correctPin == 1
                write(daqObjDemand, [1, 0]); % Activate dispenseleftPin
            else
                write(daqObjDemand, [0, 1]); % Activate dispenserightPin
            end
            pause(dispenseDuration);
            write(daqObjDemand, [0, 0]);  % Turn off all dispensers
            
            % Record the correct response
            responseMatrix(trial, :) = [1, 0, 0, responseTimeElapsed, responseMatrix(trial, 5), toneFreq, trialDelay, lockoutDuration, lockoutViolations, absoluteTime];
            completedTrials = completedTrials + 1;
            break;
        end
    end
    
    % If no response is detected within responseTime
    if ~responseDetected
        disp('No response detected within the allowed time.');
        responseMatrix(trial, :) = [0, 0, 1, NaN, responseMatrix(trial, 5), toneFreq, trialDelay, lockoutDuration, lockoutViolations, absoluteTime];
    end
    
    % Pause for randomized trial delay
    pause(trialDelay);
end

% Trim the response matrix to include only completed trials
responseMatrix = responseMatrix(1:completedTrials, :);

% Display the final response matrix and labels
disp('All trials finished');
disp(responseMatrixLabels);
disp(responseMatrix);
