% Initialize DAQ and GUI
initializeDAQRecording(params, daqLickSample);
guiHandles = lickResponseMonitorGUI(params.numTrials);

% Initialize histories
correctLeftHistory = [];
correctRightHistory = [];
noResponseHistory = [];
trialNumbers = [];
completedTrials = 0;

% Main trial loop
for trial = 1:params.numTrials
    disp(['Trial ', num2str(trial), ' of ', num2str(params.numTrials)]);

    [toneFreq, isTest] = selectToneFreq(params, params.leftToneFreq, params.rightToneFreq);
    toneSignal = generateTone(toneFreq, samples, daqObjClocked.Rate, params.amplitude);
    [expectedPin, unexpectedPin] = getExpectedPin(toneFreq, params.cutOffFrequency);

    onsetTime = datetime('now');
    absoluteTime = seconds(onsetTime - datetime('today'));

    disp('Tone playing:');
    disp(toneFreq);
    write(daqObjClocked, toneSignal');

    trialDelay = rand * diff(params.trialDelayRange) + params.trialDelayRange(1);
    lockoutDuration = rand * diff(params.lockoutDurationRange) + params.lockoutDurationRange(1);

    [responseRow, isCorrect, isIncorrect] = runResponseLoop(daqObjInput, daqObjOutput, ...
        expectedPin, unexpectedPin, params.responseTime, lockoutDuration, ...
        params.dispenseDuration, trialDelay, toneFreq, isTest, absoluteTime);

    responseMatrix(trial, :) = responseRow;

    % Update performance tracking
    completedTrials = completedTrials + 1;
    set(guiHandles.TrialText, 'String', num2str(completedTrials));
    trialNumbers(end+1) = completedTrials;
    [correctLeftHistory, correctRightHistory, noResponseHistory] = ...
        updatePerformanceHistory(responseMatrix, completedTrials, ...
        correctLeftHistory, correctRightHistory, noResponseHistory);

    % Update GUI plots
    set(guiHandles.LeftLine, 'XData', trialNumbers, 'YData', correctLeftHistory);
    set(guiHandles.RightLine, 'XData', trialNumbers, 'YData', correctRightHistory);
    set(guiHandles.NoRespLine, 'XData', trialNumbers, 'YData', noResponseHistory);
end
