#!/bin/bash
CONTAINER_NAME=mazzin_proj

setfacl -m user:1000:r ${HOME}/.Xauthority
dpkg -l | grep nvidia-container-toolkit &> /dev/null
HAS_NVIDIA_TOOLKIT=$?
which nvidia-docker > /dev/null
HAS_NVIDIA_DOCKER=$?

DOCKER_IMAGE_NAME="mazzin_proj_nvidia"
DOCKER_BASE_IMAGE="nvidia/opengl:1.2-glvnd-devel-ubuntu18.04"
if [ $HAS_NVIDIA_TOOLKIT -eq 0 ]; then
  docker_version=`docker version --format '{{.Client.Version}}' | cut -d. -f1`
  if [ $docker_version -ge 19 ]; then
	  DOCKER_COMMAND="docker run --gpus all"
  else
	  DOCKER_COMMAND="docker run --runtime=nvidia"
  fi
elif [ $HAS_NVIDIA_DOCKER -eq 0 ]; then
  DOCKER_COMMAND="nvidia-docker run"
else
  DOCKER_IMAGE_NAME="mazzin_proj_no_gpu"
  DOCKER_BASE_IMAGE="ubuntu:bionic"
  DOCKER_COMMAND="docker run"
fi

docker build -t $DOCKER_IMAGE_NAME \
  --build-arg base_img=$DOCKER_BASE_IMAGE \
  --build-arg git_email="$(git config user.email)" \
  --build-arg git_name="$(git config user.name)" \
  --build-arg ssh_prv_key="$(cat ~/.ssh/id_ed25519)" \
  --build-arg ssh_pub_key="$(cat ~/.ssh/id_ed25519.pub)" \
  --squash  .

exec $DOCKER_COMMAND \
     -it \
     --name $CONTAINER_NAME\
     --net=host \
     -e DISPLAY \
     -v ${HOME}/.Xauthority:/home/user/.Xauthority \
     $DOCKER_IMAGE_NAME
