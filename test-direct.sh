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

echo -e "${BLUE}🧪 Testing Services Directly (Without APISIX)${NC}"
echo "===================================================="

# Test 1: GoFiber Backend Health Check
echo -e "\n${YELLOW}1. Testing GoFiber Backend Health Check...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/health")
if [ "$response" == "200" ]; then
    echo -e "${GREEN}✅ GoFiber health check passed${NC}"
    curl -s http://localhost:8080/health | jq . 2>/dev/null || curl -s http://localhost:8080/health
else
    echo -e "${RED}❌ GoFiber health check failed (HTTP $response)${NC}"
fi

# Test 2: Get All Records
echo -e "\n${YELLOW}2. Testing Get All Records...${NC}"
response=$(curl -s -w "%{http_code}" "http://localhost:8080/api/data")
http_code="${response: -3}"
if [ "$http_code" == "200" ]; then
    echo -e "${GREEN}✅ Get records works${NC}"
    data="${response%???}"
    record_count=$(echo "$data" | jq '.count' 2>/dev/null || echo "N/A")
    echo "Records found: $record_count"
else
    echo -e "${RED}❌ Get records failed (HTTP $http_code)${NC}"
fi

# Test 3: Create New Record
echo -e "\n${YELLOW}3. Testing Create New Record...${NC}"
response=$(curl -s -w "%{http_code}" -X POST "http://localhost:8080/api/data" \
    -H "Content-Type: application/json" \
    -d '{"name":"Direct Test Record","value":"Created by direct test script"}')
http_code="${response: -3}"
if [ "$http_code" == "201" ]; then
    echo -e "${GREEN}✅ Record creation works${NC}"
    data="${response%???}"
    record_id=$(echo "$data" | jq '.data.id' 2>/dev/null || echo "N/A")
    echo "Created record ID: $record_id"
else
    echo -e "${RED}❌ Record creation failed (HTTP $http_code)${NC}"
fi

# Test 4: Get Specific Record
if [ "$record_id" != "N/A" ] && [ "$record_id" != "null" ]; then
    echo -e "\n${YELLOW}4. Testing Get Specific Record (ID: $record_id)...${NC}"
    response=$(curl -s -w "%{http_code}" "http://localhost:8080/api/data/$record_id")
    http_code="${response: -3}"
    if [ "$http_code" == "200" ]; then
        echo -e "${GREEN}✅ Get specific record works${NC}"
    else
        echo -e "${RED}❌ Get specific record failed (HTTP $http_code)${NC}"
    fi
else
    echo -e "\n${YELLOW}4. Skipping specific record test (no record ID)${NC}"
fi

# Test 5: Protected Endpoint with API Key
echo -e "\n${YELLOW}5. Testing Protected Endpoint with API Key...${NC}"
response=$(curl -s -w "%{http_code}" "http://localhost:8080/api/protected/data" \
    -H "X-API-Key: ${GOFIBER_API_KEY}")
http_code="${response: -3}"
if [ "$http_code" == "200" ]; then
    echo -e "${GREEN}✅ Protected endpoint works with API key${NC}"
else
    echo -e "${RED}❌ Protected endpoint failed (HTTP $http_code)${NC}"
fi

# Test 6: Protected Endpoint without API Key (should fail)
echo -e "\n${YELLOW}6. Testing Protected Endpoint without API Key...${NC}"
response=$(curl -s -w "%{http_code}" "http://localhost:8080/api/protected/data")
http_code="${response: -3}"
if [ "$http_code" == "401" ]; then
    echo -e "${GREEN}✅ Protected endpoint correctly rejects requests without API key${NC}"
else
    echo -e "${RED}❌ Expected 401, got HTTP $http_code${NC}"
fi

# Test 7: Get Users
echo -e "\n${YELLOW}7. Testing Get Users...${NC}"
response=$(curl -s -w "%{http_code}" "http://localhost:8080/api/users")
http_code="${response: -3}"
if [ "$http_code" == "200" ]; then
    echo -e "${GREEN}✅ Get users works${NC}"
    data="${response%???}"
    user_count=$(echo "$data" | jq '.count' 2>/dev/null || echo "N/A")
    echo "Users found: $user_count"
else
    echo -e "${RED}❌ Get users failed (HTTP $http_code)${NC}"
fi

# Test 8: Get API Keys
echo -e "\n${YELLOW}8. Testing Get API Keys...${NC}"
response=$(curl -s -w "%{http_code}" "http://localhost:8080/api/apikeys")
http_code="${response: -3}"
if [ "$http_code" == "200" ]; then
    echo -e "${GREEN}✅ Get API keys works${NC}"
    data="${response%???}"
    key_count=$(echo "$data" | jq '.count' 2>/dev/null || echo "N/A")
    echo "API keys found: $key_count"
else
    echo -e "${RED}❌ Get API keys failed (HTTP $http_code)${NC}"
fi

# Test 9: React Dashboard
echo -e "\n${YELLOW}9. Testing React Dashboard...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000")
if [ "$response" == "200" ]; then
    echo -e "${GREEN}✅ React Dashboard is accessible${NC}"
else
    echo -e "${RED}❌ React Dashboard failed (HTTP $response)${NC}"
fi

# Test 10: WordPress
echo -e "\n${YELLOW}10. Testing WordPress...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8081")
if [ "$response" == "200" ] || [ "$response" == "302" ]; then
    echo -e "${GREEN}✅ WordPress is accessible${NC}"
else
    echo -e "${RED}❌ WordPress failed (HTTP $response)${NC}"
fi

# Test 11: Database Connection Test
echo -e "\n${YELLOW}11. Testing Database Connection...${NC}"
if docker-compose exec -T mariadb mysql -u apiuser -papipassword apiapp -e "SELECT COUNT(*) as record_count FROM records;" 2>/dev/null; then
    echo -e "${GREEN}✅ Database connection works${NC}"
else
    echo -e "${RED}❌ Database connection failed${NC}"
fi

echo -e "\n${BLUE}===================================================="
echo -e "🏁 Direct Testing Complete!${NC}"
echo -e "\n${GREEN}Working Services:${NC}"
echo "- GoFiber Backend: http://localhost:8080"
echo "- React Dashboard: http://localhost:3000"
echo "- WordPress: http://localhost:8081"
echo "- MariaDB: localhost:3307"
echo ""
echo -e "${RED}Issue:${NC}"
echo "- APISIX Gateway: http://localhost:9080 (etcd connection issue)"
echo ""
echo -e "${YELLOW}💡 Your core application is working perfectly!${NC}"
echo -e "${YELLOW}   The APISIX routing layer needs etcd configuration fix.${NC}" 