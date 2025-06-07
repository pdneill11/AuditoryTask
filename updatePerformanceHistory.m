function [correctLeftHistory, correctRightHistory, noResponseHistory] = ...
    updatePerformanceHistory(responseMatrix, completedTrials, correctLeftHistory, ...
    correctRightHistory, noResponseHistory)

    rightTrials = responseMatrix(1:completedTrials,4) == 2;
    leftTrials  = responseMatrix(1:completedTrials,4) == 1;

    numCorrectLeft = sum(responseMatrix(1:completedTrials,1) == 1 & leftTrials);
    numCorrectRight = sum(responseMatrix(1:completedTrials,1) == 1 & rightTrials);
    numNoResp = sum(responseMatrix(1:completedTrials,3));

    numLeftTrials = sum(leftTrials);
    numRightTrials = sum(rightTrials);

    correctLeftHistory(end+1) = 100 * numCorrectLeft / max(numLeftTrials, 1);
    correctRightHistory(end+1) = 100 * numCorrectRight / max(numRightTrials, 1);
    noResponseHistory(end+1) = 100 * numNoResp / completedTrials;
end
