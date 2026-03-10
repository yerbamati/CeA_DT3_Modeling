%%
% cd('\\pbs-srv2.win.ad.jhu.edu\janaklabtest')
% oldFolder = cd('Matilde');
% cd('MatLab');
load RAWSuperJazz_Latency_raw.mat;
%%
% cd(oldFolder);
% cd('Matilde/Matlab/CarlMatLab');
opts = detectImportOptions('AB_FR21to23.xlsx');
opts.SelectedVariableNames = 1:38; 
guided_approach_behavior_ts = readmatrix('AB_FR21to23.xlsx',opts);
%%
% cd(oldFolder);
% cd('Matilde/DT3-Matilde-2023-09-04/videos/')

% Carl's Directory
% cd('videos_and_coords/')
%%
for session = 1
    % Make trial table
    trialTbl = table();
    LI = strcmp('LeverInsertion', RAW(session).Einfo(:,2));
    LItimes = RAW(session).Erast{LI};
    trialTbl.trialNo = [1:length(LItimes)]';
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
    
    % Get velocity
    cutoff=0.95;
    tag = RAW(session).Einfo{1}(5:12);
    opts = detectImportOptions([tag 'DLC_resnet_50_DT3Sep4shuffle1_1030000.csv']);
    opts.SelectedVariableNames = [1,5:7,20:34,8:13]; 
    curr_session = readmatrix([tag 'DLC_resnet_50_DT3Sep4shuffle1_1030000.csv'],opts);
    
    frames_DLC = curr_session(:,1); 
    all_coords_DLC=curr_session(:,2:3);
    coords_DLC = curr_session(logical([1;curr_session(2:end,4)>cutoff]),2:3);
    coords_rightear_DLC = curr_session(logical([1;curr_session(2:end,22)>cutoff]),20:21);
    coords_leftear_DLC = curr_session(logical([1;curr_session(2:end,25)>cutoff]),23:24);

    percentkept(session,1)= (sum([1;curr_session(2:end,4)>cutoff])/length(curr_session))*100;
    percentkept(session,2)= (sum([1;curr_session(2:end,22)>cutoff])/length(curr_session))*100;
    percentkept(session,3)= (sum([1;curr_session(2:end,25)>cutoff])/length(curr_session))*100;
    trackedbodypartconf{session,1}=curr_session(:,4);
    trackedbodypartconf{session,2}=curr_session(:,22);
    trackedbodypartconf{session,3}=curr_session(:,25);
    
    %Mati's Directories
    ffpath='W:\Matilde\MatLab\Supporting Programs\bin';
    path2videos='W:\Matilde\DT3-Matilde-2023-09-04\videos\';

    %Carl's Directories
    %ffpath='/Users/Carl/Desktop/FR Video Labeling';
    %path2videos='/Users/Carl/Desktop/FR Video Labeling/';

    % ffpath = 'E:\ffmpeg\bin';
    % path2videos = 'E:\DT3_Data_Processing\videos_and_coords\';
    
    ts=videoframets(ffpath,[path2videos tag '.AVI']);
    time_DLC=ts(logical([1;curr_session(2:end,4)>cutoff]),:);
    time_rightear_DLC = ts(logical([1;curr_session(2:end,22)>cutoff]),:);
    time_leftear_DLC = ts(logical([1;curr_session(2:end,25)>cutoff]),:);

    portleft(session,1)=mean(curr_session(curr_session(:,7)>.999,5));
    portleft(session,2)=mean(curr_session(curr_session(:,7)>.999,6));
    portright(session,1)=mean(curr_session(curr_session(:,10)>.999,8));
    portright(session,2)=mean(curr_session(curr_session(:,10)>.999,9));
    backleft(session,1)=mean(curr_session(curr_session(:,13)>.999,11));
    backleft(session,2)=mean(curr_session(curr_session(:,13)>.999,12));
    backright(session,1)=mean(curr_session(curr_session(:,16)>.999,14));
    backright(session,2)=mean(curr_session(curr_session(:,16)>.999,15));
    lever(session,1)=mean(curr_session(curr_session(:,19)>.999,17));
    lever(session,2)=mean(curr_session(curr_session(:,19)>.999,18));
    scatterx=[backright(:,1), backleft(:,1), portright(:,1), portleft(:,1),  lever(:,1)];
    scattery=[backright(:,2), backleft(:,2), portright(:,2), portleft(:,2),  lever(:,2)];

    time_plexon = (0:0.1:(RAW(session).Erast{29}))';
    coords_plexon = interp1(time_DLC,coords_DLC,time_plexon);
    all_coords_plexon=interp1(ts,all_coords_DLC,time_plexon);
    coords_rightear_plexon = interp1(time_rightear_DLC,coords_rightear_DLC,time_plexon);
    coords_leftear_plexon = interp1(time_leftear_DLC,coords_leftear_DLC,time_plexon);

    % figure;
    % plot(coords_plexon(:,1),coords_plexon(:,2))
    % hold on;
    % scatter(scatterx,scattery)
    % title([RAW(session).Subject, RAW(session).Einfo{1}(10:12) ' session long trace']);
    % set(gca,'YDir','reverse')

    li_indices= [];
    for num_li = 1:length(trialTbl.LeverInsertion)
        index_of_li = find(round(time_plexon(:,1),1) == round(trialTbl.LeverInsertion(num_li),1)); %changed from 4 to 3, check if still work
        li_indices = [li_indices;index_of_li];
    end
    
    lp1_indices = [];
    for num_lp = 1:length(trialTbl.LeverPress1)
        if isnan(trialTbl.LeverPress1(num_lp))
            index_of_lp1 = NaN;
        else
            index_of_lp1 = find(round(time_plexon(:,1),1) == round(trialTbl.LeverPress1(num_lp),1));
        end
        lp1_indices = [lp1_indices;index_of_lp1];
    end

    lr_indices = [];
    for num_lr = 1:length(trialTbl.LeverRetract)
        index_of_lr = find(round(time_plexon(:,1),1) == round(trialTbl.LeverRetract(num_lr),1));
        lr_indices = [lr_indices;index_of_lr];
    end

    %reward_velocity = [];
    %noreward_velocity = [];
    %session_velocity = [];
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
    sessionlever_distance=[];
    sessiontotal_distance=[];
    instvelocity=[];
    lever_distance = [];
    instvelocity_idx = [];
    lever_distance_idx = [];
    distance_thusfar = NaN(6e4+100,length(trialTbl.trialNo));
    trial_logic_RD = [];
    trial_logic_OM = [];
    approach_behavior_dist = [];
    approach_behavior_inst = [];
    approach_behavior_turn = [];


    for trial = 1:length(trialTbl.trialNo)
        if sum(isnan(trialTbl{trial,:})) == 0
            trial_coordsRD = coords_plexon(li_indices(trial):lp1_indices(trial),:);
            trial_rightear_coordsRD = coords_rightear_plexon(li_indices(trial):lp1_indices(trial),:);
            trial_leftear_coordsRD = coords_leftear_plexon(li_indices(trial):lp1_indices(trial),:);
            trial_timeRD= time_plexon(li_indices(trial):lp1_indices(trial),:);
            all_trial_coordsRD= all_coords_plexon(li_indices(trial):lp1_indices(trial),:);
            
            [num_of_trial_coords,~] = size(trial_coordsRD);
            instvel_trialcolumns(trial,1)=num_of_trial_coords-1;
            instvel_trialcolumns(trial,2)= 1;
            id1=find(instvelocity,1,'last')+1;
            if isempty(id1)
                id1=1;
            end
            lever_id1 = find(lever_distance,1,'last')+1;
            if isempty(lever_id1)
                lever_id1 = 1;
            end
            
            distance_squared_RD = (diff(trial_coordsRD)).^2; %first column is (x2-x1)^2, second column is (y2-y1)^2
            distance_RD = sqrt(distance_squared_RD(:,1) + distance_squared_RD(:,2));
            trial_instvelocity = distance_RD./0.001;
            instvelocity = [instvelocity; trial_instvelocity];
            total_distance = sum(distance_RD);
            trial_thusfar_RD = [0;cumsum(distance_RD)];
            dist_from_lever_squared_RD = (trial_coordsRD - lever(session,:)).^2;
            dist_from_lever_RD = sqrt(dist_from_lever_squared_RD(:,1) + dist_from_lever_squared_RD(:,2));
            ld_instvelocity = diff(dist_from_lever_RD)./0.001;

            interval = round(0.2*length(trial_timeRD));
            front_section = dist_from_lever_RD(1:end-interval);
            back_section = dist_from_lever_RD(interval+1:end);
            slope_of_dist = (back_section - front_section)./interval;

            % rewardtotal_distance=[rewardtotal_distance;total_distance];
            %trial_velocity = total_distance/num_of_trial_coords;
            %reward_velocity = [reward_velocity;trial_velocity];
            %session_velocity = [session_velocity;trial_velocity];
            % ratx= trial_coordsRD(1,1);
            % raty= trial_coordsRD(1,2);
            % trial_lvr_distance= sqrt((ratx-leverx(session))^2+(raty-levery(session))^2);
            % rewardlever_distance=[rewardlever_distance;dist_from_lever_RD(1)];
            sessiontotal_distance=[sessiontotal_distance;total_distance];
            distance_thusfar(1:length(trial_thusfar_RD),trial) = trial_thusfar_RD;
            sessionlever_distance=[sessionlever_distance;dist_from_lever_RD(1)];
            lever_distance = [lever_distance;dist_from_lever_RD];

            id2=find(instvelocity,1,'last');
            lever_id2 = find(lever_distance,1,'last');
            %trial_accel=(instvelocity(id1)-instvelocity(id2))/num_of_trial_coords;
            %reward_accel=[reward_accel;trial_accel];
            %session_accel=[session_accel;trial_accel];
            instvelocity_idx(trial,1)=id1;
            instvelocity_idx(trial,2)=id2;
            lever_distance_idx(trial,1) = lever_id1;
            lever_distance_idx(trial,2) = lever_id2;

            %Finding the angle of the head relative to the lever
            rhs_squared = (trial_rightear_coordsRD - trial_coordsRD).^2;
            rightear_headcap_side = sqrt(rhs_squared(:,1) + rhs_squared(:,2));
            lhs_squared = (trial_leftear_coordsRD - trial_coordsRD).^2;
            leftear_headcap_side = sqrt(lhs_squared(:,1) + lhs_squared(:,2));
            base_squared = (trial_rightear_coordsRD - trial_leftear_coordsRD).^2;
            base = sqrt(base_squared(:,1) + base_squared(:,2));

            s = (rightear_headcap_side + leftear_headcap_side + base)./2;
            area = sqrt(s.*(s-rightear_headcap_side).*(s-leftear_headcap_side).*(s-base)); %Heron's Formula
            height = (2.*area)./base;
            leftear_anchor_side = sqrt(leftear_headcap_side.^2 - height.^2);

            base_vector = trial_rightear_coordsRD - trial_leftear_coordsRD;
            base_unit_vector = base_vector ./ base;
            leftear_anchor_vector = base_unit_vector .* leftear_anchor_side;
            trial_anchor_coordsRD = trial_leftear_coordsRD + leftear_anchor_vector;

            anchor_headcap_vector = trial_coordsRD - trial_anchor_coordsRD;
            % test = anchor_headcap_vector(1,:) * (leftear_anchor_vector(1,:))';
            anchor_lever_vector = lever(session,:) - trial_anchor_coordsRD;
            headcap_lever_dot_product = dot(anchor_headcap_vector,anchor_lever_vector,2);
            ahv_size = sqrt(anchor_headcap_vector(:,1).^2 + anchor_headcap_vector(:,2).^2);
            alv_size = sqrt(anchor_lever_vector(:,1).^2 + anchor_lever_vector(:,2).^2);
            pre_angle = headcap_lever_dot_product ./ (ahv_size .* alv_size);
            angle_of_head_radian = acos(pre_angle);
            
            % figure()
            % polarhistogram(angle_of_head_radian,4)

            angle_of_head = angle_of_head_radian .* 180 ./ pi;
            head_turn_rate = diff(angle_of_head)./0.001;

            % %Finding the angle of the head relative to the chamber
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

            %Finding all instvelocity and dist_from_leverRD local maximums
            % instvelocity_smooth = smoothdata(trial_instvelocity,'movmean',2000);
            % instvelocity_over_time = [[instvelocity_smooth;instvelocity_smooth(end)] trial_timeRD];
            % dist_from_lever_smooth = smoothdata(dist_from_lever_RD,'movmean',500);
            % dist_from_lever_over_time = [dist_from_lever_smooth trial_timeRD];
            % ld_instvelocity_smooth = smoothdata(ld_instvelocity,'movmean',2000);
            % ld_instvelocity_over_time = [[ld_instvelocity_smooth;ld_instvelocity_smooth(end)] trial_timeRD];
            % slope_of_dist_smooth = smoothdata(slope_of_dist,'movmean',500);
            % slope_of_dist_over_time = [slope_of_dist_smooth trial_timeRD(1:end-interval)];

            instvelocity_smooth = smoothdata(trial_instvelocity,'movmean',50);
            instvelocity_over_time = [[instvelocity_smooth;instvelocity_smooth(end)] trial_timeRD];
            dist_from_lever_smooth = smoothdata(dist_from_lever_RD,'movmean',5);
            dist_from_lever_over_time = [dist_from_lever_smooth trial_timeRD];
            ld_instvelocity_smooth = smoothdata(ld_instvelocity,'movmean',50);
            ld_instvelocity_over_time = [[ld_instvelocity_smooth;ld_instvelocity_smooth(end)] trial_timeRD];
            slope_of_dist_smooth = smoothdata(slope_of_dist,'movmean',5);
            slope_of_dist_over_time = [slope_of_dist_smooth trial_timeRD(1:end-interval)];
            
            % angle_of_head_smooth = smoothdata(angle_of_head,'movmean',500);
            % angle_of_head_over_time = [angle_of_head_smooth trial_timeRD];
            % head_turn_rate_smooth = smoothdata(head_turn_rate, 'movmean',2000);
            % head_turn_rate_over_time = [[head_turn_rate_smooth;head_turn_rate_smooth(end)] trial_timeRD];
            % angle_of_head_chamber_smooth = smoothdata(angle_of_head_chamber, 'movmean', 500);
            % angle_of_head_chamber_over_time = [angle_of_head_chamber_smooth,trial_timeRD];

            angle_of_head_smooth = smoothdata(angle_of_head,'movmean',5);
            angle_of_head_over_time = [angle_of_head_smooth trial_timeRD];
            head_turn_rate_smooth = smoothdata(head_turn_rate, 'movmean',50);
            head_turn_rate_over_time = [[head_turn_rate_smooth;head_turn_rate_smooth(end)] trial_timeRD];

            % velocity_indicator = logical([islocalmax(instvelocity_smooth,'MaxNumExtrema',5,'Minseparation',1000);0]);
            % dist_from_lever_indicator = islocalmax(dist_from_lever_smooth,'MaxNumExtrema',5,'Minseparation',1000);
            % ld_instvelocity_indicator = logical([islocalmin(ld_instvelocity_smooth,'MaxNumExtrema',5,'MinSeparation',1000);0]);
            % slope_of_dist_indicator = islocalmin(slope_of_dist_smooth,'MaxNumExtrema',5,'MinSeparation',1000);
            % 
            % angle_of_head_indicator = islocalmin(angle_of_head_smooth, 'MaxNumExtrema',5,'MinSeparation',1000);
            % head_turn_rate_indicator = islocalmin(head_turn_rate_smooth,'MaxNumExtrema',5,'MinSeparation',1000);

            velocity_indicator = logical([islocalmax(instvelocity_smooth,'MaxNumExtrema',5,'Minseparation',10);0]);
            dist_from_lever_indicator = islocalmax(dist_from_lever_smooth,'MaxNumExtrema',5,'Minseparation',10);
            ld_instvelocity_indicator = logical([islocalmin(ld_instvelocity_smooth,'MaxNumExtrema',5,'MinSeparation',10);0]);
            slope_of_dist_indicator = islocalmin(slope_of_dist_smooth,'MaxNumExtrema',5,'MinSeparation',10);

            angle_of_head_indicator = islocalmin(angle_of_head_smooth, 'MaxNumExtrema',5,'MinSeparation',10);
            head_turn_rate_indicator = islocalmin(head_turn_rate_smooth,'MaxNumExtrema',5,'MinSeparation',10);

            instvelocity_local_maximums = instvelocity_over_time(velocity_indicator,:);
            dist_from_lever_local_maximums = dist_from_lever_over_time(dist_from_lever_indicator,:);
            ld_instvelocity_local_minimums = ld_instvelocity_over_time(ld_instvelocity_indicator,:);
            slope_of_dist_local_minimums = slope_of_dist_over_time(slope_of_dist_indicator,:);

            angle_of_head_local_minimums = angle_of_head_over_time(angle_of_head_indicator,:);
            head_turn_rate_local_minimums = head_turn_rate_over_time(head_turn_rate_indicator,:);

            %Finding large value head turns
            turn_time = round(0.15*length(trial_timeRD));
            turn_interval_a = angle_of_head_smooth(1:end-turn_time);
            turn_interval_b = angle_of_head_smooth(turn_time+1:end);
            turn_value = turn_interval_a - turn_interval_b;
            turn_value_wth_time = [turn_value trial_timeRD(turn_time+1:end)];

            large_turn_ts_a = turn_value_wth_time(turn_interval_b < 45, :);
            
            large_turn_indicator_b = large_turn_ts_a(:,1) > (median(abs(turn_value)) + std(abs(turn_value))*2);
            large_turn_ts_b = large_turn_ts_a(large_turn_indicator_b,:);
            
            [num_large_turns,~] = size(large_turn_ts_b);
            large_turn_indicator_c = NaN(num_large_turns,1);
            
            for turn_angle = 1:num_large_turns
                turn_index = find(trial_timeRD == large_turn_ts_b(turn_angle,2));
                large_turn_indicator_c(turn_angle) = turn_index;
            end

            large_turn_ts_c = angle_of_head_over_time(large_turn_indicator_c,:);

            %Finding Approach Behaviour Using dist_from_lever
            trial_approach_dist = [];
            if length(trial_timeRD) > 50
                [num_local_max,~] = size(dist_from_lever_local_maximums);
                if num_local_max == 1
                    approach_timestamp = dist_from_lever_local_maximums(1,2);
                    diff_timestamp = abs(instvelocity_local_maximums(:,2) - approach_timestamp);
                    diff_evaluation = sum(diff_timestamp < 2);
                    if diff_evaluation >= 1
                        approach_behavior_dist = [approach_behavior_dist;approach_timestamp];
                        trial_approach_dist = dist_from_lever_local_maximums(1,:);
                    end
                else
                    for peak = length(dist_from_lever_local_maximums):-1:1
                        approach_timestamp = dist_from_lever_local_maximums(peak,2);
                        diff_timestamp = abs(instvelocity_local_maximums(:,2) - approach_timestamp);
                        diff_evaluation = sum(diff_timestamp < 2);
                        if diff_evaluation >= 1
                            approach_behavior_dist = [approach_behavior_dist;approach_timestamp];
                            trial_approach_dist = dist_from_lever_local_maximums(peak,:);
                            break
                        else
                            continue
                        end
                    end
                end
            else
                approach_behavior_dist = [approach_behavior_dist;trial_timeRD(1)];
                trial_approach_dist = [NaN, NaN];
            end
            %In case the trial is more than 5 seconds long, but no approach
            %behavior can be found
            if isempty(trial_approach_dist)
                approach_behavior_dist = [approach_behavior_dist;NaN];
                trial_approach_dist = [NaN, NaN];
            end

            %Finding Approach Behaviour Using ld_instvelocity
            inst_major_peak = [NaN, NaN];
            inst_minor_peak = [NaN, NaN];
            [num_local_min,~] = size(ld_instvelocity_local_minimums);
            if length(trial_timeRD) > 50
                if num_local_min == 1
                    approach_behavior_inst = [approach_behavior_inst;[ld_instvelocity_local_minimums(end,2),ld_instvelocity_local_minimums(end,2)]];
                    inst_major_peak = ld_instvelocity_local_minimums(end,:);
                else
                    peak_diff = ld_instvelocity_local_minimums(end,1) - ld_instvelocity_local_minimums(end-1,1);
                    major_peak_threshold = 0.2 * abs(ld_instvelocity_local_minimums(end-1,1));
                    if peak_diff > major_peak_threshold
                        approach_behavior_inst = [approach_behavior_inst;[ld_instvelocity_local_minimums(end-1,2),ld_instvelocity_local_minimums(end,2)]];
                        inst_major_peak = ld_instvelocity_local_minimums(end-1,:);
                        inst_minor_peak = ld_instvelocity_local_minimums(end,:);
                    else
                        approach_behavior_inst = [approach_behavior_inst;[ld_instvelocity_local_minimums(end,2),ld_instvelocity_local_minimums(end,2)]];
                        inst_major_peak = ld_instvelocity_local_minimums(end,:);
                    end
                end
            else
                approach_behavior_inst = [approach_behavior_inst;[trial_timeRD(1),trial_timeRD(1)]];
            end

            %Finding Approach Behavior Using large head turns
            ld_indicator_turn = logical([islocalmin(ld_instvelocity_smooth,'MaxNumExtrema',2,'MinSeparation',10);0]);
            ld_local_minimums_turn = ld_instvelocity_over_time(ld_indicator_turn,:);
            trial_approach_turn = [NaN,NaN];
            if length(trial_timeRD) > 50
                [num_local_min_turn,~] = size(ld_local_minimums_turn);
                if num_local_min_turn == 1
                    approach_behavior_turn = [approach_behavior_turn;ld_local_minimums_turn(1,2)];
                    trial_approach_turn = ld_local_minimums_turn(1,:);
                else
                    if isempty(large_turn_ts_b)
                        peak_diff_turn = ld_local_minimums_turn(2,1) - ld_local_minimums_turn(1,1);
                        major_peak_threshold_turn = 0.2 * abs(ld_local_minimums_turn(1,1));
                        if peak_diff_turn > major_peak_threshold_turn
                            approach_behavior_turn = [approach_behavior_turn;ld_local_minimums_turn(1,2)];
                            trial_approach_turn = ld_local_minimums_turn(1,:);
                        else
                            approach_behavior_turn = [approach_behavior_turn;ld_local_minimums_turn(2,2)];
                            trial_approach_turn = ld_local_minimums_turn(2,:);
                        end
                    else
                        large_turn_time = large_turn_ts_b(1,2);
                        large_turn_diff = abs(ld_local_minimums_turn(:,2) - large_turn_time);
                        [~,large_turn_diff_idx] = min(large_turn_diff);
                        approach_behavior_turn = [approach_behavior_turn;ld_local_minimums_turn(large_turn_diff_idx,2)];
                        trial_approach_turn = ld_local_minimums_turn(large_turn_diff_idx,:);
                    end
                end
            else
                approach_behavior_turn = [approach_behavior_turn;trial_timeRD(1)];
            end

            trial_logic_RD = [trial_logic_RD;1];
            trial_logic_OM = [trial_logic_OM;0];

            trial_RD_idx = sum(trial_logic_RD);

            %User determined Approach Behaviour
            guided_curr_trial_ts = guided_approach_behavior_ts(trial_RD_idx,session);
            guided_idx = find(round(ld_instvelocity_over_time(:,2),1) == round(guided_curr_trial_ts,1));
            trial_approach_guided = ld_instvelocity_over_time(guided_idx,:);
            
            %Graphing figures
            figure(trial)
            hold on
            yyaxis left
            title(['Trial ' num2str(trial) ' (RD' num2str(trial_RD_idx) ')'])
            xlabel('Time(s)')

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

            ylabel('Angle of Head Relative to Lever (Degree)')
            plot(angle_of_head_over_time(:,2),angle_of_head_over_time(:,1))
            plot(angle_of_head_local_minimums(:,2),angle_of_head_local_minimums(:,1),'g*')
            plot(large_turn_ts_c(:,2),large_turn_ts_c(:,1),'.m')

            % ylabel('Angle of Head Relative to Chamber (Degree)')
            % plot(angle_of_head_chamber_over_time(:,2),angle_of_head_chamber_over_time(:,1))

            yyaxis right

            % ylabel('Distance from Lever (pixel)')
            % plot(dist_from_lever_over_time(:,2),dist_from_lever_over_time(:,1))
            % plot(dist_from_lever_local_maximums(:,2),dist_from_lever_local_maximums(:,1),'g*')
            % plot(trial_approach_dist(2),trial_approach_dist(1),'bsquare')

            ylabel('Lever Directed Instantaneous Velocity (pixel/s)')
            yline(0,'k','LineWidth',0.55)
            xline(trial_approach_guided(2),'k','LineWidth',0.55)
            plot(ld_instvelocity_over_time(:,2),ld_instvelocity_over_time(:,1))
            plot(ld_instvelocity_local_minimums(:,2),ld_instvelocity_local_minimums(:,1),'mx')
            plot(inst_major_peak(2),inst_major_peak(1),'kdiamond','MarkerSize',8)
            plot(inst_minor_peak(2),inst_minor_peak(1),'rv','MarkerSize',8)
            plot(trial_approach_turn(2),trial_approach_turn(1),'bsquare','MarkerSize',8)
            % plot(trial_approach_guided(2),trial_approach_guided(1),'k.','Markersize',15)

            % ylabel('Slope of Distance over 1/5 of Trial')
            % plot(slope_of_dist_over_time(:,2),slope_of_dist_over_time(:,1))
            % plot(slope_of_dist_local_minimums(:,2),slope_of_dist_local_minimums(:,1),'pentagram','Color',[0.6350 0.0780 0.1840])

            % ylabel('Angle of Head Relative to Lever (Degree)')
            % plot(angle_of_head_over_time(:,2),angle_of_head_over_time(:,1))

            hold off
            
            alltrials.allsession{session,trial}=trial_coordsRD(:,:);
            alltrials.RD{session,trial}=trial_coordsRD(:,:);
            alltrials.timeinRD{session,trial}=length(all_trial_coordsRD).*0.001;
        
        elseif sum(isnan(trialTbl{trial,:})) ~= 0
            trial_coordsOM = coords_plexon(li_indices(trial):lr_indices(trial),:);
            trial_timeOM= time_plexon(li_indices(trial):lr_indices(trial),:);
            all_trial_coordsOM= all_coords_plexon(li_indices(trial):lr_indices(trial),:);
            [num_of_trial_coords,~] = size(trial_coordsOM);
            instvel_trialcolumns(trial,1)=num_of_trial_coords-1;
            instvel_trialcolumns(trial,2)= 0;
            id1=find(instvelocity,1,'last')+1;
            if isempty(id1)
                id1=1;
            end
            lever_id1 = find(lever_distance,1,'last')+1;
            if isempty(lever_id1)
                lever_id1 = 1;
            end
            % for interval = 2:num_of_trial_coords
            %     x1 = trial_coordsOM(interval-1,1);
            %     y1 = trial_coordsOM(interval-1,2);
            %     x2 = trial_coordsOM(interval,1);
            %     y2 = trial_coordsOM(interval,2);
            %     distance = sqrt((x2-x1)^2 + (y2-y1)^2);
            %     instvelocity=[instvelocity; distance/(trial_timeOM(interval)-trial_timeOM(interval-1))]; 
            %     total_distance = total_distance + distance;
            % end
            % session_approachbehaviorts=[session_approachbehaviorts; ]
            
            distance_squared_OM = (diff(trial_coordsOM)).^2; %first column is (x2-x1)^2, second column is (y2-y1)^2
            distance_OM = sqrt(distance_squared_OM(:,1) + distance_squared_OM(:,2));
            trial_instvelocity = distance_OM./0.001;
            instvelocity = [instvelocity; trial_instvelocity];
            total_distance = sum(distance_OM);
            trial_thusfar_OM = [0;cumsum(distance_OM)];
            dist_from_lever_squared_OM = (trial_coordsOM - lever(session,:)).^2;
            dist_from_lever_OM = sqrt(dist_from_lever_squared_OM(:,1) + dist_from_lever_squared_OM(:,2));
            
            % norewardtotal_distance=[norewardtotal_distance;total_distance];
            % trial_velocity = total_distance/num_of_trial_coords;
            % noreward_velocity = [noreward_velocity;trial_velocity];
            % session_velocity = [session_velocity;trial_velocity];
            % ratx= trial_coordsOM(1,1);
            % raty= trial_coordsOM(1,2);
            % trial_lvr_distance= sqrt((ratx-leverx(session))^2+(raty-levery(session))^2);
            % norewardlever_distance=[norewardlever_distance;dist_from_lever_OM(1)];
            sessiontotal_distance=[sessiontotal_distance;total_distance];
            distance_thusfar(1:length(trial_thusfar_OM),trial) = trial_thusfar_OM;
            sessionlever_distance=[sessionlever_distance;dist_from_lever_OM(1)];
            lever_distance = [lever_distance;dist_from_lever_OM];
            
            id2=find(instvelocity,1,'last');
            lever_id2 = find(lever_distance,1,'last');
            % trial_accel=(instvelocity(id1)-instvelocity(id2))/num_of_trial_coords;
            % noreward_accel=[noreward_accel;trial_accel];
            % session_accel=[session_accel;trial_accel];
            instvelocity_idx(trial,1)=id1;
            instvelocity_idx(trial,2)=id2;
            lever_distance_idx(trial,1) = lever_id1;
            lever_distance_idx(trial,2) = lever_id2;

            instvelocity_smooth = smoothdata(trial_instvelocity,'movmean',2000);
            instvelocity_over_time = [[instvelocity_smooth;instvelocity_smooth(end)] trial_timeOM];
            dist_from_lever_smooth = smoothdata(dist_from_lever_OM,'movmean',500);
            dist_from_lever_over_time = [dist_from_lever_smooth trial_timeOM];

            trial_logic_RD = [trial_logic_RD;0];
            trial_logic_OM = [trial_logic_OM;1];

            trial_OM_idx = sum(trial_logic_OM);

            % figure(trial)
            % hold on
            % yyaxis left
            % title(['Trial ' num2str(trial) ' (OM' num2str(trial_OM_idx) ')'])
            % xlabel('Time(s)')

            % plot(instvelocity_over_time(:,2),instvelocity_over_time(:,1))
            % % plot(instvelocity_local_maximums(:,2),instvelocity_local_maximums(:,1),'ro')
            % ylabel('Instantaneous Velocity (pixel/s)')
            
            % yyaxis right
            
            % plot(dist_from_lever_over_time(:,2),dist_from_lever_over_time(:,1))
            % % plot(dist_from_lever_local_maximums(:,2),dist_from_lever_local_maximums(:,1),'g*')
            % ylabel('Distance from Lever (pixel)')
            % hold off
            
            alltrials.allsession{session,trial}=trial_coordsOM(:,:);
            alltrials.OM{session,trial}=trial_coordsOM(:,:);
            alltrials.timeinOM{session,trial}=length(all_trial_coordsOM).*0.001;
        end

        trial_logic_RD = logical(trial_logic_RD);
        trial_logic_OM = logical(trial_logic_OM);
    end
    
    curr_session_guided_ab_ts = guided_approach_behavior_ts(:,session);
    curr_session_guided_ab_ts(isnan(curr_session_guided_ab_ts)) = [];
    
    dist_approximation_error = abs(approach_behavior_dist - curr_session_guided_ab_ts);
    inst_approximation_error = abs(approach_behavior_inst - curr_session_guided_ab_ts);
    turn_approximation_error = abs(approach_behavior_turn - curr_session_guided_ab_ts);
    
    mean_dist_error = mean(dist_approximation_error,'omitnan');
    mean_inst_error = mean(inst_approximation_error);
    mean_turn_error = mean(turn_approximation_error);
   
    dist_error_raw = approach_behavior_dist - curr_session_guided_ab_ts;
    inst_error_raw = approach_behavior_inst - curr_session_guided_ab_ts;
    turn_error_raw = approach_behavior_turn - curr_session_guided_ab_ts;

    mean_dist_raw = mean(dist_error_raw,'omitnan');
    mean_inst_raw = mean(inst_error_raw);
    mean_turn_raw = mean(turn_error_raw);

    figure()
    hold on
    title(['Approximation Error ' tag])
    bar(1:sum(trial_logic_RD),[(turn_approximation_error)';(inst_approximation_error)'])
    legend('Turn Approximation Error','Inst Approximation Error(Major)','Inst Approximation Error(Minor)')
    %ylim([0,12])
    hold off

    xlineplaces=[cumsum(instvel_trialcolumns(:,1)),instvel_trialcolumns(:,2)];
    if xlineplaces(1,2)==1
        initialpatch=1;
    elseif xlineplaces(1,2)==0
        initialpatch=0;
    end
    if xlineplaces(end,2)==1
        finalpatch=1;
    elseif xlineplaces(end,2)==0
        finalpatch=0;
    end
    transitions=diff(xlineplaces(:,2));
    patchcoordinatesmaster=[[0 initialpatch];xlineplaces(find(transitions==-1|transitions==1)+1,:);[xlineplaces(end,1) finalpatch]];
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
    patchxsexpanded=[repelem(patchcoordinatesmaster(1,1),2)';repelem(patchcoordinatesmaster(2:end-1,1),4);repelem(patchcoordinatesmaster(end,1),2)'];
    patchxreshaped=reshape(patchxsexpanded,4,length(patchxsexpanded)/4);
    ys=repmat([0;0.2;0.2;0],1,size(patchxreshaped,2));
    for transit=2:length(patchcoordinatesmaster)
        if patchcoordinatesmaster(transit-1,2)==1
            patchxreshaped(5,transit-1)=1;
        elseif patchcoordinatesmaster(transit-1,2)==0
            patchxreshaped(5,transit-1)=0;
        end
    end

    % figure;hold on;
    % patch(patchxreshaped(1:4,patchxreshaped(5,:)==1),ys(:,patchxreshaped(5,:)==1),'g','FaceAlpha',0.2,'EdgeColor','none');
    % patch(patchxreshaped(1:4,patchxreshaped(5,:)==0),ys(:,patchxreshaped(5,:)==0),'k','FaceAlpha',0.2,'EdgeColor','none');
    % plot(smoothdata(instvelocity,'movmean',5000))
    % xline(xlineplaces(:,1))
    % xlim([0 max(xlineplaces(:,1))])

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
    % 
    % RAW(session).Erast{47,1}=session_velocity(strcmp(RAW(session).Erast{42,1},'low'));
    % RAW(session).Einfo{47,1}=RAW(session).Einfo{1,1};
    % RAW(session).Einfo{47,2}='VelocityLowMotivation';

    RAW(session).Erast{43,1} = sessionlever_distance;
    RAW(session).Einfo{43,1} = cellstr(RAW(session).Einfo{1,1});
    RAW(session).Einfo{43,2} = 'DistancefromLever';

    % RAW(session).Erast{49,1} = rewardlever_distance;
    % RAW(session).Einfo{49,1} = RAW(session).Einfo{1,1};
    % RAW(session).Einfo{49,2} = 'DistancefromLeverRD';

    % RAW(session).Erast{50,1} = norewardlever_distance;
    % RAW(session).Einfo{50,1} = RAW(session).Einfo{1,1};
    % RAW(session).Einfo{50,2} = 'DistancefromLeverNoRD';

    RAW(session).Erast{44,1} = sessionlever_distance(strcmp(RAW(session).Erast{42,1},'high'));
    RAW(session).Einfo{44,1} = RAW(session).Einfo{1,1};
    RAW(session).Einfo{44,2} = 'DistancefromLeverHighMotivation';

    RAW(session).Erast{45,1} = sessionlever_distance(strcmp(RAW(session).Erast{42,1},'low'));
    RAW(session).Einfo{45,1} = RAW(session).Einfo{1,1};
    RAW(session).Einfo{45,2} = 'DistancefromLeverLowMotivation';

    RAW(session).Erast{46,1} = sessiontotal_distance;
    RAW(session).Einfo{46,1} = cellstr(RAW(session).Einfo{1,1});
    RAW(session).Einfo{46,2} = 'TotalDistanceTraveled';

    % RAW(session).Erast{54,1} = rewardtotal_distance;
    % RAW(session).Einfo{54,1} = RAW(session).Einfo{1,1};
    % RAW(session).Einfo{54,2} = 'TotalDistanceTraveledRD';

    % RAW(session).Erast{55,1} = norewardtotal_distance;
    % RAW(session).Einfo{55,1} = RAW(session).Einfo{1,1};
    % RAW(session).Einfo{55,2} = 'TotalDistanceTravelednoRD';

    RAW(session).Erast{47,1} = sessiontotal_distance(strcmp(RAW(session).Erast{42,1},'high'));
    RAW(session).Einfo{47,1} = RAW(session).Einfo{1,1};
    RAW(session).Einfo{47,2} = 'TotalDistanceTraveledHM';

    RAW(session).Erast{48,1} = sessiontotal_distance(strcmp(RAW(session).Erast{42,1},'low'));
    RAW(session).Einfo{48,1} = RAW(session).Einfo{1,1};
    RAW(session).Einfo{48,2} = 'TotalDistanceTraveledLM';

    RAW(session).Erast{49,1} = approach_behavior_dist;
    RAW(session).Einfo{49,1} = RAW(session).Einfo{1,1};
    RAW(session).Einfo{49,2} = 'ApproachBehaviorDist';

    RAW(session).Erast{50,1} = approach_behavior_inst;
    RAW(session).Einfo{50,1} = RAW(session).Einfo{1,1};
    RAW(session).Einfo{50,2} = 'ApproachBehaviorInst';

    alltrials.ApproachBehaviorDist{session,1} = approach_behavior_dist;
    alltrials.ApproachBehaviorInst{session,1} = approach_behavior_inst;
    alltrials.ApproachBehaviorTurn{session,1} = approach_behavior_turn;
    
    alltrials.DistError{session,1} = dist_approximation_error;
    alltrials.DistError{session,2} = dist_error_raw;
    alltrials.InstError{session,1} = inst_approximation_error;
    alltrials.InstError{session,2} = inst_error_raw;
    alltrials.TurnError{session,1} = turn_approximation_error;
    alltrials.TurnError{session,2} = turn_error_raw;
    
    alltrials.MeanDistError{session,1} = mean_dist_error;
    alltrials.MeanDistError{session,2} = mean_dist_raw;
    alltrials.MeanInstError{session,1} = mean_inst_error;
    alltrials.MeanInstError{session,2} = mean_inst_raw;
    alltrials.MeanTurnError{session,1} = mean_turn_error;
    alltrials.MeanTurnError{session,2} = mean_turn_raw;

