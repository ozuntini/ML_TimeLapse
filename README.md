# Projet ML_TimeLapse
## TimeLapse avec Magic Lantern  

Exécution d'un cycle de photos pour réaliser un time lapse avec la gestion du passage du jour à la nuit.  
Qualifié avec un Canon 6D.  

## Principe de fonctionnement
Le programme ML_TimeLapse.lua va réaliser une série de photos avec un cycle précis.  
Il est exécuté par l'application Magic Lantern. Les informations sur Magic Lantern sont données dans le chapitre suivant.

## Magic Lantern
Installer Magic Lantern sur votre boitier.  
https://www.magiclantern.fm/index.html  
Attention ! Il faut activer le module lua  "Lua scripting" dans le menu Modules de MagicLantern.  
![Menu Modules](./images/Modules.png)  
Copier le script ML_TimeLapse.lua dans le répertoire ML/SCRIPTS de la carte SD.

## Script ML_TimeLapse.lua
Script en langage Lua qui exécute les cycle de photos.
Il est exécuté par l'interpréteur Lua présent dans MagiLantern.

## Manuel d'utilisation.md
Documentation d'utilisation du programme eclipse_OZ.

## MLua_PIC.sh
Script bash utilisé avec l'émulation ML Qemu.  
https://bitbucket.org/hudson/magic-lantern/src/qemu/contrib/qemu/README.rst  
Copie du script Lua en paramètre sur les pseudo SD Qemu et lancement du virtualiseur.

## MLua_mount_imgSD.sh
Script de montage des images des pseudos cartes SD pour Qemu et de copie du fichier en paramètre.

## MLua_Test.sh
Script bash utilise pour tester l'application.
Copie du script Lua en paramètre sur la carte SD présente dans le lecteur et démontage de celle-ci.
