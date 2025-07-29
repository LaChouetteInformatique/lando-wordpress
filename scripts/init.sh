#!/bin/bash
# ~/wordpress_template/scripts/init.sh - Final Version (Uses all env variables)

set -e
# Change directory to the Lando project root inside the container
cd /app

# Define the WordPress path and the WP-CLI command with the correct path
WP_DIR="/app/app"
WP_CLI="/usr/local/bin/wp --path=$WP_DIR"
APP_URL=""

# --- STEP 0: READ THE --url ARGUMENT ---
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
    echo "❌ ERROR: You must provide the site URL as an argument."
    echo "   USAGE: lando install -- --url=http://your-site.lndo.site:PORT"
    exit 1
fi

echo "--- STARTING CONFIGURATION SCRIPT (Final Version) ---"
echo "Configuration URL: ${APP_URL}"

# Create the application directory if it doesn't exist
mkdir -p $WP_DIR

# --- Check if the installation is already done ---
if [ -f "$WP_DIR/wp-config.php" ]; then
    echo "✅ wp-config.php file already exists. Installation cancelled."
    exit 0
fi

# --- STEP 1: DOWNLOAD WORDPRESS ---
echo "➡️  STEP 1: Downloading WordPress Core files..."
$WP_CLI core download --locale=en_US --force
echo "   ✅ WordPress files downloaded in $WP_DIR."

# --- STEP 2: CONFIGURATION ---
echo "➡️  STEP 2: Configuring WordPress..."
source /app/config.env
# THIS IS THE CORRECTED LINE - It now uses the variables from the config file.
$WP_CLI config create --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --dbhost="$DB_HOST" --force
$WP_CLI core install --url="$APP_URL" --title="$WP_TITLE" --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASS" --admin_email="$WP_ADMIN_EMAIL"
echo "✅ WordPress configured with URL: ${APP_URL}"

# --- STEP 3: PLUGINS & CLEANUP ---
echo "➡️  STEP 3: Installing plugins and cleaning up..."
for plugin in $PLUGINS_LIST; do $WP_CLI plugin install "$plugin" --activate; done
for plugin_zip in /app/plugins-premium/*.zip; do [ -f "$plugin_zip" ] && $WP_CLI plugin install "$plugin_zip" --activate; done
$WP_CLI plugin delete akismet hello
$WP_CLI theme delete $($WP_CLI theme list --status=inactive --field=name)
echo "   ✅ Plugins installed and cleanup finished."

# --- STEP 4: FINALIZATION ---
echo "➡️  STEP 4: Saving the installation URL..."
echo "$APP_URL" > .lando-url.txt
echo "   URL saved to .lando-url.txt (in the project root)."

echo "🎉🎉🎉 CONFIGURATION FINISHED SUCCESSFULLY! 🎉🎉🎉"
echo "Your site is ready and accessible at: ${APP_URL}"