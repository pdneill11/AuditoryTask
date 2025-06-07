function [responseMatrixRow, correct, incorrect] = runResponseLoop(daqObjInput, daqObjOutput, ...
    expectedPin, unexpectedPin, responseTime, lockoutDuration, dispenseDuration, trialDelay, ...
    toneFreq, isTest, absoluteTime)

    correct = false;
    incorrect = false;
    lockoutViolations = 0;
    startTime = tic;

    while toc(startTime) < responseTime
        inputVals = read(daqObjInput, "OutputFormat", "Matrix");
        
        if inputVals(expectedPin) == 1
            correct = true;
            disp('CORRECT')
            responseEndTime = toc(startTime);
            dispenseReward(daqObjOutput, expectedPin, dispenseDuration);
            responseMatrixRow = [1, 0, 0, expectedPin, responseEndTime, isTest, toneFreq, trialDelay, lockoutDuration, lockoutViolations, absoluteTime];
            return;

        elseif inputVals(unexpectedPin) == 1
            incorrect = true;
            disp('INCORRECT')
            responseEndTime = toc(startTime);
            lockoutViolations = lockoutViolations + 1;
            pause(lockoutDuration);
            responseMatrixRow = [0, 1, 0, expectedPin, responseEndTime, isTest, toneFreq, trialDelay, lockoutDuration, lockoutViolations, absoluteTime];
            return;
        end
    end

    % No response
    disp('NO RESPONSE')
    responseMatrixRow = [0, 0, 1, expectedPin, NaN, isTest, toneFreq, trialDelay, lockoutDuration, lockoutViolations, absoluteTime];
end
