%% Figures for Castro et al. 2026
%% Figure 1
% 1a&b.
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

        end
    end
    fprintf(RAWsinuse{currentRAW});
    globalrds{currentRAW}(isnan(globalrds{currentRAW}))=[];
    globallplat{currentRAW}(isnan(globallplat{currentRAW}))=[];
    globalt2c{currentRAW}(isnan(globalt2c{currentRAW}))=[];
    globalpelat{currentRAW}(isnan(globalpelat{currentRAW}))=[];

end
colors=[0.8, 0.6, 0; 0.5 0 0; 0.2, 0.4, 0];
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

% 1c.
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

end
%% Figure 2
% plot colors
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

% plot results of GLM analysis
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
                    PvalsNull{i}(n,:) = (sum(FstatNull{i}(varExp{i}(:,1)>0, 2:end) >= FstatNull{i}(n,2:end), 1) + 1) ./ (sum(varExp{i}(:,1)>0) + 1);
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

% 2b.
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
    selective = significant;% & significant(:,2);



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
    p = 2 * min( binocdf(sum(significant{bestit}(:,v)),totalNeurons,pcutoff), binocdf(sum(significant{bestit}(:,v))-1,totalNeurons,pcutoff,'upper') );
    p_val(v) = min(p,1);
end


for i = 1:length(variables)
    fprintf('Event: %s, p = %.4f', variables{i}, p_val(i));
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
% 2d.
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
% 2e.
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


[number,g]=groupcounts(R.Ninfo(:,4));
table(g,number)

% 2c.
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

        % Map global neuron indices to session + within-session index
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
        % Plot combined rasters for each modulated neuron
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
%% Figure 3
%Clustering with GLM inputs
%sig modulation data clusters
use=[];
sigmodlogical=[];
selective=significant{bestit};
if contains(whichmat,{'SuperJazz'})
    whichfile='SUPERAPPLE_lick_modulation_nans.mat';
    load(whichfile)
else
    whichfile=[upper(regexp(whichmat, '(.*?)(?=2)', 'match', 'once')),'_lick_modulation.mat'];
    load(whichfile)
end
if contains(whichmat,{'SuperJazz','Melon','Grape'})
    load('R',whichmat,'_Latency_raw_blockskernelsizepostwinBLinepre.mat')
eventsforanalysis=[1:4];
    selective=selective(:,eventsforanalysis);
eventsforanalysiscolumns=[1:all_columnstart(5)-1,all_columnstart(6):all_columnstart(7)-1];
else
%load('RSuperApple_Latency_raw_blockskernelsizepostwinBLinepre.mat')
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
        end
end
sigmodlogical(:,end+1)=lickmodulation;
criteriamet=[R.Bmean>1,varExp{bestit}(:,1)>0,~isnan(lickmodulation)];
allcritmet=sum(criteriamet,2)==size(criteriamet,2);
sigmodlogical=sigmodlogical(allcritmet,:);
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
directionsigns=directionsigns(allcritmet,:);
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

% 3a.
figure;
% Identify GLM-only signs
glmSigns = directionsigns;
glmSigns(glmSigns==2) = 0;  % ignore lick for streak calc

nNeurons = size(glmSigns,1);
maxConsec = zeros(nNeurons,1);

% Determine first-event index and sign
[~, firstEventIdx] = max(abs(glmSigns),[],2);
rows = (1:nNeurons)';
firstSign = glmSigns(sub2ind(size(glmSigns), rows, firstEventIdx));

% Compute consecutive streak starting at first event
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

% Separate groups
posNeurons     = find(firstSign > 0);
negNeurons     = find(firstSign < 0);
neutralNeurons = find(all(glmSigns==0,2) & ~any(directionsigns==2,2));
lickOnly       = find(any(directionsigns==2,2) & all(glmSigns==0,2));

% Identify lick-modulated neurons
lickResp = any(directionsigns==2,2);

% Build matrix of subsequent event signs for tertiary+ sorting
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

% Global hierarchical sorting (first-event, streak, next signs)
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


% Concatenate final neuron order
neurons = [
    posSorted;
    lickOnlySorted;
    neutralSorted;
    flip(negSorted)
];

% Plot
imagesc(directionsigns(neurons,:));
colormap([
    0 0 1;      % -1
    1 1 1;      %  0
    1 0 0;      % +1
    0.7 0.7 0.7 %  2 lick-modulated
]);
clim([-1 2]);




figure;

% 3b.
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

% 3c.
subplot(5,1,3)
negresp  = any(directionsigns==-1,2);
posresp  = any(directionsigns== 1,2);
lickresp = any(directionsigns== 2,2);

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

% 3d.
subplot(5,1,4)
histogram(sum(sigmodlogical,2),'FaceColor','k')
ylabel('Count')

% 3e.
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

%% Figure 4
% 4a-b. Run below after initalizing %plot colors and %plot results of GLM
% analysis with the GLM results that include all trials ("AT" in title)
% 4c-d. As in 4a-b, but using GLM results that only include seek trials
% ("RD" in title)

