function [TKEO_simple] = TKEO (EMGsignal)
%EMG Tkeo filter based on Teager-Kaiser Energy Operator
% Authors: Paolo Tecchio


for k=2:length(EMGsignal)
    
    if k < length(EMGsignal)
        TKEO_simple(k)= abs(EMGsignal(k)^2 - EMGsignal(k+1)*EMGsignal(k-1));
        
    end
end

end