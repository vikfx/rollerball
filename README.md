rollerball
==========
Jeu roller ball en flash avec moteur 3D Away 3D 4.1 et moteur de physique JigLibFlash.
Jeu en cours de développement (version alpha)

La classe principale Main.as se trouve dans le dossier /src/
Les classes d'objets sont dans le package /src/vikfx/

  - ControlCamera.as => controller de la caméra
  - Debugger.as => classe de débuggage. Affiche les données et le trident
  - Plateau3D.as => construction du plateau de jeu et gestion des collision avec l'acteur
  - ControlCharacter.as => construction des acteurs
  - Interface.as => interface du jeu avec les menu pause / mute/ score / chronomètre
  - Menu.as => menu du jeu avec choix des acteurs et choix du level
  - PopUp.as => popup pour afficher le score à la fin du level et les boutons level précédent / level suivant / recharger le level


Les ressources externes sont dans le dossier /bin/

  - /js/ => les javascripts (swfObject)
  - /xml/ => xml pour le chargement des configs et des levels
  - /assets/ => ressources images / sons / modeles 3D
  - /./ => racine avec les swf du jeu et la page html


Les libraries associes swc sont dans le dossier /lib/
  
  - away3D 4.1 pour le moteur 3D sous forme swc
  - GreenSocks pour les tweens sous forme swc


Le moteur physique jigilib se trouve dans /src/jiglib/
