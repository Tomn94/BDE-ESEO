# Bureau des Étudiants du Groupe ESEO

[![Version](https://img.shields.io/badge/version-6.0-green.svg)](https://itunes.apple.com/app/apple-store/id966385182?pt=104224803&ct=GitHub&mt=8)
[![Code](https://img.shields.io/badge/code-Objective--C%20+%20Swift-orange.svg)](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html#//apple_ref/doc/uid/TP40011210)
[![Platform](https://img.shields.io/badge/platform-iOS-red.svg)](http://www.apple.com/ios/)
![Contributors](https://img.shields.io/badge/contributors-Thomas%20NAUDET%20+%20Benjamin%20GONDANGE-blue.svg)
[![Licence](https://img.shields.io/badge/licence-GNU%20GPLv3-lightgrey.svg)](http://www.gnu.org/licenses/)

Télécharger : [App Store](https://itunes.apple.com/app/apple-store/id966385182?pt=104224803&ct=GitHub&mt=8) &nbsp;·&nbsp; Portail : [portail.bdeeseo.fr](https://portail.bdeeseo.fr)


![Event online order](twophoneapp.png) 
###### Image [François Leparoux](https://github.com/rascafr)


## Description

> Découvrez l’application du Bureau des Étudiants du Groupe ESEO !
> 
> Tout au long de l'année, profitez de toute la vie associative de l'ESEO en un seul endroit.
> 
> NEWS
> - Toute l'actualité de l'ESEO, accédez facilement à la newsletter du dimanche
> - Les notifications vous permettent de ne rien manquer !
> - Accédez aux éditions du journal Ingénews
> 
> EVENTS
> - Retrouvez le calendrier annuel des événements de la vie associative
> - Inscrivez-vous aux événements et commandez vos places, notamment pour la Blue Moon !
> 
> BDE & CLUBS
> - Les infos, les photos, les liens, les contacts pour le BDE ainsi que tous les clubs de l'ESEO.  
> L'occasion rêvée de découvrir de nouveaux clubs et d'en rejoindre !
> 
> CAFÉTÉRIA
> - La cafétéria se modernise ! Désormais, commandez avec votre smartphone votre déjeuner !
> - Visualisez votre historique de commandes et soyez informés, sans bouger, lorsque votre commande est prête par une notification
> - Payez en liquide ou en carte bleue
> 
> BONS PLANS
> - Grâce à nos sponsors, profitez de multiples bons plans étudiants
>
> PRATIQUE
> - Remontez l'arbre des parrainages étudiants !
> - Consultez le plan du campus à Angers
> - Retrouvez également tous les liens vers le portail, campus, mails, …
> 
> Disponible sur iPhone, iPad & Apple Watch  


## Licence

    Copyright © 2015-2018 Thomas NAUDET and other repository contributors

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see http://www.gnu.org/licenses/

###### Règles spécifiques :

	- Chaque contributeur passé et présent de l'application BDE ESEO iOS/watchOS/… bénéficie d'un droit d’accès au code non limité sur le contenu, ni dans le temps.
	- Chaque publication nécessite citation des contributeurs.
	- Chaque contributeur bénéficie d'un droit de regard sur ce qui est distributé, notamment sur l'App Store, incluant textes, images, données, interface, outils, tarifs, décisions.
	- Il conserve un accès intégral à la gestion de l'application, incluant App Store Connect.
	- La prise d'une décision cruciale nécessite un accord entre les différents participants. Une décision nécessite 81 % d'adhésion parmi tous les contributeurs.
	- Chaque personne est le propriétaire et responsable légal de son code et de ses actions.
	- Chaque contributeur bénéficie d'un droit d’accès au back-end, ceci pour pouvoir réaliser entièrement l’app. Cela peut prendre une forme passive : possibilité d'ouvrir une pull request sur l'environnement de travail du back-end, ou la participation active en interagissant avec le serveur. Chaque contributeur a accès à des outils de test et de production adéquats.
	- Sauf exception claire, un contributeur ne peut être déchu.
	- Chaque contributeur doit connaître, comprendre et appliquer ces règles.


## Informations techniques

Nécessite une [API Serveur BDE](https://gitlab.com/bdeeseo/Portail) pour fonctionner.

#### BDE fraîchement élu ? Comment ajouter un logo
> - Ajouter son thème :
>   - Dans `ThemeManager.swift` :
>      - Ajouter le thème avec `case nomBDE = NUMÉRO_UNIQUE` dans `enum Theme`
>      - Ajouter ses couleurs dans `var themeValue` :  
>       `case .nomBDE: return (bars: COULEUR_1, barButtons: COULEUR_2, window: GÉNÉRALEMENT_COMME_COULEUR_1)`
>      - Ajouter son nom visible par l'utilisateur dans le sélecteur de thème dans `var name` :  
>       `case .nomBDE: return "NOM BDE"`
>      - Rendre le thème disponible en l'ajoutant à la fin de la liste `static var themes`
> 
> - Ajouter son icône :
>   - Créer 3 icônes PNG RGB non-transparent et les nommer ainsi, avec `*` le `NUMÉRO_UNIQUE` du thème (cf Ajouter son thème) :
> 	   - 120×120px : `App-Icon-*@2x.png`> 	   - 152×152px : `App-Icon-*@2x~ipad.png`> 	   - 180×180px : `App-Icon-*@3x.png`
>   - Les placer dans `ESEOmega/App Icons`
>   - Ouvrir `ESEOmega/Info.plist`
>     - Sous la clef `Icon files (iOS 5)`/`CFBundleIcons` puis `CFBundleAlternateIcons`, copier un BDE existant, coller
>     - Renommer ce BDE selon le nom choisi dans `var name`, et sous sa clef `CFBundleIconFiles`, modifier l'`Item 0` avec le numéro des noms de fichiers précédents `App-Icon-*`
>     - Faire la même opération dans `CFBundleIcons~ipad` (copier la clef renommée au nom du BDE, coller dans `CFBundleAlternateIcons`)
> 
> - Ajouter son sticker iMessage :
>   - Côté serveur sur l'[API Serveur BDE](https://gitlab.com/bdeeseo/Portail), ajouter son logo format PNG RGB transparent 300×300px dans le dossier (susceptible de changer) :  
>     `/api/v1/stickers/img/`
>   - Éditer `/api/v1/stickers/stickers.json` et rajouter :  
>     ``` {
		"id": NUMÉRO_UNIQUE_INCRÉMENTAL,  
		"name": "NOM BDE",  
		"img": "https://api.bdeeseo.fr/stickers/img/VOTRE_IMAGE.png"  
	},
>     ```

#### Clarifications connexion
> Un utilisateur peut se connecter grâce à son compte ESEO pour débloquer plusieurs fonctionnalités dont la commande à la cafet, l'achat de places et la réception de notifications.  
> Celui-ci se connecte grâce à son mail et son mot de passe, transmis temporairement à l'API Serveur BDE pour établir une connexion.
> Ce serveur vérifie uniquement que le compte existe et que le mot de passe est correct via le SMTP de Microsoft Exchange.
> Votre e-mail est conservé pour identifier vos achats et le mot de passe est hashé.

#### Une question ?
> Conformément à la loi relative à l'informatique, aux fichiers et aux libertés du 6 janvier 1978, vous disposez à tout moment d'un droit individuel d'opposition, d'accès, de modification, de rectification et de suppression des données qui vous concernent en nous contactant (par exemple en utilisant le bouton Contact dans l’application).


## Versions

### v6.0 · 21/06/2018

> - Nouvelle app sur Apple Watch !  
>   Jetez un coup d'œil à vos commandes cafet et trouvez une salle.  
>   Et bientôt plus !
> - Nouveau thème et icône AVÉSEO !
> - Nouveau sticker AVÉSEO pour iMessage et correctifs
> - Retour de la liste des clubs
> - Contactez les membres des clubs en tapant sur leur nom
> - La famille de l'utilisateur connecté est automatiquement chargée
> - Correction d'arbres de famille complexes
> - Mise à jour des liens 3D Touch vers le Portail/Campus ESEO/cafet
> - Améliorations d'UI, notamment pour iPhone X
> - Optimisations d'Handoff et préparation pour Siri
> - Hack du continuum espace-temps pour commander à la cafet avec iOS 11
> 
> 3 ans après la création de cette app, ceci est une des dernières mises à jour de ma part :)  
> ~ Thomas

###### Promotional Text
> Jetez un coup d'œil à vos commandes cafet et trouvez les salles de l'école sur Apple Watch !  
> Le thème, l'icône et le sticker AVÉSEO sont arrivés !

### v5.1 · 07/11/2017

> - Lydia est de retour pour payer à la cafet !
> - Support de l'iPhone X
> - Donnez une note à l'app sans la quitter

### v5.0 · 18/10/2017
> - La cafet est de retour !  
> Rétablissement également des news, de la liste des salles, des familles, des Ingénews.  
> Réécriture en Swift et utilisation de la nouvelle API BDE.  
> Les événements, clubs et sponsors reviendront prochainement.
> 
> - Mise à jour de l'interface pour iOS 11
> 
> - Nouveau thème ESEOdin !  
> Mettez-vous aux couleurs de votre BDE en choisissant un thème et une icône d’app dans votre profil.
> 
> - Nouveaux stickers ESEOdin et ESEO  
> Utilisez-les dans vos iMessages, leur chargement est désormais instantané.
> 
> - Vous vous êtes déjà connecté sur portail.bdeeseo.fr ?  
Vos identifiants seront désormais pré-remplis lors de la connexion à votre profil !
> 
> - Chargement accéléré des images et des sponsors
> - Améliorations de l'affichage des news et des alertes
> - Diverses corrections sur iPad

### v4.2 · 05/04/2017
> - Changez le thème de l'app !  
> Mettez-vous aux couleurs de votre BDE en choisissant un thème dans votre profil.
>
> - Personnalisez l'icône de l'app !  
> Célestin est désormais sur vos écrans,  
> ou sélectionnez un thème pour changer l'icône de l'app sur votre écran d'accueil (nécessite iOS 10.3).
> 
> - Nouveaux stickers !  
> Utilisez-les dans vos iMessages sur iOS 10, leur chargement est désormais instantané.

### v4.1 · 26/02/2017
> - La connexion au profil est rétablie !  
> Vous pouvez à nouveau commander à la cafet si vous étiez déconnecté(e), pour cela, utilisez votre adresse mail ESEO ainsi que votre mot de passe habituel.
> 
> - Améliorations de l'interface du profil et correction de quelques détails.

### v4.0.3 · 03/01/2017
> - Correctifs pour iPhone 7/7+, Ingénews et la cafet […]

### v4.0.2 · 29/11/2016
> - Correctifs pour les news, events et autres… […]

### v4.0.1 · 21/11/2016
> - Correctifs pour les news et autres… […]

### v4.0 · 15/11/2016
> Non ce n'est pas un mirage…  
> l'app a changé de logo !
> 
> Nouveau avec ESEOasis :
> - Interface aux couleurs du club du désert
> - Arbre des parrainages à l'ESEO : recherchez votre nom et trouvez votre famille !
> - Possibilité de s'inscrire à un événement
> - Aperçu des news et événements liés à chaque club
> - Récupération des données désormais depuis le serveur ESEOasis et mise à jour des liens
> 
> Également dans cette version :
> - Nouveau son pour les notifications
> - Retour haptique sur iPhone 7/7+ validant un ajout au panier
> - Trouvez une salle en quelques secondes par un appui 3D Touch sur l'icône de l'app. Nouveaux tris par bâtiment et par étage.
> - Ajout facilité d'un club/BDE en ami Snapchat
> - Les événements les plus récents apparaissent maintenant en haut
> - Améliorations de l'affichage des sponsors et infos événements
> - Perfection de multiples détails d'interface
> 
> Partagez l'app et n'oubliez pas de la noter sur l'App Store !  
> Une question ? Un problème ? Contactez Thomas Naudet sur Facebook

### v3.2 · 02/10/2016

<img src="/Captures App Store/iMessage/iPhone.png?raw=true" height="300" />

> Mise à jour corrective de rentrée
> 
> Support d'iOS 10 :
> - Envoie des stickers de la Vie Asso. dans tes iMessages !
> - Notifications enrichies (titre, images, GIF), in-app et interactives
> - Améliorations de l'interface & couleurs
> 
> - Correction du message de paiement via Lydia
> 
> Partagez l'app et n'oubliez pas de la noter sur l'App Store !  
> Une question, ou vous voulez proposer un sticker ? Contactez Thomas Naudet sur Facebook

### v3.1.6 · 05/06/2016
> Amélioration et correction des achats cafet, événements et Lydia […]

### v3.1.5 · 02/06/2016
> Merci d'avoir utilisé l'app pendant notre mandat ESEOmega !  
> Ω  
> Mais ce n'est pas fini…  
> Utilisez-la pour ESEOasis et les futurs BDE !
> 
> - Généralisation de l'app
> - Ajout d'un lien rapide vers Microsoft Dreamspark
> - Copyright photo bâtiment
> - Corrections push, cafet et UI
> 
> N'oubliez pas de noter l'app sur l'App Store !

### v3.1.4 · 25/03/2016
> - Retour sur iOS 8.1 pour les old school […]

### v3.1.3 · 17/03/2016
> - Correction des notifications, suite et fin […]

### v3.1.2 · 11/03/2016
> - Correction des notifications internes à l'app
> - Rafraîchissement des pages plus rapide
> […]

### v3.1.1 · 06/03/2016
> - Correction des notifications internes à l'app […]

### v3.1 · 03/03/2016
> La touche finale de votre app BDE ESEO :
> 
> - Passage en HTTPS et sur les nouvelles API ESEOmega · SheepDev
> - Chargement dynamique de l'intégralité des données pour évolutivité…
> - Ajout d'un lien vers le nouveau portail clubs ESEOmega.fr/portail
> - Correction d'un rare bug lors d'une commande, empêchant de sélectionner un menu
> - GP danse en musique
> - Améliorations d'interface, crashes chassés
> 
> Et toujours avec la 3.0, payez par carte à la cafet, lisez les IngéNews, accédez au plan des salles, …  
> Ω

### v3.0 · 19/01/2016

<img src="/Captures App Store/v3/iPad.png?raw=true" height="300" />

> Méga mise à jour pour bien commencer la nouvelle année 2016 !
> 
> - Payez par carte à la cafet !  
> Ce n'est pas parce que votre porte-monnaie est vide que votre estomac doit l'être aussi !  
> Au moment de votre commande vous pouvez désormais choisir de payer par carte bancaire sans frais supplémentaires, grâce à Lydia.
> 
> - Une Carte Bleue pour la Blue Moon  
> Achetez votre place pour la Blue Moon depuis l'application ! Par CB, c'est tellement simple, tout est dans l'onglet Événements.
> 
> - Lisez les articles Ingénews  
> Depuis l'onglet News, tapez sur le logo du club pour avoir les dernières éditions du journal de l'ESEO !
> 
> - « On a cours où, déjà ? »  
> Un nouveau bouton est apparu quand vous lancez l'application, tapotez-le doucement et il vous indiquera gentiment la liste des salles de l'ESEO Angers. Vraiment perdu ? Vous pouvez même consulter les plans.
> 
> - Indication du club/BDE servant à la cafet la semaine
> - Amélioration du processus de commande et de l'affichage
> - Restructuration de tous les services en ligne
> - Corrections diverses et variées
> 
> N'oubliez pas de noter l'app sur l'App Store !  
> Ω

### v2.1.2 · 06/11/2015
> - 3D Touch corrigé pour les iPhone 6s (Plus)  
> [Excusez le développeur en lui en offrant un qu'il puisse mieux effectuer ses tests]  
> Sur l'écran d'accueil, appuyez fortement l'icône ESEOmega pour accéder aux raccourcis :  
> commandes par exemple votre sandwich ou accédez au portail ESEO en 1 seconde !  
> Prévisualisez également toutes les contenus avec Peek et Pop (appui ± fort).
> 
> - Correction de l'ouverture des articles depuis un Rappel créé avec Siri  
> (Dites à Siri : « Rappelle-moi de lire ça plus tard » n'importe où dans l'app)
> 
> - Bonus pour la route :  
> Ouvrez les news dans Safari depuis le menu partage.
> 
> Consultez l'Historique des mises à jour pour en savoir plus sur les précédents ajouts (notifications, navigateur Safari intégré & économie de batterie iOS 9, Siri, transfert de lecture Handoff entre appareils iOS/Mac, 3D Touch, multitâche iPad, recherche Spotlight, zoom sur les images de club en tapant sur la description, améliorations cafet, …).
> 
> N'oubliez pas de noter l'app sur l'App Store !  
> Ω

### v2.1.1 · 04/11/2015

<img src="/Captures App Store/iPad/1.png?raw=true" height="300" /> <img src="/Captures App Store/iPad/3.png?raw=true" height="300" /> <img src="/Captures App Store/iPad/4.png?raw=true" height="300" /> <img src="/Captures App Store/6/2.png?raw=true" height="300" /> <img src="/Captures App Store/6/5.png?raw=true" height="300" />

> Après les Notifications et l'optimisation iOS 9, quelques autres nouveautés pour l'app ESEOmega :
> 
> - 3D Touch  
> Sur l'écran d'accueil de votre iPhone 6s (Plus), appuyez fortement sur l'icône ESEOmega pour accéder aux raccourcis !  
> Lancer la commande de son sandwich en 1 seconde sans ouvrir l'app, c'est possible !  
> Prévisualisez également les News, les liens dans les news, les Évenements, Clubs, Liens rapides, Bons plans et vos Commandes en appuyant légèrement dessus (Peek), et pressez un peu plus fort pour les afficher en plein écran (Pop) !
> 
> - Tapez sur la description d'un club pour afficher son image en plein écran
> - Correction des problèmes de connexion au profil ESEO et des notifications pour certains utilisateurs
> ¯    _(ツ)_/¯
> 
> - Prise en charge d'Handoff : lisez un article sur votre iPhone et finissez-le sur votre Mac, et inversement
> - Dites à Siri : « Rappelle-moi de lire ça plus tard », si vous n'avez pas le temps de lire une news (ou autre) tout de suite !
> - Retrouvez les news et les fonctionnalités de l'app depuis la recherche Spotlight iOS 9
> - Multitâche sur iPad : avec Split View, Slide Over et les vidéos Picture in Picture, utilisez ESEOmega en même temps qu'une autre app !
> - Détection des liens dans les news, prise en charge des vidéos intégrées, amélioration diverses…
> 
> N'oubliez pas de noter l'app sur l'App Store !
> 
> Ω

### v2.1 · 15/10/2015
> Hermès livre encore pléthore d'améliorations après la méga mise à jour de rentrée…
> 
> NOTIFICATIONS
> - Plus besoin de garder l'app ouverte pour ne pas manquer les dernières news
> - Plus pratique ! Vous pouvez venir cherche votre repas et payer après qu'il soit prêt en étant prévenu par une notification
> 
> N'hésitez donc pas à vous connecter dans l'app grâce à votre compte ESEO pour accéder à la cafet et aux notifications !
> 
> iOS 9 INSIDE
> - Ouvrez les liens sans quitter l'app avec le navigateur Safari intégré
> - Optimisations en mode économie d'énergie et réduction du poids de l'app
> 
> MAIS AUSSI
> - Possibilité d'ajouter des commentaires à sa commande cafet
> - Nouvelle barre rapide d'ajout au panier cafet
> - Affichage de la date de fin et diverses améliorations pour les événements
> - Correction des liens rapides pour nous contacter
> - News plus rapides à charger, correction du style
> - Ajout des comptes Instagram pour les clubs
> - 100aine de petites améliorations de l'affichage partout
> - Passage à la Guyllotine
> - Correction de bugs et sécurité renforcée (© Romain H.)
> 
> N'oubliez pas de noter l'app sur l'App Store !
> 
> Ω

### v2.0 · 02/09/2015

<img src="/Captures App Store/v2/iPad/1.png?raw=true" height="300" /> <img src="/Captures App Store/v2/iPad/3.png?raw=true" height="300" /> <img src="/Captures App Store/v2/iPad/4.png?raw=true" height="300" /> <img src="/Captures App Store/v2/6/2.png?raw=true" height="300" /> <img src="/Captures App Store/v2/6/5.png?raw=true" height="300" />

> Nouvelle année scolaire, place à une toute nouvelle application !
> 
> NEWS  
> → Toute l'actualité de l'ESEO en un seul endroit, accédez facilement à la newsletter du dimanche
> 
> EVENTS  
> → Retrouvez le calendrier annuel des événements de la vie associative
> 
> BDE & CLUBS  
> → Les infos, les liens, les contacts pour le BDE ainsi que tous les clubs de l'ESEO.  
> L'occasion rêvée de découvrir de nouveaux clubs et d'en rejoindre !
> 
> CAFÉTÉRIA  
> → La cafétéria se modernise ! Désormais, commandez avec votre smartphone votre déjeuner !  
> Visualisez votre historique de commandes et soyez informés lorsque votre commande est prête.
> 
> BONS PLANS  
> → Grâce à nos sponsors, profitez de multiples bons plans étudiants
> 
> Retrouvez également tous les liens vers le portail, campus, mails, …  
> Maintenant disponible sur iPad.
> 
> ESEOmega vous souhaite une bonne rentrée !<br>
> Ω

### v1.1 · 15/04/2015
> Merci à tous !  
> On vous réserve une super année 2015/2016 !
> 
> Bientôt des nouveautés, Hermès a livré quelques améliorations pour patienter :  
> › rajout de toutes les vidéos dont l'aftermovie rallye appart !  
> › l'app s'offre une cure de minceur puissance 4  
> › économie également pour votre forfait  
> › Hadès ne vous envoie plus en enfer d'un tap sur Animations, si vous n'aviez pas mis à jour votre iPhone  
> › Rodolphe retrouve son T  
> › correction des crédits  
> Nous remercions tous nos sponsors !

### v1.0 · 29/03/2015
> *Publication originale pour la campagne ESEOmega*
> 
> *[Voir l'app de campagne](https://github.com/Tomn94/Campagne-ESEOmega)*
