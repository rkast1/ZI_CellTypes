
mouselist = {''};

outputDirectory = 'Shelter_matlab_050324_4PM'; % Specify the output directory name

if ~isfolder(outputDirectory)
    mkdir(outputDirectory); % Create the output directory if it doesn't exist
end

files = dir('*.csv');

for m = 1:numel(mouselist)
    x = 0;
    currentString = mouselist{m};
    disp(currentString)
    ShelterData = [];
    
    for i = 1:numel(files)
        filename = files(i).name;

        % find the DLC predictions for the current mouse
        if contains(filename, mouselist{m}) && contains(filename, '50000.csv')
            
            x = 1;
            %startindex = strfind(filename, 'Trial');
            %startindex = startindex + 5
            endindex = strfind(filename,'_');
            endindex = endindex - 1;
            trialnum = filename(1:endindex);
            trialnum = str2double(trialnum);
            output = ExtractShelterBehavior(filename, currentString);
            ShelterData = [ShelterData; output];
        
        end
        
    end

 if x == 1
    variableNames = {'Loom Number', 'Session Time of Loom (s)', 'Shelter Escape Entry (s)',  'Shelter Arrival Latency (s)', 'Freeze Start (s)', 'Freeze Start Latency (s)', 'Post Freeze Small Movement (s)', 'Absolute Freeze Duration (s)', 'Post Freeze Medium Movement (s)', 'Immobility Duration (s)', 'Shelter Exit (s)', 'In Shelter Duration (s)'};
    HeaderEscapeData =  array2table(ShelterData, 'VariableNames', variableNames);
    outputFilename = fullfile(outputDirectory, strcat(currentString, '_ShelterDataAllTrials.csv'));
    writetable(HeaderEscapeData, outputFilename);
    x=0;
    disp(outputFilename);
 end

end
 

disp('Extraction completed successfully.');

