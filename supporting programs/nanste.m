function  datste=nanste(dat,DM)
infelems=find(isinf(dat));
dat(infelems)=NaN;
datste=std(dat,1,DM,'omitnan')./sqrt(sum(~isnan(dat),DM));
%datste=nanstd(dat,[],DM)./sqrt(size(dat,DM));