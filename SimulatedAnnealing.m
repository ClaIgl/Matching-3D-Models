%% Setup reading files and creating point clouds
clear;clc;close all;

% reading stl files
stlData = stlread('Mand-left-cut.stl');
mand = stlData.Points;
stlData1 = stlread('Pelvis-left-cut.stl');
pelvis = stlData1.Points;

% Initial overview 3D plots of both stl objects 
figure
mand_fig = plot3(mand(:,1),mand(:,2),mand(:,3),'.');
title('mand')
figure
pelvis_fig = plot3(pelvis(:,1),pelvis(:,2),pelvis(:,3),'.');
title('pelvis')

% updating mand position, the mand point cloud is moved to the center of
% gravity of the pelvis point cloud
mand = move(mand,pelvis);

%plot of both in one figure
figure
% 3d plot of both parts intially
plot3(mand(:,1),mand(:,2),mand(:,3),'.')
hold on
plot3(pelvis(:,1),pelvis(:,2),pelvis(:,3),'k.');
% xlabel('x')
% ylabel('y')
% zlabel('z')
title('mixed')

%% Simulated Annealing algorithm
% Initialize paramters Rotation matrix to unit matrix and translation vector 
% to zero vector

alpha = 0;
beta = 0;
gamma = 0;
xt = 0;
yt = 0;
zt = 0;

parameters_best = [alpha, beta, gamma, xt, yt, zt];
parameters_current = parameters_best;

% Create matrix to remember rejected solutions to get a shorter running
% time, since the calculation of the (modified) hausdorff distance is 
% relatively time consuming and add the inital parameters 
rejected = parameters_current;

%%
% Use hausdorff distance of the inital positions as initial best value
tic
distance_best = directed_averaged_hausdorff_distance(mand, pelvis);
toc
%%
% Calculate boundaries for the solution space
x_max = max(pelvis(:,1));
x_min = min(pelvis(:,1));
y_max = max(pelvis(:,2));
y_min = min(pelvis(:,2));
z_max = max(pelvis(:,3));
z_min = min(pelvis(:,3));

% Set starting temperature for the outer loop, the max stepsize and the max
% rotation
startT = 50;
maxStep = 5;
maxRotation = 1;

while distance_best > 10^(-2)
    for T=startT:-1:1

        for v=1:5
            % randomly update parameters for rotation
            parameters_current(1) = parameters_best(1) + (rand-0.5)*2*maxRotation*T/startT;
            parameters_current(2) = parameters_best(2) + (rand-0.5)*2*maxRotation*T/startT;
            parameters_current(3) = parameters_best(3) + (rand-0.5)*2*maxRotation*T/startT;

            % randomly update parameters for translation
            parameters_current(4) = parameters_best(4) + (rand-0.5)*2*maxStep*T/startT;
            parameters_current(5) = parameters_best(5) + (rand-0.5)*2*maxStep*T/startT;
            parameters_current(6) = parameters_best(6) + (rand-0.5)*2*maxStep*T/startT;

            % transform the mand matrix
            mand_current = transformation(parameters_current, mand);
            
            % check if parameters were already rejected 
            tf = ismember(parameters_current, rejected, 'rows');
            
            % update the parameters as long as we are not in the solution space
            % or are already in the rejected parameters
            while (max(mand_current(:,1)) > x_max+5 || min(mand_current(:,1)) < x_min-5 || ...
                   max(mand_current(:,2)) > y_max+5 || min(mand_current(:,2)) < y_min-5 || ...
                   max(mand_current(:,3)) > z_max+5 || min(mand_current(:,3)) < z_min-5 || ...
                   tf)

            % record rejected parameters
            rejected = [rejected; parameters_current];

            % randomly update parameters for rotation
            parameters_current(1) = parameters_best(1) + (rand-0.5)*2*maxRotation*T/startT;
            parameters_current(2) = parameters_best(2) + (rand-0.5)*2*maxRotation*T/startT;
            parameters_current(3) = parameters_best(3) + (rand-0.5)*2*maxRotation*T/startT;

            % randomly update parameters for translation
            parameters_current(4) = parameters_best(4) + (rand-0.5)*2*maxStep*T/startT;
            parameters_current(5) = parameters_best(5) + (rand-0.5)*2*maxStep*T/startT;
            parameters_current(6) = parameters_best(6) + (rand-0.5)*2*maxStep*T/startT;

            % transform the mand matrix
            mand_current = transformation(parameters_current, mand);
            
            % check if parameters were already rejected 
            %tf = ismember(parameters_current, rejected, 'rows');
            end

            % calculated the (modified) hausdorff distance for the transformed
            % mand matrix 
            distance_current = directed_averaged_hausdorff_distance(mand_current, pelvis);
            difference = distance_current - distance_best;

            % if the new distance is smaller than the last distance accept the
            % solution
            if difference < 0
                parameters_best = parameters_current;
                distance_best = distance_current;

            % else if the new distance is not smaller than the last distance
            % accept the solution with a random probability
            elseif (exp((-difference*50)/T) > rand)
                p = exp((-difference*50)/T)
                parameters_best = parameters_current;
                distance_best = distance_current;
            end
            %rejected = [rejected; parameters_current];
            
        end

        plot3(mand_current(:,1),mand_current(:,2),mand_current(:,3),'.')
        T
        distance_best
        parameters_best
        parameters_current
        drawnow
       
    end
end

distance_best