end
avgkept=mean(percentkept);
lowestkept=min(percentkept);
highestkept=max(percentkept);

%%
for trial = 1:length(trialTbl.trialNo)
    if sum(isnan(trialTbl{trial,:})) == 0
        graph_lever_distance = lever_distance(lever_distance_idx(trial,1):lever_distance_idx(trial,2));
        graph_instvelocity = [instvelocity(instvelocity_idx(trial,1):instvelocity_idx(trial,2));instvelocity(instvelocity_idx(trial,2))];
        graph_time = (1:length(li_indices(trial):lp1_indices(trial)))';
        figure(trial);
        yyaxis left
        plot(graph_time,smoothdata(graph_lever_distance,'movmean',200))
        yyaxis right
        plot(graph_time,smoothdata(graph_instvelocity,'movmean',2000))
    % elseif sum(isnan(trialTbl{trial,:})) ~= 0
    %     graph_lever_distance = lever_distance(lever_distance_idx(trial,1):lever_distance_idx(trial,2));
    %     graph_instvelocity = [instvelocity(instvelocity_idx(trial,1):instvelocity_idx(trial,2));instvelocity(instvelocity_idx(trial,2))];
    %     graph_time = (1:length(li_indices(trial):lr_indices(trial)))';
    %     figure(trial);
    %     yyaxis left
    %     plot(graph_time,smoothdata(graph_lever_distance,'movmean'))
    %     yyaxis right
    %     plot(graph_time,smoothdata(graph_instvelocity,'movmean',2000))
    end
