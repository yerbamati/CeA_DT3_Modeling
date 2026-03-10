clearvars;
RAWinuse= uigetfile('RAW*.mat','X:\Matilde\MatLab');
sessionstring= 'NOT';
if ~exist('RAW','var'), load (RAWinuse); end

%Encoding model parameters for just rewarded trials
binsize=0.025;
%kernel sizes. adjusted 11/21/2024
% PreLIkernel= -1:binsize:0;
LIkernel= 0:binsize:0.5;
% PreLP1kernel= -1:binsize:0;
LPkernel=-0.25:binsize:0.25;
% LP1kernel= -1:binsize:1;
% LP2kernel= -1:binsize:1;
% LP3kernel= -1:binsize:1;
%(LPs could also be considered just one type of event)
LRkernel= 0:binsize:0.5;
%PrePEkernel= -1:binsize:-0.5;
PEntryRDkernel= -0.5:binsize:0.5;
PEntrynoRDkernel= -0.5:binsize:0.5;
%EndofRDkernel= -0.1:binsize:0.5;
Lickkernel= -0.1:binsize:0.1;
Boutstartkernel=-0.25:binsize:0.25;
videosubgroup=1:2;
if sum(cellfun(@(x) contains(RAWinuse,x),{'RAWSuperJazz','RAWGrape','RAWMelon'}))~=0
    eventNameskernel={'LeverInsertion';'LeverPress';'LeverRetract';'PEntryRD';'PEntrynoRD';'Licks'; 'FirstInBout';'VideoData';'PriorTrialOutcome';'RewardNumber';'TrialType';'LIinteraction';'LRinteraction'};
    kernelssize={LIkernel,LPkernel,LRkernel,PEntryRDkernel,PEntrynoRDkernel,Lickkernel, Boutstartkernel,videosubgroup,1,1,1,LIkernel,LRkernel};
    %     LvrDistidx=strcmp(RAW(1).Einfo(:,2),'SessionLeverDistance(Model)');
    InstVelidx=strcmp(RAW(1).Einfo(:,2),'SessionInstvelocity(Model)');
    %     LvrDirInstVelidx=strcmp(RAW(1).Einfo(:,2),'Sessionld_instvelocity(Model)');
    HeadAngleidx=strcmp(RAW(1).Einfo(:,2),'SessionAngleOfHeadToLever(Model)');
else
    eventNameskernel={'LeverInsertion';'LeverPress';'LeverRetract';'PEntryRD';'PEntrynoRD';'Licks'; 'FirstInBout';'PriorTrialOutcome';'RewardNumber';'TrialType';'LIinteraction';'LRinteraction'};
    kernelssize={LIkernel,LPkernel,LRkernel,PEntryRDkernel,PEntrynoRDkernel,Lickkernel, Boutstartkernel,1,1,1,LIkernel,LRkernel};
end
LIidx=find(strcmp(eventNameskernel,'LeverInsertion'));
LRidx=find(strcmp(eventNameskernel,'LeverRetract'));

outcomeidx=find(strcmp(eventNameskernel,'TrialType'));
all_columnstartandend=cumsum([1,cellfun('length',kernelssize)]);
% all_columnstartandend_LIsplit=cumsum([1,length(LIkernel),cellfun('length',kernelssize)]);
% all_columnstartandend_LRsplit=cumsum([1,cellfun('length',kernelssize(1:4)),length(LRkernel),cellfun('length',kernelssize(5:end))]);

%all_columnstartandend_LILRsplit=cumsum([1,length(LIkernel),cellfun('length',kernelssize(1:4)),length(LRkernel),cellfun('length',kernelssize(5:end))]);

all_columnstart=all_columnstartandend(1:end-1);
finalevt=sum(find(cellfun(@length,kernelssize)>1)<=find(strcmp(eventNameskernel,'FirstInBout')));
finalevtcol=all_columnstart(finalevt+1)-1;
interactionstart=find(strcmp(eventNameskernel,'LIinteraction'));
%following code changed from OG GLM code to account for kernels that do not
%pass zero
kernellength=cellfun(@(x)find(x==0),kernelssize(1:finalevt),'UniformOutput',false);
kernellength(cellfun(@isempty, kernellength))={NaN};
kernellength=cell2mat(kernellength);
kernel_zerocolumn= [all_columnstart(1:finalevt)+kernellength-1,all_columnstart(finalevt+1:end)];

videoidxs=find(strcmp(eventNameskernel,'VideoData'));
videocol=all_columnstart(videoidxs):all_columnstart(videoidxs+1)-1;
% videoidxs=find(strcmp(eventNameskernel,'LeverDistance')):find(strcmp(eventNameskernel,'AngHeadtoLvr'));
% videocol=all_columnstart(find(strcmp(eventNameskernel,'LeverDistance')):find(strcmp(eventNameskernel,'AngHeadtoLvr')));

neuroncounter=1;
sescounter=1;
maxspikesperbin=[];
Xall=cell(length(RAW),1);
XLILRall=cell(length(RAW),1);
XLILRtrunc=cell(length(RAW),1);
XlvlLILRtrunc=cell(length(RAW),1);
% XLIsplit=cell(length(RAW),1);
% XLRsplit=cell(length(RAW),1);
% XLILRsplit=cell(length(RAW),1);
Yallhistory=cell(length(RAW),1);
Yallpoiss=cell(length(RAW),1);
YallpoissSh=cell(length(RAW),1);
YLILRhistory=cell(length(RAW),1);
YLILRallpoiss=cell(length(RAW),1);
YLILRallpoissSh=cell(length(RAW),1);
YLILRtrunchistory=cell(length(RAW),1);
YLILRtruncpoiss=cell(length(RAW),1);
YLILRtruncpoissSh=cell(length(RAW),1);
YlvlLILRtrunchistory=cell(length(RAW),1);
YlvlLILRtruncpoiss=cell(length(RAW),1);
YlvlLILRtruncpoissSh=cell(length(RAW),1);
Trialts=cell(length(RAW),1);
%binsPerTrial=cell(length(RAW),1);
rdtrialblocks=cell(length(RAW),1);
trialnumber=cell(length(RAW),1);
trialtypeblocks=cell(length(RAW),1);

%event indexes of interest
LI=strcmp('LeverInsertion',RAW(1).Einfo(:,2)); %find LI in RAW
LP1=strcmp('LeverPress1',RAW(1).Einfo(:,2));
LP2=strcmp('LeverPress2',RAW(1).Einfo(:,2));
EP=strcmp('EndPress',RAW(1).Einfo(:,2));
LR=strcmp('LeverRetract',RAW(1).Einfo(:,2));
PERD=strcmp('PEntryRD',RAW(1).Einfo(:,2));
PE=strcmp('PEntry',RAW(1).Einfo(:,2));
RD=strcmp('RewardDeliv',RAW(1).Einfo(:,2));
Licks=strcmp('Licks',RAW(1).Einfo(:,2));
Licklast=strcmp('Licklast',RAW(1).Einfo(:,2));
SesEnd=strcmp('SessionEnd',RAW(1).Einfo(:,2));
trialtype=strcmp('Trial Type',RAW(1).Einfo(:,2));


