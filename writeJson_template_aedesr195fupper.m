% Write temcaGT queue files based on section annotations using section
% masks that mark the edges of the other sections (such as knifemarks).

% If you can see the tissue directly and draw the imaging ROI directly for
% each section, don't use this script. 

% ATK 170703
% updated with some instructions ATK 200517 for aedes_r195

%% Update these files for each dataset:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%Set up tape and queue parameters
tapedir = 1; % negative is feed reel starts from high section numbers
flip = true; % whether or not a 180 degree flip is necessary for stainer images vs TEMCA. 
startSectionID = 27; % BUG - this code currently does not work with section 0 (due to 1-idx bs). 
endSectionID = 124;
skipList = []; % Insert section numbers to skip. All sections included need validated annotations.
write_json = 1; % Flag to write the queue file
plot_imgs = 1; % Flag to plot and save preview images
sectionList = startSectionID:endSectionID;
sectionList = setdiff(sectionList,skipList,'stable');
% master path should contain stainer images, masks and annotations folders, etc.
masterPath = '~/htem/temcagt/datasets/190311megAedes6Flower11Fupper_r195/roi_generation';

% ROI_mask_file drawed using the GUI 
ROI_mask_file = [masterPath '/masks/' 'ROI_mask_section4503.txt']; 

% section_mask_ref is the section_mask annotation from the section you
% produced the ROI mask on. Copy this from the annotations dir.
% eg. `cp annotations/SECTNUM.txt masks/section_mask_ref_SECTNUM.txt`
section_mask_ref_file = [masterPath '/masks/' 'section_mask_reference_sect4503.txt'];

% same slot mask as used in annotation GUI
slot_mask_file = [masterPath '/masks/' 'slot_mask.txt'];

% same section masks as used in annotation GUI
section_mask_file = [masterPath '/masks/' 'section_mask_aedes_km-brcoms.txt'];

% focus mask (if used). leave as [] if not used 
focus_mask_file = [];%[masterPath '/masks/' 'focus_mask.txt'];


%% DO NOT EDIT PAST HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set paths and load mask and image

% queue_output is name of queue json
queue_output = [masterPath '/queues/' date '_' num2str(startSectionID) '-' num2str(endSectionID) 'flipTRUE.json'];

% output of annotation, in txt
annotPath = [masterPath '/annotations']; % saves annotated relative positions to txt, for each individual section

% formatted stainer image links folder
imPath = [masterPath '/img_links']; % contains images of individual sections

% start writing json file (will continue in for loop over sections)
if write_json == 1
    fileID = fopen(queue_output,'wt');
    fprintf(fileID,'{');
end

%% Load Mask Files

% Get orig section mask vertices (masks format)
fid3 = fopen(ROI_mask_file);
section_mask_orig = dlmread(section_mask_file,' ',1,0);
section_mask_xy = [mean(section_mask_orig(:,1)),mean(section_mask_orig(:,2))];
section_mask_angle_ref = section_mask_orig(3,:)-section_mask_orig(2,:);
section_mask_angle = atan(section_mask_angle_ref(2)/section_mask_angle_ref(1));
fclose(fid3);

% Get model section mask COM and rotation (section annotation format)
fid = fopen(section_mask_ref_file, 'rt');
s = textscan(fid, '%s', 'delimiter', '\n');
idx3 = find(strcmp(s{1}, 'SECTION'), 1, 'first');
idx4 = find(strcmp(s{1}, 'NOITCES'), 1, 'first');
section_ref = dlmread(section_mask_ref_file,'',[idx3 0 idx4-2 1]);
idx = find(strcmp(s{1},'SECTIONCOM(x,y,theta):'), 1, 'first');
section_xyTH = dlmread(section_mask_ref_file,'',[idx 0 idx 2]);
%section_xy = section_xyTH(1:2);
section_xy = [mean(section_ref(:,1)),mean(section_ref(:,2))];
%section_angle = section_xyTH(3); %angles are not accurate!
section_angle_ref = section_ref(3,:)-section_ref(2,:);
section_angle = atan(section_angle_ref(2)/section_angle_ref(1));
% ATH 180625 but this needs to be relative

fclose(fid);

delta_xy = section_xy - section_mask_xy;
delta_angle = section_angle - section_mask_angle;

% Get ROI mask vertices (masks format)
fid2 = fopen(ROI_mask_file, 'rt');
ROI_ref = dlmread(ROI_mask_file,' ',1,0);
fclose(fid2);

% Rotate ROI back to ref mask
section_mask_calc = RotateMaskVertices(section_ref,delta_angle,section_xy)-delta_xy;%RotateMaskVertices(section_ref,-section_angle,section_xy)+delta_xy;
test = section_mask_calc - section_mask_orig;

