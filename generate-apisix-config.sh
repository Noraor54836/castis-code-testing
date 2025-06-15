#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Check if APISIX_ADMIN_KEY is set
if [ -z "$APISIX_ADMIN_KEY" ]; then
    echo "Error: APISIX_ADMIN_KEY not found in .env file"
    exit 1
fi

# Generate config.yaml from template
sed "s/__APISIX_ADMIN_KEY__/$APISIX_ADMIN_KEY/g" apisix/config.yaml.template > apisix/config.yaml

echo "✅ Generated apisix/config.yaml with secure admin key"
echo "🔑 Admin key: $APISIX_ADMIN_KEY" 