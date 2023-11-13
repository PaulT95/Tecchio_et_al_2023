function [Peaks] = find_peaks_with_time(Y,X)
clc

[Peaks.pks,Peaks.locs] = findpeaks(Y,X);
Peak_Max = max(Y);
Peak_Min= min(Y);
checkhing_value = ((Peak_Max+Peak_Min)/2);
SD = std(Peaks.pks);

for i=1:length(Peaks.pks)
    
    if (Peaks.pks(i) > (checkhing_value-(SD))) && Peaks.pks(i) < (checkhing_value+(2*SD))
    Peaks.pks(i) = Peaks.pks(i);
    else
    Peaks.pks(i)=0;
    Peaks.locs(i)=0;
    end
    
end