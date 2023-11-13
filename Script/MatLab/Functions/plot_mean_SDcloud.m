
function [h0]= plot_mean_SDcloud(Y, varargin)
%% Function to plot mean and variability of your data as shaded area
% Author: Paolo Tecchio 
% EXAMPLE: plot_mean_SDcloud(FL_50 ,'X',X,'linethick',4,'color',[0.23 0.34 0.45],'facealpha',0.20,'error','c95');


%% type of analysis
varChk = ["std" "c95" "sem" "var"];
%% check arguments
%parse inputs
p         = inputParser;
addOptional(p,'X',[]) %if you don't insert X
addOptional(p, 'color', 'red');
addOptional(p, 'facealpha', 0.3, @(x) isscalar(x) && (x>=0) && (x<=1) );
addOptional(p, 'linethick', 1.5, @(x) isscalar(x) && (x>=0) );
addOptional(p, 'lineStyle', '-');
addOptional(p, 'plot', gca);
addOptional(p, 'error','std', @(s) isstring(s) || ischar(s) && any(strcmp(s,varChk)==1) );% Type of error plot


p.parse(varargin{:});
X              = p.Results.X;
colore         = p.Results.color;
facealpha      = p.Results.facealpha;
linethick      = p.Results.linethick;
lineStyle      = p.Results.lineStyle;
selectedPlot   = p.Results.plot;
typeArea       = p.Results.error;


%% Just check that Y and X

%Check whether that columns are less than rows, so likely people forget to
%transpose the matrix. 

[row,col] = size(Y);
if (row>col)
    Y = Y';
end

%mean & std
[y,ys]    = deal(mean(Y,1), std(Y,1));  

%define what type of area will be plotted
%re calculate ys
switch(typeArea)
    case 'std', ys = ys;
    case 'sem', ys = (ys./sqrt(size(Y,1)));
    case 'var', ys = (ys.^2);
    case 'c95', ys = (ys./sqrt(size(Y,1))).*1.96;
end

%Check input X to create X/Time array
if(isempty(X))
    X = 0:numel(y)-1;
end

if(~isrow(X)) 
    X = X';
end
        
%% Plot the mean 

h0 = plot(selectedPlot, X, y, 'color',colore, 'linewidth',linethick,'LineStyle',lineStyle);

%% Patching the areas

if ~(row == 1 || col == 1)

    Up = flip(y+ys);
    Down = (y-ys);

    %plot the patching
    patch(selectedPlot,[X flip(X)],[Down Up], colore,'facealpha',facealpha,'FaceColo',colore, 'EdgeColor','None')
end

