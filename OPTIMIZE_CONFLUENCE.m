% Determine optimial passage rate for clones of a given growth rate and carrying capacity

% By Bradley Fox
% P.I.: Dr. Noemi Andor

clc
clear all
close all
import bioma.data.*

%% Important Assumptions of this optimizer

% 1) A "full" petri dish (the denominator of the confluence) can be represented by the largest conal carrying capacity
% 2) A passage percent of ~0.61 minimizes changes in clonal density
% 3) Both clones remain genetically distinct, and no third clone is formed
% 4) 10 passages are completed per confluence value, and sufficient for observing difference
% 5) Value of tEnd significantly changes- minimizing tEnd makes results more precise

% UPDATE: Assumption 3 is no longer made! For third clones, update the "Initialize" portion


%% Initialize

% Clones in the form [initialSeed growthRate carryingCapacity]

clone1 = [390 2.1 4000];
clone2 = [500 2.4 3800];

cloneMatrix = [clone1' clone2'];
cloneMatrix(4,:) = cloneMatrix(1,:) / sum(cloneMatrix(1,:));

% Identify Bounds of confluence

min_confluence = 0.60;
max_confluence = 0.90;

% Percent of cells harvested per passage
passagePercent = 0.61;

%% simulate

% for each passage rate
i = 1;
minDensityError = -1;
for c = min_confluence:0.01:max_confluence
    
    % determine change/'error' in clonal composition associated with seeding count
    densityError = Manager_ODE_Passaging_Iterator_BF(c, passagePercent, cloneMatrix);
    errors_C(i) = densityError;
    
    % if the error is the smallest seen so far
    if densityError < minDensityError || minDensityError == -1
        
        % update minimum change in clonal composition
        minDensityError = densityError;
        optimal_confluence = c;
    end
    i = i + 1;
end

%% calculate divisions before splitting

% these calculations are derived from known relation that confluence = cells / max_carrying_capacity
% note that cells = init_cells*(2)^n 
% we want to solve for n
optimalCells = optimal_confluence*max(cloneMatrix(3,:));
divisions = log((optimalCells / sum(cloneMatrix(1,:)))) / log(2);

disp("Passage after this many divisions: ")
disp(divisions)
disp("Store this percentage of the petri dish for further harvesting: ")
disp(passagePercent)

%% Plot
x = min_confluence:0.01:max_confluence;

figure(1);
hold on
plot(x, errors_C, '.k')
plot(optimal_confluence, minDensityError, 'r.', 'MarkerSize', 20)
title("changes in clonal composition per confluence choice")
xlim([min_confluence max_confluence])
xlabel("confluence")
ylabel("change in clonal composition")
axis square
hold off

