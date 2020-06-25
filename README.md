# Docker For [InvenTree](https://github.com/inventree/InvenTree)

[![Docker Hub](https://img.shields.io/docker/cloud/build/zeigren/inventree)](https://hub.docker.com/r/zeigren/inventree)
[![MicroBadger](https://images.microbadger.com/badges/image/zeigren/inventree.svg)](https://microbadger.com/images/zeigren/inventree)
[![MicroBadger](https://images.microbadger.com/badges/version/zeigren/inventree.svg)](https://microbadger.com/images/zeigren/inventree)
[![MicroBadger](https://images.microbadger.com/badges/commit/zeigren/inventree.svg)](https://microbadger.com/images/zeigren/inventree)
![Docker Pulls](https://img.shields.io/docker/pulls/zeigren/inventree)

## [Docker Hub](https://hub.docker.com/r/zeigren/inventree)

## [GitHub](https://github.com/Zeigren/inventree-docker)

## Stack

- [Python:Alpine](https://hub.docker.com/_/python) for InvenTree
- [Nginx:Alpine](https://hub.docker.com/_/nginx)
- [MariaDB:10](https://hub.docker.com/_/mariadb)

### For Development

- [phpMyAdmin](https://hub.docker.com/r/phpmyadmin/phpmyadmin/)

## Tags

Tags follow this naming scheme:

- \*.\*.\* - InvenTree Release Tag
- InvenTree Tag-Commit Stub (A commit on master newer than the InvenTree Release Tag)
- latest (this will be the same as the newest InvenTree Tag-Commit Stub)

### Release Tags

- 0.1.1
- 0.1.0
- 0.0.10
- 0.0.8

## Usage

Use [Docker Compose](https://docs.docker.com/compose/) or [Docker Swarm](https://docs.docker.com/engine/swarm/) to deploy InvenTree for either development or production.

Clone the [GitHub](https://github.com/Zeigren/inventree-docker) repository and create a `config` folder inside the `inventree-docker` directory.

I like using [Portainer](https://www.portainer.io/) since it makes all the tinkering easier, but it's not necessary.

### Quick Test

To give it a quick test copy the `inventree_dev_vhost.conf` file into the config folder and run the `docker-compose -f docker-compose.yml -f test.yml up -d` command in the `inventree-docker` directory. This will pull all the Docker images and run them.

Once they're running edit the `docker-compose.yml` file and change `MIGRATE_STATIC` and `CREATE_SUPERUSER` to `True`, then run `docker-compose -f docker-compose.yml -f test.yml up -d` again. This initializes the database, collects all the static files, and creates a superuser.

Open up a web browser and go to `127.0.0.1:9080` and login with user `admin` and password `admin`, now you're good to go!

### Configuration

Configuration consists of environment variables in the `docker-compose.yml`, `test.yml`, `development.yml`, `production.yml`, and `docker-stack.yml` files or as files contained in the `config` folder.

Using [multiple Docker Compose files](https://docs.docker.com/compose/extends/#multiple-compose-files) makes it easier to differentiate between use cases. `docker-compose.yml` is the base configuration file and `test.yml`, `development.yml`, and `production.yml` are used to either add or override the base configuration.

#### `docker-compose.yml`

Settings for MariaDB

- MYSQL_ROOT_PASSWORD=CHANGEME
- MYSQL_DATABASE=inventree
- MYSQL_USER=inventree
- MYSQL_PASSWORD=CHANGEME

Migrate database and collect static files. Use on first run and when upgrading InvenTree.

- MIGRATE_STATIC=True

Create a superuser, should only be used once then deleted

- CREATE_SUPERUSER=True
- DJANGO_SUPERUSER_USERNAME=admin
- DJANGO_SUPERUSER_EMAIL=admin@admin.com
- DJANGO_SUPERUSER_PASSWORD=admin
  
Check `docker-entrypoint.sh` for more options.

#### `test.yml`, `development.yml`, and `production.yml`

Enable debug

- DEBUG=True

#### Config Files

The configuration files that can be placed in the `config` folder are:

- inventree_dev_vhost.conf = A simple Nginx vhost file for InvenTree, for development and local testing
- inventree_prod_vhost.conf = Nginx vhost file for InvenTree that includes SSL termination (simply replace all instances of `YOURDOMAIN`)
- YOURDOMAIN.com.crt = The SSL certificate for your domain (you’ll need to create/copy this)
- YOURDOMAIN.com.key = The SSL key for your domain (you’ll need to create/copy this)
- dhparam.pem = Diffie-Hellman parameter (you’ll need to create/copy this)
- secret_key.txt = A secret key for Django

For Development:
dev_requirements.txt = A pip requirements file that can be used in development (example provided)

### Production

Replace all instances of `YOURDOMAIN` in `production.yml` and `inventree_prod_vhost.conf`. Then run `docker-compose -f docker-compose.yml -f production.yml up -d`. If you want to use a specific version of InvenTree change the image used in `production.yml`.

### [Docker Swarm](https://docs.docker.com/engine/swarm/)

I use this with [Traefik](https://traefik.io/) as a reverse proxy, but it’s not necessary.

You’ll need to create these [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/):

- YOURDOMAIN.com.crt = The SSL certificate for your domain (you’ll need to create/copy this)
- YOURDOMAIN.com.key = The SSL key for your domain (you’ll need to create/copy this)
- dhparam.pem = Diffie-Hellman parameter (you’ll need to create/copy this)
- InvenTreesql_root_password = Root password for your SQL database
- InvenTreesql_password = InvenTree user password for your SQL database
- secret_key = A secret key for Django

You’ll also need to create this [Docker Config](https://docs.docker.com/engine/swarm/configs/):

- inventree_vhost = The Nginx vhost file for InvenTree (use the inventree_prod_vhost.conf template and simply replace all instances of `YOURDOMAIN`)

Make whatever changes you need to docker-stack.yml (replace all instances of `YOURDOMAIN`).

Run with `docker stack deploy --compose-file docker-stack.yml inventree`

## Theory of operation

### InvenTree

The [Dockerfile](https://docs.docker.com/engine/reference/builder/) uses [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/), [build hooks](https://docs.docker.com/docker-hub/builds/advanced/#build-hook-examples), and [labels](http://label-schema.org/rc1/#build-time-labels) for automated builds on Docker Hub.

The multi-stage build creates a container that can be used for development and another for production. The development container has all the build dependencies for the python packages which are installed into a [python virtual environment](https://docs.python.org/3/tutorial/venv.html). The production container copies the python virtual environment from the development container and runs InvenTree from there, this allows it to be much more lightweight.

On startup, the container first runs the `docker-entrypoint.sh` script before running the `gunicorn -c gunicorn.conf.py InvenTree.wsgi` command.

`docker-entrypoint.sh` creates configuration files and runs commands based on environment variables that are declared in the various compose files.

`env_secrets_expand.sh` handles using Docker Secrets.

### Nginx

Used as a web server. It serves up the static files and passes everything else off to gunicorn/InvenTree.

### MariaDB

SQL database.

## Development

### Run

Clone the [InvenTree](https://github.com/inventree/InvenTree) repository into a folder called `InvenTree` and build the development Docker image by running `docker build . --target development -t inventree:development`. Then use `docker-compose -f docker-compose.yml -f development.yml up -d` to grab all the other Docker images and run InvenTree.

### InvenTree Development

The clone you made of InvenTree replaces the one in the Docker container when the container is started (as seen in `development.yml`). So any changes you make are reflected in the Docker container (you may need to restart the container for those changes to take effect).

If you want to develop/test using the production container you can build it using `docker build . --target production -t inventree:production`, then change the image tag in `development.yml`.

### Python

If you need to change which python packages are installed you can create/alter the `dev_requirements.txt` file and uncomment the line in the `Dockerfile`. Then run `docker build . --target development -t inventree:development`  to rebuild the container, this will install `dev_requirements.txt` instead of the default InvenTree `requirements.txt`.

### Docs

If you installed the required packages using `dev_requirements.txt` you can make the docs by running `docker exec -it inventree -w /usr/src/app make docs`.

### phpMyAdmin

Useful for database administration, you can connect to phpMyAdmin at `127.0.0.1:6060`.

### VSCode

You can use VSCode to work in the container directly on either your computer or a remote one. I've included a sample `devcontainer.json` for that purpose. You'll need to check the [official documentation](https://code.visualstudio.com/docs/remote/containers) to set that up.
