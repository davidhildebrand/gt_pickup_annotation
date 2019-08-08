%First, mount the dataset directory locally using sshfs, or download the
%files that need to be aligned.

%cd to the location of the raw (unaligned) stainer images
cd /n/groups/htem/temcagt/datasets/aedes_r195/roi_generation/stainer_images_1_correctedBarcodes

%Load the required translations (output by the Align images in stack...
%Fiji plugin).
offsets=readmatrix('../alignment_try2');
dXcolumn=2;
dYcolumn=3;
sectionNumColumn=4;

for i = offsets'
    imname=ls(['*_' num2str(i(sectionNumColumn)) '_section.png']);
    imname=imname(1:length(imname)-1)
    imdata=imread(imname);
    alignedimage=imtranslate(imdata, [i(dXcolumn) i(dYcolumn)]);
    imshow(alignedimage)
    pause(.05)
    imwrite(alignedimage,['/n/groups/htem/temcagt/datasets/aedes_r195/roi_generation/stainer_images_4_slot_aligned_color/' imname]);
end