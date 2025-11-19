# Docker Setup Guide

This guide will help you set up and run the Vanguard application using Docker.

## Prerequisites

- Docker Desktop (or Docker Engine + Docker Compose)
- Git

## Quick Start

1. **Copy environment file** (if you have one):
   ```bash
   cp .env.example .env
   ```

2. **Update your `.env` file** with the following Docker-specific settings:
   ```env
   APP_ENV=local
   APP_DEBUG=true
   APP_URL=http://localhost
   
   DB_CONNECTION=mysql
   DB_HOST=postgres
   DB_PORT=3306
   DB_DATABASE=vanguard
   DB_USERNAME=vanguard
   DB_PASSWORD=vanguard
   
   REDIS_HOST=redis
   REDIS_PORT=6379
   REDIS_PASSWORD=null
   
   QUEUE_CONNECTION=redis
   
   REVERB_SERVER_HOST=reverb
   REVERB_SERVER_PORT=8080
   REVERB_HOST=localhost
   REVERB_PORT=8080
   REVERB_SCHEME=http
   ```

3. **Choose your deployment method:**

   **Option A: Use pre-built Docker images (Recommended)**
   ```bash
   # Set your GitHub repository (replace with your actual repo)
   export GITHUB_REPOSITORY="your-org/vanguard"
   export DOCKER_IMAGE="ghcr.io/${GITHUB_REPOSITORY}:latest"
   
   # Pull and start containers
   docker-compose pull
   docker-compose up -d
   ```

   **Option B: Build images locally**
   ```bash
   docker-compose up -d --build
   ```

4. **Run database migrations**:
   ```bash
   docker-compose exec app php artisan migrate
   ```

5. **Create application key** (if not already set):
   ```bash
   docker-compose exec app php artisan key:generate
   ```

6. **Access the application**:
   - Web: http://localhost
   - Reverb WebSocket: ws://localhost:8080

## Using Pre-built Images

The project automatically builds Docker images on GitHub and pushes them to GitHub Container Registry (ghcr.io).

### Pulling Latest Image

```bash
# Set your repository
export GITHUB_REPOSITORY="your-org/vanguard"
export DOCKER_IMAGE="ghcr.io/${GITHUB_REPOSITORY}:latest"

# Login to GitHub Container Registry (first time only)
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Pull the image
docker-compose pull

# Start containers
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

- **app**: PHP-FPM application container
- **nginx**: Web server
- **postgres**: PostgreSQL 16 database
- **redis**: Redis cache and queue
- **horizon**: Laravel Horizon queue worker
- **reverb**: Laravel Reverb WebSocket server
- **node**: Node.js for Vite development server (optional)

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

1. Set `APP_ENV=production` and `APP_DEBUG=false` in your `.env`
2. Use strong database passwords
3. Configure proper SSL/TLS certificates for Nginx
4. Set up proper backup strategies for PostgreSQL data
5. Consider using Docker secrets for sensitive data
6. Review and adjust resource limits in `docker-compose.yml`
7. Use a reverse proxy (like Traefik) for better SSL management
8. Use pre-built images from GitHub Container Registry for faster deployments

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

## GitHub Actions

Docker images are automatically built and pushed to GitHub Container Registry on:
- Push to `main` or `develop` branches
- Creation of version tags (e.g., `v1.0.0`)
- Manual workflow dispatch

The workflow file is located at `.github/workflows/docker-build.yml`.
