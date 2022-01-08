# video-to-slots pipeline

Author: [Jasper Phelps](https://github.com/jasper-tms)

Step 1: `video_to_frames.sh` to convert a video file to a series of image files

Step 2: TODO select specific video frames that have the slot centered and give them a filename containing their barcode number

Step 3: `find_slot.py` to find the slot in each image and crop it, thereby producing a series of images that all have the slot in the same location at the center of the image
