% Main trial loop
for trial = 1:numTrials
    disp(['Trial ', num2str(trial), ' of ', num2str(numTrials)]);

    % Initialize response tracking
    correctResponse = false;
    incorrectResponse = false;
    lockoutViolations = 0;

    % Randomize trial delay and lockout duration
    trialDelay = rand * diff(trialDelayRange) + trialDelayRange(1);
    lockoutDuration = rand * diff(lockoutDurationRange) + lockoutDurationRange(1);

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

    % Capture the system time at the onset of the tone
    onsetTime = datetime('now');
    absoluteTime = seconds(onsetTime - datetime('today'));

    % Wait for the tone duration to elapse
    pause(toneDuration);
    stop(daqObjClocked);
    
    % Start response period
    responseStartTime = tic;

    % Allow time responseTime for a response
    while toc(responseStartTime) < responseTime
        
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
                pause(dispenseDuration);
                write(daqObjOutput, [0, 0]);
                pause(0.1);
            else
                write(daqObjOutput, [0, 1]);
                pause(dispenseDuration);
                write(daqObjOutput, [0, 0]);
                pause(0.1);
            end

            % Record correct response
            responseMatrix(trial, :) = [1, 0, 0, responseEndTime, responseMatrix(trial, 5), toneFreq, trialDelay, lockoutDuration, lockoutViolations, absoluteTime];
            completedTrials = completedTrials + 1;
            break;
        
        elseif inputVals(unexpectedPin) == 1
            incorrectResponse = true;
            disp('INCORRECT')
            responseEndTime = toc(responseStartTime);
            
            % Dispense reward for incorrect response
            if expectedPin == 1
                write(daqObjOutput, [0, 1]);
                pause(dispenseDuration);
                write(daqObjOutput, [0, 0]);
                pause(0.1);
            else
                write(daqObjOutput, [1, 0]);
                pause(dispenseDuration);
                write(daqObjOutput, [0, 0]);
                pause(0.1);
            end

            % Record incorrect response
            responseMatrix(trial, :) = [0, 1, 0, responseEndTime, responseMatrix(trial, 5), toneFreq, trialDelay, lockoutDuration, lockoutViolations, absoluteTime];
            completedTrials = completedTrials + 1;
            break;
        end
    end
    
    % No response
    if ~correctResponse && ~incorrectResponse
        disp('NO RESPONSE')
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
