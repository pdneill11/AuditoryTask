function [expectedPin, unexpectedPin] = getExpectedPin(toneFreq, cutoffFreq)
    if toneFreq < cutoffFreq
        expectedPin = 1;
        unexpectedPin = 2;
    else
        expectedPin = 2;
        unexpectedPin = 1;
    end
end
