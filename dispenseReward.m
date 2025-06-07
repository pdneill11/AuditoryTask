function dispenseReward(daqObjOutput, expectedPin, duration)
    if expectedPin == 1
        write(daqObjOutput, [1, 0]);
    else
        write(daqObjOutput, [0, 1]);
    end
    pause(duration);
    write(daqObjOutput, [0, 0]);
    pause(0.1);
end
