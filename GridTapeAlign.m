function hfig = GridTapeAlign
%% Make figure
scrn = get(0,'Screensize');
hfig = figure('Position',[scrn(3)*0 scrn(4)*0 scrn(3)*1 scrn(4)*1],...% [50 100 1700 900]
    'Name','GridTapeAlign','DeleteFcn',@closefigure_Callback,...
    'KeyPressFcn',@KeyPressCallback,...
    'WindowButtonDownFcn',@WindowButtonDownCallback,...
    'ToolBar', 'none'); % 'MenuBar', 'none'
hold off; axis off

% init GUI drawing axes
%ax_pos = [0.1, 0.1, 0.8, 0.7];
% setappdata(hfig,'ax_pos',ax_pos);
figure(hfig); axis image

%% Initialize no-data state
setappdata(hfig,'dataPath','');
setappdata(hfig,'outputPath','');
setappdata(hfig,'imPath','');    

% Default masks
setappdata(hfig,'slot_mask_file','masks/slot_mask.txt');
setappdata(hfig,'ROI_mask_file','masks/ROI_mask.txt');
slot_mask_name = 'slot_mask.txt';
ROI_mask_name = 'ROI_mask.txt';

% dataSet loaded successfully flag
setappdata(hfig,'dataLoaded',false);

%% Create UI controls
set(gcf,'DefaultUicontrolUnits','normalized'); 
set(gcf,'defaultUicontrolBackgroundColor',[1 1 1]);

% tab group setup
tgroup = uitabgroup('Parent', hfig, 'Position', [0.05,0.86,0.91,0.14]);
numtabs = 2;
tab = cell(1,numtabs);
M_names = {'General','Queues - TODO'};
for i = 1:numtabs
    tab{i} = uitab('Parent', tgroup, 'BackgroundColor', [1,1,1], 'Title', M_names{i});
end

% grid setup, to help align display elements
rheight = 0.2;
yrow = .8:-.2:0;%.75:-.25:0;
disp(yrow)
dTextHt = 0.05; % dTextHt = manual adjustment for 'text' controls:
% (vertical alignment is top instead of center like for all other controls)
bwidth = 0.03;
grid = 0:bwidth+0.001:1;

%% handles
global h_i_im h_secID h_datadir h_slot_mask h_ROI_mask h_probflag h_verflag h_status 

%% UI ----- tab one ----- (General)
i_tab = 1;

%% UI row 1: datasetDir
i_row = 1; i = 1; n = 0;

i=i+n; n=2; % getdataDir pushbutton
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Set dataset dir',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_getdatadir_Callback);

i=i+n; n=12; % dataDir textbox
h_datadir = uicontrol('Parent',tab{i_tab},'Style','edit',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'String','Select Data Dir','enable', 'off');
    
%% UI row 2: masks
i_row = 2; i = 1; n = 0;
i=i+n; n=2; % Set ROI mask dir pushbutton
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Set ROI mask',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_getROImasksdir_Callback, 'BackgroundColor',[0,1,0]);
i=i+n; n=6; % ROI mask text box
h_ROI_mask = uicontrol('Parent',tab{i_tab},'Style','edit',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'String',ROI_mask_name,'enable', 'off');
i=i+n; n=2; % Get mask dir pushbutton
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Set slot mask',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_getSLOTmasksdir_Callback, 'BackgroundColor',[0,1,1]);
i=i+n; n=6; % Slot mask text box
h_slot_mask = uicontrol('Parent',tab{i_tab},'Style','edit',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'String',slot_mask_name,'enable', 'off');
%% UI row 3: current section
i_row = 3; i = 1;n = 0;

i=i+n; n=2; % Section count label
uicontrol('Parent',tab{i_tab},'Style','text','String','Section count:',...
    'Position',[grid(i) yrow(i_row)-dTextHt bwidth*n rheight],'HorizontalAlignment','right');

i=i+n; n=2; % Section count box 
h_i_im = uicontrol('Parent',tab{i_tab},'Style','edit',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@edit_imageCount_Callback);

