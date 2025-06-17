#!/bin/bash

echo "Creating .env file with required environment variables..."

# Generate a secure random API key
APISIX_ADMIN_KEY=$(openssl rand -hex 16)
GOFIBER_API_KEY="admin-key-$(openssl rand -hex 8)"
USER1_API_KEY="user1-key-$(openssl rand -hex 8)"

cat > .env << ENVEOF
# APISIX Configuration
APISIX_ADMIN_URL=http://localhost:9092
APISIX_ADMIN_KEY=${APISIX_ADMIN_KEY}

# GoFiber Backend API Keys (for accessing protected endpoints)
GOFIBER_API_KEY=${GOFIBER_API_KEY}
USER1_API_KEY=${USER1_API_KEY}

# Database Configuration
DB_ROOT_PASSWORD=rootpassword123
DB_USER=apiuser
DB_PASSWORD=apipassword

# WordPress Database Configuration
WORDPRESS_DB_ROOT_PASSWORD=wordpress_root_pass
WORDPRESS_DB_USER=wordpress_user
WORDPRESS_DB_PASSWORD=wordpress_pass
ENVEOF

echo "✅ .env file created successfully!"
echo "🔑 Generated secure random API keys:"
echo "   - APISIX_ADMIN_KEY: ${APISIX_ADMIN_KEY}"
echo "   - GOFIBER_API_KEY: ${GOFIBER_API_KEY}"
echo "   - USER1_API_KEY: ${USER1_API_KEY}"
echo ""
echo "⚠️  Save these keys securely - they won't be shown again!"
echo "📝 The .env file is in your .gitignore, so it won't be committed to git." 