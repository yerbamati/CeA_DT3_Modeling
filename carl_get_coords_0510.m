%%
cd('\\pbs-srv2.win.ad.jhu.edu\janaklabtest')
oldFolder = cd('Matilde');
cd('MatLab');
if exist('loadfile','var')
clear loadfile
end
loadfile=uigetfile('RAW*.mat');
load(loadfile);
%%
cd(oldFolder);
cd('Matilde/DT3-Matilde-2023-09-04/videos/')

% Carl's Directory
% cd('videos_and_coords/')
%%
timeidx=find(strcmp(RAW(1).Einfo(:,2),'SessionEnd'));
newvaridx1=length(RAW(1).Einfo)+1;
trialidx=find(strcmp(RAW(1).Einfo(:,2),'Trial-based LP Latency'));
for session = 1:length(RAW)
    % Make trial table
    trialTbl = table();
    LI = strcmp('LeverInsertion', RAW(session).Einfo(:,2));
    LItimes = RAW(session).Erast{LI};
    trialTbl.trialNo = (1:length(LItimes))';
    trialTbl.LeverInsertion = LItimes;
    eventNames = {'LeverPress1', 'LeverRetract', 'RewardDeliv'};
    for evt = 1:length(eventNames)
        evInd = strcmp(eventNames(evt),RAW(session).Einfo(:,2));
        evTimes = RAW(session).Erast{evInd};
        trialTbl.(eventNames{evt}) = NaN(length(LItimes),1);
        for trl = 1:length(LItimes)
            startTime = LItimes(trl);
            if trl < length(LItimes)
                endTime = LItimes(trl+1); end
            if trl == length(LItimes)
                endTime = LItimes(trl) + 60.1; end
            if sum(evTimes >= startTime & evTimes < endTime) == 1
                trialTbl.(eventNames{evt})(trl) = evTimes(evTimes >= startTime & evTimes < endTime);
            elseif sum(evTimes >= startTime & evTimes < endTime) == 2
                quindex = evTimes(evTimes > startTime & evTimes < endTime);
                trialTbl.(eventNames{evt})(trl-1) = quindex(1,:);
                trialTbl.(eventNames{evt})(trl) = quindex(2,:);
            end
         end
    end
    
    session_press_latency = RAW(session).Erast{trialidx-1,1};
    press_latency_quartile1 = prctile(session_press_latency,33);

    % Get Session-long Physical Parameters
    cutoff=0.95;
    bpcutoff = 0.5;
    tag = RAW(session).Einfo{1}(5:12);
    opts = detectImportOptions([tag 'DLC_resnet_50_DT3Sep4shuffle1_1030000.csv']);
    opts.SelectedVariableNames = 1:49; 
    curr_session = readmatrix([tag 'DLC_resnet_50_DT3Sep4shuffle1_1030000.csv'],opts);
    
    frames_DLC = curr_session(:,1); 
    all_coords_DLC=curr_session(:,5:6);
    rightbp_confidence = curr_session(:,40);
    leftbp_confidence = curr_session(:,43);

    coords_DLC = curr_session(logical([1;curr_session(2:end-1,7)>cutoff;1]),5:6);
    coords_rightear_DLC = curr_session(logical([1;curr_session(2:end-1,10)>cutoff;1]),8:9);
    coords_leftear_DLC = curr_session(logical([1;curr_session(2:end-1,13)>cutoff;1]),11:12);
    coords_midback_DLC = curr_session(logical([1;curr_session(2:end-1,16)>cutoff;1]),14:15);
    coords_baseoftail_DLC = curr_session(logical([1;curr_session(2:end-1,19)>cutoff;1]),17:18);

    percentkept(session,1)= (sum([1;curr_session(2:end,7)>cutoff])/length(curr_session))*100;
    percentkept(session,2)= (sum([1;curr_session(2:end,10)>cutoff])/length(curr_session))*100;
    percentkept(session,3)= (sum([1;curr_session(2:end,13)>cutoff])/length(curr_session))*100;
    percentkept(session,4)= (sum([1;curr_session(2:end,16)>cutoff])/length(curr_session))*100;
    percentkept(session,5)= (sum([1;curr_session(2:end,19)>cutoff])/length(curr_session))*100;
    trackedbodypartconf{session,1}=curr_session(:,7);
    trackedbodypartconf{session,2}=curr_session(:,10);
    trackedbodypartconf{session,3}=curr_session(:,13);
    trackedbodypartconf{session,4}=curr_session(:,16);
    trackedbodypartconf{session,5}=curr_session(:,19);
    
    %Mati's Directories
    ffpath='\\pbs-srv2.win.ad.jhu.edu\janaklabtest\Matilde\MatLab\Supporting Programs\bin';
    path2videos='\\pbs-srv2.win.ad.jhu.edu\janaklabtest\Matilde\DT3-Matilde-2023-09-04\videos\';

    %Carl's Directories
    % ffpath='/Users/Carl/Desktop/FR Video Labeling';
    % path2videos='/Users/Carl/Desktop/FR Video Labeling/';

    % ffpath = 'E:\ffmpeg\bin';
    % path2videos = 'E:\DT3_Data_Processing\videos_and_coords\';
    
    ts = videoframets(ffpath,[path2videos tag '.AVI']);
    time_DLC = ts(logical([1;curr_session(2:end-1,7)>cutoff;1]),:);
    time_rightear_DLC = ts(logical([1;curr_session(2:end-1,10)>cutoff;1]),:);
    time_leftear_DLC = ts(logical([1;curr_session(2:end-1,13)>cutoff;1]),:);
    time_midback_DLC = ts(logical([1;curr_session(2:end-1,16)>cutoff;1]),:);
    time_baseoftail_DLC = ts(logical([1;curr_session(2:end-1,19)>cutoff;1]),:);

    rightbp_ts_filtered = ts(rightbp_confidence > bpcutoff);
    leftbp_ts_filtered = ts(leftbp_confidence > bpcutoff);

    portleft(session,1)=mean(curr_session(curr_session(:,22)>.999,20));
    portleft(session,2)=mean(curr_session(curr_session(:,22)>.999,21));
    portright(session,1)=mean(curr_session(curr_session(:,25)>.999,23));
    portright(session,2)=mean(curr_session(curr_session(:,25)>.999,24));
    backleft(session,1)=mean(curr_session(curr_session(:,28)>.999,26));
    backleft(session,2)=mean(curr_session(curr_session(:,28)>.999,27));
    backright(session,1)=mean(curr_session(curr_session(:,31)>.999,29));
    backright(session,2)=mean(curr_session(curr_session(:,31)>.999,30));
    lever(session,1)=mean(curr_session(curr_session(:,34)>.999,32));
    lever(session,2)=mean(curr_session(curr_session(:,34)>.999,33));
    port(session,1)=mean(curr_session(curr_session(:,37)>.999,35));
    port(session,2)=mean(curr_session(curr_session(:,37)>.999,36));
    scatterx=[backright(:,1), backleft(:,1), portright(:,1), portleft(:,1),  lever(:,1)];
    scattery=[backright(:,2), backleft(:,2), portright(:,2), portleft(:,2),  lever(:,2)];

    % Testing confidence of backright
    percentkept_backright(session,1) = (nnz(curr_session(:,31)>.999))/length(curr_session)*100;

    time_plexon = (0:0.001:(RAW(session).Erast{timeidx}))';

    [~,ts_cutoff_id] = min(abs(ts-time_plexon(end)));

    % MCcommented out bc interfering with running of GRAPE group. CG made
    % adjustments 04/04/2025
    if ts_cutoff_id < length(ts)
        if ts(ts_cutoff_id) < time_plexon(end)
            ts_cutoff_id = ts_cutoff_id + 1;
        end
    end

    all_coords_plexon = interp1(ts(1:ts_cutoff_id),all_coords_DLC(1:ts_cutoff_id,:),time_plexon);
    coords_plexon = interp1(time_DLC,coords_DLC,time_plexon);
    coords_rightear_plexon = interp1(time_rightear_DLC,coords_rightear_DLC,time_plexon);
    coords_leftear_plexon = interp1(time_leftear_DLC,coords_leftear_DLC,time_plexon);
    coords_midback_plexon = interp1(time_midback_DLC,coords_midback_DLC,time_plexon);
    coords_baseoftail_plexon = interp1(time_baseoftail_DLC,coords_baseoftail_DLC,time_plexon);

    % Tracing Session-long Rat Movement
    % figure;
    % plot(coords_plexon(:,1),coords_plexon(:,2))
    % hold on;
    % scatter(scatterx,scattery)
    % title([RAW(session).Subject, RAW(session).Einfo{1}(10:12) ' session long trace']);
    % set(gca,'YDir','reverse')

    all_distance_squared = (diff(coords_plexon)).^2;
    all_distance = sqrt(all_distance_squared(:,1) + all_distance_squared(:,2));
    all_instvelocity = all_distance/0.001;
    all_instvelocity = [all_instvelocity;all_instvelocity(end)];

    all_lever_distance_squared = (coords_plexon - lever(session,:)).^2;
    all_lever_distance = sqrt(all_lever_distance_squared(:,1) + all_lever_distance_squared(:,2));
    all_ld_instvelocity = diff(all_lever_distance)/0.001;
    all_ld_instvelocity = [all_ld_instvelocity;all_ld_instvelocity(end)];

    session_anchor_coords = head_anchor(coords_leftear_plexon,coords_rightear_plexon,coords_plexon);
    session_anchor_headcap_vector = coords_plexon - session_anchor_coords;
    session_anchor_lever_vector = lever(session,:) - session_anchor_coords;
    session_angle_of_head = angle_btw_vectors(session_anchor_headcap_vector,session_anchor_lever_vector);

    
    time_model = (0:0.025:(RAW(session).Erast{timeidx}))';
    time_model_centers= (time_model(1:end-1) + time_model(2:end)) / 2;
    all_instvelocity_model = interp1(time_plexon,all_instvelocity,time_model_centers);
    all_lever_distance_model = interp1(time_plexon,all_lever_distance,time_model_centers);
    all_ld_instvelocity_model = interp1(time_plexon,all_ld_instvelocity,time_model_centers);
    all_positions_model= interp1(time_plexon,coords_plexon,time_model_centers);
    session_angle_of_head_model = interp1(time_plexon,session_angle_of_head,time_model_centers);
    
    % In case we want to normalize the distance from lever for the model
    % lever_backright_distance_square = (lever(session,:) - backright(session,:)).^2;
    % lever_backright_distance = sqrt(lever_backright_distance_square(1) + lever_backright_distance_square(2));
    % all_lever_distance_model_norm = all_lever_distance_model / lever_backright_distance;
    % all_lever_distance_model_norm(all_lever_distance_model_norm > 1) = 1;

    li_indices= NaN(length(trialTbl.LeverInsertion),1);
    for num_li = 1:length(trialTbl.LeverInsertion)
        index_of_li = find(round(time_plexon(:,1),3) == round(trialTbl.LeverInsertion(num_li),3));
        li_indices(num_li) = index_of_li;
    end
    
    lp1_indices = NaN(length(trialTbl.LeverPress1),1);
    for num_lp = 1:length(trialTbl.LeverPress1)
        if isnan(trialTbl.LeverPress1(num_lp))
            index_of_lp1 = NaN;
        else
            index_of_lp1 = find(round(time_plexon(:,1),3) == round(trialTbl.LeverPress1(num_lp),3));
        end
        lp1_indices(num_lp) = index_of_lp1;
    end

    lr_indices = NaN(length(trialTbl.LeverRetract),1);
    for num_lr = 1:length(trialTbl.LeverRetract)
        index_of_lr = find(round(time_plexon(:,1),3) == round(trialTbl.LeverRetract(num_lr),3));
        lr_indices(num_lr) = index_of_lr;
    end

    sessionlever_distance=[];
    sessiontotal_distance=[];
    instvelocity=[];
    lever_distance = [];
    instvelocity_idx = [];
    lever_distance_idx = [];
    distance_thusfar = NaN(6e4+100,length(trialTbl.trialNo));
    trial_logic_RD = NaN(length(trialTbl.trialNo),1);
    trial_logic_OM = NaN(length(trialTbl.trialNo),1);
    approach_behavior_genRD = [];
    approach_behavior_gen_leverRD = [];
    approach_behavior_gen_portRD = [];
    approach_behavior_genOM = [];
    approach_behavior_gen_leverOM = [];
    approach_behavior_gen_portOM = [];

    for trial = 1:length(trialTbl.trialNo)

        if sum(isnan(trialTbl{trial,:})) == 0
            RD = true;
        else
            RD = false;
        end

        if RD == true
            trial_coords = coords_plexon(li_indices(trial):lp1_indices(trial),:);
            trial_time= time_plexon(li_indices(trial):lp1_indices(trial),:);
            all_trial_coords= all_coords_plexon(li_indices(trial):lp1_indices(trial),:); 

            trial_coords2 = coords_plexon(li_indices(trial)-5000:lp1_indices(trial),:);
            trial_rightear_coords2 = coords_rightear_plexon(li_indices(trial)-5000:lp1_indices(trial),:);
            trial_leftear_coords2 = coords_leftear_plexon(li_indices(trial)-5000:lp1_indices(trial),:);
            trial_midback_coords2 = coords_midback_plexon(li_indices(trial)-5000:lp1_indices(trial),:);
            trial_baseoftail_coords2 = coords_baseoftail_plexon(li_indices(trial)-5000:lp1_indices(trial),:);
            trial_time2= time_plexon(li_indices(trial)-5000:lp1_indices(trial),:);

            trial_press_latency = RAW(session).Erast{trialidx,1}(trial);
            
            % Identifying anticipation trials
            if trial_press_latency < press_latency_quartile1
                trial_coords3 = coords_plexon(li_indices(trial)-15000:lp1_indices(trial),:);
                trial_leftear_coords3 = coords_leftear_plexon(li_indices(trial)-15000:lp1_indices(trial),:);
                trial_rightear_coords3= coords_rightear_plexon(li_indices(trial)-15000:lp1_indices(trial),:);
                trial_midback_coords3 = coords_midback_plexon(li_indices(trial)-15000:lp1_indices(trial),:);
                trial_baseoftail_coords3 = coords_baseoftail_plexon(li_indices(trial)-15000:lp1_indices(trial),:);
                trial_time3= time_plexon(li_indices(trial)-15000:lp1_indices(trial),:);

                dist_from_lever_squared_3 = (trial_coords3 - lever(session,:)).^2;
                dist_from_lever_3 = sqrt(dist_from_lever_squared_3(:,1) + dist_from_lever_squared_3(:,2));
                ld_instvelocity3 = diff(dist_from_lever_3)./0.001;
                ld_instvelocity_smooth3 = smoothdata(ld_instvelocity3,'movmean',2000);
                ld_instvelocity_over_time3 = [[ld_instvelocity_smooth3;ld_instvelocity_smooth3(end)] trial_time3];
                ld_instvelocity_indicator3 = logical([islocalmin(ld_instvelocity_smooth3,'MaxNumExtrema',5,'MinSeparation',1000);0]);
                ld_instvelocity_local_minimums3 = ld_instvelocity_over_time3(ld_instvelocity_indicator3,:);

                trial_anchor_coords3 = head_anchor(trial_leftear_coords3,trial_rightear_coords3,trial_coords3);
                anchor_headcap_vector3 = trial_coords3 - trial_anchor_coords3;
                anchor_lever_vector3 = lever(session,:) - trial_anchor_coords3;
                anchor_port_vector3 = port(session,:) - trial_anchor_coords3;
                angle_of_head3 = angle_btw_vectors(anchor_headcap_vector3,anchor_lever_vector3);
                angle_of_head_smooth3 = smoothdata(angle_of_head3,'movmean',500);
                angle_of_head_over_time3 = [angle_of_head_smooth3 trial_time3];
                angle_of_head_to_port3 = angle_btw_vectors(anchor_headcap_vector3,anchor_port_vector3);
                angle_of_head_to_port_smooth3 = smoothdata(angle_of_head_to_port3,'movmean',500);
                angle_of_head_to_port_over_time3 = [angle_of_head_to_port_smooth3 trial_time3];

                midback_baseoftail_vector3 = trial_baseoftail_coords3 - trial_midback_coords3;
                angle_of_head_to_body3 = angle_btw_vectors(anchor_headcap_vector3,midback_baseoftail_vector3);
                angle_of_head_to_body_smooth3 = smoothdata(angle_of_head_to_body3,'movmean',500);
                angle_of_head_to_body_over_time3 = [angle_of_head_to_body_smooth3 trial_time3];
                angle_of_head_to_body_indicator3 = islocalmin(angle_of_head_to_body_smooth3,'MinSeparation',1000);
                angle_of_head_to_body_local_minimums3 = angle_of_head_to_body_over_time3(angle_of_head_to_body_indicator3,:);
                angle_of_head_to_body_local_minimums3(angle_of_head_to_body_local_minimums3(:,1)>110,:) = [];

                angle_of_head_to_body_local_minimums_port3 = trough_elimination(angle_of_head_to_body_local_minimums3,angle_of_head_to_port_over_time3,trial_time3,ts,rightbp_confidence,leftbp_confidence,bpcutoff);
                if isempty(angle_of_head_to_body_local_minimums_port3)
                    angle_of_head_to_body_local_minimums_port3 = [0,0];
                end

                angle_of_head_to_body_local_minimums3 = trough_elimination(angle_of_head_to_body_local_minimums3,angle_of_head_over_time3,trial_time3,ts,rightbp_confidence,leftbp_confidence,bpcutoff);
                if isempty(angle_of_head_to_body_local_minimums3)
                    angle_of_head_to_body_local_minimums3 = [0,0];
                end
            end
            
            trial_logic_RD(trial) = 1;
            trial_logic_OM(trial) = 0;
            trial_RD_idx = sum(trial_logic_RD,'omitnan');

            alltrials.allsession{session,trial}=trial_coords(:,:);
            alltrials.RD{session,trial}=trial_coords(:,:);
            alltrials.timeinRD{session,trial}=length(all_trial_coords).*0.001;

        else
            trial_coords = coords_plexon(li_indices(trial):lr_indices(trial),:);
            trial_time= time_plexon(li_indices(trial):lr_indices(trial),:);
            all_trial_coords= all_coords_plexon(li_indices(trial):lr_indices(trial),:); 

            trial_coords2 = coords_plexon(li_indices(trial)-5000:lr_indices(trial),:);
            trial_rightear_coords2 = coords_rightear_plexon(li_indices(trial)-5000:lr_indices(trial),:);
            trial_leftear_coords2 = coords_leftear_plexon(li_indices(trial)-5000:lr_indices(trial),:);
            trial_midback_coords2 = coords_midback_plexon(li_indices(trial)-5000:lr_indices(trial),:);
            trial_baseoftail_coords2 = coords_baseoftail_plexon(li_indices(trial)-5000:lr_indices(trial),:);
            trial_time2= time_plexon(li_indices(trial)-5000:lr_indices(trial),:);

            trial_press_latency = 60;

            trial_logic_RD(trial) = 0;
            trial_logic_OM(trial) = 1;
            trial_OM_idx = sum(trial_logic_OM,'omitnan');

            alltrials.allsession{session,trial}=trial_coords(:,:);
            alltrials.OM{session,trial}=trial_coords(:,:);
            alltrials.timeinOM{session,trial}=length(all_trial_coords).*0.001;
        end
        
        [num_of_trial_coords,~] = size(trial_coords);
        instvel_trialcolumns(trial,1)= num_of_trial_coords-1;
        instvel_trialcolumns(trial,2)= 1;
        id1=find(instvelocity,1,'last')+1;
        if isempty(id1)
            id1=1;
        end
        lever_id1 = find(lever_distance,1,'last')+1;
        if isempty(lever_id1)
            lever_id1 = 1;
        end
        
        distance_squared = (diff(trial_coords)).^2;
        distance = sqrt(distance_squared(:,1) + distance_squared(:,2));
        trial_instvelocity = distance./0.001;
        instvelocity = [instvelocity; trial_instvelocity];
        total_distance = sum(distance);
        trial_thusfar = [0;cumsum(distance)];
        dist_from_lever_squared = (trial_coords - lever(session,:)).^2;
        dist_from_lever = sqrt(dist_from_lever_squared(:,1) + dist_from_lever_squared(:,2));
        ld_instvelocity = diff(dist_from_lever)./0.001;

        dist_from_lever_squared2 = (trial_coords2 - lever(session,:)).^2;
        dist_from_lever2 = sqrt(dist_from_lever_squared2(:,1) + dist_from_lever_squared2(:,2));
        ld_instvelocity2 = diff(dist_from_lever2)./0.001;

        sessiontotal_distance=[sessiontotal_distance;total_distance];
        sessionlever_distance=[sessionlever_distance;dist_from_lever(1)];
        distance_thusfar(1:length(trial_thusfar),trial) = trial_thusfar;
        lever_distance = [lever_distance;dist_from_lever];

        id2=find(instvelocity,1,'last');
        lever_id2 = find(lever_distance,1,'last');
        instvelocity_idx(trial,1)=id1;
        instvelocity_idx(trial,2)=id2;
        lever_distance_idx(trial,1) = lever_id1;
        lever_distance_idx(trial,2) = lever_id2;

        %Finding the angle of the head relative to the lever
        trial_anchor_coords2 = head_anchor(trial_leftear_coords2,trial_rightear_coords2,trial_coords2);

        anchor_headcap_vector2 = trial_coords2 - trial_anchor_coords2;
        anchor_lever_vector2 = lever(session,:) - trial_anchor_coords2;
        anchor_port_vector2 = port(session,:) - trial_anchor_coords2;

        angle_of_head2 = angle_btw_vectors(anchor_headcap_vector2,anchor_lever_vector2);
        angle_of_head_to_port2 = angle_btw_vectors(anchor_headcap_vector2,anchor_port_vector2);

        %Finding the angle of the head relative to the midback
        anchor_midback_vector2 = trial_midback_coords2 - trial_anchor_coords2;
        angle_of_head_to_midback2 = angle_btw_vectors(anchor_headcap_vector2,anchor_midback_vector2);

        %Finding the angle of the head relative to the body axis
        midback_baseoftail_vector2 = trial_baseoftail_coords2 - trial_midback_coords2;
        angle_of_head_to_body2 = angle_btw_vectors(anchor_headcap_vector2,midback_baseoftail_vector2);

        %Smoothing the data for further analysis
        instvelocity_smooth = smoothdata(trial_instvelocity,'movmean',2000);
        instvelocity_over_time = [[instvelocity_smooth;instvelocity_smooth(end)] trial_time];
        dist_from_lever_smooth = smoothdata(dist_from_lever,'movmean',500);
        dist_from_lever_over_time = [dist_from_lever_smooth trial_time];

        ld_instvelocity_smooth = smoothdata(ld_instvelocity,'movmean',2000);
        ld_instvelocity_over_time = [[ld_instvelocity_smooth;ld_instvelocity_smooth(end)] trial_time];
        ld_instvelocity_smooth2 = smoothdata(ld_instvelocity2,'movmean',2000);
        ld_instvelocity_over_time2 = [[ld_instvelocity_smooth2;ld_instvelocity_smooth2(end)] trial_time2];

        angle_of_head_smooth2 = smoothdata(angle_of_head2,'movmean',500);
        angle_of_head_over_time2 = [angle_of_head_smooth2 trial_time2];
        angle_of_head_to_port_smooth2 = smoothdata(angle_of_head_to_port2,'movmean',500);
        angle_of_head_to_port_over_time2 = [angle_of_head_to_port_smooth2 trial_time2];

        angle_of_head_to_midback_smooth2 = smoothdata(angle_of_head_to_midback2,'movmean',500);
        angle_of_head_to_midback_over_time2 = [angle_of_head_to_midback_smooth2 trial_time2];

        angle_of_head_to_body_smooth2 = smoothdata(angle_of_head_to_body2,'movmean',500);
        angle_of_head_to_body_over_time2 = [angle_of_head_to_body_smooth2 trial_time2];

            
        %Finding the local maximum/minimum of various parameters
        velocity_indicator = logical([islocalmax(instvelocity_smooth,'MaxNumExtrema',5,'Minseparation',1000);0]);
        dist_from_lever_indicator = islocalmax(dist_from_lever_smooth,'MaxNumExtrema',5,'Minseparation',1000);

        ld_instvelocity_indicator = logical([islocalmin(ld_instvelocity_smooth,'MaxNumExtrema',5,'MinSeparation',1000);0]);
        ld_instvelocity_indicator2 = logical([islocalmin(ld_instvelocity_smooth2,'MaxNumExtrema',5,'MinSeparation',1000);0]);

        angle_of_head_to_body_indicator2 = islocalmin(angle_of_head_to_body_smooth2,'MinSeparation',1000);

        instvelocity_local_maximums = instvelocity_over_time(velocity_indicator,:);
        dist_from_lever_local_maximums = dist_from_lever_over_time(dist_from_lever_indicator,:);

        ld_instvelocity_local_minimums = ld_instvelocity_over_time(ld_instvelocity_indicator,:);
        ld_instvelocity_local_minimums2 = ld_instvelocity_over_time2(ld_instvelocity_indicator2,:);

        angle_of_head_to_body_local_minimums2 = angle_of_head_to_body_over_time2(angle_of_head_to_body_indicator2,:);
        angle_of_head_to_body_local_minimums2(angle_of_head_to_body_local_minimums2(:,1)>110,:) = [];

        % Locating turns and scratches
        angle_of_head_to_body_local_minimums_port2 = trough_elimination(angle_of_head_to_body_local_minimums2,angle_of_head_to_port_over_time2,trial_time2,ts,rightbp_confidence,leftbp_confidence,bpcutoff);
        if isempty(angle_of_head_to_body_local_minimums_port2)
            angle_of_head_to_body_local_minimums_port2 = [0,0];
        end

        angle_of_head_to_body_local_minimums2 = trough_elimination(angle_of_head_to_body_local_minimums2,angle_of_head_over_time2,trial_time2,ts,rightbp_confidence,leftbp_confidence,bpcutoff);

        if isempty(angle_of_head_to_body_local_minimums2)
            angle_of_head_to_body_local_minimums2 = [0,0];
        end

        % Eliminating non-approach behavior using angle of heads
        final_press_window = 5.5;
        head_lever_elim_window = 1;
        head_port_elim_window = 1;
        head_body_elim_window = 5;
        head_body_trough_window = 2.5;
        exception_window = -0.5;
        head_lever_threshold = 90;
        head_port_threshold = 90;
        head_body_threshold = 90;
        ld_instvelocity_threshold = -7.5;
        trial_approach_gen_leverRD = [];
        trial_approach_gen_portRD = [];
        trial_approach_gen_leverOM = [];
        trial_approach_gen_portOM = [];

        if trial_press_latency < press_latency_quartile1 % Anticipatory Trial
            for peak = 1:size(ld_instvelocity_local_minimums3,1)
                candidate_timestamp = ld_instvelocity_local_minimums3(peak,2);
                lp1_latency = trial_time3(end) - candidate_timestamp;

                eval_window1_diff = angle_of_head_over_time3(:,2) - candidate_timestamp;
                eval_window1_indicator = logical((eval_window1_diff >= 0) + (eval_window1_diff <= head_lever_elim_window)-1);
                eval_window1 = angle_of_head_over_time3(eval_window1_indicator,1);
                head_lever_average = mean(eval_window1);

                eval_window1_port_diff = angle_of_head_to_port_over_time3(:,2) - candidate_timestamp;
                eval_window1_port_indicator = logical((eval_window1_port_diff >= 0) + (eval_window1_port_diff <= head_port_elim_window)-1);
                eval_window1_port = angle_of_head_to_port_over_time3(eval_window1_port_indicator,1);
                head_port_average = mean(eval_window1_port);

                if lp1_latency < 1
                    continue

                elseif (head_lever_average < head_port_average) && (head_lever_average < head_lever_threshold) % Approach Behavior for lever
                    if lp1_latency > final_press_window
                        eval_window2_diff = angle_of_head_to_body_over_time3(:,2) - candidate_timestamp;
                        eval_window2_indicator = logical((eval_window2_diff >= 0) + (eval_window2_diff <= head_body_elim_window)-1);
                        eval_window2 = angle_of_head_to_body_over_time3(eval_window2_indicator,1);
                        head_body_average = mean(eval_window2);
                        if head_body_average > head_body_threshold
                            head_body_trough_diff = angle_of_head_to_body_local_minimums3(:,2) - candidate_timestamp;
                            head_body_trough_indicator = (head_body_trough_diff >= 0) + (head_body_trough_diff <= head_body_trough_window)-1;
                            exception_indicator = (head_body_trough_diff < 0) + (head_body_trough_diff >= exception_window)-1;
                            if sum(head_body_trough_indicator) == 0
                                if sum(exception_indicator) == 0
                                    if ld_instvelocity_local_minimums3(peak,1) < ld_instvelocity_threshold
                                        approach_behavior_gen_leverRD = [approach_behavior_gen_leverRD;candidate_timestamp];
                                        trial_approach_gen_leverRD = [trial_approach_gen_leverRD; ld_instvelocity_local_minimums3(peak,:)];
                                        approach_behavior_genRD = [approach_behavior_genRD;candidate_timestamp];                                          
                                    end
                                end
                            end
                        end
                    else
                        head_body_trough_diff = angle_of_head_to_body_local_minimums3(:,2) - candidate_timestamp;
                        head_body_trough_indicator = (head_body_trough_diff >= 0) + (head_body_trough_diff <= head_body_trough_window)-1;
                        exception_indicator = (head_body_trough_diff < 0) + (head_body_trough_diff >= exception_window)-1;
                        if sum(head_body_trough_indicator) == 0
                            if sum(exception_indicator) == 0
                                if ld_instvelocity_local_minimums3(peak,1) < ld_instvelocity_threshold
                                    approach_behavior_gen_leverRD = [approach_behavior_gen_leverRD;candidate_timestamp];
                                    trial_approach_gen_leverRD = [trial_approach_gen_leverRD; ld_instvelocity_local_minimums3(peak,:)];
                                    approach_behavior_genRD = [approach_behavior_genRD;candidate_timestamp];                                    
                                end
                            end
                        end
                    end

                elseif head_port_average < head_port_threshold % Approach Behavior for port
                    if lp1_latency > final_press_window
                        eval_window2_diff = angle_of_head_to_body_over_time3(:,2) - candidate_timestamp;
                        eval_window2_indicator = logical((eval_window2_diff >= 0) + (eval_window2_diff <= head_body_elim_window)-1);
                        eval_window2 = angle_of_head_to_body_over_time3(eval_window2_indicator,1);
                        head_body_average = mean(eval_window2);
                        if head_body_average > head_body_threshold
                            head_body_trough_diff = angle_of_head_to_body_local_minimums_port3(:,2) - candidate_timestamp;
                            head_body_trough_indicator = (head_body_trough_diff >= 0) + (head_body_trough_diff <= head_body_trough_window)-1;
                            exception_indicator = (head_body_trough_diff < 0) + (head_body_trough_diff >= exception_window)-1;
                            if sum(head_body_trough_indicator) == 0
                                if sum(exception_indicator) == 0
                                    if ld_instvelocity_local_minimums3(peak,1) < ld_instvelocity_threshold
                                        approach_behavior_gen_portRD = [approach_behavior_gen_portRD;candidate_timestamp];
                                        trial_approach_gen_portRD = [trial_approach_gen_portRD; ld_instvelocity_local_minimums3(peak,:)];
                                        approach_behavior_genRD = [approach_behavior_genRD;candidate_timestamp];                                          
                                    end
                                end
                            end
                        end
                    else
                        head_body_trough_diff = angle_of_head_to_body_local_minimums_port3(:,2) - candidate_timestamp;
                        head_body_trough_indicator = (head_body_trough_diff >= 0) + (head_body_trough_diff <= head_body_trough_window)-1;
                        exception_indicator = (head_body_trough_diff < 0) + (head_body_trough_diff >= exception_window)-1;
                        if sum(head_body_trough_indicator) == 0
                            if sum(exception_indicator) == 0
                                if ld_instvelocity_local_minimums3(peak,1) < ld_instvelocity_threshold
                                    approach_behavior_gen_portRD = [approach_behavior_gen_portRD;candidate_timestamp];
                                    trial_approach_gen_portRD = [trial_approach_gen_portRD; ld_instvelocity_local_minimums3(peak,:)];
                                    approach_behavior_genRD = [approach_behavior_genRD;candidate_timestamp];                                   
                                end
                            end
                        end
                    end
                end
            end

        else % Non-anticipatory trials
            for peak = 1:size(ld_instvelocity_local_minimums2,1)
                candidate_timestamp = ld_instvelocity_local_minimums2(peak,2);
                lp1_latency = trial_time2(end) - candidate_timestamp;

                if RD == false
                    lp1_latency = 60;
                end

                eval_window1_diff = angle_of_head_over_time2(:,2) - candidate_timestamp;
                eval_window1_indicator = logical((eval_window1_diff >= 0) + (eval_window1_diff <= head_lever_elim_window)-1);
                eval_window1 = angle_of_head_over_time2(eval_window1_indicator,1);
                head_lever_average = mean(eval_window1);

                eval_window1_port_diff = angle_of_head_to_port_over_time2(:,2) - candidate_timestamp;
                eval_window1_port_indicator = logical((eval_window1_port_diff >= 0) + (eval_window1_port_diff <= head_port_elim_window)-1);
                eval_window1_port = angle_of_head_to_port_over_time2(eval_window1_port_indicator,1);
                head_port_average = mean(eval_window1_port);

                if lp1_latency < 1
                    continue

                elseif (head_lever_average <= head_port_average) && (head_lever_average < head_lever_threshold) % Approach Behavior for lever
                    if lp1_latency > final_press_window
                        eval_window2_diff = angle_of_head_to_body_over_time2(:,2) - candidate_timestamp;
                        eval_window2_indicator = logical((eval_window2_diff >= 0) + (eval_window2_diff <= head_body_elim_window)-1);
                        eval_window2 = angle_of_head_to_body_over_time2(eval_window2_indicator,1);
                        head_body_average = mean(eval_window2);
                        if head_body_average > head_body_threshold
                            head_body_trough_diff = angle_of_head_to_body_local_minimums2(:,2) - candidate_timestamp;
                            head_body_trough_indicator = (head_body_trough_diff >= 0) + (head_body_trough_diff <= head_body_trough_window)-1;
                            exception_indicator = (head_body_trough_diff < 0) + (head_body_trough_diff >= exception_window)-1;
                            if sum(head_body_trough_indicator) == 0
                                if sum(exception_indicator) == 0
                                    if ld_instvelocity_local_minimums2(peak,1) < ld_instvelocity_threshold
                                        if RD == true
                                            approach_behavior_gen_leverRD = [approach_behavior_gen_leverRD;candidate_timestamp];
                                            trial_approach_gen_leverRD = [trial_approach_gen_leverRD; ld_instvelocity_local_minimums2(peak,:)];
                                            approach_behavior_genRD = [approach_behavior_genRD;candidate_timestamp];
                                        else
                                            approach_behavior_gen_leverOM = [approach_behavior_gen_leverOM;candidate_timestamp];
                                            trial_approach_gen_leverOM = [trial_approach_gen_leverOM; ld_instvelocity_local_minimums2(peak,:)];
                                            approach_behavior_genOM = [approach_behavior_genOM;candidate_timestamp];
                                        end
                                    end
                                end
                            end
                        end
                    else
                        head_body_trough_diff = angle_of_head_to_body_local_minimums2(:,2) - candidate_timestamp;
                        head_body_trough_indicator = (head_body_trough_diff >= 0) + (head_body_trough_diff <= head_body_trough_window)-1;
                        exception_indicator = (head_body_trough_diff < 0) + (head_body_trough_diff >= exception_window)-1;
                        if sum(head_body_trough_indicator) == 0
                            if sum(exception_indicator) == 0
                                if ld_instvelocity_local_minimums2(peak,1) < ld_instvelocity_threshold
                                    approach_behavior_gen_leverRD = [approach_behavior_gen_leverRD;candidate_timestamp];
                                    trial_approach_gen_leverRD = [trial_approach_gen_leverRD; ld_instvelocity_local_minimums2(peak,:)];
                                    approach_behavior_genRD = [approach_behavior_genRD;candidate_timestamp];                                    
                                end
                            end
                        end
                    end

                elseif head_port_average < head_port_threshold % Approach Behavior for port
                    if lp1_latency > final_press_window
                        eval_window2_diff = angle_of_head_to_body_over_time2(:,2) - candidate_timestamp;
                        eval_window2_indicator = logical((eval_window2_diff >= 0) + (eval_window2_diff <= head_body_elim_window)-1);
                        eval_window2 = angle_of_head_to_body_over_time2(eval_window2_indicator,1);
                        head_body_average = mean(eval_window2);
                        if head_body_average > head_body_threshold
                            head_body_trough_diff = angle_of_head_to_body_local_minimums_port2(:,2) - candidate_timestamp;
                            head_body_trough_indicator = (head_body_trough_diff >= 0) + (head_body_trough_diff <= head_body_trough_window)-1;
                            exception_indicator = (head_body_trough_diff < 0) + (head_body_trough_diff >= exception_window)-1;
                            if sum(head_body_trough_indicator) == 0
                                if sum(exception_indicator) == 0
                                    if ld_instvelocity_local_minimums2(peak,1) < ld_instvelocity_threshold
                                        if RD == true
                                            approach_behavior_gen_portRD = [approach_behavior_gen_portRD;candidate_timestamp];
                                            trial_approach_gen_portRD = [trial_approach_gen_portRD; ld_instvelocity_local_minimums2(peak,:)];
                                            approach_behavior_genRD = [approach_behavior_genRD;candidate_timestamp];
                                        else
                                            approach_behavior_gen_portOM = [approach_behavior_gen_portOM;candidate_timestamp];
                                            trial_approach_gen_portOM = [trial_approach_gen_portOM; ld_instvelocity_local_minimums2(peak,:)];
                                            approach_behavior_genOM = [approach_behavior_genOM;candidate_timestamp];
                                        end
                                    end
                                end
                            end
                        end
                    else
                        head_body_trough_diff = angle_of_head_to_body_local_minimums_port2(:,2) - candidate_timestamp;
                        head_body_trough_indicator = (head_body_trough_diff >= 0) + (head_body_trough_diff <= head_body_trough_window)-1;
                        exception_indicator = (head_body_trough_diff < 0) + (head_body_trough_diff >= exception_window)-1;
                        if sum(head_body_trough_indicator) == 0
                            if sum(exception_indicator) == 0
                                if ld_instvelocity_local_minimums2(peak,1) < ld_instvelocity_threshold
                                    approach_behavior_gen_portRD = [approach_behavior_gen_portRD;candidate_timestamp];
                                    trial_approach_gen_portRD = [trial_approach_gen_portRD; ld_instvelocity_local_minimums2(peak,:)];
                                    approach_behavior_genRD = [approach_behavior_genRD;candidate_timestamp];                                      
                                end
                            end
                        end
                    end
                end
            end
        end

        if isempty(trial_approach_gen_leverRD)
            trial_approach_gen_leverRD = [NaN,NaN];
        end

        if isempty(trial_approach_gen_leverOM)
            trial_approach_gen_leverOM = [NaN,NaN];
        end

        if isempty(trial_approach_gen_portRD)
            trial_approach_gen_portRD = [NaN,NaN];
        end

        if isempty(trial_approach_gen_portOM)
            trial_approach_gen_portOM = [NaN,NaN];
        end
            
    %     %Graphing figures
    %     figure(trial)
    %     hold on
    % 
    %     yyaxis left
    %     xlabel('Time(s)')
    %     ylabel('Angle(degree)')
    %     yline(90)
    %     ylim([0,180])
    %     if trial_press_latency < press_latency_quartile1
    %         xlim([trial_time3(1),trial_time3(end)])
    %         title(['Trial ' num2str(trial) ' (RD' num2str(trial_RD_idx) ') Anticipatory'])
    %         plot(angle_of_head_over_time3(:,2),angle_of_head_over_time3(:,1),'-')
    %         plot(angle_of_head_to_body_over_time3(:,2), angle_of_head_to_body_over_time3(:,1),'--')
    %         plot(angle_of_head_to_port_over_time3(:,2), angle_of_head_to_port_over_time3(:,1),':',LineWidth=1)
    %         if angle_of_head_to_body_local_minimums3(1,2) > 0
    %             plot(angle_of_head_to_body_local_minimums3(:,2), angle_of_head_to_body_local_minimums3(:,1),'g*')
    %         end
    %     else
    %         xlim([trial_time2(1),trial_time2(end)])
    %         if RD == true
    %             title(['Trial ' num2str(trial) ' (RD' num2str(trial_RD_idx) ')'])
    %         else
    %             title(['Trial ' num2str(trial) ' (OM' num2str(trial_OM_idx) ')'])
    %         end
    %         plot(angle_of_head_over_time2(:,2),angle_of_head_over_time2(:,1),'-')
    %         plot(angle_of_head_to_body_over_time2(:,2), angle_of_head_to_body_over_time2(:,1),'--')
    %         plot(angle_of_head_to_port_over_time2(:,2), angle_of_head_to_port_over_time2(:,1),':',LineWidth=1)
    %         if angle_of_head_to_body_local_minimums2(1,2) > 0
    %             plot(angle_of_head_to_body_local_minimums2(:,2), angle_of_head_to_body_local_minimums2(:,1),'g*')
    %         end
    %     end
    %     xline(trial_time(1), 'r', 'LineWidth',0.55)
    %     plot(rightbp_ts_filtered,160*ones(size(rightbp_ts_filtered)),'r.')
    %     plot(leftbp_ts_filtered,170*ones(size(leftbp_ts_filtered)),'b.')
    % 
    % 
    %     yyaxis right
    %     ylabel('Lever Directed Instantaneous Velocity (pixel/s)')
    %     if trial_press_latency < press_latency_quartile1
    %         plot(ld_instvelocity_over_time3(:,2),ld_instvelocity_over_time3(:,1))
    %         plot(ld_instvelocity_local_minimums3(:,2),ld_instvelocity_local_minimums3(:,1),'mx')
    %     else
    %         plot(ld_instvelocity_over_time2(:,2),ld_instvelocity_over_time2(:,1))
    %         plot(ld_instvelocity_local_minimums2(:,2),ld_instvelocity_local_minimums2(:,1),'mx')
    %     end
    %     if RD == true     
    %         plot(trial_approach_gen_leverRD(:,2),trial_approach_gen_leverRD(:,1),'ksquare','MarkerSize',8)
    %         plot(trial_approach_gen_portRD(:,2),trial_approach_gen_portRD(:,1),'ko','MarkerSize',8)
    %     else
    %         plot(trial_approach_gen_leverOM(:,2),trial_approach_gen_leverOM(:,1),'ksquare','MarkerSize',8)
    %         plot(trial_approach_gen_portOM(:,2),trial_approach_gen_portOM(:,1),'ko','MarkerSize',8)            
    %     end
    %     hold off
    end
    
    trial_logic_RD = logical(trial_logic_RD);
    trial_logic_OM = logical(trial_logic_OM);

    % Finding First Approach Behavior Latency
    session_ts = trialTbl{:,[2,3,5]};
    session_latency = zeros(size(session_ts,1),1);
    for trial = 1:size(session_ts,1)
        if sum(isnan(session_ts(trial,:))) == 0
            RD_li = session_ts(trial,1);
            RD_lp = session_ts(trial,2);
            AB_trial_indicator = logical((approach_behavior_genRD - RD_li >= 0) + (RD_lp - approach_behavior_genRD >= 0) - 1);
            AB_trial = approach_behavior_genRD(AB_trial_indicator);
            if isempty(AB_trial)
                session_latency(trial) = RD_lp - RD_li;
            else
                session_latency(trial) = RD_lp - AB_trial(1);
            end
        else
            session_latency(trial) = NaN;
        end
    end

    AB_latency = session_latency;
    AB_latency(isnan(AB_latency)) = [];

    RAW(session).Erast{newvaridx1,1} = all_lever_distance_model;
    RAW(session).Erast{newvaridx1,2} = time_model_centers;
    RAW(session).Einfo{newvaridx1,1} = cellstr(RAW(session).Einfo{1,1});
    RAW(session).Einfo{newvaridx1,2} = 'SessionLeverDistance(Model)';

    RAW(session).Erast{newvaridx1+1,1} = all_instvelocity_model;
    RAW(session).Erast{newvaridx1+1,2} = time_model_centers;
    RAW(session).Einfo{newvaridx1+1,1} = cellstr(RAW(session).Einfo{1,1});
    RAW(session).Einfo{newvaridx1+1,2} = 'SessionInstvelocity(Model)';

    RAW(session).Erast{newvaridx1+2,1} = all_ld_instvelocity_model;
    RAW(session).Erast{newvaridx1+2,2} = time_model_centers;
    RAW(session).Einfo{newvaridx1+2,1} = cellstr(RAW(session).Einfo{1,1});
    RAW(session).Einfo{newvaridx1+2,2} = 'Sessionld_instvelocity(Model)';

    RAW(session).Erast{newvaridx1+3,1} = session_angle_of_head_model;
    RAW(session).Erast{newvaridx1+3,2} = time_model_centers;
    RAW(session).Einfo{newvaridx1+3,1} = cellstr(RAW(session).Einfo{1,1});
    RAW(session).Einfo{newvaridx1+3,2} = 'SessionAngleOfHeadToLever(Model)';

    RAW(session).Erast{newvaridx1+4,1} = all_positions_model;
    RAW(session).Erast{newvaridx1+4,2} = time_model_centers;
    RAW(session).Einfo{newvaridx1+4,1} = cellstr(RAW(session).Einfo{1,1});
    RAW(session).Einfo{newvaridx1+4,2} = 'All positions(Model)';

    RAW(session).Erast{newvaridx1+5,1} = sessionlever_distance;
    RAW(session).Einfo{newvaridx1+5,1} = cellstr(RAW(session).Einfo{1,1});
    RAW(session).Einfo{newvaridx1+5,2} = 'DistancefromLever';

    RAW(session).Erast{newvaridx1+6,1} = sessiontotal_distance;
    RAW(session).Einfo{newvaridx1+6,1} = cellstr(RAW(session).Einfo{1,1});
    RAW(session).Einfo{newvaridx1+6,2} = 'TotalDistanceTraveled';

    RAW(session).Erast{newvaridx1+7,1} = approach_behavior_genRD;
    RAW(session).Einfo{newvaridx1+7,1} = cellstr(RAW(session).Einfo{1,1});
    RAW(session).Einfo{newvaridx1+7,2} = 'GenApproachRD';

    RAW(session).Erast{newvaridx1+8,1} = approach_behavior_gen_leverRD;
    RAW(session).Einfo{newvaridx1+8,1} = cellstr(RAW(session).Einfo{1,1});
    RAW(session).Einfo{newvaridx1+8,2} = 'LeverApproachRD';

    RAW(session).Erast{newvaridx1+9,1} = approach_behavior_gen_portRD;
    RAW(session).Einfo{newvaridx1+9,1} = cellstr(RAW(session).Einfo{1,1});
    RAW(session).Einfo{newvaridx1+9,2} = 'PortApproachRD';

