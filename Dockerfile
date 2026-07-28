FROM hugomods/hugo:debian-non-root

USER root

RUN apt-get update \
    && apt-get install -y git \
    && rm -rf /var/lib/apt/lists/*

USER hugo

RUN git config --global --add safe.directory /src

WORKDIR /src

EXPOSE 1313

CMD ["hugo", "server", "--bind=0.0.0.0", "--port=1313", "--buildDrafts", "--buildFuture", "--disableFastRender", "--poll", "700ms"]