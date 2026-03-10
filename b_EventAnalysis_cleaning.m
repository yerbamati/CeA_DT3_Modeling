%% initial analysis of event-evoked activity

%need to save excel sheets in the specified folder
%the excel sheets say which events to make PSTHs for and what windows to
%use for statistical testing

clearvars; clc;
global Dura Baseline Tm Tbase BSIZE Tbin
 tic

RAWinuse= uigetfile('RAW*.mat','X:\Matilde\MatLab');
sessionstring= 'NOT';
if ~exist('RAW'), load (RAWinuse); end

addpath(genpath('\\pbs-srv2.win.ad.jhu.edu\JanakLabTest\Matilde\MatLab\Supporting Programs'));

%Main settings
SAVE_FLAG=1;
BSIZE=0.01; %Do not change
Dura=[-5 5]; Tm=Dura(1):BSIZE:Dura(2);
%Baseline=[-22 0]; Tbase=Baseline(1):BSIZE:Baseline(2); %now defined line 98
Tbin=-0.5:0.005:0.5; %window used to determine the optimal binsize
PStat=0.05; %for comparing pre versus post windows, or event A versus event B
MinNumTrials=5; %how many trials of event there need to be to conduct analysis
BinSize=0.05;
Baseline=[-15 -5]; %relative to LI, used for z-score and ev resp tests, changed from -15 - -6 to current settings 11/22/2024

%Smoothing PSTHs
%smoothing filter for whole PSTH
PSTHsmoothbins=25; %number of previous bins used to smooth
halfnormal=makedist('HalfNormal','mu',0,'sigma',8); %used to be 6.6
PSTHfilterweights=pdf(halfnormal,0:PSTHsmoothbins);

%smoothing filter for individual trials
trialsmoothbins=10; %number of previous bins used to smooth
halfnormal=makedist('HalfNormal','mu',0,'sigma',3); %std=3.98
trialfilterweights=pdf(halfnormal,0:trialsmoothbins);


%smoothing filter for licking PSTH
licksmoothbins=50; %number of previous bins used to smooth
halfnormal=makedist('HalfNormal','mu',0,'sigma',25); %std=3.98
lickfilterweights=pdf(halfnormal,0:licksmoothbins);

%for bins analysis
BinBase=[-22 -12]; %For normalizing activity
BinDura=[0 0.6]; %size of bin
bins = 66; %number of bins
binint = 0.1; %spacing of bins
binstart = -2; %start time of first bin relative to event

%%  Standard sessions

%start fresh
R=[];R.Ninfo={};NN=0;Nneurons=0;

% List of events to analyze and analysis windows EXTRACTED from excel file
[file,loc]=uigetfile('*.xls','X:\Matilde\MatLab');
path=strcat(loc,file);
if contains(path(28:end),'-')
    windowofanalysis=strcat('-',char(extract(path(28:end), digitsPattern)));
else
    match = regexp(path, '([a-zA-Z0-9]*s[a-zA-Z0-9]*)\.xls$', 'tokens');
    windowofanalysis=match{1}{1};
end
windowofanalysis=([windowofanalysis 'postwin']);
if contains(RAWinuse,'SuperApple')
    [~,Erefnames]=xlsread(path,'Windows','a3:a26'); % cell that contains the event names
prewin =  xlsread(path,'Windows','b3:c26');
postwin = xlsread(path,'Windows','d3:e26');
cellcomp={'LeverPress','PEntry','PEntrynoRD','PEntryminusRD','PEITI','Licks','FirstInBout', 'PEntryRDtrial','PEntryNoRDtrial','PEntryNoRDtrial1'};
eventNames={'LeverInsertionNoRD';'LeverInsertionRD';'LeverPress';'LeverPress1';'LeverPress2';'EndPress';'LeverRetract';'LeverRetractRD';'LeverRetractNoRD';...
            'PEntry';'PEITI';'PEntryRD';'PEntrynoRD';'PEntryminusRD';'PEntryNoRDtrial';'PEntryRDtrial';'PEntryNoRDtrial1';'RewardDeliv';'Licks';'LickRD';'FirstInBout';'EndofRD';'Licklast'};
else
[~,Erefnames]=xlsread(path,'Windows','a3:a28'); % cell that contains the event names
prewin =  xlsread(path,'Windows','b3:c28');
postwin = xlsread(path,'Windows','d3:e28');
cellcomp={'LeverApproachRD','PortApproachRD','LeverPress','PEntry','PEntrynoRD','PEntryminusRD','PEITI','Licks','FirstInBout', 'PEntryRDtrial','PEntryNoRDtrial','PEntryNoRDtrial1'};
eventNames={'LeverInsertionNoRD';'LeverInsertionRD';'LeverApproachRD';'PortApproachRD';'LeverPress';'LeverPress1';'LeverPress2';'EndPress';'LeverRetract';'LeverRetractRD';'LeverRetractNoRD';...
            'PEntry';'PEITI';'PEntryRD';'PEntrynoRD';'PEntryminusRD';'PEntryNoRDtrial';'PEntryRDtrial';'PEntryNoRDtrial1';'RewardDeliv';'Licks';'LickRD';'FirstInBout';'EndofRD';'Licklast'};
end

%saves event names for reference later
R.Erefnames=Erefnames;

