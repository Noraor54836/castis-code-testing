# 🚀 APISIX Custom Dashboard with WordPress Integration

A comprehensive API gateway solution using Apache APISIX with a React-based custom dashboard, GoFiber backend, and WordPress as an API provider.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture & Design Decisions](#architecture--design-decisions)
- [Setup & Installation](#setup--installation)
- [Security Setup](#security-setup)
- [API Documentation](#api-documentation)
- [Dashboard Usage](#dashboard-usage)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🎯 Overview

This project demonstrates a complete API gateway architecture with:

- **Apache APISIX** as the API gateway with dynamic routing
- **React Dashboard** for route and upstream management
- **GoFiber Backend** for custom API logic with MariaDB
- **WordPress** as an API provider using REST API
- **Docker Compose** for container orchestration
- **etcd** for APISIX configuration storage
- **Environment-based security** for credential protection

## 🏗 Architecture & Design Decisions

### System Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  React Dashboard│    │                  │    │   WordPress     │
│     :3000       │───▶│   Apache APISIX  │───▶│     :8081       │
└─────────────────┘    │      :9080       │    └─────────────────┘
                       │      :9092       │
                       │                  │    ┌─────────────────┐
                       │                  │───▶│  GoFiber API    │
                       └──────────────────┘    │     :8080       │
                                               └─────────────────┘
                                                        │
                                               ┌─────────────────┐
                                               │    MariaDB      │
                                               │     :3306       │
                                               └─────────────────┘
```

### Design Decisions

#### 1. **Apache APISIX as API Gateway**

- **Why**: High performance, dynamic configuration, rich plugin ecosystem
- **Benefits**: Real-time route management, built-in authentication, load balancing
- **Alternative considered**: Kong, but APISIX offers better etcd integration

#### 2. **GoFiber for Backend API**

- **Why**: High performance Go framework, Express.js-like syntax
- **Benefits**: Fast execution, low memory footprint, easy middleware integration
- **Alternative considered**: Gin, but Fiber offers better developer experience

#### 3. **React for Dashboard**

- **Why**: Component-based architecture, rich ecosystem, real-time updates
- **Benefits**: Modern UI, responsive design, easy state management
- **Alternative considered**: Vue.js, but React has better APISIX community support

#### 4. **MariaDB for Data Storage**

- **Why**: MySQL compatibility, better performance, open-source
- **Benefits**: ACID compliance, mature ecosystem, Docker-friendly
- **Alternative considered**: PostgreSQL, but MariaDB offers simpler setup

#### 5. **WordPress as API Provider**

- **Why**: Demonstrates real-world CMS integration, rich REST API
- **Benefits**: Content management, user authentication, plugin ecosystem
- **Alternative considered**: Strapi, but WordPress shows legacy system integration

#### 6. **Docker Compose for Orchestration**

- **Why**: Simple multi-container management, environment consistency
- **Benefits**: Easy development setup, production-like environment
- **Alternative considered**: Kubernetes, but Docker Compose is simpler for development

#### 7. **Environment Variable Security**

- **Why**: Prevents credential exposure in version control
- **Benefits**: Secure development, easy deployment, team collaboration
- **Implementation**: `.env` files with `.gitignore` protection

## 🚀 Setup & Installation

### Prerequisites

- Docker and Docker Compose
- Git
- curl (for testing)
- Web browser (for dashboard access)

### 1. Clone and Setup Environment

```bash
# Clone the repository
git clone <your-repo-url>
cd castis-code-testing

# Copy environment template
cp .env.example .env

# Edit .env with your credentials (see Security Setup section)
nano .env
```

### 2. Generate Secure Configuration

```bash
# Make scripts executable
chmod +x generate-apisix-config.sh
chmod +x setup-apisix-routes.sh

# Generate APISIX config with your secure keys
./generate-apisix-config.sh
```

### 3. Start All Services

```bash
# Start all containers
docker-compose up -d

# Wait for services to initialize (30-60 seconds)
docker-compose logs -f

# Initialize APISIX routes and run tests
./setup-apisix-routes.sh
```

### 4. Verify Installation

```bash
# Check all containers are running
docker-compose ps

# Test API endpoints
curl http://localhost:8080/api/data
curl http://localhost:9080/api/data  # Via APISIX
```

### 5. Access Services

- **React Dashboard**: http://localhost:3000
- **APISIX Gateway**: http://localhost:9080
- **APISIX Admin**: http://localhost:9092
- **GoFiber API**: http://localhost:8080
- **WordPress**: http://localhost:8081
- **MariaDB**: localhost:3307

## 🔐 Security Setup

### Environment Variables Protection

This project uses environment variables to protect sensitive credentials from being committed to Git.

#### Protected Credentials

The following sensitive information is stored in the `.env` file (which is ignored by Git):

- **Database Credentials**: MariaDB and WordPress database passwords
- **API Keys**: GoFiber API key and APISIX admin key
- **JWT Secrets**: For authentication tokens

#### Quick Security Setup

1. **Copy environment template**:

   ```bash
   cp .env.example .env
   ```

2. **Generate secure keys**:

   ```bash
   # Generate APISIX admin key
   openssl rand -hex 32

   # Generate strong passwords
   openssl rand -base64 32
   ```

3. **Edit .env file**:

   ```env
   # API Keys & Secrets
   APISIX_ADMIN_KEY=your-secure-64-character-hex-key-here
   GOFIBER_API_KEY=your-gofiber-api-key-here

   # Database Credentials
   DB_USER=apiuser
   DB_PASSWORD=your-secure-database-password
   DB_ROOT_PASSWORD=your-secure-root-password

   # WordPress Database
   WORDPRESS_DB_USER=wordpress
   WORDPRESS_DB_PASSWORD=your-secure-wordpress-password
   WORDPRESS_DB_ROOT_PASSWORD=your-secure-wordpress-root-password
   ```

4. **Generate APISIX config**:
   ```bash
   ./generate-apisix-config.sh
   ```

#### Files Protected by .gitignore

- `.env` - Your actual environment variables
- `apisix/config.yaml` - Generated APISIX config with secrets

#### Files Safe for Git

- `.env.example` - Template without secrets
- `apisix/config.yaml.template` - Template without secrets
- `generate-apisix-config.sh` - Script to generate config
- `docker-compose.yml` - Uses environment variable references

#### Security Verification

```bash
# Check that secrets are properly ignored
git status  # Should NOT show .env or apisix/config.yaml

# Verify environment variables are loaded
docker-compose config  # Should show substituted values
```

#### Important Security Notes

1. **Never commit `.env`** - It contains your actual secrets
2. **Always run `./generate-apisix-config.sh`** after updating APISIX_ADMIN_KEY
3. **Share `.env.example`** with team members, not `.env`
4. **Use different credentials** for production environments
5. **Rotate keys regularly** in production

## 📚 API Documentation

### GoFiber Backend API

Base URL: `http://localhost:8080` (direct) or `http://localhost:9080` (via APISIX)

#### Public Endpoints

##### Get All Records

```http
GET /api/data
```

**Response:**

```json
{
  "success": true,
  "count": 10,
  "data": [
    {
      "id": 1,
      "name": "Sample Record",
      "value": "Sample Value",
      "created_at": "2025-06-15T17:10:17Z",
      "updated_at": "2025-06-15T17:10:17Z"
    }
  ]
}
```

##### Get Specific Record

```http
GET /api/data/{id}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Sample Record",
    "value": "Sample Value",
    "created_at": "2025-06-15T17:10:17Z",
    "updated_at": "2025-06-15T17:10:17Z"
  }
}
```

##### Create New Record

```http
POST /api/data
Content-Type: application/json

{
  "name": "New Record",
  "value": "New Value"
}
```

**Response:**

```json
{
  "success": true,
  "message": "Record created successfully",
  "data": {
    "id": 11,
    "name": "New Record",
    "value": "New Value",
    "created_at": "2025-06-15T18:00:00Z",
    "updated_at": "2025-06-15T18:00:00Z"
  }
}
```

##### Update Record

```http
PUT /api/data/{id}
Content-Type: application/json

{
  "name": "Updated Record",
  "value": "Updated Value"
}
```

##### Delete Record

```http
DELETE /api/data/{id}
```

**Response:**

```json
{
  "success": true,
  "message": "Record deleted successfully"
}
```

##### Health Check

```http
GET /health
```

**Response:**

```json
{
  "status": "healthy",
  "timestamp": "2025-06-15T18:00:00Z",
  "database": "connected"
}
```

#### Protected Endpoints (Require API Key)

All protected endpoints require the `X-API-Key` header:

```http
X-API-Key: your-gofiber-api-key-here
```

##### Protected Data Access

```http
GET /api/protected/data
X-API-Key: your-gofiber-api-key-here
```

##### Protected Data Creation

```http
POST /api/protected/data
X-API-Key: your-gofiber-api-key-here
Content-Type: application/json

{
  "name": "Protected Record",
  "value": "Protected Value"
}
```

#### User Management Endpoints

##### Get All Users

```http
GET /api/users
```

##### Create New User

```http
POST /api/users
Content-Type: application/json

{
  "username": "newuser",
  "email": "user@example.com"
}
```

##### Get API Keys

```http
GET /api/apikeys
```

### WordPress API Endpoints (via APISIX)

Base URL: `http://localhost:9080/api` (proxied through APISIX)

#### Posts Management

##### Get All Posts

```http
GET /api/posts
```

**Response:**

```json
[
  {
    "id": 1,
    "title": {
      "rendered": "Hello World"
    },
    "content": {
      "rendered": "<p>Welcome to WordPress...</p>"
    },
    "status": "publish",
    "date": "2025-06-15T17:00:00",
    "link": "http://localhost:8081/?p=1"
  }
]
```

##### Get Specific Post

```http
GET /api/posts/{id}
```

##### Create New Post (requires WordPress authentication)

```http
POST /api/posts
Authorization: Basic base64(username:password)
Content-Type: application/json

{
  "title": "New Post Title",
  "content": "Post content here",
  "status": "publish"
}
```

### APISIX Admin API

Base URL: `http://localhost:9092/apisix/admin`

#### Routes Management

##### List All Routes

```http
GET /apisix/admin/routes
X-API-KEY: your-apisix-admin-key
```

##### Create Route

```http
POST /apisix/admin/routes
X-API-KEY: your-apisix-admin-key
Content-Type: application/json

{
  "uri": "/api/test",
  "methods": ["GET", "POST"],
  "upstream": {
    "type": "roundrobin",
    "nodes": {
      "gofiber-backend:8080": 1
    }
  }
}
```

##### Delete Route

```http
DELETE /apisix/admin/routes/{route_id}
X-API-KEY: your-apisix-admin-key
```

### Error Responses

All APIs return consistent error responses:

```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

Common HTTP status codes:

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `404` - Not Found
- `500` - Internal Server Error

## 🎛 Dashboard Usage

### Accessing the Dashboard

1. Open http://localhost:3000 in your browser
2. The dashboard provides three main tabs:
   - **Routes**: Manage APISIX routes
   - **Upstreams**: View upstream configurations
   - **API Test**: Test API endpoints

### Managing Routes

#### Creating Routes

1. Click "Create Route" button
2. Choose from predefined templates:

   - **WordPress API Route**: Pre-configured for WordPress REST API
   - **GoFiber Backend Route**: Pre-configured with API key authentication
   - **Custom Route**: Build your own configuration

3. Configure route parameters:
   - **URI Pattern**: URL path (e.g., `/api/data`)
   - **HTTP Methods**: GET, POST, PUT, DELETE
   - **Upstream Nodes**: Backend services
   - **Plugins**: Authentication, rate limiting, etc.

#### Route Templates

**WordPress API Route:**

```json
{
  "uri": "/api/posts",
  "methods": ["GET"],
  "upstream": {
    "type": "roundrobin",
    "nodes": {
      "wordpress:80": 1
    }
  },
  "plugins": {
    "proxy-rewrite": {
      "regex_uri": ["^/api/posts(.*)", "/wp-json/wp/v2/posts$1"]
    }
  }
}
```

**GoFiber Backend Route:**

```json
{
  "uri": "/api/data",
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
}
```

#### Deleting Routes

1. Find the route in the routes list
2. Click the delete button (🗑️)
3. Confirm deletion

### API Testing

1. Go to the "API Test" tab
2. Choose from predefined tests:

   - **Test GoFiber API**
   - **Test WordPress API**
   - **Test Protected Endpoints**

3. Or create custom tests:

   - Set HTTP method
   - Enter URL
   - Add headers (e.g., API keys)
   - Set request body

4. Click "Run Test" to execute

## 🧪 Testing

### Manual Testing Commands

#### Test GoFiber Backend

```bash
# Health check
curl http://localhost:8080/health

# Get all data
curl http://localhost:8080/api/data

# Create new record
curl -X POST http://localhost:8080/api/data \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Record","value":"Test Value"}'

# Test via APISIX
curl http://localhost:9080/api/data

# Test protected endpoint
curl -H "X-API-Key: your-gofiber-api-key-here" \
  http://localhost:8080/api/protected/data
```

#### Test WordPress Integration

```bash
# Test WordPress posts via APISIX
curl http://localhost:9080/api/posts

# Direct WordPress access
curl http://localhost:8081/wp-json/wp/v2/posts

# Test specific post
curl http://localhost:9080/api/posts/1
```

#### Test APISIX Admin API

```bash
# List all routes
curl -H "X-API-KEY: your-apisix-admin-key" \
  http://localhost:9092/apisix/admin/routes

# Get route details
curl -H "X-API-KEY: your-apisix-admin-key" \
  http://localhost:9092/apisix/admin/routes/1
```

### Automated Testing Scripts

#### Run Complete Test Suite

```bash
# Make test script executable
chmod +x setup-apisix-routes.sh

# Run API setup and tests
./setup-apisix-routes.sh
```

#### Load Testing

```bash
# Install Apache Bench (if needed)
# Ubuntu/Debian: apt-get install apache2-utils
# macOS: brew install httpie

# Test GoFiber endpoint
ab -n 1000 -c 10 http://localhost:9080/api/data

# Test WordPress endpoint
ab -n 500 -c 5 http://localhost:9080/api/posts
```

### React Dashboard Testing

1. Navigate to http://localhost:3000
2. Verify all tabs load correctly
3. Test route creation and deletion
4. Use the built-in API testing feature
5. Check real-time updates

## 🔍 Troubleshooting

### Common Issues

#### Services Not Starting

```bash
# Check service status
docker-compose ps

# View logs for specific service
docker-compose logs [service-name]

# Restart specific service
docker-compose restart [service-name]

# Rebuild and restart
docker-compose down
docker-compose build
docker-compose up -d
```

#### Database Connection Issues

```bash
# Check MariaDB logs
docker-compose logs mariadb

# Test database connection
docker-compose exec mariadb mysql -u apiuser -p apiapp

# Reset database
docker-compose down -v  # WARNING: This deletes all data
docker-compose up -d
```

#### APISIX Configuration Issues

```bash
# Check APISIX logs
docker-compose logs apisix

# Verify etcd connection
docker-compose logs etcd

# Test admin API
curl -H "X-API-KEY: your-apisix-admin-key" \
  http://localhost:9092/apisix/admin/routes

# Regenerate APISIX config
./generate-apisix-config.sh
docker-compose restart apisix
```

#### React Dashboard Issues

```bash
# Check dashboard logs
docker-compose logs react-dashboard

# Rebuild dashboard
docker-compose build react-dashboard
docker-compose up -d react-dashboard

# Check if APISIX admin API is accessible
curl -H "X-API-KEY: your-apisix-admin-key" \
  http://localhost:9092/apisix/admin/routes
```

#### Environment Variable Issues

```bash
# Verify .env file exists
ls -la .env

# Check environment variable substitution
docker-compose config

# Regenerate configuration
./generate-apisix-config.sh
```

#### Port Conflicts

```bash
# Check what's using ports
lsof -i :3000  # React Dashboard
lsof -i :8080  # GoFiber
lsof -i :8081  # WordPress
lsof -i :9080  # APISIX Gateway
lsof -i :9092  # APISIX Admin

# Stop conflicting services or change ports in docker-compose.yml
```

### Performance Issues

#### Slow API Responses

1. Check database performance:

   ```bash
   docker-compose exec mariadb mysql -u apiuser -p apiapp \
     -e "SHOW PROCESSLIST;"
   ```

2. Monitor container resources:

   ```bash
   docker stats
   ```

3. Check APISIX upstream health:
   ```bash
   curl -H "X-API-KEY: your-apisix-admin-key" \
     http://localhost:9092/apisix/admin/upstreams
   ```

#### High Memory Usage

1. Limit container memory in docker-compose.yml:

   ```yaml
   services:
     service-name:
       deploy:
         resources:
           limits:
             memory: 512M
   ```

2. Optimize database queries
3. Enable APISIX caching plugins

### Debug Mode

Enable debug logging:

```bash
# Set debug environment variables
echo "DEBUG=true" >> .env
echo "LOG_LEVEL=debug" >> .env

# Restart services
docker-compose restart
```

## 🤝 Contributing

### Development Setup

1. Fork the repository
2. Create a feature branch:

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. Set up development environment:

   ```bash
   cp .env.example .env
   # Edit .env with development credentials
   ./generate-apisix-config.sh
   docker-compose up -d
   ```

4. Make your changes
5. Test your changes:

   ```bash
   ./setup-apisix-routes.sh
   ```

6. Commit and push:

   ```bash
   git add .
   git commit -m "Add your feature description"
   git push origin feature/your-feature-name
   ```

7. Submit a pull request

### Code Style

- **Go**: Follow standard Go formatting (`gofmt`)
- **JavaScript/React**: Use ESLint and Prettier
- **Docker**: Use multi-stage builds where appropriate
- **Documentation**: Update README.md for any new features

### Testing Requirements

- Add tests for new API endpoints
- Update API documentation
- Test with both direct access and APISIX proxy
- Verify security configurations

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🎯 Quick Demo

### Complete Demo Flow

1. **Start the System**

   ```bash
   docker-compose up -d
   ./setup-apisix-routes.sh
   ```

2. **Access Dashboard** (http://localhost:3000)

   - Show routes management
   - Create new route
   - Test API endpoints

3. **Test API Integration**

   ```bash
   # Test WordPress via APISIX
   curl http://localhost:9080/api/posts

   # Test GoFiber via APISIX
   curl http://localhost:9080/api/data

   # Create new record
   curl -X POST http://localhost:9080/api/data \
     -H "Content-Type: application/json" \
     -d '{"name":"Demo Record","value":"Created via APISIX"}'
   ```

4. **Verify Database**
   ```bash
   docker-compose exec mariadb mysql -u apiuser -p apiapp \
     -e "SELECT * FROM records ORDER BY created_at DESC LIMIT 5;"
   ```

This demonstrates the complete integration: APISIX routing requests to both WordPress and GoFiber services, data persistence in MariaDB, and management through the React dashboard.

---

**Built with ❤️ using Apache APISIX, GoFiber, React, and Docker**
