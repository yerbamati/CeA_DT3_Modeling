%% create a struct with timestamps of all neurons and events

%before starting:
%put all nex files in the same folder
%name of each file starts with "NA1" or corresponding region and rat
%for water and 3 rewards sessions, "WA1" or "TH1" (all VP)

%need supporting programs "readNexFile" and "myfind"

clear all;clc
SAVE_FLAG=1;
tic

addpath(genpath('\\pbs-srv2.win.ad.jhu.edu\JanakLabTest\Matilde\MatLab\Supporting Programs'));
whichfolder=uigetdir('X:\Matilde\Ephys Data\');
sessionstring=questdlg('Which sessions shall we process?','Sessions','NOT','OMT','NOT');
firstidx=strfind(whichfolder,'(')+1;
finalidx=strfind(whichfolder,')')-1;
if strcmp(sessionstring,'NOT')~=1
    filename=strcat('RAW',whichfolder(firstidx:finalidx),sessionstring,'.mat');
else
    filename=strcat('RAW',whichfolder(firstidx:finalidx),'.mat');
end
addpath(whichfolder);

address=whichfolder;


AF=dir([address,'\',sessionstring,'-*-sorted-*.nex']);
Sesnum=0;

%Animal sexes
if  strcmp(filename,'RAWApple.mat')
    ratids={'FR07','FR09','FR10','FR11','FR12','FR13'};
    F={'FR09','FR10','FR12','FR13'};
    M={'FR07','FR11'};
elseif strcmp(filename,'RAWSuperJazz.mat')
    ratids={'FR21','FR22','FR23','FR25','FR27','FR28'};
    F={'FR22','FR28'};
    M={'FR21','FR23','FR25','FR27'};
    xlsstring='X:\Matilde\MatLab\CompiledEtOHConsumption.xlsx';
    opts=detectImportOptions(xlsstring,'Sheet','SuperJazz');
    opts.SelectedVariableNames=opts.SelectedVariableNames(1,[1,4,18]);
    opts.Sheet='SuperJazz';
    dosetable=readtable(xlsstring,opts);
    rat_ses=strcat(dosetable.Var1,'_',dosetable.Var4);
    dose_ses=table2array(dosetable(:,end));
elseif strcmp(filename,'RAWSuperApple.mat')
    ratids={'FR07','FR09','FR10','FR11','FR12','FR13','FR21','FR22','FR23','FR25','FR27','FR28'};
    F={'FR09','FR10','FR12','FR13','FR22','FR28'};
    M={'FR07','FR11','FR21','FR23','FR25','FR27'};
    xlsstring='X:\Matilde\MatLab\CompiledEtOHConsumption.xlsx';
    opts=detectImportOptions(xlsstring,'Sheet','SuperApple');
    opts.SelectedVariableNames=opts.SelectedVariableNames(1,[1,4,18]);
    opts.Sheet='SuperApple';
    dosetable=readtable(xlsstring,opts);
    rat_ses=strcat(dosetable.Var1,'_',dosetable.Var4);
    dose_ses=table2array(dosetable(:,end));
elseif strcmp(filename,'RAWGrape.mat')
    ratids={'FR29','FR30','FR32','FR33'};
    F={'FR30','FR32'};
    M={'FR29','FR33'};
elseif strcmp(filename,'RAWMelon.mat')
    ratids={'FR35','FR36','FR37','FR38','FR39','FR40'};
    F={'FR36','FR38','FR40'};
    M={'FR35','FR37','FR39'};
elseif strcmp(filename,'RAWMelonOMT.mat')
    ratids={'FR37','FR38','FR39','FR40'};
    F={'FR38','FR40'};
    M={'FR37','FR39'};
end

for k=1:length(AF)

    fname=AF(k).name;
    [nexfile] = readNexFile([address,'\\',fname]);  fprintf([fname,'\n'])
    Iind=myfind(nexfile.intervals,'AllFile');
    Sesnum=Sesnum+1;
    % Get all events timestamps for the selected session
    NUM_EVENTS=length(nexfile.events);
    for j=1:NUM_EVENTS
        evt=nexfile.events{j}.timestamps;
        RAW(Sesnum).Erast{j,1}=evt(find((evt>nexfile.intervals{Iind}.intStarts) & (evt<nexfile.intervals{Iind}.intEnds)));
        RAW(Sesnum).Einfo(j,:)={fname,nexfile.events{j}.name};
    end

    % start from neuron 1 get ready for the next session

    % Get the Neuron timestamps and waveforms
    NUM_NEURONS=length(nexfile.neurons);
    for j=1:NUM_NEURONS
        nrn=nexfile.neurons{j}.timestamps;
        RAW(Sesnum).Nrast{j,1}=nrn(find((nrn>nexfile.intervals{Iind}.intStarts) & (nrn<nexfile.intervals{Iind}.intEnds)));
        RAW(Sesnum).Ninfo(j,:)={fname,nexfile.neurons{j}.name};
    end
    RAW(Sesnum).Type=fname(1:4);
    RAW(Sesnum).Subject=fname(5:8);
    if ismember(RAW(Sesnum).Subject,F)
        RAW(Sesnum).Sex='F';
    elseif ismember(RAW(Sesnum).Subject,M)
        RAW(Sesnum).Sex='M';
    end
    RAW(Sesnum).Region=fname(end-6:end-4);
    if contains(filename,{'SuperApple','SuperJazz'})
        RAW(Sesnum).Doseage= dose_ses(cellfun(@(x) isequal(fname(5:12),x),rat_ses));
    end
end

% run latency and t2c calculations
% question2=questdlg('Scored or Raw Data?','LORS','Score','Raw','Raw');
% if strcmp(question2,'Raw')
lors=1;
% elseif strcmp(question2,'Score')
%     lors=2;
% end

restarteventidx=length(RAW(1).Erast)+1;
newvarstartidx=length(RAW(1).Erast)+7;

RD_time_rel_PERD_nojitter=[];
RD_time_rel_PERD_jitter=[];
RD_time_rel_LickRD_nojitter=[];
RD_time_rel_LickRD_jitter=[];
TimebetweenPEandLick_nojitter=[];
TimebetweenPEandLick_jitter=[];

for i=1:length(RAW)
    fprintf([RAW(i).Einfo{1, 1},'\n'])
    RD=strmatch('RewardDeliv',RAW(i).Einfo(:,2),'exact');
    if strcmp(sessionstring,RAW(i).Type(1:3)) %&& length(RAW(i).Erast{RD})>=10 % && strcmp(| strcmp('VP',RAW(i).Type(1:2))
        %make table with all information.
        %updated: 12.13.2024
        RD_time_rel_PERD_currses=[];
        trialTbl=table();
        LI=strcmp('LeverInsertion',RAW(i).Einfo(:,2));
        LInoRD=strcmp('LeverInsertionNoRD',RAW(i).Einfo(:,2));
        LIRD=strcmp('LeverInsertionRD',RAW(i).Einfo(:,2));
        LItimes=RAW(i).Erast{LI};
        LR=strcmp('LeverRetract',RAW(i).Einfo(:,2));
        LRnoRD=strcmp('LeverRetractNoRD',RAW(i).Einfo(:,2));
        LRRD=strcmp('LeverRetractRD',RAW(i).Einfo(:,2));
        LRtimes=RAW(i).Erast{LR};
        PERD=strcmp('PEntryRD',RAW(i).Einfo(:,2));
        trialTbl.trialNo=[1:length(LItimes)]';
        %trialTbl.trialType=RAW(i).Erast{end};
        trialTbl.LeverInsertion=LItimes;
        eventNames={'LeverInsertionNoRD';'LeverInsertionRD';'LeverPress';'LeverPress1';'LeverPress2';'EndPress';'LeverRetract';'LeverRetractRD';'LeverRetractNoRD';...
            'PEntry';'PEITI';'PEntryRD';'PEntryminusRD';'RewardDeliv';'Licks';'LickRD';'EndofRD';'Licklast'};
        for evt=1:length(eventNames)
            evInd=strcmp(eventNames(evt),RAW(i).Einfo(:,2)); %find LP1 in RAW.mat
            evTimes=RAW(i).Erast{evInd};
            if strcmp(eventNames{evt},'LeverPress') ||  strcmp(eventNames{evt},'PEntry') || strcmp(eventNames{evt},'PEntryminusRD')|| strcmp(eventNames{evt},'PEITI') || strcmp(eventNames{evt},'Licks')
                trialTbl.(eventNames{evt})=cell(length(LItimes),1);
            else
                trialTbl.(eventNames{evt})=NaN(length(LItimes),1);
            end
            for trl=1:length(LItimes)
                startTime=LItimes(trl)-15;
                endTime=LRtimes(trl)+12; % for port entry... should this be pre or post LI/LR?
                if strcmp(eventNames{evt},'LeverPress') || strcmp(eventNames{evt},'PEntry') || strcmp(eventNames{evt},'PEntryminusRD')|| strcmp(eventNames{evt},'PEITI')|| strcmp(eventNames{evt},'Licks')
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
        
        potentials=isnan(trialTbl.LeverInsertionRD)&~isnan(trialTbl.EndofRD);
        if sum(potentials)~=0
            if ~isnan(trialTbl.EndPress(potentials))
                trialTbl.LeverInsertionRD(potentials)= trialTbl.LeverInsertion(potentials);
                RAW(i).Erast{LIRD}=trialTbl.LeverInsertionRD(~isnan(trialTbl.LeverInsertionRD));
            end
        end
        potentials=~isnan(trialTbl.LeverInsertionNoRD)&~isnan(trialTbl.LeverInsertionRD);
        if sum(potentials)~=0
            if ~isnan(trialTbl.EndPress(potentials))
                trialTbl.LeverInsertionNoRD(potentials)=NaN;
                trialTbl.LeverRetractNoRD(potentials)=NaN;
                RAW(i).Erast{LInoRD}=trialTbl.LeverInsertionNoRD(~isnan(trialTbl.LeverInsertionNoRD));
                RAW(i).Erast{LRnoRD}=trialTbl.LeverRetractNoRD(~isnan(trialTbl.LeverRetractNoRD));
                RAW(i).Erast{LIRD}=trialTbl.LeverInsertionRD(~isnan(trialTbl.LeverInsertionRD));
                RAW(i).Erast{LRRD}=trialTbl.LeverRetractRD(~isnan(trialTbl.LeverRetractRD));
            else
                trialTbl.LeverInsertionRD(potentials)=NaN;
                trialTbl.LeverRetractRD(potentials)=NaN;
                RAW(i).Erast{LInoRD}=trialTbl.LeverInsertionNoRD(~isnan(trialTbl.LeverInsertionNoRD));
                RAW(i).Erast{LRnoRD}=trialTbl.LeverRetractNoRD(~isnan(trialTbl.LeverRetractNoRD));
                RAW(i).Erast{LIRD}=trialTbl.LeverInsertionRD(~isnan(trialTbl.LeverInsertionRD));
                RAW(i).Erast{LRRD}=trialTbl.LeverRetractRD(~isnan(trialTbl.LeverRetractRD));
            end
        end
        potentials=isnan(trialTbl.PEntryRD)&~isnan(trialTbl.LeverInsertionRD);
        if sum(potentials)~=0
            ifl=find(potentials);
            for pot=1:sum(potentials)
                if isnan(trialTbl.PEntry{ifl(pot)})
                    trialTbl.PEntryRD(ifl(pot))=NaN;
                elseif isscalar(trialTbl.PEntry{ifl(pot)}) && trialTbl.PEntry{ifl(pot)}<trialTbl.LeverRetractRD(ifl(pot))
                    trialTbl.PEntryRD(ifl(pot))=NaN;
                else
                    possiblePEs=trialTbl.PEntry{ifl(pot)};
                    PEafterLR=find(possiblePEs>trialTbl.LeverRetract(ifl(pot)),1);
                    if ~isempty(PEafterLR)
                    trialTbl.PEntryRD(ifl(pot))=possiblePEs(PEafterLR);
                    end
                end
            end
        end
        RAW(i).Erast{PERD}=trialTbl.PEntryRD(~isnan(trialTbl.PEntryRD));
        if length(RAW(i).Erast{PERD})~=length(RAW(i).Erast{LIRD})
            disp('mismatch')
            if sum(isnan(trialTbl.PEntryRD) & ~isnan(trialTbl.RewardDeliv))~=0
                disp('mismatch driven by MPC TTLs --> PE probably did not happen, despite RD')
                disp(find(isnan(trialTbl.PEntryRD) & ~isnan(trialTbl.RewardDeliv)))
            end
        end
        trialTbl.PEntryRDtrials(~isnan(trialTbl.EndPress))=trialTbl.PEntry(~isnan(trialTbl.EndPress));
        trialTbl.PEntryRDtrials(isnan(trialTbl.EndPress))={NaN};
        trialTbl.PEntryNoRDtrials(isnan(trialTbl.EndPress))=trialTbl.PEntry(isnan(trialTbl.EndPress));
        trialTbl.PEntryNoRDtrials(~isnan(trialTbl.EndPress))={NaN};
        indices = cellfun(@(cell_vec, mat_val) find(cell_vec > mat_val, 1, 'first'), trialTbl.PEntry, num2cell(trialTbl.LeverInsertion), 'UniformOutput', false);
        trialTbl.PEntryNoRDtrial1=cellfun(@(x, idx) x(idx), trialTbl.PEntry,indices,'UniformOutput',false);
        trialTbl.PEntryNoRDtrial1(logical(cellfun(@(x) isempty(x),trialTbl.PEntryNoRDtrial1)))={NaN};
        trialTbl.PEntryNoRDtrial1(~isnan(trialTbl.EndPress))={NaN};
        dirtyRDarray=cell2mat(trialTbl.PEntryRDtrials);
        dirtyNoRDarray=cell2mat(trialTbl.PEntryNoRDtrials);
        dirtyNoRD1array=cell2mat(trialTbl.PEntryNoRDtrial1);
        RAW(i).Erast{restarteventidx}=dirtyRDarray(~isnan(dirtyRDarray));
        RAW(i).Einfo{restarteventidx,2}='PEntryRDtrial';
        RAW(i).Erast{restarteventidx+1}=dirtyNoRDarray(~isnan(dirtyNoRDarray));
        RAW(i).Einfo{restarteventidx+1,2}='PEntryNoRDtrial';
        RAW(i).Erast{restarteventidx+2}=dirtyNoRD1array(~isnan(dirtyNoRD1array));
        RAW(i).Einfo{restarteventidx+2,2}='PEntryNoRDtrial1';
        %for bout calculations
        typelicks=cell2mat(trialTbl.Licks);
        typelicks(isnan(typelicks))=[];
        firstinclust=[];
        typediff=diff(typelicks);
        lickswithincluster=find(typediff<0.5);
        if length(lickswithincluster)>4
            firstinclust=lickswithincluster(1);
            for j=2:length(lickswithincluster)
                if (lickswithincluster(j)-lickswithincluster(j-1))>1
                    firstinclust=cat(1,firstinclust,lickswithincluster(j));
                end
            end
        end
        lickspertrial=cellfun(@(x) sum(~isnan(x)),trialTbl.Licks);
        split_points=[cumsum(lickspertrial)];
        licksintrial=mat2cell(1:sum(cellfun(@(x) sum(~isnan(x)),trialTbl.Licks)),1,[cellfun(@(x) sum(~isnan(x)),trialTbl.Licks)]);
        firstLickTrialIdx = discretize(firstinclust, [0; split_points]);
        boutsperrd = accumarray(firstLickTrialIdx(:), 1, [length(licksintrial), 1]);
        boutsperrd(isnan(trialTbl.RewardDeliv))=[];
        %for actual raster
        typelicks=RAW(i).Erast{strcmp(RAW(i).Einfo(:,2),'Licks'),1};
        typelicks(isnan(typelicks))=[];
        firstinclust=[];
        typediff=diff(typelicks);
        lickswithincluster=find(typediff<0.5);
        if length(lickswithincluster)>4
            firstinclust=lickswithincluster(1);
            for j=2:length(lickswithincluster)
                if (lickswithincluster(j)-lickswithincluster(j-1))>1
                    firstinclust=cat(1,firstinclust,lickswithincluster(j));
                end
            end
        end
        RAW(i).Erast{restarteventidx+3}=RAW(i).Erast{strcmp(RAW(i).Einfo(:,2),'Licks'),1}(firstinclust);
        RAW(i).Einfo{restarteventidx+3,2}='FirstInBout';
        unrewardedLP1=~isnan(trialTbl.LeverPress1) & isnan(trialTbl.EndPress);
        cleanedLP1ts=trialTbl.LeverPress1;
        cleanedLP1ts(unrewardedLP1)=NaN;
        LPlat=cleanedLP1ts-trialTbl.LeverInsertion;
        Time2Complete=trialTbl.EndPress-cleanedLP1ts;
        PElat=trialTbl.PEntryRD-trialTbl.EndPress;
        licksperrd=cellfun(@(x) size(x(~isnan(x)),1),trialTbl.Licks);
        licksperrd(isnan(trialTbl.RewardDeliv))=[];
        RAW(i).Erast{restarteventidx+4}=licksperrd;
        RAW(i).Einfo{restarteventidx+4,2}='Licks Per RD';
        RAW(i).Erast{restarteventidx+5}=boutsperrd;
        RAW(i).Einfo{restarteventidx+5,2}='Bouts Per RD';
        RAW(i).Erast{newvarstartidx}=LPlat(~isnan(LPlat));
        RAW(i).Einfo{newvarstartidx,2}='LP Latency';
        RAW(i).Erast{newvarstartidx+1}=LPlat;
        RAW(i).Einfo{newvarstartidx+1,2}= 'Trial-based LP Latency';
        RAW(i).Erast{newvarstartidx+2}=Time2Complete(~isnan(Time2Complete));
        RAW(i).Einfo{newvarstartidx+2,2}='Time2Complete';
        RAW(i).Erast{newvarstartidx+3}= Time2Complete;
        RAW(i).Einfo{newvarstartidx+3,2}= 'Trial-based Time2Complete';
        RAW(i).Erast{newvarstartidx+4}= PElat(~isnan(PElat));
        RAW(i).Einfo{newvarstartidx+4,2}= 'PE Latency';
        RAW(i).Erast{newvarstartidx+5}= PElat;
        RAW(i).Einfo{newvarstartidx+5,2}= 'Trial-based PE Latency';
        RAW(i).Einfo{newvarstartidx+7,2}='Trial Type';

        RD_time_rel_PERD_currses=trialTbl.PEntryRD - trialTbl.RewardDeliv;
        RD_time_rel_LickRD_currses= trialTbl.LickRD - trialTbl.RewardDeliv;
        TimebetweenPEandLick= trialTbl.PEntryRD - trialTbl.LickRD;
        if strcmp(RAW(i).Subject,'FR07') || strcmp(RAW(i).Subject,'FR09') || strcmp(RAW(i).Subject,'FR10') || strcmp(RAW(i).Subject,'FR11') || strcmp(RAW(i).Subject,'FR12') || strcmp(RAW(i).Subject,'FR13')
            RD_time_rel_PERD_nojitter=[RD_time_rel_PERD_nojitter;RD_time_rel_PERD_currses(~isnan(RD_time_rel_PERD_currses))];
            RD_time_rel_LickRD_nojitter=[RD_time_rel_LickRD_nojitter;RD_time_rel_LickRD_currses(~isnan(RD_time_rel_LickRD_currses))];
            TimebetweenPEandLick_nojitter=[TimebetweenPEandLick_nojitter;TimebetweenPEandLick(~isnan(TimebetweenPEandLick))];
        elseif strcmp(RAW(i).Subject,'FR21') || strcmp(RAW(i).Subject,'FR22') || strcmp(RAW(i).Subject,'FR23') || strcmp(RAW(i).Subject,'FR25') || strcmp(RAW(i).Subject,'FR27') || strcmp(RAW(i).Subject,'FR28')
            RD_time_rel_PERD_jitter=[RD_time_rel_PERD_jitter;RD_time_rel_PERD_currses(~isnan(RD_time_rel_PERD_currses))];
            RD_time_rel_LickRD_jitter=[RD_time_rel_LickRD_jitter;RD_time_rel_LickRD_currses(~isnan(RD_time_rel_LickRD_currses))];
            TimebetweenPEandLick_jitter=[TimebetweenPEandLick_jitter;TimebetweenPEandLick(~isnan(TimebetweenPEandLick))];
        end
        if contains(filename,'OMT')
            trialTbl.trialType(~isnan(trialTbl.EndPress) & isnan(trialTbl.RewardDeliv))= {'forced omission'};
            RAW(i).Erast{newvarstartidx+7,1}(:,1)=trialTbl.trialType(:,1);
        end
    end
end
    globallplatency=[];
    globalt2c=[];
    globalpelatency=[];
    globalscores=[];


    for rat=1:length(ratids)
        lplatency=[];
        t2c=[];
        pelatency=[];
        scores=[];

        for s=1:length(RAW)
            LIidx= strcmp('LeverInsertion',RAW(s).Einfo(:,2));
            RDidx= strcmp('RewardDeliv',RAW(s).Einfo(:,2));
            lplatidx=strcmp('LP Latency',RAW(s).Einfo(:,2));
            t2cidx=strcmp('Time2Complete',RAW(s).Einfo(:,2));
            peidx=strcmp('PE Latency',RAW(s).Einfo(:,2));
            if strcmp(cell2mat(ratids(rat)),RAW(s).Subject)==1
                lplatency=[lplatency; RAW(s).Erast{lplatidx}];
                t2c=[t2c; RAW(s).Erast{t2cidx}];
                pelatency=[pelatency; RAW(s).Erast{peidx}];
                if (length(lplatency)==length(t2c))&&(length(t2c)~=length(pelatency))
                    pelatency(end+1:length(lplatency))=NaN;
                end
            end
        end
        paramsrat=NaN(max([length(lplatency),length(t2c),length(pelatency)]),3);
        paramsrat=[lplatency,t2c,pelatency];
        [c, p]=corr(paramsrat,'Rows','pairwise');
        fprintf('%s coefficient\n',cell2mat(ratids(rat)))
        fprintf('%-5.5g %-5.5g %-5.5g \n',c(:,1),c(:,2),c(:,3))
        fprintf('%s p-value\n',cell2mat(ratids(rat)))
        fprintf('%-5.5g %-5.5g %-5.5g \n',p(:,1),p(:,2),p(:,3))
        for ses=find(strcmp(ratids(rat),{RAW.Subject}))
            RAW(ses).Erast{newvarstartidx,2}=(RAW(ses).Erast{newvarstartidx,1}-min(lplatency))/(max(lplatency)-min(lplatency));
            RAW(ses).Einfo{newvarstartidx,3}='LP Latency Score';
            counter=1;
            for row=1:length(RAW(ses).Erast{newvarstartidx+1,1})
                if ~isnan(RAW(ses).Erast{newvarstartidx+1,1}(row))
                    RAW(ses).Erast{newvarstartidx+1,2}(row,1)=RAW(ses).Erast{newvarstartidx,2}(counter);
                    counter=counter+1;
                else
                    RAW(ses).Erast{newvarstartidx+1,2}(row,1)=NaN;
                end
            end
            RAW(ses).Einfo{newvarstartidx+1,3}= 'Trial-based LP Latency Score';
            RAW(ses).Erast{newvarstartidx+2,2}=(RAW(ses).Erast{newvarstartidx+2,1}-min(t2c))/(max(t2c)-min(t2c));
            RAW(ses).Einfo{newvarstartidx+2,3}='Time2Complete Score';
            counter=1;
            for row=1:length(RAW(ses).Erast{newvarstartidx+3,1})
                if ~isnan(RAW(ses).Erast{newvarstartidx+3,1}(row))
                    RAW(ses).Erast{newvarstartidx+3,2}(row,1)=RAW(ses).Erast{newvarstartidx+2,2}(counter);
                    counter=counter+1;
                else
                    RAW(ses).Erast{newvarstartidx+3,2}(row,1)=NaN;
                end
            end
            RAW(ses).Einfo{newvarstartidx+3,3}= 'Trial-based Time2Complete Score';
            RAW(ses).Erast{newvarstartidx+4,2}= (RAW(ses).Erast{newvarstartidx+4,1}-min(pelatency))/(max(pelatency)-min(pelatency));
            RAW(ses).Einfo{newvarstartidx+4,3}= 'PE Latency Score';
            counter=1;
            for row=1:length(RAW(ses).Erast{newvarstartidx+5,1})
                if ~isnan(RAW(ses).Erast{newvarstartidx+5,1}(row))
                    RAW(ses).Erast{newvarstartidx+5,2}(row,1)=RAW(ses).Erast{newvarstartidx+4,2}(counter);
                    counter=counter+1;
                else
                    RAW(ses).Erast{newvarstartidx+5,2}(row,1)=NaN;
                end
            end
            RAW(ses).Einfo{newvarstartidx+5,3}= 'Trial-based PE Latency Score';
            RAW(ses).Erast{newvarstartidx+6,1}=mean([RAW(ses).Erast{newvarstartidx+1,lors}],2);
            RAW(ses).Einfo{newvarstartidx+6,2}='Trial Behavioral Metric';

        end
        for s=find(strcmp(ratids(rat),{RAW.Subject}))
            if strcmp(cell2mat(ratids(rat)),RAW(s).Subject)==1
                scores=[scores;RAW(s).Erast{newvarstartidx,lors}(~isnan(RAW(s).Erast{newvarstartidx,lors}))];
            end
        end
        mediancutoff=quantile(scores,0.5);
        mediancutoffquarter=quantile(scores,0.25);
        mediancutoffthreequarter=quantile(scores,0.75);
        globallplatency=[globallplatency; lplatency];
        globalt2c=[globalt2c; t2c];
        globalpelatency=[globalpelatency; pelatency];
        globalscores=[globalscores;scores];
        for sss=find(strcmp(ratids(rat),{RAW.Subject}))
            for trial=1:length(RAW(sss).Erast{LIidx})
                row2use=newvarstartidx+6;
                col2use=1;
                if isempty(RAW(sss).Erast{newvarstartidx+7,1}{trial,1}) && RAW(sss).Erast{row2use,col2use}(trial,1)<=mediancutoff
                    RAW(sss).Erast{newvarstartidx+7,1}{trial,1}='high';
                elseif isempty(RAW(sss).Erast{newvarstartidx+7,1}{trial,1}) && RAW(sss).Erast{row2use,col2use}(trial,1)>mediancutoff
                    RAW(sss).Erast{newvarstartidx+7,1}{trial,1}='low';
                elseif isempty(RAW(sss).Erast{newvarstartidx+7,1}{trial,1})
                    RAW(sss).Erast{newvarstartidx+7,1}{trial,1}='omission';
                end
            end
        end
    end
    % if strcmp(question2,'Raw')
    save([filename(1:end-4) '_Latency_raw.mat'],'RAW');
    % elseif strcmp(question2,'Score')
    %     save([filename(1:end-4) '_Latency_score.mat'],'RAW');
    % end
    globalfastlplatency=quantile(globallplatency,0.5);

    toc
    % %% SAVING DATA
    % if SAVE_FLAG
    %     save(filename,'RAW')
    % end
    % fprintf('\n')
    % toc
