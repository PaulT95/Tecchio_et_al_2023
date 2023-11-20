%% Retrieve and fit passive torque values

clear
clc

%load moment arm data inside functions
tmp = mfilename;
tmp = erase(which(tmp),[tmp '.m']);
addpath([tmp '/Functions']);
files = uipickfiles('FilterSpec','*.mat');


for num_file = 1:length(files)

    load(files{num_file});

    Tor = Torque.values;
    Ang = Angle.values;
    Frequency = 1/Torque.interval;
    %% Filtering torque so then plotting in spike is easy
    CutOff = 12;
    Filt_order = 4;

    %correct order and cut off
    [cu,order] = Wcu(Filt_order,CutOff,'low',Frequency);
    [b,a] = butter(order, cu/(0.5*Frequency),'low');

    Tor = filtfilt(b,a,Tor);
    Ang = filtfilt(b,a,Ang);
    %% Cutting the rest values

    plot(Tor)
    title('Select rest torque ');
    [index,~] = ginput(2);
    close

    % rest long which is the beginning of the concentric
    Torque_values(num_file) = mean(Tor(index(1):index(2)));
    Angle_values(num_file) = mean(Ang(index(1):index(2)));


end

%fit 3rd poly
p = polyfit(Angle_values,Torque_values,3);

%create x array from min to max angle with step of 0.1 degree
Ang = round(min(Angle_values)-3):0.1:round(max(Angle_values)+3);
Tor = polyval(p,Ang);

Passive.polyp = p;

%% add control if column

%plot for fun
title('Rest fit torque')
hold on
plot(Ang,Tor,'LineWidth',2,'Color',[0.55 0.68 0.06]);
plot(Angle_values,Torque_values,'*','LineWidth',4,'color',[0 0.21 0.38]);
ylabel('Torque (Nm)')
xlabel('Crank Foot Angle (Degree)');
set(gca,'FontSize',16)
box off

[filepath,name] = fileparts(files{num_file});
if ~exist([filepath '/Final_Elaborated/'], 'dir')
       mkdir([filepath '/Final_Elaborated/'])
end

%save
uisave('Passive',[filepath '/Final_Elaborated/Passive_FIT'])
