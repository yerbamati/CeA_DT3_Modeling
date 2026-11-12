% Pointwise GIANT RAT SVM (DECODER)
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

if exist('includeq','var')
    useincludeq = true;
else
    useincludeq = false;
end

load(whichRAW);
numbrats=50;

% event indexes of interest
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
SesEnd=strcmp('SessionEnd',RAW(1).Einfo(:,2));
ratnames=unique({RAW.Subject});
nmodels=1; % for lesioning modelsize(ratnames,2)+1;
nbinsLI=length(windowStartLI:binsize:windowEndLI)-1;
nbinsLR=length(windowStartLR:binsize:windowEndLR)-1;

% RDvsOM
PointWiseAccuracyRDvsOMLI=struct;
fprintf('\nRDvsOM')

for seed=1:10

    m1=fprintf('\nSeed %d/10: [',seed);
    m2=fprintf(repelem(':',numbrats));
    m3=fprintf('] GR 0/%d',numbrats);

    for gr=1:numbrats

        rn=1;
        matcounter=1;
        clearvars popbline goodneurons neurbyneurRatID;

        baseSeed=(seed-1)*numbrats+gr;
        rng(baseSeed,'twister');

        for i=1:length(RAW)

            [neuronspersesh,~]=size(RAW(i).Ninfo);

            if length(RAW(i).Erast{RD})>=10

                if length(RAW(i).Erast{RD})>=trials2pull && sum(strcmp(RAW(i).Erast{trialtype,1},'omission'))>=trials2pull

                    rewardedtrialts=RAW(i).Erast{LI}(~strcmp(RAW(i).Erast{trialtype,1},'omission'),:);
                    omittedtrialindts=RAW(i).Erast{LI}(strcmp(RAW(i).Erast{trialtype,1},'omission'),:);

                    % Trials are selected once here. Raw, shuffled, and subsampled SVMs below all use the same observations contained in popbline.
                    randrdtrialstart=rewardedtrialts(randperm(length(rewardedtrialts),trials2pull));
                    randomtrialstart=omittedtrialindts(randperm(length(omittedtrialindts),trials2pull));

                    for neur=1:neuronspersesh

                        %randrdactivity=R.FiringRate(rn,randrdtrialstart);
                        avgactivity=mean(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25}));
                        stdactivity=std(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25}));

                        randrdactivity=arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur}>=(t0+windowStartLI) & RAW(i).Nrast{neur}<=(t0+windowEndLI)),randrdtrialstart,'UniformOutput',false);
                        randrdactivity=cellfun(@(spk,t0) histcounts(spk-t0,binEdgesLI),randrdactivity,num2cell(randrdtrialstart),'UniformOutput',false);
                        randrdactivity=cellfun(@(x) (x-avgactivity)/stdactivity,randrdactivity,'UniformOutput',false);

                        randomactivity=arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur}>=(t0+windowStartLI) & RAW(i).Nrast{neur}<=(t0+windowEndLI)),randomtrialstart,'UniformOutput',false);
                        randomactivity=cellfun(@(spk,t0) histcounts(spk-t0,binEdgesLI),randomactivity,num2cell(randomtrialstart),'UniformOutput',false);
                        randomactivity=cellfun(@(x) (x-avgactivity)/stdactivity,randomactivity,'UniformOutput',false);

                        popbline(:,matcounter)=vertcat(randrdactivity,randomactivity);
                        neurbyneurRatID{matcounter,1}=RAW(i).Subject;
                        neurbyneurRatID{matcounter,2}=regexp(RAW(i).Einfo{1,1},'(?<=_)[^-]+','match','once');
                        matcounter=matcounter+1;

                    end

                else
                end
            end
        end

        % precompute neuron masks
        goodneurons=cell(nmodels,1);

        for model=1:nmodels

            if model==1

                goodneurons{model}=ismember(neurbyneurRatID(:,1),ratnames);

                if useincludeq

                    vidmod=significant{bestit}(logical(goodneurons{model}),strcmp(variables,'VideoComponents'));
                    [sessrat,rat,session]=findgroups(neurbyneurRatID(:,1),neurbyneurRatID(:,2));

                    % Force neuron/session masks into matching column-vector orientation
                    vidmod=vidmod(:);
                    sessrat=sessrat(:);

                    nVideo=accumarray(sessrat,double(vidmod));
                    nNotVideo=accumarray(sessrat,double(~vidmod));
                    nRemove=min(nVideo,nNotVideo);
                    nTotal=accumarray(sessrat,ones(size(vidmod,1),1));
                    nVideoTotal=[nVideo nTotal nVideo./nTotal];

                    % Sessions must contain both VM and NVM neurons
                    eligibleSess=(nVideo>0) & (nNotVideo>0);
                    eligibleSess=eligibleSess(:);

                    all20randomGoodNeurons=[];
                    randomVideoRemoved=zeros(length(nVideo),20);
                    randomnotVideoRemoved=zeros(length(nVideo),20);
                    % Depletion model
                    for r=1:20

                        % Exclude all neurons from one-population sessions immediately
                        randomGoodNeurons=eligibleSess(sessrat);
                        randomGoodNeurons=randomGoodNeurons(:);
                        for sr=1:length(nVideo)

                            thisSess=(sessrat==sr);
                            thisSess=thisSess(:);

                            if eligibleSess(sr)

                                if strcmp(includeq,'yes')

                                    % NVM-depleted minimum control
                                    neurons_okaytoremove=find(thisSess & ~vidmod);

                                elseif strcmp(includeq,'no')

                                    % VM-depleted
                                    neurons_okaytoremove=find(thisSess & vidmod);

                                end

                                subsampleSeed=1000000+baseSeed*100000+r*1000+sr;
                                rng(subsampleSeed,'twister');
                                randomindices=randperm(length(neurons_okaytoremove),nRemove(sr));
                                remove=neurons_okaytoremove(randomindices);
                                randomGoodNeurons(remove)=false;

                                randomVideoRemoved(sr,r)=sum(vidmod(remove));
                                randomnotVideoRemoved(sr,r)=sum(~vidmod(remove));

                            else

                                randomVideoRemoved(sr,r)=nVideo(sr);
                                randomnotVideoRemoved(sr,r)=nNotVideo(sr);

                            end
                        end

                        all20randomGoodNeurons(:,r)=randomGoodNeurons;

                    end

                end

            else

                goodneurons{model}=~ismember(neurbyneurRatID(:,1),ratnames(model-1));

            end
        end

        % make jobs
        [modellist,binlist]=ndgrid(1:nmodels,1:nbinsLI);
        modellist=modellist(:);
        binlist=binlist(:);

        testaccuracy=zeros(nmodels*nbinsLI,1);
        meanshuffledaccuracy=zeros(nmodels*nbinsLI,1);
        totalshuffledaccuracy=zeros(nmodels*nbinsLI,100);
        subsamptestaccuracy=zeros(20,nmodels*nbinsLI);

        y=[ones(length(randrdtrialstart),1);(zeros(length(randomtrialstart),1)+2)];
        cvSeed=2000000+baseSeed;
        rng(cvSeed,'twister');
        cv_partition=cvpartition(y,KFold=methodstring2,Stratify=true);
        
        parfor job=1:length(modellist)

            model=modellist(job);
            bin=binlist(job);

            x_full=cellfun(@(x) x(bin),popbline(:,goodneurons{model}));

            % Preserve the original x variable for the raw SVM.
            x=x_full;

            % Raw SVM
            % Wholesale VM-removal analysis.
            if useincludeq

                if strcmp(includeq,'no')

                    x(:,significant{bestit}(logical(goodneurons{model}),strcmp(variables,'VideoComponents')))=[];

                end
            end

            x_train=x;
            y_train=y;

            Mdl2=fitcsvm(x_train,y_train,'KernelFunction','linear','CVPartition',cv_partition,'Standardize',false);

            l=kfoldPredict(Mdl2);

            testaccuracy(job)=sum(l==y_train)/length(y_train)*100;

            % shuffled SVM
            tmp=zeros(100,1);
            shuffleSeed=3000000+baseSeed;
            cvShuffSeed=2500000+baseSeed;

            for s=1:100
                rng(shuffleSeed+s,'twister');
                y_trainshuff=y(randperm(length(y)));

                rng(cvShuffSeed+s,'twister');
                cv_partition_shuff=cvpartition(y_trainshuff,KFold=methodstring2,Stratify=true);

                Mdlshuff=fitcsvm(x_train,y_trainshuff,'KernelFunction','linear','CVPartition',cv_partition_shuff,'Standardize',false);

                ls=kfoldPredict(Mdlshuff);

                tmp(s)=sum(ls==y_trainshuff)/length(y_trainshuff)*100;

            end

            totalshuffledaccuracy(job,:)=tmp;

            meanshuffledaccuracy(job)=mean(tmp);

            if useincludeq

                if model==1

                    for sub=1:20
                        xsub=x_full(:,logical(all20randomGoodNeurons(:,sub)));

                        x_train=xsub;
                        y_train=y;

                        Mdl2=fitcsvm(x_train,y_train,'KernelFunction','linear','CVPartition',cv_partition,'Standardize',false);

                        l=kfoldPredict(Mdl2);

                        subsamptestaccuracy(sub,job)=sum(l==y_train)/length(y_train)*100;

                    end
                end

            end

        end

        testaccuracy=reshape(testaccuracy,nmodels,nbinsLI);

        meanshuffledaccuracy=reshape(meanshuffledaccuracy,nmodels,nbinsLI);

        totalshuffledaccuracy=reshape(totalshuffledaccuracy,nmodels,nbinsLI,100);
        totalshuffledaccuracy=permute(totalshuffledaccuracy,[1 3 2]);

        subsamptestaccuracy=subsamptestaccuracy(:,modellist==1);

        PointWiseAccuracyRDvsOMLI(seed,gr).testaccuracy=testaccuracy;
        PointWiseAccuracyRDvsOMLI(seed,gr).totalshuffledaccuracy=totalshuffledaccuracy;
        PointWiseAccuracyRDvsOMLI(seed,gr).meanshuffledaccuracy=meanshuffledaccuracy;
        PointWiseAccuracyRDvsOMLI(seed,gr).subsamptestaccuracy=subsamptestaccuracy;

        if gr==1

            fprintf(repmat('\b',1,m1+m2+m3));
            m4=fprintf('\nSeed %d/10: [',seed);
            m5=fprintf(repelem('|',gr));
            m6=fprintf(repelem(':',numbrats-gr));
            m7=fprintf('] GR %d/%d',gr,numbrats);

        else

            fprintf(repmat('\b',1,m4+m5+m6+m7));
            m4=fprintf('\nSeed %d/10: [',seed);
            m5=fprintf(repelem('|',gr));
            m6=fprintf(repelem(':',numbrats-gr));
            m7=fprintf('] GR %d/%d',gr,numbrats);

        end
    end
end



% HMvsLM
PointWiseAccuracyHMvsLMLI=struct;
fprintf('\nHMvsLM')

