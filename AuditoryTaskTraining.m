% Define the digital input, digital output, and analog output channels
lickleftPin = 'Port0/Line0';    % Specify the digital input pin for left lick port
lickrightPin = 'Port0/Line1';   % Specify the digital input pin for right lick port

dispenseleftPin = 'Port0/Line2';  % Specify the digital output pin for dispense left
dispenserightPin = 'Port0/Line3'; % Specify the digital output pin for dispense right

speakerPin = 'ao0';             % Specify the analog output channel for the speaker

% Define parameters
dispenseDuration = 1; % Dispense duration in seconds
responseTime = 3; % Allowed response time in seconds
numTrials = 500; % Set number of total trials
trialDelay = 3; % Delay between trials in seconds

% Define tone frequencies and duration
leftToneFreq = 3000;   % Frequency in Hz for the left tone (e.g., 3 kHz)
rightToneFreq = 12000; % Frequency in Hz for the right tone (e.g., 12 kHz)
toneDuration = 1;    % Duration in seconds

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

% Generate the output signals for both tones (left and right)
leftToneSignal = sin(2 * pi * leftToneFreq * time);
rightToneSignal = sin(2 * pi * rightToneFreq * time);

% Preallocate response matrix: Columns -> [Correct, Incorrect, No Response, Response Time]
responseMatrix = nan(numTrials, 4); % Initialize with NaN values

completedTrials = 0; % Initialize the counter for completed trials

for trial = 1:numTrials
    disp(['Trial ', num2str(trial), ' of ', num2str(numTrials)]);
    
    % Randomly select between left and right tone
    if rand > 0.5
        toneSignal = leftToneSignal;
        expectedPin = 1;  % Index for left lick pin
        unexpectedPin = 2;
        disp('Playing left tone...');
    else
        toneSignal = rightToneSignal;
        expectedPin = 2;  % Index for right lick pin
        unexpectedPin = 1;
        disp('Playing right tone...');
    end

    % Output the tone to the speaker
    preload(daqObjClocked, toneSignal);
    start(daqObjClocked);
    disp('Tone played');
    
    % Wait for the tone duration to elapse
    pause(toneDuration);
    
    % Stop the clocked DataAcquisition object
    stop(daqObjClocked);
    
    % Record the start time of the response period
    responseStartTime = tic;
    
    % Initialize response tracking
    responseDetected = false;
    incorrectResponse = false;
    responseTime = NaN;

    % Allow time responseTime for a response
    startTime = tic;
    
    while toc(startTime) < responseTime
        % Read the current state of digital inputs
        inputVals = read(daqObjDemand, "OutputFormat", "Matrix");
        
        % Check if the correct input was activated
        if inputVals(1, expectedPin) == 1
            responseDetected = true;
            responseTime = toc(responseStartTime);  % Record response time
            disp('Correct response detected! Triggering output...');
            
            % Set the correct digital output high for dispenseDuration
            if expectedPin == 1 
                write(daqObjDemand, [1, 0]);
            else
                write(daqObjDemand, [0, 1]);
            end

            % Deactivate both output pins after the response duration
            pause(dispenseDuration);
            write(daqObjDemand, [0, 0]);
            disp('Output deactivated.');
            
            % Record the correct response
            responseMatrix(trial, :) = [1, 0, 0, responseTime];
            completedTrials = completedTrials + 1;
            break;
        elseif inputVals(1, unexpectedPin) == 1  % The incorrect input was activated
            incorrectResponse = true;
            responseTime = toc(responseStartTime);  % Record response time
            disp('Incorrect response detected! Triggering output...');

            % Set the incorrect digital output high for dispenseDuration
            if expectedPin == 1 
                write(daqObjDemand, [0, 1]);
            else
                write(daqObjDemand, [1, 0]);
            end

            % Deactivate both output pins after the response duration
            pause(dispenseDuration);
            write(daqObjDemand, [0, 0]);
            disp('Output deactivated.');

            responseMatrix(trial, :) = [0, 1, 0, responseTime];  % Record incorrect response
            completedTrials = completedTrials + 1;
            break;
        end
    end
    
    % If no response or incorrect response was detected within responseTime
    if ~responseDetected && ~incorrectResponse
        disp('No response detected within the allowed time.');
        responseMatrix(trial, :) = [0, 0, 1, NaN];  % Record no response
    elseif incorrectResponse
        % Enter lockout period
        pause(lockoutDuration);
        disp('Lockout period ended.');
    end
    
    pause(trialDelay); % Pause before the next trial
end

% Trim the response matrix to include only completed trials
responseMatrix = responseMatrix(1:completedTrials, :);

% Display the final response matrix
disp('All trials finished');