end

% Graphing Trajectories
% for session = 1:length(RAW)
%     coords_RD = [];
%     coords_OM = [];
%     traj_RD = [];
%     traj_OM = [];
%     for trial = 1:length(alltrials.allsession(session,:))
%         if isempty(alltrials.OM{session,trial})
%             trial_coords = alltrials.RD{session,trial};
%             trial_traj = diff(trial_coords);
%             trial_traj = [trial_traj;trial_traj(end,:)];
%             coords_RD = [coords_RD;trial_coords];
%             traj_RD = [traj_RD;trial_traj];
%         else
%             trial_coords = alltrials.OM{session,trial};
%             trial_traj = diff(trial_coords);
%             trial_traj = [trial_traj;trial_traj(end,:)];
%             coords_OM = [coords_OM;trial_coords];
%             traj_OM = [traj_OM;trial_traj];
%         end
%     end
% 
%     figure
%     title(RAW(1).Ninfo(:,1))
%     scatter(scatterx,scattery,'m',LineWidth = 1)
%     hold on
%     plot(coords_RD(:,1),coords_RD(:,2),'r')
%     plot(coords_OM(:,1),coords_OM(:,2),'b')
%     hold off
% 
%     % idx_RD = kmeans(traj_RD,2);
%     % coords_RD_cat1 = coords_RD(idx_RD == 1,:);
%     % coords_RD_cat2 = coords_RD(idx_RD == 2,:);
%     % % coords_RD_cat3 = coords_RD(idx_RD == 3,:);
%     % % coords_RD_cat4 = coords_RD(idx_RD == 4,:);
%     % % coords_RD_cat5 = coords_RD(idx_RD == 5,:);
%     % 
%     % figure
%     % scatter(scatterx,scattery,'m',LineWidth = 1)
%     % hold on
%     % plot(coords_RD_cat1(:,1),coords_RD_cat1(:,2))
%     % plot(coords_RD_cat2(:,1),coords_RD_cat2(:,2))
%     % % plot(coords_RD_cat3(:,1),coords_RD_cat3(:,2))
%     % % plot(coords_RD_cat4(:,1),coords_RD_cat4(:,2))
%     % % plot(coords_RD_cat5(:,1),coords_RD_cat5(:,2))
%     % hold off
% end
% abidx=strcmp('AB Latency',RAW(1).Einfo(:,2));
% abtrialidx=strcmp('Trial-based AB Latency',RAW(1).Einfo(:,2));
% metricidx=strcmp('Trial Behavioral Metric',RAW(1).Einfo(:,2));
% trialidx=strcmp('Trial Type',RAW(1).Einfo(:,2));
% globalab=[];
% scores=[];
% ratids=unique({RAW.Subject});
% for rat=1:length(ratids)
%     ablatency=[];
% 
%     for s=1:length(RAW)
%         if strcmp(cell2mat(ratids(rat)),RAW(s).Subject)==1
%             ablatency=[ablatency; RAW(s).Erast{abidx}];
%         end
%     end
%     for ses=find(strcmp(ratids(rat),{RAW.Subject}))
%         RAW(ses).Erast{metricidx,1}=mean([RAW(ses).Erast{abtrialidx,1}],2);
%         RAW(ses).Einfo{metricidx,2}='Trial Behavioral Metric';
% 
%     end
%     for s=find(strcmp(ratids(rat),{RAW.Subject}))
%         if strcmp(cell2mat(ratids(rat)),RAW(s).Subject)==1
%             scores=[scores;RAW(s).Erast{abidx,1}(~isnan(RAW(s).Erast{abidx,1}))];
%         end
%     end
%     mediancutoff=quantile(scores,0.5);
%     mediancutoffquarter=quantile(scores,0.25);
%     mediancutoffthreequarter=quantile(scores,0.75);
%     globalab=[globalab;scores];
%     for sss=find(strcmp(ratids(rat),{RAW.Subject}))
%         for trial=1:length(RAW(sss).Erast{abtrialidx})
% 
%             if RAW(sss).Erast{metricidx,1}(trial,1)<=mediancutoff
%                 RAW(sss).Erast{trialidx,1}{trial,1}='high';
%             elseif RAW(sss).Erast{metricidx,1}(trial,1)>mediancutoff
%                 RAW(sss).Erast{trialidx,1}{trial,1}='low';
%             else
%                 RAW(sss).Erast{trialidx,1}{trial,1}='omission';
%             end
%         end
%     end
% end
cd(oldFolder);
cd('Matilde\Matlab');
save(loadfile,'RAW')
avgkept=mean(percentkept);
lowestkept=min(percentkept);
highestkept=max(percentkept);
%% Approach Behavior Latency Analysis
AB_latency_stats = zeros(10,6);
for session = 1:10
    session_AB_latency = RAW(session).Erast{51,1};
    session_press_latency = RAW(session).Erast{trialidx-1,1};
    AB_latency_stats(session,1) = mean(session_AB_latency);
    AB_latency_stats(session,2) = median(session_AB_latency);
    AB_latency_stats(session,3) = std(session_AB_latency);
    AB_latency_stats(session,4) = min(session_AB_latency);
    AB_latency_stats(session,5) = max(session_AB_latency);
    AB_latency_stats(session,6) = mean(session_press_latency - session_AB_latency);
