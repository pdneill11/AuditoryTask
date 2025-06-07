function handles = LickResponseMonitorGUI(numTrials)
    % Create GUI figure
    hFig = figure('Name','Lick Response Monitor', ...
                  'NumberTitle','off', ...
                  'Position',[300, 300, 500, 350], ...
                  'MenuBar','none', ...
                  'Resize','off');

    % Create axes for line plot
    hAxes = axes('Parent', hFig, ...
                 'Units', 'pixels', ...
                 'Position', [70, 100, 400, 200]);

    % Initialize plot lines
    hLeftLine = plot(hAxes, NaN, NaN, 'g', 'LineWidth', 2); hold on;
    hRightLine = plot(hAxes, NaN, NaN, 'b', 'LineWidth', 2);
    hNoRespLine = plot(hAxes, NaN, NaN, 'k', 'LineWidth', 2);
    hold off;

    legend(hAxes, {'Correct Left', 'Correct Right', 'No Response'}, 'Location', 'southeast');
    xlabel(hAxes, 'Trial Number');
    ylabel(hAxes, 'Percentage');
    ylim(hAxes, [0 100]);
    xlim(hAxes, [1 numTrials]);  % Will auto-scale later
    title(hAxes, 'Real-time Lick Accuracy');

    % Completed trial label
    uicontrol('Parent', hFig, 'Style', 'text', 'String', 'Completed Trials:', ...
              'Position', [150, 40, 120, 20], 'FontSize', 10);
    hTrialText = uicontrol('Parent', hFig, 'Style', 'text', 'String', '0', ...
              'Position', [280, 40, 50, 20], 'FontSize', 10);

    % Output handles
    handles.Figure = hFig;
    handles.Axes = hAxes;
    handles.LeftLine = hLeftLine;
    handles.RightLine = hRightLine;
    handles.NoRespLine = hNoRespLine;
    handles.TrialText = hTrialText;
end