% rasters (vs)
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
        LInull=significantNull{bestit}(:,LIidx)==1;
    LIonlynull=significantNull{bestit}(:,LIidx)==1 & significantNull{bestit}(:,LIintidx)==0;
    LIintnull=significantNull{bestit}(:,LIintidx)==1;
    LIintonlynull=significantNull{bestit}(:,LIidx)==0 & significantNull{bestit}(:,LIintidx)==1;
    LIbothnull=significantNull{bestit}(:,LIidx)==1 & significantNull{bestit}(:,LIintidx)==1;

     pLIonly = 2 * min( binocdf(sum(LIonly),totalNeurons,pcutoff), binocdf(sum(LIonly)-1,totalNeurons,pcutoff,'upper') );
     pLIintonly = 2 * min( binocdf(sum(LIintonly),totalNeurons,pcutoff), binocdf(sum(LIintonly)-1,totalNeurons,pcutoff,'upper') );
     pLIboth = 2 * min( binocdf(sum(LIboth),totalNeurons,pcutoff), binocdf(sum(LIboth)-1,totalNeurons,pcutoff,'upper') );
     p_val=[pLIonly, pLIintonly, pLIboth];
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
            LRnull=significantNull{bestit}(:,LRidx)==1;
    LRonlynull=significantNull{bestit}(:,LRidx)==1 & significantNull{bestit}(:,LRintidx)==0;
    LRintnull=significantNull{bestit}(:,LRintidx)==1;
    LRintonlynull=significantNull{bestit}(:,LRidx)==0 & significantNull{bestit}(:,LRintidx)==1;
    LRbothnull=significantNull{bestit}(:,LRidx)==1 & significantNull{bestit}(:,LRintidx)==1;
     pLRonly = 2 * min( binocdf(sum(LRonly),totalNeurons,pcutoff), binocdf(sum(LRonly)-1,totalNeurons,pcutoff,'upper') );
     pLRintonly = 2 * min( binocdf(sum(LRintonly),totalNeurons,pcutoff), binocdf(sum(LRintonly)-1,totalNeurons,pcutoff,'upper') );
     pLRboth = 2 * min( binocdf(sum(LRboth),totalNeurons,pcutoff), binocdf(sum(LRboth)-1,totalNeurons,pcutoff,'upper') );
          p_val=[pLRonly, pLRintonly, pLRboth];

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

        % Map global neuron indices to session + within-session index
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
        % Plot combined rasters for each modulated neuron
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
%% Figure 5
% 5a-c.
OM = [0.3 0.3 0.3];
RD = [0.01 0.87 0.02];
hm = [0.77 0.1 0.37];
lm = [0.2 0.28 0.45];
ylims=[0 150;0 100;0 250];
RAWsinuse={'RAWSuperJazz_Latency_raw_addedvars.mat','RAWGrape_Latency_raw.mat','RAWMelon_Latency_raw.mat'};
gnames={'EtOHEtOH','EtOHSuc','NoEtOHSuc'};
allgroups_vidbehav={};
for g=1:length(RAWsinuse)
    load(RAWsinuse{g})
    LIidx=strcmp(RAW(1).Einfo(:,2),'LeverInsertion');
angidx=strcmp(RAW(1).Einfo(:,2),'SessionAngleOfHeadToLever(Model)');
velidx=strcmp(RAW(1).Einfo(:,2),'SessionInstvelocity(Model)');
LIdistidx=strcmp(RAW(1).Einfo(:,2),'SessionLeverDistance(Model)');
for i=1:length(RAW)
    SessName{i,:}=RAW(i).Ninfo{1,1}(10:12);
    SessNumb(i,:)=str2num(RAW(i).Ninfo{1,1}(11:12));
    ratnames=unique({RAW.Subject});
end

Data=unique(SessName(~cellfun(@isempty,SessName)));
nBins=length((-15:0.025:5))-1;
nCents=-15:0.025:5;
for session=1:length(RAW)
        ratsession=RAW(session).Ninfo{1,1}(10:12);
        rat=strcmp(RAW(session).Subject,ratnames);
        row2go=contains([Data(:,1)],ratsession);
    trialStartTimes=RAW(session).Erast{LIidx};
    binCenters=RAW(session).Erast{angidx,2};
    angle=RAW(session).Erast{angidx,1};
    velocity=RAW(session).Erast{velidx,1};
    LIdist=RAW(session).Erast{LIdistidx,1};
    anglepertrial = cell(length(trialStartTimes),1);
    ITIvelpertrial = cell(length(trialStartTimes),1);
    LIdistpertrial = cell(length(trialStartTimes),1);
        anglepertrial_post = cell(length(trialStartTimes),1);
    ITIvelpertrial_post = cell(length(trialStartTimes),1);
    LIdistpertrial_post = cell(length(trialStartTimes),1);
    angle_pw=nan(length(trialStartTimes),nBins);
    velocity_pw=nan(length(trialStartTimes),nBins);
    LIdistance_pw=nan(length(trialStartTimes),nBins);
    for tr = 1:length(trialStartTimes)
        % Define time window relative to this trial start
        tStart = trialStartTimes(tr) - 2.5;
        tEnd   = trialStartTimes(tr);

        % Get indices of binCenters within the window
        idx = binCenters >= tStart & binCenters <= tEnd;

        if sum(idx) > 1
            % Distance = sum of stepwise movement
            % posSegment = angle(idx,:);
            % diffs = diff(posSegment,1,1);
            % % Euclidean distances
            % stepDist = sqrt(sum(diffs.^2,2));
            % distancePerTrial{tr} = sum(abs(diff(stepDist)));
            ITIvelpertrial{tr}=mean(velocity(idx));
             LIdistpertrial{tr}= mean(LIdist(idx));
        anglepertrial{tr}=mean(angle(idx));
        else
            ITIvelpertrial{tr}=NaN; 
            LIdistpertrial{tr}= NaN;
        anglepertrial{tr}=NaN;
        end

        % Define time window relative to this trial start
        tStart = trialStartTimes(tr);
        tEnd   = trialStartTimes(tr) + 2.5;

        % Get indices of binCenters within the window
        idx = binCenters >= tStart & binCenters <= tEnd;

        if sum(idx) > 1
            % Distance = sum of stepwise movement
            % posSegment = angle(idx,:);
            % diffs = diff(posSegment,1,1);
            % % Euclidean distances
            % stepDist = sqrt(sum(diffs.^2,2));
            % distancePerTrial{tr} = sum(abs(diff(stepDist)));
            ITIvelpertrial_post{tr}=mean(velocity(idx));        
            LIdistpertrial_post{tr}= mean(LIdist(idx));
        anglepertrial_post{tr}=mean(angle(idx));
        else
            ITIvelpertrial_post{tr}=NaN;
        end



        tStart = trialStartTimes(tr) - 15;
        tEnd   = trialStartTimes(tr) + 5;

        idx = binCenters >= tStart & binCenters < tEnd;
  
            velocity_pw(tr,:) = velocity(idx)';
            LIdistance_pw(tr,:)= LIdist(idx)';
            angle_pw(tr,:)= angle(idx)';
            

    end
    LIdistance_pw(:,end)=[];
    Data{row2go,2}{rat,1}=RAW(session).Erast{41};
    Data{row2go,2}{rat,2}=anglepertrial;
    Data{row2go,2}{rat,3}=ITIvelpertrial;
    Data{row2go,2}{rat,4}=LIdistpertrial;
    Data{row2go,2}{rat,5}=angle_pw;
    Data{row2go,2}{rat,6}=velocity_pw;
    Data{row2go,2}{rat,7}=LIdistance_pw;
    Data{row2go,2}{rat,8}=anglepertrial_post;
    Data{row2go,2}{rat,9}=ITIvelpertrial_post;
    Data{row2go,2}{rat,10}=LIdistpertrial_post;    