end
%%
total_dist_error = 0;
total_major_error = 0;
total_minor_error = 0;
total_turn_error = 0;

total_num_inst = 0;
total_num_dist = 0;
total_num_turn = 0;

first_session = 31
last_session = 38
num_of_sessions = last_session-first_session+1;
for ab_session = first_session:last_session
    dist_error_nanfree = alltrials.DistError{ab_session,1};
    dist_error_nanfree(isnan(dist_error_nanfree)) = [];

    total_major_error = total_major_error + sum(alltrials.InstError{ab_session,1}(:,1));
    total_minor_error = total_minor_error + sum(alltrials.InstError{ab_session,1}(:,2));
    total_dist_error = total_dist_error + sum(dist_error_nanfree);
    total_turn_error = total_turn_error + sum(alltrials.TurnError{ab_session,1});
    
    total_num_inst = total_num_inst + length(alltrials.InstError{ab_session,1}(:,1));
    total_num_dist = total_num_dist + length(dist_error_nanfree);
    total_num_turn = total_num_turn + length(alltrials.TurnError{ab_session,1});
end
overall_mean_major_error = total_major_error/total_num_inst;
overall_mean_minor_error = total_minor_error/total_num_inst;
overall_mean_dist_error = total_dist_error/total_num_dist;
overall_mean_turn_error = total_turn_error/total_num_turn;