i=i+n; n=2; % Section ID label
uicontrol('Parent',tab{i_tab},'Style','text','String','Section ID:',...
    'Position',[grid(i) yrow(i_row)-dTextHt bwidth*n rheight],'HorizontalAlignment','right');

i=i+n; n=2; % Section ID box
h_secID = uicontrol('Parent',tab{i_tab},'Style','edit',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@edit_secID_Callback);

i=i+n+1; n=3; % Previous section pushbutton
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Previous(''Shift+rClick'')',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_loadPreviousImage_Callback);

i=i+n; n=3; % Next section pushbutton
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Next(''Right Click'')',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_loadNextImage_Callback);

i=i+n; n=2; % Reset masks pushbutton
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Reset Masks',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_resetMasks_Callback);

%% UI row 4: create masks, and flags
i_row = 4; i = 1; n = 0;

i=i+n; n = 4; % Make new slot masks button
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Make new slot mask',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_createSlotMask_Callback);

i=i+n; n = 4; %  Make new ROI mask button
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Make new ROI mask',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_createSectionMask_Callback);

i=i+n; n = 3; % Problematic checkbox
h_probflag = uicontrol('Parent',tab{i_tab},'Style','checkbox','String','problematic?','Value',0,...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@checkbox_isProblematicFlag_Callback);

i=i+n; n = 3; % Verified checkbox
h_verflag = uicontrol('Parent',tab{i_tab},'Style','checkbox','String','verified?','Value',0,...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@checkbox_isVerifiedFlag_Callback);

%% UI row 5: status messages
i_row = 5;i = 1; n = 12; % Status Text
h_status = uicontrol('Parent',tab{i_tab},'Style','text','String','STATUS:',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight]);
end

%% Callback functions for UI elements:

%% ----- tab one ----- (General)

%% row 1: file navigation
function pushbutton_getdatadir_Callback(hObject,~)
    hfig = getParentFigure(hObject);
    start_path = getappdata(hfig,'dataPath');
    if isempty(start_path) 
        gt_dir = '/n/groups/htem/temcagt/datasets';
        if exist(gt_dir,'dir')
            start_path = gt_dir;
        end
    end
    folder_name = uigetdir(start_path,'Choose dataset folder');

    global h_datadir h_status
    folder_name = CheckDataDir(folder_name);

    if folder_name~=0
        h_datadir.String = folder_name;
        setappdata(hfig,'dataPath',folder_name);   
        setappdata(hfig,'imPath',[folder_name '/img_links']);
        setappdata(hfig,'outputPath',[folder_name '/annotations']);  
        ParseImageDir(hfig,getappdata(hfig,'imPath'));
        loadFirstSection(hfig);     
        setappdata(hfig,'dataLoaded',true);
        % try to load masks from datadir
        ROI_mask_file = [folder_name '/masks/ROI_mask.txt'];
        if exist(ROI_mask_file,'file')
            setappdata(hfig, 'ROI_mask_file', ROI_mask_file);
        end
        slot_mask_file = [folder_name '/masks/slot_mask.txt'];
        disp(slot_mask_file);
        if exist(slot_mask_file,'file')
            setappdata(hfig, 'slot_mask_file', slot_mask_file);
        end
        try 
            LoadNewMask(hfig,slot_mask_file,ROI_mask_file);
            hpoly = getappdata(hfig,'hpoly');
            delete(hpoly);
            DrawNewMask(hfig)
            h_status.String = 'STATUS: Dataset and defauly masks loaded';
        catch 
            h_status.String = 'STATUS: Dataset loaded';
        end
    end
end

