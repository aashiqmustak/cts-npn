# Stage 1: Build Flutter web application using pre-configured official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy dependency files first for Docker caching
COPY client/pubspec.yaml client/pubspec.lock* ./

RUN flutter pub get

# Copy remaining Flutter project
COPY client/ ./

# Build Flutter Web in release mode
RUN flutter build web --release

# Stage 2: Serve with lightweight NGINX
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

COPY infra/docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
