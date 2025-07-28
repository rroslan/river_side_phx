# River Side Food Court - Production Deployment Guide

## Environment Variables Required

### Critical Variables (Must be set)

1. **DATABASE_URL**
   - PostgreSQL connection string
   - Format: `ecto://USER:PASS@HOST/DATABASE`
   - Example: `ecto://riverside_user:secretpass@db.example.com/riverside_prod`

2. **SECRET_KEY_BASE**
   - Used for signing/encrypting cookies and other secrets
   - Generate with: `mix phx.gen.secret`
   - Must be at least 64 characters

3. **PHX_HOST**
   - Your production domain
   - Example: `riverside-foodcourt.com` or `foodcourt.yourdomain.com`
   - Do NOT include `https://` or trailing slashes

### Email Configuration

4. **RESEND_API_KEY** (Optional but recommended)
   - API key from Resend.com for sending emails
   - Required for magic link authentication
   - If not set, falls back to local adapter (emails won't be sent)

### Optional Variables

5. **PORT**
   - Default: `4000`
   - The port your app will listen on

6. **POOL_SIZE**
   - Default: `10`
   - Database connection pool size
   - Increase for high-traffic applications

7. **PHX_SERVER**
   - Set to `true` when using `mix release`
   - Enables the web server

8. **UPLOADS_DIR**
   - Default: `/app/uploads`
   - Directory for file uploads (vendor logos, menu images)
   - Must be writable and persistent

9. **DNS_CLUSTER_QUERY**
   - For clustering multiple nodes
   - Example: `riverside.internal`

## Pre-deployment Checklist

### 1. Database Setup

```bash
# Create production database
createdb riverside_prod

# Run migrations
MIX_ENV=prod mix ecto.migrate

# (Optional) Seed initial data
MIX_ENV=prod mix run priv/repo/seeds.exs
```

### 2. Asset Compilation

```bash
# Install dependencies
mix deps.get --only prod

# Compile assets
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
```

### 3. Generate Release (if using releases)

```bash
# Generate release files
mix phx.gen.release

# Build the release
MIX_ENV=prod mix release
```

### 4. SSL/TLS Configuration

The application is configured to force SSL in production. Ensure your deployment platform provides SSL certificates, or configure them manually.

## Deployment Platforms

### Fly.io

1. Install Fly CLI
2. Create `fly.toml`:

```toml
app = "riverside-foodcourt"
primary_region = "sin"

[env]
  PHX_HOST = "riverside-foodcourt.fly.dev"

[http_service]
  internal_port = 4000
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true

[[services]]
  protocol = "tcp"
  internal_port = 4000

  [[services.ports]]
    port = 80
    handlers = ["http"]

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]
```

3. Set secrets:
```bash
fly secrets set DATABASE_URL=ecto://...
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
fly secrets set RESEND_API_KEY=re_...
```

### Heroku

1. Create `Procfile`:
```
web: MIX_ENV=prod mix phx.server
```

2. Configure buildpacks:
```bash
heroku buildpacks:add https://github.com/HashNuke/heroku-buildpack-elixir
heroku buildpacks:add https://github.com/gjaldon/heroku-buildpack-phoenix-static
```

3. Set config vars:
```bash
heroku config:set PHX_HOST=yourapp.herokuapp.com
heroku config:set SECRET_KEY_BASE=$(mix phx.gen.secret)
heroku config:set RESEND_API_KEY=re_...
```

### Docker

1. The project includes a `Dockerfile` for containerized deployments
2. Build: `docker build -t riverside-foodcourt .`
3. Run with environment variables:
```bash
docker run -e DATABASE_URL=... -e SECRET_KEY_BASE=... -e PHX_HOST=... -p 4000:4000 riverside-foodcourt
```

## Post-deployment Tasks

### 1. Create Admin User

```elixir
# Run in production console
user = RiverSide.Accounts.create_user!(%{
  email: "admin@riverside.com",
  is_admin: true
})
RiverSide.Accounts.deliver_user_magic_link_instructions(user, "https://yourapp.com")
```

### 2. Configure Vendors

1. Log in as admin
2. Navigate to Admin Dashboard
3. Create vendor accounts
4. Vendors can then log in and set up their profiles

### 3. Monitor Application

- Check logs for errors
- Monitor database connections
- Set up error tracking (e.g., Sentry, AppSignal)
- Configure uptime monitoring

## Security Considerations

1. **Environment Variables**: Never commit secrets to version control
2. **Database**: Use SSL connections in production
3. **Uploads**: Ensure upload directory is outside the application root
4. **CORS**: Configure allowed origins if needed
5. **Rate Limiting**: Consider adding rate limiting for API endpoints

## Troubleshooting

### Common Issues

1. **"SECRET_KEY_BASE is missing"**
   - Generate with `mix phx.gen.secret`
   - Set the environment variable

2. **"DATABASE_URL is missing"**
   - Ensure PostgreSQL is accessible
   - Check connection string format

3. **"Assets not loading"**
   - Run `MIX_ENV=prod mix assets.deploy`
   - Check `cache_static_manifest` is generated

4. **"Emails not sending"**
   - Verify RESEND_API_KEY is set
   - Check Resend dashboard for errors
   - Ensure sender domain is verified

5. **"File uploads failing"**
   - Check UPLOADS_DIR permissions
   - Ensure directory is persistent (not ephemeral)

## Performance Optimization

1. **Database**
   - Add indexes for frequently queried fields
   - Consider connection pooling
   - Monitor slow queries

2. **Caching**
   - Enable ETag support
   - Configure CDN for static assets
   - Consider Redis for session storage

3. **Monitoring**
   - Set up Phoenix LiveDashboard
   - Monitor memory usage
   - Track response times

## Backup Strategy

1. **Database**: Set up automated PostgreSQL backups
2. **Uploads**: Backup the uploads directory regularly
3. **Configuration**: Document all environment variables
4. **Code**: Use version control and tag releases

## Scaling Considerations

1. **Horizontal Scaling**: The app supports multiple nodes
2. **Database**: Consider read replicas for high traffic
3. **File Storage**: Use cloud storage (S3, GCS) for uploads
4. **Load Balancing**: Configure sticky sessions for WebSockets