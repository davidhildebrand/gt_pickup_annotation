import json
import sys

js1 = json.load(open(sys.argv[1],'r'))
js2 = json.load(open(sys.argv[2],'r'))
out_fn = sys.argv[3]
for sec_num in js1:
    if sec_num in js2:
        for roi in js2[sec_num]['rois']:
            js1[sec_num]['rois'].append(roi)
json.dump(js1,open(out_fn,'w'))

