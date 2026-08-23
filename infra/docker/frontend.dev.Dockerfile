FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /app

# Pre-fetch pub packages for faster startup
COPY client/pubspec.yaml client/pubspec.lock ./
RUN flutter pub get

EXPOSE 8080

# Run Flutter Web Development Server
CMD ["flutter", "run", "-d", "web-server", "--web-hostname", "0.0.0.0", "--web-port", "8080"]