end

rddist=[];
omdist=[];
vidbehav={};
vidbehav_post={};
vidbehav_pw={};
% Find variable and align to trial
for session=1:length(Data)
    for rat=1:size(Data{session,2},1)
        tmpa= Data{session,2}{rat,1};
        tmpdist= Data{session,2}{rat,2};
        tmpvel= Data{session,2}{rat,3};
        tmpLIdist= Data{session,2}{rat,4};
        tmpdist_pw= Data{session,2}{rat,5};
        tmpvel_pw= Data{session,2}{rat,6};
        tmpLIdist_pw=Data{session,2}{rat,7};
        tmpdist_post= Data{session,2}{rat,8};
        tmpvel_post= Data{session,2}{rat,9};
        tmpLIdist_post=Data{session,2}{rat,10};

        ratID_col = repmat(ratnames(rat), size(tmpa,1), 1);
        tmp=[tmpa tmpdist tmpvel tmpLIdist ratID_col];
        tmp_post=[tmpa tmpdist_post tmpvel_post tmpLIdist_post ratID_col];
        tmp_pw=[tmpa num2cell(tmpdist_pw,2) num2cell(tmpvel_pw,2) num2cell(tmpLIdist_pw,2) ratID_col];
        vidbehav=[vidbehav;tmp];
         vidbehav_post=[vidbehav_post;tmp_post];
        vidbehav_pw=[vidbehav_pw;tmp_pw];
    end
end
rdbehav=vidbehav(~contains(vidbehav(:,1),'omission'),:);
ombehav=vidbehav(contains(vidbehav(:,1),'omission'),:);
lmbehav=vidbehav(contains(vidbehav(:,1),'low'),:);
hmbehav=vidbehav(contains(vidbehav(:,1),'high'),:);
rdbehav_post=vidbehav_post(~contains(vidbehav_post(:,1),'omission'),:);
ombehav_post=vidbehav_post(contains(vidbehav_post(:,1),'omission'),:);
lmbehav_post=vidbehav_post(contains(vidbehav_post(:,1),'low'),:);
hmbehav_post=vidbehav_post(contains(vidbehav_post(:,1),'high'),:);
rdbehav_pw=vidbehav_pw(~contains(vidbehav_pw(:,1),'omission'),:);
ombehav_pw=vidbehav_pw(contains(vidbehav_pw(:,1),'omission'),:);
lmbehav_pw=vidbehav_pw(contains(vidbehav_pw(:,1),'low'),:);
hmbehav_pw=vidbehav_pw(contains(vidbehav_pw(:,1),'high'),:);
%diff?
behaviors={'Avg Head to LVR angle (degrees)','ITI Velocity (pxl/s)','Pre LI Distance (pxl)'};
behaviors_pw={'Head to LVR angle (degrees)','Velocity (pxl/s)','LI Distance (pxl)'};
groupNames1 = {'RD','OM'};
groupNames2 = {'HM','LM'};
figure;
nBeh=length(behaviors);
for behavior=2:size(vidbehav,2)-1

       % Compute rat-wise means
    data_rd = [];
    data_om = [];
    data_hm = [];
    data_lm = [];
    for r=1:length(ratnames)
        idx_rd = strcmp(rdbehav(:,end), ratnames{r});
        idx_om = strcmp(ombehav(:,end), ratnames{r});
        idx_hm = strcmp(hmbehav(:,end), ratnames{r});
        idx_lm = strcmp(lmbehav(:,end), ratnames{r});
        
        if any(idx_rd), data_rd(end+1) = mean(cell2mat(rdbehav(idx_rd,behavior))); end
        if any(idx_om), data_om(end+1) = mean(cell2mat(ombehav(idx_om,behavior))); end
        if any(idx_hm), data_hm(end+1) = mean(cell2mat(hmbehav(idx_hm,behavior))); end
        if any(idx_lm), data_lm(end+1) = mean(cell2mat(lmbehav(idx_lm,behavior))); end
    end

[hyprd,prd,~,statsrd]=ttest(data_rd,data_om);
[hyphvl,phvl,~,statsvl]=ttest(data_hm,data_lm);
fprintf('%s:\n', behaviors{behavior-1});
fprintf('   RD vs OM: p = %.2e t(%d): %.2e\n', prd,statsrd.df,statsrd.tstat);
fprintf('   HM vs LM: p = %.2e t(%d): %.2e\n\n', phvl,statsvl.df,statsvl.tstat);
    %  % Compute means and SEMs
    % means1 = [mean(data_rd), mean(data_om)];
    % sems1  = [std(data_rd)/sqrt(length(data_rd)), std(data_om)/sqrt(length(data_om))];
    % 
    % means2 = [mean(data_hm), mean(data_lm)];
    % sems2  = [std(data_hm)/sqrt(length(data_hm)), std(data_lm)/sqrt(length(data_lm))];
    % 
    %    % Create subplot for this behavior
    % subplot(nBeh, 2, behavior*2-3);
    % hold on;
    % anova1
    % % Bar positions
     x1 = 1:2; % RD vs OM
     x2 = 3:4; % HM vs LM
    % 
    % % Plot RD vs OM
    % b1 = bar(x1, means1);
    % set(b1,'FaceColor','flat');
    % b1.CData=[RD;OM];
    % 
    % % Plot HM vs LM
    % b2 = bar(x2, means2);
    % set(b2,'FaceColor','flat');
    % b2.CData=[hm;lm];
    %errorbar(x1, means1, sems1, 'k', 'LineStyle','none');
    %errorbar(x2, means2, sems2, 'k', 'LineStyle','none');

    allData = [data_rd(:); data_om(:); data_hm(:); data_lm(:)];
    group   = [ones(size(data_rd(:))); 2*ones(size(data_om(:))); 3*ones(size(data_hm(:))); 4*ones(size(data_lm(:)))];

