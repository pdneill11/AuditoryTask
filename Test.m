%Initialize and begin recording voltage data
disp("Starting acquisition...");
daqLickSample.LogToDisk = true;
daqLickSample.LogFileName = params.fileLocation + params.fileName;
start(daqLickSample, "Continuous");

% Initialize GUI
guiHandles = LickResponseMonitorGUI(params.numTrials);

% Initialize history arrays
correctLeftHistory = [];
correctRightHistory = [];
noResponseHistory = [];
trialNumbers = [];

% Main trial loop
for trial = 1:params.numTrials
    disp(['Trial ', num2str(trial), ' of ', num2str(params.numTrials)]);
    
    % Randomly select test or train trial
    isTestTrial = rand <= params.testTrialProbability;
    if isTestTrial
        toneFreq = params.testFrequencies(randi(length(params.testFrequencies)));
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
    time = (0:samples-1) / daqObjClocked.Rate;  % Time vector
    toneSignal = params.amplitude*sin(2 * pi * toneFreq * time);

    % Determine correct pin based on tone frequency
    if toneFreq < params.cutOffFrequency
        expectedPin = 1;  % Left pin is correct
        unexpectedPin = 2;  % Right pin is incorrect
    else
        expectedPin = 2;  % Right pin is correct
        unexpectedPin = 1;  % Left pin is incorrect
    end

    %Capture the system time at the onset of the tone
    onsetTime = datetime('now');
    absoluteTime = seconds(onsetTime - datetime('today'));

    % Write the sine wave to the DAQ output
    disp('Tone playing:');
    disp(toneFreq);
    write(daqObjClocked, toneSignal');  % Sine wave is transposed to match the format (column vector)
    
    % Start response period
    responseStartTime = tic;
    
    % Initialize response tracking
    correctResponse = false;
    incorrectResponse = false;
    lockoutViolations = 0;

    % Randomize trial delay and lockout duration
    trialDelay = rand * diff(params.trialDelayRange) + params.trialDelayRange(1);
    lockoutDuration = rand * diff(params.lockoutDurationRange) + params.lockoutDurationRange(1);

    % Allow time responseTime for a response
    while toc(responseStartTime) < params.responseTime
        
        % Read the current state of digital inputs
        inputVals = read(daqObjInput, "OutputFormat", "Matrix");

        % Check for response
        if inputVals(expectedPin) == 1
            correctResponse = true;
            disp('CORRECT')
            responseEndTime = toc(responseStartTime);
            
            % Dispense reward for correct response
            if expectedPin == 1
                write(daqObjOutput, [1, 0]);
                pause(params.dispenseDuration);
                write(daqObjOutput, [0, 0]);
                pause(0.1);
            else
                write(daqObjOutput, [0, 1]);
                pause(params.dispenseDuration);
                write(daqObjOutput, [0, 0]);
                pause(0.1);
            end

            % Record correct response
            responseMatrix(trial, :) = [1, 0, 0, expectedPin, responseEndTime, responseMatrix(trial, 5), toneFreq, trialDelay, lockoutDuration, lockoutViolations, absoluteTime];
            break;
        
        elseif inputVals(unexpectedPin) == 1
            
            %Begin lockout period for incorrect response
            incorrectResponse = true;
            disp('INCORRECT')
            responseEndTime = toc(responseStartTime);
            lockoutViolations = lockoutViolations + 1;
            pause(lockoutDuration);

            % Record incorrect response
            responseMatrix(trial, :) = [0, 1, 0, expectedPin, responseEndTime, responseMatrix(trial, 5), toneFreq, trialDelay, lockoutDuration, lockoutViolations, absoluteTime];
            break;
        end
    end
    
    % No response
    if ~correctResponse && ~incorrectResponse
        disp('NO RESPONSE')
        responseMatrix(trial, :) = [0, 0, 1, expectedPin, NaN, responseMatrix(trial, 5), toneFreq, trialDelay, lockoutDuration, lockoutViolations, absoluteTime];
    end
    
    % Increment completedTrials
    completedTrials = completedTrials + 1;
    
    % Outcome parsing
    trialNumbers(end+1) = completedTrials;
    
    % Check what happened in the trial
    isCorrect = responseMatrix(completedTrials, 1) == 1;
    isNoResp = responseMatrix(completedTrials, 3) == 1;
    expectedPin = responseMatrix(completedTrials, 4);  % 1 = left, 2 = right
    
   % Count totals for each category
    rightTrials = responseMatrix(1:completedTrials,4) == 2;
    leftTrials = responseMatrix(1:completedTrials,4) == 1;
    
    numCorrectLeft = sum(responseMatrix(1:completedTrials,1) == 1 & leftTrials);
    numCorrectRight = sum(responseMatrix(1:completedTrials,1) == 1 & rightTrials);
    numNoResp = sum(responseMatrix(1:completedTrials,3));
    
    numLeftTrials = sum(leftTrials);
    numRightTrials = sum(rightTrials);
    
    % Compute percentages
    correctLeftHistory(end+1) = 100 * numCorrectLeft / max(numLeftTrials, 1);  % Avoid divide by 0
    correctRightHistory(end+1) = 100 * numCorrectRight / max(numRightTrials, 1);
    noResponseHistory(end+1) = 100 * numNoResp / completedTrials;

    
    % Update plot lines
    set(guiHandles.LeftLine, 'XData', trialNumbers, 'YData', correctLeftHistory);
    set(guiHandles.RightLine, 'XData', trialNumbers, 'YData', correctRightHistory);
    set(guiHandles.NoRespLine, 'XData', trialNumbers, 'YData', noResponseHistory);
    
    % Update trial count
    guiHandles.TrialText.String = num2str(completedTrials);
    
    % Expand X limits if needed
    if completedTrials > 100
        set(guiHandles.Axes, 'XLim', [completedTrials-99 completedTrials]);
    end

    drawnow;  % Refresh GUI
    % Pause for randomized trial delay
    pause(trialDelay);
end

stop(daqLickSample);

% Trim response matrix
responseMatrix = responseMatrix(1:completedTrials, :);
writematrix(responseMatrix, params.fileLocation+'Test_responseMatrix.csv');