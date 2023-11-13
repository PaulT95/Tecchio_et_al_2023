
clear
clc

addpath(genpath(cd))
Frequency = 2000;

%load Contractions files
uiopen();
%% Find indexes of window analysis

win_an = [8.5 9.5];
%win_an = [7 8 9];
Index = zeros(numel(win_an),1);

for tmp = 1:numel(win_an)
    Index(tmp) = find(abs(Contraction.Time-win_an(tmp)) ==  min(abs(Contraction.Time-win_an(tmp)) ),1);
end
clear tmp
%you can potentially use ismemebertol but the tolerance is not that much
%programmable so the resulting indexes are not perfect. The method above
%is the most accurate
% tmp = ismemebertol(Contraction.Time,win_an,0.0002)
% Indexes = find(tmp);
%You can't use directly find(Contraction.Time,win_an) because it will
%always account for the length of the array

%% EMG,FL and Torque check
h = figure(1);

for tmp = 1:numel(Index)-1
    Tor(tmp,:) = mean(Contraction.Tor(Index(tmp):Index(tmp+1),:),1);
    EMG(tmp,:) = mean(Contraction.EMG(Index(tmp):Index(tmp+1),:),1);
    Ang(tmp,:) = mean(Contraction.Ang(Index(tmp):Index(tmp+1),:),1);

    if isfield(Contraction,'FL_Up')
        FL_Up(tmp,:) = mean(Contraction.FL_Up(Index(tmp):Index(tmp+1),:),1);
        %Fas_Stretch(tmp,:) = (min(Dynamic.Contraction.FL_Up,[],1)-mean(Contraction.FL_Up(Index(tmp):Index(tmp+1),:),1));
        %FL_Low(tmp,:) = mean(Contraction.FL_Low(Index(tmp):Index(tmp+1),:),1);
    end
   
    x = 1:length(Contraction.Name);

    subplot(211)
    Tor_pts = plot(x,Tor(tmp,:),'*','MarkerSize',7,'linew',2); hold on
    ylabel('Torque (Nm)')
    text(x,Tor(tmp,:),Contraction.Name,'VerticalAlignment','bottom','HorizontalAlignment','right')


    subplot(212)
    EMG_pts = plot(x,EMG(tmp,:),'*','MarkerSize',7,'linew',2); hold on
    ylabel('EMG (V)')
    text(x,EMG(tmp,:),Contraction.Name,'VerticalAlignment','bottom','HorizontalAlignment','right')


end

title('Select which trials are the reference (only 2 can be selected)')      
brush on
uicontrol('Units', 'Normalized','Position',[.85 .01 .15 .05],'String','Done',...
            'Callback','uiresume(gcf)');
        uiwait(gcf);

