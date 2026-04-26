# Backend Dockerfile
FROM node:20-bullseye

WORKDIR /usr/src/app

# Install production dependencies
COPY package.json ./
RUN npm install --only=production --no-audit --no-fund

# Copy source
COPY . .

# Ensure uploads dir exists
RUN mkdir -p ./uploads && chown -R node:node ./uploads

USER node

EXPOSE 80

# Use environment variables from docker-compose or .env
CMD ["node", "src/server.js"]
