FROM ghcr.io/cfc-servers/steamcmd:latest

ARG GMOD_BRANCH=live
ARG GLUATEST_REF=main
ARG GLUATEST_REPO=https://github.com/CFC-Servers/GLuaTest.git

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y --no-install-recommends --no-install-suggests git python3-minimal expect rsync openssh-client gdb && apt autoremove

ARG home=/home/steam
ARG gmodroot=$home/gmodserver
ARG server=$home/gmodserver/garrysmod

USER steam
RUN if [ "$GMOD_BRANCH" = "x86-64" ]; then \
    echo "Downloading x86-64 branch"; \
    ./steamcmd.sh +force_install_dir $gmodroot +login anonymous +app_update 4020 -beta x86-64 validate +quit; \
elif [ "$GMOD_BRANCH" = "dev" ]; then \
    echo "Downloading dev branch"; \
    ./steamcmd.sh +force_install_dir $gmodroot +login anonymous +app_update 4020 -beta dev validate +quit; \
elif [ "$GMOD_BRANCH" = "prerelease" ]; then \
    echo "Downloading prerelease branch"; \
    ./steamcmd.sh +force_install_dir $gmodroot +login anonymous +app_update 4020 -beta prerelease validate +quit; \
else \
    echo "Downloading live branch"; \
    ./steamcmd.sh +force_install_dir $gmodroot +login anonymous +app_update 4020 validate +quit; \
fi

# Initial server config
RUN touch $gmodroot/custom_server.cfg && \
    mkdir --parents --verbose $server/data && \
    mkdir --parents --verbose $home/garrysmod_override

USER root

# Base Config
COPY base_server.cfg $server/cfg/test.cfg

# Base fixture addon
COPY testfixture $server/addons/testfixture

# Any additional files
COPY _gluatest_artifacts/ $gmodroot/

RUN for file in $gmodroot/*.tar.gz; do \
      tar -xzf "$file" -C "$gmodroot" && \
      rm -f "$file"; \
    done

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

RUN git clone --depth 1 --branch $GLUATEST_REF $GLUATEST_REPO $server/addons/gluatest
RUN mkdir --parents --verbose $server/addons/gluatest/data_static
RUN echo "$GLUATEST_REF" > $server/addons/gluatest/data_static/gluatest_version.txt

ENTRYPOINT ["/home/steam/gmodserver/entrypoint.sh"]