%event indexes of interest
LI=strcmp('LeverInsertion',RAW(1).Einfo(:,2)); %find LI in RAW
LP=strcmp('LeverPress',RAW(1).Einfo(:,2));
LP1=strcmp('LeverPress1',RAW(1).Einfo(:,2));
LP2=strcmp('LeverPress2',RAW(1).Einfo(:,2));
EP=strcmp('EndPress',RAW(1).Einfo(:,2));
LR=strcmp('LeverRetract',RAW(1).Einfo(:,2));
PERD=strcmp('PEntryRD',RAW(1).Einfo(:,2));
RD=strcmp('RewardDeliv',RAW(1).Einfo(:,2));
Licks=strcmp('Licks',RAW(1).Einfo(:,2));
LickRD=strcmp('LickRD',RAW(1).Einfo(:,2));
EndofRD=strcmp('EndofRD',RAW(1).Einfo(:,2));
trialtype=strcmp('Trial Type',RAW(1).Einfo(:,2));
 if contains(RAWinuse,'SuperJazz') || contains(RAWinuse,'Melon') || contains(RAWinuse,'Grape')
     positionidx=strcmp('SessionInstvelocity(Model)',RAW(1).Einfo(:,2));
 end





%Finds the total number of neurons in 2R and marks them by region/session
R.Subject={};
Nsessions=length(RAW);
for i=1:Nsessions
    if  strcmp(sessionstring,RAW(i).Type(1:3)) && length(RAW(i).Erast{RD})>=10 %| strcmp('VP',RAW(i).Type(1:2))
        R.Ninfo=cat(1,R.Ninfo,RAW(i).Ninfo);
        Nneurons=Nneurons+size(RAW(i).Nrast,1);
        if contains(RAWinuse,{'SuperApple','SuperJazz'})
            R.Subject=cat(1,R.Subject,[repelem({RAW(i).Subject},size(RAW(i).Nrast,1),1),repelem({RAW(i).Sex},size(RAW(i).Nrast,1),1),repelem({RAW(i).Doseage},size(RAW(i).Nrast,1),1)]);
            trialmax=50;
        else
            R.Subject=cat(1,R.Subject,[repelem({RAW(i).Subject},size(RAW(i).Nrast,1),1),repelem({RAW(i).Sex},size(RAW(i).Nrast,1),1)]);
            trialmax=100;
        end
    end
end
for i=1:Nneurons
    Session=string(R.Ninfo(i,1));
    Name=char(Session);
    R.Ninfo(i,3)=cellstr(Name(1:3));
    R.Ninfo(i,4)=cellstr(Name(end-6:end-4));
end
% preallocating
R.Param.Tm=Tm;
R.Param.Tbin=Tbin;
R.Param.Dura=Dura;
R.Param.Baseline=Baseline;
R.Param.PStat=PStat;
R.Param.MinNumTrials=MinNumTrials;
R.Param.path=path;
R.Param.prewin=prewin;
R.Param.postwin=postwin;
R.Param.SmoothTYPE='Causal Filter';
% R_2R.Param.SmoothSPAN=SmoothSPAN;
R.Param.BinBase=BinBase;
R.Param.BinDura=BinDura;
R.Param.bins = bins;
R.Param.binint = binint;
R.Param.binstart = binstart;

for k=1:length(Erefnames)
    R.Ev(k).PSTHraw(1:Nneurons,1:length(Tm))=NaN(Nneurons,length(Tm));
    R.Ev(k).PSTHz(1:Nneurons,1:length(Tm))=NaN(Nneurons,length(Tm));
    R.Ev(k).Meanraw(1:Nneurons,1)=NaN;
    R.Ev(k).Meanz(1:Nneurons,1)=NaN;
    %R.Ev(k).BW(1:Nneurons,1)=NaN;
    R.Ev(k).signrank(1:Nneurons,1)=NaN;
    R.Ev(k).RespDir(1:Nneurons,1)=NaN;
    R.Ev(k).NumberTrials(1:Nneurons,1)=NaN;
end
R.TrialbyTrialLIactivity=NaN(Nneurons,trialmax);
R.TrialbyTrialLP1activity=NaN(Nneurons,trialmax);
R.TrialbyTrialLP2activity=NaN(Nneurons,trialmax);
R.TrialbyTrialEPactivity=NaN(Nneurons,trialmax);
R.TrialbyTrialPERDactivity=NaN(Nneurons,trialmax);
R.cumrd=NaN(Nneurons,trialmax);
if contains(RAWinuse,'SuperJazz') || contains(RAWinuse,'Melon') || contains(RAWinuse,'Grape')
R.TrialITIInstVel=NaN(Nneurons,trialmax);
end
R.TrialType=cell(Nneurons,trialmax);
R.FiringRate=NaN(Nneurons,trialmax);
R.FiringRatenormalized=NaN(Nneurons,11);
R.MaxTrials=NaN(Nneurons,1);
R.Bmean=NaN(Nneurons,1);
R.Bstd=NaN(Nneurons,1);
R.FiringRateom=NaN(Nneurons,trialmax);
R.Bmeanom=NaN(Nneurons,1);
R.Bstdom=NaN(Nneurons,1);
R.FiringRaterd=NaN(Nneurons,trialmax);
R.Bmeanrd=NaN(Nneurons,1);
R.Bstdrd=NaN(Nneurons,1);
R.FiringRatelm=NaN(Nneurons,trialmax);
R.Bmeanlm=NaN(Nneurons,1);
R.Bstdlm=NaN(Nneurons,1);
R.FiringRatehm=NaN(Nneurons,trialmax);
R.Bmeanhm=NaN(Nneurons,1);
R.Bstdhm=NaN(Nneurons,1);
question1=questdlg('Which pre-event window?','Pre-event window','-250ms before','Baseline FR','Baseline FR');
% question2=questdlg('Scored or Raw Data?','LORS','Score','Raw','Raw');
% if strcmp(question2,'Raw')
%     lors=1;
% elseif strcmp(question2,'Score')
%     lors=2;
% end
if strcmp(question1,'-250ms before')
    prewindowflag=1;
