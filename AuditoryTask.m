%Auditory task in which each sound corresponds to one lick port

% Define the digital input, digital output, and analog output channels
lickleftPin = 'Port0/Line0';    % Specify the digital input pin for left lick port
lickrightPin = 'Port0/Line1';   % Specify the digital input pin for right lick port

dispenseleftPin = 'Port0/Line2';  % Specify the digital output pin for dispense left
dispenserightPin = 'Port0/Line3'; % Specify the digital output pin for dispense right

speakerPin = 'ao0';             % Specify the analog output channel for the speaker

% Define parameters
X = 1; % Dispense duration in seconds
Y = 3; % Allowed response time in seconds
lockoutDuration = 10; % Duration in seconds for the lockout period after an incorrect response
totalTrials = 500; % Total number of trials

% Define tone frequencies and duration
leftToneFreq = 3000;   % Frequency in Hz for the left tone (e.g., 3 kHz)
rightToneFreq = 12000; % Frequency in Hz for the right tone (e.g., 12 kHz)
toneDuration = 1;    % Duration in seconds

% Define the maximum amplitude for the tone
maxAmplitude = 5; % Set to the desired amplitude, e.g., 5V if your output range is ±10V

% Create two DataAcquisition objects
daqObjClocked = daq("ni");
daqObjDemand = daq('ni');

% Add digital input channels for lick ports
addinput(daqObjDemand, 'Dev1', lickleftPin, 'Digital');
addinput(daqObjDemand, 'Dev1', lickrightPin, 'Digital');

% Add digital output channels for left and right dispensers
addoutput(daqObjDemand, 'Dev1', dispenseleftPin, 'Digital');
addoutput(daqObjDemand, 'Dev1', dispenserightPin, 'Digital');

% Add analog output channel for the speaker
addoutput(daqObjClocked, 'Dev1', speakerPin, 'Voltage');
daqObjClocked.Rate = 10000;  % Set the sample rate for the clocked output

% Calculate the total number of samples needed for the tone
numSamples = daqObjClocked.Rate * toneDuration;

% Generate time vector
time = linspace(0, toneDuration, numSamples)';

% Generate the output signals for both tones (left and right) with increased amplitude
leftToneSignal = maxAmplitude * sin(2 * pi * leftToneFreq * time);
rightToneSignal = maxAmplitude * sin(2 * pi * rightToneFreq * time);

% Initialize the response matrix
% Columns: [Correct, Incorrect, No Response]
responseMatrix = zeros(totalTrials, 3);

for trial = 1:totalTrials
    % Randomly select between left and right tone
    if rand > 0.5
        toneSignal = leftToneSignal;
        expectedPinIndex = 1;  % Index corresponding to lickleftPin
        disp('Playing left tone...');
    else
        toneSignal = rightToneSignal;
        expectedPinIndex = 2;  % Index corresponding to lickrightPin
        disp('Playing right tone...');
    end

    % Output the tone to the speaker
    preload(daqObjClocked, toneSignal);
    start(daqObjClocked, "continuous");
    disp('Tone playing...');
    
    % Allow the tone to play for the entire duration
    pause(toneDuration);
    
    % Stop the clocked output after the tone duration
    stop(daqObjClocked);
    disp('Tone finished');

    % Allow time Y for a response
    responseDetected = false;
    incorrectResponse = false;
    startTime = tic;
    
    while toc(startTime) < Y
        % Read the current state of digital inputs
        inputVals = read(daqObjDemand, "OutputFormat", "Matrix");
    
        % Check if the correct input was activated
        if inputVals(1, expectedPinIndex) == 1
            responseDetected = true;
            disp('Correct response detected! Triggering output...');
            
            % Activate the corresponding dispenser
            if expectedPinIndex == 1
                % Activate left dispenser
                write(daqObjDemand, [1, 0]);
            else
                % Activate right dispenser
                write(daqObjDemand, [0, 1]);
            end
    
            % Keep the dispenser active for duration X
            pause(X);
            % Deactivate both dispensers
            write(daqObjDemand, [0, 0]);
            disp('Output deactivated.');
            
            % Log correct response
            responseMatrix(trial, 1) = 1;
            break;
        elseif inputVals(1, 3 - expectedPinIndex) == 1 % The incorrect input was activated
            incorrectResponse = true;
            disp('Incorrect response detected! Entering lockout...');
            % Log incorrect response
            responseMatrix(trial, 2) = 1;
            break;
        end
        
        pause(0.01); % Small delay to avoid excessive CPU usage
    end
    
    % If no response was detected within Y seconds
    if ~responseDetected && ~incorrectResponse
        disp('No response detected within the allowed time.');
        % Log no response
        responseMatrix(trial, 3) = 1;
    elseif incorrectResponse
        % Enter lockout period
        pause(lockoutDuration);
        disp('Lockout period ended.');
    end
    
    pause(1); % Pause before the next trial
end

% Display the response matrix after all trials
disp('Response Matrix:');
disp(responseMatrix);
