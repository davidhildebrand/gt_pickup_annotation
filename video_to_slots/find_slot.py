#!/usr/bin/env python3

import os
import sys
import json

import numpy as np  # pip install numpy
import cv2  # pip install opencv-python

import npimage  # pip install git+https://github.com/jasper-tms/npimage


script_dir = os.path.dirname(__file__)
default_template_filename = script_dir + '/slot_template_righty_210725.tif'
with open(script_dir + '/slot_template_righty_210725_info.json', 'r') as f:
    default_template_slot_location = json.load(f)


# TODO implement subpixel matching, e.g. https://sites.google.com/site/qingzongtseng/template-matching-ij-plugin/tuto2#:~:text=implement
# TODO make sure behavior when no full slot is present is consistent and desirable
def find_slot(im: np.ndarray,
              output='center',
              template_filename=default_template_filename,
              template_slot_location=default_template_slot_location):
    """
    Given a 2D numpy array representing a single-channel image of GridTape,
    determine whether an entire slot is visible in the image, and if so, return
    its location.

    output: 'center' (default), 'bounds', or 'topleft'
        'center': returned dict will have keys "x" and "y" for the slot's center
        'bounds': returned dict will have keys "left", "right", "top" and "bottom"
        'topleft': returned dict will have keys "x" and "y" for the coordinates
            of the source image that match the top-left corner of the template

    template_filename: the filename of the template file to use. Must be
        located in the same directory as this script.

    template_slot_location: a dict containing keys "left", "right", "top", and
        "bottom" indicating the pixel locations of the edges of the slot within
        the template image.
    """
    #method: 'template' (default) or 'threshold' (TODO)
    #    'template': find the slot by cross-correlation with a template image of
    #        a slot
    #    'threshold': find the slot by thresholding and finding the connected
    #    component with the appropriate size


    script_dir = os.path.dirname(__file__)
    template = npimage.open(os.path.join(script_dir, template_filename))
    template_slot_center = (
        (template_slot_location['bottom'] + template_slot_location['top']) / 2,
        (template_slot_location['right'] + template_slot_location['left']) / 2
    )  # y,x order

    # Following https://docs.opencv.org/4.5.2/d4/dc6/tutorial_py_template_matching.html
    scores = cv2.matchTemplate(im, template, cv2.TM_CCOEFF_NORMED)
    # TODO TODO TODO implement subpixel max_loc finding. Perhaps fitting a gaussian peak?
    min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(scores)
    top_left = max_loc  # This is x,y ordered,
    top_left = top_left[::-1]  # so flip it to y,x

    if any([i < 2 or i > s - 3 for i, s in zip(top_left, scores.shape)]):
        raise ValueError('No full slot in the image, or slot too close to the '
                         'edge of the image to be detected.')

    if output == 'center':
        template_slot_center = (
            (template_slot_location['bottom'] + template_slot_location['top']) / 2,
            (template_slot_location['right'] + template_slot_location['left']) / 2
        )  # y,x order
        return {'x': top_left[1] + template_slot_center[1],
                'y': top_left[0] + template_slot_center[0]}
    elif output == 'bounds':
        return {'left': template_slot_location['left'] + top_left[1],
                'right': template_slot_location['right'] + top_left[1],
                'top': template_slot_location['top'] + top_left[0],
                'bottom': template_slot_location['bottom'] + top_left[0]}
    elif output == 'topleft':
        return {'x': top_left[1],
                'y': top_left[0]}
    else:
        raise ValueError("'output' must be 'center', 'bounds', or 'topleft' "
                         "but was " + str(output))


def crop_slot(im: np.ndarray,
              margin=5,
              channel=0,  # 0 -> red channel
              **kwargs):
    """
    Given a 2D numpy array representing a single-channel image of GridTape or a
    3D numpy array representing an RGB or RGBalpha image of GridTape, determine
    whether an entire slot is visible in the image, and if so, crop the slot
    out and return it or save it to file.

    'margin': Number of pixels around the slot edges to save.

    'channel': For RGB/RGBalpha images, the index of the channel to use for
        slot finding. Defaults to 0 to use the red channel.

    'output_filename': If specified, saves the cropped image to file instead of
        returning it as an array. If not specified, returns the cropped image.
    """
    if len(im.shape) == 3 and im.shape[2] in [3, 4]:  # if multichannel image
        im_for_find_slot = im[:, :, channel]
    else:
        im_for_find_slot = im
    slot_bounds = find_slot(im_for_find_slot, output='bounds', **kwargs)
    cropped = im[slot_bounds['top'] - margin:slot_bounds['bottom'] + margin + 1,
                 slot_bounds['left'] - margin:slot_bounds['right'] + margin + 1]
    return cropped


def crop_slot_from_file(filename,
                        margin=5,
                        channel=0,  # 0 -> red channel
                        output_suffix='_cropped-to-slot',
                        **kwargs):
    """
    TODO description

    If slot was found and an output image was saved, returns the output image's
    filename. Returns False otherwise
    """

    im = npimage.load(filename)

    # Turns 'hello.world/my.file.tif' into 'hello.world/my.file{output_suffix}.tif'
    output_filename = ('.'.join(filename.split('.')[:-1]) + output_suffix
                       + '.' + filename.split('.')[-1])

    try:
        im_cropped = crop_slot(im, margin=margin, channel=channel, **kwargs)
        npimage.save(im_cropped, output_filename)
        return output_filename
    except:
        return False


if __name__ == "__main__":
    for filename in sys.argv[1:]:
        if os.path.exists(filename):
            output_filename = crop_slot_from_file(filename, margin=20)
            if output_filename:
                print(f'Saved image to {output_filename}')
            else:
                print(f'Failed to crop {filename}')
        else:
            print(f'Skipping {filename}, is not a filename.')
