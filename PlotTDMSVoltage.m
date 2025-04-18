% Read TDMS file
Date = "04182025";
data = tdmsread("Z:\pdneill\MATLAB Code\AuditoryTask\Data\"+Date+"_VoltageSignal.tdms");

% Check the number of segments
nSegments = numel(data);

% Sample rate (e.g., 1000 Hz)
sampleRate = 1000;

% Loop through cells and plot the first usable segment
plotted = false;

for i = 1:nSegments
    segment = data{i};
    
    % Check if the segment is a table
    if istable(segment)
        varNames = segment.Properties.VariableNames;

        % Use the first column as voltage data
        signal = segment{:, 1};  % Assuming the first column is the voltage signal
        
        % Create a time vector based on sample rate
        time = (1:length(signal)) / sampleRate;  % Time in seconds

        % Plot the signal against time
        plot(time, signal);
        xlabel('Time (s)', 'FontSize', 14, 'FontWeight', 'bold');
        ylabel('Voltage (V)', 'FontSize', 14, 'FontWeight', 'bold');
        title('Lick Signal', 'FontSize', 16, 'FontWeight', 'bold');
        
        % Adjust grid and ticks for publication-ready appearance
        grid on;
        set(gca, 'FontSize', 12, 'FontWeight', 'normal');
        
        % Set proper x-axis limits
        xlim([0, max(time)]);  % Set x-axis from 0 to the max time value

        % Tighten the axis to fit the plot tightly around the data
        axis tight;  % Ensures the plot does not extend beyond the data bounds

        plotted = true;
        break;

    % If the segment is numeric and 1D, plot it as voltage data
    elseif isnumeric(segment) && isvector(segment)
        signal = segment;  % The voltage signal
        time = (1:length(signal)) / sampleRate;  % Time in seconds
        
        % Plot the signal against time
        plot(time, signal);
        xlabel('Time (s)', 'FontSize', 14, 'FontWeight', 'bold');
        ylabel('Voltage (V)', 'FontSize', 14, 'FontWeight', 'bold');
        title(['TDMS Segment ', num2str(i)], 'FontSize', 16, 'FontWeight', 'bold');
        
        % Adjust grid and ticks for publication-ready appearance
        grid on;
        set(gca, 'FontSize', 12, 'FontWeight', 'normal');
        
        % Set proper x-axis limits
        xlim([0, max(time)]);  % Set x-axis from 0 to the max time value

        % Tighten the axis to fit the plot tightly around the data
        axis tight;  % Ensures the plot does not extend beyond the data bounds

        plotted = true;
        break;
    end
end

% If no plot was found, notify the user
if ~plotted
    disp('No plottable data found.');
end
