# GitHub Actions Deployment Setup for RiverSide

This guide explains how to set up automated deployment for RiverSide using GitHub Actions.

## Prerequisites

### On Your VPS

1. **Ubuntu server** with sudo access
2. **Git** installed
3. **PostgreSQL 16** installed and running
4. **Elixir 1.18.3** and **Erlang/OTP 27** installed
5. **Node.js** (for asset compilation)
6. **Nginx** installed and configured
7. **SSL certificates** (via Let's Encrypt)
8. **Repository cloned** at `/home/ubuntu/river_side_phx`

### Passwordless Sudo for systemctl

Add this to `/etc/sudoers.d/ubuntu` on your VPS:
```bash
ubuntu ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart river_side.service
ubuntu ALL=(ALL) NOPASSWD: /usr/bin/systemctl status river_side.service
```

## GitHub Secrets Configuration

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add these secrets:

### 1. VPS_HOST
- **Value**: Your server IP or hostname
- **Example**: `10.35.102.60` or `riverside.applikasi.tech`

### 2. VPS_SSH_USER
- **Value**: `ubuntu`

### 3. VPS_SSH_PRIVATE_KEY
- **Value**: Your SSH private key content (the entire content of your `~/.ssh/id_rsa` or similar)
- **Important**: Use the RAW content, not base64 encoded
- **Example**:
  ```
  -----BEGIN RSA PRIVATE KEY-----
  MIIEowIBAAKCAQEA...
  ...rest of your key...
  -----END RSA PRIVATE KEY-----
  ```

### 4. VPS_DEPLOY_PATH
- **Value**: `/home/ubuntu/river_side_phx`

### 5. VPS_GIT_BRANCH
- **Value**: `main`

### 6. VPS_SERVICE_NAME
- **Value**: `river_side.service`

### 7. DATABASE_URL
- **Value**: `ecto://postgres:postgres@localhost/river_side`
- **Note**: Adjust username/password as needed

### 8. SECRET_KEY_BASE
- **Value**: Your production secret key base
- **Generate with**: `mix phx.gen.secret`

### 9. PHX_HOST
- **Value**: `riverside.applikasi.tech`
- **Note**: Your production domain

### 10. RESEND_API_KEY
- **Value**: Your Resend API key
- **Example**: `re_YOUR_API_KEY_HERE`

### 11. ADMIN_EMAIL
- **Value**: Email address for the admin user
- **Example**: `admin@example.com`
- **Note**: Will receive magic login links

### 12. CASHIER_EMAIL
- **Value**: Email address for the cashier user
- **Example**: `cashier@example.com`
- **Note**: Will receive magic login links

### 13. DRINKS_VENDOR_EMAIL
- **Value**: Email address for the drinks vendor user
- **Example**: `drinks.vendor@example.com`
- **Note**: Will receive magic login links

### 14. FOOD_VENDOR_EMAIL
- **Value**: Email address for the food vendor user
- **Example**: `food.vendor@example.com`
- **Note**: Will receive magic login links

## Testing the Deployment

1. Make a small change to your code
2. Commit and push to main:
   ```bash
   git add .
   git commit -m "Test deployment"
   git push origin main
   ```
3. Go to GitHub → Actions tab to monitor the deployment
4. Check your app at https://riverside.applikasi.tech

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify SSH key is correct
   - Ensure no extra spaces/newlines in the key
   - Test SSH connection manually

2. **Build Fails**
   - Check Elixir/Erlang paths match your VPS installation
   - Verify all dependencies are installed on VPS

3. **Migration Fails**
   - Ensure DATABASE_URL is correct
   - Check PostgreSQL is running
   - Verify database exists

4. **Service Won't Restart**
   - Check sudoers configuration
   - Verify service name is correct
   - Check systemctl status manually

### Checking Logs

On your VPS:
```bash
# Check deployment logs
sudo journalctl -u river_side.service -n 100

# Check service status
sudo systemctl status river_side.service

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log
```

## Manual Deployment (Fallback)

If GitHub Actions fails, you can deploy manually:

```bash
ssh ubuntu@your-server-ip
cd /home/ubuntu/river_side_phx
git pull origin main

# Export environment variables
export MIX_ENV=prod
export DATABASE_URL=ecto://postgres:postgres@localhost/river_side
export SECRET_KEY_BASE=your-key
export PHX_HOST=riverside.applikasi.tech
export RESEND_API_KEY=your-resend-key
export ADMIN_EMAIL=admin@example.com
export CASHIER_EMAIL=cashier@example.com
export DRINKS_VENDOR_EMAIL=drinks@example.com
export FOOD_VENDOR_EMAIL=food@example.com

# Build
mix deps.get --only prod
mix compile
mix assets.deploy
mix release --overwrite

# Run migrations
DATABASE_URL=ecto://postgres:postgres@localhost/river_side \
SECRET_KEY_BASE=your-key \
PHX_HOST=riverside.applikasi.tech \
_build/prod/rel/river_side/bin/river_side eval "
  Application.load(:river_side)
  Application.ensure_all_started(:river_side)
  path = Application.app_dir(:river_side, \"priv/repo/migrations\")
  Ecto.Migrator.run(RiverSide.Repo, path, :up, all: true)
"

sudo systemctl restart river_side.service
```

## Security Notes

1. **Never commit secrets** to your repository
2. **Rotate keys regularly**
3. **Use strong passwords** for database
4. **Keep your VPS updated** with security patches
5. **Monitor logs** for suspicious activity

## Next Steps

1. Set up monitoring (e.g., UptimeRobot)
2. Configure backup strategy
3. Set up error tracking (e.g., Sentry)
4. Configure CI/CD for staging environment