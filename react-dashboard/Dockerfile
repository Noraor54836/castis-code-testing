# Development version
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY src/ ./src/
COPY public/ ./public/

# Expose port
EXPOSE 3000

# Start in development mode
CMD ["npm", "start"] 