%%
function outputArray = ExtractShelterBehavior(Session, Mouse)

  
     % set some hyperparameters
    %minimum_y_reached = 300;
    mouse_present_threshold = 0.1;
    %minimum_bout_time = 30;

    % perform some computations to generate the outputs
    predictions = readmatrix(Session);
    predictions(:,1) = [];
    
    % name the points
    point_list = {'front', 'left', 'right', 'center', 'left-s', 'right-s', 'body', 'left-h', 'right-h', 'tail', 'far-l', 'far-r', 'near-l', 'near-r'};
    
    % collect the points in a reasonable way
    x_points = predictions(:,1:3:end);
    y_points = predictions(:,2:3:end);
    c_points = predictions(:,3:3:end);
    
    % shelter position
    shelter_y = predictions(:,38:3:end);
    shelterthreshold = (sum(nanmean(shelter_y(:,:)))/2);
    
    % decide whether there's a mouse in each frame
    mouse_present = zeros(size(x_points,1),1);
    mouse_present(nanmean(c_points(:,1:10)')>mouse_present_threshold)=1;
    
    % midpoint of mouse
    x_mid = nanmean(x_points(:,1:10)');
    y_mid = nanmean(y_points(:,1:10)');

    % 200ms moving average velocity of the mouse (pixels/frame)
    vx = movmean(gradient(x_mid),6,2);
    vy = movmean(gradient(y_mid),6,2);
   
    % Calculate magnitudes and angles of velocity vectors using cart2pol
    [magnitude, angle] = cart2pol(vx, vy);

    % Convert angles from radians to degrees
    angle_degrees = rad2deg(angle);

    % Combine magnitudes and angles into a polar vector array
    delta_y = [magnitude; angle_degrees]';

    % find when the mouse enters and exits the field of view
    mouse_present(1) = 0;
    mouse_present(end) = 0;
    mouse_present(mouse_present>0) = 1;
    mouse_crossing = crossing(mouse_present,1:length(mouse_present),0.5);
    
    % this part needs some work !$!
    x_mid_present = x_mid(mouse_present > 0.5);
    y_mid_present = y_mid(mouse_present> 0.5);

    % read in loom matrix
    LoomIndices = readmatrix(strcat(Mouse, '_LoomIndices.csv'));
    loomframes = zeros(size(LoomIndices,1),1);

    % detect looms from reflected indicator area values
    loomframes((LoomIndices(:,6))>1)=500;
    loomframes2 = [];
    loomframes2 = movsum(loomframes, [300 0]);
    
    % remove "looms" that are too close to the start of the video
    loomframes3 = crossing(loomframes2,1:length(loomframes2),100);
    loomframes3 = loomframes3(1:2:end);
    loomframes3 = loomframes3(loomframes3>135000);
 
    % remove "looms" that are too close to the end of the video
    loomframes3 = loomframes3 - length(x_mid);
    loomframes3 = loomframes3(loomframes3 < -2700);
    loomframes3 = loomframes3 + length(x_mid);
    
    % convert loom indices from frames to seconds
    loomframes4 = loomframes3/30;
    
    % define the loom bout start (mouse_enters) and stop (mouse_exits) indices
    mouse_enters = loomframes3 - 15;

    % collect position and velocity during each bout (ending with shelter exit)
    % find when the mouse enters and exits the shelter
    s_mousex = x_mid;
    s_mousex(nanmean(c_points(:,1:10)')<mouse_present_threshold) = 0;
    s_mousex(1)=0;
    s_mousex(end)=0;
    s_nanmousex = s_mousex;
    s_nanmousex(s_nanmousex == 0) = nan;

    s_mousey = y_mid;
    s_mousey(nanmean(c_points(:,1:10)')<mouse_present_threshold) = 0;
    s_mousey(1)=0;
    s_mousey(end)=0;
    s_nanmousey = s_mousey;
    s_nanmousey(s_nanmousey == 0) = nan;

     % 200ms moving average velocity of the mouse (pixels/frame)
    svx = gradient(s_mousex);
    svy = gradient(s_mousey);
   
    % Calculate magnitudes and angles of velocity vectors using cart2pol
    [s_magnitude, s_angle] = cart2pol(svx, svy);

    % Convert angles from radians to degrees
    s_angle_degrees = s_angle * (180/pi);

    % Calculate polar velocity
    % Magnitude of velocity
    v_mag = sqrt(svx.^2 + svy.^2);
    % Angle of velocity in radians
    v_angle = atan2(svy, svx);

    % Combine magnitudes and angles into a polar vector array
    s_delta = [v_mag; v_angle]';
    

    shelter_crossing = crossing(s_mousey,1:length(s_mousey), shelterthreshold);
    shelter_entry = shelter_crossing(1:2:end);
    shelter_exit = shelter_crossing(2:2:end);
    nan_ymid = s_mousey;
    nan_ymid(nan_ymid == 0) = nan;
    mouse_exits2 = []; % Initialize mouse_exits2
    escape2shelter = [];
    shelterfreeze =  [];
    smallmove = [];
    mediummove = [];
    
    % calculate the mean and variance frame-to-frame y_pixel movement prior to the first loom
    %baseline_movmean = nanmean(abs(gradient(nan_ymid(1:loomframes3(1)))));
    %baseline_std = std(abs(gradient(nan_ymid(1:loomframes3(1)))), "omitmissing");
    %prct25 = prctile(abs(gradient(nan_ymid)),25);
    %prct75 = prctile(abs(gradient(nan_ymid)),75);

    for f = 1:size(loomframes3, 2)
        if find(shelter_entry > loomframes3(f), 1) > 0
            
            idx_entry = find(shelter_entry > loomframes3(f), 1); % Find the index of the first element greater than loomframes3(f)
            escape2shelter(1, f) = shelter_entry(idx_entry);  % Assign the shelter_entry value to escape2shelter
    
            idx_exit = find(shelter_exit > loomframes3(f), 1); % Find the index of the first element greater than loomframes3(f)
            mouse_exits2(1, f) = shelter_exit(idx_exit); % Assign the shelter_exit value to mouse_exits2
           
            idx_freeze = find(abs(movmax(s_delta(escape2shelter(1,f):end,1), [0 30])) < 1, 1);
            shelterfreeze(1, f) = escape2shelter(1,f) + idx_freeze;

            idx_smallmove = find(abs(movmean(s_delta(shelterfreeze(1,f):end,1), [0 3])) > 1, 1);
            smallmove(1,f) = shelterfreeze(1,f) + idx_smallmove;
            
            idx_medmove = find(abs(movmean(s_delta(shelterfreeze(1,f):end,1), [0 3])) > 2, 1);
            mediummove(1,f) = shelterfreeze(1,f) + idx_medmove;

        end

    end

    mouse_time2 = mouse_exits2-mouse_enters(1:size(mouse_exits2,2));
    
    mouse_x_pos2 = [];
    mouse_y_pos2 = [];
    bout_delta_y2 = [];

    for f = 1:size(mouse_time2,2)
    mouse_x_pos2(f,1:mouse_time2(f)) = x_mid(mouse_enters(f)+1:mouse_exits2(f));
    mouse_y_pos2(f,1:mouse_time2(f)) = y_mid(mouse_enters(f)+1:mouse_exits2(f));
    bout_delta_y2(f,1:mouse_time2(f)) = s_delta(mouse_enters(f)+1:mouse_exits2(f),1)';
    end
    
    mouse_x_pos2(mouse_x_pos2==0)=nan;
    mouse_y_pos2(mouse_y_pos2==0)=nan;
    
    % get the head part positions during each bout
    mouse_front_x_pos2 = [];
    mouse_left_x_pos2 = [];
    mouse_right_x_pos2 = [];
    mouse_middle_x_pos2 = [];
    mouse_bodycenter_x_pos2 = [];
    
    mouse_front_y_pos2 = [];
    mouse_left_y_pos2 = [];
    mouse_right_y_pos2 = [];
    mouse_middle_y_pos2 = [];
    mouse_bodycenter_y_pos2 = [];
    delta_y2 = movmean(gradient(nan_ymid),6,2);

    % trim the matrix down to just the frames included in a bout with 
    % qualifying values for minimum length and minimum y value
    for f = 1:size(mouse_time2,2)
    mouse_front_x_pos2(f,1:mouse_time2(f)) = x_points(mouse_enters(f)+1:mouse_exits2(f),1);
    mouse_front_y_pos2(f,1:mouse_time2(f)) = y_points(mouse_enters(f)+1:mouse_exits2(f),1);
    
    mouse_left_x_pos2(f,1:mouse_time2(f)) = x_points(mouse_enters(f)+1:mouse_exits2(f),2);
    mouse_left_y_pos2(f,1:mouse_time2(f)) = y_points(mouse_enters(f)+1:mouse_exits2(f),2);
    
    mouse_right_x_pos2(f,1:mouse_time2(f)) = x_points(mouse_enters(f)+1:mouse_exits2(f),3);
    mouse_right_y_pos2(f,1:mouse_time2(f)) = y_points(mouse_enters(f)+1:mouse_exits2(f),3);
    
    mouse_middle_x_pos2(f,1:mouse_time2(f)) = x_points(mouse_enters(f)+1:mouse_exits2(f),4);
    mouse_middle_y_pos2(f,1:mouse_time2(f)) = y_points(mouse_enters(f)+1:mouse_exits2(f),4);
    
    mouse_bodycenter_x_pos2(f,1:mouse_time2(f)) = x_points(mouse_enters(f)+1:mouse_exits2(f), 7);
    mouse_bodycenter_y_pos2(f,1:mouse_time2(f)) = y_points(mouse_enters(f)+1:mouse_exits2(f), 7);
    
    mouse_x_pos2(f,1:mouse_time2(f)) = x_points(mouse_enters(f)+1:mouse_exits2(f), 7);
    mouse_y_pos2(f,1:mouse_time2(f)) = y_points(mouse_enters(f)+1:mouse_exits2(f), 7);
    end
    
    mouse_front_x_pos2(mouse_front_x_pos2==0) = nan;
    mouse_left_x_pos2(mouse_left_x_pos2==0) = nan;
    mouse_right_x_pos2(mouse_right_x_pos2==0) = nan;
    mouse_middle_x_pos2(mouse_middle_x_pos2==0) = nan;
    mouse_front_y_pos2(mouse_front_y_pos2==0) = nan;
    mouse_left_y_pos2(mouse_left_y_pos2==0) = nan;
    mouse_right_y_pos2(mouse_right_y_pos2==0) = nan;
    mouse_middle_y_pos2(mouse_middle_y_pos2==0) = nan;
    mouse_bodycenter_x_pos2(mouse_bodycenter_x_pos2==0) = nan;
    mouse_bodycenter_y_pos2(mouse_bodycenter_y_pos2==0) = nan;
    
    mouse_x_pos2(mouse_x_pos2==0) = nan;
    mouse_y_pos2(mouse_y_pos2==0) = nan;
    
    % record whether the mouse is in the field of view during each loom bout
    
    mouse_bout_presence2 = [];
    
    for f = 1:size(mouse_time2,2)
    mouse_bout_presence2(f,1:mouse_time2(f)) = mouse_present(mouse_enters(f)+1:mouse_exits2(f),1);
    mouse_bout_presence2(f,1:mouse_time2(f)) = mouse_present(mouse_enters(f)+1:mouse_exits2(f),1);
    end

    % Calculate the instantaneous velocity of the mouse with updated direction
    %delta_y = movmean(gradient(mouse_y_pos),6,2);
    %mouse_velocity = delta_y; %this was written as abs(delta_y), but just converted back below, so we can ignore
    %mouse_velocity(delta_y < 0) = -mouse_velocity(delta_y < 0);
    
    %create a cell area housing the head angle (theta1) and the angular velocity
    head_angular_vel = [];

    for f = 1:size(mouse_time2,2)
    tempF_x = mouse_front_x_pos2(f,:);
    tempF_y = mouse_front_y_pos2(f,:);
    
    tempM_x = mouse_middle_x_pos2(f,:);
    tempM_y = mouse_middle_y_pos2(f,:);
    
    tempB_x = mouse_bodycenter_x_pos2(f,:);
    tempB_y = mouse_bodycenter_y_pos2(f,:);
    
    tempF_x = tempM_x - tempB_x;
    tempF_y = tempM_y - tempB_y;
    
    tempF_x = movmean(tempF_x, 3);
    tempF_y = movmean(tempF_y, 3);
    
    [theta1,rho1] = cart2pol(tempF_x,tempF_y);
    
    temp_angular_vel = gradient(theta1) * (180/pi);
    head_angular_vel(f,:) = temp_angular_vel(1,:);
    end
    
    %startbout = find(movmean(mouse_present,90)==1, 1);
    %actualentry = find(y_mid < 300,1) + startbout;
    %retreat = find(delta_y(actualentry:end) > 10, 1)

    for f = 1:size(mouse_time2,2)
    % create an output array to append to the matrix
    outputArray(f,:) = [f, (loomframes3(f)/30) , ((escape2shelter(f))/30), ((escape2shelter(f)-loomframes3(f))/30), (shelterfreeze(f)/30), ((shelterfreeze(f)-loomframes3(f))/30), (smallmove(f)/30), ((smallmove(f)-shelterfreeze(f))/30), (mediummove(f)/30), ((mediummove(f)-shelterfreeze(f))/30), ((mouse_exits2(f))/30), ((mouse_exits2(f)-escape2shelter(f))/30)];
    end

end

%% 

% crossing function

function [ind,t0,s0,t0close,s0close] = crossing(S,t,level,imeth)

error(nargchk(1,4,nargin));
if nargin < 2 || isempty(t)
    t = 1:length(S);
elseif length(t) ~= length(S)
    error('t and S must be of identical length!');    
end
if nargin < 3
    level = 0;
end
if nargin < 4
    imeth = 'linear';
end
t = t(:)';
S = S(:)';
S   = S - level;
ind0 = find( S == 0 ); 
S1 = S(1:end-1) .* S(2:end);
ind1 = find( S1 < 0 );
ind = sort([ind0 ind1]);
t0 = t(ind); 
s0 = S(ind);

if strcmp(imeth,'linear')
    for ii=1:length(t0)
        if abs(S(ind(ii))) > eps(S(ind(ii)))
            NUM = (t(ind(ii)+1) - t(ind(ii)));
            DEN = (S(ind(ii)+1) - S(ind(ii)));
            DELTA =  NUM / DEN;
            t0(ii) = t0(ii) - S(ind(ii)) * DELTA;
            s0(ii) = 0;
        end
    end
end

end