end
%% Functions:
%% Find angle by dot product
function angle = angle_btw_vectors(vector_a,vector_b)
a_b_dot_product = dot(vector_a,vector_b,2);
vector_a_size = sqrt(vector_a(:,1).^2 + vector_a(:,2).^2);
vector_b_size = sqrt(vector_b(:,1).^2 + vector_b(:,2).^2);
pre_angle = a_b_dot_product ./ (vector_a_size .* vector_b_size);
pre_angle(pre_angle < -1) = -1;
pre_angle(pre_angle > 1) = 1;
angle = acosd(pre_angle);
end

%% Find anchor coords from head triangle
function anchor_coords = head_anchor(left_ear_coords, right_ear_coords, headcap_coords)
rhs_squared = (right_ear_coords - headcap_coords).^2;
rightear_headcap_side = sqrt(rhs_squared(:,1) + rhs_squared(:,2));
lhs_squared = (left_ear_coords - headcap_coords).^2;
leftear_headcap_side = sqrt(lhs_squared(:,1) + lhs_squared(:,2));
base_squared = (right_ear_coords - left_ear_coords).^2;
base = sqrt(base_squared(:,1) + base_squared(:,2));

s = (rightear_headcap_side + leftear_headcap_side + base)./2;
area = sqrt(s.*(s-rightear_headcap_side).*(s-leftear_headcap_side).*(s-base)); %Heron's Formula
height = (2.*area)./base;
leftear_anchor_squared = leftear_headcap_side.^2 - height.^2;
leftear_anchor_squared(leftear_anchor_squared < 0) = NaN;
leftear_anchor_squared(isnan(leftear_anchor_squared)) = min(leftear_anchor_squared);
leftear_anchor_side = sqrt(leftear_anchor_squared);

