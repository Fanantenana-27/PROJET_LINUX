#!/bin/bash

echo  -e "Content-type: text/html\n\n"

echo "<html>"
echo "  <head>"
echo "      <meta charset=\"UTF-8\">"
echo "      <title>Installation</title>"
echo "  </head>"
echo "  <body>"
echo "      <h2 align=\"center\" >Télécharger un fichier .deb</h2>"
for file in /var/www/html/local/* ; do
    nom_file=$(echo $file | awk -F'/' '{print $NF}')
    echo "      <a href=\"/deb/$nom_file\" download>$nom_file</a>"
    echo "<br>"
done
echo "  </body>"