#!/bin/bash
# Script to revert documentation to a previous version

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we have a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}Error: No git repository found in $DOCS_DIR${NC}"
    echo -e "${YELLOW}Make sure you've deployed at least once using the deploy.sh script${NC}"
    exit 1
fi

# List available tags
echo -e "${YELLOW}Available deployment tags to revert to:${NC}"
git tag -l "deploy-*" -n1

echo
echo -e "${YELLOW}Enter the tag you want to revert to (or press Ctrl+C to cancel):${NC}"
read TAG

# Verify tag exists
if ! git tag -l | grep -q "^$TAG$"; then
    echo -e "${RED}Error: Tag $TAG not found${NC}"
    exit 1
fi

# Confirm the reversion
echo -e "${YELLOW}Are you sure you want to revert to $TAG? This will overwrite your current documentation. (y/n)${NC}"
read CONFIRM

if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo -e "${YELLOW}Revert cancelled${NC}"
    exit 0
fi

# Create a backup of the current state
BACKUP_TAG="backup-$(date '+%Y%m%d-%H%M%S')"
echo -e "${GREEN}Creating backup tag $BACKUP_TAG of current state...${NC}"
git tag -a "$BACKUP_TAG" -m "Backup before reverting to $TAG"

# Revert to the selected tag
echo -e "${GREEN}Reverting to $TAG...${NC}"
git checkout "$TAG" -- .

# Stage all changes
git add .

# Commit the reversion
git commit -m "Reverted to $TAG on $(date '+%Y-%m-%d %H:%M:%S')"

echo -e "${GREEN}Reversion completed successfully!${NC}"
echo -e "${YELLOW}To deploy these changes, run the deploy.sh script${NC}"
