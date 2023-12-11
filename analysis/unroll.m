% Assuming meanintention is your table
mean_diff_sd = meanintention.std_error_diff; % Accessing the column

% Extracting data for mean_pert from trials 25 to 224
mean_pert_sd = mean_diff_sd(25:224);

% Extracting data for mean_wash from trials 25 to the end
mean_wash_sd = mean_diff_sd(226:end);

a = -14.9951;
b = -1.1853;
c = 12.5889;

x_values = 1:200;
mean_values = a * x_values.^b + c;

num_participants = 19;
simulated_pert = zeros(length(x_values), num_participants);

start_SD = 3;
end_SD = 2.5;
start_trial = 1;
end_trial = 200;

for i = 1:num_participants
    % Define the changing SD for each participant
    participant_SD = linspace(start_SD, end_SD, end_trial - start_trial + 1);
    
    % Define the range of trials with changing SD
    changing_range = start_trial:end_trial;
    changing_SD = participant_SD;
    
    % Adjust SD for the first 20 trials with +/- 5 trials
    changing_range_first_20 = max(1, start_trial - 5):min(end_trial, start_trial + 20 + 5);
    changing_SD(changing_range_first_20) = normrnd(start_SD, 0.5, size(changing_range_first_20));
    
    % Generate participant data
    perturbations = normrnd(0, changing_SD, size(mean_values));
    participant_data = mean_values + perturbations;
    
    % Store participant data in simulated_pert
    simulated_pert(:, i) = participant_data;
end



% Considering you already have simulated_pert and simulated_wash for each participant

% Assuming each of these matrices has dimensions: (length of trials, num_participants)

% Unroll the data for each participant
unrolled_data = [];
for i = 1:num_participants
    participant_data = [simulated_pert(:, i); simulated_wash(:, i)];
    unrolled_data = [unrolled_data; participant_data];
end

% Check the size of the concatenated vector
size_unrolled_data = size(unrolled_data);
disp(size_unrolled_data);


% Assuming unrolled_data contains the concatenated data for all participants

data_length = size(unrolled_data, 1);
num_lots = ceil(data_length / 300);

figure;
hold on;

for i = 1:num_lots
    start_idx = (i - 1) * 300 + 1;
    end_idx = min(i * 300, data_length);
    lot_data = unrolled_data(start_idx:end_idx);
    
    plot(lot_data, 'DisplayName', sprintf('Lot %d', i));
    
    % Wait for a key press to continue plotting
    if i < num_lots
        waitforbuttonpress;
    end
end

legend('show');
xlabel('Data Points');
ylabel('Values');
title('Unrolled Data in Lots of 300');
hold off;




% Displaying mean_pert lengths for each participant
length_of_mean_wash = size(simulated_pert, 1); % Length of mean_pert
disp(length_of_mean_wash);

a = -1.7847;
b = 0.2046;
standard_deviation = 2.4;

x_values = 1:100;
mean_values = a * x_values.^b;

num_participants = 19;
simulated_data = zeros(length(x_values), num_participants);

for i = 1:num_participants
    perturbations = normrnd(0, standard_deviation, size(mean_values));
    participant_data = mean_values + perturbations;
    simulated_wash(:, i) = participant_data;
end

% Displaying length of mean_pert for each participant
length_of_mean_wash = size(simulated_wash, 1); % Length of mean_pert
disp(length_of_mean_wash);



% Assuming simulated_data contains the simulated values for each participant

num_last_values = 20;
mean_divided_by_2 = zeros(num_participants, 1);

for i = 1:num_participants
    last_20_values = simulated_pert(end - num_last_values + 1:end, i);
    mean_last_20 = mean(last_20_values) / 2;
    mean_divided_by_2(i) = mean_last_20;
end

% Displaying the mean divided by 2 for each participant
disp(mean_divided_by_2);


% Assuming baseline and unrolleddata are tables containing the data as described

% Assuming baseline and unrolleddata are tables containing the data as described

% Convert tables to arrays
baseline_array = table2array(baseline);
unrolleddata_array = table2array(unrolleddata);

% Reshape the unrolled data to have a size of 300x19
unrolled_reshaped = reshape(unrolleddata_array, 300, 19);
baseline_reshaped = reshape(baseline_array, 25, 19);

% Initialize the combined vector
combined_vector = [];

% Iterate through each participant
for i = 1:19
    % Stack each column from baseline_reshaped onto the corresponding column from unrolled_reshaped
    combined_column = [baseline_reshaped(:, i); unrolled_reshaped(:, i)];
    
    % Concatenate the combined column for all participants
    combined_vector = [combined_vector; combined_column];
end

% Check the total length of the combined vector (should be 6175)
total_length = length(combined_vector);
disp(total_length);


% Assuming combined_vector is the vector with a total length of 6175

% Define the number of values per participant
values_per_participant = 325;

% Initialize the figure
figure;
hold on;

% Iterate through each participant and plot their values
for i = 1:values_per_participant:length(combined_vector)
    % Check if remaining data for a full participant is available
    if i + values_per_participant - 1 <= length(combined_vector)
        % Plot each participant's values with different colors
        plot(combined_vector(i:i+values_per_participant-1), 'DisplayName', ['Participant ' num2str((i-1)/values_per_participant + 1)]);
    else
        % Plot remaining values if they don't fit a full participant
        plot(combined_vector(i:end), 'DisplayName', ['Remaining Values']);
    end
    
    % Wait for a key press before plotting the next participant
    pause;
end

% Add legend
legend('show');

hold off;


