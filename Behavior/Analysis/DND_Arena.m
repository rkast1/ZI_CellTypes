
mouselist = {'78-1-1',
            '78-1-2',
            '78-1-3',
            '78-1-4',
            '78-1-5'}; 


outputDirectory = 'test'; % Specify the output directory name

if ~isfolder(outputDirectory)
    mkdir(outputDirectory); % Create the output directory if it doesn't exist
end

files = dir('*.csv');

for m = 1:numel(mouselist)
    x = 0;
    currentString = mouselist{m};
    disp(currentString)
    EscapeData = [];
    
    for i = 1:numel(files)
        filename = files(i).name;
        if contains(filename, mouselist{m}) && contains(filename, '70000.csv') && contains(filename, 'Day4')
            x = 1;

            %startindex = strfind(filename, 'Trial');
            %startindex = startindex + 5
            endindex = strfind(filename,'_');
            endindex = endindex - 1;
            trialnum = filename(1:endindex);
            trialnum = str2double(trialnum);
            output = ExtractEscapes(filename, currentString);
            EscapeData = [EscapeData; output];

        
        end
        
    end

 if x == 1
    
    variableNames = {'Loom Number', 'Session Time of Loom (s)', 'Loom Time Relative To Arena Entry',  'Escape Onset Latency (s)', 'Run Latency (s)', 'Shelter Arrival Latency (s)', 'Escape Success', 'MaxSpeed', 'Direction While Licking'};
    HeaderEscapeData = [variableNames; num2cell(sortrows(EscapeData,1))];
    outputFilename = fullfile(outputDirectory, strcat(currentString, '_EscapeOnsetFramesAllTrials.csv'));
    writecell(HeaderEscapeData, outputFilename);
    x=0;
    disp(outputFilename)
 end

end

disp('Extraction completed successfully.');


