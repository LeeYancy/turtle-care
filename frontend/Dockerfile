# ===== Stage 1: Build Flutter Web =====
FROM ghcr.io/cirruslabs/flutter:3.22.3 AS builder

WORKDIR /build

# Copy pubspec first for dependency caching
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Copy source and build
COPY lib ./lib
COPY assets ./assets
COPY web ./web

RUN flutter build web --release --web-renderer canvaski

# ===== Stage 2: Nginx Serve =====
FROM nginx:alpine

LABEL maintainer="turtlecare-team"
LABEL description="TurtleCare Frontend (Web)"

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY <<'EOF' /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # SPA routing: fallback to index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy to backend
    location /api/ {
        proxy_pass http://backend:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
        proxy_read_timeout 300s;
    }

    # Actuator (health checks)
    location /actuator/ {
        proxy_pass http://backend:8080;
        proxy_set_header Host $host;
    }

    # Gzip
    gzip on;
    gzip_types text/css application/javascript application/json image/svg+xml;
    gzip_min_length 1024;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Copy built web assets
COPY --from=builder /build/build/web /usr/share/nginx/html

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
