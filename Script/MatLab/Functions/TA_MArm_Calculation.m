
%% Extrapolate Tibialis Anterior Moment arm from literature
%  Author: Paolo Tecchio (Paolo.Tecchio@rub.de)

clear
clc
%% Data extrapolated from paper figures
Angles = [-15 0 15 30];
%Maganaris 2000/1999 data from MRI

TA_Arm_Rest =  [4.5518    3.4174    3.2335    3.0892];
TA_Arm_MVC =   [6.0963    4.9619    4.3028    4.0596];

%Miller et al. 2015 with rotation correction
TA_Arm_RestM = [4.3119    4.2723    3.9945    3.7663];

figure(1), clf
subplot(211)
plot(Angles,TA_Arm_Rest,'--s','LineWidth',2)
hold on
plot(Angles,TA_Arm_MVC,'--s','LineWidth',2)
plot(Angles,TA_Arm_RestM,'--s','LineWidth',2)
xlim([-20 40])
ylim([2.5 6.5])
xlabel('Angle (°)')
ylabel('Moment Arm (cm)')

%% Fit polynomial 2nd order


TA_Arm_Fit.polyp_Rest = polyfit(Angles,TA_Arm_Rest,2);
TA_Arm_Fit.polyp_MVC = polyfit(Angles,TA_Arm_MVC,2);
TA_Arm_Fit.polyp_RestMiller = polyfit(Angles,TA_Arm_RestM,2);

%create x array from min to max angle with step of 0.1 degree
%first col is angle
Ang = round(min(Angles)):0.1:round(max(Angles)+8);

subplot(212)
plot(Ang ,polyval(TA_Arm_Fit.polyp_Rest,Ang) ,'-.','LineWidth',2)
hold on
plot(Ang ,polyval(TA_Arm_Fit.polyp_MVC,Ang) ,'-.','LineWidth',2)
plot(Ang ,polyval(TA_Arm_Fit.polyp_RestMiller,Ang) ,'-.','LineWidth',2)
xlim([-20 40])
ylim([2.5 6.5])
xlabel('Angle (°)')
ylabel('Moment Arm (cm)')
legend('Maganaris Rest','Maganaris MVC','Miller Rest')

%Save as MAT to future uses
uisave('TA_Arm_Fit',[cd '/TA_Mom_Arm.mat'])
