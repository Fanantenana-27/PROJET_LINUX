#!/bin/bash

POINT_MONTAGE1="/home"
POINT_MONTAGE2="/data"

option_fstab()
{
    #Ajouter des option dans /etc/fstab
    sudo cat /etc/fstab > tmp_fst 
    n=$(sudo cat tmp_fst | awk '!/^#/ {if($2=="/home") {print NR}}')
    m=$(sudo cat tmp_fst | awk '!/^#/ {if($2=="/data") {print NR}}') 
    i=1;
    touch tmp 
    while read line ; do
        if [ $i -eq $n ] ; then
            #Verifier s'il y a déjà l'option usrquota
            v1=$(echo $line | grep "usrquota" | wc -l)
            if [ $v1 -eq 0 ]
                line=$(echo $line | awk '{if($2=="/home") {print $1 " " $2 " " $3 " " $4 ",usrquota " $5 " " $6 " " }}')
            fi
        elif [ $i -eq $m ] ; then
            #Verifier s'il y a déjà l'option usrquota
            v1=$(echo $line | grep "usrquota" | wc -l)
            if [ $v1 -eq 0 ] ; then
                line=$(echo $line | awk '{if($2=="/data") {print $1 " " $2 " " $3 " " $4 ",usrquota " $5 " " $6 " " }}')
            fi 
            #Verifier s'il y a déjà l'option grpquota
            v2=$(echo $line | grep "grpquota" | wc -l)
            if [ $v2 -eq 0 ] ; then
                line=$(echo $line | awk '{if($2=="/data") {print $1 " " $2 " " $3 " " $4 ",grpquota " $5 " " $6 " " }}')
            fi
        fi
        echo $line >> tmp
        let i++
    done < tmp_fst 
    cat tmp | sudo tee /etc/fstab 
    rm tmp
}

monter_fstab() 
{
    #Mounter /etc/fstab
    sudo systemctl daemon-reload
    sudo mount -o remount "$1" #point de montage
    sudo mount -o remount "$2"
}

creer_fichier_conf() 
{
    #Creer le fichier de configuration pour /home
    sudo quotacheck -cum -F vfsv0 $1
    #Creer le fichier de configuration pour /data
    sudo quotacheck -cum -F vfsv0 $2
    sudo quotacheck -cgm -F vfsv0 $2
}

active_quota()
{
    #Activer le quota pour /home
    sudo quotaon -u $1 
    #Activer le quota pour /data
    sudo quotaon -u $2
    sudo quotaon -g $2
}

editer_fichier_conf_home() 
{
    #Editer le fichier de configuration pour /home
    sudo awk -F: '$3>=1000 && $3<=60000 {print $1}' /etc/passwd > users.txt
    while read line ; do
        sudo setquota -u $line 500000000 700000000 0 0 $1
        sudo quotatool -u $line -b -t 7days $1
    done < users.txt
    rm users.txt
}      

editer_fichier_conf_data()
{
    #Editer le fichier de configuration de user pour /data
    sudo awk -F: '$3>=1000 && $3<=60000 {print $1}' /etc/passwd > users.txt
    while read line ; do
        sudo setquota -u $line 0 0 500000000 700000000 $1
         sudo quotatool -u $line -b -t 7days $1
    done < users.txt
    rm users.txt

    #Editer le fichier de configuration de group /data
    sudo awk -F: '$3>=1000 && $3<=60000 {print $1}' /etc/group > group.txt
    while read line ; do
        sudo setquota -g $line 0 0 9000000 9500000 $1 
        sudo quotatool -g $line -b -t 7days $1
    done < group.txt
    rm group.txt
}

#Executer la verification de quota tous le dimenche a 12h
#Le chemin de fichier de verification est entré en argument
planification_execution_de_rapport_verifiction()
{
    crontab -l > cronfile
    echo "00 12 * * 7 $1 " >> cronfile
    crontab cronfile
    rm cronfile
}


#Verification de CONFIG_QUOTA si active
ver=$(grep "CONFIG_QUOTA=y" /boot/config-* | wc -l )

if [ $ver -gt 0 ] ; then
    option_fstab
    monter_fstab $POINT_MONTAGE1 $POINT_MONTAGE2
    creer_fichier_conf $POINT_MONTAGE1 $POINT_MONTAGE2
    active_quota $POINT_MONTAGE1 $POINT_MONTAGE2
    editer_fichier_conf_home $POINT_MONTAGE1
    editer_fichier_conf_data $POINT_MONTAGE2 
    planification_execution_de_rapport_verifiction $1
else
    echo -e "\033[31mCONFIG_QUOTA non activé \033[0m"
fi