function pushbutton_getROImasksdir_Callback(hObject,~)
    hfig = getParentFigure(hObject);
    start_path = fullfile(getappdata(hfig,'dataPath'),'*.txt');
    [FileName2,PathName] = uigetfile(start_path,'Select the txt file for ROI mask');
    ROI_mask_file = fullfile(PathName,FileName2);
    slot_mask_file = getappdata(hfig, 'slot_mask_file');
    if getappdata(hfig,'dataLoaded') == false
        errordlg('Masks cannot be loaded before dataset');
    else
        if isequal(FileName2,0)
            disp('User selected Cancel')
        else
            try
                LoadNewMask(hfig,slot_mask_file,ROI_mask_file);
                DrawNewMask(hfig)
                % reload current image
                i_im = getappdata(hfig,'i_im'); 
                LoadImage(hfig,i_im);       
                % (set path if didn't crash)
                setappdata(hfig,'ROI_mask_file',ROI_mask_file);
            catch
                errordlg('failed to load new masks');
            end
        end
    end
end

function pushbutton_getSLOTmasksdir_Callback(hObject,~)
    hfig = getParentFigure(hObject);
    start_path = fullfile(getappdata(hfig,'dataPath'),'*.txt');
    [FileName1,PathName] = uigetfile(start_path,'Select the txt file for slot mask');
    slot_mask_file = fullfile(PathName,FileName1);
    ROI_mask_file = getappdata(hfig, 'ROI_mask_file');
    if getappdata(hfig,'dataLoaded') == false
        errordlg('Masks cannot be loaded before dataset');
    else
        if isequal(FileName1,0) 
            disp('User selected Cancel')
        else
            try
                LoadNewMask(hfig,slot_mask_file,ROI_mask_file);
                DrawNewMask(hfig)
                % reload current image
                i_im = getappdata(hfig,'i_im'); 
                LoadImage(hfig,i_im);        
                % (set path if didn't crash)
                setappdata(hfig,'slot_mask_file',slot_mask_file);
            catch
                errordlg('failed to load new masks');
            end
        end
    end
end

function loadFirstSection(hObject,~)
    hfig = getParentFigure(hObject);
    i_im = 1;
    setappdata(hfig,'i_im',i_im);
    secID = GetSectionIDfromCounter(hfig,i_im);
    P = LoadPaths(hfig);
    S = ScanText_GTA(secID,P.outputPath,P.slot_mask_file,P.ROI_mask_file);
    setappdata(hfig,'S',S);
    LoadImage(hfig,getappdata(hfig, 'i_im'));
%LoadNewMask(hfig,P.slot_mask_file,P.ROI_mask_file);
end

%% row 2: current section
function edit_imageCount_Callback(hObject,~)
hfig = getParentFigure(hObject);
% get/format range
str = get(hObject,'String');
if ~isempty(str),
    C = textscan(str,'%d');
    i_im = C{1}; % C{:};
    LoadImage(hfig,i_im);
end
end

function edit_secID_Callback(hObject,~)
hfig = getParentFigure(hObject);
% get/format range
str = get(hObject,'String');
if ~isempty(str),
    C = textscan(str,'%d');
    secID = C{1}; % C{:};
    
    i_im = GetCounterFromSectionID(hfig,secID);
    LoadImage(hfig,i_im);
end
end

function pushbutton_loadPreviousImage_Callback(hObject,~)
hfig = getParentFigure(hObject);
LoadPreviousImage(hfig);
end

function pushbutton_loadNextImage_Callback(hObject,~)
hfig = getParentFigure(hObject);
LoadNextImage(hfig);
end

function pushbutton_resetMasks_Callback(hObject,~)
hfig = getParentFigure(hObject);
slot_mask_file = getappdata(hfig,'slot_mask_file');
ROI_mask_file = getappdata(hfig,'ROI_mask_file');
hpoly = getappdata(hfig,'hpoly');
delete(hpoly);
LoadNewMask(hfig,slot_mask_file,ROI_mask_file);
DrawNewMask(hfig)
end

%% row 3: create masks, flags

function pushbutton_createSlotMask_Callback(hObject,~)
hfig = getParentFigure(hObject);
h = impoly;
setColor(h,[1 1 1]);
wait(h); % double click to finalize position!
setColor(h,[0 0 1]);

pos = getPosition(h);

% save to file
[file,path] = uiputfile('slot_mask.txt','Save file name');

% write to file
f = fullfile(path,file);
setappdata(hfig,'slot_mask_file',f);

% (write to txt)
fileID = fopen(f,'wt');
fprintf(fileID,'%s\n','row: vertices; col: x & y coordinate');
for i = 1:size(pos,1)
    formatSpec = '%4.2f %4.2f\n';
    fprintf(fileID,formatSpec,pos(i,1),pos(i,2));
end
fclose(fileID);
end

function pushbutton_createSectionMask_Callback(hObject,~)
hfig = getParentFigure(hObject);
h = impoly;
setColor(h,[1 1 1]);
wait(h); % double click to finalize position!
% update finalized polygon in red color
setColor(h,[0 0 1]);

pos = getPosition(h);

% save to file
[file,path] = uiputfile('ROI_mask.txt','Save file name');

% write to file
f = fullfile(path,file);
setappdata(hfig,'ROI_mask_file',f);

% (write to txt)
fileID = fopen(f,'wt');
fprintf(fileID,'row: vertices; col: x & y coordinate\n');
for i = 1:size(pos,1)
    formatSpec = '%4.2f %4.2f\n';
    fprintf(fileID,formatSpec,pos(i,1),pos(i,2));
end
fclose(fileID);
end

function checkbox_isProblematicFlag_Callback(hObject,~)
hfig = getParentFigure(hObject);
S = getappdata(hfig,'S');
S.is_problematic = get(hObject,'Value');
setappdata(hfig,'S',S);
end

function checkbox_isVerifiedFlag_Callback(hObject,~)
hfig = getParentFigure(hObject);
S = getappdata(hfig,'S');
S.is_verified = 1; %S.is_verified = get(hobject,'Value;);
setappdata(hfig,'S',S);
end

%% UI-level functions

function KeyPressCallback(hfig, event)
global h_probflag h_verflag
masktypeID = getappdata(hfig,'masktypeID');
if strcmp(event.Key,'space')
    % switch between mask types (slot vs section)
    hpoly = getappdata(hfig,'hpoly');
    pos = getPosition(hpoly(masktypeID));
    if masktypeID == 1
        setappdata(hfig,'mpos1',{masktypeID pos})
        test = getappdata(hfig,'mpos1');
    else
        setappdata(hfig,'mpos2',{masktypeID pos})
        test = getappdata(hfig,'mpos2');
    end
    masktypeID = ToggleSelectedMask(hfig);

elseif strcmp(event.Key,'j')
    % Move current mask to the last positon of the previous mask
    hpoly = getappdata(hfig,'hpoly');
    if masktypeID == 1
        m1pos = getappdata(hfig,'mpos1') 
        m1pos = m1pos(2)
        setConstrainedPosition(hpoly(masktypeID),m1pos{1});
        setappdata(hfig,'hpoly',hpoly);
    else
        m2pos = getappdata(hfig,'mpos2') 
        m2pos = m2pos(2)
        setConstrainedPosition(hpoly(masktypeID),m2pos{1});
        setappdata(hfig,'hpoly',hpoly);
    end
    % flags
elseif strcmp(event.Key,'p') % check 'is_problematic' flag
    h_probflag.Value = 1;
    S = getappdata(hfig,'S');
    S.is_problematic = 1;
    setappdata(hfig,'S',S);

elseif strcmp(event.Key,'v') % check 'is_verified' flag    
    h_verflag.Value = 1;
    S = getappdata(hfig,'S');
    S.is_verified = 1;
    setappdata(hfig,'S',S);
    
    % Translations

elseif strcmp(event.Key,'a') % translation: left
    translationArray = [-1,0];
    TranslateMask(hfig,translationArray,masktypeID);
    
elseif strcmp(event.Key,'d') % translation: right
    translationArray = [1,0];
    TranslateMask(hfig,translationArray,masktypeID);
    
elseif strcmp(event.Key,'w') % translation: up
    translationArray = [0,-1];
    TranslateMask(hfig,translationArray,masktypeID);
    
elseif strcmp(event.Key,'s') % translation: down
    translationArray = [0,1];
    TranslateMask(hfig,translationArray,masktypeID);
    
    % Rotations
    
elseif strcmp(event.Key,'q') % rotation: counter-clockwise
    rotationAngle = 0.005;
    RotateMask(hfig,rotationAngle,masktypeID);
    
elseif strcmp(event.Key,'e') % translation: clockwise
    rotationAngle = -0.005;
    RotateMask(hfig,rotationAngle,masktypeID);
elseif strcmp(event.Key,'z') % undo last rotation/translation
    hpoly = getappdata(hfig,'hpoly')
    lpos = getappdata(hfig,'lastpos')
    setConstrainedPosition(hpoly(masktypeID),lpos);
    setappdata(hfig,'hpoly',hpoly);
end
end

function WindowButtonDownCallback(hfig, event)
seltype = get(gcf,'SelectionType');
switch seltype
    case 'extend' % Shift-click
        LoadPreviousImage(hfig);
    case 'alt' % RightClick/Control-click
        LoadNextImage(hfig);
        %     case 'open' % double left click
        %         disp(['double'])
        %     case 'normal' % normal single left click
        %         disp(['normal'])
end
end

function closefigure_Callback(hfig,~)
if getappdata(hfig, 'dataLoaded') == true
    SaveCurrentMasks(hfig);
end

global EXPORT_autorecover;
EXPORT_autorecover = getappdata(hfig);
end

%% Helper functions

function Paths = LoadPaths(hfig)
Paths = struct;
Paths.dataPath = getappdata(hfig,'dataPath');
Paths.outputPath = getappdata(hfig,'outputPath');
Paths.imPath = getappdata(hfig,'imPath');
Paths.slot_mask_file = getappdata(hfig,'slot_mask_file');
Paths.ROI_mask_file = getappdata(hfig,'ROI_mask_file');
end

function folder = CheckDataDir(folder_name)
    global h_status
    if ~exist(folder_name,'dir')
        h_status.String = 'ERROR: data dir does not exist';
        folder = '';
    elseif ~exist([folder_name '/img_links'], 'dir')
        h_status.String = 'ERROR: img_links folder does not exist';
        folder = '';
    elseif ~exist([folder_name '/annotations'], 'dir')
        h_status.String = 'ERROR: annotations folder does not exist';
        folder = '';
    else
        h_status.String = 'STATUS: Data dir loaded';
        folder = folder_name;
    end
end

function ParseImageDir(hfig,imPath)
setappdata(hfig,'imPath',imPath);
imList = dir(fullfile(imPath, '*png')); %needs to be changed from png to tif for vnc1
numFiles = length(imList);

fileIDs = zeros(numFiles,1);
% validIX = 1:numFiles0;
try
    for i = 1:numFiles
        a = imList(i).name;
        if length(a)>12 && strcmp(a(end-11:end),'_section.png')
            str = a(end-15:end-12);
            if str(1)=='_'
                str(1) = [];
            end
            C = textscan(str,'%d');
            fileIDs(i) = C{1};
        else
            %     if strcmp(a(end-3:end),'.png')
            str = a(1:end-4);
            C = textscan(str,'%d');
            fileIDs(i) = C{1};
            
            %     else
            %         validIX(i) = 0;
            %         disp(['fLiile ''',a,''' does not match expected file name format']);
        end
    end
catch
    errordlg('folder contains files with unexpected file names');
end
% numFiles = length(find(validIX));
[sectionIDs,IX] = sort(fileIDs);

List = [];
List.filenames = {imList(IX).name}';
List.sectionIDs = sectionIDs;

setappdata(hfig,'List',List);
setappdata(hfig,'numFiles',numFiles);
end

function secID = GetSectionIDfromCounter(hfig,i_im)
List = getappdata(hfig,'List');
secID = List.sectionIDs(i_im);
setappdata(hfig,'secID',secID);
end

function i_im = GetCounterFromSectionID(hfig,secID)
List = getappdata(hfig,'List');
i_im = find(ismember(List.sectionIDs,secID),1,'first');
if ~isempty(i_im)
    setappdata(hfig,'i_im',i_im);
else
    i_im = getappdata(hfig,'i_im');
    disp('section ID invalid - image not found');
end
end

function SaveCurrentMasks(hfig)
S = getappdata(hfig,'S');
secID = getappdata(hfig,'secID');
outputPath = getappdata(hfig,'outputPath');

% update current pos stored in M (in case of unrecorded dragging of ROI)
M = getappdata(hfig,'M');
hpoly = getappdata(hfig,'hpoly');
masktypeID = getappdata(hfig,'masktypeID');
if ~isempty(hpoly) % (first load exception)
    M(masktypeID).pos = getPosition(hpoly(masktypeID));
    setappdata(hfig,'M',M);
end

% update S data (relangle is updated directly through Rotation function)
S.slot.translation = GetCenterPos(M(1).pos) - GetCenterPos(M(1).pos_init);
S.section.translation = GetCenterPos(M(2).pos) - GetCenterPos(M(2).pos_init);
setappdata(hfig,'S',S);

% write to text file
WriteToText_GTA(secID,S,M,outputPath);
end

function LoadImage(hfig,i_im)
% save mask positions for previous image
if getappdata(hfig,'dataLoaded') == true
    SaveCurrentMasks(hfig);
end 

% load new file
setappdata(hfig,'i_im',i_im); % set new image index
secID = GetSectionIDfromCounter(hfig,i_im);

% try to load txt data, if exist (otherwise just init)
outputPath = getappdata(hfig,'outputPath');
slot_mask_file = getappdata(hfig,'slot_mask_file');
ROI_mask_file = getappdata(hfig,'ROI_mask_file');
[S,tf] = ScanText_GTA(secID,outputPath,slot_mask_file,ROI_mask_file);
setappdata(hfig,'S',S);

%% update GUI
global h_i_im;
h_i_im.String = num2str(i_im);

global h_secID;
h_secID.String = num2str(secID);

% load new image
imPath = getappdata(hfig,'imPath');
List = getappdata(hfig,'List');
im_raw = imread(fullfile(imPath,List.filenames{i_im}));

%% draw image
% clean-up canvas
allAxesInFigure = findall(hfig,'type','axes');
if ~isempty(allAxesInFigure),
    delete(allAxesInFigure);
end
axes(gca);

% Preprocess image to make easier to see edges
%left_crop = 0; %1 for vnc1
%right_crop = 1000; %1012 for vnc1
%top_crop = 1;
%bottom_crop = 500;
channel = 3; % blue channel seems to be the most informative
num_levels = 20; % number of levels for histogram equalization
%imshow(histeq(im_raw(top_crop:bottom_crop,left_crop:right_crop),20),jet(255));
%imshow(histeq(im_raw(:,:,3),20),jet(255));
imagesc(im_raw);
axis equal; axis off
% setappdata(hfig,'im_raw',im_raw);
% setappdata(hfig,'h_ax',h_ax);

%% set flags and set pos from file
global h_probflag h_verflag

% setup mask position from info saved in S
if tf % (if annotation file exists)
    %disp([num2str(i_im),': sectionID = ',num2str(secID)]);
    S = getappdata(hfig,'S');

    pos_slot_init = dlmread(slot_mask_file,' ',1,0);
    pos_section_init = dlmread(ROI_mask_file,' ',1,0);
    % init mask struct
    M = [];
    
    masktypeID = 1;
    M(masktypeID).pos_init = pos_slot_init;
    
    masktypeID = 2;
    M(masktypeID).pos_init = pos_section_init;
    
    pos_slot = S.slot.vertices;
    pos_section = S.section.vertices;
    
    M(1).pos = pos_slot;
    M(2).pos = pos_section;
    
    setappdata(hfig,'M',M);
    
    %% load flags
    h_probflag.Value = S.is_problematic;
%     h_verflag.Value = S.is_verified;
    h_verflag.Value = 1;
else
    LoadNewMask(hfig,slot_mask_file,ROI_mask_file);
    h_probflag.Value = 0;
    h_verflag.Value = 0; 
end

%% draw mask
DrawNewMask(hfig);

end

function LoadPreviousImage(hfig)
i_im = getappdata(hfig,'i_im');
if i_im > 1
    i_im = i_im-1;
    LoadImage(hfig,i_im);
else
    msgbox('reached first image');
end
end

function LoadNextImage(hfig)
global h_i_im;
i_im = getappdata(hfig,'i_im');
numFiles = getappdata(hfig,'numFiles');
if i_im < numFiles
    i_im = i_im+1;
%     hpoly = getappdata(hfig,'hpoly');
%     lpos = getappdata(hfig,'lastpos');
%     setConstrainedPosition(hpoly(2),lpos);
%     setappdata(hfig,'hpoly',hpoly);
    LoadImage(hfig,i_im); 
    % update GUI
    h_i_im.String = num2str(i_im);
else
    msgbox('reached last image');
end
end

function masktypeID = ToggleSelectedMask(hfig)
M = getappdata(hfig,'M');
hpoly = getappdata(hfig,'hpoly');

% save current pos of old mask
masktypeID_old = getappdata(hfig,'masktypeID');
M(masktypeID_old).pos = getPosition(hpoly(masktypeID_old));
delete(hpoly(masktypeID_old));

% toggle masktypeID
if masktypeID_old==1
    masktypeID = 2;    
elseif masktypeID_old==2
    masktypeID = 1;
end

setappdata(hfig,'masktypeID',masktypeID);
% redundant?
M(1).isselected = 0;
M(2).isselected = 0;

M(masktypeID).isselected = 1;

% draw new mask
hpoly(masktypeID) = impoly(gca, M(masktypeID).pos);
if masktypeID == 1
    setColor(hpoly(masktypeID),[0,1,1]);
elseif masktypeID == 2
    setColor(hpoly(masktypeID),[0,1,0]);
end

% save
setappdata(hfig,'M',M);
setappdata(hfig,'hpoly',hpoly);
end

function RotateMask(hfig,rotationAngle,masktypeID)
S = getappdata(hfig,'S');
M = getappdata(hfig,'M');
hpoly = getappdata(hfig,'hpoly');

% record rotation angle for this section

if masktypeID == 1
    S.slot.rotation = S.slot.rotation + rotationAngle;
elseif masktypeID == 2
    S.section.rotation = S.section.rotation + rotationAngle;
end

pos = getPosition(hpoly(masktypeID));
center = GetCenterPos(pos);
poscenter = repmat(center,size(pos,1),1);
rotationArray = [cos(rotationAngle), -sin(rotationAngle); sin(rotationAngle), cos(rotationAngle)];
pos2 = (pos-poscenter) * rotationArray + poscenter;
%     hpoly_section = impoly(h_ax, pos2);
setConstrainedPosition(hpoly(masktypeID),pos2);
M(masktypeID).pos = pos2;

% save
setappdata(hfig,'S',S);
setappdata(hfig,'M',M);
setappdata(hfig,'hpoly',hpoly);
setappdata(hfig,'lastpos',pos);
end

function TranslateMask(hfig,translationArray,masktypeID)
S = getappdata(hfig,'S');
M = getappdata(hfig,'M');
hpoly = getappdata(hfig,'hpoly');

% % record translation for this section
% if masktypeID == 1
%     S.slot.translation = S.slot.translation + translationArray;
% elseif masktypeID == 2
%     S.section.translation = S.section.translation + translationArray;
% end

pos = getPosition(hpoly(masktypeID));
pos2 = pos;
pos2(:,1) = pos2(:,1)+translationArray(1);
pos2(:,2) = pos2(:,2)+translationArray(2);
setConstrainedPosition(hpoly(masktypeID),pos2);
M(masktypeID).pos = pos2;
display(pos)
display(pos2)

% save
setappdata(hfig,'S',S);
setappdata(hfig,'M',M);
setappdata(hfig,'hpoly',hpoly);
setappdata(hfig,'lastpos', pos);
end

function center = GetCenterPos(pos)
center = zeros(1,2);
center(1) = mean(pos(:,1));%(max(pos(:,1))-min(pos(:,1)))/2+min(pos(:,1));
center(2) = mean(pos(:,2));%(max(pos(:,2))-min(pos(:,2)))/2+min(pos(:,2));
end

function SetCenterPos(hfig, center, maskTypeID)
    hpoly = getappdata(hfig,'hpoly');
    pos = getPosition(hpoly(maskTypeID));
    c = GetCenterPos(pos);
    TranslateMask(hfig, center - c, maskTypeID)
end

function DrawNewMask(hfig)
M = getappdata(hfig,'M');
% hpoly = getappdata(hfig,'hpoly');

% % reset to slot
% masktypeID = 1;
% setappdata(hfig,'masktypeID',masktypeID);
% 
% % draw
% hpoly(masktypeID) = impoly(gca, M(masktypeID).pos);
% M(masktypeID).isselected = 1;
% setColor(hpoly(masktypeID),[1,0,0]);

masktypeID = 2;
setappdata(hfig,'masktypeID',masktypeID);

% draw
hpoly(1) = impoly(gca, M(1).pos);
delete(hpoly(1));
hpoly(masktypeID) = impoly(gca, M(masktypeID).pos);
M(masktypeID).isselected = 1;
setColor(hpoly(masktypeID),[0,1,0]);

% masktypeID = 2;
% 
% hpoly(masktypeID) = impoly(gca, M(masktypeID).pos);
% M(masktypeID).isselected = 0;
% setColor(hpoly(masktypeID),[0.7,0.7,0.7]);

setappdata(hfig,'hpoly',hpoly);
end

function [pos_slot,pos_section] = ReconstitutePos(S,M)
% slot
masktypeID = 1;
% 
rotationAngle = S.slot.rotation;
pos = M(masktypeID).pos_init;
center = GetCenterPos(pos);
poscenter = repmat(center,size(pos,1),1);
rotationArray = [cos(rotationAngle), -sin(rotationAngle); sin(rotationAngle), cos(rotationAngle)];
pos_slot = (pos-poscenter) * rotationArray + poscenter;
%     translate1 = pos2(1,:)-pos(1,:);

% translate
translationArray = S.slot.translation;% - translate1;
pos_slot(:,1) = pos_slot(:,1)+translationArray(1);
pos_slot(:,2) = pos_slot(:,2)+translationArray(2);

% section
masktypeID = 2;
% rotate
rotationAngle = S.section.rotation;
pos = M(masktypeID).pos_init;
center = GetCenterPos(pos);
poscenter = repmat(center,size(pos,1),1);
rotationArray = [cos(rotationAngle), -sin(rotationAngle); sin(rotationAngle), cos(rotationAngle)];
pos_section = (pos-poscenter) * rotationArray + poscenter;
%     translate1 = pos2(1,:)-pos(1,:);

% translate
translationArray = S.section.translation;% - translate1;
pos_section(:,1) = pos_section(:,1)+translationArray(1);
pos_section(:,2) = pos_section(:,2)+translationArray(2);

end

function LoadNewMask(hfig,slot_mask_file,ROI_mask_file)
global h_ROI_mask h_slot_mask 
% update textboxs
[slot_path,slot_name,slot_ext] = fileparts(slot_mask_file);
[ROI_path,ROI_name,ROI_ext] = fileparts(ROI_mask_file);


h_ROI_mask.String = [ROI_name ROI_ext];
h_slot_mask.String = [slot_name slot_ext];

pos_slot_init = dlmread(slot_mask_file,' ',1,0);
pos_section_init = dlmread(ROI_mask_file,' ',1,0);
% init mask struct
M = [];

masktypeID = 1;
M(masktypeID).pos_init = pos_slot_init;

masktypeID = 2;
M(masktypeID).pos_init = pos_section_init;

pos_slot = pos_slot_init;
pos_section = pos_section_init;
M(1).pos = pos_slot;
M(2).pos = pos_section;

setappdata(hfig,'M',M);
end

function fig = getParentFigure(fig)
% if the object is a figure or figure descendent, return the figure. Otherwise return [].
while ~isempty(fig) && ~strcmp('figure', get(fig,'type'))
    fig = get(fig,'parent');
end
end
