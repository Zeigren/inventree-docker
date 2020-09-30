# Docker Stack For [InvenTree](https://github.com/inventree/InvenTree)

[![Docker Hub](https://img.shields.io/docker/cloud/build/zeigren/inventree)](https://hub.docker.com/r/zeigren/inventree)
[![MicroBadger](https://images.microbadger.com/badges/image/zeigren/inventree.svg)](https://microbadger.com/images/zeigren/inventree)
[![MicroBadger](https://images.microbadger.com/badges/version/zeigren/inventree.svg)](https://microbadger.com/images/zeigren/inventree)
[![MicroBadger](https://images.microbadger.com/badges/commit/zeigren/inventree.svg)](https://microbadger.com/images/zeigren/inventree)
![Docker Pulls](https://img.shields.io/docker/pulls/zeigren/inventree)

## Usage

Use [Docker Compose](https://docs.docker.com/compose/) or [Docker Swarm](https://docs.docker.com/engine/swarm/) to deploy InvenTree for either development or production. Templates included for using NGINX or Traefik for SSL termination.

## Links

### [Docker Hub](https://hub.docker.com/r/zeigren/inventree)

### [GitHub](https://github.com/Zeigren/inventree-docker)

## Tags

Tags follow this naming scheme:

- \*.\*.\* - InvenTree Release Tag
- InvenTree Tag-Commit Stub (A commit on master newer than the InvenTree Release Tag)
- latest (this will be the same as the newest InvenTree Tag-Commit Stub)

Using the Release Tags is recommended.

### Release Tags

- v0.1.3
- 0.1.1
- 0.1.0
- 0.0.10
- 0.0.8

## Stack

- [Python:Alpine](https://hub.docker.com/_/python) for InvenTree
- [NGINX:Alpine](https://hub.docker.com/_/nginx)
- [MariaDB:10](https://hub.docker.com/_/mariadb)

### For Development

- [phpMyAdmin](https://hub.docker.com/r/phpmyadmin/phpmyadmin/)

## Configuration

Configuration consists of variables in the `.yml` and `.conf` files.

- inventree_vhost = A simple NGINX vhost file for InvenTree (templates included, use `inventree_vhost_ssl` if you're using NGINX for SSL termination)
- Make whatever changes you need to the appropriate `.yml`. All environment variables for InvenTree can be found in `docker-entrypoint.sh`

### Using NGINX for SSL Termination

- yourdomain.com.crt = The SSL certificate for your domain (you'll need to create/copy this)
- yourdomain.com.key = The SSL key for your domain (you'll need to create/copy this)

### [Docker Compose](https://docs.docker.com/compose/)

Using [multiple Docker Compose files](https://docs.docker.com/compose/extends/#multiple-compose-files) makes it easier to differentiate between use cases. `docker-compose.yml` is the base configuration file and `production.yml` or `development.yml` are used to either add to or override the base configuration.

Clone the [repository](https://github.com/Zeigren/inventree-docker), create a `config` folder inside the `inventree-docker` directory, and put the relevant configuration files you created/modified into it.

Run with `docker-compose -f docker-compose.yml -f production.yml up -d`. View using `127.0.0.1:9080`.

### [Docker Swarm](https://docs.docker.com/engine/swarm/)

I personally use this with [Traefik](https://traefik.io/) as a reverse proxy, I've included an example `traefik.yml` but it's not necessary.

You'll need to create the appropriate [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/) and [Docker Configs](https://docs.docker.com/engine/swarm/configs/).

Run with `docker stack deploy --compose-file docker-swarm.yml inventree`

## Deployment

On first run you'll need to create a superuser using the variables in the `.yml` file. You will also need to migrate the database and collect static files by changing the `MIGRATE_STATIC` variable in the `.yml` file, this also needs to be done everytime InvenTree is updated.

## Theory of operation

### InvenTree

The [Dockerfile](https://docs.docker.com/engine/reference/builder/) uses [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/), [build hooks](https://docs.docker.com/docker-hub/builds/advanced/#build-hook-examples), and [labels](http://label-schema.org/rc1/#build-time-labels) for automated builds on Docker Hub.

The multi-stage build creates a container that can be used for development and another for production. The development container has all the build dependencies for the python packages which are installed into a [python virtual environment](https://docs.python.org/3/tutorial/venv.html). The production container copies the python virtual environment from the development container and runs InvenTree from there, this allows it to be much more lightweight.

On startup, the container first runs the `docker-entrypoint.sh` script before running the `gunicorn -c gunicorn.conf.py InvenTree.wsgi` command.

`docker-entrypoint.sh` creates configuration files and runs commands based on environment variables that are declared in the various `.yml` files.

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
