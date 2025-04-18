data = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 1 1 1 1 1 1 1 1 1 1 1 ...
        1 1 1 1 1 1 1 1 1 1 1 1 0 0 1 0 0 0 1 0 1 1 1 1 1 1 0 0 0 1 1 1 1 0 0 0 1 0 0 0 0 ...
        1 0 1 1 0 1 1 1 0 1 0 1 1 1 1 1 1 1];

% Switch 1s and 0s
data = 1 - data; 

% Create x-axis values
x = 1:length(data);

figure;
stem(x, data, 'filled', 'MarkerSize', 3, 'LineWidth', 0.8);
ylim([-0.5 1.5]);
yticks([0 1]);
yticklabels({'No Lick', 'Lick'});

xlabel('Trial Number', 'FontSize', 18, 'FontWeight', 'Bold');
ylabel('Outcome', 'FontSize', 18, 'FontWeight', 'Bold');
title('Responses', 'FontSize', 20, 'FontWeight', 'Bold');
set(gca, 'FontSize', 16, 'LineWidth', 1.2);
grid on;
