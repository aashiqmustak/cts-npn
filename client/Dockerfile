# Stage 1: Build Flutter web application
FROM dart:stable AS build

# Install tools required for Flutter
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
RUN git clone --depth 1 -b stable https://github.com/flutter/flutter.git /flutter

ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

WORKDIR /app

# Copy dependency files first for Docker caching
COPY pubspec.yaml pubspec.lock ./

RUN flutter pub get

# Copy remaining Flutter project
COPY . .

# Build Flutter Web
RUN flutter build web --release


# Stage 2: NGINX
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]