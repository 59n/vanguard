# Docker Setup Guide

This guide will help you run Vanguard using the pre-built Docker images that live in GitHub Container Registry.

> **Quick Start:** Clone the repo, create a `.env` file with the settings below, then run `docker-compose up -d`. No local build is required—the containers pull `ghcr.io/59n/vanguard:latest` automatically.

## Prerequisites

- **Docker Desktop** (macOS/Windows) or **Docker Engine + Docker Compose** (Linux)
- **Git** (for cloning the repository)
- **4GB+ RAM** recommended
- **10GB+ free disk space** for images and volumes

## Quick Start

1. **Create your `.env` file** (if it doesn't exist):
   ```bash
   # The entrypoint script will generate APP_KEY automatically if missing
   touch .env
   ```

2. **Update your `.env` file** with the following Docker-specific settings:
   ```env
   APP_NAME=Vanguard
   APP_ENV=local
   APP_DEBUG=true
   APP_URL=http://localhost
   
   DB_CONNECTION=pgsql
   DB_HOST=postgres
   DB_PORT=5432
   DB_DATABASE=vanguard
   DB_USERNAME=postgres
   DB_PASSWORD=password
   
   REDIS_HOST=redis
   REDIS_PORT=6379
   REDIS_PASSWORD=null
   
   QUEUE_CONNECTION=redis
   ```
   
   **Note:** The entrypoint script will automatically:
   - Generate `APP_KEY` if missing
   - Install dependencies
   - Build frontend assets
   - Run database migrations

3. **(Optional) Set a specific image tag (defaults to `latest`):**
   ```bash
   export VANGUARD_IMAGE=ghcr.io/59n/vanguard:main-<sha>
   ```

4. **Start the containers:**
   ```bash
   docker-compose up -d
   ```
   
   The entrypoint script will automatically:
   - Install PHP and Node dependencies
   - Build frontend assets
   - Generate application key (if missing)
   - Run database migrations
   - Set up permissions

5. **Wait for services to be ready** (usually 30-60 seconds):
   ```bash
   # Check container status
   docker-compose ps
   
   # View logs to see initialization progress
   docker-compose logs -f app
   ```

6. **Access the application**:
   - Web: http://localhost
   - Horizon Dashboard: http://localhost/horizon (requires authentication)

**Note:** For production deployments with pre-built images, see the [Using Pre-built Images](#using-pre-built-images) section below.

## Using Pre-built Images

The project automatically builds multi-architecture images (linux/amd64 + linux/arm64) and publishes them to GitHub Container Registry: `ghcr.io/59n/vanguard`. The default `docker-compose.yml` already pulls this image, so no build step is necessary. See the published tags here: [ghcr.io/59n/vanguard](https://github.com/59n/vanguard/pkgs/container/vanguard).

### Authentication

If the repository is private, authenticate with GitHub Container Registry:

```bash
# Create a Personal Access Token at: https://github.com/settings/tokens
# Select scope: read:packages

# Login
echo "YOUR_PAT_TOKEN" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

### Pinning a Specific Image

```bash
# Use a specific tag (optional)
export VANGUARD_IMAGE="ghcr.io/59n/vanguard:main-82f7734"

# Pull the pinned image
docker-compose pull

# Start the stack
docker-compose up -d
```

### Available Image Tags

- `latest` - Latest from main branch
- `main` - Latest from main branch
- `develop` - Latest from develop branch
- `v1.0.0` - Semantic version tags
- `main-<sha>` - Specific commit SHA

View all tags at: `https://github.com/59n/vanguard/pkgs/container/vanguard`

### Verify Image is Available

```bash
# Check if image exists
docker pull ghcr.io/59n/vanguard:latest

# Or view on GitHub
# Visit: https://github.com/59n/vanguard/pkgs/container/vanguard
```

## Services

The simplified Docker stack now runs only the core services that are required in production:

- **app** (`ghcr.io/59n/vanguard`) – PHP-FPM container that runs the Laravel application and performs all bootstrap tasks automatically.
- **nginx** – Serves HTTP traffic and proxies PHP requests to the app container.
- **postgres** – PostgreSQL 16 database with persistent storage.
- **redis** – Cache + queue backend shared by Laravel and Horizon.
- **horizon** (`ghcr.io/59n/vanguard`) – Processes queued jobs so notifications, mailers, and other async tasks keep working.

### Resource Usage

- CPU: ~5-20% total across containers (depends on Horizon workload)
- Memory: ~400-600MB
- Disk: ~2GB for images + growing PostgreSQL/Redis volumes

## Common Commands

### Start services
```bash
docker-compose up -d
```

### Stop services
```bash
docker-compose down
```

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f horizon
```

### Run Artisan commands
```bash
docker-compose exec app php artisan [command]
```

### Run Composer commands
```bash
docker-compose exec app composer [command]
```

### Access container shell
```bash
docker-compose exec app bash
```

### Clear caches
```bash
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear
docker-compose exec app php artisan view:clear
```

### Run tests
```bash
docker-compose exec app php artisan test
```

### Seed database
```bash
docker-compose exec app php artisan db:seed
```

## Development

### Queue Processing

Laravel Horizon is automatically running in the `horizon` container. Monitor it at http://localhost/horizon (requires authentication).


## Environment Variables

You can customize the setup using environment variables in your `.env` file:

- `APP_PORT`: Port for the PHP application (default: 8000)
- `HTTP_PORT`: Port for Nginx (default: 80)
- `HTTPS_PORT`: Port for HTTPS (default: 443)
- `DB_PORT`: Port for PostgreSQL (default: 5432)
- `REDIS_PORT`: Port for Redis (default: 6379)
- `VANGUARD_IMAGE`: Override the application image tag (default: `ghcr.io/59n/vanguard:latest`)

## Troubleshooting

### Permission Issues

If you encounter permission issues with storage or cache directories:

```bash
docker-compose exec app chown -R www-data:www-data storage bootstrap/cache
docker-compose exec app chmod -R 775 storage bootstrap/cache
```

### Database Connection Issues

Ensure PostgreSQL is ready before running migrations:

```bash
docker-compose exec postgres pg_isready -U postgres
```

### Rebuild Containers

If you need to rebuild everything from scratch:

```bash
docker-compose down -v
docker-compose up -d --build
```

### View Service Status

```bash
docker-compose ps
```

### Pulling Latest Images

```bash
# Update to latest image
docker-compose pull
docker-compose up -d
```

## Production Considerations

For production deployment:

1. Set `APP_ENV=production` and `APP_DEBUG=false` in your `.env`.
2. Use strong database credentials and rotate them regularly.
3. Configure proper SSL/TLS certificates for Nginx (or front it with your preferred reverse proxy).
4. Back up the `postgres_data` volume on a schedule.
5. Consider Docker secrets or an external secret manager for sensitive configuration.
6. Review resource limits and add `deploy.resources` constraints if you orchestrate with Swarm or Kubernetes.
7. Keep `VANGUARD_IMAGE` pinned to a known-good tag for deterministic rollouts.

### Reducing Resource Usage

- Scale down Horizon workers by setting `HORIZON_SUPERVISOR_MAX_PROCESSES` via `.env`.
- Stop containers you do not need temporarily: `docker-compose stop horizon`.
- Use `docker-compose down --volumes` only when you intentionally want a clean slate (destroys DB + cache).

## Data Persistence

Data is persisted in Docker volumes:
- `app_code`: Application code + compiled assets copied from the image (also stores `storage/` + `bootstrap/cache`)
- `postgres_data`: PostgreSQL database data
- `redis_data`: Redis data

To remove all data:
```bash
docker-compose down -v
```

## Stopping and Cleaning Up

To stop all services:
```bash
docker-compose stop
```

To stop and remove containers:
```bash
docker-compose down
```

To stop, remove containers, and volumes:
```bash
docker-compose down -v
```

## Testing

```bash
# Check services are running
docker-compose ps

# Test web server
curl -I http://localhost

# Test database
docker-compose exec postgres pg_isready -U postgres

# Test Redis
docker-compose exec redis redis-cli ping

# Check logs
docker-compose logs --tail=50
```

## GitHub Actions

Docker images are **automatically built and pushed** to GitHub Container Registry on:
- Push to `main` or `develop` branches
- Creation of version tags (e.g., `v1.0.0`)
- Manual workflow dispatch

**The image is already pushed!** No manual action needed.

### View Your Images

- **On GitHub**: https://github.com/59n/vanguard/pkgs/container/vanguard
- **Pull the image**: `docker pull ghcr.io/59n/vanguard:latest`

### Image Location

Images are automatically available at:
- `ghcr.io/59n/vanguard:latest` (your fork)
- After merge: `ghcr.io/vanguardbackup/vanguard:latest` (main repo)

The workflow file is located at `.github/workflows/docker-build.yml`.