for seed=1:10

    m1=fprintf('\nSeed %d/10: [',seed);
    m2=fprintf(repelem(':',numbrats));
    m3=fprintf('] GR 0/%d',numbrats);

    for gr=1:numbrats

        rn=1;
        matcounter=1;
        clearvars popbline goodneurons neurbyneurRatID;
        baseSeed=(seed-1)*numbrats+gr;
        rng(baseSeed,'twister');

        for i=1:length(RAW)

            [neuronspersesh,~]=size(RAW(i).Ninfo);

            if length(RAW(i).Erast{RD})>=10

                if  sum(strcmp(RAW(i).Erast{trialtype,1},'high'))>= trials2pull && sum(strcmp(RAW(i).Erast{trialtype,1},'low'))>= trials2pull

                    hmtrialts=RAW(i).Erast{LI}(strcmp(RAW(i).Erast{trialtype,1},'high'),:);
                    lmtrialts=RAW(i).Erast{LI}(strcmp(RAW(i).Erast{trialtype,1},'low'),:);
                    randHMtrialstart=hmtrialts(randperm(length(hmtrialts),trials2pull));
                    randLMtrialstart=lmtrialts(randperm(length(lmtrialts),trials2pull));

                    for neur=1:neuronspersesh

                        %randrdactivity=R.FiringRate(rn,randrdtrialstart);
                        avgactivity=mean(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25}));
                        stdactivity=std(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25}));

                        randHMactivity=arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur}>=(t0+windowStartLI) & RAW(i).Nrast{neur}<=(t0+windowEndLI)),randHMtrialstart,'UniformOutput',false);
                        randHMactivity=cellfun(@(spk,t0) histcounts(spk-t0,binEdgesLI),randHMactivity,num2cell(randHMtrialstart),'UniformOutput',false);
                        randHMactivity=cellfun(@(x) (x-avgactivity)/stdactivity,randHMactivity,'UniformOutput',false);

                        randLMactivity=arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur}>=(t0+windowStartLI) & RAW(i).Nrast{neur}<=(t0+windowEndLI)),randLMtrialstart,'UniformOutput',false);
                        randLMactivity=cellfun(@(spk,t0) histcounts(spk-t0,binEdgesLI),randLMactivity,num2cell(randLMtrialstart),'UniformOutput',false);
                        randLMactivity=cellfun(@(x) (x-avgactivity)/stdactivity,randLMactivity,'UniformOutput',false);

                        popbline(:,matcounter)=vertcat(randHMactivity,randLMactivity);
                        neurbyneurRatID{matcounter,1}=RAW(i).Subject;
                        neurbyneurRatID{matcounter,2}=regexp(RAW(i).Einfo{1,1},'(?<=_)[^-]+','match','once');
                        matcounter=matcounter+1;

                    end

                else
                end
            end
        end

        % precompute neuron masks
        goodneurons=cell(nmodels,1);

        for model=1:nmodels

            if model==1

                goodneurons{model}=ismember(neurbyneurRatID(:,1),ratnames);

                if useincludeq

                    vidmod=significant{bestit}(logical(goodneurons{model}),strcmp(variables,'VideoComponents'));
                    [sessrat,rat,session]=findgroups(neurbyneurRatID(:,1),neurbyneurRatID(:,2));

                    % Force neuron/session masks into matching column-vector orientation
                    vidmod=vidmod(:);
                    sessrat=sessrat(:);

                    nVideo=accumarray(sessrat,double(vidmod));
                    nNotVideo=accumarray(sessrat,double(~vidmod));
                    nRemove=min(nVideo,nNotVideo);
                    nTotal=accumarray(sessrat,ones(size(vidmod,1),1));
                    nVideoTotal=[nVideo nTotal nVideo./nTotal];

                    % Sessions must contain both VM and NVM neurons
                    eligibleSess=(nVideo>0) & (nNotVideo>0);
                    eligibleSess=eligibleSess(:);

                    all20randomGoodNeurons=[];
                    randomVideoRemoved=zeros(length(nVideo),20);
                    randomnotVideoRemoved=zeros(length(nVideo),20);

                    for r=1:20

                        % Exclude all neurons from one-population sessions immediately
                        randomGoodNeurons=eligibleSess(sessrat);
                        randomGoodNeurons=randomGoodNeurons(:);

                        for sr=1:length(nVideo)

                            thisSess=(sessrat==sr);
                            thisSess=thisSess(:);

                            if eligibleSess(sr)

                                if strcmp(includeq,'yes')

                                    % NVM-depleted
                                    neurons_okaytoremove=find(thisSess & ~vidmod);

                                elseif strcmp(includeq,'no')

                                    % VM-depleted
                                    neurons_okaytoremove=find(thisSess & vidmod);

                                end

                                subsampleSeed=1000000+baseSeed*100000+r*1000+sr;
                                rng(subsampleSeed,'twister');
                                randomindices=randperm(length(neurons_okaytoremove),nRemove(sr));
                                remove=neurons_okaytoremove(randomindices);
                                randomGoodNeurons(remove)=false;

                                randomVideoRemoved(sr,r)=sum(vidmod(remove));
                                randomnotVideoRemoved(sr,r)=sum(~vidmod(remove));

                            else

                                randomVideoRemoved(sr,r)=nVideo(sr);
                                randomnotVideoRemoved(sr,r)=nNotVideo(sr);

                            end

                        end

                        all20randomGoodNeurons(:,r)=randomGoodNeurons;

                    end

                end

            else

                goodneurons{model}=~ismember(neurbyneurRatID(:,1),ratnames(model-1));

            end
        end

        % make jobs
        [modellist,binlist]=ndgrid(1:nmodels,1:nbinsLI);
        modellist=modellist(:);
        binlist=binlist(:);

        testaccuracy=zeros(nmodels*nbinsLI,1);
        meanshuffledaccuracy=zeros(nmodels*nbinsLI,1);
        totalshuffledaccuracy=zeros(nmodels*nbinsLI,100);
        subsamptestaccuracy=zeros(20,nmodels*nbinsLI);
        y=[ones(length(randHMtrialstart),1);(zeros(length(randLMtrialstart),1)+2)];


        cvSeed=2000000+baseSeed;
        rng(cvSeed,'twister');
        cv_partition=cvpartition(y,KFold=methodstring2,Stratify=true);

        parfor job=1:length(modellist)

            model=modellist(job);
            bin=binlist(job);

            x_full=cellfun(@(x) x(bin),popbline(:,goodneurons{model}));

            % Preserve the original x variable for the raw SVM.
            x=x_full;

            % Raw SVM
            % Wholesale VM-removal analysis.
            if useincludeq

                if strcmp(includeq,'no')

                    x(:,significant{bestit}(logical(goodneurons{model}),strcmp(variables,'VideoComponents')))=[];

                end
            end

            x_train=x;
            y_train=y;

            Mdl2=fitcsvm(x_train,y_train,'KernelFunction','linear','CVPartition',cv_partition,'Standardize',false);

            l=kfoldPredict(Mdl2);

            testaccuracy(job)=sum(l==y_train)/length(y_train)*100;

             % shuffled SVM
            tmp=zeros(100,1);
            shuffleSeed=3000000+baseSeed;
            cvShuffSeed=2500000+baseSeed;

            for s=1:100
                rng(shuffleSeed+s,'twister');
                y_trainshuff=y(randperm(length(y)));

                rng(cvShuffSeed+s,'twister');
                cv_partition_shuff=cvpartition(y_trainshuff,KFold=methodstring2,Stratify=true);

                Mdlshuff=fitcsvm(x_train,y_trainshuff,'KernelFunction','linear','CVPartition',cv_partition_shuff,'Standardize',false);

                ls=kfoldPredict(Mdlshuff);

                tmp(s)=sum(ls==y_trainshuff)/length(y_trainshuff)*100;

            end

            totalshuffledaccuracy(job,:)=tmp;

            meanshuffledaccuracy(job)=mean(tmp);

            if useincludeq

                if model==1

                    for sub=1:20
                        xsub=x_full(:,logical(all20randomGoodNeurons(:,sub)));

                        x_train=xsub;
                        y_train=y;

                        Mdl2=fitcsvm(x_train,y_train,'KernelFunction','linear','CVPartition',cv_partition,'Standardize',false);

                        l=kfoldPredict(Mdl2);

                        subsamptestaccuracy(sub,job)=sum(l==y_train)/length(y_train)*100;

                    end
                end

            end

        end

        testaccuracy=reshape(testaccuracy,nmodels,nbinsLI);

        meanshuffledaccuracy=reshape(meanshuffledaccuracy,nmodels,nbinsLI);

        totalshuffledaccuracy=reshape(totalshuffledaccuracy,nmodels,nbinsLI,100);
        totalshuffledaccuracy=permute(totalshuffledaccuracy,[1 3 2]);
        subsamptestaccuracy=subsamptestaccuracy(:,modellist==1);

        PointWiseAccuracyHMvsLMLI(seed,gr).testaccuracy=testaccuracy;
        PointWiseAccuracyHMvsLMLI(seed,gr).totalshuffledaccuracy=totalshuffledaccuracy;
        PointWiseAccuracyHMvsLMLI(seed,gr).meanshuffledaccuracy=meanshuffledaccuracy;
        PointWiseAccuracyHMvsLMLI(seed,gr).subsamptestaccuracy=subsamptestaccuracy;

        if gr==1
            fprintf(repmat('\b',1,m1+m2+m3));
            m4=fprintf('\nSeed %d/10: [',seed);
            m5=fprintf(repelem('|',gr));
            m6=fprintf(repelem(':',numbrats-gr));
            m7=fprintf('] GR %d/%d',gr,numbrats);
        else
            fprintf(repmat('\b',1,m4+m5+m6+m7));
            m4=fprintf('\nSeed %d/10: [',seed);
            m5=fprintf(repelem('|',gr));
            m6=fprintf(repelem(':',numbrats-gr));
            m7=fprintf('] GR %d/%d',gr,numbrats);
        end
    end
end
save([regexp(whichRAW, '(?<=W)[^_]+(?=_)', 'match','once'),'_',includeq,'videoneurons_SVM_seeds_finalimp.mat'],'windowStartLI','windowEndLI','binCentersLI','binsize','PointWiseAccuracyRDvsOMLI','PointWiseAccuracyHMvsLMLI','NLI')


%%
numbrats=50;
numNeuronSubs=20;
numSeeds=3;

groupFiles={'RAWSuperJazz_Latency_raw_addedvars.mat'
    'RAWGrape_Latency_raw.mat'
    'RAWMelon_Latency_raw.mat'};

sigpulls={'SuperJazz1itSig.mat'
    'Grape1itSig.mat'
    'Melon1itSig.mat'};

groupNames={'SuperJazz','Grape','Melon'};

trials2pull=9;
binsize=0.5;

windowStartLI=-15;
windowEndLI=5;

binEdgesLI=windowStartLI:binsize:windowEndLI;
binCentersLI=binEdgesLI(1:end-1)+binsize/2;
NLI=length(binCentersLI);

methodstring2=trials2pull;

beforeIdx=binCentersLI>=-2.5 & binCentersLI<0;
afterIdx=binCentersLI>=0 & binCentersLI<2.5;

RDmatchedPrePost=nan(numSeeds,numbrats,3,2);
RDcurve=nan(numSeeds,numbrats,3,NLI);
HMmatchedPrePost=nan(numSeeds,numbrats,3,2);
HMcurve=nan(numSeeds,numbrats,3,NLI);

RDmatchedPopulationSize=nan(numSeeds,numbrats,3);
HMmatchedPopulationSize=nan(numSeeds,numbrats,3);

