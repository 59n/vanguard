# Docker Image Setup Guide

## Automatic (No Setup Required) ✅

**GitHub Actions builds and pushes images automatically:**
- When you push to `main` or `develop` branches
- When you create version tags (e.g., `v1.0.0`)
- Uses `GITHUB_TOKEN` automatically - **no configuration needed!**

The workflow at `.github/workflows/docker-build.yml` handles everything automatically.

## Manual Setup (For Pulling Images Locally)

If you want to **pull and use the pre-built images** on your local machine or server, you need to authenticate with GitHub Container Registry.

### Step 1: Create a GitHub Personal Access Token (PAT)

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Or visit: https://github.com/settings/tokens

2. Click "Generate new token (classic)"

3. Give it a name like "Docker Registry Access"

4. Select scopes:
   - ✅ `read:packages` (to pull images)
   - ✅ `write:packages` (if you want to push images manually)

5. Click "Generate token"

6. **Copy the token immediately** (you won't see it again!)

### Step 2: Login to GitHub Container Registry

**On your local machine:**

```bash
# Login using your GitHub username and the PAT as password
echo "YOUR_PAT_TOKEN" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

**Example:**
```bash
echo "ghp_xxxxxxxxxxxxxxxxxxxx" | docker login ghcr.io -u johndoe --password-stdin
```

You should see: `Login Succeeded`

### Step 3: Pull and Use Images

```bash
# Set your repository
export GITHUB_REPOSITORY="your-org/vanguard"
export DOCKER_IMAGE="ghcr.io/${GITHUB_REPOSITORY}:latest"

# Pull the image
docker-compose pull

# Or use the production compose file
docker-compose -f docker-compose.yml -f docker-compose.prod.yml pull
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Step 4: Make Token Persistent (Optional)

The login above is temporary. To make it persistent:

**On macOS/Linux:**
```bash
# Store credentials in Docker config
mkdir -p ~/.docker
echo "YOUR_PAT_TOKEN" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

Docker will save the credentials in `~/.docker/config.json`

**Or use a credential helper:**
```bash
# Install Docker credential helper (if not already installed)
brew install docker-credential-helper

# Login (credentials will be stored securely)
echo "YOUR_PAT_TOKEN" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

## For Production Servers

### Option 1: Use PAT (Same as above)

```bash
# On your server
echo "YOUR_PAT_TOKEN" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

### Option 2: Use GitHub Actions Secrets (Recommended for CI/CD)

If deploying via GitHub Actions or other CI/CD:

1. Go to your repository → Settings → Secrets and variables → Actions
2. Add a new secret:
   - Name: `GHCR_TOKEN`
   - Value: Your PAT token
3. Use it in workflows:

```yaml
- name: Login to GitHub Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GHCR_TOKEN }}
```

### Option 3: Use Fine-Grained Personal Access Token (More Secure)

For better security, use a Fine-Grained PAT:

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Click "Generate new token"
3. Select your repository
4. Set permissions:
   - Repository permissions → Packages → Read (and Write if needed)
5. Generate and use the same way

## Verify Setup

```bash
# Check if you're logged in
cat ~/.docker/config.json | grep ghcr.io

# Try pulling an image
docker pull ghcr.io/your-org/vanguard:latest
```

## Troubleshooting

### "unauthorized: authentication required"

- Make sure you're logged in: `docker login ghcr.io`
- Verify your PAT has `read:packages` permission
- Check that the image exists: Visit `https://github.com/your-org/vanguard/pkgs/container/vanguard`

### "pull access denied"

- The repository might be private - ensure your PAT has access
- Check if the image was actually built (check GitHub Actions)

### Token expired

- PATs can expire - create a new one and login again
- Consider using Fine-Grained tokens with longer expiration

## Quick Reference

```bash
# 1. Create PAT on GitHub (with read:packages permission)
# 2. Login
echo "YOUR_PAT" | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# 3. Set variables
export GITHUB_REPOSITORY="your-org/vanguard"
export DOCKER_IMAGE="ghcr.io/${GITHUB_REPOSITORY}:latest"

# 4. Pull and run
docker-compose pull
docker-compose up -d
```

## Summary

- **GitHub Actions**: Fully automatic, no setup needed ✅
- **Local/Server use**: Need PAT token for authentication ⚙️
- **First time**: Create PAT → Login → Pull images
- **After that**: Just pull and use!

