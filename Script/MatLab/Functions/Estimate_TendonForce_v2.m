function [ varargout ] = Estimate_TendonForce_v2 (TorSig,AngSig,p,ForceDistribution)

%% From fitted moment arm estimate muscle force for the respective angle
%  Author: Paolo Tecchio (Paolo.Tecchio@rub.de)

%% check arguments
minArgs=1;  
maxArgs=2;
nargoutchk(minArgs,maxArgs);

varargout = cell(nargout,1);

if nargin < 3
    %if empty, ASSUME the entire torque is produced by the desidered muscle
    %group and is the same of the muscle investigated. Example: from
    %literature the soleus is the major contributor of plantar flexor muscles, so the its force onto
    %the Achilles tendon is about 50-60% of the overall. 
    % So ForcDistribution = 0.50   
    ForceDistribution = 1; 
    
end


%initialize var
M_Arm = zeros(length(AngSig),1);
M_Arm = polyval(p,AngSig); %it's in cm
                               
%Estimate muscle-tendon force
M_Force = (TorSig ./ (M_Arm/100) ) * ForceDistribution;

%% Outputs
%first output is muscle force, second is the moment arm 
varargout{1} = M_Force;
varargout{2} = M_Arm;
end
