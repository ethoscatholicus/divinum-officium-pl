# Etap 1 - Informacje o git (bez zmian)
FROM public.ecr.aws/docker/library/alpine:3.14 AS gitinfo
RUN apk add git
COPY .git /build/
WORKDIR /build
RUN echo "{\"commit\":\"$(git rev-parse HEAD)\",\"branch\":\"$(git rev-parse --abbrev-ref HEAD)\"}" > /build/buildinfo

# Etap 2 - Główny obraz
FROM public.ecr.aws/docker/library/perl:5.28-slim AS final

# Instalacja wymaganych pakietów
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Pobranie i instalacja dumb-init z weryfikacją
RUN set -eux; \
    ARCH=$(dpkg --print-architecture); \
    case "${ARCH}" in \
        amd64) DL_ARCH=x86_64 ;; \
        arm64) DL_ARCH=aarch64 ;; \
        *) echo "Unsupported architecture: ${ARCH}"; exit 1 ;; \
    esac; \
    wget -O /tmp/dumb-init \
        "https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_${DL_ARCH}"; \
    # Weryfikacja rozmiaru pliku
    if [ $(stat -c%s /tmp/dumb-init) -lt 50000 ]; then \
        echo "Downloaded file is too small, likely corrupted"; exit 1; \
    fi; \
    mv /tmp/dumb-init /usr/local/bin/dumb-init; \
    chmod +x /usr/local/bin/dumb-init; \
    # Test wykonania
    /usr/local/bin/dumb-init --version

# Reszta konfiguracji (bez zmian)
ENV APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates curl \
    apache2 libcgi-session-perl \
    && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/apache2 && \
    chown -R www-data:www-data /var/run/apache2


COPY docker/apache/ports.conf /etc/apache2/
COPY docker/apache/apache2.conf /etc/apache2/
COPY --chown=www-data:www-data web /var/www/web
COPY --from=gitinfo /build/buildinfo /var/www/web/buildinfo

EXPOSE 5057

# Zmieniamy ENTRYPOINT i CMD na bardziej niezawodne
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["sh", "-c", "exec /usr/sbin/apache2ctl -DFOREGROUND"]