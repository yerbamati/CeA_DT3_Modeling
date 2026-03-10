%% To start out, load the R.mat, Supporting Programs, and Subplot tight
clearvars -EXCEPT R Rinuse; clc;
if exist('Rinuse','var')
    priorR=Rinuse;
else
    priorR='Empty';
end

Rinuse= uigetfile('R*.mat','X:\Matilde\MatLab');
if ~strcmp(priorR,Rinuse) || ~exist('R','var'), load (Rinuse); end

addpath(genpath('\\pbs-srv2.win.ad.jhu.edu\JanakLabTest\Matilde\MatLab\Supporting Programs'));

%% Consumption LME to see effect of sex
valididx= cellfun(@(x) length(x{24})>=10, {RAW.Erast})
subject = {RAW(valididx).Subject}';
sex     = {RAW(valididx).Sex}';   % between-subject factor
dosage  = [RAW(valididx).Doseage]';     % outcome
numbneurons=cellfun(@(x) size(x,1),{RAW(valididx).Nrast});
[uniqueSubjects, ~, idx] = unique(subject);
neuronsPerSubject = accumarray(idx, numbneurons);

% Put into a table
tbl = table(subject, sex, dosage);

% Convert to categorical
tbl.subject = categorical(tbl.subject);
tbl.sex = categorical(tbl.sex);

% Map each observation to its subject
[uniqueSubjects, ~, idxSubj] = unique(subject);           

% Compute mean dosage per animal
meanPerAnimal = accumarray(idxSubj, dosage, [], @mean);   

% Overall mean consumption across all animals
overallMean = mean(meanPerAnimal);                        
overallSEM  = nanste(meanPerAnimal,1);                    % SEM across animals
disp(['Overall mean consumption: ', num2str(overallMean), ' ± ', num2str(overallSEM)])

% Get sex per unique subject (take first occurrence of each subject)
sexPerAnimal = sex(cellfun(@(x) find(strcmp(uniqueSubjects, x), 1), uniqueSubjects));
sexPerAnimal = categorical(sexPerAnimal);               

% Mean consumption by sex
maleData   = meanPerAnimal(sexPerAnimal=='M');
femaleData = meanPerAnimal(sexPerAnimal=='F');

maleMean   = mean(maleData);
femaleMean = mean(femaleData);

maleSEM    = nanste(maleData,1);
femaleSEM  = nanste(femaleData,1);

disp(['Male mean consumption: ', num2str(maleMean), ' ± ', num2str(maleSEM)])
disp(['Female mean consumption: ', num2str(femaleMean), ' ± ', num2str(femaleSEM)])


% Fit linear mixed-effects model
lme = fitlme(tbl, 'dosage ~ sex + (1|subject)');

% Show results
disp(anova(lme))
%% Autocorrelation
neuronofinterest=RAW(61).Nrast{10};

for neur=neuronofinterest
spikeTimes = neuronofinterest; % 200 spikes in 10s

% Parameters
maxLag = 1;     
binSize = 0.01;  

% Compute all pairwise differences
diffs = [];
for i = 1:length(spikeTimes)
    % time differences relative to spike i
    d = spikeTimes - spikeTimes(i);
    % keep lags within window and exclude zero
    d = d(d ~= 0 & abs(d) <= maxLag);
    diffs = [diffs; d];
end

% Bin into histogram
edges = -maxLag:binSize:maxLag;
acf = histcounts(diffs, edges);

% Plot
centers = edges(1:end-1) + binSize/2;
figure;
bar(centers*1000, acf, 'k'); % ms
xlabel('Lag (ms)');
ylabel('Count');
title('Spike Autocorrelogram for neuron' );
end
%% Plotting heatmaps of all neurons to each event
figure;
Xaxis=[-1 1];
Ishow=find(R.Param.Tm>=Xaxis(1) & R.Param.Tm<=Xaxis(2));
time1=R.Param.Tm(Ishow);
Xaxis2=[-0.5 0.5];
Ushow=find(R.Param.Tm>=Xaxis2(1) & R.Param.Tm<=Xaxis2(2));
time2=R.Param.Tm(Ushow);

inh=[0.1 0.021154 0.6];
inhfirst5 = [0.0039 0.5922 0.6];
inhlast5 = [0.5922 0.058 0.6];
inhf5l5 = [inhfirst5; inhlast5];
exc=[0.9 0.75 0.205816];
excfirst5 = [0.21 0.8157 0.0314];
exclast5 = [0.95 0.5373 0.0314];
excf5l5 = [excfirst5;exclast5];


% Creates an index variable to identify data associated with each event
%Eventlist={'LeverInsertion'; 'LeverRetract'; 'LeverPress1';'LeverPress2';'EndPress';'RewardDeliv';...
%   'PEntryRD';'LickRD';'Licklast';'EndofRD'};
Eventlist={'LeverInsertion';'LeverPress'; 'LeverRetract';'PEntrynoRD';'PEntryRD';'LickRD';'EndofRD'};
cols= 8;
height=ceil(length(Eventlist)/(cols/2))*2;

i=1;
Reg=true(length(R.Ninfo),1); %change this to Reg=strcmp(R.Type,'DOI'): or
% 'SAL' and it'll plot only those neurons

% sets color map & plotting specifications
[magma,inferno,plasma,viridis]=colormaps;
colormap(plasma);
c=[-100 2000];ClimE=sign(c).*abs(c).^(1/2);%colormap

%select neurons of interest,
additional=questdlg('All or subdivided?','all or sub','All','Subdivided','All');
if strcmp(additional,'Subdivided')
    whichq=questdlg('Which neurons would you like to pull?','Neurons','By Sex','By Region','By Animal', 'By Region');
end
if exist('whichq','var') && strcmp(whichq,'By Animal')
    animaldivide=questdlg('Separate high contribution rats from low contribution rats?','animaldivide','yes','no','no');
end
Sel = ones(size(R.Ev(1).RespDir), 'logical');
SpecialSel= logical(R.Bmean>1);
sexidx=unique(R.Subject(:,2));
sexcolors=[0.922, 0.467, 0.812;0.133, 0.482, 0.788];
regions=unique(R.Ninfo(:,4));
regioncolors=[0.2578,0.9336,0; 0,0.9336,0.7773;0.8203,0.0664,0.9258];
[names,~,ratidx]=unique(R.Subject(:,1));
proportionneurons_perrat=accumarray(ratidx,1)/size(R.Subject(:,2),1);
proportionidx=[];
highpropcounter=2;
for rat=1:size(proportionneurons_perrat,1)
    if proportionneurons_perrat(rat)<0.15
        proportionidx(ratidx==rat,:)=1;
    else
        proportionidx(ratidx==rat,:)=highpropcounter;
        highpropcounter=highpropcounter+1;
    end