% ROIvert_mask is the ROI in the original mask reference frame
ROIvert_mask = RotateMaskVertices(ROI_ref,-section_angle,section_xy)-delta_xy;

%% Set up figure (for annotation images)
if plot_imgs == 1
    scrn = get(0,'Screensize');
    hfig1 = figure('Position',[scrn(3)*0 scrn(4)*0 scrn(3)*1 scrn(4)*1],...% [50 100 1700 900]
        'Name','writeTestJson','ToolBar', 'none'); % 'MenuBar', 'none'
    hold off; axis off
    
    % init GUI drawing axes
    ax_pos = [0.1, 0.1, 0.8, 0.7];
    % setappdata(hfig,'ax_pos',ax_pos);
    figure(hfig1);
    h_ax = axes('Position',ax_pos);
    axis image
end
%% Parse annotation text files
% check for validation
problematic = zeros(length(sectionList),1);
verified = zeros(length(sectionList),1);
for i = 1:length(sectionList)
    f = fullfile(annotPath,[num2str(sectionList(i)),'.txt']);
    fid = fopen(f, 'rt');
    s = textscan(fid, '%s', 'delimiter', '\n');
    
    idx5 = find(strcmp(s{1}, 'FLAGS'), 1, 'first');
    flags = dlmread(f,'',[idx5+1 0 idx5+1 1]);
    problematic(i) = flags(1);
    verified(i) = 1;
    fclose(fid);
end

problems = sectionList(find(problematic==1));
unverified = sectionList(find(verified==0));

%sectionList = setdiff(sectionList,problems,'stable');

%disp(['Problem sections: ' num2str(problems)]);

if ~isempty(problems) > 0
    disp(['WARNING - problem sections: ' num2str(problems)]);
    disp('Adding them to the queue anyway...')
end

if ~isempty(unverified) > 0
    error(['Unverified sections: ' num2str(unverified)]);
end
%%
tf = [];
% start writing json file (will continue in for loop over sections)
if write_json == 1
    fileID = fopen(queue_output,'wt');
    fprintf(fileID,'{');
end

