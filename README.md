# Template de Déploiement WordPress avec Lando

## Objectif

Ce projet fournit un template et un workflow pour initialiser des environnements de développement WordPress locaux **propres et prêts à l'emploi** en quelques minutes.

Le processus automatisé vous livre :
-   Une installation fraîche de la dernière version de WordPress dans un sous-dossier `app/` dédié.
-   Un site pré-configuré avec vos paramètres (titre, admin, etc.) via un simple fichier `config.env`.
-   Vos plugins favoris (gratuits et premium) installés et activés.
-   Une installation **nettoyée** : les plugins par défaut (Akismet, Hello Dolly) et les thèmes inutiles sont automatiquement supprimés.

L'architecture sépare les fichiers de l'environnement de développement (Lando, scripts) des fichiers de l'application (WordPress), ce qui est idéal pour les migrations via des plugins.

## Prérequis

- Docker Desktop (Windows/macOS) ou Docker Engine (Linux)
- Lando (dernière version stable)
- WSL2 (pour les utilisateurs Windows)
- Git
- `rsync` (généralement installé par défaut sur Linux et WSL)

---

## 1. Configuration Initiale (à faire une seule fois)

Avant de pouvoir créer des projets, vous devez cloner ce template sur votre machine locale. Il servira de "blueprint" pour tous vos futurs sites.

```bash
# Clonez le dépôt du template dans votre dossier home
git clone https://votre-repo.git ~/wordpress_template
```

> [!IMPORTANT]
> Ce dossier `~/wordpress_template` est votre source de vérité. Vous n'y travaillerez jamais directement.

---

## 2. Workflows de Création de Projet

### Workflow A : Créer un Nouveau Site de Zéro

C'est le point de départ pour tout nouveau projet, qu'il soit vierge ou un clone.

1.  **Initialiser le dossier du projet :**
    ```bash
    mkdir ~/mon-nouveau-site.dev && cd $_
    ```

2.  **Copier le template (sans l'historique Git) :**
    Utilisez `rsync` pour copier les fichiers du template tout en excluant le dossier `.git`.
    ```bash
    rsync -av --exclude='.git' ~/wordpress_template/ .
    ```

3.  **Personnaliser la configuration :**
    -   **`.lando.yml` :** Modifiez la ligne `name:` pour donner un nom unique à votre projet Lando (ex: `mon-nouveau-site-dev`).
    -   **`config.env` :** Ajustez le titre du site, les identifiants admin et la liste des plugins gratuits.

4.  **Initialiser le dépôt Git :**
    ```bash
    git init && git add . && git commit -m "Initial commit"
    ```

5.  **Démarrer les conteneurs (`lando start`) :**
    ```bash
    lando start
    ```
    > [!NOTE]
    > Attendez que la commande se termine (ou faites `CTRL+C` si elle boucle sur les `vitals`) pour passer à l'étape suivante.

6.  **Obtenir l'URL active (`lando info`) :**
    ```bash
    lando info
    ```
    Repérez l'URL principale dans la sortie (ex: `http://mon-nouveau-site-dev.lndo.site:8000/`) et copiez-la.

7.  **Finaliser l'installation (`lando install`) :**
    Lancez notre commande personnalisée en lui passant l'URL que vous venez de copier.
    ```bash
    # Syntaxe : lando install -- --url=<URL_COPIÉE>
    lando install -- --url=http://mon-nouveau-site-dev.lndo.site:8000
    ```
    Le script va installer le site et créer un fichier `.lando-url.txt` contenant cette URL.

Votre site vierge est maintenant prêt.

---

### Workflow B : Cloner un Site Existant

Il y a deux méthodes principales pour cloner un site. Choisissez celle qui correspond à vos outils.

#### Méthode 1 : Export/Import Manuel (avec WP-CLI)

Cette méthode vous donne un contrôle total sur le processus.

1.  **Exporter depuis la Production :**
    -   Via SSH, connectez-vous à votre serveur.
    -   Exportez la base de données : `wp db export backup_prod.sql`
    -   Archivez les fichiers : `tar -czvf wp-content.tar.gz wp-content`
    -   Téléchargez `backup_prod.sql` et `wp-content.tar.gz` sur votre machine.

2.  **Créer l'Environnement Local Vierge :**
    -   Suivez **toutes les étapes du Workflow A** pour créer un site local propre et fonctionnel.

3.  **Importer les Données en Local :**
    -   Placez `backup_prod.sql` et `wp-content.tar.gz` à la racine de votre projet Lando.
    -   Exécutez les commandes suivantes :
        ```bash
        # 1. Importer la base de données de production
        lando db-import backup_prod.sql

        # 2. Remplacer le dossier wp-content
        rm -rf app/wp-content
        tar -xzvf wp-content.tar.gz -C app/
        ```

4.  **Finaliser la Migration :**
    -   Mettez à jour les URLs dans la base de données :
        ```bash
        URL_LOCALE=$(cat .lando-url.txt)
        lando wp search-replace 'https://www.votre-site-prod.com' "$URL_LOCALE" --all-tables
        ```
    -   Videz le cache et rafraîchissez les permaliens :
        ```bash
        lando wp cache flush
        lando wp rewrite flush --hard
        ```
    -   Connectez-vous à `/wp-admin` avec les identifiants de **production**.

---

#### Méthode 2 : Restauration via un Plugin (ex: WPvivid)

Cette méthode est souvent plus simple si vous n'avez pas d'accès SSH.

1.  **Exporter depuis la Production :**
    -   Sur votre site de production, utilisez votre plugin de migration (ex: WPvivid) pour créer une sauvegarde complète.
    -   Téléchargez le fichier de sauvegarde généré par le plugin.

2.  **Créer l'Environnement Local Vierge (avec le plugin de migration) :**
    -   Suivez **toutes les étapes du Workflow A**.
    -   **Point crucial :** Avant de lancer `lando install`, assurez-vous que le plugin de migration sera bien présent sur votre site local.
        -   **Version gratuite :** Ajoutez le slug du plugin (ex: `wpvivid-backuprestore`) à la liste `PLUGINS_LIST` dans votre fichier `config.env`.
        -   **Version Pro :** Placez le fichier `.zip` du plugin dans le dossier `plugins-premium/`.
    -   Lancez `lando install` comme d'habitude.

3.  **Restaurer la Sauvegarde en Local :**
    -   Connectez-vous à l'administration de votre nouveau site local vierge.
    -   Allez dans l'interface du plugin de migration que vous venez d'installer.
    -   Utilisez sa fonction "Importer" ou "Restaurer" pour téléverser le fichier de sauvegarde que vous avez téléchargé depuis le site de production.
    -   Suivez les instructions du plugin pour lancer la restauration.

4.  **Finaliser :**
    -   La plupart des plugins de migration modernes gèrent automatiquement le `search-replace` des URLs pendant la restauration.
    -   Une fois la restauration terminée, vous serez probablement déconnecté. Reconnectez-vous avec les identifiants de **production**.
    -   Par sécurité, allez dans `Réglages > Permaliens` et cliquez sur "Enregistrer les modifications" pour rafraîchir les règles de réécriture.

---

## Commandes Utiles

```bash
# Démarre les conteneurs
lando start

# Finalise l'installation de WordPress
lando install -- --url=<URL>

# Affiche les informations (URLs, BDD, etc.)
lando info

# Exécute une commande WP-CLI
lando wp <commande>

# Arrête l'environnement
lando stop

# Supprime complètement l'environnement (irréversible !)
lando destroy -y
```

## License

Ce projet est dédié au domaine public. Pour plus de détails, voir le fichier [LICENSE](LICENSE).

---
*README généré par Gemini 2.5 Pro*