# !/bin/bash

./build_image.sh acg_f2pt acg_f2pt workflow.yaml main analytics/dockerized/acg_worker-requirements.txt analytics/events /data/fed_request.avro
# ./build_image.sh acg_pt2f acg_pt2f workflow.yaml main analytics/dockerized/acg_worker-requirements.txt analytics/events

echo Images built ✅