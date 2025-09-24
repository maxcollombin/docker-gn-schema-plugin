# GeoNetwork Docker Setup with iso19139.che Plugin

This repository contains a setup script to automatically configure GeoNetwork with the Swiss iso19139.che schema plugin.

## Quick Start

```bash
# Make the script executable
chmod +x setup.sh

# Run the setup (default version: 4.4.2)
./setup.sh

# Or specify a different version
./setup.sh 4.4.5

cd docker-geonetwork/4.4.2

# Start the stack
make up

# Stop the stack
make down

# Remove the container and images
make clean
```

## Available Services

- **GeoNetwork**: http://localhost:8080/geonetwork
- **PostgreSQL**: localhost:5432
- **Elasticsearch**: http://localhost:9200