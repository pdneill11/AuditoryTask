% Define the digital input, digital output, and analog output channels
device = 'Dev2'; %Specify location of DAQ device

lickleftPin = 'Port0/Line0';    % Specify the digital input pin for left lick port
lickrightPin = 'Port0/Line1';   % Specify the digital input pin for right lick port
dispenseleftPin = 'Port0/Line2';  % Specify the digital output pin for dispense left
dispenserightPin = 'Port0/Line3'; % Specify the digital output pin for dispense right
speakerPin = 'ao0';             % Specify the analog output channel for the speaker
voltagePin = 'ai0';

% Create two DataAcquisition objects
daqLickSample = daq('ni'); %For clocked operations (lick sampling)
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
daqLickSample.Rate = 1000; % Lick sampling rate in Hz (samples per second)
daqObjClocked.Rate = 250000; % Sound sampling rate in Hz (samples per second)

completedTrials = 0;
function params = ParameterInputGUI()
    % Default values
    defaultAnimal = 'M1';
    defaultDate = 'MM_DD_YYYY';
    defaultSession = 'Session_1';
    defaultFrequencies = '11.3, 13, 14.9, 17.1, 19.7, 22.6';
    defaultProbability = '0';
    defaultDispenseDuration = '0.2';
    defaultResponseTime = '3';
    defaultNumTrials = '100';
    defaultTrialDelayRange = '0.5, 2';
    defaultLockoutRange = '2, 4';
    defaultCutoff = '16000';
    defaultLeftTone = '8000';
    defaultRightTone = '32000';
    defaultToneDuration = '1';
    defaultAmplitude = '1';

    % Create the GUI figure
    hFig = figure('Name','Experiment Parameter Input', ...
                  'NumberTitle','off', ...
                  'Position',[400, 100, 500, 700], ...
                  'MenuBar','none', ...
                  'Resize','off');

    % Function to create labels and fields
    function [hField] = makeField(label, posY, defaultVal)
        uicontrol(hFig, 'Style', 'text', 'String', [label ':'], ...
                  'Position', [30, posY, 180, 20], ...
                  'HorizontalAlignment', 'right');
        hField = uicontrol(hFig, 'Style', 'edit', 'String', defaultVal, ...
                  'Position', [220, posY, 230, 25]);
    end

    posY = 650;
    step = 35;
    hAnimal     = makeField('Animal', posY, defaultAnimal);        posY = posY - step;
    hDate       = makeField('Date (MM_DD_YYYY)', posY, defaultDate); posY = posY - step;
    hSession    = makeField('Session', posY, defaultSession);       posY = posY - step;
    hFreq       = makeField('Test Frequencies (kHz)', posY, defaultFrequencies); posY = posY - step;
    hProb       = makeField('Test Trial Probability', posY, defaultProbability); posY = posY - step;

    hDispense   = makeField('Dispense Duration (s)', posY, defaultDispenseDuration); posY = posY - step;
    hResponse   = makeField('Response Time (s)', posY, defaultResponseTime);         posY = posY - step;
    hTrials     = makeField('Number of Trials', posY, defaultNumTrials);             posY = posY - step;
    hTrialDelay = makeField('Trial Delay Range (s)', posY, defaultTrialDelayRange);  posY = posY - step;
    hLockout    = makeField('Lockout Duration Range (s)', posY, defaultLockoutRange);posY = posY - step;
    hCutoff     = makeField('Cutoff Frequency (Hz)', posY, defaultCutoff);           posY = posY - step;

    hLeftTone   = makeField('Left Tone Frequency (Hz)', posY, defaultLeftTone);      posY = posY - step;
    hRightTone  = makeField('Right Tone Frequency (Hz)', posY, defaultRightTone);    posY = posY - step;
    hToneDur    = makeField('Tone Duration (s)', posY, defaultToneDuration);         posY = posY - step;
    hAmp        = makeField('Amplitude', posY, defaultAmplitude);                    posY = posY - step;

    % Submit button
    uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Submit', ...
              'Position', [200, 20, 100, 40], ...
              'Callback', @submitCallback);

    uiwait(hFig);  % Wait for user to press Submit

    function submitCallback(~, ~)
        params.Animal = get(hAnimal, 'String');
        params.Date = get(hDate, 'String');
        params.Session = get(hSession, 'String');

        params.testFrequencies = str2num(get(hFreq, 'String')) * 1000; %#ok<ST2NM>
        params.testTrialProbability = str2double(get(hProb, 'String'));

        params.dispenseDuration = str2double(get(hDispense, 'String'));
        params.responseTime = str2double(get(hResponse, 'String'));
        params.numTrials = str2double(get(hTrials, 'String'));
        params.trialDelayRange = str2num(get(hTrialDelay, 'String')); %#ok<ST2NM>
        params.lockoutDurationRange = str2num(get(hLockout, 'String')); %#ok<ST2NM>
        params.cutOffFrequency = str2double(get(hCutoff, 'String'));

        params.leftToneFreq = str2double(get(hLeftTone, 'String'));
        params.rightToneFreq = str2double(get(hRightTone, 'String'));
        params.toneDuration = str2double(get(hToneDur, 'String'));
        params.amplitude = str2double(get(hAmp, 'String'));

        % Compose file path
        params.fileLocation = "Z:\pdneill\MATLAB Code\Auditory Task\Data\" + params.Animal + "\";
        params.fileName = params.Date + "_" + params.Session + "_Test_VoltageSignal.tdms";

        uiresume(hFig);
        close(hFig);
    end
end


params = ParameterInputGUI();

samples = daqObjClocked.Rate * params.toneDuration;

% Preallocate response matrix
responseMatrix = nan(params.numTrials, 11);

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