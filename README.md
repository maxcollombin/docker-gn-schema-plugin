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
```

## What the script does

1. **Clones** the official docker-geonetwork repository
2. **Downloads** the iso19139.che plugin from geocat
3. **Modifies** the Dockerfile to include the plugin
4. **Creates** a Makefile for easy container management
5. **Cleans up** unnecessary files and versions

## Usage

After running the setup script:

```bash
cd docker-geonetwork/4.4.2

# Build the custom image
make build

# Start the stack
make up

# View logs
make logs

# Stop the stack
make down
```

## Available Services

- **GeoNetwork**: http://localhost:8080/geonetwork
- **PostgreSQL**: localhost:5432
- **Elasticsearch**: http://localhost:9200

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make build` | Build the custom Docker image |
| `make up` | Start all services |
| `make down` | Stop all services |
| `make clean` | Stop services and remove volumes |

## Requirements

- Docker
- Docker Compose
- Git
- Make (optional, for using Makefile commands)

## Plugin Information

The script automatically installs the **iso19139.che** plugin from the geocat project, which provides Swiss-specific metadata schema extensions for GeoNetwork.

## Cleanup

To remove all generated files:

```bash
rm -rf docker-geonetwork
```