subplot(nBeh, 3, behavior*3-5);
hold on;

x_rd = ones(size(data_rd));        
x_om = 2*ones(size(data_om));      

% Lines connecting each rat
for r = 1:length(data_rd)
    plot([1 2], [data_rd(r) data_om(r)], '-', ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 1);
end

% Dots
scatter(x_rd, data_rd, 50, RD, 'filled');
scatter(x_om, data_om, 50, OM, 'filled');

x_hm = 3*ones(size(data_hm));        % x = 1 for RD
x_lm = 4*ones(size(data_lm));      % x = 2 for OM

% Lines connecting each rat
for r = 1:length(data_hm)
    plot([3 4], [data_hm(r) data_lm(r)], '-', ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 1);
end

% Dots
scatter(x_hm, data_hm, 50, hm, 'filled');
scatter(x_lm, data_lm, 50, lm, 'filled');

ylabel(behaviors{behavior-1});
    % Error barscl

        if prd < 0.001
        stars = '***';
    elseif prd < 0.01
        stars = '**';
    elseif prd < 0.05
        stars = '*';
    else
        stars = 'n.s.';
        end
        lims=gca;
        lims.YLim=[lims.YLim(1) lims.YLim(end)*1.05];
    text(mean(x1), lims.YLim(end)-lims.YLim(end)/30, stars, 'HorizontalAlignment','center', 'FontSize',12);
    pStr = sprintf('p=%.2e\nt %.2e', prd,statsrd.tstat);  % use scientific notation

% Place text on plot
text(mean(x1), lims.YLim(end)+lims.YLim(end)/5, pStr, 'HorizontalAlignment','center', 'FontSize',12);
    % --- significance for HM vs LM ---

    if phvl < 0.001
        stars = '***';
    elseif phvl < 0.01
        stars = '**';
    elseif phvl < 0.05
        stars = '*';
    else
        stars = 'n.s.';
    end
    text(mean(x2), lims.YLim(end)-lims.YLim(end)/30, stars, 'HorizontalAlignment','center', 'FontSize',12);
    pStr = sprintf('p=%.2e\nt(%d) %.2e', phvl,statsvl.df,statsvl.tstat);  % use scientific notation

% Place text on plot
text(mean(x2), lims.YLim(end)+lims.YLim(end)/5, pStr, 'HorizontalAlignment','center', 'FontSize',12);
    % X-axis
    xticks([mean(x1), mean(x2)]);
    xticklabels({'RD vs OM','HM vs LM'});
    ylabel(behaviors{behavior-1});
    xlim([0 5])
    ylim(ylims(behavior-1,:))
    box off;

              % Compute rat-wise means
    data_rd = [];
    data_om = [];
    data_hm = [];
    data_lm = [];
    for r=1:length(ratnames)
        idx_rd = strcmp(rdbehav_post(:,end), ratnames{r});
        idx_om = strcmp(ombehav_post(:,end), ratnames{r});
        idx_hm = strcmp(hmbehav_post(:,end), ratnames{r});
        idx_lm = strcmp(lmbehav_post(:,end), ratnames{r});
        
        if any(idx_rd), data_rd(end+1) = mean(cell2mat(rdbehav_post(idx_rd,behavior))); end
        if any(idx_om), data_om(end+1) = mean(cell2mat(ombehav_post(idx_om,behavior))); end
        if any(idx_hm), data_hm(end+1) = mean(cell2mat(hmbehav_post(idx_hm,behavior))); end
        if any(idx_lm), data_lm(end+1) = mean(cell2mat(lmbehav_post(idx_lm,behavior))); end
    end
[hyprd,prd,~,statsrd]=ttest(data_rd,data_om);
[hypphvl,phvl,~,statsvl]=ttest(data_hm,data_lm);
fprintf('%s:\n', behaviors{behavior-1});
fprintf('   RD vs OM: p = %.2e t(%d): %.2e\n', prd,statsrd.df,statsrd.tstat);
fprintf('   HM vs LM: p = %.2e t(%d): %.2e\n\n', phvl,statsvl.df,statsvl.tstat);
    %  % Compute means and SEMs
    % means1 = [mean(data_rd), mean(data_om)];
    % sems1  = [std(data_rd)/sqrt(length(data_rd)), std(data_om)/sqrt(length(data_om))];
    % 
    % means2 = [mean(data_hm), mean(data_lm)];
    % sems2  = [std(data_hm)/sqrt(length(data_hm)), std(data_lm)/sqrt(length(data_lm))];
    % 
    %    % Create subplot for this behavior
    % subplot(nBeh, 2, behavior*2-3);
    % hold on;
    % 
    % % Bar positions
     x1 = 1:2; % RD vs OM
     x2 = 3:4; % HM vs LM
    % 
    % % Plot RD vs OM
    % b1 = bar(x1, means1);
    % set(b1,'FaceColor','flat');
    % b1.CData=[RD;OM];
    % 
    % % Plot HM vs LM
    % b2 = bar(x2, means2);
    % set(b2,'FaceColor','flat');
    % b2.CData=[hm;lm];
    %errorbar(x1, means1, sems1, 'k', 'LineStyle','none');
    %errorbar(x2, means2, sems2, 'k', 'LineStyle','none');

    allData = [data_rd(:); data_om(:); data_hm(:); data_lm(:)];
group   = [ones(size(data_rd(:))); 2*ones(size(data_om(:))); 3*ones(size(data_hm(:))); 4*ones(size(data_lm(:)))];