base_vector = right_ear_coords - left_ear_coords;
base_unit_vector = base_vector ./ base;
leftear_anchor_vector = base_unit_vector .* leftear_anchor_side;
anchor_coords = left_ear_coords + leftear_anchor_vector;
end

%% Eliminate local minima of head body angle to isolate noisy turns from meaningful turns
function surviving_troughs = trough_elimination(initial_troughs,angle_of_head_over_time,trial_time,ts,rightbp_confidence,leftbp_confidence,bpcutoff)
trough_elim = ones(size(initial_troughs,1),1);
trough_elim_window_size = 1;
trough_turn_window_size = 2;
trough_turn_threshold = 90;
final_press_window = 5.5;

for trough = 1:size(initial_troughs,1)
    trough_ts = initial_troughs(trough,2);
    trough_turn_diff = angle_of_head_over_time(:,2) - trough_ts;
    trough_turn_indicator = logical((trough_turn_diff >= 0) + (trough_turn_diff <= trough_turn_window_size)-1);
    trough_turn_mean = mean(angle_of_head_over_time(trough_turn_indicator,1));
    if trough_turn_mean >= trough_turn_threshold
        trough_elim(trough) = 1;
    elseif (trial_time(end) - trough_ts) < final_press_window
        trough_elim(trough) = 0;
    else
        trough_elim_diff = ts - trough_ts;
        trough_elim_window1 = logical((trough_elim_diff >= 0) + (trough_elim_diff <= trough_elim_window_size)-1);
        trough_rightbp_window1 = rightbp_confidence(trough_elim_window1);
        trough_leftbp_window1 = leftbp_confidence(trough_elim_window1);
        if (mean(trough_rightbp_window1) < bpcutoff) && (mean(trough_leftbp_window1) < bpcutoff)
            % trough_elim_window2 = logical((trough_elim_diff <= 0) + (trough_elim_diff >= -trough_elim_window_size)-1);
            % trough_rightbp_window2 = rightbp_confidence(trough_elim_window2);
            % trough_leftbp_window2 = leftbp_confidence(trough_elim_window2);
            % if (mean(trough_rightbp_window2) < bpcutoff) && (mean(trough_leftbp_window2) < bpcutoff)
                trough_elim(trough) = 0;
            % end
        end
    end
