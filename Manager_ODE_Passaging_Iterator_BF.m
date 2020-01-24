
% Iterate through the in vitro passaging of cells
% Determine change in clonal compositions following 10 passages given
%           -Confluence at which passaging occurs
%           -Percent of cells harvested at each passage
%           -Clone cell counts, growth rates, carrying capacities, and initial dnsities

% By Bradley Fox
% P.I.: Dr. Noemi Andor

function densityError = Manager_ODE_Passaging_Iterator_BF(confluence, passagePercent, cloneMatrix)

global param;
import bioma.data.*


%% initialize

tEnd = 10;                  % max time per simulation
time = 0;                   % total time accrued
numPassages = 10;           % number of passages
newCells = false;           % true if new cells have been passaged

% number of clones
numClones = length(cloneMatrix(1,:));

% determine initial clonal densities
initDensities = cloneMatrix(4,:);

% time span to track sizes
tspan = linspace(1, tEnd, 100);

% Establish max capacity to help measure confluence
maxCapacity = max(cloneMatrix(3,:));

% Fill initially empty param DataMatrix
param = DataMatrix(ones(numClones, 2), 'ColumnNames',{'r','K'});
for j = 1:numClones
    param(j,:) = cloneMatrix(2:3, j)';
end

%% simulate

% For each passage
densityError = 0;
for i = 1:numPassages
    
%     if time >= tEnd
%         break;
%     end
%     
    % calculate cell growth over time by using ODE with parameter input
    [T, Y] = ode45(@ODE_densityDependent_BF, tspan, cloneMatrix(1,:)');
    
    % iterate through cell growth
    for j = 1:length(Y(:, 1))
        
        % update time
        time = time + (tEnd / 100);
        
        % determine confluence
        total_cells_temp = sum(Y(j,:));
        curr_confluence = total_cells_temp / maxCapacity;
        
        %%%%%%FIND FUNCTION @TODO
        % if clonal compositons have retured to the same value
        if (curr_confluence >= confluence)
            
            % passage cells
            
            newCells = true;
            
            % cell density at passaging
            densitiesTemp = Y(j,:) / total_cells_temp;
            
            % track error in density
            densityError = densityError + sum(abs(initDensities-densitiesTemp));
            
            % passaged cells are quantified
            for s = 1:length(cloneMatrix(1,:))
                cloneMatrix(1,s) = Y(j,s)*(passagePercent);
            end
        end
        
        % if cells have been passaged, move on
        if newCells
            newCells = false;
            break
        end
        
    end
end
end
