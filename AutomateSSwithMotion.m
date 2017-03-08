%% Initialize
clear; close all;
dataPath='/Volumes/Project/fMRI/OCombinedProcessed/';
subject= ['sub-01' ; 'sub-02'; 'sub-03'; 'sub-04'; 'sub-05'; 'sub-06'; 'sub-07'; 'sub-08'; 'sub-09'; 'sub-10'];
types={'test' ; 'retest'};
tasks={'fingerfootlips' ; 'covertverbgeneration' ; 'overtverbgeneration' ; 'overtwordrepetition' ; 'linebisection'};
taskFrames=[184 ; 173 ; 88 ; 76 ; 238]; 

% Create conditions file for covertverbgeneration task
names=cell(1,1);
onsets=cell(1,1);
durations=cell(1,1);
names{1}='covertverbgeneration';
onsets{1}=[10 70 130 190 250 310 370];
durations{1}=[30 30 30 30 30 30 30];
save('covertverbgeneration.mat','names','onsets','durations');

% Create conditions file for overtverbgeneration task
names=cell(1,1);
onsets=cell(1,1);
durations=cell(1,1);
names{1}='overtverbgeneration';
onsets{1}=[20 80 140 200 260 320 380];
durations{1}=[30 30 30 30 30 30 30];
save('overtverbgeneration.mat','names','onsets','durations');

% Create conditions file for overtwordrepetition task
names=cell(1,1);
onsets=cell(1,1);
durations=cell(1,1);
names{1}='overtwordrepetition';
onsets{1}=[20 80 140 200 260 320];
durations{1}=[30 30 30 30 30 30];
save('overtwordrepetition.mat','names','onsets','durations');

% Create conditions file for fingerfootlips task
names=cell(1,3);
onsets=cell(1,3);
durations=cell(1,3);
names{1}='finger';
names{2}='foot';
names{3}='lips';
onsets{1}=[10 100 190 280 370];
onsets{2}=[40 130 220 310 400];
onsets{3}=[70 160 250 340 430];
durations{1}=[15 15 15 15 15];
durations{2}=[15 15 15 15 15];
durations{3}=[15 15 15 15 15];
save('fingerfootlips.mat','names','onsets','durations');

%% Create conditions for linebisection task
for subjInd=1:10
    for typeInd=1:2
        % Path for linebisection tsv file for the particular subject and type
        filePath=[dataPath subject(subjInd,:) '/ses-' types{typeInd} '/func/' subject(subjInd,:) '_ses-' types{typeInd} '_task-linebisection_events.tsv'];
        
        % Path for output file for the conditions for linebisection task
        oFilePath=[dataPath subject(subjInd,:) '/ses-' types{typeInd} '/func/' subject(subjInd,:) '-' types{typeInd} '-linebisection_conditions.mat'];
        
        % Path for storing the unique events in a text file
        eventFilePath=[dataPath subject(subjInd,:) '/ses-' types{typeInd} '/func/' subject(subjInd,:) '-' types{typeInd} '-linebisection_events.txt'];
        
        % Read the linebisection tsv file containing conditions data
        fid=fopen(filePath,'r');
        fileData=textscan(fid, '%f %f %f %s' ,'HeaderLines',1,'Delimiter',' ');
        fclose(fid);
        
        % Extract lists of event labels, times and durations
        eventLabels=char(fileData{1,4});
        times=fileData{1,1};
        taskDur=fileData{1,2};
        
        % Identify unique events
        uniqueEvents=unique(eventLabels,'rows');

        % Initialize output variables to be written to the file
        names=cell(1,size(uniqueEvents,1));
        onsets=cell(1,size(uniqueEvents,1));
        durations=cell(1,size(uniqueEvents,1));
        
        % Create times and duration list for each unique event
        % Store the unique event labels in a file
        fid=fopen(eventFilePath,'w');
        for eventInd=1:size(uniqueEvents,1)
            fprintf(fid,[uniqueEvents(eventInd,:) '\n']);
            names{eventInd}=uniqueEvents(eventInd,:);
            onsets{eventInd}=[];
            durations{eventInd}=[];
            
            for timeInd=1:size(fileData{1,1},1)
                if eventLabels(timeInd,:)==uniqueEvents(eventInd,:)
                    onsets{eventInd}=[onsets{eventInd} times(timeInd)];
                    durations{eventInd}=[durations{eventInd} taskDur(timeInd)];
                end
            end
        end
        fclose(fid);
        
        % Create the conditions file 
        save(oFilePath,'names','onsets','durations');
        
    end
end

