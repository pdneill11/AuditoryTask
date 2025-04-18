% Define the DAQ session and set up the device
s = daq.createSession('ni'); % 'ni' stands for National Instruments DAQ device
ch = addAnalogInputChannel(s, 'Dev4', 'ai0', 'Voltage'); % 'Dev1' is the device, 'ai0' is the analog input channel

% Set properties for the session (optional)
s.Rate = 1000; % Sampling rate in Hz (samples per second)
s.DurationInSeconds = 10; % Duration to acquire data in seconds

% Start the data acquisition
[data, time] = startForeground(s); % Start and collect data synchronously

% Plot the acquired voltage signal
figure;
plot(time, data);
xlabel('Time (seconds)');
ylabel('Voltage (V)');
title('Voltage Signal from DAQ Device');
grid on;
