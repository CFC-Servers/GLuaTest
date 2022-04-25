#!/bin/bash

gmodserver=/home/steam/gmodserver
cat "$gmodserver/custom_requirements.txt" >> "$gmodserver/requirements.txt"
cat "$gmodserver/custom_server.cfg" >> "$gmodserver/cfg/test.cfg"

cd "$gmodserver"/garrysmod/addons
function getCloneLine {
    python3 - <<-EOF
line = "$1"
spl = line.split("@")

name = spl[0].split("/")[1].lower()
url = "https://github.com/" + spl[0] + ".git"

branch = " --branch " + spl[1] if len(spl) > 1 else ""

print("git clone -v " + url + branch + " --single-branch " + name)
EOF
}

while read p; do
    eval $(getCloneLine "$p")
done <"$gmodserver"/requirements.txt

stdbuf -oL -eL timeout 2m "$gmodserver"/srcds_run_x64 -nodns -nohltv -systemtest -game garrysmod -ip 127.0.0.1 -port 27015 +clientport 27005 +gamemode sandbox +map gm_construct +servercfgfile test.cfg -maxplayers 12 -disableluarefresh
