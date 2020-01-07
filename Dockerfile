FROM python:alpine AS development

ARG VERSION=master

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV INVENTREE_ROOT="/usr/src/app"
ENV INVENTREE_HOME="/usr/src/app/InvenTree"
ENV INVENTREE_STATIC="/usr/src/static"
ENV INVENTREE_MEDIA="/usr/src/media"
ENV VIRTUAL_ENV="/opt/venv"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN apk add --no-cache \
    gcc mariadb-dev libjpeg-turbo-dev zlib-dev git musl-dev make

# Uncomment COPY and change DEV="True" to install new requirements in development
#COPY dev_requirements.txt /usr/src/dev_requirements.txt
ENV DEV="False"

RUN if echo $VERSION | grep -Eq - ; \
    then git clone --branch master --depth 1 https://github.com/inventree/InvenTree.git ${INVENTREE_ROOT} ; \
    else git clone --branch ${VERSION} --depth 1 https://github.com/inventree/InvenTree.git ${INVENTREE_ROOT} ; fi \
    && python -m venv $VIRTUAL_ENV \
    && pip install --upgrade pip \
    && if [ $DEV = True ] ; \
    then pip install --no-cache-dir -U -r /usr/src/dev_requirements.txt mysqlclient gunicorn ; \
    else pip install --no-cache-dir -U -r /usr/src/app/requirements.txt mysqlclient gunicorn ; fi

COPY env_secrets_expand.sh docker-entrypoint.sh /

RUN chmod +x /env_secrets_expand.sh \
    && chmod +x /docker-entrypoint.sh

WORKDIR ${INVENTREE_HOME}

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["gunicorn", "-c", "gunicorn.conf.py", "InvenTree.wsgi"]


FROM python:alpine AS production

ARG BRANCH
ARG COMMIT
ARG DATE
ARG URL
ARG VERSION=master

LABEL org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=$DATE \
    org.label-schema.vendor="Zeigren" \
    org.label-schema.name="zeigren/inventree" \
    org.label-schema.url="https://hub.docker.com/r/zeigren/inventree" \
    org.label-schema.version="$VERSION" \
    org.label-schema.vcs-url=$URL \
    org.label-schema.vcs-branch=$BRANCH \
    org.label-schema.vcs-ref=$COMMIT

ENV PYTHONUNBUFFERED 1
ENV INVENTREE_ROOT="/usr/src/app"
ENV INVENTREE_HOME="/usr/src/app/InvenTree"
ENV VIRTUAL_ENV="/opt/venv"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN apk add --no-cache \
    mariadb-connector-c git make libjpeg-turbo zlib

COPY --from=development $VIRTUAL_ENV $VIRTUAL_ENV
COPY --from=development $INVENTREE_ROOT $INVENTREE_ROOT
COPY env_secrets_expand.sh docker-entrypoint.sh /

RUN chmod +x /env_secrets_expand.sh \
    && chmod +x /docker-entrypoint.sh

WORKDIR ${INVENTREE_HOME}

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["gunicorn", "-c", "gunicorn.conf.py", "InvenTree.wsgi"]