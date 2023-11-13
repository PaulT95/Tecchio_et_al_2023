clear
clc

addpath(genpath(cd));

dir_data = uigetdir();
list = dir(dir_data);
% 
% Subj = string.empty
% for ii = 1:length(list)
%     if(list(ii).isdir)
%         Subj(ii) = list(ii).name;
%     end
% 
% end
% 
% fig = uifigure('Position', [100 100 300 250],'Name','Select Subj');
% 
% 
% lbx = uilistbox(fig,'Items',Subj);
% lbx.Multiselect = 'on';
% lbx.Value = {}; %needed for selecting first Item
% lbx.ValueChangedFcn = @listboxValChgFcn;
% 
% function listboxValChgFcn(hObj, event)
% %disp(['From event: ', event.Value])
% 
% selected = event.Value;
% 
% %disp(['From Object: ', hObj.Value])
% %within app designer the obj handle would be something like app.ListBox.Value
% 
% close(fig)
% return
% end

FL_Tot = [];
Fv_Tot = [];
n_Condition = 3; %depends on your experiment design

for num_file = 1:length(list)
    
    if exist([dir_data '/' list(num_file).name '/Final_Elaborated/FL_Rot.mat'])~=0
        load([dir_data '/' list(num_file).name '/Final_Elaborated/FL_Rot.mat']);    

        FL_0(:,num_file) = FL(:,1) / F_Long;
        FL_50(:,num_file) = FL(:,2)/ F_Long;
        FL_95(:,num_file) = FL(:,3)/ F_Long;
        
        Fv_0(:,num_file) = F_Velocity(:,1);
        Fv_50(:,num_file) = F_Velocity(:,2);
        Fv_95(:,num_file) = F_Velocity(:,3);
        
    elseif (num_file < length(list))
        n(num_file) = num_file; %check which position are not loaded
    %     FL_Tot = padconcatenation(FL_Tot,FL,2)
    %     Fv_Tot = padconcatenation(Fv_Tot,F_Velocity,2)
    end
end

%removes the zeros column from the matrix correspoding to the file not
%loaded

n(n==0)=[];
FL_0(:,n) = [];
FL_50(:,n) = [];
FL_95(:,n) = [];

Fv_0(:,n) = [];
Fv_50(:,n) = [];
Fv_95(:,n) = [];


%Create the repeated matrix
FL_Tot = padconcatenation(FL_0,FL_50,2);
FL_Tot = padconcatenation(FL_Tot,FL_95,2);
FL_Tot = FL_Tot';


Fv_Tot = padconcatenation(Fv_0,Fv_50,2);
Fv_Tot = padconcatenation(Fv_Tot,Fv_95,2);
Fv_Tot = Fv_Tot';

%% Vars for 
SUBJ = repmat(0:num_file-1,1,n_Condition);
SUBJ = reshape(SUBJ,[n_Condition*num_file,1]);
SUBJ = int64(SUBJ);
%Conditions
A = repmat(0:n_Condition-1,num_file,1);
A = reshape(A,[n_Condition*num_file,1]);
A = int64(A);


%% Fancy plot from me
figure(1), clf
Green = [0.55, 0.68, 0.06] %Green
Blu = [0, 0.21, 0.38] %blu
Orange = [212/255, 126/255, 47/255] %orange
Purple = [170/255, 100/255, 195/255] %Purple

X = linspace(-5,35,2000); 

subplot(2,1,1)
plot_mean_SDcloud(FL_0 ,'X',X,'linethick',4,'color',Blu,'facealpha',0.20);
hold on
plot_mean_SDcloud(FL_50 ,'X',X,'linethick',4,'color',Orange,'facealpha',0.20);
plot_mean_SDcloud(FL_95 ,'X',X,'linethick',4,'color',Purple,'facealpha',0.20);
yticks(0.4:0.1:0.9)

box off
ylabel('{\it f_l} / {\it f}_L_o_n_g')
legend('PL0','','PL50','','PL95')
set(gca,'FontName','Times','FontSize',22)

