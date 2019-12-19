#!/bin/sh

source /env_secrets_expand.sh

set -e

if [ ! -f "$INVENTREE_HOME/config.yaml" ]; then
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

# Set debug to False to run in production mode
debug: ${DEBUG:-True}

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

# Logging options
# If debug mode is enabled, set log_queries to True to show aggregate database queries in the debug console
log_queries: ${LOG_QUERIES:-False}

# Backup options
# Set the backup_dir parameter to store backup files in a specific location
# If unspecified, the local user's temp directory will be used
backup_dir: ${BACKUP_DIR:-'/home/inventree/backup/'}
EOF
fi

if [ ! -f "$INVENTREE_HOME/secret_key.txt" ] && [ "${SECRET_KEY}" != "" ] ;
  then cat > "$INVENTREE_HOME/secret_key.txt" <<EOF
    ${SECRET_KEY}
EOF
  else
    python setup.py ;
fi

if [ "$MIGRATE_STATIC" = "true" ]; then
  make -C /usr/src/app/ migrate
  python manage.py collectstatic --noinput
fi

exec "$@"