end
surviving_troughs = initial_troughs(logical(trough_elim),:);
end

%% Archive
%% Archived Behavior Parameters and their calculations
% reward_velocity = [];
% noreward_velocity = [];
% session_velocity = [];
% rewardlever_distance=[];
% norewardlever_distance=[];
% rewardtotal_distance=[];
% norewardtotal_distance=[];
% reward_accel=[];
% noreward_accel=[];
% session_accel=[];
% rdidx=[];
% omidx=[];
% lever_rdidx = [];
% lever_omidx = [];

% Rewarded Trials:
% rewardtotal_distance=[rewardtotal_distance;total_distance];
% trial_velocity = total_distance/num_of_trial_coords;
% reward_velocity = [reward_velocity;trial_velocity];
% session_velocity = [session_velocity;trial_velocity];
% ratx= trial_coordsRD(1,1);
% raty= trial_coordsRD(1,2);
% trial_lvr_distance= sqrt((ratx-leverx(session))^2+(raty-levery(session))^2);
% rewardlever_distance=[rewardlever_distance;dist_from_lever_RD(1)];
% trial_accel=(instvelocity(id1)-instvelocity(id2))/num_of_trial_coords;
% reward_accel=[reward_accel;trial_accel];
% session_accel=[session_accel;trial_accel];