for i = 1:length(sectionList)
    
    %[S(sectionList(i)),tf(sectionList(i))] = ScanText_GTA(sectionList(i),annotPath,slot_mask_file,section_mask_file, focus_mask_file);
   
    f = fullfile(annotPath,[num2str(sectionList(i)),'.txt']);
    
    fid = fopen(f, 'rt');
    s = textscan(fid, '%s', 'delimiter', '\n');
    
    idx1 = find(strcmp(s{1}, 'SLOT'), 1, 'first');
    idx2 = find(strcmp(s{1}, 'TOLS'), 1, 'first');
    slot = dlmread(f,'',[idx1 0 idx2-2 1]);
    
    idx3 = find(strcmp(s{1}, 'SECTION'), 1, 'first');
    idx4 = find(strcmp(s{1}, 'NOITCES'), 1, 'first');
    section = dlmread(f,'',[idx3 0 idx4-2 1]);
    
    idx5 = find(strcmp(s{1}, 'FOCUS'), 1, 'first');
    idx6 = find(strcmp(s{1}, 'SUCOF'), 1, 'first');
    focus = [];
    hasFocus = 0;

    idx5 = find(strcmp(s{1}, 'FLAGS'), 1, 'first');
    flags = dlmread(f,'',[idx5+1 0 idx5+1 1]);
    isproblematic = flags(1);
    isverified = flags(2);
    fclose(fid);
    
    %% Determine scale and center of slot 
    num_pts = size(slot,1);     
    slot_center_pxl = sum(slot,1)/num_pts;
    pxl_size = 5.3; %um, point grey camera
    pxl_scale = 1000/pxl_size/1e6; % pxls per nm 

    %% Place ROI
    
    disp(['Sect ' num2str(sectionList(i)) ': ']);
    
    % Get ROI mask vertices (masks format)
    fid2 = fopen(ROI_mask_file, 'rt');
    ROI_ref = dlmread(ROI_mask_file,' ',1,0);
    fclose(fid2);
    
    % Rotate ROI back to ref mask
    ROIvert_mask = RotateMaskVertices(ROI_ref,delta_angle,section_xy)-delta_xy;      
    % ROIvert_mask is the ROI in the original mask reference frame26-Jun-2018_499-499_corner_2.json
    
    % Calculate section COM and angles
    xy = [mean(section(:,1)),mean(section(:,2))];
    relative_xy = xy - section_mask_xy;
    
    %section_angle = section_xyTH(3); %angles are not accurate!
    angle_ref = section(3,:)-section(2,:);
    angle = atan(angle_ref(2)/angle_ref(1));
    relative_angle = angle - section_mask_angle;

    % Rotate and translate vertices to match section mask
    % Rotation should be with respect to the section masks' COM
    ROIvert = RotateMaskVertices(ROIvert_mask,-relative_angle,section_mask_xy)+relative_xy;
    %ROIvert_nm = round((ROIvert-slot_center_pxl)./pxl_scale);

    % Focus point
    if hasFocus
        focus_pxl_x = focus(1,1)-slot_center_pxl(1);
        focus_pxl_y = focus(1,2)-slot_center_pxl(2);
        focus_nm = [focus_pxl_x,focus_pxl_y]/pxl_scale;
        focus_nm = -focus_nm;
        focus_nm = round(focus_nm);
    end
    
    %% Crop ROI to slot boundaries
    
    ROIpoly = polyshape(ROIvert(:,1), ROIvert(:,2));
    slotpoly = polyshape(slot(:,1),slot(:,2));
    ROI_crop_poly = intersect(ROIpoly, slotpoly);
    ROI_crop = ROI_crop_poly.Vertices;
    
    % Convert ROI to nm and slot-centric coordinates 
    ROInm = round((ROI_crop-slot_center_pxl)./pxl_scale); 
    
    if flip
        ROInm = -ROInm; % 180 degree rotation to match temcaGT vs staining image orientation.
    end
    
    % Calculate bounding box 
    right_edge_nm = max(ROInm(:,1)); 
    left_edge_nm = min(ROInm(:,1));
    top_edge_nm = min(ROInm(:,2)); % top is y smaller on scope
    bottom_edge_nm = max(ROInm(:,2));
    width_nm = right_edge_nm - left_edge_nm;
    height_nm = bottom_edge_nm - top_edge_nm;
    
    %% Write json entry
    if write_json == 1 && ~isproblematic%str2double(find_problematic(i))
        vertices=', "vertices": [';
        for vertex = ROInm'
            vertices=[vertices '[' num2str((vertex(1)-(right_edge_nm-width_nm))/width_nm) ', ' num2str((vertex(2)-top_edge_nm)/height_nm) '], '];
        end
        vertices=[vertices(1:length(vertices)-2) ']'];
        
        fprintf(fileID,['"' num2str(sectionList(i)) '": {"rois": [{"width": ' num2str(width_nm) ', "right": ' ...
            sprintf('%0.0f',right_edge_nm) ', "top": ' sprintf('%0.0f',top_edge_nm)...
            ', "height": ' num2str(height_nm) vertices '}]']);
        if hasFocus
            fprintf(fileID,[',"focus_points":[[' num2str(focus_nm(1)) ',' num2str(focus_nm(2)) ']]']);
        end
        fprintf(fileID,'}');
        if sectionList(i) == sectionList(end)
            fprintf(fileID,'}');
        else
            fprintf(fileID,', ');
        end
    end
    %% Plot and save annotation image
    
    if plot_imgs == 1
               
        im_raw = imread([imPath '/' num2str(sectionList(i)) '.png']);
        figure(hfig1);
        channel = 3; % blue channel seems to be the most informative
        num_levels = 20; % number of levels for histogram equalization
        A2 = histeq(im_raw(:,:,3),20);
        A1 = A2;
        imshow(A1,jet(225)); axis equal; axis off; hold on;
        hold on; 
        % plot slot center
        plot(slot_center_pxl(:,1),slot_center_pxl(:,2),'mo','Linewidth',3);
        
        if hasFocus
            plot(focus(:,1), focus(:,2), 'ro', 'Linewidth',4);
        end
        
        % plot section outline
        section_outline = vertcat(section, section(1,:));     
        plot(section_outline(:,1),section_outline(:,2),'w-','Linewidth',2); 
        
        % plot ROI outline
        ROI_outline = vertcat(ROI_crop, ROI_crop(1,:));
        plot(ROI_outline(:,1),ROI_outline(:,2),'r-','Linewidth',2)
        
        %plot slot outline
        pgon = polyshape((slot(:,1))',(slot(:,2))');
        plot(pgon,'FaceColor','none','EdgeColor','w','LineWidth', 2);

        timestamp = datetime('now');
        title(['sect ' num2str(sectionList(i)) ' ' datestr(timestamp)]);
        hold off;

        F = frame2im(getframe(hfig1));%im2frame(C);
        previewPath = fullfile(masterPath,'annot_imgs');
        if exist(previewPath,'dir')~=7
            mkdir(previewPath);
        end
        img_save_path = [previewPath '/' num2str(sectionList(i)) '.png'];
        
        imwrite(F,img_save_path);
    
    end
    
end
%% close json file
if write_json == 1
    fclose(fileID);
end

%% End of Script