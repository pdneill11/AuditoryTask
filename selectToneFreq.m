function [toneFreq, isTestTrial] = selectToneFreq(params, leftToneFreq, rightToneFreq)
    isTestTrial = rand <= params.testTrialProbability;
    if isTestTrial
        toneFreq = params.testFrequencies(randi(length(params.testFrequencies)));
    else
        toneFreq = leftToneFreq;
        if rand > 0.5
            toneFreq = rightToneFreq;
        end
    end
end
