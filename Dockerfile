# Start with Go image to build the binary
FROM golang:1.22-alpine AS builder

# Install build dependencies including bash
RUN apk add --no-cache make git bash

# Set working directory
WORKDIR /app

# Clone the repository
RUN git clone https://github.com/akave-ai/akavesdk .

# Build the binary
RUN make build

# Final image
FROM alpine:3.19

# Install Node.js and npm
RUN apk add --no-cache nodejs npm

# Copy binary from builder
COPY --from=builder /app/bin/akavecli /usr/local/bin/akavecli

# Set working directory
WORKDIR /app

# Copy package files first (better layer caching)
COPY package*.json ./

# Install only production dependencies
RUN npm install --production

# Copy source files
COPY server.js ./
COPY index.js ./

# Environment variables with defaults
ENV NODE_ADDRESS=23.227.172.75:5500
ENV PRIVATE_KEY=""
ENV PORT=3000

# Expose API port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Start the API server
CMD ["node", "server.js"] 