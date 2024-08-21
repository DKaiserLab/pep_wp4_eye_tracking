% Example: Load the list of object names from previous analysis
% (Replace with your actual object names or load them from a file)
object_names = keys(object_frequency); % Assuming object_frequency is from previous script

% Set the minimum number of consecutive letters in common (e.g., 4)
min_common_letters = 4;

% Initialize an empty cell array to store pairs of similar object names
similar_name_pairs = {};

% Loop through each pair of object names
for i = 1:length(object_names)
    for j = i+1:length(object_names)
        name1 = object_names{i};
        name2 = object_names{j};
        
        % Find the longest consecutive substring between the two names
        longest_common_substring = find_longest_common_substring(name1, name2);
        
        % If the longest common substring has more than the specified number of letters
        if length(longest_common_substring) >= min_common_letters
            % Add the pair to the list
            similar_name_pairs{end+1, 1} = name1; %#ok<AGROW>
            similar_name_pairs{end, 2} = name2;
            similar_name_pairs{end, 3} = longest_common_substring; % Optionally store the common substring
        end
    end
end

% Display the similar name pairs
fprintf('Object name pairs with more than %d consecutive letters in common:\n', min_common_letters);
for i = 1:size(similar_name_pairs, 1)
    fprintf('"%s" and "%s" have "%s" in common\n', ...
        similar_name_pairs{i, 1}, similar_name_pairs{i, 2}, similar_name_pairs{i, 3});
end

% Optionally save the pairs to a CSV file
output_table = cell2table(similar_name_pairs, 'VariableNames', {'ObjectName1', 'ObjectName2', 'CommonSubstring'});
writetable(output_table, 'similar_object_name_pairs.csv');

fprintf('Similar name pairs saved to similar_object_name_pairs.csv\n');

%% Helper function to find the longest common substring between two strings
function longest_common_substring = find_longest_common_substring(str1, str2)
    % Initialize the matrix for dynamic programming
    len1 = length(str1);
    len2 = length(str2);
    LCSuff = zeros(len1+1, len2+1);
    longest_length = 0;
    longest_end_pos = 0;
    
    % Build the LCSuff table to store lengths of common suffixes
    for i = 1:len1
        for j = 1:len2
            if str1(i) == str2(j)
                LCSuff(i+1, j+1) = LCSuff(i, j) + 1;
                if LCSuff(i+1, j+1) > longest_length
                    longest_length = LCSuff(i+1, j+1);
                    longest_end_pos = i;
                end
            end
        end
    end
    
    % Extract the longest common substring from str1
    longest_common_substring = str1(longest_end_pos-longest_length+1 : longest_end_pos);
end