subplot(nBeh, 3, behavior*3-4);
hold on;

x_rd = ones(size(data_rd));        
x_om = 2*ones(size(data_om));      

% Lines connecting each rat
for r = 1:length(data_rd)
    plot([1 2], [data_rd(r) data_om(r)], '-', ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 1);
end

% Dots
scatter(x_rd, data_rd, 50, RD, 'filled');
scatter(x_om, data_om, 50, OM, 'filled');

x_hm = 3*ones(size(data_hm));        % x = 1 for RD
x_lm = 4*ones(size(data_lm));      % x = 2 for OM

% Lines connecting each rat
for r = 1:length(data_hm)
    plot([3 4], [data_hm(r) data_lm(r)], '-', ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 1);
end

% Dots
scatter(x_hm, data_hm, 50, hm, 'filled');
scatter(x_lm, data_lm, 50, lm, 'filled');
ylabel(behaviors{behavior-1});
    % Error barscl

        if prd < 0.001
        stars = '***';
    elseif prd < 0.01
        stars = '**';
    elseif prd < 0.05
        stars = '*';
    else
        stars = 'n.s.';
        end
        lims=gca;
        lims.YLim=[lims.YLim(1) lims.YLim(end)*1.05];
    text(mean(x1), lims.YLim(end)-lims.YLim(end)/30, stars, 'HorizontalAlignment','center', 'FontSize',12);
    pStr = sprintf('p=%.2e\nt(%d) %.2e', prd,statsrd.df,statsrd.tstat);  % use scientific notation

% Place text on plot
text(mean(x1), lims.YLim(end)+lims.YLim(end)/5, pStr, 'HorizontalAlignment','center', 'FontSize',12);
    % --- significance for HM vs LM ---

    if phvl < 0.001
        stars = '***';
    elseif phvl < 0.01
        stars = '**';
    elseif phvl < 0.05
        stars = '*';
    else
        stars = 'n.s.';
    end
    text(mean(x2), lims.YLim(end)-lims.YLim(end)/30, stars, 'HorizontalAlignment','center', 'FontSize',12);
    pStr = sprintf('p=%.2e\nt %.2e', phvl,statsvl.tstat);  % use scientific notation