every_mean_inst_error = cell2mat(alltrials.MeanInstError);
graph_mean_inst_error = every_mean_inst_error(1:num_of_sessions,1:2);
graph_mean_dist_error = cell2mat(alltrials.MeanDistError(first_session:last_session,1));
graph_mean_turn_error = cell2mat(alltrials.MeanTurnError(first_session:last_session,1));

figure()
hold on
title(['Mean Approximation Error Over ' num2str(num_of_sessions) ' Sessions'])
bar(1:num_of_sessions,[(graph_mean_turn_error)';(graph_mean_inst_error)'])
legend('Mean Turn Approximation Error','Mean Inst Approximation Error(Major)','Mean Inst Approximation Error(Minor)')
hold off

graph_mean_inst_raw = every_mean_inst_error(1:num_of_sessions,3:4);
graph_mean_dist_raw = cell2mat(alltrials.MeanDistError(first_session:last_session,2));
graph_mean_turn_raw = cell2mat(alltrials.MeanTurnError(first_session:last_session,2));

figure()
hold on
title(['Mean Approximation Error (Raw) Over ' num2str(num_of_sessions) ' Sessions'])
bar(1:num_of_sessions,[(graph_mean_turn_raw)';(graph_mean_inst_raw)'])
legend('Mean Turn Approximation Error','Mean Inst Approximation Error(Major)','Mean Inst Approximation Error(Minor)')
hold off