for seed=1:numSeeds

   
    fprintf('SEED %d/3\n',seed);
  
    for gr=1:numbrats

        fprintf('\nTRIAL RESAMPLE %d/50\n',gr);

        baseSeed=(seed-1)*numbrats+gr;

        % RD VS OM

        fprintf('\nRD vs OM\n');

        RDpopbline=cell(3,1);
        RDNeuronIDs=cell(3,1);
        RDSessIDs=cell(3,1);
        RDVidMod=cell(3,1);

        for g=1:3


            clearvars RAW significant bestit variables ratnames

            load(sigpulls{g});
            load(groupFiles{g});

            LI=strcmp('LeverInsertion',RAW(1).Einfo(:,2));
            RD=strcmp('RewardDeliv',RAW(1).Einfo(:,2));
            trialtype=strcmp('Trial Type',RAW(1).Einfo(:,2));

            ratnames=unique({RAW.Subject});

            rng(baseSeed,'twister');

            popbline=cell(18,0);
            neurbyneurRatID=cell(0,2);
            matcounter=1;

            for i=1:length(RAW)

                [neuronspersesh,~]=size(RAW(i).Ninfo);

                if length(RAW(i).Erast{RD})>=10

                    if length(RAW(i).Erast{RD})>=trials2pull && sum(strcmp(RAW(i).Erast{trialtype,1},'omission'))>=trials2pull

                        rewardedtrialts=RAW(i).Erast{LI}(~strcmp(RAW(i).Erast{trialtype,1},'omission'),:);
                        omittedtrialindts=RAW(i).Erast{LI}(strcmp(RAW(i).Erast{trialtype,1},'omission'),:);

                        randrdtrialstart=rewardedtrialts(randperm(length(rewardedtrialts),trials2pull));
                        randomtrialstart=omittedtrialindts(randperm(length(omittedtrialindts),trials2pull));

                        for neur=1:neuronspersesh

                            avgactivity=mean(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25}));
                            stdactivity=std(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25}));

                            randrdactivity=arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur}>=(t0+windowStartLI) & RAW(i).Nrast{neur}<=(t0+windowEndLI)),randrdtrialstart,'UniformOutput',false);
                            randrdactivity=cellfun(@(spk,t0) histcounts(spk-t0,binEdgesLI),randrdactivity,num2cell(randrdtrialstart),'UniformOutput',false);
                            randrdactivity=cellfun(@(x) (x-avgactivity)/stdactivity,randrdactivity,'UniformOutput',false);

                            randomactivity=arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur}>=(t0+windowStartLI) & RAW(i).Nrast{neur}<=(t0+windowEndLI)),randomtrialstart,'UniformOutput',false);
                            randomactivity=cellfun(@(spk,t0) histcounts(spk-t0,binEdgesLI),randomactivity,num2cell(randomtrialstart),'UniformOutput',false);
                            randomactivity=cellfun(@(x) (x-avgactivity)/stdactivity,randomactivity,'UniformOutput',false);

                            popbline(:,matcounter)=vertcat(randrdactivity,randomactivity);

                            neurbyneurRatID{matcounter,1}=RAW(i).Subject;
                            neurbyneurRatID{matcounter,2}=regexp(RAW(i).Einfo{1,1},'(?<=_)[^-]+','match','once');

                            matcounter=matcounter+1;

                        end
                    end
                end
            end

            goodneurons=ismember(neurbyneurRatID(:,1),ratnames);

            vidmod=significant{bestit}(logical(goodneurons),strcmp(variables,'VideoComponents'));
            vidmod=vidmod(:);

            [sessrat,~,~]=findgroups(neurbyneurRatID(:,1),neurbyneurRatID(:,2));
            sessrat=sessrat(:);

            RDpopbline{g}=popbline;
            RDNeuronIDs{g}=neurbyneurRatID;
            RDSessIDs{g}=sessrat;
            RDVidMod{g}=vidmod;

            % Reproduce original vm-depleted subsampling logic

            nVideo=accumarray(sessrat,double(vidmod));
            nNotVideo=accumarray(sessrat,double(~vidmod));

            nRemove=min(nVideo,nNotVideo);

            eligibleSess=(nVideo>0) & (nNotVideo>0);
            eligibleSess=eligibleSess(:);

            all20originalVMdepleted=false(length(vidmod),numNeuronSubs);

            parfor r=1:numNeuronSubs

                randomGoodNeurons=eligibleSess(sessrat);
                randomGoodNeurons=randomGoodNeurons(:);

                for sr=1:length(nVideo)

                    thisSess=(sessrat==sr);
                    thisSess=thisSess(:);

                    if eligibleSess(sr)

                        neurons_okaytoremove=find(thisSess & vidmod);

                        subsampleSeed=1000000+baseSeed*100000+r*1000+sr;

                        rng(subsampleSeed,'twister');

                        randomindices=randperm(length(neurons_okaytoremove),nRemove(sr));

                        remove=neurons_okaytoremove(randomindices);

                        randomGoodNeurons(remove)=false;

                    end
                end

                all20originalVMdepleted(:,r)=randomGoodNeurons;

            end

        end

        % Exclude all VM neurons across groups

        RDVMexcludedMask=cell(3,1);
        RDpopSize=zeros(3,1);

        for g=1:3

            RDVMexcludedMask{g}=~logical(RDVidMod{g});

            RDpopSize(g)=sum(RDVMexcludedMask{g});

        end

        RDNmin=min(RDpopSize);

        % SIZE MATCH RD/OM ACROSS THE THREE GROUPS
  
        RDmatchedMask=cell(3,1);

        for g=1:3

            RDmatchedMask{g}=false(size(RDVMexcludedMask{g}));

            currentNeurons=find(RDVMexcludedMask{g});
            currentN=length(currentNeurons);

            sessionIDs=RDSessIDs{g};
            sessionsPresent=unique(sessionIDs(currentNeurons));

            for r=1:numNeuronSubs

                if currentN==RDNmin

                    RDmatchedMask{g}(:,r)=RDVMexcludedMask{g};

                else

                    nToRemove=currentN-RDNmin;

                    removable=[];

                    for s=1:length(sessionsPresent)

                        thisSession=sessionsPresent(s);

                        sessionNeurons=currentNeurons(sessionIDs(currentNeurons)==thisSession);

                        if length(sessionNeurons)>1

                            removable=[removable;sessionNeurons(:)];

                        end
                    end

                    if RDNmin<length(sessionsPresent)

                        removable=currentNeurons;

                    end

                    if length(removable)<nToRemove

                        error('Cannot size-match RD/OM group %d at seed %d resample %d while retaining one neuron per session.',g,seed,gr);

                    end

                    matchSeed=3000000+baseSeed*100000+r*1000+g;

                    rng(matchSeed,'twister');

                    removeIdx=randperm(length(removable),nToRemove);

                    remove=removable(removeIdx);

                    RDmatchedMask{g}(:,r)=RDVMexcludedMask{g};

                    RDmatchedMask{g}(remove,r)=false;

                end
            end
        end

        RDmatchedN=zeros(3,numNeuronSubs);

        for g=1:3

            RDmatchedN(g,:)=sum(RDmatchedMask{g},1);

        end

        if any(RDmatchedN(:)~=RDNmin)

            error('RD/OM size matching failed.');

        end

        % RD/OM CV PARTITION


        yRD=[ones(trials2pull,1);zeros(trials2pull,1)+2];

        cvSeed=2000000+baseSeed;

        rng(cvSeed,'twister');

        cv_partitionRD=cvpartition(yRD,KFold=methodstring2,Stratify=true);


        % RD/OM SVM

        for g=1:3


            RDmatchedAccuracy=zeros(numNeuronSubs,NLI);

            parfor r=1:numNeuronSubs

                thisMask=RDmatchedMask{g}(:,r);

                for bin=1:NLI

                    xbin=cellfun(@(x) x(bin),RDpopbline{g}(:,thisMask));

                    Mdl=fitcsvm(xbin,yRD,'KernelFunction','linear','CVPartition',cv_partitionRD,'Standardize',false);

                    l=kfoldPredict(Mdl);

                    RDmatchedAccuracy(r,bin)=sum(l==yRD)/length(yRD)*100;

                end
            end

            RDmatchedMeanAccuracy=mean(RDmatchedAccuracy,1);

            RDprepost=[mean(RDmatchedMeanAccuracy(beforeIdx)) mean(RDmatchedMeanAccuracy(afterIdx))];
            
            RDcurved(seed,gr,g,:) = RDmatchedMeanAccuracy;
            RDmatchedPrePost(seed,gr,g,1)=RDprepost(1);
            RDmatchedPrePost(seed,gr,g,2)=RDprepost(2);

            RDmatchedPopulationSize(seed,gr,g)=RDNmin;

        end


        % HM VS LM


        fprintf('\nHM vs LM\n');

        HMpopbline=cell(3,1);
        HMNeuronIDs=cell(3,1);
        HMSessIDs=cell(3,1);
        HMVidMod=cell(3,1);

        for g=1:3


            clearvars RAW significant bestit variables ratnames

            load(sigpulls{g});
            load(groupFiles{g});

            LI=strcmp('LeverInsertion',RAW(1).Einfo(:,2));
            RD=strcmp('RewardDeliv',RAW(1).Einfo(:,2));
            trialtype=strcmp('Trial Type',RAW(1).Einfo(:,2));

            ratnames=unique({RAW.Subject});

            rng(baseSeed,'twister');

            popbline=cell(18,0);
            neurbyneurRatID=cell(0,2);
            matcounter=1;

            for i=1:length(RAW)

                [neuronspersesh,~]=size(RAW(i).Ninfo);

                if length(RAW(i).Erast{RD})>=10

                    if sum(strcmp(RAW(i).Erast{trialtype,1},'high'))>=trials2pull && sum(strcmp(RAW(i).Erast{trialtype,1},'low'))>=trials2pull

                        hmtrialts=RAW(i).Erast{LI}(strcmp(RAW(i).Erast{trialtype,1},'high'),:);
                        lmtrialts=RAW(i).Erast{LI}(strcmp(RAW(i).Erast{trialtype,1},'low'),:);

                        randHMtrialstart=hmtrialts(randperm(length(hmtrialts),trials2pull));
                        randLMtrialstart=lmtrialts(randperm(length(lmtrialts),trials2pull));

                        for neur=1:neuronspersesh

                            avgactivity=mean(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25}));
                            stdactivity=std(histcounts(RAW(i).Nrast{neur},0:binsize:RAW(i).Erast{25}));

                            randHMactivity=arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur}>=(t0+windowStartLI) & RAW(i).Nrast{neur}<=(t0+windowEndLI)),randHMtrialstart,'UniformOutput',false);
                            randHMactivity=cellfun(@(spk,t0) histcounts(spk-t0,binEdgesLI),randHMactivity,num2cell(randHMtrialstart),'UniformOutput',false);
                            randHMactivity=cellfun(@(x) (x-avgactivity)/stdactivity,randHMactivity,'UniformOutput',false);

                            randLMactivity=arrayfun(@(t0) RAW(i).Nrast{neur}(RAW(i).Nrast{neur}>=(t0+windowStartLI) & RAW(i).Nrast{neur}<=(t0+windowEndLI)),randLMtrialstart,'UniformOutput',false);
                            randLMactivity=cellfun(@(spk,t0) histcounts(spk-t0,binEdgesLI),randLMactivity,num2cell(randLMtrialstart),'UniformOutput',false);
                            randLMactivity=cellfun(@(x) (x-avgactivity)/stdactivity,randLMactivity,'UniformOutput',false);

                            popbline(:,matcounter)=vertcat(randHMactivity,randLMactivity);

                            neurbyneurRatID{matcounter,1}=RAW(i).Subject;
                            neurbyneurRatID{matcounter,2}=regexp(RAW(i).Einfo{1,1},'(?<=_)[^-]+','match','once');

                            matcounter=matcounter+1;

                        end
                    end
                end
            end

            goodneurons=ismember(neurbyneurRatID(:,1),ratnames);

            vidmod=significant{bestit}(logical(goodneurons),strcmp(variables,'VideoComponents'));
            vidmod=vidmod(:);

            [sessrat,~,~]=findgroups(neurbyneurRatID(:,1),neurbyneurRatID(:,2));
            sessrat=sessrat(:);

            HMpopbline{g}=popbline;
            HMNeuronIDs{g}=neurbyneurRatID;
            HMSessIDs{g}=sessrat;
            HMVidMod{g}=vidmod;


            nVideo=accumarray(sessrat,double(vidmod));
            nNotVideo=accumarray(sessrat,double(~vidmod));

            nRemove=min(nVideo,nNotVideo);

            eligibleSess=(nVideo>0) & (nNotVideo>0);
            eligibleSess=eligibleSess(:);

            all20originalVMdepleted=false(length(vidmod),numNeuronSubs);

            parfor r=1:numNeuronSubs

                randomGoodNeurons=eligibleSess(sessrat);
                randomGoodNeurons=randomGoodNeurons(:);

                for sr=1:length(nVideo)

                    thisSess=(sessrat==sr);
                    thisSess=thisSess(:);

                    if eligibleSess(sr)

                        neurons_okaytoremove=find(thisSess & vidmod);

                        subsampleSeed=1000000+baseSeed*100000+r*1000+sr;

                        rng(subsampleSeed,'twister');

                        randomindices=randperm(length(neurons_okaytoremove),nRemove(sr));

                        remove=neurons_okaytoremove(randomindices);

                        randomGoodNeurons(remove)=false;

                    end
                end

                all20originalVMdepleted(:,r)=randomGoodNeurons;

            end

        end

  
        % Exclude all VM neurons across groups


        HMVMexcludedMask=cell(3,1);
        HMpopSize=zeros(3,1);

        for g=1:3

            HMVMexcludedMask{g}=~logical(HMVidMod{g});

            HMpopSize(g)=sum(HMVMexcludedMask{g});

        end

        HMNmin=min(HMpopSize);

        % Size match HM/LM across the three groups

        HMmatchedMask=cell(3,1);

        for g=1:3

            HMmatchedMask{g}=false(size(HMVMexcludedMask{g}));

            currentNeurons=find(HMVMexcludedMask{g});
            currentN=length(currentNeurons);

            sessionIDs=HMSessIDs{g};
            sessionsPresent=unique(sessionIDs(currentNeurons));

            for r=1:numNeuronSubs

                if currentN==HMNmin

                    HMmatchedMask{g}(:,r)=HMVMexcludedMask{g};

                else

                    nToRemove=currentN-HMNmin;

                    removable=[];

                    for s=1:length(sessionsPresent)

                        thisSession=sessionsPresent(s);

                        sessionNeurons=currentNeurons(sessionIDs(currentNeurons)==thisSession);

                        if length(sessionNeurons)>1

                            removable=[removable;sessionNeurons(:)];

                        end
                    end

                    if HMNmin<length(sessionsPresent)

                        removable=currentNeurons;

                    end

                    if length(removable)<nToRemove

                        error('Cannot size-match HM/LM group %d at seed %d resample %d while retaining one neuron per session.',g,seed,gr);

                    end

                    matchSeed=4000000+baseSeed*100000+r*1000+g;

                    rng(matchSeed,'twister');

                    removeIdx=randperm(length(removable),nToRemove);

                    remove=removable(removeIdx);

                    HMmatchedMask{g}(:,r)=HMVMexcludedMask{g};

                    HMmatchedMask{g}(remove,r)=false;

                end
            end
        end

        HMmatchedN=zeros(3,numNeuronSubs);

        for g=1:3

            HMmatchedN(g,:)=sum(HMmatchedMask{g},1);

        end

        if any(HMmatchedN(:)~=HMNmin)

            error('HM/LM size matching failed.');

        end

        % HM/LM CV PARTITION

        yHM=[ones(trials2pull,1);zeros(trials2pull,1)+2];

        cvSeed=2000000+baseSeed;

        rng(cvSeed,'twister');

        cv_partitionHM=cvpartition(yHM,KFold=methodstring2,Stratify=true);

        % HM/LM SVM

        for g=1:3


            HMmatchedAccuracy=zeros(numNeuronSubs,NLI);

            parfor r=1:numNeuronSubs

                thisMask=HMmatchedMask{g}(:,r);

                for bin=1:NLI

                    xbin=cellfun(@(x) x(bin),HMpopbline{g}(:,thisMask));

                    Mdl=fitcsvm(xbin,yHM,'KernelFunction','linear','CVPartition',cv_partitionHM,'Standardize',false);

                    l=kfoldPredict(Mdl);

                    HMmatchedAccuracy(r,bin)=sum(l==yHM)/length(yHM)*100;

                end
            end

            HMmatchedMeanAccuracy=mean(HMmatchedAccuracy,1);

            HMprepost=[mean(HMmatchedMeanAccuracy(beforeIdx)) mean(HMmatchedMeanAccuracy(afterIdx))];
            
            HMcurve (seed,gr,g,:) = HMmatchedMeanAccuracy;
            HMmatchedPrePost(seed,gr,g,1)=HMprepost(1);
            HMmatchedPrePost(seed,gr,g,2)=HMprepost(2);

            HMmatchedPopulationSize(seed,gr,g)=HMNmin;

        end

    end
end

save('3groups_VMexcluded_sizeMatchedbygroup.mat','RDmatchedPrePost','RDcurve','HMmatchedPrePost','HMcurve','RDmatchedPopulationSize','HMmatchedPopulationSize','binCentersLI','beforeIdx','afterIdx','groupNames','-v7.3');

fprintf('\nDONE.\n');
%% removing video neuron effect

groups={'SuperJazz','Grape','Melon'};
whichgroup = listdlg('PromptString','Select a group:', ...
    'ListString',groups,'SelectionMode','single');


% LOAD YES-VIDEO / NVM-DEPLETED DATA


load([groups{whichgroup} '_yesvideoneurons_SVM_seeds_finalimp.mat'])

seeds=size(PointWiseAccuracyRDvsOMLI,1);
nResamples=size(PointWiseAccuracyRDvsOMLI,2);
nBins=size(PointWiseAccuracyRDvsOMLI(1,1).testaccuracy,2);

beforeIdx = binCentersLI >= -2.5 & binCentersLI < 0;
afterIdx  = binCentersLI >= 0 & binCentersLI < 2.5;


% INITIALIZE POINTWISE SEED CURVES

% Raw/full population
RDvsOMwith_seedCurves = zeros(seeds,nBins);
HMvsLMwith_seedCurves = zeros(seeds,nBins);

% NVM-depleted subsampled population
RDvsOM_NVM_seedCurves = zeros(seeds,nBins);
HMvsLM_NVM_seedCurves = zeros(seeds,nBins);


% PROCESS YES-VIDEO / NVM-DEPLETED DATA FOR ALL SEEDS


