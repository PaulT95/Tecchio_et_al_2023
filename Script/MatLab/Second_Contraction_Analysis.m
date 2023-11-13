%% Analyze each trial for torque, angle, EMG and US data (if present)

clear
clc

Frequency = 2000;
addpath(genpath(cd));

%load moment arm data inside functions
tmp = mfilename;
tmp = erase(which(tmp),[tmp '.m']);
load([tmp '/Functions/TA_Mom_Arm.mat']); clear tmp

files = uipickfiles('FilterSpec','*.mat');

%load passive data automatically if exists otherwise open dialog to open it
[path] = fileparts(files{1});
if exist([path '/Final_Elaborated/Passive_FIT.mat'])
    load([path '/Final_Elaborated/Passive_FIT.mat']);
else
    uiopen([path '/Final_Elaborated/']);
end


US_Data = true; %if you don't have US who cares
do_shift = false;
Apo_Angle = 0;  %potential correction of pennation angle as it corresponds to the Horizontal
Ang_Cor = 0; 

for num_file = 1:length(files)
    
    % load data
    % dynamometer
    load(files{num_file});  
    
    [path,name] = fileparts(files{num_file});

    % US data automatically loaded with the same name if exists

    if (US_Data ~= false && exist([path '/US_Data/Fas_Data/' name '.mat'],'file') )

        Fascicle_data = load([path '/US_Data/Fas_Data/' name '.mat']);
        %retrieve correct US frequency
        FrequencyUS = 1 / (Fascicle_data.Fdat.Region(1).Time(end) / (Fascicle_data.TrackingData.NumFrames));
        %just remove digits
        FrequencyUS = round(FrequencyUS,0);
        % cut data if US is recorded
        %Time = US_Top.times;
        if ~isempty(US.times)
            Time = US.times;
            time_point(1) = min(Time,[],'All');
            time_point(2) = max(Time,[],'All');
        elseif ~isempty(Myon.times)
            Time = Myon.times;
            time_point(1) = min(Time,[],'All');
            time_point(2) = max(Time,[],'All');
        end
    else
        time_point = [1.0314 16.0014]; %if no US, cut the data according to this
    end

    %create Time array
    time = 0:Torque.interval:(Torque.length/Frequency);
    
    index(1) = find(time <= time_point(1),1,'last');
    index(2) = find(time >= time_point(2),1,'first');   
   
  
   %% Cut torque and angle adn EMG according to index
    
    Tor = Torque.values(index(1):index(2));
    Ang = Angle.values(index(1):index(2)); %-15 beacuse the Null point was 90°+15°
    TA_Emg = (EMG_TA.values(index(1):index(2)));

    %% Filtering data
    CutOff = 12;
    Filt_order = 4;
    
    %correct order and cut off
    [cu,order] = Wcu(Filt_order,CutOff,'low',Frequency);
    [b,a] = butter(order, cu/(0.5*Frequency),'low');
    
    Tor = filtfilt(b,a,Tor);
    Ang = filtfilt(b,a,Ang);

    %% Interpolate Fascicle data so I don't give a shit on the frequency

    if (exist("Fascicle_data",'var'))
       
        [~, m] = size(Fascicle_data.Fdat.Region); %check whether I tracked deep compartment
        if (m > 1)
            Fas_Len(1,:) = interp1(linspace(0,1,length(Fascicle_data.Fdat.Region(1).FL)),Fascicle_data.Fdat.Region(1).FL, linspace(0,1,diff(index)+1));
            PA (1,:) = interp1(linspace(0,1,length(Fascicle_data.Fdat.Region(1).PEN)),Fascicle_data.Fdat.Region(1).PEN, linspace(0,1,diff(index)+1));
            %Fas_Len(2,:) = interp1(linspace(0,1,length(Fascicle_data.Fdat.Region(2).FL)),Fascicle_data.Fdat.Region(2).FL, linspace(0,1,diff(index)+1));
        else
            Fas_Len(1,:) = interp1(linspace(0,1,length(Fascicle_data.Fdat.Region.FL)),Fascicle_data.Fdat.Region.FL, linspace(0,1,diff(index)+1));
            PA (1,:) = interp1(linspace(0,1,length(Fascicle_data.Fdat.Region.PEN)),Fascicle_data.Fdat.Region.PEN, linspace(0,1,diff(index)+1));
        end

       Fas_Len(1,:) = filtfilt(b,a,Fas_Len(1,:));
       PA(1,:) = filtfilt(b,a,PA(1,:) + deg2rad(Apo_Angle));       
