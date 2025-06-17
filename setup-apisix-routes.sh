#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# APISIX Admin API Configuration
APISIX_ADMIN_URL="${APISIX_ADMIN_URL:-http://localhost:9092}"
APISIX_URL="http://localhost:9080"

# Function to wait for APISIX to be ready
wait_for_apisix() {
    echo -e "${YELLOW}⏳ Waiting for APISIX to be ready...${NC}"
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "${APISIX_ADMIN_URL}/apisix/admin/routes" -H "X-API-KEY: ${APISIX_ADMIN_KEY}" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ APISIX Admin API is ready!${NC}"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts: Waiting for APISIX Admin API..."
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ APISIX Admin API not ready after $max_attempts attempts${NC}"
    return 1
}

# Function to create a route
create_route() {
    local route_id=$1
    local route_data=$2
    local route_name=$3
    
    echo -e "${YELLOW}📝 Creating route: $route_name${NC}"
    
    response=$(curl -s -w "\n%{http_code}" "${APISIX_ADMIN_URL}/apisix/admin/routes/${route_id}" \
        -H "X-API-KEY: ${APISIX_ADMIN_KEY}" \
        -H "Content-Type: application/json" \
        -X PUT \
        -d "$route_data")
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
        echo -e "${GREEN}✅ Successfully created route: $route_name${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to create route: $route_name (HTTP $http_code)${NC}"
        echo "Response: $response_body"
        return 1
    fi
}

# Function to create a consumer for key-auth
create_consumer() {
    echo -e "${YELLOW}📝 Creating APISIX consumer for GoFiber...${NC}"
    
    local username="gofiber_consumer"
    local consumer_data='{
        "username": "'"$username"'",
        "plugins": {
            "key-auth": {
                "key": "'"${GOFIBER_API_KEY}"'"
            }
        }
    }'

    response=$(curl -s -w "\n%{http_code}" "${APISIX_ADMIN_URL}/apisix/admin/consumers/${username}" \
        -H "X-API-KEY: ${APISIX_ADMIN_KEY}" \
        -H "Content-Type: application/json" \
        -X PUT \
        -d "$consumer_data")
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | sed '$d')

    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
        echo -e "${GREEN}✅ Successfully created consumer 'gofiber_consumer'${NC}"
        return 0
    else
        # Check if consumer already exists
        if echo "$response_body" | grep -q "already exists"; then
            echo -e "${YELLOW}⚠️ Consumer 'gofiber_consumer' already exists, skipping creation.${NC}"
            return 0
        else
            echo -e "${RED}❌ Failed to create consumer (HTTP $http_code)${NC}"
            echo "Response: $response_body"
            return 1
        fi
    fi
}

setup_routes() {
    echo -e "\n${BLUE}Creating APISIX routes for assignment demonstration...${NC}"
    
    # Route 1: WordPress API Integration
    wordpress_route='{
        "name": "WordPress Posts API",
        "uris": ["/api/posts", "/api/posts/*"],
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "wordpress:80": 1
            }
        },
        "plugins": {
            "proxy-rewrite": {
                "regex_uri": ["/api/posts/(.*)", "/wp-json/wp/v2/posts/$1"]
            },
            "cors": {}
        }
    }'
    create_route "1" "$wordpress_route" "WordPress Posts API"
    
    # Route 2: GoFiber Backend Public API
    gofiber_public_route='{
        "name": "GoFiber Backend Public",
        "uri": "/api/data",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "gofiber-backend:8080": 1
            }
        },
        "plugins": {
            "cors": {}
        }
    }'
    create_route "2" "$gofiber_public_route" "GoFiber Backend Public"
    
    # Route 3: GoFiber Backend with ID parameter
    gofiber_crud_route='{
        "name": "GoFiber Backend CRUD",
        "uri": "/api/data/*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "gofiber-backend:8080": 1
            }
        },
        "plugins": {
            "cors": {}
        }
    }'
    create_route "3" "$gofiber_crud_route" "GoFiber Backend CRUD"
    
    # Route 4: GoFiber Protected API (with API key authentication)
    gofiber_protected_route='{
        "name": "GoFiber Backend Protected",
        "uri": "/api/protected/*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "gofiber-backend:8080": 1
            }
        },
        "plugins": {
            "key-auth": {
                "header": "X-API-Key"
            },
            "cors": {}
        }
    }'
    create_route "4" "$gofiber_protected_route" "GoFiber Backend Protected"
    
    # Route 5: Health Check Route
    health_route='{
        "name": "Health Check",
        "uri": "/health",
        "methods": ["GET", "OPTIONS"],
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "gofiber-backend:8080": 1
            }
        },
        "plugins": {
            "cors": {}
        }
    }'
    create_route "5" "$health_route" "Health Check"
    
    echo -e "\n${GREEN}🎉 APISIX Routes Setup Complete!${NC}"
}

