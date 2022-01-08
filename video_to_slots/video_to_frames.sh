#!/bin/bash


frame_format=png
# If you want you can change frame_format to:
# 'jpg' to compress the frames more heavily, which will take up less disk space but reduce image quality
# 'tif' to have uncompressed frames, which will take up more disk space but slightly increase image quality. (png doesn't compress much though, so the difference is barely noticeable)


show_help () {
    >&2 echo "Extract frames from a video file and save each frame as a separate .$frame_format"
    >&2 echo " "
    >&2 echo "Requirements: ffmpeg must be installed."
    >&2 echo " "
    >&2 echo "WARNING: The total file size of the frames extracted from a video"
    >&2 echo "will be ~100x the size of the original video! (i.e. a 10GB video"
    >&2 echo "will produce ~1TB of frames.) Only run this on a filesystem with"
    >&2 echo "sufficient storage space available!"
    >&2 echo " "
    >&2 echo "Usage: ./video_to_frames.sh file1 [file2] [...]"
}

if [ "$#" -eq 0 -o "$1" = "--help" -o "$1" = "-h" ]; then
    show_help
    exit 1
fi


for i in $@; do
    suffix=${i##*.}  # get the characters after the last .
    filename=$(echo $i | sed s/\.$suffix//)  # Remove the last . and suffix
    if [ ! -e ${filename}_frames ]; then  # If a frames folder doesn't already exist
        mkdir ${filename}_frames  # Make it
        ffmpeg -i $i ${filename}_frames/%05d.$frame_format  # Then extract frames
    fi
done