elseif strcmp(question1,'Baseline FR')
    prewindowflag=0;
end
%question2=questdlg('Which behavioral metric?','Behavioral metric','Latency (Raw)','Time2Complete (Raw)','Score of LP1 Lat + T2C','Latency (Raw)');

RD_time_rel_PERD_nojitter=[];
RD_time_rel_PERD_jitter=[];
for i=1:Nsessions %loops through session
    if strcmp(sessionstring,RAW(i).Type(1:3)) && length(RAW(i).Erast{RD})>=10 % && strcmp(| strcmp('VP',RAW(i).Type(1:2))
        %make table with all information.
        %updated: 12.13.2024
        RD_time_rel_PERD_currses=[];
        trialTbl=table();
        LI=strcmp('LeverInsertion',RAW(i).Einfo(:,2));
        LItimes=RAW(i).Erast{LI};
        LR=strcmp('LeverRetract',RAW(i).Einfo(:,2));
        LRtimes=RAW(i).Erast{LR};
        trialTbl.trialNo=[1:length(LItimes)]';
        %trialTbl.trialType=RAW(i).Erast{end};
        trialTbl.LeverInsertion=LItimes;
          for evt=1:length(eventNames)
            evInd=strcmp(eventNames(evt),RAW(i).Einfo(:,2)); %find LP1 in RAW.mat
            evTimes=RAW(i).Erast{evInd};
            if ismember(eventNames{evt},cellcomp)
                trialTbl.(eventNames{evt})=cell(length(LItimes),1);
            else
                trialTbl.(eventNames{evt})=NaN(length(LItimes),1);
            end
            for trl=1:length(LItimes)
                startTime=LItimes(trl)-15;
                endTime=LRtimes(trl)+12; % for port entry... should this be pre or post LI/LR?
                if ismember(eventNames{evt},cellcomp)
                    if sum(evTimes>=startTime & evTimes<endTime)==0
                        trialTbl.(eventNames{evt})(trl)={NaN};
                    else
                        trialTbl.(eventNames{evt})(trl)={evTimes(evTimes>=startTime & evTimes<endTime)};
                        if isequal(eventNames{evt},'LeverPress') & size(trialTbl.(eventNames{evt}){trl,end},1)>=3
                            trialTbl.(eventNames{evt}){trl}(end)=[];
                        end
                    end
                else
                    if sum(evTimes>=startTime & evTimes<endTime)==1
                        trialTbl.(eventNames{evt})(trl)=evTimes(evTimes>=startTime & evTimes<endTime);
                    elseif sum(evTimes>=startTime & evTimes<endTime)==2
                        quindex=evTimes(evTimes>startTime & evTimes<endTime);
                        trialTbl.(eventNames{evt})(trl-1)=quindex(1,:);
                        trialTbl.(eventNames{evt})(trl)=quindex(2,:);
                    end
                end
            end
        end

        maxtrials=length(RAW(i).Erast{4});
        for j= 1:size(RAW(i).Nrast,1) %Number of neurons per session
            NN=NN+1; %neuron counter
            col2use=1;
            rdtrials=~strcmp('omission',RAW(i).Erast{trialtype,1}(:,col2use));
            highmotivetrials=strncmp(RAW(i).Erast{trialtype,1}(:,col2use),'high',4);
            nomotivetrials=strcmp('omission',RAW(i).Erast{trialtype,1}(:,col2use));
            lowmotivetrials=strncmp(RAW(i).Erast{trialtype,1}(:,col2use),'low',4);
            %get mean baseline firing for all trials
            LI=strcmp('LeverInsertion',RAW(i).Einfo(:,2)); %
            LItimes=RAW(i).Erast{LI};
            [Bcell1,B1n]=MakePSR04(RAW(i).Nrast(j),RAW(i).Erast{LI},Baseline,{2});% makes trial by trial rasters for baseline
            basespk=NaN(1,B1n);
            for y= 1:B1n
                basespk(1,y)=sum(Bcell1{1,y}>Baseline(1));
            end
            FiringRate=basespk/(Baseline(1,2)-Baseline(1,1));
            Bmean=nanmean(FiringRate);
            Bstd=nanstd(FiringRate);
            if contains(RAWinuse,'SuperJazz') || contains(RAWinuse,'Melon') || contains(RAWinuse,'Grape')
                position= RAW(i).Erast{positionidx,1};
                timestamps=RAW(i).Erast{positionidx,2};
                ITIvideowindow=round(floor((LItimes+Baseline) / 0.025) * 0.025,4);
                startidx=round((ITIvideowindow(:,1)-RAW(i).Erast{positionidx,2}(1))/0.025)+1;
                endidx=round((ITIvideowindow(:,2)-RAW(i).Erast{positionidx,2}(1))/0.025)+1;
                scaledvel=normalize(RAW(i).Erast{positionidx,1},1,'range');
                R.TrialITIInstVel(NN,1:length(endidx))=arrayfun(@(x,y) mean(scaledvel(x:y)),startidx,endidx)';
            end
            % if Bmean<1
            %     pause
            % end
            R.TrialType(NN,1:length(RAW(i).Erast{trialtype,1}))=RAW(i).Erast{trialtype,1};
            %store baseline mean and std firing rate used for z score
            R.FiringRate(NN,1:length(FiringRate))=FiringRate;
            R.FiringRatenormalized(:,1)=R.FiringRate(:,1);
            R.MaxTrials(NN,1)=maxtrials;
            R.cumrd(NN,1:length(FiringRate))=cumsum(~isnan(trialTbl.RewardDeliv));
            for n=2:11
                R.FiringRatenormalized(NN,n)=R.FiringRate(NN,round(maxtrials*0.1*(n-1)));
            end
            R.Bmean(NN,1)=Bmean;
            R.Bstd(NN,1)=Bstd;

            %get mean baseline firing for high motivation trials
            %do not need to pointlessly repeat MakePSR04 since already have
            %trial by trial data from above
            % [Bhighcell,Bhighn]=MakePSR04(RAW(i).Nrast(j),trialTbl.LeverInsertion(highmotivetrials),Baseline,{2});% makes trial by trial rasters for baseline
            % basespkhigh=NaN(1,Bhighn);
            % for y= 1:Bhighn
            %     basespkhigh(1,y)=sum(Bhighcell{1,y}>Baseline(1));
            % end
            FiringRatehm=R.FiringRate(NN,highmotivetrials');
            Bmeanhm=mean(FiringRatehm,'omitnan');
            Bstdhm=nanstd(FiringRatehm);

            %store baseline mean and std firing rate used for z score
            R.FiringRatehm(NN,1:length(FiringRatehm))=FiringRatehm;
            R.Bmeanhm(NN,1)=Bmeanhm;
            R.Bstdhm(NN,1)=Bstdhm;

            %get mean baseline firing for low motivation trials
            % [Blowcell,Blown]=MakePSR04(RAW(i).Nrast(j),trialTbl.LeverInsertion(lowmotivetrials),Baseline,{2});% makes trial by trial rasters for baseline
            % basespklow=NaN(1,Blown);
            % for y= 1:Blown
            %     basespklow(1,y)=sum(Blowcell{1,y}>Baseline(1));
            % end

            FiringRatelm=R.FiringRate(NN,lowmotivetrials');
            Bmeanlm=mean(FiringRatelm,'omitnan');
            Bstdlm=nanstd(FiringRatelm);

            %store baseline mean and std firing rate used for z score
            R.FiringRatelm(NN,1:length(FiringRatelm))=FiringRatelm;
            R.Bmeanlm(NN,1)=Bmeanlm;
            R.Bstdlm(NN,1)=Bstdlm;

            %get mean baseline firing for zero motivation trials (omissions)
            % [Bnocell,Bnon]=MakePSR04(RAW(i).Nrast(j),trialTbl.LeverInsertion(nomotivetrials),Baseline,{2});% makes trial by trial rasters for baseline
            % basespkno=NaN(1,Bnon);
            % for y= 1:Bnon
            %     basespkno(1,y)=sum(Bnocell{1,y}>Baseline(1));
            % end

            FiringRateom=R.FiringRate(NN,nomotivetrials');
            Bmeanom=mean(FiringRateom,'omitnan');
            Bstdom=nanstd(FiringRateom);

            %store baseline mean and std firing rate used for z score
            R.FiringRateom(NN,1:length(FiringRateom))=FiringRateom;
            R.Bmeanom(NN,1)=Bmeanom;
            R.Bstdom(NN,1)=Bstdom;

            %get mean baseline firing for rewarded trials
            % [Brdcell,Brdn]=MakePSR04(RAW(i).Nrast(j),trialTbl.LeverInsertion(rdtrials),Baseline,{2});% makes trial by trial rasters for baseline
            % basespkrd=NaN(1,Brdn);
            % for y= 1:Brdn
            %     basespkrd(1,y)=sum(Brdcell{1,y}>Baseline(1));
            % end

            FiringRaterd=R.FiringRate(NN,rdtrials');
            Bmeanrd=mean(FiringRaterd,'omitnan');
            Bstdrd=nanstd(FiringRaterd);

            %store baseline mean and std firing rate used for z score
            R.FiringRaterd(NN,1:length(FiringRaterd))=FiringRaterd;
            R.Bmeanrd(NN,1)=Bmeanrd;
            R.Bstdrd(NN,1)=Bstdrd;

            for k=1:length(Erefnames) %loops thorough the events
                EvInd=strcmp(Erefnames(k),RAW(i).Einfo(:,2)); %find the event id number from RAW
                if sum(EvInd)==0
                    fprintf('HOWDY, CANT FIND EVENTS FOR ''%s''\n',Erefnames{k})
                end


                R.Ev(k).NumberTrials(NN,1)=length(RAW(i).Erast{EvInd});
                EvTimes=RAW(i).Erast{EvInd};
                %Tbase=prewin(k,1):BSIZE:prewin(k,2);
                if  ~isempty(EvInd) && R.Ev(k).NumberTrials(NN,1)>=MinNumTrials %avoid analyzing sessions where that do not have enough trials

                    %[PSR0,N0]=MakePSR04(RAW(i).Nrast(j),trialTbl.(Erefnames{k}),prewin(k,:),{1});% makes collapsed rasters for baseline for use in normalizing
                    LItimes=trialTbl.(Erefnames{1});
                    if sum(EvTimes<LItimes(1))~=0 && ~any(strcmp(Erefnames{k}, cellcomp))
                        EvTimes(EvTimes<LItimes(1))=[];
                    end
                    if any(strcmp(Erefnames{k}, cellcomp))
                        eventtimes=cell2mat(table2array(trialTbl(:,string(trialTbl.Properties.VariableNames) == Erefnames{k})));
                        actualtrial=repelem(trialTbl.trialNo,cellfun(@length,table2cell(trialTbl(:,string(trialTbl.Properties.VariableNames) == Erefnames{k}))));
                        rdtrialsforl8r=repelem(rdtrials,cellfun(@length,table2cell(trialTbl(:,string(trialTbl.Properties.VariableNames) == Erefnames{k}))));
                        nomotivetrialsforl8r=repelem(nomotivetrials,cellfun(@length,table2cell(trialTbl(:,string(trialTbl.Properties.VariableNames) == Erefnames{k}))));
                        highmotivetrialsforl8r=repelem(highmotivetrials,cellfun(@length,table2cell(trialTbl(:,string(trialTbl.Properties.VariableNames) == Erefnames{k}))));
                        lowmotivetrialsforl8r=repelem(lowmotivetrials,cellfun(@length,table2cell(trialTbl(:,string(trialTbl.Properties.VariableNames) == Erefnames{k}))));
                        % elseif strcmp(Erefnames{k},'PEntry')
                        %     eventtimes=cell2mat(table2array(trialTbl(:,string(trialTbl.Properties.VariableNames) == 'PEntry')));
                        %     actualtrial=repelem(trialTbl.trialNo,cellfun(@length,trialTbl.PEntry));
                        %     rdtrials=repelem(rdtrials,cellfun(@length,trialTbl.PEntry));
                        %     nomotivetrials=repelem(nomotivetrials,cellfun(@length,trialTbl.PEntry));
                        %     highmotivetrials=repelem(highmotivetrials,cellfun(@length,trialTbl.PEntry));
                        %     lowmotivetrials=repelem(lowmotivetrials,cellfun(@length,trialTbl.PEntry));
                        % elseif strcmp(Erefnames{k},'PEntryminusRD')
                        %     eventtimes=cell2mat(table2array(trialTbl(:,string(trialTbl.Properties.VariableNames) == 'PEntryminusRD')));
                        %     actualtrial=repelem(trialTbl.trialNo,cellfun(@length,trialTbl.PEntryminusRD));
                        %     rdtrials=repelem(rdtrials,cellfun(@length,trialTbl.PEntryminusRD));
                        %     nomotivetrials=repelem(nomotivetrials,cellfun(@length,trialTbl.PEntryminusRD));
                        %     highmotivetrials=repelem(highmotivetrials,cellfun(@length,trialTbl.PEntryminusRD));
                        %     lowmotivetrials=repelem(lowmotivetrials,cellfun(@length,trialTbl.PEntryminusRD));
                        % elseif strcmp(Erefnames{k},'PEITI')
                        %     eventtimes=cell2mat(table2array(trialTbl(:,string(trialTbl.Properties.VariableNames) == 'PEITI')));
                        %     actualtrial=repelem(trialTbl.trialNo,cellfun(@length,trialTbl.PEITI));
                        %     rdtrials=repelem(rdtrials,cellfun(@length,trialTbl.PEITI));
                        %     nomotivetrials=repelem(nomotivetrials,cellfun(@length,trialTbl.PEITI));
                        %     highmotivetrials=repelem(highmotivetrials,cellfun(@length,trialTbl.PEITI));
                        %     lowmotivetrials=repelem(lowmotivetrials,cellfun(@length,trialTbl.PEITI));
                    else
                        eventtimes= trialTbl.(Erefnames{k});
                        rdtrialsforl8r=rdtrials;
                        nomotivetrialsforl8r=nomotivetrials;
                        highmotivetrialsforl8r=highmotivetrials;
                        lowmotivetrialsforl8r=lowmotivetrials;
                    end
                    [PSR1,N1]=MakePSR04(RAW(i).Nrast(j),LItimes,Baseline,{2});% makes raster of baseline activity prior to LI (for normalization). PSR1 is a cell(neurons,trials)
                    [PSR4,N0]=MakePSR04(RAW(i).Nrast(j),eventtimes,prewin(k,:),{2});% makes trial by trial rasters for baseline for use in response detection, based on a pre window (for normalization). Includes omitted trials
                    [PSR2,N2]=MakePSR04(RAW(i).Nrast(j),eventtimes,Dura,{2});% makes trial by trial rasters. PSR2 is a cell(neurons, trials). Includes omitted trials
                    [PSR3,N3]=MakePSR04(RAW(i).Nrast(j),eventtimes(~isnan(eventtimes)),Dura,{2});% makes trial by trial rasters. PSR3 is a cell(neurons, trials). Does not include omitted trials
                    if ~isempty(PSR2{1}) %to avoid errors, added on 12/28 2011
                        %Fixed bin size
                        %[PTH0,~,~]=MakePTH07(PSR0,repmat(N0, size(RAW(i).Nrast{j},1),1),{1,0,BinSize});%BW1 reinjected here to make sure PTH0 & PTH1 have the same BW


                        %make PSTHs
                        smoothedtrials=NaN(length(PSR2),length(Tm));
                        smoothedtrialsz= NaN(length(PSR2),length(Tm));
                        binned=NaN(length(PSR2),length(Tm));
                        binnedz=NaN(length(PSR2),length(Tm));
                        tbytBmean=NaN(length(PSR2),1);
                        tbytBstd=NaN(length(PSR2),1);
                        for trial=1:length(PSR2)
                            if ~isnan(PSR2{trial})
                                binned(trial,:)=histcounts(PSR2{trial},[Tm Tm(end)+(Tm(end)-Tm(end-1))]);
                                if ismember(Erefnames{k},cellcomp)
                                    if prewindowflag==0
                                        baseline_hist = histcounts(PSR1{actualtrial(trial)}, Baseline(1):BSIZE:(Baseline(2))+BSIZE);
                                        tbytBmean(trial) = mean(baseline_hist);
                                        tbytBstd(trial) = std(baseline_hist);
                                    elseif prewindowflag==1
                                        prewin_hist = histcounts(PSR4{trial}, prewin(k, 1):BSIZE:(prewin(k, 2))+BSIZE);
                                        tbytBmean(trial) = mean(prewin_hist);
                                        tbytBstd(trial) = std(prewin_hist);
                                    end
                                else
                                    if prewindowflag==0
                                        baseline_hist = histcounts(PSR1{trial}, Baseline(1):BSIZE:(Baseline(2))+BSIZE);
                                        tbytBmean(trial) = mean(baseline_hist);
                                        tbytBstd(trial) = std(baseline_hist);
                                    elseif prewindowflag==1
                                        prewin_hist = histcounts(PSR4{trial}, prewin(k, 1):BSIZE:(prewin(k, 2))+BSIZE);
                                        tbytBmean(trial) = mean(prewin_hist);
                                        tbytBstd(trial) = std(prewin_hist);
                                    end
                                end
                                binnedz(trial,:)=(binned(trial,:)-tbytBmean(trial))/tbytBstd(trial);
                                for l=1:length(Tm)
                                    smoothedtrials(trial,l)=sum(binned(trial,l-min([l-1 trialsmoothbins]):l).*fliplr(trialfilterweights(1:min([l trialsmoothbins+1]))))/sum(trialfilterweights(1:min([l trialsmoothbins+1])));
                                    smoothedtrialsz(trial,l)=sum(binnedz(trial,l-min([l-1 trialsmoothbins]):l).*fliplr(trialfilterweights(1:min([l trialsmoothbins+1]))))/sum(trialfilterweights(1:min([l trialsmoothbins+1])));
                                end
                            end
                        end

                        %average together all trials
                        PTH1nosmooth=mean(binned,1,'omitnan')/BSIZE;
                        PTH1znosmooth=mean(binnedz,1,'omitnan')/BSIZE;
                        PTH1=mean(smoothedtrials,1,'omitnan')/BSIZE;
                        PTH1z=mean(smoothedtrialsz,1,'omitnan')/BSIZE;
                        PTH1nosmooth(isinf(PTH1nosmooth))=NaN;
                        PTH1znosmooth(isinf(PTH1znosmooth))=NaN;
                        PTH1(isinf(PTH1))=NaN;
                        PTH1z(isinf(PTH1z))=NaN;
                        %smooth the resulting PSTH
                        PTH1smooth=[];
                        PTH1zsmooth=[];
                        for l=1:length(Tm)
                            PTH1smooth(1,l)=sum(PTH1(1,l-min([l-1 PSTHsmoothbins]):l).*fliplr(PSTHfilterweights(1:min([l PSTHsmoothbins+1]))))/sum(PSTHfilterweights(1:min([l PSTHsmoothbins+1])));
                            PTH1zsmooth(1,l)=sum(PTH1z(1,l-min([l-1 PSTHsmoothbins]):l).*fliplr(PSTHfilterweights(1:min([l PSTHsmoothbins+1]))))/sum(PSTHfilterweights(1:min([l PSTHsmoothbins+1])));
                        end
                        PTH1smooth(isinf(PTH1smooth))=NaN;
                        PTH1zsmooth(isinf(PTH1zsmooth))=NaN;
                        %------------- Fills the R_2R.Ev(k) fields --------------
                        R.Ev(k).PSTHraw(NN,1:length(Tm))=PTH1smooth; %smoothed
                        R.Ev(k).Meanraw(NN,1)=nanmean(PTH1nosmooth(Tm>postwin(k,1) & Tm<postwin(k,2)),2); %not smoothed
                        if sum(PTH1zsmooth,2)~=0
                            R.Ev(k).PSTHz(NN,1:length(Tm))=PTH1zsmooth;
                            R.Ev(k).Meanz(NN,1)=nanmean(PTH1znosmooth(Tm>postwin(k,1) & Tm<postwin(k,2)),2);
                        else
                            R.Ev(k).PSTHz(NN,1:length(Tm))=NaN(1,length(Tm));
                            R.Ev(k).Meanz(NN,1)=NaN;
                        end

                        %could add averaging together different trials
                        % %for example

                        % collapsedbinned=[];
                        % collapsedbinnedz=[];
                        % collapsedsmoothtrials=[];
                        % collapsedsmoothtrialsz=[];
                        % notnan=~isnan(sum(smoothedtrials,2));
                        % notnanz=~isnan(sum(smoothedtrialsz,2));
                        % collapsedsmoothtrials=smoothedtrials(notnan,:);
                        % collapsedsmoothtrialsz=smoothedtrialsz(notnan,:);
                        % collapsedbinned=binned(notnan,:);
                        % collapsedbinnedz=binnedz(notnan,:);
                        % if R.Ev(k).NumberTrials(NN)>=5 && sum(notnan)>10 && Bmean~=0
                        %     PTH1first5=mean(collapsedsmoothtrials(1:5,:),1,'omitnan')/BSIZE;
                        %     PTH1first5nosmooth=mean(collapsedbinned(1:5,:),1)/BSIZE;
                        %     PTH1first5z=mean(collapsedsmoothtrialsz(1:5,:),1,'omitnan')/BSIZE;
                        %     PTH1first5znosmooth=mean(collapsedbinnedz(1:5,:),1)/BSIZE;
                        %     PTH1last5=mean(collapsedsmoothtrials(end-4:end,:),1,'omitnan')/BSIZE;
                        %     PTH1last5nosmooth=mean(collapsedbinned(end-4:end,:),1)/BSIZE;
                        %     PTH1last5z=mean(collapsedsmoothtrialsz(end-4:end,:),1,'omitnan')/BSIZE;
                        %     PTH1last5znosmooth=mean(collapsedbinnedz(end-4:end,:),1)/BSIZE;
                        %     %------------- Fills the R_2R.Ev(k) fields --------------
                        %     R.Ev(k).PSTHfirst5raw(NN,1:length(Tm))=PTH1first5; %smoothed
                        %     R.Ev(k).PSTHlast5raw(NN,1:length(Tm))=PTH1last5; %smoothed
                        %     R.Ev(k).Meanfirst5raw(NN,1)=nanmean(PTH1first5nosmooth(Tm>postwin(k,1) & Tm<postwin(k,2)),2); %not smoothed
                        %     R.Ev(k).Meanlast5raw(NN,1)=nanmean(PTH1last5nosmooth(Tm>postwin(k,1) & Tm<postwin(k,2)),2);
                        %     R.Ev(k).PSTHfirst5z(NN,1:length(Tm))=PTH1first5z;
                        %     R.Ev(k).Meanfirst5z(NN,1)=nanmean(PTH1first5znosmooth(Tm>postwin(k,1) & Tm<postwin(k,2)),2);
                        %     R.Ev(k).PSTHlast5z(NN,1:length(Tm))=PTH1last5z;
                        %     R.Ev(k).Meanlast5z(NN,1)=nanmean(PTH1last5znosmooth(Tm>postwin(k,1) & Tm<postwin(k,2)),2);
                        % else
                        %     R.Ev(k).PSTHfirst5raw(NN,1:length(Tm))=NaN(1,length(Tm));
                        %     R.Ev(k).PSTHlast5raw(NN,1:length(Tm))=NaN;
                        %     R.Ev(k).Meanfirst5raw(NN,1)=NaN;
                        %     R.Ev(k).Meanlast5raw(NN,1)=NaN;
                        %
                        %     R.Ev(k).PSTHfirst5z(NN,1:length(Tm))=NaN(1,length(Tm));
                        %     R.Ev(k).Meanfirst5z(NN,1)=NaN;
                        %     R.Ev(k).PSTHlast5z(NN,1:length(Tm))=NaN(1,length(Tm));
                        %     R.Ev(k).Meanlast5z(NN,1)=NaN;
                        % end

                        PTH1rd=mean(smoothedtrials(rdtrialsforl8r,:),1,'omitnan')/BSIZE; PTH1rd(isinf(PTH1rd))=NaN;
                        PTH1rdz=mean(smoothedtrialsz(rdtrialsforl8r,:),1,'omitnan')/BSIZE; PTH1rdz(isinf(PTH1rdz))=NaN;
                        PTH1rdnosmooth=mean(binned(rdtrialsforl8r,:),1,'omitnan')/BSIZE; PTH1rdnosmooth(isinf(PTH1rdnosmooth))=NaN;
                        PTH1rdznosmooth=mean(binnedz(rdtrialsforl8r,:),1,'omitnan')/BSIZE; PTH1rdznosmooth(isinf(PTH1rdznosmooth))=NaN;
                        PTH1hm=mean(smoothedtrials(highmotivetrialsforl8r,:),1,'omitnan')/BSIZE; PTH1hm(isinf(PTH1hm))=NaN;
                        PTH1hmnosmooth=mean(binned(highmotivetrialsforl8r,:),1,'omitnan')/BSIZE; PTH1hmnosmooth(isinf(PTH1hmnosmooth))=NaN;
                        PTH1hmz=mean(smoothedtrialsz(highmotivetrialsforl8r,:),1,'omitnan')/BSIZE; PTH1hmz(isinf(PTH1hmz))=NaN;
                        PTH1hmznosmooth=mean(binnedz(highmotivetrialsforl8r,:),1,'omitnan')/BSIZE; PTH1hmznosmooth(isinf(PTH1hmznosmooth))=NaN;
                        PTH1lm=mean(smoothedtrials(lowmotivetrialsforl8r,:),1,'omitnan')/BSIZE; PTH1lm(isinf(PTH1lm))=NaN;
                        PTH1lmnosmooth=mean(binned(lowmotivetrialsforl8r,:),1,'omitnan')/BSIZE; PTH1lmnosmooth(isinf(PTH1lmnosmooth))=NaN;
                        PTH1lmz=mean(smoothedtrialsz(lowmotivetrialsforl8r,:),1,'omitnan')/BSIZE; PTH1lmz(isinf(PTH1lmz))=NaN;
                        PTH1lmznosmooth=mean(binnedz(lowmotivetrialsforl8r,:),1,'omitnan')/BSIZE; PTH1lmznosmooth(isinf(PTH1lmznosmooth))=NaN;
                        PTH1omt=mean(smoothedtrials(nomotivetrialsforl8r,:),1,'omitnan')/BSIZE;PTH1omt(isinf(PTH1omt))=NaN;
                        PTH1omtnosmooth=mean(binned(nomotivetrialsforl8r,:),1,'omitnan')/BSIZE; PTH1omtnosmooth(isinf(PTH1omtnosmooth))=NaN;
                        PTH1omtz=mean(smoothedtrialsz(nomotivetrialsforl8r,:),1,'omitnan')/BSIZE; PTH1omtz(isinf(PTH1omtz))=NaN;
                        PTH1omtznosmooth=mean(binnedz(nomotivetrialsforl8r,:),1,'omitnan')/BSIZE; PTH1omtznosmooth(isinf(PTH1omtznosmooth))=NaN;
                        R.Ev(k).PSTHrdraw(NN,1:length(Tm))=PTH1rd; %smoothed
                        R.Ev(k).Meanrdraw(NN,1)=nanmean(PTH1rdnosmooth(Tm>postwin(k,1) & Tm<postwin(k,2)),2); %not smoothed
                        R.Ev(k).PSTHrdz(NN,1:length(Tm))=PTH1rdz;
                        R.Ev(k).Meanrdz(NN,1)=nanmean(PTH1rdznosmooth(Tm>postwin(k,1) & Tm<postwin(k,2)),2);
                        R.Ev(k).PSTHhmraw(NN,1:length(Tm))=PTH1hm; %smoothed
                        R.Ev(k).Meanhmraw(NN,1)=nanmean(PTH1hmnosmooth(Tm>postwin(k,1) & Tm<postwin(k,2)),2); %not smoothed
                        R.Ev(k).PSTHhmz(NN,1:length(Tm))=PTH1hmz;
                        R.Ev(k).Meanhmz(NN,1)=nanmean(PTH1hmznosmooth(Tm>postwin(k,1) & Tm<postwin(k,2)),2);
                        R.Ev(k).PSTHlmraw(NN,1:length(Tm))=PTH1lm; %smoothed
                        R.Ev(k).Meanlmraw(NN,1)=nanmean(PTH1lmnosmooth(Tm>postwin(k,1) & Tm<postwin(k,2)),2); %not smoothed
                        R.Ev(k).PSTHlmz(NN,1:length(Tm))=PTH1lmz;
                        R.Ev(k).Meanlmz(NN,1)=nanmean(PTH1lmznosmooth(Tm>postwin(k,1) & Tm<postwin(k,2)),2);
                        R.Ev(k).PSTHomtraw(NN,1:length(Tm))=PTH1omt; %smoothed
                        R.Ev(k).Meanomtraw(NN,1)=nanmean(PTH1omtnosmooth(Tm>postwin(k,1) & Tm<postwin(k,2)),2); %not smoothed
                        R.Ev(k).PSTHomtz(NN,1:length(Tm))=PTH1omtz;
                        R.Ev(k).Meanomtz(NN,1)=nanmean(PTH1omtznosmooth(Tm>postwin(k,1) & Tm<postwin(k,2)),2);
                        %------------------ firing (in Hz) per trial in pre/post windows ------------------
                        %used to make the between events comparisons and Response detection in a single window----
                        ev(k).pre=NaN(size(PSR2,2),1);
                        ev(k).post=NaN(size(PSR2,2),1);
                        realevno=find(cellfun(@(x) ~isnan(x(1)),PSR2));
                        for m=1:length(find(cellfun(@(x) ~isnan(x(1)),PSR2))) %not looping properly here, nans populate too early
                            %for baseline spikes, use time prior to most
                            %recent lever insertion
                            if ~isnan(PSR2{realevno(m)})
                                if prewindowflag==1
                                    ev(k).pre(realevno(m))=sum(PSR2{realevno(m)}<prewin(k,2) & PSR2{realevno(m)}>prewin(k,1))/(prewin(k,2)-prewin(k,1)); %CHANGED FROM PSR2 to PSR0 here 10/24/17
                                elseif prewindowflag==0
                                    LItrial=find(LItimes<=EvTimes(m),1,'last');
                                    if isempty(LItrial)
                                        LItrial=1;
                                    end
                                    ev(k).pre(realevno(m))=FiringRate(LItrial);
                                end
                                ev(k).post(realevno(m))=sum(PSR2{realevno(m)}<postwin(k,2) & PSR2{realevno(m)}>postwin(k,1))/(postwin(k,2)-postwin(k,1));
                            end
                        end
                            if k==1
                                R.TrialbyTrialLIactivity(NN,1:maxtrials)=ev(k).post';
                            elseif k==3
                                R.TrialbyTrialLP1activity(NN,1:maxtrials)=ev(k).post';
                            elseif k==4
                                R.TrialbyTrialLP2activity(NN,1:maxtrials)=ev(k).post';
                            elseif k==5
                                R.TrialbyTrialEPactivity(NN,1:maxtrials)=ev(k).post';
                            elseif k==7
                                R.TrialbyTrialPERDactivity(NN,1:maxtrials)=ev(k).post';
                            end
                        ev(k).pre(isnan(ev(k).post))=[];
                        ev(k).post(isnan(ev(k).post))=[];
                        %-------------------- signrank on event and direction----
                        %getting fucked up here for PEITI
                        if ~isempty(ev(k).pre) & ~isempty(ev(k).pre)
                            [R.Ev(k).signrank(NN,1),~]=signrank(ev(k).pre, ev(k).post); %Signrank used here because it is a dependant sample test
                            if R.Ev(k).signrank(NN,1)<PStat
                                R.Ev(k).RespDir(NN,1)=sign(mean(ev(k).post)-mean(ev(k).pre));
                            else R.Ev(k).RespDir(NN,1)=0;
                            end
                        end
                    end %if ~isempty(PSR0{1}) || ~isempty(PSR1{1})
                % cumnumberrd=RAW(i).
                end %if EvInd=0 OR n(trials) < MinNumTrials fills with NaN
            end %Events

            fprintf('DT Neuron #%d\n',NN);
            
        end %neurons: FOR j= 1:size(RAW(i).Nrast,1)
    end %if it's the right kind of session
end %sessions: FOR i=1:length(RAW)

if SAVE_FLAG
    if prewindowflag==1
        labelstring='priorpre';
    elseif prewindowflag==0
        labelstring='BLinepre';
    end
    group=erase(RAWinuse(4:end),'.mat');
    save(['R',group,'_',windowofanalysis,labelstring,'.mat'],'R')
end



toc

