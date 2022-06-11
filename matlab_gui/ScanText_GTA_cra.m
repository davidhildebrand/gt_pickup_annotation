function [S,tf] = ScanText_GTA(secID,outputPath,slot_mask_file,section1_mask_file,section2_mask_file,focus_mask_file)
tf = 0;
% scan in numbers
f = fullfile(outputPath,[num2str(secID),'.txt']);
% f = fullfile(outputPath,[num2str(secID,'%04d'),'.txt']);

% store info in struct
S = [];
S.secID = secID;

%%%%%%%%%%%%% hack %%%%%%%%%%%%%
if exist('slot_mask_file','var')
    S.slot_mask_file = slot_mask_file; % hack
end
if exist('section1_mask_file','var')
    S.section1_mask_file = section1_mask_file; % hack
end
if exist('section2_mask_file','var')
    S.section2_mask_file = section2_mask_file; % hack
end
if exist('focus_mask_file','var')
    S.focus_mask_file = focus_mask_file; % copied hack
end

if exist(f, 'file') == 2
    %try
        f = fullfile(outputPath,[num2str(secID),'.txt']);
        
        fid = fopen(f, 'rt');
        s = textscan(fid, '%s', 'delimiter', '\n');
        
        slot_start_line = find(strcmp(s{1}, 'SLOT'), 1, 'first');
        slot_end_line = find(strcmp(s{1}, 'TOLS'), 1, 'first');
        S.slot.vertices = dlmread(f,'',[slot_start_line 0 slot_end_line-2 1]);
        
        section1_start_line = find(strcmp(s{1}, 'SECTION1'), 1, 'first');
        section1_end_line = find(strcmp(s{1}, 'NOITCES1'), 1, 'first');
        S.section1.vertices = dlmread(f,'',[section1_start_line 0 section1_end_line-2 1]);
        
        section2_start_line = find(strcmp(s{1}, 'SECTION2'), 1, 'first');
        section2_end_line = find(strcmp(s{1}, 'NOITCES2'), 1, 'first');
        S.section2.vertices = dlmread(f,'',[section2_start_line 0 section2_end_line-2 1]);

        slot_COM_line = find(strcmp(s{1}, 'SLOTCOM(x,y,theta):'), 1, 'first');
        X = dlmread(f,' ',[slot_COM_line 0 slot_COM_line 2]);    
        S.slot.translation = [X(1,1),X(1,2)];
        S.slot.rotation = X(1,3);
        
        section1_COM_line = find(strcmp(s{1}, 'SECTION1COM(x,y,theta):'), 1, 'first');
        X = dlmread(f,' ',[section1_COM_line 0 section1_COM_line 2]);    
        S.section1.translation = [X(1,1),X(1,2)];
        S.section1.rotation = X(1,3);
        
        section2_COM_line = find(strcmp(s{1}, 'SECTION2COM(x,y,theta):'), 1, 'first');
        X = dlmread(f,' ',[section2_COM_line 0 section2_COM_line 2]);    
        S.section2.translation = [X(1,1),X(1,2)];
        S.section2.rotation = X(1,3);
        
        flags_line = find(strcmp(s{1}, 'FLAGS'), 1, 'first');
        X = dlmread(f,' ',[flags_line+1 0 flags_line+1 1]);
        S.is_problematic = X(1,1);
        S.is_verified = X(1,2);
        
        tf = 1;
    
else % txt file doesn't exist
    S.slot.vertices = [];
    S.slot.translation = [0,0];
    S.slot.rotation = 0;
    S.section1.vertices = [];
    S.section1.translation = [0,0];
    S.section1.rotation = 0;
    S.section2.vertices = [];
    S.section2.translation = [0,0];
    S.section2.rotation = 0;
    S.focus.vertices = [];
    S.is_problematic = 0;
    S.is_verified = 0;
end

end