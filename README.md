[![Docker Hub](https://img.shields.io/docker/cloud/build/zeigren/inventree)](https://hub.docker.com/r/zeigren/inventree)

## Docker For [InvenTree](https://github.com/inventree/InvenTree)

### [Docker Hub](https://hub.docker.com/r/zeigren/inventree)

### [GitHub](https://github.com/Zeigren/inventree-docker)

### Stack

- Python:Slim - InvenTree and Gunicorn
- [Nginx:Alpine](https://hub.docker.com/_/nginx)
- [Mariadb:10](https://hub.docker.com/_/mariadb)

## Usage

Use [Docker Compose](https://docs.docker.com/compose/) or [Docker Swarm](https://docs.docker.com/engine/swarm/) to deploy InvenTree for either development or production.

Clone the [GitHub](https://github.com/Zeigren/inventree-docker) repository and create a `config` folder inside the `inventree-docker` directory.

I like using [Portainer](https://www.portainer.io/) since it makes all the tinkering easier, but it's not necessary.

### Quick Test

To give it a quick test copy the `inventree_dev_vhost.conf` file into the config folder and run the `docker-compose -f docker-compose.yml -f test.yml up -d` command in the `inventree-docker` directory. This will pull all the Docker images and run them.

Once they're running edit the `docker-compose.yml` file and change `MIGRATE_STATIC` to `True`, then run `docker-compose -f docker-compose.yml -f test.yml up -d` again (this step will be fixed at some point). This does all the database initialization and collects all the static files.

Now you’ll need to create the superuser run `docker exec -it inventree python manage.py createsuperuser`. Open up a web browser and go to `127.0.0.1:9080` and you`re good to go!

### Configuration

Configuration consists of environment variables in the `docker-compose.yml`, `test.yml`, `development.yml`, `production.yml`, and `docker-stack.yml` files or as files contained in the `config` folder.

Using [multiple Docker Compose files](https://docs.docker.com/compose/extends/#multiple-compose-files) makes it easier to differentiate between use cases. `docker-compose.yml` is the base configuration file and `test.yml`, `development.yml`, and `production.yml` are used to either add or override the base configuration.

#### `docker-compose.yml`

Settings for mariadb

- MYSQL_ROOT_PASSWORD=CHANGEME
- MYSQL_DATABASE=inventree
- MYSQL_USER=inventree
- MYSQL_PASSWORD=CHANGEME

Database migration and collects the static files, use as needed

- MIGRATE_STATIC=false

#### `test.yml`, `development.yml`, and `production.yml`

Enable debug

- DEBUG=True

#### Config Files

The configuration files that can be placed in the `config` folder are:

- inventree_dev_vhost.conf = A simple nginx vhost file for InvenTree, for development and local testing
- inventree_prod_vhost.conf = nginx vhost file for InvenTree that includes ssl termination (simply replace all instances of `YOURDOMAIN`)
- YOURDOMAIN.com.crt = The SSL certificate for your domain (you’ll need to create/copy this)
- YOURDOMAIN.com.key = The SSL key for your domain (you’ll need to create/copy this)
- dhparam.pem = Diffie-Hellman parameter (you’ll need to create/copy this)
- secret_key.txt = A secret key for Django

### Development

Clone the [InvenTree](https://github.com/inventree/InvenTree) repository into a folder called `InvenTree` and run `docker-compose -f docker-compose.yml -f development.yml up -d`. This will grab all the Docker images and build InvenTree.

If you’re `requirements.txt` doesn’t match the official repository uncomment the line in the `Dockerfile`.

To re-build the Docker image run `docker build . -t inventree:development`.

### Production

Replace all instances of `YOURDOMAIN` in `production.yml` and `inventree_prod_vhost.conf`. Then run `docker-compose -f docker-compose.yml -f production.yml up -d`. If you want to use a specific version of InvenTree change the image used in `production.yml`.

### [Docker Swarm](https://docs.docker.com/engine/swarm/)

I personally use this with [Traefik](https://traefik.io/) as a reverse proxy, but it’s not necessary.

You’ll need to create these [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/):

- YOURDOMAIN.com.crt = The SSL certificate for your domain (you’ll need to create/copy this)
- YOURDOMAIN.com.key = The SSL key for your domain (you’ll need to create/copy this)
- dhparam.pem = Diffie-Hellman parameter (you’ll need to create/copy this)
- InvenTreesql_root_password = Root password for your SQL database
- InvenTreesql_password = InvenTree user password for your SQL database
- secret_key = A secret key for Django

You’ll also need to create this [Docker Config](https://docs.docker.com/engine/swarm/configs/):

- inventree_vhost = The nginx vhost file for InvenTree (use the inventree_prod_vhost.conf template and simply replace all instances of `YOURDOMAIN`)

Make whatever changes you need to docker-stack.yml (replace all instances of `YOURDOMAIN`).

Run with `docker stack deploy --compose-file docker-stack.yml inventree`

## Theory of operation

### InvenTree

The [Dockerfile](https://docs.docker.com/engine/reference/builder/) uses [build hooks](https://docs.docker.com/docker-hub/builds/advanced/#build-hook-examples) and [labels](http://label-schema.org/rc1/#build-time-labels) for automated builds on Docker Hub.

The container first runs the `docker-entrypoint.sh` script before running the `gunicorn -c gunicorn.conf.py InvenTree.wsgi` command.

`docker-entrypoint.sh` creates configuration files and runs commands based on environment variables that are declared in the various compose files.

`env_secrets_expand.sh` handles using Docker Secrets.

### Nginx

Used as a web server. It serves up the static files and passes everything else off to gunicorn/InvenTree.

### Mariadb

SQL database.