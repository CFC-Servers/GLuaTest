FROM ghcr.io/cfc-servers/steamcmd:latest

ARG GMOD_BRANCH=public
ARG GLUATEST_REF=main
ARG GLUATEST_REPO=https://github.com/CFC-Servers/GLuaTest.git

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y --no-install-recommends --no-install-suggests git python3-minimal expect rsync openssh-client gdb && apt autoremove

ARG home=/home/steam
ARG gmodroot=$home/gmodserver
ARG server=$home/gmodserver/garrysmod

USER steam
RUN echo "Downloading $GMOD_BRANCH branch"; \
./steamcmd.sh +force_install_dir $gmodroot +login anonymous +app_update 4020 -beta $GMOD_BRANCH validate +quit;

# Initial server config
RUN touch $gmodroot/custom_server.cfg && \
    mkdir --parents --verbose $server/data && \
    mkdir --parents --verbose $home/garrysmod_override

USER root

# Base Config
COPY base_server.cfg $server/cfg/test.cfg

# Base fixture addon
COPY testfixture $server/addons/testfixture

# Make requirements file
RUN touch $gmodroot/requirements.txt

# GitHub Server Keys
RUN ssh-keyscan github.com >> $home/github_known_hosts

# Enable core dumps
RUN ulimit -c unlimited

# Entrypoint
COPY entrypoint.sh $gmodroot/entrypoint.sh
RUN chown --recursive steam:steam \
    "$home/garrysmod_override" \
    "$server/cfg/test.cfg" \
    "$server/addons/" \
    "$gmodroot/requirements.txt" \
    "$gmodroot/entrypoint.sh" \
    "$home/github_known_hosts"

USER steam
ENV GMOD_BRANCH=${GMOD_BRANCH}

RUN git clone --depth 1 $GLUATEST_REPO $server/addons/gluatest && \
    cd $server/addons/gluatest && \
    git fetch --quiet origin $GLUATEST_REF && \
    git checkout FETCH_HEAD

RUN mkdir --parents --verbose $server/data
RUN mkdir --parents --verbose $server/addons/gluatest/data_static
RUN echo "$GLUATEST_REF" > $server/addons/gluatest/data_static/gluatest_version.txt
RUN echo "$GMOD_BRANCH" > $server/garrysmod_branch.txt

ENTRYPOINT ["/home/steam/gmodserver/entrypoint.sh"]
