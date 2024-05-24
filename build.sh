#!/bin/sh

if [ $# -ne 2 ]; then
	echo "Usage: $0 [type] [version]"
	exit 1
fi

docker build -t minecraft-server-$1:$2 --build-arg TYPE=$1 --build-arg VERSION=$2 .
