% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%% Define ODE logistic growth: multiple clones %%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xdot = ODE_densityDependent_BF(t,x)
% growth rate and carrying capacity
global param; 

xdot = x;
for i = 1:length(x)
    xdot(i) = double(param(i,'r')) * x(i) * (1 - sum(x)/double(param(i,'K')));
end


end