%%
function outputArray = ExtractEscapes(Session, Mouse)

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
    
    % find when the mouse enters and exits the arena
    mouse_present(1) = 0;
    mouse_present(end) = 0;
    mouse_present(mouse_present>0)=1;
    mouse_crossing = crossing(mouse_present,1:length(mouse_present),0.5);

    
    LoomIndices = readmatrix(strcat(Mouse, '_Arena_LoomIndices.csv'))
    loomframes = zeros(size(LoomIndices,1),1);

    %detect looms from reflected indicator
    loomframes((LoomIndices(:,6))>1)=500;
    loomframes2 = [];
    loomframes2 = movsum(loomframes, [300 0]);
    loomframes3 = crossing(loomframes2,1:length(loomframes2),100);
    loomframes3 = loomframes3(1:2:end) 
    loomframes3 = loomframes3(loomframes3>13500) %eliminate "looms" that are within the first 7.5 minutes
    loomframes3 = loomframes3 - length(x_mid)
    loomframes3 = loomframes3(loomframes3 < -2700) %eliminate "looms: that are 
    loomframes3 = loomframes3 + length(x_mid)
    loomframes4 = loomframes3/30
    
    mouse_enters = loomframes3 - 300
    mouse_exits = loomframes3 + 600
    mouse_time = mouse_exits-mouse_enters;

    % collect position and velocity during each bout
    mouse_x_pos = [];
    mouse_y_pos = [];
    
    for f = 1:size(mouse_time,2)
    mouse_x_pos(f,1:mouse_time(f)) = x_mid(mouse_enters(f)+1:mouse_exits(f));
    mouse_y_pos(f,1:mouse_time(f)) = y_mid(mouse_enters(f)+1:mouse_exits(f));
    end
    
    mouse_x_pos(mouse_x_pos==0)=nan;
    mouse_y_pos(mouse_y_pos==0)=nan;
    
    
    % get the head part positions during each bout
    mouse_front_x_pos = [];
    mouse_left_x_pos = [];
    mouse_right_x_pos = [];
    mouse_middle_x_pos = [];
    mouse_bodycenter_x_pos = [];
    
    mouse_front_y_pos = [];
    mouse_left_y_pos = [];
    mouse_right_y_pos = [];
    mouse_middle_y_pos = [];
    mouse_bodycenter_y_pos = [];
    
    % trim the matrix down to just the frames included in a bout with 
    % qualifying values for minimum length and minimum y value
    for f = 1:size(mouse_time,2)
    mouse_front_x_pos(f,1:mouse_time(f)) = x_points(mouse_enters(f)+1:mouse_exits(f),1);
    mouse_front_y_pos(f,1:mouse_time(f)) = y_points(mouse_enters(f)+1:mouse_exits(f),1);
    
    mouse_left_x_pos(f,1:mouse_time(f)) = x_points(mouse_enters(f)+1:mouse_exits(f),2);
    mouse_left_y_pos(f,1:mouse_time(f)) = y_points(mouse_enters(f)+1:mouse_exits(f),2);
    
    mouse_right_x_pos(f,1:mouse_time(f)) = x_points(mouse_enters(f)+1:mouse_exits(f),3);
    mouse_right_y_pos(f,1:mouse_time(f)) = y_points(mouse_enters(f)+1:mouse_exits(f),3);
    
    mouse_middle_x_pos(f,1:mouse_time(f)) = x_points(mouse_enters(f)+1:mouse_exits(f),4);
    mouse_middle_y_pos(f,1:mouse_time(f)) = y_points(mouse_enters(f)+1:mouse_exits(f),4);
    
    mouse_bodycenter_x_pos(f,1:mouse_time(f)) = x_points(mouse_enters(f)+1:mouse_exits(f), 7);
    mouse_bodycenter_y_pos(f,1:mouse_time(f)) = y_points(mouse_enters(f)+1:mouse_exits(f), 7);
    
    mouse_x_pos(f,1:mouse_time(f)) = x_points(mouse_enters(f)+1:mouse_exits(f), 7);
    mouse_y_pos(f,1:mouse_time(f)) = y_points(mouse_enters(f)+1:mouse_exits(f), 7);
    
    end
    
    mouse_front_x_pos(mouse_front_x_pos==0) = nan;
    mouse_left_x_pos(mouse_left_x_pos==0) = nan;
    mouse_right_x_pos(mouse_right_x_pos==0) = nan;
    mouse_middle_x_pos(mouse_middle_x_pos==0) = nan;
    mouse_front_y_pos(mouse_front_y_pos==0) = nan;
    mouse_left_y_pos(mouse_left_y_pos==0) = nan;
    mouse_right_y_pos(mouse_right_y_pos==0) = nan;
    mouse_middle_y_pos(mouse_middle_y_pos==0) = nan;
    mouse_bodycenter_x_pos(mouse_bodycenter_x_pos==0) = nan;
    mouse_bodycenter_y_pos(mouse_bodycenter_y_pos==0) = nan;
    
    mouse_x_pos(mouse_x_pos==0) = nan;
    mouse_y_pos(mouse_y_pos==0) = nan;
    
    % Calculate the instantaneous velocity of the mouse with updated direction
    delta_y = movmean(gradient(mouse_y_pos),6,2);
    %mouse_velocity = delta_y; %this was written as abs(delta_y), but just converted back below, so we can ignore
    %mouse_velocity(delta_y < 0) = -mouse_velocity(delta_y < 0);
    
    %create a cell area housing the head angle (theta1) and the angular velocity
    head_angular_vel = []
    for f = 1:size(mouse_time,2)
    tempF_x = mouse_front_x_pos(f,:);
    tempF_y = mouse_front_y_pos(f,:);
    
    tempM_x = mouse_middle_x_pos(f,:);
    tempM_y = mouse_middle_y_pos(f,:);
    
    tempB_x = mouse_bodycenter_x_pos(f,:);
    tempB_y = mouse_bodycenter_y_pos(f,:);
    
    tempF_x = tempM_x - tempB_x;
    tempF_y = tempM_y - tempB_y;
    
    tempF_x = movmean(tempF_x, 3)
    tempF_y = movmean(tempF_y, 3)
    
    [theta1,rho1] = cart2pol(tempF_x,tempF_y);
    
    temp_angular_vel = gradient(theta1) * (180/pi);
    head_angular_vel(f,:) = temp_angular_vel(1,:);
    end
    
    %startbout = find(movmean(mouse_present,90)==1, 1);
    %actualentry = find(y_mid < 300,1) + startbout;
    %retreat = find(delta_y(actualentry:end) > 10, 1)

    for f = 1:size(mouse_time,2)
        trialloom = loomframes3(f) - mouse_enters(f);
        headingdirection = movmean(mouse_middle_y_pos(f,:) - mouse_bodycenter_y_pos(f,:), 6);
        runstart = find(delta_y(f,trialloom:end) > 10, 1) + trialloom;% find frame when the moving average veolicty is greater than 10 pixels/frame
        gohome = find(delta_y(f,trialloom:end) > 10, 1) + trialloom - 30;
        escapeindex = find(abs(head_angular_vel(f,gohome:end)) > 10, 1) + gohome; %find the frame where the escape response starts with head rotation
        shelter_reached = find(mouse_front_y_pos(f,escapeindex:end) > shelterthreshold, 1) + escapeindex;

        maxspeed = max(delta_y(f,escapeindex:end));
        escape_success = 0;
        
        escape_cutoff = runstart + 75; %successful escape is a return to shelter within 2.5 seconds from escape onset
        
        if shelter_reached < escape_cutoff
            escape_success = 1;
        end
    
        if shelter_reached > escape_cutoff
            escape_success = 0;
        end

        if (runstart - trialloom) > 150
            escape_success = 0;
        end
    
        if isempty(escapeindex)
            escapeindex= NaN;  % Replace with NaN
        end
    
        if isempty(maxspeed)
            maxspeed= NaN;  % Replace with NaN
        end
    
        if isempty(shelter_reached)
            shelter_reached= NaN;  % Replace with NaN
        end

        if isempty(runstart)
            runstart = NaN;
        end 
    
    lickingdirection = headingdirection(trialloom - 30);
    

    % create an output array to append to the matrix
    outputArray(f,:) = [f, (loomframes3(f)/30) , (trialloom/30), ((escapeindex - trialloom)/30), ((runstart - trialloom)/30), ((shelter_reached - trialloom)/30), escape_success, maxspeed, lickingdirection]
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