%       Fas_Len(2,:) = filtfilt(b,a,Fas_Len(2,:));

    end
    
    %% Calculate Net Torque
    [~,Tor] = Normalize_Torque(Tor,Ang,Passive.polyp);
    
    if mean(Tor) < 0 %on left side torque is negative
        Tor = -Tor;
    end
    Ang = Ang + Ang_Cor; %because of the setting on the ISOMED I had a shift of 15°
   
    %% Emg filtering and analysis

    CutOff = [10 450];
    Filt_Order = 2;
    
    %correct order and cut off
    [cu,order] = Wcu(Filt_Order,CutOff,'bandpass',Frequency);
    [b,a] = butter(order, cu/(0.5*Frequency),'bandpass');    
   
    %band pass
    TA_Emg = (filtfilt(b,a,(TA_Emg)));

    %envelope
    CutOff = 5;
    Filt_Order = 2;
    
    %correct order and cut off
    [cu,order] = Wcu(Filt_Order,CutOff,'low',Frequency);
    [b,a] = butter(order, cu/(0.5*Frequency),'low');    
   
    TA_Envelope = (filtfilt(b,a,(abs(TA_Emg))));
    
    %rms 
    TA_Emg = moving_RMS(TA_Emg,Frequency,0.25,false);

    %% Muscle force estimation

    [M_force, TA_MArm] = Estimate_TendonForce_v2 (Tor, Ang, TA_Arm_Fit.polyp_MVC, 0.5);  
    
    %% Shift checks

    shift = 0; %0s
    
    if do_shift == true      
    
        if contains(name,"PL_50")
            shift = 1*Frequency; %1s
    
        elseif contains(name,"PL_0")
            shift = 2*Frequency; %2s
    
        end
        
    end

%% Put each trial in contraction struct so then I can chose which keep

    Contraction.Tor(:,num_file) = circshift(Tor,-shift);
    Contraction.Ang(:,num_file) = circshift(Ang,-shift);
    Contraction.EMG(:,num_file) = circshift(TA_Emg,-shift);
    Contraction.Name{:,num_file} = name;
    Contraction.M_force(:,num_file) = circshift(M_force,-shift);
    Contraction.Envelope(:,num_file) = circshift(TA_Envelope,-shift);

    %Fascicle stuff if fascicle data exists
    if (exist("Fas_Len",'var'))
        %Fascicle velocity       
        F_Velocity = Centered_Derivate(Fas_Len,linspace(0,length(Fas_Len)/Frequency,length(Fas_Len)) );
        
        %Fascicle displacement and work       
        F_force = (M_force ./ cos(PA)'); %PA is relatively to the Horizontal
        F_work = zeros(length(Ang),1);

        %There is a 0.5ms shift but I don't think this really matters
        F_work(2:end) = diff(Fas_Len)/1000 .* F_force(2:end)';        

        %eval(['Contractions.' name '.FL = Fas_Len']);
        Contraction.FL_Up(:,num_file) = circshift(Fas_Len(1,:),-shift);
        Contraction.PA(:,num_file) = circshift(PA(1,:),-shift);
        Contraction.F_Vel(:,num_file) = circshift(F_Velocity,-shift);
        Contraction.F_Work(:,num_file) = circshift(F_work,-shift);
        %Contraction.F_Long_Rest(num_file) = round(mean(FL_Up(end-500:end))); %Save fas at long rest for normalization
        %Contraction.FL_Low(:,num_file) = Fas_Len(2,:);
    end

    clear Fas_Len PA F_disp 

end

%time for plotting and saving in the var Contraction
Time = linspace(0,round(length(Ang)/Frequency),length(Ang));
Contraction.Time = Time';

%just plot for having a feedback
figure(1);clf
subplot(4,1,1)
plot(Time,Contraction.Tor,'linew',2);
ylabel('Torque (Nm)')
hold on
subplot(4,1,2)
plot(Time,Contraction.Ang,'linew',2);
ylabel('Angle (°)')


if (US_Data == true)
    subplot(4,1,3)
    plot(Time,Contraction.FL_Up,'linew',2);
    hold on
    %plot(Time,Contraction.FL_Low,'linew',2);
    ylabel('Fascicle Length (mm)')
end

subplot(4,1,4)
plot(Time,Contraction.EMG,'linew',2)
ylabel('EMG_R_M_S (V)')

legend('REF 15°PF','rFD','rFE')
waitforbuttonpress();
close

[filepath,name] = fileparts(files{num_file});
if ~exist([filepath '/Final_Elaborated/'], 'dir')
       mkdir([filepath '/Final_Elaborated/'])
end
%% save?
uisave('Contraction',[filepath '/Final_Elaborated/Contraction']);
