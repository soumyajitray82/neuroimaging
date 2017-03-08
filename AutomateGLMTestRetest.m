%% Initialize
clear; close all;
dataPath='/Volumes/Project/fMRI/OCombinedProcessed/';
subject= ['sub-01' ; 'sub-02'; 'sub-03'; 'sub-04'; 'sub-05'; 'sub-06'; 'sub-07'; 'sub-08'; 'sub-09'; 'sub-10'];
types={'test' ; 'retest'};
tasks={'fingerfootlips' ; 'covertverbgeneration' ; 'overtverbgeneration' ; 'overtwordrepetition' ; 'linebisection'};
taskCond=[3 ; 1 ; 1 ; 1 ; 3]; 


%% Create model specifications and estimate
for taskInd=5 %:size(tasks,1) 
    for condInd=1:taskCond(taskInd)

        % Create job file
        fid=fopen([tasks{taskInd} '_' num2str(condInd) '_GLMTR.m'],'w');
        fprintf(fid,['matlabbatch{1}.spm.stats.factorial_design.dir = {''' dataPath 'MGroupStatsTR' '_' tasks{taskInd} '_' num2str(condInd) '''};\n']);
       
        for subInd=1:size(subject,1)
            fprintf(fid,['matlabbatch{1}.spm.stats.factorial_design.des.pt.pair(' num2str(subInd) ').scans = {\n']);
            fprintf(fid,['''' dataPath subject(subInd,:) '/ses-test/M' tasks{taskInd} '/con_000' num2str(condInd) '.nii,1''\n']);
            fprintf(fid,['''' dataPath subject(subInd,:) '/ses-retest/M' tasks{taskInd} '/con_000' num2str(condInd) '.nii,1''\n']);
            fprintf(fid,'};\n');
        end                                            
        fprintf(fid,'matlabbatch{1}.spm.stats.factorial_design.des.pt.gmsca = 0;');
        fprintf(fid,'matlabbatch{1}.spm.stats.factorial_design.des.pt.ancova = 0;');
        fprintf(fid,'matlabbatch{1}.spm.stats.factorial_design.cov = struct(''c'', {}, ''cname'', {}, ''iCFI'', {}, ''iCC'', {});');
        fprintf(fid,'matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct(''files'', {}, ''iCFI'', {}, ''iCC'', {});');
        fprintf(fid,'matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;');
        fprintf(fid,'matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;');
        fprintf(fid,'matlabbatch{1}.spm.stats.factorial_design.masking.em = {''''};');
        fprintf(fid,'matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;');
        fprintf(fid,'matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;');
        fprintf(fid,'matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;');
        fclose(fid);

        % Run job file for 'Specify first level'
        jobfile = {[tasks{taskInd} '_' num2str(condInd) '_GLMTR.m']};
        inputs = cell(0, 1);
        spm('defaults', 'FMRI');
        spm_jobman('run', jobfile, inputs{:});

        % Create job file for estimate
        fid=fopen([tasks{taskInd} '_' num2str(condInd) '_GLMTREstimate.m'],'w');
        fprintf(fid,['matlabbatch{1}.spm.stats.fmri_est.spmmat = {''' dataPath 'MGroupStatsTR' '_' tasks{taskInd} '_' num2str(condInd) '/SPM.mat''};']);
        fprintf(fid,'matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;');
        fprintf(fid,'matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;');
        fclose(fid);

        % Run job file for estimate
        jobfile = {[tasks{taskInd} '_' num2str(condInd) '_GLMTREstimate.m']};
        inputs = cell(0, 1);
        spm('defaults', 'FMRI');
        spm_jobman('run', jobfile, inputs{:});

    end
end