%Finding the angle of the head relative to the chamber
% backmiddle = (backleft(session,:) + backright(session,:)) ./2;
% portmiddle = (portleft(session,:) + portright(session,:)) ./2;
% rightmiddle = (backright(session,:) + portright(session,:)) ./2;
% leftmiddle = (backleft(session,:) + portleft(session,:)) ./2;
% curr_session_scatterx=[backright(session,1), backleft(session,1), portright(session,1), portleft(session,1),  lever(session,1)];
% curr_session_scattery=[backright(session,2), backleft(session,2), portright(session,2), portleft(session,2),  lever(session,2)];
% middles_scatterx = [backmiddle(1),portmiddle(1),rightmiddle(1),leftmiddle(1)];
% middles_scattery = [backmiddle(2),portmiddle(2),rightmiddle(2),leftmiddle(2)];
% 
% port_back_vector = backmiddle - portmiddle;
% port_back_length = sqrt(port_back_vector(1)^2 + port_back_vector(2)^2);
% port_back_unit_vector = port_back_vector / port_back_length;
% port_back_line = [(portmiddle(1):port_back_unit_vector(1)/100:backmiddle(1))', (portmiddle(2):port_back_unit_vector(2)/100:backmiddle(2))'];
% 
% right_left_vector = leftmiddle - rightmiddle;
% right_left_length = sqrt(right_left_vector(1)^2 + right_left_vector(2)^2);
% right_left_unit_vector = right_left_vector / right_left_length;
% right_left_line = [(rightmiddle(1):right_left_unit_vector(1)/100:leftmiddle(1))', (rightmiddle(2):right_left_unit_vector(2)/100:leftmiddle(2))'];
% 
% if length(port_back_line) > length(right_left_line)
%    port_back_line(length(right_left_line)+1:end,:) = [];
% elseif length(port_back_line) < length(right_left_line)
%    right_left_line(length(port_back_line)+1:end,:) = [];
% end
% 
% [midbox, idx_port_back, idx_right_left] = intersect(round(port_back_line,2), round(right_left_line,2), 'rows');
% if length(midbox(:,1)) > 1
%    midbox = mean(midbox);
% end
% 
% % figure()
% % hold on
% % plot(port_back_line(:,1),port_back_line(:,2))
% % plot(right_left_line(:,1),right_left_line(:,2))
% % plot(midbox(1), midbox(2), 'r.')
% % scatter(curr_session_scatterx,curr_session_scattery)
% % scatter(middles_scatterx,middles_scattery)
% % hold off
% 
% midbox_leftmiddle_vector = leftmiddle - midbox;
% midbox_backmiddle_vector = backmiddle - midbox;
% midbox_leftmiddle_size = sqrt(midbox_leftmiddle_vector(1)^2 + midbox_leftmiddle_vector(2)^2);
% midbox_backmiddle_size = sqrt(midbox_backmiddle_vector(1)^2 + midbox_backmiddle_vector(2)^2);
% 
% box_dimension_dot_product = midbox_leftmiddle_vector * (midbox_backmiddle_vector)';
% angle_between_box_vectors = acos(box_dimension_dot_product/(midbox_leftmiddle_size * midbox_backmiddle_size)) * 180/pi;
% 
% midbox_leftmiddle_matrix = repmat(midbox_leftmiddle_vector,length(anchor_headcap_vector),1);
% headcap_leftmiddle_dot_product = dot(anchor_headcap_vector,midbox_leftmiddle_matrix,2);
% angle_horizontal = acos(headcap_leftmiddle_dot_product ./ (ahv_size .* midbox_leftmiddle_size)) *180/pi;
% 
% midbox_backmiddle_matrix = repmat(midbox_backmiddle_vector,length(anchor_headcap_vector),1);
% headcap_backmiddle_dot_product = dot(anchor_headcap_vector,midbox_backmiddle_matrix,2);
% angle_vertical = acos(headcap_backmiddle_dot_product ./ (ahv_size .* midbox_backmiddle_size)) *180/pi;
% 
% chamber_indicator = angle_vertical > 90;
% angle_of_head_chamber = angle_horizontal;
% angle_of_head_chamber(chamber_indicator) = angle_of_head_chamber(chamber_indicator) * -1 + 360;

% angle_of_head_chamber_smooth = smoothdata(angle_of_head_chamber, 'movmean', 500);
% angle_of_head_chamber_over_time = [angle_of_head_chamber_smooth,trial_timeRD];

% Omitted Trials:
% norewardtotal_distance=[norewardtotal_distance;total_distance];
% trial_velocity = total_distance/num_of_trial_coords;
% noreward_velocity = [noreward_velocity;trial_velocity];
% session_velocity = [session_velocity;trial_velocity];
% ratx= trial_coordsOM(1,1);
% raty= trial_coordsOM(1,2);
% trial_lvr_distance= sqrt((ratx-leverx(session))^2+(raty-levery(session))^2);
% norewardlever_distance=[norewardlever_distance;dist_from_lever_OM(1)];

% trial_accel=(instvelocity(id1)-instvelocity(id2))/num_of_trial_coords;
% noreward_accel=[noreward_accel;trial_accel];
% session_accel=[session_accel;trial_accel];

%% Archived Approach Behavior Dist
% approach_behavior_dist = [];

%Finding Approach Behaviour Using dist_from_lever
% trial_approach_dist = [];
% if length(trial_timeRD) > 5000
%     [num_local_max,~] = size(dist_from_lever_local_maximums);
%     if num_local_max == 1
%         approach_timestamp = dist_from_lever_local_maximums(1,2);
%         diff_timestamp = abs(instvelocity_local_maximums(:,2) - approach_timestamp);
%         diff_evaluation = sum(diff_timestamp < 2);
%         if diff_evaluation >= 1
%             approach_behavior_dist = [approach_behavior_dist;approach_timestamp];
%             trial_approach_dist = dist_from_lever_local_maximums(1,:);
%         end
%     else
%         for peak = length(dist_from_lever_local_maximums):-1:1
%             approach_timestamp = dist_from_lever_local_maximums(peak,2);
%             diff_timestamp = abs(instvelocity_local_maximums(:,2) - approach_timestamp);
%             diff_evaluation = sum(diff_timestamp < 2);
%             if diff_evaluation >= 1
%                 approach_behavior_dist = [approach_behavior_dist;approach_timestamp];
%                 trial_approach_dist = dist_from_lever_local_maximums(peak,:);
%                 break
%             else
%                 continue
%             end
%         end
%     end
% else
%     approach_behavior_dist = [approach_behavior_dist;trial_timeRD(1)];
%     trial_approach_dist = [NaN, NaN];
% end
% %In case the trial is more than 5 seconds long, but no approach
% %behavior can be found
% if isempty(trial_approach_dist)
%     approach_behavior_dist = [approach_behavior_dist;NaN];
%     trial_approach_dist = [NaN, NaN];
% end

%% Archived Approach Behavior Inst
% approach_behavior_inst = [];

%Finding Approach Behaviour Using ld_instvelocity
% inst_major_peak = [NaN, NaN];
% inst_minor_peak = [NaN, NaN];
% [num_local_min,~] = size(ld_instvelocity_local_minimums);
% if length(trial_timeRD) > 5000
%     if num_local_min == 1
%         approach_behavior_inst = [approach_behavior_inst;[ld_instvelocity_local_minimums(end,2),ld_instvelocity_local_minimums(end,2)]];
%         inst_major_peak = ld_instvelocity_local_minimums(end,:);
%     elseif num_local_min == 0
%         approach_behavior_inst = [approach_behavior_inst;[trial_timeRD(1),trial_timeRD(1)]];
%     else
%         peak_diff = ld_instvelocity_local_minimums(end,1) - ld_instvelocity_local_minimums(end-1,1);
%         major_peak_threshold = 0.2 * abs(ld_instvelocity_local_minimums(end-1,1));
%         if peak_diff > major_peak_threshold
%             approach_behavior_inst = [approach_behavior_inst;[ld_instvelocity_local_minimums(end-1,2),ld_instvelocity_local_minimums(end,2)]];
%             inst_major_peak = ld_instvelocity_local_minimums(end-1,:);
%             inst_minor_peak = ld_instvelocity_local_minimums(end,:);
%         else
%             approach_behavior_inst = [approach_behavior_inst;[ld_instvelocity_local_minimums(end,2),ld_instvelocity_local_minimums(end,2)]];
%             inst_major_peak = ld_instvelocity_local_minimums(end,:);
%         end
%     end
% else
%     approach_behavior_inst = [approach_behavior_inst;[trial_timeRD(1),trial_timeRD(1)]];
% end

%% Archived Approach Behavior Turn
% approach_behavior_turn = [];

% interval = round(0.2*length(trial_timeRD));
% front_section = dist_from_lever_RD(1:end-interval);
% back_section = dist_from_lever_RD(interval+1:end);
% slope_of_dist = (back_section - front_section)./interval;

% slope_of_dist_smooth = smoothdata(slope_of_dist,'movmean',500);
% slope_of_dist_over_time = [slope_of_dist_smooth trial_timeRD(1:end-interval)];
% slope_of_dist_indicator = islocalmin(slope_of_dist_smooth,'MaxNumExtrema',5,'MinSeparation',1000);
% slope_of_dist_local_minimums = slope_of_dist_over_time(slope_of_dist_indicator,:);

%Finding large value head turns
% turn_time = round(0.15*length(trial_timeRD));
% turn_interval_a = angle_of_head_smooth(1:end-turn_time);
% turn_interval_b = angle_of_head_smooth(turn_time+1:end);
% turn_value = turn_interval_a - turn_interval_b;
% turn_value_wth_time = [turn_value trial_timeRD(turn_time+1:end)];
% 
% large_turn_ts_a = turn_value_wth_time(turn_interval_b < 45, :);
% 
% large_turn_indicator_b = large_turn_ts_a(:,1) > (median(abs(turn_value)) + std(abs(turn_value))*2);
% large_turn_ts_b = large_turn_ts_a(large_turn_indicator_b,:);
% 
% [num_large_turns,~] = size(large_turn_ts_b);
% large_turn_indicator_c = NaN(num_large_turns,1);
% 
% for turn_angle = 1:num_large_turns
%     turn_index = find(trial_timeRD == large_turn_ts_b(turn_angle,2));
%     large_turn_indicator_c(turn_angle) = turn_index;
% end
% 
% large_turn_ts_c = angle_of_head_over_time(large_turn_indicator_c,:);

%Finding Approach Behavior Using large head turns
% ld_indicator_turn = logical([islocalmin(ld_instvelocity_smooth,'MaxNumExtrema',2,'MinSeparation',1000);0]);
% ld_local_minimums_turn = ld_instvelocity_over_time(ld_indicator_turn,:);
% trial_approach_turn = [NaN,NaN];
% if length(trial_timeRD) > 5000
%     [num_local_min_turn,~] = size(ld_local_minimums_turn);
%     if num_local_min_turn == 1
%         approach_behavior_turn = [approach_behavior_turn;ld_local_minimums_turn(1,2)];
%         trial_approach_turn = ld_local_minimums_turn(1,:);
%     elseif num_local_min_turn == 0
%         approach_behavior_turn = [approach_behavior_turn;trial_timeRD(1)];
%     else
%         if isempty(large_turn_ts_b)
%             peak_diff_turn = ld_local_minimums_turn(2,1) - ld_local_minimums_turn(1,1);
%             major_peak_threshold_turn = 0.2 * abs(ld_local_minimums_turn(1,1));
%             if peak_diff_turn > major_peak_threshold_turn
%                 approach_behavior_turn = [approach_behavior_turn;ld_local_minimums_turn(1,2)];
%                 trial_approach_turn = ld_local_minimums_turn(1,:);
%             else
%                 approach_behavior_turn = [approach_behavior_turn;ld_local_minimums_turn(2,2)];
%                 trial_approach_turn = ld_local_minimums_turn(2,:);
%             end
%         else
%             large_turn_time = large_turn_ts_b(1,2);
%             large_turn_diff = abs(ld_local_minimums_turn(:,2) - large_turn_time);
%             [~,large_turn_diff_idx] = min(large_turn_diff);
%             approach_behavior_turn = [approach_behavior_turn;ld_local_minimums_turn(large_turn_diff_idx,2)];
%             trial_approach_turn = ld_local_minimums_turn(large_turn_diff_idx,:);
%         end
%     end
% else
%     approach_behavior_turn = [approach_behavior_turn;trial_timeRD(1)];
% end


%% Extracting & Using Manually labeled approach behaviors
% cd(oldFolder);
% cd('Matilde/Matlab/CarlMatLab');
% opts = detectImportOptions('AB_FR21to23.xlsx');
% opts.SelectedVariableNames = 1:38; 
% guided_approach_behavior_ts = readmatrix('AB_FR21to23.xlsx',opts);

