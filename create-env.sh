#!/bin/bash

echo "Creating .env file with required environment variables..."

cat > .env << 'ENVEOF'
# APISIX Admin API Key (for managing APISIX routes)
ADMIN_KEY=edd1c9f034335f136f87ad84b625c8f1

# GoFiber Backend API Keys (for accessing protected endpoints)
GOFIBER_API_KEY=admin-key-12345
USER1_API_KEY=user1-key-67890

# Database Configuration
DB_ROOT_PASSWORD=rootpassword123
DB_USER=apiuser
DB_PASSWORD=apipassword

# WordPress Database Configuration
WORDPRESS_DB_ROOT_PASSWORD=wordpress_root_pass
WORDPRESS_DB_USER=wordpress_user
WORDPRESS_DB_PASSWORD=wordpress_pass

# APISIX Configuration
APISIX_ADMIN_URL=http://localhost:9091
ENVEOF

echo "✅ .env file created successfully!"
echo "⚠️  Remember to change these default values to secure ones!"
echo "📝 The .env file is already in your .gitignore, so it won't be committed to git." 