end
nShades=length(unique(R.Subject(strcmp(R.Subject(:,2),'F'),1)));
idx = linspace(0, 1, nShades);
% Interpolate the RGB values for darkest pink to lightest pink
red_values = 1 + (1 - 1) * idx;    % Red goes from 1 to 1 (max red intensity)
green_values = 0.3 + (0.8 - 0.3) * idx; % Green goes from 0.3 to 0.8
blue_values = 0.4 + (0.9 - 0.4) * idx;  % Blue goes from 0.4 to 0.9
pinkShades = [red_values', green_values', blue_values'];
[~,pinkidx]=ismember(unique(R.Subject(strcmp(R.Subject(:,2),'F'))),unique(R.Subject(:,1)));
nShades=length(unique(R.Subject(strcmp(R.Subject(:,2),'M'),1)));
idx = linspace(0, 1, nShades);
% Interpolate the RGB values for darkest pink to lightest pink
red_values = 0 + (0.5 - 0) * idx;    % Red goes from 0 to 0.5
green_values = 0 + (0.8 - 0) * idx;  % Green goes from 0 to 0.8
blue_values = 0.5 + (1 - 0.5) * idx; % Blue goes from 0.5 to 1
blueShades = [red_values', green_values', blue_values'];
[~,blueidx]=ismember(unique(R.Subject(strcmp(R.Subject(:,2),'M'))),unique(R.Subject(:,1)));
colord(pinkidx,:)=pinkShades;
colord(blueidx,:)=blueShades;
proportioncolors=colord;
proportioncolors(proportionneurons_perrat<0.15,:)=[];
proportioncolors=[0.5,0.5,0.5;proportioncolors];

x=1;
y=x+cols;

% If the event list exceeds 12, you will need to work on this section to
% make new figures in the below for loop
% % if rem(length(Eventlist),12)==1
% %     figflag == 1;
% %     numFigs = floor(length(Eventlist)/12);
% % end

% for loop for sorting neurons based on activity and plotting heat plots
% for each event
heatplotdims=[0.06,0.05];
devdims= [0.04,0.05];

for j=1:numel(Eventlist)
    Eventindex = strcmp(Eventlist{j}, R.Erefnames);

    %sort each event's heatmap by magnitude of response
    Neurons=R.Ev(Eventindex).PSTHz(Sel,Ishow); %get the firing rates of neurons of interest
    % TMP=R.Ev(Eventindex).Meanz(Sel); %find the magnitude of the inhibitions for this event
    % TMP(isnan(TMP))=0; %To place the neurons with no onset/duration/peak at the top of the color-coded map
    % [~,SORTimg]=sort(TMP);
    % Neurons=Neurons(SORTimg,:); %sort the neurons by magnitude
    TMPi=R.Ev(Eventindex).Meanz(R.Ev(Eventindex).RespDir==-1 & SpecialSel); %find the magnitude of the inhibitions for this event
    TMPi(isnan(TMPi))=0; %To place the neurons with no onset/duration/peak at the top of the color-coded map
    [~,SORTimgi]=sort(TMPi);
    overallidx=find(R.Ev(Eventindex).RespDir==-1 & SpecialSel);
    SORTimgioverall=overallidx(SORTimgi);
    TMPn=R.Ev(Eventindex).Meanz(R.Ev(Eventindex).RespDir==0 & SpecialSel); %find the magnitude of the inhibitions for this event
    TMPn(isnan(TMPn))=0; %To place the neurons with no onset/duration/peak at the top of the color-coded map
    [~,SORTimgn]=sort(TMPn);
    overallidx=find(R.Ev(Eventindex).RespDir==0 & SpecialSel);
    SORTimgnoverall=overallidx(SORTimgn);
    TMPe=R.Ev(Eventindex).Meanz(R.Ev(Eventindex).RespDir==1 & SpecialSel); %find the magnitude of the inhibitions for this event
    TMPe(isnan(TMPe))=0; %To place the neurons with no onset/duration/peak at the top of the color-coded map
    [~,SORTimge]=sort(TMPe);
    overallidx=find(R.Ev(Eventindex).RespDir==1 & SpecialSel);
    SORTimgeoverall=overallidx(SORTimge);
    Neurons=Neurons([SORTimgioverall;SORTimgnoverall;SORTimgeoverall],:); %sort the neurons by magnitude
    if length(Neurons)~=length(SpecialSel)
        imageSel=SpecialSel;
        imageSel(isnan(R.Ev(Eventindex).RespDir))=0;
    else
        imageSel=SpecialSel;
    end
    % each event's heatmap
    subplot_tight(height,cols,[x y]+(i-1)*6, heatplotdims);
    imagesc(time1,[1,sum(imageSel,1)],Neurons,ClimE); title([Eventlist{j} ' responses'], 'FontSize', 8);
    cb=colorbar;
    set(cb,'YDir','reverse');
    if j==1
        ylabel('Individual neurons sorted by response strength', 'fontsize', 8);
        xlabel(['Seconds post ' Eventlist{j}], 'fontsize', 5);
    end
    hold on;
    plot([0 0],[0 sum(imageSel)],':','color','k','linewidth',0.75);
    if rem(j,cols/2)==0
        x=x+cols+2;
        y=y+cols+2;
    elseif rem(j,cols/2)~=0
        x=x+2;
        y=y+2;
    end
    yline(length(TMPi)+0.5,'-w')
    yline(length(TMPi)+length(TMPn)+0.5,'-w')
end

x=2;
y=x+cols;
% for loop creating average firing shape figures for signifcantly inhibited
% and excited neurons
for j=1:numel(Eventlist)
    Eventindex = strcmp(Eventlist{j}, R.Erefnames);

    % Plotting neurons that respond to the lever insertion
    %inhibitions
    SelIn=R.Ev(Eventindex).RespDir<0 & SpecialSel; %Find neurons that have an inhibitory response to this event
    if sum(SelIn)~=0
        %     %average firing rate
        %added to fix aesthetics of plotting after -250 to 0 ms prewindow
        %referencing
        aa = R.Ev(Eventindex).PSTHz(SelIn,Ishow);
        aa(isinf(aa))=NaN;
        R.Ev(Eventindex).PSTHz(SelIn,Ishow) = aa;
        subplot_tight(height,cols,x+(i-1)*6,devdims);
        hold on;
        if exist('whichq','var')
            if strcmp(whichq,'By Animal') & strcmp(animaldivide,'no')
                for rat=1:max(ratidx)
                    SelPlot= SelIn & strcmp(R.Subject(:,1),names(rat));
                    if sum(SelPlot)>0
                        psthI=mean(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
                        semI=nanste(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1); %calculate standard error of the mean
                        upI(rat,:)=psthI;
                        downI(rat,:)=psthI;
                        color=colord(rat,:);
                        %                  p3=patch([time1,time1(end:-1:1)],[upI,downI(end:-1:1)],color,'EdgeColor','none');alpha(0.25);
                        plot3=plot(time1,psthI,'Color',color,'linewidth',0.1); title('Mean firing (z-score)'); %create plot of avg firing rate
                        o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
                        o2=plot([0 0],[-30 40],':','color','k','linewidth',0.75);
                        o1.Annotation.LegendInformation.IconDisplayStyle = 'off';
                        o2.Annotation.LegendInformation.IconDisplayStyle = 'off';
                    end
                end
                axis([-1 1 min(min(downI))-1 max(max(upI))+1]);
            elseif strcmp(whichq,'By Animal') & strcmp(animaldivide,'yes')
                for ratgroup=1:max(proportionidx)
                    SelPlot= SelIn & proportionidx==ratgroup;
                    if sum(SelPlot)>0
                        psthI=mean(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
                        semI=nanste(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1); %calculate standard error of the mean
                        upI(ratgroup,:)=psthI+semI;
                        downI(ratgroup,:)=psthI-semI;
                        color=proportioncolors(ratgroup,:);
                        p3=patch([time1,time1(end:-1:1)],[upI(ratgroup,:),downI(ratgroup,end:-1:1)],color,'EdgeColor','none');alpha(0.25);
                        plot3=plot(time1,psthI,'Color',color,'linewidth',0.5); title('Mean firing (z-score)'); %create plot of avg firing rate
                        o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
                        o2=plot([0 0],[-30 40],':','color','k','linewidth',0.75);
                        o1.Annotation.LegendInformation.IconDisplayStyle = 'off';
                        o2.Annotation.LegendInformation.IconDisplayStyle = 'off';
                    end
                end
                axis([-1 1 min(min(downI))-1 max(max(upI))+1]);
            elseif strcmp(whichq,'By Sex')
                for sex=[1 2]
                    SelPlot= SelIn & strcmp(R.Subject(:,2),sexidx{sex});
                    if sum(SelPlot)>0
                        psthI=mean(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
                        semI=nanste(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1); %calculate standard error of the mean
                        upI(sex,:)=psthI+semI;
                        downI(sex,:)=psthI-semI;
                        color=sexcolors(sex,:);
                        p3=patch([time1,time1(end:-1:1)],[upI(sex,:),downI(sex,end:-1:1)],color,'EdgeColor','none');alpha(0.25);
                        plot3=plot(time1,psthI,'Color',color,'linewidth',1); title('Mean firing (z-score)'); %create plot of avg firing rate
                        o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
                        o2=plot([0 0],[-30 40],':','color','k','linewidth',0.75);
                        o1.Annotation.LegendInformation.IconDisplayStyle = 'off';
                        o2.Annotation.LegendInformation.IconDisplayStyle = 'off';
                    end
                end
                axis([-1 1 min(min(downI))-1 max(max(upI))+1]);
            elseif strcmp(whichq,'By Region')
                for region=1:3
                    SelPlot= SelIn & strcmp(R.Ninfo(:,4),regions{region});
                    if sum(SelPlot)>0
                        psthI=mean(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
                        semI=nanste(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1); %calculate standard error of the mean
                        upI(region,:)=psthI+semI;
                        downI(region,:)=psthI-semI;
                        color=regioncolors(region,:);
                        p3=patch([time1,time1(end:-1:1)],[upI(region,:),downI(region,end:-1:1)],color,'EdgeColor','none');alpha(0.25);
                        plot3=plot(time1,psthI,'Color',color,'linewidth',1); title('Mean firing (z-score)'); %create plot of avg firing rate
                        o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
                        o2=plot([0 0],[-30 40],':','color','k','linewidth',0.75);
                        o1.Annotation.LegendInformation.IconDisplayStyle = 'off';
                        o2.Annotation.LegendInformation.IconDisplayStyle = 'off';
                    end
                end
                axis([-1 1 min(min(downI))-1 max(max(upI))+1]);
            end
        end
        if strcmp(additional,'All') || strcmp(whichq,'By Animal')
            psthI=mean(R.Ev(Eventindex).PSTHz(SelIn,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
            semI=nanste(R.Ev(Eventindex).PSTHz(SelIn,Ishow),1); %calculate standard error of the mean
            upI=psthI+semI;
            downI=psthI-semI;
            p3=patch([time1,time1(end:-1:1)],[upI,downI(end:-1:1)],inh,'EdgeColor','none');alpha(0.5);
            plot3=plot(time1,psthI,'Color',inh,'linewidth',2); title('Mean firing (z-score)'); %create plot of avg firing rate
            if exist('animaldivide','var')
                uistack(p3,'bottom');uistack(plot3,'bottom')
            end
            o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
            o2=plot([0 0],[-30 40],':','color','k','linewidth',0.75);
            o1.Annotation.LegendInformation.IconDisplayStyle = 'off';
            o2.Annotation.LegendInformation.IconDisplayStyle = 'off';
            if strcmp(additional,'All')
                axis([-1 1 min(downI)-1 max(upI)+1]);
            end
        end
        title([Eventlist{j} ' inhib. (' num2str(round(100*sum(SelIn)/sum(SpecialSel))) '%)'],'fontsize',8)
        ylabel('Z-score');
    end

    %excitation
    SelEx=Reg&R.Ev(Eventindex).RespDir>0 & SpecialSel; %Find neurons that have an excitatory response to this event
    %average firing rate
    if sum(SelEx)~=0
        dd = R.Ev(Eventindex).PSTHz(SelEx,Ishow);
        dd(isinf(dd))=NaN;
        R.Ev(Eventindex).PSTHz(SelEx,Ishow) = dd;
        subplot_tight(height,cols,y+(i-1)*6,devdims);
        hold on
        if exist('whichq','var')
            if strcmp(whichq,'By Animal') & strcmp(animaldivide,'no')
                for rat=1:max(ratidx)
                    SelPlot= SelEx & strcmp(R.Subject(:,1),names(rat));
                    if sum(SelPlot)>0
                        psthE=mean(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
                        semE=nanste(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1); %calculate standard error of the mean
                        upE(rat,:)=psthE;
                        downE(rat,:)=psthE;
                        color=colord(rat,:);
                        %                 p3=patch([time1,time1(end:-1:1)],[upE,downE(end:-1:1)],color,'EdgeColor','none');alpha(0.1);
                        plot3=plot(time1,psthE,'Color',color,'linewidth',0.1); title('Mean firing (z-score)'); %create plot of avg firing rate
                        o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
                        o2=plot([0 0],[-30 40],':','color','k','linewidth',0.75);
                        o1.Annotation.LegendInformation.IconDisplayStyle = 'off';
                        o2.Annotation.LegendInformation.IconDisplayStyle = 'off';
                    end
                end
                axis([-1 1 min(min(downE))-1 max(max(upE))+1]);
            elseif strcmp(whichq,'By Animal') & strcmp(animaldivide,'yes')
                for ratgroup=1:max(proportionidx)
                    SelPlot= SelEx & proportionidx==ratgroup;
                    if sum(SelPlot)>0
                        psthE=mean(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
                        semE=nanste(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1); %calculate standard error of the mean
                        upE(ratgroup,:)=psthE+semE;
                        downE(ratgroup,:)=psthE-semE;
                        color=proportioncolors(ratgroup,:);
                        p3=patch([time1,time1(end:-1:1)],[upE(ratgroup,:),downE(ratgroup,end:-1:1)],color,'EdgeColor','none');alpha(0.25);
                        plot3=plot(time1,psthE,'Color',color,'linewidth',0.5); title('Mean firing (z-score)'); %create plot of avg firing rate
                        o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
                        o2=plot([0 0],[-30 40],':','color','k','linewidth',0.75);
                        o1.Annotation.LegendInformation.IconDisplayStyle = 'off';
                        o2.Annotation.LegendInformation.IconDisplayStyle = 'off';
                    end
                end
                axis([-1 1 min(min(downE))-1 max(max(upE))+1]);
            elseif strcmp(whichq,'By Sex')
                for sex=[1 2]
                    SelPlot= SelEx & strcmp(R.Subject(:,2),sexidx{sex});
                    if sum(SelPlot)>0
                        psthE=mean(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
                        semE=nanste(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1); %calculate standard error of the mean
                        upE(sex,:)=psthE+semE;
                        downE(sex,:)=psthE-semE;
                        color=sexcolors(sex,:);
                        p3=patch([time1,time1(end:-1:1)],[upE(sex,:),downE(sex,end:-1:1)],color,'EdgeColor','none');alpha(0.25);
                        plot3=plot(time1,psthE,'Color',color,'linewidth',1); title('Mean firing (z-score)'); %create plot of avg firing rate
                        o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
                        o2=plot([0 0],[-30 40],':','color','k','linewidth',0.75);
                        o1.Annotation.LegendInformation.IconDisplayStyle = 'off';
                        o2.Annotation.LegendInformation.IconDisplayStyle = 'off';
                    end
                end
                axis([-1 1 min(min(downE))-1 max(max(upE))+1]);
            elseif strcmp(whichq,'By Region')
                for region=1:3
                    SelPlot= SelEx & strcmp(R.Ninfo(:,4),regions{region});
                    if sum(SelPlot)>0
                        psthE=mean(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
                        semE=nanste(R.Ev(Eventindex).PSTHz(SelPlot,Ishow),1); %calculate standard error of the mean
                        upE(region,:)=psthE+semE;
                        downE(region,:)=psthE-semE;
                        color=regioncolors(region,:);
                        p3=patch([time1,time1(end:-1:1)],[upE(region,:),downE(region,end:-1:1)],color,'EdgeColor','none');alpha(0.25);
                        plot3=plot(time1,psthE,'Color',color,'linewidth',1); title('Mean firing (z-score)'); %create plot of avg firing rate
                        o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
                        o2=plot([0 0],[-30 40],':','color','k','linewidth',0.75);
                        o1.Annotation.LegendInformation.IconDisplayStyle = 'off';
                        o2.Annotation.LegendInformation.IconDisplayStyle = 'off';
                    end
                end
                axis([-1 1 min(min(downE))-1 max(max(upE))+1]);
            end
        end
        if strcmp(additional,'All') || strcmp(whichq,'By Animal')
            psthE=mean(R.Ev(Eventindex).PSTHz(SelEx,Ishow),1,'omitnan');
            semE=nanste(R.Ev(Eventindex).PSTHz(SelEx,Ishow),1); %calculate standard error of the mean
            upE=psthE+semE;
            downE=psthE-semE;
            p3=patch([time1,time1(end:-1:1)],[upE,downE(end:-1:1)],exc,'EdgeColor','none');alpha(0.5);
            plot3=plot(time1,psthE,'Color',exc,'linewidth',3);
            if exist('animaldivide','var')
                uistack(p3,'bottom');uistack(plot3,'bottom')
            end
            o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
            o2=plot([0 0],[-20 60],':','color','k','linewidth',0.75);
            if strcmp(additional,'All')
                axis([-1 1 min(downE)-1 max(upE)+1]);
            end
        end
        title([Eventlist{j} ' excit. (' num2str(round(100*sum(SelEx)/sum(SpecialSel))) '%)'],'fontsize',8)
        ylabel('Z-score');
    end
    if rem(j,cols/2)==0
        x=x+cols+2;
        y=y+cols+2;
    elseif rem(j,cols/2)~=0
        x=x+2;
        y=y+2;
    end

end
text(3,43,char(regexp(Rinuse, '(?<=R)(.*?)(?=_)', 'match')),'FontSize',20)
PieChart = figure;
newColors = [inh; exc; 0.7 0.7 0.7]; colormap(newColors);
set(PieChart, 'colormap', newColors);
% Pie chart
Eventlist={'LeverInsertion';'LeverPress'; 'LeverRetract';'PEntrynoRD';'PEntryRD';'LickRD';'EndofRD'};
cols= 4;
height=ceil(length(Eventlist)/(cols));
x=1;
for j=1:numel(Eventlist)
    Eventindex = strcmp(Eventlist{j}, R.Erefnames);

    %inhibitions, excitations, and no response
    SelIn=R.Ev(Eventindex).RespDir<0 & SpecialSel; %Find neurons that have an inhibitory response to this event
    SelEx=R.Ev(Eventindex).RespDir>0 & SpecialSel;
    SelNo=R.Ev(Eventindex).RespDir==0 & SpecialSel;

    %percentage for each event
    piemat=[sum(SelIn) sum(SelEx) sum(SelNo)]; %piemat does not add up to the number of neurons?
    %plot them
    subplot_tight(height,cols,x,[0.04]);
    % Define 3 colors, one for each of the 3 wedges
    h = pie(piemat);
    ax = gca();
    title([Eventlist{j} ' response %'])
    x=x+1;
    display(sum(piemat));

end
pielegend=legend({'Inhib.','Excit.','No Response'});
set(pielegend, 'Position',[0.903253511469392 0.0509598555989272 0.062499998928979 0.0523560195381104]);
%need to finalize this
SexPie=figure;
colors=[0.969,0.698,0.843;0.584,0.58,0.878]; colormap(colors);
set(SexPie,'colormap',colors);
if  contains(Rinuse,'RApple')
    F={'FR09','FR10','FR12','FR13'};
    M={'FR07','FR11'};
elseif contains(Rinuse,'RSuperJazz')
    F={'FR22','FR28'};
    M={'FR21','FR23','FR25','FR27'};
elseif contains(Rinuse,'RSuperApple')
    F={'FR09','FR10','FR12','FR13','FR22','FR28'};
    M={'FR07','FR11','FR21','FR23','FR25','FR27'};
elseif contains(Rinuse,'RGrape')
    F={'FR30','FR32'};
    M={'FR29','FR33'};
elseif contains(Rinuse,'RMelon')
    F={'FR36','FR38','FR40'};
    M={'FR35','FR37','FR39'};
elseif contains(Rinuse,'RMelonOMT')
    F={'FR38','FR40'};
    M={'FR37','FR39'};
end
sexes={'F','M'};
colors=[repmat(colors(1,:),[length(F)],1);repmat(colors(2,:),[length(M)],1)];
idsbysex={F,M};
numpersex=[];
numperrat_bysex =[];
for sex=1:length(sexes)
    numpersex(sex)=sum(strcmp(R.Subject(:,2), sexes{sex}));
    for rat=1:length(idsbysex{sex})
        numperrat_bysex(sex,rat)=sum(cellfun(@(x) strcmp(x, idsbysex{sex}(rat)),R.Subject(:,1)));
    end
end
numperrat_bysex=[numperrat_bysex(1,:),numperrat_bysex(2,:)];
numperrat_bysex(numperrat_bysex==0)=[];
h=piechart(numperrat_bysex,cat(2,F,M));
h.ColorOrder=colors;
h.LabelStyle='name';


%% Signals as a function of trial type
figure;
%Comparing RD vs Omitted Trials
Xaxis=[-10 10];
Yaxisin=[-10 10];
Yaxisex=[-10 10];
Ishow=find(R.Param.Tm>=Xaxis(1) & R.Param.Tm<=Xaxis(2));
time1=R.Param.Tm(Ishow);
Xaxis2=[-1.5 1.5];
Ushow=find(R.Param.Tm>=Xaxis2(1) & R.Param.Tm<=Xaxis2(2));
time2=R.Param.Tm(Ushow);

inhNoRD = [0.3 0.3 0.3];
inhRD = [0.01 0.87 0.02];
excNoRD = [0.3 0.3 0.3];
excRD = [0.01 0.87 0.02];
inhhm = [0.77 0.1 0.37];
inhlm = [0.2 0.28 0.45];
inhhmlm = [inhhm; inhlm];
exchm = [0.77 0.1 0.37];
exclm = [0.2 0.28 0.45];
exchmlm = [exchm;exclm];


% Creates an index variable to identify data associated with each event
Eventlist={'LeverInsertion';'LeverInsertionRD';'LeverInsertionNoRD'; 'LeverRetract';'LeverRetractRD';'LeverRetractNoRD'};
i=1;
Reg=true(length(R.Ninfo),1); %change this to Reg=strcmp(R.Type,'DOI'): or
% 'SAL' and it'll plot only those neurons

% sets color map & plotting specifications
[magma,inferno,plasma,viridis]=colormaps;
colormap(plasma);
cRD=[-100 2000];ClimE=sign(cRD).*abs(cRD).^(1/4);%colormap for RD trials
cOM=[-100 2000];ClimE=sign(cOM).*abs(cOM).^(1/4);%colormap for OM trials

%get all neurons, using the first event as a guide
Sel= logical(R.Bmean>1); %ones(size(R.Ev(1).RespDir), 'logical');
%SelGLM= [logical(R.Bmean>1) & selective(:,1),logical(R.Bmean>1) & selective(:,2)];

x=1;
y=5;

EOI={'LeverInsertion'; 'LeverRetract'};
% for loop creating average firing shape figures for signifcantly inhibited
% and excited neurons
for j=1:numel(EOI)
    Eventindex = strcmp(EOI{j}, R.Erefnames);
    %     if j==1
    %         Sel=LIK;
    %     elseif j==2
    %         Sel=LRK;
    %     elseif j==3
    %         Sel=PEK;
    %     end
    if ismember(EOI{j},{'LeverInsertion','LeverRetract'})
        NoRDEventindex = strcmp(strcat(EOI{j},'NoRD'),R.Erefnames);
        RDEventindex=strcmp(strcat(EOI{j},'RD'),R.Erefnames);
    elseif strcmp(EOI{j},'PEntry')
        NoRDEventindex = strcmp(strcat(EOI{j},'NoRDtrial1'),R.Erefnames);
        RDEventindex=strcmp(strcat(EOI{j},'RD'),R.Erefnames);
    end
    % Plotting neurons that respond to the lever insertion
    %inhibitions
    SelIn=R.Ev(Eventindex).RespDir<0 & Sel; %Find neurons that have an inhibitory response to this event
    SelInNoRD=R.Ev(NoRDEventindex).RespDir<0 & Sel;
    SelInRD=R.Ev(RDEventindex).RespDir<0 & Sel;
    if sum(SelIn)~=0
        %     %average firing rate
        subplot_tight(2,4,x+(i-1)*4,[0.06,0.03]);
        psthI=mean(R.Ev(Eventindex).PSTHz(SelIn,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
        semI=nanste(R.Ev(Eventindex).PSTHz(SelIn,Ishow),1); %calculate standard error of the mean
        upI=psthI+semI;
        downI=psthI-semI;
        hold on;
        if ismember(EOI{j},{'LeverInsertion','LeverRetract'})
            psthINoRD=mean(R.Ev(NoRDEventindex).PSTHz(SelIn,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
            semINoRD=nanste(R.Ev(NoRDEventindex).PSTHz(SelIn,Ishow),1); %calculate standard error of the mean
            upINoRD=psthINoRD+semINoRD;
            downINoRD=psthINoRD-semINoRD;            
            p1=patch([time1,time1(end:-1:1)],[upINoRD,downINoRD(end:-1:1)],inhNoRD,'EdgeColor','none');alpha(0.5);
            plot1=plot(time1,psthINoRD,'Color',inhNoRD,'linewidth',1); title('Mean firing (z-score)'); %create plot of avg firing rate
        end
        psthIhm=mean(R.Ev(Eventindex).PSTHhmz(SelIn,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
        semIhm=nanste(R.Ev(Eventindex).PSTHhmz(SelIn,Ishow),1); %calculate standard error of the mean
        upIhm=psthIhm+semIhm;
        downIhm=psthIhm-semIhm;
        psthIlm=mean(R.Ev(Eventindex).PSTHlmz(SelIn,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
        semIlm=nanste(R.Ev(Eventindex).PSTHlmz(SelIn,Ishow),1); %calculate standard error of the mean
        upIlm=psthIlm+semIlm;
        downIlm=psthIlm-semIlm;
        %         psthIRD=mean(R.Ev(RDEventindex).PSTHz(SelIn,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
        %         semIRD=nanste(R.Ev(RDEventindex).PSTHz(SelIn,Ishow),1); %calculate standard error of the mean
        %         upIRD=psthIRD+semIRD;
        %         downIRD=psthIRD-semIRD;
        [inhmax,inhmaxidx]=max(psthI);
        p2=patch([time1,time1(end:-1:1)],[upIlm,downIhm(end:-1:1)],inhlm,'EdgeColor','none');alpha(0.5);
        plot2=plot(time1,psthIlm,'Color',inhlm,'linewidth',1); title('Mean firing (z-score)'); %create plot of avg firing rate
        p3=patch([time1,time1(end:-1:1)],[upIhm,downIhm(end:-1:1)],inhhm,'EdgeColor','none');alpha(0.5);
        plot3=plot(time1,psthIhm,'Color',inhhm,'linewidth',1); title('Mean firing (z-score)'); %create plot of avg firing rate
        ax=gca;
        ax.FontSize = 8;
        %p3=patch([time1,time1(end:-1:1)],[upI,downI(end:-1:1)],inh,'EdgeColor','none');alpha(0.5);
        %plot3=plot(time1,psthI,'Color',inh,'linewidth',1); title('Mean firing (z-score)'); %create plot of avg firing rate
        if ismember(EOI{j},{'LeverInsertion','LeverRetract','PEntry'})
            NoRD_str=['Omitted Trials']; % removed for poster Fold change = ' num2str(foldchangeINoRD) ' // Time of Peak = ' num2str(topNoRD) ' sec // Change in % Significant ' num2str(round(100*sum(SelIn)/sum(Sel))) '%'];
        end
        lm_str=['Low Motivation Trials']; %removed for poster Fold change = ' num2str(foldchangeIRD) ' // Time of Peak = ' num2str(topRD) ' sec // Change in % Significant ' num2str(round(100*sum(SelIn)/sum(Sel))) '%'];
        hm_str=['High Motivation Trials'];
        if ismember(EOI{j},{'LeverInsertion','LeverRetract','PEntry'})
            leg=legend([plot3 plot2 plot1],{hm_str,lm_str,NoRD_str},'Location','southwest','FontSize',6);
        else
            leg=legend([plot3 plot2 ],{hm_str,lm_str},'Location','southwest','FontSize',6);
        end
        leg.ItemTokenSize = [10,1];
        legend('boxoff');
        p1.Annotation.LegendInformation.IconDisplayStyle = 'off';
        p2.Annotation.LegendInformation.IconDisplayStyle = 'off';
        %p3.Annotation.LegendInformation.IconDisplayStyle = 'off';
        o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
        o2=plot([0 0],[-15 20],':','color','k','linewidth',0.75);
        o1.Annotation.LegendInformation.IconDisplayStyle = 'off';
        o2.Annotation.LegendInformation.IconDisplayStyle = 'off';
        axis([-1.5 1.5 -15 10]);
        title([EOI{j} ' inhibited (' num2str(round(100*sum(SelIn)/sum(Sel))) '%)'],'fontsize',10)
        ylabel('Z-score','fontsize',8);
    end
    SelEx=R.Ev(Eventindex).RespDir>0 & Sel; %Find neurons that have an excitatory response to this event
    SelExNoRD=R.Ev(NoRDEventindex).RespDir>0 & Sel;
    SelExRD=R.Ev(RDEventindex).RespDir>0 & Sel;
    if sum(SelEx)~=0
        %excitation
        %average firing rate
        subplot_tight(2,4,y+(i-1)*4,[0.06,0.03]);
        psthE=mean(R.Ev(Eventindex).PSTHz(SelEx,Ishow),1,'omitnan');
        semE=nanste(R.Ev(Eventindex).PSTHz(SelEx,Ishow),1); %calculate standard error of the mean
        upE=psthE+semE;
        downE=psthE-semE;
        hold on;
        if ismember(EOI{j},{'LeverInsertion','LeverRetract','PEntry'})
            values=R.Ev(NoRDEventindex).PSTHz(SelEx,Ishow);
            values(~isfinite(values))=NaN;
            psthENoRD=mean(values,1,'omitnan');
            semENoRD=nanste(R.Ev(NoRDEventindex).PSTHz(SelEx,Ishow),1); %calculate standard error of the mean
            upENoRD=psthENoRD+semENoRD;
            downENoRD=psthENoRD-semENoRD;
            p1=patch([time1,time1(end:-1:1)],[upENoRD,downENoRD(end:-1:1)],excNoRD,'EdgeColor','none');alpha(0.5);
            plot1=plot(time1,psthENoRD,'Color',excNoRD,'linewidth',1);
        end
        psthEhm=mean(R.Ev(Eventindex).PSTHhmz(SelEx,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
        semEhm=nanste(R.Ev(Eventindex).PSTHhmz(SelEx,Ishow),1); %calculate standard error of the mean
        upEhm=psthEhm+semEhm;
        downEhm=psthEhm-semEhm;
        psthElm=mean(R.Ev(Eventindex).PSTHlmz(SelEx,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
        semElm=nanste(R.Ev(Eventindex).PSTHlmz(SelEx,Ishow),1); %calculate standard error of the mean
        upElm=psthElm+semElm;
        downElm=psthElm-semElm;
        %         psthERD=mean(R.Ev(RDEventindex).PSTHz(SelEx,Ishow),1,'omitnan');
        %         semERD=nanste(R.Ev(RDEventindex).PSTHz(SelEx,Ishow),1); %calculate standard error of the mean
        %         upERD=psthERD+semERD;
        %         downERD=psthERD-semERD;
        [excRDmax,excRDmaxidx]=max(psthE);
        p2=patch([time1,time1(end:-1:1)],[upElm,downElm(end:-1:1)],exclm,'EdgeColor','none');alpha(0.5);
        plot2=plot(time1,psthElm,'Color',exclm,'linewidth',1);
        p3=patch([time1,time1(end:-1:1)],[upEhm,downEhm(end:-1:1)],inhhm,'EdgeColor','none');alpha(0.5);
        plot3=plot(time1,psthEhm,'Color',inhhm,'linewidth',1); title('Mean firing (z-score)'); %create plot of avg firing rate
        ax=gca;
        ax.FontSize = 8;
        if ismember(EOI{j},{'LeverInsertion','LeverRetract','PEntry'})
            NoRD_str=['Omitted Trials']; %removed for poster Fold change =' num2str(foldchangeENoRD) ' // Time of Peak = ' num2str(topNoRD) ' sec // % Inhibited ' num2str(round(100*sum(SelEx)/sum(Sel))) '%'];
        end
        lm_str=['Low Motivation Trials']; %removed for poster Fold change = ' num2str(foldchangeIRD) ' // Time of Peak = ' num2str(topRD) ' sec // Change in % Significant ' num2str(round(100*sum(SelIn)/sum(Sel))) '%'];
        hm_str=['High Motivation Trials'];
        if ismember(EOI{j},{'LeverInsertion','LeverRetract','PEntry'})
            leg=legend([plot3 plot2 plot1],{hm_str,lm_str,NoRD_str},'Location','southwest','FontSize',6);
        else
            leg=legend([plot3 plot2 ],{hm_str,lm_str},'Location','southwest','FontSize',6);
        end
        leg.ItemTokenSize = [10,1];
        legend('boxoff');
        p1.Annotation.LegendInformation.IconDisplayStyle = 'off';
        p2.Annotation.LegendInformation.IconDisplayStyle = 'off';
        %p3.Annotation.LegendInformation.IconDisplayStyle = 'off';
        o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
        o2=plot([0 0],[-10 85],':','color','k','linewidth',0.75);
        o1.Annotation.LegendInformation.IconDisplayStyle = 'off';
        o2.Annotation.LegendInformation.IconDisplayStyle = 'off';
        axis([-1.5 1.5 -10 65]);
        ax.FontSize=8;
        title([EOI{j} ' excited (' num2str(round(100*sum(SelEx)/sum(Sel))) '%)'],'fontsize',10)
        ylabel('Z-score','fontsize',8);
    end

    if rem(j,1)==0
        x=x+1;
        y=y+1;
    end

end

x=3;
y=7;

for j=1:numel(EOI)
    Eventindex = strcmp(EOI{j}, R.Erefnames);
    % if j==1
    %     Sel=LIK;
    % elseif j==2
    %     Sel=LRK;
    % end
    if ismember(EOI{j},{'LeverInsertion','LeverRetract'})
        NoRDEventindex = strcmp(strcat(EOI{j},'NoRD'),R.Erefnames);
        RDEventindex=strcmp(strcat(EOI{j},'RD'),R.Erefnames);
    elseif strcmp(EOI{j},'PEntry')
        NoRDEventindex = strcmp(strcat(EOI{j},'NoRDtrial1'),R.Erefnames);
        RDEventindex=strcmp(strcat(EOI{j},'RD'),R.Erefnames);
    end
    % Plotting neurons that respond to the lever insertion
    %inhibitions
    SelIn=R.Ev(Eventindex).RespDir<0 & Sel; %Find neurons that have an inhibitory response to this event
    SelInNoRD=R.Ev(NoRDEventindex).RespDir<0 & Sel;
    SelInRD=R.Ev(RDEventindex).RespDir<0 & Sel;
    if sum(SelIn)~=0
        %     %average firing rate
        subplot_tight(2,4,x+(i-1)*7,[0.06,0.03]);
        psthI=mean(R.Ev(Eventindex).PSTHz(SelIn,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
        semI=nanste(R.Ev(Eventindex).PSTHz(SelIn,Ishow),1); %calculate standard error of the mean
        upI=psthI+semI;
        downI=psthI-semI;
        psthINoRD=mean(R.Ev(NoRDEventindex).PSTHz(SelIn,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
        semINoRD=nanste(R.Ev(NoRDEventindex).PSTHz(SelIn,Ishow),1); %calculate standard error of the mean
        upINoRD=psthINoRD+semINoRD;
        downINoRD=psthINoRD-semINoRD;
        psthIRD=mean(R.Ev(RDEventindex).PSTHz(SelIn,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
        semIRD=nanste(R.Ev(RDEventindex).PSTHz(SelIn,Ishow),1); %calculate standard error of the mean
        upIRD=psthIRD+semIRD;
        downIRD=psthIRD-semIRD;
        [inhmax,inhmaxidx]=max(psthI);
        [inhNoRDmax,inhNoRDmaxidx]=max(psthINoRD);
        [inhRDmax,inhRDmaxidx]=max(psthIRD);
        hold on;
        p1=patch([time1,time1(end:-1:1)],[upINoRD,downINoRD(end:-1:1)],inhNoRD,'EdgeColor','none');alpha(0.5);
        plot1=plot(time1,psthINoRD,'Color',inhNoRD,'linewidth',1); title('Mean firing (z-score)'); %create plot of avg firing rate
        p2=patch([time1,time1(end:-1:1)],[upIRD,downIRD(end:-1:1)],inhRD,'EdgeColor','none');alpha(0.5);
        plot2=plot(time1,psthIRD,'Color',inhRD,'linewidth',1); title('Mean firing (z-score)'); %create plot of avg firing rate
        ax=gca;
        ax.FontSize = 8;
        %p3=patch([time1,time1(end:-1:1)],[upI,downI(end:-1:1)],inh,'EdgeColor','none');alpha(0.5);
        %plot3=plot(time1,psthI,'Color',inh,'linewidth',1); title('Mean firing (z-score)'); %create plot of avg firing rate
        NoRD_str=['Omitted Trials']; % removed for poster Fold change = ' num2str(foldchangeINoRD) ' // Time of Peak = ' num2str(topNoRD) ' sec // Change in % Significant ' num2str(round(100*sum(SelIn)/sum(Sel))) '%'];
        RD_str=['Rewarded Trials']; %removed for poster Fold change = ' num2str(foldchangeIRD) ' // Time of Peak = ' num2str(topRD) ' sec // Change in % Significant ' num2str(round(100*sum(SelIn)/sum(Sel))) '%'];
        leg=legend([plot2 plot1],{RD_str,NoRD_str},'Location','southwest','FontSize',6);
        leg.ItemTokenSize = [10,1];
        legend('boxoff');
        p1.Annotation.LegendInformation.IconDisplayStyle = 'off';
        p2.Annotation.LegendInformation.IconDisplayStyle = 'off';
        %p3.Annotation.LegendInformation.IconDisplayStyle = 'off';
        o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
        o2=plot([0 0],[-15 20],':','color','k','linewidth',0.75);
        o1.Annotation.LegendInformation.IconDisplayStyle = 'off';
        o2.Annotation.LegendInformation.IconDisplayStyle = 'off';
        axis([-1.5 1.5 -10 10]);
        title([EOI{j} ' inhibited (' num2str(round(100*sum(SelIn)/sum(Sel))) '%)'],'fontsize',10)
        ylabel('Z-score','fontsize',8);
    end
    SelEx=R.Ev(Eventindex).RespDir>0 & Sel; %Find neurons that have an excitatory response to this event
    SelExNoRD=R.Ev(NoRDEventindex).RespDir>0 & Sel;
    SelExRD=R.Ev(RDEventindex).RespDir>0 & Sel;
    if sum(SelEx)~=0
        %excitation
        %average firing rate
        subplot_tight(2,4,y+(i-1)*7,[0.06,0.03]);
        psthE=mean(R.Ev(Eventindex).PSTHz(SelEx,Ishow),1,'omitnan');
        semE=nanste(R.Ev(Eventindex).PSTHz(SelEx,Ishow),1); %calculate standard error of the mean
        upE=psthE+semE;
        downE=psthE-semE;
        values=R.Ev(NoRDEventindex).PSTHz(SelEx,Ishow);
        values(~isfinite(values))=NaN;
        psthENoRD=mean(values,1,'omitnan');
        semENoRD=nanste(R.Ev(NoRDEventindex).PSTHz(SelEx,Ishow),1); %calculate standard error of the mean
        upENoRD=psthENoRD+semENoRD;
        downENoRD=psthENoRD-semENoRD;
        [excNoRDmax,excNoRDmaxidx]=max(psthENoRD);
        psthERD=mean(R.Ev(RDEventindex).PSTHz(SelEx,Ishow),1,'omitnan');
        semERD=nanste(R.Ev(RDEventindex).PSTHz(SelEx,Ishow),1); %calculate standard error of the mean
        upERD=psthERD+semERD;
        downERD=psthERD-semERD;
        [excRDmax,excRDmaxidx]=max(psthERD);
        hold on;
        p1=patch([time1,time1(end:-1:1)],[upENoRD,downENoRD(end:-1:1)],excNoRD,'EdgeColor','none');alpha(0.5);
        plot1=plot(time1,psthENoRD,'Color',excNoRD,'linewidth',1);
        p2=patch([time1,time1(end:-1:1)],[upERD,downERD(end:-1:1)],excRD,'EdgeColor','none');alpha(0.5);
        plot2=plot(time1,psthERD,'Color',excRD,'linewidth',1);
        ax=gca;
        ax.FontSize = 8;
        %p3=patch([time1,time1(end:-1:1)],[upE,downE(end:-1:1)],exc,'EdgeColor','none');alpha(0.5);
        %plot3=plot(time1,psthE,'Color',exc,'linewidth',1);
        NoRD_str=['Omitted Trials']; %removed for poster Fold change =' num2str(foldchangeENoRD) ' // Time of Peak = ' num2str(topNoRD) ' sec // % Inhibited ' num2str(round(100*sum(SelEx)/sum(Sel))) '%'];
        RD_str=['Rewarded Trials']; %removed for poster Fold change =' num2str(foldchangeERD) ' // Time of Peak = ' num2str(topRD) ' sec // % Inhibited ' num2str(round(100*sum(SelEx)/sum(Sel))) '%'];
        leg=legend([plot2 plot1],{RD_str,NoRD_str},'Location','northwest','FontSize',6);
        leg.ItemTokenSize = [10,1];
        legend('boxoff');
        p1.Annotation.LegendInformation.IconDisplayStyle = 'off';
        p2.Annotation.LegendInformation.IconDisplayStyle = 'off';
        %p3.Annotation.LegendInformation.IconDisplayStyle = 'off';
        o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
        o2=plot([0 0],[-10 85],':','color','k','linewidth',0.75);
        o1.Annotation.LegendInformation.IconDisplayStyle = 'off';
        o2.Annotation.LegendInformation.IconDisplayStyle = 'off';
        axis([-1.5 1.5 -10 85]);
        ax.FontSize=8;
        title([EOI{j} ' excited (' num2str(round(100*sum(SelEx)/sum(Sel))) '%)'],'fontsize',10)
        ylabel('Z-score','fontsize',8);
    end

    if rem(j,1)==0
        x=x+1;
        y=y+1;
    end

end

% %hm vs lm trial comparison
% Xaxis=[-10 10];
% Yaxisin=[-10 10];
% Yaxisex=[-10 10];
% Ishow=find(R.Param.Tm>=Xaxis(1) & R.Param.Tm<=Xaxis(2));
% time1=R.Param.Tm(Ishow);
% Xaxis2=[-1.5 1.5];
% Ushow=find(R.Param.Tm>=Xaxis2(1) & R.Param.Tm<=Xaxis2(2));
% time2=R.Param.Tm(Ushow);
% inhhm = [0.77 0.1 0.37];
% inhlm = [0.2 0.28 0.45];
% inhhmlm = [inhhm; inhlm];
% exchm = [0.77 0.1 0.37];
% exclm = [0.2 0.28 0.45];
% exchmlm = [exchm;exclm];
% Eventlist={'LeverInsertion','LeverRetract','LeverPress','PEntryRD'};
% i=1;
% Reg=true(length(R.Ninfo),1); %change this to Reg=strcmp(R.Type,'DOI'): or
% % 'SAL' and it'll plot only those neurons
%
% % sets color map & plotting specifications
% [magma,inferno,plasma,viridis]=colormaps;
% colormap(plasma);
% c=[-100 2000];ClimE=sign(c).*abs(c).^(1/4);%colormap
%
% %get all neurons, using the first event as a guide
% Sel=  logical(R.Bmean>1); %ones(size(R.Ev(1).RespDir), 'logical');
%
% x=4;
% y=11;
%
% for j=1:numel(Eventlist)
%     Eventindex = strcmp(Eventlist{j}, R.Erefnames);
%     R.Ev(Eventindex).PSTHhmz(isinf(R.Ev(Eventindex).PSTHhmz))=NaN;
%     R.Ev(Eventindex).PSTHlmz(isinf(R.Ev(Eventindex).PSTHlmz))=NaN;
%     % Plotting neurons that respond to the lever insertion
%     %inhibitions
%     SelIn=R.Ev(Eventindex).RespDir<0 & Sel; %Find neurons that have an inhibitory response to this event
%     %     %average firing rate
%     subplot_tight(2,4,x+(i-1)*7,[0.06,0.03]);
%
%     psthIhm=mean(R.Ev(Eventindex).PSTHhmz(SelIn,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
%     semIhm=nanste(R.Ev(Eventindex).PSTHhmz(SelIn,Ishow),1); %calculate standard error of the mean
%     upIhm=psthIhm+semIhm;
%     downIhm=psthIhm-semIhm;
%     psthIlm=mean(R.Ev(Eventindex).PSTHlmz(SelIn,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
%     semIlm=nanste(R.Ev(Eventindex).PSTHlmz(SelIn,Ishow),1); %calculate standard error of the mean
%     upIlm=psthIlm+semIlm;
%     downIlm=psthIlm-semIlm;
%     [inhmax,inhmaxidx]=max(psthI);
%     hold on;
%
%     p2=patch([time1,time1(end:-1:1)],[upIlm,downIlm(end:-1:1)],inhlm,'EdgeColor','none');alpha(0.5);
%     plot2=plot(time1,psthIlm,'Color',inhlm,'linewidth',1); title('Mean firing (z-score)'); %create plot of avg firing rate
%     p1=patch([time1,time1(end:-1:1)],[upIhm,downIhm(end:-1:1)],inhhm,'EdgeColor','none');alpha(0.5);
%     plot1=plot(time1,psthIhm,'Color',inhhm,'linewidth',1); title('Mean firing (z-score)'); %create plot of avg firing rate
%     ax=gca;
%     ax.FontSize = 8;
%     hm_str=['High Motivation Trials']; % num2str(foldchangeIfirst7)]; (removed for poster)
%     lm_str=['Low Motivation Trials']; % num2str(foldchangeIlast7)]; (removed for poster)
%     leg=legend([plot1 plot2],{hm_str,lm_str},'Location','southwest','FontSize',6);
%     leg.ItemTokenSize = [10,1];
%     legend('boxoff');
%     p1.Annotation.LegendInformation.IconDisplayStyle = 'off';
%     p2.Annotation.LegendInformation.IconDisplayStyle = 'off';
%     o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
%     o2=plot([0 0],[-15 20],':','color','k','linewidth',0.75);
%     o1.Annotation.LegendInformation.IconDisplayStyle = 'off';
%     o2.Annotation.LegendInformation.IconDisplayStyle = 'off';
%     axis([-1 1 -15 20]);
%
%     title([Eventlist{j} ' inhibited (' num2str(round(100*sum(SelIn)/sum(Sel))) '%)'],'fontsize',10)
%     ylabel('Z-score','fontsize',8);
%
%     %excitation
%     SelEx=Reg&R.Ev(Eventindex).RespDir>0 & Sel; %Find neurons that have an excitatory response to this event
%     %average firing rate
%     subplot_tight(2,4,y+(i-1)*7,[0.06,0.03]);
%     psthEhm=mean(R.Ev(Eventindex).PSTHhmz(SelEx,Ishow),1,'omitnan');
%     semEhm=nanste(R.Ev(Eventindex).PSTHhmz(SelEx,Ishow),1); %calculate standard error of the mean
%     upEhm=psthEhm+semEhm;
%     downEhm=psthEhm-semEhm;
%     psthElm=mean(R.Ev(Eventindex).PSTHlmz(SelEx,Ishow),1,'omitnan');
%     semElm=nanste(R.Ev(Eventindex).PSTHlmz(SelEx,Ishow),1); %calculate standard error of the mean
%     upElm=psthElm+semElm;
%     downElm=psthElm-semElm;
%     [excmax,excmaxidx]=max(psthE);
%     hold on;
%     p2=patch([time1,time1(end:-1:1)],[upElm,downElm(end:-1:1)],exclm,'EdgeColor','none');alpha(0.5);
%     plot2=plot(time1,psthElm,'Color',exclm,'linewidth',1);
%     p1=patch([time1,time1(end:-1:1)],[upEhm,downEhm(end:-1:1)],exchm,'EdgeColor','none');alpha(0.5);
%     plot1=plot(time1,psthEhm,'Color',exchm,'linewidth',1);
%     ax=gca;
%     ax.FontSize = 8;
%     hm_str=['High Motivation Trials']; % num2str(foldchangeIfirst7)]; (removed for poster)
%     lm_str=['Low Motivation Trials']; % num2str(foldchangeIlast7)]; (removed for poster)
%     leg=legend([plot1 plot2],{hm_str,lm_str},'Location','northwest','FontSize',6);
%     leg.ItemTokenSize = [10,1];
%     legend('boxoff');
%     p1.Annotation.LegendInformation.IconDisplayStyle = 'off';
%     p2.Annotation.LegendInformation.IconDisplayStyle = 'off';
%     o1=plot([-2 2],[0 0],':','color','k','linewidth',0.75);
%     o2=plot([0 0],[-10 85],':','color','k','linewidth',0.75);
%     o1.Annotation.LegendInformation.IconDisplayStyle = 'off';
%     o2.Annotation.LegendInformation.IconDisplayStyle = 'off';
%     axis([-1 1 -10 85]);
%
%     title([Eventlist{j} ' excited (' num2str(round(100*sum(SelEx)/sum(Sel))) '%)'],'fontsize',10)
%     ylabel('Z-score','fontsize',8);
%     x=x+1;
%     y=y+1;
% end
%% all group
% heatplots
clearvars;
questans=questdlg('Video Data or not?','video','Yes','No','No');
if strcmp(questans,'No')
Rsinuse= {'RSuperApple_Latency_raw_blockskernelsizepostwinBlinepre.mat','RGrape_Latency_raw_addedvars_blockskernelsizepostwinBlinepre.mat','RMelon_Latency_raw_addedvars_blockskernelsizepostwinBlinepre.mat'};
else
Rsinuse= {'RSuperJazz_Latency_raw_addedvars_blockskernelsizepostwinBlinepre.mat','RGrape_Latency_raw_addedvars_blockskernelsizepostwinBlinepre.mat','RMelon_Latency_raw_addedvars_blockskernelsizepostwinBlinepre.mat'};
end
Eventlist={'LeverInsertion';'LeverPress'; 'LeverRetract';'PEntryRD';'PEntrynoRD'};
cols= length(Eventlist);
colscorr=length(Rsinuse);
height=length(Rsinuse)*2;
inh=[0.1 0.021154 0.6];
exc=[0.9 0.75 0.205816];
x=1;
y=x+cols;
z=1;
a=1;
b=1;
d=1;
e=1;
heatplots=figure;
BlinecorrelationscumRD=figure;
Blinecorrelationstrialno=figure;
if strcmp(questans,'Yes')
BlinevelcorrelationscumRD=figure;
Blinevelcorrelationstrialno=figure;
BlinevelcorrelationsBlineFR=figure;
end

for currentR=1:length(Rsinuse)
    clear R
    load (Rsinuse{currentR});

    addpath(genpath('\\pbs-srv2.win.ad.jhu.edu\JanakLabTest\Matilde\MatLab\Supporting Programs'));
% 1. Unique sessions and rat mapping (from your existing code)
[~,uniquesesh] = unique(R.Ninfo(:,1));
uniquerats = unique(cellfun(@(x) regexp(x, '(?<=-)[^_]+', 'match', 'once'), R.Ninfo(:,1), 'UniformOutput', false));

sexPerRat = cellfun(@(r) R.Subject(strcmp(R.Subject(:,1), r), 2), uniquerats, 'UniformOutput', false);
sexPerRat = cellfun(@(c) c{1}, sexPerRat, 'UniformOutput', false);
sexPerRat = string(sexPerRat);

femaleIdx = find(sexPerRat == "F");
maleIdx   = find(sexPerRat == "M");
uniquerats = uniquerats([femaleIdx; maleIdx]);

ratsThis = cellfun(@(x) regexp(x, '(?<=-)[^_]+', 'match', 'once'), R.Ninfo(uniquesesh,1), 'UniformOutput', false);
[~, ratIdx] = ismember(ratsThis, uniquerats);

plotting = R.cumrd(uniquesesh,:) ./ max(R.cumrd(uniquesesh,:),[],2);
y2 = 1:size(R.cumrd,2);

colers = turbo(length(uniquerats));

% -------------------------
% 2. Plot all individual sessions
figure; hold on
p = plot(y2, plotting', ':', 'LineWidth', 1.2);
set(p, {'Color'}, num2cell(colers(ratIdx,:),2));

% -------------------------
% 3. Compute mean per rat
meanPerRat = zeros(length(uniquerats), size(plotting,2));
for i = 1:length(uniquerats)
    meanPerRat(i,:) = mean(plotting(ratIdx == i, :), 1, 'omitnan');
end

% -------------------------
% 4. Plot mean per rat on top
for i = 1:length(uniquerats)
    plot(y2, meanPerRat(i,:), '-', 'LineWidth', 4, 'Color', colers(i,:));
end
%     hold on;line(y2,plottingmean,'Color','b')
%     dx=gradient(plottingmean);
%     normDeriv = abs(dx) / max(abs(dx));
% 
%     % Define a threshold for plateau detection (e.g., when derivative drops below 20% of its maximum)
%     threshold = 0.4;
% 
%     % Find the point where the derivative first drops below the threshold
% plateauStartIdx = find(normDeriv < threshold, 1, 'first');
% 
% 
%     plot(y2(plateauStartIdx),plottingmean(plateauStartIdx),'ro')
    xlim([1 length(plotting)])

    figure(heatplots)
    Xaxis=[-1 1];
    Ishow=find(R.Param.Tm>=Xaxis(1) & R.Param.Tm<=Xaxis(2));
    time1=R.Param.Tm(Ishow);
    Xaxis2=[-0.5 0.5];
    Ushow=find(R.Param.Tm>=Xaxis2(1) & R.Param.Tm<=Xaxis2(2));
    time2=R.Param.Tm(Ushow);




    i=1;
    Reg=true(length(R.Ninfo),1); %change this to Reg=strcmp(R.Type,'DOI'): or
    % 'SAL' and it'll plot only those neurons

    % sets color map & plotting specifications
    [magma,inferno,plasma,viridis]=colormaps;
    colormap(plasma);
    c=[-100 2000];ClimE=sign(c).*abs(c).^(1/2);%colormap

    %select neurons of interest,
    Sel = ones(size(R.Ev(1).RespDir), 'logical');
    SpecialSel= logical(R.Bmean>1);

    % If the event list exceeds 12, you will need to work on this section to
    % make new figures in the below for loop
    % % if rem(length(Eventlist),12)==1
    % %     figflag == 1;
    % %     numFigs = floor(length(Eventlist)/12);
    % % end

    % for loop for sorting neurons based on activity and plotting heat plots
    % for each event
    heatplotdims=[0.06,0.05];
    devdims= [0.04,0.05];
    cumRD=R.cumrd;
    normalizedFR= R.FiringRate(:,:)./mean(R.FiringRate(:,1:2),2); %normalize(R.FiringRate(:,:),[2],'range');
    if any(mean(R.FiringRate(:,1:2),2)<0.2)
        idxtochange=find(mean(R.FiringRate(:,1:2),2)<0.2);
        idxtochange=idxtochange(sum(normalizedFR(mean(R.FiringRate(:,1:2),2)<0.2,:)>10,2)>0);
        normalizedFR(idxtochange,:)=NaN(size(idxtochange,1),size(R.FiringRate,2));

    end
    for j=1:numel(Eventlist)
        Eventindex = strcmp(Eventlist{j}, R.Erefnames);

        %sort each event's heatmap by magnitude of response
        Neurons=R.Ev(Eventindex).PSTHz(Sel,Ishow); %get the firing rates of neurons of interest
        TMPi=R.Ev(Eventindex).Meanz(R.Ev(Eventindex).RespDir==-1 & SpecialSel); %find the magnitude of the inhibitions for this event
        TMPi(isnan(TMPi))=0; %To place the neurons with no onset/duration/peak at the top of the color-coded map
        [~,SORTimgi]=sort(TMPi);
        overallidx=find(R.Ev(Eventindex).RespDir==-1 & SpecialSel);
        SORTimgioverall=overallidx(SORTimgi);
        TMPn=R.Ev(Eventindex).Meanz(R.Ev(Eventindex).RespDir==0 & SpecialSel); %find the magnitude of the inhibitions for this event
        TMPn(isnan(TMPn))=0; %To place the neurons with no onset/duration/peak at the top of the color-coded map
        [~,SORTimgn]=sort(TMPn);
        overallidx=find(R.Ev(Eventindex).RespDir==0 & SpecialSel);
        SORTimgnoverall=overallidx(SORTimgn);
        TMPe=R.Ev(Eventindex).Meanz(R.Ev(Eventindex).RespDir==1 & SpecialSel); %find the magnitude of the inhibitions for this event
        TMPe(isnan(TMPe))=0; %To place the neurons with no onset/duration/peak at the top of the color-coded map
        [~,SORTimge]=sort(TMPe);
        overallidx=find(R.Ev(Eventindex).RespDir==1 & SpecialSel);
        SORTimgeoverall=overallidx(SORTimge);
        Neurons=Neurons([SORTimgioverall;SORTimgnoverall;SORTimgeoverall],:); %sort the neurons by magnitude
        if length(Neurons)~=length(SpecialSel)
            imageSel=SpecialSel;
            imageSel(isnan(R.Ev(Eventindex).RespDir))=0;
        else
            imageSel=SpecialSel;
        end
        % each event's heatmap
        subplot_tight(height,cols,[x y]+(i-1)*6, heatplotdims);
        imagesc(time1,[1,sum(imageSel,1)],Neurons,ClimE); title([Eventlist{j} ' responses'], 'FontSize', 8);
        cb=colorbar;
        set(cb,'YDir','reverse');
        if j==1
            ylabel([char(regexp(Rsinuse{currentR}, '(?<=R)(.*?)(?=_)', 'match')), ' group neurons (sorted)'], 'fontsize', 8);
            xlabel(['Seconds post ' Eventlist{j}], 'fontsize', 5);
        end
        hold on;
        plot([0 0],[0 sum(imageSel)],':','color','k','linewidth',0.75);
        if rem(j,cols/2)==0
            x=x+cols+1;
            y=y+cols+1;
        elseif rem(j,cols/2)~=0
            x=x+1;
            y=y+1;
        end
        yline(length(TMPi)+0.5,'-w')
        yline(length(TMPi)+length(TMPn)+0.5,'-w')
    end
    %baseline corr with cumulative rewards
    figure(BlinecorrelationscumRD)
    neuroncumrdcorrandp=[];
    for neuron=1:length(normalizedFR)
        if ~isempty(normalizedFR(neuron,~isnan(normalizedFR(neuron,:))))
        [corrRD,p]=corr(normalizedFR(neuron,~isnan(normalizedFR(neuron,:)))',log(R.cumrd(neuron,~isnan(normalizedFR(neuron,:))))','Type','Spearman');
        neuroncumrdcorrandp(neuron,1)=corrRD(1,end);
        neuroncumrdcorrandp(neuron,2)=p(1,end);
        end
    end
    notcorrRD(currentR)=sum(neuroncumrdcorrandp(:,2)>0.05);
    corrRD=sum(neuroncumrdcorrandp(:,2)<0.05);
    percentcorrRDvel=corrRD/length(normalizedFR)*100;
    poscorrRD(currentR)=sum(neuroncumrdcorrandp(neuroncumrdcorrandp(:,2)<0.05,1)>0);
    poscorrvaluesRD=neuroncumrdcorrandp(neuroncumrdcorrandp(:,2)<0.05 & neuroncumrdcorrandp(:,1)>0);
    percentposRD=poscorrRD/length(normalizedFR)*100;
    negcorrRD(currentR)=sum(neuroncumrdcorrandp(neuroncumrdcorrandp(:,2)<0.05,1)<0);
    negcorrvaluesRD=neuroncumrdcorrandp(neuroncumrdcorrandp(:,2)<0.05 & neuroncumrdcorrandp(:,1)<0);
    percentnegRD=negcorrRD/length(normalizedFR)*100;

    edges=linspace(min(neuroncumrdcorrandp(:,1)),max(neuroncumrdcorrandp(:,1)),100+1);
    sgtitle('Baseline FR corr Cum RD')
    subplot_tight(1,colscorr,z)

    histogram(neuroncumrdcorrandp(neuroncumrdcorrandp(:,2)>0.05,1),edges,'FaceColor',[0.7 0.7 0.7])
    hold on
    histogram(poscorrvaluesRD,edges,'FaceColor','g')
    histogram(negcorrvaluesRD,edges,'FaceColor','r')
    xlabel('Correlation Coefficient')
    
    subtitle(regexp(Rsinuse{currentR}, '(?<=R)(.*?)(?=_)', 'match', 'once'))
    ylim([0 30])
    main_pos1 = get(gca, 'Position');  % Get the current axes position
    insetpos = [main_pos1(1) + 0.6 * main_pos1(3), main_pos1(2) + 0.8 * main_pos1(4), 0.1, 0.1];
    axes('Position',insetpos);
    piecolors=[0.7,0.7,0.7;0 1 0;1 0 0];
    p=piechart([notcorrRD(currentR),poscorrRD(currentR),negcorrRD(currentR)]);
    p.ColorOrder=piecolors;
    z=z+1;
    figure;
    scatter(mean(log(R.cumrd(neuroncumrdcorrandp(:,2)>0.05,:)),1,'omitnan'), mean(normalizedFR(neuroncumrdcorrandp(:,2)>0.05,:),1,'omitnan'),45,'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0,'MarkerFaceColor',[0.7 0.7 0.7]);
    hold on
    scatter(mean(log(R.cumrd(neuroncumrdcorrandp(:,2)<0.05 & neuroncumrdcorrandp(:,1)>0,:)),1,'omitnan'),mean(normalizedFR(neuroncumrdcorrandp(:,2)<0.05 & neuroncumrdcorrandp(:,1)>0,:),1,'omitnan'),45,'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0,'MarkerFaceColor','g');
    scatter(mean(log(R.cumrd(neuroncumrdcorrandp(:,2)<0.05 & neuroncumrdcorrandp(:,1)<0,:)),1,'omitnan'), mean(normalizedFR(neuroncumrdcorrandp(:,2)<0.05 & neuroncumrdcorrandp(:,1)<0,:),1,'omitnan'),45,'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0,'MarkerFaceColor','r');
    xlabel('Cumulative Reward');
    ylabel('Firing Rate (Hz)');
    title('Baseline Firing Rate vs Cumulative Rewards');
    subtitle(char(regexp(Rsinuse{currentR}, '(?<=R)(.*?)(?=_)', 'match')))
    main_pos1 = get(gca, 'Position');  % Get the current axes position
    insetpos = [main_pos1(1) + 0.65, main_pos1(2) + 0.62,  0.12, 0.12];
    axes('Position',insetpos);
    piecolors=[0.7,0.7,0.7;0 1 0;1 0 0];
    p=piechart([notcorrRD(currentR),poscorrRD(currentR),negcorrRD(currentR)]);
    p.ColorOrder=piecolors;
    %baseline corr with trial number
    figure(Blinecorrelationstrialno)
    neurontrialnocorrandp=[];
    for neuron=1:length(normalizedFR)
        [corrRD,p]=corrcoef(normalizedFR(neuron,~isnan(normalizedFR(neuron,:))),1:length(normalizedFR(neuron,~isnan(normalizedFR(neuron,:)))));
        neurontrialnocorrandp(neuron,1)=corrRD(1,end);
        neurontrialnocorrandp(neuron,2)=p(1,end);
    end

    notcorrBL(currentR)=sum(neurontrialnocorrandp(:,2)>0.05);
    corrBL=sum(neurontrialnocorrandp(:,2)<0.05);
    percentcorrBLvel=corrBL/length(normalizedFR)*100;
    poscorrBL(currentR)=sum(neurontrialnocorrandp(neurontrialnocorrandp(:,2)<0.05,1)>0);
    poscorrvaluesBLvel=neurontrialnocorrandp(neurontrialnocorrandp(:,2)<0.05 & neurontrialnocorrandp(:,1)>0);
    percentposBL=poscorrBL/length(normalizedFR)*100;
    negcorrBL(currentR)=sum(neurontrialnocorrandp(neurontrialnocorrandp(:,2)<0.05,1)<0);
    negcorrvaluesBL=neurontrialnocorrandp(neurontrialnocorrandp(:,2)<0.05 & neurontrialnocorrandp(:,1)<0);
    percentnegBL=negcorrBL/length(normalizedFR)*100;

    edges=linspace(min(neurontrialnocorrandp(:,1)),max(neurontrialnocorrandp(:,1)),100+1);
    sgtitle('Baseline FR corr Trial No')
    subplot_tight(1,colscorr,a)

    histogram(neurontrialnocorrandp(neurontrialnocorrandp(:,2)>0.05,1),edges,'FaceColor',[0.7 0.7 0.7])
    hold on
    histogram(poscorrvaluesBLvel,edges,'FaceColor','g')
    histogram(negcorrvaluesBL,edges,'FaceColor','r')
    xlabel('Correlation Coefficient')
    
    subtitle(regexp(Rsinuse{currentR}, '(?<=R)(.*?)(?=_)', 'match', 'once'))
    ylim([0 30])
    main_pos1 = get(gca, 'Position');  % Get the current axes position
    insetpos = [main_pos1(1) + 0.6 * main_pos1(3), main_pos1(2) + 0.8 * main_pos1(4), 0.1, 0.1];
    axes('Position',insetpos);
    piecolors=[0.7,0.7,0.7;0 1 0;1 0 0];
    p=piechart([notcorrBL(currentR),poscorrBL(currentR),negcorrBL(currentR)]);
    p.ColorOrder=piecolors;
    a=a+1;
    figure;
    scatter(1:size(normalizedFR,2), mean(normalizedFR(neurontrialnocorrandp(:,2)>0.05,:),1,'omitnan'),45,'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0,'MarkerFaceColor',[0.7 0.7 0.7]);
    hold on
    scatter(1:size(normalizedFR,2),mean(normalizedFR(neurontrialnocorrandp(:,2)<0.05 & neurontrialnocorrandp(:,1)>0,:),1,'omitnan'),45,'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0,'MarkerFaceColor','g');
    scatter(1:size(normalizedFR,2), mean(normalizedFR(neurontrialnocorrandp(:,2)<0.05 & neurontrialnocorrandp(:,1)<0,:),1,'omitnan'),45,'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0,'MarkerFaceColor','r');
    xlabel('Trial Number');
    ylabel('Firing Rate (Hz)');
    title('Baseline Firing Rate vs Session Trial');
    subtitle(char(regexp(Rsinuse{currentR}, '(?<=R)(.*?)(?=_)', 'match')))
    main_pos1 = get(gca, 'Position');  % Get the current axes position
    insetpos = [main_pos1(1) + 0.65, main_pos1(2) + 0.62,  0.12, 0.12];
    axes('Position',insetpos);
    piecolors=[0.7,0.7,0.7;0 1 0;1 0 0];
    p=piechart([notcorrBL(currentR),poscorrBL(currentR),negcorrBL(currentR)]);
    p.ColorOrder=piecolors;    
    [uniqueses,idx]=unique(R.Ninfo(:,1));
    idx=[idx;length(R.Ninfo)];
    session_meancorrcoef=[];
    session_meandiff=[];
    session_meannormalizeddiff=[];
    maxRD=[];
    for session=1:length(idx)-1
        sessionneurons=idx(session):idx(session+1) - (session < length(idx)-1);
        sessionneurons_corrcoef=neurontrialnocorrandp(sessionneurons,1);
        endidx=find(~isnan(R.FiringRate(idx(session),:)),1,'last'); 
        sessionneurons_f5l5=[mean(R.FiringRate(sessionneurons,1:3),2),mean(R.FiringRate(sessionneurons,endidx-2:endidx),2)];
        sessionneurons_diffs=sessionneurons_f5l5(:,2)-sessionneurons_f5l5(:,1);
        sessionneurons_normalizedf5l5=[mean(normalizedFR(sessionneurons,1:5),2),mean(normalizedFR(sessionneurons,endidx-5:endidx),2)];
        sessionneurons_normalizeddiffs=sessionneurons_normalizedf5l5(:,2)-sessionneurons_normalizedf5l5(:,1);
        session_meancorrcoef(session,1)=mean(sessionneurons_corrcoef);
        session_meandiff(session,1)=mean(sessionneurons_diffs);
        session_meannormalizeddiff(session,1)=mean(sessionneurons_normalizeddiffs);
        maxRD(session,1)=max(R.cumrd(idx(session),:),[],2);
        if contains(Rsinuse(currentR),{'SuperApple','SuperJazz'})
            dose_EtOH(session,1)=R.Subject{idx(session),3};
        end
    end
    [corrnormRD,pnormRD]=corrcoef(session_meannormalizeddiff(~isnan(session_meannormalizeddiff)),maxRD(~isnan(session_meannormalizeddiff)));
    [corrcorrRD,pcorrRD]=corrcoef(session_meancorrcoef(~isnan(session_meancorrcoef)),maxRD(~isnan(session_meancorrcoef)));
    if contains(Rsinuse(currentR),{'SuperApple','SuperJazz'})
    [corrnormEtOH,pnormEOH]=corrcoef(session_meannormalizeddiff(~isnan(session_meancorrcoef)),dose_EtOH(~isnan(session_meancorrcoef)));
    [corrcorrEtOH,pcorrEtOH]=corrcoef(session_meancorrcoef(~isnan(session_meancorrcoef)),dose_EtOH(~isnan(session_meancorrcoef)));
    end
    rats=unique(cellfun(@(s) s(5:8), uniqueses, 'UniformOutput', false));
    colors=turbo(length(rats));
    allrats={};
    for rat=1:length(rats)
        ratses=contains(uniqueses(:,1),rats{rat});
        allrats(ratses,:)=repelem(rats(rat),sum(ratses))';
    end
    figure;
    g=gscatter(maxRD,session_meannormalizeddiff,allrats,colors,'o','filled');
    closerto= 50 * (1 + (max(maxRD) > 50));
    xlim([0 closerto])
    if contains(Rsinuse(currentR),{'SuperApple','SuperJazz'})
    figure;
    g=gscatter(dose_EtOH,session_meannormalizeddiff,allrats,colors,'o','filled');
    maxdose=ceil(max(dose_EtOH));
    xlim([0 maxdose])
    end
if strcmp(questans,'Yes')
    %baseline vel corr with cumulative rewards
    figure(BlinevelcorrelationscumRD)
    velrdcorrandp=[];
    [~,idx]=unique(R.Ninfo(:,1));
    for session=1:length(idx)
        [corrRD,p]=corr(R.TrialITIInstVel(idx(session),~isnan(R.FiringRate(idx(session),:)))',log(R.cumrd(idx(session),~isnan(R.FiringRate(idx(session),:))))','Type','Spearman');
        velrdcorrandp(session,1)=corrRD(1,end);
        velrdcorrandp(session,2)=p(1,end);
    end

    notcorrRDvel(currentR)=sum(velrdcorrandp(:,2)>0.05);
    corrRDvel=sum(velrdcorrandp(:,2)<0.05);
    percentcorrRDvel=corrRDvel/length(R.FiringRate)*100;
    poscorrRDvel(currentR)=sum(velrdcorrandp(velrdcorrandp(:,2)<0.05,1)>0);
    poscorrvaluesRDvel=velrdcorrandp(velrdcorrandp(:,2)<0.05 & velrdcorrandp(:,1)>0);
    percentposRDvel=poscorrRDvel/length(R.FiringRate)*100;
    negcorrRDvel(currentR)=sum(velrdcorrandp(velrdcorrandp(:,2)<0.05,1)<0);
    negcorrvaluesRDvel=velrdcorrandp(velrdcorrandp(:,2)<0.05 & velrdcorrandp(:,1)<0);
    percentnegRDvel=negcorrRDvel/length(R.FiringRate)*100;

    edges=linspace(min(velrdcorrandp(:,1)),max(velrdcorrandp(:,1)),10+1);
    sgtitle('Baseline Vel corr Cum RD')
    subplot_tight(1,colscorr,b)

    histogram(velrdcorrandp(velrdcorrandp(:,2)>0.05,1),edges,'FaceColor',[0.7 0.7 0.7])
    hold on
    histogram(poscorrvaluesRDvel,edges,'FaceColor','g')
    histogram(negcorrvaluesRDvel,edges,'FaceColor','r')
    xlabel('Correlation Coefficient')
    
    subtitle(regexp(Rsinuse{currentR}, '(?<=R)(.*?)(?=_)', 'match', 'once'))
    ylim([0 30])
    main_pos1 = get(gca, 'Position');  % Get the current axes position
    insetpos = [main_pos1(1) + 0.6 * main_pos1(3), main_pos1(2) + 0.8 * main_pos1(4), 0.1, 0.1];
    axes('Position',insetpos);
    piecolors=[0.7,0.7,0.7;0 1 0;1 0 0];
    p=piechart([notcorrRDvel(currentR),poscorrRDvel(currentR),negcorrRDvel(currentR)]);
    p.ColorOrder=piecolors;
    b=b+1;
    figure;
    scatter(mean(log(R.cumrd(idx(velrdcorrandp(:,2)>0.05,:),:)),1,'omitnan'), mean(R.TrialITIInstVel(velrdcorrandp(:,2)>0.05,:),1,'omitnan'),45,'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0,'MarkerFaceColor',[0.7 0.7 0.7]);
    hold on
    scatter(mean(log(R.cumrd(idx(velrdcorrandp(:,2)<0.05 & velrdcorrandp(:,1)>0,:),:)),1,'omitnan'),mean(R.TrialITIInstVel(velrdcorrandp(:,2)<0.05 & velrdcorrandp(:,1)>0,:),1,'omitnan'),45,'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0,'MarkerFaceColor','g');
    scatter(mean(log(R.cumrd(idx(velrdcorrandp(:,2)<0.05 & velrdcorrandp(:,1)<0,:),:)),1,'omitnan'), mean(R.TrialITIInstVel(velrdcorrandp(:,2)<0.05 & velrdcorrandp(:,1)<0,:),1,'omitnan'),45,'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0,'MarkerFaceColor','r');
    xlabel('Cumulative Reward');
    ylabel('Scaled Avg Velocity');
    title('ITI Velocity vs Cumulative Rewards');
    subtitle(char(regexp(Rsinuse{currentR}, '(?<=R)(.*?)(?=_)', 'match')))
    main_pos1 = get(gca, 'Position');  % Get the current axes position
    insetpos = [main_pos1(1) + 0.65, main_pos1(2) + 0.62,  0.12, 0.12];
    axes('Position',insetpos);
    piecolors=[0.7,0.7,0.7;0 1 0;1 0 0];
    p=piechart([notcorrRDvel(currentR),poscorrRDvel(currentR),negcorrRDvel(currentR)]);
    p.ColorOrder=piecolors;
    %baseline vel corr with trial number
    figure(Blinevelcorrelationstrialno)
    veltrialnocorrandp=[];
    [~,idx]=unique(R.Ninfo(:,1));
    for session=1:length(idx)
        [corrRDvel,p]=corrcoef(R.TrialITIInstVel(idx(session),~isnan(R.FiringRate(session,:)))',(1:length(R.FiringRate(session,~isnan(R.FiringRate(session,:)))))');
        veltrialnocorrandp(session,1)=corrRDvel(1,end);
        veltrialnocorrandp(session,2)=p(1,end);
    end

    notcorrBLvel(currentR)=sum(veltrialnocorrandp(:,2)>0.05);
    corrBLvel=sum(veltrialnocorrandp(:,2)<0.05);
    percentcorrBLvel=corrBLvel/length(R.FiringRate)*100;
    poscorrBLvel(currentR)=sum(veltrialnocorrandp(veltrialnocorrandp(:,2)<0.05,1)>0);
    poscorrvaluesBLvel=veltrialnocorrandp(veltrialnocorrandp(:,2)<0.05 & veltrialnocorrandp(:,1)>0);
    percentposBLvel=poscorrBLvel/length(R.FiringRate)*100;
    negcorrBLvel(currentR)=sum(veltrialnocorrandp(veltrialnocorrandp(:,2)<0.05,1)<0);
    negcorrvaluesBLvel=veltrialnocorrandp(veltrialnocorrandp(:,2)<0.05 & veltrialnocorrandp(:,1)<0);
    percentnegBLvel=negcorrBLvel/length(R.FiringRate)*100;

    edges=linspace(min(veltrialnocorrandp(:,1)),max(veltrialnocorrandp(:,1)),10+1);
    sgtitle('Baseline Vel corr Trial No')
    subplot_tight(1,colscorr,d)

    histogram(veltrialnocorrandp(veltrialnocorrandp(:,2)>0.05,1),edges,'FaceColor',[0.7 0.7 0.7])
    hold on
    histogram(poscorrvaluesBLvel,edges,'FaceColor','g')
    histogram(negcorrvaluesBLvel,edges,'FaceColor','r')
    xlabel('Correlation Coefficient')
   
    subtitle(regexp(Rsinuse{currentR}, '(?<=R)(.*?)(?=_)', 'match', 'once'))
    ylim([0 30])
    main_pos1 = get(gca, 'Position');  % Get the current axes position
    insetpos = [main_pos1(1) + 0.6 * main_pos1(3), main_pos1(2) + 0.8 * main_pos1(4), 0.1, 0.1];
    axes('Position',insetpos);
    piecolors=[0.7,0.7,0.7;0 1 0;1 0 0];
    p=piechart([notcorrBLvel(currentR),poscorrBLvel(currentR),negcorrBLvel(currentR)]);
    p.ColorOrder=piecolors;
    d=d+1;
    figure;
    scatter(1:size(R.FiringRate,2), mean(R.TrialITIInstVel(veltrialnocorrandp(:,2)>0.05,:),1,'omitnan'),45,'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0,'MarkerFaceColor',[0.7 0.7 0.7]);
    hold on
    scatter(1:size(R.FiringRate,2),mean(R.TrialITIInstVel(veltrialnocorrandp(:,2)<0.05 & veltrialnocorrandp(:,1)>0,:),1,'omitnan'),45,'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0,'MarkerFaceColor','g');
    scatter(1:size(R.FiringRate,2), mean(R.TrialITIInstVel(veltrialnocorrandp(:,2)<0.05 & veltrialnocorrandp(:,1)<0,:),1,'omitnan'),45,'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0,'MarkerFaceColor','r');
    xlabel('Trial Number');
    ylabel('Scaled Avg Velocity');
    title('ITI Velocity vs Session Trial');
    subtitle(char(regexp(Rsinuse{currentR}, '(?<=R)(.*?)(?=_)', 'match')))
    main_pos1 = get(gca, 'Position');  % Get the current axes position
    insetpos = [main_pos1(1) + 0.65, main_pos1(2) + 0.62,  0.12, 0.12];
    axes('Position',insetpos);
    piecolors=[0.7,0.7,0.7;0 1 0;1 0 0];
    p=piechart([notcorrBLvel(currentR),poscorrBLvel(currentR),negcorrBLvel(currentR)]);
    p.ColorOrder=piecolors;
    %Bline FR and ITI Velocity
    figure(BlinevelcorrelationsBlineFR)
    BlineFRvsvelcorrandp=[];
    for neuron=1:length(normalizedFR)
        if sum(~isnan(normalizedFR(neuron,:)))~=0
        [corrRDvel,p]=corr(normalizedFR(neuron,~isnan(normalizedFR(neuron,:)))',(R.TrialITIInstVel(neuron,~isnan(normalizedFR(neuron,:))))','Type','Spearman');
        BlineFRvsvelcorrandp(neuron,1)=corrRDvel(1,end);
        BlineFRvsvelcorrandp(neuron,2)=p(1,end);
        end
    end
    notcorrTRvel(currentR)=sum(BlineFRvsvelcorrandp(:,2)>0.05);
    corrTRvel=sum(BlineFRvsvelcorrandp(:,2)<0.05);
    percentcorrTRvel=corrTRvel/length(normalizedFR)*100;
    poscorrTRvel(currentR)=sum(BlineFRvsvelcorrandp(BlineFRvsvelcorrandp(:,2)<0.05,1)>0);
    poscorrvaluesTRvel=BlineFRvsvelcorrandp(BlineFRvsvelcorrandp(:,2)<0.05 & BlineFRvsvelcorrandp(:,1)>0);
    percentposTRvel=poscorrTRvel/length(normalizedFR)*100;
    negcorrTRvel(currentR)=sum(BlineFRvsvelcorrandp(BlineFRvsvelcorrandp(:,2)<0.05,1)<0);
    negcorrvaluesTRvel=BlineFRvsvelcorrandp(BlineFRvsvelcorrandp(:,2)<0.05 & BlineFRvsvelcorrandp(:,1)<0);
    percentnegTRvel=negcorrTRvel/length(normalizedFR)*100;

    edges=linspace(min(BlineFRvsvelcorrandp(:,1)),max(BlineFRvsvelcorrandp(:,1)),100+1);
    sgtitle('Baseline FR corr Baseline Vel')
    subplot_tight(1,colscorr,e)

    histogram(BlineFRvsvelcorrandp(BlineFRvsvelcorrandp(:,2)>0.05,1),edges,'FaceColor',[0.7 0.7 0.7])
    hold on
    histogram(poscorrvaluesTRvel,edges,'FaceColor','g')
    histogram(negcorrvaluesTRvel,edges,'FaceColor','r')
    xlabel('Correlation Coefficient')
    subtitle(regexp(Rsinuse{currentR}, '(?<=R)(.*?)(?=_)', 'match', 'once'))
    
    ylim([0 30])
    main_pos1 = get(gca, 'Position');  % Get the current axes position
    insetpos = [main_pos1(1) + 0.6 * main_pos1(3), main_pos1(2) + 0.8 * main_pos1(4), 0.1, 0.1];
    axes('Position',insetpos);
    piecolors=[0.7,0.7,0.7;0 1 0;1 0 0];
    p=piechart([notcorrTRvel(currentR),poscorrTRvel(currentR),negcorrTRvel(currentR)]);
    p.ColorOrder=piecolors;
    e=e+1;
    figure;
    scatter(mean(R.TrialITIInstVel(BlineFRvsvelcorrandp(:,2)>0.05,:),1,'omitnan'), mean(normalizedFR(BlineFRvsvelcorrandp(:,2)>0.05,:),1,'omitnan'),45,'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0,'MarkerFaceColor',[0.7 0.7 0.7]);
    hold on
    scatter(mean(R.TrialITIInstVel(BlineFRvsvelcorrandp(:,2)<0.05 & BlineFRvsvelcorrandp(:,1)>0,:),1,'omitnan'),mean(normalizedFR(BlineFRvsvelcorrandp(:,2)<0.05 & BlineFRvsvelcorrandp(:,1)>0,:),1,'omitnan'),45,'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0,'MarkerFaceColor','g');
    scatter(mean(R.TrialITIInstVel(BlineFRvsvelcorrandp(:,2)<0.05 & BlineFRvsvelcorrandp(:,1)<0,:),1,'omitnan'), mean(normalizedFR(BlineFRvsvelcorrandp(:,2)<0.05 & BlineFRvsvelcorrandp(:,1)<0,:),1,'omitnan'),45,'filled', ...
        'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0,'MarkerFaceColor','r');
    xlabel('ITI Velocity');
    ylabel('Firing Rate (Hz)');
    title('Baseline Firing Rate vs ITI Velocity');
    subtitle(char(regexp(Rsinuse{currentR}, '(?<=R)(.*?)(?=_)', 'match')))
    main_pos1 = get(gca, 'Position');  % Get the current axes position
    insetpos = [main_pos1(1) + 0.65, main_pos1(2) + 0.62,  0.12, 0.12];
    axes('Position',insetpos);
    piecolors=[0.7,0.7,0.7;0 1 0;1 0 0];
    p=piechart([notcorrTRvel(currentR),poscorrTRvel(currentR),negcorrTRvel(currentR)]);
    p.ColorOrder=piecolors;
end
end


data=[notcorrBL',poscorrBL',negcorrBL'];
counts = data(:);  % 9×1 vector
% Create corresponding group and type labels for each cell
[groupIdx, typeIdx] = ndgrid(1:3, 1:3);  % both 3×3
groupVals = groupIdx(:);  % 9×1
typeVals = typeIdx(:);    % 9×1
% Repeat each group/type value by its corresponding count
groupLabels = repelem(groupVals, counts);
typeLabels  = repelem(typeVals, counts);
[tbl, chi2stat, p, labels] = crosstab(groupLabels, typeLabels);
n = sum(counts);

% Cramér's V
k = min(size(tbl));  % number of categories (rows or cols)
cramersV = sqrt(chi2stat / (n * (k - 1)));
fprintf("Cramér's V = %.4f\n", cramersV);
if p<0.05
    groupNames = {'Super', 'Grape', 'Melon'};
    pairs = nchoosek(1:3, 2);
    numComparisons = size(pairs, 1);
    rawP = zeros(numComparisons, 1);
    fprintf('\nBline vs Trial No. P-values:\n');
    for i = 1:numComparisons
        g1 = pairs(i, 1);
        g2 = pairs(i, 2);

        sub = data([g1, g2], :);

        % Build labels for chi-square test
        counts = sub(:);
        groupLabels = repelem([1; 2; 1; 2; 1; 2], counts);
        typeLabels  = repelem([1; 1; 2; 2; 3; 3], counts);  
        % Chi-square test
        [~, chi2stat, p] = crosstab(groupLabels, typeLabels);
          n = sum(counts);
        cramersV = sqrt(chi2stat / (n * (k - 1)));
        fprintf(" %s  vs  %s  Cramér's V = %.4f\n",groupNames{g1}, groupNames{g2}, cramersV);
        
        rawP(i) = p;
        fprintf('  %s vs %s: p = %.4f\n', groupNames{g1}, groupNames{g2}, p);
    end

    % Bonferroni correction
    correctedP = min(rawP * numComparisons, 1);  % Cap at 1
    fprintf('\nBline vs Trial No. Bonferroni-corrected p-values:\n');
    for i = 1:numComparisons
        g1 = pairs(i,1);
        g2 = pairs(i,2);
        fprintf('  %s vs %s: corrected p = %.4f\n', groupNames{g1}, groupNames{g2}, correctedP(i));
    end
end
data=[notcorrRD',poscorrRD',negcorrRD'];
counts = data(:);  % 9×1 vector
% Create corresponding group and type labels for each cell
[groupIdx, typeIdx] = ndgrid(1:3, 1:3);  % both 3×3
groupVals = groupIdx(:);  % 9×1
typeVals = typeIdx(:);    % 9×1
% Repeat each group/type value by its corresponding count
groupLabels = repelem(groupVals, counts);
typeLabels  = repelem(typeVals, counts);
[tbl, chi2stat, p, labels] = crosstab(groupLabels, typeLabels);
n = sum(counts);

if p<0.05
    groupNames = {'Super', 'Grape', 'Melon'};
    pairs = nchoosek(1:3, 2);
    numComparisons = size(pairs, 1);
    rawP = zeros(numComparisons, 1);
    fprintf('\nBline vs RD No. P-values:\n');
    for i = 1:numComparisons
        g1 = pairs(i, 1);
        g2 = pairs(i, 2);

        sub = data([g1, g2], :);

        % Build labels for chi-square test
        counts = sub(:);
        groupLabels = repelem([1; 2; 1; 2; 1; 2], counts);
        typeLabels  = repelem([1; 1; 2; 2; 3; 3], counts);  
        % Chi-square test
        [~, chi2stat, p] = crosstab(groupLabels, typeLabels);
        n = sum(counts);
        cramersV = sqrt(chi2stat / (n * (k - 1)));
        fprintf(" %s  vs  %s  Cramér's V = %.4f\n",groupNames{g1}, groupNames{g2}, cramersV);
        rawP(i) = p;
        fprintf('  %s vs %s: p = %.4f\n', groupNames{g1}, groupNames{g2}, p);
    end

    % Bonferroni correction
    correctedP = min(rawP * numComparisons, 1);  % Cap at 1
    fprintf('\nBline vs RD No. Bonferroni-corrected p-values:\n');
    for i = 1:numComparisons
        g1 = pairs(i,1);
        g2 = pairs(i,2);
        fprintf('  %s vs %s: corrected p = %.4f\n', groupNames{g1}, groupNames{g2}, correctedP(i));
    end
end
if strcmp(questans,'Yes')
data=[notcorrTRvel',poscorrTRvel',negcorrTRvel'];
counts = data(:);  % 9×1 vector
% Create corresponding group and type labels for each cell
[groupIdx, typeIdx] = ndgrid(1:3, 1:3);  % both 3×3
groupVals = groupIdx(:);  % 9×1
typeVals = typeIdx(:);    % 9×1
% Repeat each group/type value by its corresponding count
groupLabels = repelem(groupVals, counts);
typeLabels  = repelem(typeVals, counts);
[tbl, chi2stat, p, labels] = crosstab(groupLabels, typeLabels);
if p<0.05
    groupNames = {'Super', 'Grape', 'Melon'};
    pairs = nchoosek(1:3, 2);
    numComparisons = size(pairs, 1);
    rawP = zeros(numComparisons, 1);
    fprintf('\nBline vs Velocity P-values:\n');
    for i = 1:numComparisons
        g1 = pairs(i, 1);
        g2 = pairs(i, 2);

        sub = data([g1, g2], :);

        % Build labels for chi-square test
        counts = sub(:);
        groupLabels = repelem([1; 2; 1; 2; 1; 2], counts);
        typeLabels  = repelem([1; 1; 2; 2; 3; 3], counts);  
        % Chi-square test
        [~, chi2stat, p] = crosstab(groupLabels, typeLabels);
          n = sum(counts);
        cramersV = sqrt(chi2stat / (n * (k - 1)));
        fprintf(" %s  vs  %s  Cramér's V = %.4f\n",groupNames{g1}, groupNames{g2}, cramersV);
        
        rawP(i) = p;
        fprintf('  %s vs %s: p = %.4f\n', groupNames{g1}, groupNames{g2}, p);
    end

    % Bonferroni correction
    correctedP = min(rawP * numComparisons, 1);  % Cap at 1
    fprintf('\nBline vs Velocity Bonferroni-corrected p-values:\n');
    for i = 1:numComparisons
        g1 = pairs(i,1);
        g2 = pairs(i,2);
        fprintf('  %s vs %s: corrected p = %.4f\n', groupNames{g1}, groupNames{g2}, correctedP(i));
    end
end
data=[notcorrBLvel',poscorrBLvel',negcorrBLvel'];
counts = data(:);  % 9×1 vector
% Create corresponding group and type labels for each cell
[groupIdx, typeIdx] = ndgrid(1:3, 1:3);  % both 3×3
groupVals = groupIdx(:);  % 9×1
typeVals = typeIdx(:);    % 9×1
% Repeat each group/type value by its corresponding count
groupLabels = repelem(groupVals, counts);
typeLabels  = repelem(typeVals, counts);
[tbl, chi2stat, p, labels] = crosstab(groupLabels, typeLabels);
if p<0.05
    groupNames = {'Super', 'Grape', 'Melon'};
    pairs = nchoosek(1:3, 2);
    numComparisons = size(pairs, 1);
    rawP = zeros(numComparisons, 1);
    fprintf('\nVelocity vs Trial No. P-values:\n');
    for i = 1:numComparisons
        g1 = pairs(i, 1);
        g2 = pairs(i, 2);

        sub = data([g1, g2], :);

        % Build labels for chi-square test
        counts = sub(:);
        groupLabels = repelem([1; 2; 1; 2; 1; 2], counts);
        typeLabels  = repelem([1; 1; 2; 2; 3; 3], counts);  
        % Chi-square test
        [~, chi2stat, p] = crosstab(groupLabels, typeLabels);
        rawP(i) = p;
        fprintf('  %s vs %s: p = %.4f\n', groupNames{g1}, groupNames{g2}, p);
    end

    % Bonferroni correction
    correctedP = min(rawP * numComparisons, 1);  % Cap at 1
    fprintf('\nVelocity vs Trial No. Bonferroni-corrected p-values:\n');
    for i = 1:numComparisons
        g1 = pairs(i,1);
        g2 = pairs(i,2);
        fprintf('  %s vs %s: corrected p = %.4f\n', groupNames{g1}, groupNames{g2}, correctedP(i));
    end
end
data=[notcorrRDvel',poscorrRDvel',negcorrRDvel'];
counts = data(:);  % 9×1 vector
% Create corresponding group and type labels for each cell
[groupIdx, typeIdx] = ndgrid(1:3, 1:3);  % both 3×3
groupVals = groupIdx(:);  % 9×1
typeVals = typeIdx(:);    % 9×1
% Repeat each group/type value by its corresponding count
groupLabels = repelem(groupVals, counts);
typeLabels  = repelem(typeVals, counts);
[tbl, chi2stat, p, labels] = crosstab(groupLabels, typeLabels)
if p<0.05
    groupNames = {'Super', 'Grape', 'Melon'};
    pairs = nchoosek(1:3, 2);
    numComparisons = size(pairs, 1);
    rawP = zeros(numComparisons, 1);
    fprintf('\nVelocity vs RD No. P-values:\n');
    for i = 1:numComparisons
        g1 = pairs(i, 1);
        g2 = pairs(i, 2);

        sub = data([g1, g2], :);

        % Build labels for chi-square test
        counts = sub(:);
        groupLabels = repelem([1; 2; 1; 2; 1; 2], counts);
        typeLabels  = repelem([1; 1; 2; 2; 3; 3], counts);  
        % Chi-square test
        [~, chi2stat, p] = crosstab(groupLabels, typeLabels);
        rawP(i) = p;
        fprintf('  %s vs %s: p = %.4f\n', groupNames{g1}, groupNames{g2}, p);
    end

    % Bonferroni correction
    correctedP = min(rawP * numComparisons, 1);  % Cap at 1
    fprintf('\nVelocity vs RD No. Bonferroni-corrected p-values:\n');
    for i = 1:numComparisons
        g1 = pairs(i,1);
        g2 = pairs(i,2);
        fprintf('  %s vs %s: corrected p = %.4f\n', groupNames{g1}, groupNames{g2}, correctedP(i));
    end
end
end

%% Group by group behavioral data
clearvars;
RAWsinuse= {'RAWSuperApple_Latency_raw.mat','RAWGrape_Latency_raw.mat','RAWMelon_Latency_raw.mat'};
%allgroups=figure;
mvf=figure;
perrat=figure;
permvf=figure;
globalrds={};
globallplat={};
globalt2c={};
globalpelat={};
globalnumblicks={};
globalnumbbouts={};
globaltrialoutcome={};
malerds={};
malelplat={};
malet2c={};
malepelat={};
malenumblicks={};
malenumbbouts={};
femalerds={};
femalelplat={};
femalet2c={};
femalepelat={};
femalenumblicks={};
femalenumbbouts={};
perrds={};
perlplat={};
pert2c={};
perpelat={};
pernumblicks={};
pernumbbouts={};
    perlplatfull={};
    pert2cfull={};
    perpelatfull={};
    pernumblicksfull={};
    pernumbboutsfull={};
trialslplat={};
trialst2c={};
trialspelat={};
trialslicks={};
trialsbouts={};
sessionRD={};
sessionlplat={};
sessiont2c={};
sessionpelat={};
sessionlicks={};
sessionbouts={};
for currentRAW=1:length(RAWsinuse)
    clear RAW
    load (RAWsinuse{currentRAW}); 
    RDidx=strcmp(RAW(1).Einfo(:,2),'RewardDeliv');
    LPidx=strcmp(RAW(1).Einfo(:,2),'Trial-based LP Latency');
    T2Cidx=strcmp(RAW(1).Einfo(:,2), 'Trial-based Time2Complete');
    PElatidx=strcmp(RAW(1).Einfo(:,2),'Trial-based PE Latency');
    Licksperidx=strcmp(RAW(1).Einfo(:,2), 'Licks Per RD');
    Licksidx=strcmp(RAW(1).Einfo(:,2), 'Licks');
    Boutsperidx=strcmp(RAW(1).Einfo(:,2),'Bouts Per RD');
    trialtypeidx=strcmp(RAW(1).Einfo(:,2),'Trial Type');
    globalrds{currentRAW}=[];
    globallplat{currentRAW}=[];
    globalt2c{currentRAW}=[];
    globalpelat{currentRAW}=[];
    globalnumblicks{currentRAW}=[];
    globalnumbbouts{currentRAW}=[];
    globaltrialoutcome{currentRAW}=[];
    malerds{currentRAW}=[];
    malelplat{currentRAW}=[];
    malet2c{currentRAW}=[];
    malepelat{currentRAW}=[];
    malenumblicks{currentRAW}=[];
    malenumbbouts{currentRAW}=[];
    femalerds{currentRAW}=[];
    femalelplat{currentRAW}=[];
    femalet2c{currentRAW}=[];
    femalepelat{currentRAW}=[];
    femalenumblicks{currentRAW}=[];
    femalenumbbouts{currentRAW}=[];
    trialslplat{currentRAW}=[];
    trialst2c{currentRAW}=[];
    trialspelat{currentRAW}=[];
    trialslicks{currentRAW}=[];
    trialsbouts{currentRAW}=[];
    rats{currentRAW}=unique({RAW.Subject});
    sessionRD{currentRAW}=[];
    perrds{currentRAW}=cell(length(rats{currentRAW}),1);
    perlplat{currentRAW}=cell(length(rats{currentRAW}),1);
    perlplatfull{currentRAW}=cell(length(rats{currentRAW}),1);
    pert2c{currentRAW}=cell(length(rats{currentRAW}),1);
    perpelat{currentRAW}=cell(length(rats{currentRAW}),1);
    pernumblicks{currentRAW}=cell(length(rats{currentRAW}),1);
    pernumbbouts{currentRAW}=cell(length(rats{currentRAW}),1);
    sessionRD{currentRAW}=[];
    sessionlplat{currentRAW}=[];
sessiont2c{currentRAW}=[];
sessionpelat{currentRAW}=[];
sessionlicks{currentRAW}=[];
sessionbouts{currentRAW}=[];
        perlplatfull{currentRAW}=[];
    pert2cfull{currentRAW}=[];
    perpelatfull{currentRAW}=[];
    pernumblicksfull{currentRAW}=[];
    pernumbboutsfull{currentRAW}=[];
    all_rats{currentRAW} = {};      % cell array of all rat names (may repeat)
all_sexes{currentRAW} = {};         % corresponding sexes (cell array or char arrays)
    for session=1:length(RAW)
        if size(RAW(session).Erast{RDidx,1},1)>=10
            actualtrials=discretize(RAW(session).Erast{RDidx},[RAW(session).Erast{4};Inf]);
            usedtrials=actualtrials<=50;
            globalrds{currentRAW}=[globalrds{currentRAW};size(RAW(session).Erast{RDidx,1}(usedtrials),1)];
            
            globallplat{currentRAW}=[globallplat{currentRAW};RAW(session).Erast{LPidx,1}(actualtrials)];
            globalt2c{currentRAW}=[globalt2c{currentRAW};RAW(session).Erast{T2Cidx,1}(actualtrials)];
            globalpelat{currentRAW}=[globalpelat{currentRAW};RAW(session).Erast{PElatidx,1}(actualtrials)];
            globalnumblicks{currentRAW}=[globalnumblicks{currentRAW};RAW(session).Erast{Licksperidx,1}(usedtrials)];
            globalnumbbouts{currentRAW}=[globalnumbbouts{currentRAW};RAW(session).Erast{Boutsperidx,1}(usedtrials)];
            globaltrialoutcome{currentRAW}=[globaltrialoutcome{currentRAW};RAW(session).Erast{trialtypeidx,1}(usedtrials)];
            globaltrialoutcome{currentRAW}(strcmp(globaltrialoutcome{currentRAW},'omission'))=[];
            %if extremely want to do LME
            %  sessionRD{currentRAW}=[sessionRD{currentRAW};str2double(RAW(session).Einfo{1}(11:12))']
            % trialslplat{currentRAW} = [trialslplat{currentRAW}; find(~isnan(RAW(session).Erast{find(LPidx)+1}))];
            %  sessionlplat{currentRAW}=[sessionlplat{currentRAW};repelem(str2num(RAW(session).Einfo{1}(11:12)),length(RAW(session).Erast{LPidx,1}))']
            % trialst2c{currentRAW} = arrayfun(@(i) find(~isnan(RAW(i).Erast{find(T2Cidx)+1})) .*(sum(~isnan(RAW(i).Erast{find(T2Cidx)+1})) >= 10), 1:numel(RAW), 'UniformOutput', false);
            % trialspelat{currentRAW} = arrayfun(@(i) find(~isnan(RAW(i).Erast{find(PElatidx)+1})) .*(sum(~isnan(RAW(i).Erast{find(PElatidx)+1})) >= 10), 1:numel(RAW), 'UniformOutput', false);
            % trialslicks{currentRAW} = arrayfun(@(i) find(~isnan(RAW(i).Erast{find(Licksperidx)+1})) .*(sum(~isnan(RAW(i).Erast{find(Licksperidx)+1})) >= 10), 1:numel(RAW), 'UniformOutput', false);
            %trialsbouts{currentRAW} = arrayfun(@(i) find(~isnan(RAW(i).Erast{find(Boutsperidx)+1})) .*(sum(~isnan(RAW(i).Erast{find(Boutsperidx)+1})) >= 10), 1:numel(RAW), 'UniformOutput', false);


            if strcmp(RAW(session).Sex,'M')
                malerds{currentRAW}=[malerds{currentRAW};size(RAW(session).Erast{RDidx,1}(usedtrials),1)];
                malelplat{currentRAW}=[malelplat{currentRAW};RAW(session).Erast{LPidx,1}(actualtrials)];
                malet2c{currentRAW}=[malet2c{currentRAW};RAW(session).Erast{T2Cidx,1}(actualtrials)];
                malepelat{currentRAW}=[malepelat{currentRAW};RAW(session).Erast{PElatidx,1}(actualtrials)];
                malenumblicks{currentRAW}=[malenumblicks{currentRAW};RAW(session).Erast{Licksperidx,1}(usedtrials)];
                malenumbbouts{currentRAW}=[globalnumbbouts{currentRAW};RAW(session).Erast{Boutsperidx,1}(usedtrials)];
            elseif strcmp(RAW(session).Sex,'F')
                femalerds{currentRAW}=[femalerds{currentRAW};size(RAW(session).Erast{RDidx,1}(usedtrials),1)];
                femalelplat{currentRAW}=[femalelplat{currentRAW};RAW(session).Erast{LPidx,1}(actualtrials)];
                femalet2c{currentRAW}=[femalet2c{currentRAW};RAW(session).Erast{T2Cidx,1}(actualtrials)];
                femalepelat{currentRAW}=[femalepelat{currentRAW};RAW(session).Erast{PElatidx,1}(actualtrials)];
                femalenumblicks{currentRAW}=[femalenumblicks{currentRAW};RAW(session).Erast{Licksperidx,1}(usedtrials)];
                femalenumbbouts{currentRAW}=[globalnumbbouts{currentRAW};RAW(session).Erast{Boutsperidx,1}(usedtrials)];
            end
            rat_idx=find(strcmp(rats{currentRAW},RAW(session).Subject));
            Ses= session-find(ismember({RAW.Subject},rats{currentRAW}(rat_idx)),1)+1;
            all_sexes{currentRAW}{rat_idx}=RAW(session).Sex;
            all_rats{currentRAW}{rat_idx}=RAW(session).Subject;
            if isempty(perrds{currentRAW}{rat_idx}), perrds{currentRAW}{rat_idx} = []; end
            if isempty(perlplat{currentRAW}{rat_idx}), perlplat{currentRAW}{rat_idx} = []; end
            if isempty(pert2c{currentRAW}{rat_idx}), pert2c{currentRAW}{rat_idx} = []; end
            if isempty(perpelat{currentRAW}{rat_idx}), perpelat{currentRAW}{rat_idx} = []; end
            if isempty(pernumblicks{currentRAW}{rat_idx}), pernumblicks{currentRAW}{rat_idx} = []; end
            if isempty(pernumbbouts{currentRAW}{rat_idx}), pernumbbouts{currentRAW}{rat_idx} = []; end
            perrds{currentRAW}{rat_idx}=[perrds{currentRAW}{rat_idx}; size(RAW(session).Erast{RDidx,1}(usedtrials,1),1)];
            perlplat{currentRAW}{rat_idx}=[perlplat{currentRAW}{rat_idx}; median(RAW(session).Erast{LPidx,1}(usedtrials),'omitnan')];
            perlplatfull{currentRAW}{rat_idx}{Ses}=[RAW(session).Erast{LPidx,1}(usedtrials)];
            pert2c{currentRAW}{rat_idx}=[pert2c{currentRAW}{rat_idx}; median(RAW(session).Erast{T2Cidx,1}(usedtrials),'omitnan')];
            perpelat{currentRAW}{rat_idx}=[perpelat{currentRAW}{rat_idx}; median(RAW(session).Erast{PElatidx,1}(usedtrials),'omitnan')];
            pernumblicks{currentRAW}{rat_idx}=[pernumblicks{currentRAW}{rat_idx}; median(RAW(session).Erast{Licksperidx,1}(usedtrials),'omitnan')];
            pernumbbouts{currentRAW}{rat_idx}=[pernumbbouts{currentRAW}{rat_idx}; median(RAW(session).Erast{Boutsperidx,1}(usedtrials),'omitnan')];
            perrds{currentRAW}{rat_idx}(isnan(perrds{currentRAW}{rat_idx}))=[];
            perlplat{currentRAW}{rat_idx}(isnan(perlplat{currentRAW}{rat_idx}))=[];
            perlplatfull{currentRAW}{rat_idx}{Ses}(isnan(perlplatfull{currentRAW}{rat_idx}{Ses}))=[];
           
            pert2c{currentRAW}{rat_idx}(isnan(pert2c{currentRAW}{rat_idx}))=[];
            perpelat{currentRAW}{rat_idx}(isnan(perpelat{currentRAW}{rat_idx}))=[];
            pernumblicks{currentRAW}{rat_idx}(isnan(pernumblicks{currentRAW}{rat_idx}))=[];
            pernumbbouts{currentRAW}{rat_idx}(isnan(pernumbbouts{currentRAW}{rat_idx}))=[];
           
            %if really want to do LME
            %             perlplatfull{currentRAW}{rat_idx}=[perlplat{currentRAW}{rat_idx}; RAW(session).Erast{LPidx,1}];
            % pert2cfull{currentRAW}{rat_idx}=[pert2c{currentRAW}{rat_idx}; RAW(session).Erast{T2Cidx,1}];
            % perpelatfull{currentRAW}{rat_idx}=[perpelat{currentRAW}{rat_idx}; RAW(session).Erast{PElatidx,1}];
            % pernumblicksfull{currentRAW}{rat_idx}=[pernumblicks{currentRAW}{rat_idx}; RAW(session).Erast{Licksperidx,1}];
            % pernumbboutsfull{currentRAW}{rat_idx}=[pernumbbouts{currentRAW}{rat_idx}; RAW(session).Erast{Boutsperidx,1}];
        end
    end
    fprintf(RAWsinuse{currentRAW});
    globalrds{currentRAW}(isnan(globalrds{currentRAW}))=[];
    globallplat{currentRAW}(isnan(globallplat{currentRAW}))=[];
    globalt2c{currentRAW}(isnan(globalt2c{currentRAW}))=[];
    globalpelat{currentRAW}(isnan(globalpelat{currentRAW}))=[];
    mu = mean(globalrds{currentRAW});
    sigma = std(globalrds{currentRAW});
    [hrd, prd] = kstest(globalrds{currentRAW}, 'CDF', makedist('Normal', 'mu', mu, 'sigma', sigma))
    mu = mean(globallplat{currentRAW});
    sigma = std(globallplat{currentRAW});
    [hlp, plp] = kstest(globallplat{currentRAW}, 'CDF', makedist('Normal', 'mu', mu, 'sigma', sigma))
mu = mean(globalt2c{currentRAW});
sigma = std(globalt2c{currentRAW});    
[ht2c, pt2c] = kstest(globalt2c{currentRAW}, 'CDF', makedist('Normal', 'mu', mu, 'sigma', sigma))
mu = mean(globalpelat{currentRAW});
sigma = std(globalpelat{currentRAW});    
[hpe, ppe] = kstest(globalpelat{currentRAW}, 'CDF', makedist('Normal', 'mu', mu, 'sigma', sigma))
mu = mean(globalnumblicks{currentRAW});
sigma = std(globalnumblicks{currentRAW});    
[hlicks, plicks] = kstest(globalnumblicks{currentRAW}, 'CDF', makedist('Normal', 'mu', mu, 'sigma', sigma))
mu = mean(globalnumbbouts{currentRAW});
sigma = std(globalnumbbouts{currentRAW});
[hbouts, pbouts] = kstest(globalnumbbouts{currentRAW}, 'CDF', makedist('Normal', 'mu', mu, 'sigma', sigma))
binedges=0:1:60;
        colors = {[0.77 0.1 0.37], [0.2 0.28 0.45]};
figure;histogram(globallplat{currentRAW}(strcmp(globaltrialoutcome{currentRAW},'high')),binedges,'EdgeColor','none','FaceColor',colors{1})
hold on;histogram(globallplat{currentRAW}(strcmp(globaltrialoutcome{currentRAW},'low')),binedges,'EdgeColor','none','FaceColor',colors{2})

end
colors=[0.8, 0.6, 0; 0.5 0 0; 0.2, 0.4, 0];


%if you want to see pooled across rats/sessions and trials (for everything
%but RD)
% figure(allgroups);
% a=1;
% b=2;
% c=3;
% d=4;
% e=5;
% f=6;
% for i=1:length(globalrds)
%     minVal=min(cellfun(@min, globalrds));
%     maxVal=max(cellfun(@max, globalrds));
%     edges= linspace(minVal, maxVal, 25 + 1);
%     subplot(4,6,a)
%     histogram(globalrds{i},edges,'FaceColor',colors(i,:))
%     xlim([0 100])
%     ylim([0 20])
%     a=a+6;
%     ylabel(regexp(RAWsinuse{i}, '(?<=W)(.*?)(?=_)', 'match', 'once'),'Color',colors(i,:),'FontSize',15);
%     if i==1
%         subtitle('Rewards','FontSize',15)
%     elseif i==3
%         xlabel('Time (s)')
%     end
% end
% varint=vertcat(globalrds{:});
% group = cellfun(@(x,i) repmat(i, size(x,1), 1), globalrds, num2cell(1:numel(globalrds)), 'UniformOutput', false);
% group = vertcat(group{:});
% [p,tbl,stats]=anova1(varint,group,'off');
% subplot(4,6,a);
% [comp,~,h]=multcompare(stats,'Ctype','dunn-sidak');
% for i=1:length(globallplat)
%     minVal=min(cellfun(@min, globallplat));
%     maxVal=max(cellfun(@max, globallplat));
%     edges= linspace(minVal, maxVal, 100 + 1);
%     subplot(4,6,b)
%     histogram(globallplat{i},edges,'FaceColor',colors(i,:))
%     xlim([0 60])
%     ylim([0 500])
%     b=b+6;
%     if i==1
%         subtitle('LP Latency','FontSize',15)
%     elseif i==3
%         xlabel('Time (s)')
%     end
% end
% varint=vertcat(globallplat{:});
% group = cellfun(@(x,i) repmat(i, size(x,1), 1), globallplat, num2cell(1:numel(globallplat)), 'UniformOutput', false);
% group = vertcat(group{:});
% [p,tbl,stats]=kruskalwallis(varint,group,'off');
% subplot(4,6,b);
% [comp,~,h]=multcompare(stats,'Ctype','dunn-sidak');
% for i=1:length(globalt2c)
%     minVal=min(cellfun(@min, globalt2c));
%     maxVal=max(cellfun(@max, globalt2c));
%     edges= linspace(minVal, maxVal, 100 + 1);
%     subplot(4,6,c)
%     histogram(globalt2c{i},edges,'FaceColor',colors(i,:))
%     xlim([0 30])
%     ylim([0 800])
%     c=c+6;
%     if i==1
%         subtitle('Time to Complete','FontSize',15)
%     elseif i==3
%         xlabel('Time (s)')
%     end
% end
% varint=vertcat(globalt2c{:});
% group = cellfun(@(x,i) repmat(i, size(x,1), 1), globalt2c, num2cell(1:numel(globalt2c)), 'UniformOutput', false);
% group = vertcat(group{:});
% [p,tbl,stats]=kruskalwallis(varint,group,'off');
% subplot(4,6,c);
% [comp,~,h]=multcompare(stats,'Ctype','dunn-sidak');
% for i=1:length(globalpelat)
%     minVal=min(cellfun(@min, globalpelat));
%     maxVal=max(cellfun(@max, globalpelat));
%     edges= linspace(minVal, maxVal, 100 + 1);
%     subplot(4,6,d)
%     histogram(globalpelat{i},edges,'FaceColor',colors(i,:))
%     xlim([0 15])
%     ylim([0 350])
%     d=d+6;
%     if i==1
%         subtitle('PE Latency','FontSize',15)
%     elseif i==3
%         xlabel('Time (s)')
%     end
% end
% varint=vertcat(globalpelat{:});
% group = cellfun(@(x,i) repmat(i, size(x,1), 1), globalpelat, num2cell(1:numel(globalpelat)), 'UniformOutput', false);
% group = vertcat(group{:});
% [p,tbl,stats]=kruskalwallis(varint,group,'off');
% subplot(4,6,d);
% [comp,~,h]=multcompare(stats,'Ctype','dunn-sidak');
% for i=1:length(globalnumblicks)
%     minVal=min(cellfun(@min, globalnumblicks));
%     maxVal=max(cellfun(@max, globalnumblicks));
%     edges= linspace(minVal, maxVal, 75 + 1);
%     subplot(4,6,e)
%     histogram(globalnumblicks{i},edges,'FaceColor',colors(i,:))
%     xlim([0 200])
%     ylim([0 350])
%     e=e+6;
%     if i==1
%         subtitle('Licks per Reward','FontSize',15)
%     elseif i==3
%         xlabel('Licks')
%     end
% end
% varint=vertcat(globalnumblicks{:});
% group = cellfun(@(x,i) repmat(i, size(x,1), 1), globalnumblicks, num2cell(1:numel(globalnumblicks)), 'UniformOutput', false);
% group = vertcat(group{:});
% [p,tbl,stats]=kruskalwallis(varint,group,'off');
% subplot(4,6,e);
% [comp,~,h]=multcompare(stats,'Ctype','dunn-sidak');
% for i=1:length(globalnumbbouts)
%     minVal=min(cellfun(@min, globalnumbbouts));
%     maxVal=max(cellfun(@max, globalnumbbouts));
%     edges= linspace(minVal, maxVal, 10 + 1);
%     subplot(4,6,f)
%     histogram(globalnumbbouts{i},edges,'FaceColor',colors(i,:))
%     xlim([0 10])
%     ylim([0 1500])
%     f=f+6;
%     if i==1
%         subtitle('Bouts per Reward','FontSize',15)
%     elseif i==3
%         xlabel('Bouts')
%     end
% end
% varint=vertcat(globalnumbbouts{:});
% group = cellfun(@(x,i) repmat(i, size(x,1), 1), globalnumbbouts, num2cell(1:numel(globalnumbbouts)), 'UniformOutput', false);
% group = vertcat(group{:});
% [p,tbl,stats]=kruskalwallis(varint,group,'off');
% subplot(4,6,f);
% [comp,~,h]=multcompare(stats,'Ctype','dunn-sidak');

figure(mvf);
a=1;
b=2;
c=3;
d=4;
e=5;
f=6;
for i=1:length(globalrds)
    minVal=min([cellfun(@min, malerds),cellfun(@min, femalerds)]);
    maxVal=max([cellfun(@max, malerds),cellfun(@max, femalerds)]);
    edges= linspace(minVal, maxVal, 25 + 1);
    subplot(3,6,a)
    hold on
    histogram(malerds{i},edges,'FaceColor','b')
    histogram(femalerds{i},edges,'FaceColor','m')
    xlim([0 100])
    ylim([0 20])
    a=a+6;
    ylabel(regexp(RAWsinuse{i}, '(?<=W)(.*?)(?=_)', 'match', 'once'),'Color',colors(i,:),'FontSize',15);
    if i==1
        subtitle('Rewards','FontSize',15)
    elseif i==3
        xlabel('Time (s)')
    end
end
for i=1:length(globallplat)
    minVal=min([cellfun(@min, malelplat),cellfun(@min, femalelplat)]);
    maxVal=max([cellfun(@max, malelplat),cellfun(@max, femalelplat)]);
    edges= linspace(minVal, maxVal, 50 + 1);
    subplot(3,6,b)
    hold on
    histogram(malelplat{i},edges,'FaceColor','b')
    histogram(femalelplat{i},edges,'FaceColor','m')
    xlim([0 60])
    ylim([0 500])
    b=b+6;
    if i==1
        subtitle('LP Latency','FontSize',15)
    elseif i==3
        xlabel('Time (s)')
    end
end
for i=1:length(globalt2c)
    minVal=min([cellfun(@min, malet2c),cellfun(@min, femalet2c)]);
    maxVal=max([cellfun(@max, malet2c),cellfun(@max, femalet2c)]);
    edges= linspace(minVal, maxVal, 75 + 1);
    subplot(3,6,c)
    hold on
    histogram(malet2c{i},edges,'FaceColor','b')
    histogram(femalet2c{i},edges,'FaceColor','m')
    xlim([0 30])
    ylim([0 500])
    c=c+6;
    if i==1
        subtitle('Time to Complete','FontSize',15)
    elseif i==3
        xlabel('Time (s)')
    end
end
for i=1:length(globalpelat)
    minVal=min([cellfun(@min, malepelat),cellfun(@min, femalepelat)]);
    maxVal=max([cellfun(@max, malepelat),cellfun(@max, femalepelat)]);
    edges= linspace(minVal, maxVal, 100 + 1);
    subplot(3,6,d)
    hold on
    histogram(malepelat{i},edges,'FaceColor','b')
    histogram(femalepelat{i},edges,'FaceColor','m')
    xlim([0 15])
    ylim([0 250])
    d=d+6;
    if i==1
        subtitle('PE Latency','FontSize',15)
    elseif i==3
        xlabel('Time (s)')
    end
end
for i=1:length(globalnumblicks)
    minVal=min([cellfun(@min, malenumblicks),cellfun(@min, femalenumblicks)]);
    maxVal=max([cellfun(@max, malenumblicks),cellfun(@max, femalenumblicks)]);
    edges= linspace(minVal, maxVal, 50 + 1);
    subplot(3,6,e)
    hold on
    histogram(malenumblicks{i},edges,'FaceColor','b')
    histogram(femalenumblicks{i},edges,'FaceColor','m')
    xlim([0 200])
    ylim([0 250])
    e=e+6;
    if i==1
        subtitle('Licks per Reward','FontSize',15)
    elseif i==3
        xlabel('Licks')
    end
end
for i=1:length(globalnumbbouts)
    minVal=min([cellfun(@min, malenumbbouts),cellfun(@min, femalenumbbouts)]);
    maxVal=max([cellfun(@max, malenumbbouts),cellfun(@max, femalenumbbouts)]);
    edges= linspace(minVal, maxVal, 10 + 1);
    subplot(3,6,f)
    hold on
    histogram(malenumbbouts{i},edges,'FaceColor','b')
    histogram(femalenumbbouts{i},edges,'FaceColor','m')
    xlim([0 15])
    ylim([0 1500])
    
    f=f+6;
    if i==1
        subtitle('Bouts per Reward','FontSize',15)
    elseif i==3
        xlabel('Bouts')
    end
end
figure(perrat);
j=1;
k=2;
l=3;
m=4;
n=5;
o=6;    
for i=1:length(globalrds)

    subplot(4,6,j)
    hold on
color=turbo(length(perrds{i}));
for rat=1:length(perrds{i})
    scatter(rat+0.2,perrds{i}{rat},10,'MarkerEdgeColor',color(rat,:))
    plot(rat-0.2,mean(perrds{i}{rat}),'Marker','o','MarkerSize',4,'MarkerEdgeColor',color(rat,:),'MarkerFaceColor',color(rat,:))
    error=[-std(perrds{i}{rat},1),std(perrds{i}{rat},1)];
    errorbar(rat-0.2,mean(perrds{i}{rat}),error,'Color',color(rat,:))
    varint=perrds{i};
    inds = num2cell((1:numel(perrds{i}))');  % make sure it's a column cell array
    ratgroups = cellfun(@(x, b) repmat(b, size(x,1), 1),perrds{i}, inds, 'UniformOutput', false);
    pRDper(i)=anova1(cell2mat(varint),cell2mat(ratgroups),'off');
end
xlim([0 length(perrds{i})+1])
ylim([0 51])
xticks(1:length(perrds{i}))
xticklabels(unique(rats{i}))
xtickangle(45)
ylabel(regexp(RAWsinuse{i}, '(?<=W)(.*?)(?=_)', 'match', 'once'),'Color',colors(i,:),'FontSize',15);
if i==1
    subtitle('Rewards','FontSize',15)
elseif i==3
    xlabel('Rat')
end
j = j + 6;
end
varint=cellfun(@mean,vertcat(perrds{:}));
group = cellfun(@(x,i) repmat(i, size(x,1), 1), perrds, num2cell(1:numel(perrds)), 'UniformOutput', false);
group = vertcat(group{:});
[p,tbl,stats]=anova1(varint,group,'off');
subplot(4,6,j);
hold on;
gm = cellfun(@(c) mean(cellfun(@mean,c)), perrds);
se = cellfun(@(c) std(cellfun(@mean,c))/sqrt(numel(c)), perrds);

for g = 1:3
    errorbar(g, gm(g), se(g), 'o', 'Color', colors(g,:), 'MarkerFaceColor', colors(g,:),  'MarkerSize', 4)
    scatter(repmat(g, size(perrds{g}))+0.2, cellfun(@mean, perrds{g}), 10, colors(g,:), 'MarkerFaceAlpha', 0.6)
end

xlim([0 4])
xticks(1:3)
xticklabels(regexp(RAWsinuse, '(?<=W)(.*?)(?=_)', 'match', 'once'))
ylabel('Rewards')
ylim([0 51])
[comp,~,h]=multcompare(stats,'Ctype','bonferroni','Display','off');



for i=1:length(perlplatfull)
  ratList = struct;
ratCounter = 0;

    for r = 1:length(perlplatfull{i})
        ratCounter = ratCounter + 1;
        ratList(ratCounter).ratInGroup = r;
        ratList(ratCounter).sex = all_sexes{i}(r);   % 1 = F, 2 = M
    end

% Sort females first
[~, sortIdx] = sort([ratList.sex]);
ratList = ratList(sortIdx);
    subplot(4,6,k)
    hold on
    color=turbo(length(perlplat{i}));
    ratcounter=0;
    sessioncounter=0;
    allVals=[];
    sessionID    = [];
    ratID        = [];
    positions = [];
ratCenters = [];
currentPos = 1;
gap = 1.5;   % space between rats
for rat = [ratList.ratInGroup]

    ratSessions = length(perlplatfull{i}{rat});
    
    
    for ratsession = 1:ratSessions
        if ~isempty(perlplatfull{i}{rat}{ratsession})
        sessioncounter = sessioncounter + 1;
        end
        vals = perlplatfull{i}{rat}{ratsession};
        n2 = length(vals);

        allVals   = [allVals; vals(:)];
        sessionID = [sessionID; sessioncounter * ones(n2,1)];
        ratID     = [ratID; rat * ones(n2,1)];
        
        %         scatter(rat+0.2,perlplat{i}{rat},10,'MarkerEdgeColor',color(rat,:))
        %         plot(rat-0.2, median(perlplat{i}{rat}),'Marker','o','MarkerSize',4,'MarkerEdgeColor',color(rat,:),'MarkerFaceColor',color(rat,:))
        %         d = perlplat{i}{rat};
        %         d(d==0) = [];
        %         q =prctile(d, [10 50 90]);
        %         errorbar(rat-0.2, q(2), q(2)-q(1), q(3)-q(2), 'Color', color(rat,:))
        varint=perlplat{i};
        inds = num2cell((1:numel(perlplat{i}))');  % make sure it's a column cell array
        ratgroups = cellfun(@(x, b) repmat(b, size(x,1), 1),perlplat{i}, inds, 'UniformOutput', false);
        pLPlatper(i)=kruskalwallis(cell2mat(varint),cell2mat(ratgroups),'off');
    end
end
uniqueRats = unique(ratID);
ax = gca;
origPos = ax.Position;
boxplot(allVals, sessionID,'BoxStyle','outline','Colors', 'k')
ax.Position = origPos;
hold on
h = findobj(gca,'Tag','Box');
% Important: boxes are plotted in reverse order
h = flipud(h);

sessionsused=unique(sessionID);
for l2 = 1:length(h)
    
    thisSession = sessionsused(l2);
    
    % Find rat corresponding to this session
    thisRat = mode(ratID(sessionID == thisSession));
    
    patch(get(h(l2),'XData'), ...
          get(h(l2),'YData'), ...
          color(thisRat,:), ...
          'FaceAlpha',0.15,'EdgeColor', color(thisRat,:));
end


for r = uniqueRats'

    
    y = median(perlplat{i}{r});
    
    theseSessions = unique(sessionID(ratID == r));
    
    xmin = min(theseSessions) - 0.3;
    xmax = max(theseSessions) + 0.3;
    
    plot([xmin xmax], [y y], ...
         'Color', color(r,:), ...
         'LineWidth', 3)
end
xlim([0 max(sessionID)+1])
    ylim([0 60])
    xtickangle(45)
if i==1
    subtitle('LP Latency','FontSize',15)
elseif i==3
    xlabel('Session')
end

k = k + 6;
end
varint=cellfun(@mean,vertcat(perlplat{:}));
group = cellfun(@(x,i) repmat(i, size(x,1), 1), perlplat, num2cell(1:numel(perlplat)), 'UniformOutput', false);
group = vertcat(group{:});
[p,tbl,stats]=anova1(varint,group,'off');
subplot(4,6,k);
hold on;
gm = cellfun(@(c) mean(cellfun(@median,c)), perlplat);
se = cellfun(@(c) std(cellfun(@median,c))/sqrt(numel(c)), perlplat);

for g = 1:3
    errorbar(g, gm(g), se(g), 'o', 'Color', colors(g,:), 'MarkerFaceColor', colors(g,:),  'MarkerSize',4)
    scatter(repmat(g, size(perlplat{g}))+0.2,cellfun(@median, perlplat{g}), 10, colors(g,:), 'MarkerFaceAlpha', 0.6)
end

xlim([0 4])
xticks(1:3)
xticklabels(regexp(RAWsinuse, '(?<=W)(.*?)(?=_)', 'match', 'once'))
ylabel('Time (s)')
ylim([0 35])
[comp,~,h]=multcompare(stats,'Ctype','bonferroni','Display','off');
for i=1:length(globalt2c)
     
    subplot(4,6,l)
    hold on
color=turbo(length(pert2c{i}));
for rat=1:length(pert2c{i})
    scatter(rat+0.2,pert2c{i}{rat},10,'MarkerEdgeColor',color(rat,:))
    plot(rat-0.2,median(pert2c{i}{rat}),'Marker','o','MarkerSize',4,'MarkerEdgeColor',color(rat,:),'MarkerFaceColor',color(rat,:))
    d = pert2c{i}{rat};
d(d==0) = [];
q =prctile(d, [10 50 90]);
errorbar(rat-0.2, q(2), q(2)-q(1), q(3)-q(2), 'Color', color(rat,:))
            varint=pert2c{i};
    inds = num2cell((1:numel(pert2c{i}))');  % make sure it's a column cell array
    ratgroups = cellfun(@(x, b) repmat(b, size(x,1), 1),pert2c{i}, inds, 'UniformOutput', false);
    pT2Cper(i)=kruskalwallis(cell2mat(varint),cell2mat(ratgroups),'off');
end
xlim([0 length(pert2c{i})+1])
ylim([0 8])
xticks(1:length(pert2c{i}))
xticklabels(unique(rats{i}))
    xtickangle(45)
if i==1
    subtitle('T2C','FontSize',15)
elseif i==3
    xlabel('Rat')
end

    l = l + 6;
end
varint=cellfun(@mean,vertcat(pert2c{:}));
group = cellfun(@(x,i) repmat(i, size(x,1), 1), pert2c, num2cell(1:numel(pert2c)), 'UniformOutput', false);
group = vertcat(group{:});
[p,tbl,stats]=anova1(varint,group,'off');
subplot(4,6,l);
hold on
gm = cellfun(@(c) mean(cellfun(@median,c)), pernumbbouts);
se = cellfun(@(c) std(cellfun(@median,c))/sqrt(numel(c)), pernumbbouts);

for g = 1:3
    errorbar(g, gm(g), se(g), 'o', 'Color', colors(g,:), 'MarkerFaceColor', colors(g,:),  'MarkerSize',4)
    scatter(repmat(g, size(pernumbbouts{g}))+0.2,cellfun(@median, pernumbbouts{g}), 10, colors(g,:), 'MarkerFaceAlpha', 0.6)
end

xlim([0 4])
xticks(1:3)
xticklabels(regexp(RAWsinuse, '(?<=W)(.*?)(?=_)', 'match', 'once'))
ylabel('Time (s)')
ylim([0 4])
[comp,~,h]=multcompare(stats,'Ctype','bonferroni','Display','off');
for i=1:length(globalpelat)
       subplot(4,6,m)
    hold on
color=turbo(length(perpelat{i}));
for rat=1:length(perpelat{i})
    scatter(rat+0.2,perpelat{i}{rat},10,'MarkerEdgeColor',color(rat,:))
    plot(rat-0.2,median(perpelat{i}{rat}),'Marker','o','MarkerSize',4,'MarkerEdgeColor',color(rat,:),'MarkerFaceColor',color(rat,:))
   d = perpelat{i}{rat};
d(d==0) = [];
q =prctile(d, [10 50 90]);
errorbar(rat-0.2, q(2), q(2)-q(1), q(3)-q(2),  'Color', color(rat,:))
                varint=perpelat{i};
    inds = num2cell((1:numel(perpelat{i}))');  % make sure it's a column cell array
    ratgroups = cellfun(@(x, b) repmat(b, size(x,1), 1),perpelat{i}, inds, 'UniformOutput', false);
    pPElatper(i)=kruskalwallis(cell2mat(varint),cell2mat(ratgroups),'off');
end
xlim([0 length(perpelat{i})+1])
ylim([0 4])
xticks(1:length(perpelat{i}))
xticklabels(unique(rats{i}))
    xtickangle(45)
if i==1
    subtitle('PE Latency','FontSize',15)
elseif i==3
    xlabel('Rat')
end
    m = m + 6;
end
varint=cellfun(@mean,vertcat(perpelat{:}));
group = cellfun(@(x,i) repmat(i, size(x,1), 1), perpelat, num2cell(1:numel(perpelat)), 'UniformOutput', false);
group = vertcat(group{:});
[p,tbl,stats]=anova1(varint,group,'off');
subplot(4,6,m);
hold on
gm = cellfun(@(c) mean(cellfun(@median,c)), perpelat);
se = cellfun(@(c) std(cellfun(@median,c))/sqrt(numel(c)), perpelat);

for g = 1:3
    errorbar(g, gm(g), se(g), 'o', 'Color', colors(g,:), 'MarkerFaceColor', colors(g,:),  'MarkerSize',4)
    scatter(repmat(g, size(perpelat{g}))+0.2,cellfun(@median, perpelat{g}), 10, colors(g,:), 'MarkerFaceAlpha', 0.6)
end
xlim([0 4])
xticks(1:3)
ylim([0 3])
xticklabels(regexp(RAWsinuse, '(?<=W)(.*?)(?=_)', 'match', 'once'))
ylabel('Time (s)')
[comp,~,h]=multcompare(stats,'Ctype','bonferroni','Display','off');
for i=1:length(globalnumblicks)
          subplot(4,6,n)
    hold on
color=turbo(length(pernumblicks{i}));
for rat=1:length(pernumblicks{i})
    pernumblicks{i}{rat}(pernumblicks{i}{rat}<5)=[];
    scatter(rat+0.2,pernumblicks{i}{rat},10,'MarkerEdgeColor',color(rat,:))
    plot(rat-0.2,median(pernumblicks{i}{rat}),'Marker','o','MarkerSize',4,'MarkerEdgeColor',color(rat,:),'MarkerFaceColor',color(rat,:))
    d = pernumblicks{i}{rat};
d(d==0) = [];
q = prctile(d, [10 50 90]);
errorbar(rat-0.2, q(2), q(2)-q(1), q(3)-q(2), 'Color', color(rat,:))                
    varint=pernumblicks{i};
    inds = num2cell((1:numel(pernumblicks{i}))');  % make sure it's a column cell array
    ratgroups = cellfun(@(x, b) repmat(b, size(x,1), 1),pernumblicks{i}, inds, 'UniformOutput', false);
    plicksper(i)=kruskalwallis(cell2mat(varint),cell2mat(ratgroups),'off');
end
xlim([0 length(pernumblicks{i})+1])
ylim([0 100])
xticks(1:length(pernumblicks{i}))
xticklabels(unique(rats{i}))
    xtickangle(45)
if i==1
    subtitle('Licks per RD','FontSize',15)
elseif i==3
    xlabel('Rat')
end

    n = n + 6;
end
varint=cellfun(@mean,vertcat(pernumblicks{:}));
group = cellfun(@(x,i) repmat(i, size(x,1), 1), pernumblicks, num2cell(1:numel(pernumblicks)), 'UniformOutput', false);
group = vertcat(group{:});
[p,tbl,stats]=anova1(varint,group,'off');
subplot(4,6,n);
hold on
gm = cellfun(@(c) mean(cellfun(@median,c)), pernumblicks);
se = cellfun(@(c) std(cellfun(@median,c))/sqrt(numel(c)), pernumblicks);

for g = 1:3
    errorbar(g, gm(g), se(g), 'o', 'Color', colors(g,:), 'MarkerFaceColor', colors(g,:),  'MarkerSize',4)
    scatter(repmat(g, size(pernumblicks{g}))+0.2,cellfun(@median, pernumblicks{g}), 10, colors(g,:), 'MarkerFaceAlpha', 0.6)
end
xlim([0 4])
xticks(1:3)
ylim([0 100])
xticklabels(regexp(RAWsinuse, '(?<=W)(.*?)(?=_)', 'match', 'once'))
ylabel('Number')
[comp,~,h]=multcompare(stats,'Ctype','bonferroni','Display','off');
for i=1:length(globalnumbbouts)
            subplot(4,6,o)
    hold on
color=turbo(length(pernumbbouts{i}));
for rat=1:length(pernumbbouts{i})
        pernumbbouts{i}{rat}(pernumbbouts{i}{rat}==0)=[];
    scatter(rat+0.2,pernumbbouts{i}{rat},10,'MarkerEdgeColor',color(rat,:))
    plot(rat-0.2,median(pernumbbouts{i}{rat}),'Marker','o','MarkerSize',4,'MarkerEdgeColor',color(rat,:),'MarkerFaceColor',color(rat,:))
    d = pernumbbouts{i}{rat};
d(d==0) = [];
q = prctile(d, [10 50 90]);
errorbar(rat-0.2, q(2), q(2)-q(1), q(3)-q(2), 'Color', color(rat,:))
    varint=pernumbbouts{i};
    inds = num2cell((1:numel(pernumbbouts{i}))');  % make sure it's a column cell array
    ratgroups = cellfun(@(x, b) repmat(b, size(x,1), 1),pernumbbouts{i}, inds, 'UniformOutput', false);
    pnumboutper(i)=kruskalwallis(cell2mat(varint),cell2mat(ratgroups),'off');
end
xlim([0 length(pernumbbouts{i})+1])
ylim([0 6])
xticks(1:length(pernumbbouts{i}))
xticklabels(unique(rats{i}))
    xtickangle(45)
if i==1
    subtitle('Bouts per RD','FontSize',15)
elseif i==3
    xlabel('Rat')
end

    o = o + 6;
end
varint=cellfun(@mean,vertcat(pernumbbouts{:}));
group = cellfun(@(x,i) repmat(i, size(x,1), 1), pernumbbouts, num2cell(1:numel(pernumbbouts)), 'UniformOutput', false);
group = vertcat(group{:});
[p,tbl,stats]=anova1(varint,group,'off');
subplot(4,6,o);
hold on
gm = cellfun(@(c) mean(cellfun(@median,c)), pernumbbouts);
se = cellfun(@(c) std(cellfun(@mean,c))/sqrt(numel(c)), pernumbbouts);

for g = 1:3
    errorbar(g, gm(g), se(g), 'o', 'Color', colors(g,:), 'MarkerFaceColor', colors(g,:),  'MarkerSize',4)
    scatter(repmat(g, size(pernumbbouts{g}))+0.2,cellfun(@median, pernumbbouts{g}), 10, colors(g,:), 'MarkerFaceAlpha', 0.6)
end
xlim([0 4])
xticks(1:3)
ylim([0 4])
xticklabels(regexp(RAWsinuse, '(?<=W)(.*?)(?=_)', 'match', 'once'))
ylabel('Number')
[comp,~,h]=multcompare(stats,'Ctype','bonferroni','Display','off');

figure(permvf)
p=1;
q=2;
r=3;
s1=4;
t=5;
u=6;   
% --- Step 1: Extract unique rats and their sexes from RAW struct array ---
for i=1:length(globalrds)

[unique_rats, ia] = unique(all_rats{i}, 'stable');  % unique rats in order of appearance
rat_sexes = all_sexes{i}(ia);                       % sexes corresponding to unique rats

% --- Step 2: Align pernumbbouts{i} with unique_rats ---

% Assuming pernumbbouts{i} is a 1 x N cell array of numeric data per rat
% and the order matches unique_rats exactly.
% If not, you'll need to reorder pernumbbouts{i} to match unique_rats.

% Step 3: Calculate mean per rat across sessions

% Step 4: Get unique sexes and map to x-axis positions
unique_sexes_list = unique(rat_sexes);
x_positions = containers.Map(unique_sexes_list, 1:length(unique_sexes_list));

% --- Step 5: Plotting ---
subplot(3,6,p)
hold on;
rat_means = cellfun(@mean, perrds{i});
color=turbo(length(perrds{i}));
for s = 1:length(unique_sexes_list)
    sex = unique_sexes_list{s};
    idx = strcmp(rat_sexes, sex);   % logical index for rats of this sex
    
    % X base position for this sex group
    x_base = x_positions(sex);
    
    
    % Scatter plot of individual rat means for this sex
    scatter(x_base+0.2, rat_means(idx), 20 , color(idx,:),'MarkerFaceAlpha', 0.6)
    
    % Calculate and plot mean ± SEM for this sex group
    group_mean = mean(rat_means(idx));
    group_sem = std(rat_means(idx)) / sqrt(sum(idx));
      scatter(x_base,group_mean,'filled','k')
    errorbar(x_base, group_mean, group_sem, 'k', 'LineWidth', 2)
    idx_sex1 = strcmp(rat_sexes, unique_sexes_list{1});
    idx_sex2 = strcmp(rat_sexes, unique_sexes_list{2});
    
    data1 = rat_means(idx_sex1);
    data2 = rat_means(idx_sex2);
    
    % Run ranksum test (Mann-Whitney U)
    [p2, ~, stats] = ranksum(data1, data2);
    
    % Format p-value string to avoid 0.0000 appearance
    if p2 < 1e-4
        p_str = sprintf('p < %.1e', 1e-4);
    else
        p_str = sprintf('p = %.4f', p2);
    end
    


end
% Print results
fprintf('Group %d Rewards: Comparing sexes "%s" vs "%s"\n', i, unique_sexes_list{1}, unique_sexes_list{2});
fprintf('  N=%d vs N=%d, median=%.3f vs %.3f, %s, rank sum statistic=%.1f\n\n', ...
    sum(idx_sex1), sum(idx_sex2), median(data1), median(data2), p_str, stats.ranksum);
p=p+6;
xlim([0.5, length(unique_sexes_list)+0.5])
xticks(1:length(unique_sexes_list))
xticklabels(unique_sexes_list)
ylim([0 100])
ylabel(regexp(RAWsinuse{i}, '(?<=W)(.*?)(?=_)', 'match', 'once'),'Color',colors(i,:),'FontSize',15);
if i==1
    subtitle('Rewards','FontSize',15)
elseif i==3
    xlabel('Sex')
end
end

for i=1:length(globallplat)

[unique_rats, ia] = unique(all_rats{i}, 'stable');  % unique rats in order of appearance
rat_sexes = all_sexes{i}(ia);                       % sexes corresponding to unique rats

% --- Step 2: Align pernumbbouts{i} with unique_rats ---

% Assuming pernumbbouts{i} is a 1 x N cell array of numeric data per rat
% and the order matches unique_rats exactly.
% If not, you'll need to reorder pernumbbouts{i} to match unique_rats.

% Step 3: Calculate mean per rat across sessions

% Step 4: Get unique sexes and map to x-axis positions
unique_sexes_list = unique(rat_sexes);
x_positions = containers.Map(unique_sexes_list, 1:length(unique_sexes_list));

% --- Step 5: Plotting ---
subplot(3,6,q)
hold on;
rat_means = cellfun(@mean, perlplat{i});
color=turbo(length(perlplat{i}));
for s = 1:length(unique_sexes_list)
    sex = unique_sexes_list{s};
    idx = strcmp(rat_sexes, sex);   % logical index for rats of this sex
    
    % X base position for this sex group
    x_base = x_positions(sex);
       
    % Scatter plot of individual rat means for this sex
    scatter(x_base+0.2, rat_means(idx), 20, color(idx,:), 'MarkerFaceAlpha', 0.6 )
    
    % Calculate and plot mean ± SEM for this sex group
    group_mean = mean(rat_means(idx));
    group_sem = std(rat_means(idx)) / sqrt(sum(idx));
      scatter(x_base,group_mean,'filled','k')
    errorbar(x_base, group_mean, group_sem, 'k', 'LineWidth', 2)
    idx_sex1 = strcmp(rat_sexes, unique_sexes_list{1});
    idx_sex2 = strcmp(rat_sexes, unique_sexes_list{2});
    
    data1 = rat_means(idx_sex1);
    data2 = rat_means(idx_sex2);
    
    % Run ranksum test (Mann-Whitney U)
    [p2, ~, stats] = ranksum(data1, data2);
    
    % Format p-value string to avoid 0.0000 appearance
    if p2 < 1e-4
        p_str = sprintf('p < %.1e', 1e-4);
    else
        p_str = sprintf('p = %.4f', p2);
    end
    


end
% Print results
fprintf('Group %d LP Lat: Comparing sexes "%s" vs "%s"\n', i, unique_sexes_list{1}, unique_sexes_list{2});
fprintf('  N=%d vs N=%d, median=%.3f vs %.3f, %s, rank sum statistic=%.1f\n\n', ...
    sum(idx_sex1), sum(idx_sex2), median(data1), median(data2), p_str, stats.ranksum);
q=q+6;
xlim([0.5, length(unique_sexes_list)+0.5])
xticks(1:length(unique_sexes_list))
xticklabels(unique_sexes_list)
ylim([0 20])
if i==1
    subtitle('LP Latency','FontSize',15)
elseif i==3
    xlabel('Sex')
end
end

for i=1:length(globalt2c)

[unique_rats, ia] = unique(all_rats{i}, 'stable');  % unique rats in order of appearance
rat_sexes = all_sexes{i}(ia);                       % sexes corresponding to unique rats

% --- Step 2: Align pernumbbouts{i} with unique_rats ---

% Assuming pernumbbouts{i} is a 1 x N cell array of numeric data per rat
% and the order matches unique_rats exactly.
% If not, you'll need to reorder pernumbbouts{i} to match unique_rats.

% Step 3: Calculate mean per rat across sessions

% Step 4: Get unique sexes and map to x-axis positions
unique_sexes_list = unique(rat_sexes);
x_positions = containers.Map(unique_sexes_list, 1:length(unique_sexes_list));

% --- Step 5: Plotting ---
subplot(3,6,r)
hold on;
rat_means = cellfun(@mean, pert2c{i});
color=turbo(length(pert2c{i}));
for s = 1:length(unique_sexes_list)
    sex = unique_sexes_list{s};
    idx = strcmp(rat_sexes, sex);   % logical index for rats of this sex
    
    % X base position for this sex group
    x_base = x_positions(sex);
    
    
    % Scatter plot of individual rat means for this sex
    scatter(x_base+0.2, rat_means(idx), 20, color(idx,:) , 'MarkerFaceAlpha', 0.6)
    
    % Calculate and plot mean ± SEM for this sex group
    group_mean = mean(rat_means(idx));
    group_sem = std(rat_means(idx)) / sqrt(sum(idx));
      scatter(x_base,group_mean,'filled','k')
    errorbar(x_base, group_mean, group_sem, 'k', 'LineWidth', 2)
    idx_sex1 = strcmp(rat_sexes, unique_sexes_list{1});
    idx_sex2 = strcmp(rat_sexes, unique_sexes_list{2});
    
    data1 = rat_means(idx_sex1);
    data2 = rat_means(idx_sex2);
    
    % Run ranksum test (Mann-Whitney U)
    [p2, ~, stats] = ranksum(data1, data2);
    
    % Format p-value string to avoid 0.0000 appearance
    if p2 < 1e-4
        p_str = sprintf('p < %.1e', 1e-4);
    else
        p_str = sprintf('p = %.4f', p2);
    end
    


end
% Print results
fprintf('Group %d T2C: Comparing sexes "%s" vs "%s"\n', i, unique_sexes_list{1}, unique_sexes_list{2});
fprintf('  N=%d vs N=%d, median=%.3f vs %.3f, %s, rank sum statistic=%.1f\n\n', ...
    sum(idx_sex1), sum(idx_sex2), median(data1), median(data2), p_str, stats.ranksum);
r=r+6;
xlim([0.5, length(unique_sexes_list)+0.5])
xticks(1:length(unique_sexes_list))
xticklabels(unique_sexes_list)
ylim([0 5])
if i==1
    subtitle('T2C','FontSize',15)
elseif i==3
    xlabel('Sex')
end
end

for i=1:length(globalpelat)

[unique_rats, ia] = unique(all_rats{i}, 'stable');  % unique rats in order of appearance
rat_sexes = all_sexes{i}(ia);                       % sexes corresponding to unique rats

% --- Step 2: Align pernumbbouts{i} with unique_rats ---

% Assuming pernumbbouts{i} is a 1 x N cell array of numeric data per rat
% and the order matches unique_rats exactly.
% If not, you'll need to reorder pernumbbouts{i} to match unique_rats.

% Step 3: Calculate mean per rat across sessions

% Step 4: Get unique sexes and map to x-axis positions
unique_sexes_list = unique(rat_sexes);
x_positions = containers.Map(unique_sexes_list, 1:length(unique_sexes_list));

% --- Step 5: Plotting ---
subplot(3,6,s1)
hold on;
rat_means = cellfun(@mean, perpelat{i});
color=turbo(length(perpelat{i}));
for s = 1:length(unique_sexes_list)
    sex = unique_sexes_list{s};
    idx = strcmp(rat_sexes, sex);   % logical index for rats of this sex
    
    % X base position for this sex group
    x_base = x_positions(sex);
    
    
    % Scatter plot of individual rat means for this sex
    scatter(x_base+0.2, rat_means(idx), 20 ,color(idx,:), 'MarkerFaceAlpha', 0.6)
    
    % Calculate and plot mean ± SEM for this sex group
    group_mean = mean(rat_means(idx));
    group_sem = std(rat_means(idx)) / sqrt(sum(idx));
      scatter(x_base,group_mean,'filled','k')
    errorbar(x_base, group_mean, group_sem, 'k', 'LineWidth', 2)
    idx_sex1 = strcmp(rat_sexes, unique_sexes_list{1});
    idx_sex2 = strcmp(rat_sexes, unique_sexes_list{2});
    
    data1 = rat_means(idx_sex1);
    data2 = rat_means(idx_sex2);
    
    % Run ranksum test (Mann-Whitney U)
    [p2, ~, stats] = ranksum(data1, data2);
    
    % Format p-value string to avoid 0.0000 appearance
    if p2 < 1e-4
        p_str = sprintf('p < %.1e', 1e-4);
    else
        p_str = sprintf('p = %.4f', p2);
    end
    


end
% Print results
fprintf('Group %d PE lat: Comparing sexes "%s" vs "%s"\n', i, unique_sexes_list{1}, unique_sexes_list{2});
fprintf('  N=%d vs N=%d, median=%.3f vs %.3f, %s, rank sum statistic=%.1f\n\n', ...
    sum(idx_sex1), sum(idx_sex2), median(data1), median(data2), p_str, stats.ranksum);
s1=s1+6;
xlim([0.5, length(unique_sexes_list)+0.5])
xticks(1:length(unique_sexes_list))
xticklabels(unique_sexes_list)
ylim([0 5])
if i==1
    subtitle('PE Latency','FontSize',15)
elseif i==3
    xlabel('Sex')
end
end

for i=1:length(globalnumblicks)

[unique_rats, ia] = unique(all_rats{i}, 'stable');  % unique rats in order of appearance
rat_sexes = all_sexes{i}(ia);                       % sexes corresponding to unique rats

% --- Step 2: Align pernumbbouts{i} with unique_rats ---

% Assuming pernumbbouts{i} is a 1 x N cell array of numeric data per rat
% and the order matches unique_rats exactly.
% If not, you'll need to reorder pernumbbouts{i} to match unique_rats.

% Step 3: Calculate mean per rat across sessions

% Step 4: Get unique sexes and map to x-axis positions
unique_sexes_list = unique(rat_sexes);
x_positions = containers.Map(unique_sexes_list, 1:length(unique_sexes_list));

% --- Step 5: Plotting ---
subplot(3,6,t)
hold on;
rat_means = cellfun(@mean, pernumblicks{i});
color=turbo(length(pernumblicks{i}));
for s = 1:length(unique_sexes_list)
    sex = unique_sexes_list{s};
    idx = strcmp(rat_sexes, sex);   % logical index for rats of this sex
    
    % X base position for this sex group
    x_base = x_positions(sex);
    
    
    % Scatter plot of individual rat means for this sex
    scatter(x_base+0.2, rat_means(idx), 20,color(idx,:) , 'MarkerFaceAlpha', 0.6)
    
    % Calculate and plot mean ± SEM for this sex group
    group_mean = mean(rat_means(idx));
    group_sem = std(rat_means(idx)) / sqrt(sum(idx));
    scatter(x_base,group_mean,'filled','k')
    errorbar(x_base, group_mean, group_sem, 'k', 'LineWidth', 2)
    idx_sex1 = strcmp(rat_sexes, unique_sexes_list{1});
    idx_sex2 = strcmp(rat_sexes, unique_sexes_list{2});
    
    data1 = rat_means(idx_sex1);
    data2 = rat_means(idx_sex2);
    
    % Run ranksum test (Mann-Whitney U)
    [p2, ~, stats] = ranksum(data1, data2);
    
    % Format p-value string to avoid 0.0000 appearance
    if p2 < 1e-4
        p_str = sprintf('p < %.1e', 1e-4);
    else
        p_str = sprintf('p = %.4f', p2);
    end
    


end
% Print results
fprintf('Group %d Licks/RD: Comparing sexes "%s" vs "%s"\n', i, unique_sexes_list{1}, unique_sexes_list{2});
fprintf('  N=%d vs N=%d, median=%.3f vs %.3f, %s, rank sum statistic=%.1f\n\n', ...
    sum(idx_sex1), sum(idx_sex2), median(data1), median(data2), p_str, stats.ranksum);
t=t+6;
xlim([0.5, length(unique_sexes_list)+0.5])
xticks(1:length(unique_sexes_list))
xticklabels(unique_sexes_list)
ylim([0 100])
if i==1
    subtitle('Licks/RD','FontSize',15)
elseif i==3
    xlabel('Sex')
end
end
for i=1:length(globalnumbbouts)

[unique_rats, ia] = unique(all_rats{i}, 'stable');  % unique rats in order of appearance
rat_sexes = all_sexes{i}(ia);                       % sexes corresponding to unique rats

% --- Step 2: Align pernumbbouts{i} with unique_rats ---

% Assuming pernumbbouts{i} is a 1 x N cell array of numeric data per rat
% and the order matches unique_rats exactly.
% If not, you'll need to reorder pernumbbouts{i} to match unique_rats.

% Step 3: Calculate mean per rat across sessions

% Step 4: Get unique sexes and map to x-axis positions
unique_sexes_list = unique(rat_sexes);
x_positions = containers.Map(unique_sexes_list, 1:length(unique_sexes_list));

% --- Step 5: Plotting ---
subplot(3,6,u)
hold on;
rat_means = cellfun(@mean, pernumbbouts{i});
color=turbo(length(pernumbbouts{i}));
for s = 1:length(unique_sexes_list)
    sex = unique_sexes_list{s};
    idx = strcmp(rat_sexes, sex);   % logical index for rats of this sex
    
    % X base position for this sex group
    x_base = x_positions(sex);
    
    % Scatter plot of individual rat means for this sex
    scatter(x_base+0.3, rat_means(idx), 20, color(idx,:), 'MarkerFaceAlpha', 0.6)
    
    % Calculate and plot mean ± SEM for this sex group
    group_mean = mean(rat_means(idx));
    group_sem = std(rat_means(idx)) / sqrt(sum(idx));
      scatter(x_base,group_mean,'filled','k')
    errorbar(x_base, group_mean, group_sem, 'k', 'LineWidth', 2)
    idx_sex1 = strcmp(rat_sexes, unique_sexes_list{1});
    idx_sex2 = strcmp(rat_sexes, unique_sexes_list{2});
    
    data1 = rat_means(idx_sex1);
    data2 = rat_means(idx_sex2);
    
    % Run ranksum test (Mann-Whitney U)
    [p2, ~, stats] = ranksum(data1, data2);
    
    % Format p-value string to avoid 0.0000 appearance
    if p2 < 1e-4
        p_str = sprintf('p < %.1e', 1e-4);
    else
        p_str = sprintf('p = %.4f', p2);
    end
    


end
% Print results
fprintf('Group %d  Bouts/RD: Comparing sexes "%s" vs "%s"\n', i, unique_sexes_list{1}, unique_sexes_list{2});
fprintf('  N=%d vs N=%d, median=%.3f vs %.3f, %s, rank sum statistic=%.1f\n\n', ...
    sum(idx_sex1), sum(idx_sex2), median(data1), median(data2), p_str, stats.ranksum);
u=u+6;
xlim([0.5, length(unique_sexes_list)+0.5])
xticks(1:length(unique_sexes_list))
xticklabels(unique_sexes_list)
ylim([0 4])
if i==1
    subtitle('Bouts/RD','FontSize',15)
elseif i==3
    xlabel('Sex')
end
end

%% Driving pattern
tic
addpath('X:\Matilde\Ephys Data\Fall 2022 DT3\Sorted Units');

address=['X:\Matilde\Ephys Data\Fall 2022 DT3\Sorted Units'];

AF=dir([address,'\\*.xlsx']);
filenames={AF(:).name}.';
fulldata=struct('RatID',[],'Step',[],'DV',[],'Session',[],'TotalNeurons',[],'SPK1',[],'SPK2',[],'SPK3',[],'SPK4',[],'SPK5',[],'SPK6',[],'SPK7',[],'SPK8',[],'SPK9',[],...
    'SPK10',[],'SPK11',[],'SPK12',[],'SPK13',[],'SPK14',[],'SPK15',[],'SPK16',[]);
AF = AF(~ismember({AF.name},{'.','..','.xlsx'}));

for k=1:length(AF)
    CurrentFile=AF(k).name;
    dataeachrat=readtable(CurrentFile,'VariableNamingRule','preserve');
    currrat=table2cell(dataeachrat);
    Step=currrat(:,1);
    DV=currrat(:,2);
    Session=currrat(:,3);
    TotalNeurons=currrat(:,4);
    SPK1=currrat(:,5);
    SPK2=currrat(:,6);
    SPK3=currrat(:,7);
    SPK4=currrat(:,8);
    SPK5=currrat(:,9);
    SPK6=currrat(:,10);
    SPK7=currrat(:,11);
    SPK8=currrat(:,12);
    SPK9=currrat(:,13);
    SPK10=currrat(:,14);
    SPK11=currrat(:,15);
    SPK12=currrat(:,16);
    SPK13=currrat(:,17);
    SPK14=currrat(:,18);
    SPK15=currrat(:,19);
    SPK16=currrat(:,20);
    rat_name=char(CurrentFile);
    fulldata(k).RatID=rat_name;
    fulldata(k).Step=Step;
    fulldata(k).DV=DV;
    fulldata(k).Session=Session;
    fulldata(k).TotalNeurons=TotalNeurons;
    fulldata(k).SPK1=SPK1;
    fulldata(k).SPK2=SPK2;
    fulldata(k).SPK3=SPK3;
    fulldata(k).SPK4=SPK4;
    fulldata(k).SPK5=SPK5;
    fulldata(k).SPK6=SPK6;
    fulldata(k).SPK7=SPK7;
    fulldata(k).SPK8=SPK8;
    fulldata(k).SPK9=SPK9;
    fulldata(k).SPK10=SPK10;
    fulldata(k).SPK11=SPK11;
    fulldata(k).SPK12=SPK12;
    fulldata(k).SPK13=SPK13;
    fulldata(k).SPK14=SPK14;
    fulldata(k).SPK15=SPK15;
    fulldata(k).SPK16=SPK16;
end

plotmat=struct('FR21',[],'FR22',[],'FR23',[]);
plotmat.FR21=cell2mat([fulldata(1).SPK1,fulldata(1).SPK2,fulldata(1).SPK3,fulldata(1).SPK4,fulldata(1).SPK5,fulldata(1).SPK6,fulldata(1).SPK7,...
    fulldata(1).SPK8,fulldata(1).SPK9,fulldata(1).SPK10,fulldata(1).SPK11,fulldata(1).SPK12,fulldata(1).SPK13,fulldata(1).SPK14,fulldata(1).SPK15,fulldata(1).SPK16]);
plotmat.FR22=cell2mat([fulldata(2).SPK1,fulldata(2).SPK2,fulldata(2).SPK3,fulldata(2).SPK4,fulldata(2).SPK5,fulldata(2).SPK6,fulldata(2).SPK7,...
    fulldata(2).SPK8,fulldata(2).SPK9,fulldata(2).SPK10,fulldata(2).SPK11,fulldata(2).SPK12,fulldata(2).SPK13,fulldata(2).SPK14,fulldata(2).SPK15,fulldata(2).SPK16]);
plotmat.FR23=cell2mat([fulldata(3).SPK1,fulldata(3).SPK2,fulldata(3).SPK3,fulldata(3).SPK4,fulldata(3).SPK5,fulldata(3).SPK6,fulldata(3).SPK7,...
    fulldata(3).SPK8,fulldata(3).SPK9,fulldata(3).SPK10,fulldata(3).SPK11,fulldata(3).SPK12,fulldata(3).SPK13,fulldata(3).SPK14,fulldata(3).SPK15,fulldata(3).SPK16]);


figure;
x=1;
Ratlist=fieldnames(plotmat);
for j=1:numel(Ratlist)
    plotrat=getfield(plotmat,Ratlist{j});
    subplot_tight(3,2,x,[0.075 0.20]);
    imagesc(corrcoef((plotrat)'));
    %     hold on
    %     for k=1:length(Step)
    %         xline(cell2mat(Step(k))+0.5,"r","LineWidth",5);
    %     end
    %     for  k=1:length(Session)
    %         xline(cell2mat(Session(k))+0.5,"g","LineWidth",2);
    %     end
    xlabel('Session');
    ylabel('Session');
    title(['Animal ID:' Ratlist{j}]);
    x=x+1;
end
toc
%% Baseline firing rate information
inh=[0.1 0.021154 0.6];
exc=[0.9 0.75 0.205816];
figure;
subplot(3,3,2);
histogram(R.Bmean,50);
title('Average Baseline Firing Rate (all trials)','FontSize',15);
xlabel('Frequency (Hz)','FontSize',12);
ylabel('# of Neurons','FontSize',12);
xline(mean(R.Bmean), 'LineWidth',3,'color','r');
xline(median(R.Bmean), 'LineWidth',3,'color','b');
ack=gca;
ack.FontSize=16; %how can i clean this up to not interfere later
text(10,3,sprintf('Mean = %g Hz// Median = %g Hz',(round(mean(R.Bmean),2)),(round(median(R.Bmean),2))),"FontSize",10);
subplot(3,3,4);
histogram(R.Bmeanhm,50);
title('Average Baseline Firing Rate','FontSize',15);
subtitle('(high motivation trials)');
xlabel('Frequency (Hz)','FontSize',12);
ylabel('# of Neurons','FontSize',12);
xline(mean(R.Bmeanhm), 'LineWidth',3,'color','r');
xline(median(R.Bmeanhm), 'LineWidth',3,'color','b');
text(15,10,sprintf('Mean = %g Hz // Median = %g Hz',(round(mean(R.Bmeanhm),2)),(round(median(R.Bmeanhm),2))),'FontSize',10);
subplot(3,3,5);
histogram(R.Bmeanlm,50);
title('Average Baseline Firing Rate','FontSize',15);
subtitle('(low motivation trials)');
xlabel('Frequency (Hz)','FontSize',12);
ylabel('# of Neurons','FontSize',12);
xline(mean(R.Bmeanlm), 'LineWidth',3,'color','r');
xline(median(R.Bmeanlm), 'LineWidth',3,'color','b');
text(15,10,sprintf('Mean = %g Hz // Median = %g Hz',(round(mean(R.Bmeanlm),2)),(round(median(R.Bmeanlm),2))),'FontSize',10);
subplot(3,4,6);
histogram(R.Bmeanmm,50);
title('Average Baseline Firing Rate','FontSize',15);
subtitle('(mixed motivation trials)');
xlabel('Frequency (Hz)','FontSize',12);
ylabel('# of Neurons','FontSize',12);
xline(mean(R.Bmeanmm), 'LineWidth',3,'color','r');
xline(median(R.Bmeanmm), 'LineWidth',3,'color','b');
text(15,10,sprintf('Mean = %g Hz // Median = %g Hz',(round(mean(R.Bmeanmm),2)),(round(median(R.Bmeanmm),2))),'FontSize',10);
subplot(3,3,8);
histogram(R.Bmeannm,50);
title('Average Baseline Firing Rate','FontSize',15);
subtitle('(omitted trials)');
xlabel('Frequency (Hz)','FontSize',12);
ylabel('# of Neurons','FontSize',12);
xline(mean(R.Bmeannm), 'LineWidth',3,'color','r');
xline(median(R.Bmeannm), 'LineWidth',3,'color','b');
text(15,10,sprintf('Mean = %g Hz // Median = %g Hz',(round(mean(R.Bmeannm),2)),(round(median(R.Bmeannm),2))),'FontSize',10);
figure;
plot(1:size(R.FiringRate,2),R.FiringRate);
xlim([1 50])
title('All Neuron Firing Rate')
ylabel('Frequency (Hz)')
xlabel('Trial')
figure;
hold on
for ses=1:length(RAW)
    maxtrials=[];
    rewardslogical=[];
    rewardscumulative=[];
    omissionslogical=[];
    omissionscumulative=[];
    maxtrials=length(RAW(ses).Erast{11});
    rewardslogical=~isnan(RAW(ses).Erast{38})';
    rewardscumulative=cumsum(rewardslogical);
    omissionslogical=isnan(RAW(ses).Erast{38})';
    omissionscumulative=cumsum(omissionslogical);
    for n=2:11
        rewardsnormalized(ses,n)=rewardscumulative(:,round(maxtrials*0.1*(n-1)));
        omissionsnormalized(ses,n)=omissionscumulative(:,round(maxtrials*0.1*(n-1)));
    end
    rewardsfraction(ses,:)=rewardsnormalized(ses,:)./rewardscumulative(:,end);
    omissionsfraction(ses,:)=omissionsnormalized(ses,:)./omissionscumulative(:,end);
end
semean= nanste(R.FiringRatenormalized,1);
rsemean = sem(rewardsfraction);
osemean = sem(omissionsfraction);
yyaxis right
grep=plot(1:size(rewardsfraction,2),mean(rewardsfraction),'-g','LineWidth',5);
plot(1:size(rewardsfraction,2),mean(rewardsfraction,'omitnan')+rsemean,'-g','LineWidth',2);
plot(1:size(rewardsfraction,2),mean(rewardsfraction,'omitnan')-rsemean,'-g','LineWidth',2);
ylabel('Fraction of total rewards acquired')
ylim([0 1]);
grap=plot(1:size(omissionsfraction,2),mean(omissionsfraction),'-','Color',[0.7 0.7 0.7],'LineWidth',5);
A=gcf;
A.CurrentAxes.YColor='k';
plot(1:size(omissionsfraction,2),mean(omissionsfraction,'omitnan')+osemean,'-','Color',[0.7 0.7 0.7],'LineWidth',2);
plot(1:size(omissionsfraction,2),mean(omissionsfraction,'omitnan')-osemean,'-','Color',[0.7 0.7 0.7],'LineWidth',2);
yyaxis left
rp=plot(1:size(R.FiringRatenormalized,2),mean(R.FiringRatenormalized,'omitnan'),'-r','LineWidth',5);
B=gcf;
B.CurrentAxes.YColor='k';
plot(1:size(R.FiringRatenormalized,2),mean(R.FiringRatenormalized,'omitnan')+semean,'-r','LineWidth',2);
plot(1:size(R.FiringRatenormalized,2),mean(R.FiringRatenormalized,'omitnan')-semean,'-r','LineWidth',2);
ylabel('Frequency (Hz)')
legend({'Mean','','','Cumulative Rewards','','','Cumulative Omissions'},'Location','northwest')
title('Neuron Firing Rate Across Trials (normalized)')
xlabel('% Total Trials')
xticks(1:11)
xlim([1 11])
xticklabels({'0%','10%','20%','30%','40%','50%','60%','70%','80%','90%','100%'})
figure;
dataarray= {R.FiringRate};
plotingdataarray={R.FiringRatenormalized};
titlesarray={'Baseline Firing Rate (all trials)'};
for m=1:length(dataarray)
    subplot(1,length(plotingdataarray),m)
    dataused=cell2mat(dataarray(m));
    lmstats.slope=[];
    lmstats.slopeSE=[];
    lmstats.slopepVal=[];
    lmstats.int=[];
    lmstats.intSE=[];
    lmstats.intpVal=[];
    for j=1:length(dataused)
        lasttrial=(find(isnan(dataused(j,:)),1))-1;
        if ~isempty(lasttrial)
            time=1:lasttrial;
        else
            lasttrial=49;
            time=1:49;
        end
        timearray=time';
        lm=fitlm(timearray,dataused(j,1:lasttrial));
        lmstats.slope(j)=table2array(lm.Coefficients(2,1));
        lmstats.slopeSE(j)=table2array(lm.Coefficients(2,2));
        lmstats.slopepVal(j)=table2array(lm.Coefficients(2,4));
        lmstats.int(j)=table2array(lm.Coefficients(1,1));
        lmstats.intSE(j)=table2array(lm.Coefficients(1,2));
        lmstats.intpVal(j)=table2array(lm.Coefficients(1,4));
        clear("lasttrial","time","timearray")
    end
    plottingdataused = cell2mat(plotingdataarray(m)); %all = R.FiringRate, low motive = R.FiringRate(R.Ev(1).NumberTrials==49,:)
    inh=[0.1 0.021154 0.6];
    exc=[0.9 0.75 0.205816];
    plottime=1:size(plottingdataused,2);
    posdelta=lmstats.slope>0 & lmstats.slopepVal<0.05;
    posFR=plottingdataused(posdelta,:);
    possem=nanste(posFR,1);
    posup=mean(posFR,'omitnan')+possem;
    posdown=mean(posFR,'omitnan')-possem;
    nodelta=lmstats.slopepVal>=0.05;
    noFR=plottingdataused(nodelta,:);
    nosem=nanste(noFR,1);
    noup=mean(noFR,'omitnan')+nosem;
    nodown=mean(noFR, 'omitnan')-nosem;
    negdelta=lmstats.slope<0 & lmstats.slopepVal<0.05;
    negFR=plottingdataused(negdelta,:);
    negsem=nanste(negFR,1);
    negup=mean(negFR, 'omitnan')+negsem;
    negdown=mean(negFR,'omitnan')-negsem;
    hold on
    xlim([size(plottime)])
    plot(plottime,mean(noFR,'omitnan'),'Color',[0.7 0.7 0.7],"LineWidth",1.5);
    plot(plottime,mean(negFR,'omitnan'),'Color',inh,"LineWidth",1.5);
    plot(plottime,mean(posFR,'omitnan'),'Color',exc,"LineWidth",1.5);
    label2 = '$No {\Delta}$';
    label3 = '$- {\Delta}$';
    label4 = '$+ {\Delta}$';
    legend(label2,label3,label4,'Interpreter','latex','Location','southeast','FontSize', 20);
    ylabel('Frequency (Hz)','FontSize', 15);
    xlabel('% Total Trials','FontSize', 15);
    xticks(1:11)
    xlim([1 11])
    xticklabels({'0%','10%','20%','30%','40%','50%','60%','70%','80%','90%','100%'})
    title(titlesarray(m),'FontSize', 25);
    p4= patch([plottime,plottime(end:-1:1)],[noup,nodown(end:-1:1)],[.7 .7 .7],'EdgeColor','none');alpha(0.5);
    p2= patch([plottime,plottime(end:-1:1)],[negup,negdown(end:-1:1)],inh,'EdgeColor','none');alpha(0.5);
    p3= patch([plottime,plottime(end:-1:1)],[posup,posdown(end:-1:1)],exc,'EdgeColor','none');alpha(0.5);
    p1.Annotation.LegendInformation.IconDisplayStyle = 'off';
    p2.Annotation.LegendInformation.IconDisplayStyle = 'off';
    p3.Annotation.LegendInformation.IconDisplayStyle = 'off';
    p4.Annotation.LegendInformation.IconDisplayStyle = 'off';
    text(3,3.55,sprintf('%0.3g%% %s',(round(numel(find(nodelta==1))./length(dataused).*100,2)),'total neurons'),'Color',[.4 .4 .4],'FontSize', 15);
    text(3,4.5,sprintf('%0.4g%% %s',(round(numel(find(negdelta==1))./length(dataused).*100,2)),'total neurons'),'Color',inh,'FontSize', 15);
    text(3,2.25,sprintf('%0.4g%% %s',(round(numel(find(posdelta==1))./length(dataused).*100,2)),'total neurons'),'Color',exc,'FontSize', 15);
end
Nsessions=length(RAW);
Nneurons=length(R.Ninfo);
NeurNum=1;
Blineoverall=NaN(length(R.FiringRate),2);
for i=1:length(RAW)
    if strcmp('NOT',RAW(i).Type(1:3)) && length(RAW(i).Erast{30})>=14
        LI=strmatch('LeverInsertion',RAW(i).Einfo(:,2),'exact'); %find LI in RAW.mat
        LItimes=RAW(i).Erast{LI}; %extract LI timestamps
        RD=strmatch('RewardDeliv',RAW(i).Einfo(:,2),'exact'); %find RD in RAW.mat
        RDtimes=RAW(i).Erast{RD}; %extract RD timestamps
        %make active trials time stamp array.
        n1=length(RAW(i).Erast{RD}); %num RD, RD raster --> n1x1 array
        n2=length(RAW(i).Erast{LI}); %num LI, LI raster --> n2X1 array
        LIbased_RDtrials=zeros(n2,5); %3rd column=engaged array, 4th column= 0/1 for high motive trials (RD trials + 5 unRD trials after last RD), 5th= 0/1 for low motive trials
        lasthighmotivetrials=zeros(Nsessions,1);
        RDtrial=1; %RD trial counter (for for loop)
        for t=1:n2 %for trials= 1 to number of LIs
            LIbased_RDtrials(t,1)=LItimes(t); %make LI timestamp array in comparison matrix
            if t<n2 %for all trials before the last one
                x=find(RDtimes>LItimes(t) & RDtimes<LItimes(t+1));
                if ~isempty(x)
                    LIbased_RDtrials(t,2)=RDtimes(RDtrial);
                    RDtrial=RDtrial+1;
                    if ~isempty (LItimes(1)) && (RDtimes(1))
                        LIbased_RDtrials(t,3)=1;
                    elseif ~isempty(LItimes(t)) && ~isempty(RDtimes(RDtrial))
                        LIbased_RDtrials(t,3)=1;
                    elseif ~isempty(LItimes(t)) && isempty(RDtimes(RDtrial))
                        LIbased_RDtrials(t,3)=0;
                    end
                else
                    LIbased_RDtrials(t,2)=NaN;
                end
            else %if last trial
                x=find(RDtimes>LItimes(t));
                if ~isempty(x)
                    LIbased_RDtrials(t,2)=RDtimes(RDtrial);
                    RDtrial=RDtrial+1;
                    if ~isempty (LItimes(1)) && (RDtimes(1))
                        LIbased_RDtrials(t,3)=1;
                    elseif ~isempty(LItimes(t)) && ~isempty(RDtimes(RDtrial))
                        LIbased_RDtrials(t,3)=1;
                    end
                else
                    LIbased_RDtrials(t,2)=NaN;
                end
            end
            if t==1
                LIbased_RDtrials(t,4)=1;
                LIbased_RDtrials(t,5)=0;
            elseif ~isnan(LIbased_RDtrials(t,2))
                LIbased_RDtrials(t,4)=2;
                LIbased_RDtrials(t,5)=0;
            elseif t>=2 && ~isnan(LIbased_RDtrials(t-1,2)) || t-1==1
                LIbased_RDtrials(t,4)=3;
                LIbased_RDtrials(t,5)=0;
            elseif t>=4 && ~isnan(LIbased_RDtrials(t-2,2))|| t-2==1
                LIbased_RDtrials(t,4)=4;
                LIbased_RDtrials(t,5)=0;
            elseif t>=5 && ~isnan(LIbased_RDtrials(t-3,2))|| t-3==1
                LIbased_RDtrials(t,4)=5;
                LIbased_RDtrials(t,5)=0;
            elseif t>=6 && ~isnan(LIbased_RDtrials(t-4,2))|| t-4==1
                LIbased_RDtrials(t,4)=6;
                LIbased_RDtrials(t,5)=0;
            elseif t>=7 && ~isnan(LIbased_RDtrials(t-5,2))|| t-5==1
                LIbased_RDtrials(t,4)=7;
                LIbased_RDtrials(t,5)=0;
            else
                LIbased_RDtrials(t,4)=0;
                LIbased_RDtrials(t,5)=1;
            end
        end
        for j=1:Nneurons
            Blinesession(j,1)=mean(R.FiringRate(j,LIbased_RDtrials(:,3)==1),'omitnan');
            Blinesession(j,2)=mean(R.FiringRate(j,LIbased_RDtrials(:,3)==0),'omitnan');
        end
    end
end
Blinerewarded=Blinesession(:,1);
Blineomitted=Blinesession(:,2);
avgposRD=mean(Blinerewarded(posdelta,:),1,'omitnan');
posRDsemAVG=mean(Blinerewarded(posdelta,:),2,'omitnan');
RDpossem=std(posRDsemAVG,'omitnan')/sqrt(length(posRDsemAVG));
RDposup=avgposRD+RDpossem;
RDposdown=avgposRD-RDpossem;
avgposOM=mean(Blineomitted(posdelta,:),1,'omitnan');
posOMsemAVG=mean(Blineomitted(posdelta,:),2,'omitnan');
OMpossem=std(posOMsemAVG,'omitnan')/sqrt(length(posOMsemAVG));
OMposup=avgposOM+OMpossem;
OMposdown=avgposOM-OMpossem;
avgnegRD=mean(Blinerewarded(negdelta,:),1,'omitnan');
negRDsemAVG=mean(Blinerewarded(negdelta,:),2,'omitnan');
RDnegsem=std(negRDsemAVG,'omitnan')/sqrt(length(negRDsemAVG));
RDnegup=avgnegRD+RDnegsem;
RDnegdown=avgnegRD-RDnegsem;
avgnegOM=mean(Blineomitted(negdelta,:),1,'omitnan');
negOMsemAVG=mean(Blineomitted(negdelta,:),2,'omitnan');
OMnegsem=std(negOMsemAVG,'omitnan')/sqrt(length(negOMsemAVG));
OMnegup=avgnegOM+OMnegsem;
OMnegdown=avgnegOM-OMnegsem;
avgnoRD=mean(Blinerewarded(nodelta,:),1,'omitnan');
noRDsemAVG=mean(Blinerewarded(nodelta,:),2,'omitnan');
RDnosem=std(noRDsemAVG,'omitnan')/sqrt(length(noRDsemAVG));
RDnoup=avgnoRD+RDnosem;
RDnodown=avgnoRD-RDnosem;
avgnoOM=mean(Blineomitted(nodelta,:),1,'omitnan');
noOMsemAVG=mean(Blineomitted(nodelta,:),2,'omitnan');
OMnosem=std(noOMsemAVG,'omitnan')/sqrt(length(noOMsemAVG));
OMnoup=avgnoOM+OMnosem;
OMnodown=avgnoOM-OMnosem;
avgs=[avgnoRD avgposRD avgnegRD; avgnoOM avgposOM avgnegOM];
error=[RDnosem RDpossem RDnegsem; OMnosem OMpossem OMnegsem];
axes('Position', [0.74265306122449,0.637302725968437,0.1,0.28]);
box on
err=errorbar(avgs, error);
err(2).Color=[0.9, 0.75, 0.205816];
err(2).LineStyle='-';
err(2).Marker='^';
err(2).MarkerFaceColor=[0.9, 0.75, 0.205816];
err(3).Color=[0.1, 0.021154, 0.6];
err(3).LineStyle='-';
err(3).Marker='v';
err(3).MarkerFaceColor=[0.1, 0.021154, 0.6];
err(1).Color=[0.7, 0.7, 0.7];
err(1).LineStyle='-';
err(1).Marker='o';
err(1).MarkerFaceColor=[0.7 0.7 0.7];
xlim([0.5 2.5])
ylim([2 7])
title('Average FR for rewarded vs. omitted trials')
ylabel('Average Frequency (Hz)')
xlabel('Behavioral State')
xticklabels({'Rewarded Trials','Omitted Trials' });
ax=gca;
ax.XAxis.FontSize=6;
ax.YAxis.FontSize=6;
ax.XLabel.FontSize=8;
ax.YLabel.FontSize=8;