# Template de Déploiement WordPress avec Lando

## Objectif

Ce projet fournit un template et un workflow pour initialiser des environnements de développement WordPress locaux sur Lando en quelques minutes. Il est conçu pour être flexible, robuste et pour fonctionner dans des environnements où les ports réseau peuvent être en conflit (ex: avec Caprover).

Le processus automatisé vous livre :
-   Une installation fraîche de la dernière version de WordPress.
-   Un site pré-configuré avec vos paramètres (titre, admin, etc.) via un simple fichier `config.env`.
-   Vos plugins favoris (gratuits et premium) installés et activés.
-   Une installation **nettoyée** : les plugins par défaut (Akismet, Hello Dolly) et les thèmes inutiles sont automatiquement supprimés.

Il est conçu pour être flexible, robuste et pour fonctionner dans des environnements où les ports réseau peuvent être en conflit (ex: avec Caprover).

## Prérequis

- Docker Desktop (Windows/macOS) ou Docker Engine (Linux)
- Lando (dernière version stable)
- WSL2 (pour les utilisateurs Windows)
- Git

---

## 1. Configuration Initiale (à faire une seule fois)

Avant de pouvoir créer des projets, vous devez cloner ce template sur votre machine locale. Il servira de "blueprint" pour tous vos futurs sites.

```bash
# Clonez le dépôt du template dans votre dossier home
git clone https://votre-repo.git ~/wordpress_template
```

> [!IMPORTANT]
> Ce dossier `~/wordpress_template` est votre source de vérité. Vous n'y travaillerez jamais directement. Vous ne ferez que copier son contenu.

---

## 2. Workflows de Création de Projet

### Workflow A : Créer un Nouveau Site de Zéro

1.  **Initialiser le dossier du projet :**
    ```bash
    mkdir ~/mon-nouveau-site.dev && cd $_
    ```

2.  **Copier le template :**
    ```bash
    cp -r ~/wordpress_template/. .
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
    > À la fin de cette commande, le site affichera l'écran d'installation de WordPress. **C'est normal et attendu.** Attendez que la commande se termine (ou faites `CTRL+C` si elle boucle) pour passer à l'étape suivante.

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

Votre site est maintenant entièrement installé et accessible.

---

### Workflow B : Cloner un Site Existant

Suivez le **Workflow A** pour créer un site local vierge, puis importez vos données et utilisez la commande de réparation `lando wp search-replace` (décrite dans la section Dépannage) pour mettre à jour les URLs.

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

## Dépannage (Troubleshooting)

### Le site est cassé après un `lando restart` (Problème de port qui change)

**Problème :** Après un `lando stop` puis `lando start`, le site est inaccessible. C'est parce que Lando a assigné un nouveau port, mais la base de données WordPress a mémorisé l'ancien.

#### Solution 1 (Rapide, non garantie) : Tenter de retrouver le bon port

```bash
# Arrêtez et redémarrez plusieurs fois
lando stop
lando start
```

Parfois, Lando retombera sur le port d'origine et le site fonctionnera à nouveau.

#### Solution 2 (Fiable) : Réparer la base de données avec `search-replace`

1.  **Lancez `lando start`** et attendez qu'il se termine.

2.  **Obtenez la NOUVELLE URL** avec `lando info`.
    ```bash
    # Exemple de commande pour la stocker dans une variable
    NOUVELLE_URL=$(lando info --format json | grep -o '"urls":\["[^"]*' | grep -o '[^"]*$' | head -n 1)
    echo "La nouvelle URL est : $NOUVELLE_URL"
    ```

3.  **Obtenez l'ANCIENNE URL** en lisant le fichier que le script a créé pour vous.
    ```bash
    # Exemple de commande pour la stocker dans une variable
    ANCIENNE_URL=$(cat .lando-url.txt)
    echo "L'ancienne URL était : $ANCIENNE_URL"
    ```

4.  **Lancez la commande de réparation :**
    ```bash
    lando wp search-replace "$ANCIENNE_URL" "$NOUVELLE_URL"
    ```

5.  **Mettez à jour le fichier de sauvegarde** avec la nouvelle URL pour la prochaine fois.
    ```bash
    echo "$NOUVELLE_URL" > .lando-url.txt
    ```
    Votre site est de nouveau accessible sur la nouvelle URL.

### Autres problèmes

- **`lando install` échoue avec "Vous devez fournir l'URL" :** Vous avez oublié de passer l'argument `--url` ou vous avez oublié le double tiret `--`. La syntaxe correcte est `lando install -- --url=...`.
- **Le script échoue pour une autre raison :** Lancez `lando logs -s appserver` pour voir les logs détaillés du conteneur où le script s'exécute.

## License

Ce projet est dédié au domaine public. Pour plus de détails, voir le fichier [LICENSE](LICENSE).

---
*README généré par Gemini 2.5 Pro*