%%
NoRD = [0.3 0.3 0.3];
RD = [0.01 0.87 0.02];
hm = [0.77 0.1 0.37];
lm = [0.2 0.28 0.45];
all_RD_vel = [];
all_OM_vel = [];
numbtrials=[];
for session = 1:length(RAW)
   all_RD_vel = [all_RD_vel;RAW(session).Erast{44}];
   all_OM_vel = [all_OM_vel;RAW(session).Erast{45}];
   numbtrials= [numbtrials;length(RAW(session).Erast{11})];
end
totaltrials=sum(numbtrials);
figure;
b1=bar([mean(all_RD_vel),mean(all_OM_vel)],'FaceColor','flat')
ylim([0 0.1])
b1.CData(1,:)=RD;
b1.CData(2,:)=NoRD;
xticklabels({'Rewarded','Omitted'})
title('Rewarded vs Omission Trial Velocity')
all_hm_vel = [];
all_lm_vel = [];
numbtrials=[];
for session = 1:length(RAW)
   all_hm_vel = [all_hm_vel;RAW(session).Erast{46}];
   all_lm_vel = [all_lm_vel;RAW(session).Erast{47}];
   numbtrials= [numbtrials;length(RAW(session).Erast{11})];
end
totaltrials=sum(numbtrials);
figure;
b2=bar([mean(all_hm_vel),mean(all_lm_vel)],'FaceColor','flat')
ylim([0 0.1])
b2.CData(1,:)=hm;
b2.CData(2,:)=lm;
xticklabels({'High Motivation','Low Motivation'})
title('High vs Low Trial Velocity')

