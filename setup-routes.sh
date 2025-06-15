#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# APISIX Admin API Configuration
APISIX_ADMIN_URL="http://localhost:9091"

echo "🚀 Setting up APISIX routes..."

# Wait for APISIX to be ready
echo "⏳ Waiting for APISIX to be ready..."
until curl -s -f "${APISIX_ADMIN_URL}/apisix/admin/routes" -H "X-API-KEY: ${ADMIN_KEY}" > /dev/null; do
  echo "Waiting for APISIX..."
  sleep 2
done

echo "✅ APISIX is ready!"

# Create WordPress API Route
echo "📝 Creating WordPress API route..."
curl -i "${APISIX_ADMIN_URL}/apisix/admin/routes/1" \
  -H "X-API-KEY: ${ADMIN_KEY}" \
  -X PUT -d '{
    "name": "WordPress Posts API",
    "uri": "/api/posts/*",
    "methods": ["GET", "POST", "PUT", "DELETE"],
    "upstream": {
      "type": "roundrobin",
      "nodes": {
        "wordpress:80": 1
      }
    },
    "plugins": {
      "proxy-rewrite": {
        "regex_uri": ["/api/posts/(.*)", "/wp-json/wp/v2/posts/$1"]
      }
    }
  }'

echo ""

# Create GoFiber Backend Route (Public)
echo "📝 Creating GoFiber Backend public route..."
curl -i "${APISIX_ADMIN_URL}/apisix/admin/routes/2" \
  -H "X-API-KEY: ${ADMIN_KEY}" \
  -X PUT -d '{
    "name": "GoFiber Backend Public",
    "uri": "/api/data",
    "methods": ["GET"],
    "upstream": {
      "type": "roundrobin",
      "nodes": {
        "gofiber-backend:8080": 1
      }
    }
  }'

echo ""

# Create GoFiber Backend Route (Protected)
echo "📝 Creating GoFiber Backend protected route..."
curl -i "${APISIX_ADMIN_URL}/apisix/admin/routes/3" \
  -H "X-API-KEY: ${ADMIN_KEY}" \
  -X PUT -d '{
    "name": "GoFiber Backend Protected",
    "uri": "/api/protected/*",
    "methods": ["GET", "POST", "PUT", "DELETE"],
    "upstream": {
      "type": "roundrobin",
      "nodes": {
        "gofiber-backend:8080": 1
      }
    },
    "plugins": {
      "key-auth": {}
    }
  }'

echo ""

# Create GoFiber Backend CRUD Routes
echo "📝 Creating GoFiber Backend CRUD routes..."
curl -i "${APISIX_ADMIN_URL}/apisix/admin/routes/4" \
  -H "X-API-KEY: ${ADMIN_KEY}" \
  -X PUT -d '{
    "name": "GoFiber Backend CRUD",
    "uri": "/api/data/*",
    "methods": ["GET", "POST", "PUT", "DELETE"],
    "upstream": {
      "type": "roundrobin",
      "nodes": {
        "gofiber-backend:8080": 1
      }
    }
  }'

echo ""

# Create Health Check Route
echo "📝 Creating health check route..."
curl -i "${APISIX_ADMIN_URL}/apisix/admin/routes/5" \
  -H "X-API-KEY: ${ADMIN_KEY}" \
  -X PUT -d '{
    "name": "Health Check",
    "uri": "/health",
    "methods": ["GET"],
    "upstream": {
      "type": "roundrobin",
      "nodes": {
        "gofiber-backend:8080": 1
      }
    }
  }'

echo ""
echo "✅ All routes created successfully!"
echo ""
echo "📋 Available endpoints:"
echo "  - GET /api/posts/*     → WordPress REST API"
echo "  - GET /api/data        → GoFiber public data"
echo "  - GET /api/data/*      → GoFiber CRUD operations"
echo "  - * /api/protected/*   → GoFiber protected (requires API key)"
echo "  - GET /health          → Health check"
echo ""
echo "🔑 To test protected endpoints, use header:"
echo "  X-API-Key: ${GOFIBER_API_KEY}" 