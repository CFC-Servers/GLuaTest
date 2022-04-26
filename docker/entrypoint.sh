#!/bin/bash

gmodroot=/home/steam/gmodserver
server=/home/steam/gmodserver/garrysmod
cat "$server"/cfg/test.cfg
cat "$gmodroot/custom_requirements.txt" >> "$gmodroot/requirements.txt"
cat "$gmodroot/custom_server.cfg" >> "$server/cfg/test.cfg"

cd "$server"/addons
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
done <"$gmodroot"/requirements.txt
ls -alh
pwd

stdbuf -oL -eL timeout 2m "$gmodroot"/srcds_run_x64 -nodns -nohltv -systemtest -condebug -fs_nopreloaddata -gl_enablesamplerobjects -high -hushasserts -insecure -leakcheck -nodttest -nomaster -nominidumps -nomouse -norebuildaudio -nouserclip -reuse -snoforceformat -threads 6 -game garrysmod -ip 127.0.0.1 -port 27015 +clientport 27005 +gamemode sandbox +map gm_construct +servercfgfile test.cfg -maxplayers 12 -disableluarefresh
