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
NC='\033[0m' # No Color

BASE_URL="http://localhost:9080"
# API_KEY loaded from .env file

echo -e "${BLUE}🧪 Testing APISIX Custom Dashboard APIs${NC}"
echo "=================================================="

# Test 1: Health Check
echo -e "\n${YELLOW}1. Testing Health Check...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health")
if [ "$response" == "200" ]; then
    echo -e "${GREEN}✅ Health check passed${NC}"
else
    echo -e "${RED}❌ Health check failed (HTTP $response)${NC}"
fi

# Test 2: GoFiber Public Data Endpoint
echo -e "\n${YELLOW}2. Testing GoFiber Public Data Endpoint...${NC}"
response=$(curl -s -w "%{http_code}" "$BASE_URL/api/data")
http_code="${response: -3}"
if [ "$http_code" == "200" ]; then
    echo -e "${GREEN}✅ Public data endpoint works${NC}"
    echo "Sample response: ${response%???}" | head -c 100
    echo "..."
else
    echo -e "${RED}❌ Public data endpoint failed (HTTP $http_code)${NC}"
fi

# Test 3: Create New Record
echo -e "\n${YELLOW}3. Testing Record Creation...${NC}"
response=$(curl -s -w "%{http_code}" -X POST "$BASE_URL/api/data" \
    -H "Content-Type: application/json" \
    -d '{"name":"Test Record","value":"Created by test script"}')
http_code="${response: -3}"
if [ "$http_code" == "201" ]; then
    echo -e "${GREEN}✅ Record creation works${NC}"
else
    echo -e "${RED}❌ Record creation failed (HTTP $http_code)${NC}"
fi

# Test 4: Protected Endpoint with API Key
echo -e "\n${YELLOW}4. Testing Protected Endpoint...${NC}"
response=$(curl -s -w "%{http_code}" "$BASE_URL/api/protected/data" \
    -H "X-API-Key: ${GOFIBER_API_KEY}")
http_code="${response: -3}"
if [ "$http_code" == "200" ]; then
    echo -e "${GREEN}✅ Protected endpoint works with API key${NC}"
else
    echo -e "${RED}❌ Protected endpoint failed (HTTP $http_code)${NC}"
fi

# Test 5: Protected Endpoint without API Key (should fail)
echo -e "\n${YELLOW}5. Testing Protected Endpoint without API Key...${NC}"
response=$(curl -s -w "%{http_code}" "$BASE_URL/api/protected/data")
http_code="${response: -3}"
if [ "$http_code" == "401" ] || [ "$http_code" == "403" ]; then
    echo -e "${GREEN}✅ Protected endpoint correctly rejects requests without API key${NC}"
else
    echo -e "${RED}❌ Protected endpoint should reject requests without API key (HTTP $http_code)${NC}"
fi

# Test 6: WordPress API Integration
echo -e "\n${YELLOW}6. Testing WordPress API Integration...${NC}"
response=$(curl -s -w "%{http_code}" "$BASE_URL/api/posts")
http_code="${response: -3}"
if [ "$http_code" == "200" ]; then
    echo -e "${GREEN}✅ WordPress API integration works${NC}"
else
    echo -e "${RED}❌ WordPress API integration failed (HTTP $http_code)${NC}"
    echo "Note: WordPress might still be initializing. Try again in a few minutes."
fi

# Test 7: APISIX Admin API
echo -e "\n${YELLOW}7. Testing APISIX Admin API...${NC}"
response=$(curl -s -w "%{http_code}" "http://localhost:9091/apisix/admin/routes" \
    -H "X-API-KEY: ${ADMIN_KEY}")
http_code="${response: -3}"
if [ "$http_code" == "200" ]; then
    echo -e "${GREEN}✅ APISIX Admin API works${NC}"
    # Count routes
    route_count=$(echo "${response%???}" | grep -o '"id"' | wc -l)
    echo "Routes configured: $route_count"
else
    echo -e "${RED}❌ APISIX Admin API failed (HTTP $http_code)${NC}"
fi

# Test 8: React Dashboard
echo -e "\n${YELLOW}8. Testing React Dashboard...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000")
if [ "$response" == "200" ]; then
    echo -e "${GREEN}✅ React Dashboard is accessible${NC}"
else
    echo -e "${RED}❌ React Dashboard failed (HTTP $response)${NC}"
fi

echo -e "\n${BLUE}=================================================="
echo -e "🏁 Testing Complete!${NC}"
echo -e "\n${BLUE}📋 Service URLs:${NC}"
echo "- React Dashboard: http://localhost:3000"
echo "- APISIX Gateway: http://localhost:9080"
echo "- APISIX Admin: http://localhost:9091"
echo "- WordPress: http://localhost:8081"
echo "- GoFiber Backend: http://localhost:8080"
echo ""
echo -e "${YELLOW}💡 Tip: Use the React Dashboard to manage routes visually!${NC}" 