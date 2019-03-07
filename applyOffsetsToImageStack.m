cd /n/groups/htem/temcagt/datasets/vnc1_r066/roi_generation/2_crop

for i = vnc1rawToSlotslotToSectionrawToSectionoffsets(929:end,:)'
    imname=ls(['*_' num2str(i(1)) '_section.tif']);
    imname=imname(1:length(imname)-1)
    imdata=imread(imname);
    %imdata=imread([num2str(i(1)) '.png']);
    alignedimage=imtranslate(imdata, [i(2) i(3)]);
    imshow(alignedimage)
    pause(.1)
    imwrite(alignedimage,['/n/groups/htem/temcagt/datasets/vnc1_r066/roi_generation/verifying_rawToSectionOffsets/' imname]);
end