% Select the point
ptsSelected = logical(EMG_pts.BrushData.');

ptsSelected = EMG_pts.XData(ptsSelected);

close(h);
clear tmp


%% Check Ref

for ii = 1:length(win_an)-1

    if length(ptsSelected) == 2
        [sds,normal] = percentage_Calc(EMG(ii,ptsSelected(1)),EMG(ii,ptsSelected(2)));
        disp(['EMG: ' num2str(sds) ' (normal) ' num2str(normal)])

        [sds,normal] = percentage_Calc(Tor(ii,ptsSelected(1)),Tor(ii,ptsSelected(2)));
        disp(['Tor: ' num2str(sds) ' (normal) ' num2str(normal)])

        disp('%%%%%%%%%%%%%%%%%%%%%%%')
        %if tor %diff is less than 5% in each time win, average the two closest
        %reference
        %EMG Ref
        EMG_ref(ii) = mean([EMG(ii,ptsSelected(1)),EMG(ii,ptsSelected(2))]);
  
        %Tor Ref
        Tor_ref(ii) = mean([Tor(ii,ptsSelected(1)),Tor(ii,ptsSelected(2))]);
    else
        EMG_ref(ii) = mean(EMG(ii,ptsSelected(1)));
     
        %Tor Ref
        Tor_ref(ii) = mean(Tor(ii,ptsSelected(1)));
        %%%%%%%%%%%%

    end

end

clear ii


%% Overall checks percentage

%[sds,normal] = percentage_Calc(mean(EMG(ptsSelected(end)+1:end)), EMG_ref(1))


for n_win = 1:length(win_an)-1
    
        EMG_diff(n_win,:) = -(EMG_ref(n_win) - EMG(n_win,:)) / EMG_ref(n_win)  * 100;
        Tor_diff(n_win,:) = -(Tor_ref(n_win) - Tor(n_win,:)) / Tor_ref(n_win)  * 100;
        
end
clear n_win
%% Muscle force estimation and fascicle work

%Fascicle stretch (the first one is the Ref so it is corrected later as the
%average of the first 250ms which is rest (long length) - the value in the
%time window of analysis
% 
% F_Velocity = diff(Contraction.FL_Up,[],1)./ (1/Frequency);

%From the min to win of rFE cursors
F_Stretch =  round((FL_Up) - min(Contraction.FL_Up,[],1),1);

%% Fascicle velocity during the MTU lengthening 
Rotation_Sec = [3.990 5.10]; %window where the rotation happened, it is not constant as the isomed is not super accurate that's why is a bit "bigger"
Index = zeros(numel(Rotation_Sec),1);

for tmp = 1:numel(Rotation_Sec)
    Index(tmp) = find(abs(Contraction.Time-Rotation_Sec(tmp)) ==  min(abs(Contraction.Time-Rotation_Sec(tmp)) ),1);
end
clear tmp

F_Velocity = double.empty;

for ii = 1:length(Contraction.Name)

    if  ~(contains("ref",strsplit(string(Contraction.Name{ii}),'_'),'IgnoreCase',true)) %if it's not a ref go for it
        %FL 
        tmp = Contraction.FL_Up(Index(1):Index(2),ii);
        FL(:,ii) = interp1(linspace(0,1,diff(Index)+1),tmp,linspace(0,1,2000));

        %FV
        tmp = Contraction.F_Vel(Index(1):Index(2),ii);
        F_Velocity(:,ii) = interp1(linspace(0,1,diff(Index)+1),tmp,linspace(0,1,2000));

        subplot(2,1,1)
        plot(FL(:,ii),'LineWidth',2)
        ylabel('Fascicle Length [mm]')
        hold on

        subplot(2,1,2)
        plot(F_Velocity(:,ii),'LineWidth',2)
        ylabel('Fascicle velocity [mm/s]')
        hold on
    end

end
waitforbuttonpress
clf
clear tmp
%Save them for following SPM
F_Long = mean(Contraction.FL_Up(end-100:end, :),"all");
uisave({'FL','F_Velocity','F_Long'}, 'FL_Rot.mat');

%% Amount Fascicle shortening and work
[~,loc] = min(Contraction.FL_Up,[],1);
F_Shortening = zeros(numel(loc),1);
F_Work_Pos = zeros(numel(loc),1);
F_Work_Neg = zeros(numel(loc),1);

figure(1),clf
for ii = 1:length(loc)

 if  ~(contains("ref",strsplit(string(Contraction.Name{ii}),'_'),'IgnoreCase',true)) %if it's not a ref go for it

    %I used max as a potential stretch could happened before shortening
    F_Shortening(ii) = max(Contraction.FL_Up(1:loc(ii),ii)) - Contraction.FL_Up(loc(ii),ii);
    
    %Shortening Work
    tmp = cumsum((Contraction.F_Work(1 : loc(ii),ii)));
    F_Work_Pos(ii) = tmp(end);

    subplot(3,1,1)
    plot(Contraction.FL_Up(:,ii))
    hold on    
    plot(loc(ii),Contraction.FL_Up(loc(ii),ii),'o','LineWidth',2);
    ylabel('Fascicle length [mm]')

    subplot(3,1,2)
    plot(tmp,'LineWidth',2);
    hold on
    ylabel('Work [J]')

    %lLengthening work up to sec 5.1
    tmp = cumsum( ( Contraction.F_Work(loc(ii):Index(2),ii) ) );
    F_Work_Neg(ii) = tmp(end);   

    subplot(3,1,3)
    plot(tmp,'LineWidth',2);
    hold on
    ylabel('Work [J]')

 end

end

waitforbuttonpress
clf
clear tmp

F_Work_Pos = -F_Work_Pos';
F_Work_Neg = -F_Work_Neg';
%% During rotation
% Peak Torque and its Fas length
[Rot_Peak.Force, pos_max] = max(Contraction.M_force ./ cos(Contraction.PA),[],1);
%[Rot_Peak.Tor, pos_max] = max(Contraction.Ang,[],1);
%[~ , pos_max_Force] = max(Contraction.M_force ./ cos(Contraction.PA),[],1);

win_an = [8.5 9.5];
%win_an = [7 8 9];
Index = zeros(numel(win_an),1);

for tmp = 1:numel(win_an)
    Index(tmp) = find(abs(Contraction.Time-win_an(tmp)) ==  min(abs(Contraction.Time-win_an(tmp)) ),1);
end
clear tmp

time_pts = [0 50 100];
figure(1); clf

for ii = 1:length(pos_max)

    if  ~(contains("Ref",strsplit(string(Contraction.Name{ii}),'_'),'IgnoreCase',true)) %if it's not a ref go for it

        
        %Find relative value for each parameter
        Rot_Peak.FL(ii) = Contraction.FL_Up(pos_max(ii),ii);
        Rot_Peak.Ang(ii) = Contraction.Ang(pos_max(ii),ii);
        Rot_Peak.EMG(:,ii) = Contraction.Envelope(pos_max(ii)-time_pts,ii);
        Rot_Peak.Fv(ii) = Contraction.F_Vel(pos_max(ii),ii);

        %Rot_Peak.Tor(ii) = Contraction.Tor(pos_max(ii),ii);
        [min_v, min_loc] =  min(Contraction.FL_Up(1:pos_max(ii),ii));
        Rot_Peak.F_stretch(ii) = Contraction.FL_Up(pos_max(ii),ii) - min_v;
        Rot_Peak.F_sho(ii) = max(Contraction.FL_Up(1:min_loc,ii)) - min_v;
        
        Rot_Peak.negW_toP(ii) = sum(Contraction.F_Work(1:pos_max(ii),ii));
        %Rot_Peak.F_Force(ii) = Contraction.M_force(pos_max(ii),ii) ./ cos(Contraction.PA(pos_max(ii),ii));
        %Rot_Peak.Wafter_peak(ii) = sum(Contraction.F_Work(pos_max_Force(ii):Index(1),ii) );
        
        %jwork = cumtrapz(deg2rad(Contraction.Ang(:,ii)),  Contraction.Tor(:,ii) );
         %jwork = diff(deg2rad(Contraction.Ang(:,ii))) .* (Contraction.Tor(2:end,ii));
        %Rot_Peak.JWork(ii) = trapz(deg2rad(Contraction.Ang(pos_max(ii):Index(1),ii)), Contraction.Tor(pos_max(ii):Index(1),ii));
        
        bau = cumtrapz(deg2rad(Contraction.Ang(1:pos_max(ii),ii)), Contraction.Tor(1:pos_max(ii),ii)) ;
        
        subplot(3,1,1)
        plot(Contraction.Time,Contraction.Tor(:,ii))
        hold on
        plot(Contraction.Time(pos_max(ii)),Contraction.Tor(pos_max(ii),ii),'o','LineWidth',2)

%         subplot(3,1,2)
%         plot(Contraction.Time,Contraction.Ang(:,ii))
%         hold on
%         plot(Contraction.Time(pos_max(ii)),Contraction.Ang(pos_max(ii),ii),'o','LineWidth',2)
%         
        subplot(3,1,2)
        plot(Contraction.Time,Contraction.F_Vel(:,ii))
        hold on
        plot(Contraction.Time(pos_max(ii)),Contraction.F_Vel(pos_max(ii),ii),'o','LineWidth',2)

        subplot(3,1,3)
        plot(Contraction.Time,Contraction.FL_Up(:,ii))
        hold on
        plot(Contraction.Time(pos_max(ii)),Contraction.FL_Up(pos_max(ii),ii),'o','LineWidth',2,'Color','g')
        plot(Contraction.Time(min_loc),min_v,'o','LineWidth',2,'Color','r')
        
        hold on
    end


end

Rot_Peak.EMG = round(Rot_Peak.EMG,3);
waitforbuttonpress();
% 
% Rot_Peak.F_stretch - Rot_Peak.F_sho
% 
%  cane = - (Rot_Peak.JWork -  Rot_Peak.Wafter_peak)

return


%% Defines colors
h2 = figure(); clf
x = Contraction.Time;
Green = [0.55, 0.68, 0.06] %Green
Blu = [0, 0.21, 0.38] %blu
Orange = [212/255, 126/255, 47/255] %orange
Purple = [170/255, 100/255, 195/255] %Purple

%% Plotting
subplot(3,1,2)
hold on
%plot_mean_SDcloud(Contraction.Tor(:,2),'X',x, 'color',Green, 'linethick',1.5,'facealpha',0.25);
plot_mean_SDcloud(Contraction.Tor(:,5)-0.75,'X',x , 'color',Blu, 'linethick',1.5);
plot_mean_SDcloud(Contraction.Tor(:,8)-0.75,'X',x , 'color',Orange, 'linethick',1.5);
plot_mean_SDcloud(Contraction.Tor(:,10)-0.75,'X',x , 'color',Green, 'linethick',1.5);

ylabel('Torque (Nm)');
set(gca,'FontSize',18,'FontName','Times','Box','off')
xticks(0:1:15)
ylim([0 50])

plot_V_Line(4,'color',Blu,'linethick',1.5,'linestyle','--','trasparency',0.75)
%% Angle
subplot(4,1,2)
hold on
plot_mean_SDcloud(Contraction.Ang(:,1), 'X',x,'color',Green, 'linethick',1.5);
plot_mean_SDcloud(Contraction.Ang(:,2:end), 'X',x,'color',Blu, 'linethick',1.5);
% plot_mean_SDcloud(Contraction.Ang(:,7:8)+15, 'X',x,'color',Orange, 'linethick',1.5);
% plot_mean_SDcloud(Contraction.Ang(:,9:10)+15, 'X',x,'color',Purple, 'linethick',1.5);

ylabel('DF ← Ankle Angle → PF');
ylim([-25 40])
set(gca,'FontSize',14,'FontName','Times','Box','off')
xticks(0:1:15)

plot_V_Line(win_an,'color',Blu,'linethick',1.5,'linestyle','--','trasparency',0.75)

% plot(x, Dynamic.Contraction.Tor(:,2), 'color',[0.55, 0.68, 0.06], 'linewidth',1.5,'LineStyle','--');
% plot(x, Dynamic.Contraction.Tor(:,1), 'color',[0.55, 0.68, 0.06], 'linewidth',1.5,'LineStyle',':');
%% FL_UP
subplot(4,1,3)
hold on
plot_mean_SDcloud(Contraction.FL_Up(:,1), 'X',x,'color',Green, 'linethick',1.5);
plot_mean_SDcloud(Contraction.FL_Up(:,2), 'X',x,'color',Blu, 'linethick',1.5);
plot_mean_SDcloud(Contraction.FL_Up(:,3), 'X',x,'color',Orange, 'linethick',1.5);
plot_mean_SDcloud(Contraction.FL_Up(:,4), 'X',x,'color',Purple, 'linethick',1.5);

ylabel('Fascicle Length (mm)');
set(gca,'FontSize',14,'FontName','Times','Box','off')
xticks(0:1:15)
ylim([20 61])
%% FL_LOW
subplot(4,1,4)
hold on
plot_mean_SDcloud(Contraction.FL_Low(:,1), 'X',x,'color',Green, 'linethick',1.5);
plot_mean_SDcloud(Contraction.FL_Low(:,2), 'X',x,'color',Blu, 'linethick',1.5);
plot_mean_SDcloud(Contraction.FL_Low(:,3), 'X',x,'color',Orange, 'linethick',1.5);
plot_mean_SDcloud(Contraction.FL_Low(:,4), 'X',x,'color',Purple, 'linethick',1.5);

ylabel('Fascicle Length (mm)');
set(gca,'FontSize',14,'FontName','Times','Box','off')
xticks(0:1:15)
ylim([80 120])
xlim([0 15])
%% EMG
% subplot(4,1,4)
% hold on
% plot_mean_SDcloud(Contraction.EMG(:,1), 'X',x,'color',Green, 'linethick',1.5);
% plot_mean_SDcloud(Contraction.EMG(:,2:3), 'X',x,'color',Blu, 'linethick',1.5);
% plot_mean_SDcloud(Contraction.EMG(:,4:6), 'X',x,'color',Orange, 'linethick',1.5);
% plot_mean_SDcloud(Contraction.EMG(:,7:8), 'X',x,'color',Purple, 'linethick',1.5);
% 
% 
% xticks(0:1:15)
% ylabel('RMS 50points (V)');
% ylim([0 2.5])
% set(gca,'FontSize',14,'FontName','Times','Box','off')
% 
% vline(win_an)


%% Details

xticks(0:1:15)
xticklabels off
xticklabels(0:1:15)
xlabel("Time (s)")
set(gca,'FontSize',14,'FontName','Times','Box','off')
legend("PL 0","PL 50","PL 100")

%% Export image

exportgraphics(gcf,"ProposalFig_FasZoom.jpg",'Resolution',400)
