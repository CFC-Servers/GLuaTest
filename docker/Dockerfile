FROM cm2network/steamcmd

ARG GMOD_BRANCH=live

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y git python3-minimal expect && apt autoremove

ARG home=/home/steam
ARG gmodroot=$home/gmodserver
ARG server=$home/gmodserver/garrysmod

USER steam
RUN if [ "$GMOD_BRANCH" = "x86-64" ]; then \
    echo "Downloading x86-64 branch"; \
    ./steamcmd.sh +force_install_dir $gmodroot +login anonymous +app_update 4020 -beta x86-64 validate +quit; \
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

# Base requirements
COPY base_requirements.txt $gmodroot/requirements.txt

# GitHub Server Keys
RUN ssh-keyscan github.com >> $home/github_known_hosts

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
ENTRYPOINT ["/home/steam/gmodserver/entrypoint.sh"]
