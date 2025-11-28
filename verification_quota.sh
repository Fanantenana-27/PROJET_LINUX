#!/bin/bash

envoie_mail()
{
    #Envoyer un mail tous le jour
    crontab -l > cronfile
    echo "00 12 * * * echo -e "Attention : vous avez dépassé votre quota disque.\nVous avez utilisé $2 blocs, ce qui dépasse votre limite douce de $3 blocs sur $3.\nMerci de supprimer des fichiers pour réduire votre utilisation disque." | mail -s "Utilisation quota" $1 " >> cronfile
    crontab cronfile
    rm cronfile
}

rapport_utilisation_quota_user()
{
    #Recuparation de tous les utilisateur
    sudo awk -F: '$3>=1000 && $3<=60000 {print $1}' /etc/passwd > users.txt

    periode_grace_bloc=$(sudo repquota $1 | awk '{if(NR==2) {print $0}}' | awk -F';' '{print $1}' | awk -F: '{print $2}')
    periode_grace_inode=$(sudo repquota $1 | awk '{if(NR==2) {print $0}}' | awk -F';' '{print $2}' | awk -F: '{print $2}')    

    echo -e "\033[35;1m\n     UTILISATION DE QUOTA SUR $1\033[0m (User)\n"
    echo -e "\033[36;1mPériode de grace (block)\033[0m: $periode_grace_bloc     \033[36;1mPériode de grace (inode)\033[0m: $periode_grace_inode ) "    
    echo -e "\033[32;1mUtilisateur     Utilisé(block)     Soft(block)      Hard(block)     Utilisé(inode)     Soft(inode)       Hard(inode)     \033[0m"
    echo "--------------------------------------------------------------------------------------------------------------------"
    while read line ; do
        sudo repquota $1 | grep -w "$line" | awk '{printf "%-16s %-19s %-17s %-16s  %-19s %-17s %-16s\n",$1,$3,$4,$5,$6,$7,$8}'
        utilise=$(sudo repquota $1 | grep -w "$line" | awk '{print $3}')
        soft=$(sudo repquota $1 | grep -w "$line" | awk '{print $4}')
        #Si le disque utilise depasse la limite soft sur quota , on envoye un mail à chaque utilisateur tous les jours
        if [ $utilise -ge $soft ] ; then
            envoie_mail $line $utilise $soft $1
        fi
    done < users.txt
    rm users.txt
}

rapport_utilisation_quota_group()
{
    #Recuparation de tous les utilisateur
    sudo awk -F: '$3>=1000 && $3<=60000 {print $1}' /etc/group > group.txt

    periode_grace_bloc=$(sudo repquota $1 | awk '{if(NR==2) {print $0}}' | awk -F';' '{print $1}' | awk -F: '{print $2}')
    periode_grace_inode=$(sudo repquota $1 | awk '{if(NR==2) {print $0}}' | awk -F';' '{print $2}' | awk -F: '{print $2}')

    echo -e "\033[35;1m\n     UTILISATION DE QUOTA SUR $1\033[0m(Group)\n"
    echo -e "\033[36;1mPériode de grace (block)\033[0m: $periode_grace_bloc     \033[36;1mPériode de grace (inode)\033[0m: $periode_grace_inode ) "  
    echo -e "\033[32;1mGroup           Utilisé(block)     Soft(block)      Hard(block)     Utilisé(inode)     Soft(inode)       Hard(inode)     \033[0m"
    echo "--------------------------------------------------------------------------------------------------------------------"
    while read line ; do
        sudo repquota -g $1 | grep -w "$line" | awk '{printf "%-16s %-19s %-17s %-16s  %-19s %-17s %-16s\n",$1,$3,$4,$5,$6,$7,$8}'
        utilise=$(sudo repquota $1 | grep -w "$line" | awk '{print $3}')
        soft=$(sudo repquota $1 | grep -w "$line" | awk '{print $4}')
    done < group.txt
    rm group.txt
}


rapport_utilisation_quota_user "/"
rapport_utilisation_quota_group "/"