run_tests() {
    echo -e "\n${BLUE}🧪 Running API tests...${NC}"

    # Test 1: Health Check
    echo -e "\n${YELLOW}1. Testing Health Check...${NC}"
    response=$(curl -s -o /dev/null -w "%{http_code}" "$APISIX_URL/health")
    if [ "$response" == "200" ]; then
        echo -e "${GREEN}✅ Health check passed${NC}"
    else
        echo -e "${RED}❌ Health check failed (HTTP $response)${NC}"
    fi

    # Test 2: WordPress API Integration
    echo -e "\n${YELLOW}2. Testing WordPress API Integration...${NC}"
    response=$(curl -L -s -w "%{http_code}" "$APISIX_URL/api/posts/")
    http_code="${response: -3}"
    if [ "$http_code" == "200" ]; then
        echo -e "${GREEN}✅ WordPress API integration works${NC}"
    else
        echo -e "${RED}❌ WordPress API integration failed (HTTP $http_code)${NC}"
        echo -e "${YELLOW}Note: If this fails, please ensure permalinks are set to 'Post name' in the WordPress admin dashboard.${NC}"
    fi

    # Test 3: GoFiber Public Data Endpoint
    echo -e "\n${YELLOW}3. Testing GoFiber Public Data Endpoint...${NC}"
    response=$(curl -s -w "%{http_code}" "$APISIX_URL/api/data")
    http_code="${response: -3}"
    if [ "$http_code" == "200" ]; then
        echo -e "${GREEN}✅ Public data endpoint works${NC}"
    else
        echo -e "${RED}❌ Public data endpoint failed (HTTP $http_code)${NC}"
    fi

    # Test 4: Protected Endpoint with API Key
    echo -e "\n${YELLOW}4. Testing Protected Endpoint with API Key...${NC}"
    response=$(curl -s -w "%{http_code}" "$APISIX_URL/api/protected/data" \
        -H "X-API-Key: ${GOFIBER_API_KEY}")
    http_code="${response: -3}"
    if [ "$http_code" == "200" ]; then
        echo -e "${GREEN}✅ Protected endpoint works with API key${NC}"
    else
        echo -e "${RED}❌ Protected endpoint failed (HTTP $http_code)${NC}"
    fi

    # Test 5: Protected Endpoint without API Key (should fail)
    echo -e "\n${YELLOW}5. Testing Protected Endpoint without API Key...${NC}"
    response=$(curl -s -w "%{http_code}" "$APISIX_URL/api/protected/data")
    http_code="${response: -3}"
    if [ "$http_code" == "401" ] || [ "$http_code" == "403" ]; then
        echo -e "${GREEN}✅ Protected endpoint correctly rejects requests without API key${NC}"
    else
        echo -e "${RED}❌ Protected endpoint should reject requests without API key (HTTP $http_code)${NC}"
    fi

    echo -e "\n${BLUE}=================================================="
    echo -e "🏁 Testing Complete!${NC}"
}

# Main execution
if wait_for_apisix; then
    create_consumer
    setup_routes
    run_tests
else
    echo -e "\n${YELLOW}⚠️ APISIX Admin API not accessible. Cannot set up routes or run tests.${NC}"
fi

echo -e "\n${BLUE}=================================================================="
echo -e "🚀 APISIX Route Setup and Test Complete!"
echo -e "==================================================================${NC}"