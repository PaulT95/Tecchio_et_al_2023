function  Der_Sig  = Centered_Derivate (Sig_1y, Sig_2x)

%% Calculate first centered derivate
%  Author: Paolo Tecchio (Paolo.Tecchio@rub.de)

%% check arguments

if length(Sig_1y) ~= length(Sig_2x)
    disp('Array(s) must be the same length!!!')
    return
end

%initialize var
Der_Sig = zeros(length(Sig_1y),1);

ii=2;

while ii < length(Der_Sig)

    %Calculate the centered derivate
    Der_Sig(ii) = (Sig_1y(ii+1) - Sig_1y(ii-1)) / (Sig_2x(ii+1) - Sig_2x(ii-1));

    ii = ii+1;

end
%Put first point equals to the second
Der_Sig(1) = Der_Sig(2);
%Just put last point equal to previous one to not leaving = 0
Der_Sig(end) = Der_Sig(end-1);

end