#!/bin/bash
# ~/wordpress_template/scripts/init.sh - Version Finale (Avec webroot)

set -e
# On se place dans la racine du projet Lando
cd /app

# On définit le chemin de WordPress
WP_DIR="/app/app"
WP_CLI="/usr/local/bin/wp --path=$WP_DIR"
APP_URL=""

# --- ÉTAPE 0 : LIRE L'ARGUMENT --url ---
for arg in "$@"
do
    case $arg in
        --url=*)
        APP_URL="${arg#*=}"
        shift
        ;;
    esac
done

if [ -z "$APP_URL" ]; then
    echo "❌ ERREUR: Vous devez fournir l'URL du site."
    echo "   USAGE: lando install -- --url=http://votre-site.lndo.site:PORT"
    exit 1
fi

echo "--- DÉMARRAGE DU SCRIPT DE CONFIGURATION (Version webroot) ---"
echo "URL de configuration : ${APP_URL}"

# On crée le dossier de l'application s'il n'existe pas
mkdir -p $WP_DIR

# --- On vérifie si l'installation est déjà faite ---
if [ -f "$WP_DIR/wp-config.php" ]; then
    echo "✅ Le fichier wp-config.php existe déjà. Installation annulée."
    exit 0
fi

# --- ÉTAPE 1: TÉLÉCHARGEMENT DE WORDPRESS ---
echo "➡️  ÉTAPE 1: Téléchargement des fichiers de WordPress Core..."
$WP_CLI core download --locale=fr_FR --force
echo "   ✅ Fichiers de WordPress téléchargés dans $WP_DIR."

# --- ÉTAPE 2: CONFIGURATION ---
echo "➡️  ÉTAPE 2: Configuration de WordPress..."
source /app/config.env
$WP_CLI config create --dbname=wordpress --dbuser=wordpress --dbpass=wordpress --dbhost=database --force
$WP_CLI core install --url="$APP_URL" --title="$WP_TITLE" --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASS" --admin_email="$WP_ADMIN_EMAIL"
echo "✅ WordPress configuré avec l'URL : ${APP_URL}"

# --- ÉTAPE 3: PLUGINS ET NETTOYAGE ---
echo "➡️  ÉTAPE 3: Installation des plugins et nettoyage..."
for plugin in $PLUGINS_LIST; do $WP_CLI plugin install "$plugin" --activate; done
# Note : le chemin du zip doit être relatif à la racine du projet Lando
for plugin_zip in /app/plugins-premium/*.zip; do [ -f "$plugin_zip" ] && $WP_CLI plugin install "$plugin_zip" --activate; done
$WP_CLI plugin delete akismet hello
$WP_CLI theme delete $($WP_CLI theme list --status=inactive --field=name)
echo "   ✅ Plugins installés et nettoyage terminé."

# --- ÉTAPE 4: FINALISATION ---
echo "➡️  ÉTAPE 4: Sauvegarde de l'URL d'installation..."
echo "$APP_URL" > .lando-url.txt
echo "   URL sauvegardée dans .lando-url.txt (à la racine du projet)."

echo "🎉🎉🎉 CONFIGURATION TERMINÉE AVEC SUCCÈS ! 🎉🎉🎉"
echo "Votre site est prêt et accessible à l'adresse : ${APP_URL}"