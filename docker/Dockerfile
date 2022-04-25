FROM cm2network/steamcmd:latest

USER root
RUN apt update
RUN apt install -y git python3-minimal
RUN apt upgrade -y

ARG gmodserver=/home/steam/gmodserver

USER steam
RUN ./steamcmd.sh +force_install_dir $gmodserver +login anonymous +app_update 4020 -beta x86-64 +quit

# Initial server config
RUN touch $gmodserver/custom_server.cfg
RUN touch $gmodserver/data/gluatest_failures.json

USER root

# Base Config
COPY base_server.cfg $gmodserver/cfg/test.cfg
RUN chown steam:steam $gmodserver/cfg/test.cfg

# Base fixture addon
COPY testfixure $gmodserver/addons/testfixture
RUN chown -R steam:steam $gmodserver/addons/testfixture

# Base requirements
COPY base_requirements.txt $gmodserver/requirements.txt
RUN chown steam:steam $gmodserver/requirements.txt

# Entrypoint
COPY entrypoint.sh $gmodserver/entrypoint.sh
RUN chown steam:steam $gmodserver/entrypoint.sh

USER steam
ENTRYPOINT ["/home/steam/gmodserver/entrypoint.sh"]