%User determined Approach Behaviour
% guided_curr_trial_ts = guided_approach_behavior_ts(trial_RD_idx,session);
% guided_idx = find(round(ld_instvelocity_over_time(:,2),3) == round(guided_curr_trial_ts,3));
% trial_approach_guided = ld_instvelocity_over_time(guided_idx,:);

%% Archived Plotting Codes
% xline(trial_approach_guided(2),'k','LineWidth',0.55)

% ylabel('Instantaneous Velocity (pixel/s)')
% plot(instvelocity_over_time(:,2),instvelocity_over_time(:,1))
% plot(instvelocity_local_maximums(:,2),instvelocity_local_maximums(:,1),'ro')

% ylabel('Distance from Lever (pixel)')
% plot(dist_from_lever_over_time(:,2),dist_from_lever_over_time(:,1))
% plot(dist_from_lever_local_maximums(:,2),dist_from_lever_local_maximums(:,1),'g*')
% plot(trial_approach_dist(2),trial_approach_dist(1),'bsquare','Markersize',8)

% ylabel('Head Turn Rate (Degree/s)')
% plot(head_turn_rate_over_time(:,2),head_turn_rate_over_time(:,1))
% plot(head_turn_rate_local_minimums(:,2),head_turn_rate_local_minimums(:,1),'g*')

% ylabel('Angle of Head Relative to Chamber (Degree)')
% plot(angle_of_head_chamber_over_time(:,2),angle_of_head_chamber_over_time(:,1))

% ylabel('Angle of Head Relative to Lever (Degree)')
% plot(angle_of_head_local_minimums(:,2),angle_of_head_local_minimums(:,1),'g*')
% plot(large_turn_ts_c(:,2),large_turn_ts_c(:,1),'.m')

% ylabel('Angle of Head Relative to Midback (Degree)')
% plot(angle_of_head_to_midback_over_time2(:,2), angle_of_head_to_midback_over_time2(:,1))

% plot(inst_major_peak(2),inst_major_peak(1),'kdiamond','MarkerSize',8)
% plot(inst_minor_peak(2),inst_minor_peak(1),'rv','MarkerSize',8)
% plot(trial_approach_turn(2),trial_approach_turn(1),'bsquare','MarkerSize',8)
% plot(trial_approach_guided(2),trial_approach_guided(1),'k.','Markersize',15)


%% Finding Approach Behavior Error Relative to Manual Labeling
% alltrials.ApproachBehaviorDist{session,1} = approach_behavior_dist;
% alltrials.ApproachBehaviorInst{session,1} = approach_behavior_inst;
% alltrials.ApproachBehaviorTurn{session,1} = approach_behavior_turn;

% alltrials.DistError{session,1} = dist_approximation_error;
% alltrials.DistError{session,2} = dist_error_raw;
% alltrials.InstError{session,1} = inst_approximation_error;
% alltrials.InstError{session,2} = inst_error_raw;
% alltrials.TurnError{session,1} = turn_approximation_error;
% alltrials.TurnError{session,2} = turn_error_raw;

% alltrials.MeanDistError{session,1} = mean_dist_error;
% alltrials.MeanDistError{session,2} = mean_dist_raw;
% alltrials.MeanInstError{session,1} = mean_inst_error;
% alltrials.MeanInstError{session,2} = mean_inst_raw;
% alltrials.MeanTurnError{session,1} = mean_turn_error;
% alltrials.MeanTurnError{session,2} = mean_turn_raw;

% total_dist_error = 0;
% total_major_error = 0;
% total_minor_error = 0;
% total_turn_error = 0;
% 
% total_num_inst = 0;
% total_num_dist = 0;
% total_num_turn = 0;
% 
% first_session = 31
% last_session = 38
% num_of_sessions = last_session-first_session+1;
% for ab_session = first_session:last_session
%     dist_error_nanfree = alltrials.DistError{ab_session,1};
%     dist_error_nanfree(isnan(dist_error_nanfree)) = [];
% 
%     total_major_error = total_major_error + sum(alltrials.InstError{ab_session,1}(:,1));
%     total_minor_error = total_minor_error + sum(alltrials.InstError{ab_session,1}(:,2));
%     total_dist_error = total_dist_error + sum(dist_error_nanfree);
%     total_turn_error = total_turn_error + sum(alltrials.TurnError{ab_session,1});
% 
%     total_num_inst = total_num_inst + length(alltrials.InstError{ab_session,1}(:,1));
%     total_num_dist = total_num_dist + length(dist_error_nanfree);
%     total_num_turn = total_num_turn + length(alltrials.TurnError{ab_session,1});
% end
% overall_mean_major_error = total_major_error/total_num_inst;
% overall_mean_minor_error = total_minor_error/total_num_inst;
% overall_mean_dist_error = total_dist_error/total_num_dist;
% overall_mean_turn_error = total_turn_error/total_num_turn;
% 
% every_mean_inst_error = cell2mat(alltrials.MeanInstError);
% graph_mean_inst_error = every_mean_inst_error(1:num_of_sessions,1:2);
% graph_mean_dist_error = cell2mat(alltrials.MeanDistError(first_session:last_session,1));
% graph_mean_turn_error = cell2mat(alltrials.MeanTurnError(first_session:last_session,1));
% 
% figure()
% hold on
% title(['Mean Approximation Error Over ' num2str(num_of_sessions) ' Sessions'])
% bar(1:num_of_sessions,[(graph_mean_turn_error)';(graph_mean_inst_error)'])
% legend('Mean Turn Approximation Error','Mean Inst Approximation Error(Major)','Mean Inst Approximation Error(Minor)')
% hold off
% 
% graph_mean_inst_raw = every_mean_inst_error(1:num_of_sessions,3:4);
% graph_mean_dist_raw = cell2mat(alltrials.MeanDistError(first_session:last_session,2));
% graph_mean_turn_raw = cell2mat(alltrials.MeanTurnError(first_session:last_session,2));
% 
% figure()
% hold on
% title(['Mean Approximation Error (Raw) Over ' num2str(num_of_sessions) ' Sessions'])
% bar(1:num_of_sessions,[(graph_mean_turn_raw)';(graph_mean_inst_raw)'])
% legend('Mean Turn Approximation Error','Mean Inst Approximation Error(Major)','Mean Inst Approximation Error(Minor)')
% hold off

% Session-wide approach behavior errors
% curr_session_guided_ab_ts = guided_approach_behavior_ts(:,session);
% curr_session_guided_ab_ts(isnan(curr_session_guided_ab_ts)) = [];
% 
% dist_approximation_error = abs(approach_behavior_dist - curr_session_guided_ab_ts);
% inst_approximation_error = abs(approach_behavior_inst - curr_session_guided_ab_ts);
% turn_approximation_error = abs(approach_behavior_turn - curr_session_guided_ab_ts);
% 
% mean_dist_error = mean(dist_approximation_error,'omitnan');
% mean_inst_error = mean(inst_approximation_error);
% mean_turn_error = mean(turn_approximation_error);
% 
% dist_error_raw = approach_behavior_dist - curr_session_guided_ab_ts;
% inst_error_raw = approach_behavior_inst - curr_session_guided_ab_ts;
% turn_error_raw = approach_behavior_turn - curr_session_guided_ab_ts;
% 
% mean_dist_raw = mean(dist_error_raw,'omitnan');
% mean_inst_raw = mean(inst_error_raw);
% mean_turn_raw = mean(turn_error_raw);

% figure()
% hold on
% title(['Approximation Error ' tag])
% bar(1:sum(trial_logic_RD),[(turn_approximation_error)';(inst_approximation_error)'])
% legend('Turn Approximation Error','Inst Approximation Error(Major)','Inst Approximation Error(Minor)')
% %ylim([0,12])
% hold off

%% Archived RAW Updates
% RAW(session).Erast{38,1} = all_lever_distance_model_norm;
% RAW(session).Einfo{38,1} = cellstr(RAW(session).Einfo{1,1});
% RAW(session).Einfo{38,2} = 'SessionLeverDistanceNorm(Model)';

% RAW(session).Erast{43,1} = session_velocity;
% RAW(session).Einfo{43,1} = cellstr(RAW(session).Einfo{1,1});
% RAW(session).Einfo{43,2} = 'Velocity';

% RAW(session).Erast{44,1} = reward_velocity;
% RAW(session).Einfo{44,1} = RAW(session).Einfo{1,1};
% RAW(session).Einfo{44,2} = 'VelocityRD';

% RAW(session).Erast{45,1} = noreward_velocity;
% RAW(session).Einfo{45,1} = RAW(session).Einfo{1,1};
% RAW(session).Einfo{45,2} = 'VelocityNoRD';

% RAW(session).Erast{46,1}=session_velocity(strcmp(RAW(session).Erast{42,1},'high'));
% RAW(session).Einfo{46,1}=RAW(session).Einfo{1,1};
% RAW(session).Einfo{46,2}='VelocityHighMotivation';

% RAW(session).Erast{47,1}=session_velocity(strcmp(RAW(session).Erast{42,1},'low'));
% RAW(session).Einfo{47,1}=RAW(session).Einfo{1,1};
% RAW(session).Einfo{47,2}='VelocityLowMotivation';

% RAW(session).Erast{49,1} = rewardlever_distance;
% RAW(session).Einfo{49,1} = RAW(session).Einfo{1,1};
% RAW(session).Einfo{49,2} = 'DistancefromLeverRD';

% RAW(session).Erast{50,1} = norewardlever_distance;
% RAW(session).Einfo{50,1} = RAW(session).Einfo{1,1};
% RAW(session).Einfo{50,2} = 'DistancefromLeverNoRD';

% RAW(session).Erast{40,1} = sessionlever_distance(strcmp(RAW(session).Erast{42,1},'high'));
% RAW(session).Einfo{40,1} = RAW(session).Einfo{1,1};
% RAW(session).Einfo{40,2} = 'DistancefromLeverHighMotivation';

% RAW(session).Erast{41,1} = sessionlever_distance(strcmp(RAW(session).Erast{42,1},'low'));
% RAW(session).Einfo{41,1} = RAW(session).Einfo{1,1};
% RAW(session).Einfo{41,2} = 'DistancefromLeverLowMotivation';

% RAW(session).Erast{54,1} = rewardtotal_distance;
% RAW(session).Einfo{54,1} = RAW(session).Einfo{1,1};
% RAW(session).Einfo{54,2} = 'TotalDistanceTraveledRD';

% RAW(session).Erast{55,1} = norewardtotal_distance;
% RAW(session).Einfo{55,1} = RAW(session).Einfo{1,1};
% RAW(session).Einfo{55,2} = 'TotalDistanceTravelednoRD';

% RAW(session).Erast{43,1} = sessiontotal_distance(strcmp(RAW(session).Erast{42,1},'high'));
% RAW(session).Einfo{43,1} = RAW(session).Einfo{1,1};
% RAW(session).Einfo{43,2} = 'TotalDistanceTraveledHM';

% RAW(session).Erast{44,1} = sessiontotal_distance(strcmp(RAW(session).Erast{42,1},'low'));
% RAW(session).Einfo{44,1} = RAW(session).Einfo{1,1};
% RAW(session).Einfo{44,2} = 'TotalDistanceTraveledLM';

% RAW(session).Erast{41,1} = approach_behavior_dist;
% RAW(session).Einfo{41,1} = RAW(session).Einfo{1,1};
% RAW(session).Einfo{41,2} = 'ApproachBehaviorDist';

% RAW(session).Erast{42,1} = approach_behavior_inst;
% RAW(session).Einfo{42,1} = RAW(session).Einfo{1,1};
% RAW(session).Einfo{42,2} = 'ApproachBehaviorInst';

