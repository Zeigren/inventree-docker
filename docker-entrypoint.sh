#!/bin/sh
source /env_secrets_expand.sh
set -e

cat > "$INVENTREE_HOME/config.yaml" <<EOF
# Database backend selection - Configure backend database settings
# Ref: https://docs.djangoproject.com/en/2.2/ref/settings/#std:setting-DATABASES
# Specify database parameters below as they appear in the Django docs
database:
  
  # Example Configuration - MySQL
  ENGINE: ${DATABASE_ENGINE:-django.db.backends.mysql}
  NAME: ${DATABASE_NAME:-inventree}
  USER: ${DATABASE_USER:-inventree}
  PASSWORD: ${DATABASE_PASSWORD:-CHANGEME}
  HOST: ${DATABASE_HOST:-mariadb}
  PORT: ${DATABASE_PORT:-3306}

# Select default system language (default is 'en-us')
language: ${DEFAULT_LANGUAGE:-en-us}

# System time-zone (default is UTC)
# Reference: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
# Select an option from the "TZ database name" column
timezone: ${TIMEZONE:-UTC}

# List of currencies supported by default.
# Add other currencies here to allow use in InvenTree
currencies:
  - AUD
  - CAD
  - EUR
  - GBP
  - JPY
  - NZD
  - USD

# Set debug to False to run in production mode
debug: ${DEBUG:-False}

# Set debug_toolbar to True to enable a debugging toolbar for InvenTree
# Note: This will only be displayed if DEBUG mode is enabled, 
#       and only if InvenTree is accessed from a local IP (127.0.0.1)
debug_toolbar: ${DEBUG_TOOLBAR:-False}

# Configure the system logging level
# Options: DEBUG / INFO / WARNING / ERROR / CRITICAL
log_level: WARNING

# Allowed hosts (see ALLOWED_HOSTS in Django settings documentation)
# A list of strings representing the host/domain names that this Django site can serve.
# Default behaviour is to allow all hosts (THIS IS NOT SECURE!)
allowed_hosts:
  - ${ALLOWED_HOSTS:-'*'}

# Cross Origin Resource Sharing (CORS) settings (see https://github.com/ottoyiu/django-cors-headers)
# Following parameters are 
cors:
  # CORS_ORIGIN_ALLOW_ALL - If True, the whitelist will not be used and all origins will be accepted.
  allow_all: ${CORS_ALLOW_ALL:-True}
  
  # CORS_ORIGIN_WHITELIST - A list of origins that are authorized to make cross-site HTTP requests. Defaults to []
  # whitelist:
  # - https://example.com
  # - https://sub.example.com

# MEDIA_ROOT is the local filesystem location for storing uploaded files
# By default, it is stored in a directory named 'media' local to the InvenTree directory
# This should be changed for a production installation
media_root: ${MEDIA_ROOT:-'/usr/src/media'}

# STATIC_ROOT is the local filesystem location for storing static files
# By default it is stored in a directory named 'static' local to the InvenTree directory
static_root: ${STATIC_ROOT:-'/usr/src/static'}

# Optional URL schemes to allow in URL fields
# By default, only the following schemes are allowed: ['http', 'https', 'ftp', 'ftps']
# Uncomment the lines below to allow extra schemes
#extra_url_schemes:
#  - mailto
#  - git
#  - ssh

# Backup options
# Set the backup_dir parameter to store backup files in a specific location
# If unspecified, the local user's temp directory will be used
backup_dir: ${BACKUP_DIR:-'/home/inventree/backup/'}

# Permit custom authentication backends
#authentication_backends:
#  - 'django.contrib.auth.backends.ModelBackend'

#  Custom middleware, sometimes needed alongside an authentication backend change.
#middleware:
#  - 'django.middleware.security.SecurityMiddleware'
#  - 'django.contrib.sessions.middleware.SessionMiddleware'
#  - 'django.middleware.locale.LocaleMiddleware'
#  - 'django.middleware.common.CommonMiddleware'
#  - 'django.middleware.csrf.CsrfViewMiddleware'
#  - 'corsheaders.middleware.CorsMiddleware'
#  - 'django.contrib.auth.middleware.AuthenticationMiddleware'
#  - 'django.contrib.messages.middleware.MessageMiddleware'
#  - 'django.middleware.clickjacking.XFrameOptionsMiddleware'
#  - 'InvenTree.middleware.AuthRequiredMiddleware'
EOF

if [ ! -f "$INVENTREE_HOME/secret_key.txt" ]; then
  cat > "$INVENTREE_HOME/password.awk" <<EOF
BEGIN {
    srand();
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    s = "";
    for(i=0;i<50;i++) {
        s = s "" substr(chars, int(rand()*62), 1);
    }
    print s
}

EOF
  awk -f password.awk > "$INVENTREE_HOME/secret_key.txt"
  rm password.awk
fi

echo "Test connection to database"

/wait-for.sh ${DATABASE_HOST:-mariadb}:${DATABASE_PORT:-3306} -- echo 'Success!'

echo "Give the database a few seconds to warm up"

sleep 5s

if [ "$MIGRATE_STATIC" = "True" ]; then
  echo "Running InvenTree database migrations and collecting static files..."
  python manage.py makemigrations
  python manage.py migrate
  python manage.py migrate --run-syncdb
  python manage.py check
  python manage.py collectstatic --noinput
  echo "InvenTree static files collected and database migrations completed!"
fi

if [ "$CREATE_SUPERUSER" = "True" ]; then
  python manage.py createsuperuser --noinput
fi

exec "$@"
