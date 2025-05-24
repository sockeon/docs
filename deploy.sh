#!/bin/bash
# Script to deploy documentation updates to GitHub

# Variables
DOCS_REPO="https://github.com/sockeon/docs.git"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Deploying Sockeon documentation updates...${NC}"

# Initialize git repository and add all files
git init
git add .

# Commit changes
echo -e "${GREEN}Committing changes...${NC}"
git commit -m "Documentation update $(date '+%Y-%m-%d %H:%M:%S')"

# Check if a remote already exists and remove it
if git remote | grep -q "origin"; then
    git remote remove origin
fi

# Add GitHub repository as remote and push
echo -e "${GREEN}Pushing to GitHub repository...${NC}"
git remote add origin "$DOCS_REPO"
git push -u --force origin main

# Create a local tag for this deployment for easy rollback
DEPLOY_TAG="deploy-$(date '+%Y%m%d-%H%M%S')"
git tag -a "$DEPLOY_TAG" -m "Deployment on $(date '+%Y-%m-%d %H:%M:%S')"

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${YELLOW}Your documentation is now available at https://sockeon.com${NC}"
echo -e "${YELLOW}This deployment was tagged as ${DEPLOY_TAG} for future reference${NC}"
