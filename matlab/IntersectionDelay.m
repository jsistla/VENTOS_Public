
clear all;
close all;
clc;    % position the cursor at the top of the screen
%clf;   % closes the figure window

% ---------------------------------------------------------------

path = '../results/gui/TLData_fix3.txt';    
file_id = fopen(path);
formatSpec = '%d %f %s %s %f %f %s %d';
C_text = textscan(file_id, formatSpec, 'HeaderLines', 3);
fclose(file_id);

% ---------------------------------------------------------------
    
indices = C_text{1,1};
timeSteps = C_text{1,2};
vehicles = C_text{1,3}; 
lanes = C_text{1,4};
speeds = C_text{1,6};
signal = C_text{1,8};

% ---------------------------------------------------------------
    
% stores vehicle IDs
vIDs = {};

[rows,~] = size(vehicles);
n = indices(end,1);

% preallocating and initialization with -1
vehiclesTS = zeros(n,1) - 1;
vehiclesSpeed = zeros(n,1) - 1;

for i=1:rows   
       
    index = int32(indices(i,1));        

    % store the current TS
    vehiclesTS(index,1) = double(timeSteps(i,1));
    
    % get the current vehicle name
    vehicle = char(vehicles(i,1));
        
        vNumber = find(ismember(vIDs,vehicle));        
        if( isempty(vNumber) )
            vIDs{end+1} = vehicle;
            [~,vNumber] = size(vIDs);
        end   

        vehiclesSpeed(index,vNumber) = speeds(i,1);         
        vehiclesLane(index, vNumber) = lanes(i,1);
        vehicleSignal(index, vNumber) = signal(i,1);
end
    
[~,VehNumbers] = size(vIDs);
[rows,~] = size(vehiclesLane);

% ---------------------------------------------------------------

% vehiclesLane contains the lanes (controlled by a TL) that a vehicle traveres 
% before reaching to the intersection. We are only interested into the last lane
% that the vehicle is on before entering to the intersection.

% mark the end of each column
for i=1:VehNumbers 
    for j=rows:-1:1
        currentLane = char(vehiclesLane{j,i});
        
        if( strcmp(currentLane,'') == 1 )
            continue;
        else
            vehiclesLane{j+1,i} = ':end';
            break;
        end        
    end    
end

for i=1:VehNumbers    
    stoppingLane = '';
    startingIndex = -1;
    endingIndex = -1;
    
    for j=1:rows+1            
        currentLane = char(vehiclesLane{j,i});
        if( isempty(strfind(currentLane, ':end')) )  % if not in the center of intersection
            if( strcmp(stoppingLane,currentLane) ~= 1 )
                stoppingLane = currentLane;
                startingIndex = j;        
            end
        else
            endingIndex = j-1;
            indexDB(1,i) = startingIndex;
            indexDB(2,i) = endingIndex;
            indexDB(3,i) = endingIndex - startingIndex + 1;
            break;
        end   
    end
end

% ---------------------------------------------------------------

% extracting the vehicle speed between indexDB(1,i) and indexDB(2,i) 
% signal should also be yellow or red

waitingSpeeds = zeros( size(vehiclesTS,1), VehNumbers ) - 1;

for i=1:VehNumbers    
    for j=indexDB(1,i):indexDB(2,i)    
        if( vehicleSignal(j,i) == 1 )
            waitingSpeeds(j,i) = vehiclesSpeed(j,i)';
        end
    end
end

% ---------------------------------------------------------------

% We are only interested in the descending sections

delayBike(1,:) = waitingSpeeds(1,:);
rows = size(waitingSpeeds, 1) - 1;

for i=1:VehNumbers
    diffSpeeds(:,i) = diff( waitingSpeeds(:,i) );
    
    for j=1:rows
        if( diffSpeeds(j,i) < 0)
            delayBike(j+1,i) = waitingSpeeds(j,i);
        elseif( diffSpeeds(j,i) == 0 && waitingSpeeds(j,i) > 0 )
            delayBike(j+1,i) = -1;
        elseif( diffSpeeds(j,i) == 0 && waitingSpeeds(j,i) == 0 )
            delayBike(j+1,i) = waitingSpeeds(j,i);
        elseif( diffSpeeds(j,i) > 0)
            delayBike(j+1,i) = -1;
        else
            delayBike(j+1,i) = -1;
        end
    end
end

% -----------------------------------------------------------------

% looking for the peak with a smooth descending after that

rows = size(delayBike, 1);

% setting the starting point
for i=1:VehNumbers
    index(1,i) = -1;
    smoothDelay(:,i) = diff( delayBike(:,i) );
    
    for j=1:rows
        if( delayBike(j,i) > 0 )
            if( all(smoothDelay(j+1:j+10,i) ~= 0) && all(smoothDelay(j+1:j+10,i) < -0.05) )
                index(1,i) = j;   % starting point
                break;
            end
        end
    end
end

% setting the ending point
for i=1:VehNumbers
    index(2,i) = -1;
    
    % if we could not find any starting point then skip
    if(index(1,i) == -1)
        continue;
    else
        for j=rows:-1:1
            if( delayBike(j,i) >= 0 )
                index(2,i) = j;
                break;
            end            
        end        
    end    
end

% -----------------------------------------------------------------

% speed profile of vehicles before passing the intersection   

figure('units','normalized','outerposition',[0 0 1 1]);

counter = 1;

for i=1:VehNumbers

    figNum = floor( (i-1)/12 ) + 1;
    hf(1) = figure(figNum);
    set(gcf,'name','Speed');

    subplot(4,3,counter);    
    handle1 = plot(vehiclesTS(:,1),vehiclesSpeed(:,i),'LineWidth', 3);

    counter = counter + 1;
    % reset the counter
    if(counter == 13)
        counter = 1;
    end
    
    % set the x-axis limit
    set( gca, 'XLim', [0 vehiclesTS(end)] );
    
    % set the y-axis limit
    set( gca, 'YLim', [-2 15] );

    % set font size
    set(gca, 'FontSize', 17);

    grid on;
    
    title( char(vIDs{i}) );
    
    if( index(1,i) ~= -1 && index(2,i) ~= -1 )
        startC = [vehiclesTS(index(1,i),1), vehiclesSpeed(index(1,i),i)]; 
        endC = [vehiclesTS(index(2,i),1), vehiclesSpeed(index(1,i),i)];
        arrow(startC, endC, 'Ends', 3);
    end
end

% -----------------------------------------------------------------

% calculating the delay

delayTotal = [];
delayVeh = [];
delayBike = [];
delayPed = [];

for i=1:VehNumbers    
    if( index(1,i) ~= -1 && index(2,i) ~= -1 )
        d = vehiclesTS(index(2,i)) -  vehiclesTS(index(1,i));        
        delayTotal(end+1) = d;
        name = lower( char(vIDs{i}) );
        
        if( ~isempty(strfind(name, 'veh')) )
            delayVeh(end+1) = d;
        elseif( ~isempty(strfind(name, 'bike')) )
            delayBike(end+1) = d;
        elseif( ~isempty(strfind(name, 'ped')) )
            delayPed(end+1) = d;
        end
    end
end

fprintf('Average total delay: %0.2f s\n', mean(delayTotal));
fprintf('Average vehicle delay: %0.2f s\n', mean(delayVeh));
fprintf('Average bike delay: %0.2f s\n', mean(delayBike));
fprintf('Average pedestrian delay: %0.3f s\n', mean(delayPed));