for ses=1:length(RAW)
    allbinedges=[];
    allbincenters=[];
    priortrialrdvsom=[];
    lp1lat=[];
    totalbinnedtimeofevts=[];
    totalbinnedtimeofspikes=[];
    totalbinnedspikehistory=[];
    totalbinnedtimeofspikesSh=[];
    hmvslm=[];
    if strcmp('NOT',RAW(ses).Type(1:3)) && length(RAW(ses).Erast{RD})>=10
        %make table with all information. only focuses on PEntry general,
        %unlike analysis code.
        %updated: 12.10.2024
        trialTbl=table();
        LItimes=RAW(ses).Erast{LI};
        LRtimes=RAW(ses).Erast{LR};
        trialTbl.trialNo=(1:length(LItimes))';
        %trialTbl.trialType=RAW(ses).Erast{end};
        trialTbl.LeverInsertion=LItimes;
        eventNames={'LeverInsertionNoRD';'LeverInsertionRD';'LeverPress';'LeverPress1';'LeverPress2';'EndPress';'LeverRetract';'LeverRetractRD';'LeverRetractNoRD';...
            'PEntryRD';'PEntry';'RewardDeliv';'Licklast'};
        for evt=1:length(eventNames)
            evInd=strcmp(eventNames(evt),RAW(ses).Einfo(:,2)); %find LP1 in RAW.mat
            evTimes=RAW(ses).Erast{evInd};
            if ismember(eventNames{evt},{'LeverPress';'PEntry'})
                trialTbl.(eventNames{evt})=cell(length(LItimes),1);
            else
                trialTbl.(eventNames{evt})=NaN(length(LItimes),1);
            end
            for trl=1:length(LItimes)
                startTime=LItimes(trl)-15;
                if isequal(eventNames{evt},'PEntry') && ~isnan(trialTbl.EndPress(trl))
                    endTime=trialTbl.EndPress(trl);
                else
                    endTime=LRtimes(trl)+12; % for port entry... should this be pre or post LI/LR?
                end
                if ismember(eventNames{evt},{'LeverPress';'PEntry'})
                    if sum(evTimes>=startTime & evTimes<endTime)==0
                        trialTbl.(eventNames{evt})(trl)={NaN};
                    else
                        trialTbl.(eventNames{evt})(trl)={evTimes(evTimes>=startTime & evTimes<endTime)};
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
        column1_clean = trialTbl.PEntryRD(~isnan(trialTbl.PEntryRD));
        flattened_column2 = cellfun(@(x) x(~isnan(x)), trialTbl.PEntry, 'UniformOutput', false);
        updated_column2 = cellfun(@(x) setdiff(x, column1_clean), flattened_column2, 'UniformOutput', false);
        trialTbl.PEntry = updated_column2;
        trialTbl.PEntry(cellfun(@(x) isempty(x),trialTbl.PEntry))={NaN};
        if sum(cellfun(@(x) contains(RAWinuse,x),{'RAWSuperJazz','RAWGrape','RAWMelon'}))~=0
            trialTbl=renamevars(trialTbl,{'PEntry'},{'PEntrynoRD'});
        else
            trialTbl=renamevars(trialTbl,'PEntry','PEntrynoRD');
        end
        eventNames=[eventNames;'Licklast'];
        evTimes=RAW(ses).Erast{Licks};
        trialTbl.(eventNames{end})=NaN(length(LRtimes),1);

        for trl=1:length(LItimes)
            startTime=LRtimes(trl);
            if trl<length(LRtimes)
                endTime=LRtimes(trl+1); end
            if trl==length(LRtimes)
                endTime=LRtimes(trl)+60.1; end
            if sum(evTimes>=startTime & evTimes<endTime)~=0
                licktimes=evTimes(evTimes>=startTime & evTimes<endTime);
                lickpauses=diff(licktimes)>7;
                if sum(lickpauses)~=0
                    licktimes=licktimes(1:find(lickpauses==1,1));
                end
                trialTbl.(eventNames{end})(trl)=licktimes(end);
            end
            trialTbl.trialStart(trl)=min(cell2mat(table2cell(trialTbl(trl,2:length(eventNames)+1))'));
        end
        rdtrialcounter=0;
        trialStart=trialTbl.trialStart;
        trialEndpad=[];
        for trial=1:length(trialTbl.trialNo)
            temptimes=cell2mat(cellfun(@(x) (x)',table2cell(trialTbl(trial,2:end)),'UniformOutput',false));
            finaleventts=max(temptimes);
            if trial==length(trialTbl.trialNo)
                if ceil(finaleventts)+2>RAW(ses).Erast{SesEnd,1}
                    trialEndpad(trial)=floor(RAW(ses).Erast{SesEnd,1});
                else
                    trialEndpad(trial)=ceil(finaleventts)+2';
                end
            else
                trialEndpad(trial)=ceil(finaleventts)+2';
            end
        end
        maxTime=trialEndpad(end);
        trialStartSh=round(sort(randsample(round(min(trialStart)*1000):round(maxTime*1000),length(RAW(ses).Erast{LI}),'false'))'/1000,2);
        shuffledstartDifference=round(trialStartSh-trialStart,1);
        for trial=1:length(trialTbl.trialNo)
            % pooledleverpresses=cell2mat(trialTbl.LeverPress(trial));
            % poolLPidx=1;
            % pooledPEs=cell2mat(trialTbl.PEntry(trial));
            % poolPEidx=1;
            binedges=[];
            bincenters=[];
            binedgesSh=[];
            bincentersSh=[];
            binedges=(round(trialStart(trial),1)-2:binsize:trialEndpad(trial))';
            bincenters= (binedges(1:end-1) + binedges(2:end)) / 2;
            binedgesSh=binedges+shuffledstartDifference(trial); %(round(trialStart(trial)+shuffledstartDifference(trial),1)-2:binsize:round(trialEndpad(trial)+shuffledstartDifference(trial),1))';
            bincentersSh= (binedgesSh(1:end-1) + binedgesSh(2:end)) / 2;
            %binsPerTrial{ses,1}{trial,1}=length(bincenters);
            binnedtimeofevts=zeros(length(bincenters),length(eventNameskernel));
            binnedtimeofspikes=zeros(length(bincenters),size(RAW(ses).Ninfo,1));
            binnedspikehistory=repmat({zeros(length(bincenters),2)}, 1,size(RAW(ses).Ninfo,1));
            binnedtimeofspikesSh=zeros(length(bincenters),size(RAW(ses).Ninfo,1));
            for evt=1:finalevt
                condition_matrix=[];
                if strcmp(eventNameskernel{evt},'FirstInBout')
                    if ~isempty(RAW(ses).Erast{Licks})
                        typelicks=RAW(ses).Erast{Licks}(RAW(ses).Erast{Licks}>=binedges(1)& RAW(ses).Erast{Licks}<binedges(end));
                        if ~isempty(typelicks)
                            typediff=diff(typelicks);
                            lickswithincluster=find(typediff<0.5);
                            if length(lickswithincluster)>4
                                firstinclust=lickswithincluster(1);
                                for i=2:length(lickswithincluster)
                                    if (lickswithincluster(i)-lickswithincluster(i-1))>1
                                        firstinclust=cat(1,firstinclust,lickswithincluster(i));
                                    end
                                end
                                if ~isempty(firstinclust)
                                    if length(firstinclust)==1
                                        condition_matrix = (typelicks(firstinclust) >= (binedges(1:end-1))) & (typelicks(firstinclust) < (binedges(2:end)));
                                        if any(find(condition_matrix)<find(binnedtimeofevts(:,3)))
                                            condition_matrix(condition_matrix(1),:)=0;
                                        end
                                        binnedtimeofevts(:,evt)=condition_matrix;
                                    else
                                        condition_matrix = (typelicks(firstinclust) >= (binedges(1:end-1))') & (typelicks(firstinclust) < (binedges(2:end))');
                                        potentialidxs=find(sum(condition_matrix));
                                        if any(potentialidxs<find(binnedtimeofevts(:,LRidx)))
                                            removedcol=potentialidxs(any(potentialidxs<find(binnedtimeofevts(:,LRidx))));
                                            idxrow=find(sum(condition_matrix,2));
                                            removedrow=idxrow(any(potentialidxs<find(binnedtimeofevts(:,LRidx))));
                                            condition_matrix(removedrow,removedcol)=0;
                                        end
                                        binnedtimeofevts(:,evt)=sum(condition_matrix);
                                    end
                                    binnedtimeofevts(logical(binnedtimeofevts(:,evt)),strcmp(eventNameskernel,'Licks'))=0;
                                end
                            end
                        end
                    end
                elseif strcmp(eventNameskernel{evt},'Licks')
                    if ~isempty(RAW(ses).Erast{Licks})
                        condition_matrix = (RAW(ses).Erast{Licks} >= (binedges(1:end-1))') & (RAW(ses).Erast{Licks} < (binedges(2:end))');
                        binnedtimeofevts(:,evt)=sum(condition_matrix);
                    end
                elseif strcmp(eventNameskernel{evt},'PEntrynoRD') ||  strcmp(eventNameskernel{evt},'LeverPress')
                    pooledevts=cell2mat(trialTbl.(eventNameskernel{evt})(trial));
                    pooledevts(isnan(pooledevts))=[];
                    if length(pooledevts)==3 && strcmp(eventNameskernel{evt},'LeverPress')
                        pooledevts(end)=[];
                    end
                    if ~isempty(pooledevts)
                        condition_matrix = (pooledevts >= (binedges(1:end-1))') & (pooledevts < (binedges(2:end))');
                        if sum(condition_matrix)==1
                            idxtomark=logical(condition_matrix)';
                            binnedtimeofevts(idxtomark,evt)=1;
                        else
                            idxtomark=logical(sum(condition_matrix))';
                            binnedtimeofevts(idxtomark,evt)=1;
                        end
                    end
                % elseif contains(eventNameskernel{evt},'PreLI')
                %     condition_matrix = logical((trialTbl.(eventNameskernel{LIidx})(trial) >= (binedges(1:end-1))') & (trialTbl.(eventNameskernel{LIidx})(trial) < (binedges(2:end))'));
                %     binnedtimeofevts(condition_matrix,evt)=1;
                % elseif contains(eventNameskernel{evt},'PreLP1')
                %     condition_matrix = logical((trialTbl.LeverPress1(trial) >= (binedges(1:end-1))') & (trialTbl.LeverPress1(trial) < (binedges(2:end))'));
                %     binnedtimeofevts(condition_matrix,evt)=1;
                % elseif contains(eventNameskernel{evt},'PreRDPE')
                %     condition_matrix = logical((trialTbl.PEntryRD(trial) >= (binedges(1:end-1))') & (trialTbl.PEntryRD(trial) < (binedges(2:end))'));
                %     binnedtimeofevts(condition_matrix,evt)=1;
                else
                    condition_matrix = logical((trialTbl.(eventNameskernel{evt})(trial) >= (binedges(1:end-1))') & (trialTbl.(eventNameskernel{evt})(trial) < (binedges(2:end))'));
                    binnedtimeofevts(condition_matrix,evt)=1;
                end
            end

            for neuron=1:size(RAW(ses).Ninfo,1)
                condition_matrix=[];
                condition_matrix = (RAW(ses).Nrast{neuron} >= (binedges(1:end-1))') & (RAW(ses).Nrast{neuron} < (binedges(2:end))');
                binnedtimeofspikes(:,neuron)=sum(condition_matrix);
                binnedspikehistory{neuron}=[[0;binnedtimeofspikes(1:end-1,neuron)],[0;0;binnedtimeofspikes(1:end-2,neuron)]];
                condition_matrix=[];
                condition_matrix = (RAW(ses).Nrast{neuron} >= (binedgesSh(1:end-1))') & (RAW(ses).Nrast{neuron} < (binedgesSh(2:end))');
                binnedtimeofspikesSh(:,neuron)=sum(condition_matrix);
            end
            % Here lies the old version of making the initial matrix:
            % The code below definitely works for making the initial
            % prediction matrix, but it takes for-fucking-ever. The
            % reworked version above is much faster, and has been checked
            % extensively for potential bugs. I am keeping the below in
            % tact in my current code on the off chance there is a major
            % bug in the reworked code that I am not picking up on
            %  for ts=1:length(bincenters)
            %     for evt=1:length(eventNameskernel)
            %         if strcmp(eventNameskernel(evt),'Licks')
            %             if sum(binnedtimeofevts(:,1)) && sum(binedges(ts)<=RAW(ses).Erast{Licks}&RAW(ses).Erast{Licks}<binedges(ts+1))~=0
            %                 binnedtimeofevts(ts,evt)=sum(binedges(ts)<=RAW(ses).Erast{Licks}&RAW(ses).Erast{Licks}<binedges(ts+1));
            %             end
            %
            %         elseif strcmp(eventNameskernel(evt),'LickRD')
            %             lridx=find(binnedtimeofevts(:,4)==1);
            %             lickidx=find(binnedtimeofevts(:,7)==1);
            %             if ~isempty(lridx) && ~isempty(lickidx)
            %                 LickRD=lickidx(find(lickidx>lridx,1));
            %                 if ts==LickRD
            %                     binnedtimeofevts(ts,evt)=sum(binedges(ts)<=RAW(ses).Erast{Licks}&RAW(ses).Erast{Licks}<binedges(ts+1));
            %                 end
            %             end
            %         elseif strcmp(eventNameskernel{evt},'LeverPress1')
            %             if binedges(ts)<=trialTbl.(eventNameskernel{evt})(trial)&trialTbl.(eventNameskernel{evt})(trial)<binedges(ts+1)
            %                 binnedtimeofevts(ts,evt)=1;
            %             end
            %             % elseif strcmp(eventNameskernel{evt},'LeverPress')
            %             %     lpnames={'LeverPress1' 'LeverPress2' 'EndPress'};
            %             %     for lp=1:length(lpnames)
            %             %         if binedges(ts)<=trialTbl.(lpnames{lp})(trial)&trialTbl.(lpnames{lp})(trial)<binedges(ts+1)
            %             %             binnedtimeofevts(ts,evt)=1;
            %             %             %continue
            %             %         end
            %             %     end
            %         elseif strcmp(eventNameskernel{evt},'LeverPress')
            %             if binedges(ts)<=pooledleverpresses(poolLPidx)&pooledleverpresses(poolLPidx)<binedges(ts+1)
            %                 binnedtimeofevts(ts,evt)=1;
            %                 if length(pooledleverpresses)~=1 & poolLPidx~=length(pooledleverpresses)
            %                     poolLPidx=poolLPidx+1;
            %                 end
            %             end
            %         elseif strcmp(eventNameskernel{evt},'PEntry')
            %             if binedges(ts)<=pooledPEs(poolPEidx)&pooledPEs(poolPEidx)<binedges(ts+1)
            %                 binnedtimeofevts(ts,evt)=1;
            %                 if length(pooledPEs)~=1 & poolPEidx~=length(pooledPEs)
            %                     poolPEidx=poolPEidx+1;
            %                 end
            %             end
            %         else
            %             if binedges(ts)<=trialTbl.(eventNameskernel{evt})(trial)&trialTbl.(eventNameskernel{evt})(trial)<binedges(ts+1)
            %                 binnedtimeofevts(ts,evt)=1;
            %             end
            %         end
            %         for neuron=1:size(RAW(ses).Ninfo,1)
            %             if sum(binedges(ts)<=RAW(ses).Nrast{neuron}&RAW(ses).Nrast{neuron}<binedges(ts+1))~=0
            %                 binnedtimeofspikes(ts,neuron)=sum(binedges(ts)<=RAW(ses).Nrast{neuron}&RAW(ses).Nrast{neuron}<binedges(ts+1));
            %                 if ts~=length(bincenters)
            %                     binnedtimeofspikesSh(ts,neuron)=sum(binedgesSh(ts)<=RAW(ses).Nrast{neuron}&RAW(ses).Nrast{neuron}<binedgesSh(ts+1));
            %                 elseif ts==length(bincenters)
            %                     binnedtimeofspikesSh(ts,neuron)=sum(binedgesSh(ts)<=RAW(ses).Nrast{neuron}&RAW(ses).Nrast{neuron}<binedgesSh(ts)+0.1);
            %                 end
            %             end
            %         end
            %     end
            % end
            if strcmp(RAW(ses).Erast{trialtype}(trial),'omission')
                repeatnumb=0;
            elseif strcmp(RAW(ses).Erast{trialtype}(trial),'high')
                repeatnumb=2;
            elseif strcmp(RAW(ses).Erast{trialtype}(trial),'low')
                repeatnumb=1;
            end
            if ~isnan(trialTbl.LeverInsertion(trial)) && (~isnan(trialTbl.RewardDeliv(trial)) || ~isnan(trialTbl.PEntryRD(trial)))
                rdtrialcounter=rdtrialcounter+1;
            end
            rdtrialblocks{ses,1}= [rdtrialblocks{ses,1};zeros(length(bincenters),1)+rdtrialcounter];
            trialtypeblocks{ses,1}=[trialtypeblocks{ses,1};repelem(repeatnumb,length(bincenters))'];
            totalbinnedtimeofevts=[totalbinnedtimeofevts; binnedtimeofevts];
            allbinedges=[allbinedges; binedges];
            allbincenters=[allbincenters; bincenters];
            totalbinnedspikehistory=[totalbinnedspikehistory;binnedspikehistory];
            totalbinnedtimeofspikes=[totalbinnedtimeofspikes;binnedtimeofspikes];
            totalbinnedtimeofspikesSh=[totalbinnedtimeofspikesSh;binnedtimeofspikesSh];
            if trial==1
                priortrialrdvsom=repelem(0,length(bincenters))';
                trialnumber{ses,1}=repelem(trial,length(bincenters))';
            elseif trial~=1 && ~isnan(trialTbl.LeverInsertion(trial-1)) && ~isnan(trialTbl.RewardDeliv(trial-1))
                priortrialrdvsom=[priortrialrdvsom;repelem(1,length(bincenters))'];
                trialnumber{ses}=[trialnumber{ses};repelem(trial,length(bincenters))'];
            elseif trial~=1 && ~isnan(trialTbl.LeverInsertion(trial-1)) && isnan(trialTbl.RewardDeliv(trial-1))
                priortrialrdvsom=[priortrialrdvsom;repelem(0,length(bincenters))'];
                trialnumber{ses}=[trialnumber{ses};repelem(trial,length(bincenters))'];
            end
            %lp1lat=[lp1lat;repelem(RAW(ses).Erast{31,1}(trial),length(bincenters))'];
            if size(trialnumber{ses},1)~=size(totalbinnedtimeofevts,1)
                pause
            end
        end
        totalbinnedspikehistory=cellfun(@(c) vertcat(c{:}), num2cell(totalbinnedspikehistory,1), 'UniformOutput', false);
        numbTrials{ses,1}=trial;
        expandedtotalbinnedtimeofevts=zeros(length(totalbinnedtimeofevts),finalevtcol); %changed from all_columnstartandend to all_columnstart 3/13/2025
        for column = 1:finalevt 
            kernelLen = length(kernelssize{column});
            eventCol = all_columnstart(column);  % the column representing the event itself

            % --- determine anchor and offsets ---
            if ~isnan(kernel_zerocolumn(column))          % kernel contains 0
                zeroIdx = find(kernelssize{column}==0,1,'first');
                expOffsets = (1:kernelLen) - zeroIdx;    % offsets relative to zero
                anchor = kernel_zerocolumn(column);      % column of zero
                bc=find(totalbinnedtimeofevts(:,column))';
            else                                          % kernel has no 0 → pre-event
                expOffsets = 0:kernelLen-1;           % offsets so last bin aligns with event
                evtoffset=kernelssize{column}(1)/binsize;
                anchor = eventCol;                        % last kernel bin = event column
                bc=find(totalbinnedtimeofevts(:,column))'+evtoffset;
            end

            % --- apply kernel to each active bin (diagonal preserved) ---
            for bincenter = bc

                % valid row indices (skip negatives)
                validIdx = logical((bincenter + expOffsets) > 0) == logical((bincenter + expOffsets) <= length(totalbinnedtimeofevts));

                rows = bincenter + expOffsets(validIdx);
                cols = anchor + expOffsets(validIdx);

                expandedtotalbinnedtimeofevts(sub2ind(size(expandedtotalbinnedtimeofevts), rows, cols)) = 1;
            end
        end
        % for column=1:finalevt
        %     centeridx=[];
        %     current_columnzero=kernel_zerocolumn(column);
        %     for bincenter=find(totalbinnedtimeofevts(:,column))
        %         for exp=(1:length(kernelssize{column}==0)) - find(kernelssize{column}==0 == 1)
        %             if any(bincenter+exp<=0)
        %                 negidx=bincenter+exp<=0;
        %                 expandedtotalbinnedtimeofevts([bincenter(negidx);bincenter(~negidx)+exp],current_columnzero+exp)=1;
        %             else
        %                 expandedtotalbinnedtimeofevts(bincenter+exp,current_columnzero+exp)=1;
        %             end
        %         end
        %         current_columnzero=kernel_zerocolumn(column);
        %     end
        % end
        if size(expandedtotalbinnedtimeofevts,1)~=size(allbincenters,1)
            expandedtotalbinnedtimeofevts(size(allbincenters,1)+1:end,:)=[];
        end
        if sum(cellfun(@(x) contains(RAWinuse,x),{'RAWSuperJazz','RAWGrape','RAWMelon'}))~=0 %check this part
            [~,tsidx]=ismember(round(allbincenters,4),round(RAW(ses).Erast{InstVelidx,2},4));
            %             LvrDist=RAW(ses).Erast{LvrDistidx,1}(tsidx,1);
            InstVel=RAW(ses).Erast{InstVelidx,1}(tsidx,1);
            HeadAngle=RAW(ses).Erast{HeadAngleidx,1}(tsidx,1);
            %             [~,score,~]=pca([LvrDist,InstVel,HeadAngle]);
            %             expandedtotalbinnedtimeofevts=[expandedtotalbinnedtimeofevts,score(:,1)];
            %             expandedtotalbinnedtimeofevts=[expandedtotalbinnedtimeofevts,LvrDist,InstVel,HeadAngle];
            expandedtotalbinnedtimeofevts=[expandedtotalbinnedtimeofevts,InstVel,HeadAngle];
        end
        if length(expandedtotalbinnedtimeofevts)~=length(totalbinnedtimeofevts)
            return
        end
        GLMtrials=trialnumber{ses}/max(trialnumber{ses});
        GLMrds=rdtrialblocks{ses}/max(rdtrialblocks{ses});
        binaryresponse=trialtypeblocks{ses}~=0;
        expandedtotalbinnedtimeofevts=[expandedtotalbinnedtimeofevts,priortrialrdvsom,GLMrds,binaryresponse];
        rdvsom=expandedtotalbinnedtimeofevts(:,end);
        rdvsom(rdvsom==0)=-1;
        hmvslm(trialtypeblocks{ses}==2,1)=1;
        hmvslm(trialtypeblocks{ses}==1,1)=-1;
        hmvslm(trialtypeblocks{ses}==0,1)=0;

        TrialLIandLRinteraction=[expandedtotalbinnedtimeofevts(:,all_columnstart(LIidx):all_columnstart(LIidx+1)-1).*rdvsom expandedtotalbinnedtimeofevts(:,all_columnstart(LRidx):all_columnstart(LRidx+1)-1).*rdvsom];
        LevelLIandLRinteraction=[expandedtotalbinnedtimeofevts(:,all_columnstart(LIidx):all_columnstart(LIidx+1)-1).*hmvslm expandedtotalbinnedtimeofevts(:,all_columnstart(LRidx):all_columnstart(LRidx+1)-1).*hmvslm];
        Trialrowstopull=find(sum(expandedtotalbinnedtimeofevts(:,all_columnstartandend(LIidx):all_columnstartandend(LIidx+1)-1),2) | sum(expandedtotalbinnedtimeofevts(:,all_columnstartandend(LRidx):all_columnstartandend(LRidx+1)-1),2));
        Levelrowstopull=find(sum(expandedtotalbinnedtimeofevts(:,all_columnstartandend(LIidx):all_columnstartandend(LIidx+1)-1),2)& trialtypeblocks{ses}>0 | sum(expandedtotalbinnedtimeofevts(:,all_columnstartandend(LRidx):all_columnstartandend(LRidx+1)-1),2)& trialtypeblocks{ses}>0);

        rewardedtrialidx=expandedtotalbinnedtimeofevts(:,end)>0;
        trimmedtoRDtrial=[expandedtotalbinnedtimeofevts(rewardedtrialidx,:) TrialLIandLRinteraction(rewardedtrialidx,:) LevelLIandLRinteraction(rewardedtrialidx,:)];
        trimmedtoLILRts=[expandedtotalbinnedtimeofevts(Trialrowstopull,:) TrialLIandLRinteraction(Trialrowstopull,:)];
        trimmedtolevelLILRts=[expandedtotalbinnedtimeofevts(Levelrowstopull,:) LevelLIandLRinteraction(Levelrowstopull,:)];
        GLMtrialstrunc{ses,1}=GLMtrials(Trialrowstopull,:);
        GLMlvlstrunc{ses,1}=GLMrds(Levelrowstopull,:);
        if ~isempty(videocol)
            trimmedtoRDtrial(:,videocol)=(trimmedtoRDtrial(:,videocol)-min(trimmedtoRDtrial(:,videocol)))./(max(trimmedtoRDtrial(:,videocol))-min(trimmedtoRDtrial(:,videocol)));
            trimmedtoLILRts(:,videocol)=(trimmedtoLILRts(:,videocol)-min(trimmedtoLILRts(:,videocol)))./(max(trimmedtoLILRts(:,videocol))-min(trimmedtoLILRts(:,videocol)));
            trimmedtolevelLILRts(:,videocol)=(trimmedtolevelLILRts(:,videocol)-min(trimmedtolevelLILRts(:,videocol)))./(max(trimmedtolevelLILRts(:,videocol))-min(trimmedtolevelLILRts(:,videocol)));
            expandedtotalbinnedtimeofevts(:,videocol)=(expandedtotalbinnedtimeofevts(:,videocol)-min(expandedtotalbinnedtimeofevts(:,videocol)))./(max(expandedtotalbinnedtimeofevts(:,videocol))-min(expandedtotalbinnedtimeofevts(:,videocol)));
        end
        Xall{sescounter,1}=trimmedtoRDtrial;
        XLILRall{sescounter,1}=expandedtotalbinnedtimeofevts;
        XLILRtrunc{sescounter,1}=trimmedtoLILRts;
        XlvlLILRtrunc{sescounter,1}=trimmedtolevelLILRts;
        Trialts{sescounter,1}=allbincenters(rewardedtrialidx,:);
        Trialts{sescounter,2}=allbincenters(Trialrowstopull,:);
        Trialts{sescounter,3}=allbincenters(Levelrowstopull,:);
        LIRD=trimmedtoLILRts(:,all_columnstartandend(LIidx):(all_columnstartandend(LIidx+1)-1));
        LIRD(trimmedtoLILRts(:,all_columnstartandend(outcomeidx))==0,:)=0;
        LIOM=trimmedtoLILRts(:,all_columnstartandend(LIidx):(all_columnstartandend(LIidx+1)-1));
        LIOM(trimmedtoLILRts(:,all_columnstartandend(outcomeidx))>0,:)=0;
        LRRD=trimmedtoLILRts(:,all_columnstartandend(LRidx):(all_columnstartandend(LRidx+1)-1));
        LRRD(trimmedtoLILRts(:,all_columnstartandend(outcomeidx))==0,:)=0;
        LROM=trimmedtoLILRts(:,all_columnstartandend(LRidx):(all_columnstartandend(LRidx+1)-1));
        LROM(trimmedtoLILRts(:,all_columnstartandend(outcomeidx))>0,:)=0;
        % XLIsplit{sescounter,1}=[LIRD LIOM trimmedtoLILRts(:,all_columnstartandend(2):end)];
        %XLRsplit{sescounter,1}=[trimmedtoLILRts(:,1:all_columnstartandend(4)-1) LRRD LROM trimmedtoLILRts(:,all_columnstartandend(5):end)];
        %change here
        XLILRsplittrunc{sescounter,1}=[LIRD LIOM trimmedtoLILRts(:,all_columnstartandend(LIidx+1):all_columnstartandend(LRidx)-1) LRRD LROM trimmedtoLILRts(:,all_columnstartandend(LRidx+1):end)];
        LP1latencyall{sescounter,1}=RAW(ses).Erast{34};
        LP1latencyLILRall{sescounter,1}=RAW(ses).Erast{35};
        for neuron=1:size(totalbinnedtimeofspikes,2)
            Yallpoiss{sescounter,1}(:,neuron)=totalbinnedtimeofspikes(rewardedtrialidx,neuron);
            YallpoissSh{sescounter,1}(:,neuron)=totalbinnedtimeofspikesSh(rewardedtrialidx,neuron);
            Yallhistory{sescounter,1}{:,neuron}=totalbinnedspikehistory{neuron}(rewardedtrialidx,:);
            YLILRallpoiss{sescounter,1}(:,neuron)=totalbinnedtimeofspikes(:,neuron);
            YLILRallpoissSh{sescounter,1}(:,neuron)=totalbinnedtimeofspikesSh(:,neuron);
            YLILRhistory{sescounter,1}{:,neuron}=totalbinnedspikehistory{neuron};
            YLILRtruncpoiss{sescounter,1}(:,neuron)=totalbinnedtimeofspikes(Trialrowstopull,neuron);
            YLILRtruncpoissSh{sescounter,1}(:,neuron)=totalbinnedtimeofspikesSh(Trialrowstopull,neuron);
            YLILRtrunchistory{sescounter,1}{:,neuron}=totalbinnedspikehistory{neuron}(Trialrowstopull,:);
            YlvlLILRtruncpoiss{sescounter,1}(:,neuron)=totalbinnedtimeofspikes(Levelrowstopull,neuron);
            YlvlLILRtruncpoissSh{sescounter,1}(:,neuron)=totalbinnedtimeofspikesSh(Levelrowstopull,neuron);
            YlvlLILRtrunchistory{sescounter,1}{:,neuron}=totalbinnedspikehistory{neuron}(Levelrowstopull,:);


            neuroncounter=neuroncounter+1;
        end
        fprintf('Session #%d \n',sescounter);
        sescounter=sescounter+1;
    end
end


%submodels
submodels={};
submodelssplit={};
% all_columnstartandend_LIsplit=cumsum([1,length(LIkernel),cellfun('length',kernelssize)]);
% all_columnstartandend_LRsplit=cumsum([1,cellfun('length',kernelssize(1:4)),length(LRkernel),cellfun('length',kernelssize(5:end))]);
% all_columnstartandend_LILRsplit=cumsum([1,length(LIkernel),cellfun('length',kernelssize(1:4)),length(LRkernel),cellfun('length',kernelssize(5:end))]);
for kern=1:length(kernelssize)
    submodels{kern}=ones(1,all_columnstartandend(end)-1);
    submodels{kern}(1,all_columnstartandend(kern):all_columnstartandend(kern+1)-1)=0;
end
if sum(cellfun(@(x) contains(RAWinuse,x),{'RAWSuperJazz','RAWGrape','RAWMelon'}))~=0
    spliteventNameskernel= {'LeverInsertionRD';'LeverInsertionNoRD';'LeverPress';'LeverRetractRD';'LeverRetractNoRD';'PEntryRD';'PEntrynoRD';'Licks'; 'FirstInBout';'VideoData';'PriorTrialOutcome';'TrialNumber';'RewardNumber';'TrialType';'LIinteraction';'LRinteraction'};
    splitkernelssize={LIkernel,LIkernel,LPkernel,LRkernel,LRkernel,PEntryRDkernel,PEntrynoRDkernel,Lickkernel, Boutstartkernel,videosubgroup,1,1,1,1,LIkernel,LRkernel};
else
    spliteventNameskernel={'LeverInsertionRD';'LeverInsertionNoRD';'LeverPress';'LeverRetractRD';'LeverRetractNoRD';'PEntryRD';'PEntrynoRD';'Licks'; 'FirstInBout';'PriorTrialOutcome';'TrialNumber';'RewardNumber';'TrialType';'LIinteraction';'LRinteraction'};
    splitkernelssize={LIkernel,LIkernel,LPkernel,LRkernel,LRkernel,PEntryRDkernel,PEntrynoRDkernel,Lickkernel,Boutstartkernel,1,1,1,1,LIkernel,LRkernel};
end
splitall_columnstartandend=cumsum([1,cellfun('length',splitkernelssize)]);
splitall_columnstart=splitall_columnstartandend(1:end-1);
splitfinalevt=sum(find(cellfun(@length,splitkernelssize)>1)<=find(strcmp(spliteventNameskernel,'FirstInBout')));
splitfinalevtcol=splitall_columnstart(splitfinalevt+1)-1;
splitinteractionstart=find(strcmp(spliteventNameskernel,'LIinteraction'));
splitkernel_zerocolumn= [splitall_columnstart(1:splitfinalevt)+cellfun(@(x)find(x==0),splitkernelssize(1:splitfinalevt))-1,splitall_columnstart(splitfinalevt+1:end)];
splitvideoidxs=find(strcmp(spliteventNameskernel,'VideoData'));
splitvideocol=splitall_columnstart(splitvideoidxs):splitall_columnstart(splitvideoidxs+1)-1;
for splitkern=1:length(splitkernelssize)
    submodelssplit{splitkern}=ones(1,splitall_columnstartandend(end)-1);
    submodelssplit{splitkern}(1,splitall_columnstartandend(splitkern):splitall_columnstartandend(splitkern+1)-1)=0;
end
Trialts=reshape(Trialts(cellfun(@isempty,Trialts)==0),(length(Trialts(cellfun(@isempty,Trialts)==0))/3),3);
Xall=Xall(cellfun(@isempty,Xall)==0);
LP1latencyall=LP1latencyall(cellfun(@isempty,LP1latencyall)==0);
LP1latencyLILRall=LP1latencyLILRall(cellfun(@isempty,LP1latencyLILRall)==0);
Yallhistory=Yallhistory(cellfun(@isempty,Yallhistory)==0);
Yallpoiss=Yallpoiss(cellfun(@isempty,Yallpoiss)==0);
YallpoissSh=YallpoissSh(cellfun(@isempty,YallpoissSh)==0);
XLILRall=XLILRall(cellfun(@isempty,XLILRall)==0);
% XLIsplit=XLIsplit(cellfun(@isempty,XLIsplit)==0);
% XLRsplit=XLRsplit(cellfun(@isempty,XLRsplit)==0);
XLILRsplittrunc=XLILRsplittrunc(cellfun(@isempty,XLILRsplittrunc)==0);
YLILRhistory=YLILRhistory(cellfun(@isempty,YLILRhistory)==0);
YLILRallpoiss=YLILRallpoiss(cellfun(@isempty,YLILRallpoiss)==0);
YLILRallpoissSh=YLILRallpoissSh(cellfun(@isempty,YLILRallpoissSh)==0);
XLILRtrunc=XLILRtrunc(cellfun(@isempty,XLILRtrunc)==0);
YLILRtrunchistory=YLILRtrunchistory(cellfun(@isempty,YLILRtrunchistory)==0);
YLILRtruncpoiss=YLILRtruncpoiss(cellfun(@isempty,YLILRtruncpoiss)==0);
YLILRtruncpoissSh=YLILRtruncpoissSh(cellfun(@isempty,YLILRtruncpoissSh)==0);
XlvlLILRtrunc=XlvlLILRtrunc(cellfun(@isempty,XlvlLILRtrunc)==0);
YlvlLILRtrunchistory=YlvlLILRtrunchistory(cellfun(@isempty,YlvlLILRtrunchistory)==0);
YlvlLILRtruncpoiss=YlvlLILRtruncpoiss(cellfun(@isempty,YlvlLILRtruncpoiss)==0);
YlvlLILRtruncpoissSh=YlvlLILRtruncpoissSh(cellfun(@isempty,YlvlLILRtruncpoissSh)==0);
rdtrialblocks=rdtrialblocks(cellfun(@isempty,rdtrialblocks)==0);

GLMtrialstrunc=GLMtrialstrunc(cellfun(@isempty,GLMtrialstrunc)==0);
GLMlvlstrunc=GLMlvlstrunc(cellfun(@isempty,GLMlvlstrunc)==0);

% rdtrialblocks=rdtrialblocks(cellfun(@isempty,rdtrialblocks)==0);
% trialnumber=trialnumber(cellfun(@isempty,trialnumber)==0);
%binsPerTrial=binsPerTrial(cellfun(@isempty,rdtrialblocks)==0);
neuroncounter=neuroncounter-1;

save([regexp(RAWinuse, '(?<=W)(.*?)(?=_)', 'match', 'once'),'GLMinputs',num2str(binsize*1000),'ms.mat'],'GLMtrialstrunc','GLMlvlstrunc','videoidxs','splitvideoidxs','interactionstart','splitinteractionstart','finalevt','splitfinalevt','finalevtcol','splitfinalevtcol','binsize','eventNameskernel','spliteventNameskernel','kernelssize','splitkernelssize','all_columnstart','splitall_columnstart','all_columnstartandend','splitall_columnstartandend', 'kernel_zerocolumn','splitkernel_zerocolumn', 'Xall','XLILRall','XLILRtrunc','XlvlLILRtrunc','XLILRsplittrunc','Yallhistory','Yallpoiss','YLILRhistory','YLILRallpoiss','YLILRtrunchistory','YLILRtruncpoiss','YlvlLILRtrunchistory','YlvlLILRtruncpoiss','YallpoissSh','YLILRallpoissSh','YLILRtruncpoissSh','YlvlLILRtruncpoissSh','submodels','submodelssplit','neuroncounter','Trialts','LP1latencyall','LP1latencyLILRall')
    %% perform regression with all predictors
clearvars
opts.alpha=0; %alpha = 1, lasso regression, alpha = 0 ridge regression
opts.standardize=true;
opts.thresh=1e-4;
opts.nlambda=100;
options=glmnetSet(opts);
inputsinuse= uigetfile('*GLMinputs*.mat','X:\Matilde\MatLab');
Rtoload=uigetfile(['R',regexp(inputsinuse, '(.*?)(?=G)', 'match', 'once'),'*.mat'],'X:\Matilde\MatLab');
load (inputsinuse); load(Rtoload);
if contains(Rtoload,'Super')
    itmax=1;
else
    itq=questdlg('How many iterations','ds','100','1','1');
    itmax=str2double(itq);
end


whatdistro=questdlg('Which family?','family','poisson','gaussian','gaussian');
if contains(regexp(inputsinuse, '(.*?)(?=G)', 'match', 'once'),{'SuperJazz','Grape','Melon'})
    videodata=questdlg('Analyze video data?','video','yes','no','no');
else
    videodata='no';
end
whatevents=questdlg('Rewarded trials or all trials?','whatevents','Rewarded trials','All trials','Rewarded trials');
if strcmp(whatevents,'All trials')
    maineffect=questdlg('Include RD vs OM main effect?','me','yes','no','no');
else
    maineffect=questdlg('Include HM vs LM main effect?','me','yes','no','no');
end


tic
if strcmp(whatevents,'Rewarded trials')
    if strcmp(maineffect,'no')
        X=Xall;
        if strcmp(whatdistro,'poisson')
            Y=Yallpoiss;
            Yhistory=Yallhistory;
            YSh=YallpoissSh;
            offset=log(0.025);%log(ones(1,length(eventNameskernel)-1).*0.025);
        elseif strcmp(whatdistro,'gaussian')
            Y=Yallgauss;
            YSh=YallgaussSh;
        end
    else
        X=XlvlLILRtrunc;
        if strcmp(whatdistro,'poisson')
            Y=YlvlLILRtruncpoiss;
            Yhistory=YlvlLILRtrunchistory;
            YSh=YlvlLILRtruncpoissSh;
            offset=log(0.025);%log(ones(1,length(eventNameskernel)-1).*0.025);
        end
    end
elseif strcmp(whatevents,'All trials')
    splitorintact=questdlg('Split or Intact?','sori','split','intact','intact');
    if strcmp(splitorintact,'intact')
        X=XLILRtrunc;
    elseif strcmp(splitorintact,'split')
        X=XLILRsplittrunc;
        all_columnstart=splitall_columnstart;
        all_columnstartandend=splitall_columnstartandend;
        interactionstart=splitinteractionstart;
        finalevt=splitfinalevt;
        finalevtcol=splitfinalevtcol;
        eventNameskernel=spliteventNameskernel;
        videoidxs=splitvideoidxs;
        submodels=submodelssplit;
    end
    if strcmp(whatdistro,'poisson')
        Y=YLILRtruncpoiss;
        Yhistory=YLILRtrunchistory;
        YSh=YLILRtruncpoissSh;
        offset=log(0.025);%log(ones(1,length(eventNameskernel)-1).*25);
    elseif strcmp(whatdistro,'gaussian')
        Y=YLILRtruncgauss;
        YSh=YLILRtruncgaussSh;
    end
end

NS=0;
NN=0;

totalNeurons=neuroncounter;

if any(contains(eventNameskernel,'VideoData'))
vcidx=find(strcmp(eventNameskernel,'VideoData'));
end
intidx=[interactionstart,interactionstart+1];
trialtypeidx=find(strcmp(eventNameskernel,'TrialType'));
rango=1:all_columnstartandend(end)-1;
varsinuse=1:length(eventNameskernel);
colidxtoremove=[];
idxused=[];

if exist('vcidx','var')
   if strcmp(videodata,'no')
    colidxtoremove=[colidxtoremove,all_columnstart(vcidx),all_columnstart(vcidx+1)-1];
   idxused=[idxused,vcidx];
   end
end

if strcmp(maineffect,'no')
   colidxtoremove=[colidxtoremove,all_columnstart(intidx(1)):all_columnstartandend(intidx(2)+1)-1];
   idxused=[idxused,intidx];
end

if strcmp(whatevents,'All trials')
    GLMtrials=GLMtrialstrunc;
    if strcmp(splitorintact,'split')
        colidxtoremove=[colidxtoremove,all_columnstart(trialtypeidx)];
        idxused=[idxused,trialtypeidx];
    end
elseif strcmp(whatevents,'Rewarded trials')
    GLMtrials=cellfun(@(x) x(:,all_columnstart(strcmp(eventNameskernel,'RewardNumber'))), X, 'UniformOutput', false);
    colidxtoremove=[colidxtoremove,all_columnstart(trialtypeidx)];
    idxused=[idxused,trialtypeidx];
end
rango(colidxtoremove)=[];
varsinuse(idxused)=[];
submodels(idxused)=[];
submodels=cellfun(@(x) [x(rango)], submodels, 'UniformOutput', false);
submodels=cellfun(@(x) [x,1,1],submodels,'UniformOutput',false);
submodels{end+1}=[ones(1,length(rango)),0,0];
varExp= repmat({NaN(totalNeurons,length(submodels)+1)},1,itmax);
varExpSh=repmat({NaN(totalNeurons,length(submodels)+1)},1,itmax);
predF=repmat({cell(totalNeurons,1)},1,itmax);
kernels=repmat({NaN(totalNeurons,1)},1,itmax);
lambdaVal=repmat({NaN(totalNeurons,1)},1,itmax);
Fstat=repmat({NaN(totalNeurons,length(submodels)+1)},1,itmax);
FstatNull=repmat({NaN(totalNeurons,length(submodels)+1)},1,itmax);
sessionOffsets = cumsum([0; cellfun(@(y) size(y,2), Y(1:end-1))]);
properstart=all_columnstart(strcmp(eventNameskernel,'LeverInsertion'));
if ~isempty(colidxtoremove) %NEED TO CHECK IF THIS IS NECESSARY
moveback=length(colidxtoremove);
all_columnstart(colidxtoremove(1):end)=all_columnstart(colidxtoremove(1):end)-moveback;
end
all_columnstartandend=[all_columnstart,length(rango)];

folds=4;
nsbs=length(submodels);
deltap = NaN(1,nsbs);
for sub=1:nsbs
    deltap(sub)=sum(~submodels{sub});
end


varnegcounter=0;
for session=1:length(Y)
    NS=NS+1;
    trialsavail=unique(GLMtrials{NS});
    sessX=X{NS};
    sessGLMtrials=GLMtrials{NS};
    if strcmp(whatdistro,'poisson')
        staticOffset=repelem(offset,sum(cellfun(@length,kernelssize(1:end-1))));
    end
    if itmax==1
        fixedTrialsavailtouse=trialsavail;
    end
    % Pre-slice Y, YSh, and Yhistory for this session to avoid broadcast warnings
localY        = Y{NS};
localYSh      = YSh{NS};
localYhistory = Yhistory{session};


    parfor it=1:itmax % commented out for debugging, bring back in. parfor it=1:itmax
        localOptions=options;
        if itmax~=1
            if strcmp(whatevents,'All trials')
                trialsavailtouse=sort(trialsavail(randperm(length(trialsavail),50)));
            else
                trialsavailtouse=sort(trialsavail(randperm(length(trialsavail),20)));
            end
        else
            trialsavailtouse=fixedTrialsavailtouse;
        end
        trialbins=ismember(sessGLMtrials,trialsavailtouse);
        if strcmp(whatdistro,'poisson')
            modeloffset = repmat(staticOffset, length(find(trialbins)), 1);
            localOptions.offset = modeloffset;
        end
        Aoriginal = sparse(sessX(trialbins,rango));
        trains = getfolds(round(sessGLMtrials(trialbins,1)*sum(sessX(:,properstart))),folds);
        if any(cellfun(@sum,trains)==length(Aoriginal))
            pause
        end
        %submodels
        Asoriginal={};
        for sub=1:nsbs-1
            At = Aoriginal;
            At(:,submodels{sub}==0)=0;
            Asoriginal{sub} = At;
        end
        Asoriginal{sub+1}=[Aoriginal,zeros(size(Aoriginal,1),2)];
        for neuron=1:size(localY,2)
            NN=sessionOffsets(session)+neuron;

            % if neuron==1
            %     resetter=NN;
            % end



            % varExp{it}(NN,:)= NaN(1,length(submodels)+1);
            % varExpSh{it}(NN,:)=NaN(1,length(submodels)+1);
            % predF{it}(NN,:)=cell(1,1);
            % kernels{it}(NN,:)=NaN(1,1);
            % lambdaVal{it}(NN,:)=NaN(1,1);
            % Fstat{it}(NN,:)=NaN(1,length(submodels)+1);
            % FstatNull{it}(NN,:)=NaN(1,length(submodels)+1);
            % varExpDenoms{it}(NN,:)=NaN(1,length(submodels)+1);
            % varExpDenomSh{it}(NN,:)=NaN(1,length(submodels)+1);
            if R.Bmean(NN)>1
                %cross-validated variance explained
                y=localY(trialbins,neuron);
                YhistNeuron=localYhistory{neuron};
                predfullall=NaN(size(y,1),100);
                predfull=NaN(size(y,1),1);
                foldNLL=NaN(folds,100);
                foldMSE=NaN(folds,100);
                foldlambdas=NaN(folds,100);

                A=[Aoriginal,YhistNeuron(trialbins,:)];
                fitfull=glmnet(A,y,whatdistro,localOptions);
                %if you really wanna do hurdle model
                % if strcmp(hurdleornot,'hurdle')
                %     y_binary= y~=0;
                %     fitk=glmnet(A(y_binary,:),y(y_binary),whatdistro,options);
                %     binaryfitk=glmnet(A,y_binary,'binomial');
                % end
                cvoptions=localOptions;
                cvoptions.nlambda=[];cvoptions.lambda=fitfull.lambda;
                % if strcmp(hurdleornot,'hurdle')
                %     bicvoptions=cvoptions;
                %     bicvoptions.lambda=binaryfitk.lambda;
                %     bicvoptions.offset=[];
                % end
                for fold=1:folds
                    train=trains{fold};
                    test=train==0;
                    if strcmp(whatdistro,'poisson')
                        cvoptions.offset=localOptions.offset(1:sum(train),:);
                    end
                    fitk=glmnet(A(train,:),y(train),whatdistro,cvoptions);
                    %if u really wanna do hurdle model stuff
                    % if strcmp(hurdleornot,'hurdle')
                    %     fitk=glmnet(A(train& y_binary,:),y(train& y_binary),whatdistro,cvoptions);
                    %     binaryfitk=glmnet(A(train,:),(y_binary(train)),'binomial',bicvoptions);
                    % end

                    %                 if strcmp(whatdistro,'poisson') && strcmp(hurdleornot,'hurdle')
                    %                     binary_pred=glmnetPredict(binaryfitk,A(test,:),[],'response');
                    % %                     poiss_pred=ones(size(A(test,:),1),length(fitk.lambda));
                    %                     poiss_pred=glmnetPredict(fitk,A(test & y_binary,:),[],'response',[],cvoptions.offset(test& y_binary));
                    %                     poiss_pred_exp=repmat(poiss_pred,1,length(binaryfitk.lambda));
                    %                     full_rows_poiss_pred_exp=ones(length(y(test)), size(poiss_pred_exp,2));
                    %                     full_rows_poiss_pred_exp(y_binary(test),:)=poiss_pred_exp;
                    %                     binary_pred_exp=repmat(binary_pred,1,length(fitk.lambda));
                    %                     poiss_lambda_val= repmat(fitk.lambda,length(binaryfitk.lambda),1);
                    %                     binomial_lambda_val= repmat(binaryfitk.lambda,length(fitk.lambda),1);
                    %                     combo_lambda=[binomial_lambda_val,poiss_lambda_val];
                    %                     prediction=binary_pred_exp.*full_rows_poiss_pred_exp;
                    if strcmp(whatdistro,'poisson')
                        prediction=glmnetPredict(fitk,A(test,:),[],'response',[],cvoptions.offset(test));
                    elseif strcmp(whatdistro,'gaussian')
                        prediction=glmnetPredict(fitk,A(test,:));
                    end

                    columnidx=~isnan(prediction(1,:));
                    % Negative log-likelihood: NLL = sum(lambda - y*log(lambda))
                    % Add small epsilon to avoid log(0)
                    epsval = 1e-12;
                    predclip = max(prediction, epsval);
                    foldNLL(fold, columnidx) = sum(predclip - y(test) .* log(predclip));
                    foldMSE(fold,columnidx) = mean((y(test,:)-prediction).^2);
                    predfullall(test,columnidx)=prediction;
                end
                %get best lambda with new method
                cvMSE=mean(foldMSE);
                cvNLL=mean(foldNLL);
                [~,bestlambdaidxNLL]= min(cvNLL);
                [~,bestlambdaidxMSE]= min(cvMSE);
                bestlambdaval=cvoptions.lambda(bestlambdaidxNLL);
                % numbfeatures=sum(abs(fitk.beta)>0.001);
                % %find lag in the sigmoid of the number of features to find best lambda index
                % sigmoid = fittype('L / (1 + exp(-k*(x - x0)))', 'independent', 'x', 'dependent', 'y');
                % initial_params = [max(numbfeatures), 0.5, mean(1:100)];
                % [fit_result, gof] = fit([1:length(numbfeatures)]', numbfeatures', sigmoid, 'StartPoint', initial_params);
                % threshold=0.1*fit_result.L;
                % lag_x = round(fminsearch(@(x) abs(feval(fit_result, x) - threshold), fit_result.x0));
                % if lag_x > bestlambdaidx
                %     bestlambdaidx=bestlambdaidx;
                % elseif lag_x < bestlambdaidx
                %     bestlambdaidx=lag_x;
                % end
                % figure;
                % yyaxis left
                % plot(cvMSE)
                % yyaxis right
                % plot(numbfeatures)
                %Determine varExp
                predfull=predfullall(:,bestlambdaidxNLL);
                varExp{it}(NN,1) = 1-var(y-predfull)/var(y);
                SSE = sum((y-predfull).^2);
                predF{it}{NN,1}=predfullall(:,bestlambdaidxNLL);


                %full data to get kernels
                % fullmodelopts=options;
                % fullmodelopts.nlambda=[];fullmodelopts.lambda=bestlambdaval;
                % fitk=glmnet(A,y,whatdistro,fullmodelopts);
                % kernels(NN,1:length(fitk.beta))=fitk.beta;
                kernels{it}(NN,1:length(fitfull.beta))=fitfull.beta(:,bestlambdaidxNLL);
                lambdaVal{it}(NN,1)=fitfull.lambda(bestlambdaidxNLL);

                %
                %shuffled fitk
                ysh=localYSh(trialbins,neuron);
                predfullall=NaN(size(y,1),100);
                predfull=NaN(size(y,1),1);
                foldNLL=NaN(folds,100);

                fitk=glmnet(A,ysh,whatdistro,localOptions);
                cvoptions=localOptions;
                cvoptions.nlambda=[];cvoptions.lambda=fitk.lambda;
                for fold=1:folds
                    train=trains{fold};
                    test=train==0;
                    fitk=glmnet(A(train,:),ysh(train),whatdistro,cvoptions);
                    if strcmp(whatdistro,'poisson')
                        prediction=glmnetPredict(fitk,A(test,:),[],'response',[],cvoptions.offset(test));
                    elseif strcmp(whatdistro,'gaussian')
                        prediction=glmnetPredict(fitk,A(test,:));
                    end
                    columnidx=~isnan(prediction(1,:));
                    % Negative log-likelihood: NLL = sum(lambda - y*log(lambda))
                    % Add small epsilon to avoid log(0)
                    epsval = 1e-12;
                    predclip = max(prediction, epsval);
                    foldNLL(fold, columnidx) = sum(predclip - ysh(test) .* log(predclip));
                    foldMSE(fold,columnidx) = mean((ysh(test,:)-prediction).^2);
                    predfullall(test,columnidx)=prediction;
                end
                %get best lambda with new method
                cvMSE=mean(foldMSE);
                cvNLL=mean(foldNLL);
                [~,bestlambdaidxNLL]= min(cvNLL);
                [~,bestlambdaidxMSE]= min(cvMSE);
                bestlambdaval=cvoptions.lambda(bestlambdaidxNLL);
                % [~,bestlambdaidxs]=min(foldMSE,[],2);
                % bestlambdavals=foldlambdas(sub2ind(size(foldlambdas), (1:size(foldlambdas,1))', bestlambdaidxs));
                predfull=predfullall(:,bestlambdaidxNLL);
                %Determine varExp
                varExpSh{it}(NN,1) = 1-var(ysh-predfull)/var(ysh);
                SSEsh = sum((ysh-predfull).^2);


                %submodels to find unique variance and total variance for each variable
                nv=NaN(1,nsbs);
                nvsh=NaN(1,nsbs);
                SSEsub=NaN(1,nsbs);
                SSEsubsh=NaN(1,nsbs);
                As = cell(nsbs,1);
                for sub = 1:nsbs
                    if sub < nsbs     
                        As{sub} = [ Asoriginal{sub}, YhistNeuron(trialbins,:)];
                    else
                        As{sub}=Asoriginal{sub};
                    end
                    fitk=glmnet(As{sub},y,whatdistro,localOptions);
                    cvoptions=localOptions;
                    cvoptions.nlambda=[];cvoptions.lambda=fitk.lambda;
                    foldNLL=[];
                    for fold=1:folds
                        train=trains{fold};
                        test=train==0;
                        fitk=glmnet(As{sub}(train,:),y(train),whatdistro,cvoptions);
                        if strcmp(whatdistro,'poisson')
                            prediction=glmnetPredict(fitk,As{sub}(test,:),[],'response',[],cvoptions.offset(test));
                        elseif strcmp(whatdistro,'gaussian')
                            prediction=glmnetPredict(fitk,As{sub}(test,:));
                        end
                        columnidx=~isnan(prediction(1,:));
                    % Negative log-likelihood: NLL = sum(lambda - y*log(lambda))
                    % Add small epsilon to avoid log(0)
                    epsval = 1e-12;
                    predclip = max(prediction, epsval);
                    foldNLL(fold, columnidx) = sum(predclip - y(test) .* log(predclip));
                    foldMSE(fold,columnidx) = mean((y(test,:)-prediction).^2);
                    predfullall(test,columnidx)=prediction;
                end
                %get best lambda with new method
                cvMSE=mean(foldMSE);
                cvNLL=mean(foldNLL);
                [~,bestlambdaidxNLL]= min(cvNLL);
                [~,bestlambdaidxMSE]= min(cvMSE);
                    bestlambdaval=cvoptions.lambda(bestlambdaidxNLL);
                    % [~,bestlambdaidxs]=min(foldMSE,[],2);
                    % bestlambdavals=foldlambdas(sub2ind(size(foldlambdas), (1:size(foldlambdas,1))', bestlambdaidxs));
                    numbfeatures=sum(abs(fitk.beta)>0.001);
                    predfull=predfullall(:,bestlambdaidxNLL);
                    if rem(NN,10)==0 predF{it}{NN,1+sub}=predfull; end
                    nv(1,sub) = 1-var(y-predfull)/var(y);
                    SSEsub(sub) = sum((y-predfull).^2);
                end
                %shuffled
                for sub=1:nsbs
                    predfullall=NaN(size(y,1),100);
                    predfull=NaN(size(y,1),1);
                    foldNLL=NaN(folds,100);
                    fitk=glmnet(As{sub},ysh,whatdistro,localOptions);
                    cvoptions=localOptions;
                    cvoptions.nlambda=[];cvoptions.lambda=fitk.lambda;
                    for fold=1:folds
                        train=trains{fold};
                        test=train==0;
                        fitk = glmnet(As{sub}(train,:),ysh(train),whatdistro,cvoptions);
                        if strcmp(whatdistro,'poisson')
                            prediction=glmnetPredict(fitk,As{sub}(test,:),[],'response',[],cvoptions.offset(test));
                        elseif strcmp(whatdistro,'gaussian')
                            prediction=glmnetPredict(fitk,As{sub}(test,:));
                        end
                         columnidx=~isnan(prediction(1,:));
                    % Negative log-likelihood: NLL = sum(lambda - y*log(lambda))
                    % Add small epsilon to avoid log(0)
                    epsval = 1e-12;
                    predclip = max(prediction, epsval);
                    foldNLL(fold, columnidx) = sum(predclip - ysh(test) .* log(predclip));
                    foldMSE(fold,columnidx) = mean((ysh(test,:)-prediction).^2);
                    predfullall(test,columnidx)=prediction;
                end
                %get best lambda with new method
                cvMSE=mean(foldMSE);
                cvNLL=mean(foldNLL);
                [~,bestlambdaidxNLL]= min(cvNLL);
                [~,bestlambdaidxMSE]= min(cvMSE);
                    bestlambdaval=cvoptions.lambda(bestlambdaidxNLL);
                    % [~,bestlambdaidxs]=min(foldMSE,[],2);
                    % bestlambdavals=foldlambdas(sub2ind(size(foldlambdas), (1:size(foldlambdas,1))', bestlambdaidxs));
                    numbfeatures=sum(abs(fitk.beta)>0.001);
                    predfull=predfullall(:,bestlambdaidxNLL);

                    nvsh(1,sub) = 1-var(ysh-predfull)/var(ysh);

                    SSEsubsh(sub) = sum((ysh-predfull).^2);
                end
                varExp{it}(NN,2:nsbs+1) = nv;
                varExpSh{it}(NN,2:nsbs+1) = nvsh;
                Fstat{it}(NN,2:nsbs+1) = ((SSEsub-SSE)./deltap)./(SSE./(length(y)-1));
                FstatNull{it}(NN,2:nsbs+1) = ((SSEsubsh-SSEsh)./deltap)./(SSEsh./(length(y)-1));
            end
        end
    end
    fprintf('Session #%d \n',NS);

end


savestring = 'Full';

if strcmp(whatevents,'All trials')
    forrdstring = 'AT';
elseif strcmp(whatevents,'Rewarded trials')
    forrdstring = 'RD';
end
if options.alpha==1
    reg='lasso';
elseif options.alpha==0
    reg='ridge';
end
if ~exist('splitorintact','var')
    save([regexp(inputsinuse, '(.*?)(?=G)', 'match', 'once'),num2str(binsize*1000),'msinteraction',maineffect,'video',videodata,forrdstring,'trialGLM',reg,whatdistro,savestring,'.mat'],'NN','NS','varsinuse','varExp','Fstat','FstatNull','varExpSh','kernels','lambdaVal','predF','-v7.3');

else
    save([regexp(inputsinuse, '(.*?)(?=G)', 'match', 'once'),num2str(binsize*1000),'msinteraction',maineffect,'video',videodata,forrdstring,splitorintact,'trialGLM',reg,whatdistro,savestring,'.mat'],'NN','NS','varsinuse','varExp','Fstat','FstatNull','varExpSh','kernels','lambdaVal','predF','-v7.3');
end
[~ , ~, stats] = friedman(varExp(~isnan(varExp(:,1)),:));
figure;multcompare(stats);
yticklabels(flip(['Full Model';eventNameskernel(varsinuse)])) 
toc

%% plot colors
clearvars
whichmat=uigetfile('*trialGLM*.mat','X:\Matilde\MatLab');
load (whichmat);
load([regexp(whichmat, '(.*?)(?=2)', 'match', 'once'),'GLMinputs25ms.mat'])
Rtoload=uigetfile(['R',regexp(whichmat, '(.*?)(?=2)', 'match', 'once'),'*.mat'],'X:\Matilde\MatLab');
load(Rtoload);
if contains(whichmat,'videono')
    variables = {'LeverInsertion';'LeverPress';'LeverRetract';'PEntryRD';'PEntrynoRD';'Licks';'FirstInBout';'PriorTrialOutcome';'RewardNumber'};
    endevtidx=find(strcmp(variables,'FirstInBout'));
    varcolors = [turbo(length(variables(1:endevtidx)));0.5 0 0;0.5 0.5 0.5];
    evtsinuse={'LeverInsertion';'LeverPress';'LeverRetract';'PEntryRD';'PEntrynoRD';'Licks';'FirstInBout'};
    colors= [turbo(length(variables(1:endevtidx)))];
elseif contains(whichmat,'videoyes') 
    variables = {'LeverInsertion';'LeverPress';'LeverRetract';'PEntryRD';'PEntrynoRD';'Licks';'FirstInBout';'VideoComponents';'PriorTrialOutcome';'RewardNumber'};
    endevtidx=find(strcmp(variables,'FirstInBout'));
    varcolors = [turbo(length(variables(1:endevtidx)));1 0 .5;0.5 0 0;0.5 0.5 0.5];
    evtsinuse={'LeverInsertion';'LeverPress';'LeverRetract';'PEntryRD';'PEntrynoRD';'Licks';'FirstInBout'};
    colors=[turbo(length(variables(1:endevtidx)))];
end
if contains(whichmat,'AT') && contains(whichmat,'interactionno')
    variables=[variables;'TrialType'];
    varcolors=[varcolors;0.5 0.1 1];
elseif contains(whichmat,'AT') && contains(whichmat,'interactionyes')
    variables=[variables;'TrialType';'LIinteraction';'LRinteraction'];
    varcolors=[varcolors;0.5 0.1 1;0 0 1;1 1 0];
end
if  contains(whichmat,'RD') && contains(whichmat,'interactionyes')
    variables=[variables;'LIinteraction';'LRinteraction'];
    varcolors=[varcolors;0 0 1;1 1 0];
end

if contains(whichmat,'AT') && contains(whichmat,'split')
    if contains(whichmat,'videono')
        variables = {'LeverInsertionRD';'LeverInsertionNoRD'; 'LeverPress';'LeverRetractRD';'LeverRetractNoRD';'PEntryRD';'PEntrynoRD';'Licks';'FirstInBout';'PriorTrialOutcome';'RewardNumber'};
        varcolors = [0.01 0.87 0.02;0.3 0.3 0.3;varcolors(2,:);0.01 0.87 0.02;0.3 0.3 0.3;varcolors(4:end,:); 0.5 0 0; 0.5 0.5 0.5];
    elseif contains(whichmat,'videoyes')
        variables = {'LeverInsertionRD';'LeverInsertionNoRD'; 'LeverPress';'LeverRetractRD';'LeverRetractNoRD';'PEntryRD';'PEntrynoRD';'Licks'; 'FirstInBout';'VideoComponents';'PriorTrialOutcome';'RewardNumber'};
        varcolors = [0.01 0.87 0.02;0.3 0.3 0.3;varcolors(2:4,:);0.01 0.87 0.02;0.3 0.3 0.3;varcolors(6:end-1,:)];%;1 0 .5; 0.5 0 0; 0.5 0.5 0.5];
    end
end
if contains(whichmat,'RD') && contains(whichmat,'interactionno')
    idxtouse=find(ismember(variables,evtsinuse))';
elseif contains(whichmat,'RD') && contains(whichmat,'interactionyes')
    idxtouse=[find(strcmp(eventNameskernel,'LeverInsertion')),find(strcmp(eventNameskernel,'LeverRetract')),interactionstart,interactionstart+1];
elseif contains(whichmat,'AT') && contains(whichmat,'interactionyes') && contains(whichmat,'intact')
    idxtouse=[find(strcmp(eventNameskernel,'LeverInsertion')),find(strcmp(eventNameskernel,'LeverRetract')),interactionstart,interactionstart+1];
elseif contains(whichmat,'AT') && contains(whichmat,'interactionno') && contains(whichmat,'intact')
    idxtouse=[find(strcmp(eventNameskernel,'LeverInsertion')),find(strcmp(eventNameskernel,'LeverRetract'))];
elseif contains(whichmat,'AT') && contains(whichmat,'interactionno') && contains(whichmat,'split')
    idxtouse=[find(strcmp(spliteventNameskernel,'LeverInsertionRD')),find(strcmp(spliteventNameskernel,'LeverInsertionNoRD')),find(strcmp(spliteventNameskernel,'LeverRetractRD')),find(strcmp(spliteventNameskernel,'LeverRetractNoRD'))];
end
% if contains(whichmat,'interactionno')
%     idxtouse=1:finalevt;
% elseif contains(whichmat,'interactionyes')`
%     idxtouse=[1:finalevt,interactionstart,interactionstart+1];
% end

totalNeurons=neuroncounter;
%% plot predicted vs actual
% varExp=varExp{1};
% predFplot=predF{1};
if contains(whichmat,'RD')
    X=Xall;
    if contains(whichmat,'poiss')
        Y=Yallpoiss;
        YSh=YallpoissSh;
        offset=log(ones(1,length(eventNameskernel)-1).*10);
    elseif contains(whichmat,'gauss')
        Y=Yallgauss;
        YSh=YallgaussSh;
    end
elseif contains(whichmat,'AT')
    X=XLILRtrunc;
    if contains(whichmat,'poiss')
        Y=YLILRtruncpoiss;
        YSh=YLILRtruncpoissSh;
        offset=log(offsets);
    elseif contains(whichmat,'gauss')
        Y=YLILRtruncgauss;
        YSh=YLILRtruncgaussSh;
    end
end

predFplot=predF{1}(:,1);
trialidx=all_columnstart(strcmp(eventNameskernel,'RewardNumber'));
q4=find(varExp{1}(:,1)<quantile(varExp{1}(varExp{1}(:,1)>0,1),0.25));
q3=find(varExp{1}(:,1)>=quantile(varExp{1}(varExp{1}(:,1)>0,1),0.25) & varExp{1}(:,1)<quantile(varExp{1}(varExp{1}(:,1)>0,1),0.5));
q2=find(varExp{1}(:,1)>=quantile(varExp{1}(varExp{1}(:,1)>0,1),0.5) & varExp{1}(:,1)<quantile(varExp{1}(varExp{1}(:,1)>0,1),0.75));
q1=find(varExp{1}(:,1)>=quantile(varExp{1}(:,1),0.75));
qneg=find(varExp{1}(:,1)<0);
q1toplot=randsample(q1,1);q2toplot=randsample(q2,1);q3toplot=randsample(q3,1);qnegtoplot=randsample(qneg,1);q4toplot=randsample(q4,1);
neuronsession=repelem(1:length(Y),cellfun(@(x) size(x,2),Y))';
neuroninsession=cell2mat(arrayfun(@(n) (1:n)',cellfun(@(x) size(x,2),Y),'UniformOutput',false));
[bestvar,bestvaridx]=max(varExp{1}(:,1));
figgy=figure;
hold on; plot(Y{neuronsession(bestvaridx),1}(:,neuroninsession(bestvaridx)),'k');plot(predFplot{bestvaridx},'r');
[row, col] = find(X{neuronsession(bestvaridx),1}(:,kernel_zerocolumn([1,3,4,6:finalevt])) == 1);
scatter(row, zeros(size(row))+mean(gca(figgy).YLim), 100, colors(col, :),'|');
scatter(row(col==max(col))-(3/0.05),zeros(size(row(col==max(col))-(3/0.05)))+mean(gca(figgy).YLim), 100, 'k','.')
set(gca, 'XTick',1:100:length(X{neuronsession(bestvaridx)}), 'XTickLabel',compose('%g',Trialts{neuronsession(bestvaridx),1}(1:100:length(X{neuronsession(bestvaridx)}))));
title(['Top Variance Explained (' num2str(round(varExp{1}(bestvaridx,1),3)*100) '%)'])
ylabel('Normalized Firing Rate')
xlabel('Time in Session (s)')
figure;
f=subplot(3, 2,1 );
hold on; plot(Y{neuronsession(bestvaridx),1}(:,neuroninsession(bestvaridx)),'k');plot(predFplot{bestvaridx},'r');
[row, col] = find(X{neuronsession(bestvaridx),1}(:,kernel_zerocolumn([1,3,4,6:finalevt])) == 1);
scatter(row, zeros(size(row))+mean(ylim), 100, colors(col, :),'|');
scatter(row(col==max(col))-(3/0.05),zeros(size(row(col==max(col))-(3/0.05)))+mean(ylim), 100, 'k','.')
set(gca, 'XTick',1:100:length(X{neuronsession(bestvaridx)}), 'XTickLabel',compose('%g',Trialts{neuronsession(bestvaridx),1}(1:100:length(X{neuronsession(bestvaridx)}))));
trialtoplot=randsample(unique(Xall{neuronsession(bestvaridx)}(:,trialidx)),1);
plotlims=[find(Xall{neuronsession(bestvaridx)}(:,trialidx)==trialtoplot,1) find(Xall{neuronsession(bestvaridx)}(:,trialidx)==trialtoplot,1,'last')];
xlim(plotlims); ylim([-1 1])
title(['Top Variance Explained (' num2str(round(varExp{1}(bestvaridx,1),3)*100) '%)'])
ylabel('Normalized Firing Rate')
xlabel('Time in Session (s)')
f=subplot(3, 2,2 );
hold on; plot(Y{neuronsession(q1toplot),1}(:,neuroninsession(q1toplot)),'k');plot(predFplot{q1toplot},'r');
[row, col] = find(X{neuronsession(q1toplot),1}(:,kernel_zerocolumn([1,3,4,6:finalevt])) == 1);
scatter(row, zeros(size(row))+mean(ylim), 100, colors(col, :),'|');
scatter(row(col==max(col))-(3/0.05),zeros(size(row(col==max(col))-(3/0.05)))+mean(ylim), 100, 'k','.')
set(gca, 'XTick',1:100:length(X{neuronsession(q1toplot)}), 'XTickLabel',compose('%g',Trialts{neuronsession(q1toplot),1}(1:100:length(X{neuronsession(q1toplot)}))));
trialtoplot=randsample(unique(Xall{neuronsession(q1toplot)}(:,trialidx)),1);
plotlims=[find(Xall{neuronsession(q1toplot)}(:,trialidx)==trialtoplot,1) find(Xall{neuronsession(q1toplot)}(:,trialidx)==trialtoplot,1,'last')];
xlim(plotlims);
title(['1st Q Explained (' num2str(round(varExp{1}(q1toplot,1),3)*100) '%)'])
ylabel('Normalized Firing Rate')
xlabel('Time in Session (s)')
f=subplot(3, 2,3 );
hold on; plot(Y{neuronsession(q2toplot),1}(:,neuroninsession(q2toplot)),'k');plot(predFplot{q2toplot},'r');
[row, col] = find(X{neuronsession(q2toplot),1}(:,kernel_zerocolumn([1,3,4,6:finalevt])) == 1);
scatter(row, zeros(size(row))+mean(ylim), 100, colors(col, :),'|');
scatter(row(col==max(col))-(3/0.05),zeros(size(row(col==max(col))-(3/0.05)))+mean(ylim), 100, 'k','.')
set(gca, 'XTick',1:100:length(X{neuronsession(q2toplot)}), 'XTickLabel',compose('%g',Trialts{neuronsession(q2toplot),1}(1:100:length(X{neuronsession(q2toplot)}))));
trialtoplot=randsample(unique(Xall{neuronsession(q2toplot)}(:,trialidx)),1);
plotlims=[find(Xall{neuronsession(q2toplot)}(:,trialidx)==trialtoplot,1) find(Xall{neuronsession(q2toplot)}(:,trialidx)==trialtoplot,1,'last')];
xlim(plotlims);
title(['2nd Q Explained ('  num2str(round(varExp{1}(q2toplot,1),3)*100) '%)'])
ylabel('Normalized Firing Rate')
xlabel('Time in Session (s)')
f=subplot(3, 2,4 );
hold on; plot(Y{neuronsession(q3toplot),1}(:,neuroninsession(q3toplot)),'k');plot(predFplot{q3toplot},'r');
[row, col] = find(X{neuronsession(q3toplot),1}(:,kernel_zerocolumn([1,3,4,6:finalevt])) == 1);
scatter(row, zeros(size(row))+mean(ylim), 100, colors(col, :),'|');
scatter(row(col==max(col))-(3/0.05),zeros(size(row(col==max(col))-(3/0.05)))+mean(ylim), 100, 'k','.')
set(gca, 'XTick',1:100:length(X{neuronsession(q3toplot)}), 'XTickLabel',compose('%g',Trialts{neuronsession(q3toplot),1}(1:100:length(X{neuronsession(q3toplot)}))));
trialtoplot=randsample(unique(Xall{neuronsession(q3toplot)}(:,trialidx)),1);
plotlims=[find(Xall{neuronsession(q3toplot)}(:,trialidx)==trialtoplot,1) find(Xall{neuronsession(q3toplot)}(:,trialidx)==trialtoplot,1,'last')];
xlim(plotlims); ylim([-1 1])
title(['3rd Q Explained ('  num2str(round(varExp{1}(q3toplot,1),3)*100) '%)'])
ylabel('Normalized Firing Rate')
xlabel('Time in Session (s)')
f=subplot(3, 2,5 );
hold on; plot(Y{neuronsession(q4toplot),1}(:,neuroninsession(q4toplot)),'k');plot(predFplot{q4toplot},'r');
[row, col] = find(X{neuronsession(q4toplot),1}(:,kernel_zerocolumn([1,3,4,6:finalevt])) == 1);
scatter(row, zeros(size(row))+mean(ylim), 100, colors(col, :),'|');
scatter(row(col==max(col))-(3/0.05),zeros(size(row(col==max(col))-(3/0.05)))+mean(ylim), 100, 'k','.')
set(gca, 'XTick',1:100:length(X{neuronsession(q4toplot)}), 'XTickLabel',compose('%g',Trialts{neuronsession(q4toplot),1}(1:100:length(X{neuronsession(q4toplot)}))));
trialtoplot=randsample(unique(Xall{neuronsession(q4toplot)}(:,trialidx)),1);
plotlims=[find(Xall{neuronsession(q4toplot)}(:,trialidx)==trialtoplot,1) find(Xall{neuronsession(q4toplot)}(:,trialidx)==trialtoplot,1,'last')];
xlim(plotlims); ylim([-1 1])
title(['4th Q Explained ('  num2str(round(varExp{1}(q4toplot,1),3)*100) '%)'])
ylabel('Normalized Firing Rate')
xlabel('Time in Session (s)')
f=subplot(3, 2,6 );
hold on; plot(Y{neuronsession(qnegtoplot),1}(:,neuroninsession(qnegtoplot)),'k');plot(predFplot{qnegtoplot},'r');
[row, col] = find(X{neuronsession(qnegtoplot),1}(:,kernel_zerocolumn([1,3,4,6:finalevt])) == 1);
scatter(row, zeros(size(row))+mean(ylim), 100, colors(col, :),'|');
scatter(row(col==max(col))-(3/0.05),zeros(size(row(col==max(col))-(3/0.05)))+mean(ylim), 100, 'k','.')
set(gca, 'XTick',1:100:length(X{neuronsession(qnegtoplot)}), 'XTickLabel',compose('%g',Trialts{neuronsession(qnegtoplot),1}(1:100:length(X{neuronsession(qnegtoplot)}))));
trialtoplot=randsample(unique(Xall{neuronsession(qnegtoplot)}(:,trialidx)),1);
plotlims=[find(Xall{neuronsession(qnegtoplot)}(:,trialidx)==trialtoplot,1) find(Xall{neuronsession(qnegtoplot)}(:,trialidx)==trialtoplot,1,'last')];
xlim(plotlims);
title(['- Q Explained ('  num2str(round(varExp{1}(qnegtoplot,1),4)*100) '%)'])
ylabel('Normalized Firing Rate')
xlabel('Time in Session (s)')

neurons=[370,83,419,50,128,373,412,277];
plottedevts=[1,3,3,4,6,6,7,8];
kernelssizeusing={kernelssize{[1:7,finalevt]}};
ncount=1;
figure;
for neuron=neurons
    f = subplot(length(neurons)/2, 2, ncount);
    hold on;
    
    % Determine event times for this neuron
    [row, col] = find(X{neuronsession(neuron),1}(:,kernel_zerocolumn([1,3,3,4,6,6,7,finalevt])) == 1);

    % Define threshold for predicted firing in the window
    pred_threshold = 0.1; % <-- adjust this based on your data scale

    % Keep sampling until we find a trial that satisfies both conditions
    valid_trial_found = false;
    while ~valid_trial_found
        evttoplot = randsample(row(col == plottedevts(ncount)), 1);

        % Compute spike window indices relative to the event
        win_idx = round(evttoplot + (kernelssizeusing{ncount}(1)-0.1)/binsize) : ...
                  round(evttoplot + (kernelssizeusing{ncount}(end)+0.1)/binsize);

        % Extract spikes and predicted firing in that window
        spikes_window = Y{neuronsession(neuron),1}(win_idx, neuroninsession(neuron));
        pred_window   = predFplot{neuron}(win_idx);

        % Check both conditions
        if sum(spikes_window) >= 1 && max(pred_window) > pred_threshold
            valid_trial_found = true;
        end
    end

    % Plot once a valid trial is found
    plot(Y{neuronsession(neuron),1}(:,neuroninsession(neuron)),'k');
    plot(predFplot{neuron},'r');

    scatter(row, zeros(size(row)) + mean(ylim), 100, colors(col, :), '|');

    % Compute x-limits in indices
    plotlims_idx = [win_idx(1), win_idx(end)];
    xlim(plotlims_idx);

    % Align x-ticks to kernelssize values
    xticks_idx = win_idx;
    xticklabels_str = arrayfun(@num2str, kernelssizeusing{ncount}(1)-0.1 : binsize : kernelssizeusing{ncount}(end)+0.1, 'UniformOutput', false);
    set(gca, 'XTick', xticks_idx, 'XTickLabel', xticklabels_str);

    lims = gca;
    ylim([-0.1 lims.YLim(end)+1]);

    title(['Neuron ' num2str(neuron) ' Variance Explained (' num2str(round(varExp{1}(neuron,1),4)) ')']);
    ylabel('Normalized Firing Rate');
    xlabel('Time in Session (s)');

    ncount = ncount + 1;
end
figure;
scatter(R.Bmean,varExp{1}(:,1),'k','filled','MarkerFaceAlpha',0.5)
hold on
colors=turbo(length(neurons)+2);
colors(end-3:end-2,:)=[];
scatter(R.Bmean(neurons),varExp{1}(neurons,1),50,colors,'filled');
ylim([0 0.4])
%% plot results of GLM analysis
clear whichq pvalmethod
improvCutoff=0.02;
pcutoffmin=1/totalNeurons;
pcutoff=0.05;
overallCutoff=0.02;
bestit=1;
if contains(whichmat,'Full')
    howtoanalyze='Analyze the whole rewarded trial? (F-score method)';
    savestring = 'Full';
elseif contains(whichmat,'Denoms')
    howtoanalyze='Trim around specific evnets? (Deonoms method)';
    savestring = 'Denoms';
end
if contains(whichmat,'split')
    all_columnstart=splitall_columnstart;
    all_columnstartandend=splitall_columnstartandend;
    interactionstart=splitinteractionstart;
    finalevt=splitfinalevt;
    finalevtcol=splitfinalevtcol;
    eventNameskernel=spliteventNameskernel;
    videoidxs=splitvideoidxs;
    submodels=submodelssplit;
    kernelssize=splitkernelssize;
end
Pvals=repmat({NaN(totalNeurons,size(varExp{1},2)-1)},1,length(varExp));
PvalsNull=repmat({NaN(totalNeurons,size(varExp{1},2)-1)},1,length(varExpSh));
if strcmp(howtoanalyze,'Analyze the whole rewarded trial? (F-score method)')
    pvalmethod=questdlg('What parameter should be used to calculate significance?','p-val method','F-stat','Change in model performance','F-stat');
    if strcmp(pvalmethod,'F-stat')
        for i = 1:length(varExp)
            for n = 1:totalNeurons
                if varExp{i}(n,1) > 0
                    Pvals{i}(n,:) = (sum(FstatNull{i}(varExp{i}(:,1)>0, 2:end) >= Fstat{i}(n,2:end), 1) + 1) ./ (sum(varExp{i}(:,1)>0) + 1);
                    PvalsNull{i}(n,:) = (sum(FstatNull{i}(varExp{i}(:,1)>0, 2:end) >= FstatNull{i}(n,2:end), 1) + 1) ./ (sum(varExpSh{i}(:,1)>0) + 1);
                end
            end
        end
    elseif strcmp(pvalmethod,'Change in model performance')
        improvement=-(varExp(:,2:end)-varExp(:,1));
        varExpShAdj=varExpSh(:,2:end);C
        varExpShAdj(varExpSh(:,2:end)<0)=0;
        improvementSh=-(varExpShAdj-varExpShAdj(:,1));
        for n=1:totalNeurons
            if varExp(n,1)>0
                Pvals(n,:)=(sum(improvementSh(varExp(:,1)>0,:)>=improvement(n,:),1)+1) ./ (sum(varExp(:,1)>0) + 1);
            end
        end
    end
elseif strcmp(howtoanalyze,'Trim around specific evnets? (Deonoms method)')
    pvalmethod=[];
    improvement=-(varExp(:,2:end)-varExpDenoms);
    varExpShAdj=varExpDenomSh;
    varExpShAdj(varExpDenomSh<0)=0;
    improvementSh=-(varExpShAdj-varExpShAdj(:,1));
    for n=1:totalNeurons
        if varExp(n,1)>0
            Pvals(n,:)=(sum(improvementSh(varExp(:,1)>0,:)>=improvement(n,:),1)+1) ./ (totalNeurons + 1);
        end
    end
end
if contains(whichmat,'interactionyes')
    splitorintact=questdlg('Do you want the general events split?','sori','Intact','Split','Intact');
    if strcmp(splitorintact,'Split')
        allorsome=questdlg('Do you want all of the generally modulated neurons or just the not outcome senstivie ones?','whichneur','All','Subset','All');
    end
end

% FstatNullPass=FstatNull(Pvals(:,2)<pcutoff,:);
% for n=1:totalNeurons
%     Pvals(n,3:end)=(sum(FstatNullPass(:,3:end)>Fstat(n,3:end),1)+1) ./ (length(FstatNullPass) + 1);
% end
% minF=prctile(FstatNullPass,100-100*pcutoff,1);

%  improvement=-(varExp(:,2:end)-varExpDenoms);
% improvement=-(varExp-varExp(:,1));
%  varExpShAdj=varExpDenomSh;
%  varExpShAdj(varExpDenomSh<0)=0;
% improvementSh=-(varExpShAdj-varExpShAdj(:,1));
% % % minImp=prctile(improvementSh,100-100*pcutoff,1);
% % Pvals=NaN(size(Fstat)-1);
% for n=1:totalNeurons
%     Pvals(n,:)=(sum(improvementSh>improvement(n,:),1)+1) ./ (totalNeurons + 1);
% end


significant=cellfun(@(x) x<pcutoff,Pvals,'UniformOutput',false);
if contains(whichmat,'100it')
    save([regexp(whichmat, '(.*?)(?=2)', 'match', 'once'),'100itSig'],'significant')
else
        save([regexp(whichmat, '(.*?)(?=2)', 'match', 'once'),'1itSig'],'significant')
end
LIidx=strcmp(variables,'LeverInsertion');
LRidx=strcmp(variables,'LeverRetract');
LIintidx=strcmp(variables,'LIinteraction');
LRintidx=strcmp(variables,'LRinteraction');
[~,varequiv]=ismember(eventNameskernel',variables');

if exist('allorsome','var')
    if strcmp(allorsome, 'Subset')

        significant{bestit}(:,LIidx)=significant{bestit}(:,LIidx) & ~significant{bestit}(:,LIintidx);
        significant{bestit}(:,LRidx)=significant{bestit}(:,LRidx) & ~significant{bestit}(:,LRintidx);
    end
end
significantNull=cellfun(@(x) x<pcutoff,PvalsNull,'UniformOutput',false);
propsacrossit=cellfun(@(x) sum(x)/size(x,1),significant,'UniformOutput',false);
meanprops=mean(reshape(cell2mat(propsacrossit),size(significant,2),[]));
differencesare=cellfun(@(x) sum(abs(x-meanprops)),propsacrossit,'UniformOutput',false);
[~,bestit]=min(cell2mat(differencesare));
co_responsivity = significant{bestit}' * significant{bestit};
nEvents = size(significant{bestit}, 2);
% Convert to table for readable display
co_table = array2table(co_responsivity, 'VariableNames', vertcat(eventNameskernel(varsinuse),'SpikeHistory'), 'RowNames', vertcat(eventNameskernel(varsinuse),'SpikeHistory'));
%significant=improvement>improvCutoff
% LIK = significant(:,1);
% LPK = significant(:,3);
% LRK = significant(:,4);
% PERDK = significant(:,5);
% PEK = significant(:,6);
% LicksK = significant(:,7);
% Lick1K = significant(:,8);
% LicklastK = significant(:,9);
% FirstInBoutk = significant(:,10);
% EndRDK = significant(:,11);


if contains(whichmat,'100it')
    itsignificant=cellfun(@(x) x<pcutoff,Pvals,'UniformOutput',false);
    itsigprop=cellfun(@(x) sum(x)./totalNeurons,itsignificant,'UniformOutput',false);
    itsigprop=cell2mat(itsigprop);
    itsigprop=reshape(itsigprop,size(itsignificant{1},2),100)';
    meanprop=mean(itsigprop);
    % itsigprop_centered=itsigprop-mean(itsigprop);
    % itsigprop_shifted=itsigprop_centered + (1:15);
    figure;b=bar(meanprop);
    b.FaceColor = 'flat';
    for v=1:length(variables)
        b.CData(v,:)=varcolors(v,:);
    end
    hold on;
    xvals = repmat(1:size(Pvals{1}, 2), 100, 1);  % 100 x 15
    xvals = xvals(:);                             % 1500 x 1
    yvals = itsigprop(:);                         % 1500 x 1
    scatter(xvals, yvals, 'k.')
    ylim([0 0.8])
    xticklabels(eventNameskernel(varsinuse))
    title(regexp(whichmat, '(.*?)(?=2)', 'match', 'once'))
else
    %selective = Pvals< pcutoff;%& varExp(:,1)>overallCutoff;
    selective = significant;% & significant(:,2);
    %selective = improvement>0.02;
    %selective = Fstat>1;



    figure;
    title(regexp(whichmat, '(.*?)(?=2)', 'match', 'once'))
    b=bar(sum(cell2mat(significant),1)./totalNeurons);
    b.FaceColor = 'flat';
    for v=1:length(variables)
        b.CData(v,:)=varcolors(v,:);
    end
    xlim([0.5 length(variables)+0.5]);
    ylabel('fraction of neurons');
    xticks(1:length(variables));
    xticklabels(variables);
    xtickangle(45);
    title(['selective neurons',savestring]);
    if ~isempty(pvalmethod)
        subtitle(pvalmethod)
    end
    ylim([0 1]);
end
for v=1:length(variables)
    outcomes = [significant{bestit}(:,v); significantNull{bestit}(:,v)];  % logical outcomes
    groups = [repmat("real", numel(significant{bestit}(:,v)), 1); repmat("null", numel(significantNull{bestit}(:,v)), 1)];
    [tbl, chi, p] = crosstab(groups, outcomes);
    p_val(v)=p;
    chi_all(v)=chi;
end
%corrected p
alpha2=0.05;
corrected_alpha=alpha2/length(variables)
significant_idx=p_val<corrected_alpha;
bonf_correctedp=min(p_val * length(p_val), 1);
fprintf('Bonferroni corrected alpha = %.4f\n\n', corrected_alpha);

for i = 1:length(variables)
    sig_str = 'NO';
    if p_val(i) < corrected_alpha
        sig_str = 'YES';
    end
    fprintf('Event: %s, p = %.4f, Significant after correction? %s\n', variables{i}, p_val(i), sig_str);
end

% % plot neurons in each category
window=[-5 5];
binTimes= window(1)+0.01/2:0.01:window(2)-0.01/2; %do not change this bin size
plotWindow=[-1 1];
plotBins=find(binTimes>plotWindow(1) & binTimes<plotWindow(2));


% plotting modulated neurons

directions = [1 -1];


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
regioncolors=[ 0,0.9336,0.7773;0.2578,0.9336,0;0.8203,0.0664,0.9258];
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

direction={};
directionfull={};
variable={};
if contains(whichmat,'RD')
    [~,Requivalents]=ismember(variables(1:find(strcmp(variables,'FirstInBout'))),R.Erefnames);
elseif contains(whichmat,'AT')
    if contains(whichmat,'intact')
        compvars={'LeverInsertion';'LeverRetract';'LeverInsertionRD';'LeverInsertionNoRD';'LeverRetractRD';'LeverRetractNoRD'};
        [~,Requivalents]=ismember(compvars,R.Erefnames);
    else
        [~,Requivalents]=ismember(variables(idxtouse),R.Erefnames);
    end
end
% pres={'LeverPress1', 'PEntryRD'};
% [~,preequivs]= ismember(pres,R.Erefnames);
% Requivalents(contains(variables, regexpPattern("Pre[A-Z]")))=preequivs;
kernelsit=kernels{bestit};
compactivity=cell(4,1);
    plotplacement=1;
        betas=figure;
        set(betas, 'Renderer', 'painters');
        sgtitle(regexp(whichmat, '(.*?)(?=2)', 'match', 'once'))
        [magma,inferno,plasma,viridis]=colormaps;
        colormap(plasma);
        line1=[-0.05 0.05];
        toppad=0.005;
        bottompad=0.005;
        clims=[-1 1];
        if contains(whichmat,'interactionyes')
            ylimpos=[-0.2 0.5];
            ylimneg=[-0.2 0.125];
        else
            ylimpos=[-0.35 1];
            ylimneg=[-0.65 0.3];
        end
    Rcount=1;
    candidateys=[];
    candidatemin=[];
    candidatemax=[];
    ax=[];
    linespos=[];
    linesneg=[];
    for GLMevt=idxtouse
        up=[];
        down=[];
                ax(Rcount)=subplot(2,size(idxtouse,2),0+plotplacement);
                activityfull= cellfun(@(x,y) y(x,all_columnstartandend(GLMevt):all_columnstartandend(GLMevt)-1+length(kernelssize{GLMevt})), cellfun(@(x) x(:,varequiv(GLMevt)),significant,'UniformOutput',false),kernels,'UniformOutput',false);
                fulldirections=cellfun(@(y) y(:,all_columnstartandend(GLMevt):all_columnstartandend(GLMevt)-1+length(kernelssize{GLMevt})),kernels,'UniformOutput',false);
                if contains(whichmat,'100it')
                    activity=cellfun(@(x) mean(x,2),activityfull,'UniformOutput',false);  
                else
                    activity=activityfull;
                end
                plotactivity=activityfull{bestit};
                plotwindow=1:length(all_columnstartandend(GLMevt):all_columnstartandend(GLMevt+1)-1);
                %plotactivity= (activity-mean((activity),2))./std(activity,[],2);
                %plotactivity= (activity-min(activity,[],2))./(max(activity,[],2)-min(activity,[],2));
                included=cellfun(@(x) x(:,varequiv(GLMevt)),significant,'UniformOutput',false);
                    if kernelssize{GLMevt}(1) == 0 %&& kernelssize{GLMevt}((length(kernelssize{GLMevt})+1)/2) ~= 0
                        sortActivity=cellfun(@(x) x(:,find(kernelssize{GLMevt}==0):find(kernelssize{GLMevt}==0)+10),activityfull,'UniformOutput',false);
                        sortActivityfull=cellfun(@(x) x(:,find(kernelssize{GLMevt}==0):find(kernelssize{GLMevt}==0)+10),fulldirections,'UniformOutput',false);
                    elseif  kernelssize{GLMevt}(end) == 0
                        sortActivity=cellfun(@(x) x(:,find(kernelssize{GLMevt}==0):-1:find(kernelssize{GLMevt}==0)-20),activityfull,'UniformOutput',false);
                        sortActivityfull=cellfun(@(x) x(:,find(kernelssize{GLMevt}==0):-1:find(kernelssize{GLMevt}==0)-20),fulldirections,'UniformOutput',false);
                  
                    elseif ~any(kernelssize{GLMevt}==0)
                        sortActivity=cellfun(@(x) x(:,length(kernelssize{GLMevt}):-1:find(kernelssize{GLMevt}==(kernelssize{GLMevt}(1)+kernelssize{GLMevt}(end))/2)),activityfull,'UniformOutput',false);
                     sortActivityfull=cellfun(@(x) x(:,length(kernelssize{GLMevt}):-1:find(kernelssize{GLMevt}==(kernelssize{GLMevt}(1)+kernelssize{GLMevt}(end))/2)),fulldirections,'UniformOutput',false);
                   
                    else
                        sortActivity=cellfun(@(x) x(:,find(kernelssize{GLMevt}==0)-floor(length(kernelssize{GLMevt})/10):find(kernelssize{GLMevt}==0)+ceil(length(kernelssize{GLMevt})/10)),activityfull,'UniformOutput',false);
                    sortActivityfull=cellfun(@(x) x(:,find(kernelssize{GLMevt}==0)-floor(length(kernelssize{GLMevt})/10):find(kernelssize{GLMevt}==0)+ceil(length(kernelssize{GLMevt})/10)),fulldirections,'UniformOutput',false);
                    
                    end
                    variable{Rcount}=cellfun(@(x) mean(x,2),sortActivity,'UniformOutput',false);
                    direction{Rcount} = cellfun(@(x) sign(x),variable{Rcount},'UniformOutput',false);
                    variablefull{Rcount}=cellfun(@(x) mean(x,2),sortActivityfull,'UniformOutput',false);
                    tmpvar=cell2mat(variablefull{Rcount});
                    tmpvar(cell2mat(included)==0,:)=0;
                    variablefull{Rcount}={tmpvar};
                    directionfull{Rcount} = cellfun(@(x) sign(x),variablefull{Rcount},'UniformOutput',false);

                [~,sortOrder] = cellfun(@(x) sort(x,'descend'), variable{Rcount},'UniformOutput',false);
                imagesc(plotactivity(sortOrder{bestit},:));
               
                candidatemin(Rcount)=min(clim);
                candidatemax(Rcount)=max(clim);
                    if ~isempty(find(kernelssize{GLMevt}==0))
                        xline(find(kernelssize{GLMevt}==0),'w')
                    end
                xticks([])
                title({[variables{varequiv(idxtouse(Rcount))},' neurons'],[num2str(round(sum(significant{bestit}(varExp{bestit}(:,1)>0,varequiv(GLMevt)))/totalNeurons*100)),'% of neurons']})
                yticks([1, sum(significant{bestit}(varExp{bestit}(:,1)>0,varequiv(GLMevt)))])
                activityline=activity;
                if contains(whichmat,'AT')
                    compactivity{Rcount}=activity;
                end
                for d=1:2
                    sel = cellfun(@(x) x==directions(d), direction{Rcount},'UniformOutput',false);

                        if contains(whichmat,'interactionyes')
                            if d==1
                                linespos(Rcount)=subplot(4,size(idxtouse,2),size(idxtouse,2)+d*size(idxtouse,2)+plotplacement);
                            elseif d==2
                                linesneg(Rcount)=subplot(4,size(idxtouse,2),size(idxtouse,2)+d*size(idxtouse,2)+plotplacement);
                            end
                        else
                            if d==1
                                linespos(Rcount)=subplot(4,size(idxtouse,2),size(idxtouse,2)+d*size(idxtouse,2)+plotplacement);
                            elseif d==2
                                linesneg(Rcount)=subplot(4,size(idxtouse,2),size(idxtouse,2)+d*size(idxtouse,2)+plotplacement);
                            end
                        end
                        title([num2str(round(sum(sel{bestit})/sum(significant{bestit}(varExp{bestit}(:,1)>0,varequiv(GLMevt)))*100)),'% of modulated'])
                        hold on;
      
                        if exist('whichq','var')
                            if strcmp(whichq,'By Animal') & strcmp(animaldivide,'no')
                                for rat=1:max(ratidx)
                                    SelPlot= sel & strcmp(R.Subject(included,1),names(rat));

                                    plot([0 0],[line1],':','color','k','linewidth',0.75)
                                    avg=mean(activityline(SelPlot,:),'omitnan');
                                    SE= nanste(activityline(SelPlot,:),1);
                                    color=colord(rat,:);
                                    plot(avg,'color',color,'linewidth',1)
                                    if sum(SelPlot)>1
                                        up = avg+SE;
                                        down = avg-SE;

                                        % patch([plotBinTimes,plotBinTimes(end:-1:1)],[up,avg(end:-1:1)],varcolors{GLMevt},'EdgeColor','none');alpha(alph);
                                        % patch([plotBinTimes,plotBinTimes(end:-1:1)],[down,avg(end:-1:1)],varcolors{GLMevt},'EdgeColor','none');alpha(alph);

                                        hold on;
                                        patch([plotwindow,plotwindow(end:-1:1)],[up,avg(end:-1:1)],color,'EdgeColor','none');alpha(0.5);
                                        patch([plotwindow,plotwindow(end:-1:1)],[down,avg(end:-1:1)],color,'EdgeColor','none');alpha(0.5);
                                    end
                                end
                                % axis([1 size(activity,2) min(min(down))-0.005 max(max(up))+0.005]);
                            elseif strcmp(whichq,'By Animal') & strcmp(animaldivide,'yes')
                                for ratgroup=1:max(proportionidx(included))
                                    SelPlot= sel & proportionidx(included)==ratgroup;

                                    plot([0 0],[line1],':','color','k','linewidth',0.75)
                                    avg=mean(activityline(SelPlot,:),'omitnan');
                                    SE= nanste(activityline(SelPlot,:),1);
                                    color=proportioncolors(ratgroup,:);
                                    plot(avg,'color',color,'linewidth',1)
                                    if sum(SelPlot)>1
                                        up = avg+SE;
                                        down = avg-SE;

                                        % patch([plotBinTimes,plotBinTimes(end:-1:1)],[up,avg(end:-1:1)],varcolors{GLMevt},'EdgeColor','none');alpha(alph);
                                        % patch([plotBinTimes,plotBinTimes(end:-1:1)],[down,avg(end:-1:1)],varcolors{GLMevt},'EdgeColor','none');alpha(alph);

                                        hold on;
                                        patch([plotwindow,plotwindow(end:-1:1)],[up,avg(end:-1:1)],color,'EdgeColor','none');alpha(0.5);
                                        patch([plotwindow,plotwindow(end:-1:1)],[down,avg(end:-1:1)],color,'EdgeColor','none');alpha(0.5);
                                    end
                                end
                                % axis([1 size(activity,2) min(min(down))-0.005 max(max(up))+0.005]);
                            elseif strcmp(whichq,'By Sex')
                                activitylinelocal=cell2mat(activityline);
                                for sex=[1 2]
                                    SelPlot= sel{bestit} & strcmp(R.Subject(included{bestit},2),sexidx{sex});

                                    plot([0 0],[line1],':','color','k','linewidth',0.75)
                                    
                                    avg=mean(activitylinelocal(SelPlot,:),'omitnan');
                                    SE= nanste(activitylinelocal(SelPlot,:),1);
                                    color=sexcolors(sex,:);
                                    plot(avg,'color',color,'linewidth',1)
                                    if sum(SelPlot)>1
                                        up = avg+SE;
                                        down = avg-SE;

                                        % patch([plotBinTimes,plotBinTimes(end:-1:1)],[up,avg(end:-1:1)],varcolors{GLMevt},'EdgeColor','none');alpha(alph);
                                        % patch([plotBinTimes,plotBinTimes(end:-1:1)],[down,avg(end:-1:1)],varcolors{GLMevt},'EdgeColor','none');alpha(alph);

                                        hold on;
                                        patch([plotwindow,plotwindow(end:-1:1)],[up,avg(end:-1:1)],color,'EdgeColor','none');alpha(0.5);
                                        patch([plotwindow,plotwindow(end:-1:1)],[down,avg(end:-1:1)],color,'EdgeColor','none');alpha(0.5);
                                    end
                                end
                                % axis([1 size(activity,2)  min(min(down))-0.005 max(max(up))+0.005]);
                            elseif strcmp(whichq,'By Region')
                                for region=1:3
                                    SelPlot= sel & strcmp(R.Ninfo(included,4),regions{region});

                                    plot([0 0],[line1],':','color','k','linewidth',0.75)
                                    avg=mean(activityline(SelPlot,:),'omitnan');
                                    SE= nanste(activityline(SelPlot,:),1);
                                    color=regioncolors(region,:);
                                    plot(avg,'color',color,'linewidth',1)
                                    if sum(SelPlot)>1
                                        up = avg+SE;
                                        down= avg-SE;

                                        % patch([plotBinTimes,plotBinTimes(end:-1:1)],[up,avg(end:-1:1)],varcolors{GLMevt},'EdgeColor','none');alpha(alph);
                                        % patch([plotBinTimes,plotBinTimes(end:-1:1)],[down,avg(end:-1:1)],varcolors{GLMevt},'EdgeColor','none');alpha(alph);

                                        hold on;
                                        patch([plotwindow,plotwindow(end:-1:1)],[up,avg(end:-1:1)],color,'EdgeColor','none');alpha(0.5);
                                        patch([plotwindow,plotwindow(end:-1:1)],[down,avg(end:-1:1)],color,'EdgeColor','none');alpha(0.5);
                                    end
                                end
                                % axis([1 size(activity,2) min(min(down))-0.005 max(max(up))+0.005]);
                            end
                        end
                        if strcmp(additional,'All') || strcmp(whichq,'By Animal')
                            plot([0 0],[line1],':','color','k','linewidth',0.75)
                            if contains(whichmat,'100it')
                                fulldata=cellfun(@(x,y) mean(x(y,:),1,'omitnan'),activityfull,sel,'UniformOutput',false);
                               
                                avg= mean(cell2mat(fulldata'),'omitnan');
                                SE= std(cell2mat(fulldata'),'omitnan');
                            else
                                avg=mean(activityfull{bestit}(sel{bestit},:),'omitnan');
                                SE= nanste(activityfull{bestit}(sel{bestit},:),1);
                            end
                            up = avg+SE;
                            down= avg-SE;
                            if contains(whichmat,'interactionyes') && contains(variables{varequiv(idxtouse(Rcount))},{'LIinteraction','LRinteraction'}) %| strcmp(splitorintact,'Split')
                                avgRD=mean(activity1(sel,:),'omitnan');
                                SERD= nanste(activity1(sel,:),1);
                                upRD = avgRD+SERD;
                                downRD= avgRD-SERD;
                                avgOM=mean(activity2(sel,:),'omitnan');
                                SEOM= nanste(activity2(sel,:),1);
                                upOM = avgOM+SEOM;
                                downOM= avgOM-SEOM;
                                plot3=plot(avgRD,'g','linewidth',1);
                                plot4=plot(avgOM,'color',[0.7 0.7 0.7],'linewidth',1);
                                p31=patch([plotwindow,plotwindow(end:-1:1)],[upRD,avgRD(end:-1:1)],'g','EdgeColor','none');alpha(0.5);
                                p32=patch([plotwindow,plotwindow(end:-1:1)],[downRD,avgRD(end:-1:1)],'g','EdgeColor','none');alpha(0.5);
                                p41=patch([plotwindow,plotwindow(end:-1:1)],[upOM,avgOM(end:-1:1)],[0.7 0.7 0.7],'EdgeColor','none');alpha(0.5);
                                p42=patch([plotwindow,plotwindow(end:-1:1)],[downOM,avgOM(end:-1:1)],[0.7 0.7 0.7],'EdgeColor','none');alpha(0.5);
                            elseif contains(whichmat,'interactionyes') && strcmp(splitorintact,'Split')
                                % avgRD=mean(activityRD(sel,:),'omitnan');
                                % SERD= nanste(activityRD(sel,:),1);
                                % upRD = avgRD+SERD;
                                % downRD= avgRD-SERD;
                                avgHM=mean(activityHM(sel,:),'omitnan');
                                SEHM= nanste(activityHM(sel,:),1);
                                upHM = avgHM+SEHM;
                                downHM= avgHM-SEHM;
                                avgLM=mean(activityLM(sel,:),'omitnan');
                                SELM= nanste(activityLM(sel,:),1);
                                upLM = avgLM+SELM;
                                downLM= avgLM-SELM;
                                avgOM=mean(activity2(sel,:),'omitnan');
                                SEOM= nanste(activity2(sel,:),1);
                                upOM = avgOM+SEOM;
                                downOM= avgOM-SEOM;
                                plot3=plot(avgHM,'b','linewidth',1);
                                plot3=plot(avgLM,'m','linewidth',1);
                                plot4=plot(avgOM,'color',[0.7 0.7 0.7],'linewidth',1);
                                p31=patch([plotwindow,plotwindow(end:-1:1)],[upHM,avgHM(end:-1:1)],'b','EdgeColor','none');alpha(0.5);
                                p32=patch([plotwindow,plotwindow(end:-1:1)],[downHM,avgHM(end:-1:1)],'b','EdgeColor','none');alpha(0.5);
                                p51=patch([plotwindow,plotwindow(end:-1:1)],[upLM,avgLM(end:-1:1)],'m','EdgeColor','none');alpha(0.5);
                                p52=patch([plotwindow,plotwindow(end:-1:1)],[downLM,avgLM(end:-1:1)],'m','EdgeColor','none');alpha(0.5);
                                p41=patch([plotwindow,plotwindow(end:-1:1)],[upOM,avgOM(end:-1:1)],[0.7 0.7 0.7],'EdgeColor','none');alpha(0.5);
                                p42=patch([plotwindow,plotwindow(end:-1:1)],[downOM,avgOM(end:-1:1)],[0.7 0.7 0.7],'EdgeColor','none');alpha(0.5);
                            else
                                plot3=plot(avg,'color',varcolors(varequiv(GLMevt),:),'linewidth',1);
                                hold on;
                                patch([plotwindow,plotwindow(end:-1:1)],[up,avg(end:-1:1)],varcolors(varequiv(GLMevt),:),'EdgeColor','none');alpha(0.5);
                                patch([plotwindow,plotwindow(end:-1:1)],[down,avg(end:-1:1)],varcolors(varequiv(GLMevt),:),'EdgeColor','none');alpha(0.5);
                            end


                            if exist('animaldivide','var')
                                uistack(plot3,'bottom')
                            end
                        end
                        
                            xlim([1 length(kernelssize{GLMevt})])
                            tickidx=[1 length(kernelssize{GLMevt})];
                            xticks(tickidx)
                            %xticks(1:((length(kernelssize{GLMevt})-1)/2)/2-1:length(kernelssize{GLMevt}))
                            xtickangle(45);
                            xticklabels(kernelssize{GLMevt}(tickidx))
                            %xticklabels(kernelssize{GLMevt}(1:((length(kernelssize{GLMevt})-1)/2)/2-1:length(kernelssize{GLMevt})))
                            if ~isempty(find(kernelssize{GLMevt}==0))
                                xline(find(kernelssize{GLMevt}==0),'k:')
                            end
                        yline(0,'k:')
                        if d==1
                            candidateyspos(Rcount,:)=ylim;

                        elseif d==2
                            candidateysneg(Rcount,:)=ylim;
                        end
                end
            if contains(whichmat,'AT') && contains(whichmat,'intact') && contains(variables{idxtouse(Rcount)},{'LIinteraction','LRinteraction'})
                plotplacement=plotplacement+2;
            else
                plotplacement=plotplacement+1;
            end
            Rcount=Rcount+1;
    end
            figure(betas)
            for eoi=[1 3]
                [~,p,~,stats]=ttest2(compactivity{eoi},compactivity{eoi+1},'Dim',1);
                t_vals=stats.tstat;
                alph=0.05;
                nTests=size(compactivity{eoi},2);
                bonf_thresh=alph/nTests;
                sig_bins=find(p<bonf_thresh);
                scatter(linespos(eoi+1),sig_bins,repelem(0.1,size(sig_bins,2)),'k*')
            end
            for subs=1:length(ax)
                clim(ax(subs),[clims])
            end
            for subs=1:length(linespos)
                ylim(linespos(subs),[ylimpos])
            end
            for subs=1:length(linesneg)
                ylim(linesneg(subs),[ylimneg])
            end
            % % === Raw overlap (intersection) ===
            % intersect_counts = significant{bestit}' * significant{bestit};  % Each (i,j) = # neurons modulated by both i and j
            %
            % % === Union counts ===
            % event_totals = sum(significant{bestit}, 1);  % 1 x nEvents
    % union_counts = event_totals' + event_totals - intersect_counts;  % nEvents x nEvents
    %
    % % === Jaccard index ===
    % jaccard_matrix = intersect_counts ./ union_counts;
    %
    % % === Conditional overlap matrix: P(i | j) = intersect(i,j) / total(j) ===
    % conditional_matrix = bsxfun(@rdivide, intersect_counts, event_totals);  % Each column is denominator
    % % Set columns with 0 in denominator to NaN
    % conditional_matrix(:, event_totals == 0) = NaN;
    %
    % % === Convert to tables ===
    % eventNames = eventNameskernel(varsinuse);
    %
    % % Raw counts
    % raw_table = array2table(intersect_counts, ...
    %     'VariableNames', eventNames, ...
    %     'RowNames', eventNames);
    %
    % % Jaccard index (rounded for display, optional)
    % jaccard_table = array2table(jaccard_matrix, ...
    %     'VariableNames', eventNames, ...
    %     'RowNames', eventNames);
    %
    % % Conditional overlap table
    % conditional_table = array2table(conditional_matrix, ...
    %     'VariableNames', eventNames, ...
    %     'RowNames', eventNames);
    %
    % % === Display ===
    % disp('Raw Overlap Counts (Number of Neurons Modulated by Both Events):')
    % disp(raw_table)
    %
    % disp('Jaccard Index Table (Symmetric Similarity of Modulated Sets):')
    % disp(jaccard_table)
    %
    % disp('Conditional Overlap Table (Asymmetric Proportion of j in i):')
    % disp(conditional_table)


    [number,g]=groupcounts(R.Ninfo(:,4));
    table(g,number)

    %%
    % correlation between activity and LP1
   baselineOffset = 80;  % number of bins before LI marking trial start

LIeventidx = cellfun(@(x) [ ...
    sum(x(:,all_columnstart(1):all_columnstart(2)-1), 2), ...
    max(cumsum(x(:,all_columnstart(1))==1) - 1, 0) + 1  % shift back by 1 for baseline bins
], XLILRall, 'UniformOutput', false);
LIactivitymean = cell(size(YLILRallpoiss));

for sess = 1:numel(YLILRallpoiss)

    y = YLILRallpoiss{sess};        % bins x neurons
    li = LIeventidx{sess};      % bins x 2 (LI flag, trial number)

    trials = unique(li(:,2));
    nNeurons = size(y,2);
    nTrials = numel(trials);

    out = nan(nTrials, nNeurons);

    for t = 1:nTrials

        trialIdx = li(:,2)==trials(t);

        LIidx       = trialIdx & (li(:,1)==1);
        baselineIdx = trialIdx & (li(:,1)==0>LIidx);   % adjust if baseline coded differently
        baseline = y(baselineIdx(1:end-10),:);
        LIbins   = y(LIidx,:);

        mu  = mean(baseline,1);
        sig = std(baseline,[],1);

        zLI = (LIbins - mu) ./ sig;

        out(t,:) = mean(zLI,1);

    end

    LIactivitymean{sess} = out;   % trials x neurons

end


% Preallocate
nSessions = numel(LIactivitymean);
corrCell = cell(nSessions,1);    % correlation coefficients
pvalCell = cell(nSessions,1);    % p-values

for sess = 1:nSessions
    liMat = LIactivitymean{sess};   % trials x neurons
    lpLat = LP1latencyLILRall{sess};      % vector of trial latencies

  
    nNeurons = size(liMat,2);
    sessCorr = NaN(1,nNeurons);
    sessP = NaN(1,nNeurons);

    for n = 1:nNeurons
        % Spearman correlation with p-value
        [R,P] = corr(liMat(:,n), lpLat, 'Type', 'Spearman', 'Rows','complete');
        sessCorr(n) = R;
        sessP(n) = P;
    end

    corrCell{sess} = sessCorr;   % 1 x neurons
    pvalCell{sess} = sessP;      % 1 x neurons
end
allNeuronsP=[pvalCell{:}]';
pBonf = allNeuronsP * length(allNeuronsP);
sigBonf = pBonf < 0.05;
allNeuronscorr=[corrCell{:}]';
significant_all=allNeuronsP<0.05;
figure;subplot(1,2,1);histogram(allNeuronsP,20);subplot(1,2,2);histogram(allNeuronscorr)

    %%
    % correlation between activity and LP1, for those responsive to LI_type
   baselineOffset = 80;  % number of bins before LI marking trial start

LIeventidx = cellfun(@(x) [ ...
    sum(x(:,all_columnstart(1):all_columnstart(2)-1), 2), ...
    max(cumsum(x(:,all_columnstart(1))==1) - 1, 0) + 1  % shift back by 1 for baseline bins
], XLILRall, 'UniformOutput', false);
LIactivitymean = cell(size(YLILRallpoiss));

for sess = 1:numel(YLILRallpoiss)

    y = YLILRallpoiss{sess};        % bins x neurons
    li = LIeventidx{sess};      % bins x 2 (LI flag, trial number)

    trials = unique(li(:,2));
    nNeurons = size(y,2);
    nTrials = numel(trials);

    out = nan(nTrials, nNeurons);

    for t = 1:nTrials

        trialIdx = li(:,2)==trials(t);

        LIidx       = trialIdx & (li(:,1)==1);
        baselineIdx = trialIdx & (li(:,1)==0>LIidx);   % adjust if baseline coded differently
        baseline = y(baselineIdx(1:end-10),:);
        LIbins   = y(LIidx,:);

        mu  = mean(baseline,1);
        sig = std(baseline,[],1);

        zLI = (LIbins - mu) ./ sig;

        out(t,:) = mean(zLI,1);

    end

    LIactivitymean{sess} = out;   % trials x neurons

end


% Preallocate
nSessions = numel(LIactivitymean);
corrCell = cell(nSessions,1);    % correlation coefficients
pvalCell = cell(nSessions,1);    % p-values
neuroncounter=0;
datafvs=cell(nNeurons,2);

for sess = 1:nSessions
    liMat = LIactivitymean{sess};   % trials x neurons
    lpLat = LP1latencyLILRall{sess};      % vector of trial latencies

  
    nNeurons = size(liMat,2);
    sessCorr = NaN(1,nNeurons);
    sessP = NaN(1,nNeurons);

 for n = 1:nNeurons
      pvalCell{sess}=NaN(1,nNeurons);
      corrCell{sess}=NaN(1,nNeurons);
      if significant{1}(neuroncounter+n,10)==1
          datafvs{neuroncounter+n,1}=liMat(:,n);
          datafvs{neuroncounter+n,2}=lpLat;
          % Spearman correlation with p-value
          [R,P] = corr(liMat(:,n), lpLat, 'Type', 'Spearman', 'Rows','complete');
          sessCorr(n) = R;
          sessP(n) = P;
     end

     corrCell{sess} = sessCorr;   % 1 x neurons
     pvalCell{sess} = sessP;      % 1 x neurons
 end
neuroncounter=neuroncounter+nNeurons;
end
datafvs=datafvs(~cellfun(@isempty, datafvs(:,1)), :);
allNeuronsP_type=[pvalCell{:}]';
pBonf = allNeuronsP_type * length(allNeuronsP_type);
sigBonf = pBonf < 0.05;
allNeuronscorr_type=[corrCell{:}]';
significant_type=allNeuronsP_type<0.05;
figure;sgtitle('Neurons Encoding LI_t_y_p_e');subplot(1,2,1);histogram(allNeuronsP_type,20);xlabel('P-val');ylabel('Count');subplot(1,2,2);histogram(allNeuronscorr_type);xlabel('Corr');ylabel('Count');

    %%
    % correlation between activity and LP1
   baselineOffset = 80;  % number of bins before LI marking trial start

LIeventidx = cellfun(@(x) [ ...
    sum(x(:,all_columnstart(1):all_columnstart(2)-1), 2), ...
    max(cumsum(x(:,all_columnstart(1))==1) - 1, 0) + 1  % shift back by 1 for baseline bins
], XLILRall, 'UniformOutput', false);
LIactivitymean = cell(size(YLILRallpoiss));

for sess = 1:numel(YLILRallpoiss)

    y = YLILRallpoiss{sess};        % bins x neurons
    li = LIeventidx{sess};      % bins x 2 (LI flag, trial number)

    trials = unique(li(:,2));
    nNeurons = size(y,2);
    nTrials = numel(trials);

    out = nan(nTrials, nNeurons);

    for t = 1:nTrials

        trialIdx = li(:,2)==trials(t);

        LIidx       = trialIdx & (li(:,1)==1);
        baselineIdx = trialIdx & (li(:,1)==0>LIidx);   % adjust if baseline coded differently
        baseline = y(baselineIdx(1:end-10),:);
        LIbins   = y(LIidx,:);

        mu  = mean(baseline,1);
        sig = std(baseline,[],1);

        zLI = (LIbins - mu) ./ sig;

        out(t,:) = mean(zLI,1);

    end

    LIactivitymean{sess} = out;   % trials x neurons

end


% Preallocate
nSessions = numel(LIactivitymean);
corrCellpos = cell(nSessions,1);    % correlation coefficients
pvalCellpos = cell(nSessions,1);    % p-values
corrCellneg = cell(nSessions,1);    % correlation coefficients
pvalCellneg = cell(nSessions,1);    % p-values
datapos=cell(nNeurons,2);
dataneg=cell(nNeurons,2);
neuroncounter=0;
for sess = 1:nSessions
    liMat = LIactivitymean{sess};   % trials x neurons
    lpLat = LP1latencyLILRall{sess};      % vector of trial latencies


    nNeurons = size(liMat,2);
    sessCorr = NaN(1,nNeurons);
    sessP = NaN(1,nNeurons);
    for n = 1:nNeurons
        corrCellpos{sess}=NaN(1,nNeurons);
        pvalCellpos{sess}=NaN(1,nNeurons);
        corrCellneg{sess}=NaN(1,nNeurons);
        pvalCellneg{sess}=NaN(1,nNeurons);
        if directionfull{1}{1}(neuroncounter+n,1)==1

            % Spearman correlation with p-value
            datapos{neuroncounter+n,1}=liMat(:,n);
            datapos{neuroncounter+n,2}=lpLat;
            [R,P] = corr(liMat(:,n), lpLat, 'Type', 'Spearman', 'Rows','complete');
            sessCorr(n) = R;
            sessP(n) = P;

            corrCellpos{sess} = sessCorr;   % 1 x neurons
            pvalCellpos{sess} = sessP;      % 1 x neurons
        elseif directionfull{1}{1}(neuroncounter+n,1)==-1
            dataneg{neuroncounter+n,1}=liMat(:,n);
            dataneg{neuroncounter+n,2}=lpLat;
            
            % Spearman correlation with p-value
            [R,P] = corr(liMat(:,n), lpLat, 'Type', 'Spearman', 'Rows','complete');
            sessCorr(n) = R;
            sessP(n) = P;
            corrCellneg{sess} = sessCorr;   % 1 x neurons
            pvalCellneg{sess} = sessP;      % 1 x neurons
        end
    end


    neuroncounter = neuroncounter+nNeurons;
end
dataneg=dataneg(~cellfun(@isempty, dataneg(:,1)), :);
datapos=datapos(~cellfun(@isempty, datapos(:,1)), :);
allNeuronsPpos=[pvalCellpos{:}]';
allNeuronscorrpos=[corrCellpos{:}]';
significant_pos=allNeuronsPpos<0.05;
figure;sgtitle('LI-modulated (+) neurons only');subplot(1,2,1);histogram(allNeuronsPpos,20);xlabel('P-val');ylabel('Count');subplot(1,2,2);histogram(allNeuronscorrpos);xlabel('Correlation');ylabel('Count');


allNeuronsPneg=[pvalCellneg{:}]';
allNeuronscorrneg=[corrCellneg{:}]';
significant_neg=allNeuronsPneg<0.05;
figure;sgtitle('LI-modulated (-) neurons only');subplot(1,2,1);histogram(allNeuronsPneg,20);xlabel('P-val');ylabel('Count');subplot(1,2,2);histogram(allNeuronscorrneg);xlabel('Correlation');ylabel('Count');



   %% Clustering with GLM inputs
%sig modulation data clusters
use=[];
sigmodlogical=[];
selective=significant{bestit};
if contains(whichmat,{'SuperJazz'})
    whichfile='SUPERAPPLE_lick_modulation.mat';
    load(whichfile)
    lickmodulation=lickmodulation(end-size(significant{1},1)+1:end,:);
else
    whichfile=[upper(regexp(whichmat, '(.*?)(?=2)', 'match', 'once')),'_lick_modulation.mat'];
    load(whichfile)
end
if contains(whichmat,{'SuperJazz','Melon','Grape'})
eventsforanalysis=[1:4];
    selective=selective(:,eventsforanalysis);
eventsforanalysiscolumns=[1:all_columnstart(5)-1,all_columnstart(6):all_columnstart(7)-1];
else
eventsforanalysis= [1:4];%R.Erefnames([1,2,4,6]);
selective=selective(:,eventsforanalysis);
eventsforanalysiscolumns=[1:all_columnstart(5)-1,all_columnstart(6):all_columnstart(7)-1];
end

for neuron=1:size(selective,1)
    if ~isnan(varExp{bestit}(neuron,1))
        for event=1:length(eventsforanalysis)
            if selective(neuron,event)~=0
                sigmodlogical(neuron,event)=1;
            elseif selective(neuron,event)==0
                sigmodlogical(neuron,event)=0;
            end
        end
        % sigmodlogical(neuron,evtcounter)=vec_lick_modulation(neuron);
    end
end
sigmodlogical(:,end+1)=lickmodulation;
% for neuron=1:length(R.Ninfo)c
%     evtcounter=1;
%     for event=[1,2,4,6]
%         if R.Ev(event).RespDir(neuron)~=0
%             sigmodlogical(neuron,evtcounter)=1;
%         elseif R.Ev(event).RespDir(neuron)==0
%             sigmodlogical(neuron,evtcounter)=0;
%         end
%         evtcounter=evtcounter+1;
%     end
%     sigmodlogical(neuron,evtcounter)=vec_lick_modulation(neuron);
% end
% sigmodlogical=[sigmodlogical vec_lick_modulation];
use=logical(use);
data2=corr(sigmodlogical');
stablecells=sum(isnan(data2))==size(data2,1);
use=(stablecells==0)';
data22=data2(~stablecells,~stablecells);
distance2=pdist(data22-eye(size(data22)),'hamming');
squareform(distance2);
z2=linkage(distance2,'average');
% figure;
%[emclust2,emcent2,emsumd2,emk2]=best_kmeans(z2);
% xlim([1 100]);xlabel('Number of Clusters'); ylabel('Elbow Values (WCSS)');title('Elbow Curve');
% sileva2=evalclusters(z2,'linkage','silhouette','klist',[1:20]);
% gapeva2=evalclusters(z2,'linkage','gap','klist',[1:20]);
%new method for inputting max clustersemk2e
maxclusters2=7;
%maxclusters2=5;
t2=cluster(z2,'maxclust',maxclusters2);
heights = sort(z2(:,3));
cutoff2 = heights(end - maxclusters2 + 1) + eps(heights(end - maxclusters2 + 1));
f2=figure;
tiledlayout(f2,2,maxclusters2);
leafOrder2=optimalleaforder(z2,distance2);
nexttile ([1 maxclusters2])
d2=dendrogram(z2,0,'ColorThreshold',cutoff2,'reorder',leafOrder2);
set(gca,'TickLength',[0 0]);
cluorder2 = t2(leafOrder2);
% delimit_clu2 = Accumulate(t2);
% delimit_clu2 = delimit_clu2(unique(cluorder2,'stable'));
linesColor2 = cell2mat(get(d2,'Color')); % get lines color;
colorList2 = unique(linesColor2, 'rows');
N2=length(z2)+1;
X_color2 = zeros(N2,3);
X_cluster2=zeros(N2,1);
for iLeaf = leafOrder2
    [iRow, ~] = find(z2(:,1:2)==iLeaf);
    color = linesColor2(iRow,:); % !
    % assign color to each observation
    X_color2(iLeaf,:) = color;
    X_cluster2(iLeaf,:) = find(ismember(colorList2, color, 'rows'));
end
X_cluster2=t2;
colorclusterorder2=unique(X_cluster2(leafOrder2,:),'row','stable');
colororder2=unique(X_color2(leafOrder2,:),'row','stable');
title('Significant Modulations Clustering');

clustertitlecounter=1;
% heatplotfiglog=figure;
%tile2=tiledlayout(heatplotfiglog,3,maxclusters2);
figure(f2);
clustereddata=t2;
maxclusters=maxclusters2;
colorclusterorder=colorclusterorder2;
colororder1=colororder2;
clims=[0 1];
d2=data22;
leafOrder=leafOrder2;
clusteredorderedidx=[];
numbperidx=[];
kernelsforplotting=kernels{bestit}(use,eventsforanalysiscolumns);
plotHandles = gobjects(length(colorclusterorder),1);
legendLabels = strings(length(colorclusterorder),1);
plotlines=find(ismember(eventsforanalysiscolumns,all_columnstart(eventsforanalysis)));
plotzeros=find(ismember(eventsforanalysiscolumns,kernel_zerocolumn(eventsforanalysis)));
i = 1;
for clust=(colorclusterorder)'
    %hold on
    nexttile
    activity=mean(kernelsforplotting(clustereddata==clust,:),1);
    plot(activity,'Color',colororder1(colorclusterorder==clust,:),'LineWidth',1.5);
    set(gca,'xtick',plotzeros(1:length(eventsforanalysis)),'xticklabel',eventNameskernel(eventsforanalysis));xtickangle(45);
    legend(['Cluster ',num2str(clust),' (',num2str(sum(clustereddata==clust)), ') neurons'],'Location', 'Best');
    xlim([1 length(activity)]);
%     xline(plotzeros,'Color',[0.7 0.7 0.7],'LineStyle','--','HandleVisibility', 'off');
%     xline(plotlines,'HandleVisibility', 'off');
    title(['Beta Weights']);
    ylim([-0.2 0.5])
    i = i + 1;
end
sigmodlogicalnonans = sigmodlogical(~stablecells,:);
usingsigmod=sigmodlogical(use,:);
% figure;imagesc(usingsigmod(leafOrder,:)); colormap([1 1 1; 0 0 0]); lineidx=find(diff(cluorder2)~=0);yline(lineidx,'b');yticks([1;lineidx]);yticklabels(colorclusterorder2)
figure; hold on;
matrix_reordered = usingsigmod(leafOrder,:);
region_ordered = R.Ninfo(leafOrder,4);

unique_regions = unique(region_ordered);
num_regions = length(unique_regions);
region_colors = [ 0,0.9336,0.7773;0.2578,0.9336,0;0.8203,0.0664,0.9258];

% Plot the binary matrix first
imagesc(matrix_reordered);
colormap([1 1 1; 0 0 0]);
set(gca, 'YDir', 'reverse');
xticklabels({eventNameskernel{eventsforanalysis},'Rhythmic Lick Mod'});
xlim([0.5 size(matrix_reordered,2)+0.5]);
ylim([0.5 size(matrix_reordered,1)+0.5]);

% % Overlay colored patch **per neuron row**
% for neuron_idx = 1:length(region_ordered)
%     % Find color for this neuron’s region
%     region_name = region_ordered{neuron_idx};
%     color_idx = find(strcmp(unique_regions, region_name));
%     this_color = region_colors(color_idx, :);
% 
%     % Patch rectangle covering just this row (all columns)
%     x_left = 0.5;
%     x_right = size(matrix_reordered, 2) + 0.5;
%     y_top = neuron_idx - 0.5;
%     y_bottom = neuron_idx + 0.5;
% 
%     patch('XData', [x_left x_right x_right x_left], ...
%           'YData', [y_top y_top y_bottom y_bottom], ...
%           'FaceColor', this_color, ...
%           'EdgeColor', 'none', ...
%           'FaceAlpha', 0.7); % low alpha for subtle overlay
% end

% Cluster boundary lines
lineidx = find(diff(cluorder2) ~= 0);
yline(lineidx + 0.5, 'r','LineWidth',1.5);

yticks([1; lineidx]);
yticklabels(colorclusterorder2);
regions = unique(region_ordered);
clusters = unique(cluorder2);

counts = zeros(length(regions), length(clusters));

for r = 1:length(regions)
    region_counts(r) = sum(strcmp(region_ordered, regions{r}));
    for c = 1:length(clusters)
        counts(r,c) = sum(strcmp(region_ordered, regions{r}) & cluorder2 == clusters(c));
    end
end

% Total neurons per cluster (sum down columns)
cluster_totals = sum(counts, 1);

% Compute proportions: each count divided by its cluster total
proportions = counts ./ cluster_totals;

 figure;
for i=1:max(t2)
    subplot(max(t2),1,i);
    hold on; 
    bar(nansum(sigmodlogicalnonans(t2==i,:))/sum(t2==i),'k');
    title(['Cluster ' num2str(i) ' ' num2str(sum(t2==i)/length(t2)*100) '%']);
    xticks([1:5]);
    if i==max(t2)
        xticks([1:5]);
        xticklabels({eventNameskernel{eventsforanalysis},'Rhythmic Lick Mod'});
    else
        xticklabels({});
    end
    ylim([0 1]);

end

% Display proportions table
disp('Number of neurons per region:')
disp(table(regions, region_counts'))
disp('Proportion of Total')
disp(table(regions,region_counts'/sum(region_counts)))
disp('Proportion of neurons in each cluster that come from each region:')
disp(array2table(proportions, 'RowNames', regions, 'VariableNames', ...
    strcat('Cluster_', string(clusters))))


use=[];
directionsigns= cell2mat([directionfull{:}]);
directionsigns=directionsigns(:,[1:4]);
directionsigns(:,end+1)=lickmodulation*2;
use=logical(use);
data3=corr(directionsigns');
stablecells=sum(isnan(data3))==size(data3,1);
use=(stablecells==0)';
data33=data3(~stablecells,~stablecells);
distance2=pdist(data33-eye(size(data33)));
squareform(distance2);
z3=linkage(distance2,'average');
% figure;
%[emclust3,emcent3,emsumd3,emk3]=best_kmeans(z3);
% xlim([1 100]);xlabel('Number of Clusters'); ylabel('Elbow Values (WCSS)');title('Elbow Curve');
% sileva3=evalclusters(z3,'linkage','silhouette','klist',[1:20]);
% gapeva3=evalclusters(z3,'linkage','gap','klist',[1:20]);

%new method for inputting max clustersemk2e
maxclusters2=7;
%maxclusters2=5;
t2=cluster(z3,'maxclust',maxclusters2);
heights = sort(z3(:,3));
cutoff2 = heights(end - maxclusters2 + 1) + eps(heights(end - maxclusters2 + 1));
f2=figure;
tiledlayout(f2,2,maxclusters2);
leafOrder2=optimalleaforder(z3,distance2);
nexttile ([1 maxclusters2])
d2=dendrogram(z3,0,'ColorThreshold',cutoff2,'reorder',leafOrder2);
set(gca,'TickLength',[0 0]);
cluorder2 = t2(leafOrder2);
% delimit_clu2 = Accumulate(t2);
% delimit_clu2 = delimit_clu2(unique(cluorder2,'stable'));
linesColor2 = cell2mat(get(d2,'Color')); % get lines color;
colorList2 = unique(linesColor2, 'rows');
N2=length(z3)+1;
X_color2 = zeros(N2,3);
X_cluster2=zeros(N2,1);
for iLeaf = leafOrder2
    [iRow, ~] = find(z3(:,1:2)==iLeaf);
    color = linesColor2(iRow,:); % !
    % assign color to each observation
    X_color2(iLeaf,:) = color;
    X_cluster2(iLeaf,:) = find(ismember(colorList2, color, 'rows'));
end
X_cluster2=t2;
colorclusterorder2=unique(X_cluster2(leafOrder2,:),'row','stable');
colororder2=unique(X_color2(leafOrder2,:),'row','stable');
title('Significant Modulations Clustering');

clustertitlecounter=1;
% heatplotfiglog=figure;
%tile2=tiledlayout(heatplotfiglog,3,maxclusters2);
figure(f2);
clustereddata=t2;
maxclusters=maxclusters2;
colorclusterorder=colorclusterorder2;
colororder1=colororder2;
clims=[0 1];
d2=data33;
leafOrder=leafOrder2;
clusteredorderedidx=[];
numbperidx=[];
kernelsforplotting=kernels{bestit}(use,eventsforanalysiscolumns);
plotHandles = gobjects(length(colorclusterorder),1);
legendLabels = strings(length(colorclusterorder),1);
plotlines=find(ismember(eventsforanalysiscolumns,all_columnstart(eventsforanalysis)));
plotzeros=find(ismember(eventsforanalysiscolumns,kernel_zerocolumn(eventsforanalysis)));
i = 1;
for clust=(colorclusterorder)'
    %hold on
    nexttile
    activity=mean(kernelsforplotting(clustereddata==clust,:),1);
    plot(activity,'Color',colororder1(colorclusterorder==clust,:),'LineWidth',1.5);
    set(gca,'xtick',plotzeros(1:length(eventsforanalysis)),'xticklabel',eventNameskernel(eventsforanalysis));xtickangle(45);
    legend(['Cluster ',num2str(clust),' (',num2str(sum(clustereddata==clust)), ') neurons'],'Location', 'Best');
    xlim([1 length(activity)]);
%     xline(plotzeros,'Color',[0.7 0.7 0.7],'LineStyle','--','HandleVisibility', 'off');
%     xline(plotlines,'HandleVisibility', 'off');
    title(['Beta Weights']);
    ylim([-0.2 0.5])
    i = i + 1;
end
directionssignsnonans = directionsigns(~stablecells,:);
usingdirections=directionsigns(use,:);
% figure;imagesc(usingsigmod(leafOrder,:)); colormap([1 1 1; 0 0 0]); lineidx=find(diff(cluorder2)~=0);yline(lineidx,'b');yticks([1;lineidx]);yticklabels(colorclusterorder2)
figure; hold on;
matrix_reordered = usingdirections(leafOrder,:);
region_ordered = R.Ninfo(leafOrder,4);

unique_regions = unique(region_ordered);
num_regions = length(unique_regions);
region_colors = [ 0,0.9336,0.7773;0.2578,0.9336,0;0.8203,0.0664,0.9258];

% Plot the binary matrix first
imagesc(matrix_reordered);
colormap([0 0 1;1 1 1;1 0 0;0.7 0.7 0.7])

set(gca, 'YDir', 'reverse');
xlim([0.5 size(matrix_reordered,2)+0.5]);
xticks(1:size(matrix_reordered,2));
xticklabels({eventNameskernel{eventsforanalysis},'Rhythmic Lick Mod'});
ylim([0.5 size(matrix_reordered,1)+0.5]);

% % Overlay colored patch **per neuron row**
% for neuron_idx = 1:length(region_ordered)
%     % Find color for this neuron’s region
%     region_name = region_ordered{neuron_idx};
%     color_idx = find(strcmp(unique_regions, region_name));
%     this_color = region_colors(color_idx, :);
% 
%     % Patch rectangle covering just this row (all columns)
%     x_left = 0.5;
%     x_right = size(matrix_reordered, 2) + 0.5;
%     y_top = neuron_idx - 0.5;
%     y_bottom = neuron_idx + 0.5;
% 
%     patch('XData', [x_left x_right x_right x_left], ...
%           'YData', [y_top y_top y_bottom y_bottom], ...
%           'FaceColor', this_color, ...
%           'EdgeColor', 'none', ...
%           'FaceAlpha', 0.7); % low alpha for subtle overlay
% end

% Cluster boundary lines
lineidx = find(diff(cluorder2) ~= 0);
yline(lineidx + 0.5, 'k','LineWidth',3);

yticks([1; lineidx]);
yticklabels(colorclusterorder2);
regions = unique(region_ordered);
clusters = unique(cluorder2);

counts = zeros(length(regions), length(clusters));

for r = 1:length(regions)
    region_counts(r) = sum(strcmp(region_ordered, regions{r}));
    for c = 1:length(clusters)
        counts(r,c) = sum(strcmp(region_ordered, regions{r}) & cluorder2 == clusters(c));
    end
end

% Total neurons per cluster (sum down columns)
cluster_totals = sum(counts, 1);

% Compute proportions: each count divided by its cluster total
proportions = counts ./ cluster_totals;

 figure;
for i=1:max(t2) 
    subplot(max(t2),1,i);
    hold on; 
    bar(nansum(directionssignsnonans(t2==i,:)==1)/sum(t2==i),'r');
    bar(nansum((directionssignsnonans(t2==i,:)==-1)*-1)/sum(t2==i),'b');
    bar(nansum((directionssignsnonans(t2==i,:)==2))/sum(t2==i),'FaceColor',[0.7 0.7 0.7]);
    title(['Cluster ' num2str(i) ' ' num2str(sum(t2==i)/length(t2)*100) '%']);

    if i==max(t2)
        xticks([1:5]);
        xticklabels({eventNameskernel{eventsforanalysis},'Rhythmic Lick Mod'});
    else
        xticklabels({});
    end
    ylim([-1 1]);
end

% Display proportions table
disp('Number of neurons per region:')
disp(table(regions, region_counts'))
disp('Proportion of Total')
disp(table(regions,region_counts'/sum(region_counts)))
disp('Proportion of neurons in each cluster that come from each region:')
disp(array2table(proportions, 'RowNames', regions, 'VariableNames', ...
    strcat('Cluster_', string(clusters))))

figure;

% --- 1. Identify GLM-only signs ---
glmSigns = directionsigns;
glmSigns(glmSigns==2) = 0;  % ignore lick for streak calc

nNeurons = size(glmSigns,1);
maxConsec = zeros(nNeurons,1);

% --- 2. Determine first-event index and sign ---
[~, firstEventIdx] = max(abs(glmSigns),[],2);
rows = (1:nNeurons)';
firstSign = glmSigns(sub2ind(size(glmSigns), rows, firstEventIdx));

% --- 3. Compute consecutive streak starting at first event ---
for i = 1:nNeurons
    sgn = firstSign(i);
    idxStart = firstEventIdx(i);
    if sgn == 0 || idxStart > size(glmSigns,2)
        maxConsec(i) = 0;
        continue
    end
    seq = glmSigns(i, idxStart:end);  % start from first-event
    streak = 0;
    for j = 1:length(seq)
        if seq(j) == sgn
            streak = streak + 1;
        else
            break;
        end
    end
    maxConsec(i) = streak;
end

% --- 4. Separate groups ---
posNeurons     = find(firstSign > 0);
negNeurons     = find(firstSign < 0);
neutralNeurons = find(all(glmSigns==0,2) & ~any(directionsigns==2,2));
lickOnly       = find(any(directionsigns==2,2) & all(glmSigns==0,2));

% Identify lick-modulated neurons
lickResp = any(directionsigns==2,2);

% --- 5. Build matrix of subsequent event signs for tertiary+ sorting ---
nextSignsMat = zeros(nNeurons, size(directionsigns,2));
for i = 1:nNeurons
    idxStart = firstEventIdx(i) + maxConsec(i); % first after streak
    if idxStart <= size(glmSigns,2)
        seq = glmSigns(i, idxStart:end);
        seq(seq>0) = 1;
        seq(seq<0) = -1;
        seq(seq==0) = 0;
        nextSignsMat(i,1:length(seq)) = seq;
    end
end

% --- 6. Global hierarchical sorting (first-event, streak, next signs) ---
sortMatPos = [firstEventIdx(posNeurons), -maxConsec(posNeurons), -nextSignsMat(posNeurons,:), -lickResp(posNeurons)];
[~, sidx] = sortrows(sortMatPos);
posSorted = posNeurons(sidx);

sortMatNeg = [firstEventIdx(negNeurons), -maxConsec(negNeurons), nextSignsMat(negNeurons,:), lickResp(negNeurons)];
[~, sidx] = sortrows(sortMatNeg);
negSorted = negNeurons(sidx);

[~, neutralSort] = sort(firstEventIdx(neutralNeurons));
neutralSorted = neutralNeurons(neutralSort);

[~, lickOnlySort] = sort(firstEventIdx(lickOnly));
lickOnlySorted = lickOnly(lickOnlySort);


% --- 8. Concatenate final neuron order ---
neurons = [
    posSorted;
    lickOnlySorted;
    neutralSorted;
    flip(negSorted)
];

% --- 9. Plot ---
imagesc(directionsigns(neurons,:));
colormap([
    0 0 1;      % -1
    1 1 1;      %  0
    1 0 0;      % +1
    0.7 0.7 0.7 %  2 lick-modulated
]);
clim([-1 2]);



%===== REST OF YOUR CODE (unchanged) =====

figure;
subplot(5,1,1);
hold on;
for i=1:size(directionsigns,2)
    if i==size(directionsigns,2)
        b = bar([i], ...
        [nansum(directionsigns(:,i)==2)] ...
        / nansum(directionsigns(:,i)~=0), 'FaceColor','flat');
    b.CData = [0.7 0.7 0.7];
    else
        b = bar([i-0.25 i+0.25], ...
        [nansum(directionsigns(:,i)==1) nansum(directionsigns(:,i)==-1)] ...
        / nansum(directionsigns(:,i)~=0), 'FaceColor','flat');
    b.CData = [1 0 0; 0 0 1];
    end
    
end
xticks(1:5)
xticklabels({eventNameskernel{eventsforanalysis},'Rhythmic Lick Mod'})
ylim([0 1])
ylabel('Fraction')

subplot(5,1,2);
hold on;
for i=1:size(directionsigns,2)
    bar(i, nansum(sigmodlogicalnonans(:,i))/size(directionsigns,1), 'k')
end
xticks(1:5)
xticklabels({eventNameskernel{eventsforanalysis},'Rhythmic Lick Mod'})
ylim([0 0.5])
ylabel('Fraction')

subplot(5,1,3)
negresp  = any(directionsigns==-1,2);
posresp  = any(directionsigns== 1,2);
lickresp = any(directionsigns== 2,2);   % <-- NEW

allpos = posresp & ~negresp;
allneg = negresp & ~posresp;
mix = posresp & negresp;
lickonly= ~posresp & ~negresp & lickresp;
ns     = ~posresp & ~negresp & ~lickresp;



bardata = [
    sum(allpos);
    sum(allneg);
    sum(mix);
    sum(lickonly);
    sum(ns)
] / size(directionsigns,1);

b=bar(bardata);
b(1).FaceColor = [0.8 0.2 0.8];   % non-lick

xticklabels({'+','-','Mix','Only Licks','NR'})
ylim([0 0.5])
ylabel('Fraction')

subplot(5,1,4)
histogram(sum(sigmodlogical,2),'FaceColor','k')
ylabel('Count')

subplot(5,1,5)
appetitiveresponders=any(sigmodlogical(:,1:3),2);
consummatoryresponders=any(sigmodlogical(:,4:5),2);
onlyappetitive=appetitiveresponders & ~consummatoryresponders;
onlyconsummatory= ~appetitiveresponders & consummatoryresponders;
both=appetitiveresponders & consummatoryresponders;
bardata=[sum(onlyappetitive) sum(onlyconsummatory) sum(both)]/sum(any(sigmodlogical,2));
bar(bardata)
xticklabels({'Only Appetitive','Only Consummatory','Both Phases'});
ylabel('Fraction (n = # of neurons activated by >=1 events)')

    %% Pointwise GIANT RAT SVM (DECODER)
    methodstring1='kfold';
    methodstring2=10;
    trials2pull=9;
    binsize=0.5; %250 ms bins
    windowStartLI=-15;
    windowEndLI=5;
    windowStartLR=-5;
    windowEndLR=5;
    binEdgesLI=windowStartLI:binsize:windowEndLI;
    binCentersLI=binEdgesLI(1:end-1) + binsize/2;
    NLI=numel(binCentersLI);
    binEdgesLR=windowStartLR:binsize:windowEndLR;
    binCentersLR=binEdgesLR(1:end-1) + binsize/2;
    NLR=numel(binCentersLR);
    methodstring1='kfold';
    methodstring2=trials2pull;
    whichRAW=uigetfile('RAW*.mat','X:\Matilde\MatLab');
    includeq='no';
    if contains(whichRAW,{'Jazz','Grape','Melon'})
        includeq=questdlg('Include Video Modulated Neurons?','VD Neur','yes','no','yes');
    end
    load (whichRAW);
    numbrats=50;

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
    trialtype=strcmp('Trial Type',RAW(1).Einfo(:,2));
    %RDvsOM

    PointWiseAccuracyRDvsOMLI=struct;

    for gr=1:numbrats
        rn=1;
        matcounter=1;
        validneurs=[];
        clearvars popbline;
        for i=1:length(RAW)
            [neuronspersesh,~]=size(RAW(i).Ninfo);
            if length(RAW(i).Erast{RD})>=10
                if length(RAW(i).Erast{RD})>=trials2pull && sum(strcmp(RAW(i).Erast{trialtype,1},'omission'))>= trials2pull%&& length(RAW(i).Erast{PERD})>=trials2pull
                    rewardedtrialts=RAW(i).Erast{LI}(~strcmp(RAW(i).Erast{trialtype,1},'omission'),:);
                    omittedtrialindts=RAW(i).Erast{LI}(strcmp(RAW(i).Erast{trialtype,1},'omission'),:);
                    randrdtrialstart=rewardedtrialts(randperm(length(rewardedtrialts),trials2pull));
                    randomtrialstart=omittedtrialindts(randperm(length(omittedtrialindts),trials2pull));
                    for neur=1:neuronspersesh
                        %randrdactivity=R.FiringRate(rn,randrdtrialstart);
                        avgactivity = mean(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25})); % change this to be number of spikes in -15 to -5 before LI
                        stdactivity=std(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25}));
                        randrdactivity = arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur} >= (t0 + windowStartLI) & RAW(i).Nrast{neur} <= (t0 + windowEndLI)), randrdtrialstart, 'UniformOutput', false);
                        randrdactivity =cellfun(@(spk,t0) histcounts(spk - t0, binEdgesLI), randrdactivity, num2cell(randrdtrialstart), 'UniformOutput', false);
                        randrdactivity=cellfun(@(x) (x-avgactivity)/stdactivity, randrdactivity, 'UniformOutput', false);
                        randomactivity=arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur} >= (t0 + windowStartLI) & RAW(i).Nrast{neur} <= (t0 + windowEndLI)), randomtrialstart, 'UniformOutput', false);
                        randomactivity = cellfun(@(spk,t0) histcounts(spk - t0, binEdgesLI), randomactivity, num2cell(randomtrialstart), 'UniformOutput', false);
                        randomactivity=cellfun(@(x) (x-avgactivity)/stdactivity, randomactivity, 'UniformOutput', false);
                        popbline(:,matcounter)=vertcat(randrdactivity,randomactivity);
                        rn=rn+1;
                                                matcounter=matcounter+1;
                    end
                    validneurs=[validneurs;ones(neuronspersesh,1)];
                else
                   validneurs=[validneurs;zeros(neuronspersesh,1)];
                    rn=rn+neuronspersesh;
                end
            end
        end
        for bin=1:length(windowStartLI:binsize:windowEndLI)-1

            x=cellfun(@(x) x(bin), popbline);
            if exist('includeq','var')
                if strcmp(includeq,'no')
                    x(:,significant{bestit}(logical(validneurs),strcmp(variables,'VideoComponents')))=[];
                end
            end
            %x=(x-mean(x))/std(x);
            y=[ones(length(randrdtrialstart),1);(zeros(length(randomtrialstart),1)+2)];

            x_train = x;
            y_train = y;
            %run model
            Mdl2=fitcsvm(x_train,y_train, 'KernelFunction','linear',methodstring1,methodstring2,'Standardize',false);
            l=kfoldPredict(Mdl2);
            PointWiseAccuracyRDvsOMLI(gr).testaccuracy(bin)=sum(l==y_train)/length(y_train)*100;
            tmp=zeros(100,1);
            parfor s=1:100
                y_trainshuff= y(randperm(length(y)));
                Mdlshuff=fitcsvm(x_train,y_trainshuff,'KernelFunction','linear',methodstring1,methodstring2,'Standardize',false);
                ls=kfoldPredict(Mdlshuff);
                shufftestaccuracy=sum(ls==y_trainshuff)/length(y_trainshuff)*100;
                tmp(s,1)=shufftestaccuracy
                % PointWiseAccuracy(gr).totalshuffledaccuracy(s, bin) = shufftestaccuracy;
            end
            PointWiseAccuracyRDvsOMLI(gr).totalshuffledaccuracy(:,bin)=tmp;
            PointWiseAccuracyRDvsOMLI(gr).meanshuffledaccuracy(bin)=mean(PointWiseAccuracyRDvsOMLI(gr).totalshuffledaccuracy(bin));
        end
        gr=gr+1
    end

    PointWiseAccuracyHMvsLMLI=struct;

    for gr=1:numbrats
        rn=1;
        matcounter=1;
        clearvars popbline;
        validneurs=[];
        for i=1:length(RAW)
            [neuronspersesh,~]=size(RAW(i).Ninfo);
            if length(RAW(i).Erast{RD})>=10
                if sum(strcmp(RAW(i).Erast{trialtype,1},'high'))>= trials2pull && sum(strcmp(RAW(i).Erast{trialtype,1},'low'))>= trials2pull%&& length(RAW(i).Erast{PERD})>=trials2pull
                    hmtrialts=RAW(i).Erast{LI}(strcmp(RAW(i).Erast{trialtype,1},'high'),:);
                    lmtrialts=RAW(i).Erast{LI}(strcmp(RAW(i).Erast{trialtype,1},'low'),:);
                    randHMtrialstart=hmtrialts(randperm(length(hmtrialts),trials2pull));
                    randLMtrialstart=lmtrialts(randperm(length(lmtrialts),trials2pull));
                    for neur=1:neuronspersesh
                        %randrdactivity=R.FiringRate(rn,randrdtrialstart);
                        avgactivity = mean(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25}));
                        stdactivity=std(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25}));
                        randHMactivity = arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur} >= (t0 + windowStartLI) & RAW(i).Nrast{neur} <= (t0 + windowEndLI)), randHMtrialstart, 'UniformOutput', false);
                        randHMactivity =cellfun(@(spk,t0) histcounts(spk - t0, binEdgesLI), randHMactivity, num2cell(randHMtrialstart), 'UniformOutput', false);
                        randHMactivity=cellfun(@(x) (x-avgactivity)/stdactivity, randHMactivity, 'UniformOutput', false);
                        randLMactivity=arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur} >= (t0 + windowStartLI) & RAW(i).Nrast{neur} <= (t0 + windowEndLI)), randLMtrialstart, 'UniformOutput', false);
                        randLMactivity = cellfun(@(spk,t0) histcounts(spk - t0, binEdgesLI), randLMactivity, num2cell(randLMtrialstart), 'UniformOutput', false);
                        randLMactivity=cellfun(@(x) (x-avgactivity)/stdactivity, randLMactivity, 'UniformOutput', false);
                        popbline(:,matcounter)=vertcat(randHMactivity,randLMactivity);
                        rn=rn+1;
                        matcounter=matcounter+1;
                    end
                    validneurs=[validneurs;ones(neuronspersesh,1)];
                else
                   validneurs=[validneurs;zeros(neuronspersesh,1)];
                    rn=rn+neuronspersesh;
                end
            end
        end
        for bin=1:length(windowStartLI:binsize:windowEndLI)-1

            x=cellfun(@(x) x(bin), popbline);
            if exist('includeq','var')
                if strcmp(includeq,'no')
                    x(:,significant{bestit}(logical(validneurs),strcmp(variables,'VideoComponents')))=[];
                end
            end
            y=[ones(length(randrdtrialstart),1);(zeros(length(randomtrialstart),1)+2)];

            x_train = x;
            y_train = y;
            %run model
            Mdl2=fitcsvm(x_train,y_train, 'KernelFunction','linear',methodstring1,methodstring2,'Standardize',false);
            l=kfoldPredict(Mdl2);
            PointWiseAccuracyHMvsLMLI(gr).testaccuracy(bin)=sum(l==y_train)/length(y_train)*100;
            tmp=zeros(100,1);
            parfor s=1:100
                y_trainshuff= y(randperm(length(y)));
                Mdlshuff=fitcsvm(x_train,y_trainshuff,'KernelFunction','linear',methodstring1,methodstring2,'Standardize',false);
                ls=kfoldPredict(Mdlshuff);
                shufftestaccuracy=sum(ls==y_trainshuff)/length(y_trainshuff)*100;
                tmp(s,1)=shufftestaccuracy
                % PointWiseAccuracy(gr).totalshuffledaccuracy(s, bin) = shufftestaccuracy;
            end
            PointWiseAccuracyHMvsLMLI(gr).totalshuffledaccuracy(:,bin)=tmp;
            PointWiseAccuracyHMvsLMLI(gr).meanshuffledaccuracy(bin)=mean(PointWiseAccuracyHMvsLMLI(gr).totalshuffledaccuracy(bin));
        end
        gr=gr+1
    end

    %RDvsOM

    PointWiseAccuracyRDvsOMLR=struct;

    for gr=1:numbrats
        rn=1;
        matcounter=1;
        validneurs=[];
        clearvars popbline;
        for i=1:length(RAW)
            [neuronspersesh,~]=size(RAW(i).Ninfo);
            if length(RAW(i).Erast{RD})>=10
                if length(RAW(i).Erast{RD})>=trials2pull && sum(strcmp(RAW(i).Erast{trialtype,1},'omission'))>= trials2pull%&& length(RAW(i).Erast{PERD})>=trials2pull
                    rewardedtrialts=RAW(i).Erast{LR}(~strcmp(RAW(i).Erast{trialtype,1},'omission'),:);
                    omittedtrialindts=RAW(i).Erast{LR}(strcmp(RAW(i).Erast{trialtype,1},'omission'),:);
                    randrdtrialstart=rewardedtrialts(randperm(length(rewardedtrialts),trials2pull));
                    randomtrialstart=omittedtrialindts(randperm(length(omittedtrialindts),trials2pull));
                    for neur=1:neuronspersesh
                        %randrdactivity=R.FiringRate(rn,randrdtrialstart);
                        avgactivity = mean(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25})); % change this to be number of spikes in -15 to -5 before LR
                        stdactivity=std(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25}));
                        randrdactivity = arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur} >= (t0 + windowStartLR) & RAW(i).Nrast{neur} <= (t0 + windowEndLR)), randrdtrialstart, 'UniformOutput', false);
                        randrdactivity =cellfun(@(spk,t0) histcounts(spk - t0, binEdgesLR), randrdactivity, num2cell(randrdtrialstart), 'UniformOutput', false);
                        randrdactivity=cellfun(@(x) (x-avgactivity)/stdactivity, randrdactivity, 'UniformOutput', false);
                        randomactivity=arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur} >= (t0 + windowStartLR) & RAW(i).Nrast{neur} <= (t0 + windowEndLR)), randomtrialstart, 'UniformOutput', false);
                        randomactivity = cellfun(@(spk,t0) histcounts(spk - t0, binEdgesLR), randomactivity, num2cell(randomtrialstart), 'UniformOutput', false);
                        randomactivity=cellfun(@(x) (x-avgactivity)/stdactivity, randomactivity, 'UniformOutput', false);
                        popbline(:,matcounter)=vertcat(randrdactivity,randomactivity);
                        rn=rn+1;
                                                matcounter=matcounter+1;
                    end
                    validneurs=[validneurs;ones(neuronspersesh,1)];
                else
                   validneurs=[validneurs;zeros(neuronspersesh,1)];
                    rn=rn+neuronspersesh;
                end
            end
        end
        for bin=1:length(windowStartLR:binsize:windowEndLR)-1

            x=cellfun(@(x) x(bin), popbline);
            if exist('includeq','var')
                if strcmp(includeq,'no')
                    x(:,significant{bestit}(logical(validneurs),strcmp(variables,'VideoComponents')))=[];
                end
            end
            %x=(x-mean(x))/std(x);
            y=[ones(length(randrdtrialstart),1);(zeros(length(randomtrialstart),1)+2)];

            x_train = x;
            y_train = y;
            %run model
            Mdl2=fitcsvm(x_train,y_train, 'KernelFunction','linear',methodstring1,methodstring2,'Standardize',false);
            l=kfoldPredict(Mdl2);
            PointWiseAccuracyRDvsOMLR(gr).testaccuracy(bin)=sum(l==y_train)/length(y_train)*100;
            tmp=zeros(100,1);
            parfor s=1:100
                y_trainshuff= y(randperm(length(y)));
                Mdlshuff=fitcsvm(x_train,y_trainshuff,'KernelFunction','linear',methodstring1,methodstring2,'Standardize',false);
                ls=kfoldPredict(Mdlshuff);
                shufftestaccuracy=sum(ls==y_trainshuff)/length(y_trainshuff)*100;
                tmp(s,1)=shufftestaccuracy
                % PointWiseAccuracy(gr).totalshuffledaccuracy(s, bin) = shufftestaccuracy;
            end
            PointWiseAccuracyRDvsOMLR(gr).totalshuffledaccuracy(:,bin)=tmp;
            PointWiseAccuracyRDvsOMLR(gr).meanshuffledaccuracy(bin)=mean(PointWiseAccuracyRDvsOMLR(gr).totalshuffledaccuracy(bin));
        end
        gr=gr+1
    end

    PointWiseAccuracyHMvsLMLR=struct;

    for gr=1:numbrats
        rn=1;
        matcounter=1;
        validneurs=[];
        clearvars popbline;
        for i=1:length(RAW)
            [neuronspersesh,~]=size(RAW(i).Ninfo);
            if length(RAW(i).Erast{RD})>=10
                if sum(strcmp(RAW(i).Erast{trialtype,1},'high'))>= trials2pull && sum(strcmp(RAW(i).Erast{trialtype,1},'low'))>= trials2pull%&& length(RAW(i).Erast{PERD})>=trials2pull
                    hmtrialts=RAW(i).Erast{LR}(strcmp(RAW(i).Erast{trialtype,1},'high'),:);
                    lmtrialts=RAW(i).Erast{LR}(strcmp(RAW(i).Erast{trialtype,1},'low'),:);
                    randHMtrialstart=hmtrialts(randperm(length(hmtrialts),trials2pull));
                    randLMtrialstart=lmtrialts(randperm(length(lmtrialts),trials2pull));
                    for neur=1:neuronspersesh
                        %randrdactivity=R.FiringRate(rn,randrdtrialstart);
                        avgactivity = mean(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25}));
                        stdactivity=std(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25}));
                        randHMactivity = arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur} >= (t0 + windowStartLR) & RAW(i).Nrast{neur} <= (t0 + windowEndLR)), randHMtrialstart, 'UniformOutput', false);
                        randHMactivity =cellfun(@(spk,t0) histcounts(spk - t0, binEdgesLR), randHMactivity, num2cell(randHMtrialstart), 'UniformOutput', false);
                        randHMactivity=cellfun(@(x) (x-avgactivity)/stdactivity, randHMactivity, 'UniformOutput', false);
                        randLMactivity=arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur} >= (t0 + windowStartLR) & RAW(i).Nrast{neur} <= (t0 + windowEndLR)), randLMtrialstart, 'UniformOutput', false);
                        randLMactivity = cellfun(@(spk,t0) histcounts(spk - t0, binEdgesLR), randLMactivity, num2cell(randLMtrialstart), 'UniformOutput', false);
                        randLMactivity=cellfun(@(x) (x-avgactivity)/stdactivity, randLMactivity, 'UniformOutput', false);
                        popbline(:,matcounter)=vertcat(randHMactivity,randLMactivity);
                        rn=rn+1;
                        matcounter=matcounter+1;
                    end
                    validneurs=[validneurs;ones(neuronspersesh,1)];
                else
                   validneurs=[validneurs;zeros(neuronspersesh,1)];
                    rn=rn+neuronspersesh;
                end
            end
        end
        for bin=1:length(windowStartLR:binsize:windowEndLR)-1

            x=cellfun(@(x) x(bin), popbline);
            if exist('includeq','var')
                if strcmp(includeq,'no')
                    x(:,significant{bestit}(logical(validneurs),strcmp(variables,'VideoComponents')))=[];
                end
            end
            y=[ones(length(randrdtrialstart),1);(zeros(length(randomtrialstart),1)+2)];

            x_train = x;
            y_train = y;
            %run model
            Mdl2=fitcsvm(x_train,y_train, 'KernelFunction','linear',methodstring1,methodstring2,'Standardize',false);
            l=kfoldPredict(Mdl2);
            PointWiseAccuracyHMvsLMLR(gr).testaccuracy(bin)=sum(l==y_train)/length(y_train)*100;
            tmp=zeros(100,1);
            parfor s=1:100
                y_trainshuff= y(randperm(length(y)));
                Mdlshuff=fitcsvm(x_train,y_trainshuff,'KernelFunction','linear',methodstring1,methodstring2,'Standardize',false);
                ls=kfoldPredict(Mdlshuff);
                shufftestaccuracy=sum(ls==y_trainshuff)/length(y_trainshuff)*100;
                tmp(s,1)=shufftestaccuracy
                % PointWiseAccuracy(gr).totalshuffledaccuracy(s, bin) = shufftestaccuracy;
            end
            PointWiseAccuracyHMvsLMLR(gr).totalshuffledaccuracy(:,bin)=tmp;
            PointWiseAccuracyHMvsLMLR(gr).meanshuffledaccuracy(bin)=mean(PointWiseAccuracyHMvsLMLR(gr).totalshuffledaccuracy(bin));
        end
        gr=gr+1
    end
    if ~exist('includeq','var')
        includeq='no';
    end
    save([regexp(whichRAW, '(?<=W)[^_]+(?=_)', 'match','once'),'_',includeq,'videoneurons_SVM.mat'],'windowStartLI','windowEndLI','windowStartLR','windowEndLR','binCentersLI','binCentersLR','binsize','PointWiseAccuracyRDvsOMLI','PointWiseAccuracyHMvsLMLI','PointWiseAccuracyRDvsOMLR','PointWiseAccuracyHMvsLMLR','NLI','NLR')
%%
figure;
labelnames=windowStartLI:5:windowEndLI;
tick_positions=(labelnames-binCentersLI(1))/binsize+1;
zero_idx=tick_positions(labelnames==0);

p=[];
subplot(2,2,1);line(1:length(PointWiseAccuracyRDvsOMLI(1).testaccuracy),mean(reshape([PointWiseAccuracyRDvsOMLI.testaccuracy],length(PointWiseAccuracyRDvsOMLI(1).testaccuracy),[])'),'Color','g')
hold on; line(1:length(PointWiseAccuracyRDvsOMLI(1).testaccuracy),mean(reshape([PointWiseAccuracyRDvsOMLI.meanshuffledaccuracy],length(PointWiseAccuracyRDvsOMLI(1).testaccuracy),[])'),'Color',[0.5 0.5 0.5])

x_vals = 1:length(PointWiseAccuracyRDvsOMLI(1).testaccuracy);

% Mean and SEM (or STD if you prefer)
m = mean(reshape([PointWiseAccuracyRDvsOMLI.testaccuracy],length(PointWiseAccuracyRDvsOMLI(1).testaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyRDvsOMLI.testaccuracy],length(PointWiseAccuracyRDvsOMLI(1).testaccuracy),[])',1);   % std across rows

% Patch coordinates
x_patch = [x_vals, fliplr(x_vals)];
y_patch = [m+s, fliplr(m-s)];
patch(x_patch, y_patch, 'g', 'EdgeColor', 'none', 'FaceAlpha', 0.3);
x_vals = 1:length(PointWiseAccuracyRDvsOMLI(1).meanshuffledaccuracy);

% Mean and SEM (or STD if you prefer)
m = mean(reshape([PointWiseAccuracyRDvsOMLI.meanshuffledaccuracy],length(PointWiseAccuracyRDvsOMLI(1).meanshuffledaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyRDvsOMLI.meanshuffledaccuracy],length(PointWiseAccuracyRDvsOMLI(1).meanshuffledaccuracy),[])',1);   % std across rows

% Patch coordinates
x_patch = [x_vals, fliplr(x_vals)];
y_patch = [m+s, fliplr(m-s)];
patch(x_patch, y_patch, [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
xticks(tick_positions);
xticklabels(string(labelnames));
xlim([0 NLI+1])
ylim([30 100])
ylabel('Decoder Accuracy (%)')
xline(zero_idx,'k:')
subtitle('LI RD vs OM')
% for bin=1:length(PointWiseAccuracyRDvsOMLI(1).testaccuracy)
% [pval,~,stats]=ranksum(cellfun(@(x) x(bin), {PointWiseAccuracyRDvsOMLI.testaccuracy}),cellfun(@(x) x(bin), {PointWiseAccuracyRDvsOMLI.meanshuffledaccuracy}));
% p(bin)=pval;
% end
obs = {PointWiseAccuracyRDvsOMLI.testaccuracy};
null = {PointWiseAccuracyRDvsOMLI.totalshuffledaccuracy};

nPseudo = length(obs);
nBins   = length(obs{1});
nShuff  = size(null{1},1);

% 1. Compute observed mean decoding curve
obs_mat = cell2mat(obs');           % nPseudo x nBins
obs_mean = mean(obs_mat,1);         % 1 x nBins
% 2. Compute shuffled mean decoding curves
null_mean = zeros(nShuff,nBins);

for s = 1:nShuff
    tmp = zeros(nPseudo,nBins);
    for pRat = 1:nPseudo
        tmp(pRat,:) = null{pRat}(s,:);
    end
    null_mean(s,:) = mean(tmp,1);
end


%4. Compute corrected p-values
p = zeros(1,nBins);

for b = 1:nBins
    p(b) = (sum(null_mean(:,b) >= obs_mean(b)) + 1) / (nShuff + 1);
end

%5. Significant bins
alph = 0.05;
sig_bins = find(p < alph);

scatter(sig_bins,repelem(99,size(sig_bins,2)),'k*')

p=[];
subplot(2,2,3);line(1:length(PointWiseAccuracyHMvsLMLI(1).testaccuracy),mean(reshape([PointWiseAccuracyHMvsLMLI.testaccuracy],length(PointWiseAccuracyHMvsLMLI(1).testaccuracy),[])'),'Color',[0.5 0 1])
hold on; line(1:length(PointWiseAccuracyHMvsLMLI(1).testaccuracy),mean(reshape([PointWiseAccuracyHMvsLMLI.meanshuffledaccuracy],length(PointWiseAccuracyHMvsLMLI(1).testaccuracy),[])'),'Color',[0.7 0.7 0.7])
x_vals = 1:length(PointWiseAccuracyHMvsLMLI(1).testaccuracy);

% Mean and SEM (or STD if you prefer)
m = mean(reshape([PointWiseAccuracyHMvsLMLI.testaccuracy],length(PointWiseAccuracyHMvsLMLI(1).testaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyHMvsLMLI.testaccuracy],length(PointWiseAccuracyHMvsLMLI(1).testaccuracy),[])',1);   % std across rows

% Patch coordinates
x_patch = [x_vals, fliplr(x_vals)];
y_patch = [m+s, fliplr(m-s)];
patch(x_patch, y_patch, [0.5 0 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
x_vals = 1:length(PointWiseAccuracyHMvsLMLI(1).meanshuffledaccuracy);

% Mean and SEM (or STD if you prefer)
m = mean(reshape([PointWiseAccuracyHMvsLMLI.meanshuffledaccuracy],length(PointWiseAccuracyHMvsLMLI(1).meanshuffledaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyHMvsLMLI.meanshuffledaccuracy],length(PointWiseAccuracyHMvsLMLI(1).meanshuffledaccuracy),[])',1);   % std across rows

% Patch coordinates
x_patch = [x_vals, fliplr(x_vals)];
y_patch = [m+s, fliplr(m-s)];
patch(x_patch, y_patch, [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
xticks(tick_positions);
xticklabels(string(labelnames));
xlim([0 NLI+1])
ylim([30 100])
ylabel('Decoder Accuracy (%)')
xline(zero_idx,'k:')
subtitle('LI HM vs LM')
obs = {PointWiseAccuracyHMvsLMLI.testaccuracy};
null = {PointWiseAccuracyHMvsLMLI.totalshuffledaccuracy};

nPseudo = length(obs);
nBins   = length(obs{1});
nShuff  = size(null{1},1);

% 1. Compute observed mean decoding curve
obs_mat = cell2mat(obs');           % nPseudo x nBins
obs_mean = mean(obs_mat,1);         % 1 x nBins
% 2. Compute shuffled mean decoding curves
null_mean = zeros(nShuff,nBins);

for s = 1:nShuff
    tmp = zeros(nPseudo,nBins);
    for pRat = 1:nPseudo
        tmp(pRat,:) = null{pRat}(s,:);
    end
    null_mean(s,:) = mean(tmp,1);
end

%4. Compute corrected p-values
p = zeros(1,nBins);

for b = 1:nBins
    p(b) = (sum(null_mean(:,b) >= obs_mean(b)) + 1) / (nShuff + 1);
end

%5. Significant bins
alph = 0.05;
sig_bins = find(p < alph);

scatter(sig_bins,repelem(99,size(sig_bins,2)),'k*')


labelnames=windowStartLR:5:windowEndLR;
tick_positions=(labelnames-binCentersLR(1))/binsize+1;
zero_idx=tick_positions(labelnames==0);

p=[];
subplot(2,2,2);line(1:length(PointWiseAccuracyRDvsOMLR(1).testaccuracy),mean(reshape([PointWiseAccuracyRDvsOMLR.testaccuracy],length(PointWiseAccuracyRDvsOMLR(1).testaccuracy),[])'),'Color','g')
hold on; line(1:length(PointWiseAccuracyRDvsOMLR(1).testaccuracy),mean(reshape([PointWiseAccuracyRDvsOMLR.meanshuffledaccuracy],length(PointWiseAccuracyRDvsOMLR(1).testaccuracy),[])'),'Color',[0.5 0.5 0.5])
x_vals = 1:length(PointWiseAccuracyRDvsOMLR(1).testaccuracy);

% Mean and SEM (or STD if you prefer)
m = mean(reshape([PointWiseAccuracyRDvsOMLR.testaccuracy],length(PointWiseAccuracyRDvsOMLR(1).testaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyRDvsOMLR.testaccuracy],length(PointWiseAccuracyRDvsOMLR(1).testaccuracy),[])',1);   % std across rows

% Patch coordinates
x_patch = [x_vals, fliplr(x_vals)];
y_patch = [m+s, fliplr(m-s)];
patch(x_patch, y_patch, 'g', 'EdgeColor', 'none', 'FaceAlpha', 0.3);
x_vals = 1:length(PointWiseAccuracyRDvsOMLR(1).meanshuffledaccuracy);

% Mean and SEM (or STD if you prefer)
m = mean(reshape([PointWiseAccuracyRDvsOMLR.meanshuffledaccuracy],length(PointWiseAccuracyRDvsOMLR(1).meanshuffledaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyRDvsOMLR.meanshuffledaccuracy],length(PointWiseAccuracyRDvsOMLR(1).meanshuffledaccuracy),[])',1);   % std across rows

% Patch coordinates
x_patch = [x_vals, fliplr(x_vals)];
y_patch = [m+s, fliplr(m-s)];
patch(x_patch, y_patch, [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
xticks(tick_positions);
xticklabels(string(labelnames));
xlim([0 NLR+1])
ylim([30 100])
ylabel('Decoder Accuracy (%)')
xline(zero_idx,'k:')
subtitle('LR RD vs OM')
obs = {PointWiseAccuracyRDvsOMLR.testaccuracy};
null = {PointWiseAccuracyRDvsOMLR.totalshuffledaccuracy};

nPseudo = length(obs);
nBins   = length(obs{1});
nShuff  = size(null{1},1);

% 1. Compute observed mean decoding curve
obs_mat = cell2mat(obs');           % nPseudo x nBins
obs_mean = mean(obs_mat,1);         % 1 x nBins
% 2. Compute shuffled mean decoding curves
null_mean = zeros(nShuff,nBins);

for s = 1:nShuff
    tmp = zeros(nPseudo,nBins);
    for pRat = 1:nPseudo
        tmp(pRat,:) = null{pRat}(s,:);
    end
    null_mean(s,:) = mean(tmp,1);
end

%4. Compute corrected p-values
p = zeros(1,nBins);

for b = 1:nBins
    p(b) = (sum(null_mean(:,b) >= obs_mean(b)) + 1) / (nShuff + 1);
end

%5. Significant bins
alph = 0.05;
sig_bins = find(p < alph);

scatter(sig_bins,repelem(99,size(sig_bins,2)),'k*')


p=[];
subplot(2,2,4);line(1:length(PointWiseAccuracyHMvsLMLR(1).testaccuracy),mean(reshape([PointWiseAccuracyHMvsLMLR.testaccuracy],length(PointWiseAccuracyHMvsLMLR(1).testaccuracy),[])'),'Color',[0.5 0 1])
hold on; line(1:length(PointWiseAccuracyHMvsLMLR(1).testaccuracy),mean(reshape([PointWiseAccuracyHMvsLMLR.meanshuffledaccuracy],length(PointWiseAccuracyHMvsLMLR(1).testaccuracy),[])'),'Color',[0.7 0.7 0.7])
x_vals = 1:length(PointWiseAccuracyHMvsLMLR(1).testaccuracy);

% Mean and SEM (or STD if you prefer)
m = mean(reshape([PointWiseAccuracyHMvsLMLR.testaccuracy],length(PointWiseAccuracyHMvsLMLR(1).testaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyHMvsLMLR.testaccuracy],length(PointWiseAccuracyHMvsLMLR(1).testaccuracy),[])',1);   % std across rows

% Patch coordinates
x_patch = [x_vals, fliplr(x_vals)];
y_patch = [m+s, fliplr(m-s)];
patch(x_patch, y_patch, [0.5 0 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
x_vals = 1:length(PointWiseAccuracyHMvsLMLR(1).meanshuffledaccuracy);

% Mean and SEM (or STD if you prefer)
m = mean(reshape([PointWiseAccuracyHMvsLMLR.meanshuffledaccuracy],length(PointWiseAccuracyHMvsLMLR(1).meanshuffledaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyHMvsLMLR.meanshuffledaccuracy],length(PointWiseAccuracyHMvsLMLR(1).meanshuffledaccuracy),[])',1);   % std across rows

% Patch coordinates
x_patch = [x_vals, fliplr(x_vals)];
y_patch = [m+s, fliplr(m-s)];
patch(x_patch, y_patch, [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
xticks(tick_positions);
xticklabels(string(labelnames));
xlim([0 NLR+1])
ylim([30 100])
ylabel('Decoder Accuracy (%)')
xline(zero_idx,'k:')
subtitle('LR HM vs LM')
% for bin=1:length(PointWiseAccuracyHMvsLMLR(1).testaccuracy)
% [pval,~,stats]=ranksum(cellfun(@(x) x(bin), {PointWiseAccuracyHMvsLMLR.testaccuracy}),cellfun(@(x) x(bin), {PointWiseAccuracyHMvsLMLR.meanshuffledaccuracy}));
% p(bin)=pval;
% end
% alph=0.05;
% nTests=size(PointWiseAccuracyHMvsLMLR(1).testaccuracy,2);
% bonf_thresh=alph/nTests;
% sig_bins=find(p<bonf_thresh);
% Extract observed and null per-bin values
obs = {PointWiseAccuracyHMvsLMLR.testaccuracy};       % cell array: 1 x nObservations
null = {PointWiseAccuracyHMvsLMLR.totalshuffledaccuracy}; % cell array: 1 x nObservations

nPseudo = length(obs);
nBins   = length(obs{1});
nShuff  = size(null{1},1);

% 1. Compute observed mean decoding curve
obs_mat = cell2mat(obs');           % nPseudo x nBins
obs_mean = mean(obs_mat,1);         % 1 x nBins
% 2. Compute shuffled mean decoding curves
null_mean = zeros(nShuff,nBins);

for s = 1:nShuff
    tmp = zeros(nPseudo,nBins);
    for pRat = 1:nPseudo
        tmp(pRat,:) = null{pRat}(s,:);
    end
    null_mean(s,:) = mean(tmp,1);
end

%4. Compute corrected p-values
p = zeros(1,nBins);

for b = 1:nBins
    p(b) = (sum(null_mean(:,b) >= obs_mean(b)) + 1) / (nShuff + 1);
end

%5. Significant bins
alph = 0.05;
sig_bins = find(p < alph);

scatter(sig_bins,repelem(99,size(sig_bins,2)),'k*')

%% removing video neuron effect
groups={'SuperJazz','Grape','Melon'}; 
whichgroup = listdlg('PromptString','Select a group:','ListString',groups,'SelectionMode','single');

load([groups{whichgroup} '_yesvideoneurons_SVM.mat']) 
% Find index of bin center closest to 0
[~, zeroIdx] = min(abs(binCentersLI - 0));
zeroIdx=zeroIdx+1;

beforeIdx = zeroIdx-5 : zeroIdx-1;   % 5 bins before 0
afterIdx  = zeroIdx   : zeroIdx+4;  


% RD vs OM with video
subsetb4 = cell2mat(arrayfun(@(s) s.testaccuracy(beforeIdx), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)'); 
subsetaf = cell2mat(arrayfun(@(s) s.testaccuracy(afterIdx), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)'); 
% Keep per-iteration values for stats
RDvsOMwith = [mean(subsetb4,2) mean(subsetaf,2)];   % size: iterations x 2
% HM vs LM with video
subsetb4 = cell2mat(arrayfun(@(s) s.testaccuracy(beforeIdx), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)');
subsetaf = cell2mat(arrayfun(@(s) s.testaccuracy(afterIdx), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)');
HMvsLMwith = [mean(subsetb4,2) mean(subsetaf,2)];
% RD vs OM with video (shuff)
subsetb4shuffRDvsOM = mean(cell2mat(arrayfun(@(s) s.totalshuffledaccuracy(beforeIdx), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)'),2); 
subsetafshuffRDvsOM = mean(cell2mat(arrayfun(@(s) s.totalshuffledaccuracy(afterIdx), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)'),2); 
pb4_RDvsOM=(sum(subsetb4shuffRDvsOM >= RDvsOMwith(:,1))+1)/(100+1);
paf_RDvsOM=(sum(subsetafshuffRDvsOM >= RDvsOMwith(:,2))+1)/(100+1);
correctedps_RDvsOM_with=[pb4_RDvsOM paf_RDvsOM]*2;
% HM vs LM with video (shuff)
subsetb4shuffHMvsLM = mean(cell2mat(arrayfun(@(s) s.totalshuffledaccuracy(beforeIdx), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)'),2);
subsetafshuffHMvsLM = mean(cell2mat(arrayfun(@(s) s.totalshuffledaccuracy(afterIdx), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)'),2);
pb4_HMvsLM=(sum(subsetb4shuffHMvsLM >= HMvsLMwith(:,1))+1)/(100+1);
paf_HMvsLM=(sum(subsetafshuffHMvsLM >= HMvsLMwith(:,2))+1)/(100+1);
correctedps_HMvsLM_with=[pb4_HMvsLM paf_HMvsLM]*2;



load([groups{whichgroup} '_novideoneurons_SVM.mat']) 
% RD vs OM without video
subsetb4 = cell2mat(arrayfun(@(s) s.testaccuracy(beforeIdx), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)'); 
subsetaf = cell2mat(arrayfun(@(s) s.testaccuracy(afterIdx), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)'); 
% Keep per-iteration values for stats
RDvsOMwout = [mean(subsetb4,2) mean(subsetaf,2)];   % size: iterations x 2
% HM vs LM with video
subsetb4 = cell2mat(arrayfun(@(s) s.testaccuracy(beforeIdx), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)');
subsetaf = cell2mat(arrayfun(@(s) s.testaccuracy(afterIdx), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)');
HMvsLMwout = [mean(subsetb4,2) mean(subsetaf,2)];
% RD vs OM with video (shuff)
subsetb4shuffRDvsOM = mean(cell2mat(arrayfun(@(s) s.totalshuffledaccuracy(beforeIdx), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)'),2); 
subsetafshuffRDvsOM = mean(cell2mat(arrayfun(@(s) s.totalshuffledaccuracy(afterIdx), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)'),2); 
pb4_RDvsOM=(sum(subsetb4shuffRDvsOM >= RDvsOMwout(:,1))+1)/(100+1);
paf_RDvsOM=(sum(subsetafshuffRDvsOM >= RDvsOMwout(:,2))+1)/(100+1);
correctedps_RDvsOM_wout=[pb4_RDvsOM paf_RDvsOM]*2;
% HM vs LM with video (shuff)
subsetb4shuffHMvsLM = mean(cell2mat(arrayfun(@(s) s.totalshuffledaccuracy(beforeIdx), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)'),2);
subsetafshuffHMvsLM = mean(cell2mat(arrayfun(@(s) s.totalshuffledaccuracy(afterIdx), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)'),2);
pb4_HMvsLM=(sum(subsetb4shuffHMvsLM >= HMvsLMwout(:,1))+1)/(100+1);
paf_HMvsLM=(sum(subsetafshuffHMvsLM >= HMvsLMwout(:,2))+1)/(100+1);
correctedps_HMvsLM_wout=[pb4_HMvsLM paf_HMvsLM]*2;


% Concatenate data
all_accuracy = [RDvsOMwith; RDvsOMwout]; 

% Create group labels
Group = [repmat("WithVideo", 50, 1); repmat("NoVideo", 50, 1)];
Group= categorical(Group);
% Create table
T = table(all_accuracy(:,1), all_accuracy(:,2), Group, ...
    'VariableNames', {'Before','After','Group'});

% Specify the within-subject factor (Time)
Time = table(categorical({'Before'; 'After'}), 'VariableNames', {'Time'});

% Fit repeated-measures model
rm = fitrm(T, 'Before-After ~ Group', 'WithinDesign', Time);
ranovatbl = ranova(rm, 'WithinModel', 'Time');
disp(ranovatbl)
multcompare(rm, 'Time', 'By', 'Group', 'ComparisonType', 'bonferroni')


group = {'With Video','No Video'};
timepoints = {'Before','After'};
nIter = size(RDvsOMwout,1);

figure; hold on;

% X positions for groups
xNo = 3.5; 
xWi = 1.5;
offset = 0.1;  % small horizontal offset for "Before" and "After"

% Lines connecting each pseudorat
for r = 1:length(RDvsOMwith)
    plot([1 2], [RDvsOMwith(r,1) RDvsOMwith(r,2)], '-', ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 1);
end
% Lines connecting each pseudorat
for r = 1:length(RDvsOMwout)
    plot([3 4], [RDvsOMwout(r,1) RDvsOMwout(r,2)], '-', ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 1);
end
boxplot([RDvsOMwith,RDvsOMwout])
% % Plot individual points with jitter
% scatter(xNo - offset+0.05*randn(size(RDvsOMwo(:,1))), RDvsOMwo(:,1), 20, 'b', 'filled')   % Before
% scatter(xNo + offset+0.05*randn(size(RDvsOMwo(:,2))), RDvsOMwo(:,2), 20, 'r', 'filled')   % After
% scatter(xWi - offset+0.05*randn(size(RDvsOMwith(:,1))), RDvsOMwith(:,1), 20, 'b', 'filled') % Before
% scatter(xWi + offset+0.05*randn(size(RDvsOMwith(:,2))), RDvsOMwith(:,2), 20, 'r', 'filled') % After
% 
% % Plot means ± SEM
% meanNo = mean(RDvsOMwo);
% SEMNo  = std(RDvsOMwo)/sqrt(nIter);
% errorbar(xNo - offset, meanNo(1), SEMNo(1), 'k','LineWidth',1.5)
% errorbar(xNo + offset, meanNo(2), SEMNo(2), 'k','LineWidth',1.5)
% 
% meanWi = mean(RDvsOMwith);
% SEMWi  = std(RDvsOMwith)/sqrt(nIter);
% errorbar(xWi - offset, meanWi(1), SEMWi(1), 'k','LineWidth',1.5)
% errorbar(xWi + offset, meanWi(2), SEMWi(2), 'k','LineWidth',1.5)


% Formatting
xlim([0.5 4.5])
ylim([30 100])
xticks([xWi xNo])
xticklabels(group)
ylabel('Model Accuracy')
legend({'Before','After'}, 'Location','Best')
title('Accuracy Before vs After by Group (RDvsOM)')
subtitle(groups{whichgroup})
box on


% Concatenate data
all_accuracy = [HMvsLMwith; HMvsLMwout]; 

% Create group labels
Group = [repmat("WithVideo", 50, 1); repmat("NoVideo", 50, 1)];
Group= categorical(Group);
% Create table
T = table(all_accuracy(:,1), all_accuracy(:,2), Group, ...
    'VariableNames', {'Before','After','Group'});

% Specify the within-subject factor (Time)
Time = table(categorical({'Before'; 'After'}), 'VariableNames', {'Time'});

% Fit repeated-measures model
rm = fitrm(T, 'Before-After ~ Group', 'WithinDesign', Time);
ranovatbl = ranova(rm, 'WithinModel', 'Time');
disp(ranovatbl)
multcompare(rm, 'Time', 'By', 'Group', 'ComparisonType', 'bonferroni')


group = {'With Video','No Video'};
timepoints = {'Before','After'};
nIter = size(HMvsLMwout,1);

figure; hold on;

% X positions for groups
xNo = 3.5; 
xWi = 1.5;
offset = 0.1;  % small horizontal offset for "Before" and "After"

% Lines connecting each pseudorat
for r = 1:length(HMvsLMwith)
    plot([1 2], [HMvsLMwith(r,1) HMvsLMwith(r,2)], '-', ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 1);
end
% Lines connecting each pseudorat
for r = 1:length(HMvsLMwout)
    plot([3 4], [HMvsLMwout(r,1) HMvsLMwout(r,2)], '-', ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 1);
end
boxplot([HMvsLMwith,HMvsLMwout])
% % Plot individual points with

% % Plot individual points with jitter
% scatter(xNo - offset+0.05*randn(size(HMvsLMwoshuff(:,1))), HMvsLMwoshuff(:,1), 20, [0.7 0.7 0.7], 'filled')   % Before
% scatter(xNo + offset+0.05*randn(size(HMvsLMwoshuff(:,2))), HMvsLMwoshuff(:,2), 20,  [0.7 0.7 0.7], 'filled')   % After
% scatter(xNo - offset+0.05*randn(size(HMvsLMwo(:,1))), HMvsLMwo(:,1), 20, 'b', 'filled')   % Before
% scatter(xNo + offset+0.05*randn(size(HMvsLMwo(:,2))), HMvsLMwo(:,2), 20, 'r', 'filled')   % After
% scatter(xWi - offset+0.05*randn(size(HMvsLMwithshuff(:,1))), HMvsLMwithshuff(:,1), 20,  [0.7 0.7 0.7], 'filled') % Before
% scatter(xWi + offset+0.05*randn(size(HMvsLMwithshuff(:,2))), HMvsLMwithshuff(:,2), 20, [0.7 0.7 0.7], 'filled') % After
% scatter(xWi - offset+0.05*randn(size(HMvsLMwith(:,1))), HMvsLMwith(:,1), 20, 'b', 'filled') % Before
% scatter(xWi + offset+0.05*randn(size(HMvsLMwith(:,2))), HMvsLMwith(:,2), 20, 'r', 'filled') % After
% 
% % Plot means ± SEM
% meanNo = mean(HMvsLMwo);
% SEMNo  = std(HMvsLMwo)/sqrt(nIter);
% errorbar(xNo - offset, meanNo(1), SEMNo(1), 'k','LineWidth',1.5)
% errorbar(xNo + offset, meanNo(2), SEMNo(2), 'k','LineWidth',1.5)
% 
% meanWi = mean(HMvsLMwith);
% SEMWi  = std(HMvsLMwith)/sqrt(nIter);
% errorbar(xWi - offset, meanWi(1), SEMWi(1), 'k','LineWidth',1.5)
% errorbar(xWi + offset, meanWi(2), SEMWi(2), 'k','LineWidth',1.5)
% 
% % Plot means ± SEM
% meanNoshuff = mean(HMvsLMwoshuff);
% SEMNoshuff  = std(HMvsLMwoshuff)/sqrt(nIter);
% errorbar(xNo - offset, meanNoshuff(1), SEMNoshuff(1), 'k','LineWidth',1.5)
% errorbar(xNo + offset, meanNoshuff(2), SEMNoshuff(2), 'k','LineWidth',1.5)
% 
% meanWishuff = mean(HMvsLMwithshuff);
% SEMWishuff  = std(HMvsLMwithshuff)/sqrt(nIter);
% errorbar(xWi - offset, meanWishuff(1), SEMWishuff(1), 'k','LineWidth',1.5)
% errorbar(xWi + offset, meanWishuff(2), SEMWishuff(2), 'k','LineWidth',1.5)

% Formatting
xlim([0.5 4.5])
ylim([30 100])
xticks([xWi xNo])
xticklabels(group)
ylabel('Model Accuracy')
legend({'Before','After'}, 'Location','Best')
title('Accuracy Before vs After by Group (HMvsLM)')
subtitle(groups{whichgroup})
box on


%% comparing groups
groups={'SuperJazz','Grape','Melon'};
groupaccuracy=[];
sizegroup=[];
figure;
hold on;
offset = 0.1;
differenceforbp=[];
for group=1:size(groups,2)
    load([groups{group} '_novideoneurons_SVM.mat'])
    [~, zeroIdx] = min(abs(binCentersLI - 0));
    zeroIdx=zeroIdx+1;

    % Define before and after indices
    beforeIdx = zeroIdx-5:zeroIdx-1;  % two bins just before/including 0
    afterIdx  = zeroIdx:zeroIdx+4; % two bins just after 0
    xBase=group;


    % RD vs OM with video
    subsetb4 = cell2mat(arrayfun(@(s) s.testaccuracy(beforeIdx), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)');
    subsetaf = cell2mat(arrayfun(@(s) s.testaccuracy(afterIdx), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)');
    differenceforbp=[differenceforbp; mean(subsetaf,2)-mean(subsetb4,2) repelem(group,50,1)];
        subsetb4shuff = mean(cell2mat(arrayfun(@(s) s.totalshuffledaccuracy(beforeIdx), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)'),2);
    subsetafshuff = mean(cell2mat(arrayfun(@(s) s.totalshuffledaccuracy(afterIdx), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)'),2);
    % Keep per-iteration values for stats
    RDvsOMrel{group} = [mean(subsetb4,2) mean(subsetaf,2) repelem(group,length(subsetb4))'];   % size: iterations x 2
    RDvsOMrelshuff{group}=[subsetb4shuff subsetafshuff];
    pb4_RDvsOM=(sum(RDvsOMrelshuff{group}(:,1) >=  RDvsOMrel{group}(:,1))+1)/(100+1);
    paf_RDvsOM=(sum(RDvsOMrelshuff{group}(:,2) >=  RDvsOMrel{group}(:,2))+1)/(100+1);
    correctedps_RDvsOM{group}=[pb4_RDvsOM paf_RDvsOM]*3;

    groupaccuracy=[groupaccuracy;RDvsOMrel{group}];
    sizegroup=[sizegroup,size(RDvsOMrel{group},1)];
    % s1=scatter(xBase - offset+0.05*randn(size(RDvsOMrel{group}(:,1))), RDvsOMrel{group}(:,1), 20, 'b', 'filled');% Before
    % s2=scatter(xBase + offset+0.05*randn(size(RDvsOMrel{group}(:,2))), RDvsOMrel{group}(:,2), 20, 'r', 'filled'); % After
    % nIter = size(RDvsOMrel{group},1);
    % meanplot = mean(RDvsOMrel{group});
    % SEM  = std(RDvsOMrel{group})/sqrt(nIter);
    % errorbar(xBase - offset, meanplot(1), SEM(1), 'k','LineWidth',1.5)
    % errorbar(xBase + offset, meanplot(2), SEM(2), 'k','LineWidth',1.5)
end
forplotting=vertcat(RDvsOMrel{:});
boxplot([forplotting(:,1);forplotting(:,2)],[forplotting(:,3)*2-1;forplotting(:,3)*2]);

% Lines connecting each pseudorat
for r = 1:length(forplotting)
    if forplotting(r,3)==1
    plot([1 2], [forplotting(r,1) forplotting(r,2)], '-', ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 1);
    elseif forplotting(r,3)==2
            plot([3 4], [forplotting(r,1) forplotting(r,2)], '-', ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 1);
    elseif forplotting(r,3)==3
            plot([5 6], [forplotting(r,1) forplotting(r,2)], '-', ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 1);
    end

end

yline(0,':k')
xticks([1:2:6]+0.5)
ylim([30 100])
groups={'EtOH/EtOH','EtOH/Suc','NoEtOH/Suc'};
xticklabels(groups)
ylabel('Model Accuracy')
title('Post vs Pre Accuracy by Group (RDvsOM)')


 % [~,p_b4jazz,~,stats]   = ttest(RDvsOMrel{1}(:,1), RDvsOMrelshuff{1}(:,1));
 % [~,p_afjazz,~,stats]   = ttest(RDvsOMrel{1}(:,2), RDvsOMrelshuff{1}(:,2));
 % [~,p_b4grape,~,stats] = ttest(RDvsOMrel{2}(:,1),   RDvsOMrelshuff{2}(:,1)); 
 % [~,p_afgrape,~,stats] = ttest(RDvsOMrel{2}(:,2),   RDvsOMrelshuff{2}(:,2));
 % [~,p_b4melon,~,stats] = ttest(RDvsOMrel{3}(:,1),   RDvsOMrelshuff{3}(:,1)); 
 % [~,p_afmelon,~,stats] = ttest(RDvsOMrel{3}(:,2),   RDvsOMrelshuff{3}(:,2));
% % Collect p-values
% pvals = [p_b4jazz, p_afjazz, p_b4grape, p_afgrape,p_b4melon,p_afmelon];
% 
% % Bonferroni correction
 % alpha = 0.05;                                % desired familywise error rate
 % nTests = numel(pvals);
 % pvals_bonf = min(pvals * nTests, 1);         % corrected p-values
 % sig_bonfrdvsom   = pvals_bonf < alpha;

% Group labels
Group = [repmat({'EtOH/EtOH'}, sizegroup(1), 1); 
         repmat({'EtOH/Suc'},  sizegroup(2), 1); 
         repmat({'NoEtOH/Suc'}, sizegroup(3), 1)];

Group = categorical(Group);

% Data table
T = table(groupaccuracy(:,1), groupaccuracy(:,2), Group, ...
    'VariableNames', {'PreLI','PostLI','Group'});

% Within-subject factor (Time)
WithinDesign = table(categorical({'PreLI'; 'PostLI'}), 'VariableNames', {'Time'});

% Fit repeated-measures model
rm = fitrm(T, 'PreLI-PostLI ~ Group', 'WithinDesign', WithinDesign);

% Run mixed ANOVA
ranovatbl = ranova(rm, 'WithinModel', 'Time');
disp(ranovatbl)

for t = 1:2
    mc=multcompare(rm, 'Group', 'By', 'Time', 'ComparisonType', 'bonferroni');
    timename=cellstr(unique(mc.Time));
    for i = find(ismember(mc.Time,timename(t)))'
        g1 = mc.Group_1(i);
        g2 = mc.Group_2(i);
        pval = mc.pValue(i);
        pMatrix(g1, g2, t) = pval;
        pMatrix(g2, g1, t) = pval; % symmetric
    end
end
for t = 1:2
    figure;
    heatmap(groups, groups, pMatrix(:,:,t), 'ColorLimits',[0 1]);
    title(['Post-hoc p-values for ', char(WithinDesign.Time(t))]);
end

multcompare(rm, 'Time', 'By', 'Group', 'ComparisonType', 'bonferroni')

groups={'SuperJazz','Grape','Melon'};
groupaccuracy=[];
sizegroup=[];
figure;
hold on;
offset = 0.1;
for group=1:size(groups,2)
    load([groups{group} '_novideoneurons_SVM.mat'])
    [~, zeroIdx] = min(abs(binCentersLI - 0));

    % Define before and after indices

    beforeIdx = zeroIdx-5 : zeroIdx-1;   % 5 bins before 0
    afterIdx  = zeroIdx   : zeroIdx+4;
    xBase=group;

    % RD vs OM with video
    subsetb4 = cell2mat(arrayfun(@(s) s.testaccuracy(beforeIdx), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)');
    subsetaf = cell2mat(arrayfun(@(s) s.testaccuracy(afterIdx), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)');
    differenceforbp=[differenceforbp; mean(subsetaf,2)-mean(subsetb4,2) repelem(group,50,1)];
      subsetb4shuff = mean(cell2mat(arrayfun(@(s) s.totalshuffledaccuracy(beforeIdx), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)'),2);
    subsetafshuff = mean(cell2mat(arrayfun(@(s) s.totalshuffledaccuracy(afterIdx), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)'),2);
    
    % Keep per-iteration values for stats
     HMvsLMrel{group} = [mean(subsetb4,2) mean(subsetaf,2) repelem(group,length(subsetb4))'];   % size: iterations x 2
         HMvsLMshuff{group}=[subsetb4shuff subsetafshuff];
    pb4_HMvsLM=(sum(HMvsLMshuff{group}(:,1) >= HMvsLMrel{group}(:,1))+1)/(100+1);
    paf_RDvsOM=(sum(HMvsLMshuff{group}(:,2) >= HMvsLMrel{group}(:,2))+1)/(100+1);
    correctedps_HMvsLM{group}=[pb4_HMvsLM paf_HMvsLM]*3;
     groupaccuracy=[groupaccuracy;HMvsLMrel{group}];
     sizegroup=[sizegroup,size(HMvsLMrel{group},1)];
    % s1=scatter(xBase - offset+0.05*randn(size(RDvsOMrelshuff{group}(:,1))), RDvsOMrelshuff{group}(:,1), 20, 'b', 'filled');% Before
    % s2=scatter(xBase + offset+0.05*randn(size(RDvsOMrelshuff{group}(:,2))), RDvsOMrelshuff{group}(:,2), 20, 'r', 'filled'); % After
    % nIter = size(RDvsOMrelshuff{group},1);
    % meanplot = mean(RDvsOMrelshuff{group});
    % SEM  = std(RDvsOMrelshuff{group})/sqrt(nIter);
    % errorbar(xBase - offset, meanplot(1), SEM(1), 'k','LineWidth',1.5)
    % errorbar(xBase + offset, meanplot(2), SEM(2), 'k','LineWidth',1.5)
end
forplotting=vertcat(HMvsLMrel{:});
boxplot([forplotting(:,1);forplotting(:,2)],[forplotting(:,3)*2-1;forplotting(:,3)*2]);


% Lines connecting each pseudorat
for r = 1:length(forplotting)
    if forplotting(r,3)==1
    plot([1 2], [forplotting(r,1) forplotting(r,2)], '-', ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 1);
    elseif forplotting(r,3)==2
            plot([3 4], [forplotting(r,1) forplotting(r,2)], '-', ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 1);
    elseif forplotting(r,3)==3
            plot([5 6], [forplotting(r,1) forplotting(r,2)], '-', ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 1);
    end

end
yline(0,':k')
xticks([1:2:6]+0.5)
ylim([30 100])
groups={'EtOH/EtOH','EtOH/Suc','NoEtOH/Suc'};
xticklabels(groups)
ylabel('Model Accuracy')
title('Post vs Pre Accuracy by Group (HMvsLM)')
% 
% [~,p_b4jazz,~,stats]   = ttest(RDvsOMrel{1}(:,1), RDvsOMrelshuff{1}(:,1));
% [~,p_afjazz,~,stats]   = ttest(RDvsOMrel{1}(:,2), RDvsOMrelshuff{1}(:,2));
% [~,p_b4grape,~,stats] = ttest(RDvsOMrel{2}(:,1),   RDvsOMrelshuff{2}(:,1)); 
% [~,p_afgrape,~,stats] = ttest(RDvsOMrel{2}(:,2),   RDvsOMrelshuff{2}(:,2));
% [~,p_b4melon,~,stats] = ttest(RDvsOMrel{3}(:,1),   RDvsOMrelshuff{3}(:,1)); 
% [~,p_afmelon,~,stats] = ttest(RDvsOMrel{3}(:,2),   RDvsOMrelshuff{3}(:,2));
% % Collect p-values
% pvals = [p_b4jazz, p_afjazz, p_b4grape, p_afgrape,p_b4melon,p_afmelon];
% 
% % Bonferroni correction
% alpha = 0.05;                                % desired familywise error rate
% nTests = numel(pvals);
% pvals_bonf = min(pvals * nTests, 1);         % corrected p-values
% sig_bonfhmvslm   = pvals_bonf < alpha;

% Group labels
Group = [repmat({'EtOH/EtOH'}, sizegroup(1), 1); 
         repmat({'EtOH/Suc'},  sizegroup(2), 1); 
         repmat({'NoEtOH/Suc'}, sizegroup(3), 1)];

Group = categorical(Group);

% Data table
T = table(groupaccuracy(:,1), groupaccuracy(:,2), Group, ...
    'VariableNames', {'PreLI','PostLI','Group'});

% Within-subject factor (Time)
WithinDesign = table(categorical({'PreLI'; 'PostLI'}), 'VariableNames', {'Time'});

% Fit repeated-measures model
rm = fitrm(T, 'PreLI-PostLI ~ Group', 'WithinDesign', WithinDesign);

% Run mixed ANOVA
ranovatbl = ranova(rm, 'WithinModel', 'Time');
disp(ranovatbl)

for t = 1:2
    mc=multcompare(rm, 'Group', 'By', 'Time', 'ComparisonType', 'bonferroni');
    timename=cellstr(unique(mc.Time));
    for i = find(ismember(mc.Time,timename(t)))'
        g1 = mc.Group_1(i);
        g2 = mc.Group_2(i);
        pval = mc.pValue(i);
        pMatrix(g1, g2, t) = pval;
        pMatrix(g2, g1, t) = pval; % symmetric
    end
end
for t = 1:2
    figure;
    heatmap(groups, groups, pMatrix(:,:,t), 'ColorLimits',[0 1]);
    title(['Post-hoc p-values for ', char(WithinDesign.Time(t))]);
end

multcompare(rm, 'Time', 'By', 'Group', 'ComparisonType', 'bonferroni')




%% rasters general

if contains(whichmat,'RD')
    [~,RAWequivalents]=ismember(variables(1:find(strcmp(variables,'FirstInBout'))),RAW(1).Einfo(:,2));
elseif contains(whichmat,'AT')
    if contains(whichmat,'intact')
        compvars={'LeverInsertion';'LeverRetract';'LeverInsertionRD';'LeverInsertionNoRD';'LeverRetractRD';'LeverRetractNoRD'};
        [~,Requivalents]=ismember(compvars,R.Erefnames);
        [~,RAWequivalents]=ismember(compvars,RAW(1).Einfo(:,2));
    else
        [~,RAWequivalents]=ismember(variables(idxtouse),RAW(1).Einfo(:,2));
    end
end
pres={};
   [~,preequivs]= ismember(pres,RAW(1).Einfo(:,2));
RAWequivalents(contains(variables, regexpPattern("Pre[A-Z]")))=preequivs;
   [~,evtstopull]=ismember(evtsinuse,variables);

    neur_torast=[significant{bestit}(:,evtstopull)];
    numbneurpersesh_included = [];
    sessionKeepIdx = []; % store index of sessions actually kept
    RAWRDidx=strcmp(RAW(1).Einfo(:,2),'RewardDeliv');
    trialtypeidx=strcmp(RAW(1).Einfo(:,2),'Trial Type');
    RAWLIidx=strcmp(RAW(1).Einfo(:,2),'LeverInsertion');
    RAWLRidx=strcmp(RAW(1).Einfo(:,2),'LeverRetract');
    if contains(whichmat,'RD')
        psth1='PSTHrdraw';
    else
        psth1='PSTHraw';
    end


    for s = 1:length(RAW)
        if size(RAW(s).Erast{RAWRDidx,1},1) >= 10
            sessionKeepIdx(end+1) = s;
            numbneurpersesh_included(end+1) = size(RAW(s).Ninfo,1);
        end
    end

    evtidxs= Requivalents;
    for evt=1:size(neur_torast,2)
        window = cell2mat(cellfun(@(x) [x(1)-0.1 x(end)+0.1], kernelssize(idxtouse(evt)), 'UniformOutput', false)); % Time window around event
        Ishow=find(R.Param.Tm>=window(1) & R.Param.Tm<=window(2));
        time1=R.Param.Tm(Ishow);
        eventName = evtsinuse{evt};

        modNeuronIdx=  find(neur_torast(:,evt));

        % ----- STEP 1: Map global neuron indices to session + within-session index
        cumNeur = cumsum(numbneurpersesh_included);
        modNeuronMap = [];  % rows: [globalIdx, sessionFullIdx, neuronIdxWithinSession]

        for i =  randperm(length(modNeuronIdx),10)
            globalIdx = modNeuronIdx(i);  % index in the 851-neuron set

            sessRelIdx = find(globalIdx <= cumNeur, 1, 'first');  % index in included sessions
            if sessRelIdx == 1
                neuronIdxSess = globalIdx;
            else
                neuronIdxSess = globalIdx - cumNeur(sessRelIdx - 1);
            end
            sessFullIdx = sessionKeepIdx(sessRelIdx);  % index in RAW

            modNeuronMap = [modNeuronMap; globalIdx, sessFullIdx, neuronIdxSess];
        end
        % ----- STEP 2: Plot combined rasters for each modulated neuron
        for i = 1:size(modNeuronMap, 1)
            sessIdx = modNeuronMap(i, 2);
            neuronIdxSess = modNeuronMap(i, 3);


            sessionData = RAW(sessIdx);
            spikes = sessionData.Nrast{neuronIdxSess}; % spike times for this neuron

            figure('Name', ['Neuron ' num2str(modNeuronMap(i,1))], 'Color', 'w'); hold on;
            subplot(2,1,1)
            currTrial = 0;
            evtidx=RAWequivalents(evt);

            eventTS = sessionData.Erast{evtidx}; %% change this to be the actual Time stamps
            if contains(whichmat,'RD')
                rdtrials=~strcmp(sessionData.Erast{trialtypeidx},'omission');
                RDLI=sessionData.Erast{RAWLIidx}(rdtrials);
                RDLR= sessionData.Erast{RAWLRidx}(rdtrials)+12;
                edges = [RDLI(:)'; RDLR(:)'];
                edges = edges(:)';
                [~,bin] = histc(eventTS, edges);
                keepMask = mod(bin,2)==1;
                eventTS= eventTS(keepMask);

            end
            for trial = 1:length(eventTS)
                currTrial = currTrial + 1; % running trial index
                alignTime = eventTS(trial);
                trialSpikes = spikes' - alignTime;
                trialSpikes = trialSpikes(trialSpikes >= window(1) & trialSpikes <= window(2));

                % Plot spike ticks
                if ~isempty(trialSpikes)
                    nSpikes = length(trialSpikes);
                    x = [trialSpikes; trialSpikes];                     % 2 x N
                    y = [currTrial - 0.4; currTrial + 0.4] * ones(1,nSpikes);  % 2 x N
                    line(x, y, 'Color', colors(evt,:),'LineWidth',1.5);
                end
            end
            nEvent1Trials = length(eventTS);


            % Formatting
            xlim(window);
            ylabel('Trial');
            ylim([0 currTrial + 1]);
            title(['Neuron ' num2str(modNeuronMap(i,1))]);

            % Optional: separator between event1 and event2 trials
            line([window(1) window(2)], [nEvent1Trials + 0.5 nEvent1Trials + 0.5], ...
                'Color', [0.7 0.7 0.7], 'LineStyle', '--');
            xline(0,'k')
            subplot(2,1,2)
            plot(time1,R.Ev(evtidxs(evt)).(psth1)(modNeuronMap(i,1),Ishow),'Color', colors(evt,:))
            xline(0,'k')
            ylabel('Z-Scored Firing Rate')
            xlim(window);

            xlabel('Time (s)');
        end
    end

    %% rasters (vs)
    window = [-0.1 0.6]; % Time window around event

   if contains(whichmat,'RD')
       [~,RAWequivalents]=ismember(variables(1:find(strcmp(variables,'FirstInBout'))),RAW(1).Einfo(:,2));
   elseif contains(whichmat,'AT')
       if contains(whichmat,'intact')
           compvars={'LeverInsertion';'LeverRetract';'LeverInsertionRD';'LeverInsertionNoRD';'LeverRetractRD';'LeverRetractNoRD'};
           [~,RAWequivalents]=ismember(compvars,RAW(1).Einfo(:,2));
       else
           [~,RAWequivalents]=ismember(variables(idxtouse),RAW(1).Einfo(:,2));
       end
   end
%    pres={'LeverPress1', 'PEntryRD'};
%    [~,preequivs]= ismember(pres,RAW(1).Einfo(:,2));
% RAWequivalents(contains(variables, regexpPattern("Pre[A-Z]")))=preequivs;
   [~,evtstopull]=ismember(evtsinuse,variables);

    if contains(whichmat,'RD')
        trialtypes={'high','low'};
        psth1='PSTHhmraw';
        psth2='PSTHlmraw';
        colors = {[0.77 0.1 0.37], [0.2 0.28 0.45]};
    else
        trialtypes={{'high','low'},'omission'};
        psth1='PSTHrdraw';
        psth2='PSTHomtraw';
        colors = {[0.01 0.87 0.02], [0.3 0.3 0.3]};
    end
    LI=significant{bestit}(:,LIidx)==1;
    LIonly=significant{bestit}(:,LIidx)==1 & significant{bestit}(:,LIintidx)==0;
    LIint=significant{bestit}(:,LIintidx)==1;
    LIintonly=significant{bestit}(:,LIidx)==0 & significant{bestit}(:,LIintidx)==1;
    LIboth=significant{bestit}(:,LIidx)==1 & significant{bestit}(:,LIintidx)==1;
    A = sum(LI); B = sum(LIint); AB = sum(LIboth);     % sizes
    r1 = sqrt(A/pi);
    r2 = sqrt(B/pi);

    % find center distance
    f = @(d) (d>=r1+r2)*0 + (d<=abs(r1-r2))*pi*min(r1,r2)^2 + ...
        (d>abs(r1-r2) & d<r1+r2).*( ...
        0.5*r1^2*(2*acos((d^2+r1^2-r2^2)/(2*d*r1)) - ...
        sin(2*acos((d^2+r1^2-r2^2)/(2*d*r1)))) + ...
        0.5*r2^2*(2*acos((d^2+r2^2-r1^2)/(2*d*r2)) - ...
        sin(2*acos((d^2+r2^2-r1^2)/(2*d*r2)))) );
    d = fzero(@(x) f(x)-AB, (r1+r2)/2);

    % draw circles
    t = linspace(0,2*pi,400);
    figure; hold on; axis equal off
    fill(r1*cos(t), r1*sin(t),'r','FaceAlpha',0.4,'EdgeColor','none')
    fill(d+r2*cos(t), r2*sin(t),'b','FaceAlpha',0.4,'EdgeColor','none')

    % text counts
    text(-r1/2, 0, num2str(A-AB), 'FontSize',12, 'HorizontalAlignment','center')   % A only
    text(d+r2/2, 0, num2str(B-AB), 'FontSize',12, 'HorizontalAlignment','center') % B only
    text(d/2, 0, num2str(AB), 'FontSize',12, 'HorizontalAlignment','center')      % overlap

    % circle labels
    text(0, r1+0.1*r1, 'LI', 'FontWeight','bold', 'HorizontalAlignment','center')
    text(d, r2+0.1*r2, 'LIint', 'FontWeight','bold', 'HorizontalAlignment','center')


    LR=significant{bestit}(:,LRidx)==1;
    LRonly=significant{bestit}(:,LRidx)==1 & significant{bestit}(:,LRintidx)==0;
    LRint=significant{bestit}(:,LRintidx)==1;
    LRintonly=significant{bestit}(:,LRidx)==0 & significant{bestit}(:,LRintidx)==1;
    LRboth=significant{bestit}(:,LRidx)==1 & significant{bestit}(:,LRintidx)==1;
    A = sum(LR); B = sum(LRint); AB = sum(LRboth);     % sizes
    r1 = sqrt(A/pi);
    r2 = sqrt(B/pi);

    % find center distance
    f = @(d) (d>=r1+r2)*0 + (d<=abs(r1-r2))*pi*min(r1,r2)^2 + ...
        (d>abs(r1-r2) & d<r1+r2).*( ...
        0.5*r1^2*(2*acos((d^2+r1^2-r2^2)/(2*d*r1)) - ...
        sin(2*acos((d^2+r1^2-r2^2)/(2*d*r1)))) + ...
        0.5*r2^2*(2*acos((d^2+r2^2-r1^2)/(2*d*r2)) - ...
        sin(2*acos((d^2+r2^2-r1^2)/(2*d*r2)))) );
    d = fzero(@(x) f(x)-AB, (r1+r2)/2);

    % draw circles
    t = linspace(0,2*pi,400);
    figure; hold on; axis equal off
    fill(r1*cos(t), r1*sin(t),'r','FaceAlpha',0.4,'EdgeColor','none')
    fill(d+r2*cos(t), r2*sin(t),'b','FaceAlpha',0.4,'EdgeColor','none')

    % text counts
    text(-r1/2, 0, num2str(A-AB), 'FontSize',12, 'HorizontalAlignment','center')   % A only
    text(d+r2/2, 0, num2str(B-AB), 'FontSize',12, 'HorizontalAlignment','center') % B only
    text(d/2, 0, num2str(AB), 'FontSize',12, 'HorizontalAlignment','center')      % overlap

    % circle labels
    text(0, r1+0.1*r1, 'LR', 'FontWeight','bold', 'HorizontalAlignment','center')
    text(d, r2+0.1*r2, 'LRint', 'FontWeight','bold', 'HorizontalAlignment','center')
    numbneurpersesh_included = [];
    sessionKeepIdx = []; % store index of sessions actually kept
    trialtypeidx=strcmp(RAW(1).Einfo(:,2), 'Trial Type');
    RAWRDidx=strcmp(RAW(1).Einfo(:,2),'RewardDeliv');
    Ishow=find(R.Param.Tm>=window(1) & R.Param.Tm<=window(2));
    time1=R.Param.Tm(Ishow);
    neur_torast=[LIonly,LIintonly,LIboth,LRonly,LRintonly,LRboth];


    for s = 1:length(RAW)
        if size(RAW(s).Erast{RAWRDidx,1},1) >= 10
            sessionKeepIdx(end+1) = s;
            numbneurpersesh_included(end+1) = size(RAW(s).Ninfo,1);
        end
    end
   evt_names={'LeverInsertion','LeverInsertion','LeverInsertion','LeverRetract','LeverRetract','LeverRetract'};
   titles={'LIonly','LIintonly','LIboth','LRonly','LRintonly','LRboth'};
  neuronstodraw=[randsample(find(LIonly),1),randsample(find(LIintonly),1),randsample(find(LIboth),1),randsample(find(LRonly),1),randsample(find(LRintonly),1),randsample(find(LRboth),1)];
    [~,evtidxsRAW]=ismember(evt_names,RAW(1).Einfo(:,2));
    [~,evtidxsR]=ismember(evt_names,R.Erefnames);
    for evt=1:size(neur_torast,2)
        eventName = evt_names{evt};

        modNeuronIdx=  neuronstodraw(evt); %randsample(find(neur_torast(:,evt)),5);

        % ----- STEP 1: Map global neuron indices to session + within-session index
        cumNeur = cumsum(numbneurpersesh_included);
        modNeuronMap = [];  % rows: [globalIdx, sessionFullIdx, neuronIdxWithinSession]

        for i = 1:length(modNeuronIdx)
            globalIdx = modNeuronIdx(i);  % index in the 851-neuron set

            sessRelIdx = find(globalIdx <= cumNeur, 1, 'first');  % index in included sessions
            if sessRelIdx == 1
                neuronIdxSess = globalIdx;
            else
                neuronIdxSess = globalIdx - cumNeur(sessRelIdx - 1);
            end
            sessFullIdx = sessionKeepIdx(sessRelIdx);  % index in RAW

            modNeuronMap = [modNeuronMap; globalIdx, sessFullIdx, neuronIdxSess];
        end
        % ----- STEP 2: Plot combined rasters for each modulated neuron
        for i = 1:size(modNeuronMap, 1)
            sessIdx = modNeuronMap(i, 2);
            neuronIdxSess = modNeuronMap(i, 3);


            sessionData = RAW(sessIdx);
            spikes = sessionData.Nrast{neuronIdxSess}; % spike times for this neuron

            figure('Name', ['Neuron ' num2str(modNeuronMap(i,1)) ' - ' titles{evt}], 'Color', 'w'); hold on;
            subplot(2,1,1)
            currTrial = 0;
            evtidx=evtidxsRAW(evt);

            for e = 1:2
                eventTS = sessionData.Erast{evtidx}(ismember(sessionData.Erast{trialtypeidx,1},trialtypes{e})); %% change this to be the actual Time stamps

                for trial = 1:length(eventTS)
                    currTrial = currTrial + 1; % running trial index
                    alignTime = eventTS(trial);
                    trialSpikes = spikes' - alignTime;
                    trialSpikes = trialSpikes(trialSpikes >= window(1) & trialSpikes <= window(2));

                    % Plot spike ticks
                    if ~isempty(trialSpikes)
                        nSpikes = length(trialSpikes);
                        x = [trialSpikes; trialSpikes];                     % 2 x N
                        y = [currTrial - 0.4; currTrial + 0.4] * ones(1,nSpikes);  % 2 x N
                        line(x, y, 'Color', colors{e},'LineWidth',1.5);
                    end
                end

                % Save index to draw separator line
                if e == 1
                    nEvent1Trials = length(eventTS);
                end
            end

            % Formatting
            xlim(window);
            ylabel('Trial');
            ylim([0 currTrial + 1]);
            title(['Neuron ' num2str(modNeuronMap(i,1)) ' - ' titles{evt}]);

            % Optional: separator between event1 and event2 trials
            line([window(1) window(2)], [nEvent1Trials + 0.5 nEvent1Trials + 0.5], ...
                'Color', [0.7 0.7 0.7], 'LineStyle', '--');
            xline(0,'k')
            subplot(2,1,2)
                plot(time1,R.Ev(evtidxsR(evt)).(psth1)(modNeuronMap(i,1),Ishow),'Color', colors{1})
                hold on
                line(time1,R.Ev(evtidxsR(evt)).(psth2)(modNeuronMap(i,1),Ishow),'Color', colors{2})
  

            xline(0,'k')
            ylabel('Z-Scored Firing Rate')
            xlim(window);

            xlabel('Time (s)');
        end
    end

    %%
    %--- Inputs ---
    load('SuperJazz1itSig.mat')
    significant_single = significant{1}(:,1:7);                    % Single value
    load('Grape100itSig.mat')
    significant_large1=cellfun(@(x) x(:,1:7),significant,'UniformOutput',false);
    load('Melon100itSig.mat')
    significant_large2=cellfun(@(x) x(:,1:7),significant,'UniformOutput',false);

sig_single = significant_single;          % 1-it group
varsinuse=1:length(eventNameskernel);
% 100-iteration groups: cell arrays, each cell neurons x events
sig_itersA = significant_large1;       % 100-it group A
sig_itersB = significant_large2;       % 100-it group B

nEvents = size(sig_single,2)-1;
nIters  = numel(sig_itersA);


counts_all = cell(1,nEvents);      % store counts per event
pvals_overall = nan(1,nEvents);    % overall 3-group chi2
pvals_pairwise = nan(nEvents,3);   % pairwise: 1vs2, 1vs3, 2vs3


for evt = 1:nEvents
    % --- Group 1 (1-it) ---
    sig1 = sig_single(:,evt);
    nSig1 = sum(sig1);
    nNon1 = numel(sig1) - nSig1;
    
    % --- Group 2 (100-it A) ---
    sigCountsA = zeros(nIters,2);
    for it = 1:nIters
        s = sig_itersA{it}(:,evt);
        sigCountsA(it,:) = [sum(s), numel(s)-sum(s)];
    end
    nSig2 = round(mean(sigCountsA(:,1)));
    nNon2 = round(mean(sigCountsA(:,2)));
    
    % --- Group 3 (100-it B) ---
    sigCountsB = zeros(nIters,2);
    for it = 1:nIters
        s = sig_itersB{it}(:,evt);
        sigCountsB(it,:) = [sum(s), numel(s)-sum(s)];
    end
    nSig3 = round(mean(sigCountsB(:,1)));
    nNon3 = round(mean(sigCountsB(:,2)));
    
    % --- Store counts ---
    counts_all{evt} = [nSig1, nNon1; nSig2, nNon2; nSig3, nNon3];
    
    % --- Overall 3-group chi-square test ---
    groupLabels = [ones(1,nSig1+nNon1), 2*ones(1,nSig2+nNon2), 3*ones(1,nSig3+nNon3)];
    sigStatus   = [ones(1,nSig1), zeros(1,nNon1), ...
                   ones(1,nSig2), zeros(1,nNon2), ...
                   ones(1,nSig3), zeros(1,nNon3)];
    [~,chi,p,stats] = crosstab(groupLabels, sigStatus);
    pvals_overall(evt) = p;
    chivals_overall(evt)=chi;
    
    % --- Pairwise 2x2 chi-square tests ---
    % 1 vs 2
    group12 = [ones(1,nSig1+nNon1), 2*ones(1,nSig2+nNon2)];
    sig12   = [ones(1,nSig1), zeros(1,nNon1), ones(1,nSig2), zeros(1,nNon2)];
    [~,chi12,p12] = crosstab(group12, sig12);
    pvals_pairwise(evt,1) = p12;
    chivals_pairwise(evt,1) = chi12;
    % 1 vs 3
    group13 = [ones(1,nSig1+nNon1), 2*ones(1,nSig3+nNon3)];
    sig13   = [ones(1,nSig1), zeros(1,nNon1), ones(1,nSig3), zeros(1,nNon3)];
    [~,chi13,p13] = crosstab(group13, sig13);
    pvals_pairwise(evt,2) = p13;
    chivals_pairwise(evt,2) = chi13;
    
    % 2 vs 3
    group23 = [ones(1,nSig2+nNon2), 2*ones(1,nSig3+nNon3)];
    sig23   = [ones(1,nSig2), zeros(1,nNon2), ones(1,nSig3), zeros(1,nNon3)];
    [~,chi23,p23] = crosstab(group23, sig23);
    pvals_pairwise(evt,3) = p23;
    chivals_pairwise(evt,3) = chi23;
end


adj_pvals_pairwise = min(pvals_pairwise*3, 1);


for evt = 1:nEvents
    fprintf('%s\n', eventNameskernel{varsinuse(evt)});
    fprintf('Counts (rows=groups, cols=sig/non-sig):\n');
    disp(counts_all{evt});
    fprintf('Overall 3-group chi2 p = %.4f\n', pvals_overall(evt));
    fprintf('Pairwise comparisons (p / Bonferroni-adjusted):\n');
    fprintf('  1 vs 2: %.4f / %.4f chi2= %.4f\n', pvals_pairwise(evt,1), adj_pvals_pairwise(evt,1), chivals_pairwise(evt,1));
    fprintf('  1 vs 3: %.4f / %.4f chi2= %.4f\n', pvals_pairwise(evt,2), adj_pvals_pairwise(evt,2), chivals_pairwise(evt,2));
    fprintf('  2 vs 3: %.4f / %.4f chi2= %.4f\n\n', pvals_pairwise(evt,3), adj_pvals_pairwise(evt,3), chivals_pairwise(evt,3));
end
    %% outcome neurons
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
    i=1;
    EOI={'LeverInsertion'; 'LeverRetract'}
    x=1;
    for j=1:numel(EOI)
        Sel = significant{1}(:,12+j);
        Eventindex = strcmp(EOI{j}, R.Erefnames);
        if ismember(EOI{j},{'LeverInsertion','LeverRetract'})
            NoRDEventindex = strcmp(strcat(EOI{j},'NoRD'),R.Erefnames);
            RDEventindex=strcmp(strcat(EOI{j},'RD'),R.Erefnames);
        elseif strcmp(EOI{j},'PEntry')
            NoRDEventindex = strcmp(strcat(EOI{j},'NoRDtrial1'),R.Erefnames);
            RDEventindex=strcmp(strcat(EOI{j},'RD'),R.Erefnames);
        end
        % Plotting neurons that respond to the lever insertion
        %positive beta weight neurons

        %     %average firing rate
        subplot_tight(2,4,x+(i-1)*7,[0.06,0.03]);
        psthI=mean(R.Ev(Eventindex).PSTHz(Sel,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
        semI=nanste(R.Ev(Eventindex).PSTHz(Sel,Ishow),1); %calculate standard error of the mean
        upI=psthI+semI;
        downI=psthI-semI;
        psthINoRD=mean(R.Ev(NoRDEventindex).PSTHz(Sel,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
        semINoRD=nanste(R.Ev(NoRDEventindex).PSTHz(Sel,Ishow),1); %calculate standard error of the mean
        upINoRD=psthINoRD+semINoRD;
        downINoRD=psthINoRD-semINoRD;
        psthIRD=mean(R.Ev(RDEventindex).PSTHz(Sel,Ishow),1,'omitnan'); %find the average firing rate of the neurons at the time of the event
        semIRD=nanste(R.Ev(RDEventindex).PSTHz(Sel,Ishow),1); %calculate standard error of the mean
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
        if rem(j,1)==0
            x=x+1;
        end

    end
       
    %% diverging cmap with start and end
    function c = dcmap(m,startc,endc,middlec)

    c = NaN(m,3);
    if (mod(m,2) == 0)
        increment=(middlec-startc)/(m/2);
        for x=1:m/2
            c(x,:)=startc+increment*(x-1);
        end
        increment=(endc-middlec)/(m/2);
        for x=1:m/2
            c(x+m/2,:)=middlec+increment*(x-1);
        end
    else
        increment=(middlec-start)/ceil(m/2);
        for x=1:ceil(m/2)
            c(x,:)=startc+increment*(x-1);
        end
        increment=(endc-middlec)/(m/2);
        for x=1:ceil(m/2)
            c(x+floor(m/2),:)=middlec+increment*(x-1);
        end
    end
    end
    %% get folds function
    function trains = getfolds(blockNum,folds)
    trialblockNum=unique(blockNum);
    for fold=1:folds
        step = mod([1:length(trialblockNum)]',folds)~=fold-1;
        trains{fold} = ismember(blockNum,trialblockNum(step));
    end
    end
    % function trains = getfolds(blockNum,folds)
    % for fold=1:folds
    %     trains{fold} = mod(blockNum,folds)~=fold-1;
    % end
    %
    % end