all_RD_dist = [];
all_OM_dist = [];
numbtrials=[];
for session = 1:length(RAW)
   all_RD_dist = [all_RD_dist;RAW(session).Erast{49}];
   all_OM_dist = [all_OM_dist;RAW(session).Erast{50}];
   numbtrials= [numbtrials;length(RAW(session).Erast{11})];
end
totaltrials=sum(numbtrials);
figure;
b3=bar([mean(all_RD_dist),mean(all_OM_dist)],'FaceColor','flat')
ylim([0 200])
b3.CData(1,:)=RD;
b3.CData(2,:)=NoRD;
xticklabels({'Rewarded','Omitted'})
title('Rewarded vs Omission Distance From Lever')
all_hm_dist = [];
all_lm_dist = [];
numbtrials=[];
for session = 1:length(RAW)
   all_hm_dist = [all_hm_dist;RAW(session).Erast{51}];
   all_lm_dist = [all_lm_dist;RAW(session).Erast{52}];
   numbtrials= [numbtrials;length(RAW(session).Erast{11})];
end
totaltrials=sum(numbtrials);
figure;
b4=bar([mean(all_hm_dist),mean(all_lm_dist)],'FaceColor','flat')
ylim([0 200])
b4.CData(1,:)=hm;
b4.CData(2,:)=lm;
xticklabels({'High Motivation','Low Motivation'})
title('High vs Low Trial Distance')

all_RD_totdist = [];
all_OM_totdist = [];
numbtrials=[];
for session = 1:length(RAW)
   all_RD_totdist = [all_RD_totdist;RAW(session).Erast{54}];
   all_OM_totdist = [all_OM_totdist;RAW(session).Erast{55}];
   numbtrials= [numbtrials;length(RAW(session).Erast{11})];
end
totaltrials=sum(numbtrials);
figure;
b5=bar([mean(all_RD_totdist),mean(all_OM_totdist)],'FaceColor','flat')
ylim([0 3500])
b5.CData(1,:)=RD;
b5.CData(2,:)=NoRD;
xticklabels({'Rewarded','Omitted'})
title('Rewarded vs Omission Trial Distance Traveled')
all_hm_totdist = [];
all_lm_totdist = [];
numbtrials=[];
for session = 1:length(RAW)
   all_hm_totdist = [all_hm_totdist;RAW(session).Erast{56}];
   all_lm_totdist = [all_lm_totdist;RAW(session).Erast{57}];
   numbtrials= [numbtrials;length(RAW(session).Erast{11})];
end
totaltrials=sum(numbtrials);
figure;
b6=bar([mean(all_hm_totdist),mean(all_lm_totdist)],'FaceColor','flat')
ylim([0 3500])
b6.CData(1,:)=hm;
b6.CData(2,:)=lm;
xticklabels({'High Motivation','Low Motivation'})
title('High vs Low Trial Distance Traveled')

%% Spatial Density
%set center point
Xc=0;Yc=250;
%get animal coordinates for a session and remake into a num frames x 2
%array
trialtags={'All';'Rewarded';'Omitted'};
structnames=fieldnames(alltrials);
structnames=structnames([1,2,4]);
greenmap=[];counter=1;
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