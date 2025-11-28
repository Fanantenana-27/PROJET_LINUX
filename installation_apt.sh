#!/bin/bash

#COTE SERVEUR

sudo mkdir -p /var/www/html/local
sudo cp /var/cache/apt/archives/*.deb /var/www/html/local

#Creer Packages.gz
sudo apt update
sudo apt install dpkg-dev

cd /var/www/html ; dpkg-scanpackages local /dev/null | gzip -9c | sudo tee local/Packages.gz
    # dpkg-scanpackages pool /dev/null → scanne tous les .deb dans pool et crée l’index
    # gzip -9c > .../Packages.gz → compresse l’index pour que apt puisse le lire
