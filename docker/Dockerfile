FROM ghcr.io/cfc-servers/steamcmd:latest

ARG GMOD_BRANCH=public
ARG GLUATEST_REF=main
ARG GLUATEST_REPO=https://github.com/CFC-Servers/GLuaTest.git

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --yes --no-install-recommends --no-install-suggests git python3-minimal expect rsync openssh-client gdb && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/apt/lists/*

ARG home=/home/steam
ARG gmodroot=$home/gmodserver
ARG server=$home/gmodserver/garrysmod

# HACK! Fix this once you know how!
# We have no idea why, but the first steamcmd call updates Steam BUT then randomly fails the install:
# > ERROR! Failed to install app '4020' (Missing configuration)
#
# So as a workaround, we call it a second time, where it then decides to just magically work... pure magic.
USER steam
RUN echo "Downloading $GMOD_BRANCH branch"; \
./steamcmd.sh +force_install_dir $gmodroot +login anonymous +app_update 4020 -beta $GMOD_BRANCH validate +quit; \
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

# Requirements file, GitHub server keys, and cleanup
RUN touch $gmodroot/requirements.txt && \
    ssh-keyscan github.com >> $home/github_known_hosts && \
    rm -rf \
        $server/sv.db \
        $server/console.log \
        $server/stats.txt \
        $server/scenes \
        $server/logs \
        $server/downloadlists \
        $server/fallbacks_000.vpk \
        $server/fallbacks_dir.vpk \
        $gmodroot/sourceengine/scripts \
        $gmodroot/sourceengine/content_cstrike_dir.vpk \
        $gmodroot/sourceengine/hl2_sound_vo_english_dir.vpk \
        $gmodroot/sourceengine/hl2_sound_misc_dir.vpk \
        $gmodroot/sourceengine/hl2_textures_dir.vpk \
        $gmodroot/sourceengine/content_hl2_005.vpk \
        $gmodroot/sourceengine/content_hl2_dir.vpk

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
    git -C $server/addons/gluatest fetch --quiet origin $GLUATEST_REF && \
    git -C $server/addons/gluatest checkout FETCH_HEAD && \
    mkdir --parents --verbose $server/data $server/addons/gluatest/data_static && \
    echo "$GLUATEST_REF" > $server/addons/gluatest/data_static/gluatest_version.txt && \
    echo "$GMOD_BRANCH" > $server/garrysmod_branch.txt

ENTRYPOINT ["/home/steam/gmodserver/entrypoint.sh"]
