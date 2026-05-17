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
valididx= cellfun(@(x) length(x{24})>=10, {RAW.Erast});
subject = {RAW(valididx).Subject}';
sex     = {RAW(valididx).Sex}';   % between-subject factor
dosage  = [RAW(valididx).Doseage]';     % outcome
numbneurons=cellfun(@(x) size(x,1),{RAW(valididx).Nrast});
[uniqueSubjects, a, idx] = unique(subject);
neuronsPerSubject = accumarray(idx, numbneurons);

% Put into a table
tbl = table(subject, sex, dosage);

% Convert to categorical
tbl.subject = categorical(tbl.subject);
tbl.sex = categorical(tbl.sex);

% Map each observation to its subject
[uniqueSubjects, a, idxSubj] = unique(subject);           

% Compute mean dosage per animal
meanPerAnimal = accumarray(idxSubj, dosage, [], @mean);   

% Overall mean consumption across all animals
overallMean = mean(meanPerAnimal);                        
overallSEM  = nanste(meanPerAnimal,1);                    % SEM across animals
disp(['Overall mean consumption: ', num2str(overallMean), ' ± ', num2str(overallSEM)])

% Get sex per unique subject (take first occurrence of each subject)
sexPerAnimal = sex(a);
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

%% RD LME to see effect of sex
valididx= cellfun(@(x) length(x{24})>=10, {RAW.Erast});
subject = {RAW(valididx).Subject}';
sex     = {RAW(valididx).Sex}';   % between-subject factor
rewards  = [cellfun(@(x) length(x{24}), {RAW(valididx).Erast})]';     % outcome
numbneurons=cellfun(@(x) size(x,1),{RAW(valididx).Nrast});
[uniqueSubjects, a, idx] = unique(subject);
neuronsPerSubject = accumarray(idx, numbneurons);

% Put into a table
tbl = table(subject, sex, rewards);

% Convert to categorical
tbl.subject = categorical(tbl.subject);
tbl.sex = categorical(tbl.sex);

% Map each observation to its subject
[uniqueSubjects, a, idxSubj] = unique(subject);           

% Compute mean dosage per animal
meanPerAnimal = accumarray(idxSubj, rewards, [], @mean);   

% Overall mean consumption across all animals
overallMean = mean(meanPerAnimal);                        
overallSEM  = nanste(meanPerAnimal,1);                    % SEM across animals
disp(['Overall mean consumption: ', num2str(overallMean), ' ± ', num2str(overallSEM)])

% Get sex per unique subject (take first occurrence of each subject)
sexPerAnimal = sex(a);
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
lme = fitlme(tbl, 'rewards ~ sex + (1|subject)');

% Show results
disp(anova(lme))
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
% 1. Unique sessions and rat mapping
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
[p,tbl,stats]=kruskalwallis(varint,group,'off');
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
