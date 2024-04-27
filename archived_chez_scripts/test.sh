#!/bin/bash
echo "🐠 testing one func at a time"


# (sudo "$os_installer update")
# (sudo DEBIAN_FRONTEND=noninteractive apt-get -y update)

os_installer="DEBIAN_FRONTEND=noninteractive apt-get -y"
sudo="sudo"

# (sudo DEBIAN_FRONTEND=noninteractive apt-get -y install git)
