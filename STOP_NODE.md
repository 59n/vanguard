# How to Stop the Node Service (Reduce CPU Usage)

The `vanguard_node` service runs Vite in development mode with hot-reload, which uses significant CPU (~130%+). This is normal for development but not needed in production.

## Quick Fix - Stop Node Service

```bash
# Stop the node service
docker-compose stop node

# Remove it (optional)
docker-compose rm node
```

## For Production

Since assets are pre-built in the Docker image, you don't need the node service:

```bash
# Use minimal configuration
docker-compose -f docker-compose.yml -f docker-compose.minimal.yml up -d
```

## Service Requirements

**Required:**
- ✅ app (PHP application)
- ✅ nginx (web server)
- ✅ postgres (database)
- ✅ redis (cache/queue)
- ✅ horizon (queue worker)

**Optional:**
- 🔧 node (only for development - high CPU usage)
- 🔧 reverb (only if using WebSocket features)
