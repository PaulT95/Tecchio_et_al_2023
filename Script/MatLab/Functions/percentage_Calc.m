function [SDS,Normal] = percentage_Calc(Ref,Value)

%% Funtion to return the two percentage based on asymmetry and symmetric calculation
% Check Nuzzo et al., 2018
% check the number of input arguments
narginchk(2,2);


%Normal percentage 
Normal = (Ref - Value)/ Ref * 100;

%SDS
SDS = (Ref - Value) / (Ref + Value) * 100;
