FROM python:slim

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

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV INVENTREE_ROOT="/usr/src/app"
ENV INVENTREE_HOME="/usr/src/app/InvenTree"
ENV INVENTREE_STATIC="/usr/src/static"
ENV INVENTREE_MEDIA="/usr/src/media"

# install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git libmariadb-dev gcc libjpeg-dev zlib1g-dev make

RUN if [[ "${VERSION}" =~ "-" ]] ; then \
    git clone --branch master --single-branch https://github.com/inventree/InvenTree.git ${INVENTREE_ROOT} ; \
    else git clone --branch ${VERSION} --single-branch https://github.com/inventree/InvenTree.git ${INVENTREE_ROOT}; fi

#uncomment to install new requirements in development
#COPY ./InvenTree/requirements.txt ${INVENTREE_ROOT}/requirements.txt

RUN pip install --no-cache-dir -U -r \
    ${INVENTREE_ROOT}/requirements.txt mysqlclient gunicorn 

# create the appropriate directories and clean
RUN mkdir ${INVENTREE_STATIC} \
    && mkdir ${INVENTREE_MEDIA}

# entrypoint scripts
COPY env_secrets_expand.sh docker-entrypoint.sh /

RUN chmod +x /env_secrets_expand.sh \
    && chmod +x /docker-entrypoint.sh

WORKDIR ${INVENTREE_HOME}

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["gunicorn", "-c", "gunicorn.conf.py", "InvenTree.wsgi"]