% Place text on plot
text(mean(x2), lims.YLim(end)+lims.YLim(end)/5, pStr, 'HorizontalAlignment','center', 'FontSize',12);
    % X-axis
    xticks([mean(x1), mean(x2)]);
    xticklabels({'RD vs OM','HM vs LM'});
    ylabel(behaviors{behavior-1});
    xlim([0 5])
    ylim(ylims(behavior-1,:))
    box off;

    subplot(nBeh,3,behavior*3-3)
      data_rd_pw=[];
        data_om_pw=[];
        data_hm_pw=[];
        data_lm_pw=[];
    for r = 1:length(ratnames)
        data_rd_pw(r,:) = mean(cell2mat(rdbehav_pw(strcmp(rdbehav_pw(:,end), ratnames{r}),behavior)), 1);
        data_om_pw(r,:) = mean(cell2mat(ombehav_pw(strcmp(ombehav_pw(:,end), ratnames{r}),behavior)), 1);
        data_hm_pw(r,:) = mean(cell2mat(hmbehav_pw(strcmp(hmbehav_pw(:,end), ratnames{r}),behavior)), 1);
        data_lm_pw(r,:) = mean(cell2mat(lmbehav_pw(strcmp(lmbehav_pw(:,end), ratnames{r}),behavior)), 1);
    end

    % data_rd_pw  = cell2mat([rdbehav_pw(:,behavior)]);
    % data_om_pw  = cell2mat([ombehav_pw(:,behavior)]);
    % data_hm_pw  = cell2mat([hmbehav_pw(:,behavior)]);
    % data_lm_pw  = cell2mat([lmbehav_pw(:,behavior)]);
    line(1:size(data_hm_pw,2),mean(data_hm_pw),'Color',hm)
    % X axis
    x_vals = 1:size(data_hm_pw,2);

    % Mean and SEM (or STD if you prefer)
    m = mean(data_hm_pw,1);
    s = nanste(data_hm_pw,1);   % std across rows

    % Patch coordinates
    x_patch = [x_vals, fliplr(x_vals)];
    y_patch = [m+s, fliplr(m-s)];
    patch(x_patch, y_patch, hm, 'EdgeColor', 'none', 'FaceAlpha', 0.3);

    line(1:size(data_lm_pw,2),mean(data_lm_pw),'Color',lm)
      % X axis
    x_vals = 1:size(data_lm_pw,2);

    % Mean and SEM (or STD if you prefer)
    m = mean(data_lm_pw,1);
    s = nanste(data_lm_pw,1);   % std across rows

    % Patch coordinates
    x_patch = [x_vals, fliplr(x_vals)];
    y_patch = [m+s, fliplr(m-s)];
    patch(x_patch, y_patch, lm, 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    line(1:size(data_rd_pw,2),mean(data_rd_pw),'Color',RD)
      % X axis
    x_vals = 1:size(data_rd_pw,2);

    % Mean and SEM (or STD if you prefer)
    m = mean(data_rd_pw,1);
    s = nanste(data_rd_pw,1);   % std across rows

    % Patch coordinates
    x_patch = [x_vals, fliplr(x_vals)];
    y_patch = [m+s, fliplr(m-s)];
    patch(x_patch, y_patch, RD, 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    line(1:size(data_om_pw,2),mean(data_om_pw),'Color',OM)
  % X axis
    x_vals = 1:size(data_om_pw,2);

    % Mean and SEM (or STD if you prefer)
    m = mean(data_om_pw,1);
    s = nanste(data_om_pw,1);   % std across rows

    % Patch coordinates
    x_patch = [x_vals, fliplr(x_vals)];
    y_patch = [m+s, fliplr(m-s)];
    patch(x_patch, y_patch, OM, 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    Ax=gca;
    xticklabels(nCents(Ax.XTick+1))
    xline(find(nCents==0),'k:','LineWidth',2)
    ylabel(behaviors_pw{behavior-1});
    % rdvsomavg=[ ]
    % rdvsomstd=
    % hmvslmavg=[]
    % hmvslmstd=
end
vidbehav(:,end+1)=repelem(gnames(g),size(vidbehav,1))';
allgroups_vidbehav=[allgroups_vidbehav;vidbehav];
end

% 5d&f.
figure;
labelnames=windowStartLI:5:windowEndLI;
tick_positions=(labelnames-binCentersLI(1))/binsize+1;
zero_idx=tick_positions(labelnames==0);

p=[];
subplot(2,2,1);line(1:length(PointWiseAccuracyRDvsOMLI(1).testaccuracy),mean(reshape([PointWiseAccuracyRDvsOMLI.testaccuracy],length(PointWiseAccuracyRDvsOMLI(1).testaccuracy),[])'),'Color','g')
hold on; line(1:length(PointWiseAccuracyRDvsOMLI(1).testaccuracy),mean(reshape([PointWiseAccuracyRDvsOMLI.meanshuffledaccuracy],length(PointWiseAccuracyRDvsOMLI(1).testaccuracy),[])'),'Color',[0.5 0.5 0.5])

x_vals = 1:length(PointWiseAccuracyRDvsOMLI(1).testaccuracy);

% Mean and SEM
m = mean(reshape([PointWiseAccuracyRDvsOMLI.testaccuracy],length(PointWiseAccuracyRDvsOMLI(1).testaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyRDvsOMLI.testaccuracy],length(PointWiseAccuracyRDvsOMLI(1).testaccuracy),[])',1);   
% Patch coordinates
x_patch = [x_vals, fliplr(x_vals)];
y_patch = [m+s, fliplr(m-s)];
patch(x_patch, y_patch, 'g', 'EdgeColor', 'none', 'FaceAlpha', 0.3);
x_vals = 1:length(PointWiseAccuracyRDvsOMLI(1).meanshuffledaccuracy);

% Mean and SEM 
m = mean(reshape([PointWiseAccuracyRDvsOMLI.meanshuffledaccuracy],length(PointWiseAccuracyRDvsOMLI(1).meanshuffledaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyRDvsOMLI.meanshuffledaccuracy],length(PointWiseAccuracyRDvsOMLI(1).meanshuffledaccuracy),[])',1);   

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

% Compute observed mean decoding curve
obs_mat = cell2mat(obs');           % nPseudo x nBins
obs_mean = mean(obs_mat,1);         % 1 x nBins
% Compute shuffled mean decoding curves
null_mean = zeros(nShuff,nBins);

for s = 1:nShuff
    tmp = zeros(nPseudo,nBins);
    for pRat = 1:nPseudo
        tmp(pRat,:) = null{pRat}(s,:);
    end
    null_mean(s,:) = mean(tmp,1);
end


%Compute corrected p-values
p = zeros(1,nBins);

for b = 1:nBins
    p(b) = (sum(null_mean(:,b) >= obs_mean(b)) + 1) / (nShuff + 1);
end

%Significant bins
alph = 0.05;
sig_bins = find(p < alph);

scatter(sig_bins,repelem(99,size(sig_bins,2)),'k*')

p=[];
subplot(2,2,3);line(1:length(PointWiseAccuracyHMvsLMLI(1).testaccuracy),mean(reshape([PointWiseAccuracyHMvsLMLI.testaccuracy],length(PointWiseAccuracyHMvsLMLI(1).testaccuracy),[])'),'Color',[0.5 0 1])
hold on; line(1:length(PointWiseAccuracyHMvsLMLI(1).testaccuracy),mean(reshape([PointWiseAccuracyHMvsLMLI.meanshuffledaccuracy],length(PointWiseAccuracyHMvsLMLI(1).testaccuracy),[])'),'Color',[0.7 0.7 0.7])
x_vals = 1:length(PointWiseAccuracyHMvsLMLI(1).testaccuracy);

% Mean and SEM
m = mean(reshape([PointWiseAccuracyHMvsLMLI.testaccuracy],length(PointWiseAccuracyHMvsLMLI(1).testaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyHMvsLMLI.testaccuracy],length(PointWiseAccuracyHMvsLMLI(1).testaccuracy),[])',1);   

% Patch coordinates
x_patch = [x_vals, fliplr(x_vals)];
y_patch = [m+s, fliplr(m-s)];
patch(x_patch, y_patch, [0.5 0 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
x_vals = 1:length(PointWiseAccuracyHMvsLMLI(1).meanshuffledaccuracy);

% Mean and SEM
m = mean(reshape([PointWiseAccuracyHMvsLMLI.meanshuffledaccuracy],length(PointWiseAccuracyHMvsLMLI(1).meanshuffledaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyHMvsLMLI.meanshuffledaccuracy],length(PointWiseAccuracyHMvsLMLI(1).meanshuffledaccuracy),[])',1);   

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

% Compute observed mean decoding curve
obs_mat = cell2mat(obs');           % nPseudo x nBins
obs_mean = mean(obs_mat,1);         % 1 x nBins
% Compute shuffled mean decoding curves
null_mean = zeros(nShuff,nBins);

for s = 1:nShuff
    tmp = zeros(nPseudo,nBins);
    for pRat = 1:nPseudo
        tmp(pRat,:) = null{pRat}(s,:);
    end
    null_mean(s,:) = mean(tmp,1);
end

%Compute corrected p-values
p = zeros(1,nBins);

for b = 1:nBins
    p(b) = (sum(null_mean(:,b) >= obs_mean(b)) + 1) / (nShuff + 1);
end

%Significant bins
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

% Mean and SEM 
m = mean(reshape([PointWiseAccuracyRDvsOMLR.testaccuracy],length(PointWiseAccuracyRDvsOMLR(1).testaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyRDvsOMLR.testaccuracy],length(PointWiseAccuracyRDvsOMLR(1).testaccuracy),[])',1);   

% Patch coordinates
x_patch = [x_vals, fliplr(x_vals)];
y_patch = [m+s, fliplr(m-s)];
patch(x_patch, y_patch, 'g', 'EdgeColor', 'none', 'FaceAlpha', 0.3);
x_vals = 1:length(PointWiseAccuracyRDvsOMLR(1).meanshuffledaccuracy);

% Mean and SEM 
m = mean(reshape([PointWiseAccuracyRDvsOMLR.meanshuffledaccuracy],length(PointWiseAccuracyRDvsOMLR(1).meanshuffledaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyRDvsOMLR.meanshuffledaccuracy],length(PointWiseAccuracyRDvsOMLR(1).meanshuffledaccuracy),[])',1);   

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

% Compute observed mean decoding curve
obs_mat = cell2mat(obs');           % nPseudo x nBins
obs_mean = mean(obs_mat,1);         % 1 x nBins
% Compute shuffled mean decoding curves
null_mean = zeros(nShuff,nBins);

for s = 1:nShuff
    tmp = zeros(nPseudo,nBins);
    for pRat = 1:nPseudo
        tmp(pRat,:) = null{pRat}(s,:);
    end
    null_mean(s,:) = mean(tmp,1);
end

p = zeros(1,nBins);

for b = 1:nBins
    p(b) = (sum(null_mean(:,b) >= obs_mean(b)) + 1) / (nShuff + 1);
end

alph = 0.05;
sig_bins = find(p < alph);

scatter(sig_bins,repelem(99,size(sig_bins,2)),'k*')


p=[];
subplot(2,2,4);line(1:length(PointWiseAccuracyHMvsLMLR(1).testaccuracy),mean(reshape([PointWiseAccuracyHMvsLMLR.testaccuracy],length(PointWiseAccuracyHMvsLMLR(1).testaccuracy),[])'),'Color',[0.5 0 1])
hold on; line(1:length(PointWiseAccuracyHMvsLMLR(1).testaccuracy),mean(reshape([PointWiseAccuracyHMvsLMLR.meanshuffledaccuracy],length(PointWiseAccuracyHMvsLMLR(1).testaccuracy),[])'),'Color',[0.7 0.7 0.7])
x_vals = 1:length(PointWiseAccuracyHMvsLMLR(1).testaccuracy);

% Mean and SEM 
m = mean(reshape([PointWiseAccuracyHMvsLMLR.testaccuracy],length(PointWiseAccuracyHMvsLMLR(1).testaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyHMvsLMLR.testaccuracy],length(PointWiseAccuracyHMvsLMLR(1).testaccuracy),[])',1);   

% Patch coordinates
x_patch = [x_vals, fliplr(x_vals)];
y_patch = [m+s, fliplr(m-s)];
patch(x_patch, y_patch, [0.5 0 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
x_vals = 1:length(PointWiseAccuracyHMvsLMLR(1).meanshuffledaccuracy);

% Mean and SEM 
m = mean(reshape([PointWiseAccuracyHMvsLMLR.meanshuffledaccuracy],length(PointWiseAccuracyHMvsLMLR(1).meanshuffledaccuracy),[])',1);
s = nanste(reshape([PointWiseAccuracyHMvsLMLR.meanshuffledaccuracy],length(PointWiseAccuracyHMvsLMLR(1).meanshuffledaccuracy),[])',1);   

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

% Compute observed mean decoding curve
obs_mat = cell2mat(obs');           % nPseudo x nBins
obs_mean = mean(obs_mat,1);         % 1 x nBins
% Compute shuffled mean decoding curves
null_mean = zeros(nShuff,nBins);

for s = 1:nShuff
    tmp = zeros(nPseudo,nBins);
    for pRat = 1:nPseudo
        tmp(pRat,:) = null{pRat}(s,:);
    end
    null_mean(s,:) = mean(tmp,1);
end

%Compute corrected p-values
p = zeros(1,nBins);

for b = 1:nBins
    p(b) = (sum(null_mean(:,b) >= obs_mean(b)) + 1) / (nShuff + 1);
end

%Significant bins
alph = 0.05;
sig_bins = find(p < alph);

scatter(sig_bins,repelem(99,size(sig_bins,2)),'k*')

% 5e&g.
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
subsetb4shuffRDvsOM = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,beforeIdx),2), PointWiseAccuracyRDvsOMLI,'UniformOutput', false))';  
subsetafshuffRDvsOM = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,afterIdx),2), PointWiseAccuracyRDvsOMLI,'UniformOutput', false))';
pb4_RDvsOM=(sum(mean(subsetb4shuffRDvsOM,1) >= mean(RDvsOMwith(:,1)))+1)/(100+1);
paf_RDvsOM=(sum(mean(subsetafshuffRDvsOM,1) >= mean(RDvsOMwith(:,2)))+1)/(100+1);
correctedps_RDvsOM_with=[pb4_RDvsOM paf_RDvsOM];
% HM vs LM with video (shuff)
subsetb4shuffHMvsLM = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,beforeIdx),2), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)');
subsetafshuffHMvsLM = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,afterIdx),2), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)');
pb4_HMvsLM=(sum(mean(subsetb4shuffHMvsLM,1) >= mean(HMvsLMwith(:,1)))+1)/(100+1);
paf_HMvsLM=(sum(mean(subsetafshuffHMvsLM,1) >= mean(HMvsLMwith(:,2)))+1)/(100+1);
correctedps_HMvsLM_with=[pb4_HMvsLM paf_HMvsLM];



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
% RD vs OM without video (shuff)
subsetb4shuffRDvsOM = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,beforeIdx),2), PointWiseAccuracyRDvsOMLI,'UniformOutput', false))';  
subsetafshuffRDvsOM = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,afterIdx),2), PointWiseAccuracyRDvsOMLI,'UniformOutput', false))';
pb4_RDvsOM=(sum(mean(subsetb4shuffRDvsOM,1) >= mean(RDvsOMwout(:,1)))+1)/(100+1);
paf_RDvsOM=(sum(mean(subsetafshuffRDvsOM,1) >= mean(RDvsOMwout(:,2)))+1)/(100+1);
correctedps_RDvsOM_without=[pb4_RDvsOM paf_RDvsOM];
% HM vs LM without video (shuff)
subsetb4shuffHMvsLM = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,beforeIdx),2), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)');
subsetafshuffHMvsLM = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,afterIdx),2), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)');
pb4_HMvsLM=(sum(mean(subsetb4shuffHMvsLM,1) >= mean(HMvsLMwout(:,1)))+1)/(100+1);
paf_HMvsLM=(sum(mean(subsetafshuffHMvsLM,1) >= mean(HMvsLMwout(:,2)))+1)/(100+1);
correctedps_HMvsLM_without=[pb4_HMvsLM paf_HMvsLM];


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
%% Figure 6
% 6a.see 
% for g = 1:3
%     errorbar(g, gm(g), se(g), 'o', 'Color', colors(g,:), 'MarkerFaceColor', colors(g,:),  'MarkerSize', 4)
%     scatter(repmat(g, size(per_VAR{g}))+0.2, cellfun(@mean, perrds{g}), 10, colors(g,:), 'MarkerFaceAlpha', 0.6)
% end
%in section 1b&c. above.

% 6b&c. Repeated code for 2b&e. for each group, merged in inkscape.

% 6e.
groups={'SuperJazz','Grape','Melon'};
groupaccuracy=[];
sizegroup=[];
figure;
hold on;
offset = 0.1;
differenceforbp=[];
for group = 1:size(groups,2)
    load([groups{group} '_novideoneurons_SVM.mat'])
    [~, zeroIdx] = min(abs(binCentersLI - 0));
    zeroIdx = zeroIdx + 1;

    % Define before and after indices
    beforeIdx = zeroIdx-5 : zeroIdx-1;
    afterIdx  = zeroIdx   : zeroIdx+4;

    xBase = group;

    % RD vs OM real data
    subsetb4 = cell2mat(arrayfun(@(s) s.testaccuracy(beforeIdx), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)');
    subsetaf = cell2mat(arrayfun(@(s) s.testaccuracy(afterIdx), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)');

    % Store difference for plotting
    differenceforbp = [differenceforbp; mean(subsetaf,2) - mean(subsetb4,2), repelem(group, size(subsetb4,1),1)];

    % Shuffle data
    subsetb4shuff = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,beforeIdx),2), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)');  % 50 x 100
    subsetafshuff = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,afterIdx),2), PointWiseAccuracyRDvsOMLI,'UniformOutput', false)');   % 50 x 100

    % Keep per-iteration values for stats
    RDvsOMrel{group} = [mean(subsetb4,2), mean(subsetaf,2), repelem(group, size(subsetb4,1),1)];
    RDvsOMshuff{group} = [subsetb4shuff, subsetafshuff];

    % Monte Carlo p-values
    real_b4 = mean(RDvsOMrel{group}(:,1));       % scalar real mean before
    real_af = mean(RDvsOMrel{group}(:,2));       % scalar real mean after

    mean_shuff_b4 = mean(subsetb4shuff, 1);      % 1 x 100 mean across pseudo-rats for each shuffle
    mean_shuff_af = mean(subsetafshuff, 1);      % 1 x 100

    pb4_RDvsOM = (sum(mean_shuff_b4 >= real_b4) + 1) / (100 + 1);
    paf_RDvsOM = (sum(mean_shuff_af >= real_af) + 1) / (100 + 1);

    correctedps_RDvsOM{group} = [pb4_RDvsOM, paf_RDvsOM];

    % Store group data
    groupaccuracy = [groupaccuracy; RDvsOMrel{group}];
    sizegroup = [sizegroup, size(RDvsOMrel{group},1)];
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
for group = 1:size(groups,2)
    load([groups{group} '_novideoneurons_SVM.mat'])
    [~, zeroIdx] = min(abs(binCentersLI - 0));
    zeroIdx = zeroIdx + 1;

    % Define before and after indices
    beforeIdx = zeroIdx-5 : zeroIdx-1;
    afterIdx  = zeroIdx   : zeroIdx+4;

    xBase = group;

    % HM vs LM real data
    subsetb4 = cell2mat(arrayfun(@(s) s.testaccuracy(beforeIdx), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)');
    subsetaf = cell2mat(arrayfun(@(s) s.testaccuracy(afterIdx), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)');

    % Store difference for plotting
    differenceforbp = [differenceforbp; mean(subsetaf,2) - mean(subsetb4,2), repelem(group, size(subsetb4,1),1)];

    % Shuffle data
    subsetb4shuff = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,beforeIdx),2), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)');  % 50 x 100
    subsetafshuff = cell2mat(arrayfun(@(s) mean(s.totalshuffledaccuracy(:,afterIdx),2), PointWiseAccuracyHMvsLMLI,'UniformOutput', false)');   % 50 x 100

    % Keep per-iteration values for stats
    HMvsLMrel{group} = [mean(subsetb4,2), mean(subsetaf,2), repelem(group, size(subsetb4,1),1)];
    HMvsLMshuff{group} = [subsetb4shuff, subsetafshuff];

    % Monte Carlo p-values
    real_b4 = mean(HMvsLMrel{group}(:,1));       % scalar real mean before
    real_af = mean(HMvsLMrel{group}(:,2));       % scalar real mean after

    mean_shuff_b4 = mean(subsetb4shuff, 1);      % 1 x 100 mean across pseudo-rats for each shuffle
    mean_shuff_af = mean(subsetafshuff, 1);      % 1 x 100

    pb4_HMvsLM = (sum(mean_shuff_b4 >= real_b4) + 1) / (100 + 1);
    paf_HMvsLM = (sum(mean_shuff_af >= real_af) + 1) / (100 + 1);

    correctedps_HMvsLM{group} = [pb4_HMvsLM, paf_HMvsLM];

    % Store group data
    groupaccuracy = [groupaccuracy; HMvsLMrel{group}];
    sizegroup = [sizegroup, size(HMvsLMrel{group},1)];
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