FROM python:3.12-alpine AS build

LABEL org.opencontainers.image.authors="cgoesc2@wgu.edu"
LABEL maintainer="Christian Goeschel Ndjomouo <cgoesc2@wgu.edu>"
LABEL description="Kaybee Knowledge Base"

WORKDIR /kaybee
COPY . /kaybee/

RUN apk add --no-cache git \
    && apk add --no-cache --virtual .build gcc musl-dev \
    && python -m pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && apk del .build gcc musl-dev \
    && adduser -D -u 1000 kaybee

USER kaybee