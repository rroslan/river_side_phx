# River Side Food Court - Deployment Guide

This guide covers deploying River Side Food Court v1.0.0 to production.

## Prerequisites

- Elixir 1.15 or higher
- PostgreSQL 13 or higher
- Node.js 16 or higher (for asset compilation)
- A server with at least 1GB RAM
- Domain name with SSL certificate

## Environment Variables

Create a `.env` file or set these environment variables:

```bash
# Database
DATABASE_URL=postgresql://username:password@localhost/river_side_prod

# Application
SECRET_KEY_BASE=your-secret-key-base
PHX_HOST=your-domain.com
PORT=4000

# Email (using Resend)
RESEND_API_KEY=your-resend-api-key
EMAIL_FROM=noreply@your-domain.com

# Optional
POOL_SIZE=10
```

## Deployment Steps

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/river_side.git
cd river_side

# Checkout v1.0.0
git checkout v1.0.0

# Install dependencies
mix deps.get --only prod
```

### 2. Configure Production

Edit `config/prod.exs` if needed:

```elixir
config :river_side, RiverSideWeb.Endpoint,
  url: [host: System.get_env("PHX_HOST"), port: 443, scheme: "https"],
  http: [port: {:system, "PORT"}],
  cache_static_manifest: "priv/static/cache_manifest.json"
```

### 3. Build Assets

```bash
# Install Node dependencies
cd assets && npm install && cd ..

# Build assets
MIX_ENV=prod mix assets.deploy
```

### 4. Database Setup

```bash
# Create database
MIX_ENV=prod mix ecto.create

# Run migrations
MIX_ENV=prod mix ecto.migrate

# Seed initial data (optional)
MIX_ENV=prod mix run priv/repo/seeds.exs
```

### 5. Create Release

```bash
# Generate secret key base if needed
mix phx.gen.secret

# Create release
MIX_ENV=prod mix release
```

### 6. Run the Application

```bash
# Start the release
_build/prod/rel/river_side/bin/river_side start
```

## Docker Deployment

### Dockerfile

```dockerfile
FROM elixir:1.15-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base git python3 nodejs npm

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy compile-time config files
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Copy assets
COPY assets assets/
RUN cd assets && npm install

# Compile assets
COPY lib lib/
COPY priv priv/
RUN mix assets.deploy

# Compile the release
RUN mix compile

# Create release
COPY config/runtime.exs config/
RUN mix release

# Start a new build stage
FROM alpine:3.18 AS app

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/river_side ./

ENV HOME=/app

EXPOSE 4000

CMD ["bin/river_side", "start"]
```

### Docker Compose

```yaml
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: river_side
      POSTGRES_PASSWORD: your-db-password
      POSTGRES_DB: river_side_prod
    volumes:
      - postgres_data:/var/lib/postgresql/data

  app:
    build: .
    depends_on:
      - db
    environment:
      DATABASE_URL: postgresql://river_side:your-db-password@db/river_side_prod
      SECRET_KEY_BASE: your-secret-key-base
      PHX_HOST: your-domain.com
      RESEND_API_KEY: your-resend-api-key
      EMAIL_FROM: noreply@your-domain.com
    ports:
      - "4000:4000"

volumes:
  postgres_data:
```

## Nginx Configuration

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /live/websocket {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Post-Deployment

### 1. Create Admin User

```bash
# Connect to production console
_build/prod/rel/river_side/bin/river_side remote

# Create admin user
RiverSide.Accounts.register_user(%{
  email: "admin@your-domain.com",
  is_admin: true
})
```

### 2. System Health Check

- Visit https://your-domain.com
- Login with the admin account
- Check all pages load correctly
- Test order creation flow
- Verify real-time updates work

### 3. Monitoring

Consider setting up:
- Application monitoring (AppSignal, New Relic)
- Error tracking (Sentry, Rollbar)
- Uptime monitoring (UptimeRobot, Pingdom)
- Log aggregation (Logflare, Papertrail)

## Troubleshooting

### Database Connection Issues

```bash
# Check if database is accessible
psql $DATABASE_URL -c "SELECT 1"

# Check connection pool settings
# Increase POOL_SIZE if needed
```

### Asset Loading Issues

```bash
# Regenerate assets
MIX_ENV=prod mix assets.deploy

# Check static files
ls -la priv/static/
```

### WebSocket Connection Issues

- Ensure nginx is configured for WebSocket upgrade
- Check firewall rules allow WebSocket connections
- Verify PHX_HOST matches your domain

## Backup Strategy

### Database Backups

```bash
# Create backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump $DATABASE_URL > backups/river_side_$DATE.sql
```

### Application Backups

- Backup uploaded images regularly
- Store backups offsite (S3, etc.)

## Security Checklist

- [ ] SSL certificate installed
- [ ] SECRET_KEY_BASE is strong and unique
- [ ] Database password is secure
- [ ] Admin account has strong password
- [ ] Firewall configured (only expose necessary ports)
- [ ] Regular security updates scheduled
- [ ] Rate limiting configured
- [ ] CORS properly configured

## Performance Tuning

### Database

```sql
-- Add indexes for common queries
CREATE INDEX idx_orders_vendor_id ON orders(vendor_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(inserted_at);
```

### Application

- Enable gzip compression in nginx
- Configure CDN for static assets
- Monitor query performance
- Adjust connection pool size based on load

## Maintenance

### Regular Tasks

- Monitor disk space
- Review application logs
- Update dependencies monthly
- Backup database daily
- Test restore procedures

### Updating to New Versions

```bash
# Pull latest changes
git pull origin main

# Checkout new version
git checkout vX.X.X

# Update dependencies
mix deps.get --only prod

# Run migrations
MIX_ENV=prod mix ecto.migrate

# Build and restart
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release
```

## Support

For issues specific to deployment:
1. Check application logs
2. Review this guide
3. Consult Phoenix deployment guides
4. Open an issue on GitHub

Remember to replace all placeholder values (your-domain.com, passwords, etc.) with actual values for your deployment.