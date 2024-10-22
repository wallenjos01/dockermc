ARG JAVA_VERSION=21
ARG BASE_DISTRO=jammy

# Build Wrapper
FROM gcc:14

COPY wrapper /wrapper
RUN set -eux; \
	cd /wrapper; \
	make

# Build MCDL and MCPing
FROM gradle:8-jdk$JAVA_VERSION

COPY mcdl /mcdl
COPY mcping /mcping

RUN set -eux; \
	cd /mcdl; \
	gradle :build; \
	cd ..

RUN set -eux; \
	cd /mcping; \
	gradle :app:build; \
	cd ..

FROM eclipse-temurin:$JAVA_VERSION-jre-$BASE_DISTRO


# Server Arguments
ARG TYPE=fabric
ARG VERSION=latest
ARG STDIN_PIPE_PATH=/server/stdin

ARG UID=920
ARG GID=920
ARG MCDL_ARGS=""

ENV MC_PORT=25565

# Volumes
VOLUME /data

RUN set -eux; \
	mkdir -p /data; \
	groupadd -g "${GID}" minecraft; \
	useradd --create-home --no-log-init -s /bin/bash -d /server -u "${UID}" -g "${GID}" minecraft

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
COPY --from=1 --chmod=770 --chown=minecraft:minecraft /mcping/app/build/libs/mcping-app-1.1.0.jar /server/mcping.jar
HEALTHCHECK --start-period=30s --interval=10s --retries=10 CMD ping-server -p $MC_PORT

WORKDIR /server

# Download Server
COPY --from=1 --chmod=770 --chown=minecraft:minecraft /mcdl/build/libs/mcdl-1.0.0.jar /server/mcdl.jar
RUN set -eux; \
	cd /server; \
	java -jar /server/mcdl.jar -t $TYPE -g -v $VERSION --serverWorkingDir /data $MCDL_ARGS; \
	chmod 775 /server/start.sh; \
    chown minecraft:minecraft /data; \
    chmod -R 775 /data; \
    rm /custom.jar

USER root
ENTRYPOINT [ "/docker-entrypoint.sh" ] 
CMD [ "/server/wrapper" ]