patch([linspace(7,14.8,5) linspace(14.8,7,5)],[ones(5,1)'*.4 ones(5,1)'*.9],'black','facealpha',0.12, 'EdgeColor','None')
patch([linspace(17.1,18.7,5) linspace(18.7,17.1,5)],[ones(5,1)'*.4 ones(5,1)'*.9],'black','facealpha',0.15, 'EdgeColor','None')

subplot(2,1,2)
plot_mean_SDcloud(Fv_0 ,'X',X,'linethick',4,'color',Blu,'facealpha',0.20);
hold on
plot_mean_SDcloud(Fv_50 ,'X',X,'linethick',4,'color',Orange,'facealpha',0.20);
plot_mean_SDcloud(Fv_95 ,'X',X,'linethick',4,'color',Purple,'facealpha',0.20);
box off
yline(0,'LineWidth',3,'LineStyle','--')
ylabel('{\it f}_v_e_l_o_c_i_t_y [mm/s]')
xlabel('DF ← Crank arm angle [°] → PF')
yticks(-100:20:40)
%legend('PL0','','PL50','','PL95')
set(gca,'FontName','Times','FontSize',22)

patch([linspace(7,14.8,5) linspace(14.8,7,5)],[ones(5,1)'*40 ones(5,1)'*-100],'black','facealpha',0.12, 'EdgeColor','None')
patch([linspace(17.1,18.7,5) linspace(18.7,17.1,5)],[ones(5,1)'*40 ones(5,1)'*-100],'black','facealpha',0.15, 'EdgeColor','None')

return

%% SPM Normality
alpha     = 0.05;
spm       = spm1d.stats.normality.anova1rm(FL_Tot, A, SUBJ);
spmi      = spm.inference(0.05);
disp(spmi)


%(2) Plot:
%close all
%figure('position', [0 0  1200 300])
% subplot(131);  plot(FL_Tot', 'k');  hold on;  title('Data')
% subplot(132);  plot(spm.residuals', 'k');  title('Residuals')
% subplot(133);  spmi.plot();  title('Normality test')
% 

%% SPM 1wanova RM

%(1) Conduct normality test:
spm       = spm1d.stats.anova1rm(FL_Tot, A, SUBJ);  %within-subjects model
spmi      = spm.inference(0.05);
disp(spmi)

%(2) Plot:
%close all
subplot(3,1,3)
cla
spmi.plot();
%spmi.plot_threshold_label();
spmi.plot_p_values();
hold on
%plot(X,spm.z, '-r','LineWidth',1.2)  %within-subjects model

plot(spm.z,'LineWidth',3,'Color',Blu)
hold on
plot_H_Line(spmi.zstar,'lineStyle','--','color',Green,'linethick',3)

%Set Tick manually
%set(gca,'XTick',0:0.1:1)
title('SPM ANOVA1rm')
set(gca,'XTickLabel',0:0.1:1)
set(gca,'FontName','Arial','FontSize',18)
set(text,'FontSize',20)
xlabel('Time [s]')

%Just for vertical line
pos = find(abs(spmi.z - spmi.zstar)  ==  min(abs(spmi.z - spmi.zstar)));

plot_V_Line(X(pos),'color',Orange,'linethick',2)
%% SPM PostHoc


%(1) Conduct SPM analysis:
t21        = spm1d.stats.ttest2(FL_0, FL_50);
t32        = spm1d.stats.ttest2(FL_0, FL_95);
t31        = spm1d.stats.ttest2(FL_50, FL_95);
% inference:
alpha      = 0.05;
nTests     = n_Condition;
p_critical = spm1d.util.p_critical_bonf(alpha, nTests);
t21i       = t21.inference(p_critical, 'two_tailed',true);
t32i       = t32.inference(p_critical, 'two_tailed',true);
t31i       = t31.inference(p_critical, 'two_tailed',true);



%(2) Plot:
figure(),clf
subplot(221);  t21i.plot();    title('PL0 - PL50')
subplot(222);  t32i.plot();    title('PL0 - PL95')
subplot(223);  t31i.plot();    title('PL50 - PL95')

