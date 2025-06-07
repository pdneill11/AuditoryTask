% Run water through solenoid valve to prevent dry-runs

prepareLick = 0.5; % Dispense time to prepare solenoid valves (in seconds)

write(daqObjOutput, [1, 1]);
pause(prepareLick);
write(daqObjOutput, [0, 0]);
pause(0.1);