for seed=1:seeds

    for models=1

        PointWiseAccuracyRDvsOMLIlocal=struct;
        PointWiseAccuracyHMvsLMLIlocal=struct;

        for gr=1:size(PointWiseAccuracyRDvsOMLI,2)

            PointWiseAccuracyRDvsOMLIlocal(gr).testaccuracy = ...
                PointWiseAccuracyRDvsOMLI(seed,gr).testaccuracy(models,:);

            PointWiseAccuracyRDvsOMLIlocal(gr).totalshuffledaccuracy = ...
                PointWiseAccuracyRDvsOMLI(seed,gr).totalshuffledaccuracy(models,:,:);

            PointWiseAccuracyHMvsLMLIlocal(gr).testaccuracy = ...
                PointWiseAccuracyHMvsLMLI(seed,gr).testaccuracy(models,:);

            PointWiseAccuracyHMvsLMLIlocal(gr).totalshuffledaccuracy = ...
                PointWiseAccuracyHMvsLMLI(seed,gr).totalshuffledaccuracy(models,:,:);


            % Average across the 20 neuron subsamplings
            % for each trial resample

            PointWiseAccuracyRDvsOMLIlocal(gr).meansubsamptestaccuracy = ...
                mean(PointWiseAccuracyRDvsOMLI(seed,gr).subsamptestaccuracy(:,:),1);

            PointWiseAccuracyHMvsLMLIlocal(gr).meansubsamptestaccuracy = ...
                mean(PointWiseAccuracyHMvsLMLI(seed,gr).subsamptestaccuracy(:,:),1);

        end


        % RD vs OM with video

        subsetb4 = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(beforeIdx), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false)');

        subsetaf = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(afterIdx), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false)');

        RDvsOMwith = ...
            [mean(subsetb4,2) mean(subsetaf,2)];


        % HM vs LM with video

        subsetb4 = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(beforeIdx), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false)');

        subsetaf = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(afterIdx), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false)');

        HMvsLMwith = ...
            [mean(subsetb4,2) mean(subsetaf,2)];


        % RD vs OM with video - shuffle

        subsetb4shuffRDvsOM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,beforeIdx),2), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false))';

        subsetafshuffRDvsOM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,afterIdx),2), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false))';

        pb4_RDvsOM = ...
            (sum(mean(subsetb4shuffRDvsOM,1) >= ...
            mean(RDvsOMwith(:,1)))+1)/(100+1);

        paf_RDvsOM = ...
            (sum(mean(subsetafshuffRDvsOM,1) >= ...
            mean(RDvsOMwith(:,2)))+1)/(100+1);

        correctedps_RDvsOM_with = ...
            [pb4_RDvsOM paf_RDvsOM];


        % HM vs LM with video - shuffle

        subsetb4shuffHMvsLM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,beforeIdx),2), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false))';

        subsetafshuffHMvsLM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,afterIdx),2), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false))';

        pb4_HMvsLM = ...
            (sum(mean(subsetb4shuffHMvsLM,1) >= ...
            mean(HMvsLMwith(:,1)))+1)/(100+1);

        paf_HMvsLM = ...
            (sum(mean(subsetafshuffHMvsLM,1) >= ...
            mean(HMvsLMwith(:,2)))+1)/(100+1);

        correctedps_HMvsLM_with = ...
            [pb4_HMvsLM paf_HMvsLM];


        % SUBSAMPLING - NVM DEPLETED

        subsetb4 = cell2mat(arrayfun(@(s) ...
            s.meansubsamptestaccuracy(beforeIdx), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false)');

        subsetaf = cell2mat(arrayfun(@(s) ...
            s.meansubsamptestaccuracy(afterIdx), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false)');

        RDvsOMwith_NVMdeplete = ...
            [mean(subsetb4,2) mean(subsetaf,2)];


        subsetb4 = cell2mat(arrayfun(@(s) ...
            s.meansubsamptestaccuracy(beforeIdx), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false)');

        subsetaf = cell2mat(arrayfun(@(s) ...
            s.meansubsamptestaccuracy(afterIdx), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false)');

        HMvsLMwith_NVMdeplete = ...
            [mean(subsetb4,2) mean(subsetaf,2)];

    end


    % SAVE SEED-SPECIFIC RESULTS

    RDvsOMwith_seeds{seed}=RDvsOMwith;
    HMvsLMwith_seeds{seed}=HMvsLMwith;

    RDvsOMwith_seeds_NVMdeplete{seed}=RDvsOMwith_NVMdeplete;
    HMvsLMwith_seeds_NVMdeplete{seed}=HMvsLMwith_NVMdeplete;

    seedps_RDvsOM_with(seed,1:2)=correctedps_RDvsOM_with;
    seedps_HMvsLM_with(seed,1:2)=correctedps_HMvsLM_with;


    % POINTWISE SEED CURVES
    %
    % Average across the 50 trial resamples.
    % For the subsampled curves, each trial-resample curve
    % has already been averaged across the 20 neuron subsamplings.

    RDvsOM_temp = ...
        cell2mat(arrayfun(@(s) s.testaccuracy, ...
        PointWiseAccuracyRDvsOMLIlocal, ...
        'UniformOutput',false)');

    HMvsLM_temp = ...
        cell2mat(arrayfun(@(s) s.testaccuracy, ...
        PointWiseAccuracyHMvsLMLIlocal, ...
        'UniformOutput',false)');

    RDvsOM_NVM_temp = ...
        cell2mat(arrayfun(@(s) s.meansubsamptestaccuracy, ...
        PointWiseAccuracyRDvsOMLIlocal, ...
        'UniformOutput',false)');

    HMvsLM_NVM_temp = ...
        cell2mat(arrayfun(@(s) s.meansubsamptestaccuracy, ...
        PointWiseAccuracyHMvsLMLIlocal, ...
        'UniformOutput',false)');


    RDvsOMwith_seedCurves(seed,:) = ...
        mean(RDvsOM_temp,1);

    HMvsLMwith_seedCurves(seed,:) = ...
        mean(HMvsLM_temp,1);

    RDvsOM_NVM_seedCurves(seed,:) = ...
        mean(RDvsOM_NVM_temp,1);

    HMvsLM_NVM_seedCurves(seed,:) = ...
        mean(HMvsLM_NVM_temp,1);

end




% LOAD NO-VIDEO / VM-DEPLETED DATA


load([groups{whichgroup} '_novideoneurons_SVM_seeds_finalimp.mat'])


% INITIALIZE POINTWISE SEED CURVES

% Raw/full population
RDvsOMwout_seedCurves = zeros(seeds,nBins);
HMvsLMwout_seedCurves = zeros(seeds,nBins);

% VM-depleted subsampled population
RDvsOM_VM_seedCurves = zeros(seeds,nBins);
HMvsLM_VM_seedCurves = zeros(seeds,nBins);



% PROCESS NO-VIDEO / VM-DEPLETED DATA FOR ALL SEEDS


for seed=1:seeds

    for models=1

        PointWiseAccuracyRDvsOMLIlocal=struct;
        PointWiseAccuracyHMvsLMLIlocal=struct;

        for gr=1:size(PointWiseAccuracyRDvsOMLI,2)

            PointWiseAccuracyRDvsOMLIlocal(gr).testaccuracy = ...
                PointWiseAccuracyRDvsOMLI(seed,gr).testaccuracy(models,:);

            PointWiseAccuracyRDvsOMLIlocal(gr).totalshuffledaccuracy = ...
                PointWiseAccuracyRDvsOMLI(seed,gr).totalshuffledaccuracy(models,:,:);

            PointWiseAccuracyHMvsLMLIlocal(gr).testaccuracy = ...
                PointWiseAccuracyHMvsLMLI(seed,gr).testaccuracy(models,:);

            PointWiseAccuracyHMvsLMLIlocal(gr).totalshuffledaccuracy = ...
                PointWiseAccuracyHMvsLMLI(seed,gr).totalshuffledaccuracy(models,:,:);

            PointWiseAccuracyRDvsOMLIlocal(gr).meansubsamptestaccuracy = ...
                mean(PointWiseAccuracyRDvsOMLI(seed,gr).subsamptestaccuracy(:,:),1);

            PointWiseAccuracyHMvsLMLIlocal(gr).meansubsamptestaccuracy = ...
                mean(PointWiseAccuracyHMvsLMLI(seed,gr).subsamptestaccuracy(:,:),1);

        end


        % RD vs OM without video

        subsetb4 = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(beforeIdx), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false)');

        subsetaf = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(afterIdx), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false)');

        RDvsOMwout = ...
            [mean(subsetb4,2) mean(subsetaf,2)];


        % HM vs LM without video

        subsetb4 = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(beforeIdx), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false)');

        subsetaf = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(afterIdx), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false)');

        HMvsLMwout = ...
            [mean(subsetb4,2) mean(subsetaf,2)];


        % RD vs OM without video - shuffle

        subsetb4shuffRDvsOM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,beforeIdx),2), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false))';

        subsetafshuffRDvsOM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,afterIdx),2), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false))';

        pb4_RDvsOM = ...
            (sum(mean(subsetb4shuffRDvsOM,1) >= ...
            mean(RDvsOMwout(:,1)))+1)/(100+1);

        paf_RDvsOM = ...
            (sum(mean(subsetafshuffRDvsOM,1) >= ...
            mean(RDvsOMwout(:,2)))+1)/(100+1);

        correctedps_RDvsOM_without = ...
            [pb4_RDvsOM paf_RDvsOM];


        % HM vs LM without video - shuffle

        subsetb4shuffHMvsLM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,beforeIdx),2), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false))';

        subsetafshuffHMvsLM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,afterIdx),2), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false))';

        pb4_HMvsLM = ...
            (sum(mean(subsetb4shuffHMvsLM,1) >= ...
            mean(HMvsLMwout(:,1)))+1)/(100+1);

        paf_HMvsLM = ...
            (sum(mean(subsetafshuffHMvsLM,1) >= ...
            mean(HMvsLMwout(:,2)))+1)/(100+1);

        correctedps_HMvsLM_without = ...
            [pb4_HMvsLM paf_HMvsLM];


        % SUBSAMPLING - VM DEPLETED

        subsetb4 = cell2mat(arrayfun(@(s) ...
            s.meansubsamptestaccuracy(beforeIdx), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false)');

        subsetaf = cell2mat(arrayfun(@(s) ...
            s.meansubsamptestaccuracy(afterIdx), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false)');

        RDvsOMwout_VMdeplete = ...
            [mean(subsetb4,2) mean(subsetaf,2)];


        subsetb4 = cell2mat(arrayfun(@(s) ...
            s.meansubsamptestaccuracy(beforeIdx), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false)');

        subsetaf = cell2mat(arrayfun(@(s) ...
            s.meansubsamptestaccuracy(afterIdx), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false)');

        HMvsLMwout_VMdeplete = ...
            [mean(subsetb4,2) mean(subsetaf,2)];

    end


    % SAVE SEED-SPECIFIC RESULTS

    RDvsOMwout_seeds{seed}=RDvsOMwout;
    HMvsLMwout_seeds{seed}=HMvsLMwout;

    RDvsOMwout_seeds_VMdeplete{seed}=RDvsOMwout_VMdeplete;
    HMvsLMwout_seeds_VMdeplete{seed}=HMvsLMwout_VMdeplete;

    % Keep the no-video Monte Carlo values separately
    seedps_RDvsOM_without(seed,1:2)=correctedps_RDvsOM_without;
    seedps_HMvsLM_without(seed,1:2)=correctedps_HMvsLM_without;


    % POINTWISE SEED CURVES

    RDvsOM_temp = ...
        cell2mat(arrayfun(@(s) s.testaccuracy, ...
        PointWiseAccuracyRDvsOMLIlocal, ...
        'UniformOutput',false)');

    HMvsLM_temp = ...
        cell2mat(arrayfun(@(s) s.testaccuracy, ...
        PointWiseAccuracyHMvsLMLIlocal, ...
        'UniformOutput',false)');

    RDvsOM_VM_temp = ...
        cell2mat(arrayfun(@(s) s.meansubsamptestaccuracy, ...
        PointWiseAccuracyRDvsOMLIlocal, ...
        'UniformOutput',false)');

    HMvsLM_VM_temp = ...
        cell2mat(arrayfun(@(s) s.meansubsamptestaccuracy, ...
        PointWiseAccuracyHMvsLMLIlocal, ...
        'UniformOutput',false)');


    RDvsOMwout_seedCurves(seed,:) = ...
        mean(RDvsOM_temp,1);

    HMvsLMwout_seedCurves(seed,:) = ...
        mean(HMvsLM_temp,1);

    RDvsOM_VM_seedCurves(seed,:) = ...
        mean(RDvsOM_VM_temp,1);

    HMvsLM_VM_seedCurves(seed,:) = ...
        mean(HMvsLM_VM_temp,1);

end




% SELECT REPRESENTATIVE SEEDS




% RAW DATA


% Grand mean across all 10 seeds

RDvsOMwith_grandMean = ...
    mean(RDvsOMwith_seedCurves,1);

RDvsOMwout_grandMean = ...
    mean(RDvsOMwout_seedCurves,1);

HMvsLMwith_grandMean = ...
    mean(HMvsLMwith_seedCurves,1);

HMvsLMwout_grandMean = ...
    mean(HMvsLMwout_seedCurves,1);


% Point-by-point error from each population's own grand mean

RDvsOMwith_error = ...
    abs(RDvsOMwith_seedCurves - RDvsOMwith_grandMean);

RDvsOMwout_error = ...
    abs(RDvsOMwout_seedCurves - RDvsOMwout_grandMean);

HMvsLMwith_error = ...
    abs(HMvsLMwith_seedCurves - HMvsLMwith_grandMean);

HMvsLMwout_error = ...
    abs(HMvsLMwout_seedCurves - HMvsLMwout_grandMean);


% Combine the matched yes-video and no-video errors
% point-by-point

RDvsOM_combinedError = ...
    (RDvsOMwith_error + RDvsOMwout_error) / 2;

HMvsLM_combinedError = ...
    (HMvsLMwith_error + HMvsLMwout_error) / 2;


% Mean point-by-point error for each seed

meanDeviationRDvsOM = ...
    mean(RDvsOM_combinedError,2);

meanDeviationHMvsLM = ...
    mean(HMvsLM_combinedError,2);


% Representative raw seeds

[~,representativeSeedRDvsOM_raw] = ...
    min(meanDeviationRDvsOM);

[~,representativeSeedHMvsLM_raw] = ...
    min(meanDeviationHMvsLM);




% SUBSAMPLED DATA


% Grand mean across all 10 seeds

RDvsOM_NVM_grandMean = ...
    mean(RDvsOM_NVM_seedCurves,1);

RDvsOM_VM_grandMean = ...
    mean(RDvsOM_VM_seedCurves,1);

HMvsLM_NVM_grandMean = ...
    mean(HMvsLM_NVM_seedCurves,1);

HMvsLM_VM_grandMean = ...
    mean(HMvsLM_VM_seedCurves,1);


% Point-by-point error from each population's own grand mean

RDvsOM_NVM_error = ...
    abs(RDvsOM_NVM_seedCurves - RDvsOM_NVM_grandMean);

RDvsOM_VM_error = ...
    abs(RDvsOM_VM_seedCurves - RDvsOM_VM_grandMean);

HMvsLM_NVM_error = ...
    abs(HMvsLM_NVM_seedCurves - HMvsLM_NVM_grandMean);

HMvsLM_VM_error = ...
    abs(HMvsLM_VM_seedCurves - HMvsLM_VM_grandMean);


% Combine NVM- and VM-depleted errors
% point-by-point

RDvsOM_subsamp_combinedError = ...
    (RDvsOM_NVM_error + RDvsOM_VM_error) / 2;

HMvsLM_subsamp_combinedError = ...
    (HMvsLM_NVM_error + HMvsLM_VM_error) / 2;


% Mean point-by-point error for each seed

RDvsOM_subsamp_meanDeviation = ...
    mean(RDvsOM_subsamp_combinedError,2);

HMvsLM_subsamp_meanDeviation = ...
    mean(HMvsLM_subsamp_combinedError,2);


% Representative subsampled seeds

[~,representativeSeedRDvsOM_subsamp] = ...
    min(RDvsOM_subsamp_meanDeviation);

[~,representativeSeedHMvsLM_subsamp] = ...
    min(HMvsLM_subsamp_meanDeviation);



% DISPLAY REPRESENTATIVE SEEDS

fprintf('\n');
fprintf('Representative raw RD vs OM seed = %d\n', ...
    representativeSeedRDvsOM_raw);

fprintf('Representative raw HM vs LM seed = %d\n', ...
    representativeSeedHMvsLM_raw);

fprintf('Representative subsampled RD vs OM seed = %d\n', ...
    representativeSeedRDvsOM_subsamp);

fprintf('Representative subsampled HM vs LM seed = %d\n', ...
    representativeSeedHMvsLM_subsamp);




% RAW DATA ANALYSIS
% ONLY REPRESENTATIVE SEEDS



% RD VS OM - RAW DATA

for seed = 1:10%representativeSeedRDvsOM_raw


T = table( ...
    RDvsOMwith_seeds{seed}(:,1), ...
    RDvsOMwith_seeds{seed}(:,2), ...
    RDvsOMwout_seeds{seed}(:,1), ...
    RDvsOMwout_seeds{seed}(:,2), ...
    'VariableNames', ...
    {'With_Before','With_After','Without_Before','Without_After'});


Group = categorical( ...
    {'WithVideo'; ...
    'WithVideo'; ...
    'NoVideo'; ...
    'NoVideo'});

Time = categorical( ...
    {'Before'; ...
    'After'; ...
    'Before'; ...
    'After'});


WithinDesign = table(Group,Time);


rm = fitrm( ...
    T, ...
    'With_Before-Without_After ~ 1', ...
    'WithinDesign',WithinDesign);


ranovatbl = ...
    ranova(rm,'WithinModel','Group*Time');

disp('RD vs OM - RAW DATA - REPRESENTATIVE SEED')
disp(ranovatbl)


seed_RDvsOM_anova_raw = ...
    ranovatbl({'(Intercept):Group', ...
    '(Intercept):Time', ...
    '(Intercept):Group:Time'},:);


multcomparetbl = ...
    multcompare( ...
    rm, ...
    'Time', ...
    'By','Group', ...
    'ComparisonType','bonferroni');

seed_RDvsOM_multcompare_raw = multcomparetbl;

multcomparetbl = ...
    multcompare( ...
    rm, ...
    'Group', ...
    'By','Time', ...
    'ComparisonType','bonferroni');

seed_RDvsOM_multcompare_raw_gt = multcomparetbl;


RDvsOM_results_raw(seed,:) = ...
    [seed_RDvsOM_anova_raw.F(1), ...
    seed_RDvsOM_anova_raw.pValue(1), ...
    seed_RDvsOM_anova_raw.F(2), ...
    seed_RDvsOM_anova_raw.pValue(2), ...
    seed_RDvsOM_anova_raw.F(end), ...
    seed_RDvsOM_anova_raw.pValue(end)];
end

% HM VS LM - RAW DATA

for seed = 1:10%representativeSeedHMvsLM_raw


T = table( ...
    HMvsLMwith_seeds{seed}(:,1), ...
    HMvsLMwith_seeds{seed}(:,2), ...
    HMvsLMwout_seeds{seed}(:,1), ...
    HMvsLMwout_seeds{seed}(:,2), ...
    'VariableNames', ...
    {'With_Before','With_After','Without_Before','Without_After'});


Group = categorical( ...
    {'WithVideo'; ...
    'WithVideo'; ...
    'NoVideo'; ...
    'NoVideo'});

Time = categorical( ...
    {'Before'; ...
    'After'; ...
    'Before'; ...
    'After'});


WithinDesign = table(Group,Time);


rm = fitrm( ...
    T, ...
    'With_Before-Without_After ~ 1', ...
    'WithinDesign',WithinDesign);


ranovatbl = ...
    ranova(rm,'WithinModel','Group*Time');

disp('HM vs LM - RAW DATA - REPRESENTATIVE SEED')
disp(ranovatbl)


seed_HMvsLM_anova_raw = ...
    ranovatbl({'(Intercept):Group', ...
    '(Intercept):Time', ...
    '(Intercept):Group:Time'},:);


multcomparetbl = ...
    multcompare( ...
    rm, ...
    'Time', ...
    'By','Group', ...
    'ComparisonType','bonferroni');

seed_HMvsLM_multcompare_raw = multcomparetbl;

multcomparetbl = ...
    multcompare( ...
    rm, ...
    'Group', ...
    'By','Time', ...
    'ComparisonType','bonferroni');

seed_HMvsLM_multcompare_raw_gt = multcomparetbl;

HMvsLM_results_raw(seed,:) = ...
    [seed_HMvsLM_anova_raw.F(1), ...
    seed_HMvsLM_anova_raw.pValue(1), ...
    seed_HMvsLM_anova_raw.F(2), ...
    seed_HMvsLM_anova_raw.pValue(2), ...
    seed_HMvsLM_anova_raw.F(end), ...
    seed_HMvsLM_anova_raw.pValue(end)];

end


% RAW DATA BEFORE / AFTER VALUES AND EFFECTS
% ONLY REPRESENTATIVE SEEDS



% RD VS OM

for seed = 1:10%representativeSeedRDvsOM_raw

RDvsOM_with_beforevafter(seed,:) = ...
    [mean(RDvsOMwith_seeds{seed}(:,1)), ...
    mean(RDvsOMwith_seeds{seed}(:,2))];

RDvsOM_wout_beforevafter(seed,:) = ...
    [mean(RDvsOMwout_seeds{seed}(:,1)), ...
    mean(RDvsOMwout_seeds{seed}(:,2))];

RDvsOM_effect(seed,:) = ...
    mean( ...
    (RDvsOMwith_seeds{seed}(:,2) - ...
    RDvsOMwith_seeds{seed}(:,1)) - ...
    (RDvsOMwout_seeds{seed}(:,2) - ...
    RDvsOMwout_seeds{seed}(:,1)));
end

% HM VS LM

for seed = 1:10%representativeSeedHMvsLM_raw

HMvsLM_with_beforevafter(seed,:) = ...
    [mean(HMvsLMwith_seeds{seed}(:,1)), ...
    mean(HMvsLMwith_seeds{seed}(:,2))];

HMvsLM_wout_beforevafter(seed,:) = ...
    [mean(HMvsLMwout_seeds{seed}(:,1)), ...
    mean(HMvsLMwout_seeds{seed}(:,2))];

HMvsLM_effect(seed,:) = ...
    mean( ...
    (HMvsLMwith_seeds{seed}(:,2) - ...
    HMvsLMwith_seeds{seed}(:,1)) - ...
    (HMvsLMwout_seeds{seed}(:,2) - ...
    HMvsLMwout_seeds{seed}(:,1)));
end



% REPRESENTATIVE-SEED RAW MONTE CARLO RESULTS


RDvsOM_p_with = ...
    seedps_RDvsOM_with(representativeSeedRDvsOM_raw,:);

RDvsOM_p_without = ...
    seedps_RDvsOM_without(representativeSeedRDvsOM_raw,:);


HMvsLM_p_with = ...
    seedps_HMvsLM_with(representativeSeedHMvsLM_raw,:);

HMvsLM_p_without = ...
    seedps_HMvsLM_without(representativeSeedHMvsLM_raw,:);




% SUBSAMPLED DATA ANALYSIS
% ONLY REPRESENTATIVE SUBSAMPLED SEEDS



% RD VS OM - SUBSAMPLED

for seed = 1:10%representativeSeedRDvsOM_subsamp; % change here to represent all or just representative seed


T = table( ...
    RDvsOMwith_seeds_NVMdeplete{seed}(:,1), ...
    RDvsOMwith_seeds_NVMdeplete{seed}(:,2), ...
    RDvsOMwout_seeds_VMdeplete{seed}(:,1), ...
    RDvsOMwout_seeds_VMdeplete{seed}(:,2), ...
    'VariableNames', ...
    {'NVM_Before','NVM_After','VM_Before','VM_After'});


Group = categorical( ...
    {'NVM-depleted'; ...
    'NVM-depleted'; ...
    'VM-depleted'; ...
    'VM-depleted'});

Time = categorical( ...
    {'Before'; ...
    'After'; ...
    'Before'; ...
    'After'});


WithinDesign = table(Group,Time);


rm = fitrm( ...
    T, ...
    'NVM_Before-VM_After ~ 1', ...
    'WithinDesign',WithinDesign);


ranovatbl = ...
    ranova(rm,'WithinModel','Group*Time');

disp('RD vs OM - SUBSAMPLED DATA - REPRESENTATIVE SEED')
disp(ranovatbl)


seed_RDvsOM_anova_subsamp = ...
    ranovatbl({'(Intercept):Group', ...
    '(Intercept):Time', ...
    '(Intercept):Group:Time'},:);


multcomparetbl = ...
    multcompare( ...
    rm, ...
    'Time', ...
    'By','Group', ...
    'ComparisonType','bonferroni');

seed_RDvsOM_multcompare_subsamp = multcomparetbl;

multcomparetbl = ...
    multcompare( ...
    rm, ...
    'Group', ...
    'By','Time', ...
    'ComparisonType','bonferroni');

seed_RDvsOM_multcompare_subsamp_gt = multcomparetbl;

RDvsOM_results_subsamp(seed,:) = ...
    [seed_RDvsOM_anova_subsamp.F(1), ...
    seed_RDvsOM_anova_subsamp.pValue(1), ...
    seed_RDvsOM_anova_subsamp.F(2), ...
    seed_RDvsOM_anova_subsamp.pValue(2), ...
    seed_RDvsOM_anova_subsamp.F(end), ...
    seed_RDvsOM_anova_subsamp.pValue(end)];


end
% HM VS LM - SUBSAMPLED

for seed = 1:10% representativeSeedHMvsLM_subsamp;


T = table( ...
    HMvsLMwith_seeds_NVMdeplete{seed}(:,1), ...
    HMvsLMwith_seeds_NVMdeplete{seed}(:,2), ...
    HMvsLMwout_seeds_VMdeplete{seed}(:,1), ...
    HMvsLMwout_seeds_VMdeplete{seed}(:,2), ...
    'VariableNames', ...
    {'NVM_Before','NVM_After','VM_Before','VM_After'});


Group = categorical( ...
    {'NVM-depleted'; ...
    'NVM-depleted'; ...
    'VM-depleted'; ...
    'VM-depleted'});

Time = categorical( ...
    {'Before'; ...
    'After'; ...
    'Before'; ...
    'After'});


WithinDesign = table(Group,Time);


rm = fitrm( ...
    T, ...
    'NVM_Before-VM_After ~ 1', ...
    'WithinDesign',WithinDesign);


ranovatbl = ...
    ranova(rm,'WithinModel','Group*Time');

disp('HM vs LM - SUBSAMPLED DATA - REPRESENTATIVE SEED')
disp(ranovatbl)


seed_HMvsLM_anova_subsamp = ...
    ranovatbl({'(Intercept):Group', ...
    '(Intercept):Time', ...
    '(Intercept):Group:Time'},:);


multcomparetbl = ...
    multcompare( ...
    rm, ...
    'Time', ...
    'By','Group', ...
    'ComparisonType','bonferroni');

seed_HMvsLM_multcompare_subsamp = multcomparetbl;

multcomparetbl = ...
    multcompare( ...
    rm, ...
    'Group', ...
    'By','Time', ...
    'ComparisonType','bonferroni');

seed_HMvsLM_multcompare_subsamp_gt = multcomparetbl;

HMvsLM_results_subsamp(seed,:) = ...
    [seed_HMvsLM_anova_subsamp.F(1), ...
    seed_HMvsLM_anova_subsamp.pValue(1), ...
    seed_HMvsLM_anova_subsamp.F(2), ...
    seed_HMvsLM_anova_subsamp.pValue(2), ...
    seed_HMvsLM_anova_subsamp.F(end), ...
    seed_HMvsLM_anova_subsamp.pValue(end)];
end


% SUBSAMPLED BEFORE / AFTER VALUES AND EFFECTS
% ONLY REPRESENTATIVE SEEDS



% RD VS OM

for seed = 1:10% representativeSeedRDvsOM_subsamp; % change here to represent all or just representative seed

RDvsOM_with_beforevafter_subsamp(seed,:) = ...
    [mean(RDvsOMwith_seeds_NVMdeplete{seed}(:,1)), ...
    mean(RDvsOMwith_seeds_NVMdeplete{seed}(:,2))];

RDvsOM_wout_beforevafter_subsamp(seed,:) = ...
    [mean(RDvsOMwout_seeds_VMdeplete{seed}(:,1)), ...
    mean(RDvsOMwout_seeds_VMdeplete{seed}(:,2))];

RDvsOM_effect_subsamp(seed,:) = ...
    mean( ...
    (RDvsOMwith_seeds_NVMdeplete{seed}(:,2) - ...
    RDvsOMwith_seeds_NVMdeplete{seed}(:,1)) - ...
    (RDvsOMwout_seeds_VMdeplete{seed}(:,2) - ...
    RDvsOMwout_seeds_VMdeplete{seed}(:,1)));
end

% HM VS LM

for seed = 1:10%representativeSeedHMvsLM_subsamp; % change here to represent all or just representative seed

HMvsLM_with_beforevafter_subsamp(seed,:) = ...
    [mean(HMvsLMwith_seeds_NVMdeplete{seed}(:,1)), ...
    mean(HMvsLMwith_seeds_NVMdeplete{seed}(:,2))];

HMvsLM_wout_beforevafter_subsamp(seed,:) = ...
    [mean(HMvsLMwout_seeds_VMdeplete{seed}(:,1)), ...
    mean(HMvsLMwout_seeds_VMdeplete{seed}(:,2))];

HMvsLM_effect_subsamp(seed,:) = ...
    mean( ...
    (HMvsLMwith_seeds_NVMdeplete{seed}(:,2) - ...
    HMvsLMwith_seeds_NVMdeplete{seed}(:,1)) - ...
    (HMvsLMwout_seeds_VMdeplete{seed}(:,2) - ...
    HMvsLMwout_seeds_VMdeplete{seed}(:,1)));
end

% RD vs OM - DEPLETED POPULATIONS
% REPRESENTATIVE SUBSAMPLED SEED


seed = representativeSeedRDvsOM_subsamp;

RDvsOM_NVM = RDvsOMwith_seeds_NVMdeplete{seed};
RDvsOM_VM  = RDvsOMwout_seeds_VMdeplete{seed};

nIter = size(RDvsOM_NVM,1);

figure; hold on;

% X positions
xVM  = 3.5;
xNVM = 1.5;

% Lines connecting each trial resample
for r = 1:nIter
    plot([1 2], [RDvsOM_NVM(r,1) RDvsOM_NVM(r,2)], '-', ...
        'Color', [0.6 0.6 0.6], 'LineWidth', 1);
end

for r = 1:nIter
    plot([3 4], [RDvsOM_VM(r,1) RDvsOM_VM(r,2)], '-', ...
        'Color', [0.6 0.6 0.6], 'LineWidth', 1);
end


% BOXPLOTS OF DEPLETED MODEL ACCURACIES ONLY
% NO SHUFFLED ACCURACIES
boxplot([RDvsOM_NVM, RDvsOM_VM])



% Formatting
xlim([0.5 4.5])
ylim([30 100])

xticks([xNVM xVM])
xticklabels({'NVM-depleted','VM-depleted'})

ylabel('Model Accuracy')
legend({'Before','After'}, 'Location','Best')
title('Accuracy Before vs After by Depleted Population (RDvsOM)')
subtitle(groups{whichgroup})

box on

% HM vs LM - DEPLETED POPULATIONS
% REPRESENTATIVE SUBSAMPLED SEED


seed = representativeSeedHMvsLM_subsamp;

HMvsLM_NVM = HMvsLMwith_seeds_NVMdeplete{seed};
HMvsLM_VM  = HMvsLMwout_seeds_VMdeplete{seed};

nIter = size(HMvsLM_NVM,1);

figure; hold on;

% Lines connecting each trial resample
for r = 1:nIter
    plot([1 2], [HMvsLM_NVM(r,1) HMvsLM_NVM(r,2)], '-', ...
        'Color', [0.6 0.6 0.6], 'LineWidth', 1);
end

for r = 1:nIter
    plot([3 4], [HMvsLM_VM(r,1) HMvsLM_VM(r,2)], '-', ...
        'Color', [0.6 0.6 0.6], 'LineWidth', 1);
end


% BOXPLOTS OF DEPLETED MODEL ACCURACIES ONLY

boxplot([HMvsLM_NVM, HMvsLM_VM])



% Formatting
xlim([0.5 4.5])
ylim([30 100])

xticks([1.5 3.5])
xticklabels({'NVM-depleted','VM-depleted'})

ylabel('Model Accuracy')
legend({'Before','After'}, 'Location','Best')
title('Accuracy Before vs After by Depleted Population (HMvsLM)')
subtitle(groups{whichgroup})

box on



fprintf('REPRESENTATIVE SEEDS USED FOR FINAL RESULTS\n');

fprintf('Raw RD vs OM:          Seed %d\n', ...
    representativeSeedRDvsOM_raw);

fprintf('Raw HM vs LM:          Seed %d\n', ...
    representativeSeedHMvsLM_raw);

fprintf('Subsampled RD vs OM:   Seed %d\n', ...
    representativeSeedRDvsOM_subsamp);

fprintf('Subsampled HM vs LM:   Seed %d\n', ...
    representativeSeedHMvsLM_subsamp);


%% Group Downsampling

load('3groups_VMexcluded_sizeMatchedbygroup.mat')

numSeeds=size(RDcurve,1);
numResamples=size(RDcurve,2);
numGroups=size(RDcurve,3);
beforeIdx = binCentersLI >= -2.5 & binCentersLI < 0;
afterIdx  = binCentersLI >= 0 & binCentersLI < 2.5;


fprintf('REPRESENTATIVE SEED SELECTION\n')


RDseedCurves=squeeze(mean(RDcurve,2));
RDgrandMean=squeeze(mean(RDseedCurves,1));

RDseedError=zeros(numSeeds,1);

for seed=1:numSeeds

    thisDeviation=abs(squeeze(RDseedCurves(seed,:,:))-RDgrandMean);

    RDseedError(seed)=mean(thisDeviation(:));

end

[~,representativeSeedRD]=min(RDseedError);


HMseedCurves=squeeze(mean(HMcurve,2));
HMgrandMean=squeeze(mean(HMseedCurves,1));

HMseedError=zeros(numSeeds,1);

for seed=1:numSeeds

    thisDeviation=abs(squeeze(HMseedCurves(seed,:,:))-HMgrandMean);

    HMseedError(seed)=mean(thisDeviation(:));

end

[~,representativeSeedHM]=min(HMseedError);


fprintf('Representative RD vs OM seed = %d\n',representativeSeedRD)
fprintf('Representative HM vs LM seed = %d\n',representativeSeedHM)

fprintf('\nRD/OM seed deviations:\n')
disp(RDseedError)

fprintf('HM/LM seed deviations:\n')
disp(HMseedError)


RDplotData=zeros(numResamples,numGroups*2);

for seed=1:3
for g=1:numGroups
    groupcurve=RDcurve(seed,:,g,:);
    before=mean(groupcurve(:,:,:,beforeIdx),4);
    after=mean(groupcurve(:,:,:,afterIdx),4);
    beforeRD(seed,g)=mean(before,2);
    afterRD(seed,g)=mean(after,2);
    differenceRD(seed,g)=mean(before-after,2);
    RDplotData(:,(g-1)*2+1)=squeeze(before);
    RDplotData(:,(g-1)*2+2)=squeeze(after);

end


HMplotData=zeros(numResamples,numGroups*2);

for g=1:numGroups
    groupcurve=HMcurve(seed,:,g,:);
    before=mean(groupcurve(:,:,:,beforeIdx),4);
    after=mean(groupcurve(:,:,:,afterIdx),4);
        beforeHM(seed,g)=mean(before,2);
    afterHM(seed,g)=mean(after,2);
    differenceHM(seed,g)=mean(before-after,2);
    HMplotData(:,(g-1)*2+1)=squeeze(before);
    HMplotData(:,(g-1)*2+2)=squeeze(after);
end
end

Before_RD = [ ...
    RDplotData(:,1); ...
    RDplotData(:,3); ...
    RDplotData(:,5)];

After_RD = [ ...
    RDplotData(:,2); ...
    RDplotData(:,4); ...
    RDplotData(:,6)];

Group_RD = categorical([ ...
    repmat({'EtOH/EtOH'},numResamples,1); ...
    repmat({'EtOH/Suc'},numResamples,1); ...
    repmat({'NoEtOH/Suc'},numResamples,1)]);

T_RD = table( ...
    Before_RD, ...
    After_RD, ...
    Group_RD, ...
    'VariableNames', ...
    {'Before','After','Group'});

Time = categorical({'Before';'After'});

WithinDesign = table(Time);

rm_RD = fitrm( ...
    T_RD, ...
    'Before-After ~ Group', ...
    'WithinDesign',WithinDesign);

ranovatbl_RD = ranova( ...
    rm_RD, ...
    'WithinModel','Time');

anovatbl_RD = anova(rm_RD);

disp(' ')
disp('RD vs OM - REPRESENTATIVE SEED')
disp(ranovatbl_RD)


RD_anova=ranovatbl_RD( ...
    {'Group', ...
     '(Intercept):Time', ...
     'Group:Time'},:);


RD_multcompare=multcompare( ...
    rm_RD, ...
    'Time', ...
    'By','Group', ...
    'ComparisonType','bonferroni');


disp(' ')
disp('RD vs OM group by time - BONFERRONI BEFORE/AFTER COMPARISONS')
disp(RD_multcompare)

RD_multcompare=multcompare( ...
    rm_RD, ...
    'Group', ...
    'By','Time', ...
    'ComparisonType','bonferroni');


disp(' ')
disp('RD vs OM time by group - BONFERRONI BEFORE/AFTER COMPARISONS')
disp(RD_multcompare)

RDdiff_multcompare=multcompare( ...
    rm_RD, ...
    'Group', ...
    'By','Time', ...
    'ComparisonType','bonferroni');


disp(' ')
disp('RD vs OM - BONFERRONI BEFORE/AFTER COMPARISONS')
disp(RD_multcompare)

Change_RD = After_RD - Before_RD;

[~,~,statsChange_RD] = anova1( ...
    Change_RD, ...
    Group_RD, ...
    'off');

[RD_interaction_multcompare,~,~,~] = multcompare( ...
    statsChange_RD, ...
    'CType','bonferroni');
RDtable=table(string(statsChange_RD.gnames(RD_interaction_multcompare(:,1))), ...
    string(statsChange_RD.gnames(RD_interaction_multcompare(:,2))), ...
    RD_interaction_multcompare(:,4), ...
    RD_interaction_multcompare(:,3), ...
    RD_interaction_multcompare(:,5), ...
    RD_interaction_multcompare(:,6),'VariableNames',{'Group1','Group2','Difference_Group1_minus_Group2', ...
     'Lower95CI','Upper95CI','Bonferroni_p'});
disp(' ')
disp('RD vs OM Delta - BONFERRONI BEFORE/AFTER COMPARISONS')
disp(RDtable)

RD_results=[ ...
    RD_anova.F(1), ...
    RD_anova.pValue(1), ...
    RD_anova.F(2), ...
    RD_anova.pValue(2), ...
    RD_anova.F(3), ...
    RD_anova.pValue(3)];


fprintf('\nRD vs OM ANOVA:\n')
fprintf('Group: F = %.4f, p = %.6g\n',RD_results(1),RD_results(2))
fprintf('Time: F = %.4f, p = %.6g\n',RD_results(3),RD_results(4))
fprintf('Group x Time: F = %.4f, p = %.6g\n',RD_results(5),RD_results(6))


Before_HM = [ ...
    HMplotData(:,1); ...
    HMplotData(:,3); ...
    HMplotData(:,5)];

After_HM = [ ...
    HMplotData(:,2); ...
    HMplotData(:,4); ...
    HMplotData(:,6)];

Group_HM = categorical([ ...
    repmat({'EtOH/EtOH'},numResamples,1); ...
    repmat({'EtOH/Suc'},numResamples,1); ...
    repmat({'NoEtOH/Suc'},numResamples,1)]);

T_HM = table( ...
    Before_HM, ...
    After_HM, ...
    Group_HM, ...
    'VariableNames', ...
    {'Before','After','Group'});

rm_HM = fitrm( ...
    T_HM, ...
    'Before-After ~ Group', ...
    'WithinDesign',WithinDesign);

ranovatbl_HM = ranova( ...
    rm_HM, ...
    'WithinModel','Time');

anovatbl_HM = anova(rm_HM);
disp(' ')
disp('HM vs LM - REPRESENTATIVE SEED')
disp(ranovatbl_HM)


HM_anova=ranovatbl_HM( ...
    {'Group', ...
     '(Intercept):Time', ...
     'Group:Time'},:);


HM_multcompare=multcompare( ...
    rm_HM, ...
    'Time', ...
    'By','Group', ...
    'ComparisonType','bonferroni');


disp(' ')
disp('HM vs LM - BONFERRONI BEFORE/AFTER COMPARISONS')
disp(HM_multcompare)

HM_multcompare=multcompare( ...
    rm_HM, ...
    'Group', ...
    'By','Time', ...
    'ComparisonType','bonferroni');


disp(' ')
disp('HM vs LM - BONFERRONI BEFORE/AFTER COMPARISONS')
disp(HM_multcompare)

Change_HM = After_HM - Before_HM;

[~,~,statsChange_HM] = anova1( ...
    Change_HM, ...
    Group_HM, ...
    'off');

HM_interaction_multcompare = multcompare( ...
    statsChange_HM, ...
    'CType','bonferroni');
HMtable=table(string(statsChange_HM.gnames(HM_interaction_multcompare(:,1))), ...
    string(statsChange_HM.gnames(HM_interaction_multcompare(:,2))), ...
    HM_interaction_multcompare(:,4), ...
    HM_interaction_multcompare(:,3), ...
    HM_interaction_multcompare(:,5), ...
    HM_interaction_multcompare(:,6),'VariableNames',{'Group1','Group2','Difference_Group1_minus_Group2', ...
     'Lower95CI','Upper95CI','Bonferroni_p'});
disp(' ')
disp('HM vs LM Delta - BONFERRONI BEFORE/AFTER COMPARISONS')
disp(HMtable)


HM_results=[ ...
    HM_anova.F(1), ...
    HM_anova.pValue(1), ...
    HM_anova.F(2), ...
    HM_anova.pValue(2), ...
    HM_anova.F(3), ...
    HM_anova.pValue(3)];


fprintf('\nHM vs LM ANOVA:\n')
fprintf('Group: F = %.4f, p = %.6g\n',HM_results(1),HM_results(2))
fprintf('Time: F = %.4f, p = %.6g\n',HM_results(3),HM_results(4))
fprintf('Group x Time: F = %.4f, p = %.6g\n',HM_results(5),HM_results(6))


figure
hold on

for r=1:numResamples

    plot([1 2],RDplotData(r,1:2),'-', ...
        'Color',[0.6 0.6 0.6], ...
        'LineWidth',1)

    plot([3 4],RDplotData(r,3:4),'-', ...
        'Color',[0.6 0.6 0.6], ...
        'LineWidth',1)

    plot([5 6],RDplotData(r,5:6),'-', ...
        'Color',[0.6 0.6 0.6], ...
        'LineWidth',1)

end

boxplot(RDplotData)

xlim([0.5 6.5])
ylim([30 100])

xticks([1.5 3.5 5.5])
xticklabels(groupNames)

ylabel('Model Accuracy')
legend({'Before','After'},'Location','Best')

title('Accuracy Before vs After by Group (RD vs OM)')
subtitle(['Representative seed = ' num2str(representativeSeedRD)])

box on


figure
hold on

for r=1:numResamples

    plot([1 2],HMplotData(r,1:2),'-', ...
        'Color',[0.6 0.6 0.6], ...
        'LineWidth',1)

    plot([3 4],HMplotData(r,3:4),'-', ...
        'Color',[0.6 0.6 0.6], ...
        'LineWidth',1)

    plot([5 6],HMplotData(r,5:6),'-', ...
        'Color',[0.6 0.6 0.6], ...
        'LineWidth',1)

end

boxplot(HMplotData)

xlim([0.5 6.5])
ylim([30 100])

xticks([1.5 3.5 5.5])
xticklabels(groupNames)

ylabel('Model Accuracy')
legend({'Before','After'},'Location','Best')

title('Accuracy Before vs After by Group (HM vs LM)')
subtitle(['Representative seed = ' num2str(representativeSeedHM)])

box on


save('3groups_VMexcluded_boxplot_ANOVA.mat', ...
    'representativeSeedRD', ...
    'representativeSeedHM', ...
    'RDplotData', ...
    'HMplotData', ...
    'ranovatbl_RD', ...
    'ranovatbl_HM', ...
    'RD_multcompare', ...
    'HM_multcompare', ...
    'RD_results', ...
    'HM_results')
%% Full SVM vs Lesioned SVMs
groups={'SuperJazz','Grape','Melon'};
whichgroup = listdlg('PromptString','Select a group:','ListString',groups,'SelectionMode','single');
load([groups{whichgroup} '_yesvideoneurons_SVM_seeds_finalimp.mat'])

ratnames=unique({RAW.Subject});


beforeIdx = binCentersLI >= -2.5 & binCentersLI < 0;
afterIdx  = binCentersLI >= 0 & binCentersLI < 2.5;

RDvsOM=[];
HMvsLM=[];
correctedps_RDvsOM=[];
correctedps_HMvsLM=[];

% PROCESS NO-VIDEO / VM-DEPLETED DATA FOR ALL SEEDS


for seed=1:size(PointWiseAccuracyRDvsOMLI,1)

    for models=1

        PointWiseAccuracyRDvsOMLIlocal=struct;
        PointWiseAccuracyHMvsLMLIlocal=struct;

        for gr=1:size(PointWiseAccuracyRDvsOMLI,2)

            PointWiseAccuracyRDvsOMLIlocal(gr).testaccuracy = ...
                PointWiseAccuracyRDvsOMLI(seed,gr).testaccuracy(models,:);

            PointWiseAccuracyRDvsOMLIlocal(gr).totalshuffledaccuracy = ...
                PointWiseAccuracyRDvsOMLI(seed,gr).totalshuffledaccuracy(models,:,:);

            PointWiseAccuracyHMvsLMLIlocal(gr).testaccuracy = ...
                PointWiseAccuracyHMvsLMLI(seed,gr).testaccuracy(models,:);

            PointWiseAccuracyHMvsLMLIlocal(gr).totalshuffledaccuracy = ...
                PointWiseAccuracyHMvsLMLI(seed,gr).totalshuffledaccuracy(models,:,:);

            PointWiseAccuracyRDvsOMLIlocal(gr).meansubsamptestaccuracy = ...
                mean(PointWiseAccuracyRDvsOMLI(seed,gr).subsamptestaccuracy(:,:),1);

            PointWiseAccuracyHMvsLMLIlocal(gr).meansubsamptestaccuracy = ...
                mean(PointWiseAccuracyHMvsLMLI(seed,gr).subsamptestaccuracy(:,:),1);

        end


        % RD vs OM without video

        subsetb4 = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(beforeIdx), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false)');

        subsetaf = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(afterIdx), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false)');

        RDvsOMwout = ...
            [mean(subsetb4,2) mean(subsetaf,2)];


        % HM vs LM without video

        subsetb4 = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(beforeIdx), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false)');

        subsetaf = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(afterIdx), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false)');

        HMvsLMwout = ...
            [mean(subsetb4,2) mean(subsetaf,2)];


        % RD vs OM without video - shuffle

        subsetb4shuffRDvsOM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,beforeIdx),2), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false))';

        subsetafshuffRDvsOM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,afterIdx),2), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false))';

        pb4_RDvsOM = ...
            (sum(mean(subsetb4shuffRDvsOM,1) >= ...
            mean(RDvsOMwout(:,1)))+1)/(100+1);

        paf_RDvsOM = ...
            (sum(mean(subsetafshuffRDvsOM,1) >= ...
            mean(RDvsOMwout(:,2)))+1)/(100+1);

        correctedps_RDvsOM_without = ...
            [pb4_RDvsOM paf_RDvsOM];


        % HM vs LM without video - shuffle

        subsetb4shuffHMvsLM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,beforeIdx),2), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false))';

        subsetafshuffHMvsLM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,afterIdx),2), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false))';

        pb4_HMvsLM = ...
            (sum(mean(subsetb4shuffHMvsLM,1) >= ...
            mean(HMvsLMwout(:,1)))+1)/(100+1);

        paf_HMvsLM = ...
            (sum(mean(subsetafshuffHMvsLM,1) >= ...
            mean(HMvsLMwout(:,2)))+1)/(100+1);

        correctedps_HMvsLM_without = ...
            [pb4_HMvsLM paf_HMvsLM];


    end


    % SAVE SEED-SPECIFIC RESULTS

    RDvsOMwout_seeds{seed}=RDvsOMwout;
    HMvsLMwout_seeds{seed}=HMvsLMwout;

 

    % Keep the no-video Monte Carlo values separately
    seedps_RDvsOM_without(seed,1:2)=correctedps_RDvsOM_without;
    seedps_HMvsLM_without(seed,1:2)=correctedps_HMvsLM_without;


    % POINTWISE SEED CURVES

    RDvsOM_temp = ...
        cell2mat(arrayfun(@(s) s.testaccuracy, ...
        PointWiseAccuracyRDvsOMLIlocal, ...
        'UniformOutput',false)');

    HMvsLM_temp = ...
        cell2mat(arrayfun(@(s) s.testaccuracy, ...
        PointWiseAccuracyHMvsLMLIlocal, ...
        'UniformOutput',false)');

    RDvsOM_VM_temp = ...
        cell2mat(arrayfun(@(s) s.meansubsamptestaccuracy, ...
        PointWiseAccuracyRDvsOMLIlocal, ...
        'UniformOutput',false)');

    HMvsLM_VM_temp = ...
        cell2mat(arrayfun(@(s) s.meansubsamptestaccuracy, ...
        PointWiseAccuracyHMvsLMLIlocal, ...
        'UniformOutput',false)');


    RDvsOMwout_seedCurves(seed,:) = ...
        mean(RDvsOM_temp,1);

    HMvsLMwout_seedCurves(seed,:) = ...
        mean(HMvsLM_temp,1);

    RDvsOM_VM_seedCurves(seed,:) = ...
        mean(RDvsOM_VM_temp,1);

    HMvsLM_VM_seedCurves(seed,:) = ...
        mean(HMvsLM_VM_temp,1);

end

% SELECT REPRESENTATIVE SEEDS



% RAW DATA


% Grand mean across all 10 seeds


RDvsOMwout_grandMean = ...
    mean(RDvsOMwout_seedCurves,1);


HMvsLMwout_grandMean = ...
    mean(HMvsLMwout_seedCurves,1);


% Point-by-point error from each population's own grand mean


RDvsOMwout_error = ...
    abs(RDvsOMwout_seedCurves - RDvsOMwout_grandMean);


HMvsLMwout_error = ...
    abs(HMvsLMwout_seedCurves - HMvsLMwout_grandMean);


% Representative raw seeds

[~,representativeSeedRDvsOM_raw] = ...
    min(mean(RDvsOMwout_error,2));

[~,representativeSeedHMvsLM_raw] = ...
    min(mean(HMvsLMwout_error,2));
for models=1:size(PointWiseAccuracyRDvsOMLI(1).testaccuracy,1)
    PointWiseAccuracyRDvsOMLIlocal=struct;
    PointWiseAccuracyHMvsLMLIlocal=struct;
    for gr=1:size(PointWiseAccuracyRDvsOMLI,2)
        PointWiseAccuracyRDvsOMLIlocal(gr).testaccuracy= PointWiseAccuracyRDvsOMLI(representativeSeedRDvsOM_raw,gr).testaccuracy(models,:);
        PointWiseAccuracyRDvsOMLIlocal(gr).totalshuffledaccuracy= PointWiseAccuracyRDvsOMLI(representativeSeedRDvsOM_raw,gr).totalshuffledaccuracy(models,:,:);
        PointWiseAccuracyHMvsLMLIlocal(gr).testaccuracy= PointWiseAccuracyHMvsLMLI(representativeSeedHMvsLM_raw,gr).testaccuracy(models,:);
        PointWiseAccuracyHMvsLMLIlocal(gr).totalshuffledaccuracy= PointWiseAccuracyHMvsLMLI(representativeSeedHMvsLM_raw,gr).totalshuffledaccuracy(models,:,:);
    end
% RD vs OM without video
subsetb4 = cell2mat(arrayfun(@(s) s.testaccuracy(beforeIdx), PointWiseAccuracyRDvsOMLIlocal,'UniformOutput', false)');
subsetaf = cell2mat(arrayfun(@(s) s.testaccuracy(afterIdx), PointWiseAccuracyRDvsOMLIlocal,'UniformOutput', false)');
obsBefore=mean(subsetb4,2);
obsAfter=mean(subsetaf,2);
% Keep per-iteration values for stats
RDvsOM = [RDvsOM; mean(subsetb4,2) mean(subsetaf,2) repmat(models,size(subsetb4,1),1)];   % size: iterations x 2
% HM vs LM without video
subsetb4 = cell2mat(arrayfun(@(s) s.testaccuracy(beforeIdx), PointWiseAccuracyHMvsLMLIlocal,'UniformOutput', false)');
subsetaf = cell2mat(arrayfun(@(s) s.testaccuracy(afterIdx), PointWiseAccuracyHMvsLMLIlocal,'UniformOutput', false)');
obsBefore=mean(subsetb4,2);
obsAfter=mean(subsetaf,2);
% Keep per-iteration values for stats
HMvsLM = [HMvsLM; mean(subsetb4,2) mean(subsetaf,2) repmat(models,size(subsetb4,1),1)];  
% RD vs OM without video (shuff)
subsetb4shuffRDvsOM = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,beforeIdx),2), PointWiseAccuracyRDvsOMLIlocal,'UniformOutput', false))';
subsetafshuffRDvsOM = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,afterIdx),2), PointWiseAccuracyRDvsOMLIlocal,'UniformOutput', false))';
    shuffBefore = mean(subsetb4shuffRDvsOM,1);
    shuffAfter  = mean(subsetafshuffRDvsOM,1);
pb4_RDvsOM=(sum(shuffBefore >= mean(obsBefore))+1)/(100+1);
paf_RDvsOM=(sum(shuffAfter  >= mean(obsAfter) )+1)/(100+1);
correctedps_RDvsOM=[correctedps_RDvsOM;pb4_RDvsOM paf_RDvsOM];
% HM vs LM without video (shuff)
subsetb4shuffHMvsLM = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,beforeIdx),2), PointWiseAccuracyHMvsLMLIlocal,'UniformOutput', false)');
subsetafshuffHMvsLM = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,afterIdx),2), PointWiseAccuracyHMvsLMLIlocal,'UniformOutput', false)');
    shuffBefore = mean(subsetb4shuffHMvsLM,1);
    shuffAfter  = mean(subsetafshuffHMvsLM,1);
pb4_HMvsLM=(sum(shuffBefore >= mean(obsBefore))+1)/(100+1);
paf_HMvsLM=(sum(shuffAfter  >= mean(obsAfter))+1)/(100+1);
correctedps_HMvsLM=[correctedps_HMvsLM;pb4_HMvsLM paf_HMvsLM];
end


% Create group labels
Group= categorical(RDvsOM(:,3));
% Create table
T = table(RDvsOM(:,1), RDvsOM(:,2), Group, ...
    'VariableNames', {'Before','After','Group'});

% Specify the within-subject factor (Time)
Time = table(categorical({'Before'; 'After'}), 'VariableNames', {'Time'});

% Fit repeated-measures model
rm = fitrm(T, 'Before-After ~ Group', 'WithinDesign', Time);
ranovatbl = ranova(rm, 'WithinModel', 'Time');
disp(ranovatbl)
multcompare(rm, 'Time', 'By', 'Group', 'ComparisonType', 'bonferroni')
multcompare(rm, 'Group', 'By', 'Time', 'ComparisonType', 'bonferroni')

group = [{'Full'} ratnames];
timepoints = {'Before','After'};

figure; hold on;
data4bp=[];
% X positions for groups

offset = 0.1;  % small horizontal offset for "Before" and "After"
for model=1:length(unique(RDvsOM(:,3)))
% Lines connecting each pseudorat
for r = RDvsOM(:,3)==model
    plot([model*2-1 model*2], [RDvsOM(r,1) RDvsOM(r,2)], '-', ...
        'Color', [0.6 0.6 0.6], 'LineWidth', 1);
end
data4bp=[data4bp RDvsOM(RDvsOM(:,3)==model,1:2)];
end
boxplot(data4bp)
% Formatting
ylim([30 100])
xticks(1.5:2:(2*model-0.5))
xticklabels(group)
ylabel('Model Accuracy')
legend({'Before','After'}, 'Location','Best')
title('Accuracy Before vs After by Group (RDvsOM)')
subtitle(groups{whichgroup})
box on