%% Matilde Code 1 (In Session Loop)
% xlineplaces=[cumsum(instvel_trialcolumns(:,1)),instvel_trialcolumns(:,2)];
% if xlineplaces(1,2)==1
%     initialpatch=1;
% elseif xlineplaces(1,2)==0
%     initialpatch=0;
% end
% if xlineplaces(end,2)==1
%     finalpatch=1;
% elseif xlineplaces(end,2)==0
%     finalpatch=0;
% end
% transitions=diff(xlineplaces(:,2));
% patchcoordinatesmaster=[[0 initialpatch];xlineplaces(find(transitions==-1|transitions==1)+1,:);[xlineplaces(end,1) finalpatch]];
% ompatchxs=[];
% rdpatchxs=[];
% for transit=2:length(patchcoordinatesmaster)
%     if patchcoordinatesmaster(transit-1,2)==0
%         ompatchxs=[ompatchxs;patchcoordinatesmaster(transit,1)-1];
%     elseif patchcoordinatesmaster(transit-1,2)==1
%         rdpatchxs=[rdpatchxs;patchcoordinatesmaster(transit,1)-1];
%     end
% end
% if initialpatch==1
%     rdpatchxs=[0;rdpatchxs];
% elseif initialpatch==2
%     ompatchxs=[0;ompatchxs];
% end
% rdpatchxsexpanded=[repelem(rdpatchxs,2)];
% rdpatchxreshaped=reshape(rdpatchxsexpanded,4,length(rdpatchxsexpanded)/4)
% rdys=repmat([0;0.2;0.2;0],1,size(rdpatchxreshaped,2));
% ompatchxsexpanded=[repelem(ompatchxs,2)];
% ompatchxreshaped=reshape(ompatchxsexpanded,4,length(ompatchxsexpanded)/4)
% omys=repmat([0;0.2;0.2;0],1,size(ompatchxreshaped,2));
% patchxsexpanded=[repelem(patchcoordinatesmaster(1,1),2)';repelem(patchcoordinatesmaster(2:end-1,1),4);repelem(patchcoordinatesmaster(end,1),2)'];
% patchxreshaped=reshape(patchxsexpanded,4,length(patchxsexpanded)/4);
% ys=repmat([0;0.2;0.2;0],1,size(patchxreshaped,2));
% for transit=2:length(patchcoordinatesmaster)
%     if patchcoordinatesmaster(transit-1,2)==1
%         patchxreshaped(5,transit-1)=1;
%     elseif patchcoordinatesmaster(transit-1,2)==0
%         patchxreshaped(5,transit-1)=0;
%     end
% end

% figure;hold on;
% patch(patchxreshaped(1:4,patchxreshaped(5,:)==1),ys(:,patchxreshaped(5,:)==1),'g','FaceAlpha',0.2,'EdgeColor','none');
% patch(patchxreshaped(1:4,patchxreshaped(5,:)==0),ys(:,patchxreshaped(5,:)==0),'k','FaceAlpha',0.2,'EdgeColor','none');
% plot(smoothdata(instvelocity,'movmean',5000))
% xline(xlineplaces(:,1))
% xlim([0 max(xlineplaces(:,1))])

%% Matilde Code 2
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

[prd,hyprd,statsrd]=signrank(data_rd,data_om);
[phvl,hyphvl,statsvl]=signrank(data_hm,data_lm);
fprintf('%s:\n', behaviors{behavior-1});
fprintf('   RD vs OM: p = %.2e W: %.2e\n', prd,statsrd.signedrank);
fprintf('   HM vs LM: p = %.2e W: %.2e\n\n', phvl,statsvl.signedrank);
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
    pStr = sprintf('p=%.2e\nW %.2e', prd,statsrd.signedrank);  % use scientific notation

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
    pStr = sprintf('p=%.2e\nW %.2e', phvl,statsvl.signedrank);  % use scientific notation

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
[prd,hyprd,statsrd]=signrank(data_rd,data_om);
[phvl,hyphvl,statsvl]=signrank(data_hm,data_lm);
fprintf('%s:\n', behaviors{behavior-1});
fprintf('   RD vs OM: p = %.2e W: %.2e\n', prd,statsrd.signedrank);
fprintf('   HM vs LM: p = %.2e W: %.2e\n\n', phvl,statsvl.signedrank);
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
    pStr = sprintf('p=%.2e\nW %.2e', prd,statsrd.signedrank);  % use scientific notation

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
    pStr = sprintf('p=%.2e\nW %.2e', phvl,statsvl.signedrank);  % use scientific notation

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

%LME to compare groups
seekvsabstain=allgroups_vidbehav;
seekvsabstain(ismember(seekvsabstain(:,1),{'low','high'}))={'seek'};
TrialType=categorical(seekvsabstain(:,1));
Angle=cell2mat(seekvsabstain(:,2));
ITIVel=cell2mat(seekvsabstain(:,3));
Distance=cell2mat(seekvsabstain(:,4));
ratID=categorical(seekvsabstain(:,5));
group=categorical(seekvsabstain(:,6));
tbl2use=table(TrialType,Angle,ITIVel,Distance,ratID,group);
variables = {'ITIVel','Distance','Angle'}; % replace with your table column names

lme_models_seekvsabstain = cell(length(variables),1); % store models

for v = 1:length(variables)
    % formula: Variable ~ TrialType*Group + (1|RatID)
    formula = sprintf('%s ~ TrialType*group + (1|ratID)', variables{v});
    
    % fit the linear mixed-effects model
    lme_models_seekvsabstain{v} = fitlme(tbl2use, formula);
    
    % Display summary
    disp(['--- LME for ', variables{v}, ' (Seek vs Abstain) ---']);
    disp(lme_models_seekvsabstain{v});
end

fastvsslow=allgroups_vidbehav;
fastvsslow(ismember(fastvsslow(:,1),{'omission'}),:)=[];
TrialType=categorical(fastvsslow(:,1));
Angle=cell2mat(fastvsslow(:,2));
ITIVel=cell2mat(fastvsslow(:,3));
Distance=cell2mat(fastvsslow(:,4));
ratID=categorical(fastvsslow(:,5));
group=categorical(fastvsslow(:,6));
tbl2use=table(TrialType,Angle,ITIVel,Distance,ratID,group);
variables = {'ITIVel','Distance','Angle'}; % replace with your table column names

lme_models_fastvsslow = cell(length(variables),1); % store models

for v = 1:length(variables)
    % formula: Variable ~ TrialType*Group + (1|RatID)
    formula = sprintf('%s ~ TrialType*group + (1|ratID)', variables{v});
    
    % fit the linear mixed-effects model
    lme_models_fastvsslow{v} = fitlme(tbl2use, formula);
    
    % Display summary
    disp(['--- LME for ', variables{v}, ' (Fast vs Slow) ---']);
    disp(lme_models_fastvsslow{v});
end

%% Matilde Code 3 Spatial Density
% set center point
Xc=0;Yc=250;
%get animal coordinates for a session and remake into a num frames x 2
%array
trialtags={'All';'Rewarded';'Omitted'};
structnames=fieldnames(alltrials);
structnames=structnames([1,2,4]);
greenmap=[];counter=1;
session=2;
for idx=0:0.0001:1
greenmap(counter,:)=[0 idx 0];
counter=counter+1;
end
blackwhitemap=[];counter=1;
for idx=0:0.001:1
blackwhitemap(counter,:)=[idx idx idx];
counter=counter+1;
end
hot=colormap('hot');
cms={hot,greenmap,blackwhitemap};
for ttype=1:length(structnames)
coords=[];
shiftedcoords=[];
Xrotcoords=[];
Yrotcoords=[];
Xrotcorners=[];
Yrotcorners=[];
discretizedtransfcoordsx=[];
discretizedtransfcoordsy=[];
discretizedcoords=[];
ind= [];
accumulatedelements=[];
distributionmatrix=[];
for t=1:size(alltrials.(structnames{ttype}),2)
    coords=[coords;alltrials.(structnames{ttype}){session,t}];
end
%move all coordinates by Xc and Yc to translate them to new X,Y coordiantes
shiftedcoords=[coords(:,1)-(scatterx(session,3)-Xc) coords(:,2)-(scattery(session,3)-Yc)];
%make boxcorner anchor points array and loose variables
boxcornerX=scatterx(session,:)-(scatterx(session,3)-Xc);
boxcornerY=scattery(session,:)-(scattery(session,3)-Yc);
portleftxtemp=boxcornerX(4);
portleftytemp=boxcornerY(4);
portrightxtemp=boxcornerX(3);
portrightytemp=boxcornerY(3);
backleftxtemp=boxcornerX(2);
backleftytemp=boxcornerY(2);
backrightxtemp=boxcornerX(1);
backrightytemp=boxcornerY(1);
leverxtemp=boxcornerX(5);
leverytemp=boxcornerY(5);
%calculate angle based on line created between port left corner and port
%right corner and the origin 
angle=atand((portleftytemp-portrightytemp)/(portleftxtemp-portrightxtemp));
%Shift and rotate coordiantes
Xrotcoords=(shiftedcoords(:,1)-Xc)*cosd(angle)+(shiftedcoords(:,2)-Yc)*sind(angle)+Xc;
Yrotcoords=-(shiftedcoords(:,1)-Xc)*sind(angle)+(shiftedcoords(:,2)-Yc)*cosd(angle)+Yc;
Xrotcorners=(boxcornerX-Xc)*cosd(angle)+(boxcornerY-Yc)*sind(angle)+Xc;
Yrotcorners=-(boxcornerX-Xc)*sind(angle)+(boxcornerY-Yc)*cosd(angle)+Yc;
portrightxrot=Xrotcorners(3);
portleftxrot=Xrotcorners(4);
backleftyrot=Yrotcorners(2);
portleftyrot=Yrotcorners(4);
leverxrot=Xrotcorners(5);
leveryrot=Yrotcorners(5);
% figure;
% plot(Xrotcoords,Yrotcoords)
% hold on;
% scatter(Xrotcorners,Yrotcorners)
% title([RAW(session).Subject, RAW(session).Einfo{1}(10:12) ' session long trace']);
% set(gca,'YDir','reverse')
xsize=round(portrightxrot,0)-10:round(portleftxrot,0)+10;
ysize=round(backleftyrot,0)-10:round(portleftyrot,0)+10;
discretizedtransfcoordsx=discretize(Xrotcoords,xsize);
discretizedtransfcoordsy=discretize(Yrotcoords,ysize);
discretizedcoords=[discretizedtransfcoordsx discretizedtransfcoordsy];
ind= sub2ind([length(xsize) length(ysize)],discretizedtransfcoordsx,discretizedtransfcoordsy);
accumulatedelements=accumarray(ind(~isnan(ind(:))),1);
if numel(accumulatedelements)~=length(xsize)*length(ysize)
    accumulatedelements=[accumulatedelements; zeros(length(xsize)*length(ysize)-numel(accumulatedelements),1)];
end
distributionmatrix=reshape(accumulatedelements,[length(xsize),length(ysize)]);
actualtime_distributionmatrix=distributionmatrix.*0.001;
proportiontime_distributionmatrix=actualtime_distributionmatrix./length(Xrotcoords)*0.001;
[xG,yG]=meshgrid(-5:5);
sigma=2.5;
g = exp(-xG.^2./(2.*sigma.^2)-yG.^2./(2.*sigma.^2));
g = g./sum(g(:));
timespentintrialtype=length(coords)*0.001;
figure;
imagesc(xsize,ysize,conv2(proportiontime_distributionmatrix,g,'same'))
colormap(cms{ttype})
clim([0 5.0000e-10])
colorbar
hold on
linemakerx=[Xrotcorners(3),Xrotcorners(4),Xrotcorners(2),Xrotcorners(1),Xrotcorners(3)];
linemakery=[Yrotcorners(3),Yrotcorners(4),Yrotcorners(2),Yrotcorners(1),Yrotcorners(3)];
plot(linemakerx,linemakery,'Color','w')
scatter(leverxrot,leveryrot,'filled','v','w')

title(['Occupancy Map (' trialtags{ttype} ' trials for ' RAW(session).Subject, RAW(session).Einfo{1}(10:12) ') ' num2str(round(timespentintrialtype./60,0)) 'min in this trial type' ])
end