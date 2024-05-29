#!/bin/bash

if [ $# -lt 2 ]; then
	echo "Usage: $0 [type] [version] <[image tag]>"
	exit 1
fi

tag=${3:-minecraft-server-$1}
docker build -t $tag:$2 --build-arg TYPE=$1 --build-arg VERSION=$2 --build-arg MCDL_ARGS="${@:3}" .
