# Stage 1: Build Flutter web application
FROM dart:stable AS build

# Install tools required for Flutter
RUN sed -i 's/http:/https:/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || sed -i 's/http:/https:/g' /etc/apt/sources.list 2>/dev/null || true
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
# Suppress Flutter warning about running as root in Docker BuildKit
RUN touch /.dockerenv && git clone --depth 1 -b stable https://github.com/flutter/flutter.git /flutter

ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Precache Flutter Web engine and artifacts early so they are saved in the Docker layer cache
RUN flutter precache --web

WORKDIR /app

# Copy dependency files first for Docker caching
COPY client/pubspec.yaml client/pubspec.lock ./

RUN --mount=type=cache,target=/root/.pub-cache \
    flutter pub get

# Copy remaining Flutter project
COPY client/ ./

# Build Flutter Web
RUN --mount=type=cache,target=/app/.dart_tool \
    flutter build web --release


# Stage 2: NGINX
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

COPY infra/docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
