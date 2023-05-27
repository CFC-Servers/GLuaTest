FROM cm2network/steamcmd

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y git python3-minimal && apt autoremove

ARG gmodroot=/home/steam/gmodserver
ARG server=/home/steam/gmodserver/garrysmod

USER steam
RUN ./steamcmd.sh +force_install_dir $gmodroot +login anonymous +app_update 4020 validate +quit

# Initial server config
RUN touch $gmodroot/custom_server.cfg && mkdir -pv $server/data/

USER root

# Base Config
COPY base_server.cfg $server/cfg/test.cfg

# Base fixture addon
COPY testfixture $server/addons/testfixture

# Base requirements
COPY base_requirements.txt $gmodroot/requirements.txt

# GitHub Server Keys
RUN ssh-keyscan github.com >> /home/steam/github_known_hosts

# Entrypoint
COPY entrypoint.sh $gmodroot/entrypoint.sh
RUN chown -R steam:steam "$server/cfg/test.cfg" "$server/addons/testfixture" "$gmodroot/requirements.txt" "$gmodroot/entrypoint.sh" "/home/steam/github_known_hosts"

USER steam
ENTRYPOINT ["/home/steam/gmodserver/entrypoint.sh"]
