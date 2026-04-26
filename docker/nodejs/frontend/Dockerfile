# Frontend Dockerfile - build with node, serve with nginx
FROM node:20-bullseye AS builder
WORKDIR /app

# copy package.json and optional lockfile so we can install dev deps needed for build
COPY package*.json ./
RUN npm install --no-audit --no-fund

# Copy the frontend project contents
COPY . .

# Build the Vite app
RUN npm run build

# Production image with nginx
FROM nginx:stable-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
