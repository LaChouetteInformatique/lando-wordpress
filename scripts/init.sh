#!/bin/bash
# ~/wordpress_template/scripts/init.sh - Version 18 (Avec nettoyage)

set -e
cd /app

WP_CLI="/usr/local/bin/wp"
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

echo "--- DÉMARRAGE DU SCRIPT DE CONFIGURATION (v18) ---"
echo "URL de configuration : ${APP_URL}"

# --- On vérifie si l'installation est déjà faite ---
if [ -f "wp-config.php" ]; then
    echo "✅ Le fichier wp-config.php existe déjà. Installation annulée."
    exit 0
fi

# --- ÉTAPE 1: TÉLÉCHARGEMENT DE WORDPRESS ---
echo "➡️  ÉTAPE 1: Téléchargement des fichiers de WordPress Core..."
$WP_CLI core download --locale=fr_FR --force
echo "   ✅ Fichiers de WordPress téléchargés."

# --- ÉTAPE 2: CONFIGURATION ---
echo "➡️  ÉTAPE 2: Configuration de WordPress..."
source /app/config.env
$WP_CLI config create --dbname=wordpress --dbuser=wordpress --dbpass=wordpress --dbhost=database --force
$WP_CLI core install --url="$APP_URL" --title="$WP_TITLE" --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASS" --admin_email="$WP_ADMIN_EMAIL"
echo "✅ WordPress configuré avec l'URL : ${APP_URL}"

# --- ÉTAPE 3: PLUGINS ---
echo "➡️  ÉTAPE 3: Installation des plugins désirés..."
for plugin in $PLUGINS_LIST; do $WP_CLI plugin install "$plugin" --activate; done
for plugin_zip in /app/plugins-premium/*.zip; do [ -f "$plugin_zip" ] && $WP_CLI plugin install "$plugin_zip" --activate; done
echo "   ✅ Plugins désirés installés."

# --- ÉTAPE 4: NETTOYAGE POST-INSTALLATION ---
echo "➡️  ÉTAPE 4: Nettoyage des thèmes et plugins par défaut..."
# Supprimer les plugins par défaut
$WP_CLI plugin delete akismet
$WP_CLI plugin delete hello
echo "   ✅ Plugins par défaut (Akismet, Hello Dolly) supprimés."

# Supprimer les thèmes inactifs
ACTIVE_THEME=$($WP_CLI theme list --status=active --field=name)
echo "   Thème actif détecté : $ACTIVE_THEME. Suppression des autres thèmes..."
for theme in $($WP_CLI theme list --status=inactive --field=name); do
    $WP_CLI theme delete "$theme"
done
echo "   ✅ Thèmes inactifs supprimés."

# --- ÉTAPE 5: FINALISATION ---
echo "➡️  ÉTAPE 5: Sauvegarde de l'URL d'installation..."
echo "$APP_URL" > .lando-url.txt
echo "   URL sauvegardée dans .lando-url.txt"

echo "🎉🎉🎉 CONFIGURATION TERMINÉE AVEC SUCCÈS ! 🎉🎉🎉"
echo "Votre site est prêt et accessible à l'adresse : ${APP_URL}"