#!/bin/bash

# Exit on any error
set -e

# Save the module's root directory to return to it later.
readonly MODULE_DIR="$(pwd)"

readonly src_nginx="src"
readonly dst_nginx="/etc/nginx"

# The SERVER_NAME is inherited from the main installer.sh script.
: "${SERVER_NAME:?ERROR: SERVER_NAME environment variable is not set. Please define it in the main installer.}"
# The APP_USER is inherited from the main installer.sh script for consistency.
: "${APP_USER:?ERROR: APP_USER environment variable is not set. Please define it in the main installer.}"

## install nginx
cp -r src/logrotate-nginx /etc/logrotate.d/nginx
echo "--- Adding Nginx PPA ---"
add-apt-repository -y ppa:ondrej/nginx
echo "--- Updating package lists ---"
apt-get update -y

echo "--- Installing Nginx from PPA ---"
apt-get install -y --no-install-recommends nginx

# --- Configure Nginx ---

# Return to the module's directory to ensure relative paths for configs are correct.
cd "$MODULE_DIR"

echo "--- Removing default Nginx configurations ---"
rm -rf $dst_nginx/sites-enabled/* $dst_nginx/conf.d/*

echo "--- Copying Nginx configurations ---"
cp -r $src_nginx/nginx.conf $dst_nginx/nginx.conf
cp -r $src_nginx/sites-available/* $dst_nginx/sites-available/.
cp -r $src_nginx/conf.d/* $dst_nginx/conf.d/.

ln -sf $dst_nginx/sites-available/http.conf $dst_nginx/sites-enabled/http.conf

echo "--- Setting up web root and error page directories ---"
mkdir -p /usr/share/nginx/html

echo "--- Copying main index page to site root ---"
cp -r $src_nginx/html/index.html /home/${APP_USER}/site/
chown -R ${APP_USER}:${APP_USER} /home/${APP_USER}/site

echo "--- Copying custom error pages ---"
cp -r $src_nginx/html/{403,404,500,502,503,504}.html /usr/share/nginx/html/
chown -R ${APP_USER}:${APP_USER} /usr/share/nginx/html

echo "--- Setting server name in configuration files ---"
# Replace the placeholder in the Nginx site configuration and all HTML pages.
sed -i "s/__SERVER_NAME__/${SERVER_NAME}/g" "$dst_nginx/sites-available/default.conf"
sed -i "s/__SERVER_NAME__/${SERVER_NAME}/g" "$dst_nginx/sites-available/http.conf"
sed -i "s/__SERVER_NAME__/${SERVER_NAME}/g" "$dst_nginx/sites-available/https.conf"
sed -i "s/__SERVER_NAME__/${SERVER_NAME}/g" /home/${APP_USER}/site/index.html
sed -i "s/__SERVER_NAME__/${SERVER_NAME}/g" /usr/share/nginx/html/*.html

echo "--- Enabling Nginx service ---"
systemctl enable nginx
echo "--- Restarting Nginx service ---"
systemctl restart nginx
echo "--- Finished Nginx installation ---"
