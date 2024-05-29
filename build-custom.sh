#!/bin/sh

if [ $# -lt 2 ]; then
	echo "Usage: $0 [type] [version] <[image tag]>"
	exit 1
fi

if [ -e "custom.jar" ]; then
	echo "Found custom server jar"
else
	echo "Place your custom server jar named custom.jar in the root folder!"
	exit 2
fi

tag=${3:-minecraft-server-$1}
docker build -t $tag:$2 --build-arg TYPE=custom --build-arg VERSION=$2 --build-arg MCDL_ARGS="--customJarPath /custom.jar" .
