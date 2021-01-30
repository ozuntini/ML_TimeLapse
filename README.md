# Projet ML_TimeLapse
## TimeLapse avec Magic Lantern  

Exécution d'un cycle de photos pour réaliser un time-lapse avec la gestion du passage du jour à la nuit.  
Qualifié avec un Canon 6D et un 60D.  

## Principe de fonctionnement
Le programme ML_TimeLapse.lua va réaliser une série de photos avec un cycle  défini par l'utilisateur.  
Il est exécuté par l'application Magic Lantern. Les informations sur Magic Lantern sont données dans le chapitre suivant.

## Magic Lantern
Installer Magic Lantern sur votre boitier.  
https://www.magiclantern.fm/index.html  
Attention ! Il faut activer le module lua "Lua scripting" dans le menu Modules de MagicLantern.  
![Menu Modules](./images/Modules.png)  
Copier le script ML_TimeLapse.lua dans le répertoire ML/SCRIPTS de la carte SD.

## Script ML_TimeLapse.lua
Script en langage Lua qui exécute les cycles de photos.
Il est exécuté par l'interpréteur Lua présent dans MagicLantern.

## Manuel d\'utilisation.md
Documentation d'utilisation du programme ML_TimeLapse.lua.

## MLua_PIC.sh
Script bash utilisé avec l'émulation ML Qemu.  
https://bitbucket.org/hudson/magic-lantern/src/qemu/contrib/qemu/README.rst  
Copie du script Lua en paramètre sur les pseudos SD Qemu et lancement du virtualiseur.
```
usage: MLua_PIC.sh <Modèle> <Nom_du_script> [-log]
       6D ou 60D
       script.lua
       -log récupération des .LOG
````

## MLua_mount_imgSD.sh
Script de montage des images des pseudos cartes SD pour Qemu et de copie du fichier en paramètre.

## MLua_Test.sh
Script bash utilisé pour tester l'application.
Copie du script Lua en paramètre sur la carte SD présente dans le lecteur et démontage de celle-ci.
