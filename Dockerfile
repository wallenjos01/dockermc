ARG JAVA_VERSION=21
ARG BASE_DISTRO=jammy

# Build Wrapper
FROM gcc:14

COPY wrapper /wrapper
RUN set -eux; \
	cd /wrapper; \
	make

# Build MCDL and MCPing
FROM gradle:8.7-jdk$JAVA_VERSION

COPY mcdl /mcdl
COPY mcping /mcping

RUN set -eux; \
	cd /mcdl; \
	gradle :build :copyFinalJar; \
	cd ..

RUN set -eux; \
	cd /mcping; \
	gradle :app:build :app:copyFinalJar; \
	cd ..

FROM eclipse-temurin:$JAVA_VERSION-jre-$BASE_DISTRO


# Server Arguments
ARG TYPE=fabric
ARG VERSION=latest
ARG STDIN_PIPE_PATH=/server/stdin

ARG UID=920
ARG GID=920
ARG MCDL_ARGS=""

ENV MC_PORT 25565

# Volumes
VOLUME /data

RUN set -eux; \
	mkdir /data; \
	groupadd -g "${GID}" minecraft; \
	useradd --create-home --no-log-init -s /bin/bash -d /server -u "${UID}" -g "${GID}" minecraft; \
	chown minecraft:minecraft /data

RUN set -eux; \
	apt-get update; \ 
	apt-get install -y sudo

COPY --chmod=775 docker-entrypoint.sh custom.ja[r] /
COPY --from=0 --chown=minecraft:minecraft --chmod=775 /wrapper/wrapper /server
COPY --chmod=775 bin/* /usr/bin

STOPSIGNAL SIGINT
ENV MC_STDIN_PATH=$STDIN_PIPE_PATH
RUN set -eux; \
	mkfifo $MC_STDIN_PATH; \
	chown minecraft:minecraft $MC_STDIN_PATH

# Healthcheck
COPY --from=1 --chmod=770 --chown=minecraft:minecraft /mcping/app/build/output/mcping.jar /server
HEALTHCHECK --start-period=30s --interval=10s --retries=10 CMD ping-server -p $MC_PORT

WORKDIR /server

# Download Server
COPY --from=1 --chmod=770 --chown=minecraft:minecraft /mcdl/build/output/mcdl.jar /server
RUN set -eux; \
	cd /server; \
	java -jar /server/mcdl.jar -t $TYPE -g -v $VERSION --serverWorkingDir /data $MCDL_ARGS; \
	chown minecraft:minecraft /server/minecraft_server.jar /server/start.sh; \
	rm /custom.jar

USER root
ENTRYPOINT [ "/docker-entrypoint.sh" ] 
CMD [ "/server/wrapper" ]
