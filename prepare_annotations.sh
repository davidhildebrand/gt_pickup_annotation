#!/bin/bash
mkdir img_links
mkdir masks
mkdir annotations
mkdir queues
mkdir annot_imgs

imageExtension=tif
firstFileName=`ls $1/*section.$imageExtension | head -n 1`
echo $firstFileName
trimmedFileName=`tr -dc '_' <<< $firstFileName`
echo $trimmedfileName
columnWithSectionNum=${#trimmedFileName}
echo $columnWithSectionNum
# Different dataset names have different numbers of _ characters in them. Unfortunately, this string parsing cuts file names up by the _ character. Change the -f3 in the line below to -f#, where # is the number of _ characters that come before the section number in the staining image filename, plus one. 

for i in `ls $1/*section.$imageExtension`; do 
   NUM="$(cut -d'_' -f $columnWithSectionNum <<< $i)"
   echo linking $NUM
   ln -sf ../$i img_links/$NUM.png
done

#for i in `seq 100009 100018`; do j=$((100017 - $i)); mv img_links/$i.png img_links/$j.png; echo renaming $i as $j; done

#cp /home/lab/gut/masks/dummySectionMask.txt ./masks/dummySectionMask.txt
#cp /home/lab/gut/masks/slotMask.txt ./masks/slotMask.txt
#cp /home/lab/gut/masks/focus_mask.txt ./masks/focus_mask.txt

cp /home/mk604/repos/gt_pickup_annotation/masks/section_mask.txt ./masks/section_mask.txt
cp /home/mk604/repos/gt_pickup_annotation/masks/slotMask.txt ./masks/slotMask.txt
cp /home/mk604/repos/gt_pickup_annotation/masks/focus_mask.txt ./masks/focus_mask.txt
