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
lockoutDurationRange = [2, 4]; % Lockout duration between 2000 and 4000ms
cutOffFrequency = 16000; % Cutoff frequency for correct response (left or right)

% Define tone frequencies, duration, and volume
leftToneFreq = 8000;   % Frequency in Hz for the left tone (e.g., 8 kHz)
rightToneFreq = 32000; % Frequency in Hz for the right tone (e.g., 32 kHz)
toneDuration = 0.3;    % Duration in seconds
leftAmplitude = 1;   % Adjusts volume of left tone
rightAmplitude = 1;  % Adjusts volume of right tone
testFrequencies = [11.3, 13, 14.9, 17.1, 19.7, 22.6] * 1000;  % Test frequencies in Hz
testTrialProbability = 0.3;  % 30% of trials are test trials

% Create two DataAcquisition objects
daqObjClocked = daq('ni'); % For clocked operations (tone generation)
daqObjDemand = daq('ni');  % For on-demand operations (digital IO)

% Add digital input channels for lick ports to the on-demand object
addinput(daqObjDemand, 'Dev1', lickleftPin, 'Digital');
addinput(daqObjDemand, 'Dev1', lickrightPin, 'Digital');

% Add digital output channels for left and right dispensers to the on-demand object
addoutput(daqObjDemand, 'Dev1', dispenseleftPin, 'Digital');
addoutput(daqObjDemand, 'Dev1', dispenserightPin, 'Digital');

% Add analog output channel for the speaker to the clocked object
addoutput(daqObjClocked, 'Dev1', speakerPin, 'Voltage');

% Set the clocked rate for the tone generation
daqObjClocked.Rate = 10000;

% Generate time vector for the tones
time = linspace(0, toneDuration, daqObjClocked.Rate * toneDuration)';

% Preallocate response matrix
responseMatrix = nan(numTrials, 10);

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
    'Absolute Time (s)'
};

completedTrials = 0;

% Main trial loop
for trial = 1:numTrials
    disp(['Trial ', num2str(trial), ' of ', num2str(numTrials)]);
    
    % Randomly select test or train trial
    isTestTrial = rand <= testTrialProbability;
    if isTestTrial
        toneFreq = testFrequencies(randi(length(testFrequencies)));
        responseMatrix(trial, 5) = 1; % Mark as test trial
    else
        if rand > 0.5
            toneFreq = leftToneFreq;
        else
            toneFreq = rightToneFreq;
        end
        responseMatrix(trial, 5) = 0; % Mark as train trial
    end
    
    % Generate the tone signal
    toneSignal = sin(2 * pi * toneFreq * time);

    % Determine correct pin based on tone frequency
    if toneFreq < cutOffFrequency
        expectedPin = 1;  % Left pin is correct
        unexpectedPin = 2;  % Right pin is incorrect
    else
        expectedPin = 2;  % Right pin is correct
        unexpectedPin = 1;  % Left pin is incorrect
    end
    
    % Output the tone to the speaker using the clocked object
    preload(daqObjClocked, toneSignal);
    start(daqObjClocked);
    disp('Tone played');
    
    % Wait for the tone duration to elapse
    pause(toneDuration);
    stop(daqObjClocked);
    
    % Capture the system time at the onset of the tone
    onsetTime = datetime('now');
    absoluteTime = seconds(onsetTime - datetime('today'));

    % Start response period
    responseStartTime = tic;
    
    % Initialize response tracking
    responseDetected = false;
    incorrectResponse = false;
    lockoutViolations = 0;

    % Randomize trial delay and lockout duration
    trialDelay = rand * diff(trialDelayRange) + trialDelayRange(1);
    lockoutDuration = rand * diff(lockoutDurationRange) + lockoutDurationRange(1);

    % Allow time responseTime for a response
    while toc(responseStartTime) < responseTime
        % Read the current state of digital inputs
        inputVals = read(daqObjDemand, "OutputFormat", "Matrix");

        % Check for correct or incorrect response
        if inputVals(1, expectedPin) == 1
            responseDetected = true;
            responseTime = toc(responseStartTime);
            
            % Dispense reward for correct response
            if expectedPin == 1
                write(daqObjDemand, [1, 0]);
            else
                write(daqObjDemand, [0, 1]);
            end
            pause(dispenseDuration);
            write(daqObjDemand, [0, 0]);

            % Record correct response
            responseMatrix(trial, :) = [1, 0, 0, responseTime, responseMatrix(trial, 5), toneFreq, trialDelay, lockoutDuration, lockoutViolations, absoluteTime];
            completedTrials = completedTrials + 1;
            break;
        elseif inputVals(1, unexpectedPin) == 1
            incorrectResponse = true;
            responseTime = toc(responseStartTime);
            lockoutViolations = lockoutViolations + 1;

            % Dispense penalty for incorrect response
            if expectedPin == 1
                write(daqObjDemand, [0, 1]);
            else
                write(daqObjDemand, [1, 0]);
            end
            pause(dispenseDuration);
            write(daqObjDemand, [0, 0]);

            % Start lockout period
            lockoutStartTime = tic;
            while toc(lockoutStartTime) < lockoutDuration
                inputVals = read(daqObjDemand, "OutputFormat", "Matrix");
                if inputVals(1, unexpectedPin) == 1
                    lockoutStartTime = tic;
                    lockoutViolations = lockoutViolations + 1;
                end
            end

            % Record incorrect response
            responseMatrix(trial, :) = [0, 1, 0, responseTime, responseMatrix(trial, 5), toneFreq, trialDelay, lockoutDuration, lockoutViolations, absoluteTime];
            completedTrials = completedTrials + 1;
            break;
        end
    end

    % No response
    if ~responseDetected && ~incorrectResponse
        responseMatrix(trial, :) = [0, 0, 1, NaN, responseMatrix(trial, 5), toneFreq, trialDelay, lockoutDuration, lockoutViolations, absoluteTime];
    end
    
    % Pause for randomized trial delay
    pause(trialDelay);
end

% Trim response matrix
responseMatrix = responseMatrix(1:completedTrials, :);

% Display the final response matrix and labels
disp('All trials finished');
disp(responseMatrixLabels);
disp(responseMatrix);
