#!/usr/bin/env bash
#Copie du fichier sur la carte SD et démontage de celle-ci

if [ "$1" == "" ] || [ -d "$1" ]; then
    echo "usage: MLua_Test.sh Nom_du_script"
    exit
else
    nameScript=$1
fi

if [ -d /Volumes/EOS_DIGITAL ]; then
    echo "Carte SD EOS_DIGITAL présente."
else
    echo "Installer la carte SD EOS_DIGITAL"
    exit 1
fi

ficLog=`grep -m 1 LoggingFilename $nameScript | cut -d \" -f 2`
version=`grep -m 1 Version $nameScript | cut -d \" -f 2`
datemodif=`date -r $nameScript`

echo "Copie du script : " $nameScript "sur la carte SD."

cp /Users/olivierzuntini/Documents/Projects/MagicLantern/ML_TimeLapse/$nameScript /Volumes/EOS_DIGITAL/ML/scripts/
echo "-> Script :" $nameScript "copié sur la carte."
echo "-> Nettoyage du log"
echo -e "\n" >> /Volumes/EOS_DIGITAL/$ficLog
echo `date`"---- Version $version du script ! -----------------------------" >> /Volumes/EOS_DIGITAL/$ficLog
echo "-------------------------------- Modif. du $datemodif" >> /Volumes/EOS_DIGITAL/$ficLog

echo "-> Démontage de la carte."
hdiutil detach "/Volumes/EOS_DIGITAL"

echo "Fin du script vous pouvez retirer la carte."