% Create group labels
Group= categorical(HMvsLM(:,3));
% Create table
T = table(HMvsLM(:,1), HMvsLM(:,2), Group, ...
    'VariableNames', {'Before','After','Group'});

% Specify the within-subject factor (Time)
Time = table(categorical({'Before'; 'After'}), 'VariableNames', {'Time'});

% Fit repeated-measures model
rm = fitrm(T, 'Before-After ~ Group', 'WithinDesign', Time);
ranovatbl = ranova(rm, 'WithinModel', 'Time');
disp(ranovatbl)
multcompare(rm, 'Time', 'By', 'Group', 'ComparisonType', 'bonferroni')

multcompare(rm, 'Group', 'By', 'Time', 'ComparisonType', 'bonferroni')
group = [{'Full'} ratnames];
timepoints = {'Before','After'};

figure; hold on;
data4bp=[];
% X positions for groups
offset = 0.1;  % small horizontal offset for "Before" and "After"
for model=1:length(unique(HMvsLM(:,3)))
% Lines connecting each pseudorat
for r = HMvsLM(:,3)==model
    plot([model*2-1 model*2], [HMvsLM(r,1) HMvsLM(r,2)], '-', ...
        'Color', [0.6 0.6 0.6], 'LineWidth', 1);
end
data4bp=[data4bp HMvsLM(HMvsLM(:,3)==model,1:2)];
end
boxplot(data4bp)
% Formatting
ylim([30 100])
xticks(1.5:2:(2*model-0.5))
xticklabels(group)
ylabel('Model Accuracy')
legend({'Before','After'}, 'Location','Best')
title('Accuracy Before vs After by Group (HMvsLM)')
subtitle(groups{whichgroup})
box on

