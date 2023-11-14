# !/bin/bash

./build_image.sh acg_f2pt acg_f2pt v2_workflow.yaml main analytics/dockerized/acg_worker-requirements.txt analytics/events /data
./build_image.sh acg_pt2f acg_pt2f v2_workflow.yaml main analytics/dockerized/acg_worker-requirements.txt analytics/events

echo Images built ✅