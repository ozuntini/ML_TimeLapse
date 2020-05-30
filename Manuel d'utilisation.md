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



### Attention ! 
Le temps minimum entre deux images est de 1s.

## Lancement de la séquence
* Choisir le menu script.  
* Déplacer la barre de sélection sur le choix Eclipse ML OZ.  
* Lancer la séquence avec la touche SET.

Menu Scripts  
![Menu Scripts](./images/Scripts.png)

# Paramétrage du boitier
Le boitier doit être en mode :
* Auto power off à  Disable
* Mode Manuel
* Auto Focus en off

## Mirror Lockup
Si le boitier le permet il est possible d'utiliser le Mirrorlockup. Cela permet d'éviter des vibrations pendant la prise de vue.  
Menu Shoot - Mirror Lockup  
![Menu Shoot-Mirror-Lockup](./images/Shoot-MirrorLockup.png)  
La configuration MLU Mirror Lockup est piloté par le script mais il est possible qu'elle ne soit pas acceptée. 

# Configurations
## Mode test
Pour tester le script il est possible d'utiliser le mode Test. Ce mode déroule le script normalement mais ne déclenche pas les photos.  
Pour activer/désactiver ce mode, modifier le champ TestMode dans la ligne Config.
* 0 => mode réel  
* 1 => mode test

# Fichier log
A chaque lancement de séquence, un fichier log __MLTL.LOG__ est créé à la racine de la carte SD.  
Toutes les actions de la séquence sont loggés dans le fichier.
```
===============================================================================
ML/SCRIPTS/ML_TIM~1.LUA - 2017-9-30 14:15:00
===============================================================================

==> ML_TimeLapse.lua - Version : 1.0.0
14:15:00 - Log begin.
14:15:00 - get init parameter iso at 100
14:15:00 - Apply init parameter iso at 100
14:15:00 - Table iso updated with 22 arguments
14:15:00 - ISO Table = 22 values
14:15:00 - Get ISO = 100
14:15:00 - Get Time Start at 15:10:00
14:15:00 - Start at 54600s and 100 ISO
14:15:00 - Get Start Ramp at 15:30:00
14:15:00 - Get ISO Ramp end = 6400
14:15:00 - Get End Ramp at 16:00:00
14:15:00 - Ramping Start at 55800s and finish at 57600s ISO
14:15:00 - Get Time End at 17:15:00
14:15:00 - End at 62100s
14:15:00 - Get Interval = 12
14:15:00 - Interval = 12s
14:15:00 - Star at : 54600s with 100 ISO and Interval = 12s
14:15:00 - Ramp at : 55800s and finish at : 57600s with 6400 ISO
14:15:00 - End at : 62100s 
14:15:00 - Normal exit.

```