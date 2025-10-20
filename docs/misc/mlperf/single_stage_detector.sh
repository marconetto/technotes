#!/bin/bash
# script to do all setup, data download, and training
# based on https://github.com/mlcommons/training/tree/master/single_stage_detector

export DATADIR="/datadrive"
export MYDATA="$DATADIR/mydata"
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world

sudo jq '. + {"data-root": "/mnt/docker"}' /etc/docker/daemon.json | sudo tee /etc/docker/daemon.json.tmp >/dev/null && sudo mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json && sudo systemctl restart docker
docker info | grep 'Docker Root Dir'

cd $DATADIR
git clone https://github.com/mlcommons/training.git

# alternative for faster install (with possible side effects;e.g install on other python versions)
# pip3 install --prefer-binary opencv-python-headless
# sed -i.bak -E 's/load_zoo_dataset\(\s*name="([^"]+)"\s*,/load_zoo_dataset("\1",/' fiftyone_openimages.py

pip3 install fiftyone
python -m pip show fiftyone
sudo ln -s $(which python3) /usr/local/bin/python
cd $DATADIR/training/single_stage_detector/scripts

echo "Downloading dataset... this will take several minutes"
./download_openimages_mlperf.sh -d $MYDATA

# prepare docker
cd $DATADIR/training/single_stage_detector/
docker build -t mlperf/single_stage_detector .
docker run --rm -it --gpus=all --ipc=host -v $MYDATA:/datasets/open-images-v6-mlperf mlperf/single_stage_detector bash

# inside the container:
# apt-get update ; apt-get install vim -y
# sed -i '0,/\${SLURM_LOCALID-}/s//${SLURM_LOCALID:-0}/' run_and_time.sh
# update config_DGXA100_001x08x032.sh
# DGXNGPU=1, DGXSOCKETCORES=20, DGXNSOCKET=1, DGXHT=2
# source config_DGXA100_001x08x032.sh
# -----------------------------------------------------------
# conda create -n torch212 python=3.10
# conda init bash
# source ~/.bashrc
# conda activate torch212
# pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
#
# fix: coco_eval.py
# # Old line:
# import torch._six
# #Replace with
# import collections.abc as container_abcs
#
# pip3 install mlperf_logging
# pip3 install pycocotools
# ./run_and_time.sh
