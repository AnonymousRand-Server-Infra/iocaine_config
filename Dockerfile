FROM busybox:musl AS busybox
FROM akubrinsky/envsubst AS envsubst

# :3
FROM git.madhouse-project.org/iocaine/iocaine:3

################################################################################
# install binaries

ARG DOCKER_ROOT_USER
ARG DOCKER_NONROOT_USER

USER ${DOCKER_ROOT_USER}

# install busybox's statically-compiled binaries for basic shell commands
COPY --from=busybox /bin/busybox /bin/
RUN ["/bin/busybox", "--install", "-s", "/bin"]

# also install `envsubst`, which is not statically linked so it's gonna be harder
ARG CPU_ARCH
COPY --from=envsubst /usr/bin/envsubst /usr/bin/
# linker
COPY --from=envsubst /lib/ld-musl-${CPU_ARCH}.so.1 /lib/
# C library
COPY --from=envsubst /lib/libc.musl-${CPU_ARCH}.so.1 /lib/
# internationalization library, a dependency of `envsubst`
COPY --from=envsubst /usr/lib/libintl.so.8 /usr/lib/

################################################################################
# merge configs from services

# `COPY` doesn't work if `CONFIG_SRC_FILES` holds multiple space-separated files, so we instead
# make a temporary bind of the dockerfile's context to `/tmp_bind/` inside the container and `cp`

ARG IOCAINE_CONFIG_SRC_FILES
ARG IOCAINE_CONFIG_DEST_DIR
RUN --mount=type=bind,target=/tmp_bind/ \
    if [ -n "${IOCAINE_CONFIG_SRC_FILES}" ]; then \
        cd /tmp_bind/ && cp -r ${IOCAINE_CONFIG_SRC_FILES} ${IOCAINE_CONFIG_DEST_DIR}; \
    fi
RUN chown -R ${DOCKER_NONROOT_USER} ${IOCAINE_CONFIG_DEST_DIR}

################################################################################
# set perms

# set the right permissions for the run volume inside the container
# (we do this here instead of in a `pre_start` hook since we aren't bind mounting this file,
# and since `pre_start`s run their own container they cannot access the files copied to this one)
ARG IOCAINE_RUN_DEST_DIR
RUN mkdir -p ${IOCAINE_RUN_DEST_DIR}
RUN chown -R ${DOCKER_NONROOT_USER} ${IOCAINE_RUN_DEST_DIR}

################################################################################
# entrypoint

# custom entrypoint that runs `envsubst` on config files
# we do that in entrypoint instead of in `pre_start` for the same reason as perms changing above,
# but we also can't do it in this dockerfile since dockerfile doesn't get `env_file`'s env vars
ARG PATH_FROM_ROOT_TO_IOCAINE
RUN mkdir -p /tmp_entry/
COPY ${PATH_FROM_ROOT_TO_IOCAINE}/entrypoint.sh /tmp_entry/entrypoint.sh
RUN chown -R ${DOCKER_NONROOT_USER} /tmp_entry/

USER ${DOCKER_NONROOT_USER}

RUN chmod +x /tmp_entry/entrypoint.sh
# the original entrypoint for iocaine' docker image is `/bin/iocaine ...`, found using:
# `docker inspect --format='{{json .Config.Entrypoint}} git.madhouse-project.org/iocaine/iocaine:3`
# (SYNC); this is needed to make sure original entrypoint still runs after ours!
# also the "exec" form, i.e. a list, ensures `command:` in compose.yaml still appends args to this
ENTRYPOINT ["/tmp_entry/entrypoint.sh", "/bin/iocaine", "--config-path", "/etc/config.d"]
