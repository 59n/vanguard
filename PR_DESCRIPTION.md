# Add Comprehensive Docker Support

This PR adds full Docker support to Vanguard, making it easy to run the application in containers with automatic setup and CI/CD integration.

## 🎯 What's Included

### Core Docker Files
- **Dockerfile** - PHP 8.3-FPM container with all required extensions (PostgreSQL, MySQL, Redis, GD, etc.)
- **docker-compose.yml** - Complete development stack with all services
- **docker-compose.prod.yml** - Production override for pre-built images
- **docker-entrypoint.sh** - Automatic initialization script
- **.dockerignore** - Optimized build exclusions
- **docker/nginx/default.conf** - Nginx configuration for Laravel

### CI/CD Integration
- **.github/workflows/docker-build.yml** - Automated Docker image builds
  - Builds on push to `main`/`develop` branches
  - Builds on version tags (e.g., `v1.0.0`)
  - Multi-platform support (amd64, arm64)
  - Pushes to GitHub Container Registry

### Documentation
- **DOCKER.md** - Comprehensive Docker setup guide
- **DOCKER_SETUP.md** - GitHub Container Registry authentication guide
- **README.md** - Updated with Docker installation option
- **validate-docker-env.sh** - Environment validation script

### Configuration Updates
- **vite.config.js** - Updated for Docker compatibility

## ✨ Key Features

### Automatic Setup
The entrypoint script automatically handles:
- ✅ Dependency installation (Composer & NPM)
- ✅ Frontend asset building
- ✅ Application key generation
- ✅ Database migrations
- ✅ Permission setup
- ✅ Service health checks

### Out-of-the-Box Experience
Users can get started with just:
```bash
docker-compose up -d --build
```

### Services Included
- **app** - PHP-FPM application container
- **nginx** - Web server
- **postgres** - PostgreSQL 16 database
- **redis** - Redis cache and queue
- **horizon** - Laravel Horizon queue worker
- **reverb** - Laravel Reverb WebSocket server
- **node** - Node.js for Vite development (optional)

### Production Ready
- Supports pre-built images from GitHub Container Registry
- Multi-platform builds (amd64, arm64)
- Production compose override file
- Automatic image builds on GitHub

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/vanguardbackup/vanguard.git
cd vanguard

# Create .env file
cat > .env << EOF
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
QUEUE_CONNECTION=redis
REVERB_SERVER_HOST=0.0.0.0
REVERB_SERVER_PORT=8080
REVERB_HOST=localhost
REVERB_PORT=8080
REVERB_SCHEME=http
EOF

# Start all services
docker-compose up -d --build

# Access at http://localhost
```

## 📋 Testing

- [x] Dockerfile builds successfully
- [x] All services start and connect properly
- [x] Entrypoint script handles initialization
- [x] Database migrations run automatically
- [x] Frontend assets build correctly
- [x] GitHub Actions workflow builds images
- [x] Documentation is complete and accurate

## 🔍 Files Changed

### New Files (10)
- `Dockerfile`
- `docker-compose.yml`
- `docker-compose.prod.yml`
- `docker-entrypoint.sh`
- `.dockerignore`
- `docker/nginx/default.conf`
- `.github/workflows/docker-build.yml`
- `DOCKER.md`
- `DOCKER_SETUP.md`
- `validate-docker-env.sh`

### Modified Files (2)
- `README.md` - Added Docker installation option
- `vite.config.js` - Docker compatibility updates

## 📚 Documentation

All Docker-related documentation is included:
- **DOCKER.md** - Complete setup and usage guide
- **DOCKER_SETUP.md** - GitHub Container Registry authentication
- **README.md** - Quick start with Docker option

## 🎁 Benefits

1. **Easier Onboarding** - New users can get started in minutes
2. **Consistent Environments** - Same setup across all machines
3. **CI/CD Ready** - Automatic image builds on GitHub
4. **Production Deployments** - Pre-built images for faster deployments
5. **Development Friendly** - Hot-reload support with Vite

## 🔗 Related

- Docker images will be available at: `ghcr.io/vanguardbackup/vanguard`
- See [DOCKER.md](DOCKER.md) for detailed documentation
- See [DOCKER_SETUP.md](DOCKER_SETUP.md) for authentication setup

---

**Ready for Review** ✅

This PR is complete and ready for review. All files have been tested and documentation is comprehensive.

