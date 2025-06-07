function initializeDAQRecording(params, daqLickSample)
    disp("Starting acquisition...");
    daqLickSample.LogToDisk = true;
    daqLickSample.LogFileName = params.fileLocation + params.fileName;
    start(daqLickSample, "Continuous");
    
    cleanupObj = onCleanup(@() stopAndCleanup(daqLickSample));  % Ensures it stops on exit or error

end

function stopAndCleanup(daqObj)
    disp('Stopping DAQ...');
    stop(daqObj);
end
