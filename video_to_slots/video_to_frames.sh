#!/bin/bash

# --- Configurations - Feel free to modify these to suit your needs --- #

frame_format=png
# If you want you can change frame_format to:
# 'jpg' to compress the frames more heavily, which will take up less disk space but reduce image quality.
# 'tif' to have uncompressed frames, which will take up more disk space but slightly increase image
#       quality. (png doesn't compress much though, so the difference is barely noticeable.)


framerate=""
# If this is left blank, then all frames from the video will be extracted and saved.
# If you want to save only a subset of the frames, set this to a number to indicate how
# often you want to save a frame. For instance, if your video is 30fps (you can use
# the command `ffprobe your_video.avi` to see its framerate) and you want to save only
# every 10th frame, well 30 / 10 = 3, so set `framerate=3` here. Decimal values are
# accepted, so to save every 100th frame of a 30fps video, set `framerate=0.3`


vflip=true
# Our placement camera views the tape through a mirror, so it captures reflected images.
# If you have `vflip=true` here, this script will vertically flip the frames during frame
# extraction. This is what we want for this pipeline, but if you're using this script
# for other purposes, you may want to turn this to `false`.


digits=8
# Number of digits to use for the filenames of the extracted frames

# --- End configurations --- #


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
    >&2 echo ""
    >&2 echo "See the 'Configurations' variables at the top of this script file for some options"
}

if [ "$#" -eq 0 -o "$1" = "--help" -o "$1" = "-h" ]; then
    show_help
    exit 1
fi


vflip_arg=""
if $vflip; then
    vflip_arg="-vf vflip"
fi

framerate_arg=""
if [ -n "$framerate" ]; then
    framerate_arg="-r $framerate"
fi

for i in $@; do
    suffix=${i##*.}  # get the characters after the last .
    filename=$(echo $i | sed s/\.$suffix//)  # Remove the last . and suffix
    if [ ! -e "${filename}_frames" ]; then  # If a frames folder doesn't already exist
        mkdir "${filename}_frames"  # Make it
        ffmpeg -i $i ${framerate_arg} ${vflip_arg} ${filename}_frames/%0${digits}d.$frame_format  # Then extract frames
    else
        echo "${filename}_frames already exists, skipping"
    fi
done
