# Docker Testing Guide

This guide will help you test the Docker setup to ensure everything works correctly.

## Prerequisites

- Docker Desktop or Docker Engine + Docker Compose installed
- Access to GitHub Container Registry (see DOCKER_SETUP.md for authentication)

## Step 1: Pull the Pre-built Image

First, let's pull the image that was built by GitHub Actions:

```bash
# Login to GitHub Container Registry (first time only)
echo "YOUR_PAT_TOKEN" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# Set your repository
export GITHUB_REPOSITORY="59n/vanguard"
export DOCKER_IMAGE="ghcr.io/${GITHUB_REPOSITORY}:latest"

# Pull the latest image
docker-compose pull
```

## Step 2: Set Up Environment

```bash
# Create .env file if it doesn't exist
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
REDIS_PASSWORD=null

QUEUE_CONNECTION=redis

REVERB_SERVER_HOST=0.0.0.0
REVERB_SERVER_PORT=8080
REVERB_HOST=localhost
REVERB_PORT=8080
REVERB_SCHEME=http
EOF
```

## Step 3: Start Services

### Option A: Use Pre-built Image (Recommended)

```bash
# Start with pre-built image
export DOCKER_IMAGE="ghcr.io/59n/vanguard:latest"
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Option B: Build Locally

```bash
# Build and start locally
docker-compose up -d --build
```

## Step 4: Verify Services Are Running

```bash
# Check all containers are running
docker-compose ps

# Expected output: All services should show "Up" status
# - vanguard_app
# - vanguard_nginx
# - vanguard_postgres
# - vanguard_redis
# - vanguard_horizon
# - vanguard_reverb (optional)
```

## Step 5: Check Service Health

```bash
# Check application logs
docker-compose logs app | tail -50

# Check if database is ready
docker-compose exec postgres pg_isready -U postgres

# Check if Redis is responding
docker-compose exec redis redis-cli ping
# Should return: PONG

# Check if Horizon is running
docker-compose logs horizon | tail -20

# Check if Reverb is running
docker-compose logs reverb | tail -20
```

## Step 6: Test Database Connection

```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U postgres -d vanguard -c "SELECT version();"

# Check if migrations ran
docker-compose exec app php artisan migrate:status
```

## Step 7: Test Web Application

```bash
# Test HTTP endpoint
curl -I http://localhost

# Should return: HTTP/1.1 200 OK (or 302 redirect)

# Open in browser
open http://localhost  # macOS
# or visit http://localhost in your browser
```

## Step 8: Test API Endpoints (if available)

```bash
# Test API health check (if available)
curl http://localhost/api/health

# Test authentication endpoint
curl -X POST http://localhost/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'
```

## Step 9: Test Queue System

```bash
# Check Horizon dashboard
open http://localhost/horizon  # Requires authentication

# Dispatch a test job (if available)
docker-compose exec app php artisan tinker
# Then in tinker:
# dispatch(new \App\Jobs\YourTestJob());
```

## Step 10: Test WebSocket (Reverb)

```bash
# Check Reverb is listening
curl -I http://localhost:8080

# Test WebSocket connection (using wscat if installed)
# npm install -g wscat
# wscat -c ws://localhost:8080
```

## Step 11: Test Asset Loading

```bash
# Check if CSS/JS assets are loaded
curl -I http://localhost/build/assets/app.js
curl -I http://localhost/build/assets/app.css

# Should return 200 OK (assets should be built)
```

## Step 12: Test Production Mode

```bash
# Update .env for production
sed -i '' 's/APP_ENV=local/APP_ENV=production/' .env
sed -i '' 's/APP_DEBUG=true/APP_DEBUG=false/' .env

# Restart services
docker-compose restart app horizon

# Test again
curl -I http://localhost
```

## Step 13: Test Minimal Configuration

```bash
# Stop development services
docker-compose stop node

# Use minimal configuration
docker-compose -f docker-compose.yml -f docker-compose.minimal.yml up -d

# Verify only essential services are running
docker-compose ps
```

## Step 14: Test Data Persistence

```bash
# Create test data
docker-compose exec app php artisan tinker
# Create some test records

# Stop containers
docker-compose down

# Start again
docker-compose up -d

# Verify data persisted
docker-compose exec app php artisan tinker
# Check if test data still exists
```

## Step 15: Test Logs and Monitoring

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f app
docker-compose logs -f horizon

# Check resource usage
docker stats
```

## Step 16: Test Error Handling

```bash
# Test with invalid database credentials
# Update .env with wrong password
# Restart and check logs

# Test with missing Redis
docker-compose stop redis
docker-compose restart app
docker-compose logs app | grep -i redis
```

## Step 17: Test Image Updates

```bash
# Pull latest image
docker-compose pull

# Restart with new image
docker-compose up -d

# Verify version
docker-compose exec app php artisan --version
```

## Step 18: Performance Testing

```bash
# Check resource usage
docker stats --no-stream

# Expected:
# - app: ~0-5% CPU, ~100-200MB RAM
# - postgres: ~0-2% CPU, ~50-100MB RAM
# - redis: ~0-1% CPU, ~10-20MB RAM
# - horizon: ~0-2% CPU, ~50-100MB RAM
# - nginx: ~0-1% CPU, ~10-20MB RAM
# - node: ~100-150% CPU (if running) - normal for dev
```

## Step 19: Test Cleanup

```bash
# Stop all services
docker-compose down

# Remove volumes (clean slate)
docker-compose down -v

# Start fresh
docker-compose up -d --build
```

## Step 20: Integration Tests

```bash
# Run Laravel tests inside container
docker-compose exec app php artisan test

# Run specific test suite
docker-compose exec app php artisan test --testsuite=Feature
```

## Common Issues and Solutions

### Issue: Containers won't start
```bash
# Check logs
docker-compose logs

# Check if ports are in use
lsof -i :80
lsof -i :5432
lsof -i :6379
```

### Issue: Database connection failed
```bash
# Wait for database to be ready
docker-compose exec postgres pg_isready -U postgres

# Check database logs
docker-compose logs postgres
```

### Issue: Assets not loading
```bash
# Rebuild assets
docker-compose exec app npm run build

# Check permissions
docker-compose exec app ls -la public/build
```

### Issue: High CPU usage
```bash
# Stop node service (development only)
docker-compose stop node
```

## Success Criteria

✅ All containers are running and healthy  
✅ Web application loads at http://localhost  
✅ Database connections work  
✅ Redis is responding  
✅ Horizon is processing jobs  
✅ Assets (CSS/JS) are loading  
✅ Logs show no critical errors  
✅ Resource usage is reasonable  

## Next Steps

Once testing is complete:
1. Document any issues found
2. Update configuration if needed
3. Prepare for production deployment
4. Set up monitoring and alerts

