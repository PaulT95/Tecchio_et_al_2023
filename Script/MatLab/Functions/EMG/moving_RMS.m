function [varargout] = moving_RMS(signal, frequency, winDur, Notch)
%% *Calculate a centered root-mean-square amplitude*
% moving_RMS(signal, frequency, window_length[s], Notch(true/false) )

% Author: Paolo Tecchio 
%% check arguments
minArgs=1;
maxArgs=2;
nargoutchk(minArgs,maxArgs);

varargout = cell(nargout,1);

% Set default values
if nargin < 3
    winDur = 0.025; % 25ms default time window
end

if nargin < 4
    Notch = false;
end

%% Apply Notch if it is true
if Notch == true
    Q = 100;
    wo = 50/(frequency * .5 );  
    bw = wo/Q;
    [b,a] = iirnotch(wo,bw);    
    
    %fvtool(b,a)
    signal = filtfilt(b,a,signal);
    % F_Spectrum(frequency,signal);
    % waitforbuttonpress();
end
%% Calculate window length based on window duration and frames per second
winPts = winDur/(1/frequency);
yWinDur = winPts*(1/frequency);

if rem(winPts,2) == 0 %if you entered an even number, just increase by one
    winPts = winPts+1;
    yWinDur = winPts*(1/frequency);
end

%% Remove DC offset
signal = signal-mean(signal);

%% Calculate centred root-mean-square amplitude
mov_rms_y = sqrt(movmean(signal.^2, winPts)); %final rms

%% Outputs
varargout{1} = mov_rms_y; %movmean data
varargout{2} = yWinDur; %output window length in time

end
