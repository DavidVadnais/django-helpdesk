# --- Stage 1: Build frontend assets ---
FROM node:20 AS frontend-builder

WORKDIR /opt/django-helpdesk

# Copy only the files needed for Yarn install/build
COPY django-helpdesk/package.json django-helpdesk/yarn.lock ./

# Enable Corepack and install deps
RUN corepack enable && corepack prepare yarn@4.9.4 --activate
RUN yarn install

# Copy source and build static assets
COPY django-helpdesk/ .
RUN yarn build:static

# --- Stage 2: Main Django image ---FROM python:3.11-slim-bullseye
FROM python:3.11-slim-bullseye AS app
LABEL src=https://github.com/django-helpdesk/django-helpdesk
RUN apt-get update
RUN apt-get install -yqq \
   postgresql-common \
   postgresql-client \
   cron \
   git

# Copy directories
COPY django-helpdesk/src/ /opt/django-helpdesk/src/
COPY django-helpdesk/standalone/ /opt/django-helpdesk/standalone/
COPY --from=frontend-builder /opt/django-helpdesk/src/helpdesk/static/helpdesk/vendor /opt/django-helpdesk/src/helpdesk/static/helpdesk/vendor

# Copy files
COPY django-helpdesk/pyproject.toml /opt/django-helpdesk/
COPY django-helpdesk/README.rst /opt/django-helpdesk/

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
RUN pip3 install --upgrade pip
RUN pip3 install packaging
WORKDIR /opt/django-helpdesk

ENV UV_SYSTEM_PYTHON=1
RUN uv sync
RUN uv pip install -r /opt/django-helpdesk/standalone/requirements.txt

WORKDIR /opt/django-helpdesk/standalone
ENV DJANGO_SETTINGS_MODULE=standalone.config.settings
ENV PYTHONPATH=/opt/django-helpdesk/src:/opt/django-helpdesk

RUN DJANGO_HELPDESK_SECRET_KEY=foo python3 manage.py collectstatic --noinput

RUN echo "* * * * * root . /etc/env && /usr/local/bin/python3 /opt/django-helpdesk/standalone/manage.py get_email >> /var/log/cron.log 2>&1" > /etc/crontab
RUN chmod 0644 /etc/crontab
ENTRYPOINT sh /opt/django-helpdesk/standalone/entrypoint.sh
