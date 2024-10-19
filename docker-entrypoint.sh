#!/bin/bash
# vim:sw=4:ts=4:et

# Adapted from (https://github.com/nginxinc/docker-nginx/blob/master/entrypoint/docker-entrypoint.sh)

set -e

entrypoint_log() {
    if [ -z "${MC_ENTRYPOINT_DEBUG_LOGS}" ]; then
        echo "$@"
    fi
}

# Run Startup Scripts
if [ "$1" = "/server/wrapper" ]; then
    if /usr/bin/find "/docker-entrypoint.d/start/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
        entrypoint_log "$0: Running startup scripts"

        find "/docker-entrypoint.d/start/" -follow -type f -print | sort -V | while read -r f; do
            case "$f" in
                *.envsh)
                    if [ -x "$f" ]; then
                        entrypoint_log "$0: Sourcing $f";
                        . "$f"
                    else
                        # warn on shell scripts without exec bit
                        entrypoint_log "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *.sh)
                    if [ -x "$f" ]; then
                        entrypoint_log "$0: Running $f";
                        "$f"
                    else
                        # warn on shell scripts without exec bit
                        entrypoint_log "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *) entrypoint_log "$0: Ignoring $f";;
            esac
        done
    else
        entrypoint_log "$0: No startup scripts found"
    fi
fi

# Set user ID
if [[ ! -z "${MC_UID}" ]] && [ ${MC_UID} != "0" ]; then
	usermod -u $MC_UID minecraft
    entrypoint_log "$0: Set user ID"
fi

# Set group ID
if [[ ! -z "${MC_GID}" ]] && [ ${MC_UID} != "0" ]; then
	groupmod -g $MC_GID minecraft
    entrypoint_log "$0: Set group ID"
fi

# Ensure ownership of data directory
if [[ ! -z "${MC_UID}" ]] && [ ${MC_UID} != "0" ]; then
    realUid=$(id -u minecraft)
    realGid=$(id -g minecraft)
    chown -R $realUid:$realGid /data
    entrypoint_log "$0: Set permissions for minecraft user"
fi

# Add more groups
if [[ ! -z "${MC_ADD_GROUPS}" ]] && [ ${MC_UID} != "0" ]; then 

	groups=$(echo "${MC_ADD_GROUPS}" | tr "," "\n")

	for g in "${groups[@]}"
	do
		$g_name=$(echo "$g" | cut -d':' -f1)
		$g_id=$(echo "$g" | cut -d';' -f2)

		groupadd -g $g_id $g_name
		usermod -aG $g_name minecraft
	done
fi


# Start Server
if [ "$1" = "/server/wrapper" ] && ([[ -z "${MC_UID}" ]] || [ ${MC_UID} != "0" ]); then
	sudo -E -u minecraft PATH=$PATH "$@"
else 
	sudo -E "$@"
fi

# Run Stop Scripts
if [ "$1" = "/server/wrapper" ]; then
    if /usr/bin/find "/docker-entrypoint.d/stop/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
        entrypoint_log "$0: Running shutdown scripts"

        find "/docker-entrypoint.d/stop/" -follow -type f -print | sort -V | while read -r f; do
            case "$f" in
                *.envsh)
                    if [ -x "$f" ]; then
                        entrypoint_log "$0: Sourcing $f";
                        . "$f"
                    else
                        # warn on shell scripts without exec bit
                        entrypoint_log "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *.sh)
                    if [ -x "$f" ]; then
                        entrypoint_log "$0: Running $f";
                        "$f"
                    else
                        # warn on shell scripts without exec bit
                        entrypoint_log "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *) entrypoint_log "$0: Ignoring $f";;
            esac
        done
    else
        entrypoint_log "$0: No shutdown scripts found"
    fi
fi



