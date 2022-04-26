FROM cm2network/steamcmd:latest

USER root
RUN apt update
RUN apt install -y git python3-minimal
RUN apt upgrade -y

ARG gmodroot=/home/steam/gmodserver
ARG server=/home/steam/gmodserver/garrysmod

USER steam
RUN ./steamcmd.sh +force_install_dir $gmodroot +login anonymous +app_update 4020 -beta x86-64 +validate +quit

# Initial server config
RUN touch $gmodroot/custom_server.cfg
RUN mkdir -pv $server/data/
RUN touch $server/data/gluatest_failures.json

USER root

# Base Config
COPY base_server.cfg $server/cfg/test.cfg
RUN chown steam:steam $server/cfg/test.cfg

# Base fixture addon
COPY testfixture $server/addons/testfixture
RUN chown -R steam:steam $server/addons/testfixture

# Base requirements
COPY base_requirements.txt $gmodroot/requirements.txt
RUN chown steam:steam $gmodroot/requirements.txt

# Entrypoint
COPY entrypoint.sh $gmodroot/entrypoint.sh
RUN chown steam:steam $gmodroot/entrypoint.sh

USER steam
ENTRYPOINT ["/home/steam/gmodserver/entrypoint.sh"]
