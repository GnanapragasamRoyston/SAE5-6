
# S501 - Application de recommandation adaptative sur mobile - SAE

## Contexte

L’IUT Villetaneuse Corp. souhaite une application mobile indépendante offrant une **recommandation adaptative** sans connexion.  
L’objectif : proposer des suggestions personnalisées basées sur l’usage, tout en respectant la **souveraineté des données** de l’utilisateur.  
Les défis : représenter les données efficacement, optimiser la recommandation pour la batterie et choisir les technologies mobiles appropriées.

## L'application Supriz'Me
L'application anti-ennui personnalisée
Supriz'Me est une application mobile conçue pour combattre l'ennui en fournissant des recommandations adaptatives et instantanées dans divers domaines de loisirs.

Le cœur de Supriz'Me repose sur un système de recommandation intelligent qui analyse les habitudes d'utilisation de l'utilisateur pour suggérer des activités, des jeux de société, et des films qui correspondent parfaitement à ses goûts et à son contexte actuel (temps disponible, loisirs, etc.).

🎯 Domaines de Recommandation
L'application couvre trois grandes catégories pour garantir une solution à tout type d'ennui :

Activités et Sorties : (Ex: Sports, lieux à visiter, etc.)

Jeux de Société : (Ex: Recommandations basées sur le nombre de joueurs et le temps de partie.)

Films & Séries : (Ex: Suggestions de contenu en fonction de vos genres de films préférés.)

## Fonctionnalités principales
- Recommandations adaptatives basées sur l’usage
- Fonctionnement hors ligne
- Suivi des préférences de l’utilisateur
- Contrôle total des données personnelles
- Interface mobile intuitive
- Optimisation des ressources (batterie et mémoire)

- ## Aperçu du projet
Voici un aperçu de l'application :
<p align="center">
  <img src="supriz_me/assets/images/image_home_page.png" width="300">
</p>


---

## Structure du projet

lib/ : code source principal

lib/data/ : chargement et préparation des données

lib/models/ : modèles de données

lib/services/ : logique métier et recommandations

lib/views/ : interfaces utilisateur

lib/widgets/ : composants réutilisables

test/ : tests

### Étapes d'installation

#### 1. Télécharger le projet
Clonez ou téléchargez ce dépôt GitHub :
```bash
git clone https://github.com/GnanapragasamRoyston/SAE5-6.git
```
Décompressez ou placez le projet dans un répertoire local.


### Prérequis
2. **Logiciels nécessaires** :
- Flutter SDK (version 3.x ou supérieure)

- Dart (inclus automatiquement avec Flutter)

- Android Studio ou Visual Studio Code

- Avec les extensions Flutter & Dart installées

- Git (pour cloner le dépôt et gérer le versionnement)

- Un émulateur Android ou un smartphone Android

(L’app fonctionne hors-ligne, donc pas besoin de compte Google)

3. **Environnement de base** :
1) Vérifiez votre installation :
```
   flutter doctor
```
2) Installez les dépendances du projet :
```
   flutter pub get
```
3) Vérifiez que l’appareil est reconnu :
```
   flutter devices
```  
4) Lancez votre émulateur Android :
```  
   flutter emulator --launch NOM_DE_L_EMULATEUR
```
5) Lancez l'application :

# ⚠️ IMPORTANT
Assurez-vous d’être dans le répertoire supriz_me afin que le fichier pubspec.yaml soit trouvé. <br>
❌ Ne lancez pas flutter run depuis le répertoire SAE5-6, sinon l’application ne démarrera pas

```
   cd supriz_me
```
   flutter run
   
## Technologies utilisées
- Flutter : Framework principal pour le développement mobile multiplateforme (Android/iOS).

- Dart : Langage de programmation utilisé par Flutter.

- Hive : Base de données locale pour stocker les préférences et historiques utilisateurs, permettant le fonctionnement hors-ligne.

- Git : Gestion du versionnement et collaboration.

- Android Studio / Visual Studio Code : IDEs recommandés pour le développement Flutter


## Équipe du projet
- **[Rania Bousfiha](https://github.com/rania212)**
- **[Royston Gnanapragasam](https://github.com/GnanapragasamRoyston)**
- **[Sajith Abdoul](https://github.com/GnanapragasamRoyston)**
- **[Inès Marcisz](https://github.com/inesmrcz)**
- **[Lucas Férard](https://github.com/Lucas93t)**
- **[Dhanoush Kessavane](https://github.com/dkessavane)**