%% Create model specifications and estimate
for taskInd=5 %:size(tasks,1) 
    for subjInd=1:size(subject,1) % Cycle through all the subjects
        for typeInd=1:size(types,1) % Cycle through 'test' and 'retest' data
            if(exist([dataPath subject(subjInd,:) '/ses-' types{typeInd} '/MMR' tasks{taskInd}],'file'))
                continue;
            end
            display(subjInd);
            % Create job file for 'Specify first level'
            fid=fopen([subject(subjInd,:) '_' types{typeInd} '_' tasks{taskInd} '_1stLevJob.m'],'w');
            fprintf(fid,['matlabbatch{1}.spm.stats.fmri_spec.dir = {''' dataPath subject(subjInd,:) '/ses-' types{typeInd} '/MMR' tasks{taskInd} '''}\n']);
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_spec.timing.units = ''secs'';\n');
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 2.5;\n');
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;\n');
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;\n');
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_spec.sess.scans = {\n');
            for frames=1:taskFrames(taskInd)
                fprintf(fid,['''' dataPath subject(subjInd,:) '/ses-' types{typeInd} '/func/sw' subject(subjInd,:) '_ses-' types{typeInd} '_task-' tasks{taskInd} '_bold.nii,' num2str(frames) '''\n']);
            end
            fprintf(fid,'};\n');
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_spec.sess.cond = struct(''name'', {}, ''onset'', {}, ''duration'', {}, ''tmod'', {}, ''pmod'', {}, ''orth'', {});\n');
            if taskInd==5
                oFilePath=[dataPath subject(subjInd,:) '/ses-' types{typeInd} '/func/' subject(subjInd,:) '-' types{typeInd} '-linebisection_conditions.mat'];
                fprintf(fid,['matlabbatch{1}.spm.stats.fmri_spec.sess.multi = {''' oFilePath '''};\n']);
            else
                fprintf(fid,['matlabbatch{1}.spm.stats.fmri_spec.sess.multi = {''' tasks{taskInd} '.mat''};\n']);
            end
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_spec.sess.regress = struct(''name'', {}, ''val'', {});\n');
            % rp_sub-01_ses-test_task-fingerfootlips_bold.txt
            fprintf(fid,['matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {''' dataPath subject(subjInd,:) '/ses-' types{typeInd} '/func/rp_' subject(subjInd,:) '_ses-' types{typeInd} '_task-' tasks{taskInd} '_bold.txt''};\n']);
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = 128;\n');
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_spec.fact = struct(''name'', {}, ''levels'', {});\n');
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];\n');
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_spec.volt = 1;\n');
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_spec.global = ''None'';\n');
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;\n');
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_spec.mask = {''''};\n');
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_spec.cvi = ''AR(1)'';\n');
            fclose(fid);

            % Run job file for 'Specify first level'
            jobfile = {[subject(subjInd,:) '_' types{typeInd} '_' tasks{taskInd} '_1stLevJob.m']};
            inputs = cell(0, 1);
            spm('defaults', 'FMRI');
            spm_jobman('run', jobfile, inputs{:});

            % Create job file for estimate
            fid=fopen([subject(subjInd,:) '_' types{typeInd} '_' tasks{taskInd} '_EstimateJob.m'],'w');
            fprintf(fid,['matlabbatch{1}.spm.stats.fmri_est.spmmat = {''' dataPath subject(subjInd,:) '/ses-' types{typeInd} '/MMR' tasks{taskInd} '/SPM.mat''};']);
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;');
            fprintf(fid,'matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;');
            fclose(fid);

            % Run job file for estimate
            jobfile = {[subject(subjInd,:) '_' types{typeInd} '_' tasks{taskInd} '_EstimateJob.m']};
            inputs = cell(0, 1);
            spm('defaults', 'FMRI');
            spm_jobman('run', jobfile, inputs{:});

         end
    end
end


% Create contrasts for all
for taskInd=5 %:size(tasks,1) 
    for subjInd=1:size(subject,1) % Cycle through all the subjects
        for typeInd=1:size(types,1) % Cycle through 'test' and 'retest' data
            
            fid=fopen([subject(subjInd,:) '_' types{typeInd} '_' tasks{taskInd} '_contrasts.m'],'w');
            fprintf(fid,['matlabbatch{1}.spm.stats.con.spmmat = {''' dataPath subject(subjInd,:) '/ses-' types{typeInd} '/MMR' tasks{taskInd} '/SPM.mat''};']);
            
            switch taskInd
                case 1 % fingergfootlips task
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = ''finger'';');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [1 0 0];');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = ''none'';');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{2}.tcon.name = ''foot'';');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = [0 1 0];');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{2}.tcon.sessrep = ''none'';');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{3}.tcon.name = ''lips'';');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{3}.tcon.weights = [0 0 1];');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{3}.tcon.sessrep = ''none'';');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.delete = 0;');
                case 2 % covertverbgeneration task
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = ''covertverbgeneration'';');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [1 0];');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = ''none'';');
                case 3 % overtverbgeneration task
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = ''overtverbgeneration'';');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [1 0];');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = ''none'';');
                case 4 % overtwordrepetition task
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = ''overtwordrepetition'';');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [1 0];');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = ''none'';');
                case 5 % Linebisection task
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = ''Correct_Task'';');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [1 0 0 0 0];');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = ''none'';');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{2}.tcon.name = ''Response_Control'';');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = [0 0 0 0 1];');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{2}.tcon.sessrep = ''none'';');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{3}.tcon.name = ''CT_RC'';');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{3}.tcon.weights = [1 0 0 0 -1];');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.consess{3}.tcon.sessrep = ''none'';');
                    fprintf(fid,'matlabbatch{1}.spm.stats.con.delete = 0;');
            end
            fclose(fid);
            
            jobfile = {[subject(subjInd,:) '_' types{typeInd} '_' tasks{taskInd} '_contrasts.m']};
            inputs = cell(0, 1);
            spm('defaults', 'FMRI');
            spm_jobman('run', jobfile, inputs{:});
            
        end
    end
end

