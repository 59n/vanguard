# Docker Setup Guide

This guide will help you set up and run the Vanguard application using Docker.

> **Quick Start:** Clone the repo, create a `.env` file with the settings below, then run `docker-compose up -d --build`. The entrypoint script handles everything automatically!

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
   
   REVERB_SERVER_HOST=0.0.0.0
   REVERB_SERVER_PORT=8080
   REVERB_HOST=localhost
   REVERB_PORT=8080
   REVERB_SCHEME=http
   ```
   
   **Note:** The entrypoint script will automatically:
   - Generate `APP_KEY` if missing
   - Install dependencies
   - Build frontend assets
   - Run database migrations

3. **Start the containers:**
   ```bash
   docker-compose up -d --build
   ```
   
   The entrypoint script will automatically:
   - Install PHP and Node dependencies
   - Build frontend assets
   - Generate application key (if missing)
   - Run database migrations
   - Set up permissions

4. **Wait for services to be ready** (usually 30-60 seconds):
   ```bash
   # Check container status
   docker-compose ps
   
   # View logs to see initialization progress
   docker-compose logs -f app
   ```

5. **Access the application**:
   - Web: http://localhost
   - Reverb WebSocket: ws://localhost:8080
   - Horizon Dashboard: http://localhost/horizon (requires authentication)

**Note:** For production deployments with pre-built images, see the [Using Pre-built Images](#using-pre-built-images) section below.

## Using Pre-built Images

The project automatically builds Docker images on GitHub and pushes them to GitHub Container Registry (ghcr.io).

### Pulling Latest Image

After images are built and pushed to GitHub Container Registry (see [DOCKER_SETUP.md](DOCKER_SETUP.md) for authentication):

```bash
# Set your repository (replace with actual GitHub org/repo)
export GITHUB_REPOSITORY="vanguardbackup/vanguard"
export DOCKER_IMAGE="ghcr.io/${GITHUB_REPOSITORY}:latest"

# Login to GitHub Container Registry (first time only)
# See DOCKER_SETUP.md for detailed authentication instructions
echo "YOUR_PAT_TOKEN" | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Pull the pre-built image
docker-compose pull

# Start containers (will use pre-built image instead of building)
docker-compose up -d
```

### Available Image Tags

Images are tagged with:
- `latest` - Latest build from main branch
- `main` - Latest from main branch
- `develop` - Latest from develop branch
- `v1.0.0` - Semantic version tags
- `main-<sha>` - Specific commit SHA

### Using Production Compose File

For production, use the production compose override:

```bash
export DOCKER_IMAGE="ghcr.io/your-org/vanguard:latest"
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Services

The Docker setup includes the following services:

### Required Services (Core Functionality)
- **app**: PHP-FPM application container ⚠️ **Required**
- **nginx**: Web server ⚠️ **Required**
- **postgres**: PostgreSQL 16 database ⚠️ **Required**
- **redis**: Redis cache and queue ⚠️ **Required**
- **horizon**: Laravel Horizon queue worker ⚠️ **Required** (for background jobs)

### Optional Services (Development/Features)
- **node**: Node.js for Vite development server 🔧 **Optional** (only for development)
  - **High CPU usage is normal** - Vite dev server with hot-reload is CPU intensive
  - **Not needed in production** - assets are pre-built
  - **To disable**: Use `docker-compose.minimal.yml` or stop the service
- **reverb**: Laravel Reverb WebSocket server 🔧 **Optional** (only if using real-time features)
  - Only needed if you use WebSocket/broadcasting features
  - Can be disabled if not using real-time updates

### Resource Usage

**Development Mode (all services):**
- CPU: ~100-200% (mainly from `node` service with Vite)
- Memory: ~800MB-1GB
- This is **normal** for development with hot-reload

**Production Mode (minimal services):**
- CPU: ~5-20% (much lower without Vite dev server)
- Memory: ~400-600MB
- Use `docker-compose.minimal.yml` to exclude development services

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

### Run NPM commands
```bash
docker-compose exec node npm [command]
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

### Frontend Development

For frontend development with hot reload, the `node` service runs Vite in development mode. Access it at http://localhost:5173.

### Queue Processing

Laravel Horizon is automatically running in the `horizon` container. Monitor it at http://localhost/horizon (requires authentication).

### WebSocket Server

Laravel Reverb is running in the `reverb` container on port 8080.

## Environment Variables

You can customize the setup using environment variables in your `.env` file or by creating a `.env.docker` file:

- `APP_PORT`: Port for the PHP application (default: 8000)
- `HTTP_PORT`: Port for Nginx (default: 80)
- `HTTPS_PORT`: Port for HTTPS (default: 443)
- `DB_PORT`: Port for PostgreSQL (default: 5432)
- `REDIS_PORT`: Port for Redis (default: 6379)
- `REVERB_PORT`: Port for Reverb (default: 8080)
- `VITE_PORT`: Port for Vite dev server (default: 5173)
- `DOCKER_IMAGE`: Pre-built Docker image to use (e.g., `ghcr.io/org/vanguard:latest`)

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

1. **Use minimal services** - Exclude development-only services:
   ```bash
   # Stop node service (saves ~100-150% CPU)
   docker-compose stop node
   docker-compose rm node
   
   # Or use minimal compose file
   docker-compose -f docker-compose.yml -f docker-compose.minimal.yml up -d
   ```

2. Set `APP_ENV=production` and `APP_DEBUG=false` in your `.env`

3. Use strong database passwords

4. Configure proper SSL/TLS certificates for Nginx

5. Set up proper backup strategies for PostgreSQL data

6. Consider using Docker secrets for sensitive data

7. Review and adjust resource limits in `docker-compose.yml`

8. Use a reverse proxy (like Traefik) for better SSL management

9. Use pre-built images from GitHub Container Registry for faster deployments

### Reducing Resource Usage

**To reduce CPU usage:**
```bash
# Stop the node service (Vite dev server)
docker-compose stop node

# Or exclude it when starting
docker-compose up -d app nginx postgres redis horizon
```

**To reduce memory usage:**
- Use production mode (`APP_ENV=production`)
- Disable debug mode (`APP_DEBUG=false`)
- Stop unused services (node, reverb if not needed)

## Data Persistence

Data is persisted in Docker volumes:
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

For comprehensive testing instructions, see [DOCKER_TESTING.md](DOCKER_TESTING.md).

### Quick Test

```bash
# Run the quick test script
./QUICK_TEST.sh

# Or manually check services
docker-compose ps
curl -I http://localhost
docker-compose exec postgres pg_isready -U postgres
docker-compose exec redis redis-cli ping
```

## GitHub Actions

Docker images are automatically built and pushed to GitHub Container Registry on:
- Push to `main` or `develop` branches
- Creation of version tags (e.g., `v1.0.0`)
- Manual workflow dispatch

The workflow file is located at `.github/workflows/docker-build.yml`.
