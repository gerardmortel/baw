#!/bin/bash

cd
wget https://raw.githubusercontent.com/gerardmortel/baw/master/install_chefserver.sh
chmod 755 ./install_chefserver.sh
nohup ./install_chefserver.sh >> install.log &