%% pointwise

labelnames=windowStartLI:5:windowEndLI;
tick_positions=(labelnames-binCentersLI(1))/binsize+1;
zero_idx=tick_positions(labelnames==0);
groups={'SuperJazz','Grape','Melon'};
whichgroup = listdlg('PromptString','Select a group:', ...
    'ListString',groups,'SelectionMode','single');


% LOAD YES-VIDEO / NVM-DEPLETED DATA


load([groups{whichgroup} '_yesvideoneurons_SVM_seeds_finalimp.mat'])

seeds=size(PointWiseAccuracyRDvsOMLI,1);
nResamples=size(PointWiseAccuracyRDvsOMLI,2);
nBins=size(PointWiseAccuracyRDvsOMLI(1,1).testaccuracy,2);

beforeIdx = binCentersLI >= -2.5 & binCentersLI <= 0;
afterIdx  = binCentersLI >= 0 & binCentersLI <= 2.5;


% INITIALIZE POINTWISE SEED CURVES

% Raw/full population
RDvsOMwith_seedCurves = zeros(seeds,nBins);
HMvsLMwith_seedCurves = zeros(seeds,nBins);

% NVM-depleted subsampled population
RDvsOM_NVM_seedCurves = zeros(seeds,nBins);
HMvsLM_NVM_seedCurves = zeros(seeds,nBins);



% PROCESS YES-VIDEO / NVM-DEPLETED DATA FOR ALL SEEDS

for seed=1:seeds

    for models=1

        PointWiseAccuracyRDvsOMLIlocal=struct;
        PointWiseAccuracyHMvsLMLIlocal=struct;

        for gr=1:size(PointWiseAccuracyRDvsOMLI,2)

            PointWiseAccuracyRDvsOMLIlocal(gr).testaccuracy = ...
                PointWiseAccuracyRDvsOMLI(seed,gr).testaccuracy(models,:);

            PointWiseAccuracyRDvsOMLIlocal(gr).totalshuffledaccuracy = ...
                PointWiseAccuracyRDvsOMLI(seed,gr).totalshuffledaccuracy(models,:,:);

            PointWiseAccuracyHMvsLMLIlocal(gr).testaccuracy = ...
                PointWiseAccuracyHMvsLMLI(seed,gr).testaccuracy(models,:);

            PointWiseAccuracyHMvsLMLIlocal(gr).totalshuffledaccuracy = ...
                PointWiseAccuracyHMvsLMLI(seed,gr).totalshuffledaccuracy(models,:,:);


            % Average across the 20 neuron subsamplings
            % for each trial resample

            PointWiseAccuracyRDvsOMLIlocal(gr).meansubsamptestaccuracy = ...
                mean(PointWiseAccuracyRDvsOMLI(seed,gr).subsamptestaccuracy(:,:),1);

            PointWiseAccuracyHMvsLMLIlocal(gr).meansubsamptestaccuracy = ...
                mean(PointWiseAccuracyHMvsLMLI(seed,gr).subsamptestaccuracy(:,:),1);

        end


        % RD vs OM with video

        subsetb4 = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(beforeIdx), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false)');

        subsetaf = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(afterIdx), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false)');

        RDvsOMwith = ...
            [mean(subsetb4,2) mean(subsetaf,2)];


        % HM vs LM with video

        subsetb4 = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(beforeIdx), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false)');

        subsetaf = cell2mat(arrayfun(@(s) ...
            s.testaccuracy(afterIdx), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false)');

        HMvsLMwith = ...
            [mean(subsetb4,2) mean(subsetaf,2)];

% RD vs OM with video - shuffle

        subsetb4shuffRDvsOM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,beforeIdx),2), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false))';

        subsetafshuffRDvsOM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,afterIdx),2), ...
            PointWiseAccuracyRDvsOMLIlocal, ...
            'UniformOutput',false))';

        pb4_RDvsOM = ...
            (sum(mean(subsetb4shuffRDvsOM,1) >= ...
            mean(RDvsOMwith(:,1)))+1)/(100+1);

        paf_RDvsOM = ...
            (sum(mean(subsetafshuffRDvsOM,1) >= ...
            mean(RDvsOMwith(:,2)))+1)/(100+1);

        correctedps_RDvsOM_with = ...
            [pb4_RDvsOM paf_RDvsOM];


        % HM vs LM with video - shuffle

        subsetb4shuffHMvsLM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,beforeIdx),2), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false))';

        subsetafshuffHMvsLM = cell2mat(arrayfun(@(s) ...
            mean(s.totalshuffledaccuracy(:,afterIdx),2), ...
            PointWiseAccuracyHMvsLMLIlocal, ...
            'UniformOutput',false))';

        pb4_HMvsLM = ...
            (sum(mean(subsetb4shuffHMvsLM,1) >= ...
            mean(HMvsLMwith(:,1)))+1)/(100+1);

        paf_HMvsLM = ...
            (sum(mean(subsetafshuffHMvsLM,1) >= ...
            mean(HMvsLMwith(:,2)))+1)/(100+1);

        correctedps_HMvsLM_with = ...
            [pb4_HMvsLM paf_HMvsLM];
       

    end


    % SAVE SEED-SPECIFIC RESULTS

    RDvsOMwith_seeds{seed}=RDvsOMwith;
    HMvsLMwith_seeds{seed}=HMvsLMwith;

  
    seedps_RDvsOM_with(seed,1:2)=correctedps_RDvsOM_with;
    seedps_HMvsLM_with(seed,1:2)=correctedps_HMvsLM_with;


    % POINTWISE SEED CURVES
    % Average across the 50 trial resamples. For the subsampled curves, each trial-resample curve has already been averaged across the 20 neuron subsamplings.

    RDvsOM_temp = ...
        cell2mat(arrayfun(@(s) s.testaccuracy, ...
        PointWiseAccuracyRDvsOMLIlocal, ...
        'UniformOutput',false)');

    HMvsLM_temp = ...
        cell2mat(arrayfun(@(s) s.testaccuracy, ...
        PointWiseAccuracyHMvsLMLIlocal, ...
        'UniformOutput',false)');

   

    RDvsOMwith_seedCurves(seed,:) = ...
        mean(RDvsOM_temp,1);

    HMvsLMwith_seedCurves(seed,:) = ...
        mean(HMvsLM_temp,1);

  
end






% SELECT REPRESENTATIVE SEEDS



% RAW DATA


% Grand mean across all 10 seeds

RDvsOMwith_grandMean = ...
    mean(RDvsOMwith_seedCurves,1);

RDvsOMwout_grandMean = ...
    mean(RDvsOMwout_seedCurves,1);

HMvsLMwith_grandMean = ...
    mean(HMvsLMwith_seedCurves,1);

HMvsLMwout_grandMean = ...
    mean(HMvsLMwout_seedCurves,1);


% Point-by-point error from each population's own grand mean

RDvsOMwith_error = ...
    abs(RDvsOMwith_seedCurves - RDvsOMwith_grandMean);

RDvsOMwout_error = ...
    abs(RDvsOMwout_seedCurves - RDvsOMwout_grandMean);

HMvsLMwith_error = ...
    abs(HMvsLMwith_seedCurves - HMvsLMwith_grandMean);

HMvsLMwout_error = ...
    abs(HMvsLMwout_seedCurves - HMvsLMwout_grandMean);


% Mean point-by-point error for each seed

meanDeviationRDvsOM = ...
    mean(RDvsOMwith_error,2);

meanDeviationHMvsLM = ...
    mean(HMvsLMwith_error,2);


% Representative raw seeds

[~,representativeSeedRDvsOM_raw] = ...
    min(meanDeviationRDvsOM);

[~,representativeSeedHMvsLM_raw] = ...
    min(meanDeviationHMvsLM);
for seed=1
    figure;
    structs={ ...
    PointWiseAccuracyRDvsOMLI(representativeSeedRDvsOM_raw,:), ...
    PointWiseAccuracyHMvsLMLI(2,:)};

subtitlenames={'LI RD vs OM','LI HM vs LM'};


for i=1:numel(structs)

    PointWiseAccuracy=structs{i};

    for j = 1:numel(PointWiseAccuracy)

        PointWiseAccuracy(j).testaccuracy = ...
            PointWiseAccuracy(j).testaccuracy(1,:);

        PointWiseAccuracy(j).totalshuffledaccuracy = ...
            squeeze(PointWiseAccuracy(j).totalshuffledaccuracy(1,:,:));

        PointWiseAccuracy(j).meanshuffledaccuracy = ...
            PointWiseAccuracy(j).meanshuffledaccuracy(1,:);

    end


    windowlength=length(PointWiseAccuracy(1).testaccuracy);

    subplot(2,1,i);

    plotcolor=[0 0 0;0.5 0.5 0.5];

    line(1:windowlength, ...
        mean(reshape([PointWiseAccuracy.testaccuracy], ...
        windowlength,[])'), ...
        'Color',plotcolor(1,:))

    hold on;

    line(1:windowlength, ...
        mean(reshape([PointWiseAccuracy.meanshuffledaccuracy], ...
        windowlength,[])'), ...
        'Color',plotcolor(2,:))


    x_vals = 1:windowlength;


    % Mean and SEM
    m = mean(reshape([PointWiseAccuracy.testaccuracy], ...
        windowlength,[])',1);

    s = nanste(reshape([PointWiseAccuracy.testaccuracy], ...
        windowlength,[])',1);


    % Patch coordinates
    x_patch = [x_vals, fliplr(x_vals)];
    y_patch = [m+s, fliplr(m-s)];

    patch(x_patch, y_patch, plotcolor(1,:), ...
        'EdgeColor', 'none', 'FaceAlpha', 0.3);


    % Mean and SEM
    m = mean(reshape([PointWiseAccuracy.meanshuffledaccuracy], ...
        windowlength,[])',1);

    s = nanste(reshape([PointWiseAccuracy.meanshuffledaccuracy], ...
        windowlength,[])',1);


    % Patch coordinates
    x_patch = [x_vals, fliplr(x_vals)];
    y_patch = [m+s, fliplr(m-s)];

    patch(x_patch, y_patch, [0.7 0.7 0.7], ...
        'EdgeColor', 'none', 'FaceAlpha', 0.3);


    xticks(tick_positions);
    xticklabels(string(labelnames));

    xlim([1 NLI])
    ylim([30 100])

    ylabel('Decoder Accuracy (%)')

    xline(zero_idx,'k:')

    subtitle(subtitlenames(i))


    % for bin=1:length(PointWiseAccuracyRDvsOMLI(1).testaccuracy)
    % [pval,~,stats]=ranksum(cellfun(@(x) x(bin), ...
    % {PointWiseAccuracyRDvsOMLI.testaccuracy}), ...
    % cellfun(@(x) x(bin), ...
    % {PointWiseAccuracyRDvsOMLI.meanshuffledaccuracy}));
    % p(bin)=pval;
    % end


      obs = {PointWiseAccuracy.testaccuracy};
    null = {PointWiseAccuracy.totalshuffledaccuracy};

    nPseudo = length(obs);
    nBins   = length(obs{1});
    nShuff  = size(null{1},1);


    % Compute observed mean decoding curve
    obs_mat = cell2mat(obs');
    obs_mean = mean(obs_mat,1);


    % Compute shuffled mean decoding curves
    null_mean = zeros(nShuff,nBins);

    for s = 1:nShuff

        tmp = zeros(nPseudo,nBins);

        for pRat = 1:nPseudo
            tmp(pRat,:) = null{pRat}(s,:);
        end

        null_mean(s,:) = mean(tmp,1);

    end


% Max-statistic correction across time bins
    % For each shuffle, take the highest decoding accuracy across all bins
    max_null = max(null_mean,[],2);

    % Corrected significance threshold
    threshold = prctile(max_null,95);
    % Significant bins
    sig_bins = find(obs_mean > threshold);

    scatter(sig_bins, ...
        repelem(99,size(sig_bins,2)), ...
        'k*')

end
end
