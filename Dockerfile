# VERSION 1.10.1
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

# Disclaimer: I take no credit for this Dockerfile. It is a copy of the original
# with a minor change to have git available. Please start from the original Dockerfile
# for your own setup.

FROM python:3.8-slim

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
## Update verison in requirements.txt as well.
ARG AIRFLOW_HOME=/usr/local/airflow
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
ENV AIRFLOW_GPL_UNIDECODE yes
ENV PYTHONPATH "/home/airflow/cj-airflow-dags"

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

RUN set -ex \
    && buildDeps=' \
        freetds-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        libpq-dev \
        libsasl2-dev \
        gcc \
        python-dev \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        freetds-bin \
        build-essential \
        default-libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
        git \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && pip install -U pip setuptools wheel
RUN apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

COPY script/entrypoint.sh /entrypoint.sh
COPY ../cj-airflow-dags/requirements.txt requirements.txt
ARG PIP_INDEX_URL
RUN pip install -r requirements.txt

RUN mkdir -p /usr/local/airflow/dags/repo
ADD . /usr/local/airflow/dags/repo/
ADD docker/script/* /usr/local/airflow/dags/repo/

WORKDIR ${AIRFLOW_HOME}
ARG GIT_VERSION=NOT SET
RUN mkdir ${AIRFLOW_HOME}/airflow/ && echo "$GIT_VERSION" > ${AIRFLOW_HOME}/airflow